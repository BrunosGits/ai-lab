# Core Graphics Engine — Summary

> C++ engine: sprites, palettes, bitmaps, animations, fonts, draw pipeline, Lua bindings.
> Sources: `CorsixTH/Src/th_gfx.h/.cpp`, `th_gfx_common.h`, `th_gfx_sdl.h/.cpp`, `th_gfx_font.h/.cpp`, `th_lua_gfx.cpp`, `th_lua_anims.cpp`.

## 1. Claim legend

- **[Documented fact]** — read directly in source via `ssh vps`.
- **[Inference]** — derived from combining 2+ facts, no single line states it.
- **[Hypothesis]** — plausible but unverified; needs runtime/TH-file confirmation.

## 2. Overview

- **[Documented fact]** Two-layer design: portable logic in `th_gfx.h` (`animation_manager`, `animation`, `chunk_renderer`, `drawable`) on top of SDL3 backend in `th_gfx_sdl.h` (`render_target`, `sprite_sheet`, `raw_bitmap`, `palette`).
- **[Documented fact]** Shared enums in `th_gfx_common.h`: only `animation_effect::{none,glowing,jelly}`.
- **[Documented fact]** Fonts are abstract `font` with two impls: `bitmap_font` (sprite-sheet glyphs) and `freetype_font` (FreeType2 + texture cache).
- **[Inference]** Lua owns lifetime via `luaT_stdnew` userdata; C++ never owns Lua objects, only borrows `sprite_sheet*`/`render_target*` (e.g. `animation_manager::sheet`, `canvas`).

## 3. Architecture

```text
Lua (graphics.lua / animations.lua)
  -> th_lua_gfx.cpp / th_lua_anims.cpp (lua_class_binding)
  -> animation_manager::draw_frame / sprite_sheet::draw_sprite / font::draw_text
  -> render_target::draw (SDL_RenderTexture) -> start_frame/end_frame present
```

- **[Documented fact]** Frame lifecycle: `render_target::start_frame` (`fill_black`) → draws → `end_frame` (cursor + blue filter + `SDL_RenderPresent`).
- **[Documented fact]** Lazy GPU upload: `sprite_sheet::draw_sprite` creates `SDL_Texture` on first draw via `create_palettized_texture`; `raw_bitmap` uploads eagerly in `load_from_th_file`.
- **[Documented fact]** Scaling: `set_scale_factor` picks `global_scale_factor` (zoom_buffer path) or `bitmap_scale_factor`; `raw_bitmap::draw` consults `should_scale_bitmaps`.

## 4. Key classes / flows

| Class | Role |
|-------|------|
| `palette` | 256-entry 8bpp→ARGB table; magenta→transparent |
| `chunk_renderer` | Decodes TH simple/complex RLE chunks to 8bpp rows |
| `sprite_sheet` | Table+chunk loader; owns `sprite{texture,alt_texture,data}` array |
| `raw_bitmap` | Single flat 8bpp image (loading screens, panels) |
| `animation_manager` | START/FRAME/LIST/ELEMENT tables → `draw_frame` layer filter |
| `animation` / `sprite_render_list` | `drawable` instances: tick + draw + hit-test + persist |
| `render_target` | SDL window/renderer, clip stack, zoom/intermediate textures |
| `bitmap_font` / `freetype_font` | Glyph rasterizers; FreeType uses 128-entry message cache |

- **[Documented fact]** `draw_flags` bit-compat with TH files: flip H/V, alpha50/75 (both set = skip), alt_palette, alt32 mode bits 5–7, early_list, bound_box_hit_test, crop, nearest.
- **[Documented fact]** Alt-palette: per-sprite 256-byte remap (`set_sprite_alt_palette_map`) or 32bpp grey/blue-red-swap; index 255 kept transparent.
- **[Hypothesis]** `custom_sheets` + `load_custom_animations` exist for fan content; original tables must load at offset 0 due to hard-coded Lua animation numbers.

## 5. Lua bindings

- **[Documented fact]** `lua_register_gfx`: palette, bitmap, sheet, font(+bitmap_font, freetype_font), layers, cursor, surface, line.
- **[Documented fact]** `lua_register_anims`: anims manager, animation, spriteList; `draw` takes `(surface, layers)` as upvalues.
- **[Inference]** Hot path is `anims:draw` → `draw_frame` → `draw_sprite` → `render_target::draw`; `animation:draw` adds sound (`play_at`), crop-clip, and child/morph dispatch.

## Related pages

- [[core-graphics/MAP]] — file:line index
- [[core-graphics/CLASS_DIAGRAM]] — class graph
- [[core-graphics/SEQUENCE_DIAGRAM]] — Lua→screen path
- [[core-graphics/SPEC]] — palette / sprite / animation formats
