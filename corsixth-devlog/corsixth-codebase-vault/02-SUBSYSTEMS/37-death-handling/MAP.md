# 37 — Death Handling — MAP

> Parent: [[37-death-handling/SUMMARY]] · All paths rooted at `CorsixTH/Lua/`. Verified by `ssh vps "cat|grep|sed"`.

| # | File:lines | Claim |
|---|------------|-------|
| M1 | `entities/humanoids/grim_reaper.lua:21-35` | `GrimReaper(Humanoid)` shell: walk anims 994/996/1002/1004, cursor, `tickDay()->false` |
| M2 | `entities/humanoids/grim_reaper.lua:42-52` | No dynamic info; `afterLoad` mood fix |
| M3 | `entities/humanoid.lua:63-77` | `die_anims()` schema: fall/rise/rise_hell/wings/hands/fly/extra |
| M4 | `entities/humanoid.lua:166` | Grim walk-anim registration |
| M5 | `entities/humanoid.lua:196-208` | Per-class fall/rise/wings/hands/fly ids; transparent/Chewbacca/Elvis `extra` transforms |
| M6 | `entities/humanoid.lua:224-225,820-822` | `on_ground_anim` table + `setType()` wiring of `die_anims` |
| M7 | `entities/humanoid.lua:988-990` | `tickDay` early-return on `going_home/going_to_die/dead` |
| M8 | `entities/humanoids/patient.lua:40-48` | `dead/set_to_die/going_to_die` flags + semantics |
| M9 | `entities/humanoids/patient.lua:295-312` | `treatDisease()`: pay → cure-or-`die()` → percentages + drug cost |
| M10 | `entities/humanoids/patient.lua:343-358` | `isTreatmentEffective()` cure roll (effectiveness × diagnosis + service quality) |
| M11 | `entities/humanoids/patient.lua:371-391` | `Patient:die()`: `humanoidDeath`, moods, `going_to_die`, queue Meander+Die |
| M12 | `entities/humanoids/patient.lua:590-606` | `setToDying()` + `tick()` deferred-die gate (room-free, not leaving/knocking/entering) |
| M13 | `entities/humanoids/patient.lua:660-670` | `_dailyHealthChecks()`: `health<0.01` → stage death; `==0` → `setToDying()` |
| M14 | `humanoid_actions/die.lua:30-67` | Heaven phases 0–5 → `despawn()` + `destroyEntity()` |
| M15 | `humanoid_actions/die.lua:71-93,194-215` | Reaper phases 0–5: ground wait, spawn attempt, reaper walk/idle, 20-tick pause, `rise_hell_east` stand |
| M16 | `humanoid_actions/die.lua:96-170` | Hell spawn scenarios, room/path/passable-side checks, heaven fallback |
| M17 | `humanoid_actions/die.lua:174-188` | `newObject("gates_to_hell")` + `newEntity("GrimReaper",1660,2)` + field init |
| M18 | `humanoid_actions/die.lua:219-255` | Phase 6: reaper swipe/leave/destroy loop-callbacks; patient `walkTo` + `UseObjectAction(destroy_user_after_use=true)` |
| M19 | `humanoid_actions/die.lua:259-299` | `action_die_start`: `must_happen`, baldness/Chewbacca/Slack-F fixes, male+non-bloaty 65% hell roll, `dead=true` |
| M20 | `hospital.lua:1582-1598` | `humanoidDeath()`: `msgKilled`, fatalities, `num_deaths(+ty)`, rep `death`, percentages, emergency kills |
| M21 | `hospital.lua:1768-1776,1785-1801` | `reputation_changes["death"]=-4`; `changeReputation()` incl. casebook rep |
| M22 | `hospital.lua:1908-1913` | `updatePercentages()` killed/cured formulas |
| M23 | `hospital.lua:981-991` | Salary increment damped by `(reputation-500)/(num_deaths+1)` |
| M24 | `hospital.lua:1402-1424,1464-1470` | `receiveMoneyForTreatment()` kept on death; `paySupplierForDrug()` still charged |
| M25 | `hospital.lua:1756-1759` | `removePatient()` list removal (called only by `Patient:despawn()`, i.e. non-death leave path) |
| M26 | `hospitals/player_hospital.lua:433-444` | `msgKilled()`: `boo.wav`, first-death guarantee, 6/10 repeat gate |
| M27 | `world.lua:486` + `entities/humanoids/vip.lua:326-338` | VIP `enter_deaths` snapshot; visitor:death-ratio rating table |
| M28 | `dialogs/fullscreen/annual_report.lua:147,213-217,269-287` | Deaths sort + No-Deaths/Deaths/CuresVDeaths trophies & awards |
| M29 | `room.lua:879-890` | Room-crash `remove_humanoid`: `die()+despawn()+destroyEntity()` |
| M30 | `entities/humanoids/staff.lua:265-272` + `staff/handyman.lua:216-219` | `Staff:die()` is flag/UI only; no reaper, no hospital counters |
| M31 | NEGATIVE — grep `hearse\|corpse\|morgue\|bury\|burial\|coffin\|undertaker` over `CorsixTH/Lua/**/*.lua` | Zero gameplay hits (language-only false positives): no corpse/hearse/burial system |
