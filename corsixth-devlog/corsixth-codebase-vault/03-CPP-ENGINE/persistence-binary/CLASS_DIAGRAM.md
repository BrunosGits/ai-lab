# Persistence System — Class Diagram

> **Mermaid class diagram for the CorsixTH Lua persistence subsystem**

```mermaid
classDiagram
    class lua_persist_writer {
        <<abstract>>
        +get_stack()* lua_State*
        +write_stack_object(int iIndex)* void
        +write_byte_stream(uint8_t* pBytes, size_t iCount)* void
        +set_error(const char* sError)* void
        +fast_write_stack_object(int iIndex)* void
        +write_uint~T~(T tValue) void
        +write_int~T~(T tValue) void
        +write_float~T~(T fValue) void
    }

    class lua_persist_reader {
        <<abstract>>
        +get_stack()* lua_State*
        +read_stack_object()* bool
        +read_byte_stream(uint8_t* pBytes, size_t iCount)* bool
        +set_error(const char* sError)* void
        +read_uint~T~(T& tValue) bool
        +read_int~T~(T& tValue) bool
        +read_float~T~(T& fValue) bool
    }

    class lua_persist_basic_writer {
        -lua_State* L
        -uint64_t next_index
        -string data
        -bool had_error
        +lua_persist_basic_writer(lua_State* L)
        +init() void
        +finish() int
        +write_stack_object(int iIndex) void
        +fast_write_stack_object(int iIndex) void
        +write_byte_stream(uint8_t*, size_t) void
        +set_error(const char*) void
        -write_object_raw() void
        -write_prototype(lua_Debug*, int) void
        -check_that_userdata_can_be_depersisted(int) bool
        -get_error() const char*
    }

    class lua_persist_basic_reader {
        -lua_State* L
        -uint64_t next_index
        -const uint8_t* data
        -size_t data_buffer_size
        -string string_buffer
        -bool had_error
        +lua_persist_basic_reader(lua_State*, uint8_t*, size_t)
        +init() void
        +finish() bool
        +read_stack_object() bool
        +read_byte_stream(uint8_t*, size_t) bool
        +set_error(const char*) void
        +get_pointer() const uint8_t*
        +get_object_count() uint64_t
        -read_table_contents() bool
        -save_stack_object() void
        -get_error() const char*
    }

    class load_multi_buffer {
        <<helper>>
        +const char* piece[3]
        +size_t piece_size[3]
        -int n
        +insert(string_view, size_t) void
        +load_fn(lua_State*, void*, size_t*) const char*$
    }

    class persist_type {
        <<enum>>
        PERSIST_TPERMANENT = 9
        PERSIST_TTRUE = 10
        PERSIST_TTABLE_WITH_META = 11
        PERSIST_TINTEGER = 12
        PERSIST_TPROTOTYPE = 13
        PERSIST_TRESERVED1 = 14
        PERSIST_TRESERVED2 = 15
        PERSIST_TCOUNT = 16
    }

    class lua_persist_int {
        <<template>>
    }

    lua_persist_basic_writer --|> lua_persist_writer : implements
    lua_persist_basic_reader --|> lua_persist_reader : implements
    lua_persist_basic_writer --> lua_State : operates on
    lua_persist_basic_reader --> lua_State : reconstructs
    lua_persist_basic_writer ..> persist_type : uses type tags
    lua_persist_basic_reader ..> persist_type : dispatches on type tags
    lua_persist_basic_reader ..> load_multi_buffer : uses for prototype loading
    lua_persist_writer ..> lua_persist_int : uses for zigzag encoding
    lua_persist_reader ..> lua_persist_int : uses for zigzag decoding
    lua_persist_basic_writer --> "string" data : output buffer
    lua_persist_basic_reader --> "const uint8_t*" data : input pointer

    class l_dump_toplevel {
        <<function>>
        +int l_dump_toplevel(lua_State*)
    }
    class l_load_toplevel {
        <<function>>
        +int l_load_toplevel(lua_State*)
    }
    class l_persist_dofile {
        <<function>>
        +int l_persist_dofile(lua_State*)
    }
    class luaopen_persist {
        <<function>>
        +int luaopen_persist(lua_State*)
    }

    luaopen_persist --> l_dump_toplevel : registers as persist.dump
    luaopen_persist --> l_load_toplevel : registers as persist.load
    luaopen_persist --> l_persist_dofile : registers as persist.dofile
    l_dump_toplevel ..> lua_persist_basic_writer : creates and uses
    l_load_toplevel ..> lua_persist_basic_reader : creates and uses
    l_persist_dofile ..> load_multi_buffer : uses for function loading
```

## Relationship Summary

| Relationship | Type | Description |
|-------------|------|-------------|
| `lua_persist_basic_writer` → `lua_persist_writer` | implements | Concrete writer with Lua stack walking |
| `lua_persist_basic_reader` → `lua_persist_reader` | implements | Concrete reader with Lua stack reconstruction |
| `basic_writer` → `lua_State` | operates on | Reads Lua objects from the state |
| `basic_reader` → `lua_State` | reconstructs | Pushes deserialized objects onto the state |
| `basic_writer` → `std::string data` | owns | Binary output buffer (repurposed for errors) |
| `basic_reader` → `const uint8_t* data` | borrows | Input buffer pointer (advances during read) |
| `basic_reader` → `load_multi_buffer` | uses | Assembles function code without concatenation |
| `luaopen_persist` → writer/reader | creates | Factory for Lua-registered dump/load functions |

---

## Related Pages

- [[SUMMARY]] — Full technical reference
- [[SEQUENCE_DIAGRAM]] — Save/load sequence flows
- [[MAP]] — Source file line index
