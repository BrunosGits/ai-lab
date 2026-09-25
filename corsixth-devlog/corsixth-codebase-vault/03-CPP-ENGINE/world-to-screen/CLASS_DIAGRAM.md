# World-to-Screen — Class Diagram

```mermaid
classDiagram
    class level_map {
        +draw(pCanvas, iScreenX, iScreenY, iW, iH, iCX, iCY)
        +hit_test(iTestX, iTestY) drawable*
        +world_to_screen(x, y)$
        +screen_to_world(x, y)$
        +set_overlay(pOverlay, own)
        +set_all_wall_draw_flags(iFlags)
        -draw_floor(...)
        -draw_north_wall(...)
        -draw_layer(...) int
    }
    class map_tile {
        +uint16 tile_layers[4]
        +uint16 iParcelId
        +uint16 iRoomId
        +map_tile_flags flags
        +link_list entities
        +link_list oEarlyEntities
    }
    class map_tile_flags {
        +bool passable
        +bool can_travel_n/e/s/w
        +bool hospital
        +bool buildable
        +bool shadow_half/full/wall
    }
    class tile_layer {
        <<enum>> ground=0
        north_wall=1
        west_wall=2
        ui=3
    }
    class map_tile_iterator {
        +tile_x_position_on_screen() int
        +tile_y_position_on_screen() int
        +is_last_on_scanline() bool
        -margin_top=150
        -margin_left=110
    }
    class map_scanline_iterator {
        +x() int
        +y() int
        +get_tile() map_tile*
    }
    class map_overlay {
        <<abstract>>
        +draw_cell(pCanvas, cX, cY, pMap, nX, nY)*
    }
    class map_overlay_pair {
        +set_first(p, own)
        +set_second(p, own)
    }
    class map_typical_overlay {
        +set_sprites(pSheet, own)
        +set_font(f, own)
        #draw_text(pCanvas, x, y, str)
    }
    class map_text_overlay {
        +set_background_sprite(i)
        +get_text(pMap, x, y)* string
    }
    class map_positions_overlay { +get_text() string }
    class map_flags_overlay { +draw_cell() }
    class map_parcels_overlay { +draw_cell() }
    class LuaMap { +WorldToScreen(x,y) +ScreenToWorld(x,y) +draw(...) }
    class GameUI {
        +screen_offset_x/y
        +zoom_factor
        +scrollMap(dx,dy)
        +setZoom(f)
        +draw(canvas)
    }
    level_map *-- map_tile : cells
    map_tile *-- map_tile_flags : flags
    map_tile -- tile_layer : indexes
    map_tile_iterator --> level_map : iterates
    map_scanline_iterator --> map_tile_iterator : re-iterates
    level_map --> map_overlay : overlay
    map_overlay <|-- map_overlay_pair
    map_overlay <|-- map_typical_overlay
    map_typical_overlay <|-- map_text_overlay
    map_text_overlay <|-- map_positions_overlay
    map_typical_overlay <|-- map_flags_overlay
    map_typical_overlay <|-- map_parcels_overlay
    GameUI --> LuaMap : map.draw()
    LuaMap --> level_map : th.draw()
```

## Related Pages

- [[world-to-screen/SUMMARY]] — overview
- [[world-to-screen/MAP]] — file:line index
- [[world-to-screen/SEQUENCE_DIAGRAM]] — flow
- [[world-to-screen/SPEC]] — math + flags
