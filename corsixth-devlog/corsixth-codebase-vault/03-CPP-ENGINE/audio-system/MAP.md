# Audio System — File:Line Index

> **Source locations for `th_sound.h` and `th_sound.cpp`**

## th_sound.h

| Line(s) | Symbol | Description |
|---------|--------|-------------|
| 23–24 | `CORSIX_TH_TH_SOUND_H_` | Include guard |
| 35 | `namespace th::sound` | Sound namespace opens |
| 36–62 | `class sdl_mixer` | RAII mixer wrapper |
| 38 | `number_of_fx_channels` | Constant: 32 FX channels |
| 40–41 | `sdl_mixer()` / `~sdl_mixer()` | Constructor / destructor |
| 42–44 | `get_music_track()` / `get_movie_track()` / `get_fx_track()` | Track accessors |
| 55 | `get_mixer()` | Raw MIX_Mixer* accessor |
| 58–61 | `music_track`, `movie_track`, `fx_channels`, `mixer` | Private members |
| 64 | `mixer_ptr` | `std::unique_ptr<sdl_mixer>` alias |
| 66–68 | `init()`, `quit()`, `get_mixer()` | Free functions |
| 70 | Namespace close |
| 73–101 | `class sound_archive` | Theme Hospital .DAT loader |
| 75 | `load_from_th_file()` | Archive parsing entry point |
| 78 | `get_number_of_sounds()` | Sound count accessor |
| 81 | `get_sound_name()` | Name accessor |
| 84 | `get_sound_duration()` | WAV duration calculator |
| 90 | `load_sound()` | SDL_IOStream factory |
| 93–97 | `struct sound_dat_sound_info` | Per-sound metadata |
| 99–100 | `data`, `sound_files` | Private data members |
| 103–225 | `class sound_player` | Playback engine singleton |
| 105 | `toggle_pause_result` | Enum class |
| 106 | `null_handle` | Constant: 0 |
| 107 | `number_of_channels` | Constant: 32 |
| 109–112 | Constructors / destructor | Non-copyable |
| 114 | `get_singleton()` | Static singleton accessor |
| 116 | `populate_from()` | Load sounds from archive |
| 126 | `play()` | Positionless playback |
| 138 | `play_at(index, x, y, loops)` | Positional playback |
| 152 | `play_at(index, volume, x, y, loops)` | Positional with volume |
| 158 | `toggle_pause()` | Pause/resume toggle |
| 163 | `stop()` | Stop playback |
| 166 | `is_playing()` | Status query |
| 169 | `set_sound_effect_volume()` | Volume setter |
| 173 | `set_sound_effects_enabled()` | Enable/disable SFX |
| 176 | `set_camera()` | Camera position for attenuation |
| 184 | `reserve_channel()` | Manual channel reservation |
| 187 | `release_channel()` | Manual channel release |
| 190–193 | `struct channel_data` | Per-channel state |
| 195 | `singleton` | Static singleton pointer |
| 196 | `on_channel_finished()` | Static callback |
| 198 | `play_raw()` | Internal playback implementation |
| 201 | `playing_channel_for_handle()` | Handle→channel lookup |
| 204–224 | Private data members | State, volumes, channels, mutex |

## th_sound.cpp

| Line(s) | Symbol | Description |
|---------|--------|-------------|
| 40–97 | `namespace th::sound` | Namespace implementation |
| 41 | `static mixer_ptr mixer` | File-static singleton mixer |
| 43–66 | `sdl_mixer::sdl_mixer()` | Constructor — creates mixer + tracks |
| 68–71 | `sdl_mixer::~sdl_mixer()` | Destructor — `MIX_DestroyMixer` |
| 73–75 | `get_fx_track()` | FX track accessor |
| 77–81 | `get_movie_track()` / `get_music_track()` / `get_mixer()` | Accessors |
| 83–91 | `th::sound::init()` | Global initialization |
| 93 | `th::sound::quit()` | Global cleanup |
| 95 | `th::sound::get_mixer()` | Global mixer accessor |
| 99–105 | Archive format constants | Header/entry size and offsets |
| 107–149 | `sound_archive::load_from_th_file()` | Archive parsing implementation |
| 151–153 | `get_number_of_sounds()` | Returns `sound_files.size()` |
| 155–158 | `get_sound_name()` | Returns name at index |
| 160–166 | `fourcc()` | constexpr FourCC helper |
| 170–173 | `mul64()` | 64-bit multiply helper |
| 177–251 | `get_sound_duration()` | RIFF/WAV parser and duration calc |
| 253–265 | `sound_archive::load_sound()` | Creates SDL_IOStream from archive |
| 267 | `sound_player::singleton` | Static singleton init |
| 269–294 | `sound_player::sound_player()` | Constructor — channels, handles, callback registration |
| 296–301 | `sound_player::~sound_player()` | Destructor — cleanup |
| 303–309 | `on_channel_finished()` | Static callback — releases channel |
| 311 | `get_singleton()` | Returns singleton pointer |
| 313–331 | `populate_from()` | Load/unload all sounds from archive |
| 333–340 | `play()` | Positionless playback entry |
| 342–347 | `play_at(index, x, y, loops)` | Positional playback (enabled check) |
| 349–364 | `play_at(index, volume, x, y, loops)` | Positional with distance attenuation |
| 366–380 | `toggle_pause()` | Pause/resume implementation |
| 382–389 | `stop()` | Stop playback implementation |
| 391–393 | `is_playing()` | Playing status check |
| 395–397 | `set_sound_effect_volume()` | Volume setter |
| 399–401 | `set_sound_effects_enabled()` | Enable/disable setter |
| 403–417 | `reserve_channel()` | Channel reservation with mutex |
| 419–422 | `release_channel()` | Channel release with mutex |
| 424–447 | `play_raw()` | Core playback: set audio, gain, play |
| 449–454 | `set_camera()` | Camera position setter |
| 456–469 | `playing_channel_for_handle()` | Linear handle search in channels |


## Related Pages

- [[BINARY_SPEC]]
- [[CLASS_DIAGRAM]]
- [[SEQUENCE_DIAGRAM]]
- [[SUMMARY]]
