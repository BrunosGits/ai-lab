# ISO Filesystem — File:Line Index

> **Source locations for `iso_fs.h` and `iso_fs.cpp`**

## iso_fs.h

| Line(s) | Symbol | Description |
|---------|--------|-------------|
| 23–24 | `CORSIX_TH_ISO_FS_H_` | Include guard |
| 26 | `#include "config.h"` | CorsixTH configuration header |
| 28–32 | Standard includes | `<cstdio>`, `<memory>`, `<string>`, `<string_view>`, `<vector>` |
| 34–42 | Class doc comment | ISO 9660 layer for Theme Hospital .iso disk images |
| 43 | `class iso_filesystem` | Main filesystem class declaration |
| 47 | `min_sector_size` | `static constexpr size_t` = 2048 |
| 56 | `iso_filesystem(path, pathSeparator)` | Constructor — opens ISO, finds TH data |
| 57 | `~iso_filesystem()` | Default destructor |
| 63 | `get_error()` | Returns last error as `string_view` |
| 65 | `file_handle` | Type alias: `int` (1-based index) |
| 72 | `find_file(sPath)` | Binary search for file by path |
| 82–85 | `visit_directory_files(sPath, fnCallback, pCallbackData)` | Iterate files in a directory |
| 88 | `is_handle_good(x)` | Static inline — checks handle != 0 |
| 94 | `get_file_start(iFile)` | Byte offset of file in ISO image |
| 100 | `get_file_size(iFile)` | Size in bytes of file |
| 108 | `get_file_data(iFile, pBuffer)` | Read file contents into buffer |
| 111–115 | `struct file_metadata` (private) | Path, sector, size — internal file entry |
| 117 | `raw_file` | `unique_ptr<FILE>` — open ISO file handle |
| 118 | `error` | `std::string` — last error message |
| 119 | `files` | `vector<file_metadata>` — sorted file lookup table |
| 120 | `sector_size` | `long` — detected sector size (>= 2048) |
| 121 | `path_seperator` | `char` — platform path separator |
| 124 | `set_error(sFormat, ...)` | Private — printf-style error setter |
| 127 | `seek_to_sector(iSector)` | Private — seek to logical sector |
| 130 | `read_data(iByteCount, pBuffer)` | Private — read bytes from current position |
| 142–143 | `find_hosp_directory(pDirEnt, dirEntsSize, level)` | Private — recursive TH data directory search |
| 152–153 | `build_file_lookup_table(iSector, dirEntsSize, prefix)` | Private — build sorted file table |
| 156–157 | `file_metadata_less(lhs, rhs)` | Private static — comparator for `file_metadata` |

## iso_fs.cpp

| Line(s) | Symbol | Description |
|---------|--------|-------------|
| 23 | `#include "iso_fs.h"` | Self-include |
| 25–34 | Standard includes | `<algorithm>`, `<cstdarg>`, `<cstdio>`, `<cstring>`, `<exception>`, `<iterator>`, `<memory>`, `<stdexcept>`, `<utility>`, `<vector>` |
| 36 | `#include "th.h"` | Theme Hospital helper (`bytes_to_uint32_le`, etc.) |
| 38 | `namespace {` | Anonymous namespace opens |
| 40–45 | `enum iso_volume_descriptor_type` | `vdt_primary_volume` = 0x01, `vdt_terminator` = 0xFF |
| 48–52 | `enum iso_dir_ent_flag` | `def_hidden` = 0x01, `def_directory` = 0x02, `def_multi_extent` = 0x80 |
| 56 | `file_sector_offset` | `constexpr ptrdiff_t` = 2 — data sector offset in entry |
| 60 | `file_data_length_offset` | `constexpr ptrdiff_t` = 10 — data length offset in entry |
| 64 | `file_flags_offset` | `constexpr ptrdiff_t` = 25 — flags offset in entry |
| 68 | `filename_length_offset` | `constexpr ptrdiff_t` = 32 — filename length offset |
| 72 | `filename_offset` | `constexpr ptrdiff_t` = 33 — filename start offset |
| 76 | `minimum_file_entry_size` | `constexpr uint8_t` = 34 |
| 79 | `max_directory_depth` | `constexpr int` = 16 (spec formal limit is 8) |
| 83 | `vblk_0_filename` | `constexpr const char*` = "VBLK-0.TAB" — TH sentinel file |
| 86 | `sector_size_offset` | `constexpr size_t` = 128 — sector size in PVD |
| 89 | `root_directory_offset` | `constexpr ptrdiff_t` = 156 — root dir entry in PVD |
| 92 | `root_directory_entry_size` | `constexpr size_t` = 34 |
| 96 | `first_filesystem_sector` | `constexpr uint32_t` = 16 — skip boot area |
| 100–107 | `trim_file_id(sIdent, iLength)` | Strip `;N` file version suffix from identifier |
| 111–119 | `normalise(char c)` | Single char → uppercase, `_` → `-` |
| 123–131 | `normalise(const uint8_t*, size_t)` | Byte range → normalized filename string |
| 135–143 | `normalise(const char*)` | C-string → normalized filename string |
| 146–188 | `class iso_file_entry` | Directory record parser |
| 149 | `iso_file_entry()` | Default constructor (dummy entry) |
| 156–172 | `iso_file_entry(const uint8_t* b)` | Construct from raw bytes — validates size, parses fields |
| 175 | `data_sector` | `uint32_t` — logical sector of file data |
| 178 | `data_length` | `uint32_t` — file size in bytes |
| 184 | `flags` | `uint8_t` — directory entry flags bitmask |
| 187 | `filename` | `std::string` — normalized filename |
| 194–345 | `class iso_directory_iterator` | Forward-only input iterator over directory table |
| 195–199 | Iterator type aliases | `iterator_category`, `value_type`, `difference_type`, `pointer`, `reference` |
| 202 | `iso_directory_iterator()` | Deleted default constructor |
| 213–222 | `iso_directory_iterator(begin, end)` | Main constructor — initializes at first entry |
| 227–231 | `iso_directory_iterator(it&)` | Copy constructor |
| 236–243 | `iso_directory_iterator(it&&)` | Move constructor |
| 245 | `~iso_directory_iterator()` | Default destructor |
| 251–253 | `operator==(rhs)` | Pointer equality comparison |
| 259–261 | `operator!=(rhs)` | Inequality via `operator==` |
| 266–271 | `operator*()` | Dereference — returns `const iso_file_entry&` |
| 276 | `operator=(it&)` | Copy assignment (defaulted) |
| 281–289 | `operator=(it&&)` | Move assignment |
| 298–324 | `operator++()` | Pre-increment — advance by entry size, skip null padding |
| 330–334 | `operator++(int)` | Post-increment — returns copy of old iterator |
| 338 | `directory_ptr` | Private — current position in buffer |
| 341 | `end_ptr` | Private — end of buffer |
| 344 | `entry` | Private — current parsed entry |
| 347 | `}  // namespace` | Anonymous namespace closes |
| 349–382 | `iso_filesystem::iso_filesystem(path, pathSeparator)` | Constructor — opens file, iterates volume descriptors, finds TH data |
| 384–387 | `file_metadata_less(lhs, rhs)` | Path-based comparator: `lhs.path < rhs.path` |
| 389–438 | `find_hosp_directory(pDirEnt, dirEntsSize, level)` | Recursive search for TH data directory using `VBLK-0.TAB` sentinel |
| 440–492 | `build_file_lookup_table(iSector, dirEntsSize, prefix)` | Build sorted `files` vector from directory entries |
| 494–516 | `visit_directory_files(sPath, fnCallback, pCallbackData)` | Linear scan — calls callback for direct children of a directory |
| 518–536 | `find_file(sPath)` | Binary search over sorted `files` — returns 1-based handle or 0 |
| 538–543 | `get_file_start(iFile)` | Returns `sector * sector_size` or 0 on bad handle |
| 545–550 | `get_file_size(iFile)` | Returns `files[iFile-1].size` or 0 on bad handle |
| 552–560 | `get_file_data(iFile, pBuffer)` | Seeks to sector, reads size bytes into buffer |
| 562 | `get_error()` | Returns `error` string_view |
| 564–573 | `seek_to_sector(iSector)` | `fseek(raw_file, sector_size * iSector, SEEK_SET)` |
| 575–582 | `read_data(iByteCount, pBuffer)` | `fread(pBuffer, 1, iByteCount, raw_file)` |
| 584–597 | `set_error(sFormat, ...)` | `vsnprintf` into 1024-byte buffer, stores in `error` |

---

## Related Pages

- [[SUMMARY]] — Full technical reference
- [[CLASS_DIAGRAM]] — Class hierarchy visualization
- [[SEQUENCE_DIAGRAM]] — Key operation flows
- [[FORMAT_SPEC]] — ISO 9660 format specification
