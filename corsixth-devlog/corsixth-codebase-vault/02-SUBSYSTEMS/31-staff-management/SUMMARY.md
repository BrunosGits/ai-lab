# 31 Staff Management — Summary

> Scope: hiring/applicants, wages/payday, tiredness/rest-room, firing/quitting, roles, `staff_profile.lua`. Training mechanics are out of scope — see [[05-staff-training/SUMMARY]].

Legend: **[Fact]** = read in source · **[Inference]** = derived from code · **[Hypothesis]** = needs playtest/confirm.

## 1. Overview

- [Fact] Base class `Staff` + 4 subclasses: `Doctor`, `Nurse`, `Handyman`, `Receptionist`. Profile data lives in `StaffProfile`.
- [Fact] Monthly applicant pool is regenerated; hiring costs 1× wage; payday is monthly; quitting is a timed raise-request expiry; firing costs 1× wage + reputation.
- [Fact] Fatigue is `0..1`; rest threshold is policy `goto_staffroom` (≈0.6); `Receptionist` never tires/rests.
- Related: [[31-staff-management/MAP]] · [[31-staff-management/CHECKLIST]] · [[31-staff-management/SCAFFOLD]] · [[07-financial-system/SUMMARY]] · [[05-staff-training/SUMMARY]]

## 2. Lifecycle / Flow

```
World:makeAvailableStaff -> UIHireStaff:hire -> UIPlaceStaff:onMouseUp
 -> Hospital:addStaff -> work (Staff:tick/tickDay, tire)
 -> checkIfNeedRest -> SeekStaffRoom -> UseStaffRoom (wake)
 -> payday Hospital:onEndMonth
 -> unhappy -> requestRaise -> UIStaffRise -> increaseWage | fire/quit
```

- [Fact] Pool built at init and each month. [Fact] Placement creates entity, assigns hospital, enters room or corridor. [Fact] Fired/dead staff go through `removeStaff`.

## 3. Hiring / Applicants

- [Fact] `staff_to_make` defines 4 classes; counts come from `level_config.staff_levels` (`Doctors/Nurses/Handymen/Receptionists`) with fallback to earlier month entry.
- [Fact] Each candidate is `StaffProfile:randomise(month)`: random skill, doctor flags by `Shrk/Surg/Rsch/Jr/ConsRate`, wage = fair wage.
- [Fact] `UIHireStaff:hire` blocks when `balance < wage`, otherwise removes profile from pool and opens `UIPlaceStaff`.
- [Fact] `UIPlaceStaff` validates hospital-owned walkable tile; receptionists need free `reception_desk`. Confirm creates entity via `newEntity`, `setProfile`, `addStaff`, `setHospital`.
- [Fact] `Hospital:addStaff` charges `hire_staff` transaction (1× wage). `initStaff` seeds level `start_staff` without charge.
- [Inference] Pool size is the main difficulty lever for hiring, not candidate quality.

## 4. Wages / Payday

- [Fact] Payday `Hospital:onEndMonth` sums `staff.profile.wage` and `spendMoney(wages)`. See [[07-financial-system/SUMMARY]] for ledger/stats.
- [Fact] Fair wage = `MinSalary[class] + skill*1000/SalaryAbilityDivisor` + doctor `SalaryAdd` extras; `0` in free-build.
- [Fact] `tickDay` compares `wage - fair_wage` daily (`0.05` scaled); receptionists skip this whole block.
- [Fact] `tick` starts `timer_until_raise=200` when `happiness<0.1`, then `requestRaise` (1/5 chance, capped by `payroll.MaxSalary=2000`).
- [Fact] `increaseWage` caps at max, plays `bonusal2.wav`, `happiness+0.99`, clears `pay_rise` mood.

## 5. Tiredness / Rest Room

- [Fact] `tick` calls `checkIfNeedRest`, then `tire(0.000090)` + `happiness-0.00002` only if `isTiring`.
- [Fact] `isTiring=false` in `staff_room` (unless `on_call`), on `pickup`; `Receptionist:isTiring` always false.
- [Fact] `checkIfNeedRest`: `isVeryTired` sets `tired` mood; at `fatigue >= goto_staffroom` seeks room; ward nurses may leave with patients, others wait (`staffroom_needed`); sets `waiting_for_staffroom` if none exists (cleared by `notifyNewRoom`).
- [Fact] `SeekStaffRoomAction` goes to nearest `staff_room`; `UseStaffRoomAction` picks `sofa`/`pool_table`/`video_game` by class, `wake(relaxation)` per tick, leaves at `fatigue==0`.
- [Fact] `tickDay` resting branch (`isResting` + not very tired) gives `happiness+0.006`; working-tired gives `-0.02/-0.01`. Doctors roll `1/300` per day to go crazy when very tired; resting cures.
- [Fact] `updateSpeed` slows junior / very-tired / crack-up staff; consultants are fast; receptionists ignore fatigue.

## 6. Firing / Quitting

- [Fact] `Staff:fire` closes `UIStaff`, spends `severance` (1× wage), `changeReputation("kicked", -3)`, `despawn→removeStaff`, `announceStaffLeave`, updates `UIStaffManagement`.
- [Fact] `requestRaise` sets `quitting_in=25*30+rand(0,50)` + `pay_rise` mood + `makeRaiseRequest` (bottom-panel `strike` message).
- [Fact] `checkIfWaitedTooLongForRaise` expiry: if `grant_wage_increase` → auto-raise (`getRiseAmount`), else `fire`. Open `UIStaffRise` is resolved the same way (`increaseSalary`/`fireStaff`).
- [Hypothesis] `quitting_in` ticks are per-tick, so wall-clock quit time varies with game speed — confirm by playtest.

## 7. Roles

- [Fact] `fulfillsCriterion`: base `false`; `Doctor→Doctor` + junior/consultant/specialism flags; `Nurse→Nurse`; `Handyman→Handyman`; `Receptionist→Receptionist`. Used by `countStaffOfCategory` and room staffing checks.
- [Fact] `Doctor` adds `isResearching` (research points `1550+1000*skill`), `isLearning`/`trainSkills` (defer to [[05-staff-training/SUMMARY]]), `updateStaffTitle`, `setCrazy`.
- [Fact] `Handyman` has `cleaning/watering/repairing` priorities (default `0.333` each), weighted `searchForHandymanTask`, `assign/processCleaningTask`, `release/unassign`, parcel filter, steal-from-far-handyman logic.
- [Fact] `Nurse` is behaviorally base `Staff` (only criterion + advice override). [Inference] Ward/research/training room logic treats nurses via generic staffing checks.
- [Fact] `Receptionist`: no fatigue attr, no rest, `needsWorkStation` nags for desks, occupies `reception_desk` on place/pickup, rebuilds desk cache on move/fire.

## 8. StaffProfile

- [Fact] Holds `humanoid_class, skill 0..1, wage, is_junior/consultant/surgeon/psychiatrist/researcher, attention_to_detail, name/desc/face`.
- [Fact] `parseSkillLevel` thresholds `DoctorThreshold=250`, `ConsultantThreshold=750`; `getRiseAmount = max(wage*1.1,(fair+wage)/2)-wage`.
