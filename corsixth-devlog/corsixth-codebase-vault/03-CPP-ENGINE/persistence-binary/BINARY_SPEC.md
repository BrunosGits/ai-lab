# Persistence System — Binary Format Specification

> **Binary stream format for Lua state serialization**

## 1. Stream Overview

A persistence stream is a flat byte sequence with no file header. The stream is self-describing: each value is preceded by a type tag byte. The stream begins with the serialization of a single root object.

```
┌──────────────────────────────────┐
│  Type Tag                        │  ← Root object
│  Object Data (type-dependent)    │
├──────────────────────────────────┤
│  (additional objects if table)   │
│  ...                             │
└──────────────────────────────────┘
```

---

## 2. Type Tag Encoding

| Value | Name | Meaning |
|-------|------|---------|
| 0 | `LUA_TNIL` | Nil value |
| 1 | `LUA_TBOOLEAN` | Boolean false |
| 3 | `LUA_TNUMBER` | 8-byte IEEE 754 double |
| 4 | `LUA_TSTRING` | Length-prefixed byte string |
| 5 | `LUA_TTABLE` | Table without metatable |
| 6 | `LUA_TFUNCTION` | Lua closure |
| 7 | `LUA_TUSERDATA` | Userdata with metatable |
| 9 | `PERSIST_TPERMANENT` | Reference to permanent object |
| 10 | `PERSIST_TTRUE` | Boolean true |
| 11 | `PERSIST_TTABLE_WITH_META` | Table with metatable |
| 12 | `PERSIST_TINTEGER` | Small integer (VUInt) |
| 13 | `PERSIST_TPROTOTYPE` | Function prototype |
| 16+ | — | Reference to previously-depersisted object (`index = value - 15`) |

---

## 3. Variable-Length Unsigned Integer (VUInt)

All lengths and indices use VUInt encoding:

```
Byte 0:  [C][LLLLLLL]     C=0 → last byte (1 byte total)
         [C][LLLLLLL]     C=1 → more bytes follow

Byte 1:  [C][LLLLLLL]     continuation...

Decoded value = byte_0 & 0x7F | (byte_1 & 0x7F) << 7 | ...
```

| Range | Bytes | Example |
|-------|-------|---------|
| 0–127 | 1 | `0x7F` = 127 |
| 128–16383 | 2 | `0x80 0x01` = 128 |
| 16384–2097151 | 3 | `0x80 0x80 0x01` = 16384 |

---

## 4. Zigzag Encoding (Signed Integers)

Signed integers are zigzag-encoded before VUInt encoding:

| Original | Encoded | Binary (16-bit) |
|----------|---------|-----------------|
| 0 | 0 | `0000000000000000` |
| -1 | 1 | `0000000000000001` |
| 1 | 2 | `0000000000000010` |
| -2 | 3 | `0000000000000011` |
| 16383 | 32766 | `0111111111111110` |
| -16383 | 32765 | `0111111111111101` |

**Encode:** `n >= 0 ? n << 1 : (-(n+1)) << 1 | 1`
**Decode:** `bit_0 ? -(encoded >> 1) - 1 : encoded >> 1`

---

## 5. Per-Type Data Formats

### Nil (tag = 0)
```
[0x00]
```
Just the tag byte. No additional data.

### Boolean (tag = 1 or 10)
```
[0x01]           — false
[0x0A]           — true (PERSIST_TTRUE)
```
Just the tag byte.

### Number (tag = 3)
```
[0x03][8 bytes IEEE 754 double — little-endian]
```

### Small Integer (tag = 12)
```
[0x0C][VUInt: uint16 value]
```
Optimization for integers 0–16383.

### String (tag = 4)
```
[0x04][VUInt: length][length bytes of raw data]
```
Not null-terminated in the stream.

### Table (tag = 5)
```
[0x05][key_1][value_1][key_2][value_2]...[0x00 (nil tag)]
```
Each key and value is a recursively serialized stack object. A nil tag terminates the table.

### Table with Metatable (tag = 11)
```
[0x0B][metatable_object][key_1][value_1]...[0x00]
```
The metatable is serialized as a stack object before the key-value pairs.

### Function (tag = 6)
```
[0x06][prototype_reference][VUInt: upvalue_count][VUInt: upvalue_id_size]
[upvalue_1][upvalue_id_bytes]...[upvalue_N][upvalue_id_bytes]
[environment_object]
```
The prototype reference is a stack object pointing to a `PERSIST_TPROTOTYPE` entry.

### Prototype (tag = 13)
```
[0x0D][VUInt: upvalue_count]
[upvalue_name_1]...[upvalue_name_N]
[persist_name_string]
```
Prototype data is cached — subsequent references use the object index mechanism.

### Userdata (tag = 7)
```
[0x07][metatable_object][environment_object]
[raw data via __persist metamethod]
[0x42 — sync marker as VUInt]
```
The sync marker `0x42` (66 decimal) is written as a VUInt for corruption detection.

### Permanent Reference (tag = 9)
```
[0x09][permanent_key_object]
```
The key is a stack object (typically a string) that indexes into the permanents table.

### Object Reference (tag >= 16)
```
[0x10 + (index - 1)]    — for indices 1–112
[VUInt: index]           — for larger indices (high bit set in first byte)
```
References an object previously written/read at position `index` in the object sequence.

---

## 6. Object Reference Encoding

| Index Range | Encoding |
|-------------|----------|
| 1–112 | Single byte: `0x10 + (index - 1)` = `0x10`–`0x7F` |
| 113+ | VUInt: `(index - 1 + 15)` encoded as VUInt |

The offset `PERSIST_TCOUNT - 1 = 15` ensures references never collide with type tags (0–15).

---

## 7. Stream Structure Diagram

```
Binary Persistence Stream
┌──────────────────────────────────────────────────┐
│ Root Object                                      │
│  ┌─────────────────────────────────────────────┐ │
│  │ Type Tag (1 byte)                           │ │
│  ├─────────────────────────────────────────────┤ │
│  │ Data (type-dependent)                       │ │
│  │  • VUInt lengths                            │ │
│  │  • Recursive sub-objects                    │ │
│  │  • Raw bytes (strings, doubles)             │ │
│  └─────────────────────────────────────────────┘ │
│                                                  │
│ For tables:                                      │
│  [key₁][value₁][key₂][value₂]...[0x00]         │
│                                                  │
│ For userdata:                                    │
│  [meta][env][raw_data...][0x42]                  │
│                                                  │
│ For functions:                                   │
│  [proto_ref][nups][upvals...][env]               │
└──────────────────────────────────────────────────┘
```

---

## 8. Permanents Table Encoding

The permanents table is not part of the stream. It is provided externally by the caller:

```
persist.dump(object, permanents_table)
persist.load(binary_data, permanents_table)
```

During **serialization**: objects found in `permanents_table` are written as `PERSIST_TPERMANENT` + their key.

During **deserialization**: `PERSIST_TPERMANENT` triggers a key read followed by `permanents_table[key]` lookup.

---

## 9. Example: Small Table Stream

Persisting `{ ["x"] = 42, ["y"] = true }`:

```
0x05              — LUA_TTABLE
0x04 0x01 0x78    — string "x" (tag=4, len=1, 'x')
0x0C 0x54         — integer 42 (tag=12, VUInt(84))
0x04 0x01 0x79    — string "y" (tag=4, len=1, 'y')
0x0A              — PERSIST_TTRUE
0x00              — nil terminator
```

---

## Related Pages

- [[SUMMARY]] — Full technical reference
- [[CLASS_DIAGRAM]] — Class hierarchy
- [[MAP]] — Source file line index
- [[SEQUENCE_DIAGRAM]] — Save/load sequence flows
