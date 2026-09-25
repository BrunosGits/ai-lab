# Entity Rendering — File:Line Index

> Paths relative to repo root (`~/CorsixTH`). Ranges are the narrowest verified span.

## C++ core: `CorsixTH/Src/th_gfx.h`

| Line(s) | Symbol | Notes |
|---|---|---|
| 50–91 | `enum draw_flags` | All blit flags incl. `early_list`, `crop`, `nearest`. |
| 106–134 | `struct drawable` | `draw_fn` 113, `hit_test_fn` 120, `is_multiple_frame` 125, layer get/set 127–128. |
| 187–191 | `max_number_of_layers`, `struct layers` | 13 anim layers. |
| 195–215 | `animation_key`, `animation_start_frames` | Custom-anim lookup key. |
| 234–353 | `class animation_manager` | `set_sprite_sheet` 238, `load_from_th_file` 253, `set_canvas` 263, `load_custom` 271, counts 274–277, `get_first_frame` 280, `get_next_frame` 289, alt-pal 299, `draw_frame` 325, extent 330, sound 333, hit-test 335, markers 338–341, named 349, `tick` 353. |
| 356–386 | `frame` struct | `list_index/next_frame/sound/flags`, bounds, primary/secondary markers. |
| 387–402 | `element` struct | `sprite/flags/x/y/layer/layer_id/sheet`. |
| 418 | `game_ticks` | Global effect clock. |
| 465–506 | `class animation_base` | `attach_to_tile` 470, `set_layer` 482, `tile/pixel_offset/layers/scale_factor` 487–506. |
| 508–510 | `enum animation_kind` | `primary_child/secondary_child/normal/morph`. |
| 510–587 | `class animation` | `tick` 516, `draw` fns 517–520, `draw_fn` switch 522, `is_multiple_frame` 556–560. |
| 611–662 | `class sprite_render_list` | `tick/draw/append/lifetime`, `is_multiple_frame=false` 640. |

## C++ core: `CorsixTH/Src/th_gfx.cpp`

| Line(s) | Symbol |
|---|---|
| 188–260 | `load_from_th_file` (START/FRAME/LIST/ELE parse). |
| 498–560 | `load_custom_animations`. |
| 761–776 | `get_first_frame` 761, `get_next_frame` 769. |
| 777–800 | `set_animation_alt_palette_map` (ghost install). |
| 848 | `animation_manager::tick` (`++game_ticks`). |
| 850–917 | `animation_manager::hit_test`. |
| 919–989 | `animation_manager::draw_frame` (layer filter + flip + effect). |
| 990–996 | `get_frame_sound`. |
| 1143–1176 | `animation_base` ctor 1143, `remove_from_tile` 1145, `attach_to_tile` 1150–1176 (early-list branch 1154, sorted insert 1163). |
| 1178–1182 | `set_layer`. |
| 1192–1218 | `animation` ctor 1192 (`rand` offset), `draw` 1194 (alpha-skip, deferred sound, crop clip). |
| 1220–1246 | `draw_child` (marker-anchored). |
| 1248–1290 | `draw_morph` (two-clip splice). |
| 1567–1591 | `animation::tick` (next frame, speed integrate, morph slide, sound latch). |
| 1592–1618 | `set_parent` 1592, `set_animation` 1608. |
| 1678–1728 | `set_morph_target` (extent/duration math). |
| 1729 | `set_frame`. |
| 1731–1795 | `sprite_render_list::tick` 1731, `draw` 1739, `set_lifetime` 1779, `append_sprite` 1790. |

## Bindings: `CorsixTH/Src/th_lua_anims.cpp`

| Line(s) | Binding |
|---|---|
| 41–69 | `anims` new 41, `setSheet` 46, `setCanvas` 60. |
| 70–113 | `load` 70, `loadCustom` 94, `getAnimations` 114. |
| 144–159 | `getFirstFrame` 144, `getNextFrame` 152. |
| 160–179 | `setAnimationGhostPalette` 160. |
| 180–207 | markers 180/197, `tick` 191. |
| 208–223 | `anims:draw` 208 (direct frame blit). |
| 330–379 | `anim:setAnimation` 330, `setMorph` 353, `getAnimation` 370. |
| 380–431 | `setTile` 380, `getTile` 411. |
| 432–449 | `setParent` 432. |
| 450–509 | `setFlag` 450, `setPartialFlag` 459, vis 472/482/492, `getFlag` 502. |
| 510–560 | `setPosition` 510, `setSpeed` 532, `setLayer` 544, `setLayersFrom` 554. |
| 601–635 | `anim:tick` 601, `anim:draw` 609, patient-effect 620, scale 630. |
| 636–674 | spriteList: `setSheet` 636, `append` 646, `setLifetime` 655, `isDead` 668. |

## Map: `CorsixTH/Src/th_map.h` / `th_map.cpp` / `th_lua_map.cpp`

| File:line | Symbol |
|---|---|
| `th_map.h:187–193` | `enum tile_layer` (ground/north/west/ui). |
| `th_map.h:196–214` | `map_tile`: `entities` 201, `oEarlyEntities` 204, `tile_layers` 214. |
| `th_map.h:360–371` | `draw` 360, `hit_test` 371. |
| `th_map.h:407–423` | `draw_floor` 407, `draw_north_wall` 409, `draw_layer` 412, `layer_exists` 421. |
| `th_map.cpp:954–963` | `layer_exists` 954. |
| `th_map.cpp:964–990` | `draw_floor` (+shadow 74/75). |
| `th_map.cpp:991–1016` | `draw_north_wall` (+shadow 156 clip). |
| `th_map.cpp:1018–1028` | `draw_layer`. |
| `th_map.cpp:1030–1214` | `draw` (two-pass comment 1033–1052, floor 1067, early pass 1077–1091, late pass 1093–1214). |
| `th_map.cpp:1216–1280` | `hit_test` 1216 (reverse order), `hit_test_drawables` 1258. |
| `th_lua_map.cpp:836–852` | `map:draw` 836; `hitTestObjects` 853. |

## Lua: `CorsixTH/Lua/`

| File:line | Symbol |
|---|---|
| `utility.lua:217–225` | `DrawFlags` mirror of C++ bits. |
| `utility.lua:230–242` | `DrawingLayers` 0–9. |
| `entity.lua:99–114` | `setAnimation`; `116–129` `setTile` (→`th:setTile` + drawing layer). |
| `entity.lua:192–206` | `_tick` 192, `tick` 206 (slow-anim skip, mood, timer). |
| `entity.lua:244–258` | `setLayer`; `378–379` `getDrawingLayer` (=4). |
| `world.lua:913–988` | `onTick` 913; `anims:tick` 962; `entity:tick` 977. |
| `game_ui.lua:251–273` | `GameUI:draw` 251; `map:draw` 263/267; simulated cursor 271–272. |
| `graphics.lua:279–306` | `makeGreyscaleGhost` 279; `_loadPalette` 318; `loadGhost` 358. |
| `dialogs/place_staff.lua:48–50,127–138` | ghost install 50; `draw` 127 + validity flag 130. |
| `dialogs/place_objects.lua:382–389,596–612` | ghost per idle anim; `draw` 596 + `object_anim:draw` 609. |
| `dialogs/edit_room.lua:35–40` | wall/door/window blueprints → Ghost1.dat:6 + BlueRedSwap. |

## Misc C++

| File:line | Symbol |
|---|---|
| `th_gfx_common.h:30–38` | `animation_effect` (none/glowing/jelly). |
| `th_gfx_sdl.h:720–740` | `class cursor`. |
| `th_lua_gfx.cpp:733–770` | `cursor` new/load/use/setPosition; registered 1204–1208. |
