# 37 — Death Handling — Pre-Fix Safety Gate

> Companion: [[37-death-handling/SUMMARY]] · [[37-death-handling/MAP]]

## A. Reproduce first
- [ ] Trigger each path separately: failed-treatment roll, `health→0` deferred tick, room crash. Confirm which `die()` call site fires.
- [ ] Confirm heaven vs hell branch taken (sex, `bloaty_head`, 65% roll, spawn-tile availability).
- [ ] Confirm `dead=true` set in `action_die_start` even before the fall timer elapses.

## B. Accounting invariants
- [ ] `num_deaths` AND `num_deaths_this_year` increment exactly once per death; `is_debug` skips only `fatalities`.
- [ ] `changeReputation("death")` fires with `patient.disease`; casebook `reputation` and `fatalities` stay in sync.
- [ ] `updatePercentages()` called from both `die()` and `goHome()` paths; no divide-by-zero when counts are 0.
- [ ] Emergency deaths increment `killed_emergency_patients`, never `cured_*`; `checkEmergencyOver()` still closes.

## C. Animation/entity cleanup
- [ ] Heaven path always ends `despawn()` + `destroyEntity()`; hell path consumes patient via `destroy_user_after_use` and destroys lava-hole + reaper.
- [ ] Failed hell-spawn falls back to heaven (no stranded reaper/hole, no blocked 1-wide corridor).
- [ ] `going_to_die/dead` blocks `tickDay`, litter, toilet-seek, cure, `goHome`, and right-click push.
- [ ] Female / `bloaty_head` / Chewbacca / Transparent / Elvis extras use the correct `die_anims` ids.

## D. Money/rep side effects
- [ ] Treatment payment retained on death; drug cost still charged; no double-charge on re-entry.
- [ ] Salary formula, annual-report death gates, and VIP `enter_deaths` delta behave (esp. `num_deaths=0` and zero-deaths-during-visit).
- [ ] `room_crash` mass-`die()` does not double-count or leak callbacks/messages.

## E. Save/load
- [ ] Old-save `afterLoad` paths for `die_anims.rise_hell_east` / `on_ground_anim` / Chewbacca extra verified.
- [ ] Persistable reaper callbacks (`reaper_wait/swipe/leave/destroy`, `walk_into_lava`) survive save/load mid-death.
