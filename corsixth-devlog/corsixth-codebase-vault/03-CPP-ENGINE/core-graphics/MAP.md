# Core Graphics — File:Line Index

> Prefix: `CorsixTH/Src/`. Verified via `ssh vps "sed -n ...p"`.

## th_gfx.h (675 lines)

| Lines | Symbol |
|-------|--------|
| 45 | `enum class scaled_items` |
| 47 | `clip_rect_intersection` |
| 50–93 | `enum draw_flags` (flip/alpha/alt_palette/alt32/early/crop/nearest) |
| 95–98 | `struct xy_pair` |
| 106–139 | `struct drawable : link_list` |
| 141–187 | `class chunk_renderer` |
| 190–193 | `struct layers` (13 entries) |
| 195–213 | `struct animation_key` + `operator<` |
| 215–222 | `struct animation_start_frames` |
| 234–463 | `class animation_manager` |
| 465–507 | `class animation_base` |
| 508 | `enum class animation_kind` |
| 510–609 | `class animation` |
| 611–665 | `class sprite_render_list` |
| 660–670 | `luaT_toanimationbase` |

## th_gfx_common.h (39 lines)

| Lines | Symbol |
|-------|--------|
| 30–36 | `enum class animation_effect {none, glowing, jelly}` |

## th_gfx_sdl.h (776 lines)

| Lines | Symbol |
|-------|--------|
| 43–49 | `struct clip_rect : SDL_Rect` |
| 51–63 | `window_size`, `render_size` |
| 65–78 | `render_target_creation_params` |
| 85–187 | `class palette` (pack_argb/get_red/green/blue/alpha) |
| 189–262 | `full_colour_renderer`, `full_colour_storing`, `wx_storing` |
| 264–464 | `class render_target` (+`scoped_clip`, `scoped_target_texture`) |
| 466–528 | `class raw_bitmap` |
| 530–718 | `class sprite_sheet` (+ inner `struct sprite`) |
| 720–739 | `class cursor` |
| 741–775 | `class line_sequence` |

## th_gfx_font.h (370 lines)

| Lines | Symbol |
|-------|--------|
| 38–42 | `enum class text_alignment` |
| 44 | `enum class bitmap_font_character_set` |
| 47–65 | `struct text_layout` |
| 67–79 | `struct font_shadow_options` |
| 81–137 | `class font` (abstract) |
| 139–196 | `class bitmap_font` |
| 198–369 | `class freetype_font` (+`cached_text`, cache 128) |

## th_gfx.cpp (1890 lines)

| Lines | Symbol |
|-------|--------|
| 43–141 | `class memory_reader` |
| 143 | `set_sprite_sheet` |
| 151–187 | `th_frame_properties`, `th_element_properties` |
| 188–340 | `load_from_th_file` (START/FRAME/LIST/ELEMENT) |
| 370 | `set_canvas` |
| 396–485 | `load_elements`, `make_list_elements`, `fix_next_frame` |
| 498–739 | `load_custom_animations`, named animations |
| 740–848 | getters, `set_animation_alt_palette_map`, markers, `tick` |
| 850–918 | `hit_test` |
| 919–989 | `draw_frame` (layer filter + flip + effects) |
| 990–1039 | `get_frame_sound`, `get_frame_extent` |
| 1040–1090 | `chunk_renderer` impl incl. `decode_chunks:1083` |
| 1194–1218 | `animation::draw` (+crop `scoped_clip`) |
| 1220–1298 | `draw_child`, `draw_morph`, `hit_test*` |
| 1315–1488 | `animation::persist` / `depersist` |
| 1567–1677 | `animation::tick`, `set_parent`, `set_animation`, markers |
| 1678–1729 | `set_morph_target`, `set_frame` |
| 1731–1790 | `sprite_render_list::tick/draw/hit_test/lifetime/append` |
| 1795–1860 | `sprite_render_list::persist/depersist` |

## th_gfx_sdl.cpp (1792 lines)

| Lines | Symbol |
|-------|--------|
| 270–306 | `palette::palette`, `set_entry` (magenta→transparent) |
| 432–493 | `scoped_target_texture` (offset/scale/is_target/dtor) |
| 494–613 | `render_target` ctor/dtor/update/`on_pixel_size_change`/`set_scale_factor:613` |
| 664–701 | `set_caption`, `get_renderer_details`, `get_last_error`, `start_frame:674`, `end_frame:682` |
| 701–741 | `fill_black`, `fill_colour`, `set_blue_filter_active`, `fill_rect` |
| 742–774 | `scoped_clip`, `push_clip_rect:750`, `pop_clip_rect:766` |
| 775–841 | size/window/scale/cursor/screenshot/`should_scale_bitmaps:840` |
| 885–933 | `create_palettized_texture:885`, `create_texture:899` |
| 934–973 | `render_target::draw` (alpha mod + flip + scale rect) |
| 974–1019 | `draw_line`, `begin_intermediate_drawing`, `draw_scale` |
| 1026–1133 | `raw_bitmap::set_palette/load_from_th_file:1030/draw:1114,1118` |
| 1161–1213 | `set_palette`, `set_sprite_count`, `th_sprite_properties:1196` |
| 1214–1281 | `sprite_sheet::load_from_th_file`, `set_sprite_data:1255` |
| 1282–1368 | `set_sprite_alt_palette_map:1282`, size/avg-colour/visible |
| 1369–1451 | `sprite_sheet::draw_sprite` (lazy texture + glow/jelly) |
| 1452–1461 | `wx_draw_sprite` |
| 1462–1489 | `_makeAltBitmap` (remap, idx 255 preserved) |
| 1491–1604 | `get32BppPixel`, `testSprite`, `hit_test_sprite:1590` |
| 1650–1729 | `cursor::draw`, `line_sequence::draw` |
| 1730–1792 | freetype backend: `is_monochrome:1730`, `make_texture:1739`, `draw_texture:1784` |

## th_gfx_font.cpp (802 lines)

| Lines | Symbol |
|-------|--------|
| 61–115 | `bitmap_font`: ctor, `set_sprite_sheet:63`, `set_separation:69`, `set_scale_factor:74`, `get_text_dimensions:76`, `draw_text:83` |
| 116–219 | `bitmap_font::draw_text_wrapped` |
| 220–295 | freetype statics `220–221`, ctor `223`, dtor `240`, `initialise:261`, `clear_cache:272`, `set_face:280` |
| 296–376 | `match_bitmap_font:296`, `set_ideal_character_size:334`, `set_font_color:371`, `set_shadow_options:373`, `get_text_dimensions:377`, `draw_text:384` |
| 391–748 | `codepoint_glyph:391`, CJK breaks `397`, `draw_text_wrapped:423` |
| 749–802 | `render_mono:749`, `render_gray:778` |

## th_lua_gfx.cpp (1249 lines)

| Lines | Symbol |
|-------|--------|
| 51–60 | `luaT_getfont` |
| 63–89 | `l_palette_new`, `l_palette_set_entry` |
| 90–153 | `l_rawbitmap_new/set_pal/load/draw` |
| 155–273 | `l_spritesheet_new/load/draw:213/hittest/isvisible` |
| 274–347 | bitmap-font bindings |
| 348–520 | freetype-font bindings |
| 521–664 | `l_font_draw:521`, `draw_wrapped:573`, `draw_tooltip:622` |
| 671–733 | layers bindings |
| 734–780 | cursor bindings |
| 781–1119 | surface bindings (`start_frame:860`, `end_frame:871`, scale/caption/clip/line) |
| 1121–1249 | `lua_register_gfx` (palette/bitmap/sheet/font/layers/cursor/surface/line) |

## th_lua_anims.cpp (804 lines)

| Lines | Symbol |
|-------|--------|
| 42–114 | `l_anims_new`, set_sheet/canvas, `load:71`, `loadCustom:95` |
| 115–207 | getters, alt-pal `161`, markers `181,192,198` |
| 208–223 | `l_anims_draw` → `draw_frame` |
| 225–610 | generic `l_anim_new/tick/draw:609`, tile/flag/speed/layer/morph/crop |
| 637–675 | sprite-list: set_sheet/append/lifetime/intermediate/is_dead |
| 676–804 | `lua_register_anims` (anims/animation/spriteList + Alt32 constants) |

## Related pages

- [[core-graphics/SUMMARY]] — overview
- [[core-graphics/CLASS_DIAGRAM]] — class graph
- [[core-graphics/SEQUENCE_DIAGRAM]] — render path
- [[core-graphics/SPEC]] — data formats
