# CorsixTH Financial System - Pre-Fix Checklist

> **Purpose**: Comprehensive checklist to verify before making any changes to the financial system. Ensures regressions are caught and edge cases handled.

---

## 🔴 CRITICAL - Must Verify Before Any Change

### Core Money Operations
- [ ] `spendMoney()` correctly decreases balance and logs transaction
- [ ] `receiveMoney()` correctly increases balance and logs transaction
- [ ] Both respect `world.free_build_mode` (no-op when true)
- [ ] `changeValue` parameter correctly adjusts `hospital.value`
- [ ] Transaction log maintains max 20 entries (FIFO)
- [ ] Transaction records include: day, month, balance, spend/receive, description

### Treatment Pricing (`getTreatmentPrice`)
- [ ] Formula: `ceil(raw_price * (reputation/500) * percentage)` when reputation ≥ 500
- [ ] Formula: `ceil(raw_price * percentage)` when reputation < 500 (NO multiplier)
- [ ] Disease-specific reputation overrides hospital reputation when set
- [ ] Price percentage from `casebook.price` (player-adjustable)
- [ ] Raw price from `disease.cure_price` (disease definition)
- [ ] Returns 0 for unknown/missing disease

### Insurance System
- [ ] 3 insurance companies selected at hospital creation (weighted random)
- [ ] `insurance_balance` = 3 companies × 3 months (current, -1, -2)
- [ ] `addInsuranceMoney()` accumulates in slot 1 (current month)
- [ ] Month-end rotation: slot 3 → PAID OUT, slot 2→3, slot 1→2, new slot 1=0
- [ ] 2-month delay: April treatments paid July 1st
- [ ] Insurance payments do NOT trigger `computePriceLevelImpact()`
- [ ] Direct payments DO trigger `computePriceLevelImpact()`
- [ ] Both payment types increment `casebook.money_earned`

---

## 🟠 HIGH - Financial Mechanics

### Monthly Payments (`onEndMonth`)
- [ ] **Wages**: Sum all `staff.profile.wage`, spend via `wages` transaction
- [ ] **Heating**: Pay rounded `acc_heating`, reset to 0
- [ ] **Loan Interest**: Pay rounded `acc_loan_interest`, reset to 0
- [ ] **Overdraft**: Pay rounded `acc_overdraft`, reset to 0
- [ ] **Research**: Pay rounded `acc_research_cost`, reset to 0
- [ ] **Player Salary**: Calculate and increment `player_salary`
- [ ] **Insurance**: Process all 3 companies, rotate buffers
- [ ] **Statistics**: Record monthly stats, reset `money_in`/`money_out`

### Daily Accruals (`onDayChange`)
- [ ] Loan interest: `loan * interest_rate / 365` → `acc_loan_interest`
- [ ] Overdraft interest: `abs(balance) * overdraft_rate / 365` → `acc_overdraft` (only if balance < 0)
- [ ] Heating: `(radiator_heat * 10 * num_radiators * 7.50) / days_in_month` → `acc_heating`
- [ ] Research: Call `research:researchCost()` daily

### Loan System
- [ ] Max loan = `floor(value * 0.33 / 5000) * 5000 + 10000`
- [ ] Increments of $5,000 (Ctrl = max available)
- [ ] Loan increase: `loan += amount` + `receiveMoney(amount, bank_loan)`
- [ ] Loan repayment: `loan -= amount` + `spendMoney(amount, loan_repayment)`
- [ ] Cannot exceed max loan
- [ ] Cannot repay more than balance allows

### Overdraft System
- [ ] No hard limit on negative balance
- [ ] Interest rate = `interest_rate + overdraft_differential/10000`
- [ ] Daily accrual when balance < 0
- [ ] Monthly payment via `acc_overdraft`

---

## 🟡 MEDIUM - Price Sensitivity & Reputation

### Price Distortion Calculation (`Patient:getPriceDistortion`)
- [ ] Weights: happiness=0.1, reputation=0.6, effectiveness=0.3
- [ ] Expected price = weighted sum of normalized factors
- [ ] Actual price level = `((casebook.price - 0.5) / 3) * 2`
- [ ] Distortion = actual - expected
- [ ] Happiness impact = `-(distortion / 2)`

### Reputation Impact (`computePriceLevelImpact`)
- [ ] Underpriced (distortion < under_threshold): 1% chance → reputation loss + advisory
- [ ] Overpriced (distortion > over_threshold): 1% chance → reputation loss + advisory
- [ ] Fair (|distortion| ≤ 0.15): 0.5% chance → "fair" advisory only
- [ ] Advisory only shown if `casebook.price < 1` for underpriced
- [ ] Patient happiness always affected by `-(distortion/2)`

### Difficulty Thresholds
- [ ] Easy: under=-0.3, over=0.4
- [ ] Normal: under=-0.4, over=0.3
- [ ] Hard: under=-0.5, over=0.2
- [ ] Loaded from `hospital.lua:94-100` based on `world.map:getDifficulty()`

---

## 🟢 LOW - Edge Cases & Integration

### COST_RECOVERY (40%)
- [ ] Defined in `room.lua:26` as `0.40`
- [ ] Room demolition: 40% value recovery via `sell_object` transaction
- [ ] Object sale: 40% cost recovery
- [ ] Hospital value reduced by full amount, 40% returned as cash

### Research Costs
- [ ] Daily cost = `ceil(3 * doctors * total_fraction / 100)`
- [ ] Only active (non-dummy) research categories counted
- [ ] Doctors counted in research rooms only
- [ ] Accumulated in `acc_research_cost`, paid monthly

### Drug Costs
- [ ] Per-treatment cost from `casebook.drug_cost`
- [ ] Random drug company name in transaction description
- [ ] Skipped if cost is 0 or nil

### Other Income Sources
- [ ] Sodas: `level_config.gbv.SodaPrice` (default $20)
- [ ] Emergency bonus: `emergency_bonus` transaction
- [ ] End-of-year: `eoy_trophy_bonus`, `eoy_bonus_penalty`
- [ ] Government compensation: `compensation` (epidemics)
- [ ] Research bonus: `research_bonus`
- [ ] VIP award: `vip_award`
- [ ] Jukebox: `jukebox`

### Other Expenses
- [ ] Machine replacement: `machine_replacement`
- [ ] Severance pay: `severance` (1x wage)
- [ ] Personal bonus: `personal_bonus` (10% wage)
- [ ] Vaccination: `vaccination`
- [ ] Epidemic fines: `epidemy_fine`, `epidemy_coverup_fine`
- [ ] Land purchase: `buy_land`
- [ ] Room construction: `build_room`
- [ ] Object placement: `buy_object`

---

## 🧪 TESTING REQUIREMENTS

### Unit Tests (Busted)
- [ ] `spendMoney` / `receiveMoney` basic operations
- [ ] Free build mode no-op behavior
- [ ] Transaction logging (limit, fields, ordering)
- [ ] `getTreatmentPrice` with various reputation/percentage combos
- [ ] Insurance accumulation and 2-month rotation
- [ ] Monthly payment processing (all 5 categories)
- [ ] Daily accrual calculations (loan, overdraft, heating, research)
- [ ] Loan max calculation and operations
- [ ] Price distortion calculation
- [ ] Reputation impact triggers
- [ ] COST_RECOVERY on room/object sale
- [ ] Research cost accumulation
- [ ] Drug cost payment

### Integration Tests
- [ ] Full month cycle: daily accruals → month-end payments
- [ ] Treatment → insurance → 2-month delay → payout
- [ ] Loan taken → daily interest → monthly payment → repayment
- [ ] Overdraft scenario: negative balance → interest → payment
- [ ] Price change → patient happiness → reputation impact
- [ ] Difficulty change → threshold adjustment

### Regression Tests
- [ ] Save/load preserves all financial state
- [ ] Multi-hospital (campaign) financial isolation
- [ ] Free build mode toggling
- [ ] Level config changes (interest rates, starting cash)

---

## 📋 PRE-COMMIT VERIFICATION

Before committing any financial system changes:

### Code Review
- [ ] All modified functions have corresponding test coverage
- [ ] No hardcoded values that should come from level config
- [ ] Transaction descriptions use `_S.transactions.*` keys
- [ ] Floating dollar signs shown for patient payments (`newFloatingDollarSign`)
- [ ] Balance changes reflected in `money_in` / `money_out`
- [ ] Hospital `value` updated correctly for asset purchases/sales

### Edge Case Validation
- [ ] Zero/negative amounts handled gracefully
- [ ] Missing disease casebook entries return 0 price
- [ ] Empty staff list doesn't crash wage calculation
- [ ] No research rooms = $0 research cost
- [ ] Insurance payout with negative balance works
- [ ] Rounding behavior consistent (math.round)

### Performance
- [ ] No O(n²) loops in monthly processing
- [ ] Transaction log capped at 20
- [ ] Daily accruals are O(1) operations

### Localization
- [ ] All transaction types have English strings in `english.lua`
- [ ] New transaction keys added to all language files

---

## 🔧 COMMON PITFALLS TO AVOID

| Pitfall | Prevention |
|---------|------------|
| Forgetting `free_build_mode` check | Always wrap balance changes in `if not world.free_build_mode then` |
| Using wrong reputation in pricing | Use `casebook.reputation or hospital.reputation` |
| Breaking insurance rotation | Test 3-month cycle explicitly |
| Integer vs float interest | Use `math.round()` before spending accrued amounts |
| Price floor at reputation 500 | Test reputation 499, 500, 501 |
| Difficulty thresholds | Verify all 3 difficulty levels |
| Transaction log overflow | Verify 20-entry limit maintained |
| Campaign carryover | Check `getCampaignData`/`setCampaignData` |

---

## 📝 CHANGE DOCUMENTATION TEMPLATE

When making changes, document:

```
## Change: [Brief description]

### Files Modified
- Lua/hospital.lua:XXX-YYY
- Lua/room.lua:ZZZ

### Financial Impact
- [ ] Income source added/removed/modified
- [ ] Expense category added/removed/modified
- [ ] Price calculation changed
- [ ] Insurance mechanics changed
- [ ] Loan/overdraft terms changed
- [ ] Reputation/price sensitivity changed

### Tests Added/Updated
- [ ] Unit tests for new behavior
- [ ] Regression tests for modified behavior
- [ ] Edge case tests

### Config Changes
- [ ] Level config parameters added
- [ ] Difficulty thresholds modified
- [ ] Transaction keys added to languages

### Verification
- [ ] All existing tests pass
- [ ] Manual playtest: [scenario]
- [ ] Save/load cycle tested
```

---

*Checklist Version: 1.0*
*Last Updated: 2026*
*Applies to: CorsixTH Financial System (hospital.lua, room.lua, research_department.lua, patient.lua)*
