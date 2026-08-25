# C++ Lua Binding Registration Map

## File:Line Index for All Binding Registration Functions

This document maps every `lua_register_*` function and its internal class/method registrations across all `th_lua_*.cpp` files.

---

## Master Registration: th_lua.cpp

### luaopen_th (lines 320-358)

| Line | Function | Description |
|------|----------|-------------|
| 320 | `luaopen_th` | Master module entry point |
| 324-333 | State setup | Creates 23 metatables + main table |
| 336-342 | Module functions | `LoadStrings`, `GetCompileOptions`, `GetBuiltinFont`, `FetchLatestVersionInfo`, `CRC32File` |
| 345 | `lua_register_map` | Map & Pathfinder |
| 346 | `lua_register_gfx` | Graphics subsystem |
| 347 | `lua_register_anims` | Animations |
| 348 | `lua_register_sound` | Sound |
| 349 | `lua_register_movie` | Movie playback |
| 350 | `lua_register_strings` | String proxy |
| 351 | `lua_register_ui` | UI helpers |
| 352 | `lua_register_lfs_ext` | Filesystem extensions |
| 353 | `lua_register_iso_fs` | ISO filesystem |
| 354 | `lua_register_midi` | MIDI playback |

---

## th_lua_map.cpp (lines 1108-1167)

### lua_register_map (line 1108)

#### level_map (Map) - lua_metatable::map

| Line | Method | Upvalues |
|------|--------|----------|
| 1111 | `l_map_new` (constructor) | - |
| 1113 | `__persist` → `l_map_persist` | anim |
| 1114 | `__depersist` → `l_map_depersist` | anim |
| 1115 | `load` → `l_map_load` | - |
| 1116 | `loadBlank` → `l_map_loadblank` | - |
| 1117 | `save` → `l_map_save` | - |
| 1118 | `size` → `l_map_getsize` | - |
| 1119 | `getPlayerCount` → `l_map_get_player_count` | - |
| 1120 | `setPlayerCount` → `l_map_set_player_count` | - |
| 1121 | `getCameraTile` → `l_map_get_player_camera` | - |
| 1122 | `setCameraTile` → `l_map_set_player_camera` | - |
| 1123 | `getHeliportTile` → `l_map_get_player_heliport` | - |
| 1124 | `setHeliportTile` → `l_map_set_player_heliport` | - |
| 1125 | `getCell` → `l_map_getcell` | - |
| 1126 | `getCellTemperature` → `l_map_gettemperature` | - |
| 1127 | `getRoomId` → `l_map_get_room_id` | - |
| 1128 | `getCellFlags` → `l_map_getcellflags` | - |
| 1129 | `setCellFlags` → `l_map_setcellflags` | - |
| 1130 | `getCellRaw` → `l_map_getcellraw` | - |
| 1131 | `setCell` → `l_map_setcell` | - |
| 1132 | `setWallDrawFlags` → `l_map_setwallflags` | - |
| 1133 | `setTemperatureDisplay` → `l_map_settemperaturedisplay` | - |
| 1134 | `updateTemperatures` → `l_map_updatetemperature` | - |
| 1135-1136 | `updateRoomBlueprint` → `l_map_updateblueprint` | anims, anim |
| 1137 | `updateShadows` → `l_map_updateshadows` | - |
| 1138 | `updatePathfinding` → `l_map_updatepathfinding` | - |
| 1139 | `markRoom` → `l_map_mark_room` | - |
| 1140 | `unmarkRoom` → `l_map_unmark_room` | - |
| 1141 | `setSheet` → `l_map_set_sheet` | sheet |
| 1142 | `draw` → `l_map_draw` | surface |
| 1143 | `hitTestObjects` → `l_map_hittest` | anim |
| 1144 | `getParcelTileCount` → `l_map_get_parcel_tilecount` | - |
| 1145 | `getPlotCount` → `l_map_get_parcel_count` | - |
| 1146 | `setPlotOwner` → `l_map_set_parcel_owner` | - |
| 1147 | `getPlotOwner` → `l_map_get_parcel_owner` | - |
| 1148 | `isParcelPurchasable` → `l_map_is_parcel_purchasable` | - |
| 1149 | `eraseObjectTypes` → `l_map_erase_thobs` | - |
| 1150 | `removeObjectType` → `l_map_remove_cell_thob` | - |
| 1151 | `getLitterFraction` → `l_map_get_litter_fraction` | - |

#### pathfinder (Pathfinder) - lua_metatable::pathfinder

| Line | Method | Upvalues |
|------|--------|----------|
| 1156 | `l_path_new` (constructor) | - |
| 1158 | `__persist` → `l_path_persist` | - |
| 1159 | `__depersist` → `l_path_depersist` | - |
| 1160 | `findDistance` → `l_path_distance` | - |
| 1161-1162 | `isReachableFromHospital` → `l_path_is_reachable_from_hospital` | - |
| 1163 | `findPath` → `l_path_path` | - |
| 1164 | `findIdleTile` → `l_path_idle` | - |
| 1165 | `findObject` → `l_path_visit` | - |
| 1166 | `setMap` → `l_path_set_map` | map |

---

## th_lua_gfx.cpp (lines 1098-1224)

### lua_register_gfx (line 1098)

#### palette (Palette) - lua_metatable::palette

| Line | Method | Upvalues |
|------|--------|----------|
| 1101 | `l_palette_new` (constructor) | - |
| 1103 | `setEntry` → `l_palette_set_entry` | - |

#### raw_bitmap (bitmap) - lua_metatable::bitmap

| Line | Method | Upvalues |
|------|--------|----------|
| 1108 | `l_rawbitmap_new` (constructor) | - |
| 1110 | `load` → `l_rawbitmap_load` | surface |
| 1111 | `setPalette` → `l_rawbitmap_set_pal` | palette |
| 1112 | `draw` → `l_rawbitmap_draw` | surface |

#### sprite_sheet (sheet) - lua_metatable::sheet

| Line | Method | Upvalues |
|------|--------|----------|
| 1117 | `l_spritesheet_new` (constructor) | - |
| 1119 | `__len` → `l_spritesheet_count` | - |
| 1120 | `load` → `l_spritesheet_load` | surface |
| 1121 | `setPalette` → `l_spritesheet_set_pal` | palette |
| 1123 | `size` → `l_spritesheet_size` | - |
| 1124 | `draw` → `l_spritesheet_draw` | surface |
| 1125 | `hitTest` → `l_spritesheet_hittest` | - |
| 1126 | `isVisible` → `l_spritesheet_isvisible` | - |

#### font (Font) - lua_metatable::font (abstract base)

| Line | Method | Upvalues |
|------|--------|----------|
| 1132 | `l_font_new` (errors - abstract) | - |
| 1134 | `sizeOf` → `l_font_get_size` | - |
| 1135 | `draw` → `l_font_draw` | surface |
| 1136-1137 | `drawWrapped` → `l_font_draw_wrapped` | surface |
| 1138-1139 | `drawTooltip` → `l_font_draw_tooltip` | surface |
| 1140 | `isBitmap` → `l_font_is_bitmap` | - |

#### bitmap_font (BitmapFont) - lua_metatable::bitmap_font

| Line | Method | Upvalues |
|------|--------|----------|
| 1145 | `l_bitmap_font_new` (constructor) | - |
| 1147 | `set_superclass(font)` | - |
| 1148-1149 | `setSheet` → `l_bitmap_font_set_spritesheet` | sheet |
| 1150-1151 | `getSheet` → `l_bitmap_font_get_spritesheet` | sheet |
| 1152 | `setSeparation` → `l_bitmap_font_set_sep` | - |
| 1153 | `setScaleFactor` → `l_bitmap_font_set_scale` | - |

#### freetype_font (FreeTypeFont) - lua_metatable::freetype_font

| Line | Method | Upvalues |
|------|--------|----------|
| 1158 | `l_freetype_font_new` (constructor) | - |
| 1160 | `set_superclass(font)` | - |
| 1162-1163 | `setFontOptions` → `l_freetype_font_set_font_options` | sheet |
| 1164 | `setFace` → `l_freetype_font_set_face` | - |
| 1165 | `getCopyrightNotice` → `l_freetype_font_get_copyright` | - |
| 1166 | `clearCache` → `l_freetype_font_clear_cache` | - |

#### layers (Layers) - lua_metatable::layers

| Line | Method | Upvalues |
|------|--------|----------|
| 1171 | `l_layers_new` (constructor) | - |
| 1173 | `__index` → `l_layers_get` | - |
| 1174 | `__newindex` → `l_layers_set` | - |
| 1175 | `__persist` → `l_layers_persist` | - |
| 1176 | `__depersist` → `l_layers_depersist` | - |

#### cursor (Cursor) - lua_metatable::cursor

| Line | Method | Upvalues |
|------|--------|----------|
| 1181 | `l_cursor_new` (constructor) | - |
| 1183 | `load` → `l_cursor_load` | sheet |
| 1184 | `use` → `l_cursor_use` | surface |
| 1185 | `setPosition` → `l_cursor_position` | surface |

#### render_target (surface) - lua_metatable::surface

| Line | Method | Upvalues |
|------|--------|----------|
| 1190 | `l_surface_new` (constructor) | - |
| 1192 | `update` → `l_surface_update` | - |
| 1193 | `fillBlack` → `l_surface_fill_black` | - |
| 1194 | `fillColour` → `l_surface_fill_colour` | - |
| 1195 | `startFrame` → `l_surface_start_frame` | - |
| 1196 | `endFrame` → `l_surface_end_frame` | - |
| 1197 | `nonOverlapping` → `l_surface_nonoverlapping` | - |
| 1198 | `mapRGB` → `l_surface_map` | - |
| 1199 | `setBlueFilterActive` → `l_surface_set_blue_filter_active` | - |
| 1200 | `drawRect` → `l_surface_rect` | - |
| 1201 | `pushClip` → `l_surface_push_clip` | - |
| 1202 | `popClip` → `l_surface_pop_clip` | - |
| 1203 | `getWidth` → `l_surface_get_width` | - |
| 1204 | `getHeight` → `l_surface_get_height` | - |
| 1205 | `getRenderSize` → `l_surface_get_render_dimensions` | - |
| 1206 | `takeScreenshot` → `l_surface_screenshot` | - |
| 1207 | `scale` → `l_surface_scale` | - |
| 1208 | `setCaption` → `l_surface_set_caption` | - |
| 1209 | `getRendererDetails` → `l_surface_get_renderer_details` | - |
| 1210 | `setCaptureMouse` → `l_surface_set_capture_mouse` | - |

#### line_sequence (line) - lua_metatable::line

| Line | Method | Upvalues |
|------|--------|----------|
| 1215 | `l_line_new` (constructor) | - |
| 1217 | `moveTo` → `l_move_to` | - |
| 1218 | `lineTo` → `l_line_to` | - |
| 1219 | `setWidth` → `l_set_width` | - |
| 1220 | `setColour` → `l_set_colour` | - |
| 1221 | `draw` → `l_line_draw` | surface |
| 1222 | `__persist` → `l_line_persist` | - |
| 1223 | `__depersist` → `l_line_depersist` | - |

---

## th_lua_anims.cpp (lines 676-803)

### lua_register_anims (line 676)

#### animation_manager (anims) - lua_metatable::anims

| Line | Method | Upvalues |
|------|--------|----------|
| 679 | `l_anims_new` (constructor) | - |
| 681 | `load` → `l_anims_load` | - |
| 682 | `loadCustom` → `l_anims_loadcustom` | - |
| 683 | `setSheet` → `l_anims_set_spritesheet` | sheet |
| 684 | `setCanvas` → `l_anims_set_canvas` | surface |
| 685 | `getAnimations` → `l_anims_getanims` | - |
| 686 | `getFirstFrame` → `l_anims_getfirst` | - |
| 687 | `getNextFrame` → `l_anims_getnext` | - |
| 688 | `setAnimationGhostPalette` → `l_anims_set_alt_pal` | - |
| 689 | `setFramePrimaryMarker` → `l_anims_set_primary_marker` | - |
| 690 | `setFrameSecondaryMarker` → `l_anims_set_secondary_marker` | - |
| 691-692 | `draw` → `l_anims_draw` | surface, layers |
| 693 | `tick` → `l_anims_tick` | - |
| 694 | `Alt32_GreyScale` (constant) | - |
| 695 | `Alt32_BlueRedSwap` (constant) | - |

#### Special: Weak Tables (lines 698-716)

| Line | Table | Purpose |
|------|-------|---------|
| 700-706 | `anim_metatable[1]` | Weak values: lightuserdata → animation (hitTest) |
| 708-716 | `anim_metatable[2]` | Weak values: lightuserdata → full userdata (persistence) |

#### animation (anim) - lua_metatable::anim

| Line | Method | Upvalues |
|------|--------|----------|
| 720 | `l_anim_new<animation>` (constructor) | - |
| 722 | `__persist` → `l_anim_persist<animation>` | - |
| 723 | `__pre_depersist` → `l_anim_pre_depersist<animation>` | - |
| 724 | `__depersist` → `l_anim_depersist<animation>` | - |
| 725 | `setAnimation` → `l_anim_set_anim` | anims |
| 726 | `setCrop` → `l_anim_set_crop` | - |
| 727 | `getCrop` → `l_anim_get_crop` | - |
| 728 | `setMorph` → `l_anim_set_morph` | - |
| 729 | `setFrame` → `l_anim_set_frame` | - |
| 730 | `getFrame` → `l_anim_get_frame` | - |
| 731 | `getAnimation` → `l_anim_get_anim` | - |
| 732 | `setTile` → `l_anim_set_tile<animation>` | map |
| 733 | `getTile` → `l_anim_get_tile` | - |
| 734 | `setParent` → `l_anim_set_parent` | - |
| 735 | `setFlag` → `l_anim_set_flag<animation>` | - |
| 736 | `setPartialFlag` → `l_anim_set_flag_partial<animation>` | - |
| 737 | `getFlag` → `l_anim_get_flag<animation>` | - |
| 738 | `isVisible` → `l_anim_is_visible<animation>` | - |
| 739 | `makeVisible` → `l_anim_make_visible<animation>` | - |
| 740 | `makeInvisible` → `l_anim_make_invisible<animation>` | - |
| 741 | `setTag` → `l_anim_set_tag` | - |
| 742 | `getTag` → `l_anim_get_tag` | - |
| 743 | `setPosition` → `l_anim_set_pixel_offset<animation>` | - |
| 744 | `getPosition` → `l_anim_get_pixel_offset` | - |
| 745 | `setSpeed` → `l_anim_set_speed<animation>` | - |
| 746 | `setLayer` → `l_anim_set_layer<animation>` | - |
| 747 | `setLayersFrom` → `l_anim_set_layers_from` | - |
| 748 | `setScaleFactor` → `l_anim_set_scale_factor<animation>` | - |
| 749 | `setHitTestResult` → `l_anim_set_hitresult` | - |
| 750 | `getPrimaryMarker` → `l_anim_get_primary_marker` | - |
| 751 | `getSecondaryMarker` → `l_anim_get_secondary_marker` | - |
| 752 | `tick` → `l_anim_tick<animation>` | - |
| 753 | `draw` → `l_anim_draw<animation>` | surface |
| 754 | `setPatientEffect` → `l_anim_set_patient_effect` | - |

#### Special: Duplicate Weak Tables (lines 757-767)

| Line | Action | Purpose |
|------|--------|---------|
| 758-762 | Copy `anim_metatable[1]` → `sprite_list_metatable[1]` | Shared hitTest table |
| 763-767 | Copy `anim_metatable[2]` → `sprite_list_metatable[2]` | Shared persistence table |

#### sprite_render_list (spriteList) - lua_metatable::sprite_list

| Line | Method | Upvalues |
|------|--------|----------|
| 771 | `l_anim_new<sprite_render_list>` (constructor) | - |
| 774 | `__persist` → `l_anim_persist<sprite_render_list>` | - |
| 775-776 | `__pre_depersist` → `l_anim_pre_depersist<sprite_render_list>` | - |
| 777 | `__depersist` → `l_anim_depersist<sprite_render_list>` | - |
| 778 | `setSheet` → `l_srl_set_sheet` | sheet |
| 779 | `append` → `l_srl_append` | - |
| 780 | `setLifetime` → `l_srl_set_lifetime` | - |
| 781-782 | `setUseIntermediateBuffer` → `l_srl_set_use_intermediate_buffer` | - |
| 783-784 | `setScaleFactor` → `l_anim_set_scale_factor<sprite_render_list>` | - |
| 785 | `isDead` → `l_srl_is_dead` | - |
| 786-787 | `setTile` → `l_anim_set_tile<sprite_render_list>` | map |
| 788 | `setFlag` → `l_anim_set_flag<sprite_render_list>` | - |
| 789-790 | `setPartialFlag` → `l_anim_set_flag_partial<sprite_render_list>` | - |
| 791 | `getFlag` → `l_anim_get_flag<sprite_render_list>` | - |
| 792 | `isVisible` → `l_anim_is_visible<sprite_render_list>` | - |
| 793 | `makeVisible` → `l_anim_make_visible<sprite_render_list>` | - |
| 794-795 | `makeInvisible` → `l_anim_make_invisible<sprite_render_list>` | - |
| 796-797 | `setPosition` → `l_anim_set_pixel_offset<sprite_render_list>` | - |
| 798 | `setSpeed` → `l_anim_set_speed<sprite_render_list>` | - |
| 799 | `setLayer` → `l_anim_set_layer<sprite_render_list>` | - |
| 800 | `tick` → `l_anim_tick<sprite_render_list>` | - |
| 801-802 | `draw` → `l_anim_draw<sprite_render_list>` | surface |

---

## th_lua_sound.cpp (lines 355-385)

### lua_register_sound (line 355)

#### sound_archive (soundArchive) - lua_metatable::sound_archive

| Line | Method | Upvalues |
|------|--------|----------|
| 358 | `l_soundarc_new` (constructor) | - |
| 360 | `__len` → `l_soundarc_count` | - |
| 361 | `load` → `l_soundarc_load` | - |
| 362-363 | `getFilename` → `l_soundarc_sound_name` | - |
| 364 | `getDuration` → `l_soundarc_duration` | - |
| 365-366 | `getFileData` → `l_soundarc_data` | - |
| 367 | `soundExists` → `l_soundarc_sound_exists` | - |

#### sound_player (soundEffects) - lua_metatable::sound_fx

| Line | Method | Upvalues |
|------|--------|----------|
| 372 | `l_soundfx_new` (constructor) | - |
| 374-375 | `setSoundArchive` → `l_soundfx_set_archive` | sound_archive |
| 376 | `play` → `l_soundfx_play` | - |
| 377 | `togglePause` → `l_soundfx_toggle_pause` | - |
| 378 | `stop` → `l_soundfx_stop` | - |
| 379 | `isPlaying` → `l_soundfx_is_playing` | - |
| 380 | `setSoundVolume` → `l_soundfx_set_sound_volume` | - |
| 381 | `setSoundEffectsOn` → `l_soundfx_set_sound_effects_on` | - |
| 382 | `setCamera` → `l_soundfx_set_camera` | - |
| 383 | `reserveChannel` → `l_soundfx_reserve_channel` | - |
| 384 | `releaseChannel` → `l_soundfx_release_channel` | - |

---

## th_lua_movie.cpp (lines 164-181)

### lua_register_movie (line 164)

#### movie_player (moviePlayer) - lua_metatable::movie

| Line | Method | Upvalues |
|------|--------|----------|
| 165 | `l_movie_new` (constructor) | - |
| 167 | `setRenderer` → `l_movie_set_renderer` | surface |
| 168 | `getEnabled` → `l_movie_enabled` | - |
| 169 | `load` → `l_movie_load` | - |
| 170 | `unload` → `l_movie_unload` | - |
| 171 | `play` → `l_movie_play` | - |
| 172 | `stop` → `l_movie_stop` | - |
| 173 | `togglePause` → `l_movie_toggle_pause` | - |
| 174 | `getNativeHeight` → `l_movie_get_native_height` | - |
| 175 | `getNativeWidth` → `l_movie_get_native_width` | - |
| 176 | `hasAudioTrack` → `l_movie_has_audio_track` | - |
| 177 | `getLength` → `l_movie_get_length` | - |
| 178 | `refresh` → `l_movie_refresh` | - |
| 179 | `allocatePictureBuffer` → `l_movie_allocate_picture_buffer` | - |
| 180-181 | `deallocatePictureBuffer` → `l_movie_deallocate_picture_buffer` | - |

---

## th_lua_strings.cpp (lines 636-694)

### lua_register_strings (line 636)

#### Special: Registry Weak Tables (lines 640-664)

| Line | Table | Purpose |
|------|-------|---------|
| 641-659 | `weak_table_keys[0]` | `StringProxyValues` - proxied values (weak keys) |
| 647-656 | `weak_table_keys[1]` | Cache table with auto-vivification `__index` |

#### string_proxy (stringProxy) - lua_metatable::string_proxy

| Line | Method | Upvalues |
|------|--------|----------|
| 666 | `l_str_new` (constructor) | - |
| 675 | `__index` → `l_str_index` | - |
| 676 | `__newindex` → `l_str_newindex` | - |
| 677 | `__concat` → `l_str_concat` | - |
| 678 | `__len` → `l_str_len` | - |
| 679 | `__tostring` → `l_str_tostring` | - |
| 680 | `__persist` → `l_str_persist` | - |
| 681 | `__depersist` → `l_str_depersist` | - |
| 682 | `__call` → `l_str_call` | - |
| 683 | `__lt` → `l_str_lt` | - |
| 684 | `__pairs` → `l_str_pairs` | - |
| 685 | `__ipairs` → `l_str_ipairs` | - |
| 686 | `__next` → `l_str_next` | - |
| 687 | `__inext` → `l_str_inext` | - |
| 688 | `format` → `l_str_func` | "format" |
| 689 | `lower` → `l_str_func` | "lower" |
| 690 | `rep` → `l_str_func` | "rep" |
| 691 | `reverse` → `l_str_func` | "reverse" |
| 692 | `upper` → `l_str_func` | "upper" |
| 693 | `_unwrap` → `l_str_unwrap` | - |
| 694 | `reload` → `l_str_reload` | - |

---

## th_lua_ui.cpp (lines 178-184)

### lua_register_ui (line 178)

#### abstract_window (windowHelpers) - lua_metatable::window_base

| Line | Method | Upvalues |
|------|--------|----------|
| 180 | `l_abstract_window_new` (errors - abstract) | - |
| 183-184 | `townMapDraw` → `l_town_map_draw` | map, surface |

---

## th_lua_lfs_ext.cpp (lines 95-98)

### lua_register_lfs_ext (line 95)

#### lfs_ext (lfsExt) - lua_metatable::lfs_ext

| Line | Method | Upvalues |
|------|--------|----------|
| 96 | `l_lfs_ext_new` (constructor) | - |
| 98 | `volumes` → `l_volume_list` | - |

---

## th_lua_iso.cpp (lines 180-188)

### lua_register_iso_fs (line 180)

#### iso_filesystem (iso_fs) - lua_metatable::iso_fs

| Line | Method | Upvalues |
|------|--------|----------|
| 181 | `l_isofs_new` (constructor) | - |
| 183 | `fileExists` → `l_isofs_file_exists` | - |
| 184 | `fileSize` → `l_isofs_file_size` | - |
| 185 | `fileOffsets` → `l_isofs_file_offsets` | - |
| 186 | `readContents` → `l_isofs_read_contents` | - |
| 187 | `listFiles` → `l_isofs_list_files` | - |
| 188 | `isValidRoot` → `l_isofs_is_valid_root` | - |

---

## th_lua_midi.cpp (lines 247-260)

### lua_register_midi (line 247)

#### th_lua_midi_player (midiPlayer) - lua_metatable::midi_player

| Line | Method | Upvalues |
|------|--------|----------|
| 248 | `l_midi_player_new` (constructor) | - |
| 251 | `getAvailableApis` → `l_midi_player_api_list` | - |
| 254 | `portList` → `l_midi_port_list` | - |
| 255 | `playXmi` → `l_midi_player_play_xmi` | - |
| 256 | `setVolume` → `l_midi_player_set_volume` | - |
| 257 | `stop` → `l_midi_player_stop` | - |
| 258 | `pause` → `l_midi_player_pause` | - |
| 259 | `resume` → `l_midi_player_resume` | - |
| 260 | `close` → `l_midi_player_close` | - |

---

## Cross-Reference: Metatable Dependencies

| Consumer | Uses Metatable | For |
|----------|----------------|-----|
| map | anim, sheet, surface | blueprint, drawing, hitTest |
| pathfinder | map | pathfinding on map |
| gfx: bitmap | surface, palette | drawing, palette |
| gfx: sheet | surface, palette | drawing, palette |
| gfx: bitmap_font | sheet | font rendering |
| gfx: freetype_font | sheet | font rendering |
| gfx: cursor | sheet, surface | cursor rendering |
| gfx: line | surface | line drawing |
| anims | sheet, surface, layers | animation setup, drawing |
| anim | anims, map, surface | animation control, tile attachment, drawing |
| spriteList | anim (weak tables), sheet, map, surface | shared weak tables, sprite rendering |
| sound: soundEffects | sound_archive | sound data |
| movie | surface | renderer |
| ui | map, surface | town map drawing |

---

## Summary Statistics

| File | Classes | Functions | Metamethods | Constants |
|------|---------|-----------|-------------|-----------|
| th_lua_map.cpp | 2 | 54 | 4 | 0 |
| th_lua_gfx.cpp | 12 | 60+ | 6 | 0 |
| th_lua_anims.cpp | 3 | 55+ | 9 | 2 |
| th_lua_sound.cpp | 2 | 18 | 1 | 0 |
| th_lua_movie.cpp | 1 | 14 | 0 | 0 |
| th_lua_strings.cpp | 1 | 8 | 14 | 0 |
| th_lua_ui.cpp | 1 | 1 | 0 | 0 |
| th_lua_lfs_ext.cpp | 1 | 1 | 0 | 0 |
| th_lua_iso.cpp | 1 | 7 | 0 | 0 |
| th_lua_midi.cpp | 1 | 8 | 0 | 0 |
| **Total** | **25** | **~226** | **34** | **2** |

---

*Generated from CorsixTH source code analysis - Line numbers may shift with edits*


## Related Pages

- [[18-cpp-bindings/SUMMARY]]
- [[18-cpp-bindings/CHECKLIST]]
- [[18-cpp-bindings/SCAFFOLD]]
