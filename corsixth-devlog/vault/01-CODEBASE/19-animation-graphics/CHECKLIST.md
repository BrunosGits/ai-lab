# Graphics System - Pre-Fix Checklist

## Before Making Any Graphics Changes

### 1. Understand the Architecture
- [ ] Read `Lua/graphics.lua` - Lua Graphics class, caching, loading
- [ ] Read `Src/th_gfx.h` - C++ class declarations (animation_manager, animation, sprite_sheet, etc.)
- [ ] Read `Src/th_gfx.cpp` - Core animation logic, loading, drawing, persistence
- [ ] Read `Src/th_gfx_sdl.cpp` - SDL3 backend implementation
- [ ] Read `Src/th_gfx_font.h/.cpp` - Font implementations

### 2. Identify Affected Components
- [ ] **Lua Layer**: `Graphics` class methods, `AnimationManager`, cache structures
- [ ] **C++ Layer**: Which classes? `animation_manager`, `animation`, `sprite_sheet`, `raw_bitmap`, `palette`, `bitmap_font`, `freetype_font`, `sprite_render_list`
- [ ] **SDL Backend**: `render_target`, texture creation, drawing primitives, scaling
- [ ] **Data Files**: `.tab/.dat` (sprites), `.ani` (animations), `.pal` (palettes), `.ttf` (fonts)

### 3. Check for Cross-Cutting Concerns

#### Caching & Reloading
- [ ] Does change invalidate `Graphics.cache` entries?
- [ ] Is `reload_functions` / `reload_functions_last` registration needed?
- [ ] Does `updateTarget()` need to handle new resource type?
- [ ] Are `permanent()` objects affected?

#### Persistence (Save/Load)
- [ ] Does change affect `persist()` / `depersist()` in `animation`, `sprite_render_list`?
- [ ] Is `load_info` metatable updated for new resource types?
- [ ] Will saved games load correctly after change?

#### Scaling & UI Scale
- [ ] Does change respect `scale_factor` (animation, sprite_render_list)?
- [ ] Does change respect `global_scale_factor` / `bitmap_scale_factor` (render_target)?
- [ ] Is `thdf_nearest` flag handled for pixel-perfect scaling?
- [ ] Does `use_intermediate_buffer` work for text quality?

#### Palette & Color
- [ ] Does change respect `thdf_alt_palette` and remap textures?
- [ ] Are greyscale ghosts (`palette_greyscale_ghost`) compatible?
- [ ] Is magenta (0xFF00FF) -> transparent remapping preserved?
- [ ] Do animation effects (glowing, jelly) still work?

#### Animation Flags
- [ ] `thdf_flip_horizontal/vertical` - sprite flipping
- [ ] `thdf_alpha_50/75` - transparency
- [ ] `thdf_alt_palette` - palette remapping
- [ ] `thdf_early_list` - right-to-left render pass
- [ ] `thdf_crop` - column cropping for multi-tile
- [ ] `thdf_bound_box_hit_test` - fast hit test
- [ ] `thdf_nearest` - nearest neighbor

### 4. Test Scenarios to Verify

#### Basic Loading
- [ ] Sprite sheet loads from `.tab/.dat` (simple & complex chunks)
- [ ] Raw bitmap loads from `.dat` + palette
- [ ] Palette loads (6-bit & 8-bit, with transparent_255)
- [ ] Animations load from 4 `.ani` files
- [ ] Custom animations load from `.cthg` format
- [ ] Bitmap font loads from sprite sheet + charset
- [ ] TrueType font loads from TTF data
- [ ] Cursor loads from MPointer/SPointer

#### Drawing
- [ ] Sprite draws at correct position with scale
- [ ] Animation frame draws with layers filtering
- [ ] Horizontal flip compensates width correctly
- [ ] Vertical flip works
- [ ] Alpha 50/75 blending works
- [ ] Alt palette remapping works
- [ ] Crop column clips correctly for multi-tile
- [ ] Glowing effect pulses green
- [ ] Jelly effect distorts scanlines
- [ ] Font draws wrapped/tooltip correctly
- [ ] Shadow rendering offsets properly

#### Hit Testing
- [ ] Bounding box rejection works
- [ ] Pixel-perfect hit test works
- [ ] Flip flags affect hit test
- [ ] Layer filtering works
- [ ] `thdf_bound_box_hit_test` shortcut works

#### Animation Logic
- [ ] Frame advancement loops correctly
- [ ] Frame sounds play at correct position
- [ ] Custom frame sounds override (frame_sound_replacements)
- [ ] Child animations follow parent markers
- [ ] Morph animations split vertically over duration
- [ ] Marker positions convert tile->screen correctly
- [ ] Animation length caching works

#### Font System
- [ ] Bitmap font uses correct charset (cp437/mik)
- [ ] TrueType font caches glyphs by composite key
- [ ] Font proxy swaps on language/UI scale change
- [ ] UI scale applies to both font types
- [ ] Shadow color/offset works
- [ ] Arabic numerals detection works

#### Video Target Changes
- [ ] Sprite sheets reload textures
- [ ] Raw bitmaps reload textures
- [ ] Cursors reload (depend on sheets)
- [ ] Fonts reload (depend on sheets)
- [ ] Custom animations reload

#### Multi-Tile Objects
- [ ] Split animations crop to correct column
- [ ] Each tile draws same animation with different crop_column
- [ ] Clip rect scales with scale_factor

#### Performance
- [ ] No texture leaks (destructors called)
- [ ] Caching prevents duplicate loads
- [ ] Lazy texture creation works
- [ ] Intermediate textures cleaned up per frame

### 5. Regression Test Checklist

Run after any graphics change:

- [ ] Start game, verify main menu renders
- [ ] Load saved game, verify all graphics intact
- [ ] Change UI scale (50%, 100%, 150%, 200%), verify fonts/sprites scale
- [ ] Change language (bitmap vs TTF), verify font swap
- [ ] Toggle fullscreen/windowed, verify reload works
- [ ] Test all cursor types
- [ ] Test patient animations (walking, idle, vomiting, etc.)
- [ ] Test machine animations (radiation, scanner, etc.)
- [ ] Test staff animations (walking, working, etc.)
- [ ] Test multi-tile objects (2x2, 3x3 machines)
- [ ] Test particle effects (sprite_render_list)
- [ ] Test tooltip rendering
- [ ] Test graph drawing (epidemic, finance)
- [ ] Test screenshot capture
- [ ] Test custom graphics pack loading
- [ ] Test palette remapping (team colors, ghosts)
- [ ] Test animation effects (glowing cure, jelly)

### 6. Common Pitfalls to Avoid

- [ ] **Don't** modify `animation_manager` frame/element vectors after loading (invalidates indices)
- [ ] **Don't** forget to register reload functions for new C++ resources
- [ ] **Don't** persist `scale_factor` (drawing only, not saved)
- [ ] **Don't** skip `permanent()` for palettes (GC collects them)
- [ ] **Don't** assume sprite sheet indices are stable across reloads
- [ ] **Don't** forget to handle both `thdf_flip_horizontal` in draw AND hit_test
- [ ] **Don't** use `element_list` index directly without checking 0xFFFF terminator
- [ ] **Don't** forget `thdf_crop` clip rect scales with `scale_factor`
- [ ] **Don't** create textures without checking `render_target` validity
- [ ] **Don't** leak intermediate textures (use RAII `scoped_target_texture`)
- [ ] **Don't** forget magenta->transparent remapping in palette loading
- [ ] **Don't** assume 8-bit color input (TH uses 6-bit, convert via `convert_6bit_to_8bit_colour_component`)

### 7. Code Review Checklist

For any PR touching graphics:

- [ ] Lua changes have corresponding C++ binding updates (if needed)
- [ ] New C++ methods exposed to Lua via `th_lua.h` bindings
- [ ] Persistence methods updated for new fields
- [ ] Reload functions registered for new resources
- [ ] Cache keys include all differentiating parameters
- [ ] Error handling for missing files/data
- [ ] Logging for debugging (use `print` in Lua, `std::fprintf` in C++)
- [ ] No raw `new`/`delete` without smart pointers or RAII
- [ ] Thread safety (rendering is single-threaded but verify)
- [ ] Memory leaks checked (valgrind/ASAN)

### 8. Documentation Updates

- [ ] Update `SUMMARY.md` if architecture changes
- [ ] Update `MAP.md` if method signatures change
- [ ] Add test cases to `SCAFFOLD.lua` for new features
- [ ] Update this `CHECKLIST.md` if new concerns arise

---

## Quick Reference: Key Methods by Class

| Class | Key Methods |
|-------|-------------|
| `Graphics` (Lua) | `loadSpriteTable`, `loadAnimations`, `loadRaw`, `loadFont`, `loadLanguageFont`, `loadBuiltinFont`, `loadMainCursor`, `updateTarget`, `_loadPalette`, `getPalette`, `loadGhost` |
| `AnimationManager` (Lua) | `getAnimLength`, `setAnimLength`, `setPatientMarker`, `setStaffMarker` |
| `animation_manager` (C++) | `load_from_th_file`, `load_custom_animations`, `draw_frame`, `hit_test`, `get_first_frame`, `get_next_frame`, `set_animation_alt_palette_map`, `set_frame_primary_marker`, `get_named_animations` |
| `animation` (C++) | `tick`, `draw`, `draw_child`, `draw_morph`, `hit_test`, `set_animation`, `set_parent`, `set_morph_target`, `set_speed`, `set_crop_column`, `persist`, `depersist` |
| `sprite_render_list` (C++) | `tick`, `append_sprite`, `set_sheet`, `set_speed`, `set_lifetime`, `set_use_intermediate_buffer`, `persist`, `depersist` |
| `sprite_sheet` (C++) | `load_from_th_file`, `set_sprite_count`, `set_sprite_data`, `draw_sprite`, `get_sprite_size`, `set_sprite_alt_palette_map`, `is_sprite_visible` |
| `raw_bitmap` (C++) | `load_from_th_file`, `draw`, `set_palette` |
| `palette` (C++) | `set_entry`, `get_argb_data` |
| `bitmap_font` (C++) | `setSheet`, `setSeparation`, `setScaleFactor`, `sizeOf`, `draw`, `drawWrapped`, `drawTooltip` |
| `freetype_font` (C++) | `setFace`, `setFontOptions`, `draw`, `clearCache` |
| `render_target` (C++) | `draw`, `fill_rect`, `create_texture`, `create_palettized_texture`, `set_scale_factor`, `push_clip_rect`, `start_frame`, `end_frame`, `take_screenshot` |

---

*Checklist Version: 1.0 - Generated from CorsixTH source analysis*
