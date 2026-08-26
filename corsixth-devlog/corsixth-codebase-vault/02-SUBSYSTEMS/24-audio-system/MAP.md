# Area 24: Audio System — File:Line Index

## Lua Source

### audio.lua (853 lines)

| Line(s) | Symbol / Block | Description |
|---------|---------------|-------------|
| 21-28 | Imports | `pathsep`, `rnc`, `lfs`, `SDL`, `TH`, `ipairs` |
| 30 | `class "Audio"` | Class declaration |
| 35-53 | `Audio:Audio()` | Constructor — initializes format lists, callback tables |
| 44-47 | `allowed_waveform_formats` | OGG, OPUS, FLAC, WV, WAV, MP3, AIFF etc. |
| 48-52 | `allowed_instructional_formats` | MID, MOD, S3M, XM, IT etc. |
| 55-59 | `Audio:clearCallbacks()` | Reset all callback state |
| 61-69 | `GetFileData()` | Local utility — reads file contents |
| 71-192 | `Audio:init()` | Playlist construction, music discovery, SDL init |
| 72-74 | `background_playlist` | Empty playlist initialization |
| 88-97 | `musicFileTable()` | Local closure for filename-keyed info tables |
| 108-142 | Music file discovery loop | Scans directory for waveform/instructional files |
| 144-180 | Playlist population | Enables tracks, applies midi.txt ordering |
| 182 | `initMidiPlayer()` | Delegates to MIDI initialization |
| 184-191 | `SDL.audio.init()` | SDL audio subsystem initialization |
| 194-212 | `Audio:initMidiPlayer()` | Conditional MIDI player creation |
| 214-224 | `getMidiApiList` / `getMidiPortList` | MIDI introspection |
| 226-279 | `Audio:initSpeech()` | Speech archive loading (Sound-0.dat) |
| 263-264 | RNC decompression | `rnc.decompress()` for compressed archives |
| 282-289 | `Audio:setSoundStage()` | Camera position for positional audio |
| 291-310 | `Audio:dumpSoundArchive()` | Debug dump utility |
| 312 | `wilcard_cache` | Permanent cache for wildcard resolution |
| 315-358 | `Audio:playSound()` | Primary sound effect playback |
| 337-341 | Callback registration | Assigns IDs to `played_sound_callbacks` |
| 343-347 | Position calculation | WorldToScreen + sprite offset |
| 360-371 | `Audio:togglePauseSound()` | Pause/resume a playing sound |
| 373-386 | `Audio:stopSound()` | Stop and destroy a playing sound |
| 388-400 | `Audio:isPlaying()` | Check if sound is still playing |
| 402-417 | `Audio:cacheSoundFilenamesAssociatedWithName()` | Wildcard cache builder |
| 419-427 | `Audio:resolveFilenameWildcard()` | Resolve `*` in sound names |
| 439-453 | `getSilenceLengths()` | Local — speed-dependent silence generator |
| 469-475 | `Audio:playEntitySounds()` | Entity sound sequence entry point |
| 477-479 | `canSoundsBePlayed()` | Local — checks play_sounds + world state |
| 494-524 | `Audio:entitySoundsHandler()` | Recursive entity sound sequencer |
| 526-530 | `Audio:onEndPause()` | Unpause handler |
| 532-539 | `Audio:onSoundPlayed()` | Callback dispatcher |
| 541-551 | `Audio:soundExists()` | Archive lookup wrapper |
| 553-568 | `Audio:playRandomBackgroundTrack()` | Random playlist selection |
| 570-578 | `Audio:findIndexOfCurrentTrack()` | Current track lookup |
| 580-600 | `Audio:playNextOrPreviousBackgroundTrack()` | Cyclic navigation |
| 602-608 | `playNext` / `playPrevious` | Convenience wrappers |
| 610-612 | `Audio:isPlayingWithMidiPlayer()` | MIDI player active check |
| 614-662 | `Audio:pauseBackgroundTrack()` | Pause/resume toggle with volume save |
| 664-678 | `Audio:stopBackgroundTrack()` | Full stop |
| 680-693 | `Audio:getFileData()` | Read and decompress playlist entry |
| 695-765 | `Audio:playBackgroundTrack()` | Async music load + playback |
| 705-724 | XMI handling | MIDI player vs transcode path |
| 727-756 | Async load callback | Error handling + deferred playback |
| 767-772 | `Audio:onMusicOver()` | Track end handler — plays next |
| 774-785 | `Audio:setBackgroundVolume()` | Music volume control |
| 787-794 | `Audio:setSoundVolume()` | SFX volume control |
| 796-806 | `Audio:playSoundEffects()` | Toggle sound effects on/off |
| 808-815 | `Audio:tellInterestedEntitiesTheyCanNowPlaySounds()` | Flush deferred queue |
| 817-819 | `Audio:entityNoLongerWaitingForSoundsToBeTurnedOn()` | Entity deregistration |
| 821-823 | `Audio:setAnnouncementVolume()` | Announcement volume |
| 825-831 | `Audio:notifyJukebox()` | Jukebox UI update |
| 833-845 | `Audio:reserveChannel()` / `releaseChannel()` | Exclusive channel API |
| 847-853 | `Audio:destroy()` | Teardown |

### entity.lua (relevant excerpt)

| Line(s) | Description |
|---------|-------------|
| 281-289 | `Entity:onDestroy()` — clears sound effect waiting state |

## C++ Source

### th_sound.h (227 lines)

| Line(s) | Symbol | Description |
|---------|--------|-------------|
| 36-62 | `th::sound::sdl_mixer` | SDL3_mixer wrapper class |
| 38 | `number_of_fx_channels` | Constant: 32 |
| 42-44 | `get_music_track` / `get_movie_track` / `get_fx_track` | Track accessors |
| 55 | `get_mixer()` | Returns `MIX_Mixer*` |
| 66-68 | `init()` / `quit()` / `get_mixer()` | Namespace-level functions |
| 73-101 | `sound_archive` | Theme Hospital `.dat` parser |
| 93-97 | `sound_dat_sound_info` | Per-sound metadata struct |
| 103-225 | `sound_player` | Channel-based sound player |
| 105 | `toggle_pause_result` | Enum: error, paused, resumed |
| 106 | `null_handle` | Constant: 0 |
| 107 | `number_of_channels` | Constant: 32 |
| 126-152 | `play` / `play_at` | Playback methods |
| 158 | `toggle_pause` | Pause/resume by handle |
| 163 | `stop` | Stop by handle |
| 169-173 | `set_sound_effect_volume` / `set_sound_effects_enabled` | Volume/mute |
| 176 | `set_camera` | Positional audio camera |
| 184-187 | `reserve_channel` / `release_channel` | Exclusive channel API |
| 204-224 | Private members | `sounds`, `channels`, `channel_mutex` |

### th_sound.cpp (469 lines)

| Line(s) | Symbol | Description |
|---------|--------|-------------|
| 40-97 | `th::sound` namespace | SDL_mixer init/quit |
| 43-66 | `sdl_mixer::sdl_mixer()` | Creates mixer + tracks |
| 68-71 | `sdl_mixer::~sdl_mixer()` | Destroys mixer |
| 83-96 | `init()` / `quit()` / `get_mixer()` | Global mixer management |
| 99-106 | Archive constants | Header offsets and entry sizes |
| 107-149 | `sound_archive::load_from_th_file()` | Binary format parser |
| 151-165 | `get_number_of_sounds` / `get_sound_name` | Accessors |
| 177-251 | `get_sound_duration()` | WAV RIFF parser for duration |
| 253-265 | `load_sound()` | Returns `SDL_IOStream` for a sound |
| 267-301 | `sound_player` constructor/destructor | Channel init, singleton management |
| 303-311 | `on_channel_finished()` | Static callback for channel release |
| 313-331 | `populate_from()` | Loads all sounds from archive |
| 333-364 | `play()` / `play_at()` | Playback with distance attenuation |
| 366-393 | `toggle_pause()` / `stop()` / `is_playing()` | Channel control |
| 395-401 | `set_sound_effect_volume` / `set_sound_effects_enabled` | Config setters |
| 403-422 | `reserve_channel()` / `release_channel()` | Handle-based channel allocation |
| 424-447 | `play_raw()` | Core playback implementation |
| 449-454 | `set_camera()` | Camera position setter |
| 456-469 | `playing_channel_for_handle()` | Handle-to-channel lookup |


## Related Pages

- [[CHECKLIST]]
- [[SUMMARY]]
