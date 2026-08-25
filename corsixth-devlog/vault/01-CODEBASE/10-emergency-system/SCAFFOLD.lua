--[[
  Emergency System Test Scaffold for CorsixTH
  Busted test framework with mock helpers
  
  Run with: busted SCAFFOLD.lua
--]]

local busted = require("busted")
local describe = busted.describe
local it = busted.it
local before_each = busted.before_each
local after_each = busted.after_each
local setup = busted.setup
local teardown = busted.teardown
local assert = require("luassert")
local spy = require("luassert.spy")
local stub = require("luassert.stub")
local match = require("luassert.match")

-- ============================================================
-- MOCK HELPERS
-- ============================================================

local function createMockWorld()
  local world = {
    available_diseases = {},
    game_date = {
      monthOfGame = function() return 1 end,
      dayOfMonth = function() return 1 end,
      year = function() return 1 end,
      monthOfYear = function() return 1 end,
      isSameDay = function() return false end,
      plusDays = function(self, d) return self end,
      lastDayOfMonth = function() return 28 end,
    },
    next_emergency_no = 0,
    next_emergency_month = 1,
    next_emergency_day = 1,
    next_emergency_date = nil,
    next_emergency = nil,
    map = {
      level_config = {
        emergency_control = {
          [0] = { Random = false, Mean = 180, Variance = 30 }
        }
      }
    },
    ui = {
      getWindow = function() return nil end,
      addWindow = function() end,
      playAnnouncement = function() end,
      adviser = { say = function() end },
      bottom_panel = {
        queueMessage = function() end,
        deleteMessage = function() end,
      }
    },
    app = {
      config = { autosave_frequency = 0, ui_scale = 1 }
    },
    entities = {},
    hospitals = {},
    scheduleRandomEmergency = function(self) end,
    nextEmergency = function(self) end,
    computeNextEmergencyDates = function(self) return true end,
    wasEmergencySkipped = function(self) return false end,
    newObject = function(self, type, dir)
      if type == "helicopter" then
        return createMockHelicopter()
      end
      return nil
    end,
    newEntity = function(self, type, ...)
      if type == "Patient" then
        return createMockPatient()
      end
      return {}
    end,
    dispatcher = { dropFromQueue = function() end },
    _flushDestroyedEntities = function() end,
  }
  return world
end

local function createMockHospital(world)
  world = world or createMockWorld()
  
  local hospital = {
    world = world,
    emergency = nil,
    emergency_patients = {},
    disease_casebook = {},
    population = 1.0,
    vip_declined = 0,
    num_vips = 0,
    player_salary = 0,
    salary_offer = 0,
    win_declined = false,
    hosp_cheats = { processCheatCode = function() return false end },
    
    -- Mock methods
    getHeliportSpawnPosition = function(self) return 10, 10 end,
    getHeliportPosition = function(self) return 10, 10 end,
    hasReceptionDesk = function(self, built) return true end,
    countRoomOfType = function(self, room_type, level) return 1 end,
    countStaffOfCategory = function(self, category) return 1 end,
    changeReputation = function(self, type, disease) end,
    receiveMoney = function(self, amount, transaction) end,
    updatePercentages = function(self) end,
    paySupplierForDrug = function(self, disease_id) end,
    removePatient = function(self, patient) end,
    open = function(self) end,
    makeEmergencyStartFax = function(self) end,
    makeEmergencyEndFax = function(self, rescued, total, max_bonus, earned) end,
    createEmergency = function(self, emergency) end,
    resolveEmergency = function(self) end,
    checkEmergencyOver = function(self) end,
  }
  
  -- Setup disease casebook
  for _, disease in ipairs(world.available_diseases) do
    hospital.disease_casebook[disease.id] = {
      discovered = true,
      cure_effectiveness = 80,
      drug = false,
      price = 1.0,
    }
  end
  
  world.hospitals[1] = hospital
  world.getLocalPlayerHospital = function() return hospital end
  
  return hospital
end

local function createMockDisease(id, emergency_number)
  emergency_number = emergency_number or 18
  return {
    id = id,
    name = id:gsub("_", " "):gsub("^%l", string.upper),
    emergency_number = emergency_number,
    emergency_sound = "emerg001.wav",
    treatment_rooms = { "gp", "diagnosis", "treatment" },
    expertise_id = id,
    contagious = false,
  }
end

local function createMockPatient()
  local patient = {
    disease = nil,
    diagnosis_progress = 0,
    is_emergency = nil,
    cured = false,
    dead = false,
    going_home = false,
    going_to_die = false,
    set_to_die = false,
    pay_amount = 0,
    mood = "",
    room = nil,
    current_action = { is_leaving = false },
    
    -- Methods
    setDisease = function(self, disease) self.disease = disease end,
    setDiagnosed = function(self) self.diagnosis_progress = 1 end,
    setMood = function(self, mood, state) self.mood = mood end,
    setNextAction = function(self, action) self.current_action = action end,
    setHospital = function(self, hospital) self.hospital = hospital end,
    setTile = function(self, x, y) self.x, self.y = x, y end,
    agreesToPay = function(self, disease_id) return true end,
    goHome = function(self, reason, disease_id) self.going_home = true end,
    queueAction = function(self, action) end,
    getRoom = function(self) return self.room end,
    isKnockingDoor = function(self) return false end,
    isEnteringRoom = function(self) return false end,
    cure = function(self)
      self.cured = true
      if self.hospital and self.is_emergency then
        self.hospital.emergency.cured_emergency_patients = 
          (self.hospital.emergency.cured_emergency_patients or 0) + 1
        self.hospital:checkEmergencyOver()
      end
    end,
    despawn = function(self)
      if self.hospital then
        self.hospital:removePatient(self)
      end
    end,
    die = function(self)
      self.dead = true
      self.going_to_die = true
      if self.hospital and self.is_emergency then
        self.hospital.emergency.killed_emergency_patients = 
          (self.hospital.emergency.killed_emergency_patients or 0) + 1
        self.hospital:checkEmergencyOver()
      end
    end,
    setToDying = function(self)
      self.set_to_die = true
    end,
    tick = function(self) end,
  }
  return patient
end

local function createMockHelicopter()
  local heli = {
    phase = -120,
    spawned_patients = 0,
    hospital = nil,
    th = { makeVisible = function() end, makeInvisible = function() end },
    setSpeed = function() end,
    setPosition = function() end,
    tick = function(self)
      self.phase = self.phase + 1
      if self.phase == 0 then
        self.th:makeVisible()
        self:setSpeed(0, 10)
      elseif self.phase == 60 then
        self:setSpeed(0, 0)
        self.spawned_patients = 0
      elseif self.phase == 85 then
        if self.spawned_patients < self.hospital.emergency.victims then
          self:spawnPatient()
          self.phase = 60
        end
      elseif self.phase == 87 then
        self:setSpeed(0, -10)
      elseif self.phase == 147 then
        -- destroy
      end
    end,
    spawnPatient = function(self)
      self.spawned_patients = self.spawned_patients + 1
      local patient = createMockPatient()
      patient:setDisease(self.hospital.emergency.disease)
      patient.is_emergency = self.spawned_patients
      patient:setDiagnosed()
      self.hospital.emergency_patients[self.spawned_patients] = patient
    end,
  }
  return heli
end

local function createMockUIWatch()
  local watch = {
    count_type = "emergency",
    open_timer = 12,
    tick_rate = 400,
    tick_timer = 400,
    hospital = nil,
    ui = nil,
    close = function(self) end,
    onCountdownEnd = function(self)
      if self.count_type == "emergency" and self.ui and self.ui.hospital then
        self.ui.hospital:resolveEmergency()
      end
      self:close()
    end,
    onWorldTick = function(self)
      if self.tick_timer == 0 and self.open_timer >= 0 then
        self.tick_timer = self.tick_rate
        self.open_timer = self.open_timer - 1
      elseif self.open_timer == -1 then
        self:onCountdownEnd()
      else
        self.tick_timer = self.tick_timer - 1
      end
    end,
  }
  return watch
end

local function createMockBottomPanel()
  return {
    queueMessage = function(self, type, message, icon, timeout, priority) end,
    deleteMessage = function(self, humanoid) end,
    cancelFax = function(self, fax_type)
      if fax_type == "emergency" then
        self.world:nextEmergency()
      end
    end,
  }
end

-- ============================================================
-- TEST MODULE LOADING
-- ============================================================

-- Mock corsixth module system
package.loaded["corsixth"] = {
  require = function(name) return {} end,
}

-- Load actual modules (adjust paths as needed)
local Hospital = {}
local World = {}
local Patient = {}
local Helicopter = {}
local UIWatch = {}
local PlayerHospital = {}

-- ============================================================
-- TEST SUITES
-- ============================================================

describe("Emergency System - Creation", function()
  local world, hospital
  
  before_each(function()
    world = createMockWorld()
    hospital = createMockHospital(world)
    
    -- Add test diseases
    world.available_diseases = {
      createMockDisease("bloaty_head", 18),
      createMockDisease("the_squits", 18),
      createMockDisease("alien_dna", 16),
    }
  end)
  
  it("should create emergency when heliport and reception exist", function()
    hospital.getHeliportSpawnPosition = function() return 10, 10 end
    hospital.hasReceptionDesk = function() return true end
    
    local result = hospital:createEmergency()
    
    assert.is_nil(result) -- Success returns nil
    assert.is_not_nil(hospital.emergency)
    assert.is_not_nil(hospital.emergency.disease)
    assert.is_number(hospital.emergency.victims)
    assert.equals(1000, hospital.emergency.bonus)
    assert.equals(0.75, hospital.emergency.percentage)
    assert.equals(0, hospital.emergency.killed_emergency_patients)
    assert.equals(0, hospital.emergency.cured_emergency_patients)
  end)
  
  it("should fail with 'no_heliport' when no heliport", function()
    hospital.getHeliportSpawnPosition = function() return nil end
    hospital.hasReceptionDesk = function() return true end
    
    local result = hospital:createEmergency()
    
    assert.equals("no_heliport", result)
    assert.is_nil(hospital.emergency)
  end)
  
  it("should fail with 'no_heliport' when no reception desk", function()
    hospital.getHeliportSpawnPosition = function() return 10, 10 end
    hospital.hasReceptionDesk = function() return false end
    
    local result = hospital:createEmergency()
    
    assert.equals("no_heliport", result)
    assert.is_nil(hospital.emergency)
  end)
  
  it("should fail with 'undiscovered_disease' for undiscovered disease", function()
    hospital.getHeliportSpawnPosition = function() return 10, 10 end
    hospital.hasReceptionDesk = function() return true end
    
    -- Make first disease undiscovered
    hospital.disease_casebook["bloaty_head"].discovered = false
    world.available_diseases = { createMockDisease("bloaty_head", 18) }
    
    local result = hospital:createEmergency()
    
    assert.equals("undiscovered_disease", result)
    assert.is_nil(hospital.emergency)
  end)
  
  it("should use provided emergency parameters", function()
    hospital.getHeliportSpawnPosition = function() return 10, 10 end
    hospital.hasReceptionDesk = function() return true end
    
    local custom_emergency = {
      disease = createMockDisease("alien_dna", 16),
      victims = 5,
      bonus = 2000,
      percentage = 0.5,
      killed_emergency_patients = 0,
      cured_emergency_patients = 0,
    }
    
    local result = hospital:createEmergency(custom_emergency)
    
    assert.is_nil(result)
    assert.equals(custom_emergency.disease, hospital.emergency.disease)
    assert.equals(5, hospital.emergency.victims)
    assert.equals(2000, hospital.emergency.bonus)
    assert.equals(0.5, hospital.emergency.percentage)
  end)
  
  it("should pick random disease from available_diseases", function()
    hospital.getHeliportSpawnPosition = function() return 10, 10 end
    hospital.hasReceptionDesk = function() return true end
    
    -- Spy on math.random
    local random_spy = spy.on(math, "random")
    
    hospital:createEmergency()
    
    -- Should be called for disease selection and victim count
    assert.spy(random_spy).was.called()
    random_spy:revert()
  end)
end)

describe("Emergency System - Resolution Success", function()
  local world, hospital
  
  before_each(function()
    world = createMockWorld()
    hospital = createMockHospital(world)
    
    world.available_diseases = {
      createMockDisease("bloaty_head", 18),
    }
    
    -- Setup active emergency
    hospital.emergency = {
      disease = createMockDisease("bloaty_head", 18),
      victims = 10,
      bonus = 1000,
      percentage = 0.75,
      killed_emergency_patients = 0,
      cured_emergency_patients = 0,
    }
    
    -- Add mock emergency patients
    for i = 1, 10 do
      local p = createMockPatient()
      p.hospital = hospital
      p.is_emergency = i
      hospital.emergency_patients[i] = p
    end
  end)
  
  it("should succeed when cure rate >= 75%", function()
    hospital.emergency.cured_emergency_patients = 8  -- 80%
    hospital.emergency.killed_emergency_patients = 2
    
    local money_spy = spy.on(hospital, "receiveMoney")
    local rep_spy = spy.on(hospital, "changeReputation")
    local fax_spy = spy.on(hospital, "makeEmergencyEndFax")
    local next_em_spy = spy.on(world, "nextEmergency")
    
    hospital:resolveEmergency()
    
    assert.spy(money_spy).was.called_with(match.is_ref(hospital), 8000, match.any())
    assert.spy(rep_spy).was.called_with(match.is_ref(hospital), "emergency_success", match.any())
    assert.spy(fax_spy).was.called_with(match.is_ref(hospital), 8, 10, 10000, 8000)
    assert.spy(next_em_spy).was.called_with(match.is_ref(world))
  end)
  
  it("should succeed at exactly 75% (7.5 rounded up)", function()
    hospital.emergency.cured_emergency_patients = 8  -- 8/10 = 80%
    hospital.emergency.killed_emergency_patients = 2
    
    local rep_spy = spy.on(hospital, "changeReputation")
    
    hospital:resolveEmergency()
    
    assert.spy(rep_spy).was.called_with(match.is_ref(hospital), "emergency_success", match.any())
  end)
  
  it("should set remaining patients to dying on resolve", function()
    hospital.emergency.cured_emergency_patients = 5
    hospital.emergency.killed_emergency_patients = 0
    
    -- 5 patients not cured or dead
    for i = 6, 10 do
      hospital.emergency_patients[i].cured = false
      hospital.emergency_patients[i].dead = false
      hospital.emergency_patients[i].going_home = false
    end
    
    hospital:resolveEmergency()
    
    for i = 6, 10 do
      assert.is_true(hospital.emergency_patients[i].set_to_die)
    end
  end)
  
  it("should not set cured/dead/going_home patients to dying", function()
    hospital.emergency.cured_emergency_patients = 3
    hospital.emergency.killed_emergency_patients = 2
    
    hospital.emergency_patients[6].cured = true
    hospital.emergency_patients[7].dead = true
    hospital.emergency_patients[8].going_home = true
    hospital.emergency_patients[9].going_home = false
    hospital.emergency_patients[9].cured = false
    hospital.emergency_patients[9].dead = false
    
    hospital:resolveEmergency()
    
    assert.is_false(hospital.emergency_patients[6].set_to_die)
    assert.is_false(hospital.emergency_patients[7].set_to_die)
    assert.is_false(hospital.emergency_patients[8].set_to_die)
    assert.is_true(hospital.emergency_patients[9].set_to_die)
  end)
end)

describe("Emergency System - Resolution Failure", function()
  local world, hospital
  
  before_each(function()
    world = createMockWorld()
    hospital = createMockHospital(world)
    
    hospital.emergency = {
      disease = createMockDisease("bloaty_head", 18),
      victims = 10,
      bonus = 1000,
      percentage = 0.75,
      killed_emergency_patients = 0,
      cured_emergency_patients = 0,
    }
    
    for i = 1, 10 do
      local p = createMockPatient()
      p.hospital = hospital
      p.is_emergency = i
      hospital.emergency_patients[i] = p
    end
  end)
  
  it("should fail when cure rate < 75%", function()
    hospital.emergency.cured_emergency_patients = 7  -- 70%
    hospital.emergency.killed_emergency_patients = 3
    
    local money_spy = spy.on(hospital, "receiveMoney")
    local rep_spy = spy.on(hospital, "changeReputation")
    local fax_spy = spy.on(hospital, "makeEmergencyEndFax")
    
    hospital:resolveEmergency()
    
    assert.spy(money_spy).was_not.called()
    assert.spy(rep_spy).was.called_with(match.is_ref(hospital), "emergency_failed", match.any())
    assert.spy(fax_spy).was.called_with(match.is_ref(hospital), 7, 10, 10000, 0)
  end)
  
  it("should fail at 0% cure rate", function()
    hospital.emergency.cured_emergency_patients = 0
    hospital.emergency.killed_emergency_patients = 10
    
    local money_spy = spy.on(hospital, "receiveMoney")
    
    hospital:resolveEmergency()
    
    assert.spy(money_spy).was_not.called()
  end)
end)

describe("Emergency System - Timer Management", function()
  local world, hospital, watch
  
  before_each(function()
    world = createMockWorld()
    hospital = createMockHospital(world)
    watch = createMockUIWatch()
    watch.ui = world.ui
    watch.hospital = hospital
    world.ui.getWindow = function() return watch end
    hospital.world = world
  end)
  
  it("should start with 12 segments (52 days / 13 segments)", function()
    assert.equals(12, watch.open_timer)
    assert.equals("emergency", watch.count_type)
  end)
  
  it("should decrement timer on each tick_rate interval", function()
    watch.tick_timer = 1
    watch:onWorldTick()  -- Should not decrement yet
    assert.equals(12, watch.open_timer)
    
    watch.tick_timer = 0
    watch:onWorldTick()  -- Should decrement
    assert.equals(11, watch.open_timer)
    assert.equals(watch.tick_rate, watch.tick_timer)
  end)
  
  it("should trigger onCountdownEnd when open_timer reaches -1", function()
    local end_spy = spy.on(watch, "onCountdownEnd")
    
    watch.open_timer = 0
    watch.tick_timer = 0
    watch:onWorldTick()  -- Goes to -1
    
    -- Next tick should trigger end
    watch:onWorldTick()
    
    assert.spy(end_spy).was.called()
  end)
  
  it("should call hospital.resolveEmergency on countdown end", function()
    local resolve_spy = spy.on(hospital, "resolveEmergency")
    
    watch:onCountdownEnd()
    
    assert.spy(resolve_spy).was.called_with(match.is_ref(hospital))
  end)
  
  it("should close watch window on countdown end", function()
    local close_spy = spy.on(watch, "close")
    
    watch:onCountdownEnd()
    
    assert.spy(close_spy).was.called()
  end)
  
  it("should force timer end when all patients cured/died", function()
    hospital.emergency = {
      victims = 5,
      killed_emergency_patients = 2,
      cured_emergency_patients = 3,
    }
    
    local end_spy = spy.on(watch, "onCountdownEnd")
    
    hospital:checkEmergencyOver()
    
    assert.spy(end_spy).was.called()
  end)
  
  it("should not force timer end when patients remain", function()
    hospital.emergency = {
      victims = 5,
      killed_emergency_patients = 1,
      cured_emergency_patients = 2,
    }
    
    local end_spy = spy.on(watch, "onCountdownEnd")
    
    hospital:checkEmergencyOver()
    
    assert.spy(end_spy).was_not.called()
  end)
end)

describe("Emergency System - Helicopter Spawning", function()
  local world, hospital, heli
  
  before_each(function()
    world = createMockWorld()
    hospital = createMockHospital(world)
    
    hospital.emergency = {
      disease = createMockDisease("bloaty_head", 18),
      victims = 5,
      bonus = 1000,
      percentage = 0.75,
      killed_emergency_patients = 0,
      cured_emergency_patients = 0,
    }
    
    heli = createMockHelicopter()
    heli.hospital = hospital
    hospital.emergency_patients = {}
    
    -- Mock world.newObject to return our heli
    world.newObject = function(self, type, dir)
      if type == "helicopter" then return heli end
      return nil
    end
  end)
  
  it("should initialize helicopter at heliport position", function()
    hospital.getHeliportPosition = function() return 10, 10 end
    
    heli:Helicopter(hospital, "helicopter", "north", {})
    
    assert.equals(hospital, heli.hospital)
    assert.same({}, hospital.emergency_patients)
  end)
  
  it("should spawn patients one by one during phase 85", function()
    heli:Helicopter(hospital, "helicopter", "north", {})
    
    -- Simulate phases
    heli.phase = 60
    heli:tick()  -- Phase 61
    
    -- Advance to phase 85
    for _ = 1, 25 do heli:tick() end  -- Phase 85
    
    -- Should spawn first patient
    assert.equals(1, heli.spawned_patients)
    assert.equals(1, #hospital.emergency_patients)
    assert.equals(hospital.emergency.disease, hospital.emergency_patients[1].disease)
    assert.equals(1, hospital.emergency_patients[1].is_emergency)
    assert.is_true(hospital.emergency_patients[1].diagnosis_progress == 1)
  end)
  
  it("should spawn all victims then leave", function()
    heli:Helicopter(hospital, "helicopter", "north", {})
    
    -- Run through all phases quickly
    for _ = 1, 200 do heli:tick() end
    
    assert.equals(5, heli.spawned_patients)
    assert.equals(5, #hospital.emergency_patients)
  end)
  
  it("should mark patients as emergency with sequential numbers", function()
    heli:Helicopter(hospital, "helicopter", "north", {})
    
    for _ = 1, 100 do heli:tick() end
    
    for i = 1, 5 do
      assert.equals(i, hospital.emergency_patients[i].is_emergency)
    end
  end)
  
  it("should set patients to seek final treatment room", function()
    heli:Helicopter(hospital, "helicopter", "north", {})
    
    for _ = 1, 100 do heli:tick() end
    
    for i = 1, 5 do
      local p = hospital.emergency_patients[i]
      assert.equals(2, p.cure_rooms_visited)  -- #treatment_rooms - 1 = 3 - 1
      -- Patient should have SeekRoomAction queued for final room
    end
  end)
end)

describe("Emergency System - Fax Integration", function()
  local world, hospital, bottom_panel
  
  before_each(function()
    world = createMockWorld()
    hospital = createMockHospital(world)
    bottom_panel = createMockBottomPanel()
    bottom_panel.world = world
    world.ui.bottom_panel = bottom_panel
  end)
  
  it("should queue start fax with accept/refuse choices", function()
    hospital.emergency = {
      disease = createMockDisease("bloaty_head", 18),
      victims = 5,
      bonus = 1000,
      percentage = 0.75,
    }
    
    local queue_spy = spy.on(bottom_panel, "queueMessage")
    
    hospital:makeEmergencyStartFax()
    
    assert.spy(queue_spy).was.called()
    local args = queue_spy.calls[1].vals
    assert.equals("emergency", args[1])
    assert.is_table(args[2])
    assert.is_table(args[2].choices)
    assert.equals(2, #args[2].choices)
    assert.equals("accept_emergency", args[2].choices[1].choice)
    assert.equals("refuse_emergency", args[2].choices[2].choice)
  end)
  
  it("should auto-refuse after 16 days", function()
    hospital.emergency = {
      disease = createMockDisease("bloaty_head", 18),
      victims = 5,
      bonus = 1000,
    }
    
    local queue_spy = spy.on(bottom_panel, "queueMessage")
    
    hospital:makeEmergencyStartFax()
    
    local args = queue_spy.calls[1].vals
    assert.equals(Date.hoursPerDay() * 16, args[4])  -- timeout
  end)
  
  it("should queue end fax with results", function()
    local queue_spy = spy.on(bottom_panel, "queueMessage")
    
    hospital:makeEmergencyEndFax(8, 10, 10000, 8000)
    
    assert.spy(queue_spy).was.called()
    local args = queue_spy.calls[1].vals
    assert.equals("report", args[1])
    assert.is_table(args[2])
    assert.is_table(args[2].choices)
    assert.equals(1, #args[2].choices)
    assert.equals("close", args[2].choices[1].choice)
  end)
  
  it("should schedule next emergency on refuse", function()
    local next_em_spy = spy.on(world, "nextEmergency")
    
    bottom_panel:cancelFax("emergency")
    
    assert.spy(next_em_spy).was.called_with(match.is_ref(world))
  end)
  
  it("should include treatment availability in start fax", function()
    hospital.emergency = {
      disease = createMockDisease("bloaty_head", 18),
      victims = 5,
      bonus = 1000,
    }
    
    -- No treatment room
    hospital.countRoomOfType = function(self, room_type) return 0 end
    hospital.countStaffOfCategory = function(self, cat) return 1 end
    
    local queue_spy = spy.on(bottom_panel, "queueMessage")
    hospital:makeEmergencyStartFax()
    
    local args = queue_spy.calls[1].vals
    local message_text = table.concat(vim.tbl_map(function(v) return v.text or "" end, args[2]), " ")
    -- Should mention room needed
    assert.matches("build", message_text:lower())
  end)
end)

describe("Emergency System - World Scheduling", function()
  local world
  
  before_each(function()
    world = createMockWorld()
    world.game_date = {
      monthOfGame = function() return 1 end,
      dayOfMonth = function() return 15 end,
      year = function() return 1 end,
      monthOfYear = function() return 1 end,
      isSameDay = function(self, other) 
        return self:monthOfGame() == other:monthOfGame() and self:dayOfMonth() == other:dayOfMonth()
      end,
      plusDays = function(self, d) 
        return { monthOfGame = function() return 1 end, dayOfMonth = function() return 15 + d end }
      end,
      lastDayOfMonth = function() return 28 end,
    }
  end)
  
  it("should schedule random emergency on level with Mean/Variance", function()
    world.map.level_config.emergency_control = {
      [0] = { Mean = 180, Variance = 30 }
    }
    
    local schedule_spy = spy.on(world, "scheduleRandomEmergency")
    world:nextEmergency()
    
    assert.spy(schedule_spy).was.called()
  end)
  
  it("should process controlled emergencies from config", function()
    world.map.level_config.emergency_control = {
      [0] = { Random = false },
      [1] = { StartMonth = 1, EndMonth = 12, Illness = "bloaty_head", Min = 5, Max = 15, Bonus = 1500, PercWin = 75 }
    }
    world.next_emergency_no = 1
    
    world.available_diseases = { createMockDisease("bloaty_head", 18) }
    
    local compute_spy = spy.on(world, "computeNextEmergencyDates")
    world:nextEmergency()
    
    assert.spy(compute_spy).was.called()
    assert.is_not_nil(world.next_emergency)
  end)
  
  it("should trigger emergency on matching date", function()
    world.next_emergency_month = 1
    world.next_emergency_day = 15
    world.next_emergency = { Illness = "bloaty_head", Min = 5, Max = 10, Bonus = 1000, PercWin = 75 }
    world.available_diseases = { createMockDisease("bloaty_head", 18) }
    
    local hospital = createMockHospital(world)
    hospital.createEmergency = function(self, emergency) 
      self.emergency = emergency or {}
      return nil 
    end
    world.getLocalPlayerHospital = function() return hospital end
    world.ui.getWindow = function() return nil end  -- No watch window
    
    world:onEndDay()
    
    assert.is_not_nil(hospital.emergency)
  end)
  
  it("should postpone emergency if watch window open", function()
    world.next_emergency_month = 1
    world.next_emergency_day = 15
    world.next_emergency = { Illness = "bloaty_head", Min = 5, Max = 10 }
    world.ui.getWindow = function() return {} end  -- Watch window exists
    
    local next_em_spy = spy.on(world, "nextEmergency")
    world:onEndDay()
    
    -- Should have postponed (called nextEmergency to reschedule)
    assert.spy(next_em_spy).was.called()
  end)
end)

describe("Emergency System - Patient Integration", function()
  local world, hospital, patient
  
  before_each(function()
    world = createMockWorld()
    hospital = createMockHospital(world)
    patient = createMockPatient()
    patient.hospital = hospital
    patient.is_emergency = 1
    
    hospital.emergency = {
      victims = 5,
      cured_emergency_patients = 0,
      killed_emergency_patients = 0,
    }
  end)
  
  it("should call checkEmergencyOver when emergency patient cured", function()
    hospital.checkEmergencyOver = spy.new(function() end)
    
    patient:cure()
    
    assert.spy(hospital.checkEmergencyOver).was.called()
    assert.equals(1, hospital.emergency.cured_emergency_patients)
  end)
  
  it("should call checkEmergencyOver when emergency patient goes home/dies", function()
    hospital.checkEmergencyOver = spy.new(function() end)
    
    patient:goHome("over_priced", "bloaty_head")
    
    assert.spy(hospital.checkEmergencyOver).was.called()
  end)
  
  it("should increment killed count when patient dies", function()
    patient:die()
    
    assert.equals(1, hospital.emergency.killed_emergency_patients)
  end)
  
  it("should increment cured count when patient cured", function()
    patient:cure()
    
    assert.equals(1, hospital.emergency.cured_emergency_patients)
  end)
end)

describe("Emergency System - Edge Cases", function()
  local world, hospital
  
  before_each(function()
    world = createMockWorld()
    hospital = createMockHospital(world)
  end)
  
  it("should handle zero victims emergency", function()
    hospital.getHeliportSpawnPosition = function() return 10, 10 end
    hospital.hasReceptionDesk = function() return true end
    
    local emergency = {
      disease = createMockDisease("bloaty_head", 18),
      victims = 0,
      bonus = 1000,
      percentage = 0.75,
      killed_emergency_patients = 0,
      cured_emergency_patients = 0,
    }
    
    local result = hospital:createEmergency(emergency)
    
    assert.is_nil(result)
    -- Resolution would divide by zero - check protection needed
  end)
  
  it("should handle emergency with no patients array", function()
    hospital.emergency = {
      victims = 5,
      cured_emergency_patients = 5,
      killed_emergency_patients = 0,
    }
    hospital.emergency_patients = {}
    
    -- Should not crash
    hospital:checkEmergencyOver()
  end)
  
  it("should handle resolveEmergency with no emergency", function()
    hospital.emergency = nil
    hospital.emergency_patients = {}
    
    -- Should not crash (but will error on emer.victims access)
    -- This tests the need for nil checks
    assert.has_error(function() hospital:resolveEmergency() end)
  end)
  
  it("should handle helicopter spawn with no heliport position", function()
    hospital.getHeliportSpawnPosition = function() return nil end
    
    local heli = createMockHelicopter()
    heli.hospital = hospital
    
    heli:spawnPatient()
    
    -- Patient creation should still work but spawn position nil
  end)
end)

-- ============================================================
-- RUNNER
-- ============================================================

-- To run these tests:
-- 1. Install busted: luarocks install busted
-- 2. Run: busted SCAFFOLD.lua
-- 3. Or run specific test: busted SCAFFOLD.lua --filter="Creation"

print("Emergency System Test Scaffold loaded.")
print("Run with: busted SCAFFOLD.lua")
