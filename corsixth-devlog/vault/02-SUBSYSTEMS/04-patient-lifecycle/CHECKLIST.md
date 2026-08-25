# Patient Lifecycle Changes - Pre-Fix Checklist

Use this checklist before making any changes to patient lifecycle code to ensure safety and completeness.

---

## 🔴 CRITICAL - Must Verify Before Any Change

### State Machine Integrity
- [ ] All state transitions have explicit guards (no implicit fallthrough)
- [ ] `going_home`, `going_to_die`, `dead`, `cured` are mutually exclusive where required
- [ ] `set_to_die` only triggers `die()` when patient is truly free (not in room, not entering/leaving)
- [ ] `goHome()` called at most once per patient (guard at line 511)
- [ ] `die()` early-returns if `cured` (line 373)

### Data Consistency
- [ ] `hospital:removePatient()` called exactly once on despawn
- [ ] `hospital.patients` array stays in sync with patient lifecycle
- [ ] `treatment_history` appended correctly for UI
- [ ] `diagnosis_progress` never exceeds `stop_procedure` policy
- [ ] `cure_rooms_visited` matches `treatment_rooms` array indices

### Money & Reputation
- [ ] `receiveMoneyForTreatment()` called for every room visit (diagnosis + treatment)
- [ ] Insurance patients add to `insurance_balance` (not direct money)
- [ ] Direct pay patients call `computePriceLevelImpact()` for reputation/happiness
- [ ] `paySupplierForDrug()` called on treatment completion
- [ ] Reputation changes: cured=+1, death=-4, kicked=-3, over_priced=-2

---

## 🟠 HIGH - Core Logic Changes

### Diagnosis System
- [ ] `completeDiagnosticStep()` uses correct formula: base + bonus * multiplier
- [ ] Doctor skill ≥ 0.9 gets consultant multiplier (1-5x)
- [ ] Fatigue > 0.5 reduces diagnosis bonus
- [ ] `attention_to_detail` and `skill` both factor in (divided by 1-3 random)
- [ ] GP room correctly routes: diagnose → more diagnosis OR diagnosed → treatment
- [ ] `available_diagnosis_rooms` properly filtered when disease changes (epidemic)
- [ ] `setDiagnosed()` called at correct threshold (policy OR no more rooms)

### Treatment System
- [ ] `isTreatmentEffective()` multiplies `cure_effectiveness * diagnosis_progress`
- [ ] Service quality impact: ±10% scaled by `(100 - cure_chance)` minimum 20
- [ ] Final treatment room triggers `treatDisease()` not another room seek
- [ ] `cure()` sets health=1, cured=true, infected=false
- [ ] `die()` calls `hospital:humanoidDeath()`, sets moods, queues DieAction

### Reception & Payment
- [ ] New patients pay for GP (`diag_gp`), redirected patients go to `next_room_to_visit`
- [ ] `agreesToPay()` uses exponential decay: `e^(-4 * overprice)`
- [ ] Overpriced at reception → `goHome("over_priced", "diag_gp")`
- [ ] Overpriced at GP → `goHome("over_priced", disease.id)`
- [ ] `pay_amount` cached when patient agrees, used in `receiveMoneyForTreatment`

---

## 🟡 MEDIUM - Daily Processing & Needs

### tickDay() Flow
- [ ] `_dailyWaitChecks()` decrements waiting, goes home at 0
- [ ] Waiting events at 10/20/30 days: tap_foot, yawn, check_watch
- [ ] `_dailyHealthChecks()` processes deterioration thresholds
- [ ] Health < 0.01 → `setToDying()` → die when free
- [ ] Fed up leave chance (1/30) at each threshold crossing
- [ ] `_dailyHealthHistoryRefresh()` maintains circular buffer (size 20)
- [ ] Object happiness effects when not in room
- [ ] Vomit chance: health ≤ 0.8 OR nearby vomit OR happiness < 0.6
- [ ] Daily attribute decay: health -0.004, thirst +, toilet_need +
- [ ] Thirst > 0.7 → seek drinks machine (60% litter after)
- [ ] Toilet need > 0.75 → 40% floor, 60% seek toilet

### State Persistence
- [ ] `afterLoad()` handles version migrations correctly
- [ ] `going_to_toilet` state restored properly
- [ ] Patient effect animation restored from disease
- [ ] Action queue walk/enter flags fixed for saves < v177

---

## 🟢 LOW - Edge Cases & Polish

### Epidemic / Infection
- [ ] `changeDisease()` preserves visited rooms, only adds new unvisited
- [ ] `needs_redirecting` flag handled at GP
- [ ] Vaccination status moods: epidemy1-4
- [ ] Infected patients can't be vaccinated twice

### Visual / Animation
- [ ] `th:setPatientEffect()` called on disease change and cure
- [ ] Mood markers: dying1-5, cured, dead, sad_money, exit
- [ ] Dynamic info text updates for all states
- [ ] Floating dollar sign on payment

### Performance
- [ ] `tick()` early returns when `going_to_die` or `going_home`
- [ ] `findObjectsInSquare` radius 2 for happiness effects
- [ ] Pathfinding cached in reception desk selection

---

## 📝 FILES TO REVIEW WHEN CHANGING

### Primary Files
| File | Key Functions | Risk Level |
|------|---------------|------------|
| `patient.lua` | All Patient methods | 🔴 Critical |
| `room.lua:192-237` | `Room:dealtWithPatient()` | 🔴 Critical |
| `rooms/gp.lua:112-183` | GP diagnosis routing | 🔴 Critical |
| `hospital.lua:1240-1266` | Money/insurance handling | 🔴 Critical |
| `hospital.lua:1420-1436` | Death recording | 🔴 Critical |

### Action Files
| File | Purpose | Risk Level |
|------|---------|------------|
| `humanoid_actions/seek_reception.lua` | Reception seeking | 🟠 High |
| `humanoid_actions/seek_room.lua` | Room seeking (diag/treatment) | 🟠 High |
| `humanoid_actions/die.lua` | Death animation | 🟡 Medium |
| `humanoid_actions/seek_toilets.lua` | Toilet seeking | 🟡 Medium |

### Disease & Room Definitions
| File | Purpose | Risk Level |
|------|---------|------------|
| `rooms/gp.lua` | GP room logic | 🔴 Critical |
| `rooms/*_diag.lua` | Diagnosis rooms | 🟠 High |
| `diseases/*.lua` | Disease definitions (treatment_rooms, diagnosis_rooms) | 🟠 High |

---

## ✅ TESTING REQUIREMENTS

### Unit Tests (run via busted)
- [ ] Spawn → Hospital → Reception flow
- [ ] Reception payment (base + overpriced)
- [ ] Diagnosis progress accumulation
- [ ] GP routing: more diag vs diagnosed
- [ ] Treatment room sequence
- [ ] Cure vs Death probability
- [ ] goHome() all reasons
- [ ] Insurance vs direct payment
- [ ] Daily health/thirst/toilet decay
- [ ] Death threshold triggers
- [ ] Epidemic disease change
- [ ] Edge cases (double goHome, cured+die, etc.)

### Integration Tests
- [ ] Full lifecycle: spawn → cure
- [ ] Full lifecycle: spawn → death
- [ ] Full lifecycle: spawn → kicked (no rooms)
- [ ] Full lifecycle: spawn → over_priced
- [ ] Emergency patient handling
- [ ] Epidemic infection → vaccination

### Manual Verification
- [ ] Patient UI shows correct dynamic info at each stage
- [ ] Reputation changes match expectations
- [ ] Hospital percentages update correctly
- [ ] Floating money appears on treatment
- [ ] Death animation plays (Grim Reaper)
- [ ] Advice messages for: kicked, over_priced, death, floor mess

---

## 🚨 REGRESSION RISKS - Watch For

| Change Area | Potential Regression |
|-------------|---------------------|
| Diagnosis progress formula | Patients never diagnose / instant diagnose |
| Cure chance calculation | 100% cure or 0% cure |
| Payment logic | Infinite money / no money / reputation broken |
| Health decay | Immortal patients / instant death |
| Room routing | Patients stuck / infinite loops |
| Insurance balance | Money never collected / double collected |
| State flags | Patients stuck in limbo / double despawn |
| Save/load | Corrupted patient state on load |

---

## 📋 CHANGE PROTOCOL

1. **Read** all related files (use MAP.md for line references)
2. **Write** failing test first (SCAFFOLD.lua)
3. **Implement** minimal change
4. **Run** full test suite
5. **Verify** manual playthrough for affected flow
6. **Update** documentation if behavior changes

---

*Checklist version: 1.0 | Based on CorsixTH patient.lua v1378, room.lua v1232, hospital.lua v2442*
