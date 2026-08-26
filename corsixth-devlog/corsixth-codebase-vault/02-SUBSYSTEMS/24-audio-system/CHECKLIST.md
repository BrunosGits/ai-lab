# Area 24: Audio System — Pre-Fix Verification Checklist

## Critical

- [ ] **1.1** `Audio:playSound` returns `{handle, played_callback_id}` table, not bare values — verify all callers index `.handle` (audio.lua:356)
- [ ] **1.2** Callback IDs are stored as **string keys** (`tostring(played_callback_id)`) — ensure no caller passes numeric keys to `played_sound_callbacks` (audio.lua:340, audio.lua:534)
- [ ] **1.3** `sound_archive` index 0 is intentionally invalid — do NOT add bounds-checking that starts at 0 (th_sound.cpp:254-260)
- [ ] **1.4** `SDL.audio.destroy()` must be called exactly once during teardown — verify no double-call paths from both `Audio:destroy` and app shutdown (audio.lua:852)

## High

- [ ] **2.1** `config.audio = false` sets `not_loaded = true` at construction — verify no method bypasses this guard and attempts SDL calls (audio.lua:39)
- [ ] **2.2** Volume persistence: `setBackgroundVolume` must save to `self.app.config.music_volume` even when paused (audio.lua:779-781)
- [ ] **2.3** `pauseBackgroundTrack` saves/restores volume via `old_bg_music_volume` — verify no path leaves the saved volume stale (audio.lua:651-657)
- [ ] **2.4** RNC decompression must succeed or the load path must print an error — verify `rnc.decompress` return is wrapped in `assert()` (audio.lua:264, audio.lua:690)
- [ ] **2.5** Wildcard cache uses permanent storage (`wilcard_cache`) — verify cache invalidation is not needed when the sound archive is reloaded (audio.lua:312)
- [ ] **2.6** Entity sound sequences (`entitySoundsHandler`) must check `entity.playing_sounds_in_random_sequence` before recursing — verify no infinite loop if entity is destroyed mid-sequence (audio.lua:495-524)

## Medium

- [ ] **3.1** `init()` music discovery: waveform files override instructional files of the same base name — verify `filename_music` assignment priority (audio.lua:129-136)
- [ ] **3.2** Playlist sorting: `midi.txt` presence triggers index-based sort; absence triggers alphabetical — verify the `table.sort` comparator handles missing `.index` field (audio.lua:171-173)
- [ ] **3.3** Async music load: `self.load_music` flag prevents playback if user stopped music during load — verify the callback checks this flag (audio.lua:730-755)
- [ ] **3.4** `playNextOrPreviousBackgroundTrack` wraps around using modular arithmetic — verify no off-by-one when `direction = -1` (audio.lua:594)
- [ ] **3.5** `initMidiPlayer` closes previous player before creating new one — verify no resource leak from the `pcall(self.midi_player.close, ...)` path (audio.lua:195-197)
- [ ] **3.6** `tellInterestedEntitiesTheyCanNowPlaySounds` clears the entry from the table during iteration — verify this is safe with Lua `pairs()` (audio.lua:810-814)

## Low

- [ ] **4.1** `dumpSoundArchive` is a debug utility — verify it is not reachable from production code paths (audio.lua:291-310)
- [ ] **4.2** `canSoundsBePlayed` is a module-local function — verify it is not referenced from outside the audio module (audio.lua:477-479)
- [ ] **4.3** `GetFileData` is a module-local utility — verify no external callers depend on it (audio.lua:61-69)
- [ ] **4.4** `entityNoLongerWaitingForSoundsToBeTurnedOn` is called from `Entity:onDestroy` — verify the entity reference is valid at call time (audio.lua:817-819, entity.lua:287)


## Related Pages

- [[MAP]]
- [[SUMMARY]]
