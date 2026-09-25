# 34 — Movie Player — MAP (verified via `ssh vps`)

| Claim | File | Lines |
|---|---|---|
| Lua layer header / class decl | `CorsixTH/Lua/movie_player.lua` | 21-29 |
| Aspect/size calc, 320x200 fix, letterbox | `CorsixTH/Lua/movie_player.lua` | 43-81 |
| destroy: unload, opengl restore, music/sound | `CorsixTH/Lua/movie_player.lua` | 83-104 |
| Lose headline overlay, timing table, fonts | `CorsixTH/Lua/movie_player.lua` | 106-154 |
| Ctor state defaults | `CorsixTH/Lua/movie_player.lua` | 156-176 |
| init: TH.moviePlayer, renderer, Anims scan | `CorsixTH/Lua/movie_player.lua` | 178-217 |
| init: Intro/ATTRACT scan | `CorsixTH/Lua/movie_player.lua` | 219-230 |
| playIntro / playDemo / playWin / playWinLevel | `CorsixTH/Lua/movie_player.lua` | 232-249 |
| playAdvance gate + dice SFX | `CorsixTH/Lua/movie_player.lua` | 254-273 |
| playLose random + overlay hook | `CorsixTH/Lua/movie_player.lua` | 275-282 |
| playMovie gate/load/warn/black-frame/play | `CorsixTH/Lua/movie_player.lua` | 289-356 |
| onMovieOver / stop / refresh / pause | `CorsixTH/Lua/movie_player.lua` | 372-416 |
| video-reset buffer helpers | `CorsixTH/Lua/movie_player.lua` | 358-369, 403-407 |
| C++ class + public API decl | `CorsixTH/Src/th_movie.h` | 300-406 |
| picture/packet queue decl | `CorsixTH/Src/th_movie.h` | 130-290 |
| set_renderer / movies_enabled=true | `CorsixTH/Src/th_movie.cpp` | 335-339 |
| load (open, stream info, codecs) | `CorsixTH/Src/th_movie.cpp` | 341-390 |
| unload (join threads, clear queues) | `CorsixTH/Src/th_movie.cpp` | 392-425 |
| play (alloc buffer, spawn threads) | `CorsixTH/Src/th_movie.cpp` | 427-447 |
| stop / togglePause / natives / length | `CorsixTH/Src/th_movie.cpp` | 491-537 |
| refresh (clock sync, draw) | `CorsixTH/Src/th_movie.cpp` | 542-561 |
| read_streams / run_video / audio copy | `CorsixTH/Src/th_movie.cpp` | 575-700 |
| no-FFmpeg stubs, push MOVIE_OVER | `CorsixTH/Src/th_movie.cpp` | 754-780 |
| Lua bindings (all methods) | `CorsixTH/Src/th_lua_movie.cpp` | 39-162, 165-181 |
| MOVIE_OVER event define | `CorsixTH/Src/lua_sdl.h` | 38-39 |
| MOVIE_OVER dispatch → `movie_over` | `CorsixTH/Src/sdl_core.cpp` | 489-493 |
| WITH_MOVIES → USE_FFMPEG | `CMakeLists.txt` | 122-129 |
| App wires movie_over, creates player | `CorsixTH/Lua/app.lua` | 66, 293-295 |
| playIntro on boot / idle demo / drawFrame | `CorsixTH/Lua/app.lua` | 420-421, 1299-1330 |
| onMovieOver forward / video reset | `CorsixTH/Lua/app.lua` | 1419-1420, 2165-2172 |
| UI swallows input while playing | `CorsixTH/Lua/ui.lua` | 858-862, 1240, 1281-1288 |
| GameUI ignores mouse while playing | `CorsixTH/Lua/game_ui.lua` | 601, 699 |
| config defaults | `CorsixTH/Lua/config_finder.lua` | 149-151, 469-481 |
| customise dialog toggle | `CorsixTH/Lua/dialogs/resizables/customise.lua` | 67-69, 162-164 |
| lose trigger | `CorsixTH/Lua/world.lua` | 1461 |
| fax advance+win / new-game / debug menu | `CorsixTH/Lua/dialogs/fullscreen/fax.lua` | 218-239 |
| new-game movie hook | `CorsixTH/Lua/dialogs/resizables/new_game.lua` | 156 |
| menu movie hook | `CorsixTH/Lua/dialogs/menu.lua` | 839 |
