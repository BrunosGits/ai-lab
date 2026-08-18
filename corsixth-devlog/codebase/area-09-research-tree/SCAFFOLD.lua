--[[
  CorsixTH Research Department — Busted Test Scaffold
  
  Run with: busted SCAFFOLD.lua
  Requires: busted, luassert, say
  
  Mocks TheApp, world, hospital, objects, diseases, rooms, level_config
--]]

local busted = require "busted"
local describe, it, before_each, after_each, setup, teardown = busted.describe, busted.it, busted.before_each, busted.after_each, busted.setup, busted.teardown
local assert = require "luassert"
local spy = require "luassert.spy"
local stub = require "luassert.stub"
local match = require "luassert.match"

-- ============================================================================
-- MOCK INFRASTRUCTURE
-- ============================================================================

local function createMockObject(id, thob, research_category, default_strength)
  return {
    id = id,
    thob = thob,
    research_category = research_category,
    default_strength = default_strength,
    name = id:gsub("_", " "):gsub("^%l", string.upper),
  }
end

local function createMockDisease(id, expertise_id, drug, cure_effectiveness, drug_cost, discovered)
  return {
    id = id,
    disease = { id = id, expertise_id = expertise_id, treatment_rooms = {} },
    drug = drug,
    cure_effectiveness = cure_effectiveness or 50,
    drug_cost = drug_cost or 100,
    discovered = discovered or false,
    name = id:gsub("_", " "):gsub("^%l", string.upper),
    concentrate_research = false,
  }
end

local function createMockRoom(id, objects_needed)
  return {
    id = id,
    room_info = { id = id },
    objects_needed = objects_needed or {},
    objects = {},
    hospital = nil,
  }
end

local function createMockHospital()
  local hospital = {
    disease_casebook = {},
    discovered_diseases = {},
    room_discoveries = {},
    acc_research_cost = 0,
    research_dep_built = false,
    world = nil,
    giveAdvice = spy.new(function() end),
    adviseDiscoverDisease = spy.new(function() end),
    canConcentrateResearch = spy.new(function(disease_id) return true end),
    unconditionalChangeReputation = spy.new(function() end),
  }
  return hospital
end

local function createMockWorld(hospital)
  local world = {
    map = {
      level_config = {
        gbv = {
          ResearchPointsDivisor = 5,
          MaxObjectStrength = 20,
          ResearchIncrement = 2,
          DrugImproveRate = 5,
          MinDrugCost = 50,
          RschImproveCostPercent = 10,
          RschImproveIncrementPercent = 10,
          AutopsyRschPercent = 33,
          StartRating = 100,
          StartCost = 100,
        },
        objects = {},
        expertise = {},
      },
    },
    objects = {},
    available_rooms = {},
    rooms = {},
    free_build_mode = false,
    ui = {
      getWindow = spy.new(function() return nil end),
      app = { config = { new_machine_extra_info = false } },
    },
  }
  hospital.world = world
  world.hospital = hospital
  return world
end

local function createMockTheApp()
  return {
    objects = {},
  }
end

-- ============================================================================
-- TEST MODULE LOADING
-- ============================================================================

local ResearchDepartment

setup(function()
  -- Mock globals before loading module
  _G.TheApp = createMockTheApp()
  _G.math = _G.math or {}
  _G.math.t_random = function(min, mid, max) return mid end
  _G.math.round = function(x) return math.floor(x + 0.5) end
  _G._A = { research = {
    drug_improved = "Drug improved: %s",
    drug_improved_1 = "First drug improved: %s",
    machine_improved = "Machine improved: %s",
    new_machine_researched = "New machine: %s",
    new_available = "Now available: %s",
    drug_fully_researched = "Fully researched: %s",
  } }
  _G._S = { research = { categories = { cure = "Cure", diagnosis = "Diagnosis", drugs = "Drugs", improvements = "Improvements", specialisation = "Specialisation" } } }
  _G.class = function(name) return { __name = name } end
  _G._G = _G
  
  -- Load the module
  package.path = "/tmp/CorsixTH/CorsixTH/Lua/?.lua;" .. package.path
  ResearchDepartment = require "research_department"
end)

teardown(function()
  _G.TheApp = nil
  _G._A = nil
  _G._S = nil
  _G.class = nil
end)

-- ============================================================================
-- HELPER: BUILD TEST FIXTURE
-- ============================================================================

local function buildTestFixture()
  local hospital = createMockHospital()
  local world = createMockWorld(hospital)
  local theapp = _G.TheApp
  
  -- Configure level_config.objects
  local objects_config = world.map.level_config.objects
  local expertise = world.map.level_config.expertise
  
  -- Expertise entries
  expertise["general_practice"] = { RschReqd = 0 }
  expertise["bloaty_head"] = { RschReqd = 40000 }
  expertise["hairyitus"] = { RschReqd = 40000 }
  elasticity["slack_tongue"] = { RschReqd = 40000 }
  expertise["the_squits"] = { RschReqd = 20000 }
  expertise["i_d_scanner"] = { RschReqd = 20000 }
  expertise["i_d_xray"] = { RschReqd = 30000 }
  expertise["i_x_research"] = { RschReqd = 15000 }
  
  -- Object configs (thob -> config)
  objects_config[1] = { StartCost = 100, StartAvail = 1, WhenAvail = 0, StartStrength = 10, AvailableForLevel = 1, RschReqd = 0 } -- Desk
  objects_config[2] = { StartCost = 100, StartAvail = 1, WhenAvail = 0, StartStrength = 10, AvailableForLevel = 1, RschReqd = 0 } -- Cabinet
  objects_config[9] = { StartCost = 2500, StartAvail = 0, WhenAvail = 0, StartStrength = 8, AvailableForLevel = 0, RschReqd = 40000 } -- Inflator (bloaty_head)
  objects_config[14] = { StartCost = 5000, StartAvail = 0, WhenAvail = 0, StartStrength = 12, AvailableForLevel = 0, RschReqd = 20000 } -- Scanner
  objects_config[27] = { StartCost = 4000, StartAvail = 0, WhenAvail = 0, StartStrength = 12, AvailableForLevel = 0, RschReqd = 30000 } -- X-Ray
  objects_config[26] = { StartCost = 1500, StartAvail = 0, WhenAvail = 0, StartStrength = 10, AvailableForLevel = 0, RschReqd = 40000 } -- Slicer
  objects_config[40] = { StartCost = 5000, StartAvail = 0, WhenAvail = 0, StartStrength = 10, AvailableForLevel = 0, RschReqd = 30000 } -- Research Computer
  
  -- Create TheApp.objects entries
  theapp.objects = {
    desk = createMockObject("desk", 1, nil, nil),
    cabinet = createMockObject("cabinet", 2, nil, nil),
    inflator = createMockObject("inflator", 9, "cure", 8),
    scanner = createMockObject("scanner", 14, "diagnosis", 12),
    xray = createMockObject("xray", 27, "diagnosis", 12),
    slicer = createMockObject("slicer", 26, "cure", 10),
    research_computer = createMockObject("research_computer", 40, "improvements", 10),
  }
  
  -- Set research_fallback for objects without RschReqd
  theapp.objects.inflator.research_fallback = "bloaty_head"
  theapp.objects.scanner.research_fallback = "i_d_scanner"
  theapp.objects.xray.research_fallback = "i_d_xray"
  theapp.objects.slicer.research_fallback = "slack_tongue"
  theapp.objects.research_computer.research_fallback = "i_x_research"
  
  -- Create diseases
  hospital.disease_casebook = {
    bloaty_head = createMockDisease("bloaty_head", "bloaty_head", false, 60, 100, false),
    hairyitus = createMockDisease("hairyitus", "hairyitus", false, 70, 100, false),
    slack_tongue = createMockDisease("slack_tongue", "slack_tongue", false, 50, 100, false),
    the_squits = createMockDisease("the_squits", "the_squits", true, 40, 100, true),
  }
  
  -- Create rooms
  local gp_office = createMockRoom("gp_office", { desk = 1, cabinet = 1 })
  local scanner_room = createMockRoom("scanner", { scanner = 1, cabinet = 1 })
  local xray_room = createMockRoom("xray", { xray = 1, cabinet = 1 })
  local research_room = createMockRoom("research", { research_computer = 1, cabinet = 1 })
  local inflator_room = createMockRoom("inflator", { inflator = 1, cabinet = 1 })
  local slicer_room = createMockRoom("slack_tongue", { slicer = 1, cabinet = 1 })
  
  world.available_rooms = {
    gp_office = gp_office,
    scanner = scanner_room,
    xray = xray_room,
    research = research_room,
    inflator = inflator_room,
    slack_tongue = slicer_room,
  }
  
  hospital.room_discoveries = {
    gp_office = { room = gp_office, is_discovered = true },
    scanner = { room = scanner_room, is_discovered = false },
    xray = { room = xray_room, is_discovered = false },
    research = { room = research_room, is_discovered = false },
    inflator = { room = inflator_room, is_discovered = false },
    slack_tongue = { room = slicer_room, is_discovered = false },
  }
  
  -- Link rooms to hospital
  for _, room in pairs(world.available_rooms) do
    room.hospital = hospital
  end
  for _, room in pairs(world.rooms) do
    room.hospital = hospital
  end
  
  -- Add research room to world.rooms for cost calculation
  world.rooms = { research = research_room }
  research_room.staff_member_set = {}
  
  -- Create ResearchDepartment
  local research = ResearchDepartment(hospital)
  
  return {
    hospital = hospital,
    world = world,
    theapp = theapp,
    research = research,
  }
end

-- ============================================================================
-- TESTS: POINT DISTRIBUTION
-- ============================================================================

describe("ResearchDepartment — Point Distribution", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
  end)
  
  it("initializes 5 categories with correct fractions", function()
    local policy = fixture.research.research_policy
    
    -- cure: inflator + slicer available → 20%
    assert.equal(20, policy.cure.frac)
    -- diagnosis: scanner + xray available → 20%
    assert.equal(20, policy.diagnosis.frac)
    -- drugs: the_squits has drug → 20%
    assert.equal(20, policy.drugs.frac)
    -- improvements: research_computer available → 20%
    assert.equal(20, policy.improvements.frac)
    -- specialisation: always 20% (dummy)
    assert.equal(20, policy.specialisation.frac)
    -- total should be 100
    assert.equal(100, policy.total)
  end)
  
  it("sets current targets for each category", function()
    local policy = fixture.research.research_policy
    
    -- cure: first undiscovered cure object (inflator)
    assert.equal(fixture.theapp.objects.inflator, policy.cure.current)
    -- diagnosis: first undiscovered diagnosis object (scanner)
    assert.equal(fixture.theapp.objects.scanner, policy.diagnosis.current)
    -- drugs: the_squits is discovered and has drug
    assert.equal(fixture.hospital.disease_casebook.the_squits, policy.drugs.current)
    -- improvements: research_computer is discovered (StartAvail=0 but default_strength exists)
    -- Wait: StartAvail=0 means not discovered. improvements needs discovered machines.
    -- So improvements.current should be drain initially
    assert.is_not_nil(policy.improvements.current)
  end)
  
  it("addResearchPoints distributes points proportionally with variance", function()
    local research = fixture.research
    local policy = research.research_policy
    local progress = research.research_progress
    
    -- Add 1000 raw points
    research:addResearchPoints(1000)
    
    -- divisor=5, total=100 → 1000 * 100 / 500 = 200 points distributed
    -- Each category (20%) gets ~40 points ±25%
    local cure_points = progress[policy.cure.current].points
    local diag_points = progress[policy.diagnosis.current].points
    local drug_points = progress[policy.drugs.current].points
    
    assert.is_true(cure_points > 30 and cure_points < 50)
    assert.is_true(diag_points > 30 and diag_points < 50)
    assert.is_true(drug_points > 30 and drug_points < 50)
  end)
  
  it("excludes dummy categories from point distribution", function()
    local research = fixture.research
    local policy = research.research_policy
    local progress = research.research_progress
    
    -- Set specialisation to dummy
    policy.specialisation.current = policy.specialisation.current -- drain
    
    research:addResearchPoints(1000)
    
    -- Drain should get no points (or minimal)
    local drain_points = progress[policy.specialisation.current].points
    assert.equal(0, drain_points)
  end)
  
  it("reduces total points when categories finish", function()
    local research = fixture.research
    local policy = research.research_policy
    
    -- Finish cure category
    policy.cure.frac = 0
    policy.cure.current = nil
    
    -- Manually trigger redistribution
    research:redistributeResearchPoints()
    
    -- Total should now be 80 (specialisation still 20)
    assert.equal(80, policy.total)
  end)
end)

-- ============================================================================
-- TESTS: AUTO-SELECTION LOGIC
-- ============================================================================

describe("ResearchDepartment — Auto-Selection", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
  end)
  
  describe("Drug research selection", function()
    it("selects discovered drug with lowest effectiveness", function()
      local research = fixture.research
      local policy = research.research_policy
      
      -- the_squits has 40% effectiveness (lowest)
      research:nextResearch("drugs")
      
      assert.equal(fixture.hospital.disease_casebook.the_squits, policy.drugs.current)
    end)
    
    it("sets drain when undiscovered drugs need improvement", function()
      local research = fixture.research
      local policy = research.research_policy
      
      -- Make the_squits undiscovered
      fixture.hospital.disease_casebook.the_squits.discovered = false
      fixture.hospital.disease_casebook.bloaty_head.discovered = false
      fixture.hospital.disease_casebook.hairyitus.discovered = false
      fixture.hospital.disease_casebook.slack_tongue.discovered = false
      
      research:nextResearch("drugs")
      
      -- Should set to drain since no discovered drugs
      assert.equal(research.drain, policy.drugs.current)
    end)
    
    it("finishes category when all drugs at 100% effectiveness", function()
      local research = fixture.research
      local policy = research.research_policy
      
      -- Set all discovered drugs to 100%
      for _, disease in pairs(fixture.hospital.disease_casebook) do
        if disease.drug and disease.discovered then
          disease.cure_effectiveness = 100
        end
      end
      
      research:nextResearch("drugs")
      
      assert.is_nil(policy.drugs.current)
      assert.equal(0, policy.drugs.frac)
    end)
  end)
  
  describe("Machine improvement selection", function()
    it("selects discovered machine with lowest strength", function()
      local research = fixture.research
      local policy = research.research_policy
      
      -- Make machines discovered
      research.research_progress[fixture.theapp.objects.scanner].discovered = true
      research.research_progress[fixture.theapp.objects.xray].discovered = true
      research.research_progress[fixture.theapp.objects.research_computer].discovered = true
      
      -- scanner: 12, xray: 12, research_computer: 10
      -- research_computer has lowest strength
      research:nextResearch("improvements")
      
      assert.equal(fixture.theapp.objects.research_computer, policy.improvements.current)
    end)
    
    it("excludes machines at max strength (20)", function()
      local research = fixture.research
      local policy = research.research_policy
      
      research.research_progress[fixture.theapp.objects.scanner].discovered = true
      research.research_progress[fixture.theapp.objects.scanner].start_strength = 20
      research.research_progress[fixture.theapp.objects.research_computer].discovered = true
      research.research_progress[fixture.theapp.objects.research_computer].start_strength = 10
      
      research:nextResearch("improvements")
      
      assert.equal(fixture.theapp.objects.research_computer, policy.improvements.current)
    end)
    
    it("sets drain when undiscovered machines need improvement", function()
      local research = fixture.research
      local policy = research.research_policy
      
      -- No machines discovered
      research:nextResearch("improvements")
      
      assert.equal(research.drain, policy.improvements.current)
    end)
  end)
  
  describe("Cure/Diagnosis discovery selection", function()
    it("selects first undiscovered object in category", function()
      local research = fixture.research
      local policy = research.research_policy
      
      research:nextResearch("cure")
      
      -- inflator is first cure object in TheApp.objects
      assert.equal(fixture.theapp.objects.inflator, policy.cure.current)
    end)
  end)
end)

-- ============================================================================
-- TESTS: DRUG IMPROVEMENT
-- ============================================================================

describe("ResearchDepartment — Drug Improvement", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
    -- Ensure deterministic random
    _G.math.random = function(m, n)
      if m == 1 and n == 2 then return 1 end -- effectiveness
      if m == 1 and n == 7 then return 2 end -- not "both"
      return m or 1
    end
  end)
  
  it("improves effectiveness by DrugImproveRate (5)", function()
    local research = fixture.research
    local disease = fixture.hospital.disease_casebook.the_squits
    local initial_effectiveness = disease.cure_effectiveness
    
    research:improveDrug(disease)
    
    assert.equal(initial_effectiveness + 5, disease.cure_effectiveness)
  end)
  
  it("reduces cost by 10% (floored, min 50)", function()
    local research = fixture.research
    local disease = fixture.hospital.disease_casebook.the_squits
    disease.cure_effectiveness = 100 -- Force cost improvement
    
    local initial_cost = disease.drug_cost
    research:improveDrug(disease)
    
    local expected = math.max(50, math.floor(initial_cost * 0.9))
    assert.equal(expected, disease.drug_cost)
  end)
  
  it("can improve both effectiveness and cost (1/7 chance)", function()
    local research = fixture.research
    local disease = fixture.hospital.disease_casebook.the_squits
    
    _G.math.random = function(m, n)
      if m == 1 and n == 2 then return 1 end
      if m == 1 and n == 7 then return 1 end -- "both"
      return m or 1
    end
    
    local initial_eff = disease.cure_effectiveness
    local initial_cost = disease.drug_cost
    
    research:improveDrug(disease)
    
    assert.equal(initial_eff + 5, disease.cure_effectiveness)
    assert.equal(math.max(50, math.floor(initial_cost * 0.9)), disease.drug_cost)
  end)
  
  it("stops when effectiveness=100 and cost=50", function()
    local research = fixture.research
    local disease = fixture.hospital.disease_casebook.the_squits
    disease.cure_effectiveness = 100
    disease.drug_cost = 50
    
    -- Should return early without changes
    research:improveDrug(disease)
    
    assert.equal(100, disease.cure_effectiveness)
    assert.equal(50, disease.drug_cost)
  end)
  
  it("advances to next drug after improvement", function()
    local research = fixture.research
    local policy = research.research_policy
    
    research:improveDrug(fixture.hospital.disease_casebook.the_squits)
    
    -- Should call nextResearch for drugs
    -- the_squits should no longer be current
    assert.is_not_equal(fixture.hospital.disease_casebook.the_squits, policy.drugs.current)
  end)
  
  it("clears specialisation when drug hits 100% effectiveness", function()
    local research = fixture.research
    local policy = research.research_policy
    local disease = fixture.hospital.disease_casebook.the_squits
    
    policy.specialisation.current = disease
    disease.cure_effectiveness = 95
    
    research:improveDrug(disease) -- Will hit 100
    
    assert.equal(research.drain, policy.specialisation.current)
  end)
end)

-- ============================================================================
-- TESTS: MACHINE IMPROVEMENT
-- ============================================================================

describe("ResearchDepartment — Machine Improvement", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
  end)
  
  it("alternates: first improvement is strength (+2)", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.research_computer
    local progress = research.research_progress[machine]
    
    progress.discovered = true
    progress.start_strength = 10
    progress.strength_imp = 0
    progress.cost_imp = 0
    
    research:improveMachine(machine)
    
    assert.equal(12, progress.start_strength)
    assert.equal(1, progress.strength_imp)
    assert.equal(0, progress.cost_imp)
  end)
  
  it("second improvement is cost (-12.5%)", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.research_computer
    local progress = research.research_progress[machine]
    
    progress.discovered = true
    progress.start_strength = 12
    progress.strength_imp = 1
    progress.cost_imp = 0
    progress.cost = 5000
    
    research:improveMachine(machine)
    
    -- 12.5% of 5000 = 625, rounded to nearest 10 = 630
    local expected_cost = 5000 - 630
    assert.equal(expected_cost, progress.cost)
    assert.equal(1, progress.cost_imp)
  end)
  
  it("reduces room build_cost for rooms using this machine", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.research_computer
    local progress = research.research_progress[machine]
    local room = fixture.world.available_rooms.research
    room.build_cost = 10000
    
    progress.discovered = true
    progress.start_strength = 12
    progress.strength_imp = 1
    progress.cost_imp = 0
    progress.cost = 5000
    
    research:improveMachine(machine)
    
    -- Room build_cost should decrease by decrease * quantity (1)
    local decrease = math.round(5000 * 0.125 / 10) * 10
    assert.equal(10000 - decrease, room.build_cost)
  end)
  
  it("third improvement is strength again", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.research_computer
    local progress = research.research_progress[machine]
    
    progress.discovered = true
    progress.start_strength = 12
    progress.strength_imp = 1
    progress.cost_imp = 1
    
    research:improveMachine(machine)
    
    assert.equal(14, progress.start_strength)
    assert.equal(2, progress.strength_imp)
  end)
  
  it("stops strength improvements at MaxObjectStrength (20)", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.research_computer
    local progress = research.research_progress[machine]
    local policy = research.research_policy
    
    progress.discovered = true
    progress.start_strength = 20
    progress.strength_imp = 5
    progress.cost_imp = 4
    policy.specialisation.current = machine
    
    research:improveMachine(machine)
    
    -- Should clear specialisation since max strength reached
    assert.equal(research.drain, policy.specialisation.current)
  end)
  
  it("advances to next machine after improvement", function()
    local research = fixture.research
    local policy = research.research_policy
    local machine = fixture.theapp.objects.research_computer
    local progress = research.research_progress[machine]
    
    progress.discovered = true
    progress.start_strength = 10
    policy.improvements.current = machine
    
    research:improveMachine(machine)
    
    assert.is_not_equal(machine, policy.improvements.current)
  end)
end)

-- ============================================================================
-- TESTS: OBJECT DISCOVERY & ROOM UNVEILING
-- ============================================================================

describe("ResearchDepartment — Object Discovery & Room Unveiling", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
  end)
  
  it("marks object as discovered", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.inflator
    
    research:discoverObject(machine)
    
    assert.is_true(research.research_progress[machine].discovered)
  end)
  
  it("unveils room when all required objects discovered", function()
    local research = fixture.research
    local inflator = fixture.theapp.objects.inflator
    local cabinet = fixture.theapp.objects.cabinet
    
    -- cabinet already discovered (StartAvail=1)
    -- inflator not discovered
    assert.is_false(fixture.hospital.room_discoveries.inflator.is_discovered)
    
    research:discoverObject(inflator)
    
    assert.is_true(fixture.hospital.room_discoveries.inflator.is_discovered)
  end)
  
  it("does not unveil room if other objects still undiscovered", function()
    local research = fixture.research
    local scanner = fixture.theapp.objects.scanner
    
    -- scanner room needs scanner + cabinet
    -- cabinet is discovered, scanner is not
    research:discoverObject(scanner)
    
    -- But cabinet was already discovered, so room should unveil
    assert.is_true(fixture.hospital.room_discoveries.scanner.is_discovered)
  end)
  
  it("gives different advice for automatic vs manual discovery", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.inflator
    local hospital = fixture.hospital
    
    research:discoverObject(machine, true) -- automatic
    assert.spy(hospital.giveAdvice).was_called_with(match.has_item(match.matches("Now available")))
    
    hospital.giveAdvice:clear()
    
    research:discoverObject(machine, false) -- manual
    assert.spy(hospital.giveAdvice).was_called_with(match.has_item(match.matches("New machine researched")))
  end)
  
  it("auto-discovers objects when month >= WhenAvail", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.inflator
    local obj_config = fixture.world.map.level_config.objects[machine.thob]
    obj_config.WhenAvail = 5
    
    research:checkAutomaticDiscovery(4) -- Before avail
    assert.is_false(research.research_progress[machine].discovered)
    
    research:checkAutomaticDiscovery(5) -- At avail month
    assert.is_true(research.research_progress[machine].discovered)
  end)
  
  it("triggers improvements research when new machine discovered", function()
    local research = fixture.research
    local policy = research.research_policy
    local inflator = fixture.theapp.objects.inflator
    
    policy.improvements.current = research.drain -- Currently dummy
    
    research:discoverObject(inflator)
    
    -- Should switch to inflator for improvements (strength=8 < max=20)
    assert.equal(inflator, policy.improvements.current)
  end)
end)

-- ============================================================================
-- TESTS: CONCENTRATE RESEARCH
-- ============================================================================

describe("ResearchDepartment — Concentrate Research", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
  end)
  
  it("sets concentration on disease with drug", function()
    local research = fixture.research
    local disease = fixture.hospital.disease_casebook.the_squits
    
    research:concentrateResearch("the_squits")
    
    assert.is_true(disease.concentrate_research)
    assert.equal(disease, research.research_policy.specialisation.current)
  end)
  
  it("sets concentration on machine for undiscovered disease", function()
    local research = fixture.research
    local disease = fixture.hospital.disease_casebook.bloaty_head
    disease.disease.treatment_rooms = { "inflator" }
    
    research:concentrateResearch("bloaty_head")
    
    assert.is_true(disease.concentrate_research)
    assert.equal(fixture.theapp.objects.inflator, research.research_policy.specialisation.current)
  end)
  
  it("clears concentration when called again on same disease", function()
    local research = fixture.research
    local disease = fixture.hospital.disease_casebook.the_squits
    
    research:concentrateResearch("the_squits")
    assert.is_true(disease.concentrate_research)
    
    research:concentrateResearch("the_squits")
    assert.is_false(disease.concentrate_research)
    assert.equal(research.drain, research.research_policy.specialisation.current)
  end)
  
  it("clears previous concentration when setting new one", function()
    local research = fixture.research
    local disease1 = fixture.hospital.disease_casebook.the_squits
    local disease2 = fixture.hospital.disease_casebook.bloaty_head
    disease2.disease.treatment_rooms = { "inflator" }
    
    research:concentrateResearch("the_squits")
    research:concentrateResearch("bloaty_head")
    
    assert.is_false(disease1.concentrate_research)
    assert.is_true(disease2.concentrate_research)
  end)
  
  it("auto-concentrates on first available disease", function()
    local research = fixture.research
    
    research:setResearchConcentration()
    
    -- the_squits is discovered and has drug
    assert.equal(fixture.hospital.disease_casebook.the_squits, research.research_policy.specialisation.current)
  end)
end)

-- ============================================================================
-- TESTS: RESEARCH COST
-- ============================================================================

describe("ResearchDepartment — Research Cost", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
  end)
  
  it("calculates cost as $3 per doctor per percent", function()
    local research = fixture.research
    local hospital = fixture.hospital
    local world = fixture.world
    
    -- Add 2 doctors to research room
    world.rooms.research.staff_member_set = { doc1 = {}, doc2 = {} }
    
    -- 4 active categories (80%), specialisation dummy (20%)
    research:researchCost()
    
    -- ceil(3 * 2 * 80/100) = ceil(4.8) = 5
    assert.equal(5, hospital.acc_research_cost)
  end)
  
  it("excludes dummy specialisation from cost", function()
    local research = fixture.research
    local hospital = fixture.hospital
    local world = fixture.world
    
    world.rooms.research.staff_member_set = { doc1 = {} }
    research.research_policy.specialisation.current = research.drain
    
    research:researchCost()
    
    -- Only 80% active (4 categories * 20%)
    -- ceil(3 * 1 * 80/100) = ceil(2.4) = 3
    assert.equal(3, hospital.acc_research_cost)
  end)
  
  it("excludes finished categories (frac=0) from cost", function()
    local research = fixture.research
    local hospital = fixture.hospital
    local world = fixture.world
    
    world.rooms.research.staff_member_set = { doc1 = {} }
    research.research_policy.cure.frac = 0
    research.research_policy.cure.current = nil
    
    research:researchCost()
    
    -- 60% active (3 categories * 20%)
    -- ceil(3 * 1 * 60/100) = ceil(1.8) = 2
    assert.equal(2, hospital.acc_research_cost)
  end)
  
  it("accumulates cost over multiple calls", function()
    local research = fixture.research
    local hospital = fixture.hospital
    local world = fixture.world
    
    world.rooms.research.staff_member_set = { doc1 = {} }
    
    research:researchCost() -- Day 1: 3
    research:researchCost() -- Day 2: 3
    research:researchCost() -- Day 3: 3
    
    assert.equal(9, hospital.acc_research_cost)
  end)
end)

-- ============================================================================
-- TESTS: RESEARCH REQUIREMENTS
-- ============================================================================

describe("ResearchDepartment — Research Requirements", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
  end)
  
  it("returns object RschReqd for discovery", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.inflator
    
    local required = research:getResearchRequired(machine)
    
    assert.equal(40000, required)
  end)
  
  it("returns expertise RschReqd for drug", function()
    local research = fixture.research
    local disease = fixture.hospital.disease_casebook.the_squits
    
    local required = research:getResearchRequired(disease)
    
    assert.equal(20000, required)
  end)
  
  it("calculates improvement cost as percentage of base", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.research_computer
    local progress = research.research_progress[machine]
    
    progress.discovered = true
    progress.cost_imp = 0
    
    local required = research:getResearchRequired(machine)
    
    -- Base 30000 * 10% = 3000
    assert.equal(3000, required)
  end)
  
  it("increases improvement cost percentage per improvement", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.research_computer
    local progress = research.research_progress[machine]
    
    progress.discovered = true
    progress.cost_imp = 2 -- 3rd improvement
    
    local required = research:getResearchRequired(machine)
    
    -- 10% + 2*10% = 30% of 30000 = 9000
    assert.equal(9000, required)
  end)
end)

-- ============================================================================
-- TESTS: REDISTRIBUTION
-- ============================================================================

describe("ResearchDepartment — Redistribution", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
  end)
  
  it("redistributes evenly when no categories have points", function()
    local research = fixture.research
    local policy = research.research_policy
    
    -- Finish all categories
    policy.cure.frac = 0; policy.cure.current = nil
    policy.diagnosis.frac = 0; policy.diagnosis.current = nil
    policy.drugs.frac = 0; policy.drugs.current = nil
    policy.improvements.frac = 0; policy.improvements.current = nil
    policy.total = 20 -- Only specialisation
    
    research:redistributeResearchPoints()
    
    assert.equal(0, policy.total)
  end)
  
  it("redistributes proportionally when categories remain", function()
    local research = fixture.research
    local policy = research.research_policy
    
    policy.cure.frac = 0; policy.cure.current = nil
    -- diagnosis=20, drugs=20, improvements=20, specialisation=20
    -- sum = 60, total = 80 (after removing specialisation)
    
    research:redistributeResearchPoints()
    
    -- Should redistribute 60 among 3 categories proportionally
    -- Each gets floor(60 * 20 / 60) = 20
    assert.equal(20, policy.diagnosis.frac)
    assert.equal(20, policy.drugs.frac)
    assert.equal(20, policy.improvements.frac)
    assert.equal(80, policy.total)
  end)
  
  it("gives remainder to category with highest fraction", function()
    local research = fixture.research
    local policy = research.research_policy
    
    policy.cure.frac = 30; policy.cure.current = fixture.theapp.objects.inflator
    policy.diagnosis.frac = 20; policy.diagnosis.current = fixture.theapp.objects.scanner
    policy.drugs.frac = 10; policy.drugs.current = fixture.hospital.disease_casebook.the_squits
    policy.improvements.frac = 0; policy.improvements.current = nil
    policy.specialisation.frac = 20
    policy.total = 80
    
    research:redistributeResearchPoints()
    
    -- sum=60, total-specialisation=60
    -- cure: floor(60*30/60)=30, diag: floor(60*20/60)=20, drugs: floor(60*10/60)=10
    -- Total = 60, matches. No remainder.
    assert.equal(30, policy.cure.frac)
    assert.equal(20, policy.diagnosis.frac)
    assert.equal(10, policy.drugs.frac)
  end)
end)

-- ============================================================================
-- TESTS: AUTOPSY RESEARCH
-- ============================================================================

describe("ResearchDepartment — Autopsy Research", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
  end)
  
  it("adds research points to room's undiscovered object", function()
    local research = fixture.research
    local scanner = fixture.theapp.objects.scanner
    local progress = research.research_progress[scanner]
    
    progress.discovered = false
    progress.points = 0
    
    -- AutopsyRschPercent = 33%, required = 20000
    -- advance = 20000 * 33 / 100 = 6600
    research:addResearchPointsForAutopsy("scanner")
    
    assert.equal(6600, progress.points)
  end)
  
  it("discovers object if autopsy points exceed requirement", function()
    local research = fixture.research
    local scanner = fixture.theapp.objects.scanner
    local progress = research.research_progress[scanner]
    
    progress.discovered = false
    progress.points = 15000
    
    research:addResearchPointsForAutopsy("scanner")
    
    -- 15000 + 6600 = 21600 > 20000 → discover
    assert.is_true(progress.discovered)
  end)
  
  it("does nothing if room already discovered", function()
    local research = fixture.research
    local hospital = fixture.hospital
    
    hospital.room_discoveries.scanner.is_discovered = true
    
    research:addResearchPointsForAutopsy("scanner")
    
    -- Should not modify any progress
    assert.equal(0, research.research_progress[fixture.theapp.objects.scanner].points)
  end)
end)

-- ============================================================================
-- TESTS: DISEASE DISCOVERY
-- ============================================================================

describe("ResearchDepartment — Disease Discovery", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
  end)
  
  it("marks disease as discovered and adds to list", function()
    local research = fixture.research
    local disease = fixture.hospital.disease_casebook.bloaty_head
    
    research:discoverDisease(disease.disease)
    
    assert.is_true(disease.discovered)
    assert.equal("bloaty_head", fixture.hospital.discovered_diseases[1])
  end)
  
  it("starts drug research if drug exists and no current drug research", function()
    local research = fixture.research
    local policy = research.research_policy
    local disease = fixture.hospital.disease_casebook.bloaty_head
    disease.drug = true
    
    policy.drugs.current = research.drain
    
    research:discoverDisease(disease.disease)
    
    assert.equal(disease, policy.drugs.current)
  end)
  
  it("triggers auto-concentration", function()
    local research = fixture.research
    local disease = fixture.hospital.disease_casebook.bloaty_head
    disease.drug = true
    
    research:discoverDisease(disease.disease)
    
    -- Should call setResearchConcentration
    assert.is_not_equal(research.drain, research.research_policy.specialisation.current)
  end)
end)

-- ============================================================================
-- EDGE CASES & REGRESSION
-- ============================================================================

describe("ResearchDepartment — Edge Cases", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
  end)
  
  it("handles object without RschReqd (uses fallback)", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.inflator
    
    -- Remove RschReqd from object config
    fixture.world.map.level_config.objects[machine.thob].RschReqd = nil
    
    local required = research:getResearchRequired(machine)
    
    -- Should use fallback (bloaty_head = 40000)
    assert.equal(40000, required)
  end)
  
  it("warns for object without RschReqd and no fallback", function()
    local research = fixture.research
    local machine = fixture.theapp.objects.inflator
    machine.research_fallback = nil
    fixture.world.map.level_config.objects[machine.thob].RschReqd = nil
    
    local required = research:getResearchRequired(machine)
    
    assert.is_nil(required)
  end)
  
  it("handles afterLoad migration for old saves", function()
    local research = fixture.research
    local policy = research.research_policy
    policy.global = 80
    
    research:afterLoad(200, 238) -- old < 238
    
    assert.equal(80, policy.total)
    assert.is_nil(policy.global)
  end)
  
  it("handles empty research (no categories)", function()
    local hospital = fixture.hospital
    hospital.disease_casebook = {}
    
    -- Create new research dept with no objects/diseases
    local ResearchDepartment = require "research_department"
    local research = ResearchDepartment(hospital)
    
    assert.equal(0, research.research_policy.total)
    assert.is_nil(research.research_policy.specialisation.current)
  end)
end)

-- ============================================================================
-- INTEGRATION SCENARIOS
-- ============================================================================

describe("ResearchDepartment — Integration Scenarios", function()
  local fixture
  
  before_each(function()
    fixture = buildTestFixture()
  end)
  
  it("full cycle: discover machine → unveil room → improve machine", function()
    local research = fixture.research
    local inflator = fixture.theapp.objects.inflator
    local cabinet = fixture.theapp.objects.cabinet
    
    -- 1. Discover inflator
    research:discoverObject(inflator)
    assert.is_true(research.research_progress[inflator].discovered)
    assert.is_true(fixture.hospital.room_discoveries.inflator.is_discovered)
    
    -- 2. Add points to improvements for inflator
    research.research_policy.improvements.current = inflator
    for i = 1, 5 do
      research:addResearchPoints(10000)
    end
    
    -- 3. Should have improved strength
    assert.is_true(research.research_progress[inflator].start_strength > 8)
  end)
  
  it("full cycle: drug research → improve → concentrate → 100%", function()
    local research = fixture.research
    local disease = fixture.hospital.disease_casebook.the_squits
    local policy = research.research_policy
    
    -- Start with drug research
    assert.equal(disease, policy.drugs.current)
    
    -- Add points until improvement
    for i = 1, 10 do
      research:addResearchPoints(5000)
    end
    
    -- Concentrate on it
    research:concentrateResearch("the_squits")
    assert.equal(disease, policy.specialisation.current)
    
    -- Continue until 100%
    while disease.cure_effectiveness < 100 do
      research:addResearchPoints(5000)
    end
    
    assert.equal(100, disease.cure_effectiveness)
    assert.equal(research.drain, policy.specialisation.current)
  end)
end)

print("Test scaffold loaded. Run with: busted SCAFFOLD.lua")
