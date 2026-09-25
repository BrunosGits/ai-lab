# 31 Staff Management — Checklist

> Safety gate for any hire/wage/rest/fire/role change. Check [[31-staff-management/MAP]] for lines.

## Must verify

- [ ] Hiring: pool refresh at init + month boundary; category counts from `staff_levels`; `hire` blocked when `balance < wage`; cancelled placement returns profile to pool.
- [ ] Placement: valid hospital tile; receptionist requires free `reception_desk`; confirm calls `addStaff` + `setHospital` + room-enter or corridor; `UIStaffManagement` refreshes.
- [ ] Wages: `onEndMonth` sums live `profile.wage`; `hire_staff`/`wages`/`severance` use `_S.transactions.*`; free-build fair wage is `0`.
- [ ] Fair wage: `MinSalary` per class + `skill*1000/Divisor` + doctor `SalaryAdd`; `MaxSalary` cap enforced in `requestRaise` + `increaseWage`.
- [ ] Raise flow: `happiness<0.1` → 200-tick delay → 1/5 request → `pay_rise` mood + `quitting_in`; expiry grants raise iff `grant_wage_increase`, else fires; open `UIStaffRise` resolved consistently.
- [ ] Rest: non-receptionist tires per-tick; `fatigue >= goto_staffroom` triggers seek; no-room sets `waiting_for_staffroom` until `notifyNewRoom`; ward rule for nurses; `pickup`/`on_call` suppress tiring/resting correctly.
- [ ] Staff-room: nearest room found; `sofa/pool/video` class restrictions hold; `fatigue==0` exits; research/training return path intact.
- [ ] Fire/quit: severance = 1× wage, reputation `kicked`, messages cleared, callbacks unregistered, `removeStaff` + desk-cache/handyman-task cleanup.
- [ ] Roles: `fulfillsCriterion` unchanged for room staffing, `countStaffOfCategory`, research/training checks; `Handyman` parcel + priority search intact; `Receptionist` fatigue stays `nil`.
- [ ] Save/load: `afterLoad` migrations for `going_to_staffroom`, handyman flags, metatables, profiles' `world` still apply; no stale `staffroom_needed`.
- [ ] Cross-system: finance [[07-financial-system/SUMMARY]] monthly totals match; training [[05-staff-training/SUMMARY]] `isLearning` path untouched.

## Pitfalls

- [ ] No hardcoded wages/thresholds — read `level_config`/`base_config`.
- [ ] No receptionist fatigue or staff-room assignment.
- [ ] No double-charge on hire (once in `addStaff`) or missed severance on fire.
- [ ] No stuck `going_to_staffroom` / `staffroom_needed` / `waiting_for_staffroom`.
