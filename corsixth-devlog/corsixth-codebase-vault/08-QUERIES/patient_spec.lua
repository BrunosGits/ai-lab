require("corsixth")
require("class_test_base")
require("utility")

local saved_A = _G._A
_G._A = {cheats = {}}
require("map")
require("entity")
require("entities.humanoid")
require("entities.humanoids.patient")

-- Auto-vivifying strings + minimal app stubs (spec-local only).
local function auto_table()
  return setmetatable({}, {__index = function(t, k)
    local v = auto_table()
    rawset(t, k, v)
    return v
  end})
end
_G._S = auto_table()
_G.TheApp = {gfx = {loadMainCursor = function() return {} end},
  humanoid_actions = setmetatable({}, {__index = function() return function() end end})}
_G.MockAction = setmetatable({name = "mock"}, {__index = function() return function() return _G.MockAction end end})
_G.MeanderAction = function() return _G.MockAction end
_G.DieAction = function() return _G.MockAction end

local Patient = _G["Patient"]

local function noop_anim()
  return setmetatable({}, {__index = function() return function() end end})
end

local function makeWorld()
  return {
    map = {th = {markRoom = function() end}},
    getRoom = function() return nil end,
    getHospital = function() return {disease_casebook = {}} end,
    dispatcher = {callForStaff = function() end},
    ui = {getWindow = function() return nil end},
  }
end

local function makeHospital()
  return {
    disease_casebook = {},
    policies = {stop_procedure = 1},
    addHandymanTask = function() end,
    giveAdvice = function() end,
    changeReputation = function() end,
    receiveMoneyForTreatment = function() end,
    updatePercentages = function() end,
    paySupplierForDrug = function() end,
    humanoidDeath = function(self, p)
      self.deaths = (self.deaths or 0) + 1
    end,
  }
end

local function makeDisease()
  return {
    id = "test_disease",
    name = "Test Disease",
    initPatient = function() end,
    diagnosis_rooms = {},
  }
end

local function makePatient()
  local p = Patient(noop_anim())
  p.world = makeWorld()
  p.hospital = makeHospital()
  return p
end

describe("patient.lua: Patient lifecycle", function()
  describe("Constructor", function()
    it("initializes with default flags", function()
      local p = makePatient()
      assert.is_false(p.cured)
      assert.is_false(p.dead)
      assert.is_false(p.going_to_die)
      assert.is_false(p.set_to_die)
      assert.are.equal(0, p.diagnosis_progress)
    end)
  end)

  describe("setDisease", function()
    it("stores disease and resets diagnosis state", function()
      local p = makePatient()
      local d = makeDisease()
      p:setDisease(d)
      assert.are.equal(d, p.disease)
      assert.is_false(p.diagnosed)
      assert.are.equal(0, p.diagnosis_progress)
      assert.are.equal(0, p.cure_rooms_visited)
    end)
  end)

  describe("setDiagnosed", function()
    it("marks diagnosed and records treatment history", function()
      local p = makePatient()
      p.updateDynamicInfo = function() end
      p:setDisease(makeDisease())
      p:setDiagnosed()
      assert.is_true(p.diagnosed)
      assert.are.equal("Test Disease", p.treatment_history[1])
    end)
  end)

  describe("modifyDiagnosisProgress", function()
    it("accumulates and clamps to stop_procedure", function()
      local p = makePatient()
      p:modifyDiagnosisProgress(0.4)
      assert.are.equal(0.4, p.diagnosis_progress)
      p:modifyDiagnosisProgress(10)
      assert.are.equal(1, p.diagnosis_progress)
    end)

    it("floors at zero", function()
      local p = makePatient()
      p:modifyDiagnosisProgress(-5)
      assert.are.equal(0, p.diagnosis_progress)
    end)
  end)

  describe("cure", function()
    it("sets cured, clears infected, restores health", function()
      local p = makePatient()
      p.infected = true
      p:cure()
      assert.is_true(p.cured)
      assert.is_false(p.infected)
      assert.are.equal(1, p.attributes["health"])
    end)
  end)

  describe("die", function()
    it("sets going_to_die and notifies hospital", function()
      local p = makePatient()
      p.mood_info = setmetatable({}, {__index = function() return function() end end})
      p:die()
      assert.is_true(p.going_to_die)
      assert.is_false(p.set_to_die)
      assert.are.equal(1, p.hospital.deaths)
    end)

    it("does nothing when already cured", function()
      local p = makePatient()
      p.mood_info = setmetatable({}, {__index = function() return function() end end})
      p.cured = true
      p:die()
      assert.is_false(p.going_to_die)
      assert.is_nil(p.hospital.deaths)
    end)
  end)

  describe("setToDying", function()
    it("flags the patient for deferred death", function()
      local p = makePatient()
      p:setToDying()
      assert.is_true(p.set_to_die)
    end)
  end)
end)
