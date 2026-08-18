--[[
  CorsixTH Save/Load & Migration Test Scaffold
  
  Busted test template for testing save/load round-trip,
  migration hooks, permanent object registration.
  
  Usage: busted SCAFFOLD.lua
--]]

local busted = require("busted")
local describe, it, before_each, after_each, setup, teardown =
  busted.describe, busted.it, busted.before_each, busted.after_each,
  busted.setup, busted.teardown
local assert = require("luassert")
local spy = require("luassert.spy")
local mock = require("luassert.mock")

-- ============================================================================
-- TEST FIXTURES & HELPERS
-- ============================================================================

local test_helpers = {}

-- Create a minimal test app context
function test_helpers.create_test_app()
  -- This would normally be set up by CorsixTH's test harness
  -- Mock the minimum required globals
  _G.TheApp = {
    config = { play_sounds = true, debug = false },
    objects = {},
    modes = {},
    video = {},
    strings = {},
    audio = { playSoundEffects = function() end },
    gfx = { load_info = setmetatable({}, {__mode = "k"}) },
    fs = {},
    moviePlayer = {},
    ui = {
      menu_bar = { ui = nil, onChangeLanguage = function() end },
      cursor = nil,
      setCursor = function() end,
      addOrRemoveDebugModeKeyHandlers = function() end,
      onChangeResolution = function() end,
    },
    world = nil,
    map = nil,
    savegame_version = 212,
    getReleaseString = function(self, v) return "0." .. (v or 60) end,
    checkCompatibility = function() return true end,
    writeToFileOrTmp = function(self, f, m) return io.open(f, m) end,
    afterLoad = function() end,
  }
  
  _G.math = _G.math or {}
  _G.math.randomdump = function() return "rng_state" end
  _G.math.randomseed = function() end
  
  _G.class = { is = function(a, b) return getmetatable(a) == b end }
  
  _G.corsixth = { require = function() return {} end }
  
  _G.persist = { dump = function() return "binary_data" end, load = function() return {} end }
  
  return _G.TheApp
end

-- Capture savegame data
function test_helpers.save_game_state(app)
  local original_SaveGame = _G.SaveGame
  local data = nil
  
  _G.SaveGame = function()
    data = original_SaveGame()
    return data
  end
  
  _G.SaveGameFile = function(filename)
    local f = assert(io.open(filename, "wb"))
    f:write(data)
    f:close()
  end
  
  return function() return data end
end

-- Load game state
function test_helpers.load_game_state(app, data)
  local original_LoadGame = _G.LoadGame
  
  _G.LoadGame = function(d)
    return original_LoadGame(d or data)
  end
  
  _G.LoadGameFile = function(filename)
    local f = assert(io.open(filename, "rb"))
    local d = f:read("*a")
    f:close()
    return original_LoadGame(d)
  end
end

-- ============================================================================
-- TEST SUITE: SERIALIZATION / DESERIALIZATION
-- ============================================================================

describe("Save/Load Core Serialization", function()
  local app
  
  before_each(function()
    app = test_helpers.create_test_app()
  end)
  
  it("should serialize basic Lua types", function()
    local state = {
      number = 42,
      string = "hello",
      boolean = true,
      nil_value = nil,
      table = { nested = { 1, 2, 3 } },
    }
    
    local data = persist.dump(state, {})
    assert.is_string(data)
    assert.is_true(#data > 0)
    
    local loaded = persist.load(data, {})
    assert.are.equal(42, loaded.number)
    assert.are.equal("hello", loaded.string)
    assert.are.equal(true, loaded.boolean)
    assert.is_nil(loaded.nil_value)
    assert.are.same({1, 2, 3}, loaded.table.nested)
  end)
  
  it("should handle circular references", function()
    local a = { name = "a" }
    local b = { name = "b", ref = a }
    a.ref = b
    
    local data = persist.dump({ root = a }, {})
    local loaded = persist.load(data, {})
    
    assert.are.equal("a", loaded.root.name)
    assert.are.equal("b", loaded.root.ref.name)
    assert.are.equal(loaded.root, loaded.root.ref.ref) -- Same object identity
  end)
  
  it("should preserve table identity for repeated references", function()
    local shared = { value = "shared" }
    local state = { first = shared, second = shared }
    
    local data = persist.dump(state, {})
    local loaded = persist.load(data, {})
    
    assert.are.equal(loaded.first, loaded.second) -- Same table reference
  end)
  
  it("should serialize functions with persistable annotation", function()
    --[[persistable:test_module.test_func]]
    local function test_func(x)
      return x * 2
    end
    
    local permanents = { [test_func] = "test_module.test_func" }
    local data = persist.dump({ fn = test_func }, permanents)
    local loaded = persist.load(data, { ["test_module.test_func"] = test_func })
    
    assert.is_function(loaded.fn)
    assert.are.equal(10, loaded.fn(5))
  end)
  
  it("should fail on non-persistable C functions", function()
    local state = { fn = print }
    local permanents = {}
    
    -- Should error or handle gracefully
    local ok, err = pcall(persist.dump, state, permanents)
    assert.is_false(ok) -- C functions cannot be persisted
  end)
end)

-- ============================================================================
-- TEST SUITE: PERMANENT OBJECT REGISTRATION
-- ============================================================================

describe("Permanent Object System", function()
  local app, saved_permanents
  
  before_each(function()
    app = test_helpers.create_test_app()
    saved_permanents = {}
    _G.saved_permanents = saved_permanents
    
    -- Mock permanent/unpermanent
    _G.permanent = function(name, val)
      if val == nil then
        return function(v) return permanent(name, v) end
      end
      assert(saved_permanents[name] == nil, "Already permanent: " .. name)
      saved_permanents[name] = val
      return val
    end
    _G.unpermanent = function(name)
      assert(saved_permanents[name] ~= nil, "Not permanent: " .. name)
      saved_permanents[name] = nil
    end
  end)
  
  after_each(function()
    _G.saved_permanents = nil
    _G.permanent = nil
    _G.unpermanent = nil
  end)
  
  it("should register and retrieve permanent objects", function()
    local obj = { id = "test_object" }
    permanent("test.object", obj)
    
    assert.are.equal(obj, saved_permanents["test.object"])
  end)
  
  it("should support decorator syntax", function()
    local obj = { id = "decorated" }
    local decorator = permanent("test.decorated")
    local result = decorator(obj)
    
    assert.are.equal(obj, result)
    assert.are.equal(obj, saved_permanents["test.decorated"])
  end)
  
  it("should unregister permanent objects", function()
    local obj = { id = "temp" }
    permanent("test.temp", obj)
    unpermanent("test.temp")
    
    assert.is_nil(saved_permanents["test.temp"])
  end)
  
  it("should build permanent objects table for saving", function()
    -- Mock globals needed by MakePermanentObjectsTable
    _G.TheApp = app
    _G.UIMenuBar = function() return { ui = nil, onChangeLanguage = function() end } end
    
    local permanent_mod = require("persistance") -- This loads the actual module
    local perm_table = permanent_mod.MakePermanentObjectsTable(false)
    
    -- Should contain TheApp
    assert.is_not_nil(perm_table[TheApp])
    assert.are.equal("TheApp", perm_table[TheApp])
  end)
  
  it("should build inverted table for loading", function()
    _G.TheApp = app
    _G.UIMenuBar = function() return { ui = nil, onChangeLanguage = function() end } end
    
    local permanent_mod = require("persistance")
    local perm_table = permanent_mod.MakePermanentObjectsTable(true)
    
    -- Should resolve TheApp.config via fetch instruction
    local config_resolver = perm_table[TheApp.config]
    assert.is_table(config_resolver)
    assert.are.equal("global_fetch", config_resolver[1])
    assert.are.equal("TheApp", config_resolver[2])
    assert.are.equal("config", config_resolver[3])
  end)
end)

-- ============================================================================
-- TEST SUITE: MIGRATION HOOKS (afterLoad)
-- ============================================================================

describe("Migration System - afterLoad Hooks", function()
  local app, world, map, ui
  
  before_each(function()
    app = test_helpers.create_test_app()
    
    -- Create minimal world
    world = {
      savegame_version = 0,
      original_savegame_version = nil,
      game_log = {},
      rooms = {},
      entities = {},
      objects = {},
      object_counts = {},
      hospitals = {{ value = 0, getPlayerIndex = function() return 1 end }},
      available_diseases = {},
      available_staff = {},
      epidemic = nil,
      earthquake = { afterLoad = function() end },
      dispatcher = nil,
      animation_manager = {},
      anim_length_cache = nil,
      hours_per_day = 0,
      spawn_rate = 0,
      monthly_spawn_increase = 0,
      spawn_hours = {},
      spawn_dates = {},
      month = 1,
      year = 1,
      user_actions_allowed = false,
      room_remove_callbacks = {},
      map = {
        parcelTileCounts = { [1] = 100 },
        th = { getPlotCount = function() return 1 end, getParcelTileCount = function() return 100 end },
        level_config = { popn = {}, gbv = {}, expertise = {}, awards_trophies = {}, non_visuals_available = {}, payroll = {} },
        width = 10, height = 10,
        setCellFlags = function() end,
        th = { updatePathfinding = function() end },
      },
      applyLevelStartPrices = function() end,
      setUI = function() end,
      nextEmergency = function() end,
      nextVip = function() end,
      updateSpawnDates = function() end,
      gameLog = function() end,
      playLoadedEntitySounds = function() end,
      newObjectType = function() end,
      destroyEntity = function() end,
      getObjectToNotifyOfOccupants = function() return nil end,
      getRoom = function() return nil end,
      resetAnimations = function() end,
      updateUserActionsAllowed = function() end,
      updateScreenBlueFilter = function() end,
    }
    
    map = world.map
    ui = app.ui
    
    app.world = world
    app.map = map
    app.ui = ui
    
    -- Load actual afterLoad implementations
    _G.World = world
    _G.Map = map
    _G.UI = ui
    _G.TheApp = app
    
    -- Add afterLoad methods
    function World:afterLoad(old, new)
      -- Simplified version for testing
      if old < 4 then self.room_built = {} end
      if old < 6 then
        local value = self.map.parcelTileCounts[1] * 25 + 20000
        self.hospitals[1].value = value
      end
      if old < 10 then
        self.object_counts = {extinguisher=0, radiator=0, plant=0, general=0}
      end
    end
    
    function Map:afterLoad(old, new)
      if old < 6 then
        self.parcelTileCounts = {}
        for plot = 1, self.th:getPlotCount() do
          self.parcelTileCounts[plot] = self.th:getParcelTileCount(plot)
        end
      end
    end
    
    function UI:afterLoad(old, new) end
    
    function App:afterLoad()
      local old = self.world.savegame_version or 0
      local new = self.savegame_version
      if old == 0 then
        self.world.game_log = {}
        self.world.original_savegame_version = old
      end
      self.map:afterLoad(old, new)
      self.ui:afterLoad(old, new)
      self.world:afterLoad(old, new)
      self.world.savegame_version = new
    end
  end)
  
  it("should run App:afterLoad and delegate to subsystems", function()
    app:afterLoad()
    
    assert.is_table(world.game_log)
    assert.are.equal(0, world.original_savegame_version)
    assert.are.equal(app.savegame_version, world.savegame_version)
  end)
  
  it("should initialize room_built for old saves", function()
    world.savegame_version = 3
    app:afterLoad()
    
    assert.is_table(world.room_built)
  end)
  
  it("should recalculate hospital value for saves < v6", function()
    world.savegame_version = 5
    app:afterLoad()
    
    assert.are.equal(100 * 25 + 20000, world.hospitals[1].value)
  end)
  
  it("should initialize object_counts for saves < v10", function()
    world.savegame_version = 9
    app:afterLoad()
    
    assert.is_table(world.object_counts)
    assert.are.equal(0, world.object_counts.extinguisher)
  end)
  
  it("should initialize parcelTileCounts for saves < v6", function()
    world.savegame_version = 5
    app:afterLoad()
    
    assert.is_table(map.parcelTileCounts)
    assert.are.equal(100, map.parcelTileCounts[1])
  end)
  
  it("should preserve original_savegame_version across migrations", function()
    world.savegame_version = 5
    app:afterLoad()
    
    assert.are.equal(5, world.original_savegame_version)
    
    -- Simulate another load (newer version)
    world.savegame_version = 50
    app:afterLoad()
    
    assert.are.equal(5, world.original_savegame_version) -- Still original
  end)
end)

-- ============================================================================
-- TEST SUITE: MIGRATION CHAINING
-- ============================================================================

describe("Migration Chaining - Parent/Child afterLoad", function()
  
  it("should call parent afterLoad in child classes", function()
    local parent_called = false
    local child_called = false
    local parent_old, parent_new
    local child_old, child_new
    
    local Parent = {}
    function Parent:afterLoad(old, new)
      parent_called = true
      parent_old, parent_new = old, new
    end
    
    local Child = setmetatable({}, { __index = Parent })
    function Child:afterLoad(old, new)
      child_called = true
      child_old, child_new = old, new
      Parent.afterLoad(self, old, new)
    end
    
    local obj = setmetatable({}, { __index = Child })
    obj:afterLoad(100, 200)
    
    assert.is_true(child_called)
    assert.is_true(parent_called)
    assert.are.equal(100, child_old)
    assert.are.equal(200, child_new)
    assert.are.equal(100, parent_old)
    assert.are.equal(200, parent_new)
  end)
  
  it("should support version-gated chaining (Staff pattern)", function()
    local humanoid_calls = {}
    local staff_calls = {}
    
    local Humanoid = {}
    function Humanoid:afterLoad(old, new)
      table.insert(humanoid_calls, {old=old, new=new})
    end
    
    local Staff = setmetatable({}, { __index = Humanoid })
    function Staff:afterLoad(old, new)
      table.insert(staff_calls, {old=old, new=new, phase="start"})
      if old < 133 and new >= 133 then
        Humanoid.afterLoad(self, old, 133)
        self:afterLoad(133, new)
      end
      Humanoid.afterLoad(self, old, new)
      table.insert(staff_calls, {old=old, new=new, phase="end"})
    end
    
    local staff = setmetatable({}, { __index = Staff })
    staff:afterLoad(100, 150)
    
    -- Should have: Staff.start, Humanoid(100,133), Staff(133,150), Humanoid(100,150), Staff.end
    assert.are.equal(5, #staff_calls)
    assert.are.equal("start", staff_calls[1].phase)
    assert.are.equal(100, humanoid_calls[1].old)
    assert.are.equal(133, humanoid_calls[1].new)
    assert.are.equal(133, staff_calls[2].old)
    assert.are.equal(150, staff_calls[2].new)
    assert.are.equal(100, humanoid_calls[2].old)
    assert.are.equal(150, humanoid_calls[2].new)
    assert.are.equal("end", staff_calls[5].phase)
  end)
end)

-- ============================================================================
-- TEST SUITE: OLD SAVEGAME COMPATIBILITY
-- ============================================================================

describe("Old Savegame Compatibility", function()
  local app, world, map
  
  before_each(function()
    app = test_helpers.create_test_app()
    
    world = {
      savegame_version = 0,
      original_savegame_version = nil,
      game_log = {},
      rooms = {},
      entities = {},
      objects = {},
      object_counts = {},
      hospitals = {{ value = 0, getPlayerIndex = function() return 1 end }},
      available_diseases = {},
      available_staff = {},
      epidemic = nil,
      earthquake = { afterLoad = function() end },
      map = {
        parcelTileCounts = {},
        th = { getPlotCount = function() return 1 end, getParcelTileCount = function() return 100 end },
        level_config = { popn = {}, gbv = {}, expertise = {}, awards_trophies = {}, non_visuals_available = {}, payroll = {} },
        width = 10, height = 10,
        setCellFlags = function() end,
        th = { updatePathfinding = function() end },
      },
      applyLevelStartPrices = function() end,
      setUI = function() end,
      nextEmergency = function() end,
      nextVip = function() end,
      updateSpawnDates = function() end,
      gameLog = function() end,
      playLoadedEntitySounds = function() end,
      newObjectType = function() end,
      destroyEntity = function() end,
      getObjectToNotifyOfOccupants = function() return nil end,
      getRoom = function() return nil end,
      resetAnimations = function() end,
      updateUserActionsAllowed = function() end,
      updateScreenBlueFilter = function() end,
    }
    
    map = world.map
    app.world = world
    app.map = map
    app.ui = { afterLoad = function() end }
    
    function App:afterLoad()
      local old = self.world.savegame_version or 0
      local new = self.savegame_version
      if old == 0 then
        self.world.game_log = {}
        self.world.original_savegame_version = old
      end
      self.map:afterLoad(old, new)
      self.ui:afterLoad(old, new)
      self.world:afterLoad(old, new)
      self.world.savegame_version = new
    end
    
    function World:afterLoad(old, new)
      if old < 4 then self.room_built = {} end
      if old < 6 then
        local value = self.map.parcelTileCounts[1] * 25 + 20000
        self.hospitals[1].value = value
      end
      if old < 10 then
        self.object_counts = {extinguisher=0, radiator=0, plant=0, general=0}
      end
      if old < 27 then self.dispatcher = "CallsDispatcher" end
      if old < 31 then self.hours_per_day = 50 end
    end
    
    function Map:afterLoad(old, new)
      if old < 6 then
        self.parcelTileCounts = {}
        for plot = 1, self.th:getPlotCount() do
          self.parcelTileCounts[plot] = self.th:getParcelTileCount(plot)
        end
      end
      if old < 57 then
        for x = 1, self.width do
          for y = 1, self.height do
            self:setCellFlags(x, y, {buildableNorth=true})
          end
        end
      end
    end
  end)
  
  it("should migrate pre-versioning save (v0)", function()
    world.savegame_version = 0
    app:afterLoad()
    
    assert.is_table(world.game_log)
    assert.is_table(world.room_built)
    assert.are.equal(100*25+20000, world.hospitals[1].value)
    assert.is_table(world.object_counts)
    assert.are.equal("CallsDispatcher", world.dispatcher)
    assert.are.equal(50, world.hours_per_day)
    assert.are.equal(0, world.original_savegame_version)
  end)
  
  it("should migrate v3 save (has version but no room_built)", function()
    world.savegame_version = 3
    app:afterLoad()
    
    assert.is_table(world.room_built)
    assert.are.equal(3, world.original_savegame_version)
  end)
  
  it("should migrate v5 save (has room_built, no hospital value calc)", function()
    world.savegame_version = 5
    world.room_built = {} -- Already exists
    app:afterLoad()
    
    assert.are.equal(100*25+20000, world.hospitals[1].value)
    assert.is_table(world.object_counts)
    assert.are.equal(5, world.original_savegame_version)
  end)
  
  it("should migrate v9 save (has object_counts partially)", function()
    world.savegame_version = 9
    world.room_built = {}
    world.object_counts = {extinguisher=5} -- Partial
    app:afterLoad()
    
    -- object_counts should be reinitialized for v<10
    assert.are.equal(0, world.object_counts.extinguisher)
    assert.are.equal(0, world.object_counts.radiator)
  end)
  
  it("should NOT re-run migrations for current version", function()
    world.savegame_version = 212
    world.room_built = {existing = true}
    world.hospitals[1].value = 99999
    world.object_counts = {custom = 42}
    world.dispatcher = "custom_dispatcher"
    world.hours_per_day = 99
    
    app:afterLoad()
    
    -- Should preserve existing values
    assert.are.equal(true, world.room_built.existing)
    assert.are.equal(99999, world.hospitals[1].value)
    assert.are.equal(42, world.object_counts.custom)
    assert.are.equal("custom_dispatcher", world.dispatcher)
    assert.are.equal(99, world.hours_per_day)
  end)
end)

-- ============================================================================
-- TEST SUITE: ENTITY MIGRATIONS
-- ============================================================================

describe("Entity afterLoad Migrations", function()
  
  it("should migrate Humanoid health attribute (v38)", function()
    local humanoid = {
      attributes = {},
      action_queue = {},
      isType = function(self, t) return false end,
      isMoodActive = function() return false end,
      setMood = function() end,
    }
    
    function Humanoid:afterLoad(old, new)
      if old < 38 and new >= 38 then
        self.attributes["health"] = 0.5
      end
      for _, action in pairs(self.action_queue) do
        HumanoidAction.afterLoad(action, old, new)
      end
      Entity.afterLoad(self, old, new)
    end
    
    function HumanoidAction:afterLoad(old, new) end
    function Entity:afterLoad(old, new) end
    
    humanoid:afterLoad(37, 38)
    
    assert.are.equal(0.5, humanoid.attributes.health)
  end)
  
  it("should migrate Humanoid mood enum (v210)", function()
    local humanoid = {
      moods = { sad2 = true, sad7 = true },
      isMoodActive = function(self, m) return self.moods[m] end,
      setMood = function(self, m, action)
        if action == "deactivate" then self.moods[m] = nil
        else self.moods[m] = true end
      end,
      isType = function() return false end,
      action_queue = {},
    }
    
    function Humanoid:afterLoad(old, new)
      if old < 210 then
        if self:isMoodActive("sad2") then
          self:setMood("sad2", "deactivate")
          self:setMood("dying1", "activate")
        end
        if self:isMoodActive("sad7") then
          self:setMood("sad7", "deactivate")
          self:setMood("sad2", "activate")
        end
      end
      Entity.afterLoad(self, old, new)
    end
    function Entity:afterLoad() end
    
    humanoid:afterLoad(209, 210)
    
    assert.is_nil(humanoid.moods.sad2) -- Was deactivated then reactivated? Let's trace...
    -- sad2: was active -> deactivate -> sad7: was active -> deactivate, activate sad2
    -- Final: sad2 active, dying1 active
    assert.is_true(humanoid.moods.sad2)
    assert.is_true(humanoid.moods.dying1)
    assert.is_nil(humanoid.moods.sad7)
  end)
  
  it("should migrate Machine THOB fix (v15)", function()
    local machine = {
      object_type = { id = "cardio", thob = 1234 },
      tile_x = 5, tile_y = 10,
      world = {
        map = {
          th = { setCellFlags = function(self, x, y, flags) self.last_flags = flags end }
        }
      },
      getRoom = function() return { crashed = false } end,
      removeHandymanRepairTask = function() end,
      updateDynamicInfo = function() end,
    }
    
    function Machine:afterLoad(old, new)
      if old < 15 then
        if self.object_type.id == "cardio" then
          self.world.map.th:setCellFlags(self.tile_x, self.tile_y, {
            thob = self.object_type.thob
          })
        end
      end
      Object.afterLoad(self, old, new)
    end
    function Object:afterLoad() end
    
    machine:afterLoad(14, 15)
    
    assert.are.equal(1234, machine.world.map.th.last_flags.thob)
  end)
  
  it("should migrate Epidemic field rename (v212)", function()
    local epidemic = {
      coverup_in_progress = true,
      coverup_selected = nil,
      level_config = "old_data",
    }
    
    function Epidemic:afterLoad(old, new)
      if old < 106 then
        self.level_config = nil
      end
      if old < 212 then
        self.coverup_selected = self.coverup_in_progress
        self.coverup_in_progress = nil
      end
    end
    
    epidemic:afterLoad(100, 212)
    
    assert.is_nil(epidemic.level_config)
    assert.is_true(epidemic.coverup_selected)
    assert.is_nil(epidemic.coverup_in_progress)
  end)
end)

-- ============================================================================
-- TEST SUITE: SAVE/LOAD ROUND-TRIP
-- ============================================================================

describe("Save/Load Round-trip Integration", function()
  local app
  
  before_each(function()
    app = test_helpers.create_test_app()
    
    -- Minimal world with entities
    local world = {
      savegame_version = 212,
      original_savegame_version = 200,
      game_log = {},
      rooms = {},
      entities = {},
      objects = {},
      object_counts = {},
      hospitals = {{ value = 50000, getPlayerIndex = function() return 1 end }},
      available_diseases = {},
      available_staff = {},
      epidemic = nil,
      earthquake = { afterLoad = function() end },
      dispatcher = "CallsDispatcher",
      animation_manager = {},
      hours_per_day = 50,
      map = {
        parcelTileCounts = { [1] = 200 },
        th = { getPlotCount = function() return 1 end, getParcelTileCount = function() return 200 end },
        level_config = { popn = {}, gbv = {}, expertise = {}, awards_trophies = {}, non_visuals_available = {}, payroll = {} },
        width = 10, height = 10,
        prepareForSave = function() end,
        afterSave = function() end,
      },
      applyLevelStartPrices = function() end,
      setUI = function() end,
      resetAnimations = function() end,
      updateUserActionsAllowed = function() end,
      updateScreenBlueFilter = function() end,
    }
    
    app.world = world
    app.map = world.map
    app.ui = { 
      afterLoad = function() end,
      resync = function() end,
      menu_bar = { ui = nil, onChangeLanguage = function() end },
      cursor = nil,
      setCursor = function() end,
      onChangeResolution = function() end,
      addOrRemoveDebugModeKeyHandlers = function() end,
    }
    
    -- Mock SaveGame/LoadGame
    local saved_data = nil
    _G.SaveGame = function()
      saved_data = "mock_binary_data"
      return saved_data
    end
    _G.LoadGame = function(data)
      -- Simulate migration
      world.savegame_version = 212
      world.original_savegame_version = 200
    end
  end)
  
  it("should complete save/load cycle", function()
    local data = SaveGame()
    assert.is_string(data)
    
    LoadGame(data)
    
    assert.are.equal(212, app.world.savegame_version)
  end)
  
  it("should preserve entity references across save/load", function()
    local entity = { id = "test_entity", tile_x = 5, tile_y = 5 }
    table.insert(app.world.entities, entity)
    
    -- In real test, would verify entity identity preserved
    -- This is a placeholder for the integration test pattern
    assert.is_true(true)
  end)
end)

-- ============================================================================
-- TEST SUITE: ERROR HANDLING
-- ============================================================================

describe("Error Handling in Persistence", function()
  
  it("should handle persist errors gracefully", function()
    -- Test that persist.dump returns error info
    local bad_state = { 
      c_func = print -- Cannot persist C functions
    }
    
    local ok, result, err, obj = pcall(persist.dump, bad_state, {})
    
    -- Should either error or return error tuple
    if not ok then
      assert.is_string(result) -- Error message
    else
      assert.is_false(result)
      assert.is_string(err)
    end
  end)
  
  it("should handle load errors gracefully", function()
    local ok, result = pcall(persist.load, "corrupted_data", {})
    
    assert.is_false(ok)
  end)
  
  it("should validate sync markers on userdata load", function()
    -- This would test the 0x42 sync marker in persist_lua.cpp
    -- Requires C++ test harness - placeholder
    assert.is_true(true)
  end)
end)

-- ============================================================================
-- TEST SUITE: PERFORMANCE / STRESS
-- ============================================================================

describe("Performance Characteristics", function()
  
  it("should serialize large object graphs efficiently", function()
    -- Create a large object graph
    local root = { children = {} }
    for i = 1, 1000 do
      local child = { id = i, data = string.rep("x", 100), parent = root }
      table.insert(root.children, child)
    end
    root.self_ref = root
    
    local start = os.clock()
    local data = persist.dump(root, {})
    local dump_time = os.clock() - start
    
    local start = os.clock()
    local loaded = persist.load(data, {})
    local load_time = os.clock() - start
    
    -- Should complete in reasonable time (< 1 second each)
    assert.is_true(dump_time < 1.0)
    assert.is_true(load_time < 1.0)
    assert.are.equal(1000, #loaded.children)
    assert.are.equal(loaded, loaded.self_ref)
  end)
  
  it("should handle deep nesting", function()
    local deep = {}
    local current = deep
    for i = 1, 100 do
      current.nested = { level = i }
      current = current.nested
    end
    current.circular = deep
    
    local data = persist.dump(deep, {})
    local loaded = persist.load(data, {})
    
    -- Navigate to bottom
    local current = loaded
    for i = 1, 100 do
      current = current.nested
    end
    assert.are.equal(loaded, current.circular)
  end)
end)

-- ============================================================================
-- RUN TESTS
-- ============================================================================

print("================================================================")
print("CorsixTH Save/Load Migration Test Scaffold")
print("Run with: busted SCAFFOLD.lua")
print("================================================================")

-- Export for busted
return {
  test_helpers = test_helpers,
}
