# MIDI/XMI Music — Summary

> C++ engine music path: XMI → MIDI → FluidSynth or external MIDI device.
> See [[midi-xmi/MAP]] for file:line index, [[midi-xmi/CLASS_DIAGRAM]] for types,
> [[midi-xmi/SEQUENCE_DIAGRAM]] for flows, [[midi-xmi/SPEC]] for format + backend matrix.

## 1. Overview

- **Documented fact:** Theme Hospital music is stored as XMI (single song/file, `EVNT` chunk). Two C++ sinks play it: `fluid_player` (FluidSynth, always built) and `midi_player` (RtMidi external device, only with `WITH_MIDI_DEVICE`). Lua `Audio` in `audio.lua` picks between `midi_player` and the SDL_mixer path.
- **Documented fact:** Shared conversion lives in `xmi2mid.h/cpp`: `xmi_to_midi_token_list()` for live RtMidi playback, `transcode_xmi_to_midi()` for SMF bytes (FluidSynth + SDL fallback).
- **Inference:** Design keeps original timing/behaviour on modern backends without rewriting Lua playlists: XMI quirk-handling stays in C++, backend choice stays in config + one Lua branch.
- **Hypothesis:** `fluid_player` (2026) is the intended default going forward; RtMidi path remains for hardware/DAW routing (virtual-port support).

## 2. Architecture

`audio.lua` playlist → `TH.midiPlayer` (`th_lua_midi_player` variant) → either:
(a) `fluid_player` → FluidSynth synth + SDL AudioStream, or
(b) `midi_player` → RtMidiOut + playback thread → external synth.
Fallback: `SDL.audio.transcodeXmiToMid` → `SDL.audio.loadMusicAsync/playMusic` on music track.

- **Documented fact:** `background_music` type discriminates: `number` (index sentinel) = `midi_player` active; userdata = SDL_mixer `music` object. Checked by `isPlayingWithMidiPlayer()`.
- **Documented fact:** `SDL.audio.init(findSoundFont())` and `initMidiPlayer()` both run at `Audio:init()`; either can fail independently with `pcall`/status check.

## 3. Key classes / flows

| Element | Role |
|---|---|
| `midi_player` | Owns `RtMidiOut`, port, thread, `player_command_queue`, atomic volume |
| `open_midi_port` | RAII port handle; virtual-port vs real-port branch |
| `player_command_queue` | Thread-safe stop/pause/resume/set_volume/noop queue |
| `playback_state` | Token list + cursor + adjusted start time (pause-aware) |
| `fluid_player` | Owns FluidSynth settings/synth/player + SDL AudioStream + F32 buffer |
| `th_lua_midi_player` | `variant<monostate,fluid_player[,midi_player]>` + GC `close()` |
| `midi_token` / `memory_buffer` | Intermediate event list; XMI read / SMF write cursor |

Flows: start (Lua `playBackgroundTrack` → `setVolume` → `playXmi` or transcode → async SDL); playback (`midi_player::playback_loop` sleeps to event time, sends via `midi_out_mutex`; `fluid_player` renders in SDL stream callback); stop/switch (`stopBackgroundTrack` stops both; `initMidiPlayer` closes old player).

## 4. Config gates

Compile: `WITH_MIDI_DEVICE` (empty `midi_player{}` stub when OFF); FluidSynth required. Runtime Lua: `midi_api` (""=fluid/soundfont path), `midi_port`, `midi_sysex_master_volume`, `soundfont`, `play_music`/`music_volume`, `audio_music`. See [[midi-xmi/SPEC]] matrix.

## Related

- [[midi-xmi/MAP]] — every claim → file:line
- [[midi-xmi/CLASS_DIAGRAM]] — class relations
- [[midi-xmi/SEQUENCE_DIAGRAM]] — start → playback → stop/switch
- [[midi-xmi/SPEC]] — XMI bytes, conversion math, backend selection
