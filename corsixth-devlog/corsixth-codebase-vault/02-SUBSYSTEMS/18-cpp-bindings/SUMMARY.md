# C++ Lua Bindings in CorsixTH - Deep Research Summary

## Table of Contents
1. [Overview](#overview)
2. [Binding Infrastructure](#binding-infrastructure)
3. [Core Template Functions](#core-template-functions)
4. [Metatable System](#metatable-system)
5. [lua_class_binding RAII Template](#lua_class_binding-raii-template)
6. [add_lua_function & luaT_setclosure](#add_lua_function--luat_setclosure)
7. [Master Registration: luaopen_th()](#master-registration-luaopen_th)
8. [Each lua_register_* Function](#each-lua_register_-function)
9. [Code Examples](#code-examples)

---

## Overview

CorsixTH uses a custom C++-to-Lua binding system built on top of the Lua C API (compatible with Lua 5.1 through 5.4). The binding infrastructure provides:

- **Type-safe userdata creation** with placement new into Lua-managed memory
- **Automatic metatable setup** with inheritance traversal support
- **RAII-based class registration** via `lua_class_binding` template
- **Upvalue-based dependency injection** for cross-module references
- **Persistence support** with `__persist`/`__depersist` metamethods
- **Weak table management** for circular reference handling

The system exposes **23 distinct metatable slots** (see `lua_metatable` enum in `th_lua_internal.h:31-58`) representing all bindable C++ classes.

---

## Binding Infrastructure

### File Locations
- **Core infrastructure**: `/tmp/CorsixTH/CorsixTH/Src/th_lua.h` (lines 37-549)
- **Registration internals**: `/tmp/CorsixTH/CorsixTH/Src/th_lua_internal.h` (lines 31-217)
- **Master registration**: `/tmp/CorsixTH/CorsixTH/Src/th_lua.cpp` (lines 320-358)

### Key Design Principles

1. **Placement new into userdata**: Objects are constructed directly in Lua-allocated memory via `luaT_new()`
2. **Metatable-per-class**: Each C++ class gets a unique metatable stored in `lua_register_state.metatables[]`
3. **Environment as dependency container**: The Lua environment table (`luaT_environindex`) holds cross-references
4. **Inheritance via metatable chaining**: `luaT_testuserdata()` traverses `__index` chain for polymorphic checks
5. **Class name registry**: `__class_name` field on method table metatable enables RTTI-like lookup

---

## Core Template Functions

### luaT_new<T>(L, args...)

**Location**: `th_lua.h:179-191`

```cpp
template <typename T, typename... Ts>
T* luaT_new(lua_State* L, Ts... args) {
  return new (lua_newuserdata(L, sizeof(T))) T(args...);
}
```

**Purpose**: Allocates a userdata block of `sizeof(T)` bytes and constructs `T` in-place using placement new with forwarded constructor arguments.

**Usage**:
```cpp
// Default construction
level_map* map = luaT_new<level_map>(L);

// With arguments
palette* pal = luaT_new<palette>(L, data, len, is_pal8);
```

**Key Points**:
- No metatable or environment setup - caller must call `lua_setmetatable` and optionally `lua_setfenv`
- Returns raw pointer to constructed object
- Exception safety: If constructor throws, Lua's memory allocator handles cleanup

---

### luaT_stdnew<T>(L, mt_idx, env, args...)

**Location**: `th_lua.h:219-230`

```cpp
template <class T, typename... Args>
inline T* luaT_stdnew(lua_State* L, int mt_idx = luaT_environindex,
                      bool env = false, Args&&... args) {
  T* p = luaT_new<T>(L, std::forward<Args>(args)...);
  lua_pushvalue(L, mt_idx);
  lua_setmetatable(L, -2);
  if (env) {
    lua_newtable(L);
    lua_setfenv(L, -2);
  }
  return p;
}
```

**Purpose**: Standard object creation with metatable assignment and optional environment table.

**Parameters**:
- `mt_idx`: Stack index of metatable (defaults to `luaT_environindex` - the current module's metatable)
- `env`: If true, creates and sets a new environment table for the userdata

**Usage**:
```cpp
// Standard construction with metatable from upvalue
animation_manager* anims = luaT_stdnew<animation_manager>(L, luaT_environindex, true);

// Construction with explicit metatable index
sound_archive* arc = luaT_stdnew<sound_archive>(L, mt_idx, false, data, len);
```

---

### luaT_testuserdata<T>(L, idx, mt_idx, required)

**Location**: `th_lua.h:379-416`

```cpp
template <class T>
T* luaT_testuserdata(lua_State* L, int idx, int mt_idx, bool required = true) {
  if (mt_idx > LUA_REGISTRYINDEX && mt_idx < 0) {
    mt_idx = lua_gettop(L) + mt_idx + 1;
  }

  void* ud = lua_touserdata(L, idx);
  if (ud != nullptr && lua_getmetatable(L, idx) != 0) {
    while (true) {
      if (lua_equal(L, mt_idx, -1) != 0) {
        lua_pop(L, 1);
        return static_cast<T*>(ud);
      }
      // Go up one inheritance level, if there is one.
      if (lua_type(L, -1) != LUA_TTABLE) break;
      lua_rawgeti(L, -1, 1);
      lua_replace(L, -2);
    }
    lua_pop(L, 1);
  }

  if (required) {
    const char* msg = lua_pushfstring(L, "%s expected, got %s",
                    luaT_classinfo<T>::name(), luaL_typename(L, idx));
    luaL_argerror(L, idx, msg);
    assert(false);
  }
  return nullptr;
}
```

**Purpose**: Validates that a stack value is a userdata of type `T` (or derived), with full inheritance traversal.

**Inheritance Traversal Algorithm** (lines 388-397):
1. Get the userdata's metatable
2. Compare against expected metatable (`mt_idx`)
3. If not equal, check if metatable has `__index` that is a table
4. Get `metatable[1]` (set by `lua_class_binding::set_superclass()`)
5. Replace current metatable with parent and repeat
6. If no parent or not a table, fail

**Usage**:
```cpp
// Required argument (throws error if wrong type)
level_map* map = luaT_testuserdata<level_map>(L, 1);

// Optional argument (returns nullptr if wrong type)
sprite_sheet* sheet = luaT_testuserdata<sprite_sheet>(L, 2, false);

// With explicit metatable index (for upvalue-based access)
pathfinder* pf = luaT_testuserdata<pathfinder>(L, 1, luaT_upvalueindex(1));
```

---

### luaT_touserdata_base<B, T1, T2>

**Location**: `th_lua.h:520-547`

```cpp
template <typename B, typename T1, typename T2>
B* luaT_touserdata_base(lua_State* L, int idx,
                        const std::initializer_list<const char*>& class_names) {
  static_assert(std::is_base_of<B, T1>::value, "B must be a base class for T1");
  static_assert(std::is_base_of<B, T2>::value, "B must be a base class for T2");

  const char* class_name = nullptr;
  void* p;
  int stack = luaT_get_userdata_classname(L, idx, &class_name, &p);
  if (class_name == nullptr) return nullptr;

  auto it = class_names.begin();
  if (std::strcmp(class_name, *it) == 0) {
    lua_pop(L, stack);
    return static_cast<T1*>(p);
  }
  it++;
  if (std::strcmp(class_name, *it) == 0) {
    lua_pop(L, stack);
    return static_cast<T2*>(p);
  }
  return nullptr;
}
```

**Purpose**: Resolves a polymorphic userdata to one of two known derived types using the `__class_name` registry.

**Usage** (`th_lua_gfx.cpp:51-61`):
```cpp
font* luaT_getfont(lua_State* L) {
  font* p = luaT_touserdata_base<font, bitmap_font, freetype_font>(
      L, 1, {"bitmap_font", "freetype_font"});
  return p;
}
```

---

## Metatable System

### lua_metatable Enum (23 Slots)

**Location**: `th_lua_internal.h:31-58`

```cpp
enum class lua_metatable {
  map,              // level_map
  palette,          // palette
  sheet,            // sprite_sheet
  font,             // font (base)
  bitmap_font,      // bitmap_font
  freetype_font,    // freetype_font
  layers,           // layers
  anims,            // animation_manager
  anim,             // animation
  pathfinder,       // pathfinder
  surface,          // render_target
  bitmap,           // raw_bitmap
  cursor,           // cursor
  lfs_ext,          // lfs_ext
  sound_archive,    // sound_archive
  sound_fx,         // sound_player
  movie,            // movie_player
  string,           // (unused slot)
  window_base,      // abstract_window
  sprite_list,      // sprite_render_list
  string_proxy,     // string_proxy
  line,             // line_sequence
  iso_fs,           // iso_filesystem
  midi_player,      // th_lua_midi_player

  count
};
```

### Metatable Structure

Each metatable follows this layout:

```
metatable (indexed by lua_metatable)
├── __index = method_table
├── __gc = luaT_stdgc<T> (destructor)
├── __depersist_size = sizeof(T)
├── __persist = persist_func
├── __depersist = depersist_func
├── [1] = parent_metatable (for inheritance, set by set_superclass)
└── ... other metamethods
```

Method table metatable:
```
method_table_metatable
└── __class_name = "ClassName" (for luaT_touserdata_base)
```

### Registration State

**Location**: `th_lua_internal.h:60-65`

```cpp
struct lua_register_state {
  lua_State* L;
  int metatables[static_cast<size_t>(lua_metatable::count)];
  int main_table;
  int top;
};
```

Created in `luaopen_th()` (th_lua.cpp:324-333):
1. Creates all 23 metatables upfront
2. Creates main module table
3. Stores stack position for restoration

---

## lua_class_binding RAII Template

**Location**: `th_lua_internal.h:106-215`

### Constructor

```cpp
lua_class_binding(const lua_register_state* pState, const char* name,
                  lua_CFunction new_fn, lua_metatable mt)
  : pState(pState), class_name(name), class_metatable(...) {
  lua_settop(pState->L, pState->top);
  
  // Make metatable the environment for registered functions
  lua_pushvalue(pState->L, class_metatable);
  lua_replace(pState->L, luaT_environindex);
  
  // Set __gc metamethod to C++ destructor
  luaT_pushcclosure(pState->L, luaT_stdgc<T, luaT_environindex>, 0);
  lua_setfield(pState->L, class_metatable, "__gc");
  
  // Set __depersist_size
  lua_pushinteger(pState->L, sizeof(T));
  lua_setfield(pState->L, class_metatable, "__depersist_size");
  
  // Create methods table; call it -> new instance
  luaT_pushcclosuretable(pState->L, new_fn, 0);
  
  // Set __class_name on methods metatable
  lua_getmetatable(pState->L, -1);
  lua_pushstring(pState->L, class_name);
  lua_setfield(pState->L, -2, "__class_name");
  lua_pop(pState->L, 1);
  
  // Set __index to methods table
  lua_pushvalue(pState->L, -1);
  lua_setfield(pState->L, class_metatable, "__index");
}
```

### Key Methods

| Method | Purpose |
|--------|---------|
| `set_superclass(mt)` | Sets up inheritance: `metatable[1] = parent_metatable`, chains `__index` |
| `add_constant(name, value)` | Adds constant to methods table |
| `add_metamethod(fn, name, args...)` | Adds `__name` metamethod to metatable |
| `add_function(fn, name, args...)` | Adds function to methods table with upvalues |
| **Destructor** | Registers class in main table: `main_table[name] = methods_table` |

### Usage Pattern

```cpp
void lua_register_gfx(const lua_register_state* pState) {
  // Palette
  {
    lua_class_binding<palette> lcb(pState, "palette", l_palette_new,
                                   lua_metatable::palette);
    lcb.add_function(l_palette_set_entry, "setEntry");
  }
  
  // Font hierarchy with inheritance
  {
    lua_class_binding<font> lcb(pState, "font", l_font_new,
                                lua_metatable::font);
    lcb.add_function(l_font_get_size, "sizeOf");
    // ... font methods
  }
  
  {
    lua_class_binding<bitmap_font> lcb(pState, "bitmap_font", l_bitmap_font_new,
                                       lua_metatable::bitmap_font);
    lcb.set_superclass(lua_metatable::font);  // Inheritance!
    lcb.add_function(l_bitmap_font_set_spritesheet, "setSheet", lua_metatable::sheet);
    // ... bitmap_font methods
  }
}
```

---

## add_lua_function & luaT_setclosure

### luaT_setclosure

**Location**: `th_lua_internal.h:67-83`, `th_lua.cpp:315-318`

```cpp
void luaT_setclosure(const lua_register_state* pState, lua_CFunction fn, int iUps) {
  luaT_pushcclosure(pState->L, fn, iUps);
}

template <typename... Args>
void luaT_setclosure(const lua_register_state* pState, lua_CFunction fn,
                     int iUps, lua_metatable eMetatable1, Args... args) {
  lua_pushvalue(pState->L, pState->metatables[static_cast<size_t>(eMetatable1)]);
  luaT_setclosure(pState, fn, iUps + 1, args...);
}

template <typename... Args>
void luaT_setclosure(const lua_register_state* pState, lua_CFunction fn,
                     int iUps, const char* str, Args... args) {
  lua_pushstring(pState->L, str);
  luaT_setclosure(pState, fn, iUps + 1, args...);
}
```

**Purpose**: Pushes a C closure with upvalues. Supports two upvalue types:
1. **Metatable references** - pushes `metatables[mt]` for cross-class calls
2. **String constants** - pushes string literals

### add_lua_function

**Location**: `th_lua_internal.h:93-98`

```cpp
template <typename... Args>
void add_lua_function(const lua_register_state* pState, lua_CFunction fn,
                      const char* name, Args... args) {
  luaT_setclosure(pState, fn, 0, args...);
  lua_setfield(pState->L, -2, name);
}
```

**Purpose**: Registers a C function with optional upvalues into the methods table (top of stack).

**Usage Examples**:

```cpp
// Simple function, no upvalues
add_lua_function(pState, l_load_strings, "LoadStrings");

// Function with metatable upvalue (for type checking second arg)
lcb.add_function(l_map_set_sheet, "setSheet", lua_metatable::sheet);

// Function with multiple upvalues
lcb.add_function(l_map_updateblueprint, "updateRoomBlueprint",
                 lua_metatable::anims, lua_metatable::anim);

// Static function with string upvalue
lcb.add_function(l_str_func, "format", "format");
```

---

## Master Registration: luaopen_th()

**Location**: `th_lua.cpp:320-358`

```cpp
int luaopen_th(lua_State* L) {
  lua_settop(L, 0);
  lua_checkstack(L, 16 + static_cast<int>(lua_metatable::count));

  lua_register_state oState;
  const lua_register_state* pState = &oState;
  oState.L = L;
  
  // Create all metatables
  for (int i = 0; i < static_cast<int>(lua_metatable::count); ++i) {
    lua_createtable(L, 0, 5);
    oState.metatables[i] = lua_gettop(L);
  }
  
  // Create main module table
  lua_createtable(L, 0, lua_gettop(L));
  oState.main_table = lua_gettop(L);
  oState.top = lua_gettop(L);

  // Module-level functions
  lua_settop(L, oState.top);
  add_lua_function(pState, l_load_strings, "LoadStrings");
  add_lua_function(pState, l_get_compile_options, "GetCompileOptions");
  add_lua_function(pState, bootstrap_lua_resources, "GetBuiltinFont");
  add_lua_function(pState, l_fetch_latest_version_info, "FetchLatestVersionInfo");
  add_lua_function(pState, l_crc32, "CRC32File");

  // Class registrations (order matters for dependencies!)
  lua_register_map(pState);
  lua_register_gfx(pState);
  lua_register_anims(pState);
  lua_register_sound(pState);
  lua_register_movie(pState);
  lua_register_strings(pState);
  lua_register_ui(pState);
  lua_register_lfs_ext(pState);
  lua_register_iso_fs(pState);
  lua_register_midi(pState);

  lua_settop(L, oState.main_table);
  return 1;
}
```

### Registration Order Rationale

1. **map** - Core map/pathfinder, no dependencies
2. **gfx** - Palette, sheet, font, surface, cursor, layers, line
3. **anims** - Depends on gfx (sheet, surface, layers)
4. **sound** - Depends on gfx (surface for camera?)
5. **movie** - Depends on gfx (surface/renderer)
6. **strings** - Independent string proxy system
7. **ui** - Depends on map, gfx
8. **lfs_ext** - Independent filesystem
9. **iso_fs** - Independent ISO filesystem
10. **midi** - Conditional compilation

---

## Each lua_register_* Function

### lua_register_map (th_lua_map.cpp:1108-1167)

**Classes**: `level_map` (Map), `pathfinder` (Pathfinder)

**level_map methods** (46 functions):
- Construction: `new`, `load`, `loadBlank`, `save`
- Persistence: `persist`, `depersist`
- Tile access: `getCell`, `setCell`, `getCellFlags`, `setCellFlags`, `getCellRaw`
- Room management: `markRoom`, `unmarkRoom`, `getRoomId`
- Player: `getPlayerCount`, `setPlayerCount`, `getCameraTile`, `setCameraTile`, `getHeliportTile`, `setHeliportTile`
- Temperature: `getCellTemperature`, `setTemperatureDisplay`, `updateTemperatures`
- Pathfinding: `updatePathfinding`
- Rendering: `draw`, `hitTestObjects`, `updateShadows`
- Blueprint: `updateRoomBlueprint` (complex, uses anims/anim upvalues)
- Parcels: `getParcelTileCount`, `getPlotCount`, `setPlotOwner`, `getPlotOwner`, `isParcelPurchasable`, `getLitterFraction`
- Objects: `eraseObjectTypes`, `removeObjectType`
- Sheet: `setSheet`

**pathfinder methods** (8 functions):
- Construction: `new`
- Persistence: `persist`, `depersist`
- Map binding: `setMap`
- Path queries: `findDistance`, `isReachableFromHospital`, `findPath`, `findIdleTile`, `findObject`

---

### lua_register_gfx (th_lua_gfx.cpp:1098-1224)

**Classes** (12 classes):
1. **palette** - `setEntry`
2. **raw_bitmap** (bitmap) - `load`, `setPalette`, `draw`
3. **sprite_sheet** (sheet) - `load`, `setPalette`, `size`, `draw`, `hitTest`, `isVisible`, `__len`
4. **font** (abstract base) - `sizeOf`, `draw`, `drawWrapped`, `drawTooltip`, `isBitmap`
5. **bitmap_font** (inherits font) - `setSheet`, `getSheet`, `setSeparation`, `setScaleFactor`
6. **freetype_font** (inherits font) - `setFontOptions`, `setFace`, `getCopyrightNotice`, `clearCache`
7. **layers** - `__index`, `__newindex`, `persist`, `depersist`
8. **cursor** - `load`, `use`, `setPosition`
9. **render_target** (surface) - 20+ methods: `update`, `fillBlack`, `fillColour`, `startFrame`, `endFrame`, `nonOverlapping`, `mapRGB`, `setBlueFilterActive`, `drawRect`, `pushClip`, `popClip`, `getWidth`, `getHeight`, `getRenderSize`, `takeScreenshot`, `scale`, `setCaption`, `getRendererDetails`, `setCaptureMouse`
10. **line_sequence** (line) - `moveTo`, `lineTo`, `setWidth`, `setColour`, `draw`, `persist`, `depersist`

**Inheritance**: `bitmap_font` → `font` ← `freetype_font`

---

### lua_register_anims (th_lua_anims.cpp:676-803)

**Classes**: `animation_manager` (anims), `animation` (anim), `sprite_render_list` (spriteList)

**animation_manager methods** (13):
- Construction: `new`
- Setup: `load`, `loadCustom`, `setSheet`, `setCanvas`
- Query: `getAnimations`, `getFirstFrame`, `getNextFrame`
- Palette: `setAnimationGhostPalette`
- Markers: `setFramePrimaryMarker`, `setFrameSecondaryMarker`
- Drawing: `draw` (needs surface + layers)
- Update: `tick`
- Constants: `Alt32_GreyScale`, `Alt32_BlueRedSwap`

**animation methods** (36):
- Persistence: `persist`, `pre_depersist`, `depersist`
- Animation control: `setAnimation`, `setCrop`, `getCrop`, `setMorph`, `setFrame`, `getFrame`, `getAnimation`
- Tile attachment: `setTile`, `getTile`
- Parenting: `setParent`
- Flags: `setFlag`, `setPartialFlag`, `getFlag`, `isVisible`, `makeVisible`, `makeInvisible`
- Tags: `setTag`, `getTag`
- Position: `setPosition`, `getPosition`
- Speed: `setSpeed`
- Layer: `setLayer`, `setLayersFrom`
- Scale: `setScaleFactor`
- Hit testing: `setHitTestResult`
- Markers: `getPrimaryMarker`, `getSecondaryMarker`
- Update: `tick`
- Drawing: `draw`
- Patient effects: `setPatientEffect`

**sprite_render_list methods** (17):
- Persistence: `persist`, `pre_depersist`, `depersist`
- Setup: `setSheet`, `append`, `setLifetime`, `setUseIntermediateBuffer`, `setScaleFactor`
- State: `isDead`
- Tile: `setTile`
- Flags: `setFlag`, `setPartialFlag`, `getFlag`, `isVisible`, `makeVisible`, `makeInvisible`
- Position: `setPosition`, `setSpeed`, `setLayer`
- Update: `tick`
- Drawing: `draw`

**Special**: Creates weak tables at `anim_metatable[1]` and `[2]` for lightuserdata→object lookup and persistence.

---

### lua_register_sound (th_lua_sound.cpp:355-385)

**Classes**: `sound_archive` (soundArchive), `sound_player` (soundEffects)

**sound_archive methods** (7):
- Construction: `new`
- Loading: `load`
- Query: `__len`, `getFilename`, `getDuration`, `getFileData`, `soundExists`

**sound_player methods** (11):
- Construction: `new`
- Setup: `setSoundArchive`
- Playback: `play`, `togglePause`, `stop`, `isPlaying`
- Volume: `setSoundVolume`, `setSoundEffectsOn`
- Camera: `setCamera`
- Channels: `reserveChannel`, `releaseChannel`

---

### lua_register_movie (th_lua_movie.cpp:164-181)

**Class**: `movie_player` (moviePlayer)

**Methods** (14):
- Construction: `new`
- Setup: `setRenderer`
- Query: `getEnabled`, `getNativeHeight`, `getNativeWidth`, `hasAudioTrack`, `getLength`
- Playback: `load`, `unload`, `play`, `stop`, `togglePause`
- Frame: `refresh`
- Buffers: `allocatePictureBuffer`, `deallocatePictureBuffer`

---

### lua_register_strings (th_lua_strings.cpp:636-694)

**Class**: `string_proxy` (stringProxy)

**Metamethods** (14):
- `__index`, `__newindex`, `__concat`, `__len`, `__tostring`, `__persist`, `__depersist`, `__call`, `__lt`, `__pairs`, `__ipairs`, `__next`, `__inext`

**Functions** (8):
- `format`, `lower`, `rep`, `reverse`, `upper`, `_unwrap`, `reload`

**Special**: Creates registry weak tables `StringProxyValues` and cache with auto-vivification.

---

### lua_register_ui (th_lua_ui.cpp:178-184)

**Class**: `abstract_window` (windowHelpers) - abstract base only

**Methods** (1):
- `townMapDraw` (static, takes map + surface)

---

### lua_register_lfs_ext (th_lua_lfs_ext.cpp:95-98)

**Class**: `lfs_ext` (lfsExt)

**Methods** (1):
- `volumes` (returns drive list / root filesystem)

---

### lua_register_iso_fs (th_lua_iso.cpp:180-188)

**Class**: `iso_filesystem` (iso_fs)

**Methods** (7):
- Construction: `new`, `isValidRoot` (static)
- Query: `fileExists`, `fileSize`, `fileOffsets`, `readContents`, `listFiles`

---

### lua_register_midi (th_lua_midi.cpp:247-260)

**Class**: `th_lua_midi_player` (midiPlayer)

**Static**: `getAvailableApis`

**Methods** (8):
- `portList`, `playXmi`, `setVolume`, `stop`, `pause`, `resume`, `close`

**Conditional**: Only compiled with `WITH_MIDI_DEVICE`

---

## Code Examples

### Example 1: Simple Class Binding

```cpp
// C++ class
class MyClass {
public:
  MyClass(int value) : value_(value) {}
  int getValue() const { return value_; }
  void setValue(int v) { value_ = v; }
private:
  int value_;
};

// Binding functions
int l_myclass_new(lua_State* L) {
  int value = luaL_optinteger(L, 2, 0);
  luaT_stdnew<MyClass>(L, luaT_environindex, true, value);
  return 1;
}

int l_myclass_get(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  lua_pushinteger(L, obj->getValue());
  return 1;
}

int l_myclass_set(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  obj->setValue(luaL_checkinteger(L, 2));
  return 0;
}

// Registration
void lua_register_myclass(const lua_register_state* pState) {
  lua_class_binding<MyClass> lcb(pState, "myClass", l_myclass_new,
                                  lua_metatable::my_new_slot);
  lcb.add_function(l_myclass_get, "getValue");
  lcb.add_function(l_myclass_set, "setValue");
}
```

### Example 2: Inheritance

```cpp
// Base
class Animal {
public:
  virtual ~Animal() = default;
  virtual const char* speak() const = 0;
};

// Derived
class Dog : public Animal {
public:
  const char* speak() const override { return "woof"; }
};

// Binding
void lua_register_animals(const lua_register_state* pState) {
  // Base class (abstract)
  lua_class_binding<Animal> lcb(pState, "animal", nullptr,  // no constructor
                                  lua_metatable::animal);
  lcb.add_function(l_animal_speak, "speak");
  
  // Derived class
  lua_class_binding<Dog> lcb2(pState, "dog", l_dog_new,
                               lua_metatable::dog);
  lcb2.set_superclass(lua_metatable::animal);  // Key!
}

// Polymorphic access
Animal* luaT_getanimal(lua_State* L) {
  return luaT_touserdata_base<Animal, Dog, Cat>(L, 1, {"dog", "cat"});
}
```

### Example 3: Persistence Support

```cpp
int l_myclass_persist(lua_State* L) {
  MyClass* obj = luaT_testuserdata<MyClass>(L);
  luaT_rotate(L, 1, -1);  // Move writer to bottom
  lua_persist_writer* writer = (lua_persist_writer*)lua_touserdata(L, 1);
  
  writer->write_int(obj->getValue());
  return 0;
}

int l_myclass_depersist(lua_State* L) {
  void* ud = luaT_testuserdata<MyClass>(L);
  lua_settop(L, 2);
  lua_insert(L, 1);
  lua_persist_reader* reader = (lua_persist_reader*)lua_touserdata(L, 1);
  
  int value;
  reader->read_int(value);
  new (ud) MyClass(value);  // Placement new with data
  return 0;
}

// In registration:
lcb.add_metamethod(l_myclass_persist, "persist");
lcb.add_metamethod(l_myclass_depersist, "depersist");
```

### Example 4: Cross-Class Upvalues

```cpp
// Function needing access to another class's metatable
int l_map_set_sheet(lua_State* L) {
  level_map* map = luaT_testuserdata<level_map>(L);
  sprite_sheet* sheet = luaT_testuserdata<sprite_sheet>(L, 2);  // Verified via upvalue
  map->set_block_sheet(sheet);
  luaT_setenvfield(L, 1, "sprites");  // Store in map's env
  return 1;
}

// Registration with upvalue
lcb.add_function(l_map_set_sheet, "setSheet", lua_metatable::sheet);
// Generates closure with sheet metatable as upvalue 1
// l_map_set_sheet can then use luaT_testuserdata<sprite_sheet>(L, 2, lua_upvalueindex(1))
```

### Example 5: Weak Tables for Circular References

```cpp
// In lua_register_anims (th_lua_anims.cpp:698-716)
// Weak table [1]: lightuserdata -> animation object (for hitTest)
lua_newtable(pState->L);
lua_createtable(pState->L, 0, 1);
lua_pushliteral(pState->L, "v");
lua_setfield(pState->L, -2, "__mode");
lua_setmetatable(pState->L, -2);
lua_rawseti(pState->L, anim_metatable, 1);

// Weak table [2]: lightuserdata -> full userdata (for persistence)
lua_newtable(pState->L);
lua_createtable(pState->L, 0, 1);
lua_pushliteral(pState->L, "v");
lua_setfield(pState->L, -2, "__mode");
lua_setmetatable(pState->L, -2);
lua_rawseti(pState->L, anim_metatable, 2);
```

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| Metatable slots | 23 |
| Registration files | 10 (th_lua_*.cpp) |
| Total bound classes | ~20 |
| Total bound functions | ~200+ |
| Inheritance hierarchies | 2 (font, animation) |
| Classes with persistence | 8+ |
| Weak table usage | 3 (anims, spriteList, strings) |

---

*Generated from CorsixTH source code analysis*


## Related Pages

- [[18-cpp-bindings/CHECKLIST]]
- [[18-cpp-bindings/MAP]]
- [[18-cpp-bindings/SCAFFOLD]]
