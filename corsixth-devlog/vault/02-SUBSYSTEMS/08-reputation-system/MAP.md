# Reputation System - File:Line Index

Complete mapping of all reputation-related code in CorsixTH.

---

## hospital.lua

| Line Range | Function/Content | Description |
|------------|------------------|-------------|
| 32 | `local reputation` | Hospital initialization variable |
| 37 | `reputation = level_config.towns[level].StartRep` | Campaign start reputation from town |
| 42 | `reputation = level_config.town.StartRep` | Single town start reputation |
| 87 | `self.reputation_min = 0` | Minimum reputation bound |
| 88 | `self.reputation_max = 1000` | Maximum reputation bound |
| 89 | `self.reputation = math.min(math.max(reputation, self.reputation_min), self.reputation_max)` | Initial reputation clamping |
| 94-95 | `under_priced_thresholds = {-0.3, -0.4, -0.5}` / `self.under_priced_threshold = under_priced_thresholds[difficulty]` | Under-priced threshold by difficulty |
| 99-100 | `over_priced_thresholds = {0.4, 0.3, 0.2}` / `self.over_priced_threshold = over_priced_thresholds[difficulty]` | Over-priced threshold by difficulty |
| 140 | `reputation = self.reputation` | Annual report data collection |
| 151 | `reputation = self.reputation` | Hospital stats for UI |
| 158 | `self.has_impressive_reputation = true` | Initial trophy status |
| 159 | `self:unconditionalChangeReputation(0)` | Initialize trophy status |
| 240 | `reputation = not disease.pseudo and 500 or nil` | Disease casebook initial reputation |
| 369 | `self.under_priced_threshold = -0.4` | Default under-priced threshold (normal) |
| 370 | `self.over_priced_threshold = 0.3` | Default over-priced threshold (normal) |
| 387 | `self.has_impressive_reputation = self.reputation_above_threshold and true or false` | Restore trophy status on load |
| 388 | `self.reputation_above_threshold = nil` | Clean up temp variable |
| 389 | `self:unconditionalChangeReputation(0)` | Setup trophy status on load |
| 817 | `-- rate varies on some performance factors i.e. reputation above 500 increases the score` | Salary negotiation comment |
| 820 | `local sal_mult = (self.reputation - 500) / (self.num_deaths + 1)` | Salary multiplier formula |
| 857 | `reputation = self.reputation,` | Annual report data |
| 910 | `self.has_impressive_reputation = true` | New level trophy status reset |
| 911 | `self:unconditionalChangeReputation(0)` | New level trophy setup |
| 972-973 | `self:changeReputation("emergency_success", emer.disease)` | Emergency success reputation |
| 975-976 | `self:changeReputation("emergency_failed", emer.disease)` | Emergency failure reputation |
| 1259 | `-- under- or over-priced and it could impact happiness and reputation)` | Price impact comment |
| 1260 | `self:computePriceLevelImpact(patient, casebook)` | Called when patient pays |
| 1277-1285 | `local reputation = self.disease_casebook[disease].reputation or self.reputation` / `if reputation >= 500 then return math.ceil(raw_price * (reputation / 500) * percentage) end` | Treatment pricing with reputation |
| 1430 | `self:changeReputation("death", patient.disease)` | Patient death reputation |
| 1606-1615 | `local reputation_changes = { ["cured"]=1, ["death"]=-4, ["kicked"]=-3, ["emergency_success"]=15, ["emergency_failed"]=-20, ["over_priced"]=-2, ["under_priced"]=1, ["room_crash"]=-50 }` | **Core reputation changes table** |
| 1617-1640 | `function Hospital:changeReputation(reason, disease, valueChange)` | **Main reputation change entry point** |
| 1625-1627 | `if reason == "autopsy_discovered" then ... amount = rep_hit_perc and math.floor(-self.reputation * rep_hit_perc / 100) or -70` | Autopsy reputation calculation |
| 1628-1631 | `elseif valueChange then amount = valueChange else amount = reputation_changes[reason] end` | Variable vs table-based amounts |
| 1633-1635 | `if self:isReputationChangeAllowed(amount) then self:unconditionalChangeReputation(amount) end` | Probability gate check |
| 1636-1639 | `if disease then casebook.reputation = casebook.reputation + amount end` | **Disease reputation always updated** |
| 1642-1665 | `function Hospital:unconditionalChangeReputation(valueChange)` | **Direct reputation change (bypasses gate)** |
| 1647 | `self.reputation = self.reputation + valueChange` | Apply change |
| 1649-1653 | Clamping to [0, 1000] | Bounds enforcement |
| 1655-1663 | Trophy status check and update | Trophy eligibility |
| 1667-1677 | `function Hospital:isReputationChangeAllowed(amount)` | **Probability gate logic** |
| 1672 | `if (amount > 0 and self.reputation <= 500) or (amount < 0 and self.reputation >= 500) or (amount == 0) then return true` | 500 threshold logic |
| 1675 | `return math.random() <= self:getReputationChangeLikelihood()` | Probabilistic branch |
| 1679-1701 | `function Hospital:getReputationChangeLikelihood()` | **Quadratic likelihood function** |
| 1683-1692 | Quadratic function documentation and coefficients | Algorithm explanation |
| 1693-1695 | `local a = 0.000004008; local b = 0.004008; local c = 1` | Quadratic coefficients |
| 1697 | `local x = self.reputation` | Current reputation |
| 1700 | `return 1 - (a * x * x - b * x + c)` | Likelihood calculation |
| 1703-1708 | `function Hospital:updateCuredCounts(patient)` → `self:changeReputation("cured", patient.disease)` | Cured patient reputation |
| 1723-1744 | `function Hospital:updateNotCuredCounts(patient, reason)` → `self:changeReputation(reason, patient.disease)` | Kicked/overpriced reputation |
| 1731 | `self:changeReputation(reason, patient.disease)` | Called for "kicked" and "over_priced" |
| 2234-2260 | `function Hospital:computePriceLevelImpact(patient, casebook)` | **Price distortion → happiness & reputation** |
| 2242 | `local price_distortion = patient:getPriceDistortion(casebook)` | Get distortion value |
| 2243 | `patient:changeAttribute("happiness", -(price_distortion / 2))` | Happiness impact |
| 2244-2250 | Under-priced check (1% chance) → `changeReputation("under_priced")` | Under-priced reputation |
| 2251-2255 | Over-priced check (1% chance) → `changeReputation("over_priced")` | Over-priced reputation |
| 2256-2259 | Fair price advice (0.5% chance) | Advice only |

---

## epidemic.lua

| Line Range | Function/Content | Description |
|------------|------------------|-------------|
| 50 | `self.reputation_hit = 0` | Epidemic reputation hit storage |
| 83 | `-- How many people still infected and not cure causes the player to take a reputation hit as well as a fine` | Config comment |
| 85 | `self.reputation_loss_minimum = level_config.gbv.EpidemicRepLossMinimum or 5` | Min infected for rep loss |
| 86 | `self.evacuation_minimum = level_config.gbv.EpidemicEvacMinimum or 20` | Min infected for evacuation |
| 352-356 | `function Epidemic:calculateInfectedFine(infected_count)` | Fine = max(2000, count * EpidemicFine) |
| 364-366 | `local function getBaseReputationFromFine(fine_amount) return math.round(fine_amount / 100) end` | Rep hit = fine / 100 |
| 371-379 | `function Epidemic:resolveDeclaration()` | Declare epidemic immediately |
| 376 | `local reputation_hit = getBaseReputationFromFine(self.declare_fine)` | Declaration rep hit |
| 377 | `self.hospital.reputation = self.hospital.reputation - reputation_hit` | Direct reputation change |
| 439-485 | `function Epidemic:determineFaxAndFines(still_infected)` | **Outcome determination** |
| 449-461 | `if still_infected == 0 then` → compensation, no rep hit | Success path |
| 462-468 | `elseif still_infected < self.reputation_loss_minimum and still_infected < self.evacuation_minimum then` | Minor failure (fine only) |
| 469-475 | `elseif still_infected >= self.reputation_loss_minimum and still_infected < self.evacuation_minimum then` | Major failure (fine + rep loss) |
| 476-483 | `else` → `self.will_be_evacuated = true` | Evacuation path |
| 489-508 | `function Epidemic:applyOutcome()` | **Apply fines and reputation hits** |
| 491-500 | `if self.compensation == 0 then` → failure handling | Failed epidemic |
| 492-494 | `if self.will_be_evacuated then reputation_hit = math.round(self.hospital.reputation * (1/3))` | **Evacuation: 33% rep loss** |
| 496 | `self.reputation_hit = getBaseReputationFromFine(self.coverup_fine)` | Standard failure rep hit |
| 498-500 | `self.hospital:spendMoney(...); self.hospital.reputation = self.hospital.reputation - self.reputation_hit` | Apply fine and rep hit |
| 501-502 | `else` → `self.hospital:receiveMoney(self.compensation, ...)` | Success: get money |

---

## patient.lua

| Line Range | Function/Content | Description |
|------------|------------------|-------------|
| 261-288 | `function Patient:getPriceDistortion(casebook)` | **Price distortion calculation** |
| 270-272 | `local happiness_weight = 0.1; local reputation_weight = 0.6; local effectiveness_weight = 0.3` | Weight constants |
| 275 | `local reputation = casebook.reputation or self.hospital.reputation` | Uses disease or hospital reputation |
| 278-280 | Weighted components calculation | happiness, reputation, effectiveness |
| 282 | `local expected_price_level = weighted_happiness + weighted_reputation + weighted_effectiveness` | Expected price |
| 285 | `local price_level = ((casebook.price - 0.5) / 3) * 2` | Actual price mapped to [-0.33, 1.0] |
| 287 | `return price_level - expected_price_level` | Distortion in [-1, 1] |

---

## staff.lua

| Line Range | Function/Content | Description |
|------------|------------------|-------------|
| 252 | `self.hospital:changeReputation("kicked")` | Staff fired reputation hit |

---

## room.lua

| Line Range | Function/Content | Description |
|------------|------------------|-------------|
| 961 | `self.hospital:changeReputation("room_crash")` | Room explosion reputation hit |

---

## research.lua

| Line Range | Function/Content | Description |
|------------|------------------|-------------|
| 180 | `hosp:changeReputation("autopsy_discovered")` | Autopsy research completed |

---

## annual_report.lua

| Line Range | Function/Content | Description |
|------------|------------------|-------------|
| 311 | `hosp:changeReputation("year_end", nil, math.floor(self.rep_amount))` | Year-end reputation adjustment |

---

## world.lua

| Line Range | Function/Content | Description |
|------------|------------------|-------------|
| 1227-1239 | `function World:computeReputationImpact(hospital)` | **Patient spawn rate multiplier** |
| 1228 | `-- The relation between reputation and its impact is linear.` | Linear relationship |
| 1230-1235 | Key points: 1% at <253, 60% at 400, 100% at 500, 140% at 600, 180% at 700, 300% at 1000 | Spawn rate reference |
| 1239 | `local result = 1 + ((hospital.reputation - 500) / 250)` | Formula |

---

## base_config.lua

| Line Range | Content | Description |
|------------|---------|-------------|
| 105 | `-- How many patients still infected cause a reputation loss as well as a fine` | Epidemic config comment |
| 441 | `-- If player's reputation is >x all through the year then win trophy MIN 0 MAX 1000` | Trophy config |
| 478 | `-- Bonus to reputation for pleasing VIPs in the year (REPUTATION BONUS)` | VIP bonus |
| 591 | `-- MIN -127 MAX +127 reputation bonus` | Year-end bonus range |
| 593 | `-- MIN -127 MAX +127 reputation penalty` | Year-end penalty range |

---

## endconditions.lua

| Line Range | Content | Description |
|------------|---------|-------------|
| 26 | `{name = "reputation", icon = 10, formats = 2},` | End condition type |
| 63 | `start.reputation = town.StartRep` | Starting reputation |

---

## cheats.lua

| Line Range | Content | Description |
|------------|---------|-------------|
| 54 | `{name = "max_reputation", func = self.cheatMaxReputation},` | Cheat menu entry |
| 220 | `hosp:unconditionalChangeReputation(hosp.reputation_max)` | Max reputation cheat |

---

## dialogs/bottom_panel.lua

| Line Range | Content | Description |
|------------|---------|-------------|
| 158-159 | Tooltip showing reputation value | UI reputation display |
| 296-303 | Drawing reputation meter on canvas | UI reputation meter |

---

## dialogs/fullscreen/annual_report.lua

| Line Range | Content | Description |
|------------|---------|-------------|
| 311 | `hosp:changeReputation("year_end", nil, math.floor(self.rep_amount))` | Year-end reputation |

---

## hospitals/player_hospital.lua

| Line Range | Content | Description |
|------------|---------|-------------|
| 557 | `-- from Hospital:computePriceLevelImpact` | Comment reference |

---

## Summary: Call Graph

```
changeReputation(reason, disease, valueChange)
├── autopsy_discovered: percentage-based (-70% default)
├── valueChange provided: use custom amount
└── reputation_changes[reason]: table lookup
    ├── cured (+1) ← updateCuredCounts()
    ├── death (-4) ← patient death
    ├── kicked (-3) ← staff firing OR patient sent home
    ├── emergency_success (+15) ← endEmergency()
    ├── emergency_failed (-20) ← endEmergency()
    ├── over_priced (-2) ← computePriceLevelImpact()
    ├── under_priced (+1) ← computePriceLevelImpact()
    └── room_crash (-50) ← Room:crash()
    
    → isReputationChangeAllowed(amount)
        ├── amount > 0 and rep ≤ 500: ALWAYS
        ├── amount < 0 and rep ≥ 500: ALWAYS
        ├── amount == 0: ALWAYS
        └── else: random() ≤ getReputationChangeLikelihood()
            → getReputationChangeLikelihood(): quadratic curve
                a=0.000004008, b=0.004008, c=1
                1 - (a*x² - b*x + c)
        → unconditionalChangeReputation(amount)
            → clamp [0, 1000]
            → update trophy status
    
    → disease casebook reputation += amount (ALWAYS, even if gated!)

computePriceLevelImpact(patient, casebook)
├── price_distortion = patient:getPriceDistortion(casebook)
├── happiness += -(price_distortion / 2)
├── if distortion < under_threshold (1%): changeReputation("under_priced")
├── elif distortion > over_threshold (1%): changeReputation("over_priced")
└── elif |distortion| ≤ 0.15 (0.5%): advise fair price

Epidemic Outcomes
├── 0 infected: compensation ($1K-5K), no rep hit
├── <5 infected: fine, rep hit = fine/100
├── 5-19 infected: fine, rep hit = fine/100
└── ≥20 infected: evacuation, rep hit = reputation × 33%

Downstream Effects
├── Spawn rate: 1 + (rep - 500) / 250
├── Treatment price: × (rep/500) if rep ≥ 500
├── Staff salary: (rep - 500) / (deaths + 1)
└── Trophy: rep > level_config.awards_trophies.Reputation
```

---

## Search Patterns for Future Reference

```bash
# All reputation change calls
grep -rn "changeReputation(" Lua/

# Probability gating
grep -rn "isReputationChangeAllowed\|getReputationChangeLikelihood" Lua/

# Price impact
grep -rn "computePriceLevelImpact\|getPriceDistortion" Lua/

# Epidemic reputation
grep -rn "reputation_hit\|reputation_loss" Lua/epidemic.lua

# Reputation bounds
grep -rn "reputation_min\|reputation_max\|unconditionalChangeReputation" Lua/

# Downstream effects
grep -rn "computeReputationImpact\|sal_mult.*reputation\|has_impressive_reputation" Lua/
```



## Related Pages

- [[08-reputation-system/SUMMARY]]
- [[08-reputation-system/CHECKLIST]]
- [[08-reputation-system/SCAFFOLD]]
