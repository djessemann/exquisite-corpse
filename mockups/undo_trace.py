import numpy as np, json, warnings; warnings.filterwarnings('ignore')
from PIL import Image
from skimage import measure, morphology
from scipy import ndimage
import potrace
src='/root/.claude/uploads/7f6f7cde-65fc-5c00-9001-36c3aa42a404/11520dbc-image.jpg'
a=np.array(Image.open(src).convert('L'))
bw=a<110; bw=morphology.remove_small_objects(bw,80)
lab=measure.label(ndimage.binary_closing(bw,structure=morphology.disk(6)),connectivity=2)
props=[p for p in measure.regionprops(lab) if p.area>400]
props=sorted(props,key=lambda p:p.centroid[0]); rows=[]
for p in props:
    if rows and abs(p.centroid[0]-rows[-1][-1].centroid[0])<120: rows[-1].append(p)
    else: rows.append([p])
order=[]
for r in rows: order+=sorted(r,key=lambda p:p.centroid[1])
def trace_fill(m):
    m=morphology.remove_small_holes(m,300)
    path=potrace.Bitmap(~m).trace(turdsize=4,alphamax=1.0,opttolerance=0.3); d=''
    for c in path:
        d+='M%.1f %.1f'%(c.start_point.x,c.start_point.y)
        for s in c.segments:
            if s.is_corner: d+=' L%.1f %.1f L%.1f %.1f'%(s.c.x,s.c.y,s.end_point.x,s.end_point.y)
            else: d+=' C%.1f %.1f %.1f %.1f %.1f %.1f'%(s.c1.x,s.c1.y,s.c2.x,s.c2.y,s.end_point.x,s.end_point.y)
        d+=' Z'
    return d
out={}
PAD=4
for i,p in enumerate(order):
    y0,x0,y1,x1=p.bbox
    m=(lab[y0-PAD:y1+PAD,x0-PAD:x1+PAD]==p.label)&bw[y0-PAD:y1+PAD,x0-PAD:x1+PAD]
    h,w=m.shape
    out['undo%d'%(i+1)]={'kind':'fill','w':w,'h':h,'d':trace_fill(m)}
g=json.load(open('glyphs.json')); g={k:v for k,v in g.items() if not k.startswith('undo')}; g.update(out)
json.dump(g,open('glyphs.json','w'))
import os
for n,v in out.items():
    open('svg/%s.svg'%n,'w').write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d"><path d="%s" fill="#1a1a1a"/></svg>'%(v['w'],v['h'],v['d']))
# sheet at icon size (30px) and larger (80px)
cell=120; cols=12; rows_n=2
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" style="background:#fff">'%(cols*cell,rows_n*cell)]
for i,(n,v) in enumerate(out.items()):
    X=(i%cols)*cell; Y=(i//cols)*cell
    svg.append('<text x="%d" y="%d" font-size="11" font-family="monospace">%s</text>'%(X+4,Y+12,n))
    svg.append('<svg x="%d" y="%d" width="70" height="70" viewBox="0 0 %d %d"><path d="%s" fill="#1a1a1a"/></svg>'%(X+8,Y+18,v['w'],v['h'],v['d']))
    svg.append('<svg x="%d" y="%d" width="30" height="30" viewBox="0 0 %d %d"><path d="%s" fill="#1a1a1a"/></svg>'%(X+84,Y+38,v['w'],v['h'],v['d']))
svg.append('</svg>'); open('undo_sheet.svg','w').write('\n'.join(svg))
import cairosvg; cairosvg.svg2png(url='undo_sheet.svg',write_to='undo_sheet.png',output_width=1440*2)
print(len(out))
