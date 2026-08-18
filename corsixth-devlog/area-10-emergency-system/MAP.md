# Emergency System - File:Line Index

Comprehensive mapping of all emergency-related methods, functions, and key code locations in CorsixTH.

---

## Hospital.lua (/tmp/CorsixTH/CorsixTH/Lua/hospital.lua)

| Line | Function | Description |
|------|----------|-------------|
| 925 | `Hospital:createEmergency(emergency)` | Main emergency creation. Validates heliport, reception, disease discovery. Creates emergency table with disease, victims, bonus=1000, percentage=0.75. Returns `"no_heliport"`, `"undiscovered_disease"`, or `nil` (success). |
| 955 | `Hospital:resolveEmergency()` | Called when timer expires or all patients cured/died. Calculates success (cured/victims >= 75%). Awards money (`bonus * cured`) + reputation on success. Calls `makeEmergencyEndFax()`, `changeReputation()`, `receiveMoney()`, `world:nextEmergency()`. |
| 984 | `Hospital:checkEmergencyOver()` | Checks if `killed + cured >= victims`. If true, finds UIWatch window and calls `onCountdownEnd()` to force timer end. Called from `Patient:cure()` and `Patient:goHome()`. |
| 2413 | `Hospital:makeEmergencyStartFax()` | **Stub** - Overridden by PlayerHospital. Empty base implementation. |
| 2417 | `Hospital:makeEmergencyEndFax(rescued, total, max_bonus, earned)` | **Stub** - Overridden by PlayerHospital. Empty base implementation. |

### Related Hospital Methods

| Line | Function | Description |
|------|----------|-------------|
| 398 | `boiler_countdown` | Boiler repair countdown (unrelated but similar pattern) |
| 1055 | `canCreateEmergency()` | Checks `not world.ui:getWindow(UIWatch)` and `not self.emergency` |

---

## Player_Hospital.lua (/tmp/CorsixTH/CorsixTH/Lua/hospitals/player_hospital.lua)

| Line | Function | Description |
|------|----------|-------------|
| 653 | `PlayerHospital:makeEmergencyStartFax()` | Builds start fax message. Checks final treatment room availability (`countRoomOfType`) and staff (`countStaffOfCategory`). Shows location, victim count, treatment feasibility, bonus. Queues with 16-day auto-refuse. |
| 708 | `PlayerHospital:makeEmergencyEndFax(rescued, total, max_bonus, earned)` | Builds end fax message. Shows saved count, earned/max bonus. Queues with 25-day display time. |
| 721 | `PlayerHospital:createVip()` | VIP fax (related system) |

### Fax Message Structure (Start)
```lua
{
  {text = location},                                    -- Random from 9 locations
  {text = victim_count_message},                       -- Singular/plural disease name
  {text = treatment_info},                             -- Can/cannot treat details
  {text = bonus_info},                                 -- Total potential bonus
  choices = {
    {text = "Accept", choice = "accept_emergency"},
    {text = "Refuse", choice = "refuse_emergency"},
  }
}
```

### Fax Message Structure (End)
```lua
{
  {text = "Saved X of Y people"},
  {text = "Earned $E of $M bonus"},
  choices = {{text = "Close", choice = "close"}}
}
```

---

## Helicopter.lua (/tmp/CorsixTH/CorsixTH/Lua/objects/helicopter.lua)

| Line | Function | Description |
|------|----------|-------------|
| 46 | `Helicopter:Helicopter(hospital, object_type, direction, etc)` | Constructor. Gets heliport position, starts at y=-600 (off-screen top), phase=-120. Initializes `hospital.emergency_patients = {}`. |
| 59 | `Helicopter:tick()` | Main phase machine. Increments `self.phase` each tick. |
| 85 | `Helicopter:spawnPatient()` | Creates emergency patient. Sets disease, diagnosis_progress=1, is_emergency=spawn_number. Adds to `hospital.emergency_patients`. Spawns at heliport. Sets `cure_rooms_visited = #treatment_rooms - 1`. Queues SeekRoomAction for final treatment room. |

### Helicopter Phase Timeline

| Phase | Action | Details |
|-------|--------|---------|
| -120 to -1 | Approach | Invisible, moving down from y=-600 |
| 0 | Land start | Visible, speed(0,10), plays `disease.emergency_sound` at Critical priority |
| 60 | Landed | Speed(0,0), `spawned_patients=0`, adviser says emergency line |
| 85 | Spawn patient | If `spawned_patients < victims`: `spawnPatient()`, phase=60 (loop) |
| 87 | Takeoff | Speed(0,-10) |
| 147 | Destroy | `world:destroyEntity(self)` |

### Emergency Patient Properties (set in spawnPatient)
| Property | Value | Source |
|----------|-------|--------|
| `disease` | `hospital.emergency.disease` | Emergency disease |
| `diagnosis_progress` | 1 | Pre-diagnosed |
| `is_emergency` | 1..victims | Sequential spawn number |
| `cure_rooms_visited` | `#treatment_rooms - 1` | Skip to final room |
| `mood` | "emergency" | Visual indicator (blue light) |

---

## World.lua (/tmp/CorsixTH/CorsixTH/Lua/world.lua)

| Line | Function | Description |
|------|----------|-------------|
| 145 | `World:init()` → `self:nextEmergency()` | Initial emergency scheduling on world creation |
| 1053 | `World:onEndDay()` | Daily check for emergency date match |
| 1080 | Emergency trigger check | `if game_date:monthOfGame() == next_emergency_month and dayOfMonth == next_emergency_day` |
| 1083 | Watch window check | Postpones if `ui:getWindow(UIWatch)` exists |
| 1092 | Random emergency creation | `local_hospital:createEmergency()` for Mean/Variance levels |
| 1107 | Controlled emergency creation | Builds emergency table from config: disease, victims (Min-Max), bonus, percentage (PercWin/100) |
| 1115 | `local_hospital:createEmergency(emergency)` | Passes pre-built emergency table |
| 1250 | `World:nextEmergency()` | Main scheduling function. Handles Random vs Controlled. |
| 1286 | `World:scheduleRandomEmergency(control)` | Schedules using normal distribution: `math.n_random(mean, variance)` |
| 1304 | `World:computeNextEmergencyDates(emergency)` | Calculates valid month/day within StartMonth-EndMonth range |
| 1046 | `World:wasEmergencySkipped(prev, new)` | Detects missed emergencies during time jumps |
| 1026 | `World:setEndMonth()` | Checks `wasEmergencySkipped` on cheat |
| 1037 | `World:setEndYear()` | Checks `wasEmergencySkipped` on cheat |

### Emergency Control Config Structure
```lua
emergency_control = {
  [0] = { Random = bool, Mean = int, Variance = int },
  [1] = { StartMonth = int, EndMonth = int, Illness = "disease_id", Min = int, Max = int, Bonus = int, PercWin = int },
  [2] = { ... },
  ...
}
```

---

## Watch.lua (/tmp/CorsixTH/CorsixTH/Lua/dialogs/watch.lua)

| Line | Function | Description |
|------|----------|-------------|
| 28 | `TICK_DAYS_EMERGENCY = 52` | Emergency timer duration (in-game days) |
| 30 | `TIMER_SEGMENTS = 13` | Visual segments |
| 33 | `UIWatch:UIWatch(ui, count_type)` | Constructor. For "emergency": `tick_rate = (52 * hoursPerDay) / 13`, `open_timer = 12` |
| 114 | `UIWatch:onCountdownEnd()` | Closes window. For emergency: calls `ui.hospital:resolveEmergency()` |
| 135 | `UIWatch:onWorldTick()` | Decrements `tick_timer`. When 0: decrements `open_timer`, updates visual. When `open_timer == -1`: calls `onCountdownEnd()` |
| 166 | `UIWatch:cycleTimerEventPatient()` | Click timer: cycles through `hospital.emergency_patients`, opens UIPatient |
| 196 | `UIWatch:scrollToTimerEventPatient()` | Scrolls screen to current cycled patient |

### Timer Math
- `hoursPerDay` = 24 (from Date)
- `tick_rate` = `(52 * 24) / 13` = 96 hours per segment = 4 days per segment
- Total: 13 segments × 4 days = 52 days
- `open_timer`: 12 → 11 → ... → 0 → -1 (14 states including start/end)

---

## Fax.lua (/tmp/CorsixTH/CorsixTH/Lua/dialogs/fullscreen/fax.lua)

| Line | Function | Description |
|------|----------|-------------|
| 185 | `choice == "accept_emergency"` | Spawns helicopter: `world:newObject("helicopter", "north")`, creates UIWatch emergency timer |
| 189 | `choice == "refuse_emergency"` | Calls `world:nextEmergency()` |
| 183 | Cheat code "112" | Plays random announcement (European emergency number easter egg) |

---

## Bottom_Panel.lua (/tmp/CorsixTH/CorsixTH/Lua/dialogs/bottom_panel.lua)

| Line | Function | Description |
|------|----------|-------------|
| 535 | `UIBottomPanel:cancelFax(fax_type)` | Handles fax dismissal. For "emergency": calls `world:nextEmergency()` |
| 540 | Emergency cancel | Schedules next emergency when start fax is cancelled/auto-refused |

---

## Patient.lua (/tmp/CorsixTH/CorsixTH/Lua/entities/humanoids/patient.lua)

| Line | Function | Description |
|------|----------|-------------|
| 314 | `Patient:cure()` → `checkEmergencyOver()` | After curing, if `is_emergency`: calls `hospital:checkEmergencyOver()` |
| 566 | `Patient:goHome()` → `checkEmergencyOver()` | When emergency patient leaves, calls `checkEmergencyOver()` |
| 591 | `Patient:setToDying()` | Called by `resolveEmergency()` on remaining patients |
| 315 | `hospital:checkEmergencyOver()` | Increments `cured_emergency_patients` before calling |

### Emergency Patient Flags
| Flag | Set By | Checked In |
|------|--------|------------|
| `is_emergency` | `Helicopter:spawnPatient()` | `Patient:cure()`, `Patient:goHome()` |
| `diagnosis_progress = 1` | `spawnPatient()` | Pre-diagnosed |
| `cure_rooms_visited` | `spawnPatient()` | Skip GP/diagnosis rooms |

---

## Game_UI.lua (/tmp/CorsixTH/CorsixTH/Lua/game_ui.lua)

| Line | Function | Description |
|------|----------|-------------|
| 730 | `TheApp.ui:getWindow(UIWatch)` | Accesses emergency timer window |
| 1147 | `addWindow(UIWatch("initial_opening"))` | Initial hospital opening timer |

---

## Language Files (Localization Keys)

### English.lua (/tmp/CorsixTH/CorsixTH/Lua/languages/english.lua)

| Line | Key | Description |
|------|-----|-------------|
| 39 | `fax.emergency.cure_not_possible_build` | "You will need to build a %s" |
| 40 | `fax.emergency.cure_not_possible_build_and_employ` | "You will need to build a %s and employ a %s" |
| 41 | `fax.emergency.num_disease` | "There are %d people with %s and they require immediate attention." |
| 329 | `emergency` | Fax message table |
| 364 | `cant_treat_emergency` | "Your hospital cannot treat this emergency..." |
| 927 | Cheat tooltip | "Did you try to enter the European emergency number (112)..." |
| 939 | Adviser tip | "Emergencies can be a good source for some extra cash..." |

### Fax Emergency Keys
```lua
fax.emergency = {
  location = "Emergency at %s",
  locations = { "location1", ..., "location9" },
  num_disease_singular = "There is 1 person with %s...",
  num_disease = "There are %d people with %s...",
  cure_possible = "We can treat this disease.",
  cure_possible_drug_name_efficiency = "We can treat %s with %d%% effectiveness.",
  cure_not_possible_build = "You will need to build a %s",
  cure_not_possible_build_and_employ = "You will need to build a %s and employ a %s",
  cure_not_possible_employ = "You will need to employ a %s",
  bonus = "The emergency services will pay $%d for each patient cured.",
  free_build = "Free build mode: no bonus.",
  choices = { accept = "Accept", refuse = "Refuse" },
}
fax.emergency_result = {
  saved_people = "We saved %d out of %d people.",
  earned_money = "Maximum bonus: $%d. Earned: $%d.",
  close_text = "Close",
}
```

---

## Disease Files (Lua/diseases/*.lua)

Each disease defines:

| Property | Example (Bloaty Head) | Purpose |
|----------|----------------------|---------|
| `emergency_number` | 18 | Max victims for this disease |
| `emergency_sound` | "emerg007.wav" | Sound on helicopter arrival |
| `treatment_rooms` | {"gp", "diagnosis", "treatment"} | Required rooms (last = emergency target) |
| `only_emergency` | false (Alien DNA: true) | Only available via emergency |

### Diseases with Emergency Properties
| Disease | emergency_number | emergency_sound | only_emergency |
|---------|-----------------|-----------------|----------------|
| Bloaty Head | 18 | emerg007.wav | false |
| The Squits | 18 | emerg002.wav | false |
| TV Personalities | 14 | emerg003.wav | false |
| Uncommon Cold | 18 | emerg004.wav | false |
| Slack Tongue | 18 | emerg011.wav | false |
| Discrete Itching | 15 | emerg013.wav | false |
| Sweaty Palms | 14 | emerg017.wav | false |
| Gut Rot | 14 | emerg019.wav | false |
| Alien DNA | 16 | emerg020.wav | **true** |
| Pregnant | 8 | emerg021.wav | false |
| Fake Blood | 18 | emerg031.wav | false |

---

## Call Graph Summary

```
World:onEndDay()
  └─> Date match → Hospital:createEmergency()
        ├─> Validates heliport + reception + disease discovered
        ├─> Creates emergency table
        ├─> Hospital:makeEmergencyStartFax() → BottomPanel:queueMessage()
        └─> Returns

Player accepts fax (Fax.lua)
  └─> World:newObject("helicopter") → Helicopter:Helicopter()
        └─> UI:addWindow(UIWatch("emergency")) → UIWatch:UIWatch()

UIWatch:onWorldTick() (every game tick)
  └─> Decrements timer → onCountdownEnd() at 0
        └─> Hospital:resolveEmergency()
              ├─> Sets remaining patients dying
              ├─> Calculates success (cured/victims >= 75%)
              ├─> Awards money + reputation
              ├─> Hospital:makeEmergencyEndFax()
              └─> World:nextEmergency()

Helicopter:tick() (every game tick)
  └─> Phase machine → spawnPatient() at phase 85
        └─> Creates Patient with is_emergency, pre-diagnosed, seeks final room

Patient:cure() / :goHome() / :die()
  └─> Increments cured/killed counters
  └─> Hospital:checkEmergencyOver()
        └─> If all done → UIWatch:onCountdownEnd() → resolveEmergency()
```

---

## Quick Reference: Key Constants

| Constant | Value | File:Line |
|----------|-------|-----------|
| DEFAULT_BONUS | 1000 | hospital.lua:935 |
| SUCCESS_PERCENTAGE | 0.75 | hospital.lua:936 |
| TICK_DAYS_EMERGENCY | 52 | watch.lua:29 |
| TIMER_SEGMENTS | 13 | watch.lua:30 |
| START_FAX_TIMEOUT_DAYS | 16 | player_hospital.lua:704 |
| END_FAX_DISPLAY_DAYS | 25 | player_hospital.lua:717 |
| RANDOM_EMERGENCY_MEAN | 180 | world.lua:1288 |
| RANDOM_EMERGENCY_VARIANCE | 30 | world.lua:1289 |

---

*Generated from CorsixTH source at /tmp/CorsixTH/*
*Last updated: Analysis of commit HEAD*
