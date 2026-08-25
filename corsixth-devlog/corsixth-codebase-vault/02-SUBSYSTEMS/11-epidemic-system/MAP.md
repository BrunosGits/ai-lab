# Epidemic System - File:Line Method Index

## epidemic.lua (762 lines)

### Class Definition & Constructor
| Line | Method | Description |
|------|--------|-------------|
| 25 | `class "Epidemic"` | Class declaration |
| 32-96 | `Epidemic:Epidemic(hospital, contagious_patient)` | Constructor - initializes epidemic with config, adds first patient |

### Core Tick & Infection
| Line | Method | Description |
|------|--------|-------------|
| 100-109 | `Epidemic:tick()` | Main epidemic tick - calls all sub-systems |
| 111-120 | `Epidemic:addContagiousPatient(patient)` | Adds patient to infected list, marks infected |
| 125-195 | `Epidemic:infectOtherPatients()` | Core infection spread logic |
| 132-157 | `canInfectOther(infector, victim)` | [Local] Checks if infection can occur |
| 159-165 | `infect_other(infector, victim)` | [Local] Executes infection on victim |
| 167-193 | Infection loop | Iterates infected patients, checks adjacent, applies spread formula |

### Reveal & Declaration
| Line | Method | Description |
|------|--------|-------------|
| 197-211 | `Epidemic:checkIfReadyToReveal()` | Sets ready_to_reveal if any patient diagnosed |
| 216-221 | `Epidemic:revealEpidemic()` | Reveals epidemic to player, sends fax |
| 224-229 | `Epidemic:announceStartOfEpidemic()` | Plays random EPID001-004.wav |
| 233-238 | `Epidemic:announceEndOfEpidemic()` | Plays random EPID005-008.wav |
| 330-346 | `Epidemic:sendInitialFax()` | Sends declare vs cover-up fax |
| 348-356 | `Epidemic:calculateInfectedFine(infected_count)` | Calculates fine: max(2000, count * EpidemicFine) |
| 364-366 | `getBaseReputationFromFine(fine_amount)` | [Local] Returns round(fine/100) |
| 371-379 | `Epidemic:resolveDeclaration()` | Handles declare choice - immediate fine + rep hit |
| 383-391 | `Epidemic:clearAllInfectedPatients()` | Vaccinates and clears all epidemic patients |

### Cover-Up Flow
| Line | Method | Description |
|------|--------|-------------|
| 243-257 | `Epidemic:checkInfectedLeftHospital()` | Early termination if infected patient leaves |
| 262-268 | `Epidemic:checkNoInfectedPatients()` | Early termination if all cured |
| 274-282 | `Epidemic:checkPatientsForRemoval()` | Removes patients going home/dying |
| 287-290 | `Epidemic:toggleVaccinationMode()` | Toggles vaccination cursor mode |
| 293-296 | `Epidemic:turnOffVaccinationMode()` | Forces vaccination mode off |
| 299-302 | `Epidemic:_updateVaccinationCursor()` | Updates cursor graphic |
| 308-314 | `Epidemic:markForVaccination(patient)` | Marks patient for vaccination (click handler) |
| 319-327 | `Epidemic:countInfectedPatients()` | Counts infected but not cured patients |
| 396-408 | `Epidemic:startCoverUp()` | Starts cover-up: timer, UI, patient status |
| 411-420 | `Epidemic:finishCoverUp()` | Ends cover-up: spawns inspector, closes timer |
| 424-429 | `Epidemic:handleInspectorArrival()` | Inspector arrived - determines outcome |
| 432-434 | `Epidemic:coverUpTimeIsUp()` | Timer expired - calls finishCoverUp |
| 439-485 | `Epidemic:determineFaxAndFines(still_infected)` | Calculates outcome fax and fines |
| 489-508 | `Epidemic:applyOutcome()` | Applies compensation/fines/rep/evacuation |
| 543-548 | `Epidemic:sendResultFax()` | Sends result fax, plays end announcement |
| 551-561 | `Epidemic:spawnInspector()` | Creates inspector entity at spawn point |
| 565-567 | `Epidemic:_inspectorSpawned()` | [Private] Checks if inspector exists |
| 571-573 | `Epidemic:_isCoverUpActive()` | [Private] Checks if cover-up in progress |

### Vaccination System
| Line | Method | Description |
|------|--------|-------------|
| 578-582 | `is_static(patient)` | [Local] Checks if patient is stationary |
| 587-594 | `Epidemic:markedPatientsCallForVaccination()` | Generates nurse calls for marked patients |
| 601-621 | `Epidemic:createVaccinationActions(patient, nurse)` | Creates nurse walk + vaccinate actions |
| 628-677 | `Epidemic:getBestVaccinationTile(nurse, patient)` | Finds optimal vaccination position |
| 681-693 | `Epidemic:interruptVaccinationActions(nurse)` | Handles nurse interruption |

### Advisor & Utility
| Line | Method | Description |
|------|--------|-------------|
| 697-715 | `Epidemic:showAppropriateAdviceMessages()` | Hurry up / serious warnings |
| 719-721 | `Epidemic:hasNoInfectedPatients()` | Returns true if no infected patients |
| 723-733 | `Epidemic:tryAnnounceInspector()` | Announces inspector when entering hospital |
| 736-752 | `Epidemic:cancelEpidemic()` | Cheat: cancels epidemic completely |
| 754-762 | `Epidemic:afterLoad(old, new)` | Save/load migration handler |

---

## hospital.lua (2442 lines) - Epidemic Related

### Contagious Detection & Epidemic Management
| Line | Method | Description |
|------|--------|-------------|
| 1090-1101 | `Hospital:cancelEpidemics()` | Cancels active and future epidemics |
| 1106-1128 | `Hospital:determineIfContagious(patient)` | Determines if patient starts epidemic |
| 1135-1162 | `Hospital:addToEpidemic(patient)` | Adds patient to active/future epidemic |
| 1164-1167 | `Hospital:spawnPatient()` | Spawns new patient |
| ~1170+ | `Hospital:countEpidemics()` | Counts active + future epidemics |

### VIP/Epidemic Stubs (Empty Implementations)
| Line | Method | Description |
|------|--------|-------------|
| 2385-2386 | `Hospital:onSpawnVIP()` | VIP spawn hook |
| 2408-2410 | `Hospital:makeNoTreatmentRoomFax(patient)` | No treatment room fax |
| 2408-2410 | `Hospital:makeNoDiagnosisRoomFax(patient)` | No diagnosis room fax |
| 2412-2414 | `Hospital:makeEmergencyStartFax()` | Emergency start fax |
| 2416-2418 | `Hospital:makeEmergencyEndFax(...)` | Emergency end fax |
| 2420-2422 | `Hospital:createVip()` | VIP creation fax |
| 2424-2426 | `Hospital:removeMessage(humanoid)` | Remove fax/message |
| 2428-2430 | `Hospital:makeVipEndFax(...)` | VIP end fax with rating |

---

## Cross-Reference: Key Interactions

### Epidemic → Hospital
| Epidemic Method | Hospital Method/Field |
|-----------------|----------------------|
| `Epidemic:Epidemic()` | `hospital.world`, `hospital:isInHospital()`, `hospital:getReceptionDesks()`, `hospital.patients` |
| `Epidemic:tick()` | `hospital:isInHospital()` |
| `Epidemic:sendInitialFax()` | `hospital:spendMoney()` |
| `Epidemic:resolveDeclaration()` | `hospital:spendMoney()`, `hospital.reputation`, `hospital.epidemic` |
| `Epidemic:startCoverUp()` | `hospital:playSound()` |
| `Epidemic:applyOutcome()` | `hospital:spendMoney()`, `hospital:receiveMoney()`, `hospital.reputation`, `hospital.epidemic` |
| `Epidemic:evacuateHospital()` | `hospital.patients`, `patient:goHome()` |
| `Epidemic:markPatientsAsPassedReception()` | `hospital:getReceptionDesks()`, `hospital.patients`, `hospital:isInHospital()` |

### Hospital → Epidemic
| Hospital Method | Epidemic Method |
|-----------------|-----------------|
| `determineIfContagious()` | `Epidemic()` constructor, `epidemic:addContagiousPatient()` |
| `addToEpidemic()` | `epidemic:addContagiousPatient()`, `Epidemic()` constructor |
| `cancelEpidemics()` | `epidemic:cancelEpidemic()` (implied) |

### Epidemic → World/UI/Dispatcher
| Epidemic Method | External Call |
|-----------------|---------------|
| `Epidemic:Epidemic()` | `world.map.level_config`, `world.entity_map` |
| `Epidemic:tick()` | `world.entity_map:getPatientsInAdjacentSquares()` |
| `Epidemic:announceStartOfEpidemic()` | `world.ui:playAnnouncement()` |
| `Epidemic:sendInitialFax()` | `world.ui.bottom_panel:queueMessage()` |
| `Epidemic:startCoverUp()` | `UIWatch()`, `world.ui:addWindow()`, `world.ui:setCursor()` |
| `Epidemic:markForVaccination()` | `hospital:playSound()` |
| `Epidemic:markedPatientsCallForVaccination()` | `world.dispatcher:callNurseForVaccination()` |
| `Epidemic:createVaccinationActions()` | `world.entity_map:getAdjacentFreeTiles()`, `world:getPathDistance()` |
| `Epidemic:spawnInspector()` | `world.ui.adviser:say()`, `world:newEntity()`, `world.spawn_points` |
| `Epidemic:sendResultFax()` | `world.ui.bottom_panel:queueMessage()` |
| `Epidemic:showAppropriateAdviceMessages()` | `world.ui.adviser:say()` |
| `Epidemic:cancelEpidemic()` | `world.ui.bottom_panel:deleteMessage()` |

### Patient Methods Called by Epidemic
| Patient Method | Called From |
|----------------|-------------|
| `updateDynamicInfo()` | `addContagiousPatient()`, `startCoverUp()` |
| `setInfectedStatus()` | `addContagiousPatient()`, `startCoverUp()` |
| `changeDisease()` | `infect_other()` |
| `setToReadyForVaccinationStatus()` | `markForVaccination()` |
| `giveVaccinationCandidateStatus()` | `createVaccinationActions()` |
| `removeVaccinationCandidateStatus()` | `clearAllInfectedPatients()`, `createVaccinationActions()` |
| `removeAnyEpidemicStatus()` | `clearAllInfectedPatients()` |
| `getRoom()` | `canInfectOther()` |
| `getCurrentAction()` | `is_static()`, `getBestVaccinationTile()` |
| `goHome()` | `evacuateHospital()` |

---

## Configuration Keys Referenced

### Level Config (world.map.level_config.gbv)
| Key | Used In | Default |
|-----|---------|---------|
| `ContagiousSpreadFactor` | `Epidemic:Epidemic()` line 82 | 25 |
| `EpidemicRepLossMinimum` | `Epidemic:Epidemic()` line 85 | 5 |
| `EpidemicEvacMinimum` | `Epidemic:Epidemic()` line 88 | 10 |
| `EpidemicFine` | `calculateInfectedFine()` line 354 | 2000 |
| `EpidemicCompLo` | `determineFaxAndFines()` line 452 | 1000 |
| `EpidemicCompHi` | `determineFaxAndFines()` line 453 | 5000 |
| `VacCost` | `createVaccinationActions()` line 616 | 50 |
| `ReduceContMonths` | `determineIfContagious()` line 1120 | 14 |
| `ReduceContPeepCount` | `determineIfContagious()` line 1121 | 20 |

### Expertise Config (level_config.expertise[disease.expertise_id])
| Key | Used In | Default |
|-----|---------|---------|
| `ContRate` | `determineIfContagious()` line 1114 | 0 |

---

## String Table Keys (_S)

### Initial Fax
| Key | Line |
|-----|------|
| `fax.epidemic.disease_name` | 336 |
| `fax.epidemic.declare_explanation_fine` | 337 |
| `fax.epidemic.cover_up_explanation_1` | 338 |
| `fax.epidemic.cover_up_explanation_2` | 339 |
| `fax.epidemic.choices.declare` | 341 |
| `fax.epidemic.choices.cover_up` | 342 |

### Result Fax - Success
| Key | Line |
|-----|------|
| `fax.epidemic_result.succeeded.part_1_name` | 457 |
| `fax.epidemic_result.succeeded.part_2` | 458 |
| `fax.epidemic_result.compensation_amount` | 459 |

### Result Fax - Failure
| Key | Line |
|-----|------|
| `fax.epidemic_result.failed.part_1_name` | 442, 464, 470, 479 |
| `fax.epidemic_result.failed.part_2` | 443, 465, 471, 480 |
| `fax.epidemic_result.fine_amount` | 466 |
| `fax.epidemic_result.rep_loss_fine_amount` | 473 |
| `fax.epidemic_result.hospital_evacuated` | 481 |
| `fax.epidemic_result.close_text` | 444, 460, 467, 474, 482 |

### Dynamic Info
| Key | Line |
|-----|------|
| `dynamic_info.staff.actions.vaccine` | 617 |

### Transactions
| Key | Line |
|-----|------|
| `transactions.epidemy_fine` | 375 |
| `transactions.epidemy_coverup_fine` | 499 |
| `transactions.compensation` | 502 |

---

## Advisor Keys (_A)

| Key | Line |
|-----|------|
| `information.epidemic_health_inspector` | 552 |
| `epidemic.hurry_up` | 704 |
| `epidemic.serious_warning` | 711 |

---

## Sound Files

| File | Trigger | Line |
|------|---------|------|
| `EPID001.wav` - `EPID004.wav` | Epidemic start | 225 |
| `EPID005.wav` - `EPID008.wav` | Epidemic end | 234 |
| `vaccin.wav` | Mark for vaccination | 312 |

---

## Constants & Magic Numbers

| Value | Location | Purpose |
|-------|----------|---------|
| `spread_scale_factor = 200` | line 173 | Infection rate denominator |
| `timer open_timer` | line 398 | Cover-up duration |
| `countdown_intervals * 1/4` | line 703 | Hurry up threshold (25% remaining) |
| `countdown_intervals * 3/4` | line 709 | Serious warning threshold (75% elapsed) |
| `reputation * 1/3` | line 493 | Evacuation reputation hit |
| `fine / 100` | line 365 | Base reputation from fine |
| `min fine 2000` | line 355 | Minimum fine floor |
| `5 ticks` | VaccinateAction | Vaccination duration |

---

## State Machine: Epidemic Lifecycle

```
NEW (constructor)
    │
    ▼
WAITING_FOR_DIAGNOSIS (ready_to_reveal = false)
    │ checkIfReadyToReveal()
    ▼
REVEALED (revealed = true, sendInitialFax)
    │
    ├─► DECLARE → resolveDeclaration() → END
    │
    └─► COVER_UP → startCoverUp()
                │
                ▼
         COVER_UP_ACTIVE (timer running)
                │
                ├─► All cured → finishCoverUp() → INSPECTOR
                ├─► Patient escapes → finishCoverUp() → INSPECTOR
                ├─► Timer expires → finishCoverUp() → INSPECTOR
                │
                ▼
         INSPECTOR_ARRIVED → handleInspectorArrival()
                │
                ▼
         OUTCOME_DETERMINED → determineFaxAndFines()
                │
                ▼
         OUTCOME_APPLIED → applyOutcome() → END
```

---

## Quick Search Reference

| Feature | Primary File | Line Range |
|---------|--------------|------------|
| Epidemic creation | epidemic.lua | 32-96 |
| Infection spread | epidemic.lua | 125-195 |
| Spread probability | epidemic.lua | 167-193 |
| Cover-up timer | epidemic.lua | 396-408 |
| Vaccination | epidemic.lua | 587-677 |
| Outcomes | epidemic.lua | 439-508 |
| Fine calculation | epidemic.lua | 348-356 |
| Declaration | epidemic.lua | 371-379 |
| Contagious detection | hospital.lua | 1106-1128 |
| Epidemic queue | hospital.lua | 1135-1162 |
| Evacuation | epidemic.lua | 533-541 |
| Inspector | epidemic.lua | 551-561 |
| Save/load | epidemic.lua | 754-762 |


## Related Pages

- [[11-epidemic-system/SUMMARY]]
- [[11-epidemic-system/CHECKLIST]]
- [[11-epidemic-system/SCAFFOLD]]
