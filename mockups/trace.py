import numpy as np, json, warnings
warnings.filterwarnings('ignore')
from PIL import Image
from skimage import measure, morphology
from skan import Skeleton, summarize
import potrace
from scipy import ndimage

src='/root/.claude/uploads/7f6f7cde-65fc-5c00-9001-36c3aa42a404/93bba040-image.jpg'
a=np.array(Image.open(src).convert('L'))
bw=a<110
bw=morphology.remove_small_objects(bw,60)
lab=measure.label(bw,connectivity=2)
props=measure.regionprops(lab)
props=sorted(props,key=lambda p:(p.bbox[1]//150,p.bbox[0]))
labof={i:p.label for i,p in enumerate(props)}

GROUPS={}
for i,k in enumerate(range(8,16)): GROUPS['rectA%d'%(i+1)]=('stroke',[k])
for i,k in enumerate(range(32,40)): GROUPS['rectB%d'%(i+1)]=('stroke',[k])
for i,k in enumerate(range(54,58)): GROUPS['frameL%d'%(i+1)]=('stroke',[k])
GROUPS['frameT1']=('stroke',[53])
for i,k in enumerate(range(84,89)): GROUPS['frameP%d'%(i+1)]=('stroke',[k])
for i,k in enumerate(range(70,80)): GROUPS['circ%d'%(i+1)]=('stroke',[k])
penO=[49,63,65,82,89,50,60,61,58,59,64,80,81]
for i,k in enumerate(penO): GROUPS['penO%d'%(i+1)]=('stroke',[k])
penF=[(16,17),(24,25),(45,46),(51,52),(67,68),(40,26),(43,44),(41,42),(66,62),(83,69)]
for i,k in enumerate(penF): GROUPS['penF%d'%(i+1)]=('fill',list(k))
fills=[(0,1),(2,20),(3,21),(4,5),(6,7),(18,27),(19,28),(22,29),(23,31),(30,47)]
for i,k in enumerate(fills): GROUPS['fill%d'%(i+1)]=('fill',list(k))

PAD=6
GAP={'penF3':7}
def crop_mask(ids,gap=0):
    m=np.zeros(lab.shape,bool)
    for i in ids: m|=(lab==labof[i])
    if gap and len(ids)==2:
        body=lab==labof[ids[0]]; tip=lab==labof[ids[1]]
        cb=np.array(ndimage.center_of_mass(body)); ct=np.array(ndimage.center_of_mass(tip))
        v=ct-cb; v=v/np.linalg.norm(v)*gap
        tip=ndimage.shift(tip.astype(float),v,order=0)>0.5
        m=body|tip
    ys,xs=np.nonzero(m); y0,y1,x0,x1=ys.min()-PAD,ys.max()+PAD+1,xs.min()-PAD,xs.max()+PAD+1
    return m[y0:y1,x0:x1]

def smooth(pts,k=5):
    if len(pts)<k+2: return pts
    out=pts.copy()
    for i in range(len(pts)):
        lo=max(0,i-k//2); hi=min(len(pts),i+k//2+1); out[i]=pts[lo:hi].mean(0)
    return out

def resample(pts,step=5.0):
    d=np.r_[0,np.cumsum(np.linalg.norm(np.diff(pts,axis=0),axis=1))]
    if d[-1]<step: return pts[[0,-1]]
    t=np.arange(0,d[-1],step); t=np.r_[t,d[-1]]
    return np.c_[np.interp(t,d,pts[:,0]),np.interp(t,d,pts[:,1])]

def catmull(pts):
    # pts: Nx2 (x,y). return svg d using cubic beziers
    if len(pts)<3:
        return 'M%.1f %.1f L%.1f %.1f'%(pts[0,0],pts[0,1],pts[-1,0],pts[-1,1])
    p=np.vstack([pts[0],pts,pts[-1]])
    d='M%.1f %.1f'%(p[1,0],p[1,1])
    for i in range(1,len(p)-2):
        p0,p1,p2,p3=p[i-1],p[i],p[i+1],p[i+2]
        c1=p1+(p2-p0)/6; c2=p2-(p3-p1)/6
        d+=' C%.1f %.1f %.1f %.1f %.1f %.1f'%(c1[0],c1[1],c2[0],c2[1],p2[0],p2[1])
    return d

def trace_stroke(m):
    # estimate marker width from area/skeleton length
    sk=morphology.skeletonize(m)
    S=Skeleton(sk); summ=summarize(S,separator='-')
    width=m.sum()/max(1,sk.sum())
    spur=width*3.4
    d=[]
    for i,row in summ.iterrows():
        coords=S.path_coordinates(i)  # (row,col)
        L=row['branch-distance']
        if row['branch-type']==1 and L<spur: continue
        if row['branch-type']==0 and L<spur: continue
        if row['branch-type']==2 and L<width*0.6: continue
        pts=np.c_[coords[:,1],coords[:,0]].astype(float)
        pts=smooth(pts,7); pts=resample(pts,4.0)
        d.append(catmull(pts))
    return ' '.join(d), width

from scipy import ndimage
def trace_ring(m,square=False,straighten=0.0):
    """closed outline: midline between outer and inner edge of the marker line"""
    dt0=ndimage.distance_transform_edt(m); sk0=morphology.skeletonize(m)
    w0=float(np.median(dt0[sk0])*2)
    mc=ndimage.binary_closing(m,structure=morphology.disk(int(round(w0*1.3))),border_value=0)
    filled=ndimage.binary_fill_holes(mc)
    hole=filled & ~mc
    hole=morphology.remove_small_objects(hole,200)
    if hole.sum()<200: return None
    lab2=measure.label(hole); sizes=np.bincount(lab2.ravel()); sizes[0]=0
    hole=lab2==sizes.argmax()
    dt=ndimage.distance_transform_edt(m)
    sk=morphology.skeletonize(m)
    width=float(np.median(dt[sk])*2)
    r=max(1,int(round(width/2)))
    mid=ndimage.binary_dilation(hole,structure=(morphology.square(2*r+1) if square else morphology.disk(r)))
    mid=ndimage.binary_opening(mid,structure=morphology.disk(2))
    cs=measure.find_contours(mid.astype(float),0.5)
    c=max(cs,key=len)
    pts=np.c_[c[:,1],c[:,0]]
    # circular smoothing
    k=9; n=len(pts); out=pts.copy()
    for i in range(n):
        idx=[(i+j)%n for j in range(-k//2,k//2+1)]; out[i]=pts[idx].mean(0)
    pts=resample(out,5.0)
    dev=(0.0,0.0)
    if straighten>0:
        x0,y0=pts.min(0); x1,y1=pts.max(0)
        dl=pts[:,0]-x0; dr=x1-pts[:,0]; dt=pts[:,1]-y0; db=y1-pts[:,1]
        near=np.argmin(np.c_[dl,dr,dt,db],axis=1)
        # each edge's line is the median of the points nearest to it, so edges move both ways
        L=np.median(pts[near==0,0]); R=np.median(pts[near==1,0]); T=np.median(pts[near==2,1]); B=np.median(pts[near==3,1])
        cz=0.12*min(x1-x0,y1-y0)
        tgt=pts.copy()
        tgt[near==0,0]=L; tgt[near==1,0]=R; tgt[near==2,1]=T; tgt[near==3,1]=B
        # points in a corner zone head for the corner itself, which keeps corners crisp
        nearx=np.minimum(np.abs(pts[:,0]-L),np.abs(pts[:,0]-R)); neary=np.minimum(np.abs(pts[:,1]-T),np.abs(pts[:,1]-B))
        corner=(nearx<cz)&(neary<cz)
        cx=np.where(np.abs(pts[:,0]-L)<np.abs(pts[:,0]-R),L,R); cy=np.where(np.abs(pts[:,1]-T)<np.abs(pts[:,1]-B),T,B)
        tgt[corner,0]=cx[corner]; tgt[corner,1]=cy[corner]
        pts=pts+(tgt-pts)*straighten
        # smooth again lightly, then measure how far the line still bows inward
        k=5; n=len(pts); out2=pts.copy()
        for i in range(n):
            idx=[(i+j)%n for j in range(-k//2,k//2+1)]; out2[i]=pts[idx].mean(0)
        pts=out2
        x0,y0=pts.min(0); x1,y1=pts.max(0)
        dl=pts[:,0]-x0; dr=x1-pts[:,0]; dt=pts[:,1]-y0; db=y1-pts[:,1]
        # inward bow along left/right edges (x) and top/bottom edges (y), ignoring the corners
        side=np.minimum(dl,dr); topb=np.minimum(dt,db)
        devx=float(side[topb>(y1-y0)*0.18].max()/(x1-x0)) if (topb>(y1-y0)*0.18).any() else 0.0
        devy=float(topb[side>(x1-x0)*0.18].max()/(y1-y0)) if (side>(x1-x0)*0.18).any() else 0.0
        dev=(round(devx,4),round(devy,4))
    mn=pts.min(0); pts=pts-mn; ext=pts.max(0)
    pts=np.vstack([pts,pts[:1]])
    d=catmull_closed(pts)
    return d,width,dev,(int(np.ceil(ext[0])),int(np.ceil(ext[1])))

def catmull_closed(pts):
    p=pts[:-1]; n=len(p)
    d='M%.1f %.1f'%(p[0,0],p[0,1])
    for i in range(n):
        p0,p1,p2,p3=p[(i-1)%n],p[i],p[(i+1)%n],p[(i+2)%n]
        c1=p1+(p2-p0)/6; c2=p2-(p3-p1)/6
        d+=' C%.1f %.1f %.1f %.1f %.1f %.1f'%(c1[0],c1[1],c2[0],c2[1],p2[0],p2[1])
    return d+' Z'

def trace_fill(m):
    m=morphology.remove_small_holes(m,400)
    bmp=potrace.Bitmap(~m)
    path=bmp.trace(turdsize=4,alphamax=1.0,opttolerance=0.3)
    d=''
    for curve in path:
        sp=curve.start_point; d+='M%.1f %.1f'%(sp.x,sp.y)
        for seg in curve.segments:
            if seg.is_corner:
                d+=' L%.1f %.1f L%.1f %.1f'%(seg.c.x,seg.c.y,seg.end_point.x,seg.end_point.y)
            else:
                d+=' C%.1f %.1f %.1f %.1f %.1f %.1f'%(seg.c1.x,seg.c1.y,seg.c2.x,seg.c2.y,seg.end_point.x,seg.end_point.y)
        d+=' Z'
    return d

out={}
for name,(kind,ids) in GROUPS.items():
    m=crop_mask(ids,GAP.get(name,0)); h,w=m.shape
    if kind=='stroke':
        rr=trace_ring(m,square=name[:4]!='circ',straighten=(0.5 if name.startswith('frame') else 0.0)) if name[:4] in ('rect','fram','circ') else None
        if rr: d,width,dev,(w,h)=rr
        else: d,width=trace_stroke(m); dev=(0,0)
        if name[:4] in ('rect','fram','circ') and not rr: print('  fallback skeleton for',name)
        out[name]={'kind':kind,'w':w,'h':h,'d':d,'mw':round(float(width),1),'dev':list(dev)}
        if name.startswith('frame'): print('   ',name,'inward bow x,y as fraction:',dev)
    else:
        d=trace_fill(m); out[name]={'kind':kind,'w':w,'h':h,'d':d}
    print(name,kind,w,h,len(d))
json.dump(out,open('glyphs.json','w'))
import os; os.makedirs('svg',exist_ok=True)
for n,g in out.items():
    if g['kind']=='stroke':
        body='<path d="%s" fill="none" stroke="#1a1a1a" stroke-width="2.5" vector-effect="non-scaling-stroke" stroke-linecap="round" stroke-linejoin="round"/>'%g['d']
    else:
        body='<path d="%s" fill="#1a1a1a"/>'%g['d']
    open('svg/%s.svg'%n,'w').write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d">%s</svg>'%(g['w'],g['h'],body))

# preview sheet: every glyph at uniform screen stroke
cell=110; names=list(out); cols=10; rows=(len(names)+cols-1)//cols
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" style="background:#fff">'%(cols*cell,rows*cell)]
for i,n in enumerate(names):
    g=out[n]; X=(i%cols)*cell; Y=(i//cols)*cell
    s=min(80/g['w'],80/g['h'])
    svg.append('<text x="%d" y="%d" font-size="10" font-family="monospace">%s</text>'%(X+4,Y+12,n))
    svg.append('<svg x="%d" y="%d" width="80" height="80" viewBox="0 0 %d %d" preserveAspectRatio="xMidYMid meet">'%(X+15,Y+18,g['w'],g['h']))
    if g['kind']=='stroke':
        svg.append('<path d="%s" fill="none" stroke="#1a1a1a" stroke-width="2.5" vector-effect="non-scaling-stroke" stroke-linecap="round" stroke-linejoin="round"/>'%g['d'])
    else:
        svg.append('<path d="%s" fill="#1a1a1a"/>'%g['d'])
    svg.append('</svg>')
svg.append('</svg>')
open('preview.svg','w').write('\n'.join(svg))
