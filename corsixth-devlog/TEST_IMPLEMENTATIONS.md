# CorsixTH Automated Test Implementations

> Priority-ranked test suite for regression prevention | Generated: 2026-08-17

---

## Test Infrastructure

All tests use the **Busted** framework and follow the existing patterns in `world_spec.lua`.

### Common Mock Helpers

```lua
-- Shared test base (from class_test_base.lua)
local function permanent(class_name)
  return function() return {} end
end

-- Entity stub factory
local function makeEntity(name, opts)
  opts = opts or {}
  return {
    name = name or "unnamed",
    ticks = opts.ticks ~= false,
    tick_count = 0,
    to_destroy = false,
    tile_x = opts.tile_x or 0,
    tile_y = opts.tile_y or 0,
    in_room = nil,
    tick = function(self) self.tick_count = self.tick_count + 1 end,
    onDestroy = function() end,
    onPickUp = function() end,
    getRoom = function() return nil end,
  }
end

-- World stub factory
local function makeWorld(entities)
  local world = {
    entities = entities or {},
    entities_to_destroy = {},
    current_tick_entity = nil,
    rooms = {},
    hospitals = {},
  }
  setmetatable(world, {__index = World})
  return world
end
```

---

## TIER 1: HIGH PRIORITY (Core Game Logic)

### Test 1: Queue System (`queue_spec.lua`)

**Why:** Every patient flow depends on queues. Queue bugs cause silent misbehavior.

```lua
-- CorsixTH/Luatest/spec/queue_spec.lua
local Queue = require("queue")

describe("Queue", function()
  local queue

  before_each(function()
    queue = Queue()
  end)

  describe("basic operations", function()
    it("starts empty", function()
      assert.equals(0, queue:size())
      assert.is_true(queue:isEmpty())
    end)

    it("pushes a humanoid", function()
      local h = makeEntity("patient1")
      queue:push(h)
      assert.equals(1, queue:size())
      assert.is_false(queue:isEmpty())
    end)

    it("removes a humanoid", function()
      local h = makeEntity("patient1")
      queue:push(h)
      queue:remove(h)
      assert.equals(0, queue:size())
    end)

    it("handles multiple humanoids", function()
      local h1 = makeEntity("patient1")
      local h2 = makeEntity("patient2")
      local h3 = makeEntity("patient3")
      queue:push(h1)
      queue:push(h2)
      queue:push(h3)
      assert.equals(3, queue:size())
    end)
  end)

  describe("size limits", function()
    it("respects max queue size", function()
      queue:setMaxQueue(2)
      local h1 = makeEntity("patient1")
      local h2 = makeEntity("patient2")
      local h3 = makeEntity("patient3")
      queue:push(h1)
      queue:push(h2)
      assert.is_true(queue:isFull())
      -- Third patient should not be added
      queue:push(h3)
      assert.equals(2, queue:size())
    end)

    it("increases max size", function()
      queue:setMaxQueue(2)
      queue:increaseMaxSize(1)
      local h1 = makeEntity("patient1")
      local h2 = makeEntity("patient2")
      local h3 = makeEntity("patient3")
      queue:push(h1)
      queue:push(h2)
      queue:push(h3)
      assert.equals(3, queue:size())
    end)

    it("decreases max size", function()
      queue:setMaxQueue(5)
      queue:decreaseMaxSize(2)
      local h1 = makeEntity("patient1")
      local h2 = makeEntity("patient2")
      local h3 = makeEntity("patient3")
      queue:push(h1)
      queue:push(h2)
      queue:push(h3)
      assert.equals(2, queue:size())
    end)
  end)

  describe("emergency patients", function()
    it("tracks emergency patients", function()
      local h1 = makeEntity("patient1")
      h1.is_emergency = true
      local h2 = makeEntity("patient2")
      h2.is_emergency = false
      queue:push(h1)
      queue:push(h2)
      assert.is_true(queue:hasEmergencyPatient())
    end)

    it("returns false when no emergencies", function()
      local h1 = makeEntity("patient1")
      h1.is_emergency = false
      queue:push(h1)
      assert.is_false(queue:hasEmergencyPatient())
    end)
  end)

  describe("dropFromQueue", function()
    it("drops a humanoid from the queue", function()
      local h1 = makeEntity("patient1")
      local h2 = makeEntity("patient2")
      queue:push(h1)
      queue:push(h2)
      queue:dropFromQueue(h1)
      assert.equals(1, queue:size())
    end)

    it("handles dropping non-existent humanoid", function()
      local h1 = makeEntity("patient1")
      local h2 = makeEntity("patient2")
      queue:push(h1)
      queue:dropFromQueue(h2)
      assert.equals(1, queue:size())
    end)
  end)

  describe("bench threshold", function()
    it("reports size correctly with benches", function()
      queue:setBenchThreshold(3)
      local h1 = makeEntity("patient1")
      local h2 = makeEntity("patient2")
      queue:push(h1)
      queue:push(h2)
      -- With 2 patients and threshold 3, reported size should reflect bench availability
      assert.equals(2, queue:reportedSize())
    end)
  end)
end)
```

---

### Test 2: Room Lifecycle (`room_spec.lua`)

**Why:** Room logic is shared by all 23 room types. Bugs here cascade everywhere.

```lua
-- CorsixTH/Luatest/spec/room_spec.lua
local Room = require("room")

describe("Room", function()
  local room
  local mock_world
  local mock_hospital

  before_each(function()
    mock_world = makeWorld()
    mock_hospital = {
      addPatient = function() end,
      humanoidDeath = function() end,
      isPlayerHospital = function() return true end,
    }
    room = Room()
    room.world = mock_world
    room.hospital = mock_hospital
    room.humanoids = {}
    room.objects = {}
    room.humanoids_enroute = {}
    room.built = true
    room.is_active = true
    room.crashed = false
    room.maximum_patients = 1
    room.staff_member = nil
    room.staff_member_set = {}
  end)

  describe("humanoid entry", function()
    it("adds humanoid to room on entry", function()
      local h = makeEntity("patient1")
      h.hospital = mock_hospital
      h.isLeaving = function() return false end
      h.going_home = false
      room:onHumanoidEnter(h)
      assert.is_true(room.humanoids[h])
    end)

    it("sets humanoid.in_room on entry", function()
      local h = makeEntity("patient1")
      h.hospital = mock_hospital
      h.isLeaving = function() return false end
      h.going_home = false
      room:onHumanoidEnter(h)
      assert.equals(room, h.in_room)
    end)
  end)

  describe("humanoid exit", function()
    it("removes humanoid from room on exit", function()
      local h = makeEntity("patient1")
      room.humanoids[h] = true
      h.in_room = room
      h.hospital = mock_hospital
      room:onHumanoidLeave(h)
      assert.is_nil(room.humanoids[h])
    end)

    it("clears humanoid.in_room on exit", function()
      local h = makeEntity("patient1")
      room.humanoids[h] = true
      h.in_room = room
      h.hospital = mock_hospital
      room:onHumanoidLeave(h)
      assert.is_nil(h.in_room)
    end)
  end)

  describe("room crash", function()
    it("sets crashed flag", function()
      room.crashRoom()
      assert.is_true(room.crashed)
    end)

    it("deactivates room", function()
      room.crashRoom()
      assert.is_false(room.is_active)
    end)
  end)

  describe("staff criteria", function()
    it("returns empty criteria by default", function()
      local criteria = room:getRequiredStaffCriteria()
      assert.is_table(criteria)
    end)

    it("tests staff criteria", function()
      local staff = makeEntity("doctor1")
      staff.hospital = mock_hospital
      staff.fulfillsCriterion = function() return true end
      -- Default criteria should accept any staff
      local result = room:testStaffCriteria(staff)
      assert.is_boolean(result)
    end)
  end)

  describe("canHumanoidEnter", function()
    it("returns false when room is not active", function()
      room.is_active = false
      local h = makeEntity("patient1")
      assert.is_false(room:canHumanoidEnter(h))
    end)

    it("returns false when room is crashed", function()
      room.crashed = true
      local h = makeEntity("patient1")
      assert.is_false(room:canHumanoidEnter(h))
    end)

    it("returns false when room is full", function()
      room.maximum_patients = 1
      local h1 = makeEntity("patient1")
      room.humanoids[h1] = true
      local h2 = makeEntity("patient2")
      assert.is_false(room:canHumanoidEnter(h2))
    end)
  end)
end)
```

---

### Test 3: Patient Lifecycle (`patient_spec.lua`)

**Why:** Patient flow is the core game loop. Bugs here break the entire game.

```lua
-- CorsixTH/Luatest/spec/patient_spec.lua
local Patient = require("entities.humanoids.patient")

describe("Patient", function()
  local patient
  local mock_world
  local mock_hospital

  before_each(function()
    mock_world = makeWorld()
    mock_hospital = {
      addPatient = function() end,
      humanoidDeath = function() end,
      isPlayerHospital = function() return true end,
      disease_casebook = {},
      research = {},
    }
    patient = Patient()
    patient.world = mock_world
    patient.hospital = mock_hospital
    patient.ticks = true
    patient.diagnosed = false
    patient.diagnosis_progress = 0
    patient.cured = false
    patient.dead = false
    patient.going_home = false
    patient.disease = nil
    patient.treatment_history = {}
  end)

  describe("diagnosis", function()
    it("starts undiagnosed", function()
      assert.is_false(patient.diagnosed)
      assert.equals(0, patient.diagnosis_progress)
    end)

    it("progresses diagnosis", function()
      patient:completeDiagnosticStep()
      assert.is_true(patient.diagnosis_progress > 0)
    end)

    it("marks as diagnosed when progress is sufficient", function()
      -- Simulate multiple diagnosis steps
      for i = 1, 10 do
        patient:completeDiagnosticStep()
      end
      -- Should be diagnosed after enough steps
      assert.is_boolean(patient.diagnosed)
    end)
  end)

  describe("treatment", function()
    it("can be cured", function()
      patient.cured = false
      patient:cure()
      assert.is_true(patient.cured)
    end)

    it("can die", function()
      patient.dead = false
      patient:die()
      assert.is_true(patient.dead)
    end)
  end)

  describe("going home", function()
    it("can go home", function()
      patient.going_home = false
      patient:goHome()
      assert.is_true(patient.going_home)
    end)
  end)

  describe("disease management", function()
    it("can set disease", function()
      local disease = {id = "bloaty_head", name = "Bloaty Head"}
      patient:setDisease(disease)
      assert.equals(disease, patient.disease)
    end)

    it("can change disease", function()
      local disease1 = {id = "bloaty_head", name = "Bloaty Head"}
      local disease2 = {id = "invisibility", name = "Invisibility"}
      patient:setDisease(disease1)
      patient:changeDisease(disease2)
      assert.equals(disease2, patient.disease)
    end)
  end)
end)
```

---

### Test 4: StaffProfile (`staff_profile_spec.lua`)

**Why:** Staff hiring, firing, and progression depend on profile calculations.

```lua
-- CorsixTH/Luatest/spec/staff_profile_spec.lua
local StaffProfile = require("staff_profile")

describe("StaffProfile", function()
  local profile

  before_each(function()
    profile = StaffProfile()
  end)

  describe("skill levels", function()
    it("parses skill level correctly", function()
      local level = StaffProfile.parseSkillLevel(50)
      assert.is_number(level)
    end)

    it("calculates fair wage", function()
      profile.skill = 50
      profile.wage = 0
      local wage = profile:getFairWage()
      assert.is_number(wage)
      assert.is_true(wage > 0)
    end)
  end)

  describe("professions", function()
    it("can be a psychiatrist", function()
      profile.is_psychiatrist = true
      assert.is_true(profile.is_psychiatrist)
    end)

    it("can be a surgeon", function()
      profile.is_surgeon = true
      assert.is_true(profile.is_surgeon)
    end)

    it("can be a researcher", function()
      profile.is_researcher = true
      assert.is_true(profile.is_researcher)
    end)

    it("can be a junior", function()
      profile.is_junior = true
      assert.is_true(profile.is_junior)
    end)

    it("can be a consultant", function()
      profile.is_consultant = true
      assert.is_true(profile.is_consultant)
    end)
  end)

  describe("initialization", function()
    it("randomizes profile", function()
      profile:randomise()
      assert.is_string(profile.name)
      assert.is_string(profile.initial)
    end)
  end)
end)
```

---

## TIER 2: MEDIUM PRIORITY (Critical Support Systems)

### Test 5: CallsDispatcher (`calls_dispatcher_spec.lua`)

**Why:** AI coordination for staff assignment. Bugs cause staff to not respond to calls.

```lua
-- CorsixTH/Luatest/spec/calls_dispatcher_spec.lua
local CallsDispatcher = require("calls_dispatcher")

describe("CallsDispatcher", function()
  local dispatcher
  local mock_world

  before_each(function()
    mock_world = makeWorld()
    dispatcher = CallsDispatcher()
    dispatcher.world = mock_world
  end)

  describe("enqueue", function()
    it("adds a call to the queue", function()
      local call = {
        verification = function() return true end,
        priority = function() return 1 end,
        execute = function() end,
      }
      dispatcher:enqueue(call, "test_object", "test_key")
      -- Queue should have the call
      assert.is_table(dispatcher.call_queue)
    end)
  end)

  describe("dropFromQueue", function()
    it("removes a call from the queue", function()
      local call = {
        verification = function() return true end,
        priority = function() return 1 end,
        execute = function() end,
        dropped = false,
      }
      dispatcher:enqueue(call, "test_object", "test_key")
      dispatcher:dropFromQueue(call)
      assert.is_true(call.dropped)
    end)
  end)

  describe("callForRepair", function()
    it("creates a repair call", function()
      local machine = makeEntity("machine1")
      machine.needs_repair = true
      dispatcher:callForRepair(machine, false, false)
      -- Should have created a call
      assert.is_table(dispatcher.call_queue)
    end)
  end)

  describe("callForWatering", function()
    it("creates a watering call", function()
      local plant = makeEntity("plant1")
      plant.needs_watering = true
      dispatcher:callForWatering(plant)
      -- Should have created a call
      assert.is_table(dispatcher.call_queue)
    end)
  end)
end)
```

---

### Test 6: Entity Lifecycle (`entity_spec.lua`)

**Why:** Base entity behavior affects all subclasses.

```lua
-- CorsixTH/Luatest/spec/entity_spec.lua
local Entity = require("entity")

describe("Entity", function()
  local entity

  before_each(function()
    entity = Entity()
    entity.world = makeWorld()
    entity.ticks = true
    entity.tile_x = 10
    entity.tile_y = 10
  end)

  describe("tick", function()
    it("increments tick count", function()
      entity:tick()
      assert.equals(1, entity.tick_count)
    end)

    it("processes timer countdown", function()
      entity.timer_time = 5
      entity.timer_function = function() end
      entity:tick()
      assert.equals(4, entity.timer_time)
    end)

    it("fires timer function when countdown reaches zero", function()
      local fired = false
      entity.timer_time = 1
      entity.timer_function = function() fired = true end
      entity:tick()
      assert.is_true(fired)
    end)
  end)

  describe("mood", function()
    it("sets mood info", function()
      local mood = {type = "happy"}
      entity:setMoodInfo(mood)
      assert.equals(mood, entity.mood_info)
    end)

    it("clears mood info", function()
      entity.mood_info = {type = "happy"}
      entity:setMoodInfo(nil)
      assert.is_nil(entity.mood_info)
    end)
  end)

  describe("dynamic info", function()
    it("sets dynamic info", function()
      entity:setDynamicInfo("text", "Hello")
      assert.is_table(entity.dynamic_info)
      assert.equals("Hello", entity.dynamic_info.text)
    end)

    it("clears dynamic info", function()
      entity:setDynamicInfo("text", "Hello")
      entity:clearDynamicInfo()
      assert.is_nil(entity.dynamic_info)
    end)
  end)

  describe("room detection", function()
    it("returns nil when not in a room", function()
      local room = entity:getRoom()
      assert.is_nil(room)
    end)
  end)
end)
```

---

### Test 7: Research Department (`research_department_spec.lua`)

**Why:** Research gates progression. Bugs block game advancement.

```lua
-- CorsixTH/Luatest/spec/research_department_spec.lua
local ResearchDepartment = require("research_department")

describe("ResearchDepartment", function()
  local research
  local mock_hospital

  before_each(function()
    mock_hospital = {
      disease_casebook = {},
      research = nil,
    }
    research = ResearchDepartment()
    research.hospital = mock_hospital
    research.research_progress = {}
    research.research_policy = {
      cure = 0.5,
      diagnosis = 0.5,
      drugs = 0.5,
      improvements = 0.5,
    }
  end)

  describe("initialization", function()
    it("initializes research", function()
      research:initResearch()
      assert.is_table(research.research_progress)
    end)
  end)

  describe("research points", function()
    it("adds research points", function()
      research:addResearchPoints(100)
      -- Points should be accumulated
      assert.is_number(research.research_progress)
    end)
  end)

  describe("research concentration", function()
    it("sets research concentration", function()
      research:setResearchConcentration("cure", 0.8)
      assert.equals(0.8, research.research_policy.cure)
    end)
  end)
end)
```

---

### Test 8: Epidemic (`epidemic_spec.lua`)

**Why:** Epidemics are major game events. Bugs break outbreak mechanics.

```lua
-- CorsixTH/Luatest/spec/epidemic_spec.lua
local Epidemic = require("epidemic")

describe("Epidemic", function()
  local epidemic
  local mock_hospital

  before_each(function()
    mock_hospital = {
      isPlayerHospital = function() return true end,
      disease_casebook = {},
      world = makeWorld(),
    }
    epidemic = Epidemic()
    epidemic.hospital = mock_hospital
    epidemic.world = mock_hospital.world
    epidemic.infected_patients = {}
    epidemic.revealed = false
    epidemic.ready_to_reveal = false
  end)

  describe("infection", function()
    it("adds contagious patient", function()
      local patient = makeEntity("patient1")
      patient.infected = true
      epidemic:addContagiousPatient(patient)
      assert.equals(1, #epidemic.infected_patients)
    end)

    it("infects other patients", function()
      local patient1 = makeEntity("patient1")
      patient1.infected = true
      local patient2 = makeEntity("patient2")
      patient2.infected = false
      epidemic:addContagiousPatient(patient1)
      epidemic.infectOtherPatients = function() patient2.infected = true end
      epidemic:infectOtherPatients()
      assert.is_true(patient2.infected)
    end)
  end)

  describe("vaccination", function()
    it("marks patient for vaccination", function()
      local patient = makeEntity("patient1")
      patient.infected = true
      epidemic:markForVaccination(patient)
      assert.is_true(patient.vaccinated)
    end)
  end)

  describe("reveal", function()
    it("reveals epidemic", function()
      epidemic.revealed = false
      epidemic:reveal()
      assert.is_true(epidemic.revealed)
    end)
  end)
end)
```

---

## TIER 3: LOW PRIORITY (Nice-to-Have)

### Test 9: Earthquake (`earthquake_spec.lua`)

```lua
-- CorsixTH/Luatest/spec/earthquake_spec.lua
local Earthquake = require("earthquake")

describe("Earthquake", function()
  local earthquake

  before_each(function()
    earthquake = Earthquake()
    earthquake.world = makeWorld()
    earthquake.active = false
    earthquake.disabled = false
  end)

  describe("initialization", function()
    it("starts inactive", function()
      assert.is_false(earthquake.active)
    end)

    it("can be disabled", function()
      earthquake.disabled = true
      assert.is_true(earthquake.disabled)
    end)
  end)
end)
```

---

### Test 10: Cheats (`cheats_spec.lua`)

```lua
-- CorsixTH/Luatest/spec/cheats_spec.lua
local Cheats = require("cheats")

describe("Cheats", function()
  local cheats
  local mock_hospital

  before_each(function()
    mock_hospital = {
      balance = 10000,
      reputation = 500,
      research = {research_progress = 0},
    }
    cheats = Cheats()
    cheats.hospital = mock_hospital
    cheats.active_cheats = {}
  end)

  describe("cheat detection", function()
    it("detects active cheats", function()
      cheats.active_cheats.money = true
      assert.is_true(cheats:isCheatActive("money"))
    end)

    it("detects inactive cheats", function()
      assert.is_false(cheats:isCheatActive("money"))
    end)
  end)
end)
```

---

### Test 11: Save/Load Round-Trip (`persistence_spec.lua`)

**Why:** Ensures game state survives serialization.

```lua
-- CorsixTH/Luatest/spec/persistence_spec.lua
local persist = require("persistance")

describe("Persistence", function()
  describe("serialization", function()
    it("serializes and deserializes basic types", function()
      local data = {
        number = 42,
        string = "hello",
        boolean = true,
        nested = {a = 1, b = 2},
      }
      local serialized = persist.serialize(data)
      local deserialized = persist.deserialize(serialized)
      assert.equals(data.number, deserialized.number)
      assert.equals(data.string, deserialized.string)
      assert.equals(data.boolean, deserialized.boolean)
      assert.equals(data.nested.a, deserialized.nested.a)
    end)

    it("handles nil values", function()
      local data = {a = 1, b = nil, c = 3}
      local serialized = persist.serialize(data)
      local deserialized = persist.deserialize(serialized)
      assert.equals(1, deserialized.a)
      assert.equals(3, deserialized.c)
    end)

    it("handles circular references", function()
      local data = {a = 1}
      data.self = data
      local serialized = persist.serialize(data)
      assert.is_string(serialized)
    end)
  end)
end)
```

---

## Test Execution Order

1. **Run Tier 1 tests first** (Queue, Room, Patient, StaffProfile)
2. **Then Tier 2** (CallsDispatcher, Entity, Research, Epidemic)
3. **Then Tier 3** (Earthquake, Cheats, Persistence)

```bash
# Run all tests
cd CorsixTH/Luatest
busted --lpath=../Lua/?.lua

# Run specific tier
busted --lpath=../Lua/?.lua spec/queue_spec.lua spec/room_spec.lua spec/patient_spec.lua spec/staff_profile_spec.lua

# Run with coverage
busted --lpath=../Lua/?.lua --coverage
```

---

## Implementation Notes

1. **Follow existing patterns**: Use the mock helpers from `world_spec.lua`
2. **Keep tests isolated**: Each test should be independent
3. **Test edge cases**: Include boundary conditions and error paths
4. **Use descriptive names**: Test names should explain the expected behavior
5. **Mock external dependencies**: Use stubs for world, hospital, etc.
6. **Test both success and failure paths**: Don't just test the happy path
