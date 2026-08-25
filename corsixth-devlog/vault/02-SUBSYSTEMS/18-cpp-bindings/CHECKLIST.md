# C++ Binding Changes - Pre-Fix Checklist

## Before Making Changes

### 1. Understand the Change
- [ ] Identify which metatable(s) affected
- [ ] Determine if new class or modifying existing
- [ ] Check if inheritance hierarchy changes
- [ ] Verify persistence requirements
- [ ] Check cross-module dependencies

### 2. Code Review Preparation
- [ ] Read existing binding for similar class
- [ ] Review `th_lua.h` compatibility functions
- [ ] Review `th_lua_internal.h` registration API
- [ ] Check `lua_metatable` enum for available slots

---

## Implementation Checklist

### New Class Binding

#### Header Setup
- [ ] Add `luaT_classinfo` specialization in `th_lua.h`
- [ ] Add `lua_metatable` entry in `th_lua_internal.h`
- [ ] Forward declare class if needed

#### Binding Functions
- [ ] Constructor: `luaT_stdnew` with correct args
- [ ] All methods use `luaT_testuserdata` for arg 1
- [ ] Cross-class args use `luaT_testuserdata` with upvalue index
- [ ] Return values pushed correctly
- [ ] Stack cleaned with `lua_settop` before return

#### Error Handling
- [ ] `luaL_check*` for required args
- [ ] `luaL_opt*` for optional args with defaults
- [ ] `luaL_argerror` for custom validation
- [ ] Try/catch for C++ exceptions → `lua_error`

#### Persistence (if needed)
- [ ] `__persist` writes all data via `lua_persist_writer`
- [ ] `__depersist` reads in same order
- [ ] `__depersist_size` set (automatic via `lua_class_binding`)
- [ ] `pre_depersist` for reference cycles
- [ ] Weak table registration for cross-refs

#### Registration
- [ ] `lua_class_binding` with correct name, constructor, metatable
- [ ] `set_superclass` if inheriting
- [ ] All `add_function` calls with correct upvalues
- [ ] All `add_metamethod` calls for metamethods
- [ ] `add_constant` for constants
- [ ] Destructor auto-registers in main table

---

### Modifying Existing Binding

#### Function Changes
- [ ] Stack signature matches Lua expectations
- [ ] Upvalue indices correct (account for Lua version)
- [ ] Environment field access uses `luaT_setenvfield`/`getenvfield`
- [ ] No stack leaks (every push has matching pop/settop)

#### Metatable Changes
- [ ] New metamethods added via `add_metamethod`
- [ ] Inheritance chain preserved
- [ ] `__class_name` still correct

#### Cross-Module Impact
- [ ] Check all `lua_register_*` that use this metatable as upvalue
- [ ] Verify `luaT_testuserdata` calls with upvalue index still work
- [ ] Update any `luaT_touserdata_base` class name lists

---

## Testing Checklist

### Unit Tests (Manual)

#### Construction
- [ ] `local obj = th.myClass.new()` works
- [ ] `local obj = th.myClass.new(arg1, arg2)` works
- [ ] Wrong args give clear error message
- [ ] Cannot instantiate abstract base

#### Methods
- [ ] All methods callable: `obj:method()`
- [ ] Return values correct
- [ ] Self (`obj`) preserved for chaining
- [ ] Invalid self gives clear error

#### Type Safety
- [ ] `th.myClass.new()` returns userdata
- [ ] Passing wrong type to method errors
- [ ] Passing nil errors appropriately

#### Inheritance
- [ ] Derived instance passes as base type
- [ ] Base methods work on derived
- [ ] Derived methods work on derived
- [ ] `luaT_touserdata_base` resolves correctly

#### Persistence
- [ ] `obj:persist(writer)` writes data
- [ ] `obj:depersist(reader)` restores data
- [ ] Round-trip: save → load → verify identical
- [ ] Cross-references restored (map ↔ anim, etc.)
- [ ] Weak tables don't leak memory

#### Garbage Collection
- [ ] `__gc` called when object collected
- [ ] No double-free
- [ ] No use-after-free
- [ ] Destructor cleans up C++ resources

#### Edge Cases
- [ ] Multiple instances independent
- [ ] Methods work after persist/depersist
- [ ] Circular refs don't prevent GC
- [ ] Works with Lua 5.1, 5.2, 5.3, 5.4

### Integration Tests
- [ ] Game loads without binding errors
- [ ] Save/load game works
- [ ] Multiplayer sync (if applicable)
- [ ] No memory leaks in long session
- [ ] Performance acceptable (no excessive allocations)

---

## Code Quality

### Style
- [ ] Follows existing naming conventions (`l_<class>_<method>`)
- [ ] Anonymous namespace for binding functions
- [ ] `ZoneScoped` for Tracy profiling in hot paths
- [ ] Comments for complex logic

### Safety
- [ ] No raw `lua_` calls without compatibility wrapper
- [ ] `lua_checkstack` before large pushes
- [ ] `luaL_checktype` for table/func args
- [ ] Proper `const` correctness

### Documentation
- [ ] Function comments explain Lua signature
- [ ] Complex algorithms have inline comments
- [ ] Cross-references documented

---

## Build & Deploy

### Build System
- [ ] New `.cpp` added to CMakeLists.txt / .vcxproj
- [ ] Headers in correct include path
- [ ] Compiles on Windows, Linux, macOS
- [ ] Links without unresolved symbols

### Version Control
- [ ] Changes in logical commits
- [ ] Commit messages reference issue/PR
- [ ] No debug code left in

### Regression Testing
- [ ] Run existing test suite
- [ ] Test on clean build
- [ ] Test with different Lua versions (if possible)

---

## Common Pitfalls to Avoid

| Pitfall | Prevention |
|---------|------------|
| Stack imbalance | Always `lua_settop(L, 1)` at end of methods |
| Wrong upvalue index | Use `luaT_upvalueindex(n)` not hardcoded numbers |
| Missing metatable | Call `luaT_stdnew` with `mt_idx` |
| Lost environment | Pass `true` for `env` in `luaT_stdnew` |
| Persistence order mismatch | Read/write in identical order |
| Inheritance broken | Call `set_superclass` in derived binding |
| GC crash | Ensure `__gc` only calls destructor once |
| Memory leak | Weak tables for circular refs |
| Lua version break | Use `th_lua.h` compat functions |

---

## Quick Validation Commands

```bash
# Build
cmake --build build --target CorsixTH

# Run with debug
./CorsixTH --debug

# Test binding in Lua console
# > th.myClass.new()
# > th.myClass.new(1, "test")
# > obj = th.myClass.new()
# > obj:method()

# Check memory
valgrind --leak-check=full ./CorsixTH
```

---

## Sign-Off

- [ ] Author review complete
- [ ] Peer review complete
- [ ] All checklist items verified
- [ ] Ready for merge

---

*Checklist version 1.0 - Update as binding system evolves*
