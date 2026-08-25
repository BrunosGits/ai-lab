# CorsixTH Heating System Deep Research

## Overview

This document provides comprehensive analysis of the heating system implementation in CorsixTH (Lua/hospital.lua and related files). The heating system simulates boiler maintenance, radiator heat levels, daily/monthly costs, and disaster events.

---

## 1. Heating State Variables

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:107-112`

```lua
self.heating = {
  radiator_heat = 0.5,        -- (float) [0..1] fraction of heating by a radiator.
  saved_radiator_heat = nil,  -- (float) Saved radiator heat when boiler has broken down.
  boiler_repair_count = nil,  -- (int) Number of items to repair.
  heating_broke = false       -- (bool) Whether the heating system is broken down currently.
}
```

### Field Details

| Variable | Type | Range/Values | Description |
|----------|------|--------------|-------------|
| `radiator_heat` | float | 0.0 - 1.0 | Current heat output fraction. Default 0.5 (50%). User adjustable via town map UI in 0.1 increments. |
| `saved_radiator_heat` | float/nil | 0.0 - 1.0 | Stores the pre-breakdown heat level. Restored when boiler is fixed. |
| `boiler_repair_count` | int/nil | 10-30 (initial) | Countdown timer for repair. Decrements daily based on radiator/handyman ratio. |
| `heating_broke` | bool | true/false | Flag indicating boiler breakdown state. |

### Save/Load Migration (v142)

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:392-406`

```lua
if old < 142 then
  self.heating = {
    radiator_heat = self.radiator_heat or 0.5,
    saved_radiator_heat = self.curr_setting or 0.5,
    boiler_repair_count = self.boiler_countdown or 0,
    heating_broke = self.heating_broke or false
  }
  -- Clean up old fields
  self.radiator_heat = nil
  self.curr_setting = nil
  self.boiler_countdown = nil
  self.boiler_can_break = nil
  self.heating_broke = nil
end
```

---

## 2. Boiler Breakdown Trigger

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:647-666`

```lua
function Hospital:boilerBreakdown(broken_heat)
  local heat_vars = self.heating

  if not self.opened then return end -- Boiler cannot break if hospital is closed.
  if heat_vars.heating_broke then return end -- Still broken, don't break it again.

  local num_radiators = self:countRadiators()
  if num_radiators == 0 then return end -- No radiators, don't bother to break the boiler.

  local num_handyman = self:countStaffOfCategory("Handyman")
  if num_radiators <= 8 * num_handyman then return end -- Enough handyman to maintain the heating system.

  heat_vars.saved_radiator_heat = heat_vars.radiator_heat
  heat_vars.radiator_heat = broken_heat
  heat_vars.boiler_repair_count = math.random(10, 30)
  heat_vars.heating_broke = true

  -- Warn the player of the boiler's breakdown
  self:adviseBoilerBreakdown(broken_heat)
end
```

### Breakdown Conditions (ALL must be true)

1. **Hospital is opened** (`self.opened == true`)
2. **Not already broken** (`heating_broke == false`)
3. **Has at least 1 radiator** (`countRadiators() > 0`)
4. **Radiators exceed handyman capacity** (`num_radiators > 8 * num_handyman`)

### Breakdown Parameters

| Parameter | Values | Effect |
|-----------|--------|--------|
| `broken_heat` | `0` or `1` | Sets `radiator_heat` to minimum (0%) or maximum (100%) during breakdown |
| `boiler_repair_count` | `math.random(10, 30)` | Random initial repair count (10-30 days base) |

### Disaster-Triggered Breakdowns

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:763-776`

```lua
self.disasterless_days = self.disasterless_days - 1
if self.disasterless_days <= 0 then
  self.disasterless_days = self:daysUntilNextDisaster()

  local disaster_type = math.random(1, 3) -- TODO: Set to 3 until vomit wave implemented.
  if disaster_type == 2 then
    self:boilerBreakdown(1) -- max heat
  elseif disaster_type == 3 then
    self:boilerBreakdown(0) -- min heat
  end
  -- TODO: Implement vomit wave disaster for disaster_type == 4
end
```

- **Disaster Type 1**: No disaster (skip)
- **Disaster Type 2**: Boiler breakdown at MAX heat (100%)
- **Disaster Type 3**: Boiler breakdown at MIN heat (0%)
- **Disaster Type 4**: Vomit wave (NOT IMPLEMENTED - TODO)

### Days Until Next Disaster

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:639-643`

```lua
function Hospital:daysUntilNextDisaster()
  local disaster_free_days = {300, 200, 150}
  -- Original doesn't use random, see Github #490.
  return disaster_free_days[self.world.map:getDifficulty()] + math.random(1, 21) - 11
end
```

| Difficulty | Base Days | Random Range | Total Range |
|------------|-----------|--------------|-------------|
| Easy (1) | 300 | -10 to +10 | 290-310 days |
| Medium (2) | 200 | -10 to +10 | 190-210 days |
| Hard (3) | 150 | -10 to +10 | 140-160 days |

---

## 3. Repair Countdown Mechanics

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:669-694`

```lua
function Hospital:_fixBoiler()
  local heat_vars = self.heating

  if not heat_vars.heating_broke then return end -- Not broken, done!

  -- Repair the boiler or radiators, more handy men speeds up repair
  local num_radiators = self:countRadiators()
  local num_handyman = self:countStaffOfCategory("Handyman")
  if num_radiators < 5 * num_handyman then
    heat_vars.boiler_repair_count = heat_vars.boiler_repair_count - 3
  elseif num_radiators < 8 * num_handyman then
    heat_vars.boiler_repair_count = heat_vars.boiler_repair_count - 2
  else
    heat_vars.boiler_repair_count = heat_vars.boiler_repair_count - 1
  end

  if heat_vars.boiler_repair_count <= 0 then
    -- It's fixed, restore previous settings.
    heat_vars.radiator_heat = heat_vars.saved_radiator_heat
    heat_vars.heating_broke = false
    if num_radiators > 0 then
      -- Only tell the player about fix if there is at least one radiator.
      self:giveAdvice({_A.boiler_issue.resolved})
    end
  end
end
```

### Repair Speed Tiers

| Radiator/Handyman Ratio | Daily Decrement | Days to Repair (10-30 count) |
|-------------------------|-----------------|------------------------------|
| `< 5:1` (plenty of handymen) | **-3** | 4-10 days |
| `5:1 to < 8:1` | **-2** | 5-15 days |
| `>= 8:1` (understaffed) | **-1** | 10-30 days |

### Repair Completion

When `boiler_repair_count <= 0`:
1. `radiator_heat` restored to `saved_radiator_heat`
2. `heating_broke = false`
3. Player advised via `giveAdvice({_A.boiler_issue.resolved})` if radiators exist

### Daily Call Site

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:761`

```lua
self:_fixBoiler() -- Boiler always needs work (especially if broken).
```

Called from `Hospital:onEndDay()` daily.

---

## 4. Daily Heating Cost Formula

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:778-781`

```lua
-- Calculate heating cost daily. Divide the monthly cost by the number of days in that month
local num_radiators = self:countRadiators()
local heating_costs = (self.heating.radiator_heat * 10 * num_radiators * 7.50) / self.world:date():lastDayOfMonth()
self.acc_heating = self.acc_heating + heating_costs
```

### Formula Breakdown

```
Daily Cost = (radiator_heat × 10 × num_radiators × 7.50) / days_in_month
```

| Variable | Description |
|----------|-------------|
| `radiator_heat` | Current heat setting (0.0-1.0) |
| `10` | Scale factor (converts 0.1 increments to 1-10 scale) |
| `num_radiators` | Count of radiator objects in hospital |
| `7.50` | Base cost per radiator per heat level per month |
| `days_in_month` | 28, 29, 30, or 31 (from game date) |

### Monthly Cost (Before Daily Division)

```
Monthly Cost = radiator_heat × 10 × num_radiators × 7.50
```

### Example Calculations

| Radiators | Heat Setting | Monthly Cost | Daily Cost (30-day month) |
|-----------|--------------|--------------|---------------------------|
| 10 | 0.5 (50%) | 10 × 10 × 0.5 × 7.50 = $375 | $12.50 |
| 20 | 0.8 (80%) | 20 × 10 × 0.8 × 7.50 = $1,200 | $40.00 |
| 50 | 1.0 (100%) | 50 × 10 × 1.0 × 7.50 = $3,750 | $125.00 |

### UI Display (Town Map)

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/dialogs/fullscreen/town_map.lua:196-198`

```lua
local heating_costs = world.free_build_mode and 0 or
    math.floor(((hospital.heating.radiator_heat *10)* radiators)* 7.5)
```

Note: UI shows **monthly** cost (not daily), rounded down.

---

## 5. Monthly Payment Processing

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:796-800`

```lua
-- Pay heating costs
if math.round(self.acc_heating) > 0 then
  self:spendMoney(math.round(self.acc_heating), _S.transactions.heating)
  self.acc_heating = 0
end
```

- Accumulated daily costs (`acc_heating`) paid at month end
- Rounded to nearest integer
- Transaction type: `_S.transactions.heating`
- Resets `acc_heating` to 0 after payment

---

## 6. Disaster Types Summary

| Disaster Type | Trigger | Effect | Implemented |
|---------------|---------|--------|-------------|
| 1 (None) | Random (1/3) | No disaster | ✅ |
| 2 (Max Heat) | Random (1/3) | `boilerBreakdown(1)` - radiator_heat = 1.0 | ✅ |
| 3 (Min Heat) | Random (1/3) | `boilerBreakdown(0)` - radiator_heat = 0.0 | ✅ |
| 4 (Vomit Wave) | - | TODO: Not implemented | ❌ |

### Disaster Flow

1. Daily decrement `disasterless_days` in `onEndDay()`
2. When `<= 0`, pick random type 1-3
3. Reset `disasterless_days` via `daysUntilNextDisaster()`
4. Type 2/3 → call `boilerBreakdown()` with heat parameter
5. `boilerBreakdown()` checks conditions (opened, not broken, has radiators, handyman ratio)

---

## 7. User Heat Adjustment (Town Map UI)

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/dialogs/fullscreen/town_map.lua:334-350`

```lua
function UITownMap:decreaseHeat()
  local h = self.ui.hospital
  local heat = math.floor(h.heating.radiator_heat * 10 + 0.5)
  if not h.heating.heating_broke then
    heat = math.max(heat - 1, 1)
    h.heating.radiator_heat = heat / 10
  end
end

function UITownMap:increaseHeat()
  local h = self.ui.hospital
  local heat = math.floor(h.heating.radiator_heat * 10 + 0.5)
  if not h.heating.heating_broke then
    heat = math.min(heat + 1, 10)
    h.heating.radiator_heat = heat / 10
  end
end
```

- Adjustable in 0.1 increments (1-10 scale internally)
- Minimum: 0.1 (10%)
- Maximum: 1.0 (100%)
- **Blocked when boiler is broken** (`heating_broke == true`)

---

## 8. Radiator Count Implementation

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:1508-1510`

```lua
function Hospital:countRadiators()
  return self.tile_object_counts["radiator"]
end
```

- Simple lookup from `tile_object_counts` table
- Updated when radiators are placed/removed

---

## 9. Staff Counting for Handymen

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/hospital.lua:1453-1462`

```lua
function Hospital:countStaffOfCategory(category, max_count)
  local result = 0
  for _, staff in ipairs(self.staff) do
    if staff:fulfillsCriterion(category) then
      result = result + 1
    end
    if max_count ~= nil and result >= max_count then break end
  end
  return result
end
```

- Iterates all staff, checks `fulfillsCriterion("Handyman")`
- Supports optional `max_count` for early exit optimization

---

## 10. Boiler Breakdown Advisor Messages

**Location:** `/tmp/CorsixTH/CorsixTH/Lua/hospitals/player_hospital.lua:456-465`

```lua
function PlayerHospital:adviseBoilerBreakdown(broken_heat)
  local ui = self.world.ui
  if broken_heat == 0 then
    ui.adviser:say(_A.boiler_issue.minimum_heat)
    ui:playRandomAnnouncement({ "sorry002.wav", "sorry004.wav" })
  else
    ui.adviser:say(_A.boiler_issue.maximum_heat)
    ui:playRandomAnnouncement({ "sorry003.wav", "sorry004.wav" })
  end
end
```

- Different messages/sounds for min vs max heat breakdown
- Uses advisor system (`_A.boiler_issue.minimum_heat` / `maximum_heat`)

---

## 11. Code Examples

### Example: Simulating a Boiler Breakdown

```lua
local hospital = world.hospitals[1]

-- Check if breakdown can occur
print("Hospital opened:", hospital.opened)
print("Already broken:", hospital.heating.heating_broke)
print("Radiators:", hospital:countRadiators())
print("Handymen:", hospital:countStaffOfCategory("Handyman"))
print("Ratio (rad/handy):", hospital:countRadiators() / hospital:countStaffOfCategory("Handyman"))

-- Force breakdown at max heat
hospital:boilerBreakdown(1)
print("Broken:", hospital.heating.heating_broke)
print("Heat set to:", hospital.heating.radiator_heat)
print("Repair count:", hospital.heating.boiler_repair_count)
```

### Example: Calculating Repair Time

```lua
function estimateRepairDays(hospital)
  local rad = hospital:countRadiators()
  local handy = hospital:countStaffOfCategory("Handyman")
  local repair_count = hospital.heating.boiler_repair_count or 0
  
  local daily_decrement
  if rad < 5 * handy then
    daily_decrement = 3
  elseif rad < 8 * handy then
    daily_decrement = 2
  else
    daily_decrement = 1
  end
  
  return math.ceil(repair_count / daily_decrement)
end
```

### Example: Projecting Monthly Heating Cost

```lua
function getMonthlyHeatingCost(hospital)
  local heat = hospital.heating.radiator_heat
  local rad = hospital:countRadiators()
  return heat * 10 * rad * 7.50
end

function getDailyHeatingCost(hospital)
  local monthly = getMonthlyHeatingCost(hospital)
  local days = hospital.world:date():lastDayOfMonth()
  return monthly / days
end
```

---

## 12. Edge Cases & Behaviors

| Scenario | Behavior |
|----------|----------|
| Hospital closed | Boiler cannot break (`opened == false`) |
| No radiators | Boiler cannot break, no heating costs |
| Boiler already broken | Second breakdown ignored |
| Heat adjustment during breakdown | Blocked in UI (`decreaseHeat`/`increaseHeat` check `heating_broke`) |
| 0 handymen | Ratio infinite → breakdown if radiators > 0, repair at -1/day |
| Repair count reaches 0 exactly | Fixed, heat restored, advice given |
| Free build mode | Heating costs = 0 (town map UI) |
| Save game v<142 | Migration converts old fields to `heating` table |

---

## 13. Related Files Summary

| File | Key Functions/Lines |
|------|---------------------|
| `Lua/hospital.lua` | Core heating logic: init (107-112), breakdown (647-666), repair (669-694), daily cost (778-781), monthly pay (796-800), disaster (763-776), daysUntilNextDisaster (639-643) |
| `Lua/hospitals/player_hospital.lua` | `adviseBoilerBreakdown` (456-465), daily advice checks (198, 210, 222) |
| `Lua/dialogs/fullscreen/town_map.lua` | UI display (195-198, 213-218), heat adjustment (334-350) |
| `Lua/languages/*.lua` | Localized strings for heating advice, bills |

---

## 14. Key Constants

| Constant | Value | Location |
|----------|-------|----------|
| Default radiator_heat | 0.5 | hospital.lua:108 |
| Min heat setting | 0.1 | town_map.lua:338 |
| Max heat setting | 1.0 | town_map.lua:347 |
| Base monthly cost per radiator per heat level | 7.50 | hospital.lua:780 |
| Initial repair count range | 10-30 | hospital.lua:661 |
| Handyman ratio thresholds | 5:1, 8:1 | hospital.lua:677, 657, 679 |
| Disaster free days (Easy/Med/Hard) | 300/200/150 | hospital.lua:640 |
| Disaster random variance | ±10 days | hospital.lua:642 |

---

*Document generated from CorsixTH source analysis. Version: Current Git HEAD.*


## Related Pages

- [[14-heating-system/CHECKLIST]]
- [[14-heating-system/MAP]]
- [[14-heating-system/SCAFFOLD]]
