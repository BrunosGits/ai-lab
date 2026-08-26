# ISO Filesystem — Technical Reference

> **CorsixTH C++ Engine — ISO 9660 Filesystem Access**
> Source files: `iso_fs.h`, `iso_fs.cpp`

## 1. Overview

The ISO filesystem module reads Theme Hospital's game data files directly from `.iso` CD-ROM disk images. It implements a read-only ISO 9660 filesystem parser that automatically locates the Theme Hospital data directory within the image and provides file lookup and retrieval via an in-memory file table.

| Type | Role |
|------|------|
| `iso_filesystem` | Main class — opens ISO image, finds TH data, serves file reads |
| `iso_file_entry` | Internal — represents a single directory record from the ISO |
| `iso_directory_iterator` | Internal — forward-only iterator over ISO directory tables |
| `file_metadata` | Internal — cached file path, sector, and size |

---

## 2. `iso_filesystem` Class

**Location:** `iso_fs.h:43–158`, `iso_fs.cpp:349–597`

### Public Interface

| Method | Returns | Description |
|--------|---------|-------------|
| `iso_filesystem(path, pathSeparator)` | — | Opens ISO, finds TH data directory, builds file table |
| `~iso_filesystem()` | — | Default (closes FILE via unique_ptr) |
| `get_error()` | `string_view` | Last error message (after failed operations) |
| `find_file(path)` | `file_handle` | Binary search for file by path |
| `visit_directory_files(path, callback, data)` | `void` | Iterate files in a directory |
| `is_handle_good(handle)` | `bool` | Check if handle is valid (non-zero) |
| `get_file_start(handle)` | `uint32_t` | Byte offset of file in ISO image |
| `get_file_size(handle)` | `uint32_t` | Size in bytes of file |
| `get_file_data(handle, buffer)` | `bool` | Read file contents into buffer |

### Constants

- `min_sector_size = 2048` — minimum sector size (power of two)

### File Handle Type

```cpp
using file_handle = int;
```

Handles are 1-based indices into the `files` vector. `0` means "invalid/not found."

### Private Data

```cpp
std::unique_ptr<std::FILE, int(*)(std::FILE*)> raw_file;  // Open ISO file
std::string error;                                          // Last error message
std::vector<file_metadata> files;                           // Sorted file lookup table
long sector_size;                                           // Detected sector size (≥ 2048)
char path_seperator;                                        // Platform path separator
```

### `file_metadata` Struct

```cpp
struct file_metadata {
    std::string path;    // Normalized uppercase path (e.g. "DATA/QUEUEM.STG")
    uint32_t sector;     // Logical sector number
    uint32_t size;       // File size in bytes
};
```

---

## 3. Construction and Initialization

**Location:** `iso_fs.cpp:349–382`

### Algorithm

1. Open the ISO file with `fopen(path, "rb")`
2. Iterate volume descriptors starting at sector 16 (first filesystem sector)
3. For each sector, read the first 190 bytes (header + root directory entry)
4. Validate `CD001\x01` identifier
5. If primary volume descriptor (type 0x01):
   - Read sector size from offset 128
   - Call `find_hosp_directory()` on the root directory entry
   - If files found, return
6. If terminator (type 0xFF), stop searching
7. If no TH data found, throw `runtime_error`

### Sector Reading

- `seek_to_sector()` (`iso_fs.cpp:564–573`) seeks to `sector_size * sector_number`
- `read_data()` (`iso_fs.cpp:575–582`) reads bytes from the current position
- Uses raw `std::fseek` / `std::fread`

---

## 4. Directory Traversal

### `find_hosp_directory()` (`iso_fs.cpp:389–438`)

Recursively searches for the Theme Hospital data directory:

1. Iterates directory entries using `iso_directory_iterator`
2. For directories: recurses into subdirectories (up to depth 16)
3. For files: looks for `VBLK-0.TAB` as a sentinel file indicating TH data
4. Returns:
   - `0` — not found
   - `1` — current array contains TH data files
   - `2` — current array is the TH data directory itself
5. Higher return values propagate upward with +1 offset

### `build_file_lookup_table()` (`iso_fs.cpp:440–492`)

Builds the complete file table from the TH data directory:

1. Reads the directory sector(s) into a buffer
2. Iterates entries with `iso_directory_iterator`
3. For directories with names longer than 1 char: recurses
4. For files: creates `file_metadata` with full path
5. After recursion completes (at root level), sorts `files` by path for binary search

### Path Normalization

All filenames are normalized via `normalise()` (`iso_fs.cpp:111–143`):
- ASCII letters → uppercase
- Underscores (`_`) → hyphens (`-`)
- File version suffixes (e.g., `;1`) are stripped by `trim_file_id()`

---

## 5. File Operations

### `find_file()` (`iso_fs.cpp:518–536`)

Binary search over the sorted `files` vector:
1. Normalize the input path
2. Binary search comparing normalized paths
3. Returns `index + 1` (1-based handle) on match, `0` on miss

### `get_file_data()` (`iso_fs.cpp:552–560`)

1. Validate handle bounds
2. Seek to `files[handle-1].sector * sector_size`
3. Read `files[handle-1].size` bytes into the caller's buffer

### `visit_directory_files()` (`iso_fs.cpp:494–516`)

Linear scan of `files` looking for entries whose path starts with the normalized directory path. Calls the callback for each matching filename (stripped of the directory prefix).

---

## 6. Internal Classes

### `iso_file_entry` (`iso_fs.cpp:146–188`)

Parses a single ISO 9660 directory record from raw bytes:

| Field | Offset | Size | Description |
|-------|--------|------|-------------|
| entry_size | +0 | 1 | Total size of this directory entry |
| data_sector | +2 | 4 | Logical sector of file data |
| data_length | +10 | 4 | File size in bytes |
| flags | +25 | 1 | Bitmask (directory, hidden, multi-extent) |
| filename_length | +32 | 1 | Length of filename |
| filename | +33 | variable | Filename bytes (normalized on construction) |

Minimum entry size: 34 bytes.

### `iso_directory_iterator` (`iso_fs.cpp:194–345`)

A forward-only input iterator over a byte buffer containing ISO 9660 directory records:

- Constructor: initializes at `begin`, reads first entry
- `operator++()`: advances by `*current_ptr` bytes, skips null padding, reads next entry
- `operator*()`: returns `const iso_file_entry&`
- `operator==` / `operator!=`: compares directory pointers
- Throws `out_of_range` or `runtime_error` on malformed data

### Flag Values

| Flag | Value | Description |
|------|-------|-------------|
| `def_hidden` | 0x01 | Hidden entry |
| `def_directory` | 0x02 | Directory (not a file) |
| `def_multi_extent` | 0x80 | Multi-extent file |

---

## 7. Error Handling

- Construction errors throw `std::runtime_error`
- File read errors set the `error` string via `set_error()` (printf-style formatting)
- `get_file_data()` returns `false` on error; caller checks `get_error()`
- Iterator operations throw on out-of-range access or malformed entries
- Malformed directory entries (too small, filename extends past entry) throw `runtime_error`

---

## 8. Memory Management

- `raw_file` uses `std::unique_ptr<std::FILE, decltype(&fclose)>` for automatic file closing
- `files` vector stores all metadata by value
- `build_file_lookup_table()` uses raw `new[]`/`delete[]` for directory buffers
- `find_hosp_directory()` uses `std::make_unique<uint8_t[]>` for recursion buffers

---

## 9. Integration with CorsixTH

The ISO filesystem is used when the game data comes from an original Theme Hospital CD-ROM image rather than extracted files. The rest of the engine calls `find_file()` to get handles and `get_file_data()` to read contents, abstracting away whether data comes from loose files or an ISO image.

---

## Related Pages

- [[CLASS_DIAGRAM]] — Class hierarchy and relationships
- [[SEQUENCE_DIAGRAM]] — Key operation flows
- [[MAP]] — File:line index for source locations
- [[FORMAT_SPEC]] — ISO 9660 format specification
- [[../area-1-audio/SUMMARY|Audio System]] — Reading SOUND-0.DAT from ISO
- [[../area-2-persistence/SUMMARY|Persistence System]] — Save game persistence
