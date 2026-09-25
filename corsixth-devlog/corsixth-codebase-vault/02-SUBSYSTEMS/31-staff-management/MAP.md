# 31 Staff Management — MAP

> Paths rooted at `CorsixTH/Lua/`. All ranges read via `ssh vps`.

## Hiring / Applicants

| Claim | File | Lines |
|---|---|---|
| Pool classes + counts | world.lua | 511-516 |
| `makeAvailableStaff(month)` rebuild | world.lua | 517-544 |
| Initial pool at world init | world.lua | 139 |
| Monthly pool refresh | world.lua | 1160-1181 |
| Profile randomise (rates/skill/wage) | staff_profile.lua | 89-151 |
| `parseSkillLevel` junior/consultant | staff_profile.lua | 214-222 |
| Hire: balance check, remove, place | dialogs/hire_staff.lua | 126-146 |
| Cannot-afford advice | dialogs/hire_staff.lua | 148-156 |
| Placement validity (desk/room) | dialogs/place_staff.lua | 93-125 |
| Placement confirm → newEntity/addStaff | dialogs/place_staff.lua | 144-174 |
| `addStaff` charges 1× wage | hospital.lua | 1562-1569 |
| `initStaff` from `start_staff` | hospital.lua | 1487-1560 |
| `countStaffOfCategory` | hospital.lua | 1615-1628 |

## Wages / Payday

| Claim | File | Lines |
|---|---|---|
| Monthly wage sum + spend | hospital.lua | 949-957 |
| `getFairWage` formula | staff_profile.lua | 240-259 |
| `getRiseAmount` formula | staff_profile.lua | 261-264 |
| `tickDay` wage-vs-fair happiness | entities/humanoids/staff.lua | 42-55 |
| `tick` low-happiness raise timer | entities/humanoids/staff.lua | 131-144 |
| `requestRaise` amount/cap/1-in-5 | entities/humanoids/staff.lua | 562-587 |
| `increaseWage` cap/happiness | entities/humanoids/staff.lua | 594-615 |
| `makeRaiseRequest` strike message | hospitals/player_hospital.lua | 589-598 |
| Rise dialog resolve | dialogs/staff_rise.lua | 179-190 |
| `MaxSalary=2000` | base_config.lua | 44 |
| `MinSalary` Nurse/Dr/Handy/Recep | base_config.lua | 51-54 |
| `SalaryAdd`, `SalaryAbilityDivisor=10` | base_config.lua | 57-68 |

## Tiredness / Rest

| Claim | File | Lines |
|---|---|---|
| `tick` rest-check + tire rate | entities/humanoids/staff.lua | 114-131 |
| `isTiring` / `isResting` | entities/humanoids/staff.lua | 197-227 |
| `checkIfNeedRest` policy/ward/flags | entities/humanoids/staff.lua | 379-425 |
| `notifyNewRoom` clears wait | entities/humanoids/staff.lua | 427-431 |
| `goToStaffRoom` queue seek | entities/humanoids/staff.lua | 433-445 |
| Seek nearest staff room | humanoid_actions/seek_staffroom.lua | 26-54 |
| Targets + `relaxation` table | humanoid_actions/use_staffroom.lua | 34-78 |
| `wake`, leave at fatigue 0 | humanoid_actions/use_staffroom.lua | 112-125 |
| `tickDay` rest/happiness branches | entities/humanoids/staff.lua | 56-75 |
| Doctor crazy 1/300, cure on rest | entities/humanoids/staff/doctor.lua | 39-56 |
| `updateSpeed` fatigue/junior/cons | entities/humanoids/staff.lua | 346-377 |
| `isVeryTired` 700 / `isCrackUpTired` 800 | entities/humanoids/staff.lua | 749-758 |
| `Tired=600` policy default | base_config.lua | 143 |
| `goto_staffroom` policy init | hospital.lua | 193-200 |
| Receptionist never tires/rests | entities/humanoids/staff/receptionist.lua | 46-68 |

## Firing / Quitting / Roles

| Claim | File | Lines |
|---|---|---|
| `fire`: severance/kicked/despawn | entities/humanoids/staff.lua | 234-263 |
| `die` / `despawn` / `removeStaff` | entities/humanoids/staff.lua / hospital.lua | 265-279 / 1747-1750 |
| `quitting_in` expiry → raise/fire | entities/humanoids/staff.lua | 157-195 |
| `kicked=-3` reputation | hospital.lua | 1768-1771 |
| `announceStaffLeave` | hospitals/player_hospital.lua | 602-605 |
| `fulfillsCriterion` all roles | staff.lua 489-491; doctor.lua 335-343; handyman.lua 89-91; nurse.lua 40-42; receptionist.lua 84-86 | — |
| Doctor research points | entities/humanoids/staff/doctor.lua | 57-60 |
| Doctor title/crazy/specialism | entities/humanoids/staff/doctor.lua | 168-176 / 259-309 |
| Handyman priorities + search/assign | entities/humanoids/staff/handyman.lua | 41-50 / 73-86 / 112-186 |
| Handyman unassign/die | entities/humanoids/staff/handyman.lua | 202-220 |
| Receptionist desk occupy/cache | entities/humanoids/staff/receptionist.lua | 59-82 / 101-104 |
| `getServiceQuality` weights | entities/humanoids/staff.lua | 726-741 |

Related: [[31-staff-management/SUMMARY]] · [[07-financial-system/SUMMARY]] · [[05-staff-training/SUMMARY]]
