# Core Graphics — Render-Path Sequence

> Primary path: Lua `sheet:draw / anims:draw / animation:draw` → C++ → SDL present.

```mermaid
sequenceDiagram
    participant Lua as Lua (graphics/anim code)
    participant Bind as th_lua_gfx/anims
    participant AM as animation_manager
    participant SS as sprite_sheet
    participant RT as render_target
    participant SDL as SDL3 renderer

    Lua->>Bind: sheet:draw(canvas, idx, x, y, {flags, scaleFactor})
    Bind->>SS: draw_sprite(canvas, idx, x, y, flags, 0, none, scale)
    SS->>SS: lazy create_palettized_texture if texture==nil
    SS->>RT: draw(texture, srcRect, dstRect, flags)
    RT->>RT: alpha-mod (50/75), flip → scale rect → offset
    RT->>SDL: SDL_RenderTexture[Rotated]

    Lua->>Bind: anims:draw(canvas, frame, layers, x, y, flags)
    Bind->>AM: draw_frame(canvas, frame, layers, x, y, flags)
    AM->>AM: layer filter (skip unless layer_id==0 or match)
    AM->>SS: draw_sprite per element (flip-XOR, glow/jelly ticks)

    Lua->>Bind: surface:startFrame()
    Bind->>RT: start_frame() → fill_black()
    Lua->>Bind: surface:endFrame()
    Bind->>RT: end_frame() → cursor + blue filter + SDL_RenderPresent
```

## Alternate: animation:draw with sound + crop

```mermaid
sequenceDiagram
    participant Lua as Lua entity
    participant A as animation
    participant AM as animation_manager
    participant RT as render_target
    Lua->>A: anim:draw(canvas, x, y)
    A->>A: sound_to_play → sound_player.play_at (if any)
    A->>RT: scoped_clip (if thdf_crop, 64px column window)
    A->>AM: draw_frame(frame, layers, x+offset, y+offset, flags)
```

## Related pages

- [[core-graphics/SUMMARY]] — overview
- [[core-graphics/MAP]] — file:line index
- [[core-graphics/SPEC]] — sprite/palette formats
