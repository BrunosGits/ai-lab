# Persistence System — Technical Reference

> **CorsixTH C++ Engine — Lua State Persistence**
> Source files: `persist_lua.h`, `persist_lua.cpp`

## 1. Overview

The persistence system serializes and deserializes entire Lua states — including tables, functions, userdata, and C++ object references — into compact binary streams. This is the backbone of CorsixTH's save/load game functionality.

The system is organized as:

| Type | Role |
|------|------|
| `lua_persist_writer` | Abstract interface for serializing Lua objects |
| `lua_persist_reader` | Abstract interface for deserializing Lua objects |
| `lua_persist_basic_writer` | Concrete writer — walks Lua stack, writes binary stream |
| `lua_persist_basic_reader` | Concrete reader — reads binary stream, reconstructs Lua state |
| `load_multi_buffer` | Helper for efficiently loading multi-part Lua chunks |
| `luaopen_persist()` | Lua C API registration — exposes `persist.dump` and `persist.load` |

---

## 2. `lua_persist_writer` Interface

**Location:** `persist_lua.h:44–100`

Abstract base class providing the writing API.

### Pure Virtual Methods

| Method | Description |
|--------|-------------|
| `get_stack()` | Returns the `lua_State*` being persisted |
| `write_stack_object(int iIndex)` | Serialize the Lua value at stack index `iIndex` |
| `write_byte_stream(data, count)` | Write raw bytes to the output buffer |
| `set_error(sError)` | Record a persistence error |
| `fast_write_stack_object(int iIndex)` | Optimized userdata serialization without growing the call stack |

### Template Methods

**`write_uint<T>(tValue)`** (`persist_lua.h:62–80`) — Variable-length unsigned integer encoding:
- Values 0–127: 1 byte
- Each additional byte carries 7 bits with high bit as continuation flag
- Endian-independent and type-size-independent

**`write_int<T>(tValue)`** (`persist_lua.h:83–94`) — Zigzag encoding for signed integers:
- Non-negative values: `value << 1`
- Negative values: `(-(value + 1)) << 1 | 1`
- Result passed to `write_uint()`

**`write_float<T>(fValue)`** (`persist_lua.h:97–99`) — Raw byte serialization of floating-point values.

---

## 3. `lua_persist_reader` Interface

**Location:** `persist_lua.h:107–154`

Abstract base class providing the reading API.

### Pure Virtual Methods

| Method | Description |
|--------|-------------|
| `get_stack()` | Returns the `lua_State*` being reconstructed |
| `read_stack_object()` | Deserialize next object from stream onto Lua stack |
| `read_byte_stream(pBytes, count)` | Read raw bytes from the input buffer |
| `set_error(sError)` | Record an unpersistence error |

### Template Methods

**`read_uint<T>(tValue)`** (`persist_lua.h:118–135`) — Reads variable-length unsigned integer. Reads bytes until a byte with clear high bit is found. Shifts and combines 7-bit chunks.

**`read_int<T>(tValue)`** (`persist_lua.h:138–146`) — Reads zigzag-encoded signed integer via `read_uint`, then decodes:
- If bit 0 is 1: `value = -(decoded >> 1) - 1`
- If bit 0 is 0: `value = decoded >> 1`

**`read_float<T>(fValue)`** (`persist_lua.h:149–153`) — Raw byte deserialization of floating-point values.

---

## 4. `lua_persist_basic_writer` Class

**Location:** `persist_lua.cpp:163–647`

Concrete writer implementation that walks the Lua stack and produces a binary stream.

### State Management

```cpp
lua_State* L;           // Lua state being persisted
uint64_t next_index{1}; // Auto-incrementing object index counter
std::string data;       // Output buffer (also repurposed for error messages)
bool had_error{false};  // Error flag
```

### Object Caching

The writer uses the Lua state's **environment table** (setfenv on self) as a cache to detect cycles and avoid writing duplicate objects:
- Before writing a complex object, the environment is checked
- If the object has been seen before, only its index is written (offset by `PERSIST_TCOUNT - 1`)
- If new, the object is assigned `next_index++` and stored in the cache

### `write_stack_object()` Logic (`persist_lua.cpp:257–328`)

1. Converts relative indices to absolute
2. Handles basic types inline:
   - **nil/none** → type byte `LUA_TNIL`
   - **boolean** → `LUA_TBOOLEAN` (false) or `PERSIST_TTRUE` (true)
   - **number** → small integers (0–16383) as `PERSIST_TINTEGER` + VUInt; others as `LUA_TNUMBER` + 8-byte double
3. Complex types (string, table, function, userdata) → check environment cache first; if not cached, call `write_object_raw()`

### `write_object_raw()` Logic (`persist_lua.cpp:330–483`)

Handles the actual serialization of complex types:

| Type | Serialization |
|------|--------------|
| **String** | `LUA_TSTRING` + VUInt length + raw bytes |
| **Table** | `LUA_TTABLE` or `PERSIST_TTABLE_WITH_META` + optional metatable + key-value pairs + nil terminator |
| **Function** | `LUA_TFUNCTION` + prototype data + upvalues + upvalue IDs + environment table |
| **Userdata** | `LUA_TUSERDATA` + metatable + environment + raw data via `__persist` metamethod + sync marker `0x42` |
| **Permanent** | `PERSIST_TPERMANENT` + permanent object key (looks up in permanents table at env[1]) |

### `write_prototype()` Logic (`persist_lua.cpp:534–601`)

Serializes Lua function prototypes (the shared part of closures):
1. Validates the function was defined in a source file (`source[0] == '@'`)
2. Validates it is a Lua function (not C, not a chunk)
3. Checks the metatable cache for previously-written prototypes (keyed by `file:line`)
4. Writes `PERSIST_TPROTOTYPE` + upvalue count + upvalue names + persist name

### `fast_write_stack_object()` (`persist_lua.cpp:200–255`)

Optimized path for userdata persistence that avoids growing the Lua call stack:
1. Checks for cycles via the environment cache
2. Validates userdata can be depersisted
3. Writes type + metatable + environment + raw data + sync marker
4. Calls `__persist` metamethod if present on the metatable

### `check_that_userdata_can_be_depersisted()` (`persist_lua.cpp:488–532`)

Validates that userdata can be safely serialized:
- Non-empty userdata requires `__depersist_size`, `__persist`, and `__depersist` metamethods
- Validates `__depersist_size` matches actual `lua_objlen`
- Empty userdata without a metatable is allowed

---

## 5. `lua_persist_basic_reader` Class

**Location:** `persist_lua.cpp:664–1100`

Concrete reader implementation that reconstructs a Lua state from a binary stream.

### State Management

```cpp
lua_State* L;               // Lua state being reconstructed
uint64_t next_index{1};     // Auto-incrementing object index
const uint8_t* data;        // Current read position in input buffer
size_t data_buffer_size;    // Remaining bytes in input buffer
std::string string_buffer;  // Reusable string buffer
bool had_error{false};      // Error flag
```

### `read_stack_object()` Logic (`persist_lua.cpp:695–992`)

Reads a VUInt and dispatches based on the type tag:

| Type Tag | Action |
|----------|--------|
| `LUA_TNIL` | Push nil |
| `PERSIST_TPERMANENT` | Read key, look up in permanents table (env[0]) |
| `LUA_TBOOLEAN` | Push false |
| `PERSIST_TTRUE` | Push true |
| `LUA_TSTRING` | Read VUInt length + bytes, push string |
| `LUA_TTABLE` | Create table, save index, read key-value pairs |
| `PERSIST_TTABLE_WITH_META` | Create table, set metatable, read key-value pairs |
| `LUA_TNUMBER` | Read 8-byte double |
| `LUA_TFUNCTION` | Read prototype, create closure, set upvalues + environment |
| `PERSIST_TPROTOTYPE` | Reconstruct closure factory from code lookup tables |
| `LUA_TUSERDATA` | Create userdata, set metatable, call `__depersist` |
| `PERSIST_TINTEGER` | Read VUInt as uint16, push as integer |
| `>= PERSIST_TCOUNT` | Reference to previously-depersisted object |

### Object Indexing

Every deserialized object is stored in the environment table at its sequential index. References to previously-depersisted objects use `index = stored_value + PERSIST_TCOUNT - 1`.

### `read_table_contents()` (`persist_lua.cpp:1006–1019`)

Reads key-value pairs until a nil key is encountered (nil terminates the table). Uses `lua_rawset` to avoid metamethod invocations during depersistence.

### `finish()` (`persist_lua.cpp:1021–1049`)

Post-read finalization:
1. Validates all input data has been consumed
2. Calls all `__depersist` metamethods that need a second pass (stored in the self metatable)

---

## 6. Persist Type Tags

**Location:** `persist_lua.cpp:46–64`

```cpp
enum persist_type {
    PERSIST_TPERMANENT       = 9,   // LUA_TTHREAD + 1
    PERSIST_TTRUE            = 10,  // Boolean true
    PERSIST_TTABLE_WITH_META = 11,  // Table with metatable
    PERSIST_TINTEGER         = 12,  // Small integer optimization
    PERSIST_TPROTOTYPE       = 13,  // Function prototype
    PERSIST_TRESERVED1       = 14,  // Unused
    PERSIST_TRESERVED2       = 15,  // Unused
    PERSIST_TCOUNT           = 16,  // Sentinel — must equal 16 for compatibility
};
```

Standard Lua types (0–8) are reused directly: `LUA_TNIL (0)`, `LUA_TBOOLEAN (1)`, `LUA_TNUMBER (3)`, `LUA_TSTRING (4)`, `LUA_TTABLE (5)`, `LUA_TFUNCTION (6)`, `LUA_TUSERDATA (7)`.

---

## 7. Zigzag Encoding

Zigzag encoding maps signed integers to unsigned integers for efficient variable-length encoding:

```
Original → Encoded
  0      →    0
 -1      →    1
  1      →    2
 -2      →    3
  2      →    4
  16383  → 32766
 -16383  → 32765
```

Formula:
- Non-negative `n`: encoded = `n << 1`
- Negative `n`: encoded = `(-(n + 1)) << 1 | 1`

This is applied in `write_int<T>()` / `read_int<T>()` before the variable-length unsigned encoding.

---

## 8. Variable-Length Unsigned Integer (VUInt) Encoding

Each unsigned integer is encoded as 1+ bytes:
- Each byte carries 7 data bits
- High bit (0x80) = "more bytes follow"
- High bit clear (0x00–0x7F) = "last byte"

Examples:
- `0` → `[0x00]` (1 byte)
- `127` → `[0x7F]` (1 byte)
- `128` → `[0x80, 0x01]` (2 bytes)
- `16383` → `[0xFF, 0x7F]` (2 bytes)

---

## 9. Lua C API Registration

**Location:** `persist_lua.cpp:1326–1342`

`luaopen_persist(L)` registers the `persist` library with:

| Lua Function | C Function | Description |
|-------------|------------|-------------|
| `persist.dump(obj, permanents)` | `l_dump_toplevel` | Serialize Lua object to binary string |
| `persist.load(data, permanents)` | `l_load_toplevel` | Deserialize binary string back to Lua object |
| `persist.errcatch` | `l_errcatch` | Debug error breakpoint hook |
| `persist.dofile(filename)` | `l_persist_dofile` | Load and execute a Lua file, extracting persistable functions |

### Upvalue Structure

`l_persist_dofile` uses 4 upvalues:
1. Buffer (512 bytes userdata for file reading)
2. `<file>:<line>` → `<name>` mapping (prototype names)
3. `<name>` → `<filename>` mapping (source files)
4. `<name>` → `<code>` mapping (function source code)

---

## 10. `load_multi_buffer` Helper

**Location:** `persist_lua.cpp:102–147`

Efficiently loads multiple string pieces as a single Lua chunk without concatenation:
- Implements the `lua_Reader` callback interface
- Up to `load_multi_buffer_capacity (3)` pieces
- Skips empty pieces automatically
- Used during prototype depersistence to assemble function code from name + source

---

## 11. `l_persist_dofile` Function

**Location:** `persist_lua.cpp:1181–1310`

Loads a Lua source file and extracts persistable functions:
1. Reads entire file into memory (dynamically growing buffer)
2. Rejects compiled Lua files (checks for `LUA_SIGNATURE[0]`)
3. Executes the file
4. Scans source for `--[[persistable:<name>]]` annotations
5. Extracts function boundaries using `find_function_end()`
6. Registers persistable functions in the upvalue tables

---

## 12. Version Compatibility

- `PERSIST_TCOUNT` must equal 16 for binary compatibility across versions
- `write_uint`/`read_uint` use type-sized unsigned integers for platform independence
- Prototype caching uses `file:line` as key — adding or removing code at different lines in persistable functions can break save compatibility
- Sync marker `0x42` is written after each userdata block for corruption detection

---

## 13. Error Handling

- Writer: first error wins — subsequent writes silently no-op
- Reader: returns `nil, error_message` on failure with byte count diagnostic
- `set_error()` reuses the output buffer for error messages in the writer
- `l_errcatch()` is a no-op debug hook for setting breakpoints

---

## Related Pages

- [[CLASS_DIAGRAM]] — Class hierarchy and relationships
- [[SEQUENCE_DIAGRAM]] — Save/load sequence flows
- [[MAP]] — File:line index for source locations
- [[BINARY_SPEC]] — Binary stream format specification
- [[../area-1-audio/SUMMARY|Audio System]] — Sound effect persistence
- [[../area-3-iso-filesystem/SUMMARY|ISO Filesystem]] — Reading game data from ISO images
