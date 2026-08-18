# Reputation System - Pre-Fix Checklist

Use this checklist before making any changes to the reputation system to ensure consistency and prevent regressions.

---

## Pre-Change Analysis

### 1. Identify Affected Reputation Sources
- [ ] Which reputation change reason(s) are affected? (cured, death, kicked, emergency_success, emergency_failed, over_priced, under_priced, room_crash, autopsy_discovered, year_end)
- [ ] Is this a global reputation change, disease-specific, or both?
- [ ] Does it bypass probability gating (uses `unconditionalChangeReputation` directly)?

### 2. Probability Gating Impact
- [ ] Current reputation range where change occurs (below/above 500)
- [ ] Expected acceptance probability at current reputation (use `getReputationChangeLikelihood()`)
- [ ] Will the change be gated? Test both paths (allowed vs rejected)
- [ ] **Critical:** Disease reputation updates **even when global change is gated** (hospital.lua:1636-1639)

### 3. Bounds Checking
- [ ] Does change respect `reputation_min` (0) and `reputation_max` (1000)?
- [ ] Test edge cases: reputation at 0, 500, 1000
- [ ] Verify clamping in `unconditionalChangeReputation()`

### 4. Downstream Effects
- [ ] Patient spawn rate impact (world.lua:1227-1239)
- [ ] Treatment pricing multiplier (hospital.lua:1277-1285)
- [ ] Staff salary negotiations (hospital.lua:817-820)
- [ ] Trophy eligibility (hospital.lua:1655-1663)
- [ ] Emergency outcomes
- [ ] Epidemic outcomes

---

## Code Change Checklist

### changeReputation() Modifications (hospital.lua:1617-1640)
- [ ] Reason string matches `reputation_changes` table or is handled specially
- [ ] `valueChange` parameter used correctly for variable amounts
- [ ] `autopsy_discovered` special case handled (percentage-based)
- [ ] Disease reputation update occurs **after** probability gate check
- [ ] Disease casebook exists for the disease (initialize if needed)

### unconditionalChangeReputation() Modifications (hospital.lua:1642-1665)
- [ ] Reputation clamped to [0, 1000]
- [ ] Trophy status (`has_impressive_reputation`) updated correctly
- [ ] Level config `awards_trophies.Reputation` threshold checked

### isReputationChangeAllowed() Modifications (hospital.lua:1667-1677)
- [ ] Threshold logic at 500 preserved
- [ ] Zero change always allowed
- [ ] Returns boolean correctly

### getReputationChangeLikelihood() Modifications (hospital.lua:1679-1701)
- [ ] Quadratic coefficients correct (a=0.000004008, b=0.004008, c=1)
- [ ] Curve passes through (0,0), (500,1), (1000,0) for acceptance
- [ ] Returns value in [0, 1] range

### computePriceLevelImpact() Modifications (hospital.lua:2241-2260)
- [ ] Price distortion calculated via `patient:getPriceDistortion(casebook)`
- [ ] Happiness adjustment: `-(price_distortion / 2)`
- [ ] Under-priced threshold check with 1% random chance
- [ ] Over-priced threshold check with 1% random chance
- [ ] Fair price advice at 0.5% chance when |distortion| ≤ 0.15
- [ ] Difficulty thresholds respected (Easy/Normal/Hard)

---

## Testing Checklist

### Unit Tests (SCAFFOLD.lua)
- [ ] All reputation change values match table
- [ ] Probability gating at 500 threshold
- [ ] Quadratic likelihood curve key points
- [ ] Bounds clamping at 0 and 1000
- [ ] Price distortion calculation
- [ ] Epidemic outcome reputation hits
- [ ] Disease-specific reputation updates

### Integration Tests
- [ ] Patient cured → +1 reputation → disease reputation +1
- [ ] Patient death → -4 reputation → disease reputation -4
- [ ] Emergency success → +15 reputation
- [ ] Emergency failure → -20 reputation
- [ ] Staff fired → -3 reputation
- [ ] Patient sent home → -3 reputation
- [ ] Overpriced treatment → -2 reputation (1% chance)
- [ ] Underpriced treatment → +1 reputation (1% chance)
- [ ] Room crash → -50 reputation
- [ ] Autopsy discovered → -70% reputation (or config %)
- [ ] Year-end reputation adjustment
- [ ] Epidemic success → compensation, no rep hit
- [ ] Epidemic partial failure → fine/100 rep hit
- [ ] Epidemic evacuation → 33% reputation loss

### Edge Case Tests
- [ ] Reputation at 0: positive changes allowed, negative gated at 0%
- [ ] Reputation at 500: all changes 100% allowed
- [ ] Reputation at 1000: negative changes allowed, positive gated at 0%
- [ ] Disease reputation updates when global gated
- [ ] Multiple rapid reputation changes
- [ ] Reputation change during emergency
- [ ] Reputation change during epidemic

### Regression Tests
- [ ] Patient spawn rates at various reputation levels
- [ ] Treatment pricing at various reputation levels
- [ ] Trophy unlock/loss conditions
- [ ] Annual report reputation calculation
- [ ] Cheat "max_reputation" still works

---

## Specific Scenario Checklists

### Adding New Reputation Reason
1. [ ] Add entry to `reputation_changes` table (hospital.lua:1606-1615)
2. [ ] Add comment explaining when it triggers
3. [ ] Call `changeReputation("new_reason", disease)` at trigger point
4. [ ] Add test case in SCAFFOLD.lua
5. [ ] Update this checklist

### Modifying Probability Gating
1. [ ] Verify quadratic curve still passes key points
2. [ ] Test at reputation 0, 100, 250, 380, 500, 620, 750, 900, 1000
3. [ ] Verify disease reputation still updates when gated
4. [ ] Check downstream effects (spawn rate, pricing, trophies)

### Changing Price Thresholds
1. [ ] Update `under_priced_thresholds` and `over_priced_thresholds` (hospital.lua:94-100)
2. [ ] Verify difficulty scaling still works
3. [ ] Test price distortion calculation with new thresholds
4. [ ] Verify 1%/1%/0.5% random chances unchanged

### Modifying Epidemic Reputation
1. [ ] Check `reputation_loss_minimum` and `evacuation_minimum` config
2. [ ] Verify fine calculation (`calculateInfectedFine`)
3. [ ] Verify `getBaseReputationFromFine` (fine/100)
4. [ ] Test all 4 outcome paths (success, minor fail, major fail, evacuation)
5. [ ] Verify declaration vs cover-up paths

---

## Documentation Updates

- [ ] Update SUMMARY.md with any new reasons or changed values
- [ ] Update MAP.md with new line numbers
- [ ] Update SCAFFOLD.lua with new test cases
- [ ] Update inline code comments (LuaDoc format)
- [ ] Update AGENTS.md if behavior changes significantly

---

## Performance Considerations

- [ ] `getReputationChangeLikelihood()` called frequently - avoid heavy computation
- [ ] `computePriceLevelImpact()` called per treatment - keep lightweight
- [ ] Random number generation for price impact (1%, 0.5%) - acceptable frequency
- [ ] Disease reputation table lookups - O(1) with string keys

---

## Multiplayer / Campaign Considerations

- [ ] Reputation persists across levels in campaign (`getCampaignData`/`setCampaignData`)
- [ ] AI hospitals don't use reputation system (only player hospital)
- [ ] Cheats: `max_reputation` sets to 1000 via `unconditionalChangeReputation`
- [ ] Save/load includes reputation and disease_casebook

---

## Sign-Off

Before merging any reputation system changes:

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Edge cases tested manually
- [ ] No regression in spawn rates, pricing, trophies
- [ ] Documentation updated
- [ ] Code reviewed by another developer

---

## Quick Reference: Reputation Change Values

| Reason | Value | Gated? | Disease Rep? |
|--------|-------|--------|--------------|
| cured | +1 | Yes | Yes |
| death | -4 | Yes | Yes |
| kicked | -3 | Yes | Yes |
| emergency_success | +15 | Yes | Yes |
| emergency_failed | -20 | Yes | Yes |
| over_priced | -2 | Yes | No* |
| under_priced | +1 | Yes | No* |
| room_crash | -50 | Yes | No* |
| autopsy_discovered | -70% | Yes | Yes |
| year_end | Variable | Yes | No |

*Price and room changes don't have associated disease

---

## Quick Reference: Probability Gate Thresholds

| Reputation | Positive Change | Negative Change |
|------------|-----------------|-----------------|
| 0 | **100%** (always) | ~0% (never) |
| 100 | ~36% | ~64% |
| 250 | ~64% | ~36% |
| 380 | ~80% | ~20% |
| **500** | **100%** | **100%** |
| 620 | ~20% | ~80% |
| 750 | ~36% | ~64% |
| 900 | ~64% | ~36% |
| 1000 | ~0% (never) | **100%** (always) |

