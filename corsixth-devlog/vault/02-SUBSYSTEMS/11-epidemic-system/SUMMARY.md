# Epidemic System - Comprehensive Technical Summary

## Overview

The Epidemic System in CorsixTH manages contagious disease outbreaks within hospitals. When a patient with a contagious disease is diagnosed, an epidemic may be triggered, requiring the player to either declare the epidemic (paying an immediate fine) or attempt a cover-up by vaccinating infected patients before a health inspector arrives.

---

## 1. Epidemic Initialization

### Constructor: `Epidemic:Epidemic(hospital, contagious_patient)`

**Location:** `epidemic.lua:32-96`

**Configuration Parameters (from level_config.gbv):**

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ContagiousSpreadFactor` | 25 | Percentage chance of disease transmission per contact |
| `EpidemicRepLossMinimum` | 5 | Minimum infected patients for reputation loss (on cover-up failure) |
| `EpidemicEvacMinimum` | 10 | Minimum infected patients for hospital evacuation |
| `EpidemicFine` | 2000 | Fine per infected patient |
| `EpidemicCompLo` | 1000 | Minimum compensation for successful cover-up |
| `EpidemicCompHi` | 5000 | Maximum compensation for successful cover-up |
| `VacCost` | 50 | Vaccination fee charged per patient |

**Initialization Sequence:**

1. Store hospital and world references
2. Initialize empty `infected_patients` table
3. Extract disease from the initial contagious patient
4. Set `ready_to_reveal = false`, `revealed = false`
5. Initialize financial trackers: `declare_fine`, `reputation_hit`, `coverup_fine`, `compensation`
6. Set `will_be_evacuated = false`, `coverup_selected = false`
7. Initialize timer fields: `timer = nil`, `countdown_intervals = 0`
8. Set `vaccination_mode_active = false`, `cheat_always_show_mood = false`
9. Initialize infection counters: `total_infections = 0`, `attempted_infections = 0`
10. Load configuration values with defaults
11. Call `addContagiousPatient(contagious_patient)`
12. Call `markPatientsAsPassedReception()`

**Code Example:**
```lua
-- Level config example (in level_config.gbv)
gbv = {
    ContagiousSpreadFactor = 25,      -- 25% spread chance
    EpidemicRepLossMinimum = 5,       -- Reputation hit at 5+ infected
    EpidemicEvacMinimum = 10,         -- Evacuation at 10+ infected
    EpidemicFine = 2000,              -- $2000 per infected
    EpidemicCompLo = 1000,            -- Min compensation $1000
    EpidemicCompHi = 5000,            -- Max compensation $5000
    VacCost = 50                      -- $50 per vaccination
}
```

---

## 2. Infection Mechanics

### Core Function: `Epidemic:infectOtherPatients()`

**Location:** `epidemic.lua:125-195`

**Tick Rate:** Called every `Epidemic:tick()` (same rate as hospital tick)

### Infection Eligibility (`canInfectOther`)

**Location:** `epidemic.lua:132-157`

A patient can infect another if ALL conditions are met:

1. **Infector is infectious:** `not infector.cured and not infector.vaccinated`
2. **Both in hospital bounds:** `hospital:isInHospital(tile_x, tile_y)` for both
3. **Victim not already infected:** `not victim.infected and not victim.cured and not victim.vaccinated`
4. **Victim not under infection attempt:** `not victim.under_infection_attempt`
5. **Victim not emergency:** `not victim.is_emergency`
6. **Disease compatibility:**
   - Same disease: `infector.disease == victim.disease`, OR
   - Victim's disease is contagious AND not diagnosed: `victim.disease.contagious and not victim.diagnosed`
7. **Same room:** `infector:getRoom() == victim:getRoom()`

### Spread Chance Formula

**Location:** `epidemic.lua:167-193`

```lua
local spread_scale_factor = 200  -- Balance constant (must be > 0)

-- Infection occurs if:
(self.total_infections / self.attempted_infections) < (self.spread_factor / spread_scale_factor)
```

**With defaults (spread_factor=25, spread_scale_factor=200):**
- Target infection rate = 25/200 = **12.5%** of attempts succeed
- Actual rate dynamically adjusts based on historical success ratio

### Adjacent Patient Detection

**Location:** `epidemic.lua:179-192`

```lua
local adjacent_patients = entity_map:getPatientsInAdjacentSquares(infector.tile_x, infector.tile_y)
```

Checks 4 orthogonal adjacent tiles (N, S, E, W) for patients.

### Infection Execution (`infect_other`)

**Location:** `epidemic.lua:159-165`

1. If diseases differ, change victim's disease: `victim:changeDisease(infector.disease)`
2. Add victim to epidemic: `self:addContagiousPatient(victim)`
3. Increment `total_infections`

---

## 3. Cover-Up Flow

### Trigger: `Epidemic:startCoverUp()`

**Location:** `epidemic.lua:396-408`

**Sequence:**
1. Create `UIWatch` timer: `self.timer = UIWatch(self.world.ui, "epidemic")`
2. Store `countdown_intervals = self.timer.open_timer`
3. Add timer to UI: `self.world.ui:addWindow(self.timer)`
4. Clean up patients: `self:checkPatientsForRemoval()`
5. Set `coverup_selected = true`
6. Update all infected patients: `updateDynamicInfo()` + `setInfectedStatus()`

### Timer Component: `UIWatch`

The timer provides:
- Visual countdown display
- Clickable vaccination mode toggle button
- `open_timer` property tracking remaining intervals

### Vaccination Mode Toggle

**Location:** `epidemic.lua:287-302`

```lua
function Epidemic:toggleVaccinationMode()
    self.vaccination_mode_active = not self.vaccination_mode_active
    self:_updateVaccinationCursor()
end

function Epidemic:_updateVaccinationCursor()
    local cursor = self.vaccination_mode_active and "epidemic_hover" or "default"
    self.world.ui:setCursor(self.world.ui.app.gfx:loadMainCursor(cursor))
end
```

### Marking Patients for Vaccination

**Location:** `epidemic.lua:308-314`

```lua
function Epidemic:markForVaccination(patient)
    if patient.infected and not patient.vaccinated and not patient.marked_for_vaccination then
        patient:setToReadyForVaccinationStatus()
        patient.hospital:playSound("vaccin.wav")
    end
end
```

**Requirements:**
- Patient must be infected
- Not already vaccinated
- Not already marked
- Can only happen during cover-up (`coverup_selected == true`)

### Vaccination Call Generation

**Location:** `epidemic.lua:587-594`

Called every tick during active cover-up:

```lua
function Epidemic:markedPatientsCallForVaccination()
    for _, infected_patient in ipairs(self.infected_patients) do
        if infected_patient.marked_for_vaccination and
            not infected_patient.reserved_for and is_static(infected_patient) then
            self.world.dispatcher:callNurseForVaccination(infected_patient)
        end
    end
end
```

**Static Patient Check (`is_static`):**
```lua
local function is_static(patient)
    local action = patient:getCurrentAction()
    return action.name == "queue" or action.name == "idle" or action.name == "seek_room" or
        (action.name == "use_object" and action.object.object_type.id == "bench")
end
```

### Vaccination Execution

**Location:** `epidemic.lua:601-621`

```lua
function Epidemic:createVaccinationActions(patient, nurse)
    patient.reserved_for = nurse
    local x, y = self:getBestVaccinationTile(nurse, patient)
    
    if not x or not y then
        -- Unreachable - keep call open
        nurse:setCallCompleted()
        patient.reserved_for = nil
        nurse:setNextAction(MeanderAction())
        patient:removeVaccinationCandidateStatus()
    else
        patient:giveVaccinationCandidateStatus()
        local fee = level_config.gbv.VacCost or 50
        nurse:setDynamicInfoText(_S.dynamic_info.staff.actions.vaccine)
        nurse:setNextAction(WalkAction(x, y):setMustHappen(true):enableWalkingToVaccinate())
        nurse:queueAction(VaccinateAction(patient, fee))
    end
end
```

**Vaccination Duration:** 5 ticks (hardcoded in `VaccinateAction`)

### Best Vaccination Tile Calculation

**Location:** `epidemic.lua:628-677`

1. **Bench patients:** Tile directly in front of bench based on direction
2. **General case:** Find closest reachable adjacent free tile to patient from nurse's position

---

## 4. Cover-Up Termination

### Early Termination Conditions

**Location:** `epidemic.lua:243-268`

1. **Infected patient leaves hospital:** `checkInfectedLeftHospital()` - if uncured infected patient exits
2. **No infected patients remain:** `checkNoInfectedPatients()` - `countInfectedPatients() == 0`
3. **Timer expires:** `coverUpTimeIsUp()` → `finishCoverUp()`

### Inspector Arrival

**Location:** `epidemic.lua:551-561`

```lua
function Epidemic:spawnInspector()
    self.world.ui.adviser:say(_A.information.epidemic_health_inspector)
    local inspector = self.world:newEntity("Inspector", 2, 2)
    self.inspector = inspector
    inspector:setType("Inspector")
    local spawn_point = self.world.spawn_points[math.random(1, #self.world.spawn_points)]
    inspector:setNextAction(SpawnAction("spawn", spawn_point))
    inspector:setHospital(self.hospital)
    inspector:queueAction(SeekReceptionAction())
end
```

### Inspector Arrival Handler

**Location:** `epidemic.lua:424-429`

```lua
function Epidemic:handleInspectorArrival()
    local still_infected = self:countInfectedPatients()
    self:determineFaxAndFines(still_infected)
    self:clearAllInfectedPatients()
    self:applyOutcome()
end
```

---

## 5. Outcomes & Fine Calculation

### Outcome Determination

**Location:** `epidemic.lua:439-485`

```lua
function Epidemic:determineFaxAndFines(still_infected)
    self.coverup_fine = self:calculateInfectedFine(still_infected)
    
    if still_infected == 0 then
        -- SUCCESS: Full cover-up
        self.compensation = math.random(EpidemicCompLo, EpidemicCompHi)
        -- Fax: Success + compensation amount
    elseif still_infected < self.reputation_loss_minimum and still_infected < self.evacuation_minimum then
        -- PARTIAL: Fine only (default: < 5 infected)
        -- Fax: Failed + fine amount
    elseif still_infected >= self.reputation_loss_minimum and still_infected < self.evacuation_minimum then
        -- PARTIAL: Fine + reputation hit (default: 5-9 infected)
        -- Fax: Failed + rep loss + fine amount
    else
        -- FAILURE: Evacuation (default: 10+ infected)
        self.will_be_evacuated = true
        -- Fax: Failed + hospital evacuated
    end
end
```

### Outcome Application

**Location:** `epidemic.lua:489-508`

```lua
function Epidemic:applyOutcome()
    if self.compensation == 0 then
        -- FAILED cover-up
        if self.will_be_evacuated then
            self.reputation_hit = math.round(self.hospital.reputation * (1/3))
            self:evacuateHospital()
        else
            self.reputation_hit = getBaseReputationFromFine(self.coverup_fine)
        end
        self.hospital:spendMoney(self.coverup_fine, _S.transactions.epidemy_coverup_fine)
        self.hospital.reputation = self.hospital.reputation - self.reputation_hit
    else
        -- SUCCESSFUL cover-up
        self.hospital:receiveMoney(self.compensation, _S.transactions.compensation)
    end
    self:sendResultFax()
    self.hospital.epidemic = nil
end
```

### Fine Calculation

**Location:** `epidemic.lua:352-356`

```lua
function Epidemic:calculateInfectedFine(infected_count)
    local level_config = self.world.map.level_config
    local fine_per_infected = level_config.gbv.EpidemicFine or 2000
    return math.max(2000, infected_count * fine_per_infected)
end
```

**Formula:** `max(2000, infected_count * EpidemicFine)`

**With default (EpidemicFine=2000):**
- 1 infected: $2,000
- 5 infected: $10,000
- 10 infected: $20,000

### Reputation Calculation

**Location:** `epidemic.lua:364-366`

```lua
local function getBaseReputationFromFine(fine_amount)
    return math.round(fine_amount / 100)
end
```

**Formula:** `reputation_hit = round(fine / 100)`

**Evacuation reputation hit:** `round(hospital.reputation * 1/3)`

---

## 6. Declaration Path (Alternative to Cover-Up)

**Location:** `epidemic.lua:371-379`

```lua
function Epidemic:resolveDeclaration()
    self:clearAllInfectedPatients()
    self.hospital:spendMoney(self.declare_fine, _S.transactions.epidemy_fine)
    local reputation_hit = getBaseReputationFromFine(self.declare_fine)
    self.hospital.reputation = self.hospital.reputation - reputation_hit
    self.hospital.epidemic = nil
end
```

- Immediate fine based on initial infected count
- Reputation hit proportional to fine
- No cover-up timer, no vaccination needed
- Epidemic ends immediately

---

## 7. Epidemic Queue System

**Location:** `hospital.lua:1135-1162`

```lua
function Hospital:addToEpidemic(patient)
    local epidemic = self.epidemic
    
    -- Add to active epidemic if same disease and not covering up
    if epidemic and not epidemic.coverup_selected and (patient.disease == epidemic.disease) then
        epidemic:addContagiousPatient(patient)
    elseif self.future_epidemics_pool and not (epidemic and epidemic.coverup_selected) then
        -- Try to add to future epidemic pool
        for _, future_epidemic in ipairs(self.future_epidemics_pool) do
            if future_epidemic.disease == patient.disease then
                future_epidemic:addContagiousPatient(patient)
                added = true
                break
            end
        end
        
        -- Create new epidemic if under concurrent limit
        if not added and self:countEpidemics() < self.concurrent_epidemic_limit then
            local new_epidemic = Epidemic(self, patient)
            self.future_epidemics_pool[#self.future_epidemics_pool + 1] = new_epidemic
        end
    end
end
```

---

## 8. Contagious Patient Detection

**Location:** `hospital.lua:1106-1128`

```lua
function Hospital:determineIfContagious(patient)
    if self.epidemics_disabled or patient.is_emergency or not patient.disease.contagious then
        return false
    end
    
    local level_config = self.world.map.level_config
    local disease = patient.disease
    local contRate = level_config.expertise[disease.expertise_id].ContRate or 0
    
    local potentially_contagious = contRate > 0 and (math.random(1, contRate) == contRate)
    
    local reduce_months = level_config.ReduceContMonths or 14
    local reduce_people = level_config.ReduceContPeepCount or 20
    local date_in_months = self.world:date():monthOfGame()
    
    if potentially_contagious and date_in_months > reduce_months and
        self.num_visitors > reduce_people then
        self:addToEpidemic(patient)
    end
end
```

**Contagion Chance:** `1 / ContRate` (e.g., ContRate=10 → 10% chance)

**Late-game reduction:** Only triggers after `ReduceContMonths` (default 14 months) AND `num_visitors > ReduceContPeepCount` (default 20)

---

## 9. Key Data Structures

### Epidemic Class Fields

| Field | Type | Description |
|-------|------|-------------|
| `hospital` | Hospital | Parent hospital |
| `world` | World | Game world reference |
| `infected_patients` | Patient[] | Array of infected patients |
| `disease` | Disease | The contagious disease type |
| `ready_to_reveal` | boolean | Diagnosed patient exists |
| `revealed` | boolean | Epidemic shown to player |
| `declare_fine` | number | Fine if declared immediately |
| `reputation_hit` | number | Reputation loss amount |
| `coverup_fine` | number | Fine if cover-up fails |
| `compensation` | number | Reward if cover-up succeeds (0 = failed) |
| `will_be_evacuated` | boolean | Hospital evacuation flag |
| `coverup_selected` | boolean | Player chose cover-up |
| `timer` | UIWatch | Cover-up countdown timer |
| `countdown_intervals` | number | Total timer intervals |
| `vaccination_mode_active` | boolean | Vaccination cursor mode |
| `cheat_always_show_mood` | boolean | Debug: show icons early |
| `total_infections` | number | Successful infections count |
| `attempted_infections` | number | Total infection attempts |
| `spread_factor` | number | Config: spread percentage |
| `reputation_loss_minimum` | number | Config: rep loss threshold |
| `evacuation_minimum` | number | Config: evacuation threshold |
| `inspector` | Inspector | Health inspector entity |
| `cover_up_result_fax` | table | Result fax data |
| `has_said_hurry_up` | boolean | Advisor message flag |
| `has_said_serious` | boolean | Advisor message flag |

### Patient Epidemic Flags

| Flag | Description |
|------|-------------|
| `infected` | Patient has the epidemic disease |
| `cured` | Patient cured of disease |
| `vaccinated` | Patient vaccinated |
| `marked_for_vaccination` | Player clicked for vaccination |
| `vaccination_candidate` | Nurse assigned, awaiting vaccination |
| `reserved_for` | Nurse reserved for this patient |
| `under_infection_attempt` | Currently being evaluated for infection |
| `has_passed_reception` | Past reception (for evacuation) |

---

## 10. Configuration Reference

### Level Config (gbv table)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `ContagiousSpreadFactor` | int | 25 | Spread probability numerator |
| `EpidemicRepLossMinimum` | int | 5 | Infected count for rep loss |
| `EpidemicEvacMinimum` | int | 10 | Infected count for evacuation |
| `EpidemicFine` | int | 2000 | Fine per infected patient |
| `EpidemicCompLo` | int | 1000 | Min compensation |
| `EpidemicCompHi` | int | 5000 | Max compensation |
| `VacCost` | int | 50 | Vaccination fee |
| `ReduceContMonths` | int | 14 | Months before contagion reduces |
| `ReduceContPeepCount` | int | 20 | Visitor threshold for contagion |

### Expertise Config (per disease)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `ContRate` | int | 0 | 1 in N chance of contagious strain |

---

## 11. Message/Fax String Keys

### Initial Epidemic Fax
- `fax.epidemic.disease_name`
- `fax.epidemic.declare_explanation_fine`
- `fax.epidemic.cover_up_explanation_1`
- `fax.epidemic.cover_up_explanation_2`
- `fax.epidemic.choices.declare`
- `fax.epidemic.choices.cover_up`

### Result Fax (Success)
- `fax.epidemic_result.succeeded.part_1_name`
- `fax.epidemic_result.succeeded.part_2`
- `fax.epidemic_result.compensation_amount`

### Result Fax (Failure - Fine Only)
- `fax.epidemic_result.failed.part_1_name`
- `fax.epidemic_result.failed.part_2`
- `fax.epidemic_result.fine_amount`

### Result Fax (Failure - Fine + Rep)
- `fax.epidemic_result.failed.part_1_name`
- `fax.epidemic_result.failed.part_2`
- `fax.epidemic_result.rep_loss_fine_amount`

### Result Fax (Evacuation)
- `fax.epidemic_result.failed.part_1_name`
- `fax.epidemic_result.failed.part_2`
- `fax.epidemic_result.hospital_evacuated`

### Common
- `fax.epidemic_result.close_text`

---

## 12. Announcement Sounds

### Epidemic Start
- `EPID001.wav` - `EPID004.wav` (random)

### Epidemic End
- `EPID005.wav` - `EPID008.wav` (random)

### Vaccination
- `vaccin.wav` (played when marking patient)

---

## 13. Advisor Messages

- `_A.information.epidemic_health_inspector` - Inspector arriving
- `_A.epidemic.hurry_up` - Timer at 25% remaining with infected patients
- `_A.epidemic.serious_warning` - Timer at 75% elapsed with >10 infected

---

## 14. Transaction Types

- `transactions.epidemy_fine` - Declaration fine
- `transactions.epidemy_coverup_fine` - Cover-up failure fine
- `transactions.compensation` - Successful cover-up payment

---

## 15. Complete Flow Diagram

```
Patient diagnosed with contagious disease
         │
         ▼
Hospital:determineIfContagious() ──► 1/ContRate chance
         │                              │
         ▼                              ▼
   Not contagious              Hospital:addToEpidemic()
         │                              │
         │                     ┌──────────┴──────────┐
         │                     ▼                     ▼
         │            Active epidemic?          Future epidemic pool?
         │                     │                     │
         │                Same disease?         Same disease exists?
         │                     │                     │
         │                    Yes                   Yes
         │                     │                     │
         │                     ▼                     ▼
         │            Add to active           Add to future
         │            epidemic                epidemic
         │                     │                     │
         │                     └──────────┬──────────┘
         │                                ▼
         │                     Under concurrent limit?
         │                                │
         │                               Yes
         │                                │
         ▼                                ▼
    End                          Create new Epidemic()
                                  (added to future_epidemics_pool)
                                        │
                                        ▼
                              Epidemic becomes "active"
                                        │
                                        ▼
                              Epidemic:revealEpidemic()
                                        │
                                        ▼
                              Initial Fax: Declare vs Cover-up
                                        │
                    ┌───────────────────┴───────────────────┐
                    ▼                                       ▼
             DECLARE                                     COVER-UP
                    │                                       │
                    ▼                                       ▼
        Epidemic:resolveDeclaration()            Epidemic:startCoverUp()
        - Fine = declare_fine                    - UIWatch timer starts
        - Reputation hit                         - Vaccination mode available
        - Epidemic ends                          - Mark patients for vaccination
                                                 - Nurse vaccination calls
                                                 - Timer counts down
                                                      │
                              ┌───────────────────────┼───────────────────────┐
                              ▼                       ▼                       ▼
                       Timer expires           Infected leaves           All cured
                              │                       │                       │
                              ▼                       ▼                       ▼
                       Inspector arrives       Inspector arrives       Inspector arrives
                              │                       │                       │
                              └───────────────────────┼───────────────────────┘
                                                      ▼
                                           Epidemic:handleInspectorArrival()
                                                      │
                                                      ▼
                                           Epidemic:determineFaxAndFines()
                                                      │
                              ┌───────────────────────┼───────────────────────┐
                              ▼                       ▼                       ▼
                         0 infected             <5 infected              5-9 infected
                         (Success)              (Fine only)              (Fine + Rep)
                              │                       │                       │
                              ▼                       ▼                       ▼
                    Compensation $1000-5000    Fine = count * $2000     Fine + Rep = fine/100
                              │                       │                       │
                              └───────────────────────┼───────────────────────┘
                                                      ▼
                                           Epidemic:applyOutcome()
                                                      │
                              ┌───────────────────────┼───────────────────────┐
                              ▼                       ▼                       ▼
                       Receive money           Spend fine +             Spend fine + Rep hit +
                       (compensation)          rep hit                  Evacuate hospital
                              │                       │                       │
                              └───────────────────────┼───────────────────────┘
                                                      ▼
                                           Send result fax
                                           Announce end
                                           Clear epidemic
