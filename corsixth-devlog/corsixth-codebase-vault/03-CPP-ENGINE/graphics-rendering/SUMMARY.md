# Graphics Rendering — C++ Engine Deep Dive

> C++ engine: SDL3 rendering backend, window management, graphics pipeline, rendering optimizations.
> See also: [[graphics-rendering/MAP]], [[graphics-rendering/CLASS_DIAGRAM]], [[graphics-rendering/SEQUENCE_DIAGRAM]], [[graphics-rendering/SPEC]].
> Related: [[core-graphics]], [[sdl2-backend]], [[world-to-screen]], [[entity-rendering]].

## 1. Overview

- **[Documented fact]** Two-layer graphics system: portable logic in `th_gfx.h` (`animation_manager`, `sprite_sheet`, `palette`, `render_target`) on top of SDL3 backend in `th_gfx_sdl.h` (`SDL_Window`, `SDL_Renderer`, `SDL_Texture`).
- **[Documented fact]** SDL3 renderer created via `SDL_CreateRendererWithProperties` with only VSync toggled (`present_immediate` flag). No backend selection (OpenGL/D3D/Metal/software) in source — SDL3 chooses automatically.
- **[Documented fact]** Lazy GPU upload: `sprite_sheet::draw_sprite` creates `SDL_Texture` on first draw via `create_palettized_texture`; `raw_bitmap` uploads eagerly in `load_from_th_file`.
- **[Inference]** Single render path — no OpenGL vs software renderer strings in `Src/`. Backend choice is SDL3's automatic selection observable via `get_renderer_details()`.

## 2. Architecture

```
Lua (graphics.lua / animations.lua / map.lua / game_ui.lua)
  → th_lua_gfx.cpp / th_lua_anims.cpp / th_lua_map.cpp (lua_class_binding)
  → th_gfx.h: animation_manager / sprite_sheet / raw_bitmap / palette / render_target
  → th_gfx_sdl.cpp: SDL_Window / SDL_Renderer / SDL_Texture / palettized textures
  → SDL3 API: SDL_RenderTexture / SDL_RenderPresent
```

- **[Documented fact]** Frame lifecycle: `render_target::start_frame` (`fill_black`) → draws → `end_frame` (cursor + blue filter + `SDL_RenderPresent`).
- **[Documented fact]** Scaling: `set_scale_factor` picks `global_scale_factor` (zoom_buffer path) or `bitmap_scale_factor`; `raw_bitmap::draw` consults `should_scale_bitmaps`.
- **[Documented fact]** Clip rect stacking: `scoped_clip` RAII pattern for push/pop clip rects during rendering.

## 3. Key Classes

| Class | Role | File |
|-------|------|------|
| `render_target` | Owns `SDL_Window*`, `SDL_Renderer*`; `start_frame`/`end_frame`/`draw`/`update` | `th_gfx_sdl.h/cpp` |
| `sprite_sheet` | Table+chunk loader; owns `sprite{texture,alt_texture,data}` array; lazy texture upload | `th_gfx_sdl.h/cpp` |
| `raw_bitmap` | Single flat 8bpp image (loading screens, panels); eager texture upload | `th_gfx_sdl.h/cpp` |
| `palette` | 256-entry 8bpp→ARGB table; magenta→transparent; alt-palette remap | `th_gfx_sdl.h/cpp` |
| `animation_manager` | START/FRAME/LIST/ELEMENT tables → `draw_frame` layer filter; 13 layers | `th_gfx.h/cpp` |
| `animation` / `sprite_render_list` | `drawable` instances: tick + draw + hit-test + persist | `th_gfx.h/cpp` |
| `chunk_renderer` | Decodes TH simple/complex RLE chunks to 8bpp rows | `th_gfx.h/cpp` |
| `cursor` | SDL cursor bitmap; Lua `TH.cursor` new/load/use/setPosition | `th_gfx_sdl.h/cpp` |

## 4. Key Flows

### Window Creation
`App` → `TH.surface(w,h,modes)` → `render_target` ctor → `SDL_CreateWindowWithProperties` + `SDL_CreateRendererWithProperties` (VSync only) → `set_scale_factor`.

### Frame Render
`GameUI:draw` → `map:draw` (world-pixel rect) → `animation_manager::draw_frame` → `sprite_sheet::draw_sprite` → `render_target::draw` → `SDL_RenderTexture` → `end_frame` → `SDL_RenderPresent`.

### Texture Upload
First `draw_sprite` → `create_palettized_texture` (palette + chunk RLE decode) → `SDL_CreateTexture` + `SDL_UpdateTexture` → cached in `sprite.texture`.

## 5. Related Pages

- [[graphics-rendering/MAP]] — file:line index
- [[graphics-rendering/CLASS_DIAGRAM]] — class graph
- [[graphics-rendering/SEQUENCE_DIAGRAM]] — render path
- [[graphics-rendering/SPEC]] — texture/palette formats
- [[core-graphics]] — portable graphics logic
- [[sdl2-backend]] — SDL3 event loop + window
- [[world-to-screen]] — camera + tile draw
- [[entity-rendering]] — entity draw pipeline