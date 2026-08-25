# Pre-Fix Checklist for CorsixTH Graphics System Changes

This checklist must be completed before committing any changes to the graphics/animation system. Each item represents a critical integration point or regression risk.

---

## 🔴 Critical - Must Pass Before Merge

### Core Rendering Pipeline
- [ ] **Sprite Sheet Loading**: `sprite_sheet::load_from_th_file` correctly parses `.tab` + `.dat` (simple and complex RLE)
- [ ] **Chunk Decoding**: `chunk_renderer::decode_chunks` handles all chunk types (0-3 simple, 0-4 complex)
- [ ] **Legacy Conversion**: `convertLegacySprite` produces valid 32bpp ARGB with recolour layers
- [ ] **Texture Creation**: `render_target::create_palettized_texture` generates correct SDL_Texture
- [ ] **Lazy Texture Creation**: `sprite_sheet::draw_sprite` creates texture on first draw, reuses thereafter
- [ ] **Palette Remapping**: `set_sprite_alt_palette_map` + `_makeAltBitmap` works for greyscale/blue-red swap
- [ ] **Animation Manager Loading**: `load_from_th_file` correctly parses Start/Fra/List/Ele files
- [ ] **Custom Animation Loading**: `load_custom_animations` parses CTHG format (CA/FR/SP blocks)
- [ ] **Frame Drawing**: `animation_manager::draw_frame` renders all elements with correct layer filtering
- [ ] **Hit Testing**: `animation_manager::hit_test` + `sprite_sheet::hit_test_sprite` pixel-perfect
- [ ] **Marker System**: Primary/secondary markers set and retrieved correctly with flip adjustment

### Animation Instance (`animation` class)
- [ ] **Frame Advancement**: `tick()` calls `get_next_frame` and loops correctly
- [ ] **Speed Movement**: `pixel_offset` updated by `speed` each tick (non-child animations)
- [ ] **Child Animations**: Primary/secondary child positioning at parent markers
- [ ] **Morph Animations**: Vertical split clipping with correct threshold progression
- [ ] **Crop Column**: `thdf_crop` flag clips to 64px vertical strip at `crop_column`
- [ ] **Patient Effects**: Glowing (pulse) and jelly (sine wave) render correctly
- [ ] **Sound Playback**: Frame sounds + replacement map play at correct position
- [ ] **Persistence**: `persist`/`depersist` round-trip preserves all state including morph target
- [ ] **Flip Handling**: Horizontal flip mirrors x offset and sprite width in draw/hit_test

### Font System
- [ ] **Bitmap Font**: CP437/MIK mapping, sprite sheet layout (space at index 0)
- [ ] **FreeType Font**: Face loading, character sizing, kerning, caching (128 entries)
- [ ] **Text Wrapping**: Word wrap with CJK break rules, alignment (left/center/right)
- [ ] **Shadow Rendering**: Offset + color, drawn as separate pass
- [ ] **Font Proxy**: Hot-swap bitmap↔FreeType on language/UI scale change
- [ ] **Cache Invalidation**: `clear_cache()` on graphics context change
- [ ] **Bitmap Matching**: `match_bitmap_font` detects size/color from sprite sheet

### Lua Graphics Class
- [ ] **Palette Caching**: `_loadPalette`/`getPalette` returns cached instances
- [ ] **Greyscale Ghost**: `makeGreyscaleGhost` creates valid 256-byte remap
- [ ] **Raw Bitmap Cache**: `loadRaw` caches by name, reload function captures params
- [ ] **Sprite Sheet Cache**: `loadSpriteTable` caches, handles complex flag
- [ ] **Animation Cache**: `loadAnimations` loads Start/Fra/List/Ele + custom .ca files
- [ ] **Font Loading**: `loadFont`/`loadLanguageFont` chooses bitmap vs FreeType correctly
- [ ] **Cursor Loading**: Standard + SPointer cursors with correct hotspots
- [ ] **Target Update**: `updateTarget` re-executes all reload functions in order

---

## 🟡 High - Should Pass Before Merge

### Object Animations (Lua)
- [ ] **Idle Animation Selection**: Correct animation per direction, mirror fallback
- [ ] **Draw Flags**: `FlipHorizontal` for mirrored, `EarlyList` for footprint.early_list
- [ ] **Split Animations**: Multi-tile `render_attach_position` creates child animations
- [ ] **Crop Columns**: Each split animation gets correct `crop_column`
- [ ] **Animation Sync**: `setAnimation` applies to all split animations with Crop flag
- [ ] **Position Updates**: `setPosition`/`setTile` positions split animations relatively
- [ ] **Tick Sync**: `tick()` advances all split animations (with `num_animation_ticks`)
- [ ] **Slave Objects**: Slave positioning and orientation sync

### Humanoid Animations
- [ ] **Walk/Idle/Door Animations**: Correct indices per humanoid class
- [ ] **Death Animations**: Fall/rise/wings/hands/fly/extra per class
- [ ] **Special Animations**: Vomit, yawn, tap_foot, check_watch, pee, shake_fist
- [ ] **Marker Assignment**: Patient vs staff markers for door/vomit/etc animations
- [ ] **Mood Icons**: Priority system, hover-only icons (cold/hot)

### SDL Backend
- [ ] **Scaling Modes**: `direct_zoom`, target texture, bitmap-only scaling
- [ ] **Intermediate Textures**: `scoped_target_texture` for morph/text quality
- [ ] **Clipping**: Nested `scoped_clip` with rect intersection
- [ ] **Letterboxing**: `apply_letterbox` preserves aspect ratio in fullscreen
- [ ] **Flip Rendering**: `SDL_RenderTextureRotated` with HORIZONTAL/VERTICAL
- [ ] **Alpha Mod**: 50%/75% via `SDL_SetTextureAlphaMod`
- [ ] **Nearest Neighbor**: `SDL_SCALEMODE_NEAREST` when `thdf_nearest` set

### Palette Handling
- [ ] **6-bit → 8-bit Conversion**: Correct rounding for TH palettes
- [ ] **Magenta Transparency**: 0xFF00FF → 0x00000000 in palette constructor
- [ ] **8-bit Palettes**: `.pl8` files loaded with `is8bit=true`
- [ ] **Palette Modification**: `set_entry` updates ARGB map correctly

### Custom Graphics
- [ ] **file_mapping.txt**: Loaded and parsed safely
- [ ] **Custom Animations**: Merged into animation_manager via `loadCustomAnims`
- [ ] **Custom Sprites**: `custom_sheets` in animation_manager used for custom elements

---

## 🟢 Medium - Test If Affected

### Animation Manager Advanced
- [ ] **Layer System**: 13 layers, layer_id filtering, layer 5 W1/B1→W2/B2 hack
- [ ] **Bounding Boxes**: Computed from all visible elements per frame
- [ ] **Frame Extents**: `get_frame_extent` returns correct min/max with flip
- [ ] **Named Animations**: `get_named_animations` returns start frames per direction
- [ ] **Game Ticks**: `tick()` increments for jelly/glowing effect timing

### Sprite Render List
- [ ] **Particle Lifetime**: Decrements, `is_dead()` at 0
- [ ] **Movement**: `dx_per_tick`/`dy_per_tick` applied each tick
- [ ] **Intermediate Buffer**: `use_intermediate_buffer` for scaled text quality
- [ ] **Persistence**: Save/load sprite list state

### FreeType Font Details
- [ ] **Monochrome vs Grayscale**: `is_monochrome()` chooses render mode
- [ ] **Bitmap Strikes**: Prefers embedded bitmaps for small sizes
- [ ] **Pixel Alignment**: `pixel_align` (64-based) for crisp rendering
- [ ] **UTF-8 Parsing**: `next_utf8_codepoint`/`previous_utf8_codepoint` correct
- [ ] **Cache Key**: Includes text, width, alignment, shadow, scale, skip rows

### Graphics Class Edge Cases
- [ ] **Font Fallback**: Unicode font not found → warning, no crash
- [ ] **After Load Fixes**: `loadFont`/`loadLanguageFont` handle old save formats
- [ ] **Arabic Numerals**: `arabicNumerals()` affects Font05V force_bitmap
- [ ] **Weak Cursor Cache**: `cursors` table uses weak keys for GC

---

## 🔵 Low - Regression Tests

### File Format Compatibility
- [ ] **Original TH Files**: All .dat/.tab/.ani/.pal from original game load
- [ ] **Demo vs Full**: `gfx_set` parameter loads correct palette sets
- [ ] **Save Compatibility**: `afterLoad` fixes for graphics in save games

### Performance
- [ ] **Texture Reuse**: No texture leaks (destroyed in destructors)
- [ ] **Cache Limits**: Font cache evicts LRU (128 entries)
- [ ] **Draw Call Batching**: `start_nonoverlapping_draws`/`finish_nonoverlapping_draws`

### Debugging Tools
- [ ] **Sprite Viewer**: `sprite_viewer.lua` displays animations correctly
- [ ] **Animation Viewer**: Marker positions visible in AnimView tool

---

## 📋 Testing Checklist Per Change Type

### If modifying `sprite_sheet`:
- [ ] Load simple sprite sheet (e.g., Font01V)
- [ ] Load complex sprite sheet (e.g., VObjects)
- [ ] Test alt palette map (greyscale ghost)
- [ ] Test hit_test_sprite on transparent/opaque pixels
- [ ] Test draw_sprite with all flag combinations
- [ ] Verify texture destroyed on sheet destruction

### If modifying `animation_manager`:
- [ ] Load original V animations (Data/VStart-1.ani etc.)
- [ ] Load custom .ca animation file
- [ ] Test draw_frame with all 13 layers
- [ ] Test hit_test with/without bound_box_hit_test
- [ ] Test marker set/get with flip
- [ ] Test alt_palette_map propagation to sprites
- [ ] Verify frame loop (get_next_frame wraps)

### If modifying `animation`:
- [ ] Normal animation ticks and loops
- [ ] Child animation follows parent marker
- [ ] Morph animation splits correctly
- [ ] Crop column clips correctly
- [ ] Patient effects (glowing, jelly)
- [ ] Persist/depersist round-trip
- [ ] Sound replacement map works

### If modifying font system:
- [ ] Bitmap font draws CP437 characters
- [ ] FreeType font renders UTF-8 (ASCII + CJK + RTL)
- [ ] Word wrapping at various widths
- [ ] Shadow offset/color
- [ ] Font proxy swap on language change
- [ ] UI scale change updates font size
- [ ] Cache hit/miss behavior

### If modifying `Graphics` (Lua):
- [ ] All cache types populate correctly
- [ ] Reload functions fire on target change
- [ ] Custom graphics folder loads
- [ ] Cursor types all load
- [ ] Font loading for multiple languages
- [ ] Palette loading for all known files

### If modifying SDL backend:
- [ ] All scaling modes work (1x, 2x, fractional)
- [ ] Fullscreen letterboxing
- [ ] Window resize handling
- [ ] Screenshot capture
- [ ] Intermediate texture cleanup per frame
- [ ] Clip rect nesting

---

## 🚨 Release Blockers

**DO NOT RELEASE IF ANY OF THESE FAIL:**

1. **Crash on startup** loading base graphics
2. **Black/missing sprites** in gameplay (patients, objects, UI)
3. **Animation desync** (humanoids sliding, wrong frames)
4. **Font corruption** (missing glyphs, wrong sizes, crashes)
5. **Save/load corruption** of animation state
6. **Memory leaks** in texture/cache management
7. **Custom graphics** break base game
8. **Fullscreen mode** broken on any platform

---

## 📝 Change Documentation Requirements

For any graphics system change, update:
- [ ] `SUMMARY.md` - Architecture documentation
- [ ] `MAP.md` - File:line index
- [ ] Relevant test cases in `SCAFFOLD.lua`
- [ ] CHANGELOG.md entry
- [ ] Git commit message references issue #

---

## ✅ Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Graphics Engineer | | | |
| QA Lead | | | |
| Release Manager | | | |

*Checklist version: 1.0 | Last updated: 2026-08-25*
