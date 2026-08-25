# Heating System Changes - Pre-Fix Checklist

Use this checklist before making any changes to the heating system in CorsixTH.

---

## 🔍 Code Understanding

- [ ] Read and understand `Lua/hospital.lua:107-112` (heating state initialization)
- [ ] Read and understand `Lua/hospital.lua:647-666` (boilerBreakdown function)
- [ ] Read and understand `Lua/hospital.lua:669-694` (_fixBoiler function)
- [ ] Read and understand `Lua/hospital.lua:761-781` (onEndDay: repair, disasters, daily cost)
- [ ] Read and understand `Lua/hospital.lua:796-800` (onEndMonth: monthly payment)
- [ ] Read and understand `Lua/hospital.lua:639-643` (daysUntilNextDisaster)
- [ ] Read and understand `Lua/hospital.lua:1508-1510` (countRadiators)
- [ ] Read and understand `Lua/hospital.lua:1453-1462` (countStaffOfCategory)
- [ ] Read and understand `Lua/hospitals/player_hospital.lua:456-465` (adviseBoilerBreakdown)
- [ ] Read and understand `Lua/dialogs/fullscreen/town_map.lua:195-198, 213-218, 334-350` (UI)
- [ ] Read and understand `Lua/hospital.lua:392-406` (save/load migration v142)

---

## 🎯 Change Impact Analysis

### For ANY heating-related change, verify:

#### Breakdown Logic
- [ ] Does the change affect when boilers can break? (opened, radiators > 0, handyman ratio)
- [ ] Does it affect the 8:1 handyman threshold?
- [ ] Does it affect disaster-triggered breakdowns (types 2/3)?
- [ ] Does it affect the random repair count (10-30)?

#### Repair Logic
- [ ] Does it affect the three repair speed tiers?
  - [ ] < 5:1 ratio → -3/day
  - [ ] 5:1 to < 8:1 → -2/day
  - [ ] >= 8:1 → -1/day
- [ ] Does it affect restoration of saved_radiator_heat?
- [ ] Does it affect the boiler fixed advice message?

#### Cost Calculation
- [ ] Does it affect the daily cost formula: `(radiator_heat * 10 * num_radiators * 7.50) / days_in_month`?
- [ ] Does it affect monthly accumulation in `acc_heating`?
- [ ] Does it affect the monthly payment at `onEndMonth`?
- [ ] Does it affect the town map UI display (monthly cost, floored)?

#### Heat Adjustment
- [ ] Does it affect the 0.1-1.0 range?
- [ ] Does it respect the `heating_broke` lock?
- [ ] Does it round correctly (floor for display, 0.1 increments for adjustment)?

#### Disaster System
- [ ] Does it affect `disasterless_days` countdown?
- [ ] Does it affect `daysUntilNextDisaster` difficulty scaling?
- [ ] Does it affect disaster type distribution (1/3 each)?
- [ ] Vomit wave (type 4) - still TODO?

#### Save/Load
- [ ] Does it require migration for existing saves?
- [ ] Are all heating fields properly serialized?
- [ ] Does v142 migration still work?

---

## 🧪 Testing Requirements

### Unit Tests (Busted)
- [ ] Test boiler breakdown conditions (all 4 guards)
- [ ] Test breakdown at max heat (1) and min heat (0)
- [ ] Test repair countdown at all three speed tiers
- [ ] Test repair completion restores heat and clears flag
- [ ] Test daily cost calculation with various inputs
- [ ] Test monthly payment rounding
- [ ] Test disaster countdown and triggering
- [ ] Test heat adjustment bounds (0.1 to 1.0)
- [ ] Test heat adjustment blocked when broken
- [ ] Test save/load migration

### Integration Tests
- [ ] Full cycle: disaster → breakdown → daily repairs → fixed → monthly bill
- [ ] Handyman hiring mid-repair accelerates fix
- [ ] Heat change during normal operation affects costs
- [ ] Multiple disasters over time
- [ ] Save/load preserves heating state correctly

### Manual Testing Scenarios
- [ ] Start new hospital, place radiators, verify no breakdown with enough handymen
- [ ] Place many radiators, no handymen, wait for breakdown
- [ ] Adjust heat via town map, verify cost updates
- [ ] Let boiler break, don't hire handymen, verify slow repair
- [ ] Hire handymen during repair, verify speedup
- [ ] Let month end, verify heating bill paid
- [ ] Load old save (pre-v142), verify migration works
- [ ] Test on all three difficulty levels

---

## 📝 Documentation Updates

If changing heating behavior, update:
- [ ] `SUMMARY.md` (this research document)
- [ ] In-code comments (LuaDoc format)
- [ ] `docs/` or `wiki/` if applicable
- [ ] Changelog entry

---

## 🔄 Regression Checklist

After changes, verify these still work:
- [ ] Hospital opens without immediate boiler breakdown
- [ ] Hospital with 0 radiators has no heating costs or breakdowns
- [ ] Hospital with radiators but 0 handymen eventually breaks down
- [ ] Disaster system still triggers breakdowns periodically
- [ ] Repair completes and restores previous heat setting
- [ ] Monthly heating bill matches accumulated daily costs
- [ ] Town map UI shows correct heat level and cost
- [ ] Heat adjustment buttons work and update display
- [ ] Advisor messages play for breakdown (min/max) and repair
- [ ] Save game → load game preserves all heating state
- [ ] Free build mode shows $0 heating cost

---

## ⚠️ Common Pitfalls

| Pitfall | Prevention |
|---------|------------|
| Forgetting `heating_broke` check in heat adjustment | Always check `if not heating.heating_broke then` |
| Off-by-one in repair countdown | Test boundary: exactly 0, negative values |
| Integer vs float division | Use `/` for float, `//` or `math.floor` for int |
| Month length variation | Use `world:date():lastDayOfMonth()` not hardcoded 30 |
| Randomness in tests | Seed `math.randomseed()` or mock `math.random` |
| Migration breaking old saves | Test v142 migration with missing fields |
| Disaster type 4 (vomit) | Keep TODO comment, don't implement partially |

---

## 🚀 Deployment Checklist

- [ ] All tests pass (unit + integration)
- [ ] Manual testing scenarios verified
- [ ] No linting errors (luacheck)
- [ ] Code reviewed by another developer
- [ ] Changelog updated
- [ ] Version bump if behavioral change

---

## 📋 Quick Reference: Key Formulas

```
Boiler Breaks If:       opened AND NOT broken AND radiators > 0 AND radiators > 8 * handymen
Repair Speed:           radiators < 5*handymen: -3/day
                        5*handymen <= radiators < 8*handymen: -2/day
                        radiators >= 8*handymen: -1/day
Daily Cost:             (radiator_heat * 10 * num_radiators * 7.50) / days_in_month
Monthly Cost:           radiator_heat * 10 * num_radiators * 7.50
Disaster Interval:      {300, 200, 150}[difficulty] + random(-10, 10)
Heat Adjustment:        0.1 to 1.0 in 0.1 steps (blocked if broken)
```

---

*Checklist version: 1.0 | For CorsixTH heating system modifications*
