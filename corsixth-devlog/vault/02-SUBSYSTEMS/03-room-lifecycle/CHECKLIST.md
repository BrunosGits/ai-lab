# Room Lifecycle — Pre-Fix Checklist

**Use this checklist before making any changes to room lifecycle code.**

---

## ⬜ Pre-Change Analysis

### Understand the Scope
- [ ] Identify which room type(s) are affected: Base `Room` class or derived room (GP, Ward, OperatingTheatre, etc.)?
- [ ] Determine which lifecycle phase: Entry, Exit, Staff Assignment, Patient Routing, Crash, Queue, Build/Activate, Deactivate?
- [ ] Check if change affects **all rooms** (base class) or **specific room types** (overrides)
- [ ] Review `room.lua` and relevant derived room file(s) for current implementation

### Identify Dependencies
- [ ] `room.lua` — Base class methods: `onHumanoidEnter`, `onHumanoidLeave`, `roomFinished`, `crashRoom`, `tryAdvanceQueue`, `canHumanoidEnter`, `deactivate`, `tryToEdit`
- [ ] Derived room files in `Lua/rooms/` — Check for overrides of above methods
- [ ] `dispatcher.lua` — Staff calling (`callForStaff`, `dropFromQueue`)
- [ ] `patient.lua` — Patient states, treatment routing, diagnosis flow
- [ ] `staff.lua` — Staff states, service quality, moods
- [ ] `queue.lua` — Queue operations, patient re-routing
- [ ] `world.lua` — Entity management, room registry
- [ ] `hospital.lua` — Value/reputation changes, advice system

---

## ⬜ Entry Flow (`onHumanoidEnter`) Changes

### Base Class Guards
- [ ] **Assertion**: `assert(not self.humanoids[humanoid])` — prevent duplicate entry
- [ ] **Activation check**: `if not self.is_active` — eject immediately, re-queue patients
- [ ] **Handyman special case**: `on_call` vs drop-in, `lockRoomOnRepair`/`unlockRoomOnRepair`
- [ ] **Staff entry**: `staffFitsInRoom`, `staffMeetsRoomRequirements`, replacement logic
- [ ] **Patient entry**: Infection redirect, staff criteria check, `commandEnteringPatient`

### Derived Room Overrides
- [ ] **ToiletRoom**: Loo reservation, sink handling, `getPatientCount` override
- [ ] **TrainingRoom**: Doctor-only, projector/chair/skeleton reservation
- [ ] **StaffRoom**: `UseStaffRoomAction` for staff, pass-through for handymen on call
- [ ] **OperatingTheatreRoom**: Surgeon clothes check in `canHumanoidEnter`
- [ ] **Custom rooms**: Any room-specific entry validation

### Critical Invariants
- [ ] `humanoid.in_room` and `humanoid.last_room` set correctly
- [ ] `self.humanoids[humanoid] = true` before any early returns
- [ ] `self:tryAdvanceQueue()` called after successful entry
- [ ] No patient enters room requiring staff without staff present

---

## ⬜ Exit Flow (`onHumanoidLeave`) Changes

### Staff Cleanup
- [ ] Clear `self.staff_member` or `self.staff_member_set` for leaving staff
- [ ] `humanoid.in_room = nil`
- [ ] Membership check: warn if `not self.humanoids[humanoid]`
- [ ] Remove from set: `self.humanoids[humanoid] = nil`

### Patient Departure Effects
- [ ] Release waiting staff to staff room (`staffroom_needed` flag)
- [ ] `tryToFindNearbyPatients()` when queue empty and room active
- [ ] Call for replacement staff if patients waiting

### Staff Departure — Patient Ejection
- [ ] Check `testStaffCriteria(required_staff)` and `getStaffMember() == nil`
- [ ] Eject patients via `makeHumanoidLeave` + re-queue **except Ward**
- [ ] Call for new staff if needed
- [ ] `humanoid:setMood("staff_wait", "deactivate")`

### Handyman Repair Cleanup
- [ ] `unlockRoomOnRepair()` when assigned handyman leaves
- [ ] `tryAdvanceQueue()` after unlock

### Edit Mode Trigger
- [ ] Count remaining humanoids (including door user entering)
- [ ] `enterEditMode()` when count == 0 and inactive

### Derived Room Overrides
- [ ] **OperatingTheatreRoom**: Clear `staff_member_set`, abort surgeons, X-ray off
- [ ] **WardRoom**: `updateHealingAmount()` on any leave
- [ ] **ResearchRoom**: Clear `staff_member_set`
- [ ] **Scanner/Cardiogram/Decontamination**: Clear `staff_member`
- [ ] **TrainingRoom**: Unreserve projector, chairs, skeleton, bookcase

---

## ⬜ Staff Assignment Changes

### Single vs Multi-Staff
- [ ] Single: `self.staff_member` (GP, Pharmacy, Scanner, etc.)
- [ ] Multi: `self.staff_member_set = {}` (OT, Ward, Research, Training)

### Staff Criteria
- [ ] `getRequiredStaffCriteria()` — minimum to function
- [ ] `getMaximumStaffCriteria()` — capacity limit
- [ ] `testStaffCriteria(criteria, optional_staff)` — membership test

### Staff Fit & Replacement
- [ ] `staffFitsInRoom()` — room at max capacity?
- [ ] Replacement priority: idle/meandering → replace, busy → keep
- [ ] Wrong type → send away with `adviseWrongPersonForThisRoom()`

### Service Quality
- [ ] `getStaffServiceQuality()` — single vs multi-staff average
- [ ] Affects treatment speed, patient happiness

---

## ⬜ Patient Treatment Routing Changes

### Diagnosis Flow (GPRoom)
- [ ] `dealtWithPatient()` — deduplication guard
- [ ] `addToTreatmentHistory()`
- [ ] Infection redirect: `needs_redirecting` → GP
- [ ] `completeDiagnosticStep()` — progress tracking
- [ ] Stop policy: `hospital.policies["stop_procedure"]`
- [ ] Pay check: `agreesToPay()` → treatment or `goHome("over_priced")`
- [ ] Next diagnosis room: `sendPatientToNextDiagnosisRoom()`

### Cure Flow
- [ ] `cure_rooms_visited` counter increment
- [ ] Next treatment room from `disease.treatment_rooms`
- [ ] `treatDisease()` when complete

### Room Stealing (`tryToFindNearbyPatients`)
- [ ] Same `room_info.id` rooms only
- [ ] Source queue `reportedSize() >= 2`
- [ ] Score comparison: `getUsageScore() + path_distance`
- [ ] Move from back of queue (`pat_number > 1`)

### Usage Score
- [ ] `queue:patientSize() + getPatientCount() - maximum_patients`
- [ ] Tile factor multiplier (10)
- [ ] Readiness bonus (-50 if staffed)
- [ ] Full queue penalty (+1000)

---

## ⬜ Crash Cascading (`crashRoom`) Changes

### Phase Order (Must Preserve)
1. [ ] Close door, handle reserved humanoid
2. [ ] Kill all humanoids in room (`die()`, `despawn()`, `destroyEntity()`)
3. [ ] Kill door user
4. [ ] Destroy objects (skip doors, swing doors, strong objects)
5. [ ] Place soot (floor + walls)
6. [ ] Hospital impact: `num_explosions++`, value change, reputation hit, deactivate

### Special Handling
- [ ] Emergency patients removed from hospital list
- [ ] Plants: remove watering tasks, mark unreachable
- [ ] Soot type: floor vs wall vs window variants

---

## ⬜ Queue Management Changes

### `tryAdvanceQueue()`
- [ ] Check: queue not empty, no door user, no reserved_for
- [ ] `canHumanoidEnter(front)` check
- [ ] Pop and update dynamic info
- [ ] Staff wait toggle for valid targets

### `canHumanoidEnter()`
- [ ] Active room check
- [ ] Staff: always true
- [ ] Patient: staffed + not at capacity + not needs_repair
- [ ] Derived overrides: OT surgeon ready, Training consultant limit

### Staff Wait Toggle
- [ ] `_staffWaitToggle(activate)` — mood + dynamic info text
- [ ] Valid target: has queue dialog, not toilets, front is patient
- [ ] Handles both single and multi-staff

---

## ⬜ Room Building & Activation (`roomFinished`) Changes

### Base Implementation
- [ ] `built = true`, `is_active = true`
- [ ] Cursor update for non-queue rooms
- [ ] Campaign info dialog (first build per room type)
- [ ] `tryToFindNearbyPatients()`
- [ ] Call for staff if queue has patients
- [ ] `tryAdvanceQueue()`
- [ ] `calculateHappinessFactor()`

### Derived Overrides
- [ ] **OperatingTheatre**: Find X-ray viewer, check Ward + 2 Surgeons
- [ ] **Ward**: Count beds → `maximum_patients`, desks → `maximum_staff`
- [ ] **Research**: Count desks → max researchers, first room advice
- [ ] **Training**: Count chairs + projector → max staff, training factor
- [ ] **Toilet**: Count loos → `maximum_patients`
- [ ] **GP/Pharmacy/Psych**: Verify required staff present

---

## ⬜ Deactivation & Edit Mode Changes

### `deactivate()`
- [ ] `is_active = false`
- [ ] `world:notifyRoomRemoved(self)`
- [ ] `door.queue:rerouteAllPatients(room_info.id)`
- [ ] `hospital:removeRatholesAroundRoom(self)`

### `tryToEdit()`
- [ ] Call `deactivate()`
- [ ] Count people (door user entering + humanoids not leaving)
- [ ] Eject patients: `makeHumanoidLeave` + `SeekRoomAction`
- [ ] Eject staff: `createLeaveAction` + `MeanderAction`
- [ ] `enterEditMode()` if empty

### `enterEditMode()`
- [ ] Close machine UI window if open for this room
- [ ] Open `UIEditRoom`
- [ ] Reset cursor

---

## ⬜ Cross-Cutting Methods

### `commandEnteringStaff`
- [ ] Set `staff_member` or add to `staff_member_set`
- [ ] `tryToFindNearbyPatients()`
- [ ] Clear dynamic info
- [ ] Drop from dispatcher queue if staffed

### `commandEnteringPatient`
- [ ] Increment `visitor_count`
- [ ] Clear patient dynamic info
- [ ] Disable staff wait toggle

### `dealtWithPatient`
- [ ] Central routing — diagnosis vs cure
- [ ] Derived rooms implement specific logic

### `makeHumanoidLeave` / `makeHumanoidDressIfNecessaryAndThenLeave`
- [ ] Dressing rooms: GP, Scanner, Cardiogram, GeneralDiag, XRay
- [ ] Undress → leave action → dress on re-enter

### `afterLoad` (Save Migration)
- [ ] Version-specific data structure handling
- [ ] Backward compatibility for old saves

### `isDiagnosisRoomForPatient`
- [ ] GP always valid
- [ ] Check `patient.disease.diagnosis_rooms` for others

### `calculateHappinessFactor`
- [ ] Window factor (log scale, staff_room x2)
- [ ] Space factor (log scale vs minimum_size)
- [ ] Sum = happiness_factor

---

## ⬜ Testing Requirements

### Unit Tests (Busted)
- [ ] Entry flow: inactive room, handyman, staff fit/replace/wrong, patient redirect/staffed/unstaffed
- [ ] Exit flow: staff cleanup, patient release staff, queue advance, staff recall, staff departure ejection, handyman unlock, edit mode trigger
- [ ] Staff: criteria, fit test, service quality (single + multi)
- [ ] Patient routing: diagnosis complete, refuse pay, cure advance, cure complete
- [ ] Crash: door, humanoids, door user, objects, soot, hospital impact
- [ ] Queue: advance, cannot enter, already in room, wait toggle
- [ ] canHumanoidEnter: inactive, staff, patient criteria/capacity/repair
- [ ] roomFinished: built/active, staff call, queue advance, happiness, info dialog
- [ ] Deactivate: inactive, reroute, ratholes
- [ ] Edit mode: eject all, enter edit
- [ ] Derived rooms: OT, Ward, Research, Training, Toilet, GP overrides

### Integration Tests
- [ ] Full patient journey: GP → diagnosis → treatment → cure
- [ ] Staff replacement chain with patient continuity
- [ ] Crash during treatment
- [ ] Multi-room patient stealing

### Regression Checks
- [ ] Run existing test suite
- [ ] Test save/load cycle
- [ ] Test campaign level progression
- [ ] Test sandbox mode

---

## ⬜ Code Quality Gates

### Before Commit
- [ ] No `print()` debugging left in code
- [ ] Assertions for invariants (not just comments)
- [ ] Consistent indentation (tabs, 4 spaces equivalent)
- [ ] Local variables declared at top of functions
- [ ] No global variable leaks
- [ ] Comments explain *why*, not *what*

### Performance
- [ ] O(1) set operations maintained (no `ipairs` on humanoid sets)
- [ ] No unnecessary iterations in hot paths (entry/exit/queue)
- [ ] `getPatientCount()` cached where called repeatedly

### Compatibility
- [ ] Save game migration handled in `afterLoad`
- [ ] Network/multiplayer considerations (if applicable)
- [ ] Mod compatibility: room_info fields, staff profiles

---

## ⬜ Documentation Updates

- [ ] Update `SUMMARY.md` if architecture changes
- [ ] Update `MAP.md` if method locations change
- [ ] Update inline comments for complex logic
- [ ] Update CHANGELOG.md with user-facing changes

---

## ⬜ Post-Merge Verification

- [ ] CI passes (lint, tests, build)
- [ ] Manual smoke test: build room, hire staff, send patient
- [ ] Edge case: deactivate during treatment
- [ ] Edge case: crash room with patients
- [ ] Edge case: edit room with staff inside
- [ ] Edge case: multiple same-type rooms stealing patients

---

*Checklist Version: 1.0 | Area: Room Lifecycle | Last Updated: 2026-08-25*


## Related Pages

- [[03-room-lifecycle/SUMMARY]]
- [[03-room-lifecycle/MAP]]
- [[03-room-lifecycle/SCAFFOLD]]
