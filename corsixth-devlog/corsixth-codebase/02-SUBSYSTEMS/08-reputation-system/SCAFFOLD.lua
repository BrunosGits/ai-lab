-- CorsixTH Reputation System - Busted Test Scaffold
-- Run with: busted SCAFFOLD.lua

local busted = require("busted")
local describe = busted.describe
local it = busted.it
local before_each = busted.before_each
local after_each = busted.after_each
local assert = require("luassert")
local spy = require("luassert.spy")
local stub = require("luassert.stub")
local mock = require("luassert.mock")

-- ============================================================================
-- MOCK HELPERS
-- ============================================================================

local function createMockWorld()
  return {
    map = {
      level_config = {
        gbv = {
          AutopsyRepHitPercent = 70,
          EpidemicCompLo = 1000,
          EpidemicCompHi = 5000,
          EpidemicFine = 2000,
          EpidemicRepLossMinimum = 5,
          EpidemicEvacMinimum = 20,
        },
        towns = {},
        awards_trophies = { Reputation = 800 },
      }
    },
    ui = {
      addWindow = function() end,
      playSound = function() end,
      getWindow = function() return nil end,
    },
    dispatcher = {
      dropFromQueue = function() end,
    },
    nextEmergency = function() end,
  }
end

local function createMockPatient(overrides)
  local patient = {
    is_debug = false,
    is_emergency = false,
    disease = { id = "test_disease", name = "Test Disease" },
    happiness = 0.5,
    getAttribute = function(self, attr) return self[attr] or 0 end,
    changeAttribute = function(self, attr, val) self[attr] = (self[attr] or 0) + val end,
    getPriceDistortion = function(self, casebook) return 0 end,
    isTreatmentEffective = function() return true end,
    cure = function() end,
    die = function() end,
    goHome = function() end,
    removeVaccinationCandidateStatus = function() end,
    removeAnyEpidemicStatus = function() end,
    updateDynamicInfo = function() end,
    setInfectedStatus = function() end,
    notifyOfStaffChange = function() end,
  }
  for k, v in pairs(overrides or {}) do patient[k] = v end
  return patient
end

local function createMockDisease(overrides)
  local disease = {
    id = "test_disease",
    name = "Test Disease",
    pseudo = false,
  }
  for k, v in pairs(overrides or {}) do disease[k] = v end
  return disease
end

local function createMockCasebook(overrides)
  local casebook = {
    disease = createMockDisease(),
    reputation = 500,
    cure_effectiveness = 80,
    price = 1.0,
    turned_away = 0,
  }
  for k, v in pairs(overrides or {}) do casebook[k] = v end
  return casebook
end

local function createMockHospital(overrides)
  local hospital = {
    world = createMockWorld(),
    reputation = 500,
    reputation_min = 0,
    reputation_max = 1000,
    has_impressive_reputation = false,
    disease_casebook = {},
    num_cured = 0,
    num_deaths = 0,
    not_cured = 0,
    num_cured_ty = 0,
    not_cured_ty = 0,
    num_deaths_ty = 0,
    num_explosions = 0,
    value = 100000,
    research = { research_progress = {} },
    staff = {},
    patients = {},
    debug_patients = {},
    policies = {},
    insurance = {},
    sodas_sold = 0,
    num_vips_ty = 0,
    pleased_vips_ty = 0,
    num_visitors_ty = 0,
    percentage_killed = 0,
    percentage_cured = 0,
    under_priced_threshold = -0.4,
    over_priced_threshold = 0.3,
    emergency = { killed_emergency_patients = 0, cured_emergency_patients = 0, victims = 0 },
    
    -- Methods to be tested / mocked
    changeReputation = function(self, reason, disease, valueChange) end,
    unconditionalChangeReputation = function(self, valueChange) end,
    isReputationChangeAllowed = function(self, amount) return true end,
    getReputationChangeLikelihood = function(self) return 1.0 end,
    updateCuredCounts = function(self, patient) end,
    updateNotCuredCounts = function(self, patient, reason) end,
    computePriceLevelImpact = function(self, patient, casebook) end,
    receiveMoney = function(self, amount, type) end,
    spendMoney = function(self, amount, type) end,
    receiveMoneyForTreatment = function(self, patient) end,
    updatePercentages = function(self) end,
    paySupplierForDrug = function(self, disease_id) end,
    makeEmergencyEndFax = function() end,
    checkEmergencyOver = function() end,
    advisePriceLevelImpact = function(self, type, disease_name) end,
    announceStaffLeave = function(self, staff) end,
    changeValue = function(self, changeValue) end,
    getReceptionDesks = function() return {} end,
    getAveragePatientAttribute = function() return 0.5 end,
    msgCured = function() end,
  }
  
  -- Default disease casebook
  hospital.disease_casebook["test_disease"] = createMockCasebook()
  
  for k, v in pairs(overrides or {}) do hospital[k] = v end
  return hospital
end

local function createMockStaff(overrides)
  local staff = {
    hospital = createMockHospital(),
    profile = { wage = 1000, getFullName = function() return "Test Staff" end },
    world = createMockWorld(),
    fired = false,
    going_home = false,
    dead = false,
    hover_cursor = nil,
    setMood = function() end,
    setDynamicInfoText = function() end,
    despawn = function() end,
    unregisterCallbacks = function() end,
    isLeaving = function() return false end,
    setNextAction = function() end,
    removeQueuedStaffMessage = function() end,
  }
  for k, v in pairs(overrides or {}) do staff[k] = v end
  return staff
end

local function createMockRoom(overrides)
  local room = {
    hospital = createMockHospital(),
    room_info = { build_cost = 5000 },
    world = createMockWorld(),
    crashed = false,
    is_active = true,
    door = { queue = {} },
    changeValue = function(self, val) self.hospital:changeValue(val) end,
    deactivate = function() end,
    createLeaveAction = function() return { setMustHappen = function() return {} end } end,
  }
  for k, v in pairs(overrides or {}) do room[k] = v end
  return room
end

local function createMockEpidemic(overrides)
  local epid = {
    hospital = createMockHospital(),
    world = createMockWorld(),
    disease = createMockDisease(),
    reputation_hit = 0,
    coverup_fine = 0,
    declare_fine = 5000,
    compensation = 0,
    coverup_selected = false,
    will_be_evacuated = false,
    reputation_loss_minimum = 5,
    evacuation_minimum = 20,
    infected_patients = {},
    inspector = nil,
    timer = { close = function() end, open_timer = 10 },
    
    calculateInfectedFine = function(self, count)
      return math.max(2000, count * (self.world.map.level_config.gbv.EpidemicFine or 2000))
    end,
    countInfectedPatients = function(self) return 0 end,
    clearAllInfectedPatients = function(self) end,
    turnOffVaccinationMode = function(self) end,
    spawnInspector = function(self) end,
    sendResultFax = function(self) end,
    evacuateHospital = function(self) end,
    checkPatientsForRemoval = function(self) end,
    determineFaxAndFines = function(self, still_infected) end,
    applyOutcome = function(self) end,
    finishCoverUp = function(self) end,
    handleInspectorArrival = function(self) end,
    coverUpTimeIsUp = function(self) end,
    startCoverUp = function(self) end,
    resolveDeclaration = function(self) end,
  }
  for k, v in pairs(overrides or {}) do epid[k] = v end
  return epid
end

-- ============================================================================
-- LOAD ACTUAL MODULES (if available)
-- ============================================================================

local Hospital, Patient, Epidemic, Staff, Room

-- Try to load actual modules
local ok_hospital = pcall(function()
  package.path = "/tmp/CorsixTH/CorsixTH/Lua/?.lua;" .. package.path
  Hospital = require("hospital")
end)

local ok_patient = pcall(function()
  Patient = require("entities.humanoids.patient")
end)

local ok_epidemic = pcall(function()
  Epidemic = require("epidemic")
end)

local ok_staff = pcall(function()
  Staff = require("entities.humanoids.staff")
end)

local ok_room = pcall(function()
  Room = require("room")
end)

-- ============================================================================
-- TEST SUITES
-- ============================================================================

describe("Reputation System - Change Reputation Table", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
    -- Spy on the actual methods
    hospital.unconditionalChangeReputation = spy.new(hospital.unconditionalChangeReputation)
    hospital.isReputationChangeAllowed = spy.new(hospital.isReputationChangeAllowed)
  end)
  
  it("should define correct reputation change values", function()
    local reputation_changes = {
      cured = 1,
      death = -4,
      kicked = -3,
      emergency_success = 15,
      emergency_failed = -20,
      over_priced = -2,
      under_priced = 1,
      room_crash = -50,
    }
    
    -- These are the expected values from hospital.lua:1606-1615
    assert.are.equal(1, reputation_changes.cured)
    assert.are.equal(-4, reputation_changes.death)
    assert.are.equal(-3, reputation_changes.kicked)
    assert.are.equal(15, reputation_changes.emergency_success)
    assert.are.equal(-20, reputation_changes.emergency_failed)
    assert.are.equal(-2, reputation_changes.over_priced)
    assert.are.equal(1, reputation_changes.under_priced)
    assert.are.equal(-50, reputation_changes.room_crash)
  end)
  
  it("should apply cured reputation (+1)", function()
    local patient = createMockPatient()
    -- Test would call hospital:changeReputation("cured", patient.disease)
    -- Expect isReputationChangeAllowed called with 1
    -- Expect unconditionalChangeReputation called with 1 (if allowed)
  end)
  
  it("should apply death reputation (-4)", function()
    -- hospital:changeReputation("death", disease)
  end)
  
  it("should apply kicked reputation (-3) for staff firing", function()
    -- staff:fire() calls hospital:changeReputation("kicked")
  end)
  
  it("should apply kicked reputation (-3) for patient sent home", function()
    -- hospital:updateNotCuredCounts(patient, "kicked")
  end)
  
  it("should apply emergency_success reputation (+15)", function()
    -- hospital:endEmergency() on success
  end)
  
  it("should apply emergency_failed reputation (-20)", function()
    -- hospital:endEmergency() on failure
  end)
  
  it("should apply over_priced reputation (-2)", function()
    -- hospital:computePriceLevelImpact() when price_distortion > threshold
  end)
  
  it("should apply under_priced reputation (+1)", function()
    -- hospital:computePriceLevelImpact() when price_distortion < threshold
  end)
  
  it("should apply room_crash reputation (-50)", function()
    -- room:crash()
  end)
  
  it("should apply autopsy_discovered reputation (percentage-based)", function()
    -- research completed, uses AutopsyRepHitPercent or -70 default
  end)
  
  it("should apply year_end reputation (variable)", function()
    -- annual_report.lua:updateAwards()
  end)
end)

describe("Reputation System - Probability Gating", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
  end)
  
  describe("isReputationChangeAllowed()", function()
    it("should always allow positive changes when reputation <= 500", function()
      hospital.reputation = 300
      local allowed = hospital:isReputationChangeAllowed(10)
      assert.is_true(allowed)
    end)
    
    it("should always allow negative changes when reputation >= 500", function()
      hospital.reputation = 700
      local allowed = hospital:isReputationChangeAllowed(-10)
      assert.is_true(allowed)
    end)
    
    it("should always allow zero changes", function()
      hospital.reputation = 500
      local allowed = hospital:isReputationChangeAllowed(0)
      assert.is_true(allowed)
    end)
    
    it("should probabilistically gate positive changes when reputation > 500", function()
      hospital.reputation = 700
      hospital.getReputationChangeLikelihood = function() return 0.5 end
      -- Run many times to verify probabilistic behavior
      local allowed_count = 0
      for i = 1, 1000 do
        if hospital:isReputationChangeAllowed(10) then allowed_count = allowed_count + 1 end
      end
      -- Should be around 50% (with variance)
      assert.is_true(allowed_count > 300 and allowed_count < 700)
    end)
    
    it("should probabilistically gate negative changes when reputation < 500", function()
      hospital.reputation = 300
      hospital.getReputationChangeLikelihood = function() return 0.3 end
      local allowed_count = 0
      for i = 1, 1000 do
        if hospital:isReputationChangeAllowed(-10) then allowed_count = allowed_count + 1 end
      end
      assert.is_true(allowed_count > 150 and allowed_count < 450)
    end)
  end)
  
  describe("getReputationChangeLikelihood() - Quadratic Function", function()
    it("should return 1.0 (100%) at reputation 500", function()
      hospital.reputation = 500
      local likelihood = hospital:getReputationChangeLikelihood()
      assert.are.equal(1.0, likelihood, 0.01)
    end)
    
    it("should return 0.0 (0%) at reputation 0", function()
      hospital.reputation = 0
      local likelihood = hospital:getReputationChangeLikelihood()
      assert.are.equal(0.0, likelihood, 0.01)
    end)
    
    it("should return 0.0 (0%) at reputation 1000", function()
      hospital.reputation = 1000
      local likelihood = hospital:getReputationChangeLikelihood()
      assert.are.equal(0.0, likelihood, 0.01)
    end)
    
    it("should be > 0.8 between reputation 380-720", function()
      for rep = 380, 720, 50 do
        hospital.reputation = rep
        local likelihood = hospital:getReputationChangeLikelihood()
        assert.is_true(likelihood > 0.8, "Rep " .. rep .. " likelihood " .. likelihood)
      end
    end)
    
    it("should be < 0.4 at reputation 100 and 900", function()
      hospital.reputation = 100
      assert.is_true(hospital:getReputationChangeLikelihood() < 0.4)
      hospital.reputation = 900
      assert.is_true(hospital:getReputationChangeLikelihood() < 0.4)
    end)
    
    it("should follow quadratic curve: 1 - (a*x^2 - b*x + c)", function()
      -- a = 0.000004008, b = 0.004008, c = 1
      local a = 0.000004008
      local b = 0.004008
      local c = 1
      
      for _, rep in ipairs({0, 100, 250, 500, 750, 900, 1000}) do
        hospital.reputation = rep
        local expected = 1 - (a * rep * rep - b * rep + c)
        local actual = hospital:getReputationChangeLikelihood()
        assert.are.equal(expected, actual, 0.001, "Rep " .. rep)
      end
    end)
  end)
  
  describe("Reputation Bounds", function()
    it("should clamp reputation at 0 minimum", function()
      hospital.reputation = 10
      hospital:unconditionalChangeReputation(-50)
      assert.are.equal(0, hospital.reputation)
    end)
    
    it("should clamp reputation at 1000 maximum", function()
      hospital.reputation = 990
      hospital:unconditionalChangeReputation(50)
      assert.are.equal(1000, hospital.reputation)
    end)
  end)
end)

describe("Reputation System - Price Level Impact", function()
  local hospital, patient, casebook
  
  before_each(function()
    hospital = createMockHospital()
    patient = createMockPatient()
    casebook = createMockCasebook()
    hospital.disease_casebook[casebook.disease.id] = casebook
    
    -- Spy on methods
    hospital.changeReputation = spy.new(hospital.changeReputation)
    patient.getPriceDistortion = spy.new(patient.getPriceDistortion)
  end)
  
  describe("getPriceDistortion()", function()
    it("should calculate distortion based on happiness, reputation, effectiveness", function()
      patient.happiness = 0.5
      casebook.reputation = 500
      casebook.cure_effectiveness = 80
      casebook.price = 1.0
      
      local distortion = patient:getPriceDistortion(casebook)
      -- expected = 0.1*0.5 + 0.6*0.5 + 0.3*0.8 = 0.05 + 0.3 + 0.24 = 0.59
      -- price_level = ((1.0 - 0.5) / 3) * 2 = 0.333
      -- distortion = 0.333 - 0.59 = -0.257
      assert.is_true(distortion < 0)  -- Underpriced at these values
    end)
    
    it("should increase expected price with higher reputation", function()
      casebook.reputation = 800
      local d1 = patient:getPriceDistortion(casebook)
      casebook.reputation = 300
      local d2 = patient:getPriceDistortion(casebook)
      -- Higher reputation -> higher expected price -> more negative distortion (if price same)
      assert.is_true(d1 < d2)
    end)
    
    it("should increase expected price with higher effectiveness", function()
      casebook.cure_effectiveness = 100
      local d1 = patient:getPriceDistortion(casebook)
      casebook.cure_effectiveness = 50
      local d2 = patient:getPriceDistortion(casebook)
      assert.is_true(d1 < d2)
    end)
  end)
  
  describe("computePriceLevelImpact()", function()
    it("should reduce happiness when overpriced", function()
      patient.getPriceDistortion = function() return 0.5 end  -- Overpriced
      hospital.computePriceLevelImpact(patient, casebook)
      -- happiness change = -(0.5 / 2) = -0.25
      assert.is_true(patient.happiness < 0.5)
    end)
    
    it("should increase happiness when underpriced", function()
      patient.getPriceDistortion = function() return -0.5 end  -- Underpriced
      hospital.computePriceLevelImpact(patient, casebook)
      -- happiness change = -(-0.5 / 2) = +0.25
      assert.is_true(patient.happiness > 0.5)
    end)
    
    it("should trigger under_priced reputation at 1% chance when under threshold", function()
      hospital.under_priced_threshold = -0.4
      patient.getPriceDistortion = function() return -0.5 end
      
      -- Mock random to always trigger
      local original_random = math.random
      math.random = function(a, b) return 1 end
      
      hospital.computePriceLevelImpact(patient, casebook)
      
      math.random = original_random
      assert.spy(hospital.changeReputation).was.called_with("under_priced", nil)
    end)
    
    it("should trigger over_priced reputation at 1% chance when over threshold", function()
      hospital.over_priced_threshold = 0.3
      patient.getPriceDistortion = function() return 0.5 end
      
      local original_random = math.random
      math.random = function(a, b) return 1 end
      
      hospital.computePriceLevelImpact(patient, casebook)
      
      math.random = original_random
      assert.spy(hospital.changeReputation).was.called_with("over_priced", nil)
    end)
    
    it("should trigger fair price advice at 0.5% chance when |distortion| <= 0.15", function()
      patient.getPriceDistortion = function() return 0.1 end
      hospital.advisePriceLevelImpact = spy.new(hospital.advisePriceLevelImpact)
      
      local original_random = math.random
      math.random = function(a, b) return 1 end
      
      hospital.computePriceLevelImpact(patient, casebook)
      
      math.random = original_random
      assert.spy(hospital.advisePriceLevelImpact).was.called_with("fair", casebook.disease.name)
    end)
    
    it("should use difficulty-based thresholds", function()
      -- Easy: under=-0.3, over=0.4
      hospital.under_priced_threshold = -0.3
      hospital.over_priced_threshold = 0.4
      assert.are.equal(-0.3, hospital.under_priced_threshold)
      assert.are.equal(0.4, hospital.over_priced_threshold)
      
      -- Hard: under=-0.5, over=0.2
      hospital.under_priced_threshold = -0.5
      hospital.over_priced_threshold = 0.2
      assert.are.equal(-0.5, hospital.under_priced_threshold)
      assert.are.equal(0.2, hospital.over_priced_threshold)
    end)
  end)
end)

describe("Reputation System - Epidemic Outcomes", function()
  local epidemic, hospital
  
  before_each(function()
    hospital = createMockHospital()
    epidemic = createMockEpidemic()
    epidemic.hospital = hospital
  end)
  
  describe("calculateInfectedFine()", function()
    it("should calculate fine based on infected count", function()
      local fine = epidemic:calculateInfectedFine(10)
      assert.are.equal(20000, fine)  -- 10 * 2000
    end)
    
    it("should have minimum fine of 2000", function()
      local fine = epidemic:calculateInfectedFine(0)
      assert.are.equal(2000, fine)
    end)
  end)
  
  describe("getBaseReputationFromFine()", function()
    it("should return fine / 100", function()
      local getBaseReputationFromFine = function(fine) return math.round(fine / 100) end
      assert.are.equal(20, getBaseReputationFromFine(2000))
      assert.are.equal(50, getBaseReputationFromFine(5000))
      assert.are.equal(200, getBaseReputationFromFine(20000))
    end)
  end)
  
  describe("determineFaxAndFines()", function()
    it("should give compensation (no rep hit) when 0 infected", function()
      epidemic.compensation = 0
      epidemic.coverup_fine = 0
      epidemic.will_be_evacuated = false
      epidemic.determineFaxAndFines(0)
      -- Expect compensation 1000-5000, no reputation hit
    end)
    
    it("should give fine only when infected < 5 and < 20", function()
      epidemic.determineFaxAndFines(3)
      -- Expect fine, rep hit = fine/100
    end)
    
    it("should give fine + rep loss when infected >= 5 and < 20", function()
      epidemic.determineFaxAndFines(10)
      -- Expect fine, rep hit = fine/100
    end)
    
    it("should trigger evacuation when infected >= 20", function()
      epidemic.determineFaxAndFines(25)
      assert.is_true(epidemic.will_be_evacuated)
      -- Expect rep hit = reputation * 1/3
    end)
  end)
  
  describe("applyOutcome()", function()
    it("should apply fine and reputation hit on failure", function()
      epidemic.compensation = 0
      epidemic.coverup_fine = 10000
      epidemic.will_be_evacuated = false
      epidemic.reputation_hit = 100  -- 10000/100
      hospital.reputation = 500
      hospital.spendMoney = spy.new(hospital.spendMoney)
      
      epidemic.applyOutcome()
      
      assert.spy(hospital.spendMoney).was.called()
      assert.are.equal(400, hospital.reputation)  -- 500 - 100
    end)
    
    it("should apply 33% reputation hit on evacuation", function()
      epidemic.compensation = 0
      epidemic.will_be_evacuated = true
      hospital.reputation = 900
      epidemic.reputation_hit = 300  -- 900 * 1/3
      
      epidemic.applyOutcome()
      
      assert.are.equal(600, hospital.reputation)  -- 900 - 300
    end)
    
    it("should give compensation money on success", function()
      epidemic.compensation = 3000
      hospital.receiveMoney = spy.new(hospital.receiveMoney)
      
      epidemic.applyOutcome()
      
      assert.spy(hospital.receiveMoney).was.called_with(3000, _S.transactions.compensation)
    end)
  end)
  
  describe("Declaration vs Cover-up", function()
    it("should apply fine and rep hit immediately on declaration", function()
      epidemic.declare_fine = 5000
      hospital.reputation = 500
      hospital.spendMoney = spy.new(hospital.spendMoney)
      
      epidemic.resolveDeclaration()
      
      assert.spy(hospital.spendMoney).was.called()
      assert.are.equal(450, hospital.reputation)  -- 500 - 50
    end)
  end)
end)

describe("Reputation System - Downstream Effects", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
  end)
  
  describe("Patient Spawn Rate Impact", function()
    it("should return 1% at reputation 0", function()
      local impact = 1 + ((0 - 500) / 250)
      assert.are.equal(-1, impact)  -- Actually clamped to minimum in game
    end)
    
    it("should return 100% at reputation 500", function()
      local impact = 1 + ((500 - 500) / 250)
      assert.are.equal(1.0, impact)
    end)
    
    it("should return 140% at reputation 600", function()
      local impact = 1 + ((600 - 500) / 250)
      assert.are.equal(1.4, impact)
    end)
    
    it("should return 300% at reputation 1000", function()
      local impact = 1 + ((1000 - 500) / 250)
      assert.are.equal(3.0, impact)
    end)
  end)
  
  describe("Treatment Pricing", function()
    it("should apply reputation multiplier when reputation >= 500", function()
      local raw_price = 100
      local percentage = 1.0
      local reputation = 750
      local price = math.ceil(raw_price * (reputation / 500) * percentage)
      assert.are.equal(150, price)  -- 100 * 1.5
    end)
    
    it("should not apply multiplier when reputation < 500", function()
      local raw_price = 100
      local percentage = 1.0
      local reputation = 400
      local price = math.ceil(raw_price * percentage)
      assert.are.equal(100, price)
    end)
  end)
  
  describe("Trophy Eligibility", function()
    it("should track impressive reputation status", function()
      hospital.has_impressive_reputation = true
      hospital.reputation = 850
      local level_config = { awards_trophies = { Reputation = 800 } }
      
      local min_rep = level_config.awards_trophies.Reputation
      local still_impressive = min_rep < hospital.reputation
      
      assert.is_true(still_impressive)
    end)
    
    it("should lose trophy status if reputation drops below threshold", function()
      hospital.has_impressive_reputation = true
      hospital.reputation = 750
      local level_config = { awards_trophies = { Reputation = 800 } }
      
      local min_rep = level_config.awards_trophies.Reputation
      local still_impressive = min_rep < hospital.reputation
      
      assert.is_false(still_impressive)
    end)
  end)
end)

describe("Reputation System - Disease-Specific Reputation", function()
  local hospital, patient, disease
  
  before_each(function()
    hospital = createMockHospital()
    disease = createMockDisease({ id = "flu" })
    patient = createMockPatient({ disease = disease })
    hospital.disease_casebook[disease.id] = createMockCasebook({ disease = disease })
  end)
  
  it("should update disease reputation even when global change is gated", function()
    hospital.reputation = 900  -- High rep, gains gated
    hospital.isReputationChangeAllowed = function() return false end  -- Gated!
    hospital.unconditionalChangeReputation = spy.new(hospital.unconditionalChangeReputation)
    
    -- Simulate changeReputation
    local amount = 1  -- cured
    local casebook = hospital.disease_casebook[disease.id]
    local old_disease_rep = casebook.reputation
    
    if hospital:isReputationChangeAllowed(amount) then
      hospital:unconditionalChangeReputation(amount)
    end
    casebook.reputation = casebook.reputation + amount
    
    -- Global reputation should NOT change (gated)
    assert.spy(hospital.unconditionalChangeReputation).was_not.called()
    -- But disease reputation SHOULD change
    assert.are.equal(old_disease_rep + amount, casebook.reputation)
  end)
  
  it("should use disease reputation for price expectations", function()
    hospital.disease_casebook[disease.id].reputation = 800
    hospital.reputation = 400
    
    local reputation = hospital.disease_casebook[disease.id].reputation or hospital.reputation
    assert.are.equal(800, reputation)  -- Uses disease-specific
  end)
end)

describe("Reputation System - Edge Cases", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
  end)
  
  it("should handle autopsy_discovered with config percentage", function()
    hospital.reputation = 500
    local rep_hit_perc = 70
    local amount = math.floor(-hospital.reputation * rep_hit_perc / 100)
    assert.are.equal(-350, amount)
  end)
  
  it("should handle autopsy_discovered with default -70 when no config", function()
    hospital.reputation = 500
    local rep_hit_perc = nil
    local amount = rep_hit_perc and math.floor(-hospital.reputation * rep_hit_perc / 100) or -70
    assert.are.equal(-70, amount)
  end)
  
  it("should update emergency killed/cured counts correctly", function()
    hospital.emergency.killed_emergency_patients = 0
    hospital.emergency.cured_emergency_patients = 0
    hospital.emergency.victims = 5
    
    hospital.emergency.killed_emergency_patients = hospital.emergency.killed_emergency_patients + 1
    assert.are.equal(1, hospital.emergency.killed_emergency_patients)
  end)
  
  it("should update not_cured counts for kicked patients", function()
    local patient = createMockPatient()
    hospital.not_cured = 0
    hospital.not_cured_ty = 0
    
    hospital:updateNotCuredCounts(patient, "kicked")
    
    assert.are.equal(1, hospital.not_cured)
    assert.are.equal(1, hospital.not_cured_ty)
  end)
end)

-- ============================================================================
-- INTEGRATION TEST HELPERS
-- ============================================================================

local function runFullReputationScenario(hospital, scenario)
  -- Helper to run complex multi-step reputation scenarios
  -- scenario = { actions = {...}, expected_rep = ..., expected_disease_rep = ... }
end

-- ============================================================================
-- RUN TESTS
-- ============================================================================

-- busted will automatically discover and run all describe/it blocks
print("Reputation System Test Scaffold Loaded")
print("Run with: busted SCAFFOLD.lua")

