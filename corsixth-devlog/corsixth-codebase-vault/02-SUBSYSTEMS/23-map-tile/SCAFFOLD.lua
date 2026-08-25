--[[ Map/Tile System Test Scaffolding
     Area 23 - Map/Tile System
     Busted test template for map mock helpers.
     Test cases for: tile flags, room detection, parcel pricing, camera, temperature.
]]

local busted = require("busted")
local describe = busted.describe
local it = busted.it
local before_each = busted.before_each
local after_each = busted.after_each
local setup = busted.setup
local teardown = busted.teardown
local assert = require("luassert")
local spy = require("luassert.spy")
local mock = require("luassert.mock")

-- Mock TH module
local TH = {}
TH.map = function()
  local map = {}
  map.getCellFlags = function(x, y, cache) return cache or {} end
  map.getRoomId = function(x, y) return 0 end
  map.setPlayerCount = function(count) end
  map.getPlayerCount = function() return 1 end
  map.setCameraTile = function(x, y, player) end
  map.getCameraTile = function(player) return 63, 63 end
  map.setHeliportTile = function(x, y, player) end
  map.getHeliportTile = function(player) return 0, 0 end
  map.setTemperatureDisplay = function(method) end
  map.getTemperatureDisplay = function() return 1 end
  map.size = function() return 128, 128 end
  map.getPlotCount = function() return 4 end
  map.getParcelTileCount = function(plot) return 100 end
  map.setPlotOwner = function(plot, owner) return {} end
  map.updatePathfinding = function() end
  map.save = function(filename) end
  map.load = function(data) return {}, nil end
  map.loadBlank = function() return {}, nil end
  map.setSheet = function(blocks) end
  map.setCellFlags = function(x, y, flags) end
  map.getCell = function(x, y) return 0, 0, 0 end
  map.getCellTemperature = function(x, y) return 8192 end
  map.getCellRaw = function(x, y) return string.rep("\0", 8) end
  map.draw = function(canvas, sx, sy, sw, sh, dx, dy) end
  return map
end

-- Mock app
local function createMockApp()
  local app = {}
  app.config = {
    warmth_colors_display_default = 1,
  }
  app.getFullPath = function(paths) return "test_path" end
  app.readDataFile = function(dir, file) return nil, "not found" end
  app.fs = {
    readContents = function(dir, file) return nil end
  }
  return app
end

-- Mock world
local function createMockWorld()
  return {
    rooms = {},
    getObjects = function(x, y) return {} end,
  }
end

describe("Map/Tile System - Tile Flags", function()
  local Map, map, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    package.loaded["map"] = nil
    Map = require("map")
    map = Map(app)
  end)

  describe("getCellFlag", function()
    it("should return flag value for valid coordinates", function()
      local flag_cache = {}
      map.th.getCellFlags = function(x, y, cache)
        cache.passable = true
        cache.hospital = false
        cache.buildable = true
        cache.roomId = 0
        cache.parcelId = 1
        return cache
      end
      local result = map:getCellFlag(10, 10, "passable")
      assert.is_true(result)
    end)

    it("should return nil for unknown flag", function()
      map.th.getCellFlags = function(x, y, cache)
        return {}
      end
      local result = map:getCellFlag(10, 10, "nonexistent")
      assert.is_nil(result)
    end)

    it("should floor coordinates", function()
      local called_with = {}
      map.th.getCellFlags = function(x, y, cache)
        called_with.x, called_with.y = x, y
        return {}
      end
      map:getCellFlag(10.7, 10.3, "passable")
      assert.equal(10, called_with.x)
      assert.equal(10, called_with.y)
    end)
  end)

  describe("getRoomId", function()
    it("should return room ID for valid coordinates", function()
      map.th.getRoomId = function(x, y) return 5 end
      local result = map:getRoomId(10, 10)
      assert.equal(5, result)
    end)

    it("should floor coordinates", function()
      local called_with = {}
      map.th.getRoomId = function(x, y)
        called_with.x, called_with.y = x, y
        return 0
      end
      map:getRoomId(10.9, 10.1)
      assert.equal(10, called_with.x)
      assert.equal(10, called_with.y)
    end)
  end)

  describe("setCellFlags", function()
    it("should delegate to TH map", function()
      local spy_setCellFlags = spy.on(map.th, "setCellFlags")
      map:setCellFlags(10, 10, {passable = true})
      assert.spy(spy_setCellFlags).was_called_with(10, 10, {passable = true})
    end)
  end)
end)

describe("Map/Tile System - Room Detection", function()
  local Map, map, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    package.loaded["map"] = nil
    Map = require("map")
    map = Map(app)
  end)

  it("should detect room ID at tile", function()
    map.th.getRoomId = function(x, y) return 3 end
    assert.equal(3, map:getRoomId(5, 5))
  end)

  it("should return 0 for corridor/outside", function()
    map.th.getRoomId = function(x, y) return 0 end
    assert.equal(0, map:getRoomId(1, 1))
  end)

  it("should handle room boundaries correctly", function()
    local room_ids = {}
    map.th.getRoomId = function(x, y)
      return room_ids[y] and room_ids[y][x] or 0
    end
    room_ids[10] = {[10] = 1, [11] = 1, [12] = 2}
    assert.equal(1, map:getRoomId(10, 10))
    assert.equal(1, map:getRoomId(11, 10))
    assert.equal(2, map:getRoomId(12, 10))
    assert.equal(0, map:getRoomId(13, 10))
  end)
end)

describe("Map/Tile System - Parcel Pricing", function()
  local Map, map, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    package.loaded["map"] = nil
    Map = require("map")
    map = Map(app)
    map.level_config = {gbv = {LandCostPerTile = 50}}
    map.parcelTileCounts = {[1] = 100, [2] = 200, [3] = 50}
  end)

  describe("getParcelPrice", function()
    it("should calculate price based on tile count and LandCostPerTile", function()
      local price = map:getParcelPrice(1)
      assert.equal(5000, price) -- 100 tiles * 50
    end)

    it("should use default cost when config missing", function()
      map.level_config = nil
      local price = map:getParcelPrice(1)
      assert.equal(2500, price) -- 100 tiles * 25 (default)
    end)

    it("should return 0 for invalid parcel", function()
      local price = map:getParcelPrice(999)
      assert.equal(0, price)
    end)
  end)

  describe("getParcelTileCount", function()
    it("should return tile count for valid parcel", function()
      assert.equal(100, map:getParcelTileCount(1))
      assert.equal(200, map:getParcelTileCount(2))
    end)

    it("should return 0 for invalid parcel", function()
      assert.equal(0, map:getParcelTileCount(999))
    end)
  end)
end)

describe("Map/Tile System - Camera", function()
  local Map, map, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    package.loaded["map"] = nil
    Map = require("map")
    map = Map(app)
  end)

  describe("setCameraTile", function()
    it("should set camera position for player", function()
      local spy_setCamera = spy.on(map.th, "setCameraTile")
      map:setCameraTile(50, 50, 1)
      assert.spy(spy_setCamera).was_called_with(50, 50, 1)
    end)

    it("should accept player numbers 1-4", function()
      local spy_setCamera = spy.on(map.th, "setCameraTile")
      for p = 1, 4 do
        map:setCameraTile(10 * p, 10 * p, p)
        assert.spy(spy_setCamera).was_called_with(10 * p, 10 * p, p)
      end
    end)
  end)

  describe("setHeliportTile", function()
    it("should set heliport position for player", function()
      local spy_setHeliport = spy.on(map.th, "setHeliportTile")
      map:setHeliportTile(60, 60, 1)
      assert.spy(spy_setHeliport).was_called_with(60, 60, 1)
    end)
  end)
end)

describe("Map/Tile System - Temperature", function()
  local Map, map, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    package.loaded["map"] = nil
    Map = require("map")
    map = Map(app)
  end)

  describe("setTemperatureDisplayMethod", function()
    it("should accept valid method 1 (red gradients)", function()
      local spy_setTemp = spy.on(map.th, "setTemperatureDisplay")
      map:setTemperatureDisplayMethod(1)
      assert.equal(1, map.temperature_display_method)
      assert.spy(spy_setTemp).was_called_with(1)
    end)

    it("should accept valid method 2 (blue/green/red)", function()
      map:setTemperatureDisplayMethod(2)
      assert.equal(2, map.temperature_display_method)
    end)

    it("should accept valid method 3 (yellow/orange/red)", function()
      map:setTemperatureDisplayMethod(3)
      assert.equal(3, map.temperature_display_method)
    end)

    it("should default to method 1 for invalid input", function()
      map:setTemperatureDisplayMethod(99)
      assert.equal(1, map.temperature_display_method)
    end)

    it("should update app config", function()
      map:setTemperatureDisplayMethod(2)
      assert.equal(2, app.config.warmth_colors_display_default)
    end)
  end)

  describe("registerTemperatureDisplayMethod", function()
    it("should use stored method if available", function()
      map.temperature_display_method = 3
      local spy_setTemp = spy.on(map.th, "setTemperatureDisplay")
      map:registerTemperatureDisplayMethod()
      assert.spy(spy_setTemp).was_called_with(3)
    end)

    it("should fallback to config default if not stored", function()
      map.temperature_display_method = nil
      app.config.warmth_colors_display_default = 2
      local spy_setTemp = spy.on(map.th, "setTemperatureDisplay")
      map:registerTemperatureDisplayMethod()
      assert.spy(spy_setTemp).was_called_with(2)
    end)
  end)

  describe("Temperature Debug Overlays", function()
    before_each(function()
      map.width = 10
      map.height = 10
    end)

    it("should update heat overlay", function()
      map.th.getCellTemperature = function(x, y) return 16384 end -- 327.68 * 50 = 16384
      map:loadDebugText("heat")
      assert.is_table(map.debug_text)
      assert.equal("327.7", map.debug_text[0]) -- (16384 * 50) formatted
    end)

    it("should update parcel overlay", function()
      map.th.getCellFlags = function(x, y, cache)
        cache.parcelId = 2
        return cache
      end
      map:loadDebugText("parcel")
      assert.is_table(map.debug_text)
      assert.equal("2", map.debug_text[0])
    end)

    it("should update camera overlay", function()
      map.th.getPlayerCount = function() return 2 end
      map.th.getCameraTile = function(p)
        if p == 1 then return 5, 5 end
        if p == 2 then return 8, 8 end
      end
      map:loadDebugText("camera")
      assert.is_table(map.debug_text)
      assert.equal("C1", map.debug_text[(5-1)*10 + 5 - 1])
      assert.equal("C2", map.debug_text[(8-1)*10 + 8 - 1])
    end)

    it("should update heliport overlay", function()
      map.th.getPlayerCount = function() return 1 end
      map.th.getHeliportTile = function(p) return 10, 10 end
      map:loadDebugText("heliport")
      assert.is_table(map.debug_text)
      assert.equal("H1", map.debug_text[(10-1)*10 + 10 - 1])
    end)

    it("should update flags overlay", function()
      map.th.getCellFlags = function(x, y, cache)
        cache.passable = true
        cache.hospital = true
        return cache
      end
      map:loadDebugText("flags")
      assert.is_table(map.debug_flags)
      assert.is_true(map.debug_flags[0].passable)
      assert.is_true(map.debug_flags[0].hospital)
    end)
  end)
end)

describe("Map/Tile System - Coordinate Conversion", function()
  local Map, map, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    package.loaded["map"] = nil
    Map = require("map")
    map = Map(app)
    map.width = 128
    map.height = 128
  end)

  describe("WorldToScreen", function()
    it("should convert world to screen coordinates", function()
      local sx, sy = map:WorldToScreen(1, 1)
      assert.equal(0, sx)
      assert.equal(0, sy)
    end)

    it("should handle offset coordinates", function()
      local sx, sy = map:WorldToScreen(2, 1)
      assert.equal(32, sx)
      assert.equal(16, sy)
    end)

    it("should handle diagonal", function()
      local sx, sy = map:WorldToScreen(2, 2)
      assert.equal(0, sx)
      assert.equal(32, sy)
    end)
  end)

  describe("ScreenToWorld", function()
    it("should convert screen to world coordinates", function()
      local wx, wy = map:ScreenToWorld(0, 0)
      assert.equal(1, wx)
      assert.equal(1, wy)
    end)

    it("should clamp to map bounds", function()
      local wx, wy = map:ScreenToWorld(-1000, -1000)
      assert.equal(1, wx)
      assert.equal(1, wy)
    end)

    it("should clamp to max bounds", function()
      local wx, wy = map:ScreenToWorld(10000, 10000)
      assert.equal(128, wx)
      assert.equal(128, wy)
    end)

    it("should be inverse of WorldToScreen", function()
      local wx, wy = 50, 30
      local sx, sy = map:WorldToScreen(wx, wy)
      local wx2, wy2 = map:ScreenToWorld(sx, sy)
      assert.equal(math.floor(wx), math.floor(wx2))
      assert.equal(math.floor(wy), math.floor(wy2))
    end)
  end)
end)

describe("Map/Tile System - Plot Ownership", function()
  local Map, map, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    world.rooms = {}
    package.loaded["map"] = nil
    Map = require("map")
    map = Map(app)
    map.width = 10
    map.height = 10
    map.th.getPlotCount = function() return 3 end
    map.th.getParcelTileCount = function(p) return 20 end
    map.th.getCell = function(x, y) return 0, 0, 0 end
    map.th.getCellFlags = function(x, y)
      return {roomId = 0, parcelId = 1}
    end
    map.th.setPlotOwner = function(plot, owner)
      return {{5, 5}}
    end
    map.th.updatePathfinding = function() end
  end)

  it("should set plot owner", function()
    map:setPlotOwner(1, 1)
    assert.equal(1, map.parcelTileCounts[1])
  end)

  it("should add walls between different parcel owners", function()
    local room = {room_info = {wall_type = 1}}
    world.rooms[1] = room
    map.th.getCellFlags = function(x, y)
      if x == 5 and y == 5 then return {roomId = 1, parcelId = 1} end
      if x == 5 and y == 4 then return {roomId = 0, parcelId = 2} end
      return {roomId = 0, parcelId = 0}
    end
    map.app.walls = {
      [1] = {
        inside_tiles = {north = 100},
        outside_tiles = {north = 200}
      }
    }
    map:setPlotOwner(1, 1)
  end)

  it("should update pathfinding after ownership change", function()
    local spy_update = spy.on(map.th, "updatePathfinding")
    map:setPlotOwner(1, 1)
    assert.spy(spy_update).was_called()
  end)
end)

describe("Map/Tile System - Map Loading", function()
  local Map, map, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    package.loaded["map"] = nil
    Map = require("map")
    map = Map(app)
  end)

  it("should load original campaign level", function()
    map.th.load = function(data) return {}, nil end
    app.readDataFile = function(dir, file)
      return string.rep("\0", 163948), nil
    end
    local objects, err = map:load(1, "full", "Level 1", nil, nil, false)
    assert.is_nil(err)
    assert.is_table(objects)
  end)

  it("should load custom level", function()
    map.th.load = function(data) return {}, nil end
    app.readDataFile = function(dir, file)
      return string.rep("\0", 163948), nil
    end
    app.fs.readContents = function(dir, file) return "" end
    local objects, err = map:load("custom", "full", "Custom", "mapfile", "intro", false)
    assert.is_nil(err)
  end)

  it("should load blank map for editor", function()
    map.th.loadBlank = function() return {}, nil end
    local objects, err = map:load("", nil, nil, nil, nil, true)
    assert.is_nil(err)
    assert.equal("MAP EDITOR", map.level_name)
  end)
end)

describe("Map/Tile System - Debug Text", function()
  local Map, map, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    package.loaded["map"] = nil
    Map = require("map")
    map = Map(app)
    map.width = 5
    map.height = 5
  end)

  it("should set debug text for specific tile", function()
    map:setDebugText(2, 3, "TEST")
    assert.equal("TEST", map.debug_text[(3-1)*5 + 2 - 1])
  end)

  it("should handle multiple arguments", function()
    map:setDebugText(1, 1, "A", "B", "C")
    assert.equal("A,B,C", map.debug_text[0])
  end)

  it("should store nil for zero value", function()
    map:setDebugText(1, 1, 0)
    assert.is_nil(map.debug_text[0])
  end)

  it("should clear debug text", function()
    map.debug_text = {"test"}
    map:clearDebugText()
    assert.is_false(map.debug_text)
  end)
end)

describe("Map/Tile System - Save/Load Persistence", function()
  local Map, map, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    package.loaded["map"] = nil
    Map = require("map")
    map = Map(app)
    map.debug_text = {"debug"}
    map.debug_flags = {"flags"}
    map.updateDebugOverlay = function() end
    map.thData = "data"
  end)

  it("should prepare for save by clearing debug data", function()
    map:prepareForSave()
    assert.is_false(map.debug_text)
    assert.is_false(map.debug_flags)
    assert.is_nil(map.updateDebugOverlay)
    assert.is_nil(map.thData)
  end)

  it("should restore debug data after save", function()
    map:prepareForSave()
    map:afterSave()
    assert.equal("debug", map.debug_text[1])
    assert.equal("flags", map.debug_flags[1])
    assert.is_function(map.updateDebugOverlay)
    assert.equal("data", map.thData)
  end)
end)

describe("Map/Tile System - _fixTiles", function()
  local Map, map, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    package.loaded["map"] = nil
    Map = require("map")
    map = Map(app)
    map.width = 10
    map.height = 10
    map.level_number = 6
  end)

  it("should fix outdoor tiles for original campaign", function()
    map.map_file = nil
    map.th.getCell = function(x, y, layer)
      if x == 5 and y == 5 and layer == 1 then return 99 end -- invalid tile
      return 17 -- valid indoor tile
    end
    map.th.getCellFlags = function(x, y, cache)
      cache.hospital = true
      cache.passable = true
      cache.buildable = true
      return cache
    end
    map._fixTiles()
  end)

  it("should fix level 6 specific flags", function()
    map.level_number = 6
    local spy_setCellFlags = spy.on(map, "setCellFlags")
    map._fixTiles()
    assert.spy(spy_setCellFlags).was_called_with(56, 71, {
      hospital = true, buildable = true,
      buildableNorth = true, buildableSouth = true,
      buildableEast = true, buildableWest = true
    })
    assert.spy(spy_setCellFlags).was_called_with(58, 72, {passable = false})
  end)
end)

describe("Map/Tile System - afterLoad Migration", function()
  local Map, map, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    package.loaded["map"] = nil
    Map = require("map")
    map = Map(app)
    map.th.getPlotCount = function() return 2 end
    map.th.getParcelTileCount = function(p) return 50 end
    map.level_config = {
      expertise = {},
      gbv = {},
      awards_trophies = {},
    }
  end)

  it("should migrate parcel tile counts for old saves", function()
    map:afterLoad(5, 6)
    assert.equal(50, map.parcelTileCounts[1])
    assert.equal(50, map.parcelTileCounts[2])
  end)

  it("should set default difficulty for old saves", function()
    map:afterLoad(17, 18)
    assert.equal("full", map.difficulty)
  end)

  it("should fix expertise values for old saves", function()
    map:afterLoad(43, 44)
    assert.equal(700, map.level_config.expertise[1].MaxDiagDiff)
  end)

  it("should set buildable flags for all tiles for old saves", function()
    map.width = 3
    map.height = 3
    local spy_setCellFlags = spy.on(map, "setCellFlags")
    map:afterLoad(56, 57)
    assert.spy(spy_setCellFlags).was_called(9)
  end)

  it("should update pathfinding for old saves", function()
    local spy_update = spy.on(map.th, "updatePathfinding")
    map:afterLoad(119, 120)
    assert.spy(spy_update).was_called()
  end)
end)

describe("Map/Tile System - EntityMap Integration", function()
  local EntityMap, entityMap, mockMap

  before_each(function()
    mockMap = {
      th = {
        size = function() return 10, 10 end
      }
    }
    package.loaded["entity_map"] = nil
    EntityMap = require("entity_map")
    entityMap = EntityMap(mockMap)
  end)

  it("should create entity map with correct dimensions", function()
    assert.equal(10, entityMap.width)
    assert.equal(10, entityMap.height)
  end)

  it("should add humanoid to coordinate", function()
    local humanoid = {id = 1}
    package.loaded["class"] = {is = function(e, t) return t == "Humanoid" end}
    package.loaded["Humanoid"] = "Humanoid"
    entityMap:addEntity(5, 5, humanoid)
    assert.equal(1, #entityMap:getHumanoidsAtCoordinate(5, 5))
  end)

  it("should add object to coordinate", function()
    local object = {id = 1}
    package.loaded["class"] = {is = function(e, t) return t == "Object" end}
    package.loaded["Object"] = "Object"
    entityMap:addEntity(5, 5, object)
    assert.equal(1, #entityMap:getObjectsAtCoordinate(5, 5))
  end)

  it("should remove entity from coordinate", function()
    local humanoid = {id = 1}
    package.loaded["class"] = {is = function(e, t) return t == "Humanoid" end}
    entityMap:addEntity(5, 5, humanoid)
    entityMap:removeEntity(5, 5, humanoid)
    assert.equal(0, #entityMap:getHumanoidsAtCoordinate(5, 5))
  end)

  it("should get adjacent squares", function()
    local adj = entityMap:getAdjacentSquares(5, 5)
    assert.equal(4, #adj)
  end)

  it("should get adjacent free tiles", function()
    entityMap.entity_map[4][5].objects = {{id = 1}}
    local free = entityMap:getAdjacentFreeTiles(5, 5)
    assert.equal(3, #free)
  end)
end)

-- Integration test for Map + EntityMap
describe("Map/Tile System - Integration", function()
  local Map, EntityMap, map, entityMap, app, world

  before_each(function()
    app = createMockApp()
    world = createMockWorld()
    app.world = world
    package.loaded["map"] = nil
    package.loaded["entity_map"] = nil
    Map = require("map")
    EntityMap = require("entity_map")
    map = Map(app)
    map.width = 10
    map.height = 10
    entityMap = EntityMap(map)
  end)

  it("should have matching dimensions", function()
    assert.equal(map.width, entityMap.width)
    assert.equal(map.height, entityMap.height)
  end)

  it("should coordinate room detection with entity queries", function()
    map.th.getRoomId = function(x, y) return 1 end
    local roomId = map:getRoomId(5, 5)
    local humanoids = entityMap:getHumanoidsAtCoordinate(5, 5)
    assert.equal(1, roomId)
    assert.is_table(humanoids)
  end)
end)
