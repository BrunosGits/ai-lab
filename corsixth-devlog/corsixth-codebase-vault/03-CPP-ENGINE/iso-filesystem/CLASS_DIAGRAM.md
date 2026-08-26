# ISO Filesystem — Class Diagram

> **Mermaid class diagram for the CorsixTH ISO 9660 filesystem module**

```mermaid
classDiagram
    class iso_filesystem {
        -unique_ptr~FILE~ raw_file
        -string error
        -vector~file_metadata~ files
        -long sector_size
        -char path_seperator
        +iso_filesystem(const char* path, char sep)
        +~iso_filesystem()
        +get_error() string_view
        +find_file(const char* path) file_handle
        +visit_directory_files(path, callback, data) void
        +is_handle_good(file_handle) bool$
        +get_file_start(file_handle) uint32_t
        +get_file_size(file_handle) uint32_t
        +get_file_data(file_handle, uint8_t*) bool
        -set_error(const char* fmt, ...) void
        -seek_to_sector(uint32_t) bool
        -read_data(uint32_t, uint8_t*) bool
        -find_hosp_directory(uint8_t*, uint32_t, int) int
        -build_file_lookup_table(uint32_t, uint32_t, string_view) void
        -file_metadata_less(file_metadata&, file_metadata&) bool$
    }

    class file_metadata {
        <<struct>>
        +string path
        +uint32_t sector
        +uint32_t size
    }

    class iso_file_entry {
        <<internal>>
        +uint32_t data_sector
        +uint32_t data_length
        +uint8_t flags
        +string filename
        +iso_file_entry()
        +iso_file_entry(const uint8_t* b)
    }

    class iso_directory_iterator {
        <<internal, input_iterator>>
        -const uint8_t* directory_ptr
        -const uint8_t* end_ptr
        -iso_file_entry entry
        +iso_directory_iterator(begin, end)
        +operator*() const iso_file_entry&
        +operator++() iso_directory_iterator&
        +operator++(int) iso_directory_iterator
        +operator==(rhs) bool
        +operator!=(rhs) bool
    }

    class iso_volume_descriptor_type {
        <<enum>>
        vdt_primary_volume = 0x01
        vdt_terminator = 0xFF
    }

    class iso_dir_ent_flag {
        <<enum>>
        def_hidden = 0x01
        def_directory = 0x02
        def_multi_extent = 0x80
    }

    iso_filesystem *-- "0..*" file_metadata : contains
    iso_filesystem --> iso_file_entry : creates during traversal
    iso_filesystem --> iso_directory_iterator : uses for iteration
    iso_directory_iterator --> iso_file_entry : dereferences to
    iso_directory_iterator ..> iso_dir_ent_flag : checks flags
    iso_filesystem ..> iso_volume_descriptor_type : checks descriptor type
    iso_filesystem ..> "FILE" : reads via raw_file
```

## Relationship Summary

| Relationship | Type | Description |
|-------------|------|-------------|
| `iso_filesystem` → `file_metadata` | contains (vector) | In-memory sorted file lookup table |
| `iso_filesystem` → `FILE` | owns (unique_ptr) | Raw ISO image file handle |
| `iso_directory_iterator` → `iso_file_entry` | dereferences to | Current entry pointed to by iterator |
| `iso_filesystem` → `iso_directory_iterator` | uses | During construction and traversal |
| `iso_file_entry` → `iso_dir_ent_flag` | reads | Directory entry flags |
| `iso_filesystem` → `iso_volume_descriptor_type` | reads | Volume descriptor type bytes |

---

## Related Pages

- [[SUMMARY]] — Full technical reference
- [[SEQUENCE_DIAGRAM]] — Key operation flows
- [[MAP]] — Source file line index
