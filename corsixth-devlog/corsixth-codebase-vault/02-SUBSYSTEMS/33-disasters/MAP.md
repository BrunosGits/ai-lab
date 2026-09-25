# 33 — Disasters MAP (verified file:line)

> Paths are `CorsixTH/Lua/...`. Every range below was read via `ssh vps`.

## Earthquakes

| Claim | Location |
|---|---|
| Class fields (`active`, `size`, `remaining_damage`, timers, `disabled`) | `earthquake.lua:28-39` |
| Damage/warning constants (16h, 600h, 25h) | `earthquake.lua:42-44` |
| Ctor + initial `nextEarthquake()` | `earthquake.lua:64-69` |
| Per-tick driver: end check, warning/main stages, shake, sound gate, damage loop, patient falls | `earthquake.lua:73-156` |
| End-of-quake: `active=false`, `"end"`, `size>7` adviser, plan next | `earthquake.lua:76-87` |
| Warning start/end shake signals | `earthquake.lua:90-99` |
| Small vs large shake + `"sound"` stage | `earthquake.lua:115-126` |
| Damage wave: all rooms → machines → `earthquakeImpact`; `remaining_damage-=1` | `earthquake.lua:133-146` |
| Corridor patient 50/50 fall roll | `earthquake.lua:148-155` |
| Arm on matching month/day (`active=true`) | `earthquake.lua:159-166` |
| Level-scripted planning (`quake_control`, `StartMonth/EndMonth`, `Severity`) | `earthquake.lua:169-193` |
| Cheat quake (size 1–6 fallback) | `earthquake.lua:196-209` |
| `isActive()` | `earthquake.lua:213-215` |
| Save migration (`old<115`, `old<189`, `quake_points` cleanup) | `earthquake.lua:220-248` |
| Owned by world; constructed at startup | `world.lua:148-149` |
| Ticked when not paused | `world.lua:929-932` |
| Armed from `World:onEndDay` | `world.lua:1056-1080` (`1080` is the quake call) |
| Pause stops shake (`"pause"`) | `world.lua:781-782` |
| Save-load re-attach + `afterLoad` | `world.lua:2874-2875`, `world.lua:2949` |
| UI shake: `beginShakeScreen` / `endShakeScreen` (+ config gate) | `game_ui.lua:1023-1034` |
| Stage dispatch (warning/main/end/pause/small/large/sound) | `hospitals/player_hospital.lua:801-837` |
| Repair-announce quake spam guard | `hospitals/player_hospital.lua:483-492` |
| Base-class no-op stub | `hospital.lua:2599-2600` |
| Cheats: create + toggle (+ `disabled` flag) | `cheats.lua:150-166` |

## Damage → repair (quake side only; explosions → [[32-machine-maintenance/MAP]])

| Claim | Location |
|---|---|
| `earthquakeImpact(room)` = `machineUsed(room, true)` | `entities/machine.lua:119-125` |
| Shared wear/repair-or-explode path | `entities/machine.lua:131-155` |
| Quake wear skips `total_usage`, still bumps `times_used` | `entities/machine.lua:158-167` |
| Repair task queue / priority escalation | `entities/machine.lua:170-194` |
| Explosion check (extinguisher odds) | `entities/machine.lua:197-228` |
| `explodeMachine` → `room:crashRoom()` | `entities/machine.lua:230-257` |
| Post-repair reset (`times_used=0`, smoke off) | `entities/machine.lua:374-385` |
| Room crash kills occupants, clears objects | `room.lua:858-930` |
| Room repair lock flags | `room.lua:1227-1234` |
| Patient `falling()` + happiness hit; quake calls with `false` | `entities/humanoids/patient.lua:415-433` |
| `falling_anim` registry (standard M/F patients) | `entities/humanoid.lua:218-219`, `:821` |

## Boiler disasters + finance/heating

| Claim | Location |
|---|---|
| `disasterless_days` init + heating struct | `hospital.lua:102-112` |
| Disaster interval by difficulty + jitter | `hospital.lua:639-643` |
| `boilerBreakdown(broken_heat)` guards + latch | `hospital.lua:647-666` |
| `_fixBoiler()` handyman-scaled countdown + restore | `hospital.lua:669-692` |
| Daily disaster roll (1=skip,2=max,3=min; vomit TODO) | `hospital.lua:920-936` |
| Daily heating cost accrual | `hospital.lua:938-940` |
| Monthly heating charge | `hospital.lua:959-962` |
| Generic money hook | `hospital.lua:1369-1383` |
| Boiler advice sounds/text | `hospitals/player_hospital.lua:469-479` |
