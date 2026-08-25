# CorsixTH Financial System - File:Line Index

> Complete cross-reference of all financial methods, variables, and transaction types across the codebase.

---

## Lua/hospital.lua (Primary Financial Controller)

### Hospital Initialization & Configuration
| Line | Symbol | Type | Description |
|------|--------|------|-------------|
| 32-44 | `level_config.towns[level]` | config | Starting cash, interest rate, reputation, overdraft diff per town |
| 48 | `self.balance` | var | Current cash balance (0 in free_build_mode) |
| 49 | `self.loan` | var | Current bank loan amount |
| 50 | `self.acc_loan_interest` | var | Accumulated loan interest (daily→monthly) |
| 51 | `self.acc_research_cost` | var | Accumulated research costs (daily→monthly) |
| 52 | `self.acc_overdraft` | var | Accumulated overdraft interest (daily→monthly) |
| 53 | `self.acc_heating` | var | Accumulated heating costs (daily→monthly) |
| 57 | `self.value` | var | Hospital asset value (parcel + 20000) |
| 59 | `self.player_salary` | var | Player's monthly salary |
| 60 | `self.salary_offer` | var | Pending salary offer |
| 82 | `self.interest_rate` | var | Loan interest rate (numerator/10000) |
| 83 | `self.inflation_rate` | var | Inflation rate (0.045) |
| 84 | `self.overdraft_interest_rate` | var | Overdraft rate = interest + differential |
| 85 | `self.salary_incr` | var | Max monthly salary increase (gbv.ScoreMaxInc) |
| 86 | `self.sal_min` | var | Min monthly salary increase (gbv.ScoreMaxInc/6) |
| 94-95 | `self.under_priced_threshold` | var | Price distortion threshold (by difficulty) |
| 99-100 | `self.over_priced_threshold` | var | Price distortion threshold (by difficulty) |
| 107-112 | `self.heating` | table | Radiator heat, boiler state |
| 202-215 | `self.insurance` | table | 3 selected insurance company names |
| 217-222 | `self.insurance_balance` | table | 3×3 matrix: [company][month_slot] |
| 224-230 | `self.disease_casebook` | table | Per-disease: price, reputation, money_earned |

### Core Money Operations
| Line | Function | Description |
|------|----------|-------------|
| 1207-1216 | `spendMoney(amount, reason, changeValue)` | Decrease balance, log transaction, track money_out, adjust value |
| 1218-1234 | `receiveMoney(amount, reason, changeValue)` | Increase balance, log transaction, track money_in, adjust value |
| 1236-1267 | `receiveMoneyForTreatment(patient)` | Process treatment payment (direct or insurance) |
| 1269-1275 | `sellSodaToPatient(patient)` | Sell soda at level_config.gbv.SodaPrice |
| 1277-1288 | `getTreatmentPrice(disease)` | Calculate price: raw × (rep≥500 ? rep/500 : 1) × percentage |
| 1290-1293 | `addInsuranceMoney(company, amount)` | Add to insurance_balance[company][1] (current month) |
| 1295-1298 | `receiveMoneyForProduct(patient, amount, reason)` | Generic product sale (floating $ sign + receiveMoney) |
| 1300-1308 | `paySupplierForDrug(disease_id)` | Pay drug_cost to random pharmaceutical company |
| 1310-1322 | `logTransaction(transaction)` | Add to transactions log (max 20), record day/month/balance |
| 2241-2260 | `computePriceLevelImpact(patient, casebook)` | Calculate distortion, adjust happiness, maybe reputation |
| 2270-2274 | `changeValue(changeValue)` | Direct value adjustment (no transaction) |

### Daily Processing (`onDayChange`)
| Line | Function | Description |
|------|----------|-------------|
| 741-742 | Loan interest accrual | `acc_loan_interest += loan * interest_rate / 365` |
| 746-750 | Overdraft interest accrual | If balance<0: `acc_overdraft += abs(balance) * overdraft_rate / 365` |
| 778-781 | Heating cost accrual | `acc_heating += (radiator_heat * 10 * radiators * 7.50) / days_in_month` |
| 783 | Research cost accrual | `research:researchCost()` called daily |
| 735-744 | `onDayChange()` | Main daily update function |

### Monthly Processing (`onEndMonth`)
| Line | Function | Description |
|------|----------|-------------|
| 787-860 | `onEndMonth()` | End-of-month financial close |
| 788-795 | Wages payment | Sum staff wages, `spendMoney(wages, wages)` |
| 796-800 | Heating payment | `spendMoney(round(acc_heating), heating)`, reset |
| 801-805 | Loan interest payment | `spendMoney(round(acc_loan_interest), loan_interest)`, reset |
| 806-810 | Overdraft payment | `spendMoney(round(acc_overdraft), overdraft)`, reset |
| 811-815 | Research payment | `spendMoney(round(acc_research_cost), research)`, reset |
| 816-829 | Player salary calc | `sal_inc + (rep-500)/(deaths+1)`, clamped [sal_min, salary_incr] |
| 831-842 | Insurance payouts | For each company: pay slot[3], rotate left, insert 0 |
| 844-858 | Statistics recording | Save monthly stats, reset money_in/out |

### Insurance & Pricing Helpers
| Line | Function | Description |
|------|----------|-------------|
| 202-215 | Insurance company selection | Weighted random from _S.insurance_companies |
| 2241-2260 | `computePriceLevelImpact()` | Distortion → happiness → reputation/advisory |
| 94-100 | Difficulty thresholds | under_priced: {-0.3,-0.4,-0.5}, over_priced: {0.4,0.3,0.2} |

### Campaign Data Persistence
| Line | Function | Description |
|------|----------|-------------|
| 2276-2288 | `getCampaignData()` | Returns: player_salary, message_popup, handyman_popup, hospital_littered, has_seen_pay_rise, policies |
| 2290-2296 | `setCampaignData(data)` | Restores campaign data fields |

---

## Lua/room.lua

### Constants
| Line | Symbol | Value | Description |
|------|--------|-------|-------------|
| 26 | `COST_RECOVERY` | 0.40 | 40% cost recovery on room/object demolition |

### Room Financial Methods
| Line | Function | Description |
|------|----------|-------------|
| 156 (edit_room.lua) | `receiveMoney(cost, sell_object, valueChange)` | Sell object: 40% recovery |
| 244 (edit_room.lua) | `spendMoney(cost, build_room, cost)` | Build room: full cost + value increase |
| 186 (furnish_corridor.lua) | `spendMoney/receiveMoney` | Corridor object buy/sell with recovery |

---

## Lua/research_department.lua

### Research Cost Calculation
| Line | Function | Description |
|------|----------|-------------|
| 621-647 | `researchCost()` | Daily cost: `ceil(3 * doctors * total_fraction / 100)` |
| 626 | `acc_cost` | Local reference to `hospital.acc_research_cost` |
| 630-635 | Fraction accumulation | Sum `tab.frac` for active (non-dummy) research categories |
| 637-644 | Doctor counting | Count staff in research rooms |
| 645 | Cost formula | `acc_cost + math.ceil(3 * doctors * fraction/100)` |
| 646 | Store result | `self.hospital.acc_research_cost = acc_cost` |

---

## Lua/entities/humanoids/patient.lua

### Price Sensitivity
| Line | Function | Description |
|------|----------|-------------|
| 268-288 | `getPriceDistortion(casebook)` | Calculate price distortion [-1,1] |
| 270 | `happiness_weight` | 0.1 |
| 271 | `reputation_weight` | 0.6 |
| 272 | `effectiveness_weight` | 0.3 |
| 278-280 | Weighted factors | happiness×0.1 + rep/1000×0.6 + effectiveness/100×0.3 |
| 282 | `expected_price_level` | Sum of weighted factors [0,1] |
| 285 | `price_level` | `((casebook.price - 0.5) / 3) * 2` maps price% to [-1,1] |
| 287 | Return | `price_level - expected_price_level` |

### Treatment Payment Trigger
| Line | Function | Description |
|------|----------|-------------|
| 295-307 | `treatDisease()` | Calls `hospital:receiveMoneyForTreatment(self)` |

---

## Lua/dialogs/fullscreen/bank_manager.lua

### Loan Operations
| Line | Function | Description |
|------|----------|-------------|
| 432-443 | `increaseLoan()` | Add 5000 (or max with Ctrl), `receiveMoney(bank_loan)` |
| 434 | Max loan formula | `floor(value * 0.33 / 5000) * 5000 + 10000` |
| 445-461 | `decreaseLoan()` | Repay 5000 (or max with Ctrl), `spendMoney(loan_repayment)` |
| 450-452 | Ctrl-repay | `min(loan, floor(balance/5000)*5000)` |

---

## Lua/dialogs/fullscreen/annual_report.lua

### End-of-Year Awards
| Line | Function | Description |
|------|----------|-------------|
| 301-313 | `updateAwards()` | Apply trophy bonuses/penalties |
| 304-306 | Trophy bonus | `receiveMoney(won_amount, eoy_trophy_bonus)` |
| 307-309 | Performance | `receiveMoney(award_won_amount, eoy_bonus_penalty)` |
| 310-312 | Reputation | `changeReputation("year_end", nil, rep_amount)` |

---

## Lua/epidemic.lua

### Epidemic Financials
| Line | Function | Description |
|------|----------|-------------|
| 375 | Declare fine | `spendMoney(declare_fine, epidemy_fine)` |
| 499 | Cover-up fine | `spendMoney(coverup_fine, epidemy_coverup_fine)` |
| 502 | Compensation | `receiveMoney(compensation, compensation)` |

---

## Lua/dialogs/fullscreen/staff_management.lua

### Staff Bonuses
| Line | Function | Description |
|------|----------|-------------|
| 647 | Personal bonus | `spendMoney(floor(wage*0.1), personal_bonus)` |

---

## Lua/entities/humanoids/staff.lua

### Severance
| Line | Function | Description |
|------|----------|-------------|
| 245 | Severance pay | `spendMoney(profile.wage, severance .. ": " .. name)` |

---

## Lua/entities/machine.lua

### Machine Replacement
| Line | Function | Description |
|------|----------|-------------|
| 353 | Replacement cost | `spendMoney(cost, machine_replacement)` |

---

## Lua/game_ui.lua

### Room Demolition
| Line | Function | Description |
|------|----------|-------------|
| 706 | Remove room | `spendMoney(room_cost, remove_room)` (uses COST_RECOVERY) |

---

## Lua/cheats.lua

### Cheat Money
| Line | Function | Description |
|------|----------|-------------|
| 88 | Money cheat | `receiveMoney(10000, cheat)` |

---

## Lua/humanoid_actions/vaccinate.lua

### Vaccination
| Line | Function | Description |
|------|----------|-------------|
| 96 | Vaccination fee | `spendMoney(vaccination_fee, vaccination)` |

---

## Lua/dialogs/place_objects.lua

### Object Placement
| Line | Function | Description |
|------|----------|-------------|
| 187, 223 | Buy object | `spendMoney(cost, buy_object .. ": " .. name)` |
| 257 | Sell object | `receiveMoney(cost, sell_object .. ": " .. name, valueChange)` |

---

## Lua/dialogs/furnish_corridor.lua

### Corridor Furnishing
| Line | Function | Description |
|------|----------|-------------|
| 186 | Build corridor | `spendMoney(build_cost * qty, buy_object, build_cost * qty)` |
| 190 | Remove corridor | `receiveMoney(build_cost * qty, sell_object, build_cost * qty)` |

---

## Lua/dialogs/edit_room.lua

### Room Editing
| Line | Function | Description |
|------|----------|-------------|
| 156 | Sell object | `receiveMoney(cost, sell_object, valueChange)` |
| 244 | Build room | `spendMoney(cost, build_room, cost)` |

---

## Transaction Type Reference (_S.transactions)

All transaction description keys used throughout the codebase:

| Key | Used In | Direction | Description |
|-----|---------|-----------|-------------|
| `wages` | hospital.lua:794 | Expense | Monthly staff salaries |
| `heating` | hospital.lua:798 | Expense | Monthly heating costs |
| `loan_interest` | hospital.lua:803 | Expense | Monthly loan interest |
| `overdraft` | hospital.lua:808 | Expense | Monthly overdraft interest |
| `research` | hospital.lua:813 | Expense | Monthly research costs |
| `drug_cost` | hospital.lua:1306 | Expense | Per-treatment drug payment |
| `buy_land` | hospital.lua:592 | Expense | Land purchase |
| `build_room` | edit_room.lua:244 | Expense | Room construction |
| `buy_object` | place_objects.lua:187 | Expense | Object placement |
| `remove_room` | game_ui.lua:706 | Income | Room demolition (40% recovery) |
| `sell_object` | place_objects.lua:257 | Income | Object sale (40% recovery) |
| `hire_staff` | hospital.lua:1403 | Expense | Staff recruitment |
| `severance` | staff.lua:245 | Expense | Staff termination |
| `cure_colon` | hospital.lua:1249 | Income | Cure payment |
| `treat_colon` | hospital.lua:1247 | Income | Treatment payment |
| `insurance_colon` | hospital.lua:836 | Income | Insurance reimbursement |
| `drinks` | hospital.lua:1273 | Income | Vending machine |
| `jukebox` | (various) | Income | Jukebox revenue |
| `vaccination` | vaccinate.lua:96 | Expense | Vaccination cost |
| `machine_replacement` | machine.lua:353 | Expense | Broken machine replacement |
| `emergency_bonus` | hospital.lua:974 | Income | Emergency case bonus |
| `eoy_bonus_penalty` | annual_report.lua:308 | Income/Exp | End-of-year performance |
| `eoy_trophy_bonus` | annual_report.lua:305 | Income | Trophy award |
| `bank_loan` | bank_manager.lua:438 | Income | Loan received |
| `loan_repayment` | bank_manager.lua:456 | Expense | Loan repaid |
| `compensation` | epidemic.lua:502 | Income | Govt epidemic compensation |
| `epidemy_fine` | epidemic.lua:375 | Expense | Undeclared epidemic fine |
| `epidemy_coverup_fine` | epidemic.lua:499 | Expense | Epidemic cover-up fine |
| `personal_bonus` | staff_management.lua:647 | Expense | Staff bonus (10% wage) |
| `cheat` | cheats.lua:88 | Income | Cheat money |
| `advance_colon` | (research) | Expense | Research advance |
| `final_treat_colon` | (various) | Income | Final treatment |
| `research_bonus` | (various) | Income | Research milestone |
| `vip_award` | vip.lua:232 | Income | VIP patient reward |

---

## Level Config Parameters (level_config)

### Town-Level (level_config.towns[level] or level_config.town)
| Parameter | Used In | Description |
|-----------|---------|-------------|
| `StartCash` | hospital.lua:35,40 | Initial balance |
| `InterestRate` | hospital.lua:36,41 | Loan interest numerator (÷10000) |
| `StartRep` | hospital.lua:37,42 | Starting reputation |
| `OverdraftDiff` | hospital.lua:38,43 | Overdraft differential numerator (÷10000) |

### Global Game Values (level_config.gbv)
| Parameter | Used In | Default | Description |
|-----------|---------|---------|-------------|
| `SodaPrice` | hospital.lua:1272 | 20 | Soda vending price |
| `ScoreMaxInc` | hospital.lua:85-86 | 300 | Max monthly salary increase |
| `EpidemicConcurrentLimit` | hospital.lua:77 | 1 | Max simultaneous epidemics |

---

## Difficulty Thresholds (hospital.lua:94-100)

| Difficulty | Index | Under-Priced | Over-Priced |
|------------|-------|--------------|-------------|
| Easy | 1 | -0.3 | 0.4 |
| Normal | 2 | -0.4 | 0.3 |
| Hard | 3 | -0.5 | 0.2 |

Accessed via: `self.world.map:getDifficulty()` → 1, 2, or 3

---

## Campaign Data Fields (Hospital:getCampaignData/setCampaignData)

| Field | Type | Description |
|-------|------|-------------|
| `player_salary` | int | Current player salary |
| `message_popup` | bool | Whether message popup shown |
| `handyman_popup` | bool | Whether handyman popup shown |
| `hospital_littered` | bool | Hospital littered state |
| `has_seen_pay_rise` | bool | Pay rise notification seen |
| `policies` | table | Hospital policies |

---

## Insurance Balance Structure

```
self.insurance_balance = {
  [1] = { current_month, month_minus_1, month_minus_2 },  -- Company 1
  [2] = { current_month, month_minus_1, month_minus_2 },  -- Company 2
  [3] = { current_month, month_minus_1, month_minus_2 }   -- Company 3
}
```

**Rotation at month-end** (hospital.lua:839-841):
```lua
table.remove(company, 3)      -- Remove oldest (month_minus_2)
table.insert(company, 1, 0)   -- Insert new current_month = 0
-- Result: { 0, old_current, old_month_minus_1 }
```

---

## Price Calculation Formula Summary

```
getTreatmentPrice(disease):
  raw_price    = disease.casebook.disease.cure_price
  percentage   = disease.casebook.price           -- Player set (default 1.0)
  reputation   = disease.casebook.reputation OR hospital.reputation
  
  IF reputation >= 500:
    price = ceil(raw_price * (reputation / 500) * percentage)
  ELSE:
    price = ceil(raw_price * percentage)          -- Floor at base price
```

---

## Research Cost Formula

```
Daily Research Cost = ceil(3 * num_doctors_in_research * total_active_fraction / 100)

Where:
- num_doctors_in_research = Count of staff in research rooms
- total_active_fraction = Sum of tab.frac for non-dummy research categories
- Accumulated in hospital.acc_research_cost
- Paid monthly via onEndMonth()
```

---

## Heating Cost Formula

```
Daily Heating Cost = (radiator_heat * 10 * num_radiators * 7.50) / days_in_month

Where:
- radiator_heat = hospital.heating.radiator_heat [0.0-1.0]
- num_radiators = hospital:countRadiators()
- 7.50 = Base cost per radiator per 10% heat per month
- Accumulated in hospital.acc_heating
- Paid monthly via onEndMonth()
```

---

## Interest Formulas

```
Daily Loan Interest     = loan * interest_rate / 365
Daily Overdraft Interest = abs(balance) * overdraft_interest_rate / 365  (only if balance < 0)

Where:
- interest_rate = level_config.InterestRate / 10000
- overdraft_interest_rate = interest_rate + level_config.OverdraftDiff / 10000
- Both accumulated daily, paid monthly (rounded)
```

---

## Max Loan Formula

```
max_loan = floor(hospital.value * 0.33 / 5000) * 5000 + 10000

Where:
- hospital.value = parcel_price + 20000 + room/object values
- 33% of asset value
- Rounded down to nearest $5,000
- Plus $10,000 base
```

---

*Map Version: 1.0*
*Generated from CorsixTH source analysis*
*Primary files: hospital.lua, room.lua, research_department.lua, patient.lua, bank_manager.lua, annual_report.lua, epidemic.lua*


## Related Pages

- [[07-financial-system/SUMMARY]]
- [[07-financial-system/CHECKLIST]]
- [[07-financial-system/SCAFFOLD]]
