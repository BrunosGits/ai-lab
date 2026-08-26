# CorsixTH Animation/Sprite System - Comprehensive Documentation

## Overview

The CorsixTH graphics system is a sophisticated multi-layered architecture that bridges the original Theme Hospital's 8-bit palette-based graphics with modern SDL3-based 32-bit rendering. The system comprises several interconnected C++ classes exposed to Lua via a binding layer, providing sprite sheets, raw bitmaps, palettes, animations, animation management, and font rendering (both bitmap and FreeType-based).

---

## Core C++ Classes

### 1. `sprite_sheet` (th_gfx.h:1137-1436, th_gfx_sdl.cpp:1079-1436)

**Purpose**: Manages a collection of sprites loaded from Theme Hospital's `.tab` (sprite table) and `.dat` (chunked pixel data) files.

**Key Data Structures**:
```cpp
struct sprite {
    SDL_Texture* texture;           // Primary texture (normal palette)
    SDL_Texture* alt_texture;       // Alternative palette texture
    uint8_t* data;                  // Raw 32bpp encoded pixel data
    uint8_t* alt_palette_map;       // 256-byte remap table for alt palette
    uint32_t sprite_flags;          // thdf_alt32_* flags
    int width, height;
};
```

**Loading Pipeline** (`load_from_th_file`):
1. Parse `.tab` file (6 bytes per entry: 4-byte position, 1-byte width, 1-byte height)
2. For each sprite, extract chunked data from `.dat` at the specified position
3. Decode chunks using `chunk_renderer` (supports simple and complex RLE formats)
4. Convert legacy 8bpp palette-indexed data to 32bpp ARGB using `convertLegacySprite`
5. Store decoded data; textures created lazily on first draw

**Chunk Decoding** (`chunk_renderer::decode_chunks`):
- **Type 0** (b < 0x40): Copy `b` literal pixels
- **Type 1** (0x80 ≤ b < 0xC0): Fill `b-0x80` pixels with palette index 0xFF (transparent)
- **Type 2** (b ≥ 0xC0): Fill with explicit color (complex) or transparent (simple)
- **Type 3** (b = 0): Fill to end of line with transparent
- **Type 4** (b = 0xFF): Extended fill with count + color

**Palette Remapping** (`set_sprite_alt_palette_map`, `_makeAltBitmap`):
- 256-byte remap table maps source palette indices to destination indices
- Combined with `thdf_alt32_*` flags for 32bpp effects: greyscale, red/blue swap
- Alternative texture generated on-demand when `thdf_alt_palette` flag is used

**Drawing** (`draw_sprite`):
- Lazy texture creation via `create_palettized_texture`
- Supports horizontal/vertical flip, alpha 50%/75%, nearest-neighbor scaling
- Special effects: `animation_effect::glowing` (pulsing green), `animation_effect::jelly` (sine-wave horizontal distortion)
- Scale factor applied to destination rect

**Methods**:
- `set_sprite_count(count, canvas)` - Initialize sprite array
- `load_from_th_file(tab_data, tab_len, chunk_data, chunk_len, complex, canvas)` - Load from TH files
- `set_sprite_data(sprite, data, take_ownership, len, width, height)` - Set custom sprite data
- `set_sprite_alt_palette_map(sprite, map, alt32_flags)` - Set palette remap
- `get_sprite_count()`, `get_sprite_size(sprite, &w, &h)`, `get_sprite_size_unchecked()`
- `is_sprite_visible(sprite)` - Check if any non-transparent pixels
- `get_sprite_average_colour(sprite, &colour)` - For font matching
- `draw_sprite(canvas, sprite, x, y, flags, effect_ticks, effect, scale_factor)`
- `wx_draw_sprite(sprite, rgb_data, alpha_data)` - wxWidgets export
- `hit_test_sprite(sprite, x, y, flags)` - Pixel-perfect hit testing

---

### 2. `raw_bitmap` (th_gfx.h:45-675, th_gfx_sdl.cpp:965-1077)

**Purpose**: Full-screen or large bitmap images (backgrounds, UI panels) loaded from `.dat` + `.pal` files.

**Loading** (`load_from_th_file`):
- Reads raw 8bpp pixel data (width × height bytes)
- Converts to 32bpp using `convertLegacySprite` (creates recolour-layer blocks)
- Creates palettized texture via `render_target::create_palettized_texture`

**Drawing** (`draw`):
- Supports source rectangle clipping for partial draws
- Respects `render_target::should_scale_bitmaps` for UI scaling

**Methods**:
- `set_palette(palette*)`
- `load_from_th_file(pixel_data, len, width, canvas, sprite_flags)`
- `draw(canvas, x, y)` / `draw(canvas, x, y, src_x, src_y, w, h)`

---

### 3. `palette` (th_gfx_sdl.cpp:253-293, th_gfx.h:45)

**Purpose**: 256-color palette management with 6-bit to 8-bit color conversion.

**Data**: `std::array<argb_colour, 256> colour_index_to_argb_map`

**Construction**:
- Accepts 768 bytes (RGB) or 1024 bytes (RGBA)
- Converts 6-bit components (0-63) to 8-bit (0-255) via `convert_6bit_to_8bit_colour_component`
- Special case: Magenta (0xFF00FF) → Transparent (0x00000000)

**Methods**:
- `set_entry(index, r, g, b)` - Modify single entry
- `get_argb_data()` - Returns `std::array<argb_colour, 256>&`
- Static `pack_argb(a, r, g, b)`, `get_red/blue/green/alpha(colour)`

---

### 4. `animation_manager` (th_gfx.h:234-463, th_gfx.cpp:143-1038)

**Purpose**: Loads and manages Theme Hospital animation data (Start/Fra/List/Ele .ani files) and custom animations.

**Data Structures**:
```cpp
struct frame {
    size_t list_index;      // Start index in element_list
    size_t next_frame;      // Next frame in animation loop
    unsigned int sound;     // Sound ID to play
    unsigned int flags;     // Bit 0 = start of animation
    int bounding_left, bounding_right, bounding_top, bounding_bottom;
    int primary_marker_x, primary_marker_y;
    int secondary_marker_x, secondary_marker_y;
};

struct element {
    size_t sprite;              // Sprite index in sheet
    uint32_t flags;             // thdf_flip_vertical/horizontal, alpha
    int x, y;                   // Offset from animation origin
    uint8_t layer;              // Layer class [0..12]
    uint8_t layer_id;           // Layer option to match
    sprite_sheet* element_sprite_sheet;  // May be custom sheet
};
```

**Loading Original Animations** (`load_from_th_file`):
1. **Start file** (.ani): 4 bytes per animation → first frame index (uint16)
2. **Frame file** (.ani): 10 bytes per frame → list_index, width, height, sound, flags, next_frame
3. **List file** (.ani): 2 bytes per element → element index (0xFFFF = end of frame)
4. **Element file** (.ani): 6 bytes per element → table_pos/6, offset_x-141, offset_y-186, layer/flags, layer_id

**Custom Animations** (`load_custom_animations`):
- File format: "CTHG" header (6 bytes) + blocks
- **CA block**: Named animation group (name + tile_size + 4 direction start frames)
- **FR block**: Frame (sound + element count + elements)
- **SP block**: Sprite (width, height, size, pixel data)
- Custom sprite sheets stored in `custom_sheets` vector

**Layer System** (13 layers, 0-12):
- Layer 0: Base objects (doors, benches)
- Layer 1-5: Patient/clothing variations
- Layer 5 hack: W1/B1 heads also drawn for W2/B2 (doctor animations)

**Markers**:
- Primary marker: Patient/machine center at floor level
- Secondary marker: Staff/VIP/inspector center
- Set via `set_frame_primary_marker` / `set_frame_secondary_marker`
- Retrieved via `get_frame_primary_marker` / `get_frame_secondary_marker`

**Drawing** (`draw_frame`):
- Iterates frame's element list
- Filters by layer_id matching `layers.layer_contents[layer]`
- Applies `thdf_alt_palette`, `thdf_nearest` flags to all elements
- Handles horizontal flip by mirroring x offset and sprite width
- Patient effects (glowing, jelly) applied only to patient layers (layer>0 || layer_id>0)
- Scale factor multiplies element offsets and sprite dimensions

**Hit Testing** (`hit_test`):
- Bounding box quick reject
- Optional `thdf_bound_box_hit_test` for bbox-only
- Pixel-perfect via `sprite_sheet::hit_test_sprite`
- Handles flip flags

**Methods**:
- `set_sprite_sheet(sprite_sheet*)`
- `load_from_th_file(start, fra, list, ele data)`
- `load_custom_animations(data, len)`
- `set_canvas(canvas)`
- `get_animation_count()`, `get_frame_count()`
- `get_first_frame(anim)`, `get_next_frame(frame)`
- `set_animation_alt_palette_map(anim, map, alt32)`
- `draw_frame(canvas, frame, layers, x, y, flags, patient_effect, effect_offset, scale)`
- `get_frame_extent(frame, layers, &minx, &maxx, &miny, &maxy, flags)`
- `get_frame_sound(frame)`
- `hit_test(frame, layers, x, y, flags, test_x, test_y)`
- `set_frame_primary_marker(frame, x, y)`, `set_frame_secondary_marker(frame, x, y)`
- `get_frame_primary_marker(frame, &x, &y)`, `get_frame_secondary_marker(frame, &x, &y)`
- `get_named_animations(name, tile_size)` → `animation_start_frames`
- `tick()` - Increments game_ticks for animation effects

---

### 5. `animation` (th_gfx.h:510-609, th_gfx.cpp:1192-1645)

**Purpose**: Runtime animation instance attached to entities (humanoids, objects).

**Animation Kinds** (`animation_kind`):
- `normal` - Standard standalone animation
- `primary_child` - Attached to parent's primary marker
- `secondary_child` - Attached to parent's secondary marker
- `morph` - Transition between two animations (e.g., invisible→visible patient)

**State**:
```cpp
animation_manager* manager;
animation* morph_target;
size_t animation_index, frame_index;
union { xy_pair speed; animation* parent; };
size_t sound_to_play;
int crop_column;
animation_kind anim_kind;
animation_effect patient_effect;
size_t patient_effect_offset;
```

**Drawing** (`draw_fn` → `draw`/`draw_child`/`draw_morph`):
- `normal`: Calls `manager->draw_frame` with current frame, layers, position, flags
- `child`: Positions at parent's primary/secondary marker + pixel_offset
- `morph`: Vertical split clipping - top portion draws source animation, bottom draws target
  - Morph target's `pixel_offset.x` = top limit, `pixel_offset.y` = threshold, `speed.x` = bottom limit, `speed.y` = increment per frame

**Cropping** (`thdf_crop` flag):
- Used for split animations (multi-tile objects)
- `crop_column` selects 64-pixel wide vertical strip (scaled)
- Clip rect: x = draw_x + (crop_column-1)*32*scale, w = 64*scale

**Hit Testing**:
- `normal`/`morph`: Delegates to `manager->hit_test`
- `child`: Currently returns false (TODO)

**Ticking** (`tick`):
- Advances `frame_index = manager->get_next_frame(frame_index)`
- Updates `pixel_offset` by `speed` (except child animations)
- Handles morph target vertical progression
- Selects sound: frame-specific replacements → `manager->get_frame_sound`

**Persistence** (`persist`/`depersist`):
- Serializes: chain (next), flags, anim_kind, animation_index, frame_index, pixel_offset, sound, patient_effect, crop_column, speed/parent, layers
- Morph target persisted as separate object reference

**Methods**:
- `set_animation(manager, anim)` - Initialize with animation manager and index
- `set_frame(frame)`, `set_speed(x, y)`, `set_crop_column(col)`
- `set_morph_target(target, duration)` - Compute morph parameters
- `set_parent(parent, use_primary)` - Convert to child animation
- `set_patient_effect(effect)`, `set_animation_kind(kind)`
- `get_primary_marker(&x, &y)`, `get_secondary_marker(&x, &y)` - Includes flip adjustment
- `get_animation()`, `get_frame()`, `get_crop_column()`

---

### 6. `sprite_render_list` (th_gfx.h:611-661, th_gfx.cpp:1677+)

**Purpose**: Lightweight animated sprite sequences (particles, effects) without full animation manager.

**Structure**:
```cpp
struct sprite { size_t index; int x, y; };
sprite_sheet* sheet;
std::vector<sprite> sprites;
int dx_per_tick, dy_per_tick;
int lifetime;  // -1 = infinite
bool use_intermediate_buffer;  // For scaled text quality
```

**Behavior**:
- `tick()`: Advances position by dx/dy per tick, decrements lifetime
- `draw()`: Renders all sprites at current position + offsets
- `hit_test()`: Checks all sprites
- No frame cycling - static sprite list

**Methods**:
- `set_sheet(sheet)`, `set_speed(x, y)`, `set_lifetime(ticks)`
- `set_use_intermediate_buffer()` - For text rendering quality at scale
- `append_sprite(sprite_num, x, y)`
- `is_dead()` - lifetime == 0
- `persist`/`depersist`

---

### 7. `animation_base` / `drawable` (th_gfx.h:100-135, 465-505)

**Base class** for `animation` and `sprite_render_list`.

**Tile Attachment** (`attach_to_tile`):
- Inserts into map tile's entity list (`entities` or `oEarlyEntities` if `thdf_early_list`)
- Sorted by `drawing_layer`
- `thdf_early_list`: Right-to-left rendering pass (for objects behind walls)

**Flags**: `thdf_early_list`, `thdf_crop`, `thdf_bound_box_hit_test`, etc.

**Methods**:
- `remove_from_tile()`, `attach_to_tile(tile_pos, map_tile*, layer)`
- `get/set_flags()`, `get/set_pixel_offset()`, `get/set_tile()`
- `set_layer(layer, id)`, `set_layers_from(other)`, `set_scale_factor(factor)`

---

### 8. Font System (`font`, `bitmap_font`, `freetype_font`) - th_gfx_font.h/cpp

#### Base `font` Interface (th_gfx_font.h:81-137)
```cpp
virtual text_layout get_text_dimensions(msg, len, max_width) = 0;
virtual void draw_text(canvas, msg, len, x, y) = 0;
virtual text_layout draw_text_wrapped(canvas, msg, len, x, y, width, max_rows, skip_rows, align) = 0;
```

#### `bitmap_font` (th_gfx_font.h:139-183, th_gfx_font.cpp:61-218)
- Uses `sprite_sheet` with CP437 or MIK character mapping
- Sprite 0 = space (ASCII 0x20), sequential ASCII mapping
- `set_sprite_sheet(sheet, charset)`, `set_separation(char, line)`, `set_scale_factor(factor)`
- `draw_text_wrapped`: Word-wrapping with alignment (left/center/right)
- Double newline (`\n\n` or `//`) forces paragraph break

#### `freetype_font` (th_gfx_font.h:198-368, th_gfx_font.cpp:220-802)
- FreeType2-based TrueType rendering with caching
- **Cache**: 128 entries (2^7), keyed by hash of text+params
- **Pipeline**:
  1. Parse UTF-8, load glyphs via `FT_Load_Glyph` + `FT_Get_Glyph`
  2. Apply kerning (`FT_Get_Kerning`)
  3. Word-wrap with CJK break rules
  4. Align lines (left/center/right)
  5. Render glyphs to 8-bit alpha cache canvas (`FT_Render_Glyph` → MONO or GRAY)
  6. Convert to 32bpp texture with font color + optional shadow
- **Shadow**: Configurable offset + color, drawn as separate pass
- **Bitmap matching**: `match_bitmap_font` analyzes sprite sheet for average char size/color

**Font Options** (from Lua `font_options` table):
- `x_sep`, `y_sep` - Character/line spacing
- `ttf_color` - {red, green, blue, alpha}
- `force_bitmap` - Force bitmap font even if TTF available
- `ttf_width`, `ttf_height` - Override detected size
- `ttf_shadow` - {offset_x, offset_y, color} or `true`/`false`
- `apply_ui_scale` - Scale with UI scale factor
- `scale_factor` - Internal, set by Graphics

---

## Lua Graphics Class (`/tmp/CorsixTH/CorsixTH/Lua/graphics.lua`)

### Cache Structure
```lua
self.cache = {
    raw = {},           -- raw_bitmap by name
    tabled = {},        -- sprite_sheet by name
    palette = {},       -- palette by filename
    palette_greyscale_ghost = {},  -- greyscale remap strings
    ghosts = {},        -- Ghost palette data (256 bytes each)
    anims = {},         -- animation_manager by prefix
    language_fonts = {},-- freetype_font cache by key
    cursors = {},       -- Weak-keyed cursor cache
}
```

### Resource Loading Methods

**Palettes** (`_loadPalette`, `getPalette`, `loadGhost`):
- Loads from Data/QData/Bitmap directories
- Supports `.pal` (3/4 bytes per entry) and `.pl8` (8-bit) formats
- `transparent_255`: Sets entry 255 to magenta→transparent
- `makeGreyscaleGhost`: Creates 256-byte remap for greyscale rendering

**Raw Bitmaps** (`loadRaw`):
- Loads `.dat` + palette → `raw_bitmap`
- Cached by name
- Reload function captures dir/name/width/height/palette/flags

**Sprite Sheets** (`loadSpriteTable`):
- Loads `.tab` + `.dat` → `sprite_sheet`
- Complex flag for RLE format
- Custom palette support
- Reload function re-reads files

**Animations** (`loadAnimations`):
- Loads `prefix`Spr-0 (sheet) + `prefix`Start-1/Fra-1/List-1/Ele-1.ani
- Custom animations from `file_mapping.txt` in custom graphics folder
- `loadCustomAnims` reads .ca files, passes to `animation_manager:loadCustomAnimations`

**Fonts**:
- `loadBuiltinFont()`: Built-in CP437 font from compressed TH data
- `loadFont(sprite_table, options)`: Bitmap or FreeType based on language
- `loadLanguageFont(name, sprite_table, options)`: Proxy wrapper for language switching
- `loadFontAndSpriteTable(dir, name, complex, palette, options)`: Combined load
- Font proxy (`font_proxy_mt`): Allows hot-swapping bitmap↔FreeType on language/UI scale change
- Cache key: `name,x_sep,y_sep,ttf_color,force_bitmap,ttf_shadow,apply_ui_scale`

**Cursors** (`loadCursor`, `loadMainCursor`):
- Standard cursors from MPointer/SPointer sheets
- Hotspot offsets per cursor type
- Fallback Lua-side drawing if C++ cursor load fails

**Target Update** (`updateTarget`):
- Called when video mode changes
- Re-executes all `reload_functions` and `reload_functions_last`

---

## AnimationManager Lua Wrapper (`graphics.lua:858-1056`)

**Purpose**: High-level animation marker management.

**Marker Setting** (`setPatientMarker`, `setStaffMarker`):
- Accepts flexible argument patterns:
  1. `anim, position` - Static position for all frames
  2. `anim, {pos1, pos2, ...}` - Per-frame positions (nil = repeat previous)
  3. `anim, start_pos, end_pos` - Linear interpolation
  4. `anim, keyframe1, pos1, keyframe2, pos2, ...` - Keyframe interpolation
  5. `anim` can be table of animation numbers

**Position Formats**:
- Tile: `{x, y}` (floating point, tile coordinates, origin at tile (0,0) center)
- Pixel: `{x, y, "px"}` (integer pixel offsets)

**Implementation** (`setMarkerRaw`):
- Converts tile positions via `Map:WorldToScreen(x+1, y+1)`
- Iterates frames via `anims:getFirstFrame`/`getNextFrame`
- Calls `anims:setFramePrimaryMarker`/`setFrameSecondaryMarker`

---

## Object Animations (Lua/entity/object.lua)

### Idle Animations & Flags
```lua
local anim = object_type.idle_animations[direction]
if not anim then
    anim = object_type.idle_animations[orient_mirror[direction]]
    flags = DrawFlags.FlipHorizontal
end
if footprint and footprint.early_list then
    flags = flags + DrawFlags.EarlyList
end
```

**Flags Used**:
- `DrawFlags.FlipHorizontal` (1) - Mirror animation horizontally
- `DrawFlags.EarlyList` (1<<10) - Render in early pass (behind walls)

### Split Animations (Multi-tile Objects)
For objects spanning multiple tiles (e.g., large machines):

```lua
local rap = footprint and footprint.render_attach_position
if rap and rap[1] and type(rap[1]) == "table" then
    self.split_anims = {self.th}
    self.split_anim_positions = rap
    self.th:setCrop(rap[1].column)
    for i = 2, #rap do
        local point = rap[i]
        local th = TH.animation()
        th:setCrop(point.column)
        th:setHitTestResult(self)
        th:setPosition(Map:WorldToScreen(1-point[1], 1-point[2]))
        self.split_anims[i] = th
    end
end
```

**Render Attach Position Format**:
```lua
render_attach_position = {
    {x, y, column},  -- Primary tile (column = crop column)
    {x, y, column},  -- Additional tile 1
    ...
}
```

**Crop Column**: Selects 64-pixel wide vertical strip from animation (0-indexed? 1-indexed in code)

**Animation Application** (`setAnimation`):
```lua
if self.split_anims then
    flags = (flags or 0) + DrawFlags.Crop
    for _, th in ipairs(self.split_anims) do
        th:setAnimation(anims, animation, flags)
    end
end
```

**Position Updates** (`setPosition`, `setTile`):
- Primary animation at render attach tile
- Split animations positioned relative to primary via `WorldToScreen` offsets

---

## Drawing Flags (`draw_flags` enum, th_gfx.h:50-92)

| Flag | Value | Description |
|------|-------|-------------|
| `thdf_flip_horizontal` | 1<<0 | Mirror horizontally |
| `thdf_flip_vertical` | 1<<1 | Mirror vertically |
| `thdf_alpha_50` | 1<<2 | 50% opacity |
| `thdf_alpha_75` | 1<<3 | 75% opacity (combined with 50% = invisible) |
| `thdf_alt_palette` | 1<<4 | Use alternative palette map |
| `thdf_alt32_plain` | 0<<5 | Normal 32bpp rendering |
| `thdf_alt32_grey_scale` | 1<<5 | Greyscale rendering |
| `thdf_alt32_blue_red_swap` | 2<<5 | Swap red/blue channels |
| `thdf_early_list` | 1<<10 | Attach to early render list |
| `thdf_bound_box_hit_test` | 1<<12 | Bounding box hit test only |
| `thdf_crop` | 1<<13 | Enable crop column clipping |
| `thdf_nearest` | 1<<14 | Nearest-neighbor scaling |

---

## SDL Backend Details (`th_gfx_sdl.cpp`)

### Render Target (`render_target`)
- SDL3 renderer + window management
- **Scaling Modes** (`set_scale_factor`):
  - `scaled_items::all` + `direct_zoom`: Fullscreen GPU scaling
  - `scaled_items::all` + target textures: Virtual resolution → upscale
  - `scaled_items::bitmaps`: Bitmap-only CPU scaling
- **Intermediate Textures**: `scoped_target_texture` for offscreen rendering (morph effects, text quality)
- **Clipping**: `scoped_clip` with nested rect intersection

### Texture Creation
- `create_palettized_texture`: 8bpp→32bpp decode → `SDL_CreateTexture` + `SDL_UpdateTexture`
- `create_texture`: Direct 32bpp pixel data → texture
- Blend mode: `SDL_BLENDMODE_BLEND`
- Scale mode: `SDL_SCALEMODE_NEAREST` when `thdf_nearest` flag set

### Drawing (`render_target::draw`)
- Applies alpha mod (50%/75%)
- Handles flip via `SDL_RenderTextureRotated` with `SDL_FLIP_HORIZONTAL/VERTICAL`
- Scales destination rect by `draw_scale()` (global_scale_factor or target texture scale)

### Color Conversion
- `makeGreyScale`: 0.2126R + 0.7152G + 0.0722B (luminance)
- `makeSwapRedBlue`: Compensated channel swap preserving luminance

---

## Animation Data Formats

### Original TH Animation Files
| File | Purpose | Structure |
|------|---------|-----------|
| `*Start-1.ani` | First frame per animation | 4 bytes/anim: uint16 first_frame, uint16 padding |
| `*Fra-1.ani` | Frame data | 10 bytes/frame: list_idx(4), width(1), height(1), sound(1), flags(1), next(2) |
| `*List-1.ani` | Frame→element mapping | 2 bytes/element: uint16 element_index (0xFFFF = end) |
| `*Ele-1.ani` | Element data | 6 bytes/element: table_pos(2), offset_x(1), offset_y(1), layer/flags(1), layer_id(1) |

### Custom Animation Format (.ca files)
```
Header: "CTHG" + version(1) + subversion(2) [6 bytes]
Blocks:
  CA: 'C''A' + tile_size(2) + frame_count(4) + name(str) + N/E/S/W first_frame(4×4)
  FR: 'F''R' + sound(2) + element_count(2) + elements[12 bytes each]
  SP: 'S''P' + width(2) + height(2) + data_size(4) + pixel_data[data_size]
```

---

## Code Examples

### Loading a Sprite Sheet (Lua)
```lua
local graphics = Graphics(app, gfx_set, charset)
local sheet = graphics:loadSpriteTable("QData", "VObjects", false, "MPalette.dat")
```

### Loading Animations (Lua)
```lua
local anims = graphics:loadAnimations("Data", "V")
-- anims is an animation_manager userdata
```

### Creating Animation Instance (Lua)
```lua
local th_anim = TH.animation()
th_anim:setAnimation(anims, animation_index)
th_anim:setTile(map, tile_x, tile_y, layer)
th_anim:setPosition(pixel_x, pixel_y)
th_anim:setFlags(DrawFlags.FlipHorizontal)
```

### Setting Animation Markers (Lua)
```lua
local anim_mgr = TheApp.animation_manager
-- Static position for all frames
anim_mgr:setPatientMarker(123, {1.5, 2.0})

-- Per-frame positions
anim_mgr:setPatientMarker(123, {{0,0}, {1,0}, {2,0}, nil, {4,0}})

-- Linear interpolation
anim_mgr:setPatientMarker(123, {0, 0}, {10, 5})

-- Keyframe interpolation
anim_mgr:setPatientMarker(123, 0, {0,0}, 5, {10,5}, 10, {20,0})
```

### Split Animation Setup (Object Definition)
```lua
object_type.orientations = {
    north = {
        footprint = {{0,0}, {1,0}, {0,1}, {1,1}},
        render_attach_position = {
            {0, 0, 1},   -- Primary tile, crop column 1
            {1, 0, 2},   -- Tile to east, crop column 2
            {0, 1, 3},   -- Tile to south, crop column 3
            {1, 1, 4},   -- Tile to southeast, crop column 4
        },
        animation_offset = {0, 0},
    },
}
```

### Font Loading (Lua)
```lua
-- Bitmap font
local font = graphics:loadFontAndSpriteTable("QData", "Font01V", false, "MPalette.dat", {
    x_sep = 1, y_sep = 0,
    apply_ui_scale = true,
})

-- FreeType font (for non-CP437 languages)
local font = graphics:loadLanguageFont("unicode", sprite_table, {
    ttf_color = {red=255, green=255, blue=255},
    ttf_shadow = {offset_x=1, offset_y=1, color={red=0, green=0, blue=0, alpha=255}},
    apply_ui_scale = true,
})
```

### Drawing Text (C++)
```cpp
// Bitmap font
bitmap_font->draw_text(canvas, "Hello", 5, 100.0f, 100.0f);

// FreeType font with wrapping
text_layout layout = freetype_font->draw_text_wrapped(
    canvas, "Long text...", len, 100.0f, 100.0f, 300, 5, 0, text_alignment::center
);
```

### Custom Palette Remap (C++)
```cpp
uint8_t greyscale_map[256];
// ... fill map ...
animation_manager->set_animation_alt_palette_map(anim_index, greyscale_map, thdf_alt32_grey_scale);
```

---

## Key Integration Points

1. **Graphics → C++**: `Graphics` Lua class creates `TH.palette()`, `TH.sheet()`, `TH.bitmap()`, `TH.anims()`, `TH.animation()`, `TH.bitmap_font()`, `TH.freetype_font()`

2. **Animation Manager**: Created in `app.lua`, passed to entities via `world.anims`

3. **Entity Base** (`entity.lua`): Holds `self.th` (animation or sprite_render_list), handles `setAnimation`, `setTile`, `setPosition`

4. **Map Rendering** (`th_map.cpp`): Iterates tile entity lists, calls `drawable::draw_fn` with tile screen position

5. **Persistence**: `animation::persist`/`depersist`, `sprite_render_list::persist`/`depersist` handle save/load

---

## Performance Considerations

- **Texture Caching**: Sprites create textures lazily on first draw; reused thereafter
- **Font Caching**: FreeType caches 128 rendered strings; bitmap fonts draw directly
- **Animation Frame Caching**: `AnimationManager` caches animation lengths
- **Intermediate Textures**: Used for morph effects and scaled text quality
- **Early List**: Separate render pass for objects behind walls (sorted by layer)
- **Non-overlapping Draws**: `start_nonoverlapping_draws`/`finish_nonoverlapping_draws` hints (no-op in SDL)

---

## Extension Points

1. **Custom Graphics**: `file_mapping.txt` in custom graphics folder loads `.ca` animation files
2. **Custom Palettes**: `_loadPalette` can load any palette file; used for cursors, UI
3. **Animation Effects**: `animation_effect` enum extensible for new shader-like effects
4. **Font Fallback**: `Graphics:loadFont` automatically chooses bitmap vs FreeType based on language support
5. **Sprite Sheet Replacement**: `animation_manager::custom_sheets` allows custom sprites in animations


## Related Pages

- [[CHECKLIST]]
- [[MAP]]
