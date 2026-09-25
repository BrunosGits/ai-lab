# World-to-Screen — Coordinate Spec

## 1. Tile geometry

- Diamond 64×32 px: step E/W = ±64 x; step N/S = ±32 x combined with ±16 y.
- Cell anchor = top corner of diamond; sprite blit at `(tile_x-32, tile_y-h+32)`.
- C++ is 0-based; Lua `Map` is 1-based (subtract 1 at `th_lua_map.cpp:439-452`).

## 2. Transforms

C++ (`th_map.h:386-399`), `T` generic (int or float):

```
sx = 32*(x - y)
sy = 16*(x + y)
x  = sy/32 + sx/64
y  = sy/32 - sx/64
```

Lua (`map.lua:117-143`), 1-based with origin shift and clamp:

```
sx, sy = 32*(x-y), 16*(x+y-2)
y = sy/32 + 1; x = sx/64
tx, ty = y+x, y-x; clamp to [1,width]×[1,height]
```

GameUI (`game_ui.lua:423-434,1402-1404`), `z = zoom_factor × displayScale`:

```
world = map.ScreenToWorld(offset_x + scr_x/z, offset_y + scr_y/z)
scr   = (map.WorldToScreen(w) - offset) × z
```

Scroll (`game_ui.lua:1009-1018`): `offset += delta`, clamped to
`visible_diamond` (`game_ui.lua:187-199`); zoom preserves cursor/world anchor
(`game_ui.lua:223-249`).

## 3. Layer packing + draw-flag bits

`tile_layers[i]` uint16 (`th_map.h:200-214`): low byte = block index,
high byte = `draw_flags` (`th_gfx.h:53-91`).

| Bits | Name | Effect |
|------|------|--------|
| 1<<0 | `flip_horizontal` | mirror X |
| 1<<1 | `flip_vertical` | mirror Y |
| 1<<2 | `alpha_50` | 50% (with 75% = skip) |
| 1<<3 | `alpha_75` | 75% (shadows 74/75/156) |
| 1<<4 | `alt_palette` | remap |
| 5–7 | `alt32_*` | plain/grey/swap |
| 1<<10 | `early_list` | right-to-left pass |
| 1<<12 | `bound_box_hit_test` | bbox vs pixel-perfect |
| 1<<13 | `crop` | pre-crop |
| 1<<14 | `nearest` | map tiles always set |

`set_all_wall_draw_flags(f)` (`th_map.cpp:943-951`) = `f<<8` OR into N/W
layers; Lua transparent walls passes `4` (= `alpha_50`) or `0`.

## 4. Map-flag bits (`th_map.h:118-155`)

`1<<0` passable, `1<<1-4` travel N/E/S/W, `1<<5` hospital, `1<<6` buildable,
`1<<7` blueprint-passable, `1<<8` room, `1<<9/10/11` shadow half/full/wall
(blocks 75/74/156), `1<<12/13` door N/W, `1<<14` no-idle, `1<<15/16` tall N/W,
`1<<17-20` buildable N/E/S/W, `1<<21` avoid.

## 5. Overlay sprite ids

Flags overlay (`th_map_overlays.cpp:94-140`): 3 passable, 8 hospital,
9 buildable, 4–7 travel N/E/S/W, plus `T<thob>` / `R<room>` text.
Parcels (`:153-177`): edges N/E/S/W = 18/19/20/21 + parcel-id text.

## Related Pages

- [[world-to-screen/SUMMARY]] · [[world-to-screen/CLASS_DIAGRAM]] · [[world-to-screen/MAP]] · [[world-to-screen/SEQUENCE_DIAGRAM]]
