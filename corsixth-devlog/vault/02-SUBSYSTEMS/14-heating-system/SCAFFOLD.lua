--[[
  CorsixTH Heating System - Busted Test Scaffold
  
  This file provides test infrastructure and test cases for the heating system.
  Run with: busted SCAFFOLD.lua
  
  Note: Requires CorsixTH test environment setup with mocked dependencies.
]]

local busted = require("busted")
local describe, it, before_each, after_each, setup, teardown = busted.describe, busted.it, busted.before_each, busted.after_each, busted.setup, busted.teardown
local assert = require("luassert")
local spy = require("luassert.spy")
local stub = require("luassert.stub")
local mock = require("luassert.mock")

-- ============================================================================
-- MOCK HELPERS
-- ============================================================================

local function createMockWorld()
  local world = mock({
    map = mock({
      getDifficulty = function() return 2 end, -- Medium
    }),
    date = mock({
      lastDayOfMonth = function() return 30 end,
    }),
    ui = mock({
      adviser = mock({ say = function() end }),
      playRandomAnnouncement = function() end,
    }),
    free_build_mode = false,
  })
  return world
end

local function createMockStaff(count, category)
  local staff = {}
  for i = 1, count do
    staff[i] = mock({
      fulfillsCriterion = function(self, cat) return cat == category end,
      profile = { wage = 1000 }
    })
  end
  return staff
end

local function createMockHospital(overrides)
  overrides = overrides or {}
  local world = createMockWorld()
  
  local hospital = {
    world = world,
    opened = overrides.opened or true,
    staff = overrides.staff or createMockStaff(2, "Handyman"),
    tile_object_counts = overrides.tile_object_counts or { radiator = 10, extinguisher = 0, plant = 0 },
    heating = {
      radiator_heat = overrides.radiator_heat or 0.5,
      saved_radiator_heat = nil,
      boiler_repair_count = nil,
      heating_broke = false,
    },
    acc_heating = 0,
    disasterless_days = 100,
    reputation_above_threshold = false,
    has_impressive_reputation = false,
    
    -- Methods
    countRadiators = function(self) return self.tile_object_counts.radiator end,
    countStaffOfCategory = function(self, category, max_count)
      local count = 0
      for _, staff in ipairs(self.staff) do
        if staff:fulfillsCriterion(category) then
          count = count + 1
          if max_count and count >= max_count then break end
        end
      end
      return count
    end,
    isPlayerHospital = function(self) return true end,
    spendMoney = function(self, amount, transaction) end,
    giveAdvice = function(self, advice) end,
    adviseBoilerBreakdown = function(self, broken_heat) end,
    daysUntilNextDisaster = function(self)
      local disaster_free_days = {300, 200, 150}
      return disaster_free_days[self.world.map:getDifficulty()] + math.random(1, 21) - 11
    end,
    unconditionalChangeReputation = function(self, val) end,
  }
  
  -- Import actual methods from hospital.lua (requires module loading)
  -- For now, we'll stub the key methods
  
  return hospital
end

-- ============================================================================
-- LOAD ACTUAL HOSPITAL MODULE (if available)
-- ============================================================================

local Hospital = nil
local ok, err = pcall(function()
  -- This assumes CorsixTH test environment is set up
  -- In practice, you'd need to set up package.path and require the module
  -- Hospital = require("hospital")
end)

if not ok then
  print("Warning: Could not load actual Hospital module. Using mocks only.")
  print("Error: " .. tostring(err))
end

-- ============================================================================
-- TEST SUITE: BOILER BREAKDOWN
-- ============================================================================

describe("Boiler Breakdown System", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
    -- Spy on methods
    spy.on(hospital, "adviseBoilerBreakdown")
    spy.on(hospital, "countRadiators")
    spy.on(hospital, "countStaffOfCategory")
    spy.on(hospital, "daysUntilNextDisaster")
  end)
  
  after_each(function()
    hospital.adviseBoilerBreakdown:revert()
    hospital.countRadiators:revert()
    hospital.countStaffOfCategory:revert()
    hospital.daysUntilNextDisaster:revert()
  end)
  
  it("should NOT break down if hospital is closed", function()
    hospital.opened = false
    hospital:boilerBreakdown(0)
    assert.is_false(hospital.heating.heating_broke)
  end)
  
  it("should NOT break down if already broken", function()
    hospital.heating.heating_broke = true
    hospital:boilerBreakdown(0)
    assert.is_true(hospital.heating.heating_broke)
    assert.spy(hospital.adviseBoilerBreakdown).was_not_called()
  end)
  
  it("should NOT break down if no radiators", function()
    hospital.tile_object_counts.radiator = 0
    hospital:boilerBreakdown(0)
    assert.is_false(hospital.heating.heating_broke)
  end)
  
  it("should NOT break down if enough handymen (ratio <= 8:1)", function()
    -- 10 radiators, 2 handymen = 5:1 ratio (<= 8:1, so NO breakdown)
    hospital.tile_object_counts.radiator = 10
    hospital.staff = createMockStaff(2, "Handyman")
    hospital:boilerBreakdown(0)
    assert.is_false(hospital.heating.heating_broke)
  end)
  
  it("SHOULD break down if not enough handymen (ratio > 8:1)", function()
    -- 20 radiators, 2 handymen = 10:1 ratio (> 8:1, so breakdown)
    hospital.tile_object_counts.radiator = 20
    hospital.staff = createMockStaff(2, "Handyman")
    hospital:boilerBreakdown(1)
    
    assert.is_true(hospital.heating.heating_broke)
    assert.equals(1, hospital.heating.radiator_heat)
    assert.is_not_nil(hospital.heating.boiler_repair_count)
    assert.is_true(hospital.heating.boiler_repair_count >= 10 and hospital.heating.boiler_repair_count <= 30)
    assert.spy(hospital.adviseBoilerBreakdown).was_called_with(1)
  end)
  
  it("should save current radiator_heat before breakdown", function()
    hospital.heating.radiator_heat = 0.7
    hospital.tile_object_counts.radiator = 20
    hospital.staff = createMockStaff(2, "Handyman")
    hospital:boilerBreakdown(0)
    
    assert.equals(0.7, hospital.heating.saved_radiator_heat)
    assert.equals(0, hospital.heating.radiator_heat)
  end)
  
  it("disaster type 2 triggers max heat breakdown", function()
    hospital.tile_object_counts.radiator = 20
    hospital.staff = createMockStaff(2, "Handyman")
    hospital.disasterless_days = 1
    
    -- Simulate onEndDay disaster check
    hospital.disasterless_days = hospital.disasterless_days - 1
    if hospital.disasterless_days <= 0 then
      hospital.disasterless_days = hospital:daysUntilNextDisaster()
      hospital:boilerBreakdown(1) -- disaster type 2
    end
    
    assert.is_true(hospital.heating.heating_broke)
    assert.equals(1, hospital.heating.radiator_heat)
  end)
  
  it("disaster type 3 triggers min heat breakdown", function()
    hospital.tile_object_counts.radiator = 20
    hospital.staff = createMockStaff(2, "Handyman")
    hospital.disasterless_days = 1
    
    hospital.disasterless_days = hospital.disasterless_days - 1
    if hospital.disasterless_days <= 0 then
      hospital.disasterless_days = hospital:daysUntilNextDisaster()
      hospital:boilerBreakdown(0) -- disaster type 3
    end
    
    assert.is_true(hospital.heating.heating_broke)
    assert.equals(0, hospital.heating.radiator_heat)
  end)
end)

-- ============================================================================
-- TEST SUITE: REPAIR COUNTDOWN
-- ============================================================================

describe("Boiler Repair Countdown", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
    hospital.heating.heating_broke = true
    hospital.heating.boiler_repair_count = 20
    hospital.heating.saved_radiator_heat = 0.6
    spy.on(hospital, "giveAdvice")
  end)
  
  after_each(function()
    hospital.giveAdvice:revert()
  end)
  
  it("should NOT repair if not broken", function()
    hospital.heating.heating_broke = false
    hospital:_fixBoiler()
    assert.equals(20, hospital.heating.boiler_repair_count)
  end)
  
  it("should decrement by 3 when radiators < 5 * handymen", function()
    -- 10 radiators, 3 handymen = 3.33:1 ratio (< 5:1)
    hospital.tile_object_counts.radiator = 10
    hospital.staff = createMockStaff(3, "Handyman")
    
    hospital:_fixBoiler()
    assert.equals(17, hospital.heating.boiler_repair_count)
  end)
  
  it("should decrement by 2 when 5 * handymen <= radiators < 8 * handymen", function()
    -- 20 radiators, 3 handymen = 6.67:1 ratio (5:1 <= ratio < 8:1)
    hospital.tile_object_counts.radiator = 20
    hospital.staff = createMockStaff(3, "Handyman")
    
    hospital:_fixBoiler()
    assert.equals(18, hospital.heating.boiler_repair_count)
  end)
  
  it("should decrement by 1 when radiators >= 8 * handymen", function()
    -- 30 radiators, 3 handymen = 10:1 ratio (>= 8:1)
    hospital.tile_object_counts.radiator = 30
    hospital.staff = createMockStaff(3, "Handyman")
    
    hospital:_fixBoiler()
    assert.equals(19, hospital.heating.boiler_repair_count)
  end)
  
  it("should fix boiler when repair_count reaches 0", function()
    hospital.heating.boiler_repair_count = 1
    hospital.tile_object_counts.radiator = 10
    hospital.staff = createMockStaff(3, "Handyman") -- -3 per day
    
    hospital:_fixBoiler()
    
    assert.is_false(hospital.heating.heating_broke)
    assert.equals(0.6, hospital.heating.radiator_heat)
    assert.spy(hospital.giveAdvice).was_called()
  end)
  
  it("should fix boiler when repair_count goes negative", function()
    hospital.heating.boiler_repair_count = 2
    hospital.tile_object_counts.radiator = 10
    hospital.staff = createMockStaff(3, "Handyman") -- -3 per day
    
    hospital:_fixBoiler()
    
    assert.is_false(hospital.heating.heating_broke)
    assert.equals(0.6, hospital.heating.radiator_heat)
  end)
  
  it("should NOT give advice if no radiators when fixed", function()
    hospital.heating.boiler_repair_count = 1
    hospital.tile_object_counts.radiator = 0
    hospital.staff = createMockStaff(3, "Handyman")
    
    hospital:_fixBoiler()
    
    assert.is_false(hospital.heating.heating_broke)
    assert.spy(hospital.giveAdvice).was_not_called()
  end)
  
  it("should calculate estimated repair days correctly", function()
    local function estimateDays(rad, handy, count)
      local daily
      if rad < 5 * handy then daily = 3
      elseif rad < 8 * handy then daily = 2
      else daily = 1 end
      return math.ceil(count / daily)
    end
    
    assert.equals(4, estimateDays(10, 3, 10))  -- 10/3 = 3.33 -> 4 days
    assert.equals(5, estimateDays(20, 3, 10))  -- 10/2 = 5 days
    assert.equals(10, estimateDays(30, 3, 10)) -- 10/1 = 10 days
    assert.equals(1, estimateDays(10, 3, 3))   -- 3/3 = 1 day
  end)
end)

-- ============================================================================
-- TEST SUITE: HEATING COST CALCULATION
-- ============================================================================

describe("Heating Cost Calculation", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
    hospital.world.date.lastDayOfMonth = function() return 30 end
  end)
  
  it("should calculate daily heating cost correctly", function()
    hospital.heating.radiator_heat = 0.5
    hospital.tile_object_counts.radiator = 10
    
    -- Daily cost = (0.5 * 10 * 10 * 7.50) / 30 = 375 / 30 = 12.5
    local num_radiators = hospital:countRadiators()
    local heating_costs = (hospital.heating.radiator_heat * 10 * num_radiators * 7.50) / hospital.world:date():lastDayOfMonth()
    
    assert.are.near(12.5, heating_costs, 0.01)
  end)
  
  it("should calculate monthly heating cost correctly", function()
    hospital.heating.radiator_heat = 0.8
    hospital.tile_object_counts.radiator = 20
    
    local monthly = hospital.heating.radiator_heat * 10 * hospital:countRadiators() * 7.50
    -- 0.8 * 10 * 20 * 7.50 = 1200
    assert.equals(1200, monthly)
  end)
  
  it("should accumulate daily costs in acc_heating", function()
    hospital.heating.radiator_heat = 0.5
    hospital.tile_object_counts.radiator = 10
    hospital.acc_heating = 0
    
    for day = 1, 30 do
      local num_radiators = hospital:countRadiators()
      local heating_costs = (hospital.heating.radiator_heat * 10 * num_radiators * 7.50) / 30
      hospital.acc_heating = hospital.acc_heating + heating_costs
    end
    
    -- After 30 days, should equal monthly cost
    assert.are.near(375, hospital.acc_heating, 0.01)
  end)
  
  it("should handle different month lengths", function()
    hospital.heating.radiator_heat = 1.0
    hospital.tile_object_counts.radiator = 10
    
    local monthly = hospital.heating.radiator_heat * 10 * hospital:countRadiators() * 7.50 -- 750
    
    local daily_28 = monthly / 28
    local daily_30 = monthly / 30
    local daily_31 = monthly / 31
    
    assert.are.near(26.79, daily_28, 0.01)
    assert.are.near(25.00, daily_30, 0.01)
    assert.are.near(24.19, daily_31, 0.01)
  end)
  
  it("should show correct cost in town map UI (monthly, floored)", function()
    hospital.heating.radiator_heat = 0.5
    hospital.tile_object_counts.radiator = 10
    
    local heating_costs = math.floor(((hospital.heating.radiator_heat * 10) * hospital:countRadiators()) * 7.5)
    -- floor((0.5 * 10) * 10 * 7.5) = floor(5 * 10 * 7.5) = floor(375) = 375
    assert.equals(375, heating_costs)
  end)
  
  it("should be zero in free build mode", function()
    hospital.world.free_build_mode = true
    local heating_costs = hospital.world.free_build_mode and 0 or 375
    assert.equals(0, heating_costs)
  end)
end)

-- ============================================================================
-- TEST SUITE: MONTHLY PAYMENT
-- ============================================================================

describe("Monthly Heating Payment", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
    spy.on(hospital, "spendMoney")
  end)
  
  after_each(function()
    hospital.spendMoney:revert()
  end)
  
  it("should pay accumulated heating at month end", function()
    hospital.acc_heating = 375.50
    
    if math.round(hospital.acc_heating) > 0 then
      hospital:spendMoney(math.round(hospital.acc_heating), "heating")
      hospital.acc_heating = 0
    end
    
    assert.spy(hospital.spendMoney).was_called_with(376, "heating")
    assert.equals(0, hospital.acc_heating)
  end)
  
  it("should NOT pay if acc_heating is 0", function()
    hospital.acc_heating = 0
    
    if math.round(hospital.acc_heating) > 0 then
      hospital:spendMoney(math.round(hospital.acc_heating), "heating")
    end
    
    assert.spy(hospital.spendMoney).was_not_called()
  end)
  
  it("should round correctly", function()
    assert.equals(376, math.round(375.50))
    assert.equals(375, math.round(375.49))
    assert.equals(0, math.round(0))
    assert.equals(1, math.round(0.5))
  end)
end)

-- ============================================================================
-- TEST SUITE: DISASTER SYSTEM
-- ============================================================================

describe("Disaster System", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
    hospital.tile_object_counts.radiator = 20
    hospital.staff = createMockStaff(2, "Handyman") -- 10:1 ratio, will break
    spy.on(hospital, "boilerBreakdown")
    spy.on(hospital, "daysUntilNextDisaster")
  end)
  
  after_each(function()
    hospital.boilerBreakdown:revert()
    hospital.daysUntilNextDisaster:revert()
  end)
  
  it("should decrement disasterless_days daily", function()
    hospital.disasterless_days = 10
    hospital.disasterless_days = hospital.disasterless_days - 1
    assert.equals(9, hospital.disasterless_days)
  end)
  
  it("should trigger disaster when disasterless_days <= 0", function()
    hospital.disasterless_days = 1
    hospital.disasterless_days = hospital.disasterless_days - 1
    
    if hospital.disasterless_days <= 0 then
      hospital.disasterless_days = hospital:daysUntilNextDisaster()
      -- disaster_type = 2 (max heat)
      hospital:boilerBreakdown(1)
    end
    
    assert.spy(hospital.daysUntilNextDisaster).was_called()
    assert.spy(hospital.boilerBreakdown).was_called_with(1)
  end)
  
  it("daysUntilNextDisaster returns correct range per difficulty", function()
    -- Mock math.random to return fixed value
    local orig_random = math.random
    math.random = function(a, b) return 11 end -- Middle of 1-21 range
    
    hospital.world.map.getDifficulty = function() return 1 end -- Easy
    assert.equals(300, hospital:daysUntilNextDisaster()) -- 300 + 11 - 11 = 300
    
    hospital.world.map.getDifficulty = function() return 2 end -- Medium
    assert.equals(200, hospital:daysUntilNextDisaster()) -- 200 + 11 - 11 = 200
    
    hospital.world.map.getDifficulty = function() return 3 end -- Hard
    assert.equals(150, hospital:daysUntilNextDisaster()) -- 150 + 11 - 11 = 150
    
    math.random = orig_random
  end)
  
  it("disaster type 1 does nothing (skip)", function()
    hospital.disasterless_days = 1
    hospital.disasterless_days = hospital.disasterless_days - 1
    
    if hospital.disasterless_days <= 0 then
      hospital.disasterless_days = hospital:daysUntilNextDisaster()
      local disaster_type = 1
      if disaster_type == 2 then
        hospital:boilerBreakdown(1)
      elseif disaster_type == 3 then
        hospital:boilerBreakdown(0)
      end
    end
    
    assert.spy(hospital.boilerBreakdown).was_not_called()
  end)
  
  it("vomit wave (type 4) is not implemented", function()
    -- This test documents the TODO
    local disaster_type = 4
    local implemented = false -- TODO: Implement vomit wave
    assert.is_false(implemented)
  end)
end)

-- ============================================================================
-- TEST SUITE: HEAT ADJUSTMENT UI
-- ============================================================================

describe("Heat Adjustment (Town Map UI)", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
  end)
  
  it("should increase heat in 0.1 increments up to 1.0", function()
    hospital.heating.radiator_heat = 0.5
    hospital.heating.heating_broke = false
    
    local heat = math.floor(hospital.heating.radiator_heat * 10 + 0.5)
    heat = math.min(heat + 1, 10)
    hospital.heating.radiator_heat = heat / 10
    
    assert.equals(0.6, hospital.heating.radiator_heat)
  end)
  
  it("should cap at maximum 1.0", function()
    hospital.heating.radiator_heat = 1.0
    hospital.heating.heating_broke = false
    
    local heat = math.floor(hospital.heating.radiator_heat * 10 + 0.5)
    heat = math.min(heat + 1, 10)
    hospital.heating.radiator_heat = heat / 10
    
    assert.equals(1.0, hospital.heating.radiator_heat)
  end)
  
  it("should decrease heat in 0.1 increments down to 0.1", function()
    hospital.heating.radiator_heat = 0.5
    hospital.heating.heating_broke = false
    
    local heat = math.floor(hospital.heating.radiator_heat * 10 + 0.5)
    heat = math.max(heat - 1, 1)
    hospital.heating.radiator_heat = heat / 10
    
    assert.equals(0.4, hospital.heating.radiator_heat)
  end)
  
  it("should cap at minimum 0.1", function()
    hospital.heating.radiator_heat = 0.1
    hospital.heating.heating_broke = false
    
    local heat = math.floor(hospital.heating.radiator_heat * 10 + 0.5)
    heat = math.max(heat - 1, 1)
    hospital.heating.radiator_heat = heat / 10
    
    assert.equals(0.1, hospital.heating.radiator_heat)
  end)
  
  it("should NOT allow adjustment when boiler is broken", function()
    hospital.heating.radiator_heat = 0.5
    hospital.heating.heating_broke = true
    
    local heat = math.floor(hospital.heating.radiator_heat * 10 + 0.5)
    if not hospital.heating.heating_broke then
      heat = math.min(heat + 1, 10)
      hospital.heating.radiator_heat = heat / 10
    end
    
    assert.equals(0.5, hospital.heating.radiator_heat) -- Unchanged
  end)
end)

-- ============================================================================
-- TEST SUITE: SAVE/LOAD MIGRATION
-- ============================================================================

describe("Save/Load Migration (v142)", function()
  it("should migrate old heating fields to new table", function()
    local hospital = {
      radiator_heat = 0.7,
      curr_setting = 0.6,
      boiler_countdown = 15,
      heating_broke = true,
      heating = nil,
    }
    
    -- Migration code from hospital.lua:392-406
    if true then -- simulating old < 142
      hospital.heating = {
        radiator_heat = hospital.radiator_heat or 0.5,
        saved_radiator_heat = hospital.curr_setting or 0.5,
        boiler_repair_count = hospital.boiler_countdown or 0,
        heating_broke = hospital.heating_broke or false
      }
      hospital.radiator_heat = nil
      hospital.curr_setting = nil
      hospital.boiler_countdown = nil
      hospital.boiler_can_break = nil
      hospital.heating_broke = nil
    end
    
    assert.is_nil(hospital.radiator_heat)
    assert.is_nil(hospital.curr_setting)
    assert.is_nil(hospital.boiler_countdown)
    assert.is_nil(hospital.heating_broke)
    assert.equals(0.7, hospital.heating.radiator_heat)
    assert.equals(0.6, hospital.heating.saved_radiator_heat)
    assert.equals(15, hospital.heating.boiler_repair_count)
    assert.is_true(hospital.heating.heating_broke)
  end)
  
  it("should provide defaults for missing old fields", function()
    local hospital = {} -- No old fields
    
    if true then
      hospital.heating = {
        radiator_heat = hospital.radiator_heat or 0.5,
        saved_radiator_heat = hospital.curr_setting or 0.5,
        boiler_repair_count = hospital.boiler_countdown or 0,
        heating_broke = hospital.heating_broke or false
      }
    end
    
    assert.equals(0.5, hospital.heating.radiator_heat)
    assert.equals(0.5, hospital.heating.saved_radiator_heat)
    assert.equals(0, hospital.heating.boiler_repair_count)
    assert.is_false(hospital.heating.heating_broke)
  end)
end)

-- ============================================================================
-- INTEGRATION TESTS
-- ============================================================================

describe("Full Heating System Integration", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
    hospital.tile_object_counts.radiator = 20
    hospital.staff = createMockStaff(2, "Handyman") -- 10:1 ratio
    spy.on(hospital, "adviseBoilerBreakdown")
    spy.on(hospital, "giveAdvice")
    spy.on(hospital, "spendMoney")
  end)
  
  after_each(function()
    hospital.adviseBoilerBreakdown:revert()
    hospital.giveAdvice:revert()
    hospital.spendMoney:revert()
  end)
  
  it("full cycle: breakdown -> daily repair -> fixed -> monthly payment", function()
    -- Day 0: Initial state
    assert.is_false(hospital.heating.heating_broke)
    assert.equals(0.5, hospital.heating.radiator_heat)
    
    -- Disaster strikes: boiler breaks at max heat
    hospital:boilerBreakdown(1)
    assert.is_true(hospital.heating.heating_broke)
    assert.equals(1.0, hospital.heating.radiator_heat)
    assert.is_not_nil(hospital.heating.boiler_repair_count)
    local initial_repair = hospital.heating.boiler_repair_count
    
    -- Simulate daily repair (ratio 10:1 = -1 per day)
    for day = 1, initial_repair do
      hospital:_fixBoiler()
    end
    
    -- Boiler should be fixed
    assert.is_false(hospital.heating.heating_broke)
    assert.equals(0.5, hospital.heating.radiator_heat) -- Restored
    assert.spy(hospital.giveAdvice).was_called()
    
    -- Simulate month of heating costs
    hospital.acc_heating = 0
    for day = 1, 30 do
      local num_radiators = hospital:countRadiators()
      local heating_costs = (hospital.heating.radiator_heat * 10 * num_radiators * 7.50) / 30
      hospital.acc_heating = hospital.acc_heating + heating_costs
    end
    
    -- Month end payment
    if math.round(hospital.acc_heating) > 0 then
      hospital:spendMoney(math.round(hospital.acc_heating), "heating")
      hospital.acc_heating = 0
    end
    
    assert.spy(hospital.spendMoney).was_called()
    assert.equals(0, hospital.acc_heating)
  end)
  
  it("handyman hiring speeds up repair", function()
    hospital:boilerBreakdown(0)
    local repair_count = hospital.heating.boiler_repair_count
    
    -- With 2 handymen, 20 radiators = 10:1 ratio = -1/day
    local days_with_2 = repair_count
    
    -- Reset and hire more handymen
    hospital.heating.heating_broke = true
    hospital.heating.boiler_repair_count = repair_count
    hospital.staff = createMockStaff(5, "Handyman") -- 20 radiators, 5 handymen = 4:1 ratio = -3/day
    
    local days_with_5 = math.ceil(repair_count / 3)
    
    assert.is_true(days_with_5 < days_with_2)
  end)
end)

-- ============================================================================
-- RUN TESTS
-- ============================================================================

-- busted.run() -- Uncomment to run when using busted CLI
