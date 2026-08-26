# CorsixTH Graphics System - File:Line Index

Cross-reference map for all graphics-related methods across Lua and C++.

---

## Lua Files

### `/tmp/CorsixTH/CorsixTH/Lua/graphics.lua` (1065 lines)

#### Graphics Class Constructor & Setup
| Line | Method | Description |
|------|--------|-------------|
| 68 | `Graphics:Graphics(app, gfx_set, charset)` | Constructor - initializes caches, loads font/palettes |
| 126 | `Graphics:_loadPalettes(gfx_set)` | Loads base/demo/full palette sets |
| 175 | `Graphics:loadFontFile()` | Loads Unicode TTF font from config/path |
| 224 | `Graphics:loadMainCursor(name)` | Loads standard cursor by name |
| 243 | `Graphics:loadCursor(sheet, index, hot_x, hot_y)` | Creates cursor from sprite sheet |
| 273 | `makeGreyscaleGhost(pal)` | Local: creates 256-byte greyscale remap |
| 312 | `Graphics:_loadPalette(dir, name, transparent_255, pal8bit)` | Loads palette file, creates ghost remap |
| 340 | `Graphics:getPalette(name)` | Returns cached palette + ghost |
| 348 | `Graphics:allPalettes()` | Returns all cached palettes |
| 352 | `Graphics:loadGhost(dir, name, index)` | Loads 256-byte ghost palette segment |
| 372 | `Graphics:loadRaw(name, width, height, dir, paldir, pal, transparent_255, flags)` | Loads raw bitmap (.dat + palette) |
| 403 | `Graphics:loadBuiltinFont()` | Loads built-in CP437 bitmap font |
| 428 | `Graphics:hasLanguageFont(font)` | Checks if language uses bitmap font |
| 461 | `Graphics:onChangeLanguage()` | Hot-swaps fonts on language change |
| 479 | `Graphics:onChangeUIScale()` | Updates font scale factors |
| 489 | `font_reloader(font)` | Local: clears FreeType font cache |
| 493 | `Graphics:_isLanguageSupportedByTHAssets()` | Checks if charset matches TH assets |
| 498 | `Graphics:loadMenuFont()` | Loads main menu font (unicode or builtin) |
| 510 | `ttf_col_to_cache_key(ttf_color)` | Local: cache key for font color |
| 524 | `shadow_to_cache_key(ttf_shadow)` | Local: cache key for shadow options |
| 536 | `language_font_cache_key(name, font_options)` | Local: composite font cache key |
| 547 | `Graphics:_loadTrueTypeFont(name, sprite_table, font_options)` | Creates/caches FreeType font |
| 657 | `Graphics:loadFontAndSpriteTable(dir, name, complex, palette, font_options)` | Combined font + sheet load |
| 698 | `Graphics:loadFont(sprite_table, font_options, y_sep, ttf_color, force_bitmap)` | Loads bitmap or FreeType font |
| 763 | `Graphics:arabicNumerals()` | Checks if language uses Arabic numerals |
| 770 | `Graphics:drawNumbersFromUnicode()` | Whether to draw numbers from Unicode font |
| 774 | `Graphics:loadAnimations(dir, prefix)` | Loads animation manager + custom animations |
| 820 | `Graphics:loadSpriteTable(dir, name, complex, palette)` | Loads/caches sprite sheet |
| 846 | `Graphics:updateTarget(target)` | Re-executes all reload functions |

#### AnimationManager Class (Lua wrapper)
| Line | Method | Description |
|------|--------|-------------|
| 863 | `AnimationManager:AnimationManager(anims)` | Constructor |
| 869 | `AnimationManager:setAnimLength(anim, length)` | Override animation length |
| 873 | `AnimationManager:getAnimLength(anim)` | Computes/caches animation frame count |
| 938 | `AnimationManager:setPatientMarker(anim, ...)` | Sets primary marker (flexible args) |
| 943 | `AnimationManager:setStaffMarker(anim, ...)` | Sets secondary marker (flexible args) |
| 953 | `positionToXy(pos)` | Local: converts tile/px position to screen px |
| 963 | `AnimationManager:_unfoldAnims(anim, fn, ...)` | Recurses table of animation numbers |
| 975 | `AnimationManager:setMarkerRaw(anim, fn, arg1, arg2, ...)` | Core marker setting logic |
| 1059 | `Graphics:loadPalette(_, name)` | Legacy compatibility for UI palette loading |

---

### `/tmp/CorsixTH/CorsixTH/Lua/entities/object.lua` (1105 lines)

#### Object Animation Handling
| Line | Method | Description |
|------|--------|-------------|
| 39 | `Object:Object(hospital, object_type, x, y, direction, etc)` | Constructor - creates TH.animation() |
| 64 | `Object:initOrientation(direction)` | Sets up animation, flags, split animations |
| 112 | `Object.slaveMixinClass(class_method_table)` | Adds slave object support |
| 189 | `Object:tick()` | Advances split animations |
| 207 | `Object:setPosition(x, y)` | Positions primary + split animations |
| 223 | `Object:setAnimation(animation, flags)` | Applies animation to all split anims |
| 249 | `Object:getRenderAttachTile()` | Returns primary render tile coords |
| 395 | `Object:setTile(x, y)` | Attaches/detaches animations to map tiles |
| 417 | `Object:setTile` (split anims) | Attaches split animations to tiles |
| 609 | `Object:setInvisible(invisible)` | Hides/shows all split animations |
| 831 | `Object:resetAnimation()` | Resets tile attachment |
| 912 | `Object:afterLoad(old, new)` | Fixes orientation/position on load |
| 1026 | `Object.processTypeDefinition(object_type)` | Computes footprint, render positions, crop columns |

#### SideObject
| Line | Method | Description |
|------|--------|-------------|
| 1084 | `SideObject:getDrawingLayer()` | Returns layer based on direction |

---

### `/tmp/CorsixTH/CorsixTH/Lua/entities/humanoid.lua` (1258 lines)

#### Humanoid Animation Data
| Line | Method | Description |
|------|--------|-------------|
| 27 | `walk_animations` | Permanent table: walk/idle per class |
| 28 | `door_animations` | Permanent table: door enter/leave/knock/swing |
| 29 | `die_animations` | Permanent table: fall/rise/wings/hands/fly/extra |
| 30 | `falling_animations` | Permanent table: falling anim per class |
| 31 | `on_ground_animations` | Permanent table: lying down anim |
| 32 | `get_up_animations` | Permanent table: getting up anim |
| 33 | `shake_fist_animations` | Permanent table: shake fist anim |
| 34 | `vomit_animations` | Permanent table: vomit anim |
| 35 | `tap_foot_animations` | Permanent table: tap foot anim |
| 36 | `yawn_animations` | Permanent table: yawn anim |
| 37 | `check_watch_animations` | Permanent table: check watch anim |
| 38 | `pee_animations` | Permanent table: pee anim |
| 40 | `mood_icons` | Permanent table: mood icon definitions |
| 42 | `walk_anims(name, ...)` | Local: registers walk animations |
| 69 | `die_anims(name, ...)` | Local: registers death animations |
| 80 | `falling_anim(name, anim)` | Local: registers falling anim |
| 83 | `on_ground_anim(name, anim)` | Local: registers on-ground anim |
| 86 | `get_up_anim(name, anim)` | Local: registers get-up anim |
| 89 | `shake_fist_anim(name, anim)` | Local: registers shake fist |
| 92 | `vomit_anim(name, anim)` | Local: registers vomit anim |
| 95 | `yawn_anim(name, anim)` | Local: registers yawn anim |
| 98 | `tap_foot_anim(name, anim)` | Local: registers tap foot |
| 101 | `check_watch_anim(name, anim)` | Local: registers check watch |
| 104 | `pee_anim(name, anim)` | Local: registers pee anim |
| 107 | `moods(name, icon, prio, hover)` | Local: registers mood icon |
| 112 | `assignPatientMarkers(anims, name, ...)` | Sets patient markers for anim table |
| 124 | `assignStaffMarkers(anims, name, ...)` | Sets staff markers for anim table |

#### Animation Data Definitions (lines 139-336)
- Walk animations: lines 139-166
- Door markers: lines 169-191
- Death animations: lines 193-208
- Falling/On-ground/Get-up: lines 210-231
- Shake fist: lines 233-238
- Vomit: lines 240-253
- Yawn: lines 255-263
- Tap foot: lines 265-272
- Check watch: lines 274-282
- Pee: lines 284-298
- Mood icons: lines 300-336

#### Humanoid Methods
| Line | Method | Description |
|------|--------|-------------|
| 339 | `Humanoid:Humanoid(...)` | Constructor |
| 361 | `Humanoid:afterLoad(old, new)` | Save compatibility fixes |
| 525 | `Humanoid.getIdleAnimation(humanoid_class)` | Returns idle_east anim index |
| 813 | `Humanoid:setType(humanoid_class)` | Sets animation tables + flags |
| 842 | `Humanoid:isType(humanoid_class)` | Checks humanoid class |

---

## C++ Header Files

### `/tmp/CorsixTH/CorsixTH/Src/th_gfx.h` (675 lines)

#### Enums & Constants
| Line | Symbol | Description |
|------|--------|-------------|
| 45 | `enum class scaled_items` | none, sprite_sheets, bitmaps, all |
| 50 | `enum draw_flags` | thdf_flip_horizontal (1), flip_vertical (2), alpha_50 (4), alpha_75 (8), alt_palette (16), alt32_* (32/64/96), early_list (1024), bound_box_hit_test (4096), crop (8192), nearest (16384) |
| 95 | `struct xy_pair` | int x, y |
| 106 | `struct drawable : link_list` | Base for drawable objects |
| 141 | `class chunk_renderer` | Decodes TH chunked graphics |
| 187 | `const int max_number_of_layers = 13` | Animation layer count |
| 190 | `struct layers` | uint8_t layer_contents[13] |
| 195 | `struct animation_key` | name + tile_size for custom anims |
| 215 | `struct animation_start_frames` | N/E/S/W start frame indices |
| 228 | `class animation_manager` | Core animation system |

#### animation_manager Methods
| Line | Method | Description |
|------|--------|-------------|
| 238 | `set_sprite_sheet(sprite_sheet*)` | Sets sprite sheet reference |
| 253 | `load_from_th_file(start, fra, list, ele)` | Loads original TH animations |
| 263 | `set_canvas(render_target*)` | Sets render target |
| 271 | `load_custom_animations(data, len)` | Loads CTHG custom animations |
| 274 | `get_animation_count()` | Returns animation count |
| 277 | `get_frame_count()` | Returns frame count |
| 280 | `get_first_frame(anim)` | Returns first frame index |
| 289 | `get_next_frame(frame)` | Returns next frame in loop |
| 299 | `set_animation_alt_palette_map(anim, map, alt32)` | Sets palette remap for animation |
| 325 | `draw_frame(canvas, frame, layers, x, y, flags, effect, offset, scale)` | Draws animation frame |
| 330 | `get_frame_extent(frame, layers, minx, maxx, miny, maxy, flags)` | Computes frame bounds |
| 333 | `get_frame_sound(frame)` | Returns sound ID for frame |
| 335 | `hit_test(frame, layers, x, y, flags, test_x, test_y)` | Pixel-perfect hit test |
| 338 | `set_frame_primary_marker(frame, x, y)` | Sets primary marker |
| 339 | `set_frame_secondary_marker(frame, x, y)` | Sets secondary marker |
| 340 | `get_frame_primary_marker(frame, x, y)` | Gets primary marker |
| 341 | `get_frame_secondary_marker(frame, x, y)` | Gets secondary marker |
| 349 | `get_named_animations(name, tilesize)` | Returns custom anim start frames |
| 353 | `tick()` | Increments game_ticks |

#### animation_base / animation / sprite_render_list
| Line | Class/Method | Description |
|------|--------------|-------------|
| 465 | `class animation_base : drawable` | Base with tile attachment |
| 510 | `class animation : animation_base` | Full animation instance |
| 514 | `set_parent(parent, use_primary)` | Makes child animation |
| 516 | `tick()` | Advances frame, moves by speed |
| 517 | `draw(canvas, pos)` | Normal draw |
| 518 | `draw_morph(canvas, pos)` | Morph draw (vertical split) |
| 519 | `draw_child(canvas, pos, primary)` | Child draw at parent marker |
| 539 | `hit_test(...)` | Hit test dispatch |
| 556 | `is_multiple_frame_animation_fn()` | Checks if anim has >1 frame |
| 570 | `set_animation(mgr, anim)` | Initializes with manager + index |
| 571 | `set_morph_target(target, duration)` | Sets up morph parameters |
| 572 | `set_frame(frame)` | Sets current frame |
| 574 | `set_speed(x, y)` | Sets movement speed |
| 578 | `set_crop_column(col)` | Sets crop column for split anim |
| 580 | `persist(writer)` | Serializes animation state |
| 581 | `depersist(reader)` | Deserializes animation state |
| 583 | `set_patient_effect(effect)` | Sets glowing/jelly/none |
| 584 | `set_animation_kind(kind)` | Sets normal/child/morph |
| 587 | `get_animation_manager()` | Returns manager pointer |
| 611 | `class sprite_render_list : animation_base` | Lightweight sprite sequence |
| 615 | `set_sheet(sheet)` | Sets sprite sheet |
| 616 | `set_speed(x, y)` | Sets velocity |
| 620 | `set_lifetime(ticks)` | Sets expiry (-1 = infinite) |
| 621 | `set_use_intermediate_buffer()` | For scaled text quality |
| 622 | `append_sprite(idx, x, y)` | Adds sprite to list |
| 623 | `is_dead()` | Checks lifetime == 0 |
| 628 | `draw(canvas, pos)` | Renders all sprites |
| 634 | `hit_test(...)` | Tests all sprites |

---

### `/tmp/CorsixTH/CorsixTH/Src/th_gfx_font.h` (370 lines)

#### Font System
| Line | Symbol | Description |
|------|--------|-------------|
| 38 | `enum text_alignment` | left=0, center=1, right=2 |
| 44 | `enum bitmap_font_character_set` | cp437, mik |
| 47 | `struct text_layout` | row_count, start_x, end_x, start_y, end_y, width |
| 67 | `struct font_shadow_options` | enabled, offset_x, offset_y, color |
| 81 | `class font` | Abstract base interface |
| 96 | `get_text_dimensions(msg, len, max_width)` | Measures text |
| 112 | `draw_text(canvas, msg, len, x, y)` | Draws single line |
| 133 | `draw_text_wrapped(...)` | Draws with word wrap |
| 139 | `class bitmap_font : font` | Bitmap font implementation |
| 152 | `set_sprite_sheet(sheet, charset)` | Sets glyph sheet + charset |
| 155 | `set_scale_factor(factor)` | Sets UI scale multiplier |
| 159 | `set_separation(char, line)` | Sets spacing |
| 166 | `get_text_dimensions` | Override |
| 169 | `draw_text` | Override |
| 172 | `draw_text_wrapped` | Override |
| 198 | `class freetype_font : font` | FreeType font implementation |
| 209 | `get_copyright_notice()` | FreeType license text |
| 215 | `initialise()` | Initializes FreeType library |
| 218 | `clear_cache()` | Invalidates all cached text |
| 227 | `set_face(data, len)` | Loads TTF from memory |
| 240 | `match_bitmap_font(sheet, color, w, h)` | Detects size/color from bitmap font |
| 249 | `set_ideal_character_size(w, h)` | Sets pixel size |
| 251 | `set_font_color(color)` | Sets ARGB color |
| 253 | `set_shadow_options(options)` | Configures shadow |
| 255 | `get_text_dimensions` | Override |
| 258 | `draw_text` | Override |
| 261 | `draw_text_wrapped` | Override |
| 330 | `is_monochrome()` | Engine-specific: mono vs gray |
| 341 | `make_texture(canvas, cache_entry)` | Engine-specific: cache→texture |
| 344 | `copy_pixel_data(...)` | Engine-specific: colorize |
| 355 | `free_texture(cache_entry)` | Engine-specific: destroy texture |
| 366 | `draw_texture(canvas, cache_entry, x, y)` | Engine-specific: render texture |

---

### `/tmp/CorsixTH/CorsixTH/Src/th_gfx_common.h` (39 lines)

| Line | Symbol | Description |
|------|--------|-------------|
| 30 | `enum class animation_effect` | none, glowing, jelly |

---

## C++ Implementation Files

### `/tmp/CorsixTH/CorsixTH/Src/th_gfx.cpp` (2000+ lines)

#### memory_reader (lines 43-141)
| Line | Method | Description |
|------|--------|-------------|
| 45 | `memory_reader(data, len)` | Constructor |
| 56 | `are_bytes_available(size)` | Checks remaining bytes |
| 64 | `is_at_end_of_file()` | Checks EOF |
| 71 | `read_uint8()` | Reads 1 byte |
| 85 | `read_uint16()` | Reads 2 bytes LE |
| 96 | `read_int16()` | Reads signed 16-bit |
| 109 | `read_uint32()` | Reads 4 bytes LE |
| 120 | `read_string(str)` | Reads length-prefixed string |

#### animation_manager
| Line | Method | Description |
|------|--------|-------------|
| 143 | `set_sprite_sheet` | Sets sheet pointer |
| 188 | `load_from_th_file` | Loads Start/Fra/List/Ele |
| 319 | `set_left_to_min/max` | Local helpers for bbox |
| 341 | `set_bounding_box(frame)` | Computes frame bbox from elements |
| 370 | `set_canvas` | Sets canvas pointer |
| 379 | `load_header` | Local: validates CTHG header |
| 396 | `load_elements` | Loads custom animation elements |
| 438 | `make_list_elements` | Creates element list with 0xFFFF terminator |
| 476 | `shift_first` | Local: adjusts frame indices for custom anims |
| 486 | `fix_next_frame` | Sets start flag + loops last→first |
| 498 | `load_custom_animations` | Parses CTHG blocks (CA/FR/SP) |
| 740 | `get_named_animations` | Looks up custom anim by name+tilesize |
| 755 | `get_animation_count` | Returns count |
| 759 | `get_frame_count` | Returns count |
| 761 | `get_first_frame` | Returns first frame index |
| 769 | `get_next_frame` | Returns next frame (loops) |
| 777 | `set_animation_alt_palette_map` | Applies remap to all anim sprites |
| 804 | `set_frame_primary_marker` | Sets primary marker coords |
| 815 | `set_frame_secondary_marker` | Sets secondary marker coords |
| 826 | `get_frame_primary_marker` | Gets primary marker |
| 837 | `get_frame_secondary_marker` | Gets secondary marker |
| 848 | `tick` | Increments game_ticks |
| 850 | `hit_test` | Bounding box + pixel-perfect test |
| 919 | `draw_frame` | Main draw loop with layers/flip/effects |
| 990 | `get_frame_sound` | Returns frame sound ID |
| 998 | `get_frame_extent` | Computes min/max x/y for frame |

#### chunk_renderer
| Line | Method | Description |
|------|--------|-------------|
| 1040 | `chunk_renderer(w, h, start)` | Constructor |
| 1044 | `chunk_fill_to_end_of_line` | Fills rest of scanline |
| 1051 | `chunk_finish` | Fills rest of image |
| 1055 | `chunk_fill(n, val)` | Fills N pixels with value |
| 1063 | `chunk_copy(n, data)` | Copies N literal pixels |
| 1071 | `fix_n_pixels` | Clamps to image bounds |
| 1075 | `increment_position` | Advances x/y, handles line wrap |
| 1083 | `decode_chunks(data, len, complex)` | Main decode loop (simple/complex) |

#### animation_base
| Line | Method | Description |
|------|--------|-------------|
| 1143 | `animation_base()` | Constructor |
| 1145 | `remove_from_tile()` | Unlinks from tile list |
| 1150 | `attach_to_tile(tile, node, layer)` | Inserts into tile entity list (early/normal) |
| 1178 | `set_layer(layer, id)` | Sets layer_contents[layer] = id |

#### animation
| Line | Method | Description |
|------|--------|-------------|
| 1192 | `animation()` | Constructor (random effect offset) |
| 1194 | `draw(canvas, pos)` | Normal draw with crop support |
| 1220 | `draw_child(canvas, pos, primary)` | Draws at parent marker |
| 1248 | `draw_morph(canvas, pos)` | Vertical split morph draw |
| 1285 | `hit_test(draw_pos, obj_pos)` | Delegates to manager |
| 1299 | `hit_test_morph(...)` | Tests both animations |
| 1315 | `persist(writer)` | Full state serialization |
| 1388 | `depersist(reader)` | Full state deserialization |
| 1489 | `set_patient_effect(effect)` | Sets effect enum |
| 1493 | `set_animation_kind(kind)` | Sets kind enum |
| 1567 | `tick()` | Frame advance + movement + sound |
| 1608 | `set_animation(mgr, anim)` | Init with manager + first frame |
| 1619 | `get_primary_marker(x, y)` | Gets marker + flip adjust |
| 1633 | `get_secondary_marker(x, y)` | Gets marker + flip adjust |

#### Animation Helpers
| Line | Function | Description |
|------|----------|-------------|
| 1649 | `GetAnimationDurationAndExtent` | Computes duration + Y extent for morph |
| 1678 | `animation::set_morph_target` | Sets up morph parameters from extent |

---

### `/tmp/CorsixTH/CorsixTH/Src/th_gfx_sdl.cpp` (1737 lines)

#### Render Target & SDL Integration
| Line | Method | Description |
|------|--------|-------------|
| 51 | `full_colour_renderer(w, h)` | Base for 32bpp decode |
| 295 | `decode_image(pixels, palette, flags)` | Decodes 32bpp RLE to ARGB |
| 415 | `scoped_target_texture` | RAII offscreen render target |
| 477 | `render_target(params)` | Creates SDL window+renderer |
| 535 | `~render_target()` | Cleanup |
| 550 | `update(params)` | Resize/fullscreen toggle |
| 573 | `set_scale_factor(scale, what)` | Sets global/target/bitmap scaling |
| 626 | `set_caption(title)` | Window title |
| 630 | `get_renderer_details()` | Renderer name |
| 636 | `start_frame()` | Clears + destroys intermediates |
| 644 | `end_frame()` | Draws cursor + filter + present |
| 663 | `fill_black()` | Clear to black |
| 670 | `fill_colour(colour)` | Clear to color |
| 683 | `set_window_grab(grab)` | Mouse capture |
| 688 | `fill_rect(colour, x, y, w, h)` | Draws filled rect |
| 704 | `scoped_clip` | RAII clip rect |
| 712 | `push_clip_rect(rect)` | Pushes scaled clip |
| 728 | `pop_clip_rect()` | Pops clip |
| 737 | `get_width()` | Viewport width |
| 743 | `get_height()` | Viewport height |
| 749 | `get_scaled_width()` | Width / draw_scale |
| 754 | `get_scaled_height()` | Height / draw_scale |
| 759 | `start_nonoverlapping_draws()` | No-op (SDL) |
| 763 | `finish_nonoverlapping_draws()` | No-op (SDL) |
| 767 | `set_cursor(cursor)` | Sets game cursor |
| 769 | `set_cursor_position(x, y)` | Updates cursor pos |
| 774 | `take_screenshot(path)` | Saves PNG |
| 785 | `should_scale_bitmaps(factor)` | Returns bitmap_scale_factor |
| 793 | `convertLegacySprite` | Local: 8bpp→32bpp recolour blocks |
| 830 | `create_palettized_texture` | 8bpp→texture via full_colour_storing |
| 844 | `create_texture` | 32bpp pixels→SDL_Texture |
| 879 | `draw(texture, src, dst, flags)` | Render with flip/alpha/scale |

#### Palette
| Line | Method | Description |
|------|--------|-------------|
| 253 | `palette(data, len, is8bit)` | Constructor (6/8-bit conversion) |
| 280 | `set_entry(idx, r, g, b)` | Modifies entry |
| 290 | `get_argb_data()` | Returns ARGB array |

#### raw_bitmap
| Line | Method | Description |
|------|--------|-------------|
| 965 | `~raw_bitmap()` | Destroys texture |
| 971 | `set_palette(palette)` | Sets palette ref |
| 975 | `load_from_th_file(pixels, len, w, canvas, flags)` | Loads .dat → texture |
| 1059 | `draw(canvas, x, y)` | Full draw |
| 1063 | `draw(canvas, x, y, src_x, src_y, w, h)` | Partial draw |

#### sprite_sheet
| Line | Method | Description |
|------|--------|-------------|
| 1079 | `~sprite_sheet()` | Frees all sprites |
| 1081 | `_freeSingleSprite(idx)` | Destroys one sprite's textures/data |
| 1098 | `_freeSprites()` | Frees all |
| 1106 | `set_palette(palette)` | Sets palette ref |
| 1110 | `set_sprite_count(count, canvas)` | Allocates sprite array |
| 1159 | `load_from_th_file(tab, tab_len, chunk, chunk_len, complex, canvas)` | Loads .tab+.dat |
| 1200 | `set_sprite_data(idx, data, take, len, w, h)` | Sets custom sprite |
| 1227 | `set_sprite_alt_palette_map(idx, map, alt32)` | Sets remap, invalidates alt_texture |
| 1243 | `get_sprite_count()` | Returns count |
| 1245 | `get_sprite_size(idx, w, h)` | Bounds-checked size |
| 1253 | `get_sprite_size_unchecked(idx, w, h)` | Unchecked size |
| 1259 | `get_sprite_average_colour(idx, colour)` | For font matching |
| 1302 | `is_sprite_visible(idx)` | Checks non-transparent pixels |
| 1314 | `draw_sprite(canvas, idx, x, y, flags, ticks, effect, scale)` | Main draw with effects |
| 1397 | `wx_draw_sprite(idx, rgb, alpha)` | wxWidgets export |
| 1407 | `_makeAltBitmap(sprite)` | Creates alt palette texture |
| 1438 | `get32BppPixel` | Local: extracts pixel from RLE |
| 1535 | `hit_test_sprite(idx, x, y, flags)` | Pixel-perfect hit test |

#### cursor
| Line | Method | Description |
|------|--------|-------------|
| 1551 | `~cursor()` | Destroys SDL cursor/surface |
| 1556 | `create_from_sprite(sheet, idx, hx, hy)` | Disabled (returns false) |
| 1575 | `use(target)` | Disabled |
| 1586 | `set_position(target, x, y)` | Disabled |
| 1595 | `draw(canvas, x, y)` | Disabled |

#### line_sequence
| Line | Method | Description |
|------|--------|-------------|
| 1604 | `line_sequence()` | Constructor |
| 1606 | `move_to(x, y)` | Starts new line |
| 1610 | `line_to(x, y)` | Adds line segment |
| 1614 | `set_width(w)` | Line thickness |
| 1616 | `set_colour(r,g,b,a)` | Line color |
| 1623 | `draw(canvas, x, y)` | Renders via render_target |
| 1627 | `persist(writer)` | Serializes |
| 1644 | `depersist(reader)` | Deserializes |

#### freetype_font (SDL implementation)
| Line | Method | Description |
|------|--------|-------------|
| 1675 | `is_monochrome()` | Returns false (uses grayscale) |
| 1677 | `free_texture(entry)` | Destroys SDL_Texture |
| 1684 | `make_texture(canvas, entry)` | Creates texture from cached pixels |
| 1708 | `copy_pixel_data(entry, color, ox, oy, out)` | Applies color+shadow to pixels |
| 1729 | `draw_texture(canvas, entry, x, y)` | Renders cached texture |

---

### `/tmp/CorsixTH/CorsixTH/Src/th_gfx_font.cpp` (802 lines)

#### bitmap_font
| Line | Method | Description |
|------|--------|-------------|
| 61 | `bitmap_font()` | Constructor |
| 63 | `set_sprite_sheet(sheet, charset)` | Stores sheet + charset |
| 69 | `set_separation(char, line)` | Stores spacing |
| 74 | `set_scale_factor(factor)` | Stores scale |
| 76 | `get_text_dimensions` | Delegates to draw_text_wrapped |
| 83 | `draw_text(canvas, msg, len, x, y)` | Draws each glyph via sheet |
| 116 | `draw_text_wrapped(...)` | Word wrap with alignment |

#### freetype_font
| Line | Method | Description |
|------|--------|-------------|
| 220 | `freetype_font()` | Initializes cache array |
| 240 | `~freetype_font()` | Cleans up cache + face + FT lib |
| 256 | `get_copyright_notice()` | Returns license string |
| 261 | `initialise()` | FT_Init_FreeType (refcounted) |
| 272 | `clear_cache()` | Invalidates all entries |
| 280 | `set_face(data, len)` | FT_New_Memory_Face |
| 296 | `match_bitmap_font(sheet, color, w, h)` | Samples 'M'/'0' or averages |
| 334 | `set_ideal_character_size(w, h)` | Bitmap strike or FT_Set_Pixel_Sizes |
| 371 | `set_font_color(color)` | Stores ARGB |
| 373 | `set_shadow_options(opts)` | Stores shadow config |
| 377 | `get_text_dimensions` | Delegates to draw_text_wrapped |
| 384 | `draw_text` | Delegates to draw_text_wrapped |
| 423 | `draw_text_wrapped(...)` | Full layout + cache + render pipeline |
| 749 | `render_mono(entry, bitmap, x, y)` | Renders 1bpp glyph to cache |
| 778 | `render_gray(entry, bitmap, x, y)` | Renders 8bpp glyph (alpha blend) |

#### Helpers
| Line | Function | Description |
|------|----------|-------------|
| 47 | `unicode_to_font_character(codepoint, charset)` | CP437/MIK mapping |
| 399 | `isCjkBreakCharacter(codepoint)` | CJK line break rules |
| 419 | `pixel_align(pos)` | Aligns to 64 (26.6 fixed point) |

---

## Lua ↔ C++ Binding Map (th_lua_gfx.cpp)

| Lua Class | C++ Class | Binding Lines |
|-----------|-----------|---------------|
| `palette` | `palette` | th_lua_gfx.cpp |
| `sheet` / `sprite_sheet` | `sprite_sheet` | th_lua_gfx.cpp |
| `raw_bitmap` / `bitmap` | `raw_bitmap` | th_lua_gfx.cpp |
| `anims` / `animation_manager` | `animation_manager` | th_lua_gfx.cpp |
| `animation` | `animation` | th_lua_gfx.cpp |
| `spriteList` / `sprite_render_list` | `sprite_render_list` | th_lua_gfx.cpp |
| `font` | `font` | th_lua_gfx.cpp:1132 |
| `bitmap_font` | `bitmap_font` | th_lua_gfx.cpp:1145 |
| `freetype_font` | `freetype_font` | th_lua_gfx.cpp:1158 |

---

## Key Data Flow

```
Lua Graphics Class
    ├── loadRaw() → TH.bitmap() → raw_bitmap::load_from_th_file()
    ├── loadSpriteTable() → TH.sheet() → sprite_sheet::load_from_th_file()
    ├── loadAnimations() → TH.anims() → animation_manager::load_from_th_file()
    │       └→ loadCustomAnims() → animation_manager::load_custom_animations()
    ├── loadFont() → TH.bitmap_font() / TH.freetype_font()
    │       bitmap_font::set_sprite_sheet()
    │       freetype_font::set_face() + set_ideal_character_size()
    └── loadCursor() → TH.cursor()

Animation Manager
    ├── draw_frame() → sprite_sheet::draw_sprite() → render_target::draw()
    ├── hit_test() → sprite_sheet::hit_test_sprite()
    └── set_animation_alt_palette_map() → sprite_sheet::set_sprite_alt_palette_map()

Animation Instance
    ├── tick() → animation_manager::get_next_frame()
    ├── draw() → animation_manager::draw_frame()
    ├── set_morph_target() → GetAnimationDurationAndExtent()
    └── persist/depersist → lua_persist_writer/reader
```

---

## File Quick Reference

| File | Purpose | Key Classes |
|------|---------|-------------|
| `Lua/graphics.lua` | High-level resource cache & loading | Graphics, AnimationManager |
| `Lua/entities/object.lua` | Object animations + split anims | Object, SideObject |
| `Lua/entities/humanoid.lua` | Humanoid animation data + markers | Humanoid |
| `Src/th_gfx.h` | Core graphics C++ API | animation_manager, animation, sprite_render_list, drawable |
| `Src/th_gfx.cpp` | Core graphics implementation | All above + chunk_renderer |
| `Src/th_gfx_sdl.cpp` | SDL3 backend | render_target, palette, raw_bitmap, sprite_sheet, cursor, freetype_font (SDL) |
| `Src/th_gfx_font.h/cpp` | Font system | font, bitmap_font, freetype_font |
| `Src/th_gfx_common.h` | Shared enums | animation_effect |
| `Src/th_lua_gfx.cpp` | Lua ↔ C++ bindings | All userdata classes |


## Related Pages

- [[CHECKLIST]]
- [[SUMMARY]]
