# CorsixTH Research System — Pre-Fix Checklist

**Use before any research-related code changes.**

---

## 🔴 Critical: Must Verify Before Any Change

### 1. Point Distribution Integrity
- [ ] `initResearch()` — 5 categories initialized correctly (cure, diagnosis, drugs, improvements, specialisation)
- [ ] Fractions sum to 100 (or 0 if no research)
- [ ] Categories without targets get 0% fraction
- [ ] Remainder points assigned to first active category (line 116)
- [ ] `addResearchPoints()` — divisor applied correctly (`ResearchPointsDivisor` default 5)
- [ ] Variance `math.t_random(0.75, 1, 1.25)` applied per category
- [ ] Dummy/drain categories excluded from point distribution
- [ ] Finished categories (frac=0) excluded from distribution

### 2. Auto-Selection Logic
- [ ] **Drugs**: Selects discovered drug with LOWEST `cure_effectiveness` (worst first)
- [ ] **Improvements**: Selects discovered machine with LOWEST `start_strength` (weakest first)
- [ ] **Cure/Diagnosis**: Selects first undiscovered object in category (iteration order)
- [ ] Undiscovered targets → set `current = drain` (blocks progression)
- [ ] Category finishes → `frac = 0`, `current = nil`, triggers `redistributeResearchPoints()`
- [ ] Advice notification fired on category completion

### 3. Drug Improvement Mechanics
- [ ] `decideImprovement()` — Correct priority: both maxed → false; effectiveness maxed → cost; cost min → effectiveness; else random
- [ ] 1/7 chance for "both" improvement
- [ ] `decreaseDrugCost()` — 10% reduction, floored, minimum `MinDrugCost` (50)
- [ ] `improveEffectiveness()` — +`DrugImproveRate` (5), capped at 100
- [ ] Specialisation cleared when drug hits 100% effectiveness
- [ ] `nextResearch("drugs")` called after improvement

### 4. Machine Improvement Mechanics
- [ ] Alternates: strength_imp > cost_imp → cost improvement; else strength
- [ ] Strength: +`ResearchIncrement` (2), capped at `MaxObjectStrength` (20)
- [ ] Cost: -12.5% (`math.round(cost*0.125/10)*10`), rounded to nearest 10
- [ ] Room `build_cost` reduced for ALL rooms using this machine
- [ ] Specialisation cleared when machine hits max strength
- [ ] `nextResearch("improvements")` called after improvement

### 5. Object Discovery & Room Unveiling
- [ ] `discoverObject()` sets `discovered = true`
- [ ] Iterates ALL undiscovered rooms
- [ ] Room unveiled only when ALL `objects_needed` are discovered
- [ ] Automatic discovery at `WhenAvail` month (`checkAutomaticDiscovery`)
- [ ] Different advice for automatic vs manual discovery
- [ ] Triggers improvements research switch for newly discovered machines

### 6. Concentrate Research
- [ ] Toggles off if same disease clicked again
- [ ] Clears previous concentration on other diseases
- [ ] Finds treatment room (last in `treatment_rooms` array)
- [ ] Finds associated object in room's `objects_needed`
- [ ] Drug mode: specialisation = disease (if object discovered)
- [ ] Machine mode: specialisation = object (discovery or improvement)
- [ ] Specialisation costs NO extra money (dummy excluded from cost calc)
- [ ] Auto-concentration on first available disease (`setResearchConcentration`)

### 7. Research Cost Calculation
- [ ] Formula: `ceil(3 * num_doctors * active_frac / 100)`
- [ ] Only counts doctors in research rooms (`room_info.id == "research"`)
- [ ] Excludes dummy specialisation and finished categories
- [ ] Accumulates in `hospital.acc_research_cost`

### 8. Research Requirements (Thresholds)
- [ ] Objects: `level_config.objects[thob].RschReqd` or fallback to expertise
- [ ] Drugs: `expertise[expertise_id].RschReqd`
- [ ] Improvements: base * (10% + 10% * cost_imp) / 100
- [ ] Autopsy: `required * AutopsyRschPercent / 100` (33%)

### 9. Redistribution Logic
- [ ] Triggered when category finishes (no more targets)
- [ ] Specialisation points subtracted before redistribution
- [ ] If sum==0: even distribution among active categories
- [ ] Else: proportional redistribution `floor(total * old_frac / sum)`
- [ ] Remainder → category with highest old fraction
- [ ] Specialisation points added back to total

---

## 🟡 Important: Test These Scenarios

### Edge Cases
- [ ] No research targets at level start (total=0)
- [ ] Only specialisation active (all other categories done)
- [ ] All drugs at 100% effectiveness, cost at minimum
- [ ] All machines at max strength (20)
- [ ] Object with no RschReqd and no research_fallback
- [ ] Save game migration (`afterLoad` for versions < 238)

### Integration Flows
- [ ] Autopsy → research points → object discovery → room unveiling
- [ ] Disease discovery → drug research auto-start → concentration
- [ ] Machine discovery → improvements research auto-switch
- [ ] Concentrate research on drug → improvement → specialisation clear at 100%
- [ ] Concentrate research on machine → discovery/improvement → specialisation clear at max
- [ ] Multiple research rooms with multiple doctors
- [ ] Free build mode (cost = 0 for objects)

### Config Variations
- [ ] Different `ResearchPointsDivisor` values
- [ ] Different `DrugImproveRate` values
- [ ] Different `ResearchIncrement` values
- [ ] Different `MaxObjectStrength` values
- [ ] Different `RschImproveCostPercent` / `RschImproveIncrementPercent`

---

## 🟢 Nice to Have: Validate Behaviour

### UI/Advice
- [ ] Correct advice strings for each event type
- [ ] Research window updates on category change
- [ ] Casebook shows concentration flag correctly

### Performance
- [ ] `nextResearch` doesn't iterate excessively
- [ ] `concentrateResearch` object lookup efficient
- [ ] `improveMachine` room cost update doesn't scan all rooms unnecessarily

### Save/Load
- [ ] `research_progress` serializes correctly
- [ ] `research_policy` serializes correctly
- [ ] `drain` dummy object handled properly
- [ ] `afterLoad` migrations work for old saves

---

## 📝 Change Impact Assessment

For each proposed change, mark affected areas:

| Change Area | Point Dist | Auto-Select | Drug Improv | Machine Improv | Discovery | Concentrate | Cost | Requirements | Redistrib |
|-------------|------------|-------------|-------------|----------------|-----------|-------------|------|--------------|-----------|
| gbv config  | ☐          | ☐           | ☐           | ☐              | ☐         | ☐           | ☐    | ☐            | ☐         |
| expertise   | ☐          | ☐           | ☐           | ☐              | ☐         | ☐           | ☐    | ☑            | ☐         |
| objects     | ☐          | ☑           | ☐           | ☑              | ☑         | ☑           | ☐    | ☑            | ☐         |
| diseases    | ☐          | ☑           | ☑           | ☐              | ☐         | ☑           | ☐    | ☐            | ☐         |
| rooms       | ☐          | ☐           | ☐           | ☑              | ☑         | ☑           | ☐    | ☐            | ☐         |
| policy init | ☑          | ☐           | ☐           | ☐              | ☐         | ☐           | ☑    | ☐            | ☐         |
| addPoints   | ☑          | ☐           | ☐           | ☐              | ☐         | ☐           | ☐    | ☐            | ☐         |
| nextResearch| ☐          | ☑           | ☐           | ☐              | ☐         | ☐           | ☐    | ☐            | ☑         |
| improveDrug | ☐          | ☐           | ☑           | ☐              | ☐         | ☑           | ☐    | ☐            | ☐         |
| improveMach | ☐          | ☐           | ☐           | ☑              | ☐         | ☑           | ☐    | ☐            | ☐         |
| discoverObj | ☐          | ☐           | ☐           | ☐              | ☑         | ☐           | ☐    | ☐            | ☐         |
| concentrate | ☐          | ☐           | ☐           | ☐              | ☐         | ☑           | ☑    | ☐            | ☐         |
| researchCost| ☐          | ☐           | ☐           | ☐              | ☐         | ☐           | ☑    | ☐            | ☐         |
| getRequired | ☐          | ☐           | ☐           | ☐              | ☐         | ☐           | ☐    | ☑            | ☐         |
| redistrib   | ☐          | ☐           | ☐           | ☐              | ☐         | ☐           | ☐    | ☐            | ☑         |

---

## ✅ Sign-Off

Before merging research changes:

- [ ] All Critical (🔴) items verified manually or via tests
- [ ] All Important (🟡) scenarios tested
- [ ] Busted test suite passes (`busted SCAFFOLD.lua`)
- [ ] No regression in existing levels/campaigns
- [ ] Save/load tested with pre-change saves
- [ ] Multiplayer sync verified (if applicable)
- [ ] Performance impact measured (<5ms per research tick)

**Reviewer:** _______________ **Date:** _______________ **Commit:** _______________
