# Entity Rendering — Class Diagram

```mermaid
classDiagram
    class drawable {
        <<abstract>>
        +uint32_t flags
        -int drawing_layer
        +draw_fn(canvas, pos)*
        +hit_test_fn(draw_pos, obj_pos)*
        +is_multiple_frame_animation_fn()*
        +get_drawing_layer() int
        +set_drawing_layer(int)
    }
    class animation_manager {
        -vector~size_t~ first_frames
        -vector~uint16_t~ element_list
        -vector~element~ elements
        -size_t game_ticks
        +load_from_th_file() bool
        +load_custom_animations() bool
        +get_first_frame(anim) size_t
        +get_next_frame(frame) size_t
        +draw_frame(canvas, frame, layers, x, y, flags) void
        +get_frame_sound(frame) size_t
        +hit_test(...) bool
        +set_animation_alt_palette_map(anim, map, alt32) void
        +tick() void
    }
    class animation_base {
        #xy_pair tile
        #xy_pair pixel_offset
        #layers layers
        #int scale_factor
        +attach_to_tile(pos, node, layer) void
        +remove_from_tile() void
        +set_layer(i, id) void
    }
    class animation {
        -animation_manager* manager
        -size_t animation_index
        -size_t frame_index
        -animation* morph_target
        -animation_kind anim_kind
        +tick() void
        +draw(canvas, pos) void
        +draw_child(canvas, pos, primary) void
        +draw_morph(canvas, pos) void
        +set_parent(p, primary) void
    }
    class sprite_render_list {
        -sprite_sheet* sheet
        -vector~sprite~ sprites
        -int lifetime
        +tick() void
        +draw(canvas, pos) void
        +append_sprite(i, x, y) void
    }
    class level_map {
        -map_tile* cells
        -sprite_sheet* wall_blocks
        +draw(...) void
        +draw_floor(...) void
        +draw_north_wall(...) void
        +draw_layer(...) int
        +hit_test(x, y) drawable*
    }
    class map_tile {
        +link_list entities
        +link_list oEarlyEntities
        +uint16_t tile_layers[4]
    }
    class cursor {
        -SDL_Surface* bitmap
        +create_from_sprite(sheet, i, hx, hy) bool
        +use(target) void
        +set_position(target, x, y) bool$
        +draw(canvas, x, y) void
    }
    drawable <|-- animation_base
    animation_base <|-- animation
    animation_base <|-- sprite_render_list
    animation --> animation_manager : uses
    animation --> animation : parent / morph_target
    level_map *-- map_tile : cells
    map_tile o--> drawable : entities + oEarlyEntities
    level_map ..> drawable : draw_fn / hit_test_fn
    animation_manager ..> cursor : none (separate subsystem)
```

## Related Pages

- [[entity-rendering/SUMMARY]] — overview
- [[entity-rendering/MAP]] — file:line index
- [[entity-rendering/SEQUENCE_DIAGRAM]] — tick to draw
- [[entity-rendering/SPEC]] — layers and frame format
