# Patient Lifecycle in CorsixTH - Complete Documentation

## Overview

This document provides a comprehensive analysis of the patient lifecycle system in CorsixTH, covering the complete state machine from patient spawn through reception, diagnosis, treatment, and final resolution (cure, death, or departure).

---

## 1. Patient State Machine

### States

```
SPAWN → RECEPTION → DIAGNOSIS (GP + optional diagnosis rooms) → TREATMENT → RESOLUTION
                                                                    ├── CURE → GO_HOME("cured")
                                                                    ├── DEATH → DIE → DESPAWN
                                                                    └── GO_HOME("kicked" | "over_priced" | "evacuated")
```

### Core State Fields (patient.lua)

| Field | Type | Description |
|-------|------|-------------|
| `diagnosed` | boolean | Whether patient has been fully diagnosed |
| `diagnosis_progress` | number (0-2.5) | Progress toward diagnosis (policy "stop_procedure" caps max) |
| `cured` | boolean | Patient successfully treated |
| `dead` | boolean | Patient has died |
| `going_home` | boolean | Patient is leaving hospital |
| `going_to_die` | boolean | Patient is in dying animation sequence |
| `set_to_die` | boolean | Flag to trigger death when patient becomes free |
| `infected` | boolean | Patient has epidemic disease |
| `vaccinated` | boolean | Patient received vaccination |
| `insurance_company` | number (1-3) | nil or insurance company index |
| `has_passed_reception` | boolean | Patient processed at reception desk |
| `cure_rooms_visited` | number | Count of treatment rooms visited |
| `available_diagnosis_rooms` | table | List of diagnosis room IDs not yet visited |
| `treatment_history` | table | Log of rooms/diseases for UI display |

---

## 2. Spawn & Hospital Entry

### Patient Creation (`patient.lua:27-73`)

```lua
function Patient:Patient(...)
  self:Humanoid(...)
  self.hover_cursor = TheApp.gfx:loadMainCursor("patient")
  self.should_knock_on_doors = true
  self.treatment_history = {}
  self.going_home = false
  self.litter_countdown = nil
  self.has_fallen = 1
  self.has_vomitted = 0
  self.action_string = ""
  self.cured = false
  self.infected = false
  self.pay_amount = 0
  self.dead = false
  self.set_to_die = false
  self.going_to_die = false
  self.reserved_for = false
  self.vaccinated = false
  self.needs_redirecting = false
  self.under_infection_attempt = false
  self.vaccination_candidate = false
  self.has_passed_reception = false
  self.diagnosis_progress = 0
  self.going_to_toilet = "no"
  self.health_history = nil
end
```

### Hospital Assignment (`patient.lua:232-241`)

```lua
function Patient:setHospital(hospital)
  if self.hospital then
    self.hospital:removePatient(self)
  end
  Humanoid.setHospital(self, hospital)
  if hospital.is_in_world and not self.is_debug and not self.is_emergency then
    self:setNextAction(SeekReceptionAction())  -- → RECEPTION state
  end
  hospital:addPatient(self)
end
```

**Flow**: Patient spawns → assigned to hospital → `SeekReceptionAction` queued → walks to reception desk

---

## 3. Reception Phase

### Reception Desk Logic (`objects/reception_desk.lua:99-112`)

```lua
local function handlePatient(patient, is_new)
  if not is_new then
    -- Patient redirected to reception (after diagnosis)
    local id = patient.next_room_to_visit.room_info.id
    return patient:queueAction(SeekRoomAction(id))
  end

  -- New patient arriving
  if patient:agreesToPay("diag_gp") then
    return patient:queueAction(SeekRoomAction("gp"))
  end
  -- Patient refuses to pay GP fee
  return patient:goHome("over_priced", "diag_gp")
end
```

### Queue Processing (`reception_desk.lua:130-165`)

- Queue advances based on receptionist skill (higher skill = faster)
- `front_humanoid.has_passed_reception = true` when processed
- Patient either sent to GP or goes home if overpriced

### Patient Payment Decision (`patient.lua:319-339`)

```lua
function Patient:agreesToPay(disease_id)
  local hosp = self.hospital
  local casebook = hosp.disease_casebook[disease_id]
  local agrees_to_pay = true
  local price_multiplier = casebook.price
  local is_over_priced = price_multiplier > 1.0
  if is_over_priced then
    local overprice_size = price_multiplier - 1.0
    local payment_chance_modificator = 4
    local payment_chance = math.exp(-1 * payment_chance_modificator * overprice_size)
    agrees_to_pay = math.random() <= payment_chance
  end
  if agrees_to_pay then
    self.pay_amount = hosp:getTreatmentPrice(disease_id)
  end
  return agrees_to_pay
end
```

---

## 4. Diagnosis Phase

### GP Room (`rooms/gp.lua:112-165`)

The GP is the **central hub** for diagnosis routing:

```lua
function GPRoom:dealtWithPatient(patient)
  -- Handle redirection from epidemic disease changes
  if patient.needs_redirecting then
    self:sendPatientToNextDiagnosisRoom(patient)
    patient.needs_redirecting = false
  elseif patient.disease and not patient.diagnosed then
    self.hospital:receiveMoneyForTreatment(patient)
    patient:completeDiagnosticStep(self)  -- Update diagnosis_progress
    
    local no_need_diagnose_further = patient.diagnosis_progress >= stop_procedure
    local cant_diagnose_further = (patient.diagnosis_progress >= 1.0) and (not patient:hasMoreDiagnosisRoomsAvailable())
    
    if no_need_diagnose_further or cant_diagnose_further then
      patient:setDiagnosed()  -- DIAGNOSIS COMPLETE
      if patient:agreesToPay(patient.disease.id) then
        patient:queueAction(SeekRoomAction(patient.disease.treatment_rooms[1]):enableTreatmentRoom())
      else
        patient:goHome("over_priced", patient.disease.id)
      end
    else
      self:sendPatientToNextDiagnosisRoom(patient)  -- More diagnosis needed
    end
  end
end
```

### Diagnosis Progress Calculation (`patient.lua:197-226`)

```lua
function Patient:completeDiagnosticStep(room)
  local expertise = self.world.map.level_config.expertise
  local diagnosis_difficulty = expertise[self.disease.expertise_id].MaxDiagDiff / 1000
  local diagnosis_base = 0.4 * (1 - diagnosis_difficulty)
  local diagnosis_bonus = 0.4
  
  if room.staff_member then
    local fatigue = room.staff_member:getAttribute("fatigue")
    local multiplier = 1
    
    if room.staff_member.profile.skill >= 0.9 then
      multiplier = math.random(1, 5) * (1 - (fatigue - 0.5))
    else
      multiplier = 1 * (1 - (fatigue - 0.5))
    end
    
    local divisor = math.random(1, 3)
    local attn_detail = room.staff_member.profile.attention_to_detail / divisor
    local skill = room.staff_member.profile.skill / divisor
    diagnosis_bonus = (attn_detail + 0.4) * skill
  end
  
  self:modifyDiagnosisProgress(diagnosis_base + (diagnosis_bonus * multiplier))
end
```

### Seeking Diagnosis Rooms (`humanoid_actions/seek_room.lua:57-130`)

- If GP specified a diagnosis room (`action.diagnosis_room`), tries that first
- Otherwise randomly selects from `patient.available_diagnosis_rooms`
- Removes rooms that don't exist from available list
- Sets `action.diagnosis_exists` flag if room type is buildable but not built

### Room Completion (`room.lua:192-237`)

```lua
function Room:dealtWithPatient(patient)
  if not patient.hospital or patient.going_home then return end
  patient:setNextAction(self:createLeaveAction())
  patient:addToTreatmentHistory(self.room_info)
  
  if patient.disease then
    if not patient.diagnosed then
      -- DIAGNOSIS ROOM
      patient:completeDiagnosticStep(self)
      self.hospital:receiveMoneyForTreatment(patient)
      if patient:agreesToPay("diag_gp") then
        patient:queueAction(SeekRoomAction("gp"))
      else
        patient:goHome("over_priced", "diag_gp")
      end
    else
      -- TREATMENT ROOM
      patient.cure_rooms_visited = patient.cure_rooms_visited + 1
      local next_room = patient.disease.treatment_rooms[patient.cure_rooms_visited + 1]
      if next_room then
        patient:queueAction(SeekRoomAction(next_room))
      else
        patient:treatDisease()  -- Final treatment room → RESOLUTION
      end
    end
  end
end
```

---

## 5. Treatment Phase

### Treatment Room Routing

Diseases define `treatment_rooms` array (e.g., `{"gp", "surgery", "pharmacy"}`):

1. After diagnosis: `SeekRoomAction(treatment_rooms[1]):enableTreatmentRoom()`
2. After each treatment room: `cure_rooms_visited++`, check `treatment_rooms[cure_rooms_visited + 1]`
3. Final room → `treatDisease()`

### Treatment Resolution (`patient.lua:295-317`)

```lua
function Patient:treatDisease()
  local hospital = self.hospital
  hospital:receiveMoneyForTreatment(self)
  self.th:setPatientEffect(AnimationEffect.None)
  
  if self:isTreatmentEffective() then
    self:cure()
    self.treatment_history[#self.treatment_history + 1] = _S.dynamic_info.patient.actions.cured
    self:goHome("cured")
  else
    self:die()
  end
  
  hospital:updatePercentages()
  hospital:paySupplierForDrug(self.disease.id)
  if self.is_emergency then hospital:checkEmergencyOver() end
end
```

### Cure Effectiveness (`patient.lua:343-357`)

```lua
function Patient:isTreatmentEffective()
  local cure_chance = self.hospital.disease_casebook[self.disease.id].cure_effectiveness
  cure_chance = cure_chance * self.diagnosis_progress  -- Diagnosis quality matters!
  
  local room = self:getRoom()
  local min_impact = 20
  local service_base = math.max(100 - cure_chance, min_impact)
  local scale = 0.2
  local service_factor = (room:getStaffServiceQuality() - 0.5) * scale
  cure_chance = cure_chance + (service_base * service_factor)
  
  return (cure_chance >= math.random(1, 100))
end
```

**Key factors**:
- Base cure effectiveness from casebook (modified by research)
- **Diagnosis progress directly multiplies cure chance** (better diagnosis = better cure)
- Room service quality ±10% impact

### Cure (`patient.lua:364-368`)

```lua
function Patient:cure()
  self.cured = true
  self.infected = false
  self.attributes["health"] = 1
end
```

---

## 6. Death & Grim Reaper

### Patient Death (`patient.lua:371-392`)

```lua
function Patient:die()
  self.set_to_die = false
  if self.cured then return end
  
  self.hospital:humanoidDeath(self)
  self:setMood("dying5", "deactivate")
  self:setMood("dead", "activate")
  self:unregisterCallbacks()
  
  self.going_to_die = true
  if self:getRoom() then
    self:queueAction(MeanderAction():setCount(1))
  else
    self:setNextAction(MeanderAction():setCount(1))
  end
  self:queueAction(DieAction())
  self:setDynamicInfoText(_S.dynamic_info.patient.actions.dying)
end
```

### Death Trigger Check (`patient.lua:598-607`)

```lua
function Patient:tick()
  Humanoid.tick(self)
  if self.set_to_die and
    not self:getRoom() and
    not self:getCurrentAction().is_leaving and
    not self:isKnockingDoor() and
    not self:isEnteringRoom() then
    self:die()
  end
end
```

### Health Deterioration (`patient.lua:654-706`)

Daily health decay: `changeAttribute("health", -0.004)`

**Thresholds** (health → mood):
- ≤ 0.06: dying5 ("Not looking good")
- ≤ 0.10: dying4 ("Fading fast")
- ≤ 0.14: dying3 ("Starts to take a turn for the worse")
- ≤ 0.18: dying2 ("Wishes they went to that other hospital")
- ≤ 0.22: dying1 ("Getting rather unwell now")

**At health < 0.01**: `setToDying()` → will die when free

**Fed up leave chance**: At each threshold crossing, 1/30 chance to `goHome("kicked")` if not in cure room

### Hospital Death Recording (`hospital.lua:1420-1436`)

```lua
function Hospital:humanoidDeath(patient)
  self:msgKilled()
  if not patient.is_debug then
    local case = self.disease_casebook[patient.disease.id]
    case.fatalities = case.fatalities + 1
  end
  self.num_deaths = self.num_deaths + 1
  self.num_deaths_this_year = self.num_deaths_this_year + 1
  self:changeReputation("death", patient.disease)  -- -4 reputation
  self:updatePercentages()
  if patient.is_emergency then
    self.emergency.killed_emergency_patients = self.emergency.killed_emergency_patients + 1
  end
end
```

### Grim Reaper (`entities/humanoids/grim_reaper.lua`)

```lua
class "GrimReaper" (Humanoid)
function GrimReaper:tickDay() return false end  -- No daily processing
function GrimReaper:updateDynamicInfo() end      -- No dynamic info
```
- Simple humanoid that appears for death animations
- No AI, no daily ticks, no dynamic info

### DieAction (`humanoid_actions/die.lua`)

Handles the death animation sequence and final despawn.

---

## 7. Going Home / Discharge

### Patient:goHome() (`patient.lua:509-575`)

```lua
function Patient:goHome(reason, disease_id)
  local hosp = self.hospital
  -- Prevent double goHome
  if self.going_home then return end
  
  if reason == "cured" then
    self:setMood("cured", "activate")
    self:changeAttribute("happiness", 0.8)
    hosp:updateCuredCounts(self)
    
  elseif reason == "kicked" then
    self:setMood("exit", "activate")
    hosp:updateNotCuredCounts(self, reason)
    
  elseif reason == "over_priced" then
    self:setMood("sad_money", "activate")
    self:changeAttribute("happiness", -0.5)
    hosp:updateNotCuredCounts(self, reason)
    hosp:giveAdvice({_A.warnings.patient_not_paying:format(treatment_name)})
    
  elseif reason == "evacuated" then
    self:setMood("exit", "activate")
  end
  
  hosp:updatePercentages()
  if self.is_debug then hosp:removeDebugPatient(self) end
  self:unregisterCallbacks()
  self.going_home = true
  self.waiting = nil
  
  if not self.vaccinated then
    self.world.dispatcher:dropFromQueue(self)
  end
  
  if self.is_emergency then hosp:checkEmergencyOver() end
  
  local room = self:getRoom()
  if room then room:makeHumanoidLeave(self) end
  Humanoid.despawn(self)
end
```

### Despawn (`patient.lua:578-581`)

```lua
function Patient:despawn()
  self.hospital:removePatient(self)
  Humanoid.despawn(self)
end
```

### Hospital Remove Patient (`hospital.lua:1594-1597`)

```lua
function Hospital:removePatient(patient)
  if patient.is_debug then self:removeDebugPatient(patient) end
  RemoveByValue(self.patients, patient)
end
```

---

## 8. Daily Processing (tickDay)

### Patient:tickDay() (`patient.lua:933-1004`)

```lua
function Patient:tickDay()
  -- Waiting timeout
  if self.waiting then
    self:_dailyWaitChecks()  -- go_home after 0 days, tap_foot/yawn/check_watch at 10/20/30
  end
  
  -- Sad mood at low happiness
  if self:getAttribute("happiness") < 0.3 then
    self:setMood("sad2", "activate")
  end
  
  -- Falling animation state machine
  if self.has_fallen == 3 then self.has_fallen = 1
  elseif self.has_fallen == 2 then self.has_fallen = 3 end
  
  -- Parent tickDay (handles leaving hospital bounds)
  if not Humanoid.tickDay(self) then return end
  
  -- Health checks (deterioration, death threshold)
  if self:_dailyHealthChecks() == 0.0 then return end
  
  -- Health history for chart
  self:_dailyHealthHistoryRefresh()
  
  -- Object happiness effects (plants, litter, benches, vomit)
  if not self:getRoom() and not entering/leaving then
    local num_nearby_vomit = self:_dailyObjectHappinessEffects()
    if self.vomit_anim and not self.is_emergency then
      local nausea_level = self:_calculateNausea(num_nearby_vomit)
      if nausea_level and math.random() < nausea_level + 0.5 then self:vomit() end
    end
  end
  
  -- Attribute decay
  self:changeAttribute("health", -0.004)
  if not self.is_emergency then
    self:changeAttribute("thirst", warmth * 0.02 + 0.004 * math.random() + 0.004)
    self:_dailyBowelChecks()  -- toilet_need increase
    
    if self:getAttribute("thirst") > 0.7 then
      self:_handleExcessThirst()  -- Seek drinks machine
    end
  end
  
  -- Random yawn
  if self.disease.yawn and math.random(1,10) == 5 then self:yawn() end
  
  -- Queue validation
  self:_checkPatientIsStillQueueingForARoom()
end
```

### Waiting Events (`patient.lua:611-639`)

| Days Remaining | Event | Action |
|----------------|-------|--------|
| 0 | go_home | `goHome("kicked")` - no rooms available |
| 10 | tap_foot | `tapFoot()` animation |
| 20 | yawn | `yawn()` animation |
| 30 | check_watch | `checkWatch()` animation |

---

## 9. Insurance System

### Setup (`hospital.lua:202-222`)

```lua
-- Select 3 insurance companies from translated list
self.insurance = {}
local companies = {}
for no, local_name in ipairs(_S.insurance_companies) do companies[no] = local_name end
while #self.insurance < 3 and #companies > 0 do
  local num = math.random(1, 2) == 1 and math.random(1, math.ceil(#companies / 4)) or math.random(1, #companies)
  self.insurance[#self.insurance + 1] = companies[num]
  table.remove(companies, num)
end

-- Balance: [current_month, last_month, month_before]
self.insurance_balance = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}}
```

### Patient Insurance Assignment (`patient.lua:124-128`)

```lua
-- 25% of patients pay via insurance
if math.random(1, 4) == 1 then
  self.insurance_company = math.random(1, 3)  -- Randomly pick one of 3
end
```

### Payment Processing (`hospital.lua:1240-1266`)

```lua
function Hospital:receiveMoneyForTreatment(patient)
  local disease_id = patient:getTreatmentDiseaseId()
  local casebook = self.disease_casebook[disease_id]
  local amount = patient.pay_amount or self:getTreatmentPrice(disease_id)
  
  if patient.insurance_company then
    -- 25% go through insurance (paid 2 months later)
    self:addInsuranceMoney(patient.insurance_company, amount)
  else
    -- Direct payment with price perception impact
    self:computePriceLevelImpact(patient, casebook)
    self:receiveMoney(amount, reason)
  end
  casebook.money_earned = casebook.money_earned + amount
  patient.world:newFloatingDollarSign(patient, amount)
  patient.pay_amount = 0
end

function Hospital:addInsuranceMoney(company, amount)
  self.insurance_balance[company][1] = self.insurance_balance[company][1] + amount
end
```

### Insurance Payout (Monthly)

From `hospital.lua:832-836` - insurance balances shift monthly, current month becomes payable after 2 months.

---

## 10. Epidemic / Infection Mechanics

### Infection Status (`patient.lua:1198-1241`)

```lua
function Patient:setInfectedStatus()
  self:removeAnyEpidemicStatus()
  self:setMood("epidemy4","activate")
  self.vaccination_candidate = false
end

function Patient:setVaccinatedStatus()
  self:removeAnyEpidemicStatus()
  self:setMood("epidemy1","activate")
  self.marked_for_vaccination = false
  self.vaccinated = true
end
```

### Disease Change (`patient.lua:138-167`)

```lua
function Patient:changeDisease(new_disease)
  assert(not self.diagnosed)
  assert(self.disease.contagious)
  assert(new_disease.contagious)
  
  local visited_rooms = {}
  for _, room in ipairs(self.disease.diagnosis_rooms) do visited_rooms[room] = true end
  for _, room in ipairs(self.available_diagnosis_rooms) do visited_rooms[room] = false end
  
  self.available_diagnosis_rooms = {}
  for _, room in ipairs(new_disease.diagnosis_rooms) do
    if not visited_rooms[room] then
      self.available_diagnosis_rooms[#self.available_diagnosis_rooms + 1] = room
    end
  end
  self.disease = new_disease
  self.needs_redirecting = true  -- Handled at GP
end
```

---

## 11. Patient Attributes & Needs

### Core Attributes (initialized in `setDisease`, `patient.lua:131-134`)

```lua
if not self.disease.only_emergency then
  self.attributes["thirst"] = math.random()*0.2
  self.attributes["toilet_need"] = math.random()*0.2
end
```

### Daily Decay (tickDay)

| Attribute | Daily Change | Notes |
|-----------|--------------|-------|
| health | -0.004 | Base decay; faster if untreated |
| thirst | +0.004 to +0.024 | Based on warmth |
| toilet_need | +0.002 to +0.024 | Higher for `disease.more_loo_use` |
| happiness | Variable | Affected by objects, wait time, prices, falling |

### Thirst Handling (`patient.lua:865-898`)

- Threshold: `thirst > 0.7` → unhappy, seeks drinks machine
- Timeout: 2-4 days between searches
- 60% chance to drop litter (can) after drinking

### Toilet Handling (`patient.lua:742-778`)

- Threshold: `toilet_need > 0.75`
- 40% chance: pee on floor (unhappy, advice triggered)
- 60% chance: seek toilet room (`SeekToiletsAction`)

### Vomit Mechanics (`patient.lua:726-739`, `976-980`)

- Base nausea: `(1 - health) * 0.002`
- Multiplier: `(nearby_vomit + 1) * 1.5`
- Extra 0.5 added temporarily (no rats yet)
- Triggers if `health ≤ 0.8` OR `nearby_vomit > 0` OR `happiness < 0.6`

---

## 12. Key Code References

### File:Line Index

| Function/Method | File | Line |
|-----------------|------|------|
| `Patient:Patient()` | patient.lua | 27 |
| `Patient:setHospital()` | patient.lua | 232 |
| `Patient:setDisease()` | patient.lua | 111 |
| `Patient:changeDisease()` | patient.lua | 138 |
| `Patient:setDiagnosed()` | patient.lua | 170 |
| `Patient:modifyDiagnosisProgress()` | patient.lua | 184 |
| `Patient:completeDiagnosticStep()` | patient.lua | 197 |
| `Patient:agreesToPay()` | patient.lua | 319 |
| `Patient:isTreatmentEffective()` | patient.lua | 343 |
| `Patient:cure()` | patient.lua | 364 |
| `Patient:die()` | patient.lua | 371 |
| `Patient:goHome()` | patient.lua | 509 |
| `Patient:despawn()` | patient.lua | 578 |
| `Patient:tickDay()` | patient.lua | 933 |
| `Patient:tick()` | patient.lua | 598 |
| `Patient:setToDying()` | patient.lua | 591 |
| `Room:dealtWithPatient()` | room.lua | 192 |
| `GPRoom:dealtWithPatient()` | rooms/gp.lua | 112 |
| `GPRoom:sendPatientToNextDiagnosisRoom()` | rooms/gp.lua | 167 |
| `ReceptionDesk:tick()` | objects/reception_desk.lua | 94 |
| `Hospital:receiveMoneyForTreatment()` | hospital.lua | 1240 |
| `Hospital:humanoidDeath()` | hospital.lua | 1420 |
| `Hospital:removePatient()` | hospital.lua | 1594 |
| `Hospital:changeReputation()` | hospital.lua | 1623 |
| `SeekReceptionAction` | humanoid_actions/seek_reception.lua | 21 |
| `SeekRoomAction` | humanoid_actions/seek_room.lua | 21 |
| `DieAction` | humanoid_actions/die.lua | 21 |
| `GrimReaper` | entities/humanoids/grim_reaper.lua | 21 |

---

## 13. State Transition Diagram

```
┌─────────┐
│  SPAWN  │
└────┬────┘
     │ setHospital() → SeekReceptionAction()
     ▼
┌─────────────┐
│  RECEPTION  │◄──────────────────────────┐
└──────┬──────┘                           │
       │ agreesToPay("diag_gp")           │
       ▼                                  │
┌─────────────┐    completeDiagnosticStep  │
│     GP      │────────────────────────────┤
└──────┬──────┘   diagnosis_progress++     │
       │                                  │
       │ diagnosed?                       │
       ├──────No──────────────────────────┤
       │                                  │
       ▼                                  │
┌─────────────────┐                       │
│ Diagnosis Rooms │                       │
│ (X-ray, etc.)   │                       │
└────────┬────────┘                       │
         │ diagnosis_progress ≥ stop      │
         │ OR no more rooms               │
         ▼                                │
┌─────────────┐                           │
│  DIAGNOSED  │                           │
│  (setDiagnosed)                         │
└──────┬──────┘                           │
       │ agreesToPay(disease.id)          │
       ▼                                  │
┌─────────────────┐                       │
│ Treatment Rooms │                       │
│ (sequence)      │                       │
└────────┬────────┘                       │
         │ last room?                     │
         ▼                                │
┌─────────────────┐                       │
│  TREATMENT      │                       │
│  (treatDisease) │                       │
└────────┬────────┘                       │
         │                                │
    ┌────┴────┐                            │
    ▼         ▼                            │
┌───────┐ ┌────────┐                      │
│ CURE  │ │  DEATH │                      │
└───┬───┘ └────┬───┘                      │
    │          │                          │
    ▼          ▼                          │
┌──────────┐ ┌─────────┐                  │
│goHome    │ │ DieAction│                 │
│("cured") │ │ → Grim   │                 │
└──────────┘ │ Reaper  │                 │
             └─────────┘                  │
                                         │
                    ┌────────────────────┘
                    │ Patient kicked/
                    │ over_priced/
                    │ no rooms
                    ▼
             ┌──────────┐
             │goHome    │
             │("kicked" │
             │"over_...│
             └──────────┘
```

---

## 14. Summary of Key Design Patterns

1. **Action Queue System**: Patients use queued `HumanoidAction` subclasses for navigation and interaction
2. **Central GP Hub**: GP room routes patients to diagnosis rooms and then to treatment rooms
3. **Progress-Based Diagnosis**: `diagnosis_progress` accumulates across rooms; affects cure chance directly
4. **Probabilistic Payment**: `agreesToPay()` uses exponential decay based on price multiplier
5. **Health-Driven Death**: Daily -0.004 health decay; death at 0.01 threshold with mood stages
6. **Insurance Delay**: 25% of patients use insurance; payment delayed 2 months
7. **Epidemic Integration**: Infected patients can change disease; vaccination candidate system
8. **Needs Simulation**: Thirst, toilet, happiness with environmental interactions (litter, plants, benches)

---

*Document generated from CorsixTH source code analysis. All line references approximate to current codebase state.*


## Related Pages

- [[04-patient-lifecycle/CHECKLIST]]
- [[04-patient-lifecycle/MAP]]
- [[04-patient-lifecycle/SCAFFOLD]]
