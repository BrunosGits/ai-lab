# 38 — Cheats + Debug MAP (verified file:line)

> Paths are `CorsixTH/Lua/...`. Every range was read via `ssh vps`.

## Cheats core

| Claim | Location |
|---|---|
| Class + ctor, 20-entry `cheat_list`, `active_cheats` init | `cheats.lua:27-61` |
| `performCheat`: `false` = fail; `lose_level` never success | `cheats.lua:67-71` |
| `announceCheat`: random cheat wav Critical + `cheated=true` | `cheats.lua:75-85` |
| Money +10000 (`transactions.cheat`) | `cheats.lua:87-89` |
| Research: drain diagnosis + cure policy queues | `cheats.lua:91-98` |
| Emergency cheat + `undiscovered_disease`/`no_heliport` fails | `cheats.lua:100-108` |
| `cheatToggleInfected` stub (old name) | `cheats.lua:110` |
| Show-infected: flip `cheat_always_show_mood` + mood icons | `cheats.lua:116-130` |
| Spawn contagious patient / toggle epidemics + cancel | `cheats.lua:133-148` |
| Create quake / toggle quake `disabled` | `cheats.lua:150-164` |
| VIP / spawn patient / end month / end year / lose / win | `cheats.lua:166-188` |
| Prices ±0.5 clamped [0.5, 2.0] | `cheats.lua:190-212` |
| Reset deaths / max reputation | `cheats.lua:214-221` |
| Repair all player machines in place | `cheats.lua:224-231` |
| Invulnerable-machines flip-flop + messages | `cheats.lua:234-245` |
| Roujin / no-rest / queue-jump / super-doctor On/Off | `cheats.lua:250-296` |
| `toggle_cheats` ranges: spawn 27868.3-4, norest 185.5-6, qjump 200.5-6, superdoc 301.5-6 | `cheats.lua:304-337` |
| `isCheatActive` / `processCheatCode` range scan / `toggleCheat` + window refresh | `cheats.lua:342-382` |

## Entries (dialog + fax)

| Claim | Location |
|---|---|
| Fax keypad build (`Fax_*.wav`, code/cancel/validate/correct) | `dialogs/fullscreen/fax.lua:30-90` |
| Fax pauses game | `dialogs/fullscreen/fax.lua:93-95` |
| `validate`: `24328` → cheats window; `112` → Critical `rand*`; else `processCheatCode`; `fax_yes/no.wav` | `dialogs/fullscreen/fax.lua:258-287` |
| Cheats dialog build, cheated banner, 2-column buttons | `dialogs/resizables/cheats_dialog.lua:62-122` |
| `updateCheatedStatus` green/red banner | `dialogs/resizables/cheats_dialog.lua:124-128` |
| `buttonClicked`: pause gate, `performCheat`, `announceCheat`, fail message | `dialogs/resizables/cheats_dialog.lua:132-148` |
| Cheats window closed on load (compat) | `dialogs/resizables/cheats_dialog.lua:154-158` |
| `cheat_announcements` cheat001-003.wav | `world.lua:163-165` |
| `isUserActionProhibited` (must-pause / paused-no-edit) | `world.lua:887-890` |
| Win bonus forfeited when `cheated` | `world.lua:1349-1350` |
| Per-hospital `hosp_cheats`; `active_cheats` save migration | `hospital.lua:179-180`, `hospital.lua:499-506` |
| Cheat hotkey F11 default | `config_finder.lua:207` |

## Debug console / script / menu

| Claim | Location |
|---|---|
| `debug_script.lua` header: menu/hotkey entry, `_` = clicked, `TheApp` | `debug_script.lua:1-13` |
| `UI:runDebugScript`: `loadfile` fresh, `_` set/cleared | `ui.lua:200-209` |
| Console/show handlers gated on `config.debug` | `ui.lua:1167-1173` |
| `showLuaConsole` | `ui.lua:1260-1262` |
| `debug_cursor_entity` init + hover capture | `ui.lua:146`, `game_ui.lua:472-475` |
| Console ctor (textbox, execute/close) | `dialogs/resizables/lua_console.lua:55-82` |
| Console execute: `_` capture, `load`, `pcall`, `_=nil` | `dialogs/resizables/lua_console.lua:98-127` |
| Console `afterLoad` compat | `dialogs/resizables/lua_console.lua:133-144` |
| Debug menu gated on `config.debug` | `dialogs/menu.lua:843-844` |
| Debug items: fax/patient/rat/cheats/console/script/dispatcher/dumps | `dialogs/menu.lua:853-861` |
| Cheat-window hotkey gated on debug + non-MAP-EDITOR | `game_ui.lua:182-184` |
| `showCheatsWindow` | `game_ui.lua:1389-1391` |
| `makeDebugFax` random-type fax | `game_ui.lua:404-412` |
| `makeDebugRat` from current view | `game_ui.lua:415-421` |
| Console/script hotkey defaults (F12 / Shift+D) | `config_finder.lua:198-199` |
| Empty-queue log: silent `gameLog` vs `print` by `config.debug` | `entities/humanoid.lua:758-766` |
| `adviser:say` asserts table (menu-path `announceCheat(self.ui)` note) | `dialogs/adviser.lua:200-207` |

## `is_debug` flags

| Claim | Location |
|---|---|
| `debug_patients` list init | `hospital.lua:175` |
| `getDebugPatient` round-robin | `hospital.lua:1331-1339` |
| `removePatient`/`removeDebugPatient` detach | `hospital.lua:1756-1765` |
| `humanoidDeath`: skip casebook fatalities (counts+rep still apply) | `hospital.lua:1582-1598` |
| `updateCuredCounts`: skip cured reputation only | `hospital.lua:1867-1883` |
| `updateNotCuredCounts`: early return (no rep/counts) | `hospital.lua:1890-1900` |
| `makeDebugRat` helper (view-based holes) | `hospital.lua:776-790` |
| `setHospital`: debug/emergency skip `SeekReception` | `entities/humanoids/patient.lua:232-241` |
| `die` → `humanoidDeath` (quarantine lives in hospital) | `entities/humanoids/patient.lua:371-376` |
| `goHome`: detach debug patient for despawn | `entities/humanoids/patient.lua:548-551` |
| Right-click drives debug patient | `game_ui.lua:703-712` |
| `UIMakeDebugPatient`: `is_debug`, list insert, diagnosed, `idea1` badge | `dialogs/resizables/menu_list_dialogs/make_debug_patient.lua:43-53` |
| Patient dialog hides/guards guess-cure for debug | `dialogs/patient.lua:302-309`, `dialogs/patient.lua:341-346` |
| No `is_debug` in `epidemic.lua` (grep: zero hits) | `epidemic.lua` (absent) |

## Cheat consumers

| Claim | Location |
|---|---|
| Spawn-rate +40 when `spawn_rate_cheat` | `world.lua:1201-1204` |
| `tire` skipped + speed forced 3 when `no_rest_cheat` | `entities/humanoids/staff.lua:330-336`, `entities/humanoids/staff.lua:356-357` |
| Queue priority 5 when `queuejump` + health < 0.10 | `queue.lua:181-183` |
| Max-skill doctors when `super_doctor` | `staff_profile.lua:100-101` |
| No wear/explosion when `invulnerable_machines` | `entities/machine.lua:137-145` |
| Cheat quake: active/disabled guard, size 1-6 fallback | `earthquake.lua:196-209` |
