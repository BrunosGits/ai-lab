# CorsixTH Financial System - Deep Research Documentation

## Table of Contents
1. [Overview](#overview)
2. [Money Flow - Income Sources](#money-flow---income-sources)
3. [Money Flow - Expense Categories](#money-flow---expense-categories)
4. [Treatment Price Calculation](#treatment-price-calculation)
5. [Insurance System](#insurance-system)
6. [Loan & Overdraft System](#loan--overdraft-system)
7. [Monthly Payment Processing](#monthly-payment-processing)
8. [Price Distortion & Reputation Impact](#price-distortion--reputation-impact)
9. [COST_RECOVERY (40%)](#cost_recovery-40)
10. [Price Distortion Thresholds by Difficulty](#price-distortion-thresholds-by-difficulty)
11. [Code Examples](#code-examples)

---

## Overview

CorsixTH's financial system simulates hospital economics with multiple income streams, recurring expenses, insurance payment delays, loan mechanics, and price sensitivity based on reputation. The system is primarily implemented in `Lua/hospital.lua` with supporting logic in `Lua/room.lua`, `Lua/research_department.lua`, and patient pricing in `Lua/entities/humanoids/patient.lua`.

**Key principle**: The hospital operates in two modes:
- **Campaign mode** (normal): Full financial simulation
- **Free build mode** (`world.free_build_mode = true`): Money operations are no-ops

---

## Money Flow - Income Sources

### 1. Treatment Payments (Direct Patient Payment)
**Location**: `Hospital:receiveMoneyForTreatment()` at `hospital.lua:1240-1266`

When a patient completes treatment:
- Patient pays `pay_amount` if set, otherwise `getTreatmentPrice(disease_id)`
- 25% chance to route through insurance (if `patient.insurance_company` is set)
- Direct payments trigger `computePriceLevelImpact()` for reputation/happiness effects

```lua
function Hospital:receiveMoneyForTreatment(patient)
  local amount = patient.pay_amount or 0
  amount = amount > 0 and amount or self:getTreatmentPrice(disease_id)
  
  -- 25% of payments go through insurance
  if patient.insurance_company then
    self:addInsuranceMoney(patient.insurance_company, amount)
  else
    self:computePriceLevelImpact(patient, casebook)
    self:receiveMoney(amount, reason)
  end
end
```

### 2. Insurance Reimbursements (Delayed 2 Months)
**Location**: `Hospital:onEndMonth()` at `hospital.lua:832-842`

Insurance payments use a **3-slot rotating buffer** per company:
- Slot 1: Current month's accumulating debt
- Slot 2: Previous month's debt (1 month delay)
- Slot 3: Month before that (2 month delay) — **this gets paid out**

```lua
-- Insurance balance structure: 3 companies × 3 months
self.insurance_balance = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}}

-- At month end:
for i, company in ipairs(self.insurance_balance) do
  local payout_amount = company[3]  -- 2-month-old debt
  if payout_amount > 0 then
    self:receiveMoney(payout_amount, "Insurance: " .. self.insurance[i])
  end
  -- Rotate: remove oldest, insert new zero month
  table.remove(company, 3)
  table.insert(company, 1, 0)
end
```

### 3. Product Sales (Sodas, Jukebox, Vaccines)
- **Sodas**: `Hospital:sellSodaToPatient()` at `hospital.lua:1269-1275` — price from `level_config.gbv.SodaPrice` (default $20)
- **Vaccinations**: `vaccinate.lua:96` — spends `vaccination_fee`
- **Jukebox**: Transaction type `jukebox`

### 4. Emergency Bonuses
**Location**: `hospital.lua:974`
- `receiveMoney(earned, _S.transactions.emergency_bonus)`

### 5. End-of-Year Awards
**Location**: `annual_report.lua:304-309`
- Trophy bonuses: `eoy_trophy_bonus`
- Performance penalties/bonuses: `eoy_bonus_penalty`

### 6. Government Compensation (Epidemics)
**Location**: `epidemic.lua:502`
- `receiveMoney(compensation, _S.transactions.compensation)`

### 7. Bank Loans
**Location**: `bank_manager.lua:432-438`
- Max loan = `floor(hospital.value * 0.33 / 5000) * 5000 + 10000`
- Increments of $5,000 (or Ctrl+click for max)
- Transaction: `bank_loan`

### 8. Research Bonuses
**Location**: `staff_management.lua:647`
- Personal bonuses: `personal_bonus`

---

## Money Flow - Expense Categories

### 1. Staff Wages (Monthly)
**Location**: `Hospital:onEndMonth()` at `hospital.lua:788-795`

```lua
local wages = 0
for _, staff in ipairs(self.staff) do
  wages = wages + staff.profile.wage
end
if wages ~= 0 then
  self:spendMoney(wages, _S.transactions.wages)
end
```

### 2. Heating Costs (Daily Accrual, Monthly Payment)
**Location**: `Hospital:onDayChange()` at `hospital.lua:778-781` (accrual) + `onEndMonth()` at `797-800` (payment)

```lua
-- Daily accrual:
local num_radiators = self:countRadiators()
local heating_costs = (self.heating.radiator_heat * 10 * num_radiators * 7.50) / self.world:date():lastDayOfMonth()
self.acc_heating = self.acc_heating + heating_costs

-- Monthly payment:
if math.round(self.acc_heating) > 0 then
  self:spendMoney(math.round(self.acc_heating), _S.transactions.heating)
  self.acc_heating = 0
end
```

**Formula**: `radiator_heat × 10 × num_radiators × 7.50 / days_in_month`

### 3. Loan Interest (Daily Accrual, Monthly Payment)
**Location**: `Hospital:onDayChange()` at `hospital.lua:741-742` + `onEndMonth()` at `802-805`

```lua
-- Daily:
local pay_this = self.loan * self.interest_rate / 365  -- No leap years
self.acc_loan_interest = self.acc_loan_interest + pay_this

-- Monthly:
if math.round(self.acc_loan_interest) > 0 then
  self:spendMoney(math.round(self.acc_loan_interest), _S.transactions.loan_interest)
  self.acc_loan_interest = 0
end
```

**Interest rate**: Set at hospital creation from `level_config.towns[level].InterestRate / 10000`

### 4. Overdraft Interest (Daily Accrual, Monthly Payment)
**Location**: `Hospital:onDayChange()` at `hospital.lua:746-750` + `onEndMonth()` at `807-810`

```lua
if self.balance < 0 then
  local overdraft_interest = self.overdraft_interest_rate
  local overdraft = math.abs(self.balance)
  local overdraft_payment = (overdraft * overdraft_interest) / 365
  self.acc_overdraft = self.acc_overdraft + overdraft_payment
end
```

**Overdraft rate**: `interest_rate + overdraft_differential_numerator / 10000`

### 5. Research Costs (Daily Accrual, Monthly Payment)
**Location**: `research_department.lua:625-647` (accrual) + `hospital.lua:812-815` (payment)

```lua
function ResearchDepartment:researchCost()
  local acc_cost = self.hospital.acc_research_cost
  local fraction = 0
  for _, tab in pairs(self.research_policy) do
    if type(tab) == "table" and tab.current and not tab.current.dummy then
      fraction = fraction + tab.frac
    end
  end
  local doctors = 0
  for _, room in pairs(self.world.rooms) do
    if room.room_info.id == "research" then
      for _ in pairs(room.staff_member_set) do
        doctors = doctors + 1
      end
    end
  end
  acc_cost = acc_cost + math.ceil(3 * doctors * fraction / 100)
  self.hospital.acc_research_cost = acc_cost
end
```

**Formula**: `ceil(3 × doctors × total_research_fraction / 100)` per day

### 6. Drug Costs (Per Treatment)
**Location**: `Hospital:paySupplierForDrug()` at `hospital.lua:1300-1308`

```lua
local drug_amount = self.disease_casebook[disease_id].drug_cost or 0
if drug_amount ~= 0 then
  local str = _S.drug_companies[math.random(1, 5)]
  self:spendMoney(drug_amount, _S.transactions.drug_cost .. ": " .. str)
end
```

### 7. Construction & Objects
- **Build room**: `edit_room.lua:244` — `build_room`
- **Buy object**: `place_objects.lua:187,223` — `buy_object`
- **Buy land**: `hospital.lua:592` — `buy_land`
- **Remove room**: `game_ui.lua:706` — `remove_room` (uses `COST_RECOVERY`)

### 8. Machine Replacement
**Location**: `machine.lua:353`
- `spendMoney(cost, _S.transactions.machine_replacement)`

### 9. Severance Pay
**Location**: `staff.lua:245`
- `spendMoney(profile.wage, _S.transactions.severance)`

### 10. Epidemic Fines
**Location**: `epidemic.lua:375,499`
- Fine for undeclared epidemic: `epidemy_fine`
- Cover-up fine: `epidemy_coverup_fine`

### 11. Staff Bonuses
**Location**: `staff_management.lua:647`
- Personal bonus (10% of wage): `personal_bonus`

### 12. Vaccination Costs
**Location**: `vaccinate.lua:96`
- `spendMoney(vaccination_fee, _S.transactions.vaccination)`

---

## Treatment Price Calculation

### `Hospital:getTreatmentPrice(disease)` at `hospital.lua:1279-1288`

```lua
function Hospital:getTreatmentPrice(disease)
  local reputation = self.disease_casebook[disease].reputation or self.reputation
  local percentage = self.disease_casebook[disease].price
  local raw_price  = self.disease_casebook[disease].disease.cure_price
  
  if reputation >= 500 then
    return math.ceil(raw_price * (reputation / 500) * percentage)
  else
    return math.ceil(raw_price * percentage)
  end
end
```

### Price Components

| Component | Source | Description |
|-----------|--------|-------------|
| `raw_price` | `disease.cure_price` | Base cure price from disease definition |
| `percentage` | `casebook.price` | Player-set price modifier (default 1.0 = 100%) |
| `reputation` | `casebook.reputation` or `hospital.reputation` | Disease-specific or hospital-wide reputation |
| **Reputation multiplier** | — | Only applies when reputation ≥ 500: `reputation / 500` |

### Price Floor
**Critical**: Treatment charge **never falls below starting price** if reputation < 500
- At reputation 500: multiplier = 1.0 (base price × percentage)
- At reputation 1000: multiplier = 2.0 (double price × percentage)
- At reputation 0-499: multiplier = 1.0 (clamped to base × percentage)

---

## Insurance System

### Company Selection (Hospital Creation)
**Location**: `hospital.lua:202-215`

```lua
self.insurance = {}
local companies = {}
for no, local_name in ipairs(_S.insurance_companies) do
  companies[no] = local_name
end
while #self.insurance < 3 and #companies > 0 do
  local num = math.random(1, 2) == 1 and math.random(1, math.ceil(#companies / 4)) or
              math.random(1, #companies)
  self.insurance[#self.insurance + 1] = companies[num]
  table.remove(companies, num)
end
```

- Selects 3 companies from translated list `_S.insurance_companies`
- First quarter of list has higher selection probability

### Payment Flow

1. **Treatment occurs** → `receiveMoneyForTreatment()` called
2. **If patient has insurance** → `addInsuranceMoney(company, amount)` at `hospital.lua:1290-1293`
   ```lua
   function Hospital:addInsuranceMoney(company, amount)
     local old_balance = self.insurance_balance[company][1]
     self.insurance_balance[company][1] = old_balance + amount
   end
   ```
   - Adds to **current month slot (index 1)** for that company

3. **Monthly rotation** at `onEndMonth()` (`hospital.lua:832-842`):
   - Slot 3 (2 months old) → **PAID OUT**
   - Slot 2 → becomes new Slot 3
   - Slot 1 → becomes new Slot 2
   - New Slot 1 = 0 (fresh month)

### Timeline Example

| Month | Slot 1 (Current) | Slot 2 (1 mo ago) | Slot 3 (2 mo ago) | Action |
|-------|------------------|-------------------|-------------------|--------|
| Jan | $5,000 | $0 | $0 | Accumulate |
| Feb | $3,000 | $5,000 | $0 | Accumulate |
| Mar | $4,000 | $3,000 | **$5,000** | **Payout $5,000** |
| Apr | $2,000 | $4,000 | **$3,000** | **Payout $3,000** |

---

## Loan & Overdraft System

### Loan Mechanics

**Initialization** (`hospital.lua:49, 82-84`):
```lua
self.loan = 0
self.interest_rate = interest_rate_numerator / 10000
self.overdraft_interest_rate = self.interest_rate + overdraft_differential_numerator / 10000
```

**Maximum Loan** (`bank_manager.lua:434`):
```lua
local max_loan = math.floor((hospital.value * 0.33) / 5000) * 5000 + 10000
```
- 33% of hospital value, rounded to $5,000 increments, plus $10,000 base

**Loan Operations**:
- **Increase**: `hospital.loan += amount` + `receiveMoney(amount, bank_loan)`
- **Decrease/Repay**: `hospital.loan -= amount` + `spendMoney(amount, loan_repayment)`

### Overdraft Mechanics

- **No explicit limit** — hospital can go negative indefinitely
- **Interest penalty**: Higher rate than loan (`interest_rate + differential`)
- **Daily accrual** when `balance < 0`
- **Monthly payment** via `acc_overdraft`

### Interest Rate Examples (from level configs)

| Level | Interest Rate Numerator | Interest Rate | Overdraft Diff | Overdraft Rate |
|-------|------------------------|---------------|----------------|----------------|
| Default | 800 | 8.0% | 400 | 12.0% |
| (800/10000) | | (800/10000) | (400/10000) | (1200/10000) |

---

## Monthly Payment Processing

### `Hospital:onEndMonth()` at `hospital.lua:787-860`

**Execution Order**:
1. **Wages** — Sum all staff wages, spend via `wages`
2. **Heating** — Pay accumulated `acc_heating`, reset to 0
3. **Loan Interest** — Pay accumulated `acc_loan_interest`, reset to 0
4. **Overdraft** — Pay accumulated `acc_overdraft`, reset to 0
5. **Research** — Pay accumulated `acc_research_cost`, reset to 0
6. **Player Salary** — Calculate monthly salary increase
7. **Insurance Payouts** — Process 3 companies, rotate buffers
8. **Research Discovery** — Check automatic discovery
9. **Statistics** — Record monthly stats, reset `money_in`/`money_out`

### Player Salary Calculation

```lua
local sal_inc = self.salary_incr / 10
local sal_mult = (self.reputation - 500) / (self.num_deaths + 1)
local month_incr = sal_inc + sal_mult

-- Clamped between sal_min (50) and salary_incr (300)
if month_incr < self.sal_min then month_incr = self.sal_min
elseif month_incr > self.salary_incr then month_incr = self.salary_incr end

self.player_salary = self.player_salary + math.ceil(month_incr)
```

---

## Price Distortion & Reputation Impact

### Patient Price Distortion Calculation
**Location**: `Patient:getPriceDistortion()` at `patient.lua:268-288`

```lua
function Patient:getPriceDistortion(casebook)
  local happiness_weight = 0.1
  local reputation_weight = 0.6
  local effectiveness_weight = 0.3
  
  local reputation = casebook.reputation or self.hospital.reputation
  local effectiveness = casebook.cure_effectiveness
  
  local weighted_happiness = happiness_weight * self:getAttribute("happiness")
  local weighted_reputation = reputation_weight * (reputation / 1000)
  local weighted_effectiveness = effectiveness_weight * (effectiveness / 100)
  
  local expected_price_level = weighted_happiness + weighted_reputation + weighted_effectiveness
  
  -- Map casebook.price (0.5-3.5?) to [-1, 1] range
  local price_level = ((casebook.price - 0.5) / 3) * 2
  
  return price_level - expected_price_level
end
```

### Price Impact on Reputation
**Location**: `Hospital:computePriceLevelImpact()` at `hospital.lua:2241-2260`

```lua
function Hospital:computePriceLevelImpact(patient, casebook)
  local price_distortion = patient:getPriceDistortion(casebook)
  patient:changeAttribute("happiness", -(price_distortion / 2))
  
  if price_distortion < self.under_priced_threshold then
    if math.random(1, 100) == 1 then
      if casebook.price < 1 then
        self:advisePriceLevelImpact("under", casebook.disease.name)
      end
      self:changeReputation("under_priced")
    end
  elseif price_distortion > self.over_priced_threshold then
    if math.random(1, 100) == 1 then
      self:advisePriceLevelImpact("over", casebook.disease.name)
      self:changeReputation("over_priced")
    end
  elseif math.abs(price_distortion) <= 0.15 and math.random(1, 200) == 1 then
    self:advisePriceLevelImpact("fair", casebook.disease.name)
  end
end
```

### Effects Summary

| Price Distortion Range | Happiness Change | Reputation Change | Advisory Chance |
|------------------------|------------------|-------------------|-----------------|
| `< under_priced_threshold` | `-(distortion/2)` | Negative (`under_priced`) | 1% (if price < 1.0) |
| `> over_priced_threshold` | `-(distortion/2)` | Negative (`over_priced`) | 1% |
| `\|distortion\| <= 0.15` | `-(distortion/2)` | None | 0.5% (fair) |
| Between thresholds | `-(distortion/2)` | None | None |

---

## COST_RECOVERY (40%)

**Location**: `room.lua:26`

```lua
local COST_RECOVERY = 0.40 -- Percentage cost recovery of destroyed room items
```

### Usage

When a room is destroyed/removed, the hospital recovers 40% of the room's item value:

**Location**: `edit_room.lua:156` (sell object) and `game_ui.lua:706` (remove room)

```lua
-- Selling objects returns 40% of cost
self.ui.hospital:receiveMoney(cost, _S.transactions.sell_object, valueChange)
-- where valueChange = cost * COST_RECOVERY
```

### Implications
- **Sunk cost**: 60% of room/object value is permanently lost on demolition
- Encourages careful planning
- Affects hospital `value` calculation (used for max loan)

---

## Price Distortion Thresholds by Difficulty

**Location**: `hospital.lua:92-100`

```lua
local difficulty = self.world.map:getDifficulty()

-- Under-priced thresholds (negative = patients think it's too cheap)
local under_priced_thresholds = {-0.3, -0.4, -0.5}
self.under_priced_threshold = under_priced_thresholds[difficulty]

-- Over-priced thresholds (positive = patients think it's too expensive)
local over_priced_thresholds = {0.4, 0.3, 0.2}
self.over_priced_threshold = over_priced_thresholds[difficulty]
```

### Difficulty Mapping

| Difficulty Level | Index | Under-Priced Threshold | Over-Priced Threshold | Tolerance Window |
|------------------|-------|------------------------|----------------------|------------------|
| Easy (1) | 1 | -0.3 | 0.4 | ±0.35 avg |
| Normal (2) | 2 | -0.4 | 0.3 | ±0.35 avg |
| Hard (3) | 3 | -0.5 | 0.2 | ±0.35 avg |

**Note**: Hard difficulty has tighter pricing tolerance — players must price more accurately.

---

## Code Examples

### Example 1: Complete Treatment Payment Flow

```lua
-- Patient finishes treatment in GP Office
function Patient:treatDisease()
  local hospital = self.hospital
  
  -- 1. Hospital receives payment (direct or insurance)
  hospital:receiveMoneyForTreatment(self)
  
  -- 2. If cured, patient goes home
  if self:isTreatmentEffective() then
    self:cure()
    self:goHome("cured")
  else
    self:die()
  end
end

-- Inside receiveMoneyForTreatment:
function Hospital:receiveMoneyForTreatment(patient)
  local disease_id = patient:getTreatmentDiseaseId()
  local casebook = self.disease_casebook[disease_id]
  
  -- Determine amount
  local amount = patient.pay_amount or 0
  amount = amount > 0 and amount or self:getTreatmentPrice(disease_id)
  
  -- 25% chance insurance (if patient has insurance_company)
  if patient.insurance_company then
    self:addInsuranceMoney(patient.insurance_company, amount)
    -- Money goes to insurance_balance[company][1] (current month)
  else
    -- Direct payment + price sensitivity check
    self:computePriceLevelImpact(patient, casebook)
    self:receiveMoney(amount, "Cure: " .. casebook.disease.name)
  end
end
```

### Example 2: Monthly Financial Close

```lua
function Hospital:onEndMonth()
  -- 1. Pay wages
  local wages = 0
  for _, staff in ipairs(self.staff) do
    wages = wages + staff.profile.wage
  end
  self:spendMoney(wages, "Wages")
  
  -- 2. Pay heating (accumulated daily)
  self:spendMoney(math.round(self.acc_heating), "Heating")
  self.acc_heating = 0
  
  -- 3. Pay loan interest (accumulated daily)
  self:spendMoney(math.round(self.acc_loan_interest), "Loan Interest")
  self.acc_loan_interest = 0
  
  -- 4. Pay overdraft interest (accumulated daily when balance < 0)
  self:spendMoney(math.round(self.acc_overdraft), "Overdraft")
  self.acc_overdraft = 0
  
  -- 5. Pay research costs (accumulated daily)
  self:spendMoney(math.round(self.acc_research_cost), "Research")
  self.acc_research_cost = 0
  
  -- 6. Calculate player salary increase
  local sal_inc = self.salary_incr / 10  -- 30
  local sal_mult = (self.reputation - 500) / (self.num_deaths + 1)
  local month_incr = math.clamp(sal_inc + sal_mult, self.sal_min, self.salary_incr)
  self.player_salary = self.player_salary + math.ceil(month_incr)
  
  -- 7. Process insurance payouts (2-month delay)
  for i, company in ipairs(self.insurance_balance) do
    local payout = company[3]  -- Oldest month
    if payout > 0 then
      self:receiveMoney(payout, "Insurance: " .. self.insurance[i])
    end
    -- Rotate: [new=0, month1, month2] 
    table.remove(company, 3)
    table.insert(company, 1, 0)
  end
  
  -- 8. Record statistics
  self.statistics[month] = { money_in, money_out, wages, balance, ... }
  self.money_in = 0
  self.money_out = 0
end
```

### Example 3: Daily Interest Accrual

```lua
function Hospital:onDayChange()
  -- Loan interest (daily)
  local daily_loan_interest = self.loan * self.interest_rate / 365
  self.acc_loan_interest = self.acc_loan_interest + daily_loan_interest
  
  -- Overdraft interest (only if negative balance)
  if self.balance < 0 then
    local overdraft = math.abs(self.balance)
    local daily_overdraft = overdraft * self.overdraft_interest_rate / 365
    self.acc_overdraft = self.acc_overdraft + daily_overdraft
  end
  
  -- Heating cost (daily portion of monthly)
  local num_radiators = self:countRadiators()
  local daily_heating = (self.heating.radiator_heat * 10 * num_radiators * 7.50) / days_in_month
  self.acc_heating = self.acc_heating + daily_heating
  
  -- Research cost (daily)
  self.research:researchCost()  -- Adds to acc_research_cost
end
```

### Example 4: Price Sensitivity Check

```lua
-- Player sets disease price to 150% (casebook.price = 1.5)
-- Hospital reputation = 600
-- Disease cure effectiveness = 80%
-- Patient happiness = 70 (0-100)

local price_distortion = patient:getPriceDistortion(casebook)

-- Expected price level:
-- happiness: 0.1 * 0.70 = 0.07
-- reputation: 0.6 * (600/1000) = 0.36
-- effectiveness: 0.3 * (80/100) = 0.24
-- expected = 0.67

-- Actual price level:
-- casebook.price = 1.5
-- price_level = ((1.5 - 0.5) / 3) * 2 = 0.67

-- distortion = 0.67 - 0.67 = 0.0 (perfectly priced!)
-- Result: No reputation impact, small chance of "fair" advisory
```

---

## Summary of Key Constants

| Constant | Value | Location | Description |
|----------|-------|----------|-------------|
| `COST_RECOVERY` | 0.40 | `room.lua:26` | 40% refund on room/object demolition |
| `insurance_delay` | 2 months | `hospital.lua:220` | Insurance pays 2 months after treatment |
| `insurance_split` | 25% | `hospital.lua:1255` | ~25% of patients use insurance |
| `daily_heating_base` | 7.50 | `hospital.lua:780` | Per radiator per 10% heat per day |
| `research_cost_per_doctor` | $3/day | `research_department.lua:645` | At 100% research fraction |
| `loan_max_pct` | 33% | `bank_manager.lua:434` | Of hospital value |
| `loan_increment` | $5,000 | `bank_manager.lua:436` | Minimum loan adjustment |
| `reputation_price_floor` | 500 | `hospital.lua:1283` | Below this, no price multiplier |
| `price_happiness_weight` | 0.1 | `patient.lua:270` | In distortion calculation |
| `price_reputation_weight` | 0.6 | `patient.lua:271` | In distortion calculation |
| `price_effectiveness_weight` | 0.3 | `patient.lua:272` | In distortion calculation |

---

## Transaction Type Reference (`_S.transactions`)

| Key | Description | Direction |
|-----|-------------|-----------|
| `wages` | Staff salaries | Expense |
| `heating` | Heating costs | Expense |
| `loan_interest` | Loan interest payment | Expense |
| `overdraft` | Overdraft interest | Expense |
| `research` | Research department costs | Expense |
| `drug_cost` | Pharmaceutical supplies | Expense |
| `buy_land` | Land purchase | Expense |
| `build_room` | Room construction | Expense |
| `buy_object` | Object placement | Expense |
| `remove_room` | Room demolition (40% recovery) | Income |
| `sell_object` | Object sale (40% recovery) | Income |
| `hire_staff` | Recruitment cost | Expense |
| `severance` | Staff termination pay | Expense |
| `cure_colon` | Cure payment | Income |
| `treat_colon` | Treatment payment | Income |
| `insurance_colon` | Insurance reimbursement | Income |
| `drinks` | Vending machine revenue | Income |
| `jukebox` | Jukebox revenue | Income |
| `vaccination` | Vaccination cost | Expense |
| `machine_replacement` | Broken machine replacement | Expense |
| `emergency_bonus` | Emergency case bonus | Income |
| `eoy_bonus_penalty` | End-of-year performance | Income/Expense |
| `eoy_trophy_bonus` | Trophy award | Income |
| `bank_loan` | Loan received | Income |
| `loan_repayment` | Loan repaid | Expense |
| `compensation` | Government epidemic compensation | Income |
| `epidemy_fine` | Epidemic fine | Expense |
| `epidemy_coverup_fine` | Epidemic cover-up fine | Expense |
| `personal_bonus` | Staff bonus (10% wage) | Expense |
| `cheat` | Cheat money | Income |
| `advance_colon` | Research advance | Expense |
| `final_treat_colon` | Final treatment payment | Income |
| `research_bonus` | Research milestone bonus | Income |
| `vip_award` | VIP patient reward | Income |

---

*Document generated from CorsixTH source code analysis*
*Last updated: 2026*
