# MIDI/XMI — Format + Conversion + Backend Spec

## 1. XMI input (as consumed here) — Documented fact

- Single song per file; `TIMB` chunk skipped (zero-length/gibberish on TH tracks).
- Must contain `EVNT` chunk: `scan_to("EVNT")+skip(8)` else `XMI EVNT chunk not found`.
- Timing: 120 ticks/s. Duration bytes have high-bit clear and accumulate (`dur×time_multiplier`); event bytes have high-bit set. Zero durations omitted.
- Event IDs reuse MIDI status nibbles: `0x8n/0xAn/0xBn/0xEn` two data bytes; `0xCn/0xDn` one; `0x9n` note+velocity plus separate VLQ duration → synthesised note-off (note-on vel 0); `0xFn` meta (`0xFF` + subtype + VLQ + payload).
- Tempo: first `0xFF 0x51` wins (`skip(1)` + BE24); later ones dropped (token popped + skipped). Default `500000` µs/qn. `0xFF 0x2F` ends parse. Tokens sorted by time.

## 2. Conversion — Documented fact

- `xmi_to_midi_token_list(data,len,&tempo)`: null→invalid_argument; EOF mid-event→`unexpected end of XMI data`; returns sorted `midi_token{time,type,data,buffer}` with `time` in scaled ticks.
- Scale: `time_multiplier=100`; `ticks_per_us=(3×100)/25000`; `us_per_tick=25000/(3×100)`. Rationale in header: reduce 120 Hz→µs/qn rounding; value 100 gives division 10000 on fastest TH tempo.
- `transcode_xmi_to_midi()`: empty→nullptr; writes `MThd 6 type-0 1 track`; `division=clamp(round(tempo×ticks_per_us),1,0x7FFF)` BE16; `MTrk` with placeholder length, deltas as VLQ with running status, meta verbatim incl `0x2F`; patches BE32 length; caller `delete[]`s (SDL binding does; Fluid wraps in `unique_ptr`).
- **Inference:** clamp + placeholder-patch keeps files valid for picky SMF players (FluidSynth/SDL_mixer) without two-pass sizing.

## 3. Playback semantics — Documented fact unless noted

- RtMidi: `init_playback` sends GM-on then volume (sysex 14-bit master if `midi_sysex_master_volume` else CC7=127×volume); loop polls queue (blocking only when paused), shifts `adjusted_start_time` on resume, scales live CC7 events and caches raw per-channel for later `set_volume`; stop sends all-notes+all-sound+reset on 16 channels (unresumable); pause sends all-notes-off only.
- Fluid: SDL owns volume (`synth.gain=1.0`, `SDL_SetAudioStreamGain`); `play_xmi` replaces player object; `stop` all-notes-off + destroy + pause stream; render loop `fluid_synth_write_float(2048 frames stereo F32)` in stream callback (44100 Hz, gm bank, FluidSynth chorus/reverb defaults in code).
- Completion: RtMidi pushes `SDL_USEREVENT_MUSIC_OVER` from worker; SDL path uses music-track stopped callback; Lua `onMusicOver` advances playlist either way.

## 4. Backend selection matrix — Documented fact

| midi_api | WITH_MIDI_DEVICE | Result |
|---|---|---|
| "" (empty)/nil | either | `fluid_player(soundfont)`; XMI via Fluid; others via SDL_mixer+soundfont prop |
| "Native"/"ALSA"/"JACK"/"CoreMIDI"/"Windows MM"/"Web MIDI API"[/"Windows UWP"/"Android AMidi" RtMidi6+] | ON | `midi_player(api,port,sysex)`; XMI streamed as timed RtMidi msgs |
| any api string | OFF | API ignored, falls through to `fluid_player(soundfont)` |
| XMI but `midi_player` nil/failed | either | `transcodeXmiToMid` → SDL_mixer async path |
| non-XMI / custom `audio_music` dir | either | SDL_mixer path only (`midi_api` unused) |

Port: `""`/nil→first working port else virtual (ALSA/JACK/CoreMIDI only) else stderr; name→exact match; `"Virtual Port"`→virtual. `portList()` mirrors this (fluid→`{}`). SoundFont: `findSoundFont()` order config→data-dir `FluidR3_GM.sf2`/`FluidR3.sf3`→3 Linux paths; feeds both `fluid_player` and SDL `fluidsynth.soundfont_path`.

## Related

- [[midi-xmi/SUMMARY]] — overview
- [[midi-xmi/MAP]] — file:line proof
- [[midi-xmi/SEQUENCE_DIAGRAM]] — runtime order
