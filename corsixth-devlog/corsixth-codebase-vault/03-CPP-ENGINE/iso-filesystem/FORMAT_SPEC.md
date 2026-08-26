# ISO 9660 Format Specification — CorsixTH ISO Filesystem

Source: [[iso_fs.h]], [[iso_fs.cpp]]

CorsixTH implements a read-only ISO 9660 filesystem reader to extract
[[Theme Hospital]] data files directly from `.iso` disk images. The
implementation references [ECMA-119](http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-119.pdf)
and the [ISO 9660 summary](http://alumnus.caltech.edu/~pje/iso9660.html).

---

## Sector Layout

| Property | Value |
|---|---|
| Minimum sector size | 2048 bytes (`min_sector_size`) |
| Actual sector size | Read from primary volume descriptor at byte offset 128 (`sector_size_offset`), stored as a little-endian `uint16` |
| Reserved area | First 16 sectors (0–15), used for boot information (`first_filesystem_sector = 16`) |

All seeks within the image are computed as `sector_number × sector_size`
(see [[seek_to_sector]]).

---

## Volume Descriptor Structure

Volume descriptors begin at **sector 16** and are read one per sector.
Each descriptor starts with a 5-byte header:

| Offset | Size | Field | Description |
|---|---|---|---|
| 0 | 1 | Type | Descriptor type code |
| 1 | 5 | Standard Identifier | Must be `"CD001\x01"` |
| 6 | … | Type-specific data | Varies by type |

### Recognized Types

| Type Code | Name | Constant | Purpose |
|---|---|---|---|
| `0x01` | Primary Volume | `vdt_primary_volume` | Contains root directory entry and sector size |
| `0xFF` | Terminator | `vdt_terminator` | Ends the descriptor sequence |

Other type values (supplementary volume, boot record, etc.) are not parsed.
The parser iterates sectors starting at sector 16, reading each as a volume
descriptor, and stops when it hits a terminator or an unreadable sector.

### Primary Volume Descriptor — Key Offsets

| Offset | Size | Field | Notes |
|---|---|---|---|
| 128 | 2 | Logical block size | Little-endian `uint16`; read as `sector_size` |
| 156 | 34 | Root directory record | Fixed-size directory entry for the root directory |

---

## Directory Record Format

Each directory entry is a variable-length record. The entry's total length
is stored in **byte 0**. The minimum valid size is **34 bytes**
(`minimum_file_entry_size`).

### Fields

| Offset | Size | Type | Field | Notes |
|---|---|---|---|---|
| 0 | 1 | `uint8` | Record length | Total bytes for this entry (must be ≥ 34) |
| 2 | 4 | `uint32_le` | Data sector | Logical sector where file/directory data begins |
| 10 | 4 | `uint32_le` | Data length | Size of the file data in bytes |
| 25 | 1 | `uint8` | Flags | Bitmask — see below |
| 32 | 1 | `uint8` | Filename length | Length of the file identifier that follows |
| 33 | N | bytes | File identifier | Filename bytes, followed by `;` + version (trimmed by [[trim_file_id]]) |

### Flag Bitmask (`iso_dir_ent_flag`)

| Bit | Value | Constant | Meaning |
|---|---|---|---|
| 0 | `0x01` | `def_hidden` | Hidden entry |
| 1 | `0x02` | `def_directory` | Entry is a directory (not a file) |
| 7 | `0x80` | `def_multi_extent` | File spans multiple extents |

### Filename Normalization

All filenames are normalized before storage (see [[normalise]]):

- Letters `a`–`z` are converted to `A`–`Z`
- Underscore `_` is converted to hyphen `-`

The `;version` suffix (e.g. `;1`) is stripped by [[trim_file_id]].

### Special Directory Identifiers

Within directory records (not at root level):

| Identifier | Meaning |
|---|---|
| `\x00` | Current directory (`.`) |
| `\x01` | Parent directory (`..`) |

These are skipped during traversal unless at the root level.

---

## File Table Structure

CorsixTH builds a flat, sorted vector of `file_metadata` entries during
construction. This table is the primary lookup structure.

### `file_metadata` Layout

```cpp
struct file_metadata {
  std::string path;   // Normalized full path (e.g. "DATA/DATA01.TAB")
  uint32_t sector;    // Logical sector of file data
  uint32_t size;      // File size in bytes
};
```

### Build Process

1. [[build_file_lookup_table]] is called recursively on the Theme Hospital
   data directory.
2. For each directory entry: if it is a file, a `file_metadata` is appended
   to the `files` vector with the path constructed as `prefix/FILENAME`.
3. If it is a subdirectory (with name length > 1), the function recurses
   into that directory.
4. After all entries are collected, the vector is **sorted by path** for
   binary search lookup (see [[find_file]]).
5. Maximum path length is capped at **256 bytes**.
6. Maximum directory recursion depth is **16** (`max_directory_depth`,
   spec formally allows 8).

### Lookup

`find_file(path)` performs a binary search over the sorted `files` vector.
File handles are **1-based indices** into this vector (0 = invalid).
The `is_handle_good()` helper tests `handle != 0`.

---

## Theme Hospital Directory Detection

The constructor calls [[find_hosp_directory]] to locate the game data
directory within the ISO tree.

### Detection Strategy

1. Starting from the root directory entry in the primary volume descriptor,
   the function walks all directory entries.
2. For each directory entry (flag `def_directory` set), it reads the
   directory's contents and recurses.
3. For each file entry, it checks whether the filename equals `"VBLK-0.TAB"`
   (`vblk_0_filename`). This file is unique to Theme Hospital and signals
   the correct directory has been found.
4. When found, return values propagate back up the recursion stack:
   - `1` — the current directory contains `VBLK-0.TAB`
   - `2` — the parent directory is the Theme Hospital data root
   - Other values indicate how many levels above the data directory

### Sanity Checks

- Non-root directory record arrays must occupy a whole number of sectors
  (size must be a power of 2, ≥ 2048).
- Recursion depth is capped at 16.

---

## Extension Records

### Joliet and Rock Ridge

The current CorsixTH implementation **does not parse** Joliet or Rock Ridge
extensions. Only the base ISO 9660 primary volume descriptor and directory
records are read.

If a disc uses Joliet for long filenames, CorsixTH will still find files
via their ISO 9660 (8.3 uppercase) names, which Theme Hospital's original
disc provides. Rock Ridge POSIX information is likewise ignored.

---

## How CorsixTH Maps ISO Sectors to Game Data

### Data Flow

```
.iso file on disk
    │
    ▼
iso_filesystem constructor
    │
    ├─ Read volume descriptors starting at sector 16
    ├─ Parse primary volume descriptor → extract sector_size, root directory
    ├─ find_hosp_directory() → locate "VBLK-0.TAB" in the tree
    └─ build_file_lookup_table() → populate sorted file_metadata vector
    │
    ▼
find_file("DATA/DATA01.TAB")
    │
    ├─ Binary search over sorted files vector
    └─ Return 1-based handle (or 0 on failure)
    │
    ▼
get_file_start(handle)   →  sector × sector_size  (byte offset in .iso)
get_file_size(handle)    →  size in bytes
get_file_data(handle, buf) → fseek to sector, fread size bytes
```

### Sector-to-Offset Conversion

```
byte_offset = logical_sector × sector_size
```

Where `sector_size` defaults to 2048 but is read from the primary volume
descriptor at offset 128.

### Example

For a file at logical sector 1000 with sector_size = 2048:

```
byte_offset = 1000 × 2048 = 2,048,000
```

---

## Key Constants Summary

| Constant | Value | Location |
|---|---|---|
| `min_sector_size` | 2048 | [[iso_fs.h]]:47 |
| `first_filesystem_sector` | 16 | [[iso_fs.cpp]]:96 |
| `root_directory_offset` | 156 | [[iso_fs.cpp]]:89 |
| `root_directory_entry_size` | 34 | [[iso_fs.cpp]]:92 |
| `sector_size_offset` | 128 | [[iso_fs.cpp]]:86 |
| `file_sector_offset` | 2 | [[iso_fs.cpp]]:56 |
| `file_data_length_offset` | 10 | [[iso_fs.cpp]]:60 |
| `file_flags_offset` | 25 | [[iso_fs.cpp]]:64 |
| `filename_length_offset` | 32 | [[iso_fs.cpp]]:68 |
| `filename_offset` | 33 | [[iso_fs.cpp]]:72 |
| `minimum_file_entry_size` | 34 | [[iso_fs.cpp]]:76 |
| `max_directory_depth` | 16 | [[iso_fs.cpp]]:79 |
| `vblk_0_filename` | `"VBLK-0.TAB"` | [[iso_fs.cpp]]:83 |

## Key Functions

| Function | Purpose |
|---|---|
| [[iso_filesystem]] (constructor) | Open ISO, find primary volume descriptor, locate Theme Hospital data |
| [[find_hosp_directory]] | Recursively search for the directory containing `VBLK-0.TAB` |
| [[build_file_lookup_table]] | Recursively build sorted vector of all game files |
| [[find_file]] | Binary search for a file by normalized path |
| [[get_file_start]] | Convert file handle to byte offset in ISO |
| [[get_file_size]] | Return file size in bytes for a handle |
| [[get_file_data]] | Read file contents into a caller-provided buffer |
| [[seek_to_sector]] | Seek the underlying file to `sector × sector_size` |
| [[read_data]] | Read raw bytes from current file position |
| [[trim_file_id]] | Strip `;version` suffix from ISO file identifiers |
| [[normalise]] | Uppercase letters, replace `_` with `-` |


## Related Pages

- [[CLASS_DIAGRAM]]
- [[MAP]]
- [[SEQUENCE_DIAGRAM]]
- [[SUMMARY]]
