# Graphics Methods - File:Line Index

Cross-reference for graphics-related methods across Lua and C++ codebases.

---

## Lua Layer: `/tmp/CorsixTH/CorsixTH/Lua/graphics.lua`

### Graphics Class

| Method | Line | Description |
|--------|------|-------------|
| `Graphics:Graphics` | 68 | Constructor - initializes caches, loads font, palettes, custom graphics |
| `Graphics:_loadPalettes` | 126 | Loads base/demo/full palette sets |
| `Graphics:loadFontFile` | 175 | Finds and loads TTF font file |
| `Graphics:loadMainCursor` | 224 | Loads standard cursor by name |
| `Graphics:loadCursor` | 243 | Creates cursor from sprite sheet + hotspot |
| `Graphics:_loadPalette` | 312 | Loads single palette file, creates ghost remap |
| `Graphics:getPalette` | 340 | Returns cached palette + ghost |
| `Graphics:allPalettes` | 348 | Returns all cached palettes |
| `Graphics:loadGhost` | 352 | Extracts 256-byte ghost remap from ghost file |
| `Graphics:loadRaw` | 372 | Loads raw bitmap (.dat + palette) |
| `Graphics:loadBuiltinFont` | 403 | Creates bitmap_font from embedded data |
| `Graphics:hasLanguageFont` | 428 | Checks if language uses bitmap or TTF |
| `Graphics:onChangeLanguage` | 461 | Hot-swaps fonts on language change |
| `Graphics:onChangeUIScale` | 479 | Updates font scale factors |
| `Graphics:_isLanguageSupportedByTHAssets` | 493 | Checks if charset matches TH assets |
| `Graphics:loadMenuFont` | 498 | Returns font for main menu (TTF or builtin) |
| `Graphics:loadLanguageFont` | 578 | Loads font for language (bitmap or TTF via proxy) |
| `Graphics:_loadTrueTypeFont` | 628 | Creates/caches freetype_font with options |
| `Graphics:loadFontAndSpriteTable` | 687 | Convenience: loads sheet + font together |
| `Graphics:loadFont` | 722 | Core font loading (bitmap vs TTF decision) |
| `Graphics:arabicNumerals` | 763 | Checks if language uses Arabic numerals |
| `Graphics:drawNumbersFromUnicode` | 770 | Whether to draw numbers from Unicode font |
| `Graphics:loadAnimations` | 774 | Loads animation manager from 4 .ani files + custom |
| `Graphics:loadSpriteTable` | 820 | Loads sprite sheet (.tab + .dat) |
| `Graphics:updateTarget` | 846 | Reloads all resources on video target change |

### AnimationManager Class (Lua)

| Method | Line | Description |
|--------|------|-------------|
| `AnimationManager:AnimationManager` | 863 | Constructor - takes C++ anims object |
| `AnimationManager:setAnimLength` | 869 | Overrides cached animation length |
| `AnimationManager:getAnimLength` | 873 | Returns cached or computed frame count |
| `AnimationManager:setPatientMarker` | 938 | Sets primary marker (patients/machines) |
| `AnimationManager:setStaffMarker` | 943 | Sets secondary marker (staff/VIPs) |
| `AnimationManager:_unfoldAnims` | 963 | Recursively handles table of anim numbers |
| `AnimationManager:setMarkerRaw` | 975 | Core marker setting with interpolation |
| `AnimationManager:positionToXy` | 953 | Converts tile/px position to screen coords |

### Helper Functions

| Function | Line | Description |
|----------|------|-------------|
| `makeGreyscaleGhost` | 273 | Creates 256-byte greyscale remap from palette |
| `font_reloader` | 489 | Clears font cache on reload |
| `ttf_col_to_cache_key` | 510 | Serializes TTF color for cache key |
| `shadow_to_cache_key` | 524 | Serializes shadow options for cache key |
| `language_font_cache_key` | 536 | Composite cache key for TTF fonts |

### Data Tables

| Table | Line | Description |
|-------|------|-------------|
| `cursor_data` | 34 | Cursor definitions (id, hotspot x, y) |
| `cursors_palette` | 58 | Palette mapping for SPointer cursors |
| `charsets` | 63 | Charset name -> id mapping (cp437=1, mik=2) |

---

## C++ Headers: `/tmp/CorsixTH/CorsixTH/Src/th_gfx.h`

### Enums & Constants

| Symbol | Line | Description |
|--------|------|-------------|
| `scaled_items` | 45 | {none, sprite_sheets, bitmaps, all} |
| `draw_flags` | 50 | Bitflags for drawing (flip, alpha, palette, crop, etc.) |
| `max_number_of_layers` | 187 | 13 layers |
| `animation_kind` | 508 | {primary_child, secondary_child, normal, morph} |

### Core Structs

| Struct | Line | Fields |
|--------|------|--------|
| `xy_pair` | 95 | x, y (int) |
| `drawable` | 106 | Virtual draw_fn, hit_test_fn, is_multiple_frame_animation_fn, flags, drawing_layer |
| `chunk_renderer` | 141 | Decodes TH chunk format |
| `layers` | 190 | layer_contents[13] (uint8_t) |
| `animation_key` | 195 | name (string), tile_size (int) |
| `animation_start_frames` | 215 | north, east, south, west (long, -1 = none) |
| `animation_manager::frame` | 356 | list_index, next_frame, sound, flags, bounding box, markers |
| `animation_manager::element` | 387 | sprite, flags, x, y, layer, layer_id, element_sprite_sheet |
| `animation_base` | 465 | tile, pixel_offset, layers, scale_factor, flags |
| `animation` | 510 | manager, morph_target, animation_index, frame_index, speed/parent union, sound_to_play, crop_column, anim_kind, patient_effect, patient_effect_offset |
| `sprite_render_list::sprite` | 643 | index, x, y |
| `sprite_render_list` | 611 | sheet, sprites[], dx_per_tick, dy_per_tick, lifetime, use_intermediate_buffer |

### animation_manager Methods

| Method | Line | Description |
|--------|------|-------------|
| `set_sprite_sheet` | 238 | Sets sprite_sheet pointer |
| `load_from_th_file` | 253 | Loads from 4 TH .ani files |
| `set_canvas` | 259 | Sets render_target |
| `load_custom_animations` | 271 | Loads from CTHG format |
| `get_animation_count` | 274 | Returns animation_count |
| `get_frame_count` | 277 | Returns frame_count |
| `get_first_frame` | 280 | Returns first frame index for animation |
| `get_next_frame` | 289 | Returns next frame in sequence |
| `set_animation_alt_palette_map` | 299 | Applies palette remap to animation sprites |
| `draw_frame` | 325 | Draws single frame with layers, effects, scale |
| `get_frame_extent` | 330 | Computes bounding box of frame |
| `get_frame_sound` | 333 | Returns sound ID for frame |
| `hit_test` | 335 | Pixel-perfect hit test |
| `set_frame_primary_marker` | 338 | Sets primary marker for frame |
| `set_frame_secondary_marker` | 339 | Sets secondary marker for frame |
| `get_frame_primary_marker` | 340 | Gets primary marker for frame |
| `get_frame_secondary_marker` | 341 | Gets secondary marker for frame |
| `get_named_animations` | 349 | Returns directional starts for named anim |
| `tick` | 353 | Increments game_ticks |

### animation Methods

| Method | Line | Description |
|--------|------|-------------|
| `remove_from_tile` | 469 | Unlinks from tile entity list |
| `attach_to_tile` | 470 | Links to tile at layer (early/normal list) |
| `set_parent` | 514 | Makes child of another animation |
| `tick` | 516 | Advances frame, updates position, selects sound |
| `draw` | 517 | Draws normal animation |
| `draw_morph` | 518 | Draws morph transition |
| `draw_child` | 519 | Draws at parent marker |
| `draw_fn` | 522 | Virtual draw dispatch |
| `hit_test` | 539 | Hit test normal |
| `hit_test_morph` | 540 | Hit test morph |
| `hit_test_child` | 541 | Hit test child |
| `hit_test_fn` | 543 | Virtual hit_test dispatch |
| `is_multiple_frame_animation_fn` | 556 | Checks if animation has >1 frame |
| `get_previous` | 563 | Returns prev in draw list |
| `get_animation` | 564 | Returns animation_index |
| `get_primary_marker` | 565 | Gets primary marker (with flip + offset) |
| `get_secondary_marker` | 566 | Gets secondary marker |
| `get_frame` | 567 | Returns frame_index |
| `get_crop_column` | 568 | Returns crop_column |
| `set_animation` | 570 | Sets animation_manager + animation_index |
| `set_morph_target` | 571 | Sets morph target with duration |
| `set_frame` | 572 | Sets frame_index directly |
| `set_speed` | 574 | Sets velocity (pixels/tick) |
| `set_crop_column` | 578 | Sets crop column for multi-tile |
| `persist` | 580 | Serializes to save game |
| `depersist` | 581 | Deserializes from save game |
| `set_patient_effect` | 583 | Sets glowing/jelly effect |
| `set_animation_kind` | 584 | Sets normal/child/morph |
| `get_animation_manager` | 587 | Returns manager pointer |

### sprite_render_list Methods

| Method | Line | Description |
|--------|------|-------------|
| `tick` | 613 | Advances position, decrements lifetime |
| `set_sheet` | 615 | Sets sprite_sheet |
| `set_speed` | 616 | Sets velocity |
| `set_lifetime` | 620 | Sets lifetime (-1 = infinite) |
| `set_use_intermediate_buffer` | 621 | Enables offscreen buffer for scaling |
| `append_sprite` | 622 | Adds sprite to list |
| `is_dead` | 623 | Returns lifetime == 0 |
| `persist` | 625 | Serializes |
| `depersist` | 626 | Deserializes |
| `draw` | 628 | Draws all sprites |
| `draw_fn` | 630 | Virtual draw |
| `hit_test` | 634 | Hit tests all sprites |
| `hit_test_fn` | 636 | Virtual hit_test |
| `is_multiple_frame_animation_fn` | 640 | Returns false |

### Lua Binding Helper

| Function | Line | Description |
|----------|------|-------------|
| `luaT_toanimationbase` | 670 | Converts Lua userdata to animation_base* |

---

## C++ Implementation: `/tmp/CorsixTH/CorsixTH/Src/th_gfx.cpp`

### memory_reader Class

| Method | Line | Description |
|--------|------|-------------|
| `memory_reader` | 45 | Constructor (data, length) |
| `are_bytes_available` | 56 | Checks if bytes remain |
| `is_at_end_of_file` | 64 | Checks EOF |
| `read_uint8` | 71 | Reads 1 byte |
| `read_uint16` | 85 | Reads 2 bytes (LE) |
| `read_int16` | 96 | Reads signed 16-bit |
| `read_uint32` | 109 | Reads 4 bytes (LE) |
| `read_string` | 120 | Reads length-prefixed string |

### animation_manager Implementation

| Method | Line | Description |
|--------|------|-------------|
| `set_sprite_sheet` | 143 | Sets sheet pointer |
| `load_from_th_file` | 188 | Parses Start/Fra/List/Ele files |
| `set_bounding_box` | 341 | Computes frame bounds from elements |
| `set_canvas` | 370 | Sets canvas pointer |
| `load_elements` | 396 | Loads custom animation elements |
| `make_list_elements` | 438 | Builds element_list with 0xFFFF terminators |
| `shift_first` | 476 | Adjusts frame indices for custom anims |
| `fix_next_frame` | 486 | Sets start flag + loops last->first |
| `load_custom_animations` | 498 | Parses CTHG blocks (CA/FR/SP) |
| `get_named_animations` | 740 | Looks up named animation by key |
| `get_animation_count` | 755 | Returns count |
| `get_frame_count` | 759 | Returns count |
| `get_first_frame` | 761 | Returns first frame index |
| `get_next_frame` | 769 | Returns next frame index |
| `set_animation_alt_palette_map` | 777 | Applies remap to all sprites in anim |
| `set_frame_primary_marker` | 804 | Sets marker x,y |
| `set_frame_secondary_marker` | 815 | Sets marker x,y |
| `get_frame_primary_marker` | 826 | Gets marker x,y |
| `get_frame_secondary_marker` | 837 | Gets marker x,y |
| `tick` | 848 | Increments game_ticks |
| `hit_test` | 850 | Bounding box + pixel-perfect test |
| `draw_frame` | 919 | Main draw loop with layers/effects |
| `get_frame_sound` | 990 | Returns frame sound |
| `get_frame_extent` | 998 | Computes frame extent |

### chunk_renderer Implementation

| Method | Line | Description |
|--------|------|-------------|
| `chunk_renderer` | 1040 | Constructor |
| `chunk_fill_to_end_of_line` | 1044 | Fills to line end with value |
| `chunk_finish` | 1051 | Fills remaining with value |
| `chunk_fill` | 1055 | Fills n pixels |
| `chunk_copy` | 1063 | Copies n pixels from input |
| `fix_n_pixels` | 1071 | Clamps n to remaining |
| `increment_position` | 1075 | Advances x,y position |
| `decode_chunks` | 1083 | Main decoder (simple/complex) |

### animation_base Implementation

| Method | Line | Description |
|--------|------|-------------|
| `animation_base` | 1143 | Constructor |
| `remove_from_tile` | 1145 | Unlinks from list |
| `attach_to_tile` | 1150 | Inserts into tile entity list (layer sorted) |
| `set_layer` | 1178 | Sets layer_contents[layer] = id |

### animation Implementation

| Method | Line | Description |
|--------|------|-------------|
| `animation` | 1192 | Constructor (random patient_effect_offset) |
| `draw` | 1194 | Draws with crop support |
| `draw_child` | 1220 | Draws at parent marker |
| `hit_test_child` | 1242 | Stub (returns false) |
| `draw_morph` | 1248 | Vertical split draw with clipping |
| `hit_test` | 1285 | Delegates to manager->hit_test |
| `hit_test_morph` | 1299 | Tests both animations |
| `persist` | 1315 | Serializes all fields |
| `depersist` | 1388 | Deserializes all fields |
| `set_patient_effect` | 1489 | Sets effect enum |
| `set_animation_kind` | 1493 | Sets kind enum |
| `tick` | 1567 | Next frame, move, sound selection |
| `set_parent` | 1592 | Links as child animation |
| `set_animation` | 1608 | Sets manager + anim, resets morph |
| `get_primary_marker` | 1619 | Gets marker with flip + offset + 16 |
| `get_secondary_marker` | 1633 | Gets marker with flip + offset + 16 |
| `GetAnimationDurationAndExtent` | 1649 | Helper for morph (computes duration + Y extent) |
| `set_morph_target` | 1678 | Computes morph bounds + speeds |

### frame_sound_replacements Map

| Line | Description |
|------|-------------|
| 1526 | Map of frame_index -> sound_pair for custom sounds |

---

## SDL Backend: `/tmp/CorsixTH/CorsixTH/Src/th_gfx_sdl.cpp`

### Helper Functions

| Function | Line | Description |
|----------|------|-------------|
| `makeGreyScale` | 72 | Luminance conversion (0.2126/0.7152/0.0722) |
| `makeSwapRedBlue` | 93 | Red/blue swap with luminance compensation |
| `convert_6bit_to_8bit_colour_component` | 108 | 6-bit -> 8-bit expansion |
| `intersectRect` | 121 | SDL_Rect intersection |
| `getEnclosingScaleRect` | 147 | Scales SDL_Rect with ceiling |
| `get_scale_rect` | 168 | Scales SDL_FRect with overdraw |
| `apply_letterbox` | 204 | Sets viewport for aspect ratio |

### palette Class

| Method | Line | Description |
|--------|------|-------------|
| `palette` | 253 | Constructor (6-bit or 8-bit data) |
| `set_entry` | 280 | Sets single entry, remaps magenta |
| `get_argb_data` | 290 | Returns array[256] of ARGB |

### full_colour_renderer Class

| Method | Line | Description |
|--------|------|-------------|
| `decode_image` | 295 | Decodes 32bpp sprite format (types 0-3) |

### render_target Class

| Method | Line | Description |
|--------|------|-------------|
| `render_target` | 477 | Constructor (creates window+renderer) |
| `~render_target` | 535 | Destructor |
| `update` | 550 | Updates window size/fullscreen |
| `set_scale_factor` | 573 | Sets scaling mode (direct_zoom/target_textures/bitmaps) |
| `set_caption` | 626 | Sets window title |
| `get_renderer_details` | 630 | Returns SDL renderer name |
| `get_last_error` | 634 | Returns SDL error string |
| `start_frame` | 636 | Clears intermediate textures, fills black |
| `end_frame` | 644 | Draws cursor, blue filter, presents |
| `fill_black` | 663 | Clears to black |
| `fill_colour` | 670 | Clears to color |
| `set_blue_filter_active` | 679 | Toggles blue overlay |
| `set_window_grab` | 684 | Sets mouse grab |
| `fill_rect` | 688 | Draws filled rectangle |
| `push_clip_rect` | 712 | Pushes scaled clip rect |
| `pop_clip_rect` | 728 | Pops clip rect |
| `get_width` | 737 | Returns viewport width |
| `get_height` | 743 | Returns viewport height |
| `get_scaled_width` | 749 | Returns width / draw_scale |
| `get_scaled_height` | 754 | Returns height / draw_scale |
| `start_nonoverlapping_draws` | 759 | No-op hook |
| `finish_nonoverlapping_draws` | 763 | No-op hook |
| `set_cursor` | 767 | Sets game cursor |
| `set_cursor_position` | 769 | Sets cursor position |
| `take_screenshot` | 774 | Captures PNG |
| `should_scale_bitmaps` | 785 | Checks bitmap_scale_factor |
| `convertLegacySprite` | 801 | 8bpp -> 32bpp with recolour layers |
| `create_palettized_texture` | 830 | Creates texture from palette indices |
| `create_texture` | 844 | Creates SDL_Texture from ARGB |
| `draw` | 879 | Draws texture with flip/alpha/scale |
| `draw_line` | 919 | Draws line sequence |
| `begin_intermediate_drawing` | 943 | Creates scoped_target_texture if scaling |
| `draw_scale` | 953 | Returns current scale factor |
| `destroy_intermediate_textures` | 958 | Cleans up frame intermediates |

### render_target::scoped_target_texture

| Method | Line | Description |
|--------|------|-------------|
| `scoped_target_texture` | 415 | Creates render target texture |
| `offset` | 439 | Adjusts rect for texture coords |
| `scale_factor` | 444 | Returns scale if bScale |
| `is_target` | 448 | Checks if texture valid |
| `~scoped_target_texture` | 450 | Commits texture to parent |

### raw_bitmap Class

| Method | Line | Description |
|--------|------|-------------|
| `~raw_bitmap` | 965 | Destroys texture |
| `set_palette` | 971 | Sets palette pointer |
| `load_from_th_file` | 975 | Loads .dat + palette -> texture |
| `draw` | 1059 | Draws full bitmap |
| `draw` | 1063 | Draws sub-rect |

### sprite_sheet Class

| Method | Line | Description |
|--------|------|-------------|
| `~sprite_sheet` | 1079 | Frees all sprites |
| `_freeSingleSprite` | 1081 | Destroys one sprite's textures/data |
| `_freeSprites` | 1098 | Frees all sprites |
| `set_palette` | 1106 | Sets palette pointer |
| `set_sprite_count` | 1110 | Allocates sprite array |
| `load_from_th_file` | 1159 | Loads .tab + .dat, decodes chunks |
| `set_sprite_data` | 1200 | Sets custom sprite data (32bpp) |
| `set_sprite_alt_palette_map` | 1227 | Sets remap for alt palette |
| `get_sprite_count` | 1243 | Returns sprite_count |
| `get_sprite_size` | 1245 | Returns width/height (checked) |
| `get_sprite_size_unchecked` | 1253 | Returns width/height (unchecked) |
| `get_sprite_average_colour` | 1259 | Computes dominant color (for font) |
| `is_sprite_visible` | 1302 | Checks if any non-transparent pixel |
| `draw_sprite` | 1314 | Main draw (lazy texture, effects, flip, scale) |
| `wx_draw_sprite` | 1398 | Draws to wxWidgets buffers |
| `_makeAltBitmap` | 1407 | Creates alt palette texture |

### Helper Functions

| Function | Line | Description |
|----------|------|-------------|
| `testSprite` | 1007 | Validates 32bpp sprite encoding |
| `get32BppPixel` | 1448 | Extracts single pixel from 32bpp data |

---

## Font System: `/tmp/CorsixTH/CorsixTH/Src/th_gfx_font.h` & `.cpp`

### bitmap_font

| Method | Description |
|--------|-------------|
| `setSheet` | Sets sprite_sheet + charset |
| `setSeparation` | Sets x_sep, y_sep |
| `setScaleFactor` | Sets UI scale |
| `sizeOf` | Measures text width/height |
| `draw` | Draws text at position |
| `drawWrapped` | Draws word-wrapped text |
| `drawTooltip` | Draws with tooltip styling |
| `isBitmap` | Returns true |

### freetype_font

| Method | Description |
|--------|-------------|
| `setFace` | Loads TTF face from memory |
| `setFontOptions` | Configures size, color, shadow, scale |
| `draw` | Draws text with caching |
| `drawWrapped` | Draws wrapped text |
| `drawTooltip` | Draws tooltip text |
| `clearCache` | Clears glyph cache |
| `isBitmap` | Returns false |

---

## Cross-Reference: Lua -> C++ Binding

| Lua Call | C++ Method | Binding Location |
|----------|------------|------------------|
| `TH.palette(data, pal8bit)` | `palette::palette` | th_lua.h |
| `TH.bitmap()` | `raw_bitmap` | th_lua.h |
| `TH.sheet()` | `sprite_sheet` | th_lua.h |
| `TH.anims()` | `animation_manager` | th_lua.h |
| `TH.animation()` | `animation` | th_lua.h |
| `TH.spriteList()` | `sprite_render_list` | th_lua.h |
| `TH.bitmap_font()` | `bitmap_font` | th_lua.h |
| `TH.freetype_font()` | `freetype_font` | th_lua.h |
| `TH.cursor()` | `cursor` | th_lua.h |
| `sheet:load(tab, dat, complex, target)` | `sprite_sheet::load_from_th_file` | th_lua.h |
| `sheet:draw_sprite(...)` | `sprite_sheet::draw_sprite` | th_lua.h |
| `anims:load_from_th_file(...)` | `animation_manager::load_from_th_file` | th_lua.h |
| `anims:loadCustom(data)` | `animation_manager::load_custom_animations` | th_lua.h |
| `anims:draw_frame(...)` | `animation_manager::draw_frame` | th_lua.h |
| `anims:hit_test(...)` | `animation_manager::hit_test` | th_lua.h |
| `anims:getFirstFrame(anim)` | `animation_manager::get_first_frame` | th_lua.h |
| `anims:getNextFrame(frame)` | `animation_manager::get_next_frame` | th_lua.h |
| `anims:setAnimationAltPaletteMap(...)` | `animation_manager::set_animation_alt_palette_map` | th_lua.h |
| `anims:setFramePrimaryMarker(...)` | `animation_manager::set_frame_primary_marker` | th_lua.h |
| `anim:set_animation(mgr, anim)` | `animation::set_animation` | th_lua.h |
| `anim:tick()` | `animation::tick` | th_lua.h |
| `anim:draw(canvas, pos)` | `animation::draw` | th_lua.h |
| `anim:set_parent(parent, primary)` | `animation::set_parent` | th_lua.h |
| `anim:set_morph_target(target, dur)` | `animation::set_morph_target` | th_lua.h |
| `anim:set_speed(x, y)` | `animation::set_speed` | th_lua.h |
| `anim:set_crop_column(col)` | `animation::set_crop_column` | th_lua.h |
| `anim:get_primary_marker()` | `animation::get_primary_marker` | th_lua.h |
| `font:draw(canvas, x, y, text)` | `bitmap_font::draw` / `freetype_font::draw` | th_lua.h |
| `font:sizeOf(text)` | `bitmap_font::sizeOf` / `freetype_font::sizeOf` | th_lua.h |
| `cursor:load(sheet, index, hot_x, hot_y)` | `cursor::load` | th_lua.h |

---

## Data File Formats

| Extension | Purpose | Loader |
|-----------|---------|--------|
| `.pal` / `.pl8` | 256-color palette (6-bit or 8-bit) | `Graphics:_loadPalette` |
| `.dat` | Raw pixel data or sprite chunks | `loadRaw`, `sprite_sheet::load_from_th_file` |
| `.tab` | Sprite table (position, width, height) | `sprite_sheet::load_from_th_file` |
| `.ani` | Animation data (Start/Fra/List/Ele) | `animation_manager::load_from_th_file` |
| `.cthg` | Custom animations (CTHG header + CA/FR/SP blocks) | `animation_manager::load_custom_animations` |
| `.ttf` | TrueType font | `Graphics:loadFontFile` |
| `.ghost` | Ghost remap data (256 bytes per frame) | `Graphics:loadGhost` |

---

*Map Version: 1.0 - Generated from CorsixTH source analysis*


## Related Pages

- [[19-animation-graphics/SUMMARY]]
- [[19-animation-graphics/CHECKLIST]]
- [[19-animation-graphics/SCAFFOLD]]
