# Exquisite Corpse: UX Spec for the Native iOS Port

This is the behavior of the web app (`index.html` at the repo root) written out so it can be rebuilt in SwiftUI without reading JavaScript. Where this doc and `index.html` disagree, `index.html` wins. Read the JS to settle a question, but do not port its structure. Port the experience.

All sizes are in points unless noted. "Phone" is any screen narrower than 768pt. "iPad" is 768pt or wider. Values are written `phone / iPad`.

## Look and feel

- Everything is black on white. Black is `#1a1a1a`, white is `#ffffff`, grey text is `#888`, light grey borders are `#ddd` and `#ccc`.
- Font: **Space Mono** (Regular and Bold), bundled with the app. All text is lowercase. No system font anywhere.
- No animation, no transitions between screens, no haptics, no sound. Screens cut from one to the next.
- No dark mode. The app is always white.
- Text cannot be selected. Long press does nothing. Pinch does nothing.
- Portrait only on iPhone. All orientations on iPad.
- No status bar hiding; the status bar is dark text on white.

## Buttons

Every button is the same component:

- Rectangle, 2pt black border, square corners, white background, black text in Space Mono.
- 16pt horizontal padding when width is "auto"; otherwise a fixed width.
- On tap: background goes black and text goes white for 30 ms, then returns. That is the whole press feedback.
- Disabled buttons are 40% opacity and do nothing. (Nothing in the app is currently disabled; keep the ability.)

## Canvas model

- Logical canvas: **600 x 420** units. Aspect ratio 10:7. Every coordinate, stroke width, and the guide strip are in these units.
- Render the bitmap at a scale factor (2x is a good default, so 1200 x 840 pixels) but keep all logic in the 600 x 420 space. One constant.
- **Guide strip**: the bottom **25** units of the previous player's section, shown at the top of the next player's canvas.
- Palette, 10 colors in this order:
  `#1a1a1a`, `#EE0028`, `#FF7A00`, `#FFD900`, `#00B053`, `#0057D9`, `#6A1FB0`, `#8B5E34`, `#F0157F`, `#FFFFFF`
- Pen sizes, 3 options: **3, 8, 18** units. Default is 8.
- Default state on every new section: tool pen, color black, size 8.
- Strokes are polylines with round caps and round joins, drawn in the stroke's color and width. The eraser is a stroke in pure white.
- Fill (paint bucket) is a flood fill on the bitmap pixels.

## Operations and undo

The canvas keeps an ordered list of operations. Each is either a stroke (points, color, width, eraser flag) or a fill (x, y, color). The bitmap is the rendered result.

- Drawing a stroke draws each new segment live onto the bitmap as the finger moves. On finger up, the stroke is appended to the list if it has at least 2 points. Otherwise it is discarded (a tap draws nothing).
- A fill applies immediately to the bitmap. It is appended to the list only if it changed at least one pixel.
- **Undo** removes the last operation, then rebuilds the bitmap from scratch: white, then the guide strip, then every remaining operation in order. Fills replay against the bitmap as it is at that point in the sequence, so order matters.
- Undo with an empty list does nothing. There is no redo.

## Touch handling

- One finger at a time. While a finger is down, any second finger is ignored completely: it does not draw and does not interrupt the first.
- Touch position maps to canvas units by the ratio of canvas size to the displayed size.
- Touch down anywhere on the canvas clears the "sure?" state on the done button.
- Finger leaving the canvas bounds ends the stroke, same as lifting.
- Touch cancel (a phone call, etc.) ends the stroke, same as lifting.

## Flood fill

Port this exactly; it defines how fill feels.

- Input: a point in canvas units, and a fill color.
- Round the point to a pixel. If it is off-canvas, do nothing.
- Read the target color at that pixel. If it equals the fill color exactly, do nothing.
- A pixel "matches" if the squared RGB distance from the target color is at most `48 * 48 * 3` (that is, roughly within 83 in Euclidean RGB). Alpha is ignored.
- Scanline fill, 4-connected: for each seed, walk left and right along the row while pixels match, paint the run, and for each painted pixel push the pixel above and below if they match and have not been seen.
- Set painted pixels to the fill color with full alpha.
- Returns whether anything changed.

The tolerance is what makes filling next to anti-aliased stroke edges work without leaving halos. Do not "improve" it.

## Tools, and the rules between them

State: `tool` is one of pen, eraser, fill. `color` is one of the palette colors. `size` is one of the three sizes.

**Swatch row.** 10 circles.

- Tap a non-white swatch: set color to it. If the tool was eraser, switch to pen. Fill stays fill.
- Tap the white swatch when tool is not fill: switch to eraser. Color is left alone.
- Tap the white swatch when tool is fill: set color to white (so you fill with white). Tool stays fill.
- Selection ring rules:
  - White swatch shows selected when tool is eraser, or when tool is fill and color is white.
  - Any other swatch shows selected when tool is not eraser and color equals it.
  - Selected ring: 3pt border, inset (drawn inside the circle), black. On the black swatch the ring is `#ccc` instead so it is visible.
  - Unselected white swatch: 2pt `#ccc` border. Unselected others: no visible border (3pt transparent, so the circle does not change size).

**Size row.** 3 square buttons with pencil icons, then a gap, then the fill button.

- Tap a size: set size. If tool was fill, leave fill: become eraser if color is white, else pen.
- A size button shows selected (2.5pt black border) when it is the current size AND tool is not fill. Otherwise 1.5pt `#ddd` border. So while fill is active no size looks selected; while eraser is active the size still shows selected.
- Tap the fill button: if tool is fill, leave it (eraser if color is white, else pen). Otherwise become fill.
- Fill button shows selected (2.5pt black) when tool is fill, else 1.5pt `#ddd`.
- Every tap in these rows clears the done button's "sure?" state.

**Pencil icons.** Three pencils at 45 degrees, one per size, with a thicker body for the bigger size. Body is black with a small white collar band near the tip. Half-widths are 2.6, 3.8, and 5.0 in a 24-unit icon box. Rebuild with `Path` from the JS `pencilPath` function; the numbers are in `index.html`. The fill icon is a black diamond with a white triangle cutout and a small black drop to the lower right. Port its three paths too.

## Screens and flow

Four screens: **landing**, **drawing**, **transition**, **reveal**. One game has three sections drawn in order: head, body, legs.

```
landing --play--> drawing(head) --done,done--> transition(body) --ready--> drawing(body)
  --done,done--> transition(legs) --ready--> drawing(legs) --done,done--> reveal
reveal --home,home--> landing
```

Sections are stored as three images. New game clears all three.

### Landing

Centered column, vertical gap `32 / 44`:

1. Horizontal squiggle, `200x60 / 300x80`. Path in a 200x60 box: `M 8,30 C 18,5 28,55 42,20 C 56,-15 62,65 80,30 C 98,-5 104,60 122,25 C 136,-5 148,58 162,32 C 172,14 180,48 192,30`, black, 3 wide, round caps, no fill.
2. Title "exquisite" line break "corpse", Space Mono, `48 / 68`, line height 1.1, centered.
3. Same squiggle again.
4. Button "play", `200x56 / 260x66`, font `22 / 28`.

Content column max width `440 / 680`, side padding `16 / 24`.

### Drawing

Full-height column, no scrolling.

1. Header: turn label "draw the head" / "draw the body" / "draw the legs", font `20 / 28`, centered, padding top `10 / 14`, bottom `14 / 18`.
2. Canvas: full width up to `440 / 680`, capped at `40% / 50%` of the screen height, keeping the 10:7 aspect. 2pt black border, 4pt corner radius. Side padding `12 / 24`.
3. Controls area fills the rest of the height and centers its content vertically. Padding `20 16 24 / 24 24 28`. Internal gap `20 / 24`. Max width `440 / 680`.
   - Swatch row: circles `42 / 58` wide, gap `10 / 14`, wrapping, centered, row max width `270 / 400`. That gives two rows of five on both.
   - Size row: buttons `48 / 62` square, corner radius 4, gap `12 / 16`; icons inside are `27 / 34`. Fill button has an extra `6 / 8` left margin.
   - Bottom row: "undo" and "done" side by side, equal widths filling the row, gap `12 / 16`, height `50 / 60`, font `18 / 22`.

**Done button**: first tap changes its label to "sure?". Second tap captures the section. Any other interaction (touching the canvas, tapping a swatch, size, fill, or undo) puts the label back to "done". After the head or body, go to transition. After the legs, go to reveal.

**Capture**: the section image is the full 600 x 420 bitmap including the guide strip and all operations.

**Starting a section**: bitmap goes white. If this is section 2 or 3, the bottom 25 units of the previous section are copied to the top 25 units of the new bitmap and become the guide layer (it sits under all operations and survives undo). Operations list is emptied, tool is pen, color black, size 8, done label is "done".

### Transition

Centered column, gap `20 / 28`:

1. Vertical squiggle, `60x200 / 80x280`. Path in a 60x200 box: `M 30,8 C 5,18 55,28 20,42 C -15,56 65,62 30,80 C -5,98 60,104 25,122 C -5,136 58,148 32,162 C 14,172 48,180 30,192`, black, 3 wide, round caps. Pull it up 4pt so it sits tighter to the title.
2. Title "pass the device", `36 / 48`.
3. Subtitle "next player draws the body" or "next player draws the legs", `19 / 24`, grey `#888`.
4. Button "ready", `180x52 / 240x62`, font `22 / 24`.

### Reveal

Column, top aligned, padding 16 top and bottom, scrolls if needed (it should not need to at these sizes).

1. Title "behold!", `34 / 46`.
2. The composite image, max width `300 / 440`, max height `screen height minus 155 / 195`, 2pt black border, 4pt corner radius, top margin `10 / 16`.
3. Button row, gap `10 / 14`, top margin `14 / 20`, height `42 / 52`, font `14 / 18`, centered:
   - "save": opens the share sheet with the padded composite. Also clears "sure?" on home.
   - "home": first tap shows "sure?", second tap goes to landing. The button keeps one fixed width (wide enough for "sure?") so it does not jump.

### Composite

- Width 600. Height `420 * 3 - 25 * 2 = 1210`. White background.
- Section i is drawn at y = `i * (420 - 25)`, so 0, 395, 790. Each section's guide strip lands exactly on the previous section's bottom strip.
- For saving, pad 50 units of white on all sides: 700 x 1310. This padded version is what goes to the share sheet, as a PNG named `exquisite-corpse.png`, with the title "Exquisite Corpse".
- The on-screen reveal shows the unpadded composite.

Export at the bitmap scale factor (so 1400 x 2620 pixels at 2x). Nothing in the app needs the exact pixel count; the aspect and layout do.

## Things that are not features

Do not add these unless Jesse asks. The point of the port is the same experience, not a bigger one.

- Redo, save game, resume, gallery, more colors, brush opacity, zoom, text, stickers, sharing to a specific app, multiplayer over network, Apple Pencil pressure, settings, onboarding, sounds.

Reasonable native touches that do not change the experience, and are fine: launch screen in plain white, correct safe areas, app icon, and the share sheet being the real iOS one.
