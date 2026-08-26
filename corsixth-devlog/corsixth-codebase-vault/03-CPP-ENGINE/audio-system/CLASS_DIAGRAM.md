# Audio System — Class Diagram

> **Mermaid class diagram for the CorsixTH audio subsystem**

```mermaid
classDiagram
    namespace th_sound {
        class sdl_mixer {
            -MIX_Track* music_track
            -MIX_Track* movie_track
            -MIX_Track*[32] fx_channels
            -MIX_Mixer* mixer
            +sdl_mixer()
            +~sdl_mixer()
            +get_music_track() MIX_Track*
            +get_movie_track() MIX_Track*
            +get_fx_track(int channel) MIX_Track*
            +get_mixer() MIX_Mixer*
        }

        class mixer_ptr {
            <<unique_ptr~sdl_mixer~>>
        }

        class init {
            <<function>>
            +bool init()
        }

        class quit {
            <<function>>
            +void quit()
        }

        class get_mixer {
            <<function>>
            +sdl_mixer* get_mixer()
        }
    }

    class sound_archive {
        -vector~uint8_t~ data
        -vector~sound_dat_sound_info~ sound_files
        +load_from_th_file(uint8_t* data, size_t len) bool
        +get_number_of_sounds() size_t
        +get_sound_name(size_t index) const char*
        +get_sound_duration(size_t index) size_t
        +load_sound(size_t index) SDL_IOStream*
    }

    class sound_dat_sound_info {
        <<struct>>
        +array~char,18~ sound_name
        +uint32_t position
        +uint32_t length
    }

    class sound_player {
        -MIX_Audio** sounds
        -size_t sound_count
        -int camera_x
        -int camera_y
        -double camera_radius
        -double master_volume
        -double sound_effect_volume
        -float positionless_volume
        -bool sound_effects_enabled
        -channel_data[32] channels
        -uint32_t next_playing_track_handle
        -recursive_mutex channel_mutex
        -static sound_player* singleton
        +get_singleton() sound_player*
        +populate_from(sound_archive*) void
        +play(size_t, double, int) uint32_t
        +play_at(size_t, int, int, int) uint32_t
        +play_at(size_t, double, int, int, int) uint32_t
        +toggle_pause(uint32_t) toggle_pause_result
        +stop(uint32_t) void
        +is_playing(uint32_t) bool
        +set_sound_effect_volume(double) void
        +set_sound_effects_enabled(bool) void
        +set_camera(int, int, int) void
        +reserve_channel() int
        +release_channel(int) void
        -play_raw(size_t, float, int) uint32_t
        -playing_channel_for_handle(uint32_t) int
        -on_channel_finished(void*, MIX_Track*) void$
    }

    class channel_data {
        <<struct>>
        +int channel
        +uint32_t handle
    }

    class toggle_pause_result {
        <<enum>>
        error
        paused
        resumed
    }

    mixer_ptr --> sdl_mixer : owns
    sdl_mixer *-- "1" sound_dat_sound_info : contained in archive
    sound_archive *-- "0..*" sound_dat_sound_info : indexes
    sound_player --> sound_archive : populate_from()
    sound_player *-- "32" channel_data : manages
    sound_player --> sdl_mixer : uses for MIX_Track access
    sound_player ..> toggle_pause_result : returns
    sound_archive ..> "SDL_IOStream" : load_sound() creates
    sound_player ..> "MIX_Audio" : holds array of
    sound_player ..> "MIX_Track" : operates on
    init ..> sdl_mixer : creates
    quit ..> mixer_ptr : destroys
    get_mixer ..> sdl_mixer : returns pointer to
```

## Relationship Summary

| Relationship | Type | Description |
|-------------|------|-------------|
| `mixer_ptr` → `sdl_mixer` | owns (RAII) | `std::unique_ptr<sdl_mixer>` manages mixer lifetime |
| `sound_archive` ↔ `sound_dat_sound_info` | containment | Archive contains indexed sound metadata entries |
| `sound_player` → `sound_archive` | uses | `populate_from()` loads sounds from archive |
| `sound_player` → `channel_data` | owns (array) | 32-element array of active channel state |
| `sound_player` → `sdl_mixer` | uses | Accesses `MIX_Track*` for playback |
| `sound_player` → `MIX_Audio**` | owns (raw array) | Pre-loaded audio data per sound index |
| `sdl_mixer` → `MIX_Mixer*` | owns | RAII destruction via `MIX_DestroyMixer` |
| `sdl_mixer` → `MIX_Track*` | owns (1+1+32) | 1 music + 1 movie + 32 FX tracks |

---

## Related Pages

- [[SUMMARY]] — Full technical reference
- [[SEQUENCE_DIAGRAM]] — Playback and loading flows
- [[MAP]] — Source file line index
