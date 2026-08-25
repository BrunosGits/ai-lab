# Patient Lifecycle - File:Line Index

Complete cross-reference of all patient lifecycle methods, state fields, and related code locations in CorsixTH.

---

## PATIENT.LUA (1,378 lines)

### State Fields (Constructor - lines 27-73)

| Line | Field | Type | Description |
|------|-------|------|-------------|
| 31 | `treatment_history` | table | Log of visited rooms/diseases |
| 32 | `going_home` | boolean | Patient leaving hospital |
| 33 | `litter_countdown` | number/nil | Tiles before dropping litter |
| 34 | `has_fallen` | number | Falling animation state (1=ready, 2=falling, 3=cooldown) |
| 35 | `has_vomitted` | number | Vomit count today |
| 36 | `action_string` | string | Dynamic info action text |
| 37 | `cured` | boolean | Successfully treated |
| 38 | `infected` | boolean | Has epidemic disease |
| 39 | `pay_amount` | number | Agreed payment amount |
| 41 | `dead` | boolean | Actually dead |
| 45 | `set_to_die` | boolean | Flag to die when free |
| 48 | `going_to_die` | boolean | In dying animation |
| 50 | `reserved_for` | object/false | Reserved for vaccination nurse |
| 51 | `vaccinated` | boolean | Received vaccination |
| 53 | `needs_redirecting` | boolean | Wrong room, needs GP redirect |
| 56 | `under_infection_attempt` | boolean | Being infected by another |
| 58 | `vaccination_candidate` | boolean | Marked for vaccination |
| 60 | `has_passed_reception` | boolean | Processed at reception desk |
| 63 | `diagnosis_progress` | number | 0 to ~2.5 |
| 66 | `going_to_toilet` | string | "yes", "no", "no-toilets" |
| 72 | `health_history` | table/nil | Circular buffer for health chart |

---

### Core Lifecycle Methods

| Line | Method | Purpose |
|------|--------|---------|
| 111 | `setDisease(disease)` | Initialize disease, diagnosis rooms, insurance (25%), thirst/toilet |
| 138 | `changeDisease(new_disease)` | Epidemic disease mutation, preserves visited rooms |
| 170 | `setDiagnosed()` | Mark diagnosed, log to treatment_history |
| 184 | `modifyDiagnosisProgress(increment)` | Update progress, clamp to policy |
| 197 | `completeDiagnosticStep(room)` | Calculate progress from doctor skill/fatigue |
| 232 | `setHospital(hospital)` | Assign hospital, queue SeekReceptionAction |
| 246 | `getTreatmentDiseaseId()` | Return disease_id or "diag_<room>" |
| 268 | `getPriceDistortion(casebook)` | Calculate patient price perception [-1,1] |
| 295 | `treatDisease()` | Final resolution: cure or die |
| 319 | `agreesToPay(disease_id)` | Exponential payment chance for overpriced |
| 343 | `isTreatmentEffective()` | Cure chance = effectiveness × diagnosis_progress ± service |
| 359 | `hasMoreDiagnosisRoomsAvailable()` | Check available_diagnosis_rooms |
| 364 | `cure()` | Set cured=true, health=1, infected=false |
| 371 | `die()` | Hospital death record, moods, DieAction queue |
| 509 | `goHome(reason, disease_id)` | Discharge: cured/kicked/over_priced/evacuated |
| 578 | `despawn()` | Remove from hospital, Humanoid.despawn |

---

### Daily Processing (tickDay - line 933)

| Line | Method | Purpose |
|------|--------|---------|
| 619 | `_dailyWaitChecks()` | Decrement waiting, go_home at 0, animations at 10/20/30 |
| 654 | `_dailyHealthChecks()` | Health deterioration, mood thresholds, fed_up leave chance |
| 709 | `_dailyHealthHistoryRefresh()` | Circular buffer update (size 20) |
| 726 | `_calculateNausea(vomit_count)` | Nausea from health + proximity to vomit |
| 742 | `_dailyBowelChecks()` | Increase toilet_need, seek toilet at >0.75 |
| 758 | `handleToiletNeed()` | 40% floor pee, 60% SeekToiletsAction |
| 782 | `_dailyObjectHappinessEffects()` | Plants, extinguishers, benches, litter, vomit |
| 865 | `_handleExcessThirst()` | Thirst > 0.7 → seek drinks machine |
| 819 | `_constructGetSodaAction()` | Walk to machine, use, 60% litter can |
| 900 | `_checkPatientIsStillQueueingForARoom()` | Validate queue membership |

---

### Utility Methods

| Line | Method | Purpose |
|------|--------|---------|
| 415 | `falling(player_init)` | Earthquake/player push → falling anim |
| 447 | `vomit()` | Queue VomitAction if at empty tile |
| 460 | `pee()` | Queue PeeAction if at empty tile |
| 477 | `checkWatch()` | Queue CheckWatchAction if idle |
| 484 | `yawn()` | Queue YawnAction if idle |
| 491 | `tapFoot()` | Queue TapFootAction if idle |
| 591 | `setToDying()` | Set set_to_die=true |
| 598 | `tick()` | Check set_to_die → die() when free |
| 1006 | `notifyNewRoom(room)` | Reset no-toilets when toilet built |
| 1014 | `setTile(x,y)` | Litter dropping logic |
| 1055 | `notifyNewObject(id)` | Bench notification for queue |
| 1074 | `addToTreatmentHistory(room)` | Log non-facility rooms |
| 1090 | `setDynamicInfoText(text)` | Set action_string |
| 1097 | `updateDynamicInfo()` | Build full dynamic info display |
| 1144 | `updateMessage(choice)` | Update fax message choices |
| 1198 | `setInfectedStatus()` | Epidemic mood epidemy4 |
| 1205 | `setToReadyForVaccinationStatus()` | Epidemy2 |
| 1212 | `giveVaccinationCandidateStatus()` | Epidemy3 |
| 1219 | `removeVaccinationCandidateStatus()` | Back to epidemy2 |
| 1228 | `setVaccinatedStatus()` | Epidemy1 |
| 1236 | `removeAnyEpidemicStatus()` | Clear all epidemy moods |
| 1243 | `afterLoad(old,new)` | Save version migrations |
| 1318 | `isMalePatient()` | Gender check for animations |
| 1336 | `interruptAndRequeueAction()` | Interrupt current, requeue with meander |

---

## ROOM.LUA (1,232 lines)

### Room:dealtWithPatient() - lines 192-237

| Line | Logic |
|------|-------|
| 196 | Early return if no hospital or going_home |
| 202 | Set leave action, add to treatment history |
| 204 | Clear staff dealing_with_patient flag |
| 209 | **Not diagnosed**: completeDiagnosticStep, receive money, agreesToPay("diag_gp") → GP or goHome |
| 220 | **Diagnosed**: cure_rooms_visited++, next treatment room or treatDisease() |

### Other Room Methods

| Line | Method | Purpose |
|------|--------|---------|
| 119 | `commandEnteringPatient()` | SeekRoomAction for staff |
| 330 | `commandEnteringPatient()` | Patient enters room |
| 422 | `onHumanoidLeave()` | Patient leaves → GP redirect |
| 870 | `commandEnteringPatient()` | Psychiatrist room |
| 1039 | `commandEnteringPatient()` | General room enter |

---

## ROOMS/GP.LUA (210 lines)

### GPRoom:dealtWithPatient() - lines 112-165

| Line | Logic |
|------|-------|
| 131 | Handle needs_redirecting → sendPatientToNextDiagnosisRoom |
| 134 | Not diagnosed: receiveMoney, completeDiagnosticStep |
| 137 | Check diagnosis_progress ≥ stop_procedure OR no more rooms |
| 142 | setDiagnosed() |
| 143 | agreesToPay(disease.id) → treatment room or goHome over_priced |
| 154 | Else sendPatientToNextDiagnosisRoom |

### GPRoom:sendPatientToNextDiagnosisRoom() - lines 167-183

| Line | Logic |
|------|-------|
| 168 | No more rooms → goHome kicked |
| 175 | Random available diagnosis room |
| 177 | agreesToPay("diag_"..room) → SeekRoomAction or goHome |

---

## OBJECTS/RECEPTION_DESK.LUA (263 lines)

### ReceptionDesk:tick() - lines 94-167

| Line | Logic |
|------|-------|
| 99 | handlePatient(patient, is_new) |
| 102 | Redirected patient: SeekRoomAction(next_room_to_visit) |
| 107 | New patient: agreesToPay("diag_gp") → GP or goHome over_priced |
| 133 | advanceQueue() - timer based on receptionist skill |
| 147 | Process front humanoid: Patient/Inspector/VIP |
| 160 | has_passed_reception = true |

---

## HOSPITAL.LUA (2,442 lines)

### Insurance Setup - lines 202-222

| Line | Logic |
|------|-------|
| 204 | Select 3 insurance companies (weighted random) |
| 217 | insurance_balance[3][3] = current, last, before_last month |
| 220 | Payments paid 2 months later |

### Money Handling - lines 1240-1298

| Line | Method | Purpose |
|------|--------|---------|
| 1240 | `receiveMoneyForTreatment(patient)` | Main payment entry |
| 1242 | `getTreatmentDiseaseId()` | disease_id or diag_<room> |
| 1255 | Insurance → addInsuranceMoney() |
| 1260 | Direct pay → computePriceLevelImpact() + receiveMoney() |
| 1279 | `getTreatmentPrice(disease)` | Price scaled by reputation |
| 1290 | `addInsuranceMoney(company, amount)` | Add to current month balance |

### Death & Patient Management

| Line | Method | Purpose |
|------|--------|---------|
| 1420 | `humanoidDeath(patient)` | Record death, reputation -4, update stats |
| 1594 | `removePatient(patient)` | Remove from patients array |
| 1623 | `changeReputation(reason, disease, value)` | Reputation deltas |

---

## HUMANOID_ACTIONS

### SeekReceptionAction (seek_reception.lua)

| Line | Method | Purpose |
|------|--------|---------|
| 21 | `class "SeekReceptionAction"` | Find best reception desk |
| 64 | `action_seek_reception_start()` | Score desks by distance + queue length |
| 39 | `can_join_queue_at()` | Check if can join queue at tile |

### SeekRoomAction (seek_room.lua)

| Line | Method | Purpose |
|------|--------|---------|
| 21 | `class "SeekRoomAction"` | Find diagnosis/treatment room |
| 39 | `enableTreatmentRoom()` | Mark as treatment room |
| 47 | `setDiagnosisRoom(room)` | Set specific diagnosis room index |
| 57 | `action_seek_room_find_room()` | GP choice first, then random available |
| 173 | Emergency: direct to final treatment room |
| 205 | Toilet fallback → SeekToiletsAction |

### DieAction (die.lua)

| Line | Method | Purpose |
|------|--------|---------|
| 21 | `class "DieAction"` | Death animation and cleanup |

### SeekToiletsAction (seek_toilets.lua)

| Line | Method | Purpose |
|------|--------|---------|
| 22 | `class "SeekToiletsAction"` | Find toilet room |
| 62 | Found toilet → SeekRoomAction |
| 64 | No toilet → SeekReceptionAction |

---

## GRIM_REAPER.LUA (53 lines)

| Line | Method | Purpose |
|------|--------|---------|
| 21 | `class "GrimReaper"` | Death animation humanoid |
| 38 | `tickDay()` | Return false (no daily processing) |
| 42 | `updateDynamicInfo()` | No dynamic info |

---

## PATIENT STATE MACHINE QUICK REFERENCE

```
PATIENT STATE FIELDS (patient.lua:27-73)
├── cured (37)          ← set in cure() [364]
├── dead (41)           ← set in die() [371] via DieAction
├── going_home (32)     ← set in goHome() [509]
├── going_to_die (48)   ← set in die() [371]
├── set_to_die (45)     ← set in setToDying() [591], checked in tick() [598]
├── diagnosed           ← set in setDiagnosed() [170]
├── diagnosis_progress  ← modified in completeDiagnosticStep() [197]
├── cure_rooms_visited  ← incremented in Room:dealtWithPatient() [223]
├── insurance_company   ← set in setDisease() [127] (25% chance)
└── available_diagnosis_rooms ← set in setDisease() [121], filtered in changeDisease() [159]

STATE TRANSITIONS
SPAWN → setHospital() → SeekReceptionAction
    → RECEPTION → agreesToPay("diag_gp") → GP
    → GP (diagnosed?) → completeDiagnosticStep()
        → progress ≥ stop_procedure OR no rooms → setDiagnosed()
            → agreesToPay(disease.id) → treatment_rooms[1]
            → over_priced → goHome("over_priced")
        → more rooms needed → sendPatientToNextDiagnosisRoom()
            → agreesToPay("diag_<room>") → SeekRoomAction
            → over_priced → goHome("over_priced")
    → TREATMENT ROOMS (sequence)
        → cure_rooms_visited++ each room
        → last room → treatDisease()
            → isTreatmentEffective() → cure() → goHome("cured")
            → else → die() → DieAction → GrimReaper → despawn
    → WAITING TIMEOUT → goHome("kicked")
    → HEALTH ≤ 0.01 → setToDying() → tick() → die()
    → FED UP (1/30 at thresholds) → goHome("kicked")
```

---

## DISEASE DEFINITION REFERENCE

Diseases define (in disease .lua files):
- `diagnosis_rooms` = array of room IDs for diagnosis phase
- `treatment_rooms` = array of room IDs for treatment sequence
- `expertise_id` = links to level_config.expertise for difficulty
- `cure_price` = base treatment price
- `cure_effectiveness` = base cure % (modified by research)
- `contagious` = boolean for epidemic spread
- `only_emergency` = boolean (no thirst/toilet)
- `yawn` = boolean
- `more_loo_use` = boolean
- `effect` = AnimationEffect for visual symptoms

---

## POLICY REFERENCE

Hospital policies (affect patient behavior):
- `stop_procedure` = max diagnosis_progress (default 2.5)
- Used in: modifyDiagnosisProgress [185], GP diagnosis check [138]

---

## REPUTATION IMPACTS

| Reason | Amount | Affects Disease Rep? |
|--------|--------|---------------------|
| cured | +1 | Yes |
| death | -4 | Yes |
| kicked | -3 | No |
| over_priced | -2 | Yes |
| under_priced | +1 | Yes |
| emergency_success | +15 | No |
| emergency_failed | -20 | No |
| room_crash | -50 | No |

---

*Generated from CorsixTH source. Line numbers approximate.*


## Related Pages

- [[04-patient-lifecycle/SUMMARY]]
- [[04-patient-lifecycle/CHECKLIST]]
- [[04-patient-lifecycle/SCAFFOLD]]
