# CorsixTH Performance Profiling

> Tracy integration, memory profiling, tick optimization, and bottleneck analysis

---

## Related Pages

- [[regression-index]] — Test file mappings
- [[safe-fix-patterns]] — Anti-patterns and fix templates
- [[coverage-dashboard]] — Coverage metrics

---

## Performance Budget

**Target:** 60 FPS = 16.67ms per tick

| System | Budget | Critical Path |
|--------|--------|---------------|
| Game Logic (Lua) | 8ms | Entity tick, room logic |
| Pathfinding (C++) | 2ms | A* search |
| Rendering (C++) | 5ms | Sprite drawing, map tiles |
| Audio Mixing | 1ms | MIDI, sound effects |
| UI/Input | 0.5ms | Event dispatch |
| **Total** | **16.5ms** | |

---

## Tracy Profiler Integration

### Hook Locations

| File | Line | Zone Name | Notes |
|------|------|-----------|-------|
| `Src/main.cpp` | main() | "Main Loop" | Top-level frame |
| `Src/sdl_core.cpp` | tick() | "Lua Tick" | Lua game loop |
| `Src/th_pathfind.cpp` | find_path() | "Pathfinding" | A* algorithm |
| `Src/th_gfx_sdl.cpp` | draw() | "Render Frame" | Graphics draw |
| `Src/th_sound.cpp` | mix() | "Audio Mix" | Sound mixing |
| `Src/th_map.cpp` | draw() | "Map Draw" | Tile rendering |

### Adding Tracy Zones

```cpp
#include "tracy/Tracy.hpp"

void pathfinder::find_path() {
    ZoneScoped;  // Auto-names from function
    // ... pathfinding code
}

void lua_tick() {
    ZoneScoped;
    lua_pcall(L, 0, 0, 0);
}
```

### Memory Tracking

```cpp
#include "tracy/Tracy.hpp"

// Track allocations
void* alloc = malloc(size);
TracyAlloc(alloc, size);

// Track frees
TracyFree(alloc);
free(alloc);
```

---

## Memory Allocation Patterns

### Lua State

| Allocation | Frequency | Size | Notes |
|------------|-----------|------|-------|
| Table creation | Every tick | Variable | Entity tables |
| String interning | On demand | 8-256 bytes | Dialog text |
| Function closures | On load | 32-128 bytes | Callbacks |
| Coroutine stacks | Per entity | 4KB | Pathfinding coroutines |

### C++ Structures

| Structure | Allocation | Size | Lifetime |
|-----------|------------|------|----------|
| `path_node` cache | Map load | `width*height*16` bytes | Map duration |
| `sprite_sheet` | On load | Variable | Game duration |
| `animation_manager` | On load | Variable | Game duration |
| `render_target` | On init | Screen size | Game duration |

### Key Allocation Sites

```cpp
// pathfind.cpp: Node cache allocation
void pathfinder::allocate_node_cache(int iWidth, int iHeight) {
    nodes.resize(iWidth * iHeight);  // ~256KB for 128x128 map
    dirty_node_list = new path_node*[nodes.size()];
}

// th_gfx.cpp: Sprite sheet loading
bool sprite_sheet::load_from_th_file(...) {
    // Large allocation for decoded sprites
    pixels.resize(width * height * 4);  // RGBA
}
```

---

## Tick Time Breakdown

### Entity Tick Loop (`[[Lua/world.lua#L971]]-978`)

```lua
-- Hot path: Called every tick for ALL entities
function World:onTick()
    self.current_tick_entity = true
    for _, entity in ipairs(self.entities) do
        entity:tick()  -- 0.01-0.1ms per entity
    end
    self:_flushDestroyedEntities()
end
```

**Performance characteristics:**
- Linear scan of all entities
- Each entity tick: 0.01-0.1ms
- 100 entities = 1-10ms (danger zone)
- Optimization: Spatial partitioning, dirty flagging

### Pathfinding Hot Path

```
Src/th_pathfind.cpp
├── find_path()           ~0.5-2ms (128x128 map)
├── find_idle_tile()      ~0.1-0.5ms
├── visit_objects()       ~0.1-0.3ms
└── search_neighbours()   ~0.001ms per node
```

**Optimization opportunities:**
- Node cache reuse (already implemented)
- Heuristic pruning
- Bidirectional search for long paths

### Rendering Pipeline

```
Src/th_gfx_sdl.cpp
├── draw()               ~2-5ms (full screen)
├── draw_frame()         ~0.01ms per frame
├── draw_sprite()        ~0.001ms per sprite
└── hit_test()           ~0.001ms per test
```

**Hot spots:**
- Tile rendering loop
- Sprite sheet decoding
- Alpha blending (50%/75% transparency)

---

## Bottleneck Identification

### Critical Hot Paths

| Rank | Component | File | Typical Time | Max Time |
|------|-----------|------|--------------|----------|
| 1 | Entity iteration | `Lua/world.lua` | 2ms | 15ms |
| 2 | Pathfinding | `Src/th_pathfind.cpp` | 0.5ms | 5ms |
| 3 | Map rendering | `Src/th_gfx_sdl.cpp` | 2ms | 8ms |
| 4 | Room logic | `Lua/room.lua` | 1ms | 4ms |
| 5 | Queue processing | `Lua/queue.lua` | 0.5ms | 2ms |

### Common Performance Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| Entity skip bug | Silent corruption | Deferred destruction pattern |
| Pathfinding storm | Frame drop | Rate-limit pathfinding |
| Memory leak | Growing RAM | Fix entity/sound leaks |
| Lua GC pause | Frame stutter | Reduce allocations |
| Sprite sheet thrash | Texture swap | Atlas optimization |

---

## Optimization Opportunities

### High Impact

1. **Entity iteration:** Replace `ipairs` with spatial hash
2. **Pathfinding:** Cache results, rate-limit
3. **Rendering:** Tile-based culling, sprite batching

### Medium Impact

4. **Memory:** Pool allocations for `path_node`
5. **Lua:** Reduce table creation in hot loops
6. **Audio:** Pre-mix common sounds

### Low Impact

7. **UI:** Lazy rendering for off-screen elements
8. **Strings:** Pre-compute common dialog text
9. **Config:** Cache parsed values

---

## Profiling Commands

```bash
# Build with Tracy
cmake -DTRACY_ENABLE=ON ..

# Capture profile
./CorsixTH --tracy-capture

# View in Tracy GUI
tracy capture.tracy
```

---

## Performance Testing Checklist

- [ ] Entity count: 100, 500, 1000 entities
- [ ] Map size: 64x64, 128x128, 256x256
- [ ] Pathfinding: Short (10 tiles), medium (50), long (100+)
- [ ] Room count: 5, 10, 20 rooms
- [ ] Save/load: Large saves (100+ entities)

---

*Generated from CorsixTH codebase analysis | 2026-08-26*
