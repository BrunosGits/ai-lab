# 34 — Movie / Video Playback — Summary

Scope: Lua `MoviePlayer` wrapper + C++ FFmpeg backend.
See also: [[34-movie-player/MAP]], [[34-movie-player/CHECKLIST]], [[34-movie-player/SCAFFOLD]].
Related: [[17-ui-system/MAP]] (input/paint gate), [[26-config-settings/MAP]] (switches).

## Overview

- **[Documented fact]** Lua side is `CorsixTH/Lua/movie_player.lua` (`class "MoviePlayer"`);
  C++ side is `movie_player` in `CorsixTH/Src/th_movie.{h,cpp}`,
  bound in `CorsixTH/Src/th_lua_movie.cpp` as `TH.moviePlayer`.
- **[Documented fact]** Backend is compile-gated by `CORSIX_TH_USE_FFMPEG`
  (`WITH_MOVIES` in `CMakeLists.txt`). Without it all calls are stubs
  and `getEnabled()` returns false.
- **[Documented fact]** Runtime-gated by `app.config.movies` (+ `play_intro`,
  `play_demo`). Missing file or failed `load()` skips playback and runs callback.

## Lifecycle / Flow

1. **[Documented fact]** `App` creates `MoviePlayer(app,audio,video)`, calls `init()`
   only if install folder OK. `init()` creates `TH.moviePlayer()`,
   `setRenderer(video)`, scans `Anims/` + `Intro/`.
2. **[Documented fact]** Caller: `playIntro(cb)` / `playDemoMovie()` / `playWinMovie()` /
   `playWinLevelMovie()` / `playAdvanceMovie(n)` / `playLoseMovie()` → `playMovie(file, wait_for_stop, cb)`.
3. **[Documented fact]** `playMovie` gates (`nil`, `getEnabled()`, `config.movies`),
   then `load(path)` → warns via `gameLog`/`print`, aborts to `cb()` on failure.
4. **[Documented fact]** On success: pause bg music if movie has audio, cache
   `getLength()`, paint one black frame, set `wait_for_stop/wait_for_over`,
   stash `callback_on_destroy_movie`, strip `"opengl"` from `app.modes`, call C++ `play()`.
5. **[Documented fact]** C++ `play()` allocates picture buffer, starts
   `read_streams` + `run_video` threads + audio stream. `App:drawFrame`
   calls `moviePlayer:refresh()` instead of `ui:draw` while `playing`.
6. **[Documented fact]** End: decoder threads push `SDL_USEREVENT_MOVIE_OVER` →
   `sdl_core` dispatches `movie_over` → `App:onMovieOver` →
   `MoviePlayer:onMovieOver`. If `wait_for_stop` is false it destroys now;
   else it waits for `stop()` (click / `UI:stopMovie` / Esc) then destroys.
7. **[Documented fact]** `destroyMovie` = `unload()` + restore opengl mode +
   resume/pause bg music + stop dice sound + clear flags + run destroy callback.

## Key mechanics

- **[Documented fact]** Sizing: `calculateSize()` letterboxes to render size;
  special-cases 320x200 → 320x240 (4:3 stretch); returns x,y,w,h,scale.
- **[Documented fact]** Lose overlay: `loseMovieOverlay()` picks random headline
  from `_S.newspaper[i]`, times it to `movie_length - ~780..1760ms`, draws with
  `Font39v` or narrow `Font40v` (bitmap overflow >590px) at half-scale.
- **[Documented fact]** Advance movies need dice SFX (`DICE122M` for 12, else
  `DICEYFIN`) and pause bg music eagerly; other movies pause bg music only
  if `hasAudioTrack()`.
- **[Documented fact]** `wait_for_stop=true` (win-level, advance, lose) requires
  user dismiss; `false` (intro, demo, win-game) auto-closes.
- **[Inference]** OpenGL mode is blanked during movies because the SDL-texture
  picture buffer path assumes software renderer. Restore is best-effort.
- **[Hypothesis]** `deallocate/allocatePictureBuffer` around video reset exists
  to avoid holding dead `SDL_Texture`/`SDL_Renderer` across resize; lost frames
  during reset are accepted by design.

## Related subsystems

- [[17-ui-system/MAP]]: `UI`/`GameUI` swallow clicks/mouse-move while `playing`;
  left-click/Esc/`stopMovie`/`pauseMovie` map to `stop()`/`togglePause()`.
- [[26-config-settings/MAP]]: `movies` (master), `play_intro`, `play_demo` (+ idle timer
  ~30s → demo); customise dialog toggles `movies`; saveguard excludes
  `moviePlayer` from persistence via `persistance.lua`.
- Audio: bg-music hold/resume + dice sounds; C++ resamples to 44.1kHz stereo float.
