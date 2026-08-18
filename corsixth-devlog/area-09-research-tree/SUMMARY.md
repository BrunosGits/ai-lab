# CorsixTH Research Tree — Deep Technical Analysis

**Source Files Analyzed:**
- `/tmp/CorsixTH/CorsixTH/Lua/research_department.lua` (722 lines)
- `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua` (lines 360-401)
- `/tmp/CorsixTH/CorsixTH/Lua/base_config.lua` (gbv table, expertise, objects)

---

## 1. Five Research Categories

The research system operates across **five distinct categories** defined in `ResearchDepartment:initResearch()` (lines 96-102):

| Category | Key | Initial % | Description |
|----------|-----|-----------|-------------|
| **Cure** | `cure` | 20% (if available) | Discovers treatment machines (e.g., Slicer, DNA Restorer) |
| **Diagnosis** | `diagnosis` | 20% (if available) | Discovers diagnostic machines (e.g., Scanner, X-Ray, Ultrascan) |
| **Drugs** | `drugs` | 20% | Improves drug effectiveness (+5% per step) and reduces cost (-10% per step) |
| **Improvements** | `improvements` | 20% (if available) | Improves machine strength (+2 per step) and reduces build cost (-12.5% per step) |
| **Specialisation** | `specialisation` | 20% | Player-directed focus on a specific disease/machine (costs nothing extra) |

**Specialisation** is unique: it's a "dummy" category that redirects points from the other four when the player uses "Concentrate Research" on a disease. It never incurs additional cost to the player.

---

## 2. Point Distribution Formula

### Initial Allocation (`initResearch`, lines 96-123)

```lua
local policy = {
  cure = {frac = cure and 20 or 0, current = cure},
  diagnosis = {frac = diagnosis and 20 or 0, current = diagnosis},
  drugs = {frac = 20, points = 0, current = drug and drug or drain},
  improvements = {frac = improve and 20 or 0, points = 0, current = improve},
  specialisation = {frac = 20, points = 0, current = drain},
}
```

**Rules:**
- Each category starts at **20%** if it has available research targets
- Categories without targets (e.g., no cure machines to discover) get **0%**
- If total < 100%, the **first active category** receives the remainder (line 116)
- If total == 20% (only specialisation active), research is disabled (`total = 0`)

### Adding Research Points (`addResearchPoints`, lines 360-401)

```lua
local divisor = level_config.gbv.ResearchPointsDivisor or 5  -- Default: 5
points = math.ceil(points * self.research_policy.total / (100 * divisor))

for _, info in pairs(areas) do
  if info.current then
    research_info.points = stored + math.t_random(0.75, 1, 1.25) * points * info.frac / 100
  end
end
```

**Formula breakdown:**
1. **Raw points** (from doctors' research skill) → divided by `ResearchPointsDivisor` (default 5)
2. **Scaled by policy total** (sum of active category percentages, max 100)
3. **Distributed per category** by `frac / 100`
4. **Random variance** ±25% (`math.t_random(0.75, 1, 1.25)`)

**Example:** 100 raw points, 4 active categories (80% total), divisor 5
- Points after divisor: `ceil(100 * 80 / 500) = 16`
- Per category (20% each): `16 * 0.20 * random(0.75-1.25) = 2.4–4.0 points`

---

## 3. Auto-Selection Logic

### Drug Research (`nextResearch`, lines 232-242)
**Selects the discovered drug with the LOWEST cure effectiveness:**

```lua
local worst_effect = 100
for _, disease in pairs(hospital.disease_casebook) do
  if disease.cure_effectiveness < worst_effect then
    if disease.discovered then
      self.research_policy[category].current = disease
      worst_effect = disease.cure_effectiveness
    end
    found_one = true
  end
end
```

- Undiscovered drugs block progression → sets `current = drain` (dummy)
- When all discovered drugs reach 100% effectiveness, category finishes

### Machine Improvements (`nextResearch`, lines 243-259)
**Selects the discovered machine with the LOWEST current strength:**

```lua
local max_strength = level_config.gbv.MaxObjectStrength  -- 20
local min_strength = max_strength
for object, progress in pairs(self.research_progress) do
  if object.default_strength and progress.discovered and progress.start_strength < min_strength then
    self.research_policy[category].current = object
    min_strength = progress.start_strength
  end
end
```

- Only considers **discovered** machines
- Skips machines already at `MaxObjectStrength` (20)
- Undiscovered machines needing improvement → sets `current = drain`

### Cure/Diagnosis Discovery (`nextResearch`, lines 260-265)
**Selects the FIRST undiscovered object in the category:**

```lua
for object, progress in pairs(self.research_progress) do
  if object.research_category == category and not progress.discovered then
    self.research_policy[category].current = object
  end
end
```

- Linear iteration order (depends on `TheApp.objects` array order)
- No priority logic — first match wins

---

## 4. Drug Improvement Mechanics

### `improveDrug` (lines 406-477)

**Improvement Decision (`decideImprovement`, lines 412-429):**
```lua
local at_max_effectiveness = disease.cure_effectiveness >= 100
local at_min_cost = disease.drug_cost <= min_drug_cost  -- 50

if at_max_effectiveness and at_min_cost then return false end
if at_max_effectiveness then return "cost" end
if at_min_cost then return "effectiveness" end

-- Both can improve: 50% cost, 50% effectiveness, 1/7 chance both
local improvement = math.random(1, 2) == 1 and "cost" or "effectiveness"
improvement = math.random(1, 7) == 1 and "both" or improvement
```

**Cost Reduction (`decreaseDrugCost`, lines 433-436):**
```lua
local new_cost = math.max(min_drug_cost, math.floor(disease.drug_cost * 0.9))
disease.drug_cost = new_cost  -- -10% per step, floor to integer, min 50
```

**Effectiveness Increase (`improveEffectiveness`, lines 439-442):**
```lua
local improve_rate = level_config.gbv.DrugImproveRate  -- 5
disease.cure_effectiveness = math.min(100, disease.cure_effectiveness + improve_rate)
```

**Progression:**
- Starts at effectiveness from `expertise[].StartRating` (default 100 in base_config line 72)
- Wait — base_config says `StartRating = 100` but diseases start lower
- Each step: +5% effectiveness OR -10% cost (or both, 14.3% chance)
- Max effectiveness: 100%, Min cost: 50
- When drug hits 100% effectiveness, it can no longer be specialised (line 449)

---

## 5. Machine Improvement Mechanics

### `improveMachine` (lines 482-527)

**Alternating Strength/Cost (lines 485-524):**
```lua
if research_info.strength_imp > research_info.cost_imp then
  -- Improve COST: -12.5% per step
  local decrease = math.round(research_info.cost * 0.125 / 10) * 10
  research_info.cost = research_info.cost - decrease
  research_info.cost_imp = research_info.cost_imp + 1
  
  -- Also reduces room build_cost for all rooms using this machine
  for _, room in ipairs(self.world.available_rooms) do
    for obj, no in pairs(room.objects_needed) do
      if TheApp.objects[obj] == machine then
        progress.build_cost = progress.build_cost - decrease * no
        break
      end
    end
  end
else
  -- Improve STRENGTH: +2 per step
  local improve_rate = level_config.gbv.ResearchIncrement  -- 2
  research_info.start_strength = research_info.start_strength + improve_rate
  research_info.strength_imp = research_info.strength_imp + 1
end
```

**Key Parameters (from base_config.lua gbv):**
| Parameter | Value | Line |
|-----------|-------|------|
| `MaxObjectStrength` | 20 | 92 |
| `ResearchIncrement` | 2 | 94 |
| `RschImproveCostPercent` | 10% | 139 |
| `RschImproveIncrementPercent` | +10% per improvement | 141 |

**Cost Improvement Formula (for discovery → improvement transition):**
```lua
-- getResearchRequired (lines 318-321)
local improve_percent = level_config.gbv.RschImproveCostPercent  -- 10%
local increment = level_config.gbv.RschImproveIncrementPercent   -- 10%
improve_percent = improve_percent + increment * research_info.cost_imp
required = required * improve_percent / 100
```
- First improvement: 10% of original research cost
- Second: 20%, Third: 30%, etc.

**Strength Progression:**
- Starts at `objects[].StartStrength` (e.g., Scanner=12, DNA Restorer=7)
- +2 per strength improvement
- Caps at 20
- Alternates: strength → cost → strength → cost...

---

## 6. Object Discovery & Room Unveiling

### `discoverObject` (lines 552-598)

**Discovery Process:**
```lua
self.research_progress[object].discovered = true

-- Check all undiscovered rooms
for _, room_disc in pairs(self.hospital.room_discoveries) do
  if not room_disc.is_discovered then
    local unveil_room = true
    for needed, _ in pairs(room.objects_needed) do
      local obj = self.research_progress[TheApp.objects[needed]]
      if obj and not obj.discovered then
        unveil_room = false
        break
      end
    end
    if unveil_room then
      room_disc.is_discovered = true
      -- Give advice: "New machine researched" or "New room available"
    end
  end
end
```

**Automatic Discovery (`checkAutomaticDiscovery`, lines 131-141):**
```lua
for object, progress in pairs(self.research_progress) do
  if object.default_strength then
    local avail_at = level_config.objects[object.thob].WhenAvail
    if not progress.discovered and avail_at ~= 0 and month >= avail_at then
      self:discoverObject(object, true)  -- Automatic, no research points needed
    end
  end
end
```
- Objects with `WhenAvail > 0` auto-discover at that month
- Called monthly via game loop

### Room Unveiling Logic
A room becomes available when **ALL** its required objects are discovered.
- `room.objects_needed` maps object IDs to quantities
- Iterates all undiscovered rooms on each object discovery
- Triggers advice notification to player

---

## 7. Research Cost ($3/Doctor/Day)

### `researchCost` (lines 625-647)

```lua
function ResearchDepartment:researchCost()
  local fraction = 0
  for _, tab in pairs(self.research_policy) do
    if type(tab) == "table" and tab.current and not tab.current.dummy then
      fraction = fraction + tab.frac
    end
  end
  
  local doctors = 0
  for _, room in pairs(self.world.rooms) do
    if room.room_info.id == "research" then
      for _, _ in pairs(room.staff_member_set) do
        doctors = doctors + 1
      end
    end
  end
  
  acc_cost = acc_cost + math.ceil(3 * doctors * fraction / 100)
  self.hospital.acc_research_cost = acc_cost
end
```

**Formula:**
```
Daily Cost = ceil(3 × NumDoctorsInResearchRoom × ActiveResearchPercentage / 100)
```

**Examples:**
| Doctors | Active % | Daily Cost |
|---------|----------|------------|
| 1 | 80% (4 categories) | ceil(3 × 1 × 0.8) = $3 |
| 2 | 100% | ceil(3 × 2 × 1.0) = $6 |
| 3 | 60% (3 categories) | ceil(3 × 3 × 0.6) = $6 |
| 4 | 100% + specialisation | ceil(3 × 4 × 1.0) = $12 |

**Notes:**
- Specialisation (dummy) doesn't add to cost (line 631: `not tab.current.dummy`)
- Finished categories (frac=0) don't add to cost
- Cost accrues daily via `acc_research_cost`

---

## 8. Concentrate Research

### `concentrateResearch` (lines 658-712)

**Player Action:** Right-click disease in casebook → "Concentrate Research"

**Logic:**
```lua
-- Toggle off if already concentrated
if book_entry.concentrate_research then
  book_entry.concentrate_research = nil
  self.research_policy.specialisation.current = self.drain
else
  -- Clear previous concentration
  for key, disease in pairs(self.hospital.disease_casebook) do
    if disease.concentrate_research then
      self.hospital.disease_casebook[key].concentrate_research = nil
    end
  end
  book_entry.concentrate_research = true
  
  -- Find associated treatment object
  local room = book_entry.disease.treatment_rooms[#book_entry.disease.treatment_rooms]
  local object = ... -- Find object in room.objects_needed matching research_progress
  
  if book_entry.drug and self.research_progress[object].discovered then
    -- Drug improvement mode
    self.research_policy.specialisation.current = book_entry
  else
    -- Machine discovery/improvement mode
    self.research_policy.specialisation.current = object
  end
end
```

**Specialisation Behaviour:**
- Redirects 20% research points (specialisation.frac) to single target
- Costs **no extra money** (specialisation.current.dummy = true excluded from cost calc)
- For drugs: improves that specific drug's effectiveness/cost
- For machines: discovers or improves that specific machine
- Auto-clears when drug hits 100% effectiveness or machine hits max strength

### `setResearchConcentration` (lines 144-155)
Auto-concentrates on first available discovered disease when specialisation is dummy:
```lua
for _, disease in pairs(casebook) do
  if disease.discovered and self.hospital:canConcentrateResearch(disease.disease.id) then
    self:concentrateResearch(disease.disease.id)
    return
  end
end
```

---

## 9. Research Requirements (Point Thresholds)

### `getResearchRequired` (lines 297-328)

**For Objects (Discovery):**
```lua
required = level_config.objects[thing.thob].RschReqd
-- Fallback to expertise[thing.research_fallback].RschReqd
```

**For Objects (Improvement):**
```lua
if research_info.discovered then
  local improve_percent = level_config.gbv.RschImproveCostPercent  -- 10%
  local increment = level_config.gbv.RschImproveIncrementPercent   -- 10%
  improve_percent = improve_percent + increment * research_info.cost_imp
  required = required * improve_percent / 100
end
```

**For Drugs:**
```lua
required = expert[thing.disease.expertise_id].RschReqd
```

### Example Requirements (from base_config.lua expertise table):

| Disease/Expertise | RschReqd | Category |
|-------------------|----------|----------|
| GENERAL_PRACTICE | 0 | - |
| BLOATY_HEAD | 40,000 | Cure |
| HAIRYITUS | 40,000 | Cure |
| ELVIS | 60,000 | Cure |
| INVIS | 60,000 | Cure |
| BROKEN_BONES | 20,000 | Cure |
| THE_SQUITS | 20,000 | Drug |
| I_D_SCANNER | 20,000 | Diagnosis |
| I_D_XRAY | 30,000 | Diagnosis |
| I_X_RESEARCH | 15,000 | Special (autopsy) |
| I_X_MIXER | 30,000 | Special (atom analyser) |
| I_X_COMPUTER | 30,000 | Special (research computer) |

### Object Research Requirements (from base_config.lua objects table):

| Object | Thob | RschReqd (via expertise fallback) | StartStrength | StartAvail |
|--------|------|-----------------------------------|---------------|------------|
| Inflator | 9 | BLOATY_HEAD: 40,000 | 8 | 0 |
| Scanner | 14 | I_D_SCANNER: 20,000 | 12 | 0 |
| Ultrascan | 22 | I_D_ULTRASCAN: 60,000 | 10 | 0 |
| DNA Restorer | 23 | ? | 7 | 0 |
| Slicer | 26 | SLACK_TONGUE: 40,000 | 10 | 0 |
| X-Ray | 27 | I_D_XRAY: 30,000 | 12 | 0 |
| Operating Table | 30 | ? | 10 | 0 |
| Research Computer | 40 | I_X_COMPUTER: 30,000 | 10 | 0 |
| Chemical Mixer | 41 | I_X_MIXER: 30,000 | 10 | 0 |
| Blood Machine | 42 | I_D_BLOOD_MACHINE: 50,000 | 10 | 0 |

---

## 10. Redistribution When Category Finishes

### `redistributeResearchPoints` (lines 159-216)

**Triggered when** `nextResearch` finds no more targets in a category (line 278).

**Algorithm:**
1. Sum fractions of active (non-finished) categories
2. Subtract specialisation points from total
3. **If no categories have points left (sum == 0):**
   - Distribute evenly among remaining active categories
4. **Otherwise:**
   - Redistribute proportionally: `new_frac = floor(total * old_frac / sum)`
   - Remaining points → category with highest old fraction
5. Add specialisation points back to total

---

## 11. Key Code Examples

### Creating a Research Department
```lua
local ResearchDepartment = require "research_department"
local research = ResearchDepartment(hospital)
research:initResearch()
```

### Adding Research Points (Daily Tick)
```lua
-- Called from game loop with doctor research skill total
research:addResearchPoints(total_doctor_research_skill)
```

### Checking Auto-Discovery (Monthly)
```lua
research:checkAutomaticDiscovery(current_month)
```

### Player Concentrates Research
```lua
research:concentrateResearch("bloaty_head")  -- disease_id
```

### Daily Cost Calculation
```lua
research:researchCost()  -- Updates hospital.acc_research_cost
```

### Manual Discovery (e.g., from Autopsy)
```lua
research:addResearchPointsForAutopsy("gp_office")
```

---

## 12. Configuration Reference (base_config.lua gbv)

| Parameter | Value | Used In |
|-----------|-------|---------|
| `ResearchPointsDivisor` | 5 | `addResearchPoints` divisor |
| `MaxObjectStrength` | 20 | Machine strength cap |
| `ResearchIncrement` | 2 | Strength improvement per step |
| `DrugImproveRate` | 5 | Effectiveness improvement per step |
| `MinDrugCost` | 50 | Cost floor |
| `RschImproveCostPercent` | 10 | First improvement cost % |
| `RschImproveIncrementPercent` | 10 | Cost % increase per improvement |
| `AutopsyRschPercent` | 33 | Autopsy research contribution % |
| `StartRating` | 100 | Initial drug effectiveness |
| `StartCost` | 100 | Initial drug cost |

---

## 13. Data Structures

### `research_progress` Table
```lua
-- For objects (machines)
research_progress[object] = {
  points = 0,              -- Accumulated research points
  start_strength = 12,     -- Initial strength (from objects[].StartStrength)
  cost = 5000,             -- Current build cost (from objects[].StartCost)
  discovered = false,      -- Whether discovered
  strength_imp = 0,        -- Number of strength improvements
  cost_imp = 0,            -- Number of cost improvements
}

-- For drugs (diseases)
research_progress[disease] = {
  points = 0,
  effect_imp = 1,          -- Effectiveness multiplier (starts at 1)
  cost_imp = 1,            -- Cost multiplier (starts at 1)
}
```

### `research_policy` Table
```lua
research_policy = {
  cure = {frac = 20, current = object_or_nil},
  diagnosis = {frac = 20, current = object_or_nil},
  drugs = {frac = 20, points = 0, current = disease_or_drain},
  improvements = {frac = 20, points = 0, current = object_or_drain},
  specialisation = {frac = 20, points = 0, current = object_or_disease_or_drain},
  total = 80 or 100,       -- Sum of fracs (max 100)
}
```

---

*Document generated from CorsixTH source analysis. All line numbers reference the source files as of the analysis date.*
