# 34 — Movie Player — Pre-fix Safety Gate

Do not change playback without checking all boxes.

- [ ] Compile gate: is `WITH_MOVIES`/`CORSIX_TH_USE_FFMPEG` on? Else
  `getEnabled()==false` and every movie silently no-ops (stub `play`
  only pushes `MOVIE_OVER`).
- [ ] Config gate: `config.movies` master + `play_intro`/`play_demo` for
  those paths. Test with `movies=false` → callback still runs.
- [ ] Files present: `Anims/LOSE*/AREA*V/WIN*`, `Intro/INTRO.SM4`,
  `ATTRACT.SMK`. `nil` filename must no-op, never crash.
- [ ] `load()` failure path: callback fires, no `playing=true`, warning
  goes to `world:gameLog` (in-game) or `print` (menu + `debug`).
- [ ] Audio: bg music paused only when needed (advance always; others
  only if `hasAudioTrack()`); resumed/dropped in `destroyMovie`.
- [ ] Renderer: `setRenderer` current; video resize calls
  `deallocate → updateRenderer → allocate`; no use-after-free texture.
- [ ] Draw loop: while `playing`, `App:drawFrame` skips `ui:draw`;
  `refresh(x,y,w,h)` uses `calculateSize`; pts returned drives overlay.
- [ ] End semantics: `wait_for_stop=false` auto-destroys on `MOVIE_OVER`;
  `=true` requires `stop()`. Esc/click/`stopMovie` must not double-free.
- [ ] Lose overlay: needs `lose.pl8` + `Font39v/40v`; TTF vs bitmap
  baseline differs — check headline width fallback at 590px.
- [ ] Threads: `unload()` joins stream+video threads before clearing
  queues; `stop()` only sets `aborting` — verify no deadlock.
