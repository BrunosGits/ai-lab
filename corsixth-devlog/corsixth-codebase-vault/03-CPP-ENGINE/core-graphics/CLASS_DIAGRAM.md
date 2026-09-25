# Core Graphics — Class Diagram

```mermaid
classDiagram
    class drawable {
        +uint32_t flags
        +draw_fn(canvas, pos)*
        +hit_test_fn(pos, obj)*
        +is_multiple_frame_animation_fn()*
    }
    class animation_base {
        +xy_pair tile
        +xy_pair pixel_offset
        +layers layers
        +int scale_factor
        +attach_to_tile() void
        +remove_from_tile() void
    }
    class animation {
        +size_t animation_index
        +size_t frame_index
        +animation_kind anim_kind
        +tick() void
        +draw() void
        +draw_child() void
        +draw_morph() void
    }
    class sprite_render_list {
        +sprite_sheet* sheet
        +int lifetime
        +append_sprite() void
        +tick() void
        +draw() void
    }
    class animation_manager {
        +first_frames vector
        +frames vector
        +element_list vector
        +elements vector
        +load_from_th_file() bool
        +draw_frame() void
        +tick() void
    }
    class chunk_renderer {
        +decode_chunks() void
        +chunk_copy() void
        +chunk_fill() void
    }
    class palette {
        +color_count = 256
        +pack_argb() uint32_t
        +get_argb_data() array
    }
    class raw_bitmap {
        +SDL_Texture* texture
        +load_from_th_file() void
        +draw() void
    }
    class sprite_sheet {
        +sprite* sprites
        +size_t sprite_count
        +load_from_th_file() bool
        +draw_sprite() void
        +hit_test_sprite() bool
    }
    class render_target {
        +SDL_Window* window
        +SDL_Renderer* renderer
        +start_frame() bool
        +end_frame() bool
        +draw() void
        +create_palettized_texture() SDL_Texture*
    }
    class font {
        +draw_text()*
        +draw_text_wrapped()*
        +get_text_dimensions()*
    }
    class bitmap_font {
        +sprite_sheet* sheet
        +int scale_factor
    }
    class freetype_font {
        +FT_Face font_face
        +cached_text cache[128]
        +set_face() FT_Error
        +make_texture() void
    }
    class cursor { +draw() void }
    class line_sequence { +draw() void }

    drawable <|-- animation_base
    animation_base <|-- animation
    animation_base <|-- sprite_render_list
    font <|-- bitmap_font
    font <|-- freetype_font
    animation_manager --> sprite_sheet : sheet (borrowed)
    animation_manager --> render_target : canvas (borrowed)
    animation --> animation_manager : manager (borrowed)
    sprite_render_list --> sprite_sheet : sheet (borrowed)
    sprite_sheet --> palette : palette (borrowed)
    raw_bitmap --> palette : bitmap_palette (borrowed)
    bitmap_font --> sprite_sheet : glyph sheet
    chunk_renderer ..> sprite_sheet : used at load
    render_target ..> palette : pack_argb/get_red/green/blue/alpha
```

## Relationships

| Edge | Meaning |
|------|---------|
| manager → sheet/canvas | borrowed, set via `set_sprite_sheet` / `set_canvas` |
| animation → manager | borrowed, set via `set_animation` |
| sheet → palette | borrowed, set via `set_palette` |
| lazy texture | `draw_sprite` uploads on first use; `raw_bitmap` uploads at load |

## Related pages

- [[core-graphics/SUMMARY]] — overview
- [[core-graphics/MAP]] — file:line index
- [[core-graphics/SPEC]] — data formats
