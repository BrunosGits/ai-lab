# MIDI/XMI — File:Line Index

> Paths relative to repo root. All ranges read via `cat/grep/sed` and verified.

## CorsixTH/Src/midi_player.h (309 lines)

| Lines | Symbol |
|---|---|
| 41 | `struct playback_state;` fwd decl |
| 46, 51 | `midi_virtual_port_index`, `midi_external_port_name` |
| 58–100 | `class open_midi_port` (66–73 open, 82 close, 87 is_virtual) |
| 105–121 | `enum player_command` (stop/pause/resume/set_volume/noop) |
| 128–161 | `class player_command_queue` (134 push, 145 pop, 150 clear) |
| 166–301 | `class midi_player` |
| 194–195 | ctor `(api, port_name, use_master_volume_sysex)` |
| 203, 208, 215 | `api_list`, `port_list`, `set_port` |
| 221, 228 | `set_volume`, `play_xmi` |
| 235, 240, 245 | `stop`, `pause`, `resume` |
| 253, 262 | `open_default_port`, `is_port_open` |
| 270, 278 | `init_playback`, `playback_loop` (static, thread target) |
| 281, 284, 287, 290, 293, 297, 300 | `midi_out`, `port`, `playback_thread`, `command_queue`, `volume`, `use_master_volume_sysex`, `midi_out_mutex` |
| 305 | `class midi_player {};` stub when `WITH_MIDI_DEVICE` off |

## CorsixTH/Src/midi_player.cpp (608 lines)

| Lines | Symbol |
|---|---|
| 45, 51 | `midi_application_name`, `midi_virtual_port_name` |
| 59–63 | `midi_channels=16`, `midi_max_channel_volume=127` |
| 67–96 | `midi_api_from_string` (empty/Native→UNSPECIFIED, ALSA/JACK/CoreMIDI/MM/Web/UWP/AMIDI) |
| 97–128 | `midi_api_to_name` |
| 130–146 | `api_supports_virtual_port` (Core/ALSA/JACK only) |
| 148–164 | `test_midi_api` (port-count probe) |
| 167–190 | `send_stop_playback` (all-notes/sound-off + reset, all channels) |
| 192–206 | `send_all_notes_off` (pause path) |
| 208–224 | `send_gsm_enable` (GM sysex) |
| 226–257 | `send_master_volume` (14-bit sysex) |
| 259–294 | `send_control_change_volume` (CC7 per-channel + master-only overload) |
| 297–303 | `midi_music_over_callback` (SDL_USEREVENT_MUSIC_OVER) |
| 305–329 | `player_command_queue::{push,pop,clear}` |
| 331–349 | `struct playback_state` |
| 350–358 | `midi_player::ctor/dtor` (dtor calls `stop()`) |
| 360–377 | `api_list` (compiled APIs filtered by `test_midi_api`) |
| 379–393 | `port_list` (+Virtual Port where supported) |
| 395–413 | `set_port` (empty→default; name match; Virtual Port; stderr if missing) |
| 415–427 | `play_xmi` (port check → token list → `stop()` → new thread) |
| 429–449 | `set_volume` (atomic + queue), `stop` (join+clear+panic), `pause`/`resume` (queue) |
| 451–471 | `open_default_port` (first-good port, else virtual, else stderr) |
| 473–475 | `is_port_open` (virtual-port RtMidi workaround) |
| 477–495 | `init_playback` (lock, GM enable, sysex-or-CC7 volume, reset clock) |
| 497–607 | `playback_loop` (command poll, pause clock shift, end-of-track break, timed send, CC7 scaling, `midi_music_over_callback`) |

## CorsixTH/Src/fluid_player.h (89) / .cpp (135)

| Lines | Symbol |
|---|---|
| H:31–37 | `th::fluid` consts (F32, stereo, 44100 Hz, frame/period 2048) |
| H:39–87 | `class fluid_player` (41 ctor, 50 set_volume, 57 play_xmi, 64 stop, 69 pause, 74 resume, 77 callback, 80–86 members) |
| C:31–71 | ctor (SDL stream, settings: period/float/mono-groups/44100 Hz, gain 1.0, chorus/reverb, gm bank, sfload) |
| C:73–78 | dtor (stop, pause+destroy stream, delete synth/settings) |
| C:81–83 | `set_volume` via `SDL_SetAudioStreamGain` |
| C:85–101 | `play_xmi` (stop old, transcode to SMF, `new_fluid_player/add_mem/seek/play`, resume stream) |
| C:104–106 | `pause`/`resume` (`fluid_player_stop/play`) |
| C:108–117 | `stop` (stop, all-notes-off, delete player, pause stream) |
| C:120–133 | `audio_stream_callback` (`fluid_synth_write_float` → `SDL_PutAudioStreamData`) |

## CorsixTH/Src/th_lua_midi.cpp (290)

| Lines | Symbol |
|---|---|
| 36–139 | `class th_lua_midi_player` (38 fluid ctor, 42 midi ctor, 131 close) |
| 49–62, 64–75, 77–90 | `port_list` (fluid→{}), `play_xmi`, `set_volume` dispatches |
| 92–103, 105–116, 118–129 | `stop`, `pause`, `resume` dispatches |
| 135, 137 | `variant<monostate,fluid,midi>` vs `<monostate,fluid>` |
| 143–158 | `l_midi_player_api_list` ({} when no device) |
| 160–191 | `l_midi_player_new` (2-arg→fluid; api non-empty→midi else fluid) |
| 193–207, 209–220, 222–232 | `portList`, `playXmi`, `setVolume` bindings |
| 234–242, 244–252, 254–262, 264–272 | `stop`, `pause`, `resume`, `close` bindings |
| 276–290 | `lua_register_midi` (`midiPlayer`, `getAvailableApis`, portList/playXmi/setVolume/stop/pause/resume/close) |

## CorsixTH/Src/xmi2mid.h / .cpp (392)

| Lines | Symbol |
|---|---|
| H:34–53 | MIDI/Meta/CC constants (0x80–0xFF, 0x2F/0x51, CC7, 123/120/121) |
| H:65, 70–71 | `time_multiplier=100`, `xmi_ticks_per_microsecond`, `xmi_microseconds_per_tick` |
| H:73–84, 86–90 | `midi_token`, `operator<`, `midi_token_list`, converters |
| C:48–205 | `memory_buffer` (scan/read/write/VLQ/big-endian) |
| C:208–325 | `xmi_to_midi_token_list` (222 EVNT scan+skip8, 228 tempo 500000, 245 dur×100, 252–288 per-type parse + note-on/off synth, 289–324 meta/tempo-once, sort) |
| C:327–392 | `transcode_xmi_to_midi` (335 MThd type-0, 344–347 clamped division, 350 MTrk placeholder, 352–383 delta+running-status, 386–390 length patch) |

## CorsixTH/Src/sdl_audio.cpp (378) + build gates

| Lines | Symbol |
|---|---|
| 57–61 | `audio_music_over_callback` (music-track stopped → MUSIC_OVER) |
| 63–80 | `l_init(soundfont)` (`th::sound::init`, register music-track callback) |
| 93–118 | `createMusicAudio` (soundfont prop `SDL_mixer.decoder.fluidsynth.soundfont_path`) |
| 133–175, 175–191 | `l_load_music_async`, `l_load_music` |
| 192–207, 209–234 | `l_music_volume` (music-track gain), `l_play_music` |
| 236–261, 262–273 | `l_pause/resume/stop_music` |
| 274–310 | `l_transcode_xmi` (XMI→SMF string for SDL path) |
| 313–378 | async callback + `luaopen_sdl_audio` |
| config.h.in:58 | `#cmakedefine WITH_MIDI_DEVICE` |
| CMakeLists | root:39 `option(WITH_MIDI_DEVICE ON)`, 61 `if`; CorsixTH:182–200 FluidSynth required, 278–295 RtMidi iff device |

## CorsixTH/Lua/audio.lua (852) / app.lua / config_finder.lua

| Lines | Symbol |
|---|---|
| audio 38–56 | `Audio:Audio` (midi_player=nil, waveform/instructional ext sets incl XMI) |
| audio 79–141 | `Audio:init` scan (music dir vs `Sound/Midi`, 127 `is_xmi`, waveform-over-instructional) |
| audio 145–180 | playlist enable + MIDI.TXT titles/sort |
| audio 182–184 | `initMidiPlayer()` then `SDL.audio.init(findSoundFont())` |
| audio 194–220 | `initMidiPlayer` (close old, `TH.midiPlayer(api,port,sysex,soundfont)` pcall), api/port getters |
| audio 609–660 | `isPlayingWithMidiPlayer`, `pauseBackgroundTrack` (midi vs SDL branch) |
| audio 666–678 | `stopBackgroundTrack` (SDL stop + midi stop, clear) |
| audio 680–693 | `getFileData` (music-dir vs fs + RNC decompress) |
| audio 695–763 | `playBackgroundTrack` (700 play_music gate, 704 is_xmi→setVolume+playXmi+index sentinel, else transcode→loadMusicAsync→playMusic+setMusicVolume) |
| audio 765–784 | `onMusicOver` (next track), `setBackgroundVolume` (both sinks) |
| app 1593–1611 | `findSoundFont` (config + data-dir sf2/sf3 + 3 Linux paths) |
| config_finder 139–141, 164–166 | defaults (play_music/music_volume, midi_api/port=nil, sysex=false) |
| config_finder 401–402, 627, 636, 644–669 | commented template (music opts, audio_music, soundfont, midi api/port/sysex docs) |
