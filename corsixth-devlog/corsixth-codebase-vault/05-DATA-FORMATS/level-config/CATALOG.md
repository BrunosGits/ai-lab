# Level Config Catalog

> Source: `CorsixTH/Lua/base_config.lua` — Game configuration and level parameters

## Town Configuration (per Level)

| Level | Start Cash | Interest Rate | Start Rep | Overdraft Diff |
|-------|-----------|---------------|-----------|----------------|
| 1 | 40,000 | 1.0% | 500 | 200 |
| 2 | 40,000 | 2.0% | 500 | 200 |
| 3 | 50,000 | 3.0% | 500 | 200 |
| 4 | 50,000 | 4.0% | 500 | 200 |
| 5 | 50,000 | 5.0% | 500 | 200 |
| 6 | 50,000 | 6.0% | 500 | 200 |
| 7 | 50,000 | 7.0% | 500 | 200 |
| 8 | 60,000 | 7.0% | 500 | 200 |
| 9 | 60,000 | 8.0% | 500 | 200 |
| 10 | 60,000 | 8.0% | 500 | 200 |
| 11 | 70,000 | 9.0% | 500 | 200 |
| 12 | 70,000 | 9.0% | 500 | 200 |
| 13 | 70,000 | 9.0% | 500 | 200 |

## Global Balance Values (gbv)

### General

| Parameter | Value | Description |
|-----------|-------|-------------|
| SalaryAbilityDivisor | 10 | Divides ability for extra salary addition |
| ResearchPointsDivisor | 5 | Divides research input for research points |
| StartRating | 100 | Initial drug research rating |
| StartCost | 100 | Initial drug research cost |
| MinDrugCost | 50 | Minimum drug cost |
| MaxObjectStrength | 20 | Max object strength via research |
| ResearchIncrement | 2 | Object strength increase per research |
| ScoreMaxInc | 300 | × Start Score for ceiling of normal score increases |
| VacCost | 50 | Cost per vaccination |
| SodaPrice | 20 | Drinks machine soda cost |

### Contagion

| Parameter | Value | Description |
|-----------|-------|-------------|
| HowContagious | 25 | Max contagion randomness |
| ContagiousSpreadFactor | 25 | Higher = more spreading chance (0-100) |
| ReduceContMonths | 14 | Months before reducing contagious illnesses |
| ReduceContPeepCount | 20 | Patient count before reducing contagious |
| ReduceContRate | 0 | Rate to reduce contagious (0 = none) |

### Visual Illness Hold

| Parameter | Value | Description |
|-----------|-------|-------------|
| HoldVisualMonths | 2 | Months to hold visual illnesses |
| HoldVisualPeepCount | 6 | Patient count before holding visual illnesses |

### Epidemic

| Parameter | Value | Description |
|-----------|-------|-------------|
| EpidemicFine | 2,000 | Fine per person if coverup fails |
| EpidemicCompLo | 1,000 | Low compensation for successful coverup |
| EpidemicCompHi | 15,000 | High compensation for successful coverup |
| EpidemicRepLossMinimum | 5 | Min infected for reputation loss |
| EpidemicEvacMinimum | 10 | Min infected for hospital evacuation |
| EpidemicConcurrentLimit | 1 | Max concurrent epidemics |

### Research

| Parameter | Value | Description |
|-----------|-------|-------------|
| AutopsyRschPercent | 33 | % research completed for autopsy |
| AutopsyRepHitPercent | 25 | % reputation hit for discovered autopsy |
| RschImproveCostPercent | 10 | % of original cost for improvement |
| RschImproveIncrementPercent | 10 | %-point increase per improvement |

### Training

| Parameter | Value | Description |
|-----------|-------|-------------|
| TrainingRate | 40 | Add to student ability (MIN 1, MAX 255) |
| TrainingValue[0] | 10 | Projector training value |
| TrainingValue[1] | 15 | Skeleton training value |
| TrainingValue[2] | 20 | Bookcase training value |

### Thresholds

| Threshold | Value | Description |
|-----------|-------|-------------|
| DoctorThreshold | 250 | Above this = Doctor |
| ConsultantThreshold | 750 | Above this = Consultant |
| AbilityThreshold[0] | 75 | Surgeon ability threshold |
| AbilityThreshold[1] | 60 | Psychiatrist ability threshold |
| AbilityThreshold[2] | 45 | Researcher ability threshold |

### Fatigue

| Threshold | Value (per mille) | Description |
|-----------|-------------------|-------------|
| Tired | 600 | Just tired |
| VeryTired | 700 | Very tired |
| CrackUpTired | 800 | Extremely tired (crack up) |

### Other

| Parameter | Value | Description |
|-----------|-------|-------------|
| MayorLaunch | 150 | Mayor visit frequency (lower = more frequent) |
| DrugImproveRate | 5 | Drug improvement rate (%) |
| AllocDelay | 3 | Months until population allocation |
| ScoreMaxInc | 300 | Max score increase multiplier |

## Staff Salary Structure

| Staff Type | Min Salary |
|-----------|-----------|
| Nurse | 60 |
| Doctor | 75 |
| Handyman | 25 |
| Receptionist | 20 |

### Doctor Specialism Salary Additions

| Specialism | Addition |
|-----------|----------|
| Junior | -30 |
| Doctor | +30 |
| Surgeon | +40 |
| Psychiatrist | +30 |
| Consultant | +100 |
| Research | +20 |

**Max Salary**: 2,000 (staff no longer become unhappy above this)

## Staff Levels (Default)

| Month | Nurses | Doctors | Handymen | Receptionists | Shrink Rate | Surg Rate | Rsch Rate | Cons Rate | Jr Rate |
|-------|--------|---------|----------|---------------|-------------|-----------|-----------|-----------|---------|
| 0 | 8 | 8 | 3 | 2 | 10 | 10 | 10 | 10 | 5 |

## Population Growth

| Month | Change |
|-------|--------|
| 0 | +4 patients |
| 1 | +1 per month |
| 27 | Cap at 30 |

## Expertise (Disease Research)

See [[diseases/CATALOG]] for disease-specific expertise IDs. Each expertise entry defines:
- `StartPrice`: Treatment price
- `Known`: Whether discovered at start
- `RschReqd`: Research points needed
- `MaxDiagDiff`: Max diagnostic difficulty

## Room Costs

| Room | Config Index | Cost |
|------|-------------|------|
| GP's Office | 7 | 2,280 |
| Psychiatry | 8 | 2,270 |
| Ward | 9 | 1,700 |
| Operating Theatre | 10 | 2,250 |
| Pharmacy | 11 | 500 |
| Cardiogram | 12 | 470 |
| Scanner | 13 | 3,970 |
| Ultrascan | 14 | 2,000 |
| Blood Machine | 15 | 3,000 |
| X-Ray | 16 | 2,000 |
| Inflation | 17 | 1,500 |
| DNA Fixer | 18 | 7,000 |
| Hair Restoration | 19 | 500 |
| Slack Tongue | 20 | 1,500 |
| Fracture Clinic | 21 | 500 |
| Training Room | 22 | 1,850 |
| Electrolysis | 23 | 500 |
| Jelly Vat | 24 | 4,500 |
| Staff Room | 25 | 1,350 |
| General Diagnosis | 27 | 720 |
| Research | 28 | 800 |
| Toilets | 29 | 1,170 |
| Decontamination | 30 | 5,500 |

## Awards & Trophies

### Trophy Win Conditions

| Award | Threshold |
|-------|-----------|
| Rat Kills (Absolute) | 25 |
| Cans of Coke | 100 |
| Reputation (all year) | >400 |
| Plant Watering | >80% |
| Staff Happiness (all year) | >85% |
| Rat Kills (Percentage) | 11% |

### Award Win/Loss Thresholds

| Metric | Award | Poor |
|--------|-------|------|
| Cures | >50 | <10 |
| Deaths | <10 | >25 |
| Population % | >50% | <15% |
| Cures/Deaths | >5 | <1 |
| Reputation | >500 | <200 |
| Hospital Value | >150,000 | <50,000 |
| Cleanliness | <5% litter | >40% litter |
| Emergency Success | >90% | <50% |
| Staff Happiness | >75% | <25% |
| Patient Happiness | >75% | <25% |
| Waiting Times | <25% | >75% |
| Well-Kept Tech | <20% | >70% |

## Cross-Reference Matrix

See [[MASTER_CROSSREF]] for the full level-config-room-object matrix.

## Related Pages

- [[diseases/CATALOG]]
- [[rooms/CATALOG]]
- [[objects/CATALOG]]
- [[walls/CATALOG]]
