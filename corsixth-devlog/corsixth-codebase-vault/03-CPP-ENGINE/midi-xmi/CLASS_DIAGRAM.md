# MIDI/XMI — Class Diagram

```mermaid
classDiagram
    class open_midi_port {
        -RtMidiOut midi_out
        -uint port
        +open_midi_port(RtMidiOut, uint)
        +~open_midi_port()
        +is_virtual() bool
        +get_port() uint
    }
    class player_command {
        <<enum>>
        stop
        pause
        resume
        set_volume
        noop
    }
    class player_command_queue {
        -mutex mut
        -queue queue
        -condition_variable cv
        +push(player_command)
        +pop(bool) player_command
        +clear()
    }
    class midi_player {
        -unique_ptr~RtMidiOut~ midi_out
        -optional~open_midi_port~ port
        -thread playback_thread
        -player_command_queue command_queue
        -atomic~double~ volume
        -bool use_master_volume_sysex
        -mutex midi_out_mutex
        +midi_player(api, port, sysex)
        +api_list() vector~string~
        +port_list() vector~string~
        +set_port(string)
        +set_volume(double)
        +play_xmi(bytes, len)
        +stop()
        +pause()
        +resume()
        -open_default_port()
        -is_port_open() bool
        -init_playback(state)$
        -playback_loop(state)$
    }
    class playback_state {
        +midi_player player
        +player_command_queue queue
        +midi_token_list events
        +size_t current_event_index
        +time_point adjusted_start_time
    }
    class fluid_player {
        -fluid_settings_t* settings
        -fluid_synth_t* synth
        -fluid_player_t* player
        -int soundfont_id
        -SDL_AudioStream* audio_stream
        -array~float~ buffer
        +fluid_player(soundfont)
        +set_volume(double)
        +play_xmi(bytes, len)
        +stop()
        +pause()
        +resume()
        -audio_stream_callback()$
    }
    class th_lua_midi_player {
        -variant~monostate,fluid,midi~ player
        +th_lua_midi_player(soundfont)
        +th_lua_midi_player(api, port, sysex)
        +port_list() vector~string~
        +play_xmi(bytes, len)
        +set_volume(double)
        +stop()
        +pause()
        +resume()
        +close()
    }
    class midi_token {
        +int time
        +uint8 type
        +uint8 data
        +vector~uint8~ buffer
    }
    midi_player *-- open_midi_port : optional owns
    midi_player *-- player_command_queue : owns
    midi_player ..> playback_state : drives
    playback_state --> player_command_queue : polls
    th_lua_midi_player --> fluid_player : variant holds
    th_lua_midi_player --> midi_player : variant holds
    midi_player ..> midi_token : plays
    fluid_player ..> midi_token : via transcode
```

| Relation | Note |
|---|---|
| `midi_player` → `open_midi_port` | `optional`; re-emplaced on `set_port`/default open |
| `midi_player` → thread | `stop()` joins; one song per thread lifetime |
| `th_lua_midi_player` → backends | `std::visit`; `monostate` = closed; fluid `portList` = `{}` |
