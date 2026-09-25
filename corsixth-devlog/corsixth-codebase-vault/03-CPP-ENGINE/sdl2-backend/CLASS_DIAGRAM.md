# SDL Backend — Class Diagram

```mermaid
classDiagram
    class mainloop {
        <<function sdl_core.cpp>>
        +mainloop(LuaState*) void
    }
    class fps_ctrl {
        +bool limit_fps
        +bool track_fps
        +int frame_count
        +count_frame() void
        +init() void
    }
    class sdl_module {
        <<luaT_register sdl>>
        +init(video,audio)
        +quit() +getTicks() +getKeyModifiers()
        +startTextInput() +stopTextInput()
        +getFPS() +trackFPS() +limitFPS()
        +audio +wm
    }
    class render_target {
        -SDL_Window* window
        -SDL_Renderer* renderer
        +render_target(params)
        +update(params) bool
        +start_frame() bool
        +end_frame() bool
        +get_renderer() SDL_Renderer*
        +get_renderer_details() const char*
    }
    class render_target_creation_params {
        <<struct>> +size +min_size
        +fullscreen +maximized +present_immediate
        +direct_zoom +hidpi +aspect_ratio_4_3
    }
    class music {
        +MIX_Audio* pMusic
    }
    class load_music_async_data {
        <<struct>> +L +music +rwop +err +thread
    }
    class movie_player {
        +play() +stop() +togglePause()
    }
    class sound_player {
        <<th_sound>> +play() +play_at()
    }
    mainloop --> fps_ctrl : samples
    mainloop --> render_target : ConvertEvent coords
    sdl_module --> render_target : TH.surface creates
    render_target_creation_params --> render_target : ctor param
    sdl_module --> music : audio submodule
    load_music_async_data --> music : fills pMusic
    movie_player ..> mainloop : MOVIE_OVER
    sound_player ..> mainloop : SOUND_OVER
```

| Link | Meaning |
|------|---------|
| `mainloop → render_target` | `SDL_ConvertEventToRenderCoordinates(target->get_renderer())` |
| `async_data → music` | Worker decodes, main-loop callback installs `pMusic` |
| `movie/sound → mainloop` | Custom `SDL_EVENT_USER+n` events consumed in `mainloop` |
