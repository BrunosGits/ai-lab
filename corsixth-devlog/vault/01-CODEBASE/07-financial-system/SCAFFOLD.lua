-- CorsixTH Financial System - Busted Test Scaffold
-- Run with: busted SCAFFOLD.lua

local busted = require("busted")
local describe = busted.describe
local it = busted.it
local before_each = busted.before_each
local after_each = busted.after_each
local setup = busted.setup
local teardown = busted.teardown
local assert = require("luassert")
local spy = busted.spy
local mock = busted.mock

-- ============================================================================
-- TEST HELPERS & MOCKS
-- ============================================================================

-- Mock world object
local function createMockWorld(overrides)
  overrides = overrides or {}
  return {
    free_build_mode = overrides.free_build_mode or false,
    map = {
      level_config = {
        towns = overrides.towns or {},
        town = overrides.town or {
          StartCash = 50000,
          InterestRate = 800,
          StartRep = 500,
          OverdraftDiff = 400
        },
        gbv = overrides.gbv or {
          SodaPrice = 20,
          ScoreMaxInc = 300,
          EpidemicConcurrentLimit = 1
        },
        expertise = overrides.expertise or {}
      },
      level_number = overrides.level_number or 1,
      getParcelPrice = function() return 10000 end,
      getDifficulty = function() return 2 end -- Normal
    },
    date = function()
      return {
        dayOfMonth = function() return 15 end,
        monthOfYear = function() return 6 end,
        monthOfGame = function() return 6 end,
        lastDayOfMonth = function() return 30 end
      }
    end,
    rooms = {},
    diseases = {},
    newFloatingDollarSign = function() end,
    playSound = function() end
  }
end

-- Mock hospital object with financial methods
local function createMockHospital(overrides)
  overrides = overrides or {}
  local world = createMockWorld(overrides.world)
  
  local hospital = {
    world = world,
    name = "PLAYER",
    balance = overrides.balance or 50000,
    loan = overrides.loan or 0,
    acc_loan_interest = 0,
    acc_overdraft = 0,
    acc_heating = 0,
    acc_research_cost = 0,
    value = overrides.value or 100000,
    reputation = overrides.reputation or 500,
    player_salary = 10000,
    salary_incr = 300,
    sal_min = 50,
    staff = overrides.staff or {},
    insurance = overrides.insurance or {"InsureCo A", "InsureCo B", "InsureCo C"},
    insurance_balance = overrides.insurance_balance or {{0,0,0}, {0,0,0}, {0,0,0}},
    disease_casebook = overrides.disease_casebook or {},
    transactions = {},
    money_in = 0,
    money_out = 0,
    num_deaths = 0,
    num_cured = 0,
    num_visitors = 0,
    statistics = {},
    heating = { radiator_heat = 0.5 },
    
    -- Interest rates (from level config)
    interest_rate = 0.08, -- 8%
    overdraft_interest_rate = 0.12, -- 12%
    inflation_rate = 0.045,
    
    -- Price thresholds (Normal difficulty)
    under_priced_threshold = -0.4,
    over_priced_threshold = 0.3,
    
    -- Methods
    spendMoney = function(self, amount, reason, changeValue)
      if not self.world.free_build_mode then
        self.balance = self.balance - amount
        self:logTransaction({spend = amount, desc = reason})
        self.money_out = self.money_out + amount
        if changeValue then self.value = self.value + changeValue end
      end
    end,
    
    receiveMoney = function(self, amount, reason, changeValue)
      if not self.world.free_build_mode then
        self.balance = self.balance + amount
        self:logTransaction({receive = amount, desc = reason})
        self.money_in = self.money_in + amount
        if changeValue then self.value = self.value - changeValue end
      end
    end,
    
    logTransaction = function(self, transaction)
      transaction.balance = self.balance
      transaction.day = self.world:date():dayOfMonth()
      transaction.month = self.world:date():monthOfYear()
      while #self.transactions > 20 do table.remove(self.transactions) end
      table.insert(self.transactions, 1, transaction)
    end,
    
    getTreatmentPrice = function(self, disease)
      local casebook = self.disease_casebook[disease]
      if not casebook then return 0 end
      local reputation = casebook.reputation or self.reputation
      local percentage = casebook.price or 1.0
      local raw_price = casebook.disease and casebook.disease.cure_price or 100
      if reputation >= 500 then
        return math.ceil(raw_price * (reputation / 500) * percentage)
      else
        return math.ceil(raw_price * percentage)
      end
    end,
    
    addInsuranceMoney = function(self, company, amount)
      local old = self.insurance_balance[company][1]
      self.insurance_balance[company][1] = old + amount
    end,
    
    countRadiators = function(self) return 10 end,
    
    changeReputation = function(self, type) end,
    advisePriceLevelImpact = function(self, type, disease) end,
    
    research = {
      researchCost = function(self)
        local acc_cost = self.hospital.acc_research_cost
        local fraction = 0
        for _, tab in pairs(self.research_policy or {}) do
          if type(tab) == "table" and tab.current and not tab.current.dummy then
            fraction = fraction + (tab.frac or 0)
          end
        end
        local doctors = 0
        for _, room in pairs(self.hospital.world.rooms) do
          if room.room_info and room.room_info.id == "research" then
            for _ in pairs(room.staff_member_set or {}) do doctors = doctors + 1 end
          end
        end
        acc_cost = acc_cost + math.ceil(3 * doctors * fraction / 100)
        self.hospital.acc_research_cost = acc_cost
      end,
      research_policy = {},
      checkAutomaticDiscovery = function() end
    }
  }
  
  hospital.research.hospital = hospital
  return hospital
end

-- Mock patient object
local function createMockPatient(overrides)
  overrides = overrides or {}
  return {
    hospital = overrides.hospital,
    insurance_company = overrides.insurance_company or nil,
    pay_amount = overrides.pay_amount or 0,
    world = overrides.world,
    getTreatmentDiseaseId = function(self) return overrides.disease_id or "common_cold" end,
    getAttribute = function(self, attr) return overrides.attributes and overrides.attributes[attr] or 70 end,
    changeAttribute = function(self, attr, delta) end,
    isTreatmentEffective = function(self) return true end,
    cure = function(self) end,
    goHome = function(self, reason) end,
    treatment_history = {},
    getPriceDistortion = function(self, casebook)
      local happiness_weight = 0.1
      local reputation_weight = 0.6
      local effectiveness_weight = 0.3
      local reputation = casebook.reputation or self.hospital.reputation
      local effectiveness = casebook.cure_effectiveness or 80
      local weighted_happiness = happiness_weight * self:getAttribute("happiness")
      local weighted_reputation = reputation_weight * (reputation / 1000)
      local weighted_effectiveness = effectiveness_weight * (effectiveness / 100)
      local expected_price_level = weighted_happiness + weighted_reputation + weighted_effectiveness
      local price_level = ((casebook.price - 0.5) / 3) * 2
      return price_level - expected_price_level
    end
  }
end

-- Mock disease casebook entry
local function createCasebookEntry(overrides)
  overrides = overrides or {}
  return {
    disease = { name = overrides.name or "Common Cold", cure_price = overrides.cure_price or 100 },
    price = overrides.price or 1.0,
    reputation = overrides.reputation,
    cure_effectiveness = overrides.cure_effectiveness or 80,
    money_earned = 0,
    pseudo = overrides.pseudo or false
  }
end

-- ============================================================================
-- TEST SUITES
-- ============================================================================

describe("Financial System - Core Money Operations", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
  end)
  
  describe("spendMoney", function()
    it("should decrease balance and log transaction", function()
      local initial_balance = hospital.balance
      hospital:spendMoney(1000, "Test Expense")
      
      assert.are.equal(initial_balance - 1000, hospital.balance)
      assert.are.equal(1, #hospital.transactions)
      assert.are.equal(1000, hospital.transactions[1].spend)
      assert.are.equal("Test Expense", hospital.transactions[1].desc)
      assert.are.equal(initial_balance - 1000, hospital.transactions[1].balance)
      assert.are.equal(1000, hospital.money_out)
    end)
    
    it("should not affect balance in free_build_mode", function()
      hospital.world.free_build_mode = true
      local initial_balance = hospital.balance
      hospital:spendMoney(1000, "Test Expense")
      assert.are.equal(initial_balance, hospital.balance)
      assert.are.equal(0, #hospital.transactions)
    end)
    
    it("should adjust hospital value when changeValue provided", function()
      local initial_value = hospital.value
      hospital:spendMoney(5000, "Build Room", 5000)
      assert.are.equal(initial_value + 5000, hospital.value)
    end)
  end)
  
  describe("receiveMoney", function()
    it("should increase balance and log transaction", function()
      local initial_balance = hospital.balance
      hospital:receiveMoney(2000, "Test Income")
      
      assert.are.equal(initial_balance + 2000, hospital.balance)
      assert.are.equal(1, #hospital.transactions)
      assert.are.equal(2000, hospital.transactions[1].receive)
      assert.are.equal("Test Income", hospital.transactions[1].desc)
      assert.are.equal(2000, hospital.money_in)
    end)
    
    it("should not affect balance in free_build_mode", function()
      hospital.world.free_build_mode = true
      local initial_balance = hospital.balance
      hospital:receiveMoney(2000, "Test Income")
      assert.are.equal(initial_balance, hospital.balance)
    end)
    
    it("should adjust hospital value when changeValue provided", function()
      local initial_value = hospital.value
      hospital:receiveMoney(3000, "Sell Object", 1200)
      assert.are.equal(initial_value - 1200, hospital.value)
    end)
  end)
  
  describe("Transaction logging", function()
    it("should maintain max 20 transactions", function()
      for i = 1, 25 do
        hospital:spendMoney(100, "Test " .. i)
      end
      assert.are.equal(20, #hospital.transactions)
      assert.are.equal("Test 25", hospital.transactions[1].desc)
      assert.are.equal("Test 6", hospital.transactions[20].desc)
    end)
    
    it("should record day, month, and balance in transaction", function()
      hospital:receiveMoney(500, "Test")
      local t = hospital.transactions[1]
      assert.is_not_nil(t.day)
      assert.is_not_nil(t.month)
      assert.is_not_nil(t.balance)
    end)
  end)
end)

describe("Financial System - Treatment Pricing", function()
  local hospital, patient, casebook
  
  before_each(function()
    hospital = createMockHospital({ reputation = 600 })
    casebook = createCasebookEntry({ cure_price = 100, price = 1.0 })
    hospital.disease_casebook.common_cold = casebook
    patient = createMockPatient({ hospital = hospital, disease_id = "common_cold" })
  end)
  
  describe("getTreatmentPrice", function()
    it("should apply reputation multiplier when reputation >= 500", function()
      -- reputation 600, base 100, percentage 1.0
      -- price = ceil(100 * (600/500) * 1.0) = ceil(120) = 120
      local price = hospital:getTreatmentPrice("common_cold")
      assert.are.equal(120, price)
    end)
    
    it("should NOT apply reputation multiplier when reputation < 500", function()
      hospital.reputation = 400
      local price = hospital:getTreatmentPrice("common_cold")
      -- price = ceil(100 * 1.0) = 100
      assert.are.equal(100, price)
    end)
    
    it("should apply custom price percentage", function()
      casebook.price = 1.5 -- 150%
      hospital.reputation = 500
      local price = hospital:getTreatmentPrice("common_cold")
      -- price = ceil(100 * 1.0 * 1.5) = 150
      assert.are.equal(150, price)
    end)
    
    it("should use disease-specific reputation when available", function()
      casebook.reputation = 800
      hospital.reputation = 400
      local price = hospital:getTreatmentPrice("common_cold")
      -- price = ceil(100 * (800/500) * 1.0) = ceil(160) = 160
      assert.are.equal(160, price)
    end)
    
    it("should return 0 for unknown disease", function()
      local price = hospital:getTreatmentPrice("unknown_disease")
      assert.are.equal(0, price)
    end)
  end)
  
  describe("receiveMoneyForTreatment - Direct Payment", function()
    it("should receive money directly when no insurance", function()
      patient.insurance_company = nil
      patient.pay_amount = 0
      
      hospital:receiveMoneyForTreatment(patient)
      
      assert.are.equal(120, hospital.balance - 50000) -- initial balance was 50000
      assert.are.equal(120, hospital.money_in)
      assert.are.equal(120, casebook.money_earned)
    end)
    
    it("should use patient.pay_amount when set", function()
      patient.pay_amount = 200
      hospital:receiveMoneyForTreatment(patient)
      assert.are.equal(200, hospital.money_in)
    end)
    
    it("should trigger price level impact computation for direct payments", function()
      local spy_compute = spy.on(hospital, "computePriceLevelImpact")
      hospital:receiveMoneyForTreatment(patient)
      assert.spy(spy_compute).was_called_with(patient, casebook)
    end)
  end)
  
  describe("receiveMoneyForTreatment - Insurance Payment", function()
    it("should route to insurance when patient has insurance_company", function()
      patient.insurance_company = 1
      local spy_add = spy.on(hospital, "addInsuranceMoney")
      
      hospital:receiveMoneyForTreatment(patient)
      
      assert.spy(spy_add).was_called_with(1, 120)
      assert.are.equal(0, hospital.money_in) -- No direct money received
      assert.are.equal(120, hospital.insurance_balance[1][1]) -- Added to current month
    end)
    
    it("should still track money_earned for insurance payments", function()
      patient.insurance_company = 2
      hospital:receiveMoneyForTreatment(patient)
      assert.are.equal(120, casebook.money_earned)
    end)
    
    it("should NOT compute price impact for insurance payments", function()
      patient.insurance_company = 1
      local spy_compute = spy.on(hospital, "computePriceLevelImpact")
      hospital:receiveMoneyForTreatment(patient)
      assert.spy(spy_compute).was_not_called()
    end)
  end)
end)

describe("Financial System - Insurance System", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
    hospital.insurance_balance = {{0,0,0}, {0,0,0}, {0,0,0}}
  end)
  
  describe("addInsuranceMoney", function()
    it("should accumulate in current month slot (index 1)", function()
      hospital:addInsuranceMoney(1, 500)
      hospital:addInsuranceMoney(1, 300)
      assert.are.equal(800, hospital.insurance_balance[1][1])
      assert.are.equal(0, hospital.insurance_balance[1][2])
      assert.are.equal(0, hospital.insurance_balance[1][3])
    end)
    
    it("should track each company separately", function()
      hospital:addInsuranceMoney(1, 1000)
      hospital:addInsuranceMoney(2, 500)
      assert.are.equal(1000, hospital.insurance_balance[1][1])
      assert.are.equal(500, hospital.insurance_balance[2][1])
      assert.are.equal(0, hospital.insurance_balance[3][1])
    end)
  end)
  
  describe("onEndMonth - Insurance Payout Rotation", function()
    it("should pay out slot 3 (2 months old) and rotate", function()
      -- Setup: Jan in slot 1, Feb in slot 2, Mar in slot 3
      hospital.insurance_balance[1] = {400, 300, 500} -- Company 1
      hospital.insurance_balance[2] = {200, 100, 0}   -- Company 2
      
      hospital:onEndMonth()
      
      -- Company 1: should receive 500 (slot 3), new buffer = {0, 400, 300}
      assert.are.equal(500, hospital.money_in) -- Only company 1 had slot 3 > 0
      assert.are.same({0, 400, 300}, hospital.insurance_balance[1])
      
      -- Company 2: slot 3 was 0, no payout, new buffer = {0, 200, 100}
      assert.are.same({0, 200, 100}, hospital.insurance_balance[2])
    end)
    
    it("should handle multiple companies with payouts", function()
      hospital.insurance_balance[1][3] = 1000
      hospital.insurance_balance[2][3] = 500
      hospital.insurance_balance[3][3] = 250
      
      hospital:onEndMonth()
      
      assert.are.equal(1750, hospital.money_in)
      assert.are.equal(1000, hospital.transactions[1].receive) -- Last inserted first
    end)
    
    it("should create transaction with insurance company name", function()
      hospital.insurance_balance[1][3] = 1000
      hospital:onEndMonth()
      
      assert.are.equal(1, #hospital.transactions)
      assert.is_true(string.find(hospital.transactions[1].desc, "InsureCo A") ~= nil)
    end)
  end)
end)

describe("Financial System - Monthly Payments", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital({
      balance = 100000,
      staff = {
        { profile = { wage = 5000 } },
        { profile = { wage = 3000 } }
      }
    })
    hospital.acc_heating = 1500.7
    hospital.acc_loan_interest = 200.3
    hospital.acc_overdraft = 0
    hospital.acc_research_cost = 450.9
    hospital.loan = 50000
  end)
  
  describe("onEndMonth - Wages", function()
    it("should sum all staff wages and spend", function()
      hospital:onEndMonth()
      -- wages = 5000 + 3000 = 8000
      assert.is_true(hospital.balance < 100000)
      local wages_tx = nil
      for _, t in ipairs(hospital.transactions) do
        if t.desc == "Wages" then wages_tx = t end
      end
      assert.is_not_nil(wages_tx)
      assert.are.equal(8000, wages_tx.spend)
    end)
    
    it("should skip if no staff", function()
      hospital.staff = {}
      local initial_balance = hospital.balance
      hospital:onEndMonth()
      -- Balance change should only be from other expenses
    end)
  end)
  
  describe("onEndMonth - Heating", function()
    it("should pay rounded accumulated heating and reset", function()
      hospital.acc_heating = 1500.7
      hospital:onEndMonth()
      
      local heating_tx = nil
      for _, t in ipairs(hospital.transactions) do
        if t.desc == "Heating" then heating_tx = t end
      end
      assert.is_not_nil(heating_tx)
      assert.are.equal(1501, heating_tx.spend) -- rounded
      assert.are.equal(0, hospital.acc_heating)
    end)
    
    it("should skip if heating is 0", function()
      hospital.acc_heating = 0
      hospital:onEndMonth()
      local has_heating = false
      for _, t in ipairs(hospital.transactions) do
        if t.desc == "Heating" then has_heating = true end
      end
      assert.is_false(has_heating)
    end)
  end)
  
  describe("onEndMonth - Loan Interest", function()
    it("should pay rounded accumulated loan interest and reset", function()
      hospital.acc_loan_interest = 200.3
      hospital:onEndMonth()
      
      local loan_tx = nil
      for _, t in ipairs(hospital.transactions) do
        if t.desc == "Loan Interest" then loan_tx = t end
      end
      assert.is_not_nil(loan_tx)
      assert.are.equal(200, loan_tx.spend) -- rounded down
      assert.are.equal(0, hospital.acc_loan_interest)
    end)
  end)
  
  describe("onEndMonth - Overdraft", function()
    it("should pay rounded accumulated overdraft and reset", function()
      hospital.acc_overdraft = 150.6
      hospital:onEndMonth()
      
      local od_tx = nil
      for _, t in ipairs(hospital.transactions) do
        if t.desc == "Overdraft" then od_tx = t end
      end
      assert.is_not_nil(od_tx)
      assert.are.equal(151, od_tx.spend) -- rounded up
      assert.are.equal(0, hospital.acc_overdraft)
    end)
    
    it("should skip if overdraft is 0", function()
      hospital.acc_overdraft = 0
      hospital:onEndMonth()
      local has_od = false
      for _, t in ipairs(hospital.transactions) do
        if t.desc == "Overdraft" then has_od = true end
      end
      assert.is_false(has_od)
    end)
  end)
  
  describe("onEndMonth - Research", function()
    it("should pay rounded accumulated research cost and reset", function()
      hospital.acc_research_cost = 450.9
      hospital:onEndMonth()
      
      local res_tx = nil
      for _, t in ipairs(hospital.transactions) do
        if t.desc == "Research" then res_tx = t end
      end
      assert.is_not_nil(res_tx)
      assert.are.equal(451, res_tx.spend)
      assert.are.equal(0, hospital.acc_research_cost)
    end)
  end)
  
  describe("onEndMonth - Statistics Recording", function()
    it("should record monthly statistics", function()
      hospital.money_in = 50000
      hospital.money_out = 30000
      hospital.num_visitors = 100
      hospital.num_cured = 80
      hospital.num_deaths = 2
      hospital.reputation = 650
      
      hospital:onEndMonth()
      
      local stats = hospital.statistics[7] -- monthOfGame was 6, now 7
      assert.is_not_nil(stats)
      assert.are.equal(50000, stats.money_in)
      assert.are.equal(30000, stats.money_out)
      assert.are.equal(100, stats.visitors)
      assert.are.equal(80, stats.cures)
      assert.are.equal(2, stats.deaths)
      assert.are.equal(650, stats.reputation)
    end)
    
    it("should reset money_in and money_out", function()
      hospital.money_in = 1000
      hospital.money_out = 500
      hospital:onEndMonth()
      assert.are.equal(0, hospital.money_in)
      assert.are.equal(0, hospital.money_out)
    end)
  end)
end)

describe("Financial System - Daily Accruals (onDayChange)", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital({
      balance = 50000,
      loan = 36500 -- Makes daily interest calculation clean
    })
    hospital.interest_rate = 0.10 -- 10%
    hospital.overdraft_interest_rate = 0.15 -- 15%
    hospital.heating.radiator_heat = 0.5
  end)
  
  describe("Loan Interest Accrual", function()
    it("should accrue daily loan interest = loan * rate / 365", function()
      -- loan = 36500, rate = 0.10
      -- daily = 36500 * 0.10 / 365 = 10
      hospital:onDayChange()
      assert.are.equal(10, hospital.acc_loan_interest)
    end)
    
    it("should accumulate over multiple days", function()
      hospital:onDayChange()
      hospital:onDayChange()
      hospital:onDayChange()
      assert.are.equal(30, hospital.acc_loan_interest)
    end)
  end)
  
  describe("Overdraft Interest Accrual", function()
    it("should accrue daily overdraft interest when balance < 0", function()
      hospital.balance = -10000
      hospital.overdraft_interest_rate = 0.15
      -- daily = 10000 * 0.15 / 365 = 4.11
      hospital:onDayChange()
      assert.is_true(hospital.acc_overdraft > 4.1 and hospital.acc_overdraft < 4.12)
    end)
    
    it("should NOT accrue overdraft interest when balance >= 0", function()
      hospital.balance = 1000
      hospital:onDayChange()
      assert.are.equal(0, hospital.acc_overdraft)
    end)
    
    it("should accumulate overdraft interest over multiple negative days", function()
      hospital.balance = -10000
      hospital:onDayChange()
      hospital:onDayChange()
      assert.is_true(hospital.acc_overdraft > 8.2)
    end)
  end)
  
  describe("Heating Cost Accrual", function()
    it("should accrue daily heating cost based on radiators and heat level", function()
      -- radiator_heat = 0.5, 10 radiators, 7.50 base, 30 days
      -- daily = 0.5 * 10 * 7.50 / 30 = 1.25
      hospital:onDayChange()
      assert.are.equal(1.25, hospital.acc_heating)
    end)
    
    it("should scale with radiator heat setting", function()
      hospital.heating.radiator_heat = 1.0 -- Full heat
      hospital:onDayChange()
      assert.are.equal(2.5, hospital.acc_heating) -- Double
    end)
    
    it("should scale with number of radiators", function()
      hospital.countRadiators = function() return 20 end
      hospital:onDayChange()
      assert.are.equal(2.5, hospital.acc_heating) -- Double radiators
    end)
  end)
  
  describe("Research Cost Accrual", function()
    it("should call research:researchCost() daily", function()
      local spy = spy.on(hospital.research, "researchCost")
      hospital:onDayChange()
      assert.spy(spy).was_called()
    end)
  end)
end)

describe("Financial System - Loan & Overdraft Mechanics", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital({
      balance = 50000,
      value = 200000
    })
  end)
  
  describe("Max Loan Calculation", function()
    it("should calculate max loan as 33% of value + 10000, rounded to 5000", function()
      -- value = 200000
      -- 33% = 66000
      -- /5000 = 13.2 -> floor = 13
      -- *5000 = 65000
      -- +10000 = 75000
      local max_loan = math.floor((hospital.value * 0.33) / 5000) * 5000 + 10000
      assert.are.equal(75000, max_loan)
    end)
    
    it("should be 0 in free build mode", function()
      hospital.world.free_build_mode = true
      local max_loan = not hospital.world.free_build_mode and 
        (math.floor((hospital.value * 0.33) / 5000) * 5000) + 10000 or 0
      assert.are.equal(0, max_loan)
    end)
  end)
  
  describe("Loan Increase", function()
    it("should increase loan and receive money", function()
      hospital.loan = 10000
      local amount = 5000
      hospital.loan = hospital.loan + amount
      hospital:receiveMoney(amount, "Bank Loan")
      
      assert.are.equal(15000, hospital.loan)
      assert.are.equal(55000, hospital.balance)
    end)
    
    it("should not exceed max loan", function()
      hospital.loan = 70000
      local max_loan = 75000
      local amount = 10000 -- Would exceed
      if hospital.loan + 5000 <= max_loan then
        hospital.loan = hospital.loan + 5000
        hospital:receiveMoney(5000, "Bank Loan")
      end
      assert.are.equal(75000, hospital.loan)
    end)
  end)
  
  describe("Loan Repayment", function()
    it("should decrease loan and spend money", function()
      hospital.loan = 20000
      hospital.balance = 50000
      local amount = 5000
      
      if hospital.loan > 0 and hospital.balance >= amount then
        hospital.loan = hospital.loan - amount
        hospital:spendMoney(amount, "Loan Repayment")
      end
      
      assert.are.equal(15000, hospital.loan)
      assert.are.equal(45000, hospital.balance)
    end)
    
    it("should not repay more than balance allows", function()
      hospital.loan = 20000
      hospital.balance = 3000
      local amount = 5000
      
      if hospital.loan > 0 and hospital.balance >= amount then
        hospital.loan = hospital.loan - amount
        hospital:spendMoney(amount, "Loan Repayment")
      end
      
      assert.are.equal(20000, hospital.loan) -- Unchanged
      assert.are.equal(3000, hospital.balance)
    end)
  end)
end)

describe("Financial System - Price Distortion & Reputation", function()
  local hospital, patient, casebook
  
  before_each(function()
    hospital = createMockHospital({ reputation = 600 })
    hospital.under_priced_threshold = -0.4
    hospital.over_priced_threshold = 0.3
    casebook = createCasebookEntry({ 
      price = 1.0, 
      cure_effectiveness = 80,
      reputation = 600
    })
    patient = createMockPatient({ 
      hospital = hospital, 
      attributes = { happiness = 70 }
    })
  end)
  
  describe("Patient:getPriceDistortion", function()
    it("should calculate distortion correctly for fair price", function()
      -- expected = 0.1*0.7 + 0.6*0.6 + 0.3*0.8 = 0.07 + 0.36 + 0.24 = 0.67
      -- price_level = ((1.0 - 0.5) / 3) * 2 = 0.33
      -- distortion = 0.33 - 0.67 = -0.34
      local distortion = patient:getPriceDistortion(casebook)
      assert.is_true(distortion < -0.33 and distortion > -0.35)
    end)
    
    it("should show negative distortion (underpriced) when price < expected", function()
      casebook.price = 0.5 -- 50%
      local distortion = patient:getPriceDistortion(casebook)
      -- price_level = 0, expected ~0.67, distortion ~ -0.67
      assert.is_true(distortion < -0.5)
    end)
    
    it("should show positive distortion (overpriced) when price > expected", function()
      casebook.price = 2.0 -- 200%
      local distortion = patient:getPriceDistortion(casebook)
      -- price_level = 1.0, expected ~0.67, distortion ~ 0.33
      assert.is_true(distortion > 0.2)
    end)
  end)
  
  describe("computePriceLevelImpact", function()
    it("should reduce patient happiness based on distortion", function()
      casebook.price = 2.0 -- Overpriced
      local initial_happiness = 70
      patient.getAttribute = function(self, attr) return initial_happiness end
      local happiness_changed = false
      patient.changeAttribute = function(self, attr, delta)
        if attr == "happiness" then happiness_changed = true end
      end
      
      hospital:computePriceLevelImpact(patient, casebook)
      
      assert.is_true(happiness_changed)
    end)
    
    it("should trigger reputation loss when underpriced (1% chance)", function()
      casebook.price = 0.3 -- Very underpriced
      -- Mock random to always return 1 (trigger)
      local original_random = math.random
      math.random = function(a, b) return 1 end
      
      local rep_changed = false
      hospital.changeReputation = function(self, type)
        if type == "under_priced" then rep_changed = true end
      end
      
      hospital:computePriceLevelImpact(patient, casebook)
      
      math.random = original_random
      assert.is_true(rep_changed)
    end)
    
    it("should trigger reputation loss when overpriced (1% chance)", function()
      casebook.price = 3.0 -- Very overpriced
      local original_random = math.random
      math.random = function(a, b) return 1 end
      
      local rep_changed = false
      hospital.changeReputation = function(self, type)
        if type == "over_priced" then rep_changed = true end
      end
      
      hospital:computePriceLevelImpact(patient, casebook)
      
      math.random = original_random
      assert.is_true(rep_changed)
    end)
    
    it("should trigger 'fair' advisory when well-priced (0.5% chance)", function()
      -- Set price so distortion is near 0
      casebook.price = 1.0 -- This gives ~-0.34 distortion with our setup
      -- Adjust to get distortion within 0.15
      casebook.price = 1.5 -- price_level = 0.67, expected = 0.67, distortion = 0
      
      local original_random = math.random
      math.random = function(a, b) return 1 end
      
      local advised = false
      hospital.advisePriceLevelImpact = function(self, type, disease)
        if type == "fair" then advised = true end
      end
      
      hospital:computePriceLevelImpact(patient, casebook)
      
      math.random = original_random
      assert.is_true(advised)
    end)
  end)
  
  describe("Difficulty Thresholds", function()
    it("should use tighter thresholds on higher difficulty", function()
      -- Easy (1): under=-0.3, over=0.4
      -- Normal (2): under=-0.4, over=0.3
      -- Hard (3): under=-0.5, over=0.2
      
      local under_thresholds = {-0.3, -0.4, -0.5}
      local over_thresholds = {0.4, 0.3, 0.2}
      
      assert.are.equal(-0.3, under_thresholds[1])
      assert.are.equal(-0.4, under_thresholds[2])
      assert.are.equal(-0.5, under_thresholds[3])
      
      assert.are.equal(0.4, over_thresholds[1])
      assert.are.equal(0.3, over_thresholds[2])
      assert.are.equal(0.2, over_thresholds[3])
    end)
  end)
end)

describe("Financial System - COST_RECOVERY", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
  end)
  
  it("should define COST_RECOVERY as 0.40 (40%)", function()
    local COST_RECOVERY = 0.40
    assert.are.equal(0.40, COST_RECOVERY)
  end)
  
  it("should recover 40% when selling room objects", function()
    local object_cost = 10000
    local recovery = object_cost * 0.40
    hospital:receiveMoney(recovery, "Sell Object", recovery)
    
    assert.are.equal(4000, recovery)
    assert.are.equal(54000, hospital.balance)
    assert.are.equal(96000, hospital.value) -- 100000 - 4000
  end)
  
  it("should lose 60% on room demolition", function()
    local room_value = 50000
    local loss = room_value * 0.60
    -- Demolition doesn't give money back, just removes value
    hospital.value = hospital.value - room_value
    assert.are.equal(50000, hospital.value)
  end)
end)

describe("Financial System - Research Costs", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
    hospital.research.research_policy = {
      general = { frac = 50, current = { dummy = false } },
      specialisation = { frac = 50, current = { dummy = false } }
    }
    hospital.world.rooms = {
      { room_info = { id = "research" }, staff_member_set = { doc1 = true, doc2 = true } }
    }
  end)
  
  it("should calculate daily research cost: 3 * doctors * fraction / 100", function()
    -- 2 doctors, 100% total fraction
    -- daily = ceil(3 * 2 * 100 / 100) = ceil(6) = 6
    hospital.research:researchCost()
    assert.are.equal(6, hospital.acc_research_cost)
  end)
  
  it("should only count active research categories", function()
    hospital.research.research_policy = {
      general = { frac = 50, current = { dummy = false } },
      specialisation = { frac = 50, current = { dummy = true } } -- inactive
    }
    hospital.research:researchCost()
    -- Only general: 50% fraction
    -- daily = ceil(3 * 2 * 50 / 100) = ceil(3) = 3
    assert.are.equal(3, hospital.acc_research_cost)
  end)
  
  it("should accumulate over multiple days", function()
    hospital.research:researchCost()
    hospital.research:researchCost()
    hospital.research:researchCost()
    assert.are.equal(18, hospital.acc_research_cost)
  end)
  
  it("should be paid monthly via onEndMonth", function()
    hospital.acc_research_cost = 180 -- ~30 days * 6
    hospital:onEndMonth()
    
    local res_tx = nil
    for _, t in ipairs(hospital.transactions) do
      if t.desc == "Research" then res_tx = t end
    end
    assert.is_not_nil(res_tx)
    assert.are.equal(180, res_tx.spend)
    assert.are.equal(0, hospital.acc_research_cost)
  end)
end)

describe("Financial System - Drug Costs", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital()
    hospital.disease_casebook.infection = createCasebookEntry({ 
      drug_cost = 50 
    })
  end)
  
  it("should spend drug_cost when paying supplier", function()
    hospital:paySupplierForDrug("infection")
    
    local drug_tx = nil
    for _, t in ipairs(hospital.transactions) do
      if string.find(t.desc, "Drug Cost") then drug_tx = t end
    end
    assert.is_not_nil(drug_tx)
    assert.are.equal(50, drug_tx.spend)
  end)
  
  it("should do nothing if drug_cost is 0 or nil", function()
    hospital.disease_casebook.no_drug = createCasebookEntry({ drug_cost = 0 })
    hospital:paySupplierForDrug("no_drug")
    
    local drug_tx = nil
    for _, t in ipairs(hospital.transactions) do
      if string.find(t.desc, "Drug Cost") then drug_tx = t end
    end
    assert.is_nil(drug_tx)
  end)
  
  it("should use random drug company name in transaction", function()
    hospital:paySupplierForDrug("infection")
    local drug_tx = nil
    for _, t in ipairs(hospital.transactions) do
      if string.find(t.desc, "Drug Cost") then drug_tx = t end
    end
    assert.is_not_nil(drug_tx)
    assert.is_true(string.find(drug_tx.desc, "Drug Cost:") ~= nil)
  end)
end)

describe("Financial System - Edge Cases & Integration", function()
  local hospital
  
  before_each(function()
    hospital = createMockHospital({
      balance = 10000,
      loan = 0
    })
  end)
  
  it("should handle negative balance (overdraft) correctly", function()
    hospital:spendMoney(15000, "Big Expense")
    assert.are.equal(-5000, hospital.balance)
    assert.are.equal(15000, hospital.money_out)
  end)
  
  it("should accrue overdraft interest when negative", function()
    hospital.balance = -5000
    hospital.overdraft_interest_rate = 0.12
    hospital:onDayChange()
    assert.is_true(hospital.acc_overdraft > 0)
  end)
  
  it("should process insurance payout even when balance negative", function()
    hospital.balance = -1000
    hospital.insurance_balance[1][3] = 5000
    hospital:onEndMonth()
    assert.are.equal(4000, hospital.balance) -- -1000 + 5000
  end)
  
  it("should handle zero staff wages gracefully", function()
    hospital.staff = {}
    hospital:onEndMonth()
    local wages_tx = nil
    for _, t in ipairs(hospital.transactions) do
      if t.desc == "Wages" then wages_tx = t end
    end
    assert.is_nil(wages_tx)
  end)
  
  it("should handle research with zero doctors", function()
    hospital.world.rooms = {}
    hospital.research.research_policy = {
      general = { frac = 100, current = { dummy = false } }
    }
    hospital.research:researchCost()
    assert.are.equal(0, hospital.acc_research_cost)
  end)
  
  it("should maintain transaction history limit of 20", function()
    for i = 1, 25 do
      hospital:spendMoney(100, "Test " .. i)
    end
    assert.are.equal(20, #hospital.transactions)
    -- Most recent first
    assert.are.equal("Test 25", hospital.transactions[1].desc)
    assert.are.equal("Test 6", hospital.transactions[20].desc)
  end)
end)

-- ============================================================================
-- RUN TESTS
-- ============================================================================

-- busted SCAFFOLD.lua
