# 32 — Machine Maintenance — Safety Gate

Do not merge a maintenance fix until every box is checked.

## Repro first
- [ ] Quoted exact `strength`, `times_used`, remaining before/after.
- [ ] Named single vs multi-use path (`use_object:391` vs `multi_use:308`).
- [ ] Slave involved? Confirmed master-only wear (`operating_table:130-133`).

## Thresholds intact
- [ ] `< 6` creates pri-1; `< 4` creates/upgrades to pri-2 + announce.
- [ ] No duplicate task when one exists for the tile.
- [ ] Manual call still no-ops at `times_used == 0`, forces pri-2 + gear.

## Explosion math untouched (or re-approved)
- [ ] `remaining >= 1` never explodes; `< -3` or 0 extinguishers always does.
- [ ] Clamp `[0.05, 0.95]` and 4-extinguisher cap preserved.
- [ ] Cheat `invulnerable_machines` still skips wear + explosion.

## Repair / replace semantics
- [ ] Repair resets `times_used` only; decay roll `rand < used/strength`, min 2.
- [ ] Replace resets both counters, re-reads `start_strength`, charges
  `cost`, refuses on low balance, clears task + gear + smoke.
- [ ] Room lock/unlock symmetric on repair, destroy, crash, handyman exit.

## Regression sweep
- [ ] Smoke 1/2/3 plumes; dialog + list status bars agree.
- [ ] Crash still kills occupants, soots room, value/rep, deactivates.
- [ ] Quake wear skips `total_usage` but can explode; save/load keeps both.
- [ ] Staff note [[05-staff-training/MAP]] + finance note [[07-financial-system/MAP]] updated
  if dispatch, cost, value, or reputation lines changed.
