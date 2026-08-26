# Audio System — Sequence Diagrams

> **Mermaid sequence diagrams for key audio subsystem flows**

## 1. Sound Playback Flow

```mermaid
sequenceDiagram
    participant Lua as Lua Game Logic
    participant SP as sound_player
    participant CM as channel_mutex
    participant MIX as SDL_mixer
    participant CB as on_channel_finished

    Lua->>SP: play_at(index, volume, x, y, loops)
    SP->>SP: Bounds check index vs sound_count
    SP->>SP: Compute distance from camera
    SP->>SP: Compute attenuated volume

    SP->>SP: play_raw(index, volume, loops)
    SP->>CM: lock(channel_mutex)
    SP->>SP: reserve_channel()
    Note right of SP: Find free slot in channels[]<br/>Assign next_playing_track_handle
    SP->>CM: unlock(channel_mutex)

    SP->>MIX: get_fx_track(channel)
    MIX-->>SP: MIX_Track*

    SP->>MIX: MIX_SetTrackAudio(track, sounds[index])
    SP->>MIX: MIX_SetTrackGain(track, volume)
    SP->>MIX: MIX_PlayTrack(track, properties)
    Note right of MIX: Track begins playing asynchronously

    SP-->>Lua: handle (uint32_t)

    Note over MIX,CB: ... playback continues ...

    MIX->>CB: track stopped callback
    CB->>SP: get_singleton()
    CB->>SP: release_channel(channel)
    SP->>CM: lock(channel_mutex)
    SP->>SP: channels[channel].handle = null_handle
    SP->>CM: unlock(channel_mutex)
```

---

## 2. Pause/Resume Flow

```mermaid
sequenceDiagram
    participant Lua as Lua Game Logic
    participant SP as sound_player
    participant CM as channel_mutex
    participant MIX as SDL_mixer

    Lua->>SP: toggle_pause(handle)
    SP->>CM: lock(channel_mutex)
    SP->>SP: playing_channel_for_handle(handle)
    Note right of SP: Linear scan of channels[]<br/>matching handle
    SP->>CM: unlock(channel_mutex)

    alt Channel found
        SP->>MIX: get_fx_track(channel)
        alt Track is paused
            SP->>MIX: MIX_ResumeTrack(track)
            SP-->>Lua: resumed
        else Track is playing
            SP->>MIX: MIX_PauseTrack(track)
            SP-->>Lua: paused
        end
    else No channel found
        SP-->>Lua: error
    end
```

---

## 3. Sound Archive Loading Flow

```mermaid
sequenceDiagram
    participant Caller as Game Loader
    participant SA as sound_archive
    participant FS as Filesystem (in-memory)

    Caller->>SA: load_from_th_file(pData, iDataLength)

    SA->>SA: Validate minimum size (4 + 234 bytes)

    SA->>FS: Read last 4 bytes → headerPosition
    Note right of SA: bytes_to_uint32_le(pData + len - 4)

    SA->>SA: Bounds-check headerPosition

    SA->>FS: Read header at headerPosition + 50 → tablePosition
    SA->>FS: Read header at headerPosition + 58 → tableLength

    SA->>SA: data.resize(iDataLength) + copy
    Note right of SA: Full archive copied into vector

    SA->>SA: soundFileCount = tableLength / 32

    loop For each sound entry (i = 0..soundFileCount)
        SA->>SA: Read 32-byte entry at tablePosition + i*32
        SA->>SA: Parse sound_name (18 bytes), position (uint32), length (uint32)
        SA->>SA: sound_files.push_back(soundInfo)
    end

    SA-->>Caller: true (success)
```

---

## 4. populate_from Flow (Pre-loading All Sounds)

```mermaid
sequenceDiagram
    participant Lua as Lua Game Logic
    participant SP as sound_player
    participant SA as sound_archive
    participant MIX as SDL_mixer
    participant IO as SDL_IOStream

    Lua->>SP: populate_from(pArchive)

    alt pArchive is nullptr
        SP->>SP: Destroy all MIX_Audio in sounds[]
        SP->>SP: delete[] sounds
        SP->>SP: sounds = nullptr, sound_count = 0
    else pArchive is valid
        SP->>SP: Destroy existing sounds[] if any

        SP->>SP: sounds = new MIX_Audio*[archive.get_number_of_sounds()]

        loop For each sound (i = 0..count)
            SP->>SA: load_sound(i)
            SA->>IO: SDL_IOFromConstMem(data + position, length)
            SA-->>SP: SDL_IOStream*

            opt SDL_IOStream is valid
                SP->>MIX: MIX_LoadAudio_IO(mixer, pRwop, closeIO, true)
                MIX-->>SP: MIX_Audio*
                SP->>SP: sounds[i] = MIX_Audio*
            end
            opt SDL_IOStream is nullptr (index 0)
                SP->>SP: sounds[i] = nullptr
            end
        end
    end
```

---

## 5. Mixer Initialization Flow

```mermaid
sequenceDiagram
    participant App as Application
    participant NS as th::sound namespace
    participant SM as sdl_mixer
    participant MIX as SDL3_mixer

    App->>NS: th::sound::init()
    NS->>SM: new sdl_mixer()

    SM->>MIX: MIX_CreateMixerDevice(DEFAULT_PLAYBACK, nullptr)
    MIX-->>SM: MIX_Mixer*
    SM->>MIX: MIX_CreateTrack(mixer)
    MIX-->>SM: music_track
    SM->>MIX: MIX_CreateTrack(mixer)
    MIX-->>SM: movie_track

    loop For i = 0..31
        SM->>MIX: MIX_CreateTrack(mixer)
        MIX-->>SM: fx_channels[i]
    end

    SM-->>NS: sdl_mixer instance
    NS->>NS: mixer = make_unique<sdl_mixer>(instance)
    NS-->>App: true
```

---

## Related Pages

- [[SUMMARY]] — Full technical reference
- [[CLASS_DIAGRAM]] — Class hierarchy visualization
- [[MAP]] — Source file line index
