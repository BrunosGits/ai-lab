# SDL Backend — Summary

> C++ engine: event loop, video, timers, custom events, audio glue, WM, bootstrap, renderer paths.
> Convention: see `[[sdl2-backend/MAP]]`, `[[sdl2-backend/CLASS_DIAGRAM]]`, `[[sdl2-backend/SEQUENCE_DIAGRAM]]`, `[[sdl2-backend/SPEC]]`.

## 1. Overview

- **Documented fact:** `main()` lives in `SrcUnshared/main.cpp`, not `Src/main.cpp`. `Src/main.cpp` only provides `lua_init_no_eval` / `lua_init` / `lua_stacktrace` / `lua_panic`.
- **Documented fact:** The SDL module is `sdl_core.{h,cpp}` + `sdl_audio.cpp` + `sdl_wm.cpp`, with event codes in `lua_sdl.h`. Video itself is `render_target` in `th_gfx_sdl.{h,cpp}`, constructed from Lua via `TH.surface(...)`.
- **Documented fact:** `mainloop(lua_State*)` in `sdl_core.cpp` is the only event loop. It blocks on `SDL_WaitEvent`, drains with `SDL_PollEvent`, and dispatches into `TheApp:dispatch(...)` with an error-handler closure.

## 2. Architecture

```
SrcUnshared/main.cpp:main -> Src/main.cpp:lua_init -> Lua CorsixTH.lua
  -> sdl.init("video"/"audio") -> TH.surface -> render_target ctor
  -> mainloop: WaitEvent -> TheApp:dispatch -> frame -> start/end_frame -> RenderPresent
```

- Bootstrap: `[[sdl2-backend/SPEC]]` §5; shutdown order `sound::quit / MIX_Quit / SDL_Quit`.
- Timers: one 18 ms `SDL_AddTimer` pushes `SDL_USEREVENT_TICK`; SFX-over uses per-play `SDL_AddTimer`; music-over is a mixer stopped-callback; movie-over is pushed by the movie thread (or stub).
- Audio split: `sdl_audio.cpp` handles *music* (`MIX_Audio`/`MIX_Track`); SFX lives in `th_lua_sound.cpp` + `th_sound.{h,cpp}` (see `[[audio-system/SUMMARY]]`).

## 3. Key classes / functions

| Item | Role |
|------|------|
| `mainloop` | Wait/drain/dispatch/timer/frame/GC loop |
| `fps_ctrl fps` | Ring of 4096 frame times; `limit_fps` / `track_fps` Lua toggles |
| `l_error_handler` + `push_app_dispatch` | `TheApp:errorHandler` + `TheApp:dispatch` call convention |
| `timer_frame_callback` | Pushes `SDL_USEREVENT_TICK`, returns interval to repeat |
| `render_target` | Owns `SDL_Window*` + `SDL_Renderer*`; `start_frame` / `end_frame` |
| `music` (sdl_audio) | RAII `MIX_Audio*`; async load via `load_music_async_data` + thread |
| `l_set_icon_win32` / `l_show_cursor` | WM table; icon setter is a disabled stub |
| `movie_player` / `midi_player` | Push `MOVIE_OVER` / `MUSIC_OVER` from worker paths |

## 4. Key flows

1. Startup → loop → frame → shutdown: `[[sdl2-backend/SEQUENCE_DIAGRAM]]`.
2. Input/window events → `push_app_dispatch` → `lua_pcall(nargs+1,1)`; truthy return sets `do_frame`.
3. `do_timer` → `dispatch_timer`; `do_frame || !limit_fps` → `dispatch_frame` → `video:startFrame/endFrame` in Lua → `SDL_RenderPresent`.
4. Custom events: `TICK→timer`, `MUSIC_OVER→music_over`, `MUSIC_LOADED→callback`, `MOVIE_OVER→movie_over`, `SOUND_OVER→sound_over(id)`.

## 5. Renderer paths

- **Documented fact:** Single SDL3 path: `SDL_CreateWindowWithProperties` then `SDL_CreateRendererWithProperties` with only VSync toggled. No `opengl`/`software` string in `Src/`.
- **Inference:** Backend (OpenGL/D3D/Metal/software) is SDL3's automatic choice; observable via `get_renderer_details()` → `SDL_GetRendererName`.
- **Hypothesis:** `direct_zoom` / target-texture probe exist to work around weak renderers, not to select GL vs software.

## 6. Related

- `[[sdl2-backend/MAP]]` — every claim with file:line.
- `[[sdl2-backend/SPEC]]` — event codes, timers, audio negotiation, renderer params.
- `[[audio-system/SUMMARY]]` — `sound_archive` / `sound_player` SFX side.
- `[[34-movie-player/SUMMARY]]` — movie gates that consume `movie_over`.
