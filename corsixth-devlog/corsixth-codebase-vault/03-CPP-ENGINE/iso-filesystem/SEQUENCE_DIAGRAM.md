# ISO Filesystem — Sequence Diagrams

> **Mermaid sequence diagrams for key ISO filesystem operations**

## 1. ISO Filesystem Construction

```mermaid
sequenceDiagram
    participant App as CorsixTH Application
    participant IFS as iso_filesystem
    participant FILE as std::FILE
    participant ITER as iso_directory_iterator
    participant Entry as iso_file_entry

    App->>IFS: new iso_filesystem(path)
    IFS->>FILE: fopen(path, "rb")

    loop For each sector starting at 16
        IFS->>FILE: fseek(sector_size * sector)
        IFS->>FILE: fread(buffer, 190 bytes)

        IFS->>IFS: memcmp(buffer+1, "CD001\x01", 6)

        alt Primary Volume Descriptor (type 0x01)
            IFS->>IFS: sector_size = bytes_to_uint16_le(buffer+128)
            IFS->>IFS: find_hosp_directory(buffer+156, 34, 0)
            Note right of IFS: Recursive directory search
            IFS->>IFS: files is non-empty → return
        else Terminator (type 0xFF)
            IFS->>IFS: break
        end
    end

    IFS->>IFS: throw runtime_error if nothing found
```

---

## 2. Hospital Directory Search

```mermaid
sequenceDiagram
    participant IFS as iso_filesystem
    participant ITER as iso_directory_iterator
    participant Entry as iso_file_entry
    participant FILE as std::FILE

    IFS->>ITER: new iterator(pDirEnt, pDirEnt + size)

    loop For each directory entry
        ITER->>Entry: Parse entry from current position
        ITER->>IFS: ++iterator → advance to next entry

        alt Entry is directory (flags & def_directory)
            IFS->>FILE: fseek(entry.data_sector * sector_size)
            IFS->>FILE: fread(buffer, entry.data_length)
            IFS->>IFS: find_hosp_directory(buffer, size, level+1)

            alt Found at level 1 (return 2)
                IFS->>IFS: build_file_lookup_table(sector, size, "")
                IFS-->>IFS: return level + 1
            else Found deeper
                IFS-->>IFS: return level + 1
            end
        else Entry is file
            alt filename == "VBLK-0.TAB"
                IFS-->>IFS: return 1 (found TH data)
            end
        end
    end

    IFS-->>IFS: return 0 (not found)
```

---

## 3. File Lookup Table Construction

```mermaid
sequenceDiagram
    participant IFS as iso_filesystem
    participant ITER as iso_directory_iterator
    participant Entry as iso_file_entry
    participant FILE as std::FILE
    participant FILES as files vector

    IFS->>FILE: fseek(sector * sector_size)
    IFS->>FILE: fread(pBuffer, dirEntsSize)

    IFS->>ITER: new iterator(pBuffer, pBuffer + dirEntsSize)

    loop For each entry
        ITER->>Entry: Parse from current position
        ITER->>IFS: ++iterator

        alt Entry is directory (name.length > 1)
            IFS->>IFS: build_file_lookup_table(sector, length, prefix + "/" + name)
            Note right of IFS: Recurse with updated prefix
        else Entry is file
            IFS->>FILES: push_back({path, sector, size})
            Note right of FILES: path = prefix + "/" + name
        end
    end

    alt At root level (prefix is empty)
        IFS->>FILES: sort(files, file_metadata_less)
        Note right of FILES: Sort by path for binary search
    end
```

---

## 4. File Open and Read Flow

```mermaid
sequenceDiagram
    participant App as Game Code
    participant IFS as iso_filesystem
    participant FILES as files vector
    participant FILE as std::FILE

    App->>IFS: find_file("DATA/QUEUEM.STG")
    IFS->>IFS: normalise("DATA/QUEUEM.STG")

    loop Binary search in files
        IFS->>FILES: Compare normalized path vs files[mid].path
    end

    alt Found
        IFS-->>App: handle = index + 1
    else Not found
        IFS-->>App: handle = 0
    end

    App->>IFS: is_handle_good(handle)
    IFS-->>App: true

    App->>IFS: get_file_size(handle)
    IFS->>FILES: files[handle-1].size
    IFS-->>App: size (uint32_t)

    App->>App: allocate buffer of size bytes

    App->>IFS: get_file_data(handle, buffer)
    IFS->>FILES: files[handle-1].sector
    IFS->>FILE: fseek(sector * sector_size)
    IFS->>FILE: fread(buffer, 1, size)
    IFS-->>App: true (success)
```

---

## 5. Directory Visit Flow

```mermaid
sequenceDiagram
    participant App as Game Code
    participant IFS as iso_filesystem
    participant FILES as files vector

    App->>IFS: visit_directory_files("DATA", callback, userData)
    IFS->>IFS: normalise("DATA")

    loop For each file in files
        IFS->>FILES: Check if file.path starts with normalised_path
        alt Path matches
            IFS->>IFS: Extract filename (strip directory prefix)
            alt No path separator in remaining name (direct child)
                IFS->>App: callback(userData, filename, full_path)
            end
        end
    end
```

---

## 6. Iterator Advancement

```mermaid
sequenceDiagram
    participant ITER as iso_directory_iterator
    participant Entry as iso_file_entry
    participant BUF as Byte Buffer

    Note over ITER: Current position: directory_ptr

    ITER->>ITER: operator++()

    ITER->>BUF: new_ptr = directory_ptr + *directory_ptr
    Note right of BUF: Entry size is first byte

    loop Skip null padding bytes
        ITER->>BUF: while *new_ptr == 0: ++new_ptr
    end

    alt new_ptr < end_ptr and valid entry size
        ITER->>Entry: iso_file_entry(new_ptr)
        ITER->>ITER: directory_ptr = new_ptr
    else Past end of buffer
        ITER->>Entry: iso_file_entry() — dummy empty entry
        ITER->>ITER: directory_ptr = new_ptr
    end
```

---

## Related Pages

- [[SUMMARY]] — Full technical reference
- [[CLASS_DIAGRAM]] — Class hierarchy visualization
- [[MAP]] — Source file line index
- [[FORMAT_SPEC]] — ISO 9660 format specification
