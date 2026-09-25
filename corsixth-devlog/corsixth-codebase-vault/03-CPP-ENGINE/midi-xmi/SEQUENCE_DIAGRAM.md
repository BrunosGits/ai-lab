# MIDI/XMI — Sequence Diagram

## Music start → playback → stop / backend switch

```mermaid
sequenceDiagram
    participant CFG as config+CMake
    participant AU as Audio(Lua)
    participant MP as midiPlayer(variant)
    participant FL as fluid_player
    participant RT as midi_player/RtMidi
    participant SD as SDL_mixer/music-track

    Note over CFG: WITH_MIDI_DEVICE gates RtMidi build;<br/>midi_api/port/sysex+soundfont gate runtime
    AU->>AU: init(): scan playlist, flag is_xmi
    AU->>MP: TH.midiPlayer(api, port, sysex, soundfont)
    alt api non-empty + device build
        MP->>RT: midi_player(api, port, sysex)
        RT->>RT: set_port()/open_default_port()
    else
        MP->>FL: fluid_player(soundfont)
        FL->>FL: new_fluid_settings/synth/sfload + SDL stream
    end
    AU->>SD: SDL.audio.init(findSoundFont())

    AU->>AU: playBackgroundTrack(i)
    AU->>AU: getFileData(i) + RNC decode if needed
    alt is_xmi + midiPlayer present
        AU->>MP: setVolume(music_volume)
        MP->>FL: SDL_SetAudioStreamGain / MP->>RT: queue set_volume
        AU->>MP: playXmi(xmi_bytes)
        alt fluid
            FL->>FL: transcode_xmi_to_midi() → fluid_player_add_mem/play
            FL->>SD: SDL_ResumeAudioStreamDevice (callback renders)
        else RtMidi
            RT->>RT: xmi_to_midi_token_list() → spawn playback_loop
            RT->>RT: init_playback(): GM enable + volume
            loop timed send
                RT->>RT: sleep to event time; send via midi_out_mutex; scale CC7
            end
            RT->>AU: SDL_USEREVENT_MUSIC_OVER on end
        end
        AU->>AU: background_music=index (number sentinel)
    else waveform / no midiPlayer
        AU->>SD: transcodeXmiToMid() if XMI
        AU->>SD: loadMusicAsync(data, cb) → playMusic + setMusicVolume
        AU->>AU: background_music=music userdata
    end
    AU->>AU: onMusicOver() → playNextBackgroundTrack()

    alt pause/resume
        AU->>MP: pause()/resume() if number sentinel; else SDL pause/resume
    end
    alt stop or backend switch
        AU->>SD: stopMusic()
        AU->>MP: stop() (RtMidi: join+panic; Fluid: all-notes-off+pause)
        AU->>AU: background_music=nil
        AU->>MP: initMidiPlayer() closes + re-creates on settings change
    end
```

## Related

- [[midi-xmi/SUMMARY]] — architecture + gates
- [[midi-xmi/MAP]] — line index for each arrow
- [[midi-xmi/SPEC]] — conversion + selection matrix
