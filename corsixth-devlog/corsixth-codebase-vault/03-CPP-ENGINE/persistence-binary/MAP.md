# Persistence System — File:Line Index

> **Source locations for `persist_lua.h` and `persist_lua.cpp`**

## persist_lua.h

| Line(s) | Symbol | Description |
|---------|--------|-------------|
| 23–24 | `CORSIX_TH_PERSIST_LUA_H_` | Include guard |
| 32–37 | `struct lua_persist_int<T>` | Zigzag encoding type trait |
| 44–100 | `class lua_persist_writer` | Abstract writer interface |
| 46 | `virtual ~lua_persist_writer()` | Virtual destructor |
| 48 | `get_stack()` | Pure virtual — get lua_State |
| 49 | `write_stack_object()` | Pure virtual — serialize Lua value |
| 50 | `write_byte_stream()` | Pure virtual — write raw bytes |
| 51 | `set_error()` | Pure virtual — error recording |
| 57 | `fast_write_stack_object()` | Pure virtual — optimized userdata path |
| 62–80 | `write_uint<T>()` | VUInt variable-length encoding template |
| 83–94 | `write_int<T>()` | Zigzag + VUInt encoding template |
| 97–99 | `write_float<T>()` | Raw float serialization template |
| 107–154 | `class lua_persist_reader` | Abstract reader interface |
| 109 | `virtual ~lua_persist_reader()` | Virtual destructor |
| 111 | `get_stack()` | Pure virtual — get lua_State |
| 112 | `read_stack_object()` | Pure virtual — deserialize next object |
| 113 | `read_byte_stream()` | Pure virtual — read raw bytes |
| 114 | `set_error()` | Pure virtual — error recording |
| 118–135 | `read_uint<T>()` | VUInt variable-length decoding template |
| 138–146 | `read_int<T>()` | Zigzag + VUInt decoding template |
| 149–153 | `read_float<T>()` | Raw float deserialization template |
| 156 | `luaopen_persist()` | Lua C API library registration |

## persist_lua.cpp

| Line(s) | Symbol | Description |
|---------|--------|-------------|
| 44–74 | Anonymous namespace | persist_type enum, l_crude_gc template |
| 46–64 | `enum persist_type` | Type tags (PERMANENT, TRUE, TABLE_WITH_META, etc.) |
| 66–72 | `l_crude_gc<T>()` | Generic GC metamethod for C++ objects on Lua stack |
| 76 | `load_multi_buffer_capacity` | Constant: 3 pieces |
| 102–147 | `class load_multi_buffer` | Multi-piece chunk loader helper |
| 115–130 | `load_multi_buffer::load_fn()` | lua_Reader callback |
| 133–136 | `load_multi_buffer::insert()` | Insert piece at index |
| 163–647 | `class lua_persist_basic_writer` | Concrete writer implementation |
| 165 | Constructor | Takes lua_State* |
| 171–184 | `init()` | Sets up environment, metatable, __gc |
| 186–198 | `finish()` | Returns serialized string or error |
| 200–255 | `fast_write_stack_object()` | Optimized userdata serialization |
| 257–328 | `write_stack_object()` | Main serialization dispatch |
| 330–483 | `write_object_raw()` | Type-specific serialization |
| 488–532 | `check_that_userdata_can_be_depersisted()` | Userdata validation |
| 534–601 | `write_prototype()` | Function prototype serialization |
| 603–611 | `write_byte_stream()` | Appends to output string buffer |
| 613–622 | `set_error()` | First-error-wins error recording |
| 624–632 | `set_error_object()` | Stores error object in metatable |
| 634–639 | `get_error()` | Returns error string or nullptr |
| 641–647 | Private members | L, next_index, data, data_size, had_error |
| 664–1100 | `class lua_persist_basic_reader` | Concrete reader implementation |
| 666–667 | Constructor | Takes lua_State*, data pointer, length |
| 671 | `get_stack()` | Returns lua_State* |
| 673–676 | `set_error()` | Records error message |
| 678–693 | `init()` | Sets up environment, metatable, __gc |
| 695–992 | `read_stack_object()` | Main deserialization dispatch |
| 994–1004 | `save_stack_object()` | Stores object at next_index in environment |
| 1006–1019 | `read_table_contents()` | Reads key-value pairs until nil |
| 1021–1049 | `finish()` | Validates completion, calls __depersist pass 2 |
| 1051–1081 | `read_byte_stream()` (2 overloads) | Read from input buffer |
| 1083 | `get_pointer()` | Returns current read position |
| 1084 | `get_object_count()` | Returns total objects read |
| 1086–1091 | `get_error()` | Returns error string or nullptr |
| 1093–1100 | Private members | L, next_index, data, buffer_size, string_buffer, had_error |
| 1102–1324 | Anonymous namespace | Lua C functions |
| 1104–1115 | `l_dump_toplevel()` | persist.dump implementation |
| 1117–1140 | `l_load_toplevel()` | persist.load implementation |
| 1142–1159 | `calculate_line_number()` | Source line counter for dofile |
| 1161–1179 | `find_function_end()` | Lua function boundary finder |
| 1181–1310 | `l_persist_dofile()` | persist.dofile implementation |
| 1312–1317 | `l_errcatch()` | Debug error breakpoint |
| 1321–1322 | `persist_lib` | luaL_Reg registration table |
| 1326–1342 | `luaopen_persist()` | Library registration entry point |


## Related Pages

- [[BINARY_SPEC]]
- [[CLASS_DIAGRAM]]
- [[SEQUENCE_DIAGRAM]]
- [[SUMMARY]]
