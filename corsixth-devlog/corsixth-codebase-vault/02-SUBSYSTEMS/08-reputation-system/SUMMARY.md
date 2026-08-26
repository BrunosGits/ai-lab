# CorsixTH Reputation System - Deep Research Summary

## Overview

The reputation system in CorsixTH is a core gameplay mechanic that tracks the hospital's standing in the community. Reputation ranges from **0 to 1000**, with **500** as the neutral midpoint. It affects patient arrival rates, treatment pricing, emergency outcomes, and trophy eligibility.

---

## 1. Reputation Changes Table

Defined in `[[Lua/hospital.lua#L1606]]-1615` as the `reputation_changes` table:

| Reason | Value | Description | Trigger Location |
|--------|-------|-------------|------------------|
| `cured` | **+1** | Patient successfully treated | `hospital.lua:1707` - `updateCuredCounts()` |
| `death` | **-4** | Patient died from bad treatment/waiting | `hospital.lua:1430` - patient death |
| `kicked` | **-3** | Staff fired OR patient sent home early | `staff.lua:252` (staff), `hospital.lua:1731` (patient) |
| `emergency_success` | **+15** | Emergency completed with enough rescued | `hospital.lua:973` - `endEmergency()` |
| `emergency_failed` | **-20** | Emergency failed (too few rescued) | `hospital.lua:976` - `endEmergency()` |
| `over_priced` | **-2** | Patient considers treatment too expensive | `hospital.lua:2254` - `computePriceLevelImpact()` |
| `under_priced` | **+1** | Patient considers treatment a bargain | `hospital.lua:2249` - `computePriceLevelImpact()` |
| `room_crash` | **-50** | Room explosion/crash | `room.lua:961` - `Room:crash()` |

### Special Reputation Changes (Variable Amounts)

| Reason | Calculation | Trigger Location |
|--------|-------------|------------------|
| `autopsy_discovered` | `floor(-reputation * percent/100)` or **-70** | `research.lua:180` - autopsy research completed |
| `year_end` | Variable (calculated in annual report) | `annual_report.lua:311` - `updateAwards()` |

**Note:** The `autopsy_discovered` penalty uses `level_config.gbv.AutopsyRepHitPercent` (default ~70% of current reputation).

---

## 2. Probability Gating System

### Core Logic: `isReputationChangeAllowed()` (hospital.lua:1667-1677)

```lua
function Hospital:isReputationChangeAllowed(amount)
  if (amount > 0 and self.reputation <= 500) or 
     (amount < 0 and self.reputation >= 500) or 
     (amount == 0) then
    return true  -- Always allowed: gains below 500, losses above 500
  else
    return math.random() <= self:getReputationChangeLikelihood()
  end
end
```

### Threshold Behavior at 500

| Current Reputation | Positive Changes | Negative Changes |
|-------------------|------------------|------------------|
| **≤ 500** | **Always applied** (100%) | Probabilistic |
| **≥ 500** | Probabilistic | **Always applied** (100%) |

This creates a **self-correcting mechanism** - reputation naturally gravitates toward 500.

### Likelihood Calculation: `getReputationChangeLikelihood()` (hospital.lua:1679-1701)

Quadratic function: `likelihood = 1 - (a * x² - b * x + c)`

**Coefficients:**
- `a = 0.000004008`
- `b = 0.004008`
- `c = 1`

**Key Points (x = reputation, y = refusal probability):**
- (0, 1) → 0% acceptance at reputation 0
- (500, 0) → 100% acceptance at reputation 500
- (1000, 1) → 0% acceptance at reputation 1000

**Acceptance Probability Table:**

| Reputation | Refusal Probability | Acceptance Probability |
|------------|---------------------|------------------------|
| 0 | 100% | **0%** |
| 100 | ~64% | **~36%** |
| 200 | ~36% | **~64%** |
| 300 | ~16% | **~84%** |
| 380 | ~20% | **~80%** |
| **500** | **0%** | **100%** |
| 620 | ~20% | **~80%** |
| 700 | ~16% | **~84%** |
| 800 | ~36% | **~64%** |
| 900 | ~64% | **~36%** |
| 1000 | 100% | **0%** |

**Effective Range (80%+ acceptance):** Reputation **380–720**

---

## 3. Price Level Impact on Happiness & Reputation

### Price Distortion Calculation (patient.lua:261-288)

```lua
function Patient:getPriceDistortion(casebook)
  local happiness_weight = 0.1
  local reputation_weight = 0.6
  local effectiveness_weight = 0.3

  local reputation = casebook.reputation or self.hospital.reputation
  local effectiveness = casebook.cure_effectiveness

  local expected_price_level = 
    0.1 * (happiness) +
    0.6 * (reputation / 1000) +
    0.3 * (effectiveness / 100)

  local price_level = ((casebook.price - 0.5) / 3) * 2  -- maps [0.5, 3.5] to [-0.33, 1.0]
  
  return price_level - expected_price_level  -- Range: [-1, 1]
end
```

**Factors:**
- **Reputation (60% weight):** Higher reputation → patients expect higher prices
- **Cure Effectiveness (30% weight):** Better cures → patients expect higher prices
- **Happiness (10% weight):** Happier patients → slightly higher price tolerance

### Thresholds by Difficulty (hospital.lua:94-100)

| Difficulty | Under-priced Threshold | Over-priced Threshold |
|------------|------------------------|----------------------|
| Easy (1) | -0.3 | 0.4 |
| Normal (2) | -0.4 | 0.3 |
| Hard (3) | -0.5 | 0.2 |

*Higher difficulty = stricter pricing expectations*

### Impact Application: `computePriceLevelImpact()` (hospital.lua:2241-2260)

```lua
function Hospital:computePriceLevelImpact(patient, casebook)
  local price_distortion = patient:getPriceDistortion(casebook)
  patient:changeAttribute("happiness", -(price_distortion / 2))
  
  if price_distortion < self.under_priced_threshold then
    if math.random(1, 100) == 1 then  -- 1% chance
      self:changeReputation("under_priced")  -- +1 reputation
    end
  elseif price_distortion > self.over_priced_threshold then
    if math.random(1, 100) == 1 then  -- 1% chance
      self:changeReputation("over_priced")  -- -2 reputation
    end
  elseif math.abs(price_distortion) <= 0.15 and math.random(1, 200) == 1 then
    -- 0.5% chance for "fair price" advice
    self:advisePriceLevelImpact("fair", casebook.disease.name)
  end
end
```

### Effects Summary

| Price Distortion | Happiness Change | Reputation Chance | Reputation Change |
|------------------|------------------|-------------------|-------------------|
| `< under_threshold` (underpriced) | `+(|distortion|/2)` | 1% per payment | **+1** |
| `> over_threshold` (overpriced) | `-(distortion/2)` | 1% per payment | **-2** |
| `|distortion| ≤ 0.15` (fair) | Minimal | 0.5% per payment | Advice only |

**Called from:** `hospital.lua:1260` in `receiveMoneyForTreatment()` when patient pays.

---

## 4. Epidemic Reputation Outcomes

### Epidemic Configuration (epidemic.lua:83-85)

```lua
self.reputation_loss_minimum = level_config.gbv.EpidemicRepLossMinimum or 5
self.evacuation_minimum = level_config.gbv.EpidemicEvacMinimum or 20
```

### Outcome Determination: `determineFaxAndFines()` (epidemic.lua:439-485)

| Still Infected | Outcome | Fine | Reputation Hit |
|----------------|---------|------|----------------|
| **0** | **Success** | Compensation ($1,000–5,000) | **None** (gain money) |
| **< 5** AND **< 20** | Minor Failure | Fine only | `fine / 100` |
| **≥ 5** AND **< 20** | Major Failure | Fine + Rep Loss | `fine / 100` |
| **≥ 20** | **Evacuation** | Fine + Evacuation | **reputation × 1/3** (33%) |

### Reputation Hit Calculation

```lua
-- Base reputation from fine (epidemic.lua:364-366)
local function getBaseReputationFromFine(fine_amount)
  return math.round(fine_amount / 100)
end

-- Cover-up fine calculation (epidemic.lua:352-356)
function Epidemic:calculateInfectedFine(infected_count)
  local fine_per_infected = level_config.gbv.EpidemicFine or 2000
  return math.max(2000, infected_count * fine_per_infected)
end
```

### Application: `applyOutcome()` (epidemic.lua:489-508)

```lua
function Epidemic:applyOutcome()
  if self.compensation == 0 then  -- Failed epidemic
    if self.will_be_evacuated then
      self.reputation_hit = math.round(self.hospital.reputation * (1/3))
      self:evacuateHospital()
    else
      self.reputation_hit = getBaseReputationFromFine(self.coverup_fine)
    end
    self.hospital:spendMoney(self.coverup_fine, ...)
    self.hospital.reputation = self.hospital.reputation - self.reputation_hit
  else  -- Success
    self.hospital:receiveMoney(self.compensation, ...)
  end
end
```

### Epidemic Reputation Scenarios

| Scenario | Infected Remaining | Fine | Reputation Loss |
|----------|-------------------|------|-----------------|
| Perfect containment | 0 | N/A (gain $1K-5K) | **0** (gain money) |
| Few escapees | 3 | $6,000+ | **~60** (6000/100) |
| Moderate outbreak | 10 | $20,000+ | **~200** |
| Catastrophe (evacuation) | 25+ | $50,000+ | **~333** (at 1000 rep) |

### Declaration vs Cover-up

- **Declare immediately:** Fine = `declare_fine`, Rep hit = `fine/100`, no evacuation risk
- **Cover-up attempt:** Risk of evacuation (33% rep loss) but chance of success (money gain)

---

## 5. Reputation Bounds & Clamping

### Hard Limits (hospital.lua:87-89)

```lua
self.reputation_min = 0
self.reputation_max = 1000
self.reputation = math.min(math.max(reputation, self.reputation_min), self.reputation_max)
```

### In `unconditionalChangeReputation()` (hospital.lua:1646-1665)

```lua
function Hospital:unconditionalChangeReputation(valueChange)
  self.reputation = self.reputation + valueChange
  if self.reputation < self.reputation_min then
    self.reputation = self.reputation_min
  elseif self.reputation > self.reputation_max then
    self.reputation = self.reputation_max
  end
  -- Trophy check...
end
```

---

## 6. Reputation's Downstream Effects

### Patient Spawn Rate (world.lua:1227-1239)

```lua
function World:computeReputationImpact(hospital)
  -- Linear relationship
  -- 1% at rep < 253
  -- 60% at rep = 400
  -- 100% at rep = 500 (baseline)
  -- 140% at rep = 600
  -- 180% at rep = 700
  -- 300% at rep = 1000
  return 1 + ((hospital.reputation - 500) / 250)
end
```

**Impact Multiplier Table:**

| Reputation | Spawn Rate Multiplier |
|------------|----------------------|
| 0 | 1% |
| 250 | 0% (no patients) |
| 400 | 60% |
| **500** | **100%** (baseline) |
| 600 | 140% |
| 700 | 180% |
| 1000 | 300% |

### Treatment Pricing (hospital.lua:1277-1285)

```lua
local reputation = self.disease_casebook[disease].reputation or self.reputation
if reputation >= 500 then
  return math.ceil(raw_price * (reputation / 500) * percentage)
end
return math.ceil(raw_price * percentage)  -- No bonus below 500
```

- **Reputation ≥ 500:** Price multiplier = `reputation / 500` (up to 2.0x at 1000)
- **Reputation < 500:** No price bonus (base price only)

### Salary Negotiations (hospital.lua:817-820)

```lua
local sal_mult = (self.reputation - 500) / (self.num_deaths + 1)
```

Higher reputation → staff demand higher wages (mitigated by low deaths).

### Trophy Eligibility (hospital.lua:1655-1663)

```lua
if self.has_impressive_reputation then
  local min_reputation = level_config.awards_trophies.Reputation
  self.has_impressive_reputation = min_reputation < self.reputation
end
```

---

## 7. Disease-Specific Reputation

Each disease has its own reputation meter in `disease_casebook`:

```lua
casebook.reputation = casebook.reputation + amount  -- hospital.lua:1638
```

Used for:
- Price expectation calculation (patient.lua:275)
- Treatment effectiveness tracking
- Per-disease pricing

---

## 8. Code Examples

### Applying Reputation Change (Standard Path)

```lua
-- In Hospital class
function Hospital:updateCuredCounts(patient)
  if not patient.is_debug then
    self:changeReputation("cured", patient.disease)  -- +1, goes through probability gate
  end
end
```

### Direct Reputation Change (Bypassing Probability)

```lua
-- In Hospital class
function Hospital:unconditionalChangeReputation(valueChange)
  self.reputation = self.reputation + valueChange
  -- Clamping + trophy check
end

-- Usage: epidemics, cheats, year-end
self.hospital.reputation = self.hospital.reputation - self.reputation_hit  -- epidemic.lua:500
```

### Probability Gate Check

```lua
-- In Hospital:changeReputation()
local amount = reputation_changes[reason]  -- or custom value
if self:isReputationChangeAllowed(amount) then
  self:unconditionalChangeReputation(amount)
end
-- Disease reputation still updated even if gated!
if disease then
  casebook.reputation = casebook.reputation + amount
end
```

**Critical Note:** Disease-specific reputation is **always updated**, even when global reputation change is gated!

---

## 9. Key Files & Line References

| File | Lines | Content |
|------|-------|---------|
| `hospital.lua` | 1606-1615 | `reputation_changes` table |
| `hospital.lua` | 1617-1640 | `changeReputation()` |
| `hospital.lua` | 1642-1665 | `unconditionalChangeReputation()` |
| `hospital.lua` | 1667-1677 | `isReputationChangeAllowed()` |
| `hospital.lua` | 1679-1701 | `getReputationChangeLikelihood()` |
| `hospital.lua` | 2241-2260 | `computePriceLevelImpact()` |
| `hospital.lua` | 94-100 | Difficulty pricing thresholds |
| `hospital.lua` | 972-977 | Emergency reputation |
| `hospital.lua` | 1703-1708 | Cured reputation |
| `hospital.lua` | 1724-1744 | Kicked/overpriced reputation |
| `hospital.lua` | 1430 | Death reputation |
| `epidemic.lua` | 439-508 | Epidemic outcomes |
| `epidemic.lua` | 364-366 | `getBaseReputationFromFine()` |
| `patient.lua` | 261-288 | `getPriceDistortion()` |
| `staff.lua` | 252 | Staff fired reputation |
| `room.lua` | 961 | Room crash reputation |
| `research.lua` | 180 | Autopsy discovered reputation |
| `annual_report.lua` | 311 | Year-end reputation |
| `world.lua` | 1227-1239 | Spawn rate impact |

---

## 10. Summary of Key Mechanics

1. **Self-correcting at 500:** Gains below 500 always apply; losses above 500 always apply
2. **Quadratic probability gate:** Smooth curve, 100% at 500, 0% at extremes
3. **Disease reputation always updates:** Even when global change is gated
4. **Price distortion affects happiness continuously:** But reputation changes are rare (1% chance)
5. **Epidemics are high-stakes:** 33% reputation loss on evacuation
6. **Reputation drives economy:** Patient spawns, treatment prices, staff wages
7. **Room crash is catastrophic:** -50 reputation (5% of max) instant



## Related Pages

- [[08-reputation-system/CHECKLIST]]
- [[08-reputation-system/MAP]]
- [[08-reputation-system/SCAFFOLD]]
