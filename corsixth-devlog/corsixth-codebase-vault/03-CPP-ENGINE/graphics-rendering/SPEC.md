# Graphics Rendering — Data Structures & Formats

## 1. Palette (256 entries)

- **[Documented fact]** Accepts 768B (RGB) or 1024B (RGBA); `is8bit` selects 6-bit→8-bit expand (`convert_6bit_to_8bit_colour_component`) vs direct copy.
- **[Documented fact]** Stored as `array<argb_colour,256>` via `pack_argb(A,R,G,B)` = R|G<<8|B<<16|A<<24.
- **[Documented fact]** Magenta `0xFFFF00FF` remapped to transparent `0x00000000` in ctor + `set_entry`.
- **[Documented fact]** Alt path: 256-byte index remap; entry 255 forced transparent (not remapped).

## 2. Sprite sheet (TH table + chunks)

- **[Documented fact]** Table entry 6B: `position:u32 LE + width:u8 + height:u8` (`th_sprite_properties`).
- **[Documented fact]** `load_from_th_file(table, chunk, complex, canvas)`; zero-size sprites skipped (slot left empty).
- **[Documented fact]** Chunk RLE: simple mode (`0`=EOL-fill FF, `<0x80`=copy run, else `0x100-b`=FF fill); complex mode adds `0x80–0xBF` fills and `0xC0+`/0xFF (amt,colour) fills; stream ends with `chunk_finish(0xFF)`.
- **[Documented fact]** 32bpp custom sprites: RLE opcodes top-2-bits = 0 opaque / 1 translucent(+opacity) / 2 transparent-skip / 3 recolour(+table,opacity); validated by `testSprite`.

## 3. Animation tables (START/FRAME/LIST/ELEMENT)

- **[Documented fact]** Counts = `len/size`: START/2B, FRAME/`th_frame_properties`, LIST/u16, ELEMENT/`th_element_properties`.
- **[Documented fact]** `frame{list_index, next_frame, sound, flags, bbox, primary/secondary markers}`; `element{sprite, flags, x, y, layer, layer_id, sheet*}`.
- **[Documented fact]** `max_number_of_layers=13` (nibble-sized); `draw_frame` skips non-matching `layer_id` except doctor-head hack (layer 5, W1→W2/B1→B2 fallback).
- **[Documented fact]** Custom-file path (`load_custom_animations`) uses `memory_reader` blocks with per-block sheet appended to `custom_sheets`; original path requires offset-0 load.

## 4. Bitmap / draw flags / fonts

- **[Documented fact]** `raw_bitmap`: flat `width*height` 8bpp + width → `height=len/width`; single `SDL_Texture`; `draw` honors `should_scale_bitmaps`.
- **[Documented fact]** Flags passthrough in `draw_frame` is only `alt_palette|nearest`; element flags supply flip/alpha otherwise.
- **[Documented fact]** `bitmap_font`: glyph N = ASCII-31 (space at sheet idx 1); UTF-8→cp437/mik via `unicode_to_font_character`; per-glyph `draw_sprite` with `thdf_nearest`.
- **[Documented fact]** `freetype_font`: 128-slot (`cache_size_log2=7`) message cache; grey (not mono) path; `match_bitmap_font` derives colour/size from reference sheet.

## 5. Render target / SDL3

- **[Documented fact]** `render_target` ctor: `SDL_CreateWindowWithProperties` → `SDL_CreateRendererWithProperties` (only VSync via `present_immediate`).
- **[Documented fact]** No backend-name selection in `Src/`; target-texture probe sets `supports_target_textures`; `get_renderer_details` returns `SDL_GetRendererName`.
- **[Inference]** GL vs D3D vs Metal vs software is SDL3 auto-choice; Lua only toggles `present_immediate/direct_zoom/hidpi/fullscreen/maximized`.
- **[Hypothesis]** Fullscreen letterbox + `RaiseWindow`/drain workaround exist for Wayland/macOS quirks, not perf tiers.

## 6. Clip rect / draw flags

| Bit | C++ | Lua | Meaning |
|-----|-----|-----|---------|
| 0 | `flip_horizontal` | `FlipHorizontal` | mirror X |
| 1 | `flip_vertical` | `FlipVertical` | mirror Y |
| 2+3 | `alpha_50/75` | `Alpha50/75` | both set = invisible + no hit-test |
| 4 | `alt_palette` (16) | `AltPalette` | ghost remap; validity toggle in placement previews |
| 5–7 | `alt32_{plain,grey,blue_red}` | `Alt32_*` consts | 32bpp ghost style |
| 10 | `early_list` (1024) | `EarlyList` | attach to `oEarlyEntities` |
| 12 | `bound_box_hit_test` | `BoundBoxHitTest` | skip pixel-perfect test |
| 13 | `crop` | `Crop` | 64px column clip (`crop_column`) |
| 14 | `nearest` | `Nearest` | nearest-neighbour scale |

## Related pages

- [[graphics-rendering/SUMMARY]] — overview
- [[graphics-rendering/MAP]] — file:line index
- [[graphics-rendering/CLASS_DIAGRAM]] — class graph
- [[graphics-rendering/SEQUENCE_DIAGRAM]] — render path