# World-to-Screen — File:Line Index

> Repo-relative paths. All ranges read via `ssh vps`.

## CorsixTH/Src/th_map.h

| Line(s) | Symbol | Claim |
|---------|--------|-------|
| 118–141 | `map_tile_flags::key` | bit ids `passable 1<<0` … `avoid 1<<21` |
| 153–155 | `shadow_half/full/wall` | render blocks 75/74/156 |
| 187–193 | `tile_layer` | `ground 0, north 1, west 2, ui 3` |
| 200–214 | `tile_layers[4]` | low byte sprite, high byte draw flags; Lua 1–4 |
| 360–362 | `level_map::draw` | world-px rect → canvas rect |
| 371 | `hit_test` | reverse-order hit test entry |
| 386–391 | `world_to_screen` | `sx=32(x-y), sy=16(x+y)` |
| 394–399 | `screen_to_world` | `x=sy/32+sx/64, y=sy/32-sx/64` |
| 407–414 | `draw_floor/north_wall/draw_layer` | private pass helpers |
| 479–482 | scanline direction | `forward=2, backward=0` |
| 495–547 | `map_tile_iterator` | ctor args, accessors, `is_last_on_scanline` |
| 554–558 | `margin_*` | 150/110/110/150 overdraw margins |
| 579 | `advance_until_visible` | culling core |
| 583–610 | `map_scanline_iterator` | re-iterate scanline L→R or R→L |

## CorsixTH/Src/th_map.cpp

| Line(s) | Symbol | Claim |
|---------|--------|-------|
| 273–278 | `set_overlay` | ownership swap |
| 943–951 | `set_all_wall_draw_flags` | `iFlags<<8` OR into N/W layers |
| 964–990 | `draw_floor` | floor + shadow 74/75, anchor `-32, -h+32` |
| 991–1008 | `draw_north_wall` | N-wall + clipped shadow 156 |
| 1018–1028 | `draw_layer` | generic layer blit, returns height |
| 1030–1062 | `draw` comment+clip | two-pass order + `scoped_clip` |
| 1067–1212 | `draw` body | floor pass, R→L N-wall/early, L→R W-wall/late, layers 8/9 repair |
| 1204–1212 | overlay loop | one `draw_cell` per visible tile |
| 1214–1256 | `hit_test` | backward scanline, entities then early |
| 1749–1775 | iterator ctor | `base_y=(sy-32)/16` seed |
| 1777–1840 | `operator++/advance` | diagonal step, margin cull |
| 1842–1846 | `is_last_on_scanline` | scanline-end predicate |
| 1856–1880 | scanline ctor | `tile_step/x_step` from direction |

## CorsixTH/Src/th_map_overlays.h / .cpp

| Line(s) | Symbol | Claim |
|---------|--------|-------|
| .h 35–41 | `map_overlay` | `draw_cell` interface |
| .h 43–56 | `map_overlay_pair` | first+second fan-out |
| .h 58–78 | `map_typical_overlay` | sprites+font, `draw_text` |
| .h 80–99 | `map_text_overlay` | background + `get_text` |
| .cpp 56–66 | pair `draw_cell` | calls first then second |
| .cpp 71–79 | text `draw_cell` | bg sprite + centred text |
| .cpp 82–87 | positions | `"<x+1>,<y+1>"` |
| .cpp 94–140 | flags | sprites 3/8/9/4-7, `T/R` text |
| .cpp 153–154 | `parcel_edges` | N/E/S/W → sprites 18/19/20/21 |
| .cpp 158–177 | parcels | id text + edge sprites |
| .cpp 179–184 | `draw_text` | centre in 64×32 cell |

## CorsixTH/Src/th_lua_map.cpp, th_gfx.h, th_gfx_sdl.cpp

| Line(s) | Symbol | Claim |
|---------|--------|-------|
| th_lua_map.cpp 426–437 | `getCameraTile` | 0-based→1-based return |
| th_lua_map.cpp 439–452 | `setCameraTile` | 1-based→0-based store |
| th_lua_map.cpp 716–720 | `setwallflags` | → `set_all_wall_draw_flags` |
| th_lua_map.cpp 836–850 | `l_map_draw` | `(canvas,sx,sy,sw,sh,dx,dy)` → `draw` |
| th_lua_map.cpp 853–867 | `l_map_hittest` | → `hit_test` |
| th_lua_map.cpp 1121–1143 | bindings | `draw/setSheet/hitTestObjects/…` |
| th_gfx.h 53–91 | `draw_flags` | flip/alpha/alt/early/crop/nearest bits |
| th_gfx_sdl.cpp 1369–1373 | `draw_sprite` | final blit entry |

## CorsixTH/Lua/map.lua, game_ui.lua

| Line(s) | Symbol | Claim |
|---------|--------|-------|
| map.lua 78–80 | `setCameraTile` | → `th:setCameraTile` |
| map.lua 117–124 | `WorldToScreen` | `32(x-y), 16(x+y-2)` 1-based |
| map.lua 127–143 | `ScreenToWorld` | inverse + clamp to size |
| map.lua 678–716 | `_drawDebugTiles` | Lua debug overlay (alt path) |
| map.lua 727–730 | `Map:draw` | → `th:draw`, then debug tiles |
| game_ui.lua 50–98 | `GameUI:GameUI` | camera-tile centre + `scrollMap` |
| game_ui.lua 187–199 | `makeVisibleDiamond` | scroll clamp diamond |
| game_ui.lua 223–249 | `setZoom` | anchor-preserving zoom |
| game_ui.lua 251–274 | `GameUI:draw` | shake + `scale(zoom)` + `map:draw` |
| game_ui.lua 423–434 | `Screen/WorldToScreen` | offset ± zoom wrappers |
| game_ui.lua 447–451 | cursor hit test | `hitTestObjects` on world-px |
| game_ui.lua 1009–1018 | `scrollMap` | offset += delta, diamond clamp |
| game_ui.lua 1042–1053 | transparency | `setWallDrawFlags(4 or 0)` |
| game_ui.lua 1402–1404 | `getEffectiveZoom` | `zoom_factor × displayScale` |

## Related Pages

- [[world-to-screen/SUMMARY]] · [[world-to-screen/CLASS_DIAGRAM]] · [[world-to-screen/SEQUENCE_DIAGRAM]] · [[world-to-screen/SPEC]]
