# hand-drawn icon mockups

`index.html` is a standalone page that drops the traced marker sketch (`sketch.jpg`) into mockups of the four app screens, with a mixer to combine glyphs and tune line weight.

- `glyphs/*.svg` one file per traced drawing. Outline shapes are stroked paths with `vector-effect="non-scaling-stroke"`, so `stroke-width` is in screen pixels no matter how the glyph is scaled. Solid pencils and fill icons are filled paths.
- `glyphs.json` the same path data as one object, ready to inline.
- `trace.py` the tracing pipeline (skeletonize for outlines, potrace for solids).

Naming: `rectA*`/`rectB*` CTA buttons, `frameL*` landscape canvas frames, `frameP*`/`frameT1` portrait reveal frames, `circ*` swatch circles, `penO*` outline pencils, `penF*` solid pencils, `fill*` fill icons.
