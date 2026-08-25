# CorsixTH Animation/Graphics System - Deep Research Summary

## Overview

CorsixTH's graphics system is a sophisticated multi-layered architecture that bridges Lua game logic with C++ rendering backends (SDL3). The system handles sprite sheets, raw bitmaps, palettes, animations, fonts, and custom graphics with full save/load persistence support.

---

## 1. Graphics Class (Lua Layer) - `/tmp/CorsixTH/CorsixTH/Lua/graphics.lua`

The `Graphics` class is the primary Lua-side interface for loading and caching all graphical resources. It acts as an abstraction layer that hides C++ API changes from game logic.

### 1.1 Cache Structure

```lua
self.cache = {
    raw = {},                    -- Raw bitmaps (full-screen images)
    tabled = {},                 -- Sprite sheets (tablified graphics)
    palette = {},                -- Palettes by name
    palette_greyscale_ghost = {}, -- Greyscale remap for ghost effects
    ghosts = {},                 -- Ghost data (palette remaps)
    anims = {},                  -- Animation managers by prefix
    language_fonts = {},         -- Cached fonts by cache key
    cursors = setmetatable({}, {__mode = "k"}), -- Weak cursor cache
}
```

### 1.2 Initialization (`Graphics:Graphics`)

- Loads font file (TTF or builtin)
- Loads base palettes via `_loadPalettes()`
- Handles custom graphics via `file_mapping.txt` in graphics folder

### 1.3 Palette Management

**`_loadPalette(dir, name, transparent_255, pal8bit)`** (line 312)
- Reads palette data from data files
- Creates `TH.palette` C++ object
- Generates greyscale ghost remap via `makeGreyscaleGhost()`
- Caches both palette and ghost version
- Marks as permanent (prevents GC)

**`makeGreyscaleGhost(pal)`** (line 273)
- Converts palette entries to luminance (0.299R + 0.587G + 0.114B)
- Finds nearest palette entry for each grey value
- Returns 256-byte remap string

**`getPalette(name)`** (line 340) - Returns cached palette + ghost

**`loadGhost(dir, name, index)`** (line 352) - Extracts 256-byte ghost remap from ghost file

### 1.4 Raw Bitmap Loading

**`loadRaw(name, width, height, dir, _paldir, pal, _transparent_255, flags)`** (line 372)
- Loads `.dat` file (raw pixel data)
- Creates `TH.bitmap` C++ object
- Applies palette and registers reload function
- Caches result

### 1.5 Font System

#### Builtin Font (`loadBuiltinFont`, line 403)
- Uses embedded font data from C++ (`TH.GetBuiltinFont()`)
- Creates `TH.bitmap_font` with cp437 charset
- Sets separation (1, 0) and UI scale factor

#### Language Font Loading (`loadLanguageFont`, line 578)
- Determines bitmap vs freetype based on:
  - `force_bitmap` option
  - Language charset match (`_isLanguageSupportedByTHAssets`)
  - Sprite table visibility of char 46 (ASCII '.')
- Creates proxy wrapper for hot-swapping on language/UI scale change

#### TrueType Font (`_loadTrueTypeFont`, line 628)
- Uses `TH.freetype_font` C++ class
- Caches by composite key: `name,x_sep,y_sep,ttf_color,force_bitmap,shadow,scale`
- Supports shadow, color, UI scaling

#### Font Proxy Pattern (line 441)
```lua
local font_proxy_mt = {
  __index = {
    sizeOf = function(self, ...) return self._proxy:sizeOf(...) end,
    draw = function(self, ...) return self._proxy:draw(...) end,
    drawWrapped = function(self, ...) return self._proxy:drawWrapped(...) end,
    drawTooltip = function(self, ...) return self._proxy:drawTooltip(...) end,
    isBitmap = function(self) return self._proxy:isBitmap() end
  }
}
```
Allows seamless switching between bitmap and freetype fonts on language/scale change.

### 1.6 Cursor Loading

**`loadMainCursor(name)`** (line 224)
- Uses predefined `cursor_data` table with hotspot coordinates
- Loads from `Data/MPointer` or `QData/SPointer` with appropriate palette
- Creates `TH.cursor` C++ object with fallback draw function

**`loadCursor(sheet, index, hot_x, hot_y)`** (line 243)
- Caches per-sheet, per-index
- Registers reload function for video target changes

### 1.7 Animation Loading

**`loadAnimations(dir, prefix)`** (line 774)
- Loads sprite sheet: `prefix .. "Spr-0"`
- Creates `TH.anims` (animation_manager)
- Loads 4 core animation files:
  - `prefix .. "Start-1.ani"` - First frame indices
  - `prefix .. "Fra-1.ani"` - Frame details
  - `prefix .. "List-1.ani"` - Element list indices
  - `prefix .. "Ele-1.ani"` - Element details
- Supports custom animations from `file_mapping.txt`

### 1.8 Sprite Table Loading

**`loadSpriteTable(dir, name, complex, palette)`** (line 820)
- Loads `.tab` (sprite table) and `.dat` (chunk data)
- Creates `TH.sheet` (sprite_sheet)
- Handles complex vs simple chunk decoding
- Registers reload function

### 1.9 Video Target Updates

**`updateTarget(target)`** (line 846)
- Called when video mode changes
- Re-executes all reload functions in two phases:
  1. `reload_functions` (sprite sheets, bitmaps)
  2. `reload_functions_last` (cursors, fonts - depend on sheets)

---

## 2. AnimationManager Class (Lua Layer) - `graphics.lua` lines 858-1056

Utility class for animation metadata and marker positioning.

### 2.1 Animation Length Caching

```lua
function AnimationManager:AnimationManager(anims)
  self.anim_length_cache = {}
  self.anims = anims
end

function AnimationManager:getAnimLength(anim)
  if not self.anim_length_cache[anim] then
    local length = 0
    local seen = {}
    local frame = self.anims:getFirstFrame(anim)
    while not seen[frame] do
      seen[frame] = true
      length = length + 1
      frame = self.anims:getNextFrame(frame)
    end
    self.anim_length_cache[anim] = length
  end
  return self.anim_length_cache[anim]
end
```
- Caches animation frame counts to avoid repeated traversal
- Detects loops via `seen` table

### 2.2 Marker System

Two marker types per frame:
- **Primary**: Patients, machines
- **Secondary**: Staff, VIPs, inspectors

**`setPatientMarker(anim, ...)`** / **`setStaffMarker(anim, ...)`** (lines 938, 943)
Multiple argument formats:
1. Single position for all frames
2. Table of positions per frame (nil = repeat previous)
3. Start/end position (linear interpolation)
4. Keyframe positions with interpolation

**Position formats:**
- Tile: `{x, y}` - converted via `Map:WorldToScreen()`
- Pixel: `{x, y, "px"}` - used directly

---

## 3. C++ Graphics Classes - `/tmp/CorsixTH/CorsixTH/Src/th_gfx.h` & `.cpp`

### 3.1 Draw Flags (`th_gfx.h` lines 50-92)

```cpp
enum draw_flags : uint32_t {
  thdf_flip_horizontal = 1 << 0,
  thdf_flip_vertical = 1 << 1,
  thdf_alpha_50 = 1 << 2,
  thdf_alpha_75 = 1 << 3,
  thdf_alt_palette = 1 << 4,
  thdf_alt32_start = 5,
  thdf_alt32_mask = 0x7 << 5,
  thdf_alt32_plain = 0 << 5,
  thdf_alt32_grey_scale = 1 << 5,
  thdf_alt32_blue_red_swap = 2 << 5,
  thdf_early_list = 1 << 10,      // Right-to-left render pass
  thdf_bound_box_hit_test = 1 << 12,
  thdf_crop = 1 << 13,            // Column cropping for multi-tile objects
  thdf_nearest = 1 << 14,         // Nearest neighbor scaling
};
```

### 3.2 Core Data Structures

#### `animation_manager::frame` (th_gfx.h:356)
```cpp
struct frame {
  size_t list_index;       // First element_list entry
  size_t next_frame;       // Next frame in animation
  unsigned int sound;      // Sound ID to play
  unsigned int flags;      // Bit 0 = start of animation
  
  // Bounding box (all layers enabled)
  int bounding_left, bounding_right, bounding_top, bounding_bottom;
  
  // Markers (humanoid center at floor level)
  int primary_marker_x, primary_marker_y;
  int secondary_marker_x, secondary_marker_y;
};
```

#### `animation_manager::element` (th_gfx.h:387)
```cpp
struct element {
  size_t sprite;              // Sprite index in sheet
  uint32_t flags;             // Flip, alpha, etc.
  int x, y;                   // Offset from animation origin
  uint8_t layer;              // Layer class [0..12]
  uint8_t layer_id;           // Layer option to match
  sprite_sheet* element_sprite_sheet;  // Source sheet (not owned)
};
```

#### `layers` struct (th_gfx.h:190)
```cpp
struct layers {
  uint8_t layer_contents[13];  // max_number_of_layers = 13
};
```
Each layer can have multiple options (e.g., different clothing on layer 1).

#### `animation_start_frames` (th_gfx.h:215)
```cpp
struct animation_start_frames {
  long north{-1}, east{-1}, south{-1}, west{-1};
};
```
For directional animations (4 view directions).

### 3.3 Animation Manager (`animation_manager`)

#### Loading Original Animations (`load_from_th_file`, th_gfx.cpp:188)
Parses 4 TH data files:
1. **Start** (4 bytes/anim): First frame index per animation
2. **Frame** (10 bytes/frame): list_index, width, height, sound, flags, next_frame
3. **List** (2 bytes/entry): Element indices (0xFFFF = end)
4. **Element** (6 bytes/element): table_pos, offset_x, offset_y, layer/flags, layer_id

Key processing:
- Converts TH sprite table position to sprite index: `table_position / 6`
- Adjusts offsets: `x = offset_x - 141`, `y = offset_y - 186`
- Computes bounding boxes from sprite dimensions
- Fixes frame loops (`fix_next_frame`)

#### Custom Animation Format (`load_custom_animations`, th_gfx.cpp:498)
Block-based format with header "CTHG" + version:
- **CA** (Custom Animation): Named animations with 4 directional starts
- **FR** (Frame): Sound + elements
- **SP** (Sprite): Width, height, full-color pixel data

#### Drawing (`draw_frame`, th_gfx.cpp:919)
```cpp
void draw_frame(render_target* pCanvas, size_t iFrame,
                const ::layers& oLayers, float iX, float iY, uint32_t iFlags,
                animation_effect patient_effect, size_t patient_effect_offset,
                int scale_factor) const
```
- Iterates element_list for frame
- Filters by layer_contents match
- Applies patient effects (glowing, jelly) to non-background layers
- Handles horizontal flip with width compensation
- Scales element positions by `scale_factor`

#### Hit Testing (`hit_test`, th_gfx.cpp:850)
1. Bounding box check (with flip)
2. If `thdf_bound_box_hit_test`, return true
3. Per-element pixel-perfect test via `sprite_sheet::hit_test_sprite`
4. Respects layer filtering and flip flags

#### Palette Remapping (`set_animation_alt_palette_map`, th_gfx.cpp:777)
Applies 256-byte remap to all sprites in animation for `thdf_alt_palette` flag.

---

### 3.4 Animation Base & Derived Classes

#### `animation_base` (th_gfx.h:465)
Base for drawable objects attached to map tiles.
- `tile` position (-1,-1 = inactive)
- `pixel_offset` from tile center
- `layers` configuration
- `scale_factor` (drawing only, not persisted)
- `flags` (draw_flags)
- Linked list via `link_list` for tile entity lists

#### `animation` (th_gfx.h:510)
Main animation class with multiple kinds:
```cpp
enum class animation_kind { primary_child, secondary_child, normal, morph };
```

**State:**
- `manager` - animation_manager reference
- `animation_index`, `frame_index`
- `speed` (pixels/tick) OR `parent` (for child animations)
- `patient_effect`, `patient_effect_offset`
- `crop_column` for multi-tile splitting
- `morph_target` for transition animations

**Key Methods:**
- `tick()`: Advances frame, updates position, selects sound
- `draw()`: Delegates to manager->draw_frame with crop support
- `draw_child()`: Draws at parent's marker position
- `draw_morph()`: Vertical split between two animations
- `hit_test()` / `hit_test_morph()` / `hit_test_child()`
- `persist()` / `depersist()`: Full save/load support

**Child Animations** (attached to parent markers):
```cpp
void set_parent(animation* parent_anim, bool use_primary) {
  set_animation_kind(use_primary ? animation_kind::primary_child
                                  : animation_kind::secondary_child);
  parent = parent_anim;
  // Links into parent's draw list
}
```

**Morphing** (e.g., invisible patient curing):
```cpp
void set_morph_target(animation* target, int duration) {
  // Computes vertical split progression over duration
  // Stores bounds in morph_target's pixel_offset/speed
}
```

#### `sprite_render_list` (th_gfx.h:611)
Lightweight multi-sprite object (particles, effects).
- Vector of `{index, x, y}` sprites
- Velocity (`dx_per_tick`, `dy_per_tick`)
- Lifetime counter
- `use_intermediate_buffer` for quality text scaling
- No animation frames (single frame)

---

### 3.5 Sprite Sheet (`sprite_sheet`)

#### Loading (`load_from_th_file`, th_gfx_sdl.cpp:1159)
- Parses `.tab` (6 bytes/sprite: position, width, height)
- Uses `chunk_renderer` to decode `.dat` chunk data
- Converts legacy 8bpp to 32bpp via `convertLegacySprite`

#### Chunk Decoding (`chunk_renderer`, th_gfx.cpp:1040)
Two formats:
- **Simple** (b < 0x80): Copy `b` bytes, Fill `0x100-b` transparent
- **Complex** (b >= 0x80): Variable encoding with recolour layers (type 3)

#### Sprite Drawing (`draw_sprite`, th_gfx_sdl.cpp:1314)
- Lazy texture creation on first draw
- Supports alt palette textures
- Animation effects:
  - **Glowing**: Green color modulation pulsing
  - **Jelly**: Horizontal sine wave distortion per scanline
- Handles flip, scale, nearest neighbor

#### Palette Remapping (`_makeAltBitmap`, th_gfx_sdl.cpp:1407)
Creates temporary palette with remapped indices for `thdf_alt_palette`.

---

### 3.6 Raw Bitmap (`raw_bitmap`)

Simple full-screen image (th_gfx_sdl.cpp:965):
- Single texture from `.dat` + palette
- Supports sub-rect drawing
- Optional bitmap scaling via `render_target::should_scale_bitmaps`

---

### 3.7 Palette (`palette`)

- 256 ARGB entries
- Loads from 6-bit (768 bytes) or 8-bit (1024 bytes) data
- Magenta (0xFF00FF) -> Transparent remapping
- `set_entry()` for runtime modification (e.g., cursor index 255)

---

### 3.8 Font System (C++)

#### `bitmap_font` (th_gfx_font.h/.cpp)
- Uses sprite sheet with charset mapping (cp437/mik)
- Character separation (x_sep, y_sep)
- UI scale factor
- Methods: `sizeOf()`, `draw()`, `drawWrapped()`, `drawTooltip()`

#### `freetype_font` (th_gfx_font.h/.cpp)
- FreeType face from TTF data
- Font options: color, shadow, size, scale
- Glyph caching with composite keys
- Shadow rendering via offset draw

---

## 4. SDL Backend - `/tmp/CorsixTH/CorsixTH/Src/th_gfx_sdl.cpp`

### 4.1 Render Target (`render_target`)

#### Scaling Modes (`set_scale_factor`, line 573)
```cpp
enum scaled_items { none, sprite_sheets, bitmaps, all };
```
- **direct_zoom** (fullscreen): Renders to screen-sized buffer, scales via GPU
- **target_textures**: Renders to virtual-size texture, scales to window
- **bitmap-only**: Scales only raw_bitmap draws

#### Intermediate Textures (`scoped_target_texture`, line 415)
RAII wrapper for render-to-texture:
- Creation with optional scaling
- Automatic commit on destruction
- Used for zoom, text quality, morph clipping

#### Clipping (`push_clip_rect`/`pop_clip_rect`, line 712)
- Stack of SDL_Rect clips
- Intersects with parent clips
- Scaled by `draw_scale()`

#### Drawing Primitives
- `draw()`: Texture with flip, alpha, scale
- `fill_rect()`: Solid color
- `draw_line()`: Graph lines
- `take_screenshot()`: PNG capture

### 4.2 Full-Color Rendering (`full_colour_renderer`)

Decodes 32bpp sprite format (type/length encoding):
- Type 0: Opaque RGB (3 bytes/pixel)
- Type 1: Transparent RGB + opacity byte
- Type 2: Fully transparent run
- Type 3: Recolour layer (palette index remap)

---

## 5. Object Animations & Idle Animations

### 5.1 Animation Flags (from draw_flags)

**`thdf_early_list`** (1 << 10): Attaches to tile's `oEarlyEntities` list (right-to-left render pass for proper overlapping).

**`thdf_crop`** (1 << 13): Enables column cropping for multi-tile objects. Used with `crop_column` (1-based).

**`thdf_flip_horizontal/vertical`**: Sprite flipping.

**`thdf_alpha_50/75`**: Transparency (50% or 75%).

**`thdf_alt_palette`**: Use remapped palette (set via `set_animation_alt_palette_map`).

**`thdf_bound_box_hit_test`**: Skip pixel-perfect hit test.

**`thdf_nearest`**: Nearest-neighbor scaling.

### 5.2 Split Animations for Multi-Tile Objects

Large objects (e.g., 2x2 tile machines) use **split animations**:
- Single animation covers full object
- Each tile draws same animation with `thdf_crop` + `crop_column`
- `crop_column` selects 64-pixel wide column (2x32 tile width)
- Clip rect in `animation::draw()` (th_gfx.cpp:1205):
```cpp
if (flags & thdf_crop) {
  clip_rect rcNew;
  rcNew.x = x + (crop_column - 1) * 32 * scale_factor;
  rcNew.w = 64 * scale_factor;
  // Draw with clipping
}
```

### 5.3 Idle Animations

Objects have idle animation cycles managed by game logic:
- Animation index set via `animation::set_animation(manager, anim)`
- `animation::tick()` advances frame each game tick
- Frame sounds played via `sound_player` at frame position
- Custom frame sounds overridden in `frame_sound_replacements` map (th_gfx.cpp:1526)

---

## 6. Code Examples

### 6.1 Loading a Sprite Sheet (Lua)
```lua
local sheet = Graphics:loadSpriteTable("Data", "VEnd01V", false, "MPalette.dat")
```

### 6.2 Loading Animations (Lua)
```lua
local anims = Graphics:loadAnimations("Data", "VEnd")
local anim_mgr = AnimationManager(anims)
anim_mgr:setAnimLength(123, 10)  -- Override length
```

### 6.3 Creating Animation (C++/Lua Bridge)
```lua
local anim = TH.animation()
anim:set_animation(anim_mgr, 42)  -- Animation #42
anim:set_tile({x = 10, y = 15})
anim:set_pixel_offset(0, 0)
anim:set_layer(1, 2)  -- Layer 1, option 2
```

### 6.4 Child Animation (Speech Bubble)
```lua
local bubble = TH.animation()
bubble:set_animation(anim_mgr, speech_anim)
bubble:set_parent(staff_anim, true)  -- Attach to primary marker
```

### 6.5 Morph Animation (Curing)
```lua
local morph = TH.animation()
morph:set_animation(anim_mgr, cured_anim)
patient_anim:set_morph_target(morph, 30)  -- 30-tick transition
```

### 6.6 Sprite Render List (Particles)
```lua
local particles = TH.spriteList()
particles:set_sheet(effect_sheet)
particles:set_speed(10, -5)
particles:set_lifetime(60)
particles:append_sprite(5, 0, 0)
particles:append_sprite(6, 8, -4)
```

### 6.7 Palette Remapping (Team Colors)
```lua
local ghost_pal = Graphics:getPalette("MPalette.dat")  -- Returns greyscale remap
anims:set_animation_alt_palette_map(anim_id, ghost_pal, thdf_alt32_grey_scale)
-- Draw with thdf_alt_palette flag
```

### 6.8 Font Loading
```lua
-- Bitmap font
local font = Graphics:loadFontAndSpriteTable("QData", "Font01V", false, nil, {
  x_sep = 1, y_sep = 0, apply_ui_scale = true
})

-- TrueType font (unicode)
local font = Graphics:loadLanguageFont("unicode", sprite_table, {
  ttf_color = {red=255, green=255, blue=255},
  ttf_shadow = {offset_x=1, offset_y=1, color={red=0, green=0, blue=0}},
  apply_ui_scale = true
})
```

### 6.9 Custom Animation File Format
```lua
-- CTHG header + blocks
-- CA: Custom Animation (name, tile_size, 4 directional frame indices)
-- FR: Frame (sound, elements[])
-- SP: Sprite (width, height, full-color pixel data)
```

---

## 7. Persistence (Save/Load)

All animation objects implement `persist()`/`depersist()`:
- **animation**: Chain, flags, kind, animation/frame index, pixel_offset, sound, patient_effect, crop_column, speed/parent, layers
- **sprite_render_list**: Chain, flags, sheet, sprites[], velocity, lifetime
- **animation_manager**: Not persisted (rebuilt from data files)
- **sprite_sheet**: Not persisted (reloaded from files)

Lua `Graphics` cache uses `load_info` metatable to reconstruct objects on video target change.

---

## 8. Key File References

| File | Purpose |
|------|---------|
| `Lua/graphics.lua` | Lua Graphics class, AnimationManager, font/cursor/animation loading |
| `Src/th_gfx.h` | C++ class declarations (animation_manager, animation, sprite_sheet, etc.) |
| `Src/th_gfx.cpp` | Core animation logic, loading, drawing, hit-test, persistence |
| `Src/th_gfx_sdl.cpp` | SDL3 backend: textures, rendering, palette, font, scaling |
| `Src/th_gfx_font.h/.cpp` | bitmap_font, freetype_font implementations |
| `Src/th_gfx_common.h` | Shared types: palette, clip_rect, render_target base |
| `Src/th_lua.h` | Lua-C++ binding macros |

---

## 9. Performance Considerations

1. **Caching**: All resources cached in `Graphics.cache` tables
2. **Lazy Textures**: Sprite textures created on first draw
3. **Bounding Boxes**: Precomputed for fast hit-test rejection
4. **Batch Drawing**: `start_nonoverlapping_draws`/`finish_nonoverlapping_draws` hooks (no-op in SDL)
5. **Intermediate Buffers**: For high-quality scaled text rendering
6. **Permanent Objects**: Palettes marked `permanent()` to prevent GC collection

---

## 10. Extension Points

1. **Custom Graphics**: `file_mapping.txt` redirects data files
2. **Custom Animations**: `.cthg` files with CA/FR/SP blocks
3. **TrueType Fonts**: Unicode support via FreeType
4. **Palette Remapping**: Per-animation color changes
5. **Animation Effects**: Glowing, jelly (extensible via `animation_effect` enum)
6. **Scale Factors**: UI scale, bitmap scale, direct zoom

---

*End of Summary - Generated from CorsixTH source analysis*


## Related Pages

- [[19-animation-graphics/CHECKLIST]]
- [[19-animation-graphics/MAP]]
- [[19-animation-graphics/SCAFFOLD]]
