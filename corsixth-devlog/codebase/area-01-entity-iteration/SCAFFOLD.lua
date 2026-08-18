--[[
  CorsixTH Entity Iteration & Destruction Test Scaffold
  =====================================================
  
  Busted test template with helpers for testing entity iteration patterns.
  Copy this file and extend with your own test cases.
  
  Run with: busted SCAFFOLD.lua
]]

local class = require("class")
local World = require("world")
local Entity = require("entity")
local Humanoid = require("entities.humanoid")
local Plant = require("entities.plant")

-- ============================================================================
-- TEST HELPERS
-- ============================================================================

---Create a minimal entity for testing
---@param name string
---@param opts table|nil Optional overrides: {ticks=true, kind="humanoid", tick=fn, tickDay=fn, checkForDeadlock=fn, onDestroy=fn}
---@return table
local function makeEntity(name, opts)
  opts = opts or {}
  local entity = {
    name = name,
    ticks = opts.ticks ~= false,
    tick_count = 0,
    destroyed = false,
    to_destroy = false,
    kind = opts.kind,
  }
  
  function entity:tick()
    self.tick_count = self.tick_count + 1
    if opts.tick then opts.tick(self) end
  end
  
  function entity:tickDay()
    self.tick_count = self.tick_count + 1
    if opts.tickDay then opts.tickDay(self) end
  end
  
  function entity:checkForDeadlock()
    self.tick_count = self.tick_count + 1
    if opts.checkForDeadlock then opts.checkForDeadlock(self) end
  end
  
  function entity:onDestroy()
    self.destroyed = true
    if opts.onDestroy then opts.onDestroy(self) end
  end
  
  return entity
end

---Create a test world with entities
---@param entities table[] List of entities
---@return table
local function makeWorld(entities)
  local world = {
    entities = entities or {},
    entities_to_destroy = {},
    current_tick_entity = nil,
    app = { cheats = {} },
    map = { th = {} },
    dispatcher = { dropFromQueue = function() end },
    object_types = {},
    hospitals = {},
  }
  setmetatable(world, { __index = World })
  return world
end

---Simulate the main tick loop (World:onTick)
---@param world table
local function runTickLoop(world)
  for _, entity in ipairs(world.entities) do
    if entity.ticks and not entity.to_destroy then
      world.current_tick_entity = entity
      entity:tick()
    end
  end
  world.current_tick_entity = nil
  world:_flushDestroyedEntities()
end

---Simulate the end-of-day loop (World:onEndDay)
---@param world table
local function runTickDayLoop(world)
  for _, entity in ipairs(world.entities) do
    if entity.kind == "humanoid" and not entity.to_destroy then
      world.current_tick_entity = entity
      entity:tickDay()
    elseif entity.kind == "plant" and not entity.to_destroy then
      world.current_tick_entity = entity
      entity:tickDay()
    end
  end
  world.current_tick_entity = nil
  world:_flushDestroyedEntities()
end

---Simulate the deadlock check loop (World:onEndMonth)
---@param world table
local function runDeadlockLoop(world)
  for _, entity in ipairs(world.entities) do
    if entity.checkForDeadlock and not entity.to_destroy then
      world.current_tick_entity = entity
      entity:checkForDeadlock()
    end
  end
  world.current_tick_entity = nil
  world:_flushDestroyedEntities()
end

---Assert entity counts and order
---@param world table
---@param expected_names string[]
local function assertEntities(world, expected_names)
  assert.are.equal(#expected_names, #world.entities, "Entity count mismatch")
  for i, name in ipairs(expected_names) do
    assert.is.equal(name, world.entities[i].name, "Entity at index " .. i)
  end
end

---Assert tick counts
---@param entities table[]
---@param expected table<string, number>
local function assertTickCounts(entities, expected)
  for _, entity in ipairs(entities) do
    local exp = expected[entity.name] or 0
    assert.are.equal(exp, entity.tick_count, entity.name .. " tick count")
  end
end

---Assert destruction state
---@param entities table[]
---@param expected table<string, boolean>
local function assertDestroyed(entities, expected)
  for _, entity in ipairs(entities) do
    local exp = expected[entity.name] or false
    assert.are.equal(exp, entity.destroyed, entity.name .. " destroyed flag")
  end
end

-- ============================================================================
-- TEST SUITE
-- ============================================================================

describe("Entity Iteration & Destruction Scaffold", function()

  -- --------------------------------------------------------------------------
  -- BASIC DESTROY PATTERNS
  -- --------------------------------------------------------------------------
  
  it("immediate destroy outside loop removes entity", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local world = makeWorld({e1, e2})
    
    world:destroyEntity(e1)
    
    assertEntities(world, {"e2"})
    assert.is_true(e1.destroyed)
    assert.are.equal(0, #world.entities_to_destroy)
  end)
  
  it("deferred destroy during loop queues entity", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local e3 = makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    world.current_tick_entity = e2
    
    world:destroyEntity(e2)
    
    assert.are.equal(3, #world.entities)
    assert.are.equal(1, #world.entities_to_destroy)
    assert.is_true(e2.to_destroy)
    assert.is_true(e2.destroyed)
    
    world.current_tick_entity = nil
    world:_flushDestroyedEntities()
    
    assertEntities(world, {"e1", "e3"})
    assert.is_nil(e2.to_destroy)
  end)
  
  it("destroyEntity is idempotent", function()
    local e1 = makeEntity("e1")
    local world = makeWorld({e1})
    world.current_tick_entity = e1
    
    world:destroyEntity(e1)
    world:destroyEntity(e1)
    
    assert.are.equal(1, #world.entities_to_destroy)
  end)

  -- --------------------------------------------------------------------------
  -- ITERATION SAFETY (NO SKIPPING)
  -- --------------------------------------------------------------------------
  
  it("does not skip entities when earlier entity destroyed mid-loop", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local e3 = makeEntity("e3")
    local e4 = makeEntity("e4")
    local world = makeWorld({e1, e2, e3, e4})
    
    e2.tick = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e1)  -- Before current index
      world:destroyEntity(e4)  -- After current index
    end
    
    runTickLoop(world)
    
    assertTickCounts({e1, e2, e3, e4}, {e1=1, e2=1, e3=1, e4=0})
    assert.is_true(e4.destroyed)
    assertEntities(world, {"e2", "e3"})
  end)
  
  it("does not tick entity destroyed earlier in same loop", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local e3 = makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    
    e1.tick = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e3)
    end
    
    runTickLoop(world)
    
    assertTickCounts({e1, e2, e3}, {e1=1, e2=1, e3=0})
    assert.is_true(e3.destroyed)
    assertEntities(world, {"e1", "e2"})
  end)

  -- --------------------------------------------------------------------------
  -- SELF-DESTRUCTION
  -- --------------------------------------------------------------------------
  
  it("entity can destroy itself during tick", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local world = makeWorld({e1, e2})
    
    e1.tick = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(self)
    end
    
    runTickLoop(world)
    
    assertTickCounts({e1, e2}, {e1=1, e2=1})
    assert.is_true(e1.destroyed)
    assertEntities(world, {"e2"})
  end)

  -- --------------------------------------------------------------------------
  -- CASCADING DESTRUCTION
  -- --------------------------------------------------------------------------
  
  it("handles cascading destruction in onDestroy", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local e3 = makeEntity("e3")
    local e4 = makeEntity("e4")
    local world = makeWorld({e1, e2, e3, e4})
    
    e2.tick = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e3)
    end
    
    e3.onDestroy = function(self)
      self.destroyed = true
      world:destroyEntity(e4)  -- Cascade
    end
    
    runTickLoop(world)
    
    assertTickCounts({e1, e2, e3, e4}, {e1=1, e2=1, e3=0, e4=0})
    assert.is_true(e3.destroyed)
    assert.is_true(e4.destroyed)
    assertEntities(world, {"e1", "e2"})
  end)

  -- --------------------------------------------------------------------------
  -- ENTITIES ADDED DURING LOOP
  -- --------------------------------------------------------------------------
  
  it("ticks entities appended during loop (ipairs sees them)", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local e3 = makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    local e4 = makeEntity("e4")
    
    e2.tick = function(self)
      self.tick_count = self.tick_count + 1
      world.entities[#world.entities + 1] = e4
    end
    
    runTickLoop(world)
    
    assertTickCounts({e1, e2, e3, e4}, {e1=1, e2=1, e3=1, e4=1})
    assertEntities(world, {"e1", "e2", "e3", "e4"})
  end)

  -- --------------------------------------------------------------------------
  -- ERROR RECOVERY / INTERRUPTED LOOP
  -- --------------------------------------------------------------------------
  
  it("recovers when loop interrupted before flush (stale queue flushed next loop)", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local e3 = makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    
    world.current_tick_entity = e1
    world:destroyEntity(e2)  -- Queued
    
    -- Simulate error handler clearing current_tick_entity WITHOUT flush
    world.current_tick_entity = nil
    
    -- Next loop should flush stale queue
    runTickLoop(world)
    
    assertTickCounts({e1, e2, e3}, {e1=1, e2=0, e3=1})
    assert.is_true(e2.destroyed)
    assertEntities(world, {"e1", "e3"})
  end)

  -- --------------------------------------------------------------------------
  -- OLD SAVEGAME COMPATIBILITY
  -- --------------------------------------------------------------------------
  
  it("handles nil entities_to_destroy (old savegame)", function()
    local e1 = makeEntity("e1")
    local world = makeWorld({e1})
    world.entities_to_destroy = nil
    
    world:_flushDestroyedEntities()  -- Should not crash
    
    assertEntities(world, {"e1"})
    assert.is_nil(world.entities_to_destroy)
  end)
  
  it("lazily creates queue when destroying during loop on old savegame", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local world = makeWorld({e1, e2})
    world.entities_to_destroy = nil
    world.current_tick_entity = e1
    
    world:destroyEntity(e2)
    
    assert.is_true(e2.to_destroy)
    assert.are.equal(1, #world.entities_to_destroy)
    
    world.current_tick_entity = nil
    world:_flushDestroyedEntities()
    
    assertEntities(world, {"e1"})
    assert.are.equal(0, #world.entities_to_destroy)
  end)

  -- --------------------------------------------------------------------------
  -- STRAY ENTITIES (NOT IN WORLD)
  -- --------------------------------------------------------------------------
  
  it("destroys stray entity during loop without side effects", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local stray = makeEntity("stray")
    local world = makeWorld({e1, e2})
    world.current_tick_entity = e1
    
    world:destroyEntity(stray)
    
    assert.is_true(stray.destroyed)
    assert.is_true(stray.to_destroy)
    assert.are.equal(1, #world.entities_to_destroy)
    
    world.current_tick_entity = nil
    world:_flushDestroyedEntities()
    
    assertEntities(world, {"e1", "e2"})
    assert.is_nil(stray.to_destroy)
    assert.are.equal(0, #world.entities_to_destroy)
  end)

  -- --------------------------------------------------------------------------
  -- FLUSH SAFETY
  -- --------------------------------------------------------------------------
  
  it("flush is idempotent (safe to call twice)", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local world = makeWorld({e1, e2})
    world.current_tick_entity = e1
    world:destroyEntity(e2)
    world.current_tick_entity = nil
    
    world:_flushDestroyedEntities()
    world:_flushDestroyedEntities()
    
    assertEntities(world, {"e1"})
    assert.are.equal(0, #world.entities_to_destroy)
  end)

  -- --------------------------------------------------------------------------
  -- NESTED ITERATION
  -- --------------------------------------------------------------------------
  
  it("nested iteration defers until outer loop ends", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local e3 = makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    
    e2.tick = function(self)
      self.tick_count = self.tick_count + 1
      -- Nested iteration over world.entities
      for _, inner in ipairs(world.entities) do
        if inner == e3 then
          world:destroyEntity(e3)
        end
      end
    end
    
    runTickLoop(world)
    
    assertTickCounts({e1, e2, e3}, {e1=1, e2=1, e3=0})
    assert.is_true(e3.destroyed)
    assertEntities(world, {"e1", "e2"})
  end)

  -- --------------------------------------------------------------------------
  -- TICKDAY LOOP (HUMANOIDS + PLANTS)
  -- --------------------------------------------------------------------------
  
  it("tickDay loop defers destruction for humanoids", function()
    local e1 = makeEntity("e1", {kind="humanoid"})
    local e2 = makeEntity("e2", {kind="humanoid"})
    local e3 = makeEntity("e3", {kind="humanoid"})
    local e4 = makeEntity("e4", {kind="humanoid"})
    local world = makeWorld({e1, e2, e3, e4})
    
    e2.tickDay = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e1)
      world:destroyEntity(e4)
    end
    
    runTickDayLoop(world)
    
    assertTickCounts({e1, e2, e3, e4}, {e1=1, e2=1, e3=1, e4=0})
    assert.is_true(e4.destroyed)
    assertEntities(world, {"e2", "e3"})
  end)
  
  it("tickDay loop defers destruction for plants", function()
    local plant = makeEntity("plant", {kind="plant"})
    local e2 = makeEntity("e2", {kind="humanoid"})
    local e3 = makeEntity("e3", {kind="humanoid"})
    local world = makeWorld({plant, e2, e3})
    
    plant.tickDay = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e3)
    end
    
    runTickDayLoop(world)
    
    assertTickCounts({plant, e2, e3}, {plant=1, e2=1, e3=0})
    assert.is_true(e3.destroyed)
    assertEntities(world, {"plant", "e2"})
  end)

  -- --------------------------------------------------------------------------
  -- DEADLOCK LOOP
  -- --------------------------------------------------------------------------
  
  it("deadlock loop defers destruction", function()
    local e1 = makeEntity("e1", {checkForDeadlock=true})
    local e2 = makeEntity("e2", {checkForDeadlock=true})
    local e3 = makeEntity("e3", {checkForDeadlock=true})
    local world = makeWorld({e1, e2, e3})
    
    e1.checkForDeadlock = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e3)
    end
    
    runDeadlockLoop(world)
    
    assertTickCounts({e1, e2, e3}, {e1=1, e2=1, e3=0})
    assert.is_true(e3.destroyed)
    assertEntities(world, {"e1", "e2"})
  end)

  -- --------------------------------------------------------------------------
  -- CONSECUTIVE LOOPS REUSE QUEUE
  -- --------------------------------------------------------------------------
  
  it("queue is recreated fresh each loop", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local e3 = makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    
    e1.tick = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e2)
    end
    
    runTickLoop(world)
    assertEntities(world, {"e1", "e3"})
    assert.are.equal(0, #world.entities_to_destroy)
    
    e3.tick = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e1)
    end
    
    runTickLoop(world)
    
    assertEntities(world, {"e3"})
    assertTickCounts({e1, e3}, {e1=2, e3=2})
    assert.are.equal(0, #world.entities_to_destroy)
  end)

  -- --------------------------------------------------------------------------
  -- DESTROY OUTSIDE LOOP WITH PENDING QUEUE
  -- --------------------------------------------------------------------------
  
  it("immediate destroy works even with pending queued entities", function()
    local e1 = makeEntity("e1")
    local e2 = makeEntity("e2")
    local e3 = makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    world.current_tick_entity = e1
    world:destroyEntity(e1)  -- Queued
    world.current_tick_entity = nil
    
    -- Now destroy e3 OUTSIDE loop
    world:destroyEntity(e3)
    
    assert.is_true(e3.destroyed)
    assert.is_nil(e3.to_destroy)
    assert.are.equal(1, #world.entities_to_destroy)  -- e1 still queued
    
    world:_flushDestroyedEntities()
    assertEntities(world, {"e2"})
  end)

end)

-- ============================================================================
-- USAGE EXAMPLES FOR EXTENDING
-- ============================================================================

--[[
-- Example: Test a new entity type with custom tick behavior
it("custom entity type respects to_destroy guard", function()
  local CustomEntity = class("CustomEntity")
  function CustomEntity:init(world)
    self.world = world
    self.ticks = true
    self.custom_state = 0
  end
  function CustomEntity:tick()
    self.custom_state = self.custom_state + 1
    if self.custom_state > 2 then
      self.world:destroyEntity(self)
    end
  end
  
  local world = makeWorld({})
  local ent = CustomEntity(world)
  world.entities[1] = ent
  
  runTickLoop(world)  -- tick 1
  runTickLoop(world)  -- tick 2
  runTickLoop(world)  -- tick 3 -> destroy
  
  assert.are.equal(3, ent.custom_state)
  assert.is_true(ent.destroyed)
  assertEntities(world, {})
end)

-- Example: Test room destruction cascading to objects
it("room destruction cascades to contained objects", function()
  local room = makeEntity("room")
  local obj1 = makeEntity("obj1")
  local obj2 = makeEntity("obj2")
  local world = makeWorld({room, obj1, obj2})
  
  room.onDestroy = function(self)
    world:destroyEntity(obj1)
    world:destroyEntity(obj2)
  end
  
  world.current_tick_entity = room
  world:destroyEntity(room)
  world.current_tick_entity = nil
  world:_flushDestroyedEntities()
  
  assert.is_true(room.destroyed)
  assert.is_true(obj1.destroyed)
  assert.is_true(obj2.destroyed)
  assertEntities(world, {})
end)
--]]
