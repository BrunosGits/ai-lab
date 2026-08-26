# Area 24: Audio System — Technical Reference

## 1. Architecture Overview

The CorsixTH audio system is a two-layer architecture bridging Lua gameplay logic with C++ mixing hardware. The Lua `Audio` class (853 lines) orchestrates high-level concerns—playlist management, callback registration, volume policies—while the C++ `sound_player`, `sound_archive`, and `sdl_mixer` classes (469 + 227 lines) handle channel allocation, distance attenuation, and SDL3_mixer integration.

### Layer Diagram

```
┌─────────────────────────────────────────────────────┐
│  Lua Layer  (audio.lua)                             │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │  Playlist     │  │  SFX Proxy  │  │  MIDI     │ │
│  │  Manager      │  │  (TH.sound) │  │  Player   │ │
│  └──────┬───────┘  └──────┬───────┘  └─────┬─────┘ │
│─────────┼─────────────────┼────────────────┼────────│
│  C++ Layer (th_sound.h / th_sound.cpp)              │
│  ┌──────┴───────┐  ┌──────┴───────┐  ┌─────┴─────┐ │
│  │ sdl_mixer    │  │ sound_player │  │ sound_    │ │
│  │ (SDL3 mixer) │  │ (32 ch pool) │  │ archive   │ │
│  └──────────────┘  └──────────────┘  └───────────┘ │
└─────────────────────────────────────────────────────┘
```

### Key Source Files

| File | Lines | Role |
|------|-------|------|
| `CorsixTH/Lua/audio.lua` | 853 | Lua-side audio orchestration |
| `CorsixTH/Src/th_sound.h` | 227 | C++ header: class declarations |
| `CorsixTH/Src/th_sound.cpp` | 469 | C++ implementation: SDL3_mixer |
| `CorsixTH/[[Lua/entity.lua#L281]]-289` | 9 | Entity sound teardown hook |

See [[MAP]] for the complete file:line index.

---

## 2. Audio Class Initialization

The `Audio` class is instantiated once by `App` and stored as `self.app.audio`.

```lua
-- audio.lua:35-53
function Audio:Audio(app)
  self.app = app
  self.has_bg_music = false
  self.not_loaded = not app.config.audio      -- respects config.audio toggle
  self.unused_played_callback_id = 0
  self.played_sound_callbacks = {}
  self.entities_waiting_for_sound_to_be_enabled = {}
  self.midi_player = nil
  self.allowed_waveform_formats = {
    "OGG", "OPUS", "FLAC", "WV", "WAV", "WAVE",
    "MPG", "MPEG", "MP3", "MAD", "AIFF", "AIFC", "AIF"
  }
  self.allowed_instructional_formats = {
    "MID", "MIDI", "KAR", "669", "AMF", "AMS", "DBM",
    "DSM", "FAR", "GDM", "IT", "MED", "MDL", "MOD", "MOL", "MTM", "NST", "OKT", "PTM",
    "S3M", "STM", "ULT", "UMX", "WOW", "XM", "XMI"
  }
end
```

### Format Classification

The constructor splits supported formats into two families:

- **Waveform** (`allowed_waveform_formats`): container formats with decoded audio — OGG, OPUS, FLAC, WV, WAV, MP3, AIFF.
- **Instructional** (`allowed_instructional_formats`): tracker/MIDI formats — MOD, S3M, XM, IT, MIDI, XMI.

Waveform files are preferred over instructional files when both exist for the same base name (line 132-136). This prevents a user-supplied MP3 from being shadowed by an original MIDI.

### Guard: `not_loaded`

When `config.audio` is `false`, `not_loaded` is set `true` at construction time (line 39). Every public method checks this flag early and returns without action, so the rest of the codebase can call audio methods unconditionally.

---

## 3. Background Track Playlist System

### 3.1 Playlist Construction (`Audio:init`, lines 71-192)

The `init()` method builds `self.background_playlist` — an array of info tables:

```lua
-- Each entry: { title, filename, filename_music, enabled, music, is_xmi, index }
```

**Discovery flow:**

1. If `config.audio_music` (or legacy `config.audio_mp3`) is set, scan that directory via `lfs.dir` (line 114).
2. Otherwise, scan the game's virtual filesystem at `Sound/Midi` (line 116).
3. For each file, check the extension against the waveform/instructional sets.
4. If a waveform file exists, it takes the `filename_music` slot (line 133). Instructional files only fill `filename_music` when no waveform already occupies it (line 135-136).
5. If a `midi.txt` / `names.txt` file is found, titles are read from it and the playlist is sorted by index order (line 171). Otherwise, alphabetical by title (line 173).

**RNC Decompression:** Both speech archive data and music file data may be RNC-compressed. The `rnc` module is called at load time:

```lua
-- audio.lua:689-691
if data:sub(1, 3) == "RNC" then
  data = assert(rnc.decompress(data))
end
```

See [[CHECKLIST]] item 3.1 for RNC regression testing guidance.

### 3.2 Random Playback (`Audio:playRandomBackgroundTrack`, line 553)

Collects enabled playlist entries and picks one uniformly at random:

```lua
local enabled = {}
for i, info in ipairs(self.background_playlist) do
  if info.enabled then
    enabled[#enabled + 1] = i
  end
end
local index = enabled[math.random(1, #enabled)]
```

### 3.3 Sequential Navigation (lines 580-608)

`playNextOrPreviousBackgroundTrack(direction)` wraps around the playlist cyclically using modular arithmetic:

```lua
local next_index = ((index + direction * i - 1) % #self.background_playlist) + 1
```

Direction `+1` = next, `-1` = previous.

### 3.4 Track Lifecycle (lines 698-765)

`playBackgroundTrack(index)` has three code paths depending on format:

1. **XMI with MIDI player:** Calls `midi_player:playXmi(data)` directly. Returns early.
2. **XMI without MIDI player:** Transcodes to MIDI via `SDL.audio.transcodeXmiToMid(data)`, then falls through to path 3.
3. **All other formats:** Uses `SDL.audio.loadMusicAsync(data, callback)` for non-blocking load. On success, calls `SDL.audio.playMusic(music)`.

The async load path sets `self.load_music = true` before starting and checks it inside the callback. If the user stopped music during loading, the callback no-ops.

### 3.5 Pause/Resume (lines 617-662)

`pauseBackgroundTrack()` is a toggle. When pausing:

1. For MIDI player: calls `midi_player:pause()`.
2. For SDL music: calls `SDL.audio.pauseMusic()`, then mutes by setting volume to 0.
3. If SDL reports `false` (unsupported format), falls back to full stop.

The volume is saved in `self.old_bg_music_volume` and restored on resume.

---

## 4. Sound Effects Playback

### 4.1 `playSound` (lines 330-358)

The primary entry point for positional sound effects:

```lua
function Audio:playSound(name, where, is_announcement, played_callback,
                         played_callback_delay, loops)
```

**Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `name` | string | Archive filename, may contain `*` wildcards |
| `where` | Entity | Positional source, or `nil` for non-positional |
| `is_announcement` | boolean | Uses `announcement_volume` if true |
| `played_callback` | function | Called when sound finishes |
| `played_callback_delay` | integer | Milliseconds before callback fires |
| `loops` | integer | `-1` for infinite looping |

**Callback registration (lines 337-341):** Each callback is assigned a unique integer ID, stored as a string key in `self.played_sound_callbacks`:

```lua
played_callback_id = self.unused_played_callback_id
self.unused_played_callback_id = self.unused_played_callback_id + 1
self.played_sound_callbacks[tostring(played_callback_id)] = played_callback
```

**Positional calculation (lines 343-347):** The world-space tile coordinate is converted to screen-space via `Map:WorldToScreen`, then adjusted by the entity's sprite offset and the UI's screen offset.

### 4.2 Wildcard Sound Resolution (lines 402-427)

Sound names containing `*` are resolved by matching against all filenames in the sound archive:

```lua
function Audio:resolveFilenameWildcard(name)
  if name:find("*") then
    local list = self:cacheSoundFilenamesAssociatedWithName(name)
    name = list[1] and list[math.random(1, #list)] or name
  end
  return name
end
```

Results are cached in the permanent `wilcard_cache` table (line 312) to avoid re-scanning the archive on every play.

### 4.3 Entity Sound Sequences (`playEntitySounds`, lines 469-524)

This system plays a sequence of related sounds (e.g., lava bubbling) with random inter-sound silence:

```lua
function Audio:playEntitySounds(names, entity, min_silence_lengths,
                                 max_silence_lengths, num_silences)
```

Silence durations are speed-dependent, indexed by `TheApp.world.tick_rate`:

| Index | Speed |
|-------|-------|
| 1 | Slowest |
| 2 | Slow |
| 3 | Normal |
| 4 | Fast |
| 5 | Maximum |

The handler recurses via a played_callback, creating a self-sustaining loop until `entity.playing_sounds_in_random_sequence` becomes `false`.

### 4.4 Deferred Playback Queue (lines 515-518)

When sounds cannot be played (game paused or sound effects disabled), entities are stored in `self.entities_waiting_for_sound_to_be_enabled`. When sounds are re-enabled (`playSoundEffects`, line 796) or the game unpauses (`onEndPause`, line 526), all waiting entities are notified:

```lua
function Audio:tellInterestedEntitiesTheyCanNowPlaySounds()
  for entity, callback in pairs(self.entities_waiting_for_sound_to_be_enabled) do
    callback()
    self.entities_waiting_for_sound_to_be_enabled[entity] = nil
  end
end
```

Entities register for this via `entity:setWaitingForSoundEffectsToBeTurnedOn(true)` and deregister on destroy at [[entity.lua:281-289]].

---

## 5. C++ Sound Infrastructure

### 5.1 `sdl_mixer` Wrapper (th_sound.h:36-62)

Wraps SDL3_mixer's `MIX_Mixer` and its tracks:

- **1 music track** for background music
- **1 movie track** for cutscene audio
- **32 FX tracks** (`number_of_fx_channels`) for simultaneous sound effects

```cpp
// th_sound.cpp:43-66
sdl_mixer::sdl_mixer() {
  mixer = MIX_CreateMixerDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, nullptr);
  music_track = MIX_CreateTrack(mixer);
  movie_track = MIX_CreateTrack(mixer);
  for (auto& track : fx_channels) {
    track = MIX_CreateTrack(mixer);
  }
}
```

### 5.2 `sound_archive` Class (th_sound.h:73-101)

Parses Theme Hospital's `SOUND-0.DAT` format:

1. Reads the header position from the last 4 bytes of the file (th_sound.cpp:114).
2. Extracts table position and length from the header (th_sound.cpp:124-127).
3. Each sound entry is 32 bytes: 18-byte name + 4-byte position + 4-byte length (th_sound.cpp:93-97).
4. Index 0 is intentionally invalid — it represents the entire file due to a legacy bug (th_sound.cpp:254-260).

**Duration calculation** (th_sound.cpp:177-251): A minimal RIFF parser extracts sample rate, channels, bits per sample, and data length to compute duration in milliseconds.

### 5.3 `sound_player` Class (th_sound.h:103-225)

Manages 32 channels with a handle-based API:

```cpp
// Channel lifecycle:
uint32_t play(size_t iIndex, double dVolume, int loops);     // non-positional
uint32_t play_at(size_t iIndex, int iX, int iY, int loops); // positional
void stop(uint32_t handle);
toggle_pause_result toggle_pause(uint32_t handle);
bool is_playing(uint32_t handle);
```

**Channel allocation** (th_sound.cpp:403-417): Channels are recycled via `reserve_channel()`. Handle uniqueness is guaranteed by seeding `next_playing_track_handle` from the current epoch seconds (th_sound.cpp:290-293).

**Distance attenuation** (th_sound.cpp:349-363):

```cpp
double fDistance = sqrt(fDX * fDX + fDY * fDY);
if (fDistance > camera_radius) return null_handle;  // outside hearing range
fDistance = fDistance / camera_radius;               // normalize to 0..1
double fVolume = master_volume * (1.0 - fDistance * 0.8) * dVolume;
```

Sounds beyond `camera_radius` are silently dropped — the entity simply doesn't play.

**Thread safety** (th_sound.h:219-224): A `std::recursive_mutex` protects the channels array. The comment explicitly warns against holding this mutex during SDL_mixer calls to avoid deadlocks with the internal `on_channel_finished` callback.

---

## 6. Volume Control

### 6.1 `setBackgroundVolume` (audio.lua:774-785)

Dual-path depending on MIDI player vs SDL:

```lua
function Audio:setBackgroundVolume(volume)
  if self.midi_player then
    self.app.config.music_volume = volume
    self.midi_player:setVolume(volume)
  end
  if self.background_paused then
    self.old_bg_music_volume = volume
  else
    self.app.config.music_volume = volume
    SDL.audio.setMusicVolume(volume)
  end
end
```

### 6.2 `setSoundVolume` (audio.lua:787-794)

Propagates to both Lua config and C++ sound player:

```lua
function Audio:setSoundVolume(volume)
  self.app.config.sound_volume = volume
  if self.sound_fx then
    self.sound_fx:setSoundVolume(volume)
  end
end
```

### 6.3 Volume Sources

Three distinct volume axes are managed:

| Axis | Config Key | Lua Method | C++ Method |
|------|-----------|------------|------------|
| Background music | `music_volume` | `setBackgroundVolume` | `SDL.audio.setMusicVolume` |
| Sound effects | `sound_volume` | `setSoundVolume` | `sound_fx:setSoundVolume` |
| Announcements | `announcement_volume` | `setAnnouncementVolume` | N/A (applied per-play) |

See [[CHECKLIST]] item 2.2 for volume persistence verification.

---

## 7. MIDI Subsystem

### 7.1 Conditional Compilation (audio.lua:194-212)

MIDI support depends on `TH.GetCompileOptions().midi_device`:

```lua
function Audio:initMidiPlayer()
  if TH.GetCompileOptions().midi_device and self.app.config.midi_api then
    local midi_ok, midi_player = pcall(
      TH.midiPlayer,
      self.app.config.midi_api,
      self.app.config.midi_port,
      self.app.config.midi_sysex_master_volume)
    if midi_ok then
      self.midi_player = midi_player
    end
  end
end
```

### 7.2 MIDI API Selection

The config supports multiple backends:

| API | Platform | Config Value |
|-----|----------|-------------|
| FluidSynth | Default | `nil` |
| Native | Platform-detected | `"Native"` |
| ALSA | Linux | `"ALSA"` |
| JACK | Unix | `"JACK"` |
| CoreMIDI | macOS | `"CoreMIDI"` |
| WindowsMM | Windows | `"WindowsMM"` |

### 7.3 XMI Transcoding

XMI files (the original TH music format) get special treatment:

```lua
-- audio.lua:705-724
if info.is_xmi then
  if self.midi_player then
    -- Play directly through MIDI player
    self.midi_player:playXmi(data)
    return
  end
  -- Transcode to MIDI for SDL_mixer
  data = SDL.audio.transcodeXmiToMid(data)
end
```

---

## 8. Sound Archive Format

The `TH.soundArchive()` Lua binding wraps the C++ `sound_archive` class. Key methods:

| Method | Returns | Description |
|--------|---------|-------------|
| `:load(data)` | boolean | Parse RNC-compressed `.dat`/`.pal` data |
| `:getFilename(index)` | string | Sound name at position |
| `:getDuration(index)` | integer | Duration in milliseconds |
| `:getFileData(index)` | string | Raw PCM data |
| `:soundExists(sound)` | boolean | Name or index lookup |
| `#archive` | integer | Number of sounds (including invalid index 0) |

### RNC Decompression

Sound archive data may be RNC-compressed (audio.lua:263-264):

```lua
if archive_data:sub(1, 3) == "RNC" then
  archive_data = assert(rnc.decompress(archive_data))
end
```

---

## 9. Jukebox Integration

The Audio class notifies the jukebox UI window of state changes:

```lua
-- audio.lua:826-831
function Audio:notifyJukebox()
  local jukebox = TheApp.ui and TheApp.ui:getWindow(UIJukebox)
  if jukebox then
    jukebox:updatePlayButton()
  end
end
```

This is called from `playBackgroundTrack`, `stopBackgroundTrack`, and `pauseBackgroundTrack`. The jukebox is a UI overlay that displays the current track title and provides next/previous controls.

---

## 10. Channel Reservation API

For exclusive sound effect channels (e.g., long-running environmental sounds):

```lua
local channel = TheApp.audio:reserveChannel()
-- ... use channel for exclusive playback ...
TheApp.audio:releaseChannel(channel)
```

Returns `-1` if no channels are available. This maps to `sound_player::reserve_channel()` / `sound_player::release_channel()` in C++.

---

## 11. Teardown (`Audio:destroy`, lines 847-853)

```lua
function Audio:destroy()
  self.has_bg_music = false
  self.not_loaded = not TheApp.config.audio
  self.speech_file_name = nil
  self.sound_fx = nil
  SDL.audio.destroy()
end
```

Note that `sound_fx` is set to `nil` but not explicitly freed — the C++ `sound_player` singleton is destroyed by `SDL.audio.destroy()`.

---

## 12. Error Handling Patterns

### Graceful Degradation

The audio system is designed to degrade silently:

1. `not_loaded` flag suppresses all operations when audio is disabled.
2. `sound_fx` nil checks appear in every playback method.
3. Failed music loads disable the track and show a one-time warning (line 736-739).
4. SDL failures are logged to `gameLog` but never crash.

### Error Messages

| Condition | Message |
|-----------|---------|
| SDL audio init failure | `"Audio system could not initialise (SDL error: ...)"` |
| No sound archive | `"No sound effects as no SOUND/DATA/... file found"` |
| Music load failure | Displays `errors.music` UI notification (once per session) |
| Missing soundfont | `"Required soundfont is not found, please download one."` |

See [[SCAFFOLD]] for test templates covering these paths.

---

## Related Pages

- [[MAP]] — File:line index for rapid navigation across all audio source files
- [[SCAFFOLD]] — Busted test templates for audio system unit/integration tests
- [[CHECKLIST]] — Pre-fix verification checklist with priority-ordered items
