# Emergency System - Pre-Fix Checklist

This checklist must be completed before making any changes to the Emergency System in CorsixTH.

---

## 🔴 CRITICAL - Must Verify Before Any Changes

### 1. Requirements Validation
- [ ] **Heliport check**: `Hospital:getHeliportSpawnPosition()` returns valid coordinates
- [ ] **Reception desk check**: `Hospital:hasReceptionDesk(true)` returns true (built + staffed)
- [ ] **Disease discovered**: `disease_casebook[disease.id].discovered` is true
- [ ] **Available diseases**: `world.available_diseases` not empty

### 2. Data Integrity
- [ ] Emergency table structure preserved:
  - `disease` (Disease object)
  - `victims` (number, 2 to disease.emergency_number)
  - `bonus` (number, default 1000)
  - `percentage` (number, default 0.75)
  - `killed_emergency_patients` (number, starts 0)
  - `cured_emergency_patients` (number, starts 0)
- [ ] No mutation of original disease objects
- [ ] Patient `is_emergency` field set to sequential number (1..victims)

### 3. Timer System
- [ ] UIWatch emergency timer: 52 days / 13 segments = 4 days per segment
- [ ] `tick_rate` = `(52 * Date.hoursPerDay()) / 13`
- [ ] `open_timer` starts at 12, counts down to -1
- [ ] `onCountdownEnd()` calls `hospital:resolveEmergency()`
- [ ] Early termination via `checkEmergencyOver()` works

---

## 🟠 HIGH - Core Functionality

### 4. Emergency Creation
- [ ] Random disease selection from `world.available_diseases`
- [ ] Random victim count: `math.random(2, disease.emergency_number)`
- [ ] Scheduled emergencies use level config `emergency_control`
- [ ] Random emergencies use Mean/Variance (default 180/30 days)
- [ ] Proper error returns: `"no_heliport"`, `"undiscovered_disease"`, `nil` (success)
- [ ] `world:nextEmergency()` called after creation (success or refuse)

### 5. Emergency Resolution
- [ ] Success formula: `cured_patients / total_victims >= percentage`
- [ ] Money reward: `bonus * cured_patients` (only on success)
- [ ] Reputation: `emergency_success` vs `emergency_failed`
- [ ] Remaining patients set to dying via `setToDying()`
- [ ] `world:nextEmergency()` called after resolution
- [ ] Max bonus calculation: `bonus * victims`

### 6. Patient Spawning (Helicopter)
- [ ] Helicopter phases: -120 → 0 (descend) → 60 (land) → 85 (spawn) → 87 (ascend) → 147 (destroy)
- [ ] Spawns one patient per 25-phase cycle at phase 85
- [ ] Patients pre-diagnosed (`diagnosis_progress = 1`)
- [ ] Patients skip to final treatment room (`cure_rooms_visited = #treatment_rooms - 1`)
- [ ] Emergency sound played at phase 0
- [ ] Adviser announcement at phase 60

### 7. Fax System
- [ ] Start fax queued with 16-day auto-refuse timeout
- [ ] Start fax shows: location, victim count, treatment availability, bonus, accept/refuse
- [ ] End fax shows: saved count, earned/max bonus, close button
- [ ] Auto-refuse triggers `world:nextEmergency()`
- [ ] Refuse button triggers `world:nextEmergency()`
- [ ] Accept button spawns helicopter + UIWatch

---

## 🟡 MEDIUM - Edge Cases & Integration

### 8. Level Configuration
- [ ] Controlled emergencies: `emergency_control` array with StartMonth/EndMonth/Illness/Min/Max/Bonus/PercWin
- [ ] Random emergencies: `emergency_control[0].Mean` and `.Variance`
- [ ] Missing emergency[5] handling (Level 3 quirk)
- [ ] `computeNextEmergencyDates()` validates date not in past

### 9. Date/Time Handling
- [ ] `onEndDay()` checks month/day match for emergencies
- [ ] `wasEmergencySkipped()` handles time jumps (cheats/speed)
- [ ] `setEndMonth()` / `setEndYear()` check for skipped emergencies
- [ ] Auto-refuse timeout uses `Date.hoursPerDay() * 16`

### 10. Patient Lifecycle
- [ ] `Patient:cure()` increments `cured_emergency_patients` + calls `checkEmergencyOver()`
- [ ] `Patient:goHome()` calls `checkEmergencyOver()` for emergency patients
- [ ] `Patient:die()` increments `killed_emergency_patients` + calls `checkEmergencyOver()`
- [ ] Emergency patients marked with `is_emergency` number
- [ ] Emergency patients have blue blinking light (UI)

### 11. Multiplayer Considerations
- [ ] Emergency creation only for local player hospital (TODO in code)
- [ ] Reputation changes affect correct hospital
- [ ] Money transactions go to correct hospital

---

## 🟢 LOW - Polish & UX

### 12. UI/UX
- [ ] UIWatch timer visible during emergency
- [ ] Timer clicks cycle through emergency patients
- [ ] Timer hover shows tooltip
- [ ] Emergency patients have blue light above head
- [ ] Adviser says emergency line on helicopter landing
- [ ] Start fax shows correct room/staff requirements

### 13. Localization
- [ ] All fax texts use `_S.fax.emergency.*` keys
- [ ] Emergency sounds: `emerg001.wav` through `emerg031.wav`
- [ ] Disease names in faxes use localized disease names

### 14. Cheat Codes
- [ ] Fax code "112" plays random announcement (European emergency number easter egg)
- [ ] Debug cheat "Create Emergency" works

---

## 🧪 TESTING REQUIREMENTS

### Unit Tests (Busted)
- [ ] `test/emergency_creation_spec.lua` - Creation with various conditions
- [ ] `test/emergency_resolution_spec.lua` - Success/failure scenarios
- [ ] `test/emergency_timer_spec.lua` - Timer tick, early end, expiry
- [ ] `test/emergency_helicopter_spec.lua` - Spawning phases, patient properties
- [ ] `test/emergency_fax_spec.lua` - Start/end fax content, choices
- [ ] `test/emergency_scheduling_spec.lua` - World scheduling, random/controlled

### Integration Tests
- [ ] Full emergency flow: scheduled date → fax → accept → helicopter → patients → cure → resolve
- [ ] Refuse flow: fax → refuse → next emergency scheduled
- [ ] Auto-refuse flow: fax → timeout → next emergency scheduled
- [ ] Early end: cure all patients before timer → timer ends early
- [ ] Failure: timer expires with < 75% cured → no money, rep loss

### Regression Tests
- [ ] Level 1: First emergency works
- [ ] Level with controlled emergencies: correct disease/date
- [ ] Level with random emergencies: proper distribution
- [ ] Alien DNA emergency (only_emergency = true)
- [ ] Multiplayer: only local hospital gets emergency

---

## 📝 CHANGE DOCUMENTATION

For any fix, document:

| Field | Required |
|-------|----------|
| Issue/Feature | Yes |
| Files Modified | Yes |
| Lines Changed | Yes |
| Test Added/Updated | Yes |
| Config Changes | If applicable |
| Localization Updates | If applicable |
| Savegame Compatibility | Yes/No + migration if needed |

---

## ⚠️ KNOWN ISSUES / TODOs (From Code)

1. **hospital.lua:957** - TODO: "If new combined diseases are added this will not work correctly anymore" (cure_rooms_visited)
2. **hospital.lua:979** - `world:nextEmergency()` called after resolution
3. **player_hospital.lua:656** - TODO: "Make it work for all kinds of lists of treatment rooms"
4. **player_hospital.lua:657** - TODO: "Change to make use of Hospital:checkDiseaseRequirements"
5. **world.lua:1090** - TODO: "Do it only for the player hospital for now. TODO: Multiplayer"
6. **helicopter.lua:55** - TODO: "Shadow: 3918"
7. **helicopter.lua:98** - TODO: "If new combined diseases are added this will not work correctly anymore"
8. **watch.lua:22** - Comment: "The timer lasts approximately 100 days" but emergency is 52 days

---

## 🔍 CODE REVIEW CHECKLIST

Before merging any emergency system changes:

- [ ] All checklist items above verified
- [ ] No hardcoded values (use constants/config)
- [ ] Error handling for nil cases
- [ ] No memory leaks (tables properly cleared)
- [ ] Save/load compatibility maintained
- [ ] No performance regression (timer tick is per world tick)
- [ ] Multiplayer-safe (or documented as single-player only)
- [ ] Localization keys exist for all new strings

---

## 📁 FILES TO REVIEW

| File | Purpose |
|------|---------|
| `Lua/hospital.lua:925-993` | Core emergency logic |
| `Lua/hospitals/player_hospital.lua:653-718` | Fax implementation |
| `Lua/objects/helicopter.lua` | Helicopter + patient spawning |
| `Lua/world.lua:1080-1120, 1250-1321` | Scheduling & triggering |
| `Lua/dialogs/watch.lua` | Timer UI & logic |
| `Lua/dialogs/fullscreen/fax.lua:185-190` | Fax choice handling |
| `Lua/dialogs/bottom_panel.lua:535-543` | Fax cancellation |
| `Lua/entities/humanoids/patient.lua:314, 566` | Patient cure/death integration |

---

*Checklist version: 1.0*
*Based on CorsixTH source analysis at /tmp/CorsixTH/*
