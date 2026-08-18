# CorsixTH Epidemic System - Deep Research Summary

## Overview

The epidemic system in CorsixTH manages contagious disease outbreaks in hospitals. It handles everything from initial infection detection through spread mechanics, player response options (declare vs. cover-up), vaccination procedures, and final outcomes with fines, reputation changes, or hospital evacuation.

**Key Files:**
- `/tmp/CorsixTH/CorsixTH/Lua/epidemic.lua` (762 lines) - Main epidemic logic
- `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:1106` - `determineIfContagious()` patient entry point
- `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:2385-2430` - VIP/epidemic stub methods
- `/tmp/CorsixTH/CorsixTH/Lua/dialogs/watch.lua` - UIWatch timer for cover-up countdown
- `/tmp/CorsixTH/CorsixTH/Lua/calls_dispatcher.lua` - Nurse vaccination dispatch
- `/tmp/CorsixTH/CorsixTH/Lua/humanoid_actions/vaccinate.lua` - Vaccination action execution
- `/tmp/CorsixTH/CorsixTH/Lua/entities/humanoids/patient.lua` - Patient epidemic status handling
- `/tmp/CorsixTH/CorsixTH/Lua/entities/humanoids/inspector.lua` - Health inspector entity

---

## 1. Epidemic Initialization

### 1.1 Configuration Parameters (base_config.lua:80-110)

```lua
ContagiousSpreadFactor      = 25,    -- % chance disease spreads per contact attempt
EpidemicFine                = 2000,  -- Base fine per infected patient (max 20,000)
EpidemicCompLo              = 1000,  -- Compensation low bound (successful cover-up)
EpidemicCompHi              = 15000, -- Compensation high bound (successful cover-up)
EpidemicRepLossMinimum      = 5,     -- Infected count triggering reputation loss
EpidemicEvacMinimum         = 10,    -- Infected count triggering hospital evacuation
EpidemicConcurrentLimit     = 1,     -- Max simultaneous epidemics (active + queued)
ReduceContMonths            = 14,    -- Months before contagious patients can appear
ReduceContPeepCount         = 20,    -- Visitor count before contagious patients can appear
VacCost                     = 50,    -- Vaccination fee per patient
```

### 1.2 Epidemic Constructor (epidemic.lua:32-96)

```lua
function Epidemic:Epidemic(hospital, contagious_patient)
  self.hospital = hospital
  self.world = self.hospital.world
  self.infected_patients = {}
  self.disease = contagious_patient.disease
  self.ready_to_reveal = false
  self.revealed = false
  self.declare_fine = 0
  self.reputation_hit = 0
  self.coverup_fine = 0
  self.compensation = 0
  self.will_be_evacuated = false
  self.cover_up_result_fax = {}
  self.coverup_selected = false
  self.timer = nil
  self.countdown_intervals = 0
  self.vaccination_mode_active = false
  self.cheat_always_show_mood = false
  self.total_infections = 0
  self.attempted_infections = 0

  -- Load from level config (with defaults)
  local level_config = self.world.map.level_config
  self.spread_factor = level_config.gbv.ContagiousSpreadFactor or 25
  self.reputation_loss_minimum = level_config.gbv.EpidemicRepLossMinimum or 5
  self.evacuation_minimum = level_config.gbv.EpidemicEvacMinimum or 10

  self.inspector = nil
  self:addContagiousPatient(contagious_patient)
  self:markPatientsAsPassedReception()
end
```

**Initialization Flow:**
1. Contagious patient detected via `Hospital:determineIfContagious()` (hospital.lua:1106)
2. Patient added to active epidemic or `future_epidemics_pool` via `Hospital:addToEpidemic()` (hospital.lua:1135)
3. `Epidemic` object created with first contagious patient
4. All existing patients in hospital marked as `has_passed_reception = true` for evacuation tracking

### 1.3 Contagious Patient Detection (hospital.lua:1106-1128)

```lua
function Hospital:determineIfContagious(patient)
  if self.epidemics_disabled or patient.is_emergency or not patient.disease.contagious then
    return false
  end

  local level_config = self.world.map.level_config
  local disease = patient.disease
  local contRate = level_config.expertise[disease.expertise_id].ContRate or 0

  -- 1 in contRate chance to be contagious (e.g., ContRate=4 → 25% chance)
  local potentially_contagious = contRate > 0 and (math.random(1, contRate) == contRate)

  -- Only after game progression thresholds
  local reduce_months = level_config.ReduceContMonths or 14
  local reduce_people = level_config.ReduceContPeepCount or 20
  local date_in_months = self.world:date():monthOfGame()

  if potentially_contagious and date_in_months > reduce_months and
      self.num_visitors > reduce_people then
    self:addToEpidemic(patient)
  end
end
```

**Key Points:**
- `ContRate` is per-disease (defined in expertise table)
- Contagious patients only appear after month 14 AND 20+ visitors
- Emergency patients are never contagious
- Disabled entirely if `epidemics_disabled = true`

### 1.4 Epidemic Pool Management (hospital.lua:1050-1077)

```lua
function Hospital:manageEpidemics()
  local function can_be_revealed(epidemic)
    return not self.world.ui:getWindow(UIWatch) and
           not self.epidemic and epidemic.ready_to_reveal
  end

  local current_epidemic = self.epidemic
  if current_epidemic then
    current_epidemic:tick()
  end

  if self.future_epidemics_pool then
    for i, future_epidemic in ipairs(self.future_epidemics_pool) do
      if future_epidemic:hasNoInfectedPatients() then
        table.remove(self.future_epidemics_pool, i)  -- Clean up empty epidemics
      elseif can_be_revealed(future_epidemic) then
        self.epidemic = future_epidemic
        self.epidemic:revealEpidemic()  -- Becomes active, sends initial fax
        table.remove(self.future_epidemics_pool, i)
      else
        future_epidemic:tick()  -- Background spread continues
      end
    end
  end
end
```

**Concurrency Limit:** `EpidemicConcurrentLimit = 1` (base_config.lua:110) - only one active + queued epidemic total.

---

## 2. Infection Mechanics

### 2.1 Tick Processing (epidemic.lua:100-109)

```lua
function Epidemic:tick()
  self:infectOtherPatients()
  self:checkIfReadyToReveal()
  self:showAppropriateAdviceMessages()
  self:tryAnnounceInspector()
  self:markedPatientsCallForVaccination()
  self:checkInfectedLeftHospital()
  self:checkNoInfectedPatients()
  self:checkPatientsForRemoval()
end
```

### 2.2 Spread Algorithm (epidemic.lua:125-195)

```lua
function Epidemic:infectOtherPatients()
  local function canInfectOther(infector, victim)
    -- Infector must be actively infectious
    if infector.cured or infector.vaccinated then return false end

    -- Both patients must be inside hospital bounds
    local ppx, ppy = infector.tile_x, infector.tile_y
    if ppx and ppy and not self.hospital:isInHospital(ppx, ppy) then return false end
    local opx, opy = victim.tile_x, victim.tile_y
    if opx and opy and not self.hospital:isInHospital(opx, opy) then return false end

    -- Victim eligibility
    if victim.infected or victim.cured or victim.vaccinated then return false end
    if victim.under_infection_attempt then return false end
    if victim.is_emergency then return false end

    -- Disease compatibility
    if infector.disease ~= victim.disease and
        (not victim.disease.contagious or victim.diagnosed) then return false end

    -- Must be in same room (no infection through walls)
    return infector:getRoom() == victim:getRoom()
  end

  local function infect_other(infector, victim)
    if infector.disease ~= victim.disease then
      victim:changeDisease(infector.disease)
    end
    self:addContagiousPatient(victim)
    self.total_infections = self.total_infections + 1
  end

  -- BALANCE: spread_scale_factor = 200 reduces effective spread rate
  local spread_scale_factor = 200

  local entity_map = self.world.entity_map
  if entity_map then
    for _, infector in ipairs(self.infected_patients) do
      local adjacent_patients = entity_map:getPatientsInAdjacentSquares(
        infector.tile_x, infector.tile_y
      )
      for _, potential_victim in ipairs(adjacent_patients) do
        if canInfectOther(infector, potential_victim) then
          potential_victim.under_infection_attempt = true
          self.attempted_infections = self.attempted_infections + 1

          -- Infection probability formula:
          -- (successful / attempted) < (spread_factor / spread_scale_factor)
          -- With defaults: (total_infections / attempted_infections) < 25/200 = 0.125
          if (self.total_infections / self.attempted_infections) <
              (self.spread_factor / spread_scale_factor) then
            infect_other(infector, potential_victim)
          end
        end
      end
    end
  end
end
```

### 2.3 Infection Probability Analysis

| Parameter | Default Value | Effective Rate |
|-----------|--------------|----------------|
| `spread_factor` | 25 | Base spread % |
| `spread_scale_factor` | 200 | Balance divisor |
| **Effective probability** | | **12.5% per adjacent contact attempt** |

The formula `(total_infections / attempted_infections) < (spread_factor / spread_scale_factor)` creates a **dynamic probability** that self-regulates:
- Early epidemic: few attempts, high success rate → rapid initial spread
- Later epidemic: many attempts, success rate approaches 12.5% → natural slowdown

**Infection Constraints:**
- Only adjacent tiles (4-directional)
- Same room only (no wall penetration)
- Victim must not be: already infected, cured, vaccinated, emergency, diagnosed with different non-contagious disease
- Infector must not be cured or vaccinated

### 2.4 Ready to Reveal (epidemic.lua:202-211)

```lua
function Epidemic:checkIfReadyToReveal()
  if self.ready_to_reveal then return end
  for _, infected_patient in ipairs(self.infected_patients) do
    if infected_patient.diagnosed then
      self.ready_to_reveal = true
      break
    end
  end
end
```

Epidemic becomes revealable when **any infected patient is fully diagnosed**. This triggers the initial fax offering "Declare" vs "Cover Up" choices.

---

## 3. Cover-Up Flow

### 3.1 Initial Fax & Player Choice (epidemic.lua:330-346)

```lua
function Epidemic:sendInitialFax()
  local num_infected = self:countInfectedPatients()
  self.declare_fine = self:calculateInfectedFine(num_infected)

  local message = {
    {text = _S.fax.epidemic.disease_name:format(self.disease.name)},
    {text = _S.fax.epidemic.declare_explanation_fine:format(self.declare_fine)},
    {text = _S.fax.epidemic.cover_up_explanation_1},
    {text = _S.fax.epidemic.cover_up_explanation_2},
    choices = {
      {text = _S.fax.epidemic.choices.declare, choice = "declare_epidemic"},
      {text = _S.fax.epidemic.choices.cover_up, choice = "cover_up_epidemic"},
    },
  }
  self.world.ui.bottom_panel:queueMessage("epidemy", message, self, 24*20, 2)
end
```

### 3.2 Declaration Path (epidemic.lua:371-379)

```lua
function Epidemic:resolveDeclaration()
  self:clearAllInfectedPatients()  -- Vaccinate all, remove from hospital
  self.hospital:spendMoney(self.declare_fine, _S.transactions.epidemy_fine)
  local reputation_hit = getBaseReputationFromFine(self.declare_fine)
  self.hospital.reputation = self.hospital.reputation - reputation_hit
  self.hospital.epidemic = nil
end
```

**Result:** Immediate fine + reputation hit, epidemic ends instantly.

### 3.3 Cover-Up Path - Timer Start (epidemic.lua:396-408)

```lua
function Epidemic:startCoverUp()
  self.timer = UIWatch(self.world.ui, "epidemic")  -- Creates 13-segment timer
  self.countdown_intervals = self.timer.open_timer  -- 12 intervals
  self.world.ui:addWindow(self.timer)
  self:checkPatientsForRemoval()
  self.coverup_selected = true

  -- Show infected mood icons on all patients
  for _, infected_patient in ipairs(self.infected_patients) do
    infected_patient:updateDynamicInfo()
    infected_patient:setInfectedStatus()  -- Shows epidemy4 mood icon
  end
end
```

### 3.4 UIWatch Timer Mechanics (watch.lua:28-154)

```lua
local TICK_DAYS = 100          -- Total timer duration: 100 game days
local TIMER_SEGMENTS = 13      -- Visual segments
local tick_rate = floor((100 * 24) / 13) = 184 ticks per segment (~7.7 days)

function UIWatch:onWorldTick()
  if self.tick_timer == 0 and self.open_timer >= 0 then
    self.tick_timer = self.tick_rate
    self.open_timer = self.open_timer - 1  -- 12 → 11 → ... → 0 → -1
    -- Visual updates at each segment
  elseif self.open_timer == -1 then
    self:onCountdownEnd()  -- Timer expired
  else
    self.tick_timer = self.tick_timer - 1
  end
end

function UIWatch:onCountdownEnd()
  if self.count_type == "epidemic" then
    local epidemic = self.hospital.epidemic
    if epidemic then
      epidemic:coverUpTimeIsUp()  -- Triggers finishCoverUp()
    end
  end
end
```

**Timer Duration:** ~100 game days (13 segments × ~7.7 days each)

### 3.5 Vaccination Mode (epidemic.lua:284-302, watch.lua:158-162)

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

**UIWatch Button:** Clicking the timer's vaccination button toggles mode (watch.lua:71-73, 158-162).

### 3.6 Marking Patients for Vaccination (epidemic.lua:304-314, patient.lua:1198-1216)

```lua
function Epidemic:markForVaccination(patient)
  if patient.infected and not patient.vaccinated and
      not patient.marked_for_vaccination then
    patient:setToReadyForVaccinationStatus()  -- Sets epidemy2 mood
    patient.hospital:playSound("vaccin.wav")
  end
end

-- Patient.lua status methods:
function Patient:setToReadyForVaccinationStatus()
  self:removeAnyEpidemicStatus()
  self:setMood("epidemy2", "activate")  -- Yellow cross icon
  self.marked_for_vaccination = true
end

function Patient:giveVaccinationCandidateStatus()
  self:removeAnyEpidemicStatus()
  self:setMood("epidemy3", "activate")  -- Green cross icon (nurse assigned)
  self.vaccination_candidate = true
end

function Patient:setVaccinatedStatus()
  self:removeAnyEpidemicStatus()
  self:setMood("epidemy1", "activate")  -- Green checkmark icon
  self.marked_for_vaccination = false
  self.vaccinated = true
end
```

**Mood Icons:**
- `epidemy4` = Infected (red cross) - shown when cover-up starts
- `epidemy2` = Marked for vaccination (yellow cross) - player clicked patient
- `epidemy3` = Vaccination candidate (green cross) - nurse assigned
- `epidemy1` = Vaccinated (green checkmark) - vaccination complete

### 3.7 Vaccination Dispatch (epidemic.lua:587-593, calls_dispatcher.lua:151-251)

```lua
function Epidemic:markedPatientsCallForVaccination()
  for _, infected_patient in ipairs(self.infected_patients) do
    if infected_patient.marked_for_vaccination and
        not infected_patient.reserved_for and is_static(infected_patient) then
      self.world.dispatcher:callNurseForVaccination(infected_patient)
    end
  end
end

-- Static check: patient must be queuing, idle, seeking room, or sitting on bench
local function is_static(patient)
  local action = patient:getCurrentAction()
  return action.name == "queue" or action.name == "idle" or action.name == "seek_room" or
      (action.name == "use_object" and action.object.object_type.id == "bench")
end
```

**Dispatcher Verification (calls_dispatcher.lua:184-205):**
```lua
function CallsDispatcher.verifyStaffForVaccination(patient, staff)
  if not class.is(staff, Nurse) or not staff:isIdle() or
      staff:getRoom() or patient:getRoom() then
    return false
  end
  -- Must be within 5 tiles (Manhattan distance)
  local x_diff = math.abs(patient.tile_x - staff.tile_x)
  local y_diff = math.abs(patient.tile_y - staff.tile_y)
  return x_diff <= 5 and y_diff <= 5
end
```

### 3.8 Vaccination Execution (epidemic.lua:601-621, vaccinate.lua)

```lua
function Epidemic:createVaccinationActions(patient, nurse)
  patient.reserved_for = nurse
  local x, y = self:getBestVaccinationTile(nurse, patient)
  if not x or not y then
    -- Unreachable - drop call
    nurse:setCallCompleted()
    patient.reserved_for = nil
    nurse:setNextAction(MeanderAction())
    patient:removeVaccinationCandidateStatus()
  else
    patient:giveVaccinationCandidateStatus()  -- epidemy3 mood
    local level_config = self.world.map.level_config
    local fee = level_config.gbv.VacCost or 50
    nurse:setDynamicInfoText(_S.dynamic_info.staff.actions.vaccine)
    nurse:setNextAction(WalkAction(x, y):setMustHappen(true):enableWalkingToVaccinate())
    nurse:queueAction(VaccinateAction(patient, fee))
  end
end
```

**VaccinateAction (vaccinate.lua:85-119):**
```lua
local function vaccinate(action, nurse)
  local patient = action.patient
  local perform_vaccination = function()
    if is_in_adjacent_square(nurse, patient) then
      CallsDispatcher.queueCallCheckpointAction(nurse)
      nurse:queueAction(AnswerCallAction())
      patient:setVaccinatedStatus()  -- epidemy1 mood
      patient.hospital:spendMoney(action.vaccination_fee, _S.transactions.vaccination)
      patient:updateDynamicInfo()
    else
      patient:removeVaccinationCandidateStatus()
      -- ... cleanup
    end
  end

  if is_in_adjacent_square(nurse, patient) then
    local face_direction = find_face_direction(nurse, patient)
    nurse:queueAction(IdleAction():setDirection(face_direction):setCount(5)
        :setAfterUse(perform_vaccination):setOnInterrupt(interrupt_vaccination):setMustHappen(true))
  else
    -- ... cleanup
  end
  nurse:finishAction()
end
```

**Vaccination Process:**
1. Nurse walks to adjacent tile (5-tile radius)
2. Nurse idles for **5 ticks** facing patient
3. Patient marked vaccinated, fee charged (default 50)
4. Patient receives `epidemy1` mood icon (green checkmark)

### 3.9 Cover-Up Early Termination (epidemic.lua:243-268)

```lua
function Epidemic:checkInfectedLeftHospital()
  if not self:_isCoverUpActive() then return end
  for _, infected_patient in ipairs(self.infected_patients) do
    local px, py = infected_patient.tile_x, infected_patient.tile_y
    if (infected_patient.going_home or infected_patient.going_to_die) and not infected_patient.cured and
        px and py and not self.hospital:isInHospital(px, py) then
      self:finishCoverUp()  -- Infected escaped - cover-up fails immediately
      return
    end
  end
end

function Epidemic:checkNoInfectedPatients()
  if not self:_isCoverUpActive() then return end
  if self:countInfectedPatients() == 0 then
    self:finishCoverUp()  -- All cured/vaccinated - cover-up succeeds early
  end
end
```

---

## 4. Outcomes

### 4.1 Inspector Arrival & Verdict (epidemic.lua:424-485)

```lua
function Epidemic:handleInspectorArrival()
  local still_infected = self:countInfectedPatients()
  self:determineFaxAndFines(still_infected)
  self:clearAllInfectedPatients()
  self:applyOutcome()
end

function Epidemic:determineFaxAndFines(still_infected)
  local fail_text_1 = _S.fax.epidemic_result.failed.part_1_name:format(self.disease.name)
  local fail_text_2 = _S.fax.epidemic_result.failed.part_2
  local close_option = {text = _S.fax.epidemic_result.close_text, choice = "close"}

  self.coverup_fine = self:calculateInfectedFine(still_infected)

  if still_infected == 0 then
    -- SUCCESS: Full compensation
    local level_config = self.world.map.level_config
    local compensation_low_value = level_config.gbv.EpidemicCompLo or 1000
    local compensation_high_value = level_config.gbv.EpidemicCompHi or 5000
    self.compensation = math.random(compensation_low_value, compensation_high_value)

    self.cover_up_result_fax = {
      {text = _S.fax.epidemic_result.succeeded.part_1_name:format(self.disease.name)},
      {text = _S.fax.epidemic_result.succeeded.part_2},
      {text = _S.fax.epidemic_result.compensation_amount:format(self.compensation)},
      choices = {close_option}
    }

  elseif still_infected < self.reputation_loss_minimum and still_infected < self.evacuation_minimum then
    -- FAIL: Fine only (0-4 infected)
    self.cover_up_result_fax = {
      {text = fail_text_1},
      {text = fail_text_2},
      {text = _S.fax.epidemic_result.fine_amount:format(self.coverup_fine)},
      choices = {close_option}
    }

  elseif still_infected >= self.reputation_loss_minimum and still_infected < self.evacuation_minimum then
    -- FAIL: Fine + Reputation hit (5-9 infected)
    self.cover_up_result_fax = {
      {text = fail_text_1},
      {text = fail_text_2},
      {text = _S.fax.epidemic_result.rep_loss_fine_amount:format(self.coverup_fine)},
      choices = {close_option}
    }

  else
    -- CATASTROPHE: Hospital evacuation (10+ infected)
    self.will_be_evacuated = true
    self.cover_up_result_fax = {
      {text = fail_text_1},
      {text = fail_text_2},
      {text = _S.fax.epidemic_result.hospital_evacuated},
      choices = {close_option}
    }
  end
end
```

### 4.2 Outcome Application (epidemic.lua:489-508)

```lua
function Epidemic:applyOutcome()
  if self.compensation == 0 then  -- Failed cover-up
    if self.will_be_evacuated then
      self.reputation_hit = math.round(self.hospital.reputation * (1/3))  -- 33% rep loss
      self:evacuateHospital()
    else
      self.reputation_hit = getBaseReputationFromFine(self.coverup_fine)
    end
    self.hospital:spendMoney(self.coverup_fine, _S.transactions.epidemy_coverup_fine)
    self.hospital.reputation = self.hospital.reputation - self.reputation_hit
  else
    -- Successful cover-up
    self.hospital:receiveMoney(self.compensation, _S.transactions.compensation)
  end
  self:sendResultFax()
  self.hospital.epidemic = nil
end
```

### 4.3 Outcome Summary Table

| Infected Remaining | Outcome | Fine | Reputation | Evacuation |
|-------------------|---------|------|------------|------------|
| 0 | **Compensation** | - | - | No |
| 1-4 | Fine only | `infected × EpidemicFine` (min 2000) | `fine / 100` | No |
| 5-9 | Fine + Rep hit | `infected × EpidemicFine` (min 2000) | `fine / 100` | No |
| 10+ | **Evacuation** | `infected × EpidemicFine` (min 2000) | **33% of current rep** | **Yes** |

### 4.4 Fine Calculation (epidemic.lua:352-366)

```lua
function Epidemic:calculateInfectedFine(infected_count)
  local level_config = self.world.map.level_config
  local fine_per_infected = level_config.gbv.EpidemicFine or 2000
  return math.max(2000, infected_count * fine_per_infected)
end

local function getBaseReputationFromFine(fine_amount)
  return math.round(fine_amount / 100)
end
```

**Examples (default EpidemicFine=2000):**
- 1 infected: max(2000, 1×2000) = 2,000 fine, 20 rep loss
- 3 infected: max(2000, 3×2000) = 6,000 fine, 60 rep loss
- 5 infected: max(2000, 5×2000) = 10,000 fine, 100 rep loss
- 10 infected: max(2000, 10×2000) = 20,000 fine, 200 rep loss + evacuation

### 4.5 Hospital Evacuation (epidemic.lua:533-541)

```lua
function Epidemic:evacuateHospital()
  for _, patient in ipairs(self.hospital.patients) do
    if patient.has_passed_reception and
      not patient.going_home and
      not patient.going_to_die then
        patient:goHome("evacuated")
    end
  end
end
```

All patients who have passed reception (not in queue) are forced to leave immediately.

---

## 5. Vaccination Process Deep Dive

### 5.1 Complete Flow

```
Player clicks infected patient (vaccination mode ON)
       │
       ▼
Epidemic:markForVaccination() → Patient:setToReadyForVaccinationStatus() (epidemy2)
       │
       ▼
Epidemic:markedPatientsCallForVaccination() [called every tick]
       │
       ▼
CallsDispatcher:callNurseForVaccination() → Queues call with verification/priority
       │
       ▼
Nurse selected (closest idle nurse within 5 tiles, not in room)
       │
       ▼
CallsDispatcher.sendNurseToVaccinate() → Epidemic:createVaccinationActions()
       │
       ▼
Nurse walks to best adjacent tile (getBestVaccinationTile)
       │
       ▼
Patient:giveVaccinationCandidateStatus() (epidemy3)
       │
       ▼
VaccinateAction queued:
  - Nurse idles 5 ticks facing patient
  - perform_vaccination() callback:
    - Patient:setVaccinatedStatus() (epidemy1)
    - Hospital charged vaccination fee (default 50)
       │
       ▼
Patient cured of epidemic disease, removed from infected list
```

### 5.2 Vaccination Fee (epidemic.lua:616)

```lua
local level_config = self.world.map.level_config
local fee = level_config.gbv.VacCost or 50  -- Default 50 per vaccination
```

### 5.3 Interruption Handling (epidemic.lua:679-693)

```lua
function Epidemic:interruptVaccinationActions(nurse)
  local call = nurse.on_call
  if call then
    local patient = call.object
    if patient and patient.vaccination_candidate and not patient.vaccinated then
      patient:removeVaccinationCandidateStatus()  -- Back to epidemy2
    end
    call.object.reserved_for = nil
    call.assigned = nil
    nurse.on_call = nil
  end
end
```

If nurse interrupted (emergency, fire, etc.), patient reverts to "marked" status, call re-queued.

---

## 6. Code Examples & Key Patterns

### 6.1 Creating a Test Epidemic

```lua
-- In test setup:
local hospital = world:getLocalPlayerHospital()
local disease = world.diseases.by_name["Bloaty Head"]  -- Must be contagious
local patient = hospital:createTestPatient(disease)
patient.diagnosed = true  -- Makes epidemic ready to reveal

local epidemic = Epidemic(hospital, patient)
hospital.epidemic = epidemic
epidemic:revealEpidemic()  -- Sends initial fax
```

### 6.2 Simulating Infection Spread

```lua
-- Force infection tick
epidemic:infectOtherPatients()

-- Check spread stats
print("Total infections:", epidemic.total_infections)
print("Attempted infections:", epidemic.attempted_infections)
print("Effective rate:", epidemic.total_infections / epidemic.attempted_infections)
```

### 6.3 Testing Cover-Up Outcomes

```lua
-- Start cover-up
epidemic:startCoverUp()

-- Simulate vaccinating all patients
for _, p in ipairs(epidemic.infected_patients) do
  p.vaccinated = true
end

-- Force inspector arrival
epidemic:finishCoverUp()  -- Spawns inspector
-- ... wait for inspector to reach reception ...
epidemic:handleInspectorArrival()

-- Check outcome
print("Compensation:", epidemic.compensation)
print("Cover-up fine:", epidemic.coverup_fine)
print("Reputation hit:", epidemic.reputation_hit)
print("Evacuated:", epidemic.will_be_evacuated)
```

### 6.4 Configuration Override Example

```lua
-- In level config or mod:
level_config.gbv = {
  ContagiousSpreadFactor = 50,      -- Double spread rate
  EpidemicFine = 5000,              -- Higher fines
  EpidemicCompLo = 5000,            -- Better compensation
  EpidemicCompHi = 20000,
  EpidemicRepLossMinimum = 3,       -- Reputation hit sooner
  EpidemicEvacMinimum = 7,          -- Evacuation sooner
  VacCost = 100,                    -- Double vaccination cost
  EpidemicConcurrentLimit = 2,      -- Allow 2 simultaneous epidemics
}
```

### 6.5 Cheat Commands (cheats.lua:41-42, 112-146)

```lua
-- Toggle epidemic icons visibility (pre-reveal)
cheatToggleEpidemic()

-- Create instant epidemic
cheatEpidemic()
```

---

## 7. Key Implementation Details

### 7.1 Save/Load Compatibility (epidemic.lua:754-762)

```lua
function Epidemic:afterLoad(old, new)
  if old < 106 then
    self.level_config = nil
  end
  if old < 212 then
    self.coverup_selected = self.coverup_in_progress
    self.coverup_in_progress = nil
  end
end
```

### 7.2 Patient Removal Fairness (epidemic.lua:274-282)

```lua
function Epidemic:checkPatientsForRemoval()
  for i = #self.infected_patients, 1, -1 do
    local infected_patient = self.infected_patients[i]
    -- Remove patients already leaving/dying before epidemic started
    if (not self.coverup_selected and (infected_patient.going_home or infected_patient.going_to_die)) or
        infected_patient.dead or infected_patient.tile_x == nil then
      table.remove(self.infected_patients, i)
    end
  end
end
```

Prevents instant failure from patients already departing when epidemic begins.

### 7.3 Advice Messages (epidemic.lua:697-715)

```lua
function Epidemic:showAppropriateAdviceMessages()
  if not self:_isCoverUpActive() then return end

  if self.countdown_intervals then
    -- Hurry up warning at 25% timer remaining
    if not self.has_said_hurry_up and self:countInfectedPatients() > 0 and
        self.timer.open_timer == math.floor(self.countdown_intervals * 1 / 4) then
      self.world.ui.adviser:say(_A.epidemic.hurry_up)
      self.has_said_hurry_up = true
    end

    -- Serious warning after 25% elapsed with >10 infected
    elseif self.timer.open_timer <= math.floor(self.countdown_intervals * 3 / 4) and
        not self.has_said_serious and self:countInfectedPatients() > 10 then
      self.world.ui.adviser:say(_A.epidemic.serious_warning)
      self.has_said_serious = true
    end
  end
end
```

---

## 8. Integration Points

### 8.1 Hospital Tick Integration (hospital.lua:1050-1077)

Epidemics tick via `Hospital:manageEpidemics()` called from main hospital tick loop.

### 8.2 Patient Click Handling (patient.lua:75-109)

```lua
function Patient:onClick(ui, button)
  if button == "left" then
    local function isValidEpidemicTarget(epidemic)
      return epidemic and epidemic.coverup_selected and
          (epidemic.vaccination_mode_active or
          (self.infected and (not self.marked_for_vaccination)))
    end
    -- ...
    if isValidEpidemicTarget(epidemic) then
      if not epidemic.timer.closed then
        epidemic:markForVaccination(self)
      end
    end
  end
end
```

### 8.3 Dynamic Info Display (patient.lua:1126-1138)

```lua
local epidemic = self.hospital and self.hospital.epidemic
if epidemic and self.infected and epidemic.coverup_selected then
  if self.vaccinated then
    self:setDynamicInfo('text', {action_string, _S.dynamic_info.patient.actions.epidemic_vaccinated, info})
  else
    self:setDynamicInfo('text', {action_string, _S.dynamic_info.patient.actions.epidemic_contagious, info})
  end
end
```

---

## 9. Modding & Extension Points

### 9.1 Configurable Parameters (All in level_config.gbv)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ContagiousSpreadFactor` | 25 | Spread probability numerator |
| `EpidemicFine` | 2000 | Fine per infected patient |
| `EpidemicCompLo` | 1000 | Compensation minimum |
| `EpidemicCompHi` | 15000 | Compensation maximum |
| `EpidemicRepLossMinimum` | 5 | Rep loss threshold |
| `EpidemicEvacMinimum` | 10 | Evacuation threshold |
| `VacCost` | 50 | Vaccination fee |
| `EpidemicConcurrentLimit` | 1 | Max concurrent epidemics |
| `ReduceContMonths` | 14 | Months before contagion starts |
| `ReduceContPeepCount` | 20 | Visitors before contagion starts |

### 9.2 Disease-Specific Contagion (expertise table)

Each disease has `ContRate` in expertise config (base_config.lua:172-219):
- `ContRate = 0` → Never contagious
- `ContRate = 4` → 25% chance per patient
- `ContRate = 2` → 50% chance per patient

### 9.3 Hook Points for Mods

1. `Epidemic:tick()` - Custom spread logic
2. `Epidemic:calculateInfectedFine()` - Custom fine formula
3. `Epidemic:determineFaxAndFines()` - Custom outcome tiers
4. `Epidemic:getBestVaccinationTile()` - Custom nurse positioning
5. `Hospital:determineIfContagious()` - Custom contagion triggers

---

## 10. Summary of Critical Values

| Constant | Value | Source |
|----------|-------|--------|
| Spread factor | 25% | `ContagiousSpreadFactor` |
| Spread scale factor | 200 | Hardcoded in `infectOtherPatients()` |
| Effective spread rate | 12.5% | 25/200 |
| Timer segments | 13 | `TIMER_SEGMENTS` in watch.lua |
| Timer duration | ~100 days | `TICK_DAYS = 100` |
| Vaccination idle ticks | 5 | `IdleAction():setCount(5)` in vaccinate.lua |
| Vaccination fee | 50 | `VacCost` default |
| Fine minimum | 2,000 | Hardcoded in `calculateInfectedFine()` |
| Rep loss per 100 fine | 1 | `getBaseReputationFromFine()` |
| Evacuation rep loss | 33% | `reputation * (1/3)` |
| Concurrent epidemic limit | 1 | `EpidemicConcurrentLimit` |
| Contagion start month | 14 | `ReduceContMonths` |
| Contagion start visitors | 20 | `ReduceContPeepCount` |

---

*Document generated from CorsixTH source code analysis. Last updated: 2026-08-18*
