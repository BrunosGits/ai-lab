# Emergency System in CorsixTH - Deep Research Summary

## Overview

The Emergency System in CorsixTH handles random emergency events where a helicopter delivers multiple patients with a specific disease that must be treated within a time limit. This document provides a comprehensive analysis of the emergency structure, creation requirements, resolution logic, timer management, fax system, and helicopter spawning mechanics.

---

## 1. Emergency Structure

### 1.1 Emergency Data Structure

When an emergency is created, it is stored as a table with the following fields:

```lua
emergency = {
    disease = disease,              -- The disease object for this emergency
    victims = number,               -- Number of patients (2 to disease.emergency_number)
    bonus = 1000,                   -- Base bonus per cured patient
    percentage = 0.75,              -- Success threshold (75% must be cured)
    killed_emergency_patients = 0,  -- Counter for patients who died
    cured_emergency_patients = 0,   -- Counter for patients who were cured
}
```

### 1.2 Default Values

| Field | Default Value | Description |
|-------|---------------|-------------|
| `bonus` | 1000 | Base monetary reward per cured patient |
| `percentage` | 0.75 (75%) | Minimum cure rate for success |
| `victims` | Random 2 to `disease.emergency_number` | Number of patients in the emergency |

### 1.3 Disease-Specific Emergency Properties

Each disease defines emergency-related properties in its disease file (`Lua/diseases/*.lua`):

- `emergency_sound`: Sound played when helicopter arrives (e.g., `"emerg007.wav"`)
- `emergency_number`: Maximum number of victims for this disease
- `treatment_rooms`: Ordered list of rooms required for treatment

**Examples from disease files:**
- Bloaty Head: `emergency_number = 18`, `emergency_sound = "emerg007.wav"`
- The Squits: `emergency_number = 18`, `emergency_sound = "emerg002.wav"`
- Alien DNA: `emergency_number = 16`, `only_emergency = true`

---

## 2. Emergency Creation Requirements

### 2.1 Prerequisites (Hospital:createEmergency)

From `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:925-952`:

```lua
function Hospital:createEmergency(emergency)
  local random_disease = self.world.available_diseases[math.random(1, #self.world.available_diseases)]
  local disease = TheApp.diseases[random_disease.id]
  local number = math.random(2, disease.emergency_number)
  
  -- REQUIREMENT 1: Heliport with spawn position
  -- REQUIREMENT 2: Reception desk (built and staffed)
  if self:getHeliportSpawnPosition() and self:hasReceptionDesk(true) then
    -- ... create emergency
  end
  return "no_heliport"
end
```

### 2.2 Requirements Summary

| Requirement | Check Method | Description |
|-------------|--------------|-------------|
| Heliport | `getHeliportSpawnPosition()` | Must have a heliport built with valid spawn position |
| Reception Desk | `hasReceptionDesk(true)` | Must have a built reception desk with a receptionist |
| Discovered Disease | `disease_casebook[disease.id].discovered` | Disease must be discovered in casebook |

### 2.3 Failure Reasons

| Return Value | Cause |
|--------------|-------|
| `"no_heliport"` | No heliport or no valid spawn position |
| `"undiscovered_disease"` | Selected disease not yet discovered |
| `nil` (success) | Emergency created successfully |

### 2.4 Scheduled vs Random Emergencies

From `world.lua:1250-1321`:

**Controlled Emergencies** (level-defined schedule):
- Level config defines `emergency_control` array with specific months/diseases
- `World:nextEmergency()` processes scheduled emergencies
- `World:computeNextEmergencyDates()` calculates exact date

**Random Emergencies** (mean/variance based):
- Level config `emergency_control[0].Mean` and `.Variance`
- `World:scheduleRandomEmergency()` schedules using normal distribution
- Default: Mean=180 days, Variance=30 days

---

## 3. Emergency Resolution Logic

### 3.1 Resolution Trigger

Emergency resolution occurs when:
1. **Timer expires** - `UIWatch:onCountdownEnd()` calls `hospital:resolveEmergency()`
2. **All patients cured/died** - `Hospital:checkEmergencyOver()` detects `killed + cured >= victims`

### 3.2 Resolution Algorithm (hospital.lua:955-980)

```lua
function Hospital:resolveEmergency()
  local emer = self.emergency
  local rescued_patients = emer.cured_emergency_patients
  
  -- Set remaining patients to dying
  for _, patient in ipairs(self.emergency_patients) do
    if patient and not patient.cured and not patient.dead and not patient.going_home then
      patient:setToDying()
    end
  end
  
  local total = emer.victims
  local max_bonus = emer.bonus * total
  local emergency_success = rescued_patients / total >= emer.percentage
  local earned = 0
  
  if emergency_success then
    earned = emer.bonus * rescued_patients
  end
  
  -- Send end fax
  self:makeEmergencyEndFax(rescued_patients, total, max_bonus, earned)
  
  if emergency_success then
    self:changeReputation("emergency_success", emer.disease)
    self:receiveMoney(earned, _S.transactions.emergency_bonus)
  else
    self:changeReputation("emergency_failed", emer.disease)
  end
  
  self.world:nextEmergency()
end
```

### 3.3 Success Criteria

| Condition | Formula | Result |
|-----------|---------|--------|
| **Success** | `cured_patients / total_victims >= 0.75` | Money bonus + Reputation gain |
| **Failure** | `cured_patients / total_victims < 0.75` | No money + Reputation loss |

### 3.4 Rewards & Penalties

| Outcome | Money | Reputation |
|---------|-------|------------|
| Success | `bonus * cured_patients` (max `bonus * victims`) | `changeReputation("emergency_success", disease)` |
| Failure | 0 | `changeReputation("emergency_failed", disease)` |

### 3.5 Patient Tracking

Patients are tracked via:
- `emergency.cured_emergency_patients` - Incremented when emergency patient cured
- `emergency.killed_emergency_patients` - Incremented when emergency patient dies
- `hospital.emergency_patients` - Array of active emergency patient entities

---

## 4. Timer Management

### 4.1 UIWatch Emergency Timer (dialogs/watch.lua:21-154)

```lua
-- Constants
local TICK_DAYS_EMERGENCY = 52      -- 52 in-game days total
local TIMER_SEGMENTS = 13           -- 13 visual segments

-- Emergency timer initialization
function UIWatch:UIWatch(ui, count_type)
  if count_type == "emergency" then
    self.tick_rate = math.floor((TICK_DAYS_EMERGENCY * Date.hoursPerDay()) / TIMER_SEGMENTS)
    self.tick_timer = self.tick_rate
  end
  self.open_timer = 12  -- Starts at segment 12 (13 segments: 0-12)
  self.count_type = "emergency"
end
```

### 4.2 Timer Mechanics

| Parameter | Value | Description |
|-----------|-------|-------------|
| Total Duration | 52 in-game days | ~2 months game time |
| Segments | 13 | Visual timer segments |
| Tick Rate | `(52 * hoursPerDay) / 13` | Hours per segment |
| Initial Segment | 12 | Counts down from 12 to 0 |

### 4.3 Timer Tick Logic (watch.lua:135-154)

```lua
function UIWatch:onWorldTick()
  if self.tick_timer == 0 and self.open_timer >= 0 then
    self.tick_timer = self.tick_rate
    self.open_timer = self.open_timer - 1
    
    -- Visual updates at specific segments
    if self.open_timer == 11 then
      self:addPanel(2, 2, 47)  -- Start animation
    elseif self.open_timer == 0 then
      self.panels[#self.panels].sprite_index = 0  -- Fully red
    elseif self.open_timer < 11 and self.open_timer > 0 then
      self.panels[#self.panels].sprite_index = 13 - self.open_timer
      if self.open_timer == 5 then
        table.remove(self.panels, #self.panels - 1)
      end
    end
  elseif self.open_timer == -1 then
    self:onCountdownEnd()  -- Timer expired
  else
    self.tick_timer = self.tick_timer - 1
  end
end
```

### 4.4 Timer Expiration

When `open_timer == -1`:
1. `onCountdownEnd()` called
2. Window closes
3. For emergency type: `self.ui.hospital:resolveEmergency()`

### 4.5 Early Timer End

`Hospital:checkEmergencyOver()` (hospital.lua:984-993) checks if all patients are cured/dead:

```lua
function Hospital:checkEmergencyOver()
  local killed = self.emergency.killed_emergency_patients
  local cured = self.emergency.cured_emergency_patients
  if killed + cured >= self.emergency.victims then
    local window = self.world.ui:getWindow(UIWatch)
    if window then
      window:onCountdownEnd()  -- Force timer end
    end
  end
end
```

This is called from:
- `Patient:cure()` (patient.lua:314-315) when emergency patient cured
- `Patient:goHome()` (patient.lua:566-567) when emergency patient leaves/dies

---

## 5. Fax System

### 5.1 Fax Flow

```
Emergency Scheduled
       │
       ▼
World:onEndDay() detects date
       │
       ▼
Hospital:createEmergency() creates emergency table
       │
       ▼
Hospital:makeEmergencyStartFax() queues fax message
       │
       ▼
Player sees fax in bottom panel
       │
       ├── Accept ──► Helicopter spawned + UIWatch emergency timer started
       │
       └── Refuse ──► World:nextEmergency() schedules next
```

### 5.2 Start Fax (player_hospital.lua:653-705)

```lua
function PlayerHospital:makeEmergencyStartFax()
  -- Check treatment room availability
  local no_rooms = #self.emergency.disease.treatment_rooms
  local room_name, required_staff, staff_name = ...
  
  -- Check if final treatment room exists
  if self:countRoomOfType(self.emergency.disease.treatment_rooms[no_rooms], 1) > 0 then
    room_name = nil  -- Room available
  end
  
  -- Check staff availability
  local staff_available = self:countStaffOfCategory(required_staff) > 0
  
  -- Build message based on capabilities
  local added_info = ...
  if room_name and staff_available then
    added_info = _S.fax.emergency.cure_not_possible_build:format(room_name)
  elseif room_name and not staff_available then
    added_info = _S.fax.emergency.cure_not_possible_build_and_employ:format(room_name, staff_name)
  elseif not staff_available then
    added_info = _S.fax.emergency.cure_not_possible_employ:format(staff_name)
  else
    added_info = _S.fax.emergency.cure_possible
  end
  
  -- Queue message with 16-day auto-refuse timeout
  self.world.ui.bottom_panel:queueMessage("emergency", message, nil, 
    Date.hoursPerDay() * 16, 2)
end
```

### 5.3 Start Fax Message Components

| Component | Source | Description |
|-----------|--------|-------------|
| Location | `_S.fax.emergency.locations[math.random(1,9)]` | Random location name |
| Victim Count | `_S.fax.emergency.num_disease` or `num_disease_singular` | Disease name + count |
| Treatment Info | Dynamic based on room/staff | Can/cannot treat info |
| Bonus | `_S.fax.emergency.bonus:format(bonus * victims)` | Total potential bonus |
| Choices | Accept / Refuse | Auto-refuses after 16 days |

### 5.4 End Fax (player_hospital.lua:708-718)

```lua
function PlayerHospital:makeEmergencyEndFax(rescued_patients, total, max_bonus, earned)
  local message = {
    {text = _S.fax.emergency_result.saved_people:format(rescued_patients, total)},
    {text = self.world.free_build_mode and "" or 
      _S.fax.emergency_result.earned_money:format(max_bonus, earned)},
    choices = {
      {text = _S.fax.emergency_result.close_text, choice = "close"},
    },
  }
  self.world.ui.bottom_panel:queueMessage("report", message, nil, 
    Date.hoursPerDay() * 25, 1)
end
```

### 5.5 Fax Cancellation

If fax is cancelled (bottom_panel.lua:535-543):

```lua
function UIBottomPanel:cancelFax(fax_type)
  if fax_type == "emergency" then
    self.world:nextEmergency()  -- Schedule next emergency
  end
end
```

---

## 6. Helicopter Spawning

### 6.1 Helicopter Object (objects/helicopter.lua:21-107)

```lua
class "Helicopter" (Object)

function Helicopter:Helicopter(hospital, object_type, direction, etc)
  local x, y = hospital:getHeliportPosition()
  y = y + 1  -- Land below tile
  self:Object(hospital, object_type, x, y, direction, etc)
  self.th:makeInvisible()
  self:setPosition(0, -600)  -- Start off-screen (above)
  self.phase = -120
  self.hospital = hospital
  hospital.emergency_patients = {}  -- Reset patient array
end
```

### 6.2 Helicopter Phases (tick function)

| Phase | Action |
|-------|--------|
| 0 | Make visible, start descending (speed 0, 10), play emergency sound |
| 60 | Stop (speed 0, 0), reset `spawned_patients = 0`, adviser speaks |
| 85 | Spawn patient if `spawned_patients < victims`, reset phase to 60 |
| 87 | Start ascending (speed 0, -10) |
| 147 | Destroy helicopter entity |

### 6.3 Patient Spawning (helicopter.lua:85-107)

```lua
function Helicopter:spawnPatient()
  local hospital = self.hospital
  self.spawned_patients = self.spawned_patients + 1
  
  local patient = self.world:newEntity("Patient", 2, 1)
  patient:setDisease(hospital.emergency.disease)
  patient.diagnosis_progress = 1  -- Pre-diagnosed
  patient.is_emergency = self.spawned_patients  -- Mark as emergency patient
  patient:setDiagnosed()
  patient:setMood("emergency", "activate")
  hospital.emergency_patients[self.spawned_patients] = patient
  
  local x, y = hospital:getHeliportSpawnPosition()
  patient:setNextAction(SpawnAction("spawn", {x = x, y = y}):setOffset({y = 1}))
  patient:setHospital(hospital)
  
  -- Skip all but last treatment room
  patient.cure_rooms_visited = #patient.disease.treatment_rooms - 1
  
  -- Check if patient agrees to pay
  if not patient:agreesToPay(patient.disease.id) then
    patient:goHome("over_priced", patient.disease.id)
  else
    patient:queueAction(SeekRoomAction(patient.disease.treatment_rooms[#patient.disease.treatment_rooms]))
  end
end
```

### 6.4 Emergency Patient Properties

| Property | Value | Purpose |
|----------|-------|---------|
| `is_emergency` | Patient number (1..victims) | Identifies emergency patients |
| `diagnosis_progress` | 1 | Pre-diagnosed (skip GP) |
| `cure_rooms_visited` | `#treatment_rooms - 1` | Only needs final treatment room |
| `disease` | Emergency disease | Specific disease for this emergency |

### 6.5 Helicopter Spawning Trigger

From fax.lua:185-187:
```lua
elseif choice == "accept_emergency" then
  self.ui.app.world:newObject("helicopter", "north")
  self.ui:addWindow(UIWatch(self.ui, "emergency"))
```

---

## 7. Code Examples

### 7.1 Creating an Emergency Manually

```lua
-- Cheat/debug function to create emergency
function createTestEmergency(hospital)
  local disease = TheApp.diseases["bloaty_head"]
  local emergency = {
    disease = disease,
    victims = 10,
    bonus = 1000,
    percentage = 0.75,
    killed_emergency_patients = 0,
    cured_emergency_patients = 0,
  }
  return hospital:createEmergency(emergency)
end
```

### 7.2 Checking Emergency Status

```lua
function getEmergencyStatus(hospital)
  if not hospital.emergency then
    return "No active emergency"
  end
  
  local e = hospital.emergency
  local cured = e.cured_emergency_patients
  local killed = e.killed_emergency_patients
  local total = e.victims
  local remaining = total - cured - killed
  local success_rate = cured / total
  
  return string.format(
    "Emergency: %s | Victims: %d | Cured: %d | Killed: %d | Remaining: %d | Rate: %.1f%% | Target: %.0f%%",
    e.disease.name, total, cured, killed, remaining, success_rate * 100, e.percentage * 100
  )
end
```

### 7.3 Scheduling Next Emergency (World)

```lua
-- Force schedule next emergency immediately
function forceNextEmergency(world)
  world.next_emergency_month = world.game_date:monthOfGame()
  world.next_emergency_day = world.game_date:dayOfMonth() + 1
  world:onEndDay()  -- Will trigger emergency creation
end
```

### 7.4 Emergency Timer Access

```lua
-- Get remaining emergency time
function getEmergencyTimeRemaining(ui)
  local watch = ui:getWindow(UIWatch)
  if watch and watch.count_type == "emergency" then
    local segments_left = watch.open_timer + 1  -- 0-12
    local hours_per_segment = watch.tick_rate
    local hours_left = segments_left * hours_per_segment
    return math.floor(hours_left / 24) .. " days"
  end
  return "No emergency timer"
end
```

---

## 8. Key File References

| File | Key Functions/Lines |
|------|---------------------|
| `Lua/hospital.lua` | `createEmergency` (925), `resolveEmergency` (955), `checkEmergencyOver` (984), `makeEmergencyStartFax` (2413), `makeEmergencyEndFax` (2417) |
| `Lua/hospitals/player_hospital.lua` | `makeEmergencyStartFax` (653), `makeEmergencyEndFax` (708) |
| `Lua/objects/helicopter.lua` | `Helicopter:Helicopter` (46), `Helicopter:tick` (59), `Helicopter:spawnPatient` (85) |
| `Lua/world.lua` | `nextEmergency` (1250), `scheduleRandomEmergency` (1286), `onEndDay` emergency check (1080) |
| `Lua/dialogs/watch.lua` | `UIWatch:UIWatch` (33), `onCountdownEnd` (114), `onWorldTick` (135) |
| `Lua/dialogs/fullscreen/fax.lua` | `accept_emergency` handling (185), `refuse_emergency` handling (188) |
| `Lua/dialogs/bottom_panel.lua` | `cancelFax` emergency handling (540) |
| `Lua/entities/humanoids/patient.lua` | `checkEmergencyOver` calls at cure (314), despawn (566) |

---

## 9. Summary of Key Constants

| Constant | Value | Location |
|----------|-------|----------|
| Default Bonus | 1000 | hospital.lua:935 |
| Success Percentage | 0.75 (75%) | hospital.lua:936 |
| Emergency Timer Days | 52 | watch.lua:29 |
| Timer Segments | 13 | watch.lua:30 |
| Start Fax Auto-Refuse | 16 days | player_hospital.lua:704 |
| End Fax Display Time | 25 days | player_hospital.lua:717 |
| Random Emergency Mean | 180 days | world.lua:1288 |
| Random Emergency Variance | 30 days | world.lua:1289 |

---

## 10. Integration Points

The emergency system integrates with:
- **Level Configuration**: `map.level_config.emergency_control` defines schedule
- **Disease System**: Diseases define `emergency_number`, `emergency_sound`, `treatment_rooms`
- **Reputation System**: `changeReputation("emergency_success"/"emergency_failed")`
- **Finance System**: `receiveMoney(earned, _S.transactions.emergency_bonus)`
- **UI System**: Bottom panel fax queue, UIWatch timer window
- **Object System**: Helicopter object spawns patients
- **Patient System**: Emergency patients marked with `is_emergency`, pre-diagnosed

---

*Document generated from CorsixTH source code analysis. All file paths and line numbers refer to the analyzed codebase at /tmp/CorsixTH/*


## Related Pages

- [[10-emergency-system/CHECKLIST]]
- [[10-emergency-system/MAP]]
- [[10-emergency-system/SCAFFOLD]]
