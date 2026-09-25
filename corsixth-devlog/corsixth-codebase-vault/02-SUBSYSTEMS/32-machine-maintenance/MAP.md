# 32 — Machine Maintenance — Map

Paths rooted at `CorsixTH/Lua/`. All ranges verified by direct read.

| Claim | File | Lines |
|---|---|---|
| Machine ctor: `strength = start_strength`, `total_usage = 0` | `entities/machine.lua` | 29–47 |
| `getRemainingUses`, `isBreaking (< 4)` | `entities/machine.lua` | 62–71 |
| Smoke tile + on/off helpers | `entities/machine.lua` | 79–117 |
| `earthquakeImpact` → `machineUsed(room, true)` | `entities/machine.lua` | 123–124 |
| `machineUsed`: counters → info → explode vs repair+smoke | `entities/machine.lua` | 131–156 |
| `incrementUsageCounts` (quake skips total, cheat skips wear) | `entities/machine.lua` | 158–167 |
| Auto repair tasks: `< 4` pri-2+announce, `< 6` pri-1 | `entities/machine.lua` | 170–195 |
| Explosion roll + extinguisher formula | `entities/machine.lua` | 197–228 |
| `explodeMachine`: drop task, crash, anim, clear UI/smoke/gear | `entities/machine.lua` | 230–256 |
| Smoke plumes `< 4/< 3/< 2` | `entities/machine.lua` | 259–283 |
| `placed`, `getRepairTile` | `entities/machine.lua` | 285–294 |
| `createHandymanActions`: walk, wait-free meander, 20f repair | `entities/machine.lua` | 296–348 |
| `replaceMachine`: pay, reset, re-read strength, cleanup | `entities/machine.lua` | 351–370 |
| `machineRepaired`, `removeHandymanRepairTask` | `entities/machine.lua` | 374–395 |
| `reduceStrengthOnRepair` (`rand < used/strength`, min 2) | `entities/machine.lua` | 397–410 |
| `setRepairingStatus` / `removeRepairingStatus` (gear 4564) | `entities/machine.lua` | 412–437 |
| `finalize` (repair cursor), `updateDynamicInfo` | `entities/machine.lua` | 450–478 |
| `onClick` (machine dialog), `onDestroy` cleanup | `entities/machine.lua` | 480–500 |
| Persist `total_usage`, `strength` | `entities/machine.lua` | 536–556 |
| Repair-tile selection (`handyman_position` fallback) | `entities/machine.lua` | 564–590 |
| Type stats: `default/crashed/smoke` per machine | `objects/machines/*.lua` | 30–33 each |
| Operating-table slave guard (master-only wear) | `objects/machines/operating_table.lua` | 128–133 |
| `times_used = 0` at create; `incrementUsedCount` (non-machine) | `entities/object.lua` | 36–60, 264–272 |
| Missing `handyman_position` falls back to `use_position` | `entities/object.lua` | 957–958 |
| `crashRoom`: kill, destroy, soot, value/rep, deactivate | `room.lua` | 858–965 |
| Counters: `num_explosions`, `-build_cost`, `room_crash` | `room.lua` | 958–963 |
| `getRoomMachine`, `lock/unlockRoomOnRepair` | `room.lua` | 1217–1235 |
| Handyman entry locks; non-manual exit unlocks | `room.lua` | 340–356, 638–647 |
| Patients blocked while `needs_repair` | `room.lua` | 697–710 |
| `callForRepair` (+ advisor branches), `sendStaffToRepair` | `calls_dispatcher.lua` | 97–124, 558–560 |
| Handyman task add/get/modify/remove/by-tile lookup | `hospital.lua` | 2136–2168, 2321–2331 |
| Repair announce stub | `hospital.lua` | 2544–2545 |
| `spendMoney` (replace path uses `machine_replacement`) | `hospital.lua` | 1369–1382 |
| Dialog buttons, status bar, call/replace handlers | `dialogs/machine_dialog.lua` | 50–55, 67–131 |
| Wear call sites after patient use | `humanoid_actions/use_object.lua` | 385–395 |
| Wear call site (multi-use, incl. table/blood) | `humanoid_actions/multi_use_object.lua` | 300–312 |
| Research `start_strength`/`cost` init; improve to max | `research_department.lua` | 54–76, 240–256, 500–522 |
| Player machine list (excl. slaves) | `world.lua` | 2449–2464 |
| Quake damage loop over room machines | `earthquake.lua` | 136–145 |
| Cheats: repair-all, invulnerable toggle + query | `cheats.lua` | 224–243, 342–343 |
| Handyman search/assign by cleaning/watering/repairing | `entities/humanoids/staff/handyman.lua` | 41–43, 77–79, 112–186 |
