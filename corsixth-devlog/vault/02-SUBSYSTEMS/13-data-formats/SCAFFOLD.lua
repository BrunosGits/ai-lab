-- Busted test template for validating CorsixTH data files
-- Run with: busted SCAFFOLD.lua

local luassert = require("luassert")
local say = require("say")

-- ============================================================================
-- TEST HELPERS
-- ============================================================================

local function load_data_file(path)
  -- In real test, this would use CorsixTH's module loader
  -- For now, we simulate by dofile
  local env = {
    _S = setmetatable({}, { __index = function() return "localized_string" end }),
    TheApp = {
      config = {},
      animation_manager = { setPatientMarker = function() end, setStaffMarker = function() end, setAnimLength = function() end, getAnimLength = function() return 1 end },
      gfx = { loadMainCursor = function() end },
      ui = { adviser = { say = function() end }, hospital = { emergency = { disease = { emergency_sound = "emerg001.wav" } } } },
      world = { getLocalPlayerHospital = function() end }
    },
    AnimationEffect = { Glowing = 1, Jelly = 2 },
    DrawingLayers = { RatHole = 1, AtomAnalyser = 2, Litter = 3, Door = 4 },
    class = function(name, parent) return function(t) end end,
    corsixth = { require = function() end },
    require = function(name)
      if name == "TH" then return { animation = function() return { makeVisible = function() end, makeInvisible = function() end, setFrame = function() end, getFrame = function() return 0 end } end } end
      if name == "queue" then return { new = function() return { setPriorityForSameRoom = function() end, setBenchThreshold = function() end, setMaxQueue = function() end, front = function() end, pop = function() end, rerouteAllPatients = function() end, patientSize = function() return 0 end, isFull = function() return false end, visitor_count = 0 } end } end
      if name == "announcer" then return { AnnouncementPriority = { Critical = 1 } } end
      return {}
    end,
    math = math,
    string = string,
    table = table,
    pairs = pairs,
    ipairs = ipairs,
    next = next,
    assert = assert,
    error = error,
    print = print,
    type = type,
    setmetatable = setmetatable,
    tostring = tostring,
  }
  local fn, err = loadfile(path, "bt", env)
  if not fn then return nil, err end
  local ok, result = pcall(fn)
  if not ok then return nil, result end
  return result
end

local function get_all_files(dir, pattern)
  local files = {}
  local handle = io.popen('find "' .. dir .. '" -name "' .. pattern .. '" -type f 2>/dev/null | sort')
  if handle then
    for line in handle:lines() do
      table.insert(files, line)
    end
    handle:close()
  end
  return files
end

-- ============================================================================
-- DISEASE TESTS
-- ============================================================================

describe("Disease Data Files", function()
  local disease_files
  local diseases = {}
  local room_ids = {}
  local object_ids = {}

  setup(function()
    -- Load all room IDs
    local room_files = get_all_files("/tmp/CorsixTH/CorsixTH/Lua/rooms", "*.lua")
    for _, f in ipairs(room_files) do
      local room = load_data_file(f)
      if room and room.id then room_ids[room.id] = true end
    end

    -- Load all object IDs
    local object_files = get_all_files("/tmp/CorsixTH/CorsixTH/Lua/objects", "*.lua")
    for _, f in ipairs(object_files) do
      local obj = load_data_file(f)
      if obj and obj.id then object_ids[obj.id] = true end
    end

    -- Load all diseases
    disease_files = get_all_files("/tmp/CorsixTH/CorsixTH/Lua/diseases", "*.lua")
    for _, f in ipairs(disease_files) do
      local disease, err = load_data_file(f)
      if disease then
        diseases[disease.id] = disease
      else
        print("Failed to load " .. f .. ": " .. tostring(err))
      end
    end
  end)

  it("should have exactly 34 disease files", function()
    assert.are.equal(34, #disease_files)
  end)

  it("each disease should have all required fields", function()
    local required = {
      "id", "expertise_id", "name", "cause", "symptoms", "cure",
      "cure_price", "emergency_sound", "emergency_number",
      "contagious", "initPatient", "diagnosis_rooms", "treatment_rooms"
    }
    for id, disease in pairs(diseases) do
      for _, field in ipairs(required) do
        assert.is_not_nil(disease[field], id .. " missing required field: " .. field)
      end
      -- Must have exactly one of visuals_id or non_visuals_id
      local has_visuals = disease.visuals_id ~= nil
      local has_non_visuals = disease.non_visuals_id ~= nil
      assert.is_true(has_visuals ~= has_non_visuals, id .. " must have exactly one of visuals_id or non_visuals_id")
    end
  end)

  it("each disease id should match filename", function()
    for _, f in ipairs(disease_files) do
      local expected_id = f:match("([^/]+)%.lua$")
      local disease = load_data_file(f)
      assert.are.equal(expected_id, disease.id, "File " .. f .. " has mismatched id: " .. tostring(disease.id))
    end
  end)

  it("expertise_id should be unique across diseases", function()
    local seen = {}
    for id, disease in pairs(diseases) do
      assert.is_nil(seen[disease.expertise_id], "Duplicate expertise_id " .. disease.expertise_id .. " in " .. id .. " and " .. seen[disease.expertise_id])
      seen[disease.expertise_id] = id
    end
  end)

  it("diagnosis_rooms should reference existing rooms", function()
    for id, disease in pairs(diseases) do
      for _, room_id in ipairs(disease.diagnosis_rooms) do
        assert.is_true(room_ids[room_id], id .. " references unknown diagnosis room: " .. room_id)
      end
    end
  end)

  it("treatment_rooms should reference existing rooms", function()
    for id, disease in pairs(diseases) do
      for _, room_id in ipairs(disease.treatment_rooms) do
        assert.is_true(room_ids[room_id], id .. " references unknown treatment room: " .. room_id)
      end
    end
  end)

  it("treatment_rooms should not be empty", function()
    for id, disease in pairs(diseases) do
      assert.is_true(#disease.treatment_rooms > 0, id .. " has empty treatment_rooms")
    end
  end)

  it("cure_price should be positive", function()
    for id, disease in pairs(diseases) do
      assert.is_true(type(disease.cure_price) == "number" and disease.cure_price > 0, id .. " cure_price must be positive number")
    end
  end)

  it("emergency_number should be positive", function()
    for id, disease in pairs(diseases) do
      assert.is_true(type(disease.emergency_number) == "number" and disease.emergency_number > 0, id .. " emergency_number must be positive")
    end
  end)

  it("initPatient should be a function", function()
    for id, disease in pairs(diseases) do
      assert.is_function(disease.initPatient, id .. " initPatient must be a function")
    end
  end)

  it("contagious should be boolean", function()
    for id, disease in pairs(diseases) do
      assert.is_boolean(disease.contagious, id .. " contagious must be boolean")
    end
  end)

  it("optional fields should have correct types when present", function()
    for id, disease in pairs(diseases) do
      if disease.requires_machine ~= nil then assert.is_boolean(disease.requires_machine, id .. " requires_machine must be boolean") end
      if disease.more_loo_use ~= nil then assert.is_boolean(disease.more_loo_use, id .. " more_loo_use must be boolean") end
      if disease.must_stand ~= nil then assert.is_boolean(disease.must_stand, id .. " must_stand must be boolean") end
      if disease.only_emergency ~= nil then assert.is_boolean(disease.only_emergency, id .. " only_emergency must be boolean") end
      if disease.yawn ~= nil then assert.is_boolean(disease.yawn, id .. " yawn must be boolean") end
    end
  end)
end)

-- ============================================================================
-- ROOM TESTS
-- ============================================================================

describe("Room Data Files", function()
  local room_files
  local rooms = {}
  local object_ids = {}

  setup(function()
    -- Load all object IDs
    local object_files = get_all_files("/tmp/CorsixTH/CorsixTH/Lua/objects", "*.lua")
    for _, f in ipairs(object_files) do
      local obj = load_data_file(f)
      if obj and obj.id then object_ids[obj.id] = true end
    end

    -- Load all rooms
    room_files = get_all_files("/tmp/CorsixTH/CorsixTH/Lua/rooms", "*.lua")
    for _, f in ipairs(room_files) do
      local room = load_data_file(f)
      if room then rooms[room.id] = room end
    end
  end)

  it("should have exactly 23 room files", function()
    assert.are.equal(23, #room_files)
  end)

  it("each room should have all required fields", function()
    local required = {
      "id", "level_config_id", "class", "name", "long_name", "tooltip",
      "objects_needed", "build_preview_animation", "categories",
      "minimum_size", "wall_type", "floor_tile", "required_staff", "call_sound"
    }
    for id, room in pairs(rooms) do
      for _, field in ipairs(required) do
        assert.is_not_nil(room[field], id .. " missing required field: " .. field)
      end
    end
  end)

  it("each room id should match filename", function()
    for _, f in ipairs(room_files) do
      local expected_id = f:match("([^/]+)%.lua$")
      local room = load_data_file(f)
      assert.are.equal(expected_id, room.id, "File " .. f .. " has mismatched id: " .. tostring(room.id))
    end
  end)

  it("level_config_id should be unique", function()
    local seen = {}
    for id, room in pairs(rooms) do
      assert.is_nil(seen[room.level_config_id], "Duplicate level_config_id " .. room.level_config_id .. " in " .. id .. " and " .. seen[room.level_config_id])
      seen[room.level_config_id] = id
    end
  end)

  it("objects_needed should reference existing objects", function()
    for id, room in pairs(rooms) do
      for obj_id, count in pairs(room.objects_needed) do
        assert.is_true(object_ids[obj_id], id .. " references unknown object in objects_needed: " .. obj_id)
        assert.is_true(type(count) == "number" and count > 0, id .. " objects_needed[" .. obj_id .. "] must be positive number")
      end
    end
  end)

  it("objects_additional should reference existing objects when present", function()
    for id, room in pairs(rooms) do
      if room.objects_additional then
        for _, obj_id in ipairs(room.objects_additional) do
          assert.is_true(object_ids[obj_id], id .. " references unknown object in objects_additional: " .. obj_id)
        end
      end
    end
  end)

  it("categories should be a non-empty table", function()
    for id, room in pairs(rooms) do
      assert.is_table(room.categories)
      assert.is_true(next(room.categories) ~= nil, id .. " categories must not be empty")
      for cat, priority in pairs(room.categories) do
        assert.is_string(cat, id .. " category key must be string")
        assert.is_number(priority, id .. " category priority must be number")
      end
    end
  end)

  it("minimum_size should be positive integer", function()
    for id, room in pairs(rooms) do
      assert.is_true(type(room.minimum_size) == "number" and room.minimum_size > 0 and room.minimum_size == math.floor(room.minimum_size), id .. " minimum_size must be positive integer")
    end
  end)

  it("wall_type should be one of known types", function()
    local valid_walls = { white = true, yellow = true, blue = true, green = true }
    for id, room in pairs(rooms) do
      assert.is_true(valid_walls[room.wall_type], id .. " has invalid wall_type: " .. tostring(room.wall_type))
    end
  end)

  it("required_staff should have at least one role", function()
    for id, room in pairs(rooms) do
      assert.is_table(room.required_staff)
      assert.is_true(next(room.required_staff) ~= nil, id .. " required_staff must not be empty")
      for role, count in pairs(room.required_staff) do
        assert.is_string(role)
        assert.is_true(type(count) == "number" and count > 0)
      end
    end
  end)

  it("maximum_staff should be compatible with required_staff when present", function()
    for id, room in pairs(rooms) do
      if room.maximum_staff then
        for role, max_count in pairs(room.maximum_staff) do
          local req_count = room.required_staff[role]
          if req_count then
            assert.is_true(max_count >= req_count, id .. " maximum_staff[" .. role .. "] (" .. max_count .. ") < required_staff (" .. req_count .. ")")
          end
        end
      end
    end
  end)

  it("optional fields should have correct types", function()
    for id, room in pairs(rooms) do
      if room.vip_must_visit ~= nil then assert.is_boolean(room.vip_must_visit) end
      if room.handyman_call_sound ~= nil then assert.is_string(room.handyman_call_sound) end
      if room.has_no_queue_dialog ~= nil then assert.is_boolean(room.has_no_queue_dialog) end
      if room.swing_doors ~= nil then assert.is_boolean(room.swing_doors) end
    end
  end)

  it("class should follow naming convention", function()
    for id, room in pairs(rooms) do
      assert.is_string(room.class)
      assert.is_true(room.class:match("Room$"), id .. " class should end with 'Room': " .. room.class)
    end
  end)
end)

-- ============================================================================
-- OBJECT TESTS
-- ============================================================================

describe("Object Data Files", function()
  local object_files
  local objects = {}
  local room_ids = {}

  setup(function()
    -- Load all room IDs
    local room_files = get_all_files("/tmp/CorsixTH/CorsixTH/Lua/rooms", "*.lua")
    for _, f in ipairs(room_files) do
      local room = load_data_file(f)
      if room and room.id then room_ids[room.id] = true end
    end

    -- Load all objects
    object_files = get_all_files("/tmp/CorsixTH/CorsixTH/Lua/objects", "*.lua")
    for _, f in ipairs(object_files) do
      local obj = load_data_file(f)
      if obj then objects[obj.id] = obj end
    end
  end)

  it("should have exactly 43 object files", function()
    assert.are.equal(43, #object_files)
  end)

  it("each object should have all required fields", function()
    local required = { "id", "thob", "name", "tooltip", "ticks", "build_preview_animation", "orientations" }
    for id, obj in pairs(objects) do
      for _, field in ipairs(required) do
        assert.is_not_nil(obj[field], id .. " missing required field: " .. field)
      end
    end
  end)

  it("each object id should match filename", function()
    for _, f in ipairs(object_files) do
      local expected_id = f:match("([^/]+)%.lua$")
      local obj = load_data_file(f)
      assert.are.equal(expected_id, obj.id, "File " .. f .. " has mismatched id: " .. tostring(obj.id))
    end
  end)

  it("thob should be unique", function()
    local seen = {}
    for id, obj in pairs(objects) do
      assert.is_nil(seen[obj.thob], "Duplicate thob " .. obj.thob .. " in " .. id .. " and " .. seen[obj.thob])
      seen[obj.thob] = id
    end
  end)

  it("ticks should be boolean", function()
    for id, obj in pairs(objects) do
      assert.is_boolean(obj.ticks, id .. " ticks must be boolean")
    end
  end)

  it("orientations should have at least north and east", function()
    for id, obj in pairs(objects) do
      assert.is_table(obj.orientations)
      assert.is_not_nil(obj.orientations.north, id .. " missing north orientation")
      assert.is_not_nil(obj.orientations.east, id .. " missing east orientation")
      -- south/west optional but recommended
    end
  end)

  it("each orientation should have footprint", function()
    for id, obj in pairs(objects) do
      for dir, orient in pairs(obj.orientations) do
        assert.is_table(orient.footprint, id .. " orientation " .. dir .. " missing footprint")
        assert.is_true(#orient.footprint > 0, id .. " orientation " .. dir .. " footprint empty")
        for _, cell in ipairs(orient.footprint) do
          assert.is_table(cell)
          assert.is_number(cell[1])
          assert.is_number(cell[2])
        end
      end
    end
  end)

  it("usage_animations should match idle_animations directions when present", function()
    for id, obj in pairs(objects) do
      if obj.usage_animations then
        for dir in pairs(obj.usage_animations) do
          assert.is_not_nil(obj.idle_animations[dir], id .. " has usage_animations for " .. dir .. " but no idle_animations")
        end
      end
    end
  end)

  it("multi_usage_animations keys should follow 'Staff - Patient' pattern", function()
    for id, obj in pairs(objects) do
      if obj.multi_usage_animations then
        for key in pairs(obj.multi_usage_animations) do
          assert.is_true(key:match("^.+ %-.+$"), id .. " multi_usage_animations key '" .. key .. "' should follow 'Type - Type' pattern")
        end
      end
    end
  end)

  it("slave_id should reference existing object when present", function()
    for id, obj in pairs(objects) do
      if obj.slave_id then
        assert.is_true(objects[obj.slave_id] ~= nil, id .. " references unknown slave_id: " .. obj.slave_id)
      end
    end
  end)

  it("locked_to_wall should map valid directions when present", function()
    local valid_dirs = { north = true, east = true, south = true, west = true }
    for id, obj in pairs(objects) do
      if obj.locked_to_wall then
        for wall_dir, obj_dir in pairs(obj.locked_to_wall) do
          assert.is_true(valid_dirs[wall_dir], id .. " locked_to_wall has invalid wall direction: " .. wall_dir)
          assert.is_true(valid_dirs[obj_dir], id .. " locked_to_wall maps to invalid object direction: " .. obj_dir)
        end
      end
    end
  end)

  it("corridor_object should be in range 1-7 when present", function()
    for id, obj in pairs(objects) do
      if obj.corridor_object then
        assert.is_true(type(obj.corridor_object) == "number" and obj.corridor_object >= 1 and obj.corridor_object <= 7, id .. " corridor_object must be 1-7")
      end
    end
  end)

  it("research_category should be 'diagnosis' or 'cure' when present", function()
    for id, obj in pairs(objects) do
      if obj.research_category then
        assert.is_true(obj.research_category == "diagnosis" or obj.research_category == "cure", id .. " research_category must be 'diagnosis' or 'cure'")
      end
    end
  end)

  it("referenced objects should be used by at least one room", function()
    local used = {}
    local room_files = get_all_files("/tmp/CorsixTH/CorsixTH/Lua/rooms", "*.lua")
    for _, f in ipairs(room_files) do
      local room = load_data_file(f)
      if room then
        for obj_id in pairs(room.objects_needed) do used[obj_id] = true end
        if room.objects_additional then
          for _, obj_id in ipairs(room.objects_additional) do used[obj_id] = true end
        end
      end
    end
    for id, obj in pairs(objects) do
      -- Some objects are special (litter, rathole, helicopter, door) and not placed in rooms
      local special = { litter = true, rathole = true, helicopter = true, door = true, reception_desk = true }
      if not special[id] then
        assert.is_true(used[id], "Object " .. id .. " is not referenced by any room")
      end
    end
  end)
end)

-- ============================================================================
-- CROSS-REFERENCE TESTS
-- ============================================================================

describe("Cross-Reference Integrity", function()
  local diseases, rooms, objects = {}, {}, {}

  setup(function()
    local function load_all(dir, pattern)
      local t = {}
      local files = get_all_files(dir, pattern)
      for _, f in ipairs(files) do
        local data = load_data_file(f)
        if data and data.id then t[data.id] = data end
      end
      return t
    end
    diseases = load_all("/tmp/CorsixTH/CorsixTH/Lua/diseases", "*.lua")
    rooms = load_all("/tmp/CorsixTH/CorsixTH/Lua/rooms", "*.lua")
    objects = load_all("/tmp/CorsixTH/CorsixTH/Lua/objects", "*.lua")
  end)

  it("all disease diagnosis_rooms exist", function()
    for did, disease in pairs(diseases) do
      for _, rid in ipairs(disease.diagnosis_rooms) do
        assert.is_not_nil(rooms[rid], "Disease " .. did .. " references missing room " .. rid)
      end
    end
  end)

  it("all disease treatment_rooms exist", function()
    for did, disease in pairs(diseases) do
      for _, rid in ipairs(disease.treatment_rooms) do
        assert.is_not_nil(rooms[rid], "Disease " .. did .. " references missing room " .. rid)
      end
    end
  end)

  it("all room objects_needed exist", function()
    for rid, room in pairs(rooms) do
      for oid in pairs(room.objects_needed) do
        assert.is_not_nil(objects[oid], "Room " .. rid .. " needs missing object " .. oid)
      end
    end
  end)

  it("all room objects_additional exist", function()
    for rid, room in pairs(rooms) do
      if room.objects_additional then
        for _, oid in ipairs(room.objects_additional) do
          assert.is_not_nil(objects[oid], "Room " .. rid .. " has additional missing object " .. oid)
        end
      end
    end
  end)

  it("all object slave_ids exist", function()
    for oid, obj in pairs(objects) do
      if obj.slave_id then
        assert.is_not_nil(objects[obj.slave_id], "Object " .. oid .. " references missing slave " .. obj.slave_id)
      end
    end
  end)

  it("no orphaned rooms (referenced by diseases but not buildable)", function()
    -- All rooms referenced by diseases should have level_config_id (buildable)
    for did, disease in pairs(diseases) do
      for _, rid in ipairs(disease.diagnosis_rooms) do
        assert.is_not_nil(rooms[rid].level_config_id, "Disease " .. did .. " references unbuildable room " .. rid)
      end
      for _, rid in ipairs(disease.treatment_rooms) do
        assert.is_not_nil(rooms[rid].level_config_id, "Disease " .. did .. " references unbuildable room " .. rid)
      end
    end
  end)
end)

-- ============================================================================
-- CUSTOM ASSERTIONS
-- ============================================================================

say:set("assertion.has_required_fields.positive", "Expected %s to have required field %s")
say:set("assertion.has_required_fields.negative", "Expected %s to not have required field %s")
assert:register("assertion", "has_required_fields", function(state, arguments)
  local obj, fields = arguments[1], arguments[2]
  for _, f in ipairs(fields) do
    if obj[f] == nil then return false end
  end
  return true
end)

-- ============================================================================
-- RUN TESTS
-- ============================================================================

-- busted --verbose SCAFFOLD.lua
