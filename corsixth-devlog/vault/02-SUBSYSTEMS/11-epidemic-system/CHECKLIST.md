# Epidemic System - Pre-Fix Checklist

## Purpose
This checklist ensures all epidemic system changes are properly validated before implementation. Complete each section before committing changes.

---

## 1. Configuration Validation

### Level Config (gbv table)
- [ ] `ContagiousSpreadFactor` - Integer, range 1-100, default 25
- [ ] `EpidemicRepLossMinimum` - Integer, range 1-50, default 5
- [ ] `EpidemicEvacMinimum` - Integer, range 1-100, default 10
- [ ] `EpidemicFine` - Integer, minimum 100, default 2000
- [ ] `EpidemicCompLo` - Integer, minimum 0, default 1000
- [ ] `EpidemicCompHi` - Integer, >= EpidemicCompLo, default 5000
- [ ] `VacCost` - Integer, minimum 0, default 50
- [ ] `ReduceContMonths` - Integer, range 1-100, default 14
- [ ] `ReduceContPeepCount` - Integer, range 1-1000, default 20

### Expertise Config (per disease)
- [ ] `ContRate` - Integer, 0 = never contagious, 1 = always, N = 1/N chance

### Validation Rules
- [ ] `EpidemicEvacMinimum` > `EpidemicRepLossMinimum` (evacuation threshold higher than rep loss)
- [ ] `EpidemicCompHi` >= `EpidemicCompLo`
- [ ] `spread_scale_factor` (200) > `ContagiousSpreadFactor` (to avoid division issues)

---

## 2. Initialization Checks

### Epidemic Constructor
- [ ] Hospital reference stored correctly
- [ ] World reference stored correctly
- [ ] Initial patient added to `infected_patients`
- [ ] Initial patient marked `infected = true`
- [ ] `ready_to_reveal = false`
- [ ] `revealed = false`
- [ ] All financial trackers initialized to 0
- [ ] `will_be_evacuated = false`
- [ ] `coverup_selected = false`
- [ ] Timer fields nil/0
- [ ] `vaccination_mode_active = false`
- [ ] Infection counters at 0
- [ ] Config values loaded with fallbacks
- [ ] `markPatientsAsPassedReception()` called

### Patient Reception Marking
- [ ] All patients in hospital marked `has_passed_reception = true`
- [ ] Patients queuing at reception desks EXCLUDED
- [ ] Only patients inside hospital bounds (`isInHospital`) marked

---

## 3. Infection Mechanics Checks

### canInfectOther() Conditions
- [ ] Infector not cured
- [ ] Infector not vaccinated
- [ ] Both patients inside hospital bounds
- [ ] Victim not already infected/cured/vaccinated
- [ ] Victim not `under_infection_attempt`
- [ ] Victim not emergency
- [ ] Disease compatibility:
  - Same disease, OR
  - Victim's disease contagious AND not diagnosed
- [ ] Both patients in same room (`getRoom()` equal)

### Spread Formula
- [ ] `spread_scale_factor = 200` (constant)
- [ ] Target rate = `spread_factor / spread_scale_factor`
- [ ] Dynamic adjustment: `total_infections / attempted_infections < target_rate`
- [ ] `attempted_infections` incremented for each valid target
- [ ] `total_infections` incremented only on success

### Adjacent Detection
- [ ] Uses `entity_map:getPatientsInAdjacentSquares(x, y)`
- [ ] Checks 4 orthogonal directions only
- [ ] Does not infect through walls (room check)

---

## 4. Cover-Up Flow Checks

### startCoverUp()
- [ ] `UIWatch` timer created with type "epidemic"
- [ ] `countdown_intervals` captured from timer
- [ ] Timer added to UI
- [ ] `checkPatientsForRemoval()` called
- [ ] `coverup_selected = true`
- [ ] All infected patients: `updateDynamicInfo()` + `setInfectedStatus()`

### Vaccination Mode
- [ ] `toggleVaccinationMode()` flips boolean
- [ ] `_updateVaccinationCursor()` changes cursor:
  - Active: "epidemic_hover"
  - Inactive: "default"
- [ ] Cursor loaded via `world.ui.app.gfx:loadMainCursor()`

### Mark for Vaccination
- [ ] Only during cover-up (`coverup_selected`)
- [ ] Patient infected, not vaccinated, not already marked
- [ ] Calls `setToReadyForVaccinationStatus()`
- [ ] Plays "vaccin.wav" sound

### Vaccination Calls
- [ ] Only during active cover-up (`_isCoverUpActive()`)
- [ ] Patient `marked_for_vaccination = true`
- [ ] Patient not `reserved_for`
- [ ] Patient is static (`is_static()`):
  - Action: queue, idle, seek_room, OR use_object on bench
- [ ] Calls `dispatcher:callNurseForVaccination(patient)`

### Vaccination Execution
- [ ] Patient reserved for nurse
- [ ] Best tile calculated via `getBestVaccinationTile()`
- [ ] Bench patients: tile in front based on direction
- [ ] Non-bench: closest reachable adjacent tile
- [ ] If unreachable: nurse meanders, call kept open
- [ ] If reachable: nurse walks, queues `VaccinateAction(patient, fee)`
- [ ] Fee from config: `gbv.VacCost` or 50
- [ ] Vaccination takes 5 ticks (VaccinateAction)

### Early Termination
- [ ] `checkInfectedLeftHospital()`: uncured infected patient leaves hospital → `finishCoverUp()`
- [ ] `checkNoInfectedPatients()`: `countInfectedPatients() == 0` → `finishCoverUp()`
- [ ] Timer expiry: `coverUpTimeIsUp()` → `finishCoverUp()`

### finishCoverUp()
- [ ] Spawns inspector if not already spawned
- [ ] Closes timer
- [ ] Turns off vaccination mode

---

## 5. Outcome Determination Checks

### determineFaxAndFines(still_infected)
- [ ] `coverup_fine = calculateInfectedFine(still_infected)`
- [ ] **Case 0 infected**: 
  - `compensation = random(EpidemicCompLo, EpidemicCompHi)`
  - Success fax with compensation amount
- [ ] **Case < reputation_loss_minimum AND < evacuation_minimum**:
  - Fine only fax
  - `compensation = 0`
  - `will_be_evacuated = false`
- [ ] **Case >= reputation_loss_minimum AND < evacuation_minimum**:
  - Fine + rep loss fax
  - `compensation = 0`
  - `will_be_evacuated = false`
- [ ] **Case >= evacuation_minimum**:
  - `will_be_evacuated = true`
  - Evacuation fax
  - `compensation = 0`

### applyOutcome()
- [ ] **If compensation > 0** (success):
  - `hospital:receiveMoney(compensation, "compensation")`
- [ ] **If compensation == 0** (failure):
  - **If will_be_evacuated**:
    - `reputation_hit = round(reputation * 1/3)`
    - `evacuateHospital()`
  - **Else**:
    - `reputation_hit = round(coverup_fine / 100)`
  - `hospital:spendMoney(coverup_fine, "epidemy_coverup_fine")`
  - `hospital.reputation -= reputation_hit`
- [ ] Result fax sent via `sendResultFax()`
- [ ] End announcement played
- [ ] `hospital.epidemic = nil`

### Evacuation
- [ ] All patients with `has_passed_reception = true`
- [ ] Not `going_home` or `going_to_die`
- [ ] Calls `patient:goHome("evacuated")`

---

## 6. Fine Calculation Checks

### calculateInfectedFine(infected_count)
- [ ] Uses `gbv.EpidemicFine` or default 2000
- [ ] Formula: `max(2000, infected_count * fine_per_infected)`
- [ ] Minimum fine always 2000

### Reputation Calculation
- [ ] Base: `round(fine / 100)`
- [ ] Evacuation: `round(reputation * 1/3)`

### Declaration Path
- [ ] `resolveDeclaration()`:
  - Clears all infected patients
  - Spends `declare_fine` as "epidemy_fine"
  - Reputation hit = `round(declare_fine / 100)`
  - Sets `hospital.epidemic = nil`

---

## 7. Contagious Detection Checks (Hospital)

### determineIfContagious(patient)
- [ ] Returns false if `epidemics_disabled`
- [ ] Returns false if `patient.is_emergency`
- [ ] Returns false if `not patient.disease.contagious`
- [ ] Gets `ContRate` from expertise config
- [ ] Contagious if `math.random(1, ContRate) == ContRate` (1/ContRate chance)
- [ ] Late-game reduction:
  - Month > `ReduceContMonths` (default 14)
  - `num_visitors` > `ReduceContPeepCount` (default 20)
  - Both must be true to suppress

### addToEpidemic(patient)
- [ ] Adds to active epidemic if:
  - Active epidemic exists
  - Not in cover-up
  - Same disease
- [ ] Else tries future_epidemics_pool:
  - Matches disease
  - Not in cover-up
- [ ] Else creates new epidemic if under `concurrent_epidemic_limit`

---

## 8. UI & Messaging Checks

### Faxes
- [ ] Initial fax: declare vs cover-up choices
- [ ] Declare fine shown in initial fax
- [ ] Result fax: success (compensation) or failure (fine ± rep ± evacuation)
- [ ] All string keys exist in _S.fax.epidemic.*

### Announcements
- [ ] Start: random EPID001-004.wav
- [ ] End: random EPID005-008.wav
- [ ] Priority: Critical

### Advisor Messages
- [ ] Inspector arriving: `_A.information.epidemic_health_inspector`
- [ ] Hurry up (25% timer): `_A.epidemic.hurry_up`
- [ ] Serious warning (75% elapsed, >10 infected): `_A.epidemic.serious_warning`

### Sounds
- [ ] Mark for vaccination: "vaccin.wav"

---

## 9. Save/Load Compatibility

### afterLoad(old, new)
- [ ] Version < 106: `level_config = nil` (migrate to world.map.level_config)
- [ ] Version < 212: `coverup_selected = coverup_in_progress`, clear old field

---

## 10. Edge Cases & Error Handling

### Patient State
- [ ] Dead patients removed from epidemic
- [ ] Patients leaving hospital (going_home/going_to_die) removed if not in cover-up
- [ ] `tile_x == nil` patients removed

### Concurrency
- [ ] Multiple epidemics queued in `future_epidemics_pool`
- [ ] Only one active epidemic at a time
- [ ] Concurrent limit enforced

### Cheat Handling
- [ ] `cancelEpidemic()` cleans up:
  - Removes initial fax
  - Turns off vaccination mode
  - Closes timer
  - Sends inspector home
  - Clears all infected patients
  - Empties infected_patients array

### Inspector
- [ ] Spawned at random spawn point
- [ ] Seeks reception desk
- [ ] Announced when entering hospital
- [ ] Triggers `handleInspectorArrival()` on arrival

---

## 11. Testing Requirements

### Unit Tests (Busted)
- [ ] Epidemic initialization with defaults
- [ ] Epidemic initialization with custom config
- [ ] Infection spread: all canInfectOther conditions
- [ ] Spread formula with various ratios
- [ ] Cover-up start/stop
- [ ] Vaccination mode toggle
- [ ] Mark for vaccination
- [ ] Vaccination call generation
- [ ] Vaccination execution (reachable/unreachable)
- [ ] Best tile calculation (bench/non-bench)
- [ ] Outcome: 0 infected (compensation)
- [ ] Outcome: < rep minimum (fine only)
- [ ] Outcome: 5-9 infected (fine + rep)
- [ ] Outcome: 10+ infected (evacuation)
- [ ] Fine calculation with defaults
- [ ] Fine calculation with custom config
- [ ] Declaration path
- [ ] Contagious detection (all conditions)
- [ ] Late-game contagion reduction
- [ ] Early cover-up termination
- [ ] Patient removal edge cases
- [ ] Concurrent epidemic limit
- [ ] Advisor message triggers
- [ ] Save/load migration

### Integration Tests
- [ ] Full epidemic lifecycle: detect → reveal → cover-up → outcome
- [ ] Full epidemic lifecycle: detect → reveal → declare
- [ ] Multiple simultaneous epidemics (different diseases)
- [ ] Epidemic during earthquake/emergency
- [ ] Save/load mid-epidemic

---

## 12. Performance Considerations

- [ ] `infectOtherPatients()` only iterates infected patients
- [ ] Adjacent patient lookup uses entity_map (O(1) per patient)
- [ ] Infection attempt tracking prevents duplicate work
- [ ] Timer tick same rate as hospital (acceptable)
- [ ] No memory leaks in patient references

---

## 13. Documentation Updates

- [ ] Update any inline code comments
- [ ] Update CHANGELOG if user-facing changes
- [ ] Verify string table entries exist for new messages

---

## 14. Regression Checklist

After changes, verify:
- [ ] Existing levels still load
- [ ] Epidemic scenarios in campaigns work
- [ ] Sandbox mode epidemics work
- [ ] Multiplayer (if applicable) syncs epidemic state
- [ ] Cheat menu epidemic cancel works
- [ ] No Lua errors in logs during epidemic

---

## Sign-Off

| Check | Verified By | Date |
|-------|-------------|------|
| Config Validation | | |
| Initialization | | |
| Infection Mechanics | | |
| Cover-Up Flow | | |
| Outcomes | | |
| Fine Calculation | | |
| Contagious Detection | | |
| UI & Messaging | | |
| Save/Load | | |
| Edge Cases | | |
| Unit Tests Pass | | |
| Integration Tests Pass | | |
| Performance | | |
| Documentation | | |
| Regression | | |

**All checks passed:** ☐ Yes ☐ No

**Notes:**
