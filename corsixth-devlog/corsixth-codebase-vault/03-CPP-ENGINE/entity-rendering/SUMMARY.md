# Entity Drawing Pipeline — Summary

> C++ engine deep dive: animation manager → per-frame advance → layered map draw → Lua draw calls → cursor/ghost.

## 1. Overview

- **[Fact]** `animation_manager` (owns frames/elements/lists) decodes TH `START/FRAME/LIST/ELE` data and draws single frames via `draw_frame`. `animation` (one live instance) holds `manager + animation_index + frame_index + tile + pixel_offset + layers + flags`. Per-tick Lua drives `World:onTick → anims:tick + Entity:tick → th:tick`.
- **[Fact]** Map draw is two-pass per scanline: pass 1 = floor + shadows; pass 2 = north-wall + early entities (right-to-left), then west-wall + UI layer + late entities (left-to-right). Entities are `drawable` linked lists on each `map_tile`, sorted by `drawing_layer`.
- **[Fact]** Lua draws two ways: (a) attached entities drawn implicitly by `map:draw`; (b) unattached previews (`UIPlaceStaff`, `UIPlaceObjects`) call `anim:draw(canvas,x,y)` directly. Cursor is separate: SDL `cursor` object + `GameUI` simulated-cursor path.
- See [[entity-rendering/MAP]] for every file:line, [[entity-rendering/CLASS_DIAGRAM]] for types, [[entity-rendering/SEQUENCE_DIAGRAM]] for tick→draw, [[entity-rendering/SPEC]] for layers/flags/frame format.

## 2. Architecture

```
Lua (entity.lua / world.lua / game_ui.lua / place_*.lua)
  │ setAnimation / setTile / setLayer / tick / draw
  ▼
th_lua_anims.cpp bindings (anims / animation / spriteList)
  │  th_gfx.h: animation_manager / animation / animation_base / sprite_render_list
  ▼
th_gfx.cpp: tick (advance) + draw_frame (layer-filtered blit)
  │  drawable::draw_fn virtual dispatch
  ▼
th_map.cpp level_map::draw: floor → walls → entity lists
  │  th_gfx_sdl.h render_target / sprite_sheet / cursor
  ▼
screen (GameUI:draw → map:draw → Window → tooltip → cursor)
```

## 3. Key classes / flows

| Piece | Role |
|---|---|
| `animation_manager` | Frame store + `draw_frame`, `tick` (global `game_ticks`), ghost-palette map. |
| `animation` | Live entity anim: `tick()` = `frame=get_next_frame`, `offset+=speed`, latch `sound_to_play`; `draw/draw_child/draw_morph` → `draw_frame`. |
| `animation_base` | Tile attachment (`attach_to_tile`), `layers[13]`, `flags`, `pixel_offset`, `scale_factor`. |
| `sprite_render_list` | Lightweight sprite bag (floating text/moods): `tick` moves+fades, `draw` blits list. Not multi-frame. |
| `level_map` | Owns `map_tile` grid; `draw_floor / draw_north_wall / draw_layer / draw`; reverse-order `hit_test`. |
| `cursor` | SDL cursor bitmap; Lua `TH.cursor` new/load/use/setPosition; `GameUI` draws simulated cursor last. |
| Ghost | Not a class: `setAnimationGhostPalette(anim,256B,grey/blue-red)` + `thdf_alt_palette` flag on the instance. |

## 4. Per-frame advance — **[Fact]**

`World:onTick` calls `self.anims:tick()` once per game-hour iteration, then `entity:tick()` for each entity. `Entity:_tick` calls `self.th:tick()` (skipped every other tick if `slow_animation`). C++ `animation::tick` advances exactly one frame link and integrates speed; sound is deferred to next `draw`.

## 5. Draw order / layers — **[Fact]**, one **[Inference]**

Floor (tile layer 0) always first; walls/entity interleave per scanline. In-tile entity order = ascending `drawing_layer` (Lua `DrawingLayers` 0–9). `thdf_early_list` routes to `oEarlyEntities` (north-wall pass). **[Inference]** `drawing_layer` 8/9 redraw hack exists to repaint side objects overlapping a walking multi-frame anim.

## 6. Cursor / ghost — **[Fact]** + **[Hypothesis]**

- Ghost preview = grey/blue-red remap installed per-animation id + flag 16 (`AltPalette`) toggled by validity (e.g. `UIPlaceStaff:draw`). Wall blueprints use Ghost1.dat slot 6 + blue-red swap.
- Cursor = hardware SDL cursor normally; `simulated_cursor.draw` overlay only when set. **[Hypothesis]** simulated path is for remote/screenshot cursors, not the normal in-game cursor — needs a runtime check to confirm.
