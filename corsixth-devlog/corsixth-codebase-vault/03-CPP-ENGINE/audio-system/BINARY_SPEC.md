# Audio System — Binary Format Specification

> **Theme Hospital SOUND-0.DAT and SOUND-0.PAL binary formats**

## 1. SOUND-0.DAT Overview

The file `SOUND-0.DAT` is a Theme Hospital archive containing all sound effects as embedded PCM WAV data. The file is organized as:

```
[ Sound Data Blocks ] [ Sound File Table ] [ Archive Header ] [ uint32: header_offset ]
```

The archive header is located near the end of the file. Its position is stored in the **last 4 bytes** of the file as a little-endian uint32.

---

## 2. Archive Header

**Size:** 234 bytes
**Location:** Read from last 4 bytes of file

### Header Layout

| Offset | Size | Type | Description |
|--------|------|------|-------------|
| +0 | 234 | — | Full header block |
| +50 | 4 | uint32 LE | Position (byte offset) of the sound file table |
| +58 | 4 | uint32 LE | Length (in bytes) of the sound file table |

### Parsing Algorithm

```
header_position = read_uint32_le(file_end - 4)
table_position  = read_uint32_le(data + header_position + 50)
table_length    = read_uint32_le(data + header_position + 58)
sound_count     = table_length / 32
```

---

## 3. Sound File Table

**Entry size:** 32 bytes each
**Location:** At `table_position` within the archive

### Table Entry Layout

| Offset | Size | Type | Description |
|--------|------|------|-------------|
| +0 | 18 | char[18] | Sound name (null-padded ASCII filename) |
| +18 | 4 | uint32 LE | Byte offset of sound data within the archive |
| +26 | 4 | uint32 LE | Byte length of sound data |

### Notes

- The table contains `table_length / 32` entries
- Entry index 0 is a **dummy entry** (its position/length spans the entire file) — this is a legacy artifact from early CorsixTH versions
- Valid sound indices are **1 through sound_count - 1**

---

## 4. Sound Data Blocks

Each sound is stored as a complete **RIFF/WAV** file within the data blocks:

### WAV/RIFF Structure

```
+0   "RIFF"               (4 bytes)
+4   file_size - 8        (uint32 LE)
+8   "WAVE"               (4 bytes)
+12  "fmt "               (4 bytes — format chunk tag)
+16  fmt_chunk_size       (uint32 LE, typically 16)
+20  audio_format         (uint16 LE, 1 = PCM)
+22  channel_count        (uint16 LE)
+24  sample_rate          (uint32 LE)
+28  byte_rate            (uint32 LE)
+32  block_align          (uint16 LE)
+34  bits_per_sample      (uint16 LE)
+36  "data"               (4 bytes — data chunk tag)
+40  data_size            (uint32 LE)
+44  raw PCM data         (data_size bytes)
```

### Duration Calculation

```
duration_ms = (data_length * 8000) / (bits_per_sample * channels * sample_rate)
```

---

## 5. SOUND-0.PAL Format

The `.PAL` file is a Theme Hospital **palette** file used for color definitions. Based on the Theme Hospital specification:

### Palette Structure

| Offset | Size | Type | Description |
|--------|------|------|-------------|
| +0 | 4 | uint32 | Number of palette entries |
| +4 | N × 3 | RGB triples | 256 palette entries, each 3 bytes (R, G, B) |

Each palette entry:
- Red:   1 byte (0–63 range for DOS VGA palette)
- Green: 1 byte (0–63 range)
- Blue:  1 byte (0–63 range)

The palette is used by the game's rendering engine to convert indexed-color sprites to RGB for display.

---

## 6. File Layout Diagram

```
SOUND-0.DAT
┌─────────────────────────────────────┐  Offset 0
│  Sound Data Block 0 (WAV)           │
│  ...                                │
├─────────────────────────────────────┤
│  Sound Data Block 1 (WAV)           │
│  ...                                │
├─────────────────────────────────────┤
│  ...                                │
├─────────────────────────────────────┤
│  Sound Data Block N (WAV)           │
│  ...                                │
├─────────────────────────────────────┤  table_position
│  Table Entry 0 (32 bytes)           │  ← dummy entry
│  Table Entry 1 (32 bytes)           │  ← first valid sound
│  ...                                │
│  Table Entry N (32 bytes)           │
├─────────────────────────────────────┤  header_position
│  Archive Header (234 bytes)         │
│    [+50] table_position (uint32)    │
│    [+58] table_length (uint32)      │
├─────────────────────────────────────┤
│  header_offset (uint32 LE)          │  ← last 4 bytes of file
└─────────────────────────────────────┘

SOUND-0.PAL
┌─────────────────────────────────────┐  Offset 0
│  entry_count (uint32 LE)            │
├─────────────────────────────────────┤
│  Palette Entry 0 (R, G, B)          │
│  Palette Entry 1 (R, G, B)          │
│  ...                                │
│  Palette Entry 255 (R, G, B)        │
└─────────────────────────────────────┘
```

---

## 7. Safety Considerations

- The loader validates that `iDataLength >= sizeof(uint32) + archive_header_size` before parsing
- Header position is bounds-checked against file length
- Table entry reads are bounds-checked against `iDataLength`
- The `load_sound()` method returns `nullptr` for index 0 and out-of-range indices
- WAV duration parsing gracefully handles malformed RIFF chunks by returning 0

---

## Related Pages

- [[SUMMARY]] — Full technical reference for the audio system
- [[CLASS_DIAGRAM]] — Class hierarchy
- [[MAP]] — Source file line index
- [[../area-3-iso-filesystem/FORMAT_SPEC|ISO 9660 Format]] — Reading DAT files from ISO images
