# World-to-Screen — Sequence Diagram

## Camera move → tile draw → present

```mermaid
sequenceDiagram
    participant P as Player input
    participant G as GameUI (Lua)
    participant M as Map (Lua)
    participant C as level_map (C++)
    participant I as tile iterators
    participant S as sprite_sheet
    participant R as render_target/SDL
    P->>G: drag/keys/wheel (scrollMap/setZoom)
    G->>G: screen_offset += delta, clamp to visible_diamond
    G->>G: draw(): dx=offset+shake, zoom=getEffectiveZoom()
    G->>R: canvas:scale(zoom)
    G->>M: draw(canvas, dx, dy, w/zoom, h/zoom, 0, 0)
    M->>C: th:draw(sx, sy, sw, sh, dx, dy)
    C->>R: scoped_clip(canvas rect)
    C->>I: map_tile_iterator(sx, sy, sw, sh)
    I-->>C: visible tiles (margin-culled)
    C->>S: draw_floor tiles + shadows 74/75
    loop each scanline (is_last_on_scanline)
        C->>S: R-to-L: north walls + oEarlyEntities
        C->>S: L-to-R: west walls + ui + entities
        C->>S: layer 8/9 overdraw repair
    end
    C->>C: overlay.draw_cell per tile (if set)
    G->>R: canvas:scale(1)
    G->>R: Window.draw + tooltip + cursor
    R-->>P: SDL present (full-frame redraw)
```

## Notes

- No dirty-rect messages exist; culling = iterator margins + canvas clip.
- Zoom never enters C++; Lua pre-divides `w/zoom` and scales the target.
- Hit test (`hitTestObjects`) is the draw order reversed, not shown.

## Related Pages

- [[world-to-screen/SUMMARY]] — overview
- [[world-to-screen/CLASS_DIAGRAM]] — classes
- [[world-to-screen/MAP]] — line index
- [[world-to-screen/SPEC]] — math + flags
