# SDL Backend — SPEC

## 1. Event codes (`lua_sdl.h:32-43`) — Documented fact

| Code | Value | Producer | Consumer (`sdl_core.cpp`) |
|------|-------|----------|---------------------------|
| `TICK` | `USER+0` | `timer_frame_callback :73-78` | `:485-487` sets `do_timer` |
| `MUSIC_OVER` | `USER+1` | `sdl_audio.cpp:57-61`, `midi_player.cpp:297-301` | `:468-471` → `music_over` |
| `MUSIC_LOADED` | `USER+2` | `sdl_audio.cpp:116-131` thread | `:473-484` → Lua `callback`; `RemoveTimer` on pcall fail |
| `MOVIE_OVER` | `USER+3` | `th_movie.cpp:602-604`, stub `:762-764` | `:489-492` → `movie_over` |
| `SOUND_OVER` | `USER+4` | `th_lua_sound.cpp:207-216` | `:494-499` pushes id from `e.user.data1` |

## 2. Timers — Documented fact

- Frame tick: `SDL_AddTimer(18, timer_frame_callback) :302`; callback pushes TICK and returns `interval` to repeat; removed at `:555`.
- SFX-over: `SDL_AddTimer(duration*(loops+1)+delay, played_sound_callback, &id)` (`th_lua_sound.cpp:250-272`); pause/resume/stop adjust via `RemoveTimer` + re-`AddTimer` (`:292-317`).
- Infinite-loop guard: `lua_sethook(COUNT,10M)` → error after 100 hits (`sdl_core.cpp:122-129,308`); skipped under Tracy.

## 3. Audio negotiation — Documented fact

- `l_init(soundfont?)`: `sound::init()` then `MIX_SetTrackStoppedCallback(music_track, music_over_cb)` (`sdl_audio.cpp:63-78`).
- Decode props (`:96-114`): IOStream ptr + closeIO + mixer ptr + predecode + optional `fluidsynth.soundfont_path`.
- Async: pin CB + empty `music` userdata in registry, `SDL_CreateThread` (`:133-173`); main-loop `MUSIC_LOADED` runs `l_load_music_async_callback` which `SDL_WaitThread` then calls Lua CB (`:313-358`).
- Transport: `MIX_SetTrackAudio` + `MIX_PlayTrack(loops)`; volume via `MIX_SetTrackGain` (`:192-234`); pause/resume/stop map to `MIX_*Track` (`:236-272`).

## 4. Renderer selection — fact vs inference

- **Fact:** `render_target` ctor (`th_gfx_sdl.cpp:494-560`) sets window props (title/size/resizable/hidden/fullscreen/maximized/hidpi) → `SDL_CreateWindowWithProperties :516`; renderer props carry only window + VSync (`present_immediate?0:1`) → `SDL_CreateRendererWithProperties :528`.
- **Fact:** No backend-name selection in `Src/`; target-texture probe `:536-544` sets `supports_target_textures`; `get_renderer_details :668-670` returns `SDL_GetRendererName`.
- **Inference:** GL vs D3D vs Metal vs software is SDL3 auto-choice; Lua only toggles `present_immediate/direct_zoom/hidpi/fullscreen/maximized` (`th_lua_gfx.cpp:781-811`).
- **Hypothesis:** Fullscreen letterbox + `RaiseWindow`/drain workaround (`:551-560`) exist for Wayland/macOS quirks, not perf tiers.

## 5. Bootstrap / shutdown — Documented fact

- `SrcUnshared/main.cpp:105-173`: `luaL_newstate :122`, `atpanic :135`, `openlibs :136`, push `stacktrace+init :138-139`, `pcall(argc) :147`, on fail `bootstrap_lua_error_report :156-158`, then `mainloop :162`.
- Teardown: `_RESTART :164`, destroy Lua first, then `sound::quit :170`, `MIX_Quit :171`, `SDL_Quit :172`.
- `Src/main.cpp:160` preloads `sdl→luaopen_sdl`; `bootstrap.cpp:82-90` error UI itself uses `SDL.init('video')` + `SDL.mainloop`.
