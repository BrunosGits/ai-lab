# 32 — Machine Maintenance — Summary

Scope: strength model, handyman service/repair flow, breakdowns +
explosions, replacement-cost logic. Full refs: [[32-machine-maintenance/MAP]].
Gate future edits with [[32-machine-maintenance/CHECKLIST]]; see pattern in
[[32-machine-maintenance/SCAFFOLD]].

## 1. Strength model
- [Documented fact] Each machine type declares `default_strength`
  (e.g. x-ray/cardio/blood 12, dna/jelly 7, operating table 8).
- [Documented fact] At construction `Machine` copies current researched
  `start_strength` into `self.strength`; slave half (operating_table_b)
  gets none.
- [Documented fact] Wear counter is `times_used` (starts 0 in `Object`);
  remaining life = `strength - times_used`; smoking threshold `< 4`.
- [Documented fact] Research raises future `start_strength` (up to
  `MaxObjectStrength`); it does not heal placed machines — only
  replace picks up the new value.
- [Inference] `total_usage` (lifetime, quake-excluded) is stats-only;
  `times_used` (since last repair) drives all breakdown logic.

## 2. Lifecycle / flow
1. Patient use finishes (`use_object` / `multi_use_object`) →
   `machineUsed(room)` unless room already crashed.
2. `machineUsed`: bump counters → recompute dynamic info → roll
   explosion → else queue/escalate handyman task + update smoke.
3. Handyman dispatched via dispatcher call → walks to repair tile →
   meanders until machine free → `UseObjectAction` → `machineRepaired`.
4. `machineRepaired`: maybe `strength - 1`, `times_used = 0`, unlock room,
   clear smoke/gear/task.
5. If overused: `explodeMachine` → `room:crashRoom()` (kill occupants,
   soot, deactivate); or player pre-empts via Replace button.

## 3. Servicing / handyman repair flow
- [Documented fact] Auto-task thresholds: `< 6` low priority (1),
  `< 4` high priority (2) + advisor announcement; existing low task is
  upgraded, not duplicated.
- [Documented fact] Manual Call button forces priority-2 task +
  `setRepairingStatus` (gear icon 4564, `needs_repair = true`) even
  above the auto thresholds; no-op when `times_used == 0`.
- [Documented fact] Repair execution waits for `not self.user` and no
  non-leaving patient, then runs a 20-frame minimum `UseObjectAction`.
- [Documented fact] Room locks (`needs_repair`) while assigned handyman
  is inside; patients blocked via `canHumanoidEnter`; lock released on
  repair, handyman exit (non-manual), destroy, or crash cleanup.
- [Inference] Task lookup is by tile (`getIndexOfTask(x, y)`), so two
  machines can never share a tile; slave table routes repair to master.

## 4. Breakdowns and explosions
- [Documented fact] Explosion roll only when `remaining < 1`. No
  extinguisher, or `remaining < -3`, always explodes; otherwise
  `chance = 2/strength - 0.2*remaining - 0.05*extinguishers + 0.05`,
  clamped to [0.05, 0.95]; max 4 extinguishers counted.
- [Documented fact] Smoke is 1/2/3 plumes at `< 4 / < 3 / < 2`; cleared
  on repair, replace, explosion, destroy.
- [Documented fact] Crash kills everyone in room (+ door user), destroys
  non-machine objects, lays floor+wall soot, `num_explosions += 1`,
  hospital value `-= room build_cost`, reputation `room_crash`,
  `crashed = true` + deactivate.
- [Documented fact] Earthquakes call `machineUsed(room, true)`: counts
  toward explosion but not `total_usage`. Invulnerability cheat skips
  both wear and explosion; repair-all cheat calls `machineRepaired(_, false)`.

## 5. Repair decay + replacement cost
- [Documented fact] Each repair rolls `math.random() < times_used/strength`
  for `strength - 1`, floor 2. Late repairs almost always decay.
- [Documented fact] Replace costs `research_progress[type].cost`
  (`StartCost`, 0 in free-build), logged as `machine_replacement`;
  refuses when `balance < cost`. It resets both counters, re-reads
  `start_strength`, drops repair task, clears gear + smoke.
- [Documented fact] Machine dialog + town-machine list render the same
  `1 - times_used/strength` status bar; dialog also shows lifetime count.

## 6. Related subsystems
- Staff / handyman dispatch + priorities: [[05-staff-training/MAP]],
  [[31-staff-management/MAP]] (`Handyman:searchForHandymanTask`).
- Money / value / reputation: [[07-financial-system/MAP]]
  (`spendMoney`, `changeValue`, `changeReputation`).
- Research (StartStrength/StartCost/MaxObjectStrength): research subsystem note.
- Rooms (lock, crash, queue): room lifecycle subsystem note.
- Cheats (`repair_all_machines`, `invulnerable_machines`): debug note.

## 7. Hypotheses (needs playtest)
- [Hypothesis] Optimal play is early low-priority repair: decay odds scale
  with `times_used`, so waiting for `< 4` trades handyman trips for max life.
- [Hypothesis] One extinguisher is cost-effective on low-strength (7–8)
  machines; beyond 2 the +5% each rarely matters vs. repair labor.
