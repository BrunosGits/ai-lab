# World-to-Screen Pipeline — Technical Reference

> **CorsixTH C++ Engine — camera, iso projection, tile draw, overlays**
> Sources: `CorsixTH/Src/th_map.h/.cpp`, `th_map_overlays.h/.cpp`, `CorsixTH/Lua/map.lua`, `game_ui.lua`

## 1. Overview

**[Fact]** `level_map` owns tiles and draws a world-pixel viewport to a canvas.
Lua `GameUI` owns the camera (`screen_offset_x/y`, `zoom_factor`) and calls
`Map:draw` → `level_map::draw` every frame. There is no dirty-rect list
(negative grep for `dirty` in `th_map.*`, `th_gfx*`, `map.lua`, `game_ui.lua`).

Coordinate spaces in play:

| Space | Unit | Origin |
|-------|------|--------|
| World/map | tiles (float; int part = cell) | C++ 0-based; Lua 1-based |
| Absolute/world-pixel | px, unscaled iso projection | map origin `(0,0)` tile corner |
| Screen/relative | px, zoomed | GameUI viewport top-left |

## 2. Key classes

| Type | Role |
|------|------|
| `level_map` | tile store (`cells`), `draw`, `hit_test`, `world_to_screen` |
| `map_tile` | 4 `tile_layers` + flags + parcel/room + entity lists |
| `map_tile_iterator` / `map_scanline_iterator` | visible-tile scanline iteration with margins |
| `map_overlay*` | debug per-cell painter (`positions`/`flags`/`parcels`) |
| Lua `Map` | 1-based wrapper, `WorldToScreen`/`ScreenToWorld`, `draw` |
| Lua `GameUI` | `screen_offset_*` scroll, `zoom_factor`, `visible_diamond` clamp |

## 3. Camera → render flow

**[Fact]** `GameUI:GameUI` centres the camera tile then `scrollMap(-wwz/2, …)`.
`scrollMap` adds the delta and clamps to `visible_diamond`.
`GameUI:draw` adds quake shake, applies `canvas:scale(zoom)`, then
`Map:draw(canvas, dx, dy, w/zoom, h/zoom, 0, 0)` so C++ sees unscaled
world-pixels. **[Inference]** Zoom is an SDL render-target scale, not C++ math —
C++ only ever sees pre-divided `iScreenX/Y/W/H`.

## 4. C++ two-pass draw

**[Fact]** `level_map::draw` comment block states the passes explicitly:
pass 1 = floors + floor shadows left-to-right; pass 2a = north walls +
`oEarlyEntities` right-to-left; pass 2b = west walls + `ui` layer + `entities`
left-to-right, with layer-8/9 overdraw repair of the previous tile.
`draw_floor` anchors sprites at `tile_x-32, tile_y-height+32` with
`thdf_nearest`; shadows are blocks 74/75/156. Overlay (if set) paints last,
one `draw_cell` per visible tile.

## 5. Hit testing

**[Fact]** `level_map::hit_test` repaints the same scanline order reversed
(own comment), testing `entities` then `oEarlyEntities` back-to-front via
`hit_test_drawables`. Lua cursor path uses `map.th:hitTestObjects(x, y)` on
unscaled world-pixels.

## 6. Status labels

- **[Fact]**: transform formulas, pass order, class members, Lua/C++ call chain.
- **[Inference]**: full-redraw-per-frame (no retained regions); margin sizes are
  perf/correctness trade-off (own comment in header).
- **[Hypothesis]**: `margin_*` (150/110) sized for tallest wall + entity sprite;
  not verified against sprite table maxima.

## Related Pages

- [[world-to-screen/CLASS_DIAGRAM]] — class graph
- [[world-to-screen/SEQUENCE_DIAGRAM]] — camera → draw → present
- [[world-to-screen/MAP]] — file:line index
- [[world-to-screen/SPEC]] — formulas, diamond math, flag bits
