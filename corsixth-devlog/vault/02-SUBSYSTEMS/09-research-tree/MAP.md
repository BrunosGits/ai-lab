# CorsixTH Research Department — File:Line Index

**Primary File:** `/tmp/CorsixTH/CorsixTH/Lua/research_department.lua` (722 lines)
**Config File:** `/tmp/CorsixTH/CorsixTH/Lua/base_config.lua` (598 lines)
**Hospital File:** `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua` (2442 lines)

---

## ResearchDepartment Class Methods

| Method | Line Range | Description |
|--------|------------|-------------|
| `ResearchDepartment:ResearchDepartment(hospital)` | 37-46 | Constructor, initializes research_progress, calls initResearch |
| `ResearchDepartment:initResearch()` | 49-129 | **Core initialization** — sets up 5 categories, progress tracking, policy |
| `ResearchDepartment:checkAutomaticDiscovery(month)` | 131-141 | Auto-discovers objects when month >= WhenAvail |
| `ResearchDepartment:setResearchConcentration()` | 144-155 | Auto-concentrates on first available discovered disease |
| `ResearchDepartment:redistributeResearchPoints()` | 159-216 | Redistributes fractions when category finishes |
| `ResearchDepartment:nextResearch(category)` | 222-289 | **Auto-selection** — picks next target for category |
| `ResearchDepartment:getResearchRequired(thing)` | 297-328 | Returns research points needed for discovery/improvement |
| `ResearchDepartment:addResearchPointsForAutopsy(target_room_id)` | 332-355 | Adds research points from autopsy (33% of requirement) |
| `ResearchDepartment:addResearchPoints(points)` | 360-401 | **Main point distribution** — divides points per policy |
| `ResearchDepartment:improveDrug(drug)` | 406-477 | Improves drug effectiveness (+5) or cost (-10%) |
| `ResearchDepartment:improveMachine(machine)` | 482-527 | Alternates strength (+2) and cost (-12.5%) improvements |
| `ResearchDepartment:updateMachinesDynamicInfo(machine_id)` | 533-544 | Updates UI for improved machines in hospital |
| `ResearchDepartment:discoverObject(object, automatic)` | 552-598 | **Discovery** — marks object, unveils rooms, triggers next |
| `ResearchDepartment:discoverDisease(disease)` | 603-619 | Marks disease discovered, starts drug research, auto-concentrates |
| `ResearchDepartment:concentrateResearch(disease_id)` | 658-712 | **Player-directed focus** — sets specialisation target |
| `ResearchDepartment:researchCost()` | 625-647 | Calculates daily cost ($3/doctor/active%) |
| `ResearchDepartment:afterLoad(old, new)` | 714-722 | Save migration for versions < 238 |

---

## Key Data Structures

### `research_progress` (initialized in `initResearch`, lines 54-89)
```lua
-- For objects (machines)
research_progress[object] = {
  points = 0,              -- line 58
  start_strength = ...,    -- line 59 (from objects[].StartStrength)
  cost = ...,              -- line 60 (from objects[].StartCost, 0 if free_build)
  discovered = ...,        -- line 61 (from objects[].StartAvail == 1)
  strength_imp = 0,        -- line 62
  cost_imp = 0,            -- line 63
}

-- For drugs (diseases with drug)
research_progress[disease] = {
  points = 0,              -- line 81
  effect_imp = 1,          -- line 82
  cost_imp = 1,            -- line 83
}

-- Dummy for specialisation
research_progress[drain] = { points = 0 }  -- lines 92-93
```

### `research_policy` (initialized in `initResearch`, lines 96-124)
```lua
research_policy = {
  cure = { frac = 20/0, current = object/nil },           -- lines 97
  diagnosis = { frac = 20/0, current = object/nil },      -- line 98
  drugs = { frac = 20, points = 0, current = disease/drain },  -- line 99
  improvements = { frac = 20/0, points = 0, current = object/drain }, -- line 100
  specialisation = { frac = 20, points = 0, current = drain }, -- line 101
  total = 80/100/0,                                       -- line 108/122
}
```

---

## Configuration References (base_config.lua)

### `gbv` Table (lines 56-150)
| Key | Line | Value | Used In |
|-----|------|-------|---------|
| `ResearchPointsDivisor` | 70 | 5 | `addResearchPoints` (366) |
| `MaxObjectStrength` | 92 | 20 | `nextResearch` (245), `improveMachine` (504), `discoverObject` (576) |
| `ResearchIncrement` | 94 | 2 | `improveMachine` (517) |
| `DrugImproveRate` | 120 | 5 | `improveDrug` (440) |
| `MinDrugCost` | 76 | 50 | `improveDrug` (409, 434) |
| `RschImproveCostPercent` | 139 | 10 | `getResearchRequired` (318) |
| `RschImproveIncrementPercent` | 141 | 10 | `getResearchRequired` (320) |
| `AutopsyRschPercent` | 112 | 33 | `addResearchPointsForAutopsy` (345) |
| `StartRating` | 72 | 100 | Initial drug effectiveness |
| `StartCost` | 74 | 100 | Initial drug cost |

### `expertise` Table (lines 172-219)
| Index | Expertise ID | RschReqd | Category |
|-------|--------------|----------|----------|
| 0 | GENERAL_PRACTICE | 0 | - |
| 1 | BLOATY_HEAD | 40000 | Cure |
| 2 | HAIRYITUS | 40000 | Cure |
| 3 | ELVIS | 60000 | Cure |
| 4 | INVIS | 60000 | Cure |
| 5 | RADIATION | 60000 | Cure |
| 6 | SLACK_TONGUE | 40000 | Cure |
| 7 | ALIEN | 60000 | Cure |
| 8 | BROKEN_BONES | 20000 | Cure |
| 9 | BALDNESS | 40000 | Cure |
| 10 | DISCRETE_ITCHING | 40000 | Cure |
| 11 | JELLYITUS | 40000 | Cure |
| 12 | SLEEPING_ILLNESS | 40000 | Cure |
| 13 | PREGNANT | 5000 | Cure |
| 14 | TRANSPARENCY | 40000 | Cure |
| 15 | UNCOMMON_COLD | 20000 | Drug |
| 16 | BROKEN_WIND | 60000 | Drug |
| 17 | SPARE_RIBS | 20000 | Drug |
| 18 | KIDNEY_BEANS | 20000 | Drug |
| 19 | BROKEN_HEART | 20000 | Drug |
| 20 | RUPTURED_NODULES | 20000 | Drug |
| 21 | MULTIPLE_TV_PERSONALITIES | 40000 | Drug |
| 22 | INFECTIOUS_LAUGHTER | 60000 | Drug |
| 23 | CORRUGATED_ANKLES | 40000 | Drug |
| 24 | CHRONIC_NOSEHAIR | 40000 | Drug |
| 25 | 3RD_DEGREE_SIDEBURNS | 40000 | Drug |
| 26 | FAKE_BLOOD | 40000 | Drug |
| 27 | GASTRIC_EJECTIONS | 40000 | Drug |
| 28 | THE_SQUITS | 20000 | Drug |
| 29 | IRON_LUNGS | 20000 | Drug |
| 30 | SWEATY_PALMS | 40000 | Drug |
| 31 | HEAPED_PILES | 20000 | Drug |
| 32 | GUT_ROT | 20000 | Drug |
| 33 | GOLF_STONES | 20000 | Drug |
| 34 | UNEXPECTED_SWELLING | 20000 | Drug |
| 35 | I_D_SCANNER | 20000 | Diagnosis |
| 36 | I_D_BLOOD_MACHINE | 50000 | Diagnosis |
| 37 | I_D_CARDIO | 20000 | Diagnosis |
| 38 | I_D_XRAY | 30000 | Diagnosis |
| 39 | I_D_ULTRASCAN | 60000 | Diagnosis |
| 40 | I_D_STANDARD | 20000 | Diagnosis |
| 41 | I_D_WARD | 20000 | Diagnosis |
| 42 | I_D_SHRINK | 20000 | Diagnosis |
| 43 | I_X_RESEARCH | 15000 | Special (autopsy) |
| 44 | I_X_MIXER | 30000 | Special (atom analyser) |
| 45 | I_X_COMPUTER | 30000 | Special (research computer) |

### `objects` Table (lines 220-282)
| Thob | Object | StartCost | StartAvail | WhenAvail | StartStrength | AvailableForLevel | Research Category |
|------|--------|-----------|------------|-----------|---------------|-------------------|-------------------|
| 1 | Desk | 100 | 1 | 0 | 10 | 1 | - |
| 2 | Cabinet | 100 | 1 | 0 | 10 | 1 | - |
| 9 | Inflator | 2500 | 0 | 0 | 8 | 0 | cure |
| 13 | Cardiogram | 1000 | 0 | 0 | 13 | 0 | diagnosis |
| 14 | Scanner | 5000 | 0 | 0 | 12 | 0 | diagnosis |
| 22 | Ultrascan | 6000 | 0 | 0 | 9 | 0 | diagnosis |
| 23 | DNA Restorer | 10000 | 0 | 0 | 7 | 0 | cure |
| 24 | Cast Remover | 2000 | 0 | 0 | 11 | 0 | cure |
| 25 | Hair Restorer | 1000 | 0 | 0 | 8 | 0 | cure |
| 26 | Slicer | 1500 | 0 | 0 | 10 | 0 | cure |
| 27 | X-Ray | 4000 | 0 | 0 | 12 | 0 | diagnosis |
| 30 | Operating Table | 5000 | 0 | 0 | 10 | 0 | cure |
| 40 | Research Computer | 1000 | 0 | 0 | 10 | 0 | improvements |
| 41 | Chemical Mixer | 10000 | 0 | 0 | 10 | 0 | improvements |
| 42 | Blood Machine | 3000 | 0 | 0 | 10 | 0 | diagnosis |
| 46 | Electrolysis | 3500 | 0 | 0 | 8 | 0 | cure |
| 47 | Jelly Moulding | 6500 | 0 | 0 | 7 | 0 | cure |
| 54 | Decon Shower | 6500 | 0 | 0 | 10 | 0 | cure |
| 55 | Autopsy Research | 4000 | 0 | 0 | 10 | 0 | improvements |

---

## Hospital.lua References (lines 360-401)

| Line Range | Context |
|------------|---------|
| 360 | `EpidemicConcurrentLimit` from gbv |
| 363-365 | Version migration < 107 (reception_desks) |
| 367-371 | Version migration < 109 (price distortion thresholds) |
| 373-375 | Version migration < 111 (initial_grace) |
| 377-379 | Version migration < 114 (ratholes) |
| 381-384 | Version migration < 131 (autopsy_discovered, discover_autopsy_risk) |
| 386-390 | Version migration < 140 (reputation_above_threshold → has_impressive_reputation) |
| 392-400 | Version migration < 142 (disasterless_days, heating system) |

**Note:** Hospital.lua lines 360-401 contain only version migration code, not active research logic. The research-related hospital methods are elsewhere:
- `hospital:giveAdvice()` — called from research_department
- `hospital:adviseDiscoverDisease()` — called from `discoverDisease`
- `hospital:canConcentrateResearch()` — called from `concentrateResearch` and `setResearchConcentration`
- `hospital.disease_casebook` — accessed throughout research_department
- `hospital.room_discoveries` — accessed in `discoverObject`
- `hospital.acc_research_cost` — updated in `researchCost`

---

## Cross-Reference Map

### initResearch → calls/uses
- `TheApp.objects` iteration (54)
- `world.map.level_config.objects` (51)
- `hospital.disease_casebook` (78)
- Creates `drain` dummy (92-94)

### addResearchPoints → calls
- `getResearchRequired` (383)
- `discoverObject` (389)
- `improveDrug` (392)
- `improveMachine` (395)
- `nextResearch` (via category completion, 278)

### nextResearch → calls
- `redistributeResearchPoints` (278)
- `hospital:giveAdvice` (280)

### improveDrug → calls
- `decideImprovement` (412)
- `decreaseDrugCost` (433)
- `improveEffectiveness` (439)
- `decideNextResearch` (445) → `setResearchConcentration` (453), `nextResearch("drugs")` (458)
- `hospital:giveAdvice` (473, 475)

### improveMachine → calls
- `updateMachinesDynamicInfo` (522)
- `setResearchConcentration` (507)
- `nextResearch("improvements")` (513)
- `hospital:giveAdvice` (526)

### discoverObject → calls
- `hospital:giveAdvice` (570, 572)
- `nextResearch` (597) for object's category

### discoverDisease → calls
- `hospital:adviseDiscoverDisease` (607)
- `setResearchConcentration` (618)

### concentrateResearch → calls
- `hospital:canConcentrateResearch` (660)
- Sets `specialisation.current` (705, 709)

### researchCost → reads
- `hospital.acc_research_cost` (626)
- `world.rooms` for research room doctors (638-643)
- Writes `hospital.acc_research_cost` (646)

### getResearchRequired → reads
- `level_config.objects[thob].RschReqd` (304)
- `expertise[fallback].RschReqd` (312)
- `level_config.gbv` improvement params (318-320)
- `expertise[expertise_id].RschReqd` (325)

### redistributeResearchPoints → reads/writes
- `research_policy[].frac` (164, 180, 189, 202, 208)
- `research_policy.total` (170, 183, 211)
- `specialisation_point` (162, 195, 211)

---

## Call Graph Summary

```
Game Loop (monthly)
  └─ checkAutomaticDiscovery(month)
      └─ discoverObject(object, true)
          ├─ Room unveiling check
          └─ nextResearch(category)

Game Loop (daily)
  └─ addResearchPoints(doctor_skill_total)
      ├─ Points distributed per policy.frac
      ├─ getResearchRequired(current_target)
      ├─ If threshold met:
      │   ├─ discoverObject()  → nextResearch()
      │   ├─ improveDrug()     → nextResearch("drugs")
      │   └─ improveMachine()  → nextResearch("improvements")
      └─ researchCost()

Player Action: Concentrate Research
  └─ concentrateResearch(disease_id)
      ├─ Finds treatment room & object
      ├─ Sets specialisation.current
      └─ Toggles off if same disease

Auto-Concentration
  └─ setResearchConcentration()
      └─ concentrateResearch(first_available_disease)

Category Completion
  └─ nextResearch() finds no target
      └─ redistributeResearchPoints()
          └─ Rebalances fractions
```

---

## Test Coverage Targets (from SCAFFOLD.lua)

| Test Suite | Methods Covered |
|------------|-----------------|
| Point Distribution | `initResearch`, `addResearchPoints`, `redistributeResearchPoints` |
| Auto-Selection | `nextResearch` (drugs, improvements, cure, diagnosis) |
| Drug Improvement | `improveDrug`, `decideImprovement`, `decreaseDrugCost`, `improveEffectiveness` |
| Machine Improvement | `improveMachine`, `updateMachinesDynamicInfo` |
| Object Discovery | `discoverObject`, `checkAutomaticDiscovery` |
| Concentrate Research | `concentrateResearch`, `setResearchConcentration` |
| Research Cost | `researchCost` |
| Requirements | `getResearchRequired` |
| Autopsy | `addResearchPointsForAutopsy` |
| Disease Discovery | `discoverDisease` |
| Edge Cases | `afterLoad`, empty research, missing configs |
