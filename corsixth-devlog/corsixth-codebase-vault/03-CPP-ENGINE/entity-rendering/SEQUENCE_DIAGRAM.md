# Entity Rendering — Sequence Diagram

```mermaid
sequenceDiagram
    participant W as World:onTick (Lua)
    participant AM as animation_manager (C++)
    participant E as Entity (Lua)
    participant A as animation (C++)
    participant M as level_map (C++)
    participant G as GameUI:draw (Lua)
    W->>AM: anims:tick() (l_anims_tick)
    AM->>AM: ++game_ticks (effect clock)
    W->>E: entity:tick() → _tick()
    E->>A: th:tick() (l_anim_tick)
    A->>AM: frame = get_next_frame(frame)
    A->>A: pixel_offset += speed
    A->>AM: sound_to_play = get_frame_sound(frame)
    Note over G,M: --- draw phase (next frame) ---
    G->>M: map:draw(canvas,...) (l_map_draw)
    M->>M: draw_floor (pass 1: ground + shadows 74/75)
    loop scanlines (painter order)
        M->>M: draw_north_wall (right-to-left)
        M->>A: early draw_fn() → draw_frame
        M->>M: draw west_wall + ui layer (left-to-right)
        M->>A: late draw_fn() → draw_frame
        A->>AM: draw_frame(frame, layers, x, y, flags)
        AM->>AM: filter by layers[13]; skip on alpha50+75
        A->>A: play deferred sound_to_play at (x,y)
    end
    G->>G: Window.draw + tooltip + simulated cursor
```

## Related Pages

- [[entity-rendering/SUMMARY]] — overview
- [[entity-rendering/MAP]] — file:line index
- [[entity-rendering/SEQUENCE_DIAGRAM]] — tick to draw
- [[entity-rendering/SPEC]] — layers and frame format
