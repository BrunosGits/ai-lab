# Heating System - File:Line Index

Comprehensive cross-reference for all heating-related code in CorsixTH.

---

## Primary File: `Lua/hospital.lua`

| Line Range | Function/Section | Description |
|------------|------------------|-------------|
| 53 | `self.acc_heating = 0` | Accumulated heating costs (monthly accumulator) |
| 102-104 | `disasterless_days` init | Days until next disaster (heating/vomit) |
| **107-112** | **`self.heating` table init** | **Core heating state variables** |
| 108 | `radiator_heat = 0.5` | Default 50% heat output |
| 109 | `saved_radiator_heat = nil` | Stored heat during breakdown |
| 110 | `boiler_repair_count = nil` | Repair countdown timer |
| 111 | `heating_broke = false` | Breakdown flag |
| 115-117 | `tile_object_counts.radiator` | Radiator count tracked here |
| 310 | `self.acc_heating = 0` | Reset on new game/load |
| **392-406** | **Save migration v142** | Converts old fields to `heating` table |
| 395-400 | `heating` table migration | Maps old fields to new structure |
| 639-643 | `daysUntilNextDisaster()` | Calculates days until next disaster by difficulty |
| **647-666** | **`boilerBreakdown(broken_heat)`** | **Triggers boiler breakdown** |
| 650 | `if not self.opened then return end` | Guard: hospital must be open |
| 651 | `if heat_vars.heating_broke then return end` | Guard: not already broken |
| 653-654 | `countRadiators() == 0` | Guard: must have radiators |
| 656-657 | `num_radiators <= 8 * num_handyman` | Guard: handyman ratio threshold |
| 659 | `saved_radiator_heat = radiator_heat` | Save current heat setting |
| 660 | `radiator_heat = broken_heat` | Set to 0 (min) or 1 (max) |
| 661 | `boiler_repair_count = random(10,30)` | Random initial repair count |
| 662 | `heating_broke = true` | Set breakdown flag |
| 665 | `adviseBoilerBreakdown(broken_heat)` | Notify player via advisor |
| **669-694** | **`_fixBoiler()`** | **Daily repair progress** |
| 672 | `if not heat_vars.heating_broke then return end` | Guard: only if broken |
| 675-676 | `countRadiators()`, `countStaffOfCategory("Handyman")` | Get current counts |
| 677-678 | `radiators < 5*handymen` → `-3/day` | Fast repair tier |
| 679-680 | `radiators < 8*handymen` → `-2/day` | Medium repair tier |
| 681-682 | `else` → `-1/day` | Slow repair tier |
| 685-693 | Repair completion logic | Restore heat, clear flag, advise player |
| 761 | `self:_fixBoiler()` | Called daily from `onEndDay()` |
| **763-776** | **Disaster check in `onEndDay()`** | **Random disaster triggering** |
| 764 | `disasterless_days = disasterless_days - 1` | Daily countdown |
| 765-766 | Reset counter, get new interval | When disaster triggers |
| 768 | `disaster_type = random(1,3)` | 1=none, 2=max heat, 3=min heat |
| 771 | `boilerBreakdown(1)` | Disaster type 2: max heat |
| 773 | `boilerBreakdown(0)` | Disaster type 3: min heat |
| 775 | TODO: vomit wave (type 4) | Not implemented |
| **778-781** | **Daily heating cost calculation** | **Accumulates in acc_heating** |
| 779 | `countRadiators()` | Current radiator count |
| 780 | Formula: `(heat * 10 * rad * 7.50) / days_in_month` | Daily cost |
| 781 | `acc_heating = acc_heating + heating_costs` | Accumulate |
| **796-800** | **Monthly payment in `onEndMonth()`** | **Pays accumulated heating** |
| 797 | `math.round(acc_heating) > 0` | Check if payment needed |
| 798 | `spendMoney(round(acc_heating), transactions.heating)` | Pay bill |
| 799 | `acc_heating = 0` | Reset accumulator |
| 1453-1462 | `countStaffOfCategory(category, max_count)` | Counts handymen (and other staff) |
| 1508-1510 | `countRadiators()` | Returns `tile_object_counts.radiator` |

---

## File: `Lua/hospitals/player_hospital.lua`

| Line Range | Function/Section | Description |
|------------|------------------|-------------|
| 81 | `if day == 5 and countRadiators() == 0` | Early game advice: place radiators |
| 198 | `or self.heating.heating_broke` | Guard: skip heat advice if broken |
| 202 | `increase_heating` advice | Advisor: "people are cold" |
| 210 | `decrease_heating` advice | Advisor: "people are hot" |
| 222 | `or self.heating.heating_broke` | Guard: skip heat advice if broken |
| **456-465** | **`adviseBoilerBreakdown(broken_heat)`** | **Player hospital advisor messages** |
| 458-460 | `broken_heat == 0` → `minimum_heat` + sorry sounds | Min heat breakdown message |
| 461-463 | `broken_heat == 1` → `maximum_heat` + sorry sounds | Max heat breakdown message |

---

## File: `Lua/dialogs/fullscreen/town_map.lua`

| Line Range | Function/Section | Description |
|------------|------------------|-------------|
| 85 | `makeTooltip(heating_bill, ...)` | Tooltip for heating bill display |
| 187 | `radiators = hospital:countRadiators()` | Get radiator count for display |
| **196-198** | **Heating cost display (monthly)** | **UI shows monthly cost, floored** |
| 197 | `math.floor(((heat * 10) * radiators) * 7.5)` | Monthly cost formula for display |
| 213-218 | Radiator heat bar drawing | Visual heat level indicator |
| 215 | `rad_width = rad_max_width * radiator_heat` | Bar width proportional to heat |
| **334-341** | **`decreaseHeat()`** | **Lowers heat by 0.1 (min 0.1)** |
| 336 | `heat = floor(radiator_heat * 10 + 0.5)` | Convert to 1-10 integer |
| 337 | `if not heating_broke then` | Blocked during breakdown |
| 338 | `heat = max(heat - 1, 1)` | Minimum 1 (0.1) |
| 339 | `radiator_heat = heat / 10` | Convert back to 0.1-1.0 |
| **343-350** | **`increaseHeat()`** | **Raises heat by 0.1 (max 1.0)** |
| 345 | `heat = floor(radiator_heat * 10 + 0.5)` | Convert to 1-10 integer |
| 346 | `if not heating_broke then` | Blocked during breakdown |
| 347 | `heat = min(heat + 1, 10)` | Maximum 10 (1.0) |
| 348 | `radiator_heat = heat / 10` | Convert back to 0.1-1.0 |

---

## File: `Lua/world.lua`

| Line Range | Function/Section | Description |
|------------|------------------|-------------|
| 1917 | `countStaffOfCategory("Handyman", 1) == 0` | Checks for handymen (used elsewhere) |

---

## Language Files: `Lua/languages/*.lua`

### English (`english.lua`)
| Line | Key | Description |
|------|-----|-------------|
| 924 | Radiator tooltip | "Place enough radiators..." |
| 937 | Thirst/heating tip | "Patients will get thirsty... turn up the heating" |
| 1154 | Cheat detection | "Hospital administrator is cheating!" |

### Common Keys Across Languages
| Key | Description |
|-----|-------------|
| `heating` | "Heating Costs" / "Heizkosten" / "供暖费" etc. |
| `heating_bill` | Monthly bill display |
| `increase_heating` | Advisor: "People are cold, increase heating" |
| `decrease_heating` | Advisor: "People are hot, decrease heating" |
| `boiler_issue.minimum_heat` | "Boiler broken - minimum heat" |
| `boiler_issue.maximum_heat` | "Boiler broken - maximum heat" |
| `boiler_issue.resolved` | "Boiler repaired" |

---

## Transaction Types (`Lua/languages/brazilian_portuguese.lua` example)

| Line | Key | Description |
|------|-----|-------------|
| 1516 | `transactions.heating` | "Gastos com aquecimento" (heating expenses) |

---

## Call Graph Summary

```
onEndDay() [hospital.lua:753]
  ├── _fixBoiler() [hospital.lua:761]
  │     ├── countRadiators() [hospital.lua:1508]
  │     ├── countStaffOfCategory("Handyman") [hospital.lua:1453]
  │     └── giveAdvice() [hospital.lua:691] -- when fixed
  ├── Disaster check [hospital.lua:763]
  │     ├── disasterless_days-- 
  │     ├── daysUntilNextDisaster() [hospital.lua:639]
  │     └── boilerBreakdown() [hospital.lua:647] -- if type 2 or 3
  └── Daily heating cost [hospital.lua:778]
        ├── countRadiators()
        └── acc_heating += daily_cost

onEndMonth() [hospital.lua:787]
  └── Pay heating [hospital.lua:796]
        ├── math.round(acc_heating)
        └── spendMoney(..., transactions.heating)

boilerBreakdown(heat) [hospital.lua:647]
  ├── Guards: opened, not broken, radiators > 0, ratio > 8:1
  ├── saved_radiator_heat = radiator_heat
  ├── radiator_heat = heat (0 or 1)
  ├── boiler_repair_count = random(10,30)
  ├── heating_broke = true
  └── adviseBoilerBreakdown(heat) [player_hospital.lua:456]

adviseBoilerBreakdown(heat) [player_hospital.lua:456]
  ├── heat == 0: adviser.say(minimum_heat) + sorry sounds
  └── heat == 1: adviser.say(maximum_heat) + sorry sounds

Town Map UI [town_map.lua]
  ├── decreaseHeat() [334] → radiator_heat -= 0.1 (min 0.1)
  ├── increaseHeat() [343] → radiator_heat += 0.1 (max 1.0)
  └── Both blocked if heating_broke == true

Save/Load Migration [hospital.lua:392]
  └── Converts v<142 fields to heating table
```

---

## Data Flow: Heating State

```
┌─────────────────────────────────────────────────────────────────┐
│                        HEATING TABLE                            │
│  ┌─────────────────┬─────────────────┬──────────────────────┐  │
│  │ radiator_heat   │ saved_radiator_ │ boiler_repair_count  │  │
│  │   (0.0-1.0)     │     heat        │      (int/nil)       │  │
│  │   DEFAULT: 0.5  │   (nil/0.0-1.0) │   INIT: 10-30        │  │
│  └────────┬────────┴────────┬────────┴──────────┬──────────┘  │
│           │                │                    │              │
│           ▼                ▼                    ▼              │
│  ┌────────────────────────────────────────────────────────┐   │
│  │                    heating_broke (bool)                 │   │
│  │  FALSE: Normal operation, heat adjustable, costs accrue │   │
│  │  TRUE:  Broken, heat locked at 0 or 1, repair counting  │   │
│  └────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
   ┌───────────┐      ┌─────────────┐      ┌──────────────┐
   │  DAILY    │      │  BREAKDOWN  │      │   REPAIR     │
   │  COSTS    │      │  TRIGGER    │      │  COUNTDOWN   │
   │ formula   │      │ conditions  │      │  -3/-2/-1    │
   │ uses this │      │ use this    │      │  uses this   │
   └───────────┘      └─────────────┘      └──────────────┘
```

---

## Quick Grep Patterns

```bash
# All heating state access
grep -n "heating\." Lua/hospital.lua

# Boiler breakdown logic
grep -n "boilerBreakdown\|_fixBoiler\|heating_broke" Lua/hospital.lua

# Heating costs
grep -n "acc_heating\|heating_costs\|radiator_heat.*10.*7.5" Lua/hospital.lua

# Disaster system
grep -n "disasterless_days\|daysUntilNextDisaster\|disaster_type" Lua/hospital.lua

# UI heat adjustment
grep -n "decreaseHeat\|increaseHeat\|radiator_heat" Lua/dialogs/fullscreen/town_map.lua

# Advisor messages
grep -n "adviseBoilerBreakdown\|boiler_issue" Lua/hospitals/player_hospital.lua

# Staff counting
grep -n "countStaffOfCategory.*Handyman" Lua/hospital.lua

# Radiator counting
grep -n "countRadiators\|tile_object_counts\[\"radiator\"\]" Lua/hospital.lua
```

---

## Version History Notes

| Version | Change |
|---------|--------|
| v142 | Migrated `radiator_heat`, `curr_setting`, `boiler_countdown`, `heating_broke` → `heating` table |
| Current | `boiler_can_break` removed (equivalent to `self.opened`) |
| TODO | Vomit wave disaster (type 4) |

---

*Map generated from CorsixTH source. Last updated: Current Git HEAD.*


## Related Pages

- [[14-heating-system/SUMMARY]]
- [[14-heating-system/CHECKLIST]]
- [[14-heating-system/SCAFFOLD]]
