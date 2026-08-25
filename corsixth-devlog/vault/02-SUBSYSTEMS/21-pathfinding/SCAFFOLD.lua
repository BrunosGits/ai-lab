-- Pathfinding System Test Scaffold (Area 21)
-- Mock helpers and test cases for each finder type

local PathfindingScaffold = {}

-- ============================================================
-- MOCK HELPERS
-- ============================================================

-- Mock level_map with minimal interface
local function createMockMap(width, height)
    local map = {
        width = width or 128,
        height = height or 128,
        tiles = {},
        original_tiles = {},
        parcel_count = 1,
        plot_owner = {[0]=0, 1},
    }
    
    -- Initialize tiles
    for y = 0, map.height - 1 do
        map.tiles[y] = {}
        map.original_tiles[y] = {}
        for x = 0, map.width - 1 do
            map.tiles[y][x] = {
                x = x, y = y,
                flags = {
                    passable = true,
                    can_travel_n = (y > 0),
                    can_travel_e = (x < map.width - 1),
                    can_travel_s = (y < map.height - 1),
                    can_travel_w = (x > 0),
                    hospital = true,
                    buildable = true,
                    room = false,
                    door_north = false,
                    door_west = false,
                    do_not_idle = false,
                    avoid_tile = false,
                    parcelId = 1,
                },
                objects = {},
                iParcelId = 1,
                iRoomId = 0,
                tile_layers = {0, 0, 0, 0},
            }
            map.original_tiles[y][x] = map.tiles[y][x]
        end
    end
    
    function map:get_width() return self.width end
    function map:get_height() return self.height end
    function map:get_parcel_count() return self.parcel_count - 1 end
    function map:get_parcel_owner(parcelId) return self.plot_owner[parcelId] or 0 end
    
    function map:get_tile(x, y)
        if x >= 0 and x < self.width and y >= 0 and y < self.height then
            return self.tiles[y][x]
        end
        return nil
    end
    
    function map:get_tile_unchecked(x, y)
        return self.tiles[y][x]
    end
    
    function map:get_original_tile_unchecked(x, y)
        return self.original_tiles[y][x]
    end
    
    function map:set_tile_flag(x, y, flag, value)
        local tile = self:get_tile(x, y)
        if tile then tile.flags[flag] = value end
    end
    
    function map:set_wall(x, y, direction)
        local tile = self:get_tile(x, y)
        if not tile then return end
        if direction == "north" then
            tile.flags.can_travel_n = false
            tile.flags.door_north = false
            tile.tile_layers[2] = 1 -- north wall layer
            if y > 0 then
                self.tiles[y-1][x].flags.can_travel_s = false
            end
        elseif direction == "south" then
            tile.flags.can_travel_s = false
            if y < self.height - 1 then
                self.tiles[y+1][x].flags.can_travel_n = false
                self.tiles[y+1][x].flags.door_north = false
            end
        elseif direction == "east" then
            tile.flags.can_travel_e = false
            tile.flags.door_west = false
            tile.tile_layers[3] = 1 -- west wall layer
            if x < self.width - 1 then
                self.tiles[y][x+1].flags.can_travel_w = false
            end
        elseif direction == "west" then
            tile.flags.can_travel_w = false
            if x > 0 then
                self.tiles[y][x-1].flags.can_travel_e = false
                self.tiles[y][x-1].flags.door_west = false
            end
        end
    end
    
    function map:set_door(x, y, direction)
        local tile = self:get_tile(x, y)
        if not tile then return end
        if direction == "north" then
            tile.flags.door_north = true
            tile.flags.can_travel_n = true
            if y > 0 then
                self.tiles[y-1][x].flags.can_travel_s = true
            end
        elseif direction == "south" then
            if y < self.height - 1 then
                self.tiles[y+1][x].flags.door_north = true
                self.tiles[y+1][x].flags.can_travel_n = true
                tile.flags.can_travel_s = true
            end
        elseif direction == "east" then
            tile.flags.door_west = true
            tile.flags.can_travel_e = true
            if x < self.width - 1 then
                self.tiles[y][x+1].flags.can_travel_w = true
            end
        elseif direction == "west" then
            if x > 0 then
                self.tiles[y][x-1].flags.door_west = true
                self.tiles[y][x-1].flags.can_travel_e = true
                tile.flags.can_travel_w = true
            end
        end
    end
    
    function map:add_object(x, y, obj_type)
        local tile = self:get_tile(x, y)
        if tile then table.insert(tile.objects, obj_type) end
    end
    
    function map:update_pathfinding()
        -- Recalculate can_travel from walls
        for y = 0, self.height - 1 do
            for x = 0, self.width - 1 do
                local tile = self.tiles[y][x]
                tile.flags.can_travel_n = (y > 0 and tile.tile_layers[2] == 0)
                tile.flags.can_travel_s = (y < self.height - 1 and self.tiles[y+1][x].tile_layers[2] == 0)
                tile.flags.can_travel_w = (x > 0 and self.tiles[y][x-1].tile_layers[3] == 0)
                tile.flags.can_travel_e = (x < self.width - 1 and tile.tile_layers[3] == 0)
            end
        end
    end
    
    return map
end

-- Mock path_node
local function createMockPathNode(x, y)
    return {
        x = x, y = y,
        prev = nil, -- self when not in path
        cost = 0,
        distance = 0,
        guess = 0,
        open_idx = 0,
        visited = false,
        value = function(self) return self.cost + self.guess end
    }
end

-- Mock min-heap
local MinHeap = {}
MinHeap.__index = MinHeap

function MinHeap.new()
    return setmetatable({data = {}}, MinHeap)
end

function MinHeap:push(node)
    node.open_idx = #self.data + 1
    table.insert(self.data, node)
    self:promote(node)
end

function MinHeap:pop()
    if #self.data == 0 then return nil end
    local result = self.data[1]
    local last = table.remove(self.data)
    if #self.data > 0 then
        self.data[1] = last
        last.open_idx = 1
        self:demote(1)
    end
    result.open_idx = 0
    return result
end

function MinHeap:promote(node)
    local i = node.open_idx
    while i > 1 do
        local parent_idx = math.floor(i / 2)
        local parent = self.data[parent_idx]
        if parent:value() <= node:value() then break end
        parent.open_idx = i
        self.data[i] = parent
        self.data[parent_idx] = node
        i = parent_idx
    end
    node.open_idx = i
end

function MinHeap:demote(i)
    local node = self.data[i]
    local size = #self.data
    while true do
        local left = i * 2
        local right = i * 2 + 1
        local smallest = i
        
        if left <= size and self.data[left]:value() < node:value() then
            smallest = left
        end
        if right <= size and self.data[right]:value() < self.data[smallest]:value() then
            smallest = right
        end
        if smallest == i then break end
        
        self.data[smallest].open_idx = i
        self.data[i] = self.data[smallest]
        self.data[smallest] = node
        i = smallest
    end
    node.open_idx = i
end

function MinHeap:empty() return #self.data == 0 end

-- Mock pathfinder facade
local function createMockPathfinder()
    local pf = {
        nodes = {},
        dirty_node_list = {},
        dirty_node_count = 0,
        open_heap = MinHeap.new(),
        destination = nil,
        node_cache_width = 0,
        node_cache_height = 0,
    }
    
    function pf:allocate_node_cache(width, height)
        if self.node_cache_width ~= width or self.node_cache_height ~= height then
            self.nodes = {}
            self.dirty_node_list = {}
            for y = 0, height - 1 do
                for x = 0, width - 1 do
                    local idx = y * width + x + 1
                    self.nodes[idx] = createMockPathNode(x, y)
                    self.nodes[idx].prev = self.nodes[idx] -- self = not in path
                end
            end
            self.node_cache_width = width
            self.node_cache_height = height
        else
            for i = 1, self.dirty_node_count do
                local node = self.dirty_node_list[i]
                node.prev = node
                node.visited = false
            end
        end
        self.dirty_node_count = 0
        self.open_heap = MinHeap.new()
    end
    
    function pf:push_to_open_heap(node)
        self.open_heap:push(node)
    end
    
    function pf:pop_from_open_heap()
        return self.open_heap:pop()
    end
    
    function pf:open_heap_promote(node)
        self.open_heap:promote(node)
    end
    
    function pf:get_path_length()
        if self.destination then return self.destination.distance end
        return -1
    end
    
    function pf:get_path_end()
        if self.destination then return self.destination.x, self.destination.y end
        return -1, -1
    end
    
    function pf:push_result()
        if not self.destination then return nil, "no path" end
        local path_x, path_y = {}, {}
        local node = self.destination
        while node do
            table.insert(path_x, 1, node.x + 1) -- 1-based for Lua
            table.insert(path_y, 1, node.y + 1)
            node = node.prev
            if node == node.prev then break end -- reached start (prev=self)
        end
        return path_x, path_y
    end
    
    return pf
end

-- Mock abstract_pathfinder base
local function createAbstractPathfinder(pf)
    local apf = {parent = pf, map = nil}
    
    function apf:init(pMap, startX, startY)
        self.map = pMap
        local iWidth = pMap:get_width()
        pf.destination = nil
        pf:allocate_node_cache(iWidth, pMap:get_height())
        local idx = startY * iWidth + startX + 1
        local node = pf.nodes[idx]
        node.prev = nil
        node.cost = 0
        node.distance = 0
        node.guess = self:guess_distance(node)
        node.visited = true
        pf.dirty_node_list[1] = node
        pf.dirty_node_count = 1
        return node
    end
    
    function apf:search_neighbours(node, flags, iWidth)
        local directions = {
            {dx=-1, dy=0, dir="west", can="can_travel_w", check_door="door_west"},
            {dx=1, dy=0, dir="east", can="can_travel_e", check_door="door_west"},
            {dx=0, dy=-1, dir="north", can="can_travel_n", check_door="door_north"},
            {dx=0, dy=1, dir="south", can="can_travel_s", check_door="door_north"},
        }
        
        for _, d in ipairs(directions) do
            if flags[d.can] then
                local nx, ny = node.x + d.dx, node.y + d.dy
                if nx >= 0 and nx < iWidth and ny >= 0 and ny < self.map:get_height() then
                    local neighbour = pf.nodes[ny * iWidth + nx + 1]
                    if self:try_node(node, flags, neighbour, d.dir, d.check_door) then
                        return true
                    end
                end
            end
        end
        return false
    end
    
    function apf:record_neighbour_if_passable(node, neighbour_flags, neighbour)
        if neighbour.visited then return end
        if not neighbour_flags.passable then return end
        
        local cost = neighbour_flags.avoid_tile and 128 or 1
        
        if neighbour.prev == neighbour then -- first visit
            neighbour.prev = node
            neighbour.cost = node.cost + cost
            neighbour.distance = node.distance + 1
            neighbour.guess = self:guess_distance(neighbour)
            pf.dirty_node_count = pf.dirty_node_count + 1
            pf.dirty_node_list[pf.dirty_node_count] = neighbour
            pf:push_to_open_heap(neighbour)
        elseif node.cost + 1 < neighbour.cost then
            neighbour.prev = node
            neighbour.cost = node.cost + cost
            neighbour.distance = node.distance + 1
            pf:open_heap_promote(neighbour)
        end
    end
    
    -- Virtual methods to override
    function apf:guess_distance(node) return 0 end
    function apf:try_node(node, flags, neighbour, direction, door_flag) return false end
    
    return apf
end

-- ============================================================
-- FINDER IMPLEMENTATIONS (MOCK)
-- ============================================================

-- Basic Pathfinder
local function createBasicPathfinder(pf)
    local apf = createAbstractPathfinder(pf)
    local self = {apf = apf, destination_x = 0, destination_y = 0}
    
    function self:guess_distance(node)
        return math.abs(node.x - self.destination_x) + math.abs(node.y - self.destination_y)
    end
    
    function self:try_node(node, flags, neighbour, direction)
        local neighbour_flags = self.map:get_tile_unchecked(neighbour.x, neighbour.y).flags
        self.apf:record_neighbour_if_passable(node, neighbour_flags, neighbour)
        return false
    end
    
    function self:find_path(pMap, startX, startY, endX, endY)
        if not pMap or not pMap:get_tile(endX, endY) or not pMap:get_tile_unchecked(endX, endY).flags.passable then
            pf.destination = nil
            return false
        end
        self.destination_x = endX
        self.destination_y = endY
        local node = self.apf:init(pMap, startX, startY)
        local iWidth = pMap:get_width()
        local target_idx = endY * iWidth + endX + 1
        local target = pf.nodes[target_idx]
        
        while true do
            if node == target then
                pf.destination = target
                return true
            end
            local flags = pMap:get_tile_unchecked(node.x, node.y).flags
            if self.apf:search_neighbours(node, flags, iWidth) then return true end
            if pf.open_heap:empty() then
                pf.destination = nil
                break
            else
                node = pf:pop_from_open_heap()
            end
        end
        return false
    end
    
    return self
end

-- Hospital Finder
local function createHospitalFinder(pf)
    local apf = createAbstractPathfinder(pf)
    local self = {apf = apf}
    
    function self:guess_distance(node) return 0 end
    
    function self:try_node(node, flags, neighbour, direction)
        local neighbour_flags = self.map:get_tile_unchecked(neighbour.x, neighbour.y).flags
        self.apf:record_neighbour_if_passable(node, neighbour_flags, neighbour)
        return false
    end
    
    function self:find_path_to_hospital(pMap, startX, startY)
        if not pMap or not pMap:get_tile(startX, startY) or not pMap:get_tile_unchecked(startX, startY).flags.passable then
            pf.destination = nil
            return false
        end
        local node = self.apf:init(pMap, startX, startY)
        local iWidth = pMap:get_width()
        
        while true do
            node.visited = true
            local flags = pMap:get_tile_unchecked(node.x, node.y).flags
            if flags.hospital then
                pf.destination = node
                return true
            end
            if self.apf:search_neighbours(node, flags, iWidth) then return true end
            if pf.open_heap:empty() then
                pf.destination = nil
                break
            else
                node = pf:pop_from_open_heap()
            end
        end
        return false
    end
    
    return self
end

-- Idle Tile Finder
local function createIdleTileFinder(pf)
    local apf = createAbstractPathfinder(pf)
    local self = {apf = apf, best_next_node = nil, best_distance = 0, start_x = 0, start_y = 0}
    
    function self:guess_distance(node) return 0 end
    
    function self:try_node(node, flags, neighbour, direction)
        if neighbour.visited then return false end
        
        local neighbour_flags = self.map:get_tile_unchecked(neighbour.x, neighbour.y).flags
        
        -- Door avoidance logic (same as C++)
        local allow = false
        if direction == "north" then allow = not flags.door_north
        elseif direction == "east" then allow = not neighbour_flags.door_west
        elseif direction == "south" then allow = not neighbour_flags.door_north
        elseif direction == "west" then allow = not flags.door_west end
        
        if allow then
            self.apf:record_neighbour_if_passable(node, neighbour_flags, neighbour)
        end
        
        -- Track best neighbour (closest to start)
        if neighbour.prev ~= neighbour then
            local dx = neighbour.x - self.start_x
            local dy = neighbour.y - self.start_y
            local dist = math.sqrt(dx*dx + dy*dy)
            if not self.best_next_node or dist < self.best_distance then
                self.best_next_node = neighbour
                self.best_distance = dist
            end
        end
        return false
    end
    
    function self:find_idle_tile(pMap, startX, startY, n, parcelId)
        if not pMap then pf.destination = nil return false end
        self.start_x = startX
        self.start_y = startY
        self.map = pMap
        
        if parcelId <= 0 or parcelId > pMap:get_parcel_count() or pMap:get_parcel_owner(parcelId) == 0 then
            parcelId = 0
        end
        
        local node = self.apf:init(pMap, startX, startY)
        local iWidth = pMap:get_width()
        local possible_result = nil
        
        while true do
            node.visited = true
            local tile = pMap:get_tile_unchecked(node.x, node.y)
            local flags = tile.flags
            
            local correct_parcel = (parcelId == 0) or (parcelId == tile.iParcelId)
            if not flags.do_not_idle and not flags.avoid_tile and flags.passable and flags.hospital and correct_parcel then
                if n == 0 then
                    pf.destination = node
                    return true
                else
                    possible_result = node
                    n = n - 1
                end
            end
            
            self.best_next_node = nil
            self.best_distance = 0
            
            if self.apf:search_neighbours(node, flags, iWidth) then return true end
            
            if pf.open_heap:empty() then
                pf.destination = nil
                break
            end
            
            if self.best_next_node then
                self.best_next_node.guess = -self.best_next_node.distance
                pf:open_heap_promote(self.best_next_node)
            end
            node = pf:pop_from_open_heap()
        end
        
        if possible_result then
            pf.destination = possible_result
            return true
        end
        return false
    end
    
    return self
end

-- Object Visitor
local function createObjectVisitor(pf)
    local apf = createAbstractPathfinder(pf)
    local self = {apf = apf, L = nil, visit_function_index = 0, max_distance = 0, target_any_object_type = false, target = nil}
    
    function self:guess_distance(node) return 0 end
    
    function self:try_node(node, flags, neighbour, direction)
        local map_node = self.map:get_tile_unchecked(neighbour.x, neighbour.y)
        local neighbour_flags = map_node.flags
        
        -- Count matching objects
        local object_count = 0
        for _, obj in ipairs(map_node.objects) do
            if obj == self.target then object_count = object_count + 1 end
        end
        if self.target_any_object_type and #map_node.objects > 0 then object_count = 1 end
        
        local success = false
        -- Mock Lua callback
        for i = 1, object_count do
            -- In real code: lua_call with (x+1, y+1, direction, distance)
            -- Mock: call provided function
            if self.visit_callback then
                local dir_map = {north=0, east=1, south=2, west=3}
                local result = self.visit_callback(neighbour.x + 1, neighbour.y + 1, dir_map[direction], node.distance)
                if result then success = true end
            end
        end
        
        if success then return true end
        
        -- Continue search if within max distance
        if node.distance < self.max_distance then
            local allow = false
            if direction == "north" then allow = not flags.door_north
            elseif direction == "east" then allow = not neighbour_flags.door_west
            elseif direction == "south" then allow = not neighbour_flags.door_north
            elseif direction == "west" then allow = not flags.door_west end
            
            if allow then
                self.apf:record_neighbour_if_passable(node, neighbour_flags, neighbour)
            end
        end
        return false
    end
    
    function self:visit_objects(pMap, startX, startY, targetType, maxDistance, L, visitFunc, anyType)
        if not pMap then pf.destination = nil return false end
        self.target = targetType
        self.max_distance = maxDistance
        self.target_any_object_type = anyType
        self.visit_callback = visitFunc
        self.map = pMap
        
        local node = self.apf:init(pMap, startX, startY)
        local iWidth = pMap:get_width()
        
        while true do
            node.visited = true
            local flags = pMap:get_tile_unchecked(node.x, node.y).flags
            if self.apf:search_neighbours(node, flags, iWidth) then return true end
            if pf.open_heap:empty() then
                pf.destination = nil
                break
            else
                node = pf:pop_from_open_heap()
            end
        end
        return false
    end
    
    return self
end

-- Pathfinder Facade
local function createPathfinderFacade()
    local pf = createMockPathfinder()
    local facade = {
        basic = createBasicPathfinder(pf),
        hospital = createHospitalFinder(pf),
        idle_tile = createIdleTileFinder(pf),
        object_visitor = createObjectVisitor(pf),
        pf = pf,
    }
    
    function facade:find_path(map, sx, sy, ex, ey) return self.basic:find_path(map, sx, sy, ex, ey) end
    function facade:find_idle_tile(map, sx, sy, n, parcel) return self.idle_tile:find_idle_tile(map, sx, sy, n, parcel) end
    function facade:find_path_to_hospital(map, sx, sy) return self.hospital:find_path_to_hospital(map, sx, sy) end
    function facade:visit_objects(map, sx, sy, objType, maxDist, L, func, anyType) return self.object_visitor:visit_objects(map, sx, sy, objType, maxDist, L, func, anyType) end
    function facade:get_path_length() return self.pf:get_path_length() end
    function facade:get_path_end() return self.pf:get_path_end() end
    function facade:push_result() return self.pf:push_result() end
    function facade:set_default_map(map) self.pf.default_map = map end
    
    return facade
end

-- ============================================================
-- TEST CASES
-- ============================================================

PathfindingScaffold.TestCases = {}

function PathfindingScaffold.TestCases.test_basic_pathfinder()
    print("=== Test: Basic Pathfinder ===")
    local map = createMockMap(10, 10)
    local pf = createPathfinderFacade()
    pf:set_default_map(map)
    
    -- Test 1: Straight line path
    print("Test 1: Straight line (1,1) -> (5,1)")
    assert(pf:find_path(map, 1, 1, 5, 1), "Should find path")
    local len = pf:get_path_length()
    assert(len == 4, "Path length should be 4, got " .. len)
    local px, py = pf:push_result()
    assert(#px == 5, "Should have 5 points")
    print("  PASS: Length " .. len)
    
    -- Test 2: Path around wall
    print("Test 2: Path around wall")
    map = createMockMap(10, 10)
    map:set_wall(3, 1, "east")  -- Block (3,1) to (4,1)
    map:set_wall(3, 2, "east")  -- Block (3,2) to (4,2)
    map:update_pathfinding()
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    assert(pf:find_path(map, 1, 1, 5, 1), "Should find path around wall")
    len = pf:get_path_length()
    assert(len > 4, "Path should be longer than direct")
    print("  PASS: Length " .. len .. " (detour)")
    
    -- Test 3: No path (blocked)
    print("Test 3: Completely blocked")
    map = createMockMap(5, 5)
    for x = 0, 4 do map:set_wall(x, 2, "south") end -- Horizontal wall
    map:update_pathfinding()
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    local result = pf:find_path(map, 2, 1, 2, 3)
    assert(not result, "Should not find path through wall")
    print("  PASS: No path found")
    
    -- Test 4: Through door
    print("Test 4: Through door")
    map = createMockMap(10, 10)
    map:set_wall(5, 1, "east")  -- Wall at (5,1) east
    map:set_door(5, 1, "east")  -- But door there
    map:update_pathfinding()
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    assert(pf:find_path(map, 1, 1, 9, 1), "Should cross door")
    print("  PASS: Crossed door")
    
    -- Test 5: Avoid tile penalty
    print("Test 5: Avoid tile penalty")
    map = createMockMap(10, 10)
    map:set_tile_flag(3, 1, "avoid_tile", true)
    map:set_tile_flag(4, 1, "avoid_tile", true)
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    assert(pf:find_path(map, 1, 1, 5, 1), "Should find path despite avoid tiles")
    local path_x, path_y = pf:push_result()
    -- Path should go around avoid tiles if possible
    print("  PASS: Path found with avoid tiles")
    
    print("Basic Pathfinder: ALL TESTS PASSED\n")
end

function PathfindingScaffold.TestCases.test_hospital_finder()
    print("=== Test: Hospital Finder ===")
    local map = createMockMap(10, 10)
    
    -- Only some tiles are hospital
    for y = 0, 9 do
        for x = 0, 9 do
            map.tiles[y][x].flags.hospital = (x >= 5 and y >= 5) -- Hospital in bottom-right
        end
    end
    
    local pf = createPathfinderFacade()
    pf:set_default_map(map)
    
    -- Test 1: Start outside hospital
    print("Test 1: Find hospital from outside")
    assert(pf:find_path_to_hospital(map, 1, 1), "Should find hospital")
    local ex, ey = pf:get_path_end()
    assert(ex >= 5 and ey >= 5, "Should end in hospital area: " .. ex .. "," .. ey)
    print("  PASS: Found hospital at " .. ex .. "," .. ey)
    
    -- Test 2: Start inside hospital
    print("Test 2: Find hospital from inside")
    assert(pf:find_path_to_hospital(map, 7, 7), "Should find immediately")
    ex, ey = pf:get_path_end()
    assert(ex == 7 and ey == 7, "Should stay at start")
    print("  PASS: Already in hospital")
    
    -- Test 3: Start on impassable
    print("Test 3: Start on impassable tile")
    map.tiles[1][1].flags.passable = false
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    local result = pf:find_path_to_hospital(map, 1, 1)
    assert(not result, "Should fail on impassable start")
    print("  PASS: Correctly rejected")
    
    print("Hospital Finder: ALL TESTS PASSED\n")
end

function PathfindingScaffold.TestCases.test_idle_tile_finder()
    print("=== Test: Idle Tile Finder ===")
    local map = createMockMap(10, 10)
    
    -- Mark some tiles as non-idle
    map:set_tile_flag(5, 5, "do_not_idle", true)
    map:set_tile_flag(6, 5, "avoid_tile", true)
    map:set_tile_flag(7, 5, "passable", false)
    
    local pf = createPathfinderFacade()
    pf:set_default_map(map)
    
    -- Test 1: First idle tile (N=0)
    print("Test 1: First idle tile (N=0)")
    assert(pf:find_idle_tile(map, 1, 1, 0, 1), "Should find idle tile")
    local ex, ey = pf:get_path_end()
    assert(not map.tiles[ey][ex].flags.do_not_idle, "Should not be do_not_idle")
    assert(not map.tiles[ey][ex].flags.avoid_tile, "Should not be avoid_tile")
    assert(map.tiles[ey][ex].flags.hospital, "Should be hospital")
    print("  PASS: Found at " .. ex .. "," .. ey)
    
    -- Test 2: N-th idle tile
    print("Test 2: 3rd idle tile (N=3)")
    assert(pf:find_idle_tile(map, 1, 1, 3, 1), "Should find 3rd idle tile")
    ex, ey = pf:get_path_end()
    print("  PASS: 3rd tile at " .. ex .. "," .. ey)
    
    -- Test 3: Door avoidance
    print("Test 3: Door avoidance")
    map = createMockMap(10, 10)
    -- Create room with door at (5,5) north
    map:set_wall(5, 5, "north")
    map:set_door(5, 5, "north")
    map.tiles[5][4].flags.hospital = true
    map.tiles[5][5].flags.hospital = true
    map:update_pathfinding()
    
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    
    -- Start in room at (5,5), should find idle tile in same room (not cross door)
    assert(pf:find_idle_tile(map, 5, 5, 0, 1), "Should find idle tile")
    ex, ey = pf:get_path_end()
    -- Should be in same room (y >= 5) not cross door to y=4
    assert(ey >= 5, "Should not cross door, got y=" .. ey)
    print("  PASS: Stayed in room (y=" .. ey .. ")")
    
    -- Test 4: Parcel restriction
    print("Test 4: Parcel restriction")
    map = createMockMap(10, 10)
    map.tiles[2][2].iParcelId = 2
    map.tiles[2][2].flags.hospital = true
    map.plot_owner[2] = 1
    map.parcel_count = 3
    
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    assert(pf:find_idle_tile(map, 1, 1, 0, 1), "Should find in parcel 1")
    ex, ey = pf:get_path_end()
    assert(map.tiles[ey][ex].iParcelId == 1, "Should be in parcel 1")
    print("  PASS: Respected parcel boundary")
    
    print("Idle Tile Finder: ALL TESTS PASSED\n")
end

function PathfindingScaffold.TestCases.test_object_visitor()
    print("=== Test: Object Visitor ===")
    local map = createMockMap(10, 10)
    
    -- Place objects
    map:add_object(5, 5, "toilet")
    map:add_object(8, 8, "bin")
    map:add_object(2, 2, "drink_machine")
    
    local pf = createPathfinderFacade()
    pf:set_default_map(map)
    
    local found_objects = {}
    
    -- Test 1: Find specific object type
    print("Test 1: Find toilet")
    local function visit_callback(x, y, dir, dist)
        table.insert(found_objects, {x=x, y=y, type="toilet", dist=dist})
        return false -- Continue search
    end
    assert(pf:visit_objects(map, 1, 1, "toilet", 20, nil, visit_callback, false), "Should find toilet")
    assert(#found_objects == 1, "Should find 1 toilet")
    assert(found_objects[1].x == 5 and found_objects[1].y == 5, "At correct position")
    print("  PASS: Found toilet at " .. found_objects[1].x .. "," .. found_objects[1].y)
    
    -- Test 2: Stop on callback true
    print("Test 2: Stop on first match")
    found_objects = {}
    local function stop_callback(x, y, dir, dist)
        table.insert(found_objects, {x=x, y=y})
        return true -- Stop
    end
    -- Add multiple toilets
    map:add_object(3, 3, "toilet")
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    assert(pf:visit_objects(map, 1, 1, "toilet", 20, nil, stop_callback, false), "Should stop early")
    assert(#found_objects == 1, "Should stop after first")
    print("  PASS: Stopped after first match")
    
    -- Test 3: Max distance limit
    print("Test 3: Max distance limit")
    found_objects = {}
    map = createMockMap(20, 20)
    map:add_object(15, 15, "toilet") -- Far away
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    local result = pf:visit_objects(map, 1, 1, "toilet", 10, nil, visit_callback, false)
    assert(not result, "Should not find beyond max distance")
    assert(#found_objects == 0, "Should find none")
    print("  PASS: Respected max distance")
    
    -- Test 4: Door avoidance
    print("Test 4: Door avoidance")
    map = createMockMap(10, 10)
    map:set_wall(5, 5, "north")
    map:set_door(5, 5, "north")
    map:add_object(5, 4, "toilet") -- Other side of door
    map:add_object(5, 6, "toilet") -- Same side
    map.tiles[5][4].flags.hospital = true
    map.tiles[5][6].flags.hospital = true
    map:update_pathfinding()
    
    found_objects = {}
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    pf:visit_objects(map, 5, 6, "toilet", 20, nil, visit_callback, false)
    assert(#found_objects == 1, "Should only find same-room toilet")
    assert(found_objects[1].y == 6, "Should be at y=6, not y=4")
    print("  PASS: Did not cross door")
    
    -- Test 5: Any object type
    print("Test 5: Any object type")
    map = createMockMap(10, 10)
    map:add_object(3, 3, "toilet")
    map:add_object(7, 7, "bin")
    found_objects = {}
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    pf:visit_objects(map, 1, 1, "toilet", 20, nil, visit_callback, true) -- anyType=true
    assert(#found_objects >= 1, "Should find some object")
    print("  PASS: Found object with anyType=true")
    
    print("Object Visitor: ALL TESTS PASSED\n")
end

function PathfindingScaffold.TestCases.test_min_heap()
    print("=== Test: Min-Heap ===")
    local heap = MinHeap.new()
    
    -- Test push/pop order
    local nodes = {}
    for i = 1, 10 do
        nodes[i] = createMockPathNode(0, 0)
        nodes[i].cost = math.random(1, 100)
        nodes[i].guess = 0
    end
    
    for _, n in ipairs(nodes) do heap:push(n) end
    
    local prev_val = -1
    while not heap:empty() do
        local n = heap:pop()
        assert(n:value() >= prev_val, "Heap order violated: " .. n:value() .. " < " .. prev_val)
        prev_val = n:value()
    end
    print("  PASS: Heap maintains order")
    
    -- Test promote (decrease key)
    heap = MinHeap.new()
    local n1 = createMockPathNode(0,0); n1.cost = 10; n1.guess = 0
    local n2 = createMockPathNode(1,0); n2.cost = 20; n2.guess = 0
    local n3 = createMockPathNode(2,0); n3.cost = 30; n3.guess = 0
    heap:push(n1); heap:push(n2); heap:push(n3)
    
    n2.cost = 5 -- Decrease
    heap:promote(n2)
    
    local first = heap:pop()
    assert(first == n2, "Promoted node should be first")
    print("  PASS: Promote works")
    
    print("Min-Heap: ALL TESTS PASSED\n")
end

function PathfindingScaffold.TestCases.test_node_cache()
    print("=== Test: Node Cache & Dirty List ===")
    local pf = createMockPathfinder()
    local map = createMockMap(5, 5)
    
    -- First allocation
    pf:allocate_node_cache(5, 5)
    assert(#pf.nodes == 25, "Should have 25 nodes")
    assert(#pf.dirty_node_list == 25, "Dirty list capacity 25")
    print("  PASS: Initial allocation")
    
    -- Mark some dirty
    pf.dirty_node_list[1] = pf.nodes[1]
    pf.dirty_node_list[2] = pf.nodes[7]
    pf.dirty_node_count = 2
    pf.nodes[1].cost = 100
    pf.nodes[7].cost = 200
    
    -- Reuse same size
    pf:allocate_node_cache(5, 5)
    assert(pf.nodes[1].cost == 100, "Cost preserved before reset") -- Not reset yet
    assert(pf.nodes[1].prev == pf.nodes[1], "Prev reset to self")
    assert(not pf.nodes[1].visited, "Visited reset")
    assert(pf.dirty_node_count == 0, "Dirty count reset")
    print("  PASS: Reuse resets correctly")
    
    -- Resize
    pf:allocate_node_cache(10, 10)
    assert(#pf.nodes == 100, "Should have 100 nodes after resize")
    print("  PASS: Resize works")
    
    print("Node Cache: ALL TESTS PASSED\n")
end

function PathfindingScaffold.TestCases.test_door_crossing()
    print("=== Test: Door Crossing Logic ===")
    local map = createMockMap(10, 10)
    
    -- Door between (5,5) and (5,4) - door_north on (5,5)
    map:set_wall(5, 5, "north")
    map:set_door(5, 5, "north")
    map:update_pathfinding()
    
    -- Verify flags
    local tile_south = map:get_tile(5, 5)
    local tile_north = map:get_tile(5, 4)
    assert(tile_south.flags.door_north == true, "South tile has door_north")
    assert(tile_north.flags.door_north == false, "North tile does not have door_north")
    assert(tile_south.flags.can_travel_n == true, "Can travel north")
    assert(tile_north.flags.can_travel_s == true, "Can travel south")
    print("  PASS: Door flags symmetric for travel")
    
    -- Test idle finder avoids door
    local pf = createPathfinderFacade()
    pf:set_default_map(map)
    pf:find_idle_tile(map, 5, 5, 0, 1)
    local ex, ey = pf:get_path_end()
    assert(ey >= 5, "Idle finder should not cross door north")
    print("  PASS: Idle finder avoids door")
    
    -- Test basic finder crosses door
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    pf:find_path(map, 5, 5, 5, 4)
    assert(pf:get_path_length() > 0, "Basic finder should cross door")
    print("  PASS: Basic finder crosses door")
    
    print("Door Crossing: ALL TESTS PASSED\n")
end

function PathfindingScaffold.TestCases.test_avoid_tiles()
    print("=== Test: Avoid Tiles ===")
    local map = createMockMap(10, 10)
    
    -- Create corridor with avoid tiles in middle
    for x = 3, 6 do
        map:set_tile_flag(x, 5, "avoid_tile", true)
    end
    
    local pf = createPathfinderFacade()
    pf:set_default_map(map)
    
    -- Path from (1,5) to (9,5) - should detour around avoid tiles if possible
    pf:find_path(map, 1, 5, 9, 5)
    local path_x, path_y = pf:push_result()
    
    -- Check if path goes through avoid tiles
    local avoid_count = 0
    for i = 1, #path_x do
        if map.tiles[path_y[i]-1][path_x[i]-1].flags.avoid_tile then
            avoid_count = avoid_count + 1
        end
    end
    
    -- With 128x cost, should prefer detour (2 steps up + 6 across + 2 down = 10 vs 8 through avoid = 8*128=1024)
    assert(avoid_count == 0, "Should avoid all avoid tiles, got " .. avoid_count)
    print("  PASS: Path detours around avoid tiles")
    
    -- Test forced through avoid (completely blocked otherwise)
    map = createMockMap(5, 5)
    for x = 0, 4 do map:set_wall(x, 2, "south") end -- Wall across
    map:set_tile_flag(2, 2, "avoid_tile", true) -- Only gap is avoid tile
    map.tiles[2][2].flags.can_travel_n = true
    map.tiles[2][2].flags.can_travel_s = true
    map.tiles[2][1].flags.can_travel_s = true
    map.tiles[2][3].flags.can_travel_n = true
    map:update_pathfinding()
    
    pf = createPathfinderFacade()
    pf:set_default_map(map)
    pf:find_path(map, 2, 1, 2, 3)
    assert(pf:get_path_length() > 0, "Should find path through avoid tile when forced")
    print("  PASS: Uses avoid tile when no alternative")
    
    print("Avoid Tiles: ALL TESTS PASSED\n")
end

function PathfindingScaffold.TestCases.test_persistence()
    print("=== Test: Persistence ===")
    local map = createMockMap(10, 10)
    local pf = createPathfinderFacade()
    pf:set_default_map(map)
    
    pf:find_path(map, 1, 1, 5, 5)
    local len1 = pf:get_path_length()
    
    -- Mock persist
    local saved = {}
    function pf:persist_mock()
        saved.length = self.pf:get_path_length()
        saved.width = self.pf.node_cache_width
        saved.height = self.pf.node_cache_height
        saved.path = {}
        local node = self.pf.destination
        while node do
            table.insert(saved.path, 1, {x=node.x, y=node.y})
            node = node.prev
            if node == node.prev then break end
        end
    end
    
    pf:persist_mock()
    
    -- New pathfinder, depersist
    local pf2 = createPathfinderFacade()
    pf2:set_default_map(map)
    
    function pf2:depersist_mock(data)
        self.pf:allocate_node_cache(data.width, data.height)
        local node = nil
        for i = #data.path, 1, -1 do
            local p = data.path[i]
            local idx = p.y * data.width + p.x + 1
            local new_node = self.pf.nodes[idx]
            new_node.distance = #data.path - i
            new_node.cost = #data.path - i
            new_node.prev = node
            if node then
                self.pf.dirty_node_count = self.pf.dirty_node_count + 1
                self.pf.dirty_node_list[self.pf.dirty_node_count] = new_node
            end
            node = new_node
        end
        node.prev = nil
        node.distance = 0
        node.cost = 0
        self.pf.dirty_node_count = self.pf.dirty_node_count + 1
        self.pf.dirty_node_list[self.pf.dirty_node_count] = node
        self.pf.destination = node
    end
    
    pf2:depersist_mock(saved)
    local len2 = pf2:get_path_length()
    
    assert(len1 == len2, "Persisted path length should match: " .. len1 .. " vs " .. len2)
    print("  PASS: Persist/depersist preserves path length")
    
    print("Persistence: ALL TESTS PASSED\n")
end

function PathfindingScaffold.TestCases.test_lua_callback_safety()
    print("=== Test: Lua Callback Safety ===")
    local map = createMockMap(10, 10)
    map:add_object(5, 5, "toilet")
    
    local pf = createPathfinderFacade()
    pf:set_default_map(map)
    
    -- Test error in callback doesn't crash (mock uses pcall)
    print("Test: Callback error handling")
    local function error_callback()
        error("Intentional error")
    end
    
    local ok, err = pcall(function()
        pf:visit_objects(map, 1, 1, "toilet", 20, nil, error_callback, false)
    end)
    
    assert(not ok, "Should catch error")
    assert(err:find("Intentional error"), "Error message preserved")
    print("  PASS: Error caught safely (in mock)")
    print("  NOTE: Real C++ code uses unprotected lua_call - potential crash risk!")
    
    print("Lua Callback Safety: TEST COMPLETE\n")
end

-- ============================================================
-- RUN ALL TESTS
-- ============================================================

function PathfindingScaffold.run_all_tests()
    print("\n==========================================")
    print("PATHFINDING SYSTEM - TEST SUITE (Area 21)")
    print("==========================================\n")
    
    PathfindingScaffold.TestCases.test_min_heap()
    PathfindingScaffold.TestCases.test_node_cache()
    PathfindingScaffold.TestCases.test_basic_pathfinder()
    PathfindingScaffold.TestCases.test_hospital_finder()
    PathfindingScaffold.TestCases.test_idle_tile_finder()
    PathfindingScaffold.TestCases.test_object_visitor()
    PathfindingScaffold.TestCases.test_door_crossing()
    PathfindingScaffold.TestCases.test_avoid_tiles()
    PathfindingScaffold.TestCases.test_persistence()
    PathfindingScaffold.TestCases.test_lua_callback_safety()
    
    print("==========================================")
    print("ALL TEST SUITES PASSED")
    print("==========================================")
end

-- Export for use
PathfindingScaffold.createMockMap = createMockMap
PathfindingScaffold.createPathfinderFacade = createPathfinderFacade
PathfindingScaffold.MinHeap = MinHeap

return PathfindingScaffold
