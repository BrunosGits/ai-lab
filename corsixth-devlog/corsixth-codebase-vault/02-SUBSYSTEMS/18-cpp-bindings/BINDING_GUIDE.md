# C++ Lua Binding Guide for CorsixTH

## Adding a New C++ Class to Lua

### Step 1: Add Metatable Slot

Edit `th_lua_internal.h`, add to `lua_metatable` enum:

```cpp
enum class lua_metatable {
  // ... existing entries ...
  my_new_class,      // ADD HERE
  
  count
};
```

### Step 2: Add luaT_classinfo Specialization

In `th_lua.h` (after line 377), add:

```cpp
class MyClass;
template <>
struct luaT_classinfo<MyClass> {
  static inline const char* name() { return "MyClass"; }
};
```

### Step 3: Create Binding Functions

Create or edit appropriate `th_lua_*.cpp` file:

```cpp
namespace {

int l_myclass_new(lua_State* L) {
  // Constructor arguments from Lua
  int arg1 = luaL_optinteger(L, 2, 0);
  const char* arg2 = luaL_optstring(L, 3, "default");
  
  // Create with metatable + environment table
  luaT_stdnew<MyClass>(L, luaT_environindex, true, arg1, arg2);
  return 1;
}

int l_myclass_method(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  // ... implementation
  return 1;  // number of return values
}

int l_myclass_persist(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  luaT_rotate(L, 1, -1);  // writer at bottom
  lua_persist_writer* writer = (lua_persist_writer*)lua_touserdata(L, 1);
  
  writer->write_int(obj->getValue());
  writer->write_string(obj->getName());
  return 0;
}

int l_myclass_depersist(lua_State* L) {
  void* ud = luaT_testuserdata<MyClass>(L);
  lua_settop(L, 2);
  lua_insert(L, 1);
  lua_persist_reader* reader = (lua_persist_reader*)lua_touserdata(L, 1);
  
  int value;
  std::string name;
  reader->read_int(value);
  reader->read_string(name);
  
  new (ud) MyClass(value, name);
  return 0;
}

}  // namespace
```

### Step 4: Register Class

In `lua_register_*` function:

```cpp
void lua_register_myfeature(const lua_register_state* pState) {
  lua_class_binding<MyClass> lcb(pState, "myClass", l_myclass_new,
                                  lua_metatable::my_new_class);
  
  // Instance methods
  lcb.add_function(l_myclass_method, "methodName");
  
  // Metamethods (if needed)
  lcb.add_metamethod(l_myclass_persist, "persist");
  lcb.add_metamethod(l_myclass_depersist, "depersist");
  
  // Constants
  lcb.add_constant("MAX_VALUE", 100);
}
```

### Step 5: Call Registration in luaopen_th

Edit `th_lua.cpp`:

```cpp
// Add declaration at top
void lua_register_myfeature(const lua_register_state* pState);

// Call in luaopen_th (appropriate order)
lua_register_myfeature(pState);
```

### Step 6: Add to Build System

Ensure new `.cpp` is in `CMakeLists.txt` or `CorsixTH.vcxproj`.

---

## Inheritance Patterns

### Single Inheritance

```cpp
// Base (abstract or concrete)
lua_class_binding<Base> lcb(pState, "base", l_base_new, lua_metatable::base);
lcb.add_function(l_base_method, "baseMethod");

// Derived
lua_class_binding<Derived> lcb2(pState, "derived", l_derived_new, lua_metatable::derived);
lcb2.set_superclass(lua_metatable::base);  // Sets metatable[1] and chains __index
lcb2.add_function(l_derived_method, "derivedMethod");
```

### Polymorphic Type Resolution

For functions accepting base class but needing derived:

```cpp
// In header
Base* luaT_getderived(lua_State* L, int idx = 1, bool required = true);

// In cpp
Base* luaT_getderived(lua_State* L, int idx, bool required) {
  return luaT_touserdata_base<Base, Derived1, Derived2>(
      L, idx, {"Derived1", "Derived2"});
}

// Usage
int l_some_func(lua_State* L) {
  Base* obj = luaT_getderived(L, 1);
  if (Derived1* d = dynamic_cast<Derived1*>(obj)) {
    // handle Derived1
  }
}
```

---

## Debugging Binding Issues

### Common Issues & Solutions

| Symptom | Cause | Fix |
|---------|-------|-----|
| "MyClass expected, got userdata" | Wrong metatable in upvalue | Verify `lua_metatable` enum matches registration |
| "attempt to call a nil value" | Function not registered | Check `add_function` call, verify registration order |
| Crash in `luaT_testuserdata` | Stack index mismatch | Use `luaT_upvalueindex(n)` for upvalue-based access |
| Persistence fails | Missing `__depersist_size` | Constructor sets it automatically via `lua_class_binding` |
| Inheritance not working | `set_superclass` not called | Call `lcb.set_superclass(lua_metatable::parent)` |
| Environment table lost | Forgot `env=true` in `luaT_stdnew` | Pass `true` as 3rd argument |

### Debugging Tools

```cpp
// Print stack contents
void luaT_printstack(lua_State* L);

// Print single value
void luaT_printvalue(lua_State* L, int idx);

// Print table (raw)
void luaT_printrawtable(lua_State* L, int idx);

// Get class name from userdata
const char* class_name;
void* ud;
luaT_get_userdata_classname(L, idx, &class_name, &ud);
printf("Class: %s\n", class_name);
```

### Runtime Verification

```cpp
// In binding function - verify metatable
lua_getmetatable(L, 1);
lua_rawgeti(L, -1, 1);  // Get parent metatable
if (!lua_isnil(L, -1)) {
  printf("Has parent class\n");
}
lua_pop(L, 2);

// Verify __class_name
lua_getmetatable(L, 1);
lua_getfield(L, -1, "__index");
lua_getmetatable(L, -1);
lua_getfield(L, -1, "__class_name");
printf("Class name: %s\n", lua_tostring(L, -1));
lua_pop(L, 4);
```

---

## Common Patterns

### Pattern 1: Constructor with Optional Args

```cpp
int l_new(lua_State* L) {
  int required = luaL_checkinteger(L, 2);
  int optional1 = luaL_optinteger(L, 3, DEFAULT1);
  bool optional2 = lua_toboolean(L, 4);
  const char* optional3 = luaL_optstring(L, 5, "default");
  
  luaT_stdnew<MyClass>(L, luaT_environindex, true, required, optional1, optional2, optional3);
  return 1;
}
```

### Pattern 2: Cross-Reference via Environment

```cpp
int l_set_sheet(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  SpriteSheet* sheet = luaT_testuserdata<SpriteSheet>(L, 2);  // Verified via upvalue
  
  obj->setSheet(sheet);
  luaT_setenvfield(L, 1, "sheet");  // Store in obj's env table
  return 1;
}

int l_get_sheet(lua_State* L) {
  luaT_testuserdata<MyClass>(L);
  luaT_getenvfield(L, 1, "sheet");  // Retrieve from env
  return 1;
}

// Registration
lcb.add_function(l_set_sheet, "setSheet", lua_metatable::sheet);
lcb.add_function(l_get_sheet, "getSheet");
```

### Pattern 3: Factory Returning Different Types

```cpp
int l_factory(lua_State* L) {
  int type = luaL_checkinteger(L, 2);
  
  if (type == 1) {
    luaT_stdnew<TypeA>(L, luaT_environindex, true);
  } else {
    luaT_stdnew<TypeB>(L, luaT_environindex, true);
  }
  return 1;
}
```

### Pattern 4: Callback Registration

```cpp
int l_set_callback(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  luaL_checktype(L, 2, LUA_TFUNCTION);
  
  // Store callback in environment
  lua_settop(L, 2);
  luaT_setenvfield(L, 1, "callback");
  return 0;
}

int l_trigger_callback(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  luaT_getenvfield(L, 1, "callback");
  if (lua_isfunction(L, -1)) {
    lua_pushinteger(L, 42);  // argument
    lua_call(L, 1, 0);
  }
  return 0;
}
```

### Pattern 5: Array/Table Processing

```cpp
int l_process_array(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  luaL_checktype(L, 2, LUA_TTABLE);
  
  lua_pushnil(L);
  while (lua_next(L, 2)) {
    int key = luaL_checkinteger(L, -2);
    int value = luaL_checkinteger(L, -1);
    obj->addItem(key, value);
    lua_pop(L, 1);  // Pop value, keep key for next iteration
  }
  return 0;
}
```

### Pattern 6: Error Handling

```cpp
int l_risky_operation(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  
  try {
    obj->riskyOperation();
    lua_pushboolean(L, 1);
    return 1;
  } catch (const std::exception& e) {
    lua_pushboolean(L, 0);
    lua_pushstring(L, e.what());
    return 2;
  }
}
```

### Pattern 7: Metamethod Operators

```cpp
int l_add(lua_State* L) {
  MyClass* a = luaT_testuserdata<MyClass>(L, 1);
  MyClass* b = luaT_testuserdata<MyClass>(L, 2);
  
  auto result = std::make_unique<MyClass>(*a + *b);
  luaT_stdnew<MyClass>(L, luaT_environindex, true, *result);
  return 1;
}

int l_tostring(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  lua_pushfstring(L, "MyClass(%d)", obj->getValue());
  return 1;
}

int l_eq(lua_State* L) {
  MyClass* a = luaT_testuserdata<MyClass>(L, 1);
  MyClass* b = luaT_testuserdata<MyClass>(L, 2);
  lua_pushboolean(L, *a == *b);
  return 1;
}

// Registration
lcb.add_metamethod(l_add, "add");
lcb.add_metamethod(l_tostring, "tostring");
lcb.add_metamethod(l_eq, "eq");
```

---

## Persistence Best Practices

### Pre-depersist for Reference Cycles

```cpp
// In th_lua_anims.cpp pattern
int l_anim_pre_depersist(lua_State* L) {
  Animation* anim = luaT_testuserdata<Animation>(L);
  new (anim) Animation();  // Construct early to break cycles
  return 0;
}

int l_anim_depersist(lua_State* L) {
  Animation* anim = luaT_testuserdata<Animation>(L);
  lua_settop(L, 2);
  lua_insert(L, 1);
  lua_persist_reader* reader = (lua_persist_reader*)lua_touserdata(L, 1);
  
  // Register in weak table BEFORE depersisting (for cross-refs)
  lua_rawgeti(L, luaT_environindex, 2);
  lua_pushlightuserdata(L, anim);
  lua_pushvalue(L, 2);
  lua_settable(L, -3);
  lua_pop(L, 1);
  
  anim->depersist(reader);
  return 0;
}

// Registration
lcb.add_metamethod(l_anim_pre_depersist, "pre_depersist");
lcb.add_metamethod(l_anim_depersist, "depersist");
```

### Depersist Size

The `__depersist_size` is set automatically by `lua_class_binding` constructor. Ensure your class has a default constructor for placement new during depersist.

---

## Testing Checklist

Before committing new bindings:

- [ ] Class compiles and links
- [ ] `luaopen_th` loads without error
- [ ] Constructor works with all arg combinations
- [ ] All methods return correct values
- [ ] Type checking rejects wrong types with clear error
- [ ] Inheritance works (derived passes as base)
- [ ] Persistence: save → load → verify data intact
- [ ] Cross-references survive persist/depersist
- [ ] Garbage collection calls destructor (no leaks)
- [ ] Weak tables don't prevent GC
- [ ] No stack leaks in binding functions
- [ ] Works with Lua 5.1, 5.2, 5.3, 5.4

---

## Performance Tips

1. **Minimize stack operations** - Use `lua_settop` to clean up
2. **Reuse upvalues** - Pass metatables as upvalues, not globals
3. **Cache lookups** - Environment table for cross-refs
4. **Avoid string allocation** - Use `lua_pushliteral` for constants
5. **ZoneScoped for profiling** - Add `ZoneScoped;` in hot paths

```cpp
// Good: minimal stack manipulation
int l_method(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  int arg = luaL_checkinteger(L, 2);
  obj->doSomething(arg);
  lua_settop(L, 1);  // Clean stack, return self
  return 1;
}

// Avoid: unnecessary pops/pushes
int l_method_bad(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  int arg = luaL_checkinteger(L, 2);
  lua_pop(L, 1);  // Don't do this - lua_settop is cleaner
  obj->doSomething(arg);
  lua_pushvalue(L, 1);
  return 1;
}
```

---

## Lua Version Compatibility

The binding layer handles differences:

| Feature | 5.1 | 5.2+ | Handled By |
|---------|-----|------|------------|
| Environments | `setfenv`/`getfenv` | `setuservalue`/`getuservalue` | `luaT_setenvfield`/`getenvfield` |
| `luaL_register` | Yes | No | `luaT_register` |
| `lua_rotate` | No | Yes | `luaT_rotate` |
| `lua_resume` | Different sig | Different sig | `luaT_resume` |
| `lua_load` mode arg | No | Yes | `luaT_load` |
| Lightuserdata equality | Pointer | Pointer | Native |

Always use compatibility functions from `th_lua.h`.

---

## Quick Reference Card

```cpp
// Create object
T* obj = luaT_stdnew<T>(L, mt_idx, true, args...);

// Get object (required)
T* obj = luaT_testuserdata<T>(L, idx);

// Get object (optional)
T* obj = luaT_testuserdata<T>(L, idx, false);

// Get with explicit metatable (from upvalue)
T* obj = luaT_testuserdata<T>(L, idx, lua_upvalueindex(n));

// Polymorphic get
Base* obj = luaT_touserdata_base<Base, D1, D2>(L, idx, {"D1", "D2"});

// Set metatable
lua_pushvalue(L, mt_idx);
lua_setmetatable(L, -2);

// Set environment field
luaT_setenvfield(L, obj_idx, "key");

// Get environment field
luaT_getenvfield(L, obj_idx, "key");

// Register function with metatable upvalue
add_lua_function(pState, fn, "name", lua_metatable::other_class);

// Register function with string upvalue
add_lua_function(pState, fn, "name", "string_constant");

// In lua_class_binding
lcb.add_function(fn, "name", lua_metatable::other);      // method
lcb.add_metamethod(fn, "name", lua_metatable::other);    // metamethod
lcb.set_superclass(lua_metatable::parent);                // inheritance
lcb.add_constant("NAME", value);                          // constant
```


## Related Pages

- [[18-cpp-bindings/SUMMARY]]
- [[18-cpp-bindings/CHECKLIST]]
- [[18-cpp-bindings/MAP]]
- [[18-cpp-bindings/SCAFFOLD]]
