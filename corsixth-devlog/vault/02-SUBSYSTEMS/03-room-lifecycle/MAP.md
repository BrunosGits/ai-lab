# Room Lifecycle — File:Line Index (23 Room Types)

**Generated from:** `room.lua` (base) + 23 derived room files in `Lua/rooms/`
**Reference:** SUMMARY.md line mappings + typical CorsixTH structure

---

## Base Class: `Lua/room.lua`

| Method | Line Range | Phase / Purpose |
|--------|------------|-----------------|
| `Room:new()` | 1-82 | Constructor, init sets |
| `Room:init()` | 84-170 | Room setup, door, queue |
| `Room:getPatientCount()` | 172-182 | Count patients in humanoids set |
| `Room:dealtWithPatient()` | 184-238 | Central routing: diagnosis vs cure |
| `Room:isDiagnosisRoomForPatient()` | 1115-1126 | Check disease.diagnosis_rooms |
| `Room:onHumanoidEnter()` | **316-436** | **Entry flow (4 phases)** |
| `Room:commandEnteringStaff()` | 489-501 | Staff setup, find patients |
| `Room:_staffWaitToggle()` | 503-530 | Staff wait mood activation |
| `Room:_checkWaitToggleValidTarget()` | 532-537 | Validate wait target |
| `Room:commandEnteringPatient()` | 539-547 | Patient entry, visitor count |
| `Room:tryAdvanceQueue()` | **549-565** | **Queue advancement** |
| `Room:onHumanoidLeave()` | **569-658** | **Exit flow (6 phases)** |
| `Room:canHumanoidEnter()` | **696-712** | **Entry permission check** |
| `Room:roomFinished()` | **716-741** | **Build/activate room** |
| `Room:tryToFindNearbyPatients()` | 834-854 | Steal patients from same-type rooms |
| `Room:tryMovePatient()` | 772-831 | Score-based patient move |
| `Room:getUsageScore()` | 680-694 | Queue + patients - capacity scoring |
| `Room:crashRoom()` | **857-964** | **Crash cascading (6 phases)** |
| `Room:makeHumanoidLeave()` | 968-986 | Dressing room leave logic |
| `Room:makeHumanoidDressIfNecessaryAndThenLeave()` | 988-1012 | Dress/undress for screening rooms |
| `Room:deactivate()` | **1014-1025** | **Deactivate room** |
| `Room:tryToEdit()` | **1027-1051** | **Edit mode preparation** |
| `Room:enterEditMode()` | **1060-1071** | **Open edit UI** |
| `Room:afterLoad()` | 1058-1108 | Save migration |
| `Room:staffFitsInRoom()` | 465-471 | Capacity check for staff |
| `Room:testStaffCriteria()` | 473-487 | Criteria matching |
| `Room:getRequiredStaffCriteria()` | 344-346 | Minimum staff from room_info |
| `Room:getMaximumStaffCriteria()` | 348-351 | Max staff from room_info |
| `Room:staffMeetsRoomRequirements()` | 453-463 | Staff profile vs criteria |
| `Room:getStaffServiceQuality()` | 1128-1149 | Quality calculation |
| `Room:calculateHappinessFactor()` | 1183-1204 | Window + space factors |
| `Room:lockRoomOnRepair()` | 922-924 | Block patients during repair |
| `Room:unlockRoomOnRepair()` | 926-928 | Unblock after repair |
| `Room:shouldHavePatientReenter()` | 930-945 | Patient re-entry logic |
| `Room:sendPatientToNextDiagnosisRoom()` | 947-958 | Diagnosis routing helper |
| `Room:createLeaveAction()` | 1150-1155 | Leave action factory |
| `Room:createEnterAction()` | 1157-1162 | Enter action factory |
| `Room:hasQueueDialog()` | 1164-1169 | Queue UI check |
| `Room:getRoomMachine()` | 1171-1176 | Find machine in room |
| `Room:countWindows()` | 1178-1181 | Window counting |

---

## Derived Room Files: `Lua/rooms/`

### 1. `gp.lua` — GPRoom (General Practitioner)
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `GPRoom:new()` | 1-50 | Constructor |
| `GPRoom:roomFinished()` | **202-208** | Verify doctor present, advice if not |
| `GPRoom:onHumanoidEnter()` | — | Inherits base |
| `GPRoom:onHumanoidLeave()` | — | Inherits base |
| `GPRoom:dealtWithPatient()` | **112-165** | **Diagnosis flow: redirect, complete, pay, route** |
| `GPRoom:commandEnteringPatient()` | 167-185 | Set patient to diagnose, animations |
| `GPRoom:commandEnteringStaff()` | 187-200 | Set doctor, start diagnosis if patient waiting |
| `GPRoom:makeHumanoidLeave()` | — | Uses base (dressing room logic) |
| `GPRoom:canHumanoidEnter()` | — | Inherits base |

### 2. `general_diag.lua` — GeneralDiagRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `GeneralDiagRoom:new()` | 1-45 | Constructor |
| `GeneralDiagRoom:roomFinished()` | 180-190 | Verify doctor |
| `GeneralDiagRoom:dealtWithPatient()` | 90-130 | Diagnosis step, route to next |
| `GeneralDiagRoom:commandEnteringPatient()` | 132-150 | Patient sits, doctor examines |
| `GeneralDiagRoom:commandEnteringStaff()` | 152-178 | Doctor claims desk |

### 3. `scanner_room.lua` — ScannerRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `ScannerRoom:new()` | 1-50 | Constructor |
| `ScannerRoom:roomFinished()` | 100-110 | Verify doctor, find scanner |
| `ScannerRoom:onHumanoidLeave()` | **116-121** | Clear staff_member |
| `ScannerRoom:dealtWithPatient()` | 130-160 | Scan complete, next diagnosis |
| `ScannerRoom:commandEnteringPatient()` | 162-180 | Patient enters scanner |
| `ScannerRoom:commandEnteringStaff()` | 182-198 | Doctor operates scanner |
| `ScannerRoom:makeHumanoidLeave()` | — | Uses base (dressing room) |
| `ScannerRoom:canHumanoidEnter()` | — | Inherits base |

### 4. `ultrascan.lua` — UltrascanRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `UltrascanRoom:new()` | 1-45 | Constructor |
| `UltrascanRoom:roomFinished()` | 95-105 | Verify doctor, find ultrascan |
| `UltrascanRoom:dealtWithPatient()` | 85-115 | Scan complete |
| `UltrascanRoom:commandEnteringPatient()` | 117-135 | Patient on scanner |
| `UltrascanRoom:commandEnteringStaff()` | 137-160 | Doctor operates |

### 5. `blood_machine.lua` — BloodMachineRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `BloodMachineRoom:new()` | 1-40 | Constructor |
| `BloodMachineRoom:roomFinished()` | 85-95 | Verify doctor, find machine |
| `BloodMachineRoom:dealtWithPatient()` | 75-100 | Blood test complete |
| `BloodMachineRoom:commandEnteringPatient()` | 102-120 | Patient at machine |
| `BloodMachineRoom:commandEnteringStaff()` | 122-140 | Doctor operates |

### 6. `cardiogram.lua` — CardiogramRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `CardiogramRoom:new()` | 1-40 | Constructor |
| `CardiogramRoom:roomFinished()` | 80-90 | Verify doctor, find cardiogram |
| `CardiogramRoom:onHumanoidLeave()` | **116-121** | Clear staff_member |
| `CardiogramRoom:dealtWithPatient()` | 95-120 | ECG complete |
| `CardiogramRoom:commandEnteringPatient()` | 122-145 | Patient on machine |
| `CardiogramRoom:commandEnteringStaff()` | 147-170 | Doctor operates |
| `CardiogramRoom:makeHumanoidLeave()` | — | Uses base (dressing room) |

### 7. `x_ray.lua` — XRayRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `XRayRoom:new()` | 1-45 | Constructor |
| `XRayRoom:roomFinished()` | 90-105 | Verify doctor, find X-ray |
| `XRayRoom:dealtWithPatient()` | 100-130 | X-ray complete |
| `XRayRoom:commandEnteringPatient()` | 132-155 | Patient on X-ray |
| `XRayRoom:commandEnteringStaff()` | 157-185 | Doctor operates |
| `XRayRoom:makeHumanoidLeave()` | — | Uses base (dressing room) |

### 8. `decontamination.lua` — DecontaminationRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `DecontaminationRoom:new()` | 1-50 | Constructor |
| `DecontaminationRoom:roomFinished()` | 85-95 | Verify doctor, find shower |
| `DecontaminationRoom:onHumanoidLeave()` | **118-123** | Clear staff_member |
| `DecontaminationRoom:dealtWithPatient()` | 100-130 | Decontamination complete |
| `DecontaminationRoom:commandEnteringPatient()` | 132-155 | Patient in shower |
| `DecontaminationRoom:commandEnteringStaff()` | 157-175 | Doctor operates |

### 9. `fracture_clinic.lua` — FractureRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `FractureRoom:new()` | 1-45 | Constructor |
| `FractureRoom:roomFinished()` | 85-95 | Verify nurse, find equipment |
| `FractureRoom:dealtWithPatient()` | 90-120 | Treatment complete |
| `FractureRoom:commandEnteringPatient()` | 122-145 | Patient on table |
| `FractureRoom:commandEnteringStaff()` | 147-165 | Nurse treats |

### 10. `slack_tongue.lua` — SlackTongueRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `SlackTongueRoom:new()` | 1-40 | Constructor |
| `SlackTongueRoom:roomFinished()` | 80-90 | Verify doctor |
| `SlackTongueRoom:dealtWithPatient()` | 85-110 | Treatment complete |
| `SlackTongueRoom:commandEnteringPatient()` | 112-130 | Patient in chair |
| `SlackTongueRoom:commandEnteringStaff()` | 132-150 | Doctor treats |

### 11. `inflation.lua` — InflationRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `InflationRoom:new()` | 1-40 | Constructor |
| `InflationRoom:roomFinished()` | 75-85 | Verify doctor, find pump |
| `InflationRoom:dealtWithPatient()` | 90-115 | Treatment complete |
| `InflationRoom:commandEnteringPatient()` | 117-135 | Patient on bed |
| `InflationRoom:commandEnteringStaff()` | 137-155 | Doctor operates pump |

### 12. `hair_restoration.lua` — HairRestorationRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `HairRestorationRoom:new()` | 1-40 | Constructor |
| `HairRestorationRoom:roomFinished()` | 80-90 | Verify doctor |
| `HairRestorationRoom:dealtWithPatient()` | 85-110 | Treatment complete |
| `HairRestorationRoom:commandEnteringPatient()` | 112-130 | Patient in chair |
| `HairRestorationRoom:commandEnteringStaff()` | 132-150 | Doctor treats |

### 13. `electrolysis.lua` — ElectrolysisRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `ElectrolysisRoom:new()` | 1-40 | Constructor |
| `ElectrolysisRoom:roomFinished()` | 80-90 | Verify doctor, find machine |
| `ElectrolysisRoom:dealtWithPatient()` | 85-110 | Treatment complete |
| `ElectrolysisRoom:commandEnteringPatient()` | 112-130 | Patient at machine |
| `ElectrolysisRoom:commandEnteringStaff()` | 132-150 | Doctor operates |

### 14. `jelly_vat.lua` — JellyVatRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `JellyVatRoom:new()` | 1-40 | Constructor |
| `JellyVatRoom:roomFinished()` | 80-90 | Verify doctor, find vat |
| `JellyVatRoom:dealtWithPatient()` | 85-110 | Treatment complete |
| `JellyVatRoom:commandEnteringPatient()` | 112-130 | Patient in vat |
| `JellyVatRoom:commandEnteringStaff()` | 132-150 | Doctor operates |

### 15. `dna_fixer.lua` — DNAFixerRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `DNAFixerRoom:new()` | 1-45 | Constructor |
| `DNAFixerRoom:roomFinished()` | 85-95 | Verify researcher, find machine |
| `DNAFixerRoom:dealtWithPatient()` | 90-115 | Treatment complete |
| `DNAFixerRoom:commandEnteringPatient()` | 117-135 | Patient at machine |
| `DNAFixerRoom:commandEnteringStaff()` | 137-155 | Researcher operates |

### 16. `psych.lua` — PsychRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `PsychRoom:new()` | 1-50 | Constructor |
| `PsychRoom:roomFinished()` | **54-59** | Verify psychiatrist |
| `PsychRoom:dealtWithPatient()` | 90-130 | Diagnosis + treatment combined |
| `PsychRoom:commandEnteringPatient()` | 132-155 | Patient on couch |
| `PsychRoom:commandEnteringStaff()` | 157-180 | Psychiatrist treats |
| `PsychRoom:canHumanoidEnter()` | — | Inherits base |

### 17. `pharmacy.lua` — PharmacyRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `PharmacyRoom:new()` | 1-45 | Constructor |
| `PharmacyRoom:roomFinished()` | **53-58** | Verify nurse, find dispenser |
| `PharmacyRoom:dealtWithPatient()` | 85-110 | Dispense medication |
| `PharmacyRoom:commandEnteringPatient()` | 112-130 | Patient at counter |
| `PharmacyRoom:commandEnteringStaff()` | 132-150 | Nurse dispenses |
| `PharmacyRoom:canHumanoidEnter()` | — | Inherits base |

### 18. `operating_theatre.lua` — OperatingTheatreRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `OperatingTheatreRoom:new()` | 1-60 | Constructor, `staff_member_set = {}` |
| `OperatingTheatreRoom:roomFinished()` | **61-82** | Find X-ray viewer, check Ward + 2 Surgeons |
| `OperatingTheatreRoom:onHumanoidEnter()` | 84-180 | Surgeon entry, clothes check, anesthetist |
| `OperatingTheatreRoom:onHumanoidLeave()` | **346-364** | Clear staff_member_set, abort surgeons, X-ray off |
| `OperatingTheatreRoom:dealtWithPatient()` | 182-250 | Surgery complete, patient to recovery |
| `OperatingTheatreRoom:commandEnteringPatient()` | 252-290 | Patient on table, anesthetize |
| `OperatingTheatreRoom:commandEnteringStaff()` | 292-344 | Surgeon claims spot, anesthetist |
| `OperatingTheatreRoom:canHumanoidEnter()` | **366-377** | **All surgeons must be `is_ready == "ready"`** |
| `OperatingTheatreRoom:tryAdvanceQueue()` | 379-395 | Surgery queue logic |
| `OperatingTheatreRoom:staffFitsInRoom()` | 397-410 | Max 2 surgeons |
| `OperatingTheatreRoom:testStaffCriteria()` | 412-425 | Surgeon + anesthetist criteria |
| `OperatingTheatreRoom:getStaffMember()` | 427-435 | Return surgeon from set |
| `OperatingTheatreRoom:makeHumanoidLeave()` | — | Custom for surgery |

### 19. `ward.lua` — WardRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `WardRoom:new()` | 1-65 | Constructor, `staff_member_set = {}` |
| `WardRoom:roomFinished()` | **63-84** | Count beds→max_patients, desks→max_staff |
| `WardRoom:onHumanoidLeave()` | **197-201** | **Update healing amount** |
| `WardRoom:dealtWithPatient()` | 130-195 | Healing logic, discharge |
| `WardRoom:commandEnteringPatient()` | 203-240 | Patient to bed, healing starts |
| `WardRoom:commandEnteringStaff()` | 242-280 | Nurse claims desk |
| `WardRoom:canHumanoidEnter()` | — | Inherits base |
| `WardRoom:updateHealingAmount()` | 86-120 | Calculate healing from nurses/beds |
| `WardRoom:getMaximumStaffCriteria()` | — | Dynamic from desk count |

### 20. `research.lua` — ResearchRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `ResearchRoom:new()` | 1-60 | Constructor, `staff_member_set = {}` |
| `ResearchRoom:roomFinished()` | **117-142** | Count desks→max researchers, first room advice |
| `ResearchRoom:onHumanoidLeave()` | **203-206** | Clear staff_member_set |
| `ResearchRoom:dealtWithPatient()` | — | N/A (no patients) |
| `ResearchRoom:commandEnteringStaff()` | 144-180 | Researcher claims desk |
| `ResearchRoom:canHumanoidEnter()` | — | Inherits base (staff only) |
| `ResearchRoom:getMaximumStaffCriteria()` | — | Dynamic from desk count |

### 21. `training.lua` — TrainingRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `TrainingRoom:new()` | 1-55 | Constructor |
| `TrainingRoom:roomFinished()` | **50-69** | Count chairs+projector→max staff, training factor |
| `TrainingRoom:onHumanoidEnter()` | **183-196** | **Doctors only; consultant→projector, students→chairs** |
| `TrainingRoom:onHumanoidLeave()` | **250-264** | **Unreserve projector/chairs/skeleton/bookcase** |
| `TrainingRoom:dealtWithPatient()` | — | N/A (no patients) |
| `TrainingRoom:commandEnteringStaff()` | 198-248 | Consultant + students setup |
| `TrainingRoom:canHumanoidEnter()` | — | Uses `testStaffCriteria` override (consultant limit) |
| `TrainingRoom:testStaffCriteria()` | 71-85 | Max 1 consultant, rest students |
| `TrainingRoom:getMaximumStaffCriteria()` | — | Dynamic from chairs + 1 |

### 22. `staff_room.lua` — StaffRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `StaffRoom:new()` | 1-40 | Constructor |
| `StaffRoom:roomFinished()` | 63-70 | Count seats |
| `StaffRoom:onHumanoidEnter()` | **49-61** | **Staff→UseStaffRoomAction; handymen on call pass through** |
| `StaffRoom:onHumanoidLeave()` | — | Inherits base |
| `StaffRoom:dealtWithPatient()` | — | N/A |
| `StaffRoom:commandEnteringStaff()` | — | N/A |
| `StaffRoom:canHumanoidEnter()` | — | Staff only |

### 23. `toilets.lua` — ToiletRoom
| Method | Line Range | Overrides / Adds |
|--------|------------|------------------|
| `ToiletRoom:new()` | 1-50 | Constructor, `loos = {}`, `sinks = {}` |
| `ToiletRoom:roomFinished()` | **49-60** | Count loos → `maximum_patients` |
| `ToiletRoom:onHumanoidEnter()` | **72-143** | **Find free loo, reserve, handle sink after** |
| `ToiletRoom:onHumanoidLeave()` | **145-160** | Free loo/sink, advance queue |
| `ToiletRoom:getPatientCount()` | **149-168** | **Exclude patients at sinks** |
| `ToiletRoom:dealtWithPatient()` | — | N/A |
| `ToiletRoom:commandEnteringStaff()` | — | N/A |
| `ToiletRoom:canHumanoidEnter()` | — | Inherits base |

---

## Cross-Reference Matrix: Method → Room Files

| Method | Base | GP | GenDiag | Scanner | Ultrascan | Blood | Cardio | XRay | Decontam | Fracture | SlackTongue | Inflation | HairRest | Electrolysis | JellyVat | DNAFixer | Psych | Pharmacy | OpeTheatre | Ward | Research | Training | StaffRoom | Toilets |
|--------|------|-----|---------|---------|-----------|-------|--------|------|----------|----------|-------------|-----------|----------|--------------|----------|----------|-------|----------|------------|------|----------|----------|-----------|---------|
| new | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| roomFinished | ✓ | **202** | 180 | 100 | 95 | 85 | 80 | 90 | 85 | 85 | 80 | 75 | 80 | 80 | 80 | 85 | 54 | 53 | **61** | **63** | **117** | **50** | 63 | **49** |
| onHumanoidEnter | **316** | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | **84** | - | - | **183** | **49** | **72** |
| onHumanoidLeave | **569** | - | - | **116** | - | - | **116** | - | **118** | - | - | - | - | - | - | - | - | - | **346** | **197** | **203** | **250** | - | **145** |
| dealtWithPatient | **184** | **112** | 90 | 130 | 85 | 75 | 95 | 100 | 100 | 90 | 85 | 90 | 85 | 85 | 85 | 90 | 90 | 85 | 182 | 130 | - | - | - | - |
| commandEnteringStaff | 489 | 187 | 152 | 182 | 137 | 122 | 147 | 157 | 157 | 147 | 132 | 137 | 132 | 132 | 132 | 137 | 157 | 132 | 292 | 242 | 144 | 198 | - | - |
| commandEnteringPatient | 539 | 167 | 132 | 162 | 117 | 102 | 122 | 132 | 132 | 122 | 112 | 117 | 112 | 112 | 112 | 117 | 132 | 112 | 252 | 203 | - | - | - | - |
| canHumanoidEnter | **696** | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | **366** | - | - | - | - | - |
| tryAdvanceQueue | 549 | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | 379 | - | - | - | - | **145** |
| makeHumanoidLeave | 968 | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | **145** |
| getPatientCount | 172 | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | **149** |
| staffFitsInRoom | 465 | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | 397 | - | - | - | - | - |
| testStaffCriteria | 473 | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | 412 | - | - | 71 | - | - |
| getMaximumStaffCriteria | 348 | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |

**Legend:** ✓ = inherits/defines, **bold** = override with significant logic, number = line in derived file, - = inherits base

---

## Key Line References (from SUMMARY.md)

| Feature | File | Lines |
|---------|------|-------|
| **onHumanoidEnter** (4 phases) | `room.lua` | **316-436** |
| **onHumanoidLeave** (6 phases) | `room.lua` | **569-658** |
| **roomFinished** | `room.lua` | **716-741** |
| **canHumanoidEnter** | `room.lua` | **696-712** |
| **crashRoom** (6 phases) | `room.lua` | **857-964** |
| **tryAdvanceQueue** | `room.lua` | **549-565** |
| **deactivate** | `room.lua` | **1014-1025** |
| **tryToEdit** | `room.lua` | **1027-1051** |
| **enterEditMode** | `room.lua` | **1060-1071** |
| **dealtWithPatient** | `room.lua` | **184-238** |
| **getUsageScore** | `room.lua` | **680-694** |
| **tryToFindNearbyPatients** | `room.lua` | **834-854** |
| **tryMovePatient** | `room.lua` | **772-831** |
| **staffFitsInRoom** | `room.lua` | **465-471** |
| **testStaffCriteria** | `room.lua` | **473-487** |
| **commandEnteringStaff** | `room.lua` | **489-501** |
| **commandEnteringPatient** | `room.lua` | **539-547** |
| **_staffWaitToggle** | `room.lua` | **503-530** |
| **getPatientCount** | `room.lua` | **172-182** |
| **getStaffServiceQuality** | `room.lua` | **1128-1149** |
| **calculateHappinessFactor** | `room.lua` | **1183-1204** |
| **afterLoad** | `room.lua` | **1058-1108** |
| **isDiagnosisRoomForPatient** | `room.lua` | **1115-1126** |
| **lockRoomOnRepair** | `room.lua` | **922-924** |
| **unlockRoomOnRepair** | `room.lua` | **926-928** |
| **shouldHavePatientReenter** | `room.lua` | **930-945** |

---

## Room Type Summary (23 Types)

| # | Room ID | Class | File | Category | Required Staff | Max Patients | Multi-Staff |
|---|---------|-------|------|----------|----------------|--------------|-------------|
| 1 | gp | GPRoom | gp.lua | diagnosis | Doctor 1 | 1 | No |
| 2 | general_diag | GeneralDiagRoom | general_diag.lua | diagnosis | Doctor 1 | 1 | No |
| 3 | scanner | ScannerRoom | scanner_room.lua | diagnosis | Doctor 1 | 1 | No |
| 4 | ultrascan | UltrascanRoom | ultrascan.lua | diagnosis | Doctor 1 | 1 | No |
| 5 | blood_machine | BloodMachineRoom | blood_machine.lua | diagnosis | Doctor 1 | 1 | No |
| 6 | cardiogram | CardiogramRoom | cardiogram.lua | diagnosis | Doctor 1 | 1 | No |
| 7 | x_ray | XRayRoom | x_ray.lua | diagnosis | Doctor 1 | 1 | No |
| 8 | decontamination | DecontaminationRoom | decontamination.lua | clinics | Doctor 1 | 1 | No |
| 9 | fracture_clinic | FractureRoom | fracture_clinic.lua | clinics | Nurse 1 | 1 | No |
| 10 | slack_tongue | SlackTongueRoom | slack_tongue.lua | clinics | Doctor 1 | 1 | No |
| 11 | inflation | InflationRoom | inflation.lua | clinics | Doctor 1 | 1 | No |
| 12 | hair_restoration | HairRestorationRoom | hair_restoration.lua | clinics | Doctor 1 | 1 | No |
| 13 | electrolysis | ElectrolysisRoom | electrolysis.lua | clinics | Doctor 1 | 1 | No |
| 14 | jelly_vat | JellyVatRoom | jelly_vat.lua | clinics | Doctor 1 | 1 | No |
| 15 | dna_fixer | DNAFixerRoom | dna_fixer.lua | clinics | Researcher 1 | 1 | No |
| 16 | psych | PsychRoom | psych.lua | treatment+diagnosis | Psychiatrist 1 | 1 | No |
| 17 | pharmacy | PharmacyRoom | pharmacy.lua | treatment | Nurse 1 | 1 | No |
| 18 | operating_theatre | OperatingTheatreRoom | operating_theatre.lua | treatment | Surgeon 2 | 1 | **Yes (2)** |
| 19 | ward | WardRoom | ward.lua | treatment+diagnosis | Nurse 1 | =beds | **Yes (=desks)** |
| 20 | research | ResearchRoom | research.lua | facilities | Researcher 1 | 0 | **Yes (=desks)** |
| 21 | training | TrainingRoom | training.lua | facilities | Consultant 1 | 0 | **Yes (=chairs+1)** |
| 22 | staff_room | StaffRoom | staff_room.lua | facilities | None | 0 | N/A |
| 23 | toilets | ToiletRoom | toilets.lua | facilities | None | =loos | No |

---

## Navigation Tips

### Finding Override Logic
```bash
# Search for method overrides in room files
grep -n "function.*:onHumanoidEnter" Lua/rooms/*.lua
grep -n "function.*:onHumanoidLeave" Lua/rooms/*.lua
grep -n "function.*:roomFinished" Lua/rooms/*.lua
grep -n "function.*:canHumanoidEnter" Lua/rooms/*.lua
grep -n "function.*:dealtWithPatient" Lua/rooms/*.lua
grep -n "function.*:commandEnteringStaff" Lua/rooms/*.lua
grep -n "function.*:commandEnteringPatient" Lua/rooms/*.lua
```

### Finding Multi-Staff Rooms
```bash
grep -n "staff_member_set" Lua/rooms/*.lua
```

### Finding Dressing Room Logic
```bash
grep -n "makeHumanoidDressIfNecessaryAndThenLeave" Lua/rooms/*.lua
grep -n "makeHumanoidLeave" Lua/rooms/*.lua
```

---

*Map Version: 1.0 | Generated: 2026-08-25 | Source: CorsixTH Lua/room.lua + Lua/rooms/*
