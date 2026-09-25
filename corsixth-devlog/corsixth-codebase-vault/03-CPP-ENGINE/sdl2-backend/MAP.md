# SDL Backend — MAP

> Paths rooted at `CorsixTH/Src/`. All ranges read via `ssh vps sed/grep`.

## Core / events

| Location | Symbol | Notes |
|----------|--------|-------|
| `sdl_core.h:28-31` | `mainloop`, `luaopen_sdl_audio/wm/sdl` | Module entry decls |
| `lua_sdl.h:32-41` | `SDL_USEREVENT_TICK/MUSIC_OVER/MUSIC_LOADED/MOVIE_OVER/SOUND_OVER` | `SDL_EVENT_USER+0..4` |
| `lua_sdl.h:43` | `usertick_period_ms = 18` | Tick period |
| `lua_sdl.h:45-47` | `luaopen_sdl`, `l_load_music_async_callback` | Cross-file decls |
| `sdl_core.cpp:44-68` | `l_init` | `SDL_Init(video/audio)`, `MIX_Init` |
| `sdl_core.cpp:73-78` | `timer_frame_callback` | Push TICK, return interval |
| `sdl_core.cpp:80-121` | `fps_ctrl` | 4096-ring, `count_frame` |
| `sdl_core.cpp:122-129` | `infinite_loop_*` | Limit 100, hook err |
| `sdl_core.cpp:132-155` | `l_push_modifiers_table`, `l_get_key_modifiers` | shift/alt/ctrl/gui/numlock |
| `sdl_core.cpp:156-160` | `l_quit` | Push `SDL_EVENT_QUIT` |
| `sdl_core.cpp:168-192` | `l_error_handler` | `TheApp:errorHandler` |
| `sdl_core.cpp:203-212` | `push_app_dispatch` | `TheApp:dispatch` convention |
| `sdl_core.cpp:214-252` | `l_track/limit/get_fps`, `l_get_ticks`, `l_start/stop_text_input` | FPS + text input |
| `sdl_core.cpp:254-271` | `sdllib`, `load_extra` | `sdl.{audio,wm}` install |
| `sdl_core.cpp:274-298` | `dispatch_*` | 20 dispatch names |
| `sdl_core.cpp:300-322` | `mainloop` head | AddTimer, hook, `TheApp.video`, WaitEvent |
| `sdl_core.cpp:327-467` | input/window cases | key/mouse/wheel/pinch/focus/resize/pixel/scale/max/restore |
| `sdl_core.cpp:468-499` | userevent cases | music_over/loaded, tick, movie/sound_over |
| `sdl_core.cpp:505-514` | dispatch pcall | `lua_pcall(nargs+1,1)`, `do_frame`, PollEvent drain |
| `sdl_core.cpp:515-525` | timer dispatch | `dispatch_timer` |
| `sdl_core.cpp:526-542` | frame dispatch | `dispatch_frame`, uncapped inner loop |
| `sdl_core.cpp:546-555` | GC + leave | `lua_gc(STEP,2)`, RemoveTimer |
| `sdl_core.cpp:558-565` | `luaopen_sdl` | `fps.init`, register, audio+wm |

## Audio glue / WM

| Location | Symbol | Notes |
|----------|--------|-------|
| `sdl_audio.cpp:36-55` | `class music` | RAII `MIX_Audio*` |
| `sdl_audio.cpp:57-61` | `audio_music_over_callback` | Push MUSIC_OVER |
| `sdl_audio.cpp:63-78` | `l_init` | SoundFont opt, `sound::init`, stopped-callback |
| `sdl_audio.cpp:96-114` | `createMusicAudio` | IOStream+predecode+soundfont props |
| `sdl_audio.cpp:116-131` | `load_music_async_thread` | Decode, push MUSIC_LOADED |
| `sdl_audio.cpp:133-173` | `l_load_music_async` | Registry pinning, `SDL_CreateThread` |
| `sdl_audio.cpp:175-190` | `l_load_music` | Sync decode path |
| `sdl_audio.cpp:192-234` | `l_music_volume`, `l_play_music` | Gain, SetTrackAudio+PlayTrack |
| `sdl_audio.cpp:236-272` | `l_pause/resume/stop_music` | Track pause/resume/stop |
| `sdl_audio.cpp:274-293` | `l_transcode_xmi` | XMI→MIDI helper |
| `sdl_audio.cpp:295-309` | `sdl_audiolib`, `sdl_musiclib` | Method tables |
| `sdl_audio.cpp:313-358` | `l_load_music_async_callback` | `SDL_WaitThread`, invoke Lua CB |
| `sdl_audio.cpp:360-378` | `luaopen_sdl_audio` | Table + `__gc` + music funcs |
| `sdl_wm.cpp:36-57` | `l_set_icon_win32` | Disabled stub, returns false |
| `sdl_wm.cpp:59-72` | `l_show_cursor`, `sdl_wmlib` | Show/HideCursor table |
| `sdl_wm.cpp:75-80` | `luaopen_sdl_wm` | Returns wm table |

## Bootstrap / video / producers

| Location | Symbol | Notes |
|----------|--------|-------|
| `main.cpp:65-134` | `search_script_file` | `--interpreter=`, local dirs, compiled path |
| `main.cpp:136-187` | `lua_init_no_eval` | Version check, preload `sdl` at :160 |
| `main.cpp:189-231` | `lua_init`, `lua_stacktrace`, `lua_panic` | Boot + error paths |
| `SrcUnshared/main.cpp:105-173` | `main` | newstate→pcall→mainloop→restart→quit order |
| `bootstrap.cpp:82-90` | bootstrap Lua | Uses `SDL.init('video')`, `SDL.mainloop` |
| `th_gfx_sdl.h:64-80` | `render_target_creation_params` | size/fullscreen/vsync/zoom/hidpi |
| `th_gfx_sdl.h:264-280` | `class render_target` | start/end_frame, update |
| `th_gfx_sdl.cpp:494-560` | `render_target` ctor | CreateWindow :516, CreateRenderer :528 |
| `th_gfx_sdl.cpp:561-575` | `~render_target` | Destroy renderer+window |
| `th_gfx_sdl.cpp:668-698` | `get_renderer_details`, `start/end_frame` | Name query, RenderPresent |
| `th_lua_gfx.cpp:781-824` | `l_surface_creation_params`, `l_surface_new` | Lua→params→ctor |
| `th_movie.cpp:602-604` | movie thread end | Push MOVIE_OVER |
| `th_movie.cpp:762-764` | no-movie stub | Immediate MOVIE_OVER |
| `th_lua_sound.cpp:207-272` | `played_sound_callback` + `l_soundfx_play` | Push SOUND_OVER via AddTimer |
| `midi_player.cpp:297-301,605` | `midi_music_over_callback` | Push MUSIC_OVER |
