# 37 — Death Handling — Summary

> Links: [[37-death-handling/MAP]] · [[37-death-handling/CHECKLIST]] · [[37-death-handling/SCAFFOLD]]
> Related: [[04-patient-lifecycle/SUMMARY]] · [[30-vip-inspection/SUMMARY]]
> Legend: **[Documented fact]** = read in code · **[Inference]** = strongly implied · **[Hypothesis]** = needs testing

## 1. Overview

- **[Documented fact]** Death is patient-only bookkeeping + a two-variant `DieAction` animation. There is **no corpse entity, hearse, morgue, burial, or undertaker** — a repo-wide grep for `hearse|corpse|morgue|bury|burial|coffin|undertaker` returns only language-string false positives, zero gameplay code.
- **[Documented fact]** The `GrimReaper` class is a near-empty `Humanoid` shell (walk anims + `tickDay()->false`); all choreography lives in `humanoid_actions/die.lua`.
- **[Documented fact]** Hospital accounting is synchronous in `Patient:die()` → `Hospital:humanoidDeath()`: counters, casebook fatalities, `-4` reputation, percentages, emergency kill count, advisor sound/message.
- **[Documented fact]** Finance is **not refunded**: `treatDisease()` calls `receiveMoneyForTreatment()` *before* the cure/die roll, and `paySupplierForDrug()` runs in both outcomes.

## 2. Lifecycle / flow

1. **[Documented fact]** Trigger A — failed treatment: `Patient:treatDisease()` → `isTreatmentEffective()` false → `self:die()`.
2. **[Documented fact]** Trigger B — deferred health death: `_dailyHealthChecks()` sets `health=0` / `setToDying()` (`set_to_die=true`); `Patient:tick()` calls `die()` once the patient is room-free, not leaving, not knocking/entering.
3. **[Documented fact]** Trigger C — room crash: `room.lua` `remove_humanoid()` calls `die()` + `despawn()` + `destroyEntity()` unconditionally (kills even cured occupants).
4. **[Documented fact]** `Patient:die()` is idempotent-ish: clears `set_to_die`, early-returns if `cured`, calls `humanoidDeath()`, sets moods (`dying5` off, `dead` on), unregisters callbacks, sets `going_to_die=true`, queues `MeanderAction(1)` + `DieAction()`.
5. **[Documented fact]** `action_die_start` sets `must_happen=true`, plays `fall_east`, sets `dead=true` immediately, then branches:
   - Heaven (`action_die_tick`, phases 0–5): extra-transform → rise → wings → hands → fly-up (speed `0,-4`) → `despawn()` + `destroyEntity()`.
   - Hell/Reaper (`action_die_tick_reaper`, phases 0–6): lie on ground → spawn `gates_to_hell` + `GrimReaper` → reaper walks to use-tile and idles → patient stands via `rise_hell_east` → walks into hole via `UseObjectAction(destroy_user_after_use=true)` → lava-hole + reaper destroyed.
6. **[Documented fact]** Hell eligibility: male patients only, not `bloaty_head`, 65% roll; females / failures / no spawn tiles fall back to heaven. `Chewbacca` fall is truncated (21 ticks); `baldness` resets head layer; `Slack Female` head layer fixed in phase 2.
7. **[Documented fact]** Dead patients never `goHome()` / never re-enter the hospital list: heaven path self-destroys; hell path is consumed by the lava hole. `Humanoid:tickDay()` early-returns on `going_to_die or dead`; litter/toilet/waiting logic guards on the same flags.

## 3. Key mechanics

- **GrimReaper entity.** **[Documented fact]** Walk/idle anims only; `updateDynamicInfo()` is a no-op; `tickDay()` returns false; `afterLoad` fixes `mood_marker`. Spawned via `world:newEntity("GrimReaper", 1660, 2)` with fields `lava_hole, use_tile_x/y, mirror, patient` set by the action.
- **Spawn constraints.** **[Documented fact]** Two scenarios (south/east hole); hole must accept `gates_to_hell`, patient path to hole-use-tile must exist and not be in a room, reaper use-tile must not be in a room, hole must have a passable side (checked by toggling `passable`); else heaven fallback.
- **Accounting (`humanoidDeath`).** **[Documented fact]** `num_deaths+1`, `num_deaths_this_year+1`, `casebook.fatalities+1` (skipped for `is_debug`), `changeReputation("death")`, `updatePercentages()`, `emergency.killed_emergency_patients+1` if emergency.
- **Reputation.** **[Documented fact]** `reputation_changes["death"] = -4` (vs `cured=+1`, `kicked=-3`, `room_crash=-50`); also applied to per-disease `casebook.reputation`; gated by `isReputationChangeAllowed()` (auto-pass ≤/>500 thresholds, else quadratic likelihood).
- **Finance.** **[Documented fact]** Treatment money is kept on death; drug cost still paid; no death fine/penalty transaction. **[Inference]** Death hurts future income indirectly via lower reputation → lower `getTreatmentPrice()` and `computePriceLevelImpact()`.
- **Salary/awards.** **[Documented fact]** Monthly `player_salary` increment damped by `(reputation-500)/(num_deaths+1)`; annual report sorts `deaths_sort` ascending, gates No-Deaths/All-Cured trophies and Deaths/CuresVDeaths awards on `num_deaths_this_year`.
- **VIP.** **[Documented fact]** `World:spawnVIP()` snapshots `enter_deaths = num_deaths`; `Vip` rates `death_diff = num_deaths - enter_deaths` as visitor:death ratio (+4…+0); zero deaths during visit adds nothing (neutral-good).
- **Advisor.** **[Documented fact]** `PlayerHospital:msgKilled()` always plays `boo.wav`; first death always advises; later deaths advise probabilistically (6/10) via shared `cured_died_message` flag.

## 4. Related subsystems

- Patient state machine, health/moods, cure path → [[04-patient-lifecycle/SUMMARY]]
- VIP scoring snapshot → [[30-vip-inspection/SUMMARY]]
- Reputation/awards/salary, emergency `%` complete, debug `_:die()`, staff `Staff:die()` (flag-only, no reaper/accounting) — see [[37-death-handling/MAP]].
