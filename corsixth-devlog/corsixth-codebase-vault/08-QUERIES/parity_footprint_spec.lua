-- V0 pilot: verify hand-derived post-shift footprints against the REAL code.
-- Loads real object definitions + runs real Object.processTypeDefinition /
-- occupyTilesByObjectFootprintAt with a recording stub map. No mocks of the
-- logic under test; only environment stubs (world/map/_S/TheApp).

require("corsixth")
-- Mock TH binding BEFORE any require captures it (busted env has no C++ TH).
package.preload["TH"] = function()
  local function noop_anim()
    return setmetatable({}, {__index = function() return function() end end})
  end
  return {animation = noop_anim}
end

require("class_test_base")
require("utility")
require("entity")
require("entities.object")
require("entities.machine")
require("map")

-- Auto-vivifying strings stub (object files read _S.object.X / _S.tooltip...)
local function auto_table()
  return setmetatable({}, {__index = function(t, k)
    local v = auto_table()
    rawset(t, k, v)
    return v
  end})
end
_G._S = auto_table()
_G.TheApp = {animation_manager = {
  setPatientMarker = function() end,
  setStaffMarker = function() end,
  setAnimLength = function() end,
  getAnimLength = function() return 1 end,
}}

local function load_type(path)
  local chunk = assert(loadfile(path))
  return chunk()
end

local function recording_map()
  local calls = {}
  local th = {}
  function th:setCellFlags(x, y, flags)
    table.insert(calls, {x = x, y = y, flags = flags})
  end
  function th:getCellFlags()
    return {}
  end
  return {th = th, calls = calls}
end

local function stub_world(map)
  local hospital = {}
  local world = {
    map = map,
    addObjectToTile = function() end,
    clearCaches = function() end,
    getRoom = function() return nil end,
    getLocalPlayerHospital = function() return hospital end,
    pathfinder = {isReachableFromHospital = function() return true end},
  }
  hospital.world = world
  _G["Hospital"] = hospital
  return world, hospital
end

local function flags_for(calls, x, y)
  local out = {}
  for _, c in ipairs(calls) do
    if c.x == x and c.y == y then
      for k, v in pairs(c.flags) do out[k] = v end
    end
  end
  return out
end

describe("V0 parity: slicer thob 26 post-shift footprint", function()
  local slicer = load_type("../Lua/objects/machines/slicer.lua")
  Object.processTypeDefinition(slicer)

  it("north: use shifts {0,0}->{1,0}, nearest solid (-1,0), dirs {[3]}", function()
    local n = slicer.orientations.north
    assert.are.same({1, 0}, n.use_position)
    assert.are.same({0, -1}, n.use_position_secondary)
    assert.are.same({1, -1}, n.handyman_position) -- NOT shifted by processTypeDefinition
    assert.are.same({1, 0}, n.smoke_position)
    assert.are.same({[3] = true}, n.pathfind_allowed_dirs)
  end)

  it("north: footprint recentered +1 x", function()
    local n = slicer.orientations.north
    assert.are.same({0, -1, only_passable = true}, n.footprint[1])
    assert.are.same({0, 0}, n.footprint[2])
    assert.are.same({0, 1}, n.footprint[3])
    assert.are.same({1, -1, only_passable = true}, n.footprint[4])
  end)

  it("east: use shifts {0,0}->{0,1}, nearest solid (0,-1), dirs {[0]}", function()
    local e = slicer.orientations.east
    assert.are.same({0, 1}, e.use_position)
    assert.are.same({-1, 0}, e.use_position_secondary)
    assert.are.same({-1, 1}, e.handyman_position) -- NOT shifted by processTypeDefinition
    assert.are.same({0, 1}, e.smoke_position)
    assert.are.same({[0] = true}, e.pathfind_allowed_dirs)
  end)

  it("occupyTiles marks buildable=false everywhere, passable only on passable tiles", function()
    local map = recording_map()
    local world, hospital = stub_world(map)
    Object(hospital, slicer, 10, 10, "north")
    -- post-shift passable tiles relative: (0,-1),(1,-1),(1,0),(1,1)
    for _, rel in ipairs({{0, -1}, {1, -1}, {1, 0}, {1, 1}}) do
      local f = flags_for(map.calls, 10 + rel[1], 10 + rel[2])
      assert.is_true(f.passable == true)
      assert.is_true(f.buildable == false)
    end
    -- solid tiles: passable must not be true
    for _, rel in ipairs({{0, 0}, {0, 1}}) do
      local f = flags_for(map.calls, 10 + rel[1], 10 + rel[2])
      assert.is_true(f.passable ~= true)
      assert.is_true(f.buildable == false)
    end
  end)
end)

describe("V0 parity: operating_table thob 30 post-shift + slave + asymmetry", function()
  local opt = load_type("../Lua/objects/machines/operating_table.lua")
  Object.processTypeDefinition(opt)

  it("north: use {-1,-2}->{0,-1}, dirs {[2]}, slave {1,-1}->{2,0}", function()
    local n = opt.orientations.north
    assert.are.same({0, -1}, n.use_position)
    assert.are.same({-1, 0}, n.use_position_secondary)
    assert.are.same({2, 0}, n.slave_position)
    assert.are.same({1, 1}, n.smoke_position)
    assert.are.same({1, 0}, n.render_attach_position)
    assert.are.same({[2] = true}, n.pathfind_allowed_dirs)
  end)

  it("east: use {-2,-1}-> {-1,0}, dirs {[1]}, slave {-1,1}->{0,2}", function()
    local e = opt.orientations.east
    assert.are.same({-1, 0}, e.use_position)
    assert.are.same({0, -1}, e.use_position_secondary)
    assert.are.same({0, 2}, e.slave_position)
    assert.are.same({1, 1}, e.smoke_position)
    assert.are.same({[1] = true}, e.pathfind_allowed_dirs)
  end)

  it("east has a bare solid {0,0} with no flags; north has no bare point", function()
    local e = opt.orientations.east
    local found_bare = false
    for _, p in ipairs(e.footprint) do
      if p[1] == 1 and p[2] == 1 then
        found_bare = true
        assert.is_nil(p.complete_cell)
        assert.is_nil(p.only_passable)
        assert.is_nil(p.need_north_side)
        assert.is_nil(p.need_south_side)
        assert.is_nil(p.need_east_side)
        assert.is_nil(p.need_west_side)
      end
    end
    assert.is_true(found_bare)
    local n = opt.orientations.north
    for _, p in ipairs(n.footprint) do
      assert.is_true(p.complete_cell or p.only_passable or
        p.need_north_side or p.need_south_side or
        p.need_east_side or p.need_west_side)
    end
  end)
end)
