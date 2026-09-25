# Entity Rendering — Spec

## 1. Tile layer order (map)

| Pass | Direction | What | Source |
|---|---|---|---|
| 1 | L→R per tile | floor (`tile_layers[0]`) then shadow 74/75 | `draw_floor` |
| 2a | R→L per scanline | north wall (`[1]`, +shadow 156 clip) then `oEarlyEntities` | `draw` + `draw_north_wall` |
| 2b | L→R per scanline | west wall (`[2]`), UI (`[3]`), then `entities` ascending `drawing_layer` | `draw` + `draw_layer` |
| fixup | — | if multi-frame anim seen, repaint layer-9 (left tile) / layer-8 (above) + prev north wall | `draw` redraw block |
| overlay | — | `overlay->draw_cell` if active | `draw` tail |

`tile_layers[i]`: low byte = sprite idx, high byte = flags OR `thdf_nearest`.

## 2. In-tile entity order (`DrawingLayers`)

| Value | Use |
|---|---|
| 0 | Litter / Door / RatHole |
| 1 | NorthSideObject |
| 2 | WestSideObject |
| 3 | AtomAnalyser / ReceptionistFacingUser |
| 4 | Entity (default) |
| 5 | ReceptionistFacingAway |
| 6 | MachineSmoke |
| 7 | FloatingDollars |
| 8 | EastSideObject |
| 9 | SouthSideObject |

Sorted insert in `attach_to_tile`; `thdf_early_list` selects early list instead.

## 3. Animation frame format (in-memory)

- `first_frames[anim]` → first `frame`; `frame.next_frame` loops (last→first fixed at load).
- `frame`: `list_index` into `element_list`; `sound` (0=none); `flags` (bit0=start); `bounding_*`; `primary/secondary_marker_{x,y}`.
- `element_list`: `uint16` element indices terminated by `>= element_count` sentinel.
- `element`: `sprite`, `flags`, `x/y` offsets, `layer` (0–12), `layer_id` (0=always), `element_sprite_sheet*`.
- `draw_frame`: skip if `layer_id!=0 && layers[layer]!=layer_id` (one doctor-layer hack excepted); 8bpp palette or 32bpp alt path; flip recomputes `x`; effect only if `layer>0 || layer_id>0`.

## 4. Draw-flag bits

| Bit | C++ | Lua | Meaning |
|---|---|---|---|
| 0 | `flip_horizontal` | `FlipHorizontal` | mirror X |
| 1 | `flip_vertical` | `FlipVertical` | mirror Y |
| 2+3 | `alpha_50/75` | `Alpha50/75` | both set = invisible + no hit-test |
| 4 | `alt_palette` (16) | `AltPalette` | ghost remap; validity toggle in placement previews |
| 5–7 | `alt32_{plain,grey,blue_red}` | `Alt32_*` consts | 32bpp ghost style |
| 10 | `early_list` (1024) | `EarlyList` | attach to `oEarlyEntities` |
| 12 | `bound_box_hit_test` | `BoundBoxHitTest` | skip pixel-perfect test |
| 13 | `crop` | `Crop` | 64px column clip (`crop_column`) |
| 14 | `nearest` | `Nearest` | nearest-neighbour scale |

## 5. Ghost / cursor contract

- Ghost: `loadGhost(dir,name,idx)` slices 256B from file; `setAnimationGhostPalette(anim,map,alt32)` stamps every element sprite of that anim; instance flag 16 turns it on. Wall blueprint = Ghost1.dat:6 + BlueRedSwap; staff/object preview = MPalette grey ghost + GreyScale.
- Cursor: `cursor::create_from_sprite/use/set_position/draw`; Lua `TH.cursor`; `GameUI:draw` paints map → windows → tooltip → simulated cursor last.
