# Audio System — Technical Reference

> **CorsixTH C++ Engine — Audio Subsystem**
> Source files: `th_sound.h`, `th_sound.cpp`

## 1. Overview

The audio subsystem provides playback of Theme Hospital's original sound effects (SOUND-0.DAT / SOUND-0.PAL) plus standard SDL_mixer-based music and movie audio. It is built on SDL3's `SDL_mixer` library and encapsulates all platform-specific mixer lifecycle management within the `th::sound` namespace.

The subsystem is organized into four primary types:

| Type | Role |
|------|------|
| `th::sound::sdl_mixer` | RAII wrapper around `MIX_Mixer`, tracks, and FX channels |
| `sound_archive` | Loader/parser for Theme Hospital `.DAT` sound archives |
| `sound_player` | Singleton playback engine — channel management, volume, spatial audio |
| `th::sound` namespace functions | Global `init()` / `quit()` / `get_mixer()` lifecycle |

---

## 2. `th::sound` Namespace

**Location:** `th_sound.h:35–70`, `th_sound.cpp:40–97`

Global free functions manage the singleton mixer instance:

```
bool init();              // Creates mixer via sdl_mixer constructor
void quit();              // Resets mixer_ptr (destroys mixer + tracks)
sdl_mixer* get_mixer();   // Returns raw pointer to singleton mixer
```

The mixer is stored as a file-static `mixer_ptr` (`std::unique_ptr<sdl_mixer>`) at `th_sound.cpp:41`.

---

## 3. `th::sound::sdl_mixer` Class

**Location:** `th_sound.h:36–62`, `th_sound.cpp:43–97`

RAII wrapper that owns the `MIX_Mixer` and all associated tracks.

### Public Interface

| Method | Returns | Description |
|--------|---------|-------------|
| `sdl_mixer()` | — | Creates mixer on default audio device; allocates 1 music track, 1 movie track, 32 FX tracks |
| `~sdl_mixer()` | — | Calls `MIX_DestroyMixer` (also destroys all tracks) |
| `get_mixer()` | `MIX_Mixer*` | Raw mixer pointer — caller must not store beyond object lifetime |
| `get_music_track()` | `MIX_Track*` | Dedicated music track |
| `get_movie_track()` | `MIX_Track*` | Dedicated movie playback track |
| `get_fx_track(int)` | `MIX_Track*` | FX track by channel index (0–31) |

### Constants

- `number_of_fx_channels = 32` — fixed at compile time

### Construction Details

- `MIX_CreateMixerDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, nullptr)` at `th_sound.cpp:44`
- Each track creation failure throws `std::runtime_error` with the SDL error string
- Destructor calls `MIX_DestroyMixer` which cascades to all child tracks

---

## 4. `sound_archive` Class

**Location:** `th_sound.h:73–101`, `th_sound.cpp:99–265`

Parses Theme Hospital's `SOUND-0.DAT` binary archive format.

### Public Interface

| Method | Returns | Description |
|--------|---------|-------------|
| `load_from_th_file(data, len)` | `bool` | Parse header and build sound file index |
| `get_number_of_sounds()` | `size_t` | Count of indexed sound entries |
| `get_sound_name(index)` | `const char*` | 18-char null-padded name |
| `get_sound_duration(index)` | `size_t` | Duration in ms (parses WAV RIFF headers) |
| `load_sound(index)` | `SDL_IOStream*` | Returns an in-memory IOStream over raw sound data |

### Private Data

```cpp
struct sound_dat_sound_info {
    std::array<char, 18> sound_name;   // Null-padded filename
    uint32_t position;                  // Byte offset into archive
    uint32_t length;                    // Byte length of sound data
};

std::vector<uint8_t> data;                    // Complete archive copy
std::vector<sound_dat_sound_info> sound_files; // Parsed index
```

### Archive Format Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `archive_header_size` | 234 | Size of the archive header block |
| `archive_header_table_position_offset` | 50 | Offset to table position within header |
| `archive_header_table_length_offset` | 58 | Offset to table length within header |
| `sound_entry_size` | 32 | Bytes per entry in the sound file table |
| `sound_entry_position_offset` | 18 | Offset to data position within entry |
| `sound_entry_length_offset` | 26 | Offset to data length within entry |

### Loading Algorithm

1. Read last 4 bytes of the file as `headerPosition` (little-endian uint32)
2. Bounds-check `headerPosition` against file length
3. Read table position and length from header at computed offsets
4. Copy entire archive into `data` vector
5. Iterate `tableLength / sound_entry_size` entries, parsing each into `sound_files`

### WAV Duration Calculation

`get_sound_duration()` (`th_sound.cpp:177–251`) opens the sound as an `SDL_IOStream` and performs a crude RIFF/WAV chunk walk:

- Scans for `fmt ` chunk to extract sample format, channels, sample rate, bits-per-sample
- Scans for `data` chunk to get data length
- Computes duration as: `dataLength * 8000 / (bitsPerSample * channels * sampleRate)` milliseconds
- Returns 0 if format is not PCM (audioFormat != 1) or fields are invalid

### Important Notes

- Index 0 is a dummy entry (legacy compatibility) — `load_sound(0)` returns `nullptr`
- `load_sound()` returns an `SDL_IOStream` backed by const memory — caller must close it

---

## 5. `sound_player` Class

**Location:** `th_sound.h:103–225`, `th_sound.cpp:267–469`

Singleton class managing all sound effect playback with channel pooling.

### Public Interface

| Method | Returns | Description |
|--------|---------|-------------|
| `get_singleton()` | `sound_player*` | Static singleton accessor |
| `populate_from(archive)` | `void` | Load all sounds from archive into `MIX_Audio*` array |
| `play(index, volume, loops)` | `uint32_t` | Play at fixed volume (positionless) |
| `play_at(index, x, y, loops)` | `uint32_t` | Play with distance attenuation from camera |
| `play_at(index, volume, x, y, loops)` | `uint32_t` | Play with explicit volume + distance attenuation |
| `toggle_pause(handle)` | `toggle_pause_result` | Pause/resume a playing sound |
| `stop(handle)` | `void` | Stop playback and release channel |
| `is_playing(handle)` | `bool` | Check if a handle is active |
| `set_sound_effect_volume(vol)` | `void` | Set default SFX volume (0.0–1.0) |
| `set_sound_effects_enabled(on)` | `void` | Enable/disable positional SFX |
| `set_camera(x, y, radius)` | `void` | Set camera position for attenuation |
| `reserve_channel()` | `int` | Reserve a channel for exclusive use |
| `release_channel(channel)` | `void` | Release a reserved channel |

### Constants

- `null_handle = 0` — sentinel for "no active sound"
- `number_of_channels = 32` — matches `sdl_mixer::number_of_fx_channels`

### Enum: `toggle_pause_result`

- `error` — handle not found or not playing
- `paused` — sound was playing, now paused
- `resumed` — sound was paused, now resumed

### Internal State

```cpp
MIX_Audio** sounds;                  // Array of pre-loaded audio objects
size_t sound_count;                  // Number of loaded sounds
int camera_x, camera_y;             // Camera position for attenuation
double camera_radius;               // Camera view radius
double master_volume;               // Master volume (always 1.0)
double sound_effect_volume;         // User-configurable SFX volume
float positionless_volume;          // Volume for non-positional sounds (1.0)
bool sound_effects_enabled;         // Master SFX toggle

struct channel_data {
    int channel;                    // SDL_mixer channel index
    uint32_t handle;                // Unique handle for this playback
};

std::array<channel_data, 32> channels{};     // Active channel state
uint32_t next_playing_track_handle{0};        // Auto-incrementing handle counter
std::recursive_mutex channel_mutex{};         // Protects channels + handle counter
```

### Singleton Pattern

- Constructor sets `singleton = this` at `th_sound.cpp:279`
- Destructor clears `singleton` if it still points to `this` at `th_sound.cpp:298–300`
- Copy/assignment are `= delete`

### Handle System

Handles are monotonically increasing uint32 values, seeded from the current epoch seconds at construction (`th_sound.cpp:290–293`). This ensures uniqueness across save/load cycles. The special value `null_handle (0)` means "no sound."

### Channel Reservation

`reserve_channel()` (`th_sound.cpp:403–417`) iterates the channels array under `channel_mutex` to find a free slot (where `handle == null_handle`). If found, assigns the next handle. Returns -1 if all 32 channels are occupied.

### Playback Flow

`play_raw()` (`th_sound.cpp:424–447`):
1. Reserve a channel
2. Get the corresponding `MIX_Track*`
3. Set the track's audio source via `MIX_SetTrackAudio`
4. Set gain via `MIX_SetTrackGain`
5. Create SDL properties with loop count
6. Start playback via `MIX_PlayTrack`
7. Return the channel's handle

### Spatial Audio

`play_at()` (`th_sound.cpp:349–364`) computes distance attenuation:
```
distance = sqrt((x - camera_x)^2 + (y - camera_y)^2)
if distance > camera_radius: skip (inaudible)
normalized_distance = distance / camera_radius
volume = master_volume * (1.0 - normalized_distance * 0.8) * input_volume
```

### Thread Safety

- `channel_mutex` (recursive) protects `channels[]` and `next_playing_track_handle`
- `on_channel_finished()` is called from SDL_mixer's thread — it acquires no mutex directly, just calls `release_channel()` which does
- **Critical**: Never hold `channel_mutex` while calling SDL_mixer functions (`MIX_*`), as SDL_mixer has its own internal lock held during `on_channel_finished` callbacks — this would deadlock (`th_sound.h:219–224`)

### Channel Finished Callback

`on_channel_finished()` (`th_sound.cpp:303–309`) is registered per-FX-track during `populate_from()`. When a track finishes playing, the callback releases the channel, making it available for reuse.

---

## 6. Memory Management

- `sdl_mixer` uses RAII via `std::unique_ptr<sdl_mixer>` (the `mixer_ptr` alias)
- `sound_archive` owns its data in `std::vector<uint8_t>` — fully self-contained
- `sound_player` uses raw `new[]`/`delete[]` for `MIX_Audio**` array — cleaned up in `populate_from()` and destructor
- `SDL_IOStream*` from `load_sound()` is caller-managed (SDL_CloseIO)
- `populate_from(nullptr)` safely cleans up all loaded sounds before reassigning

---

## 7. Platform Support

SDL3_mixer supports the following formats via compile-time flags in `config.h`:

| Format | Extension |
|--------|-----------|
| WAV | `.wav` |
| MP3 | `.mp3` |
| OGG Vorbis | `.ogg` |
| FLAC | `.flac` |
| OPUS | `.opus` |
| WV (WavPack) | `.wv` |
| MOD | `.mod` |
| S3M | `.s3m` |
| XM | `.xm` |
| IT | `.it` |

The Theme Hospital archive stores sounds as PCM WAV data. Music and movie playback use the full SDL_mixer pipeline.

---

## 8. Integration Points

- **Lua binding**: `sound_player` is exposed to Lua for game logic control (not shown in these files)
- **[[BINARY_SPEC]]**: SOUND-0.DAT binary format details
- **[[CLASS_DIAGRAM]]**: Full class hierarchy visualization
- **[[SEQUENCE_DIAGRAM]]**: Key playback and loading flows

---

## Related Pages

- [[CLASS_DIAGRAM]] — Class hierarchy and relationships
- [[SEQUENCE_DIAGRAM]] — Playback and loading sequence flows
- [[MAP]] — File:line index for source locations
- [[BINARY_SPEC]] — SOUND-0.DAT / .PAL binary format specification
- [[../area-2-persistence/SUMMARY|Persistence System]] — Save/load game state
- [[../area-3-iso-filesystem/SUMMARY|ISO Filesystem]] — Reading game data from ISO images
