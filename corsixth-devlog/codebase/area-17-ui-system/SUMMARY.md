# CorsixTH Window/UI Event System — Deep Research

**Version:** 1.0  
**Source Files:** `window.lua` (2185 lines), `ui.lua` (1278 lines), `game_ui.lua` (1350 lines)  
**Generated:** 2026-08-18

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Window Class — Core Foundation](#2-window-class--core-foundation)
3. [Position System](#3-position-system)
4. [Panel System](#4-panel-system)
5. [Button System](#5-button-system)
6. [Scrollbar System](#6-scrollbar-system)
7. [Textbox System](#7-textbox-system)
8. [HotkeyBox System](#8-hotkeybox-system)
9. [UI Class — Global Input & Rendering](#9-ui-class--global-input--rendering)
10. [GameUI Class — In-Game Specializations](#10-gameui-class--in-game-specializations)
11. [Modal Dialog System](#11-modal-dialog-system)
12. [Event Flow & Input Processing](#12-event-flow--input-processing)
13. [Code Examples](#13-code-examples)

---

## 1. Architecture Overview

CorsixTH's UI system is built around a **hierarchical window composition model** with three primary classes:

| Class | File | Purpose |
|-------|------|---------|
| `Window` | `window.lua` | Base class for all dialogs; manages panels, buttons, scrollbars, textboxes, hotkeyboxes, child windows |
| `UI` | `ui.lua` | Top-level container (subclass of `Window`); global key handlers, cursor management, tooltip system, modal window tracking |
| `GameUI` | `game_ui.lua` | In-game specialization (subclass of `UI`); map rendering, zoom/scroll/shake, world hit-testing, tutorial system |

```
GameUI (root)
├── UI (base)
│   └── Window (base)
│       ├── panels[]      — sprite/color/bevel panels
│       ├── buttons[]     — clickable regions on panels
│       ├── scrollbars[]  — slider + base panel
│       ├── textboxes[]   — text input fields
│       ├── hotkeyboxes[] — key binding capture fields
│       ├── tooltip_regions[] — custom tooltip areas
│       └── windows[]     — child windows (modal/non-modal)
```

**Key Design Principles:**
- **Composition over inheritance**: Windows are built from panels; buttons/scrollbars/textboxes are *created on panels*
- **Event delegation**: Child windows receive events first (top-down), then parent
- **Resolution independence**: Position system supports absolute, negative (right/bottom anchored), and fractional (0–1) coordinates
- **UI scale awareness**: All drawing/hit-testing respects `ui_scale` config

---

## 2. Window Class — Core Foundation

### 2.1 Constructor & Core Fields

```lua
function Window:Window()
  self.x = 0                    -- screen X (pixels, after setPosition)
  self.y = 0                    -- screen Y
  self.cursor_x = 0             -- cursor X relative to window
  self.cursor_y = 0             -- cursor Y relative to window
  self.panels = {}              -- array of Panel objects
  self.buttons = {}             -- array of Button objects
  self.tooltip_regions = {}     -- custom tooltip regions
  self.scrollbars = {}          -- array of Scrollbar objects
  self.textboxes = {}           -- array of Textbox objects
  self.hotkeyboxes = {}         -- array of HotkeyBox objects
  self.key_handlers = {}        -- set of registered hotkey names
  self.windows = false          -- child windows (lazy-initialized to {})
  self.active_button = false    -- currently pressed button
  self.blinking_button = false  -- index of button being blinked
  self.blink_counter = 0        -- blink animation counter
  self.panel_sprites = false    -- sprite sheet for panel drawing
  self.visible = true           -- visibility flag
  self.draggable = true         -- can user drag this window?
  self.apply_ui_scale = true    -- apply ui_scale to drawing/hit-test
  self.width = nil              -- set via setSize()
  self.height = nil
end
```

### 2.2 Window Lifecycle

| Method | Description |
|--------|-------------|
| `setSize(w, h, apply_ui_scale)` | Set dimensions; `apply_ui_scale` defaults to window's setting |
| `setPosition(x, y)` | Position using coordinate system (see §3) |
| `setDefaultPosition(x, y)` | Like `setPosition` but respects saved user position |
| `onChangeResolution()` | Recalculates position from `x_original`/`y_original` |
| `close()` | Cleanup: stops drag, removes key handlers, unregisters textboxes/hotkeyboxes, removes from parent |
| `addKeyHandler(key, handler, ...)` | Register hotkey via UI; tracks in `key_handlers` set |
| `removeKeyHandler(keys)` | Unregister hotkey |
| `mustPause()` | Override to return `true` if window should pause game (e.g., fax, annual report) |

### 2.3 Child Window Management

```lua
-- Add child window (handles z-ordering: on_top windows first)
function Window:addWindow(window)
  if window.closed then return end
  if not self.windows then self.windows = {} end
  window.parent = self
  if window.on_top then
    table.insert(self.windows, 1, window)  -- topmost
  else
    -- Insert after any on_top windows
    local pos = false
    for i = 1, #self.windows do
      if not self.windows[i].on_top then pos = i; break end
    end
    table.insert(self.windows, pos or #self.windows + 1, window)
  end
end

function Window:removeWindow(window)  -- returns bool
function Window:getWindow(window_class)  -- returns first matching child
function Window:getWindows(window_class) -- returns all matching children
```

**Z-Order Rules:**
1. `on_top = true` windows drawn first (appear on top)
2. Normal windows drawn after, in insertion order
3. `bringToTop()` / `sendToTop()` / `sendToBottom()` manipulate order

### 2.4 Drawing Pipeline

```lua
function Window:draw(canvas, x, y)
  local s = self.apply_ui_scale and TheApp.config.ui_scale or 1
  x, y = x + self.x * s, y + self.y * s
  
  -- 1. Draw panels
  for _, panel in ipairs(self.panels) do
    if panel.visible then
      if panel.custom_draw then
        panel:custom_draw(canvas, x, y)      -- ColourPanel, BevelPanel
      else
        panel_sprites_draw(panel_sprites, canvas, panel.sprite_index, 
          x + panel.x * s, y + panel.y * s, { flags=panel.draw_flags, scaleFactor=s })
      end
    end
  end
  
  -- 2. Draw textbox cursors (only for non-UI windows)
  if not class.is(self, UI) then
    for _, box in ipairs(self.textboxes) do box:drawCursor(canvas, x, y) end
  end
  
  -- 3. Draw child windows (back to front = reverse iteration)
  if self.windows then
    for i = #self.windows, 1, -1 do
      if self.windows[i].visible then
        self.windows[i]:draw(canvas, x, y)
      end
    end
  end
end
```

### 2.5 Hit Testing

```lua
function Window:hitTest(x, y)
  -- Test panels first
  for _, panel in ipairs(self.panels) do
    if self:hitTestPanel(x, y, panel) then return true end
  end
  -- Then child windows (top-down order)
  if self.windows then
    for _, child in ipairs(self.windows) do
      local s = child.apply_ui_scale and TheApp.config.ui_scale or 1
      if child:hitTest(x - child.x * s, y - child.y * s) then return true end
    end
  end
  return false
end

function Window:hitTestPanel(x, y, panel)
  local s = panel.apply_ui_scale and TheApp.config.ui_scale or 1
  local xpos, ypos = x - panel.x * s, y - panel.y * s
  if panel.visible and xpos >= 0 and ypos >= 0 then
    if panel.w and panel.h then
      return xpos <= panel.w * s and ypos <= panel.h * s  -- opaque rect test
    else
      return self.panel_sprites:hitTest(panel.sprite_index, math.floor(xpos/s), math.floor(ypos/s))
    end
  end
  return false
end
```

---

## 3. Position System

`Window:setPosition(x, y)` accepts three coordinate formats:

| Format | Range | Meaning | Example |
|--------|-------|---------|---------|
| **Absolute** | `>= 0` | Pixels from top-left of screen | `setPosition(100, 50)` |
| **Negative/Anchored** | `< 0` | Pixels from right/bottom edge | `setPosition(-200, -100)` → 200px from right, 100px from bottom |
| **Fractional** | `[0, 1)` | Fraction of available space | `setPosition(0.5, 0.5)` → centered |

**Implementation** (`window.lua:80-102`):

```lua
function Window:setPosition(x, y)
  self.x_original = x  -- saved for resolution changes
  self.y_original = y
  local w, h = TheApp.video:getRenderSize()
  if self.apply_ui_scale then
    w = w / TheApp.config.ui_scale
    h = h / TheApp.config.ui_scale
  end
  if x < 0 then
    x = math.ceil(w - self.width + x)      -- right-anchored
  elseif x < 1 then
    x = math.floor((w - self.width) * x + 0.5)  -- fractional
  end
  if y < 0 then
    y = math.ceil(h - self.height + y)     -- bottom-anchored
  elseif y < 1 then
    y = math.floor((h - self.height) * y + 0.5)
  end
  self.x, self.y = x, y
end
```

**Special Note:** Use `-0.1` to mean exactly `0` (since `0` is fractional center).

**Drag Position Representation** (`window.lua:1777-1799`):

When dragging with Ctrl held, positions snap to fractional grid (0.1 increments). The helper `getNicestPositionRepresentation` converts absolute drag position to the "nicest" representation (fractional if centered, absolute if near edges).

---

## 4. Panel System

### 4.1 Panel Class

```lua
class "Panel"
function Panel:Panel()
  self.window = nil
  self.x = nil; self.y = nil
  self.w = nil; self.h = nil      -- if set, enables fast opaque hit-test
  self.colour = nil               -- mapped RGB for ColourPanel/BevelPanel
  self.custom_draw = nil          -- function(canvas, x, y) for custom rendering
  self.visible = true
  self.wrap_text = false
  self.apply_ui_scale = true
  self.draw_flags = nil           -- sprite draw flags
  self.sprite_index = nil         -- for sprite panels
end
```

### 4.2 Panel Factory Methods (on Window)

| Method | Description |
|--------|-------------|
| `addPanel(sprite_index, x, y, w, h, apply_ui_scale, draw_flags)` | Sprite panel from sheet |
| `addColourPanel(x, y, w, h, r, g, b, apply_ui_scale)` | Solid color rectangle |
| `addBevelPanel(x, y, w, h, colour, highlight, shadow, disabled, lowered, apply_ui_scale)` | 3D beveled panel |

**Panel → Component Factories** (on `Panel` instance):

```lua
panel:makeButton(...)      -- Window:makeButtonOnPanel(self, ...)
panel:makeToggleButton(...)
panel:makeRepeatButton(...)
panel:makeScrollbar(...)
panel:makeTextbox(...)
panel:makeHotkeyBox(...)
```

### 4.3 Panel Properties & Methods

```lua
panel:setPosition(x, y)
panel:setSize(w, h)
panel:setVisible(bool)
panel:setTooltip(text, tooltip_x, tooltip_y)
panel:setDynamicTooltip(callback, tooltip_x, tooltip_y)
panel:setLabel(text, font, align)      -- "left"/"center"/"right"
panel:setAutoClip(bool)                -- truncate with "..." if too wide
panel:setTextWrap(bool)                -- multi-line wrapping
panel:clipLine(line, limit_px)         -- returns clipped line
panel:drawLabel(canvas, x, y, limit)   -- draws label, returns end y,x
panel:setColour({r,g,b}, preserve_disable)  -- ColourPanel/BevelPanel only
```

### 4.4 Custom Draw Functions

**Colour Panel** (`window.lua:419-425`):
```lua
function panel_colour_draw(panel, canvas, x, y)
  local s = panel.apply_ui_scale and TheApp.config.ui_scale or 1
  canvas:drawRect(panel.colour, x + panel.x*s, y + panel.y*s, panel.w*s, panel.h*s)
  if panel.label then panel:drawLabel(canvas, x, y) end
end
```

**Bevel Panel** (`window.lua:456-471`):
```lua
function panel_bevel_draw(panel, canvas, x, y)
  local s = panel.apply_ui_scale and TheApp.config.ui_scale or 1
  if panel.lowered then
    -- Sunken: highlight top/left, shadow bottom/right, lowered center
  else
    -- Raised: shadow top/left, highlight bottom/right, normal center
  end
  if panel.label then panel:drawLabel(canvas, x, y) end
end
```

---

## 5. Button System

### 5.1 Button Class

```lua
class "Button"
function Button:Button()
  self.ui = nil
  self.is_toggle = false
  self.is_repeat = false
  self.x = nil; self.y = nil
  self.r = nil; self.b = nil        -- right, bottom (x+w, y+h)
  self.panel_for_sprite = nil       -- panel whose sprite changes on press
  self.sprite_index_normal = nil
  self.sprite_index_disabled = nil
  self.sprite_index_active = nil    -- when pressed
  self.panel_lowered_normal = false
  self.panel_lowered_active = true
  self.on_click = nil               -- function(self_or_window, toggle_state, button)
  self.on_click_self = nil          -- first arg to on_click
  self.on_rightclick = nil
  self.enabled = true
  self.toggled = false
  self.sound = nil
end
```

### 5.2 Button Creation

```lua
-- Window:makeButtonOnPanel(panel, x, y, w, h, sprite_active, on_click, on_click_self, on_rightclick)
local button = {
  ui = self.ui,
  x = x + panel.x,  y = y + panel.y,
  r = x + panel.x + w,  b = y + panel.y + h,
  panel_for_sprite = panel,
  sprite_index_normal = panel.sprite_index,
  sprite_index_disabled = panel.sprite_index,
  sprite_index_active = sprite_active,
  on_click = on_click,
  on_click_self = on_click_self or self,
  on_rightclick = on_rightclick,
  enabled = true,
  panel_lowered_normal = false,
  panel_lowered_active = true,
}
```

**Button Modifiers:**
- `button:makeToggle()` → `is_toggle=true`, toggles sprite on click
- `button:makeRepeat()` → `is_repeat=true`, fires repeatedly while held
- `button:enable(bool)` → enables/disables, swaps sprite to `sprite_index_disabled`
- `button:setDisabledSprite(index)`
- `button:setSound(name)` → plays on click
- `button:setTooltip(text, x, y)` / `setDynamicTooltip(callback, x, y)`
- `button:setLabel(text, font, align)` → delegates to panel
- `button:preservePanel()` → creates new panel, detaches from original

### 5.3 Button Click Handling

```lua
function Button:handleClick(mouse_button)
  local arg = nil
  if self.is_toggle then arg = self:toggle() end  -- returns new state
  if self.sound then self.ui:playSound(self.sound) end
  local callback = mouse_button == "left" and self.on_click or self.on_rightclick
  if callback then callback(self.on_click_self, arg, self)
  else print("Warning: No handler for button click") end
end
```

**Repeat Buttons:** On `MouseDown`, fires once immediately, then every 2 ticks (`btn_repeat_delay` in Window).

### 5.4 Button Hit Testing & State (in `Window:onMouseDown` / `onMouseUp` / `onMouseMove`)

```lua
-- On MouseDown: find button under cursor, set sprite_index_active, lowered=true
-- On MouseMove: if mouse leaves button, revert to normal; if enters another, switch
-- On MouseUp: if still over same button, fire handleClick(); always revert sprite
```

---

## 6. Scrollbar System

### 6.1 Scrollbar Class

```lua
class "Scrollbar"
function Scrollbar:Scrollbar()
  self.base = nil      -- base panel (track)
  self.slider = nil    -- slider panel (BevelPanel)
  self.min_value = nil
  self.max_value = nil
  self.value = nil     -- current value
  self.page_size = nil -- visible items
  self.direction = "y" -- or "x"
  self.visible = true
  self.enabled = true
  self.callback = nil  -- function() called on value change
end
```

### 6.2 Creation & Range

```lua
-- Window:makeScrollbarOnPanel(panel, slider_colour, callback, min, max, page_size, value)
local slider = self:addBevelPanel(panel.x+1, panel.y+1, panel.w-2, panel.h-2, slider_colour)
local scrollbar = {
  base = panel, slider = slider, direction = "y", callback = callback, visible=true, enabled=true
}
slider.min_x, slider.min_y = slider.x, slider.y
slider.max_w, slider.max_h = slider.w, slider.h
scrollbar:setRange(min, max, page_size, value)
```

**setRange** (`window.lua:851-877`):
```lua
function Scrollbar:setRange(min_value, max_value, page_size, value)
  page_size = math.min(page_size, max_value - min_value + 1)
  value = math.min(value or min_value, math.max(min_value, max_value - page_size + 1))
  self.min_value, self.max_value, self.page_size, self.value = min_value, max_value, page_size, value
  
  -- Resize slider proportionally
  if self.direction == "y" then
    slider.h = math.ceil((page_size / (max_value - min_value + 1)) * slider.max_h)
    slider.max_y = slider.min_y + slider.max_h - slider.h
    slider.y = math.floor((value - min_value) / (max_value - min_value - page_size + 2) * (slider.max_y - slider.min_y) + slider.min_y)
  else
    -- horizontal analogous
  end
end
```

### 6.3 Interaction

- `onMouseDown` on slider → `active_scrollbar`, tracks `down_x`/`down_y`
- `onMouseMove` → `setXorY()` converts pixel position to value, calls `callback()`
- `onMouseUp` → clears active scrollbar

---

## 7. Textbox System

### 7.1 Textbox Class

```lua
class "Textbox"
function Textbox:Textbox()
  self.panel = nil              -- base panel (made into toggle button)
  self.confirm_callback = nil   -- on Enter/confirm
  self.abort_callback = nil     -- on Escape/abort
  self.button = nil             -- toggle button
  self.text = ""                -- string or table of lines
  self.allowed_input = {alpha=true, numbers=true, misc=true}
  self.char_limit = nil
  self.visible = true
  self.enabled = true
  self.active = false           -- has keyboard focus
  self.cursor_counter = 0
  self.cursor_state = false     -- blinking
  self.cursor_pos = {1, 1}      -- {line, col}
end
```

### 7.2 Creation

```lua
-- Window:makeTextboxOnPanel(panel, confirm_callback, abort_callback)
local textbox = { panel=panel, confirm_callback=..., abort_callback=..., text="", ... }
local button = panel:makeToggleButton(0, 0, panel.w, panel.h, nil, textbox.clicked, textbox)
textbox.button = button
self.textboxes[#self.textboxes+1] = textbox
self.ui:registerTextBox(textbox)  -- adds to UI.textboxes for global key routing
return textbox
```

### 7.3 Input Handling

**Keyboard Events** (`UI:onKeyDown` → `Textbox:keyInput`):
- Handles: letters, numbers, space/hyphen/plus (configurable via `allowedInput()`)
- Backspace / Delete (with Ctrl = word-wise)
- Enter → newline (multi-line) or confirm (single-line)
- Escape → abort
- Arrow keys, Home, End, Ctrl+Left/Right (word navigation)
- Tab → reserved (handled = true)
- Character limit enforcement

**Text Input** (`UI:onTextInput` → `Textbox:textInput`):
- Receives localized text from SDL
- Inserts at cursor position

**Activation** (`Textbox:setActive(true)`):
- Deactivates all other textboxes
- Starts text input (`TheApp:startTextInput()`)
- Sets cursor to end of text
- Toggles button visually

**Cursor Blinking** (`Textbox:onTick`):
- 40-tick cycle: 20 ticks visible, 20 ticks hidden
- Drawn via `Textbox:drawCursor(canvas, x, y)` in `Window:draw`

### 7.4 Configuration Methods

```lua
textbox:allowedInput(types)      -- "alpha", "numbers", "misc", "all"
textbox:characterLimit(n)
textbox:setText(text)            -- string or table of lines
textbox:setPosition(x, y)        -- delegates to button
textbox:setSize(w, h)            -- delegates to button
```

---

## 8. HotkeyBox System

### 8.1 HotkeyBox Class

```lua
class "HotkeyBox"
function HotkeyBox:HotkeyBox()
  -- Similar to Textbox but for capturing key combinations
  self.noted_keys = {}          -- keys pressed during capture
  -- ... same fields as Textbox ...
end
```

### 8.2 Key Capture Logic

```lua
function HotkeyBox:keyInput(char, rawchar, modifiers)
  if not self.active then return false end
  return true  -- consume all keys while active
end

function HotkeyBox:onKeyUp(rawchar, modifiers)  -- in UI
  -- Tracks keys released while active
  -- When ALL keys released → confirm() with noted_keys
  -- Escape → abort()
end
```

**Usage:** Click to activate → press key combo → release all → callback receives captured keys.

---

## 9. UI Class — Global Input & Rendering

### 9.1 Constructor & State

```lua
class "UI" (Window)
function UI:UI(app, minimal)
  self:Window()
  self:initKeyAndButtonCodes()
  self.app = app
  self.screen_offset_x = 0
  self.screen_offset_y = 0
  self.cursor = nil
  self.cursor_entity = nil
  self.tooltip_font = ...
  self.tooltip = nil
  self.tooltip_counter = 0
  self.background = false
  self.tick_scroll_amount = false
  self.tick_scroll_amount_mouse = false
  self.tick_scroll_mult = 1
  self.modal_windows = {}      -- [class_name] -> window
  self.key_handlers = {}       -- key -> { {modifiers, window, callback, ...}, ... }
  self.textboxes = {}          -- global registry (all windows)
  self.hotkeyboxes = {}        -- global registry
  self.editing_allowed = true
  -- Cursors
  self.default_cursor = ...
  self.down_cursor = ...
  self.grab_cursor = ...
  self.edit_room_cursor = ...
  self.waiting_cursor = ...
end
```

### 9.2 Key Handler System

**Registration** (`ui.lua:329-424`):
```lua
function UI:addKeyHandler(keys, window, callback, ...)
  -- keys: string from hotkeys config (e.g., "ingame_quitLevel") or raw key
  -- Resolves hotkey config, supports modifier+key tables
  -- Handles enter/return, +/- equivalence
  -- Stores in self.key_handlers[key] = array of {modifiers=set, window, callback, args...}
end
```

**Matching** (`ui.lua:768-778`):
```lua
local keyHandlers = self.key_handlers[key]
if keyHandlers then
  for _, handler in ipairs(keyHandlers) do
    if compare_tables(handler.modifiers, modifiers) then
      handler.callback(handler.window, unpack(handler))
      handled = true
    end
  end
end
```
- **Exact modifier match required** (no subset/superset)
- Falls back to `onTextInput` for layout-dependent keys

### 9.3 Cursor Management

```lua
function UI:setCursor(cursor)
  if cursor ~= self.cursor then
    self.cursor = cursor
    if cursor.use then
      -- Hardware/OS cursor
      self.simulated_cursor = nil
      WM.showCursor(true)
      cursor:use(self.app.video)
    else
      -- Software cursor (sprite)
      WM.showCursor(self.mouse_released)
      self.simulated_cursor = cursor
    end
  end
end
```

**Cursor Types:** `default`, `clicked` (down), `grab`, `edit_room`, `sleep` (waiting), epidemic variants.

### 9.4 Tooltip System

```lua
function UI:updateTooltip()
  if self.buttons_down.mouse_left then
    self.tooltip = nil; self.tooltip_counter = nil; return
  elseif self.tooltip_counter == nil then
    self.tooltip_counter = 30  -- ticks until show
  end
  local tooltip = self:getTooltipAt(self.cursor_x, self.cursor_y)
  if tooltip then self.tooltip = tooltip
  else self.tooltip = nil; self.tooltip_counter = 30 end
end
```

- 30-tick delay (~540ms at 55Hz) before showing
- Disabled while left mouse held
- Dynamic tooltips (callbacks) evaluated each tick when visible
- Priority: Button > Region > Panel

### 9.5 Modal Window Tracking

```lua
self.modal_windows = {}  -- [modal_class] -> window

function UI:addWindow(window)
  if window.modal_class then
    while self.modal_windows[window.modal_class] do
      self.modal_windows[window.modal_class]:close()  -- close existing
    end
    self.modal_windows[window.modal_class] = window
  end
  if window.modal_class == "main" or window.modal_class == "fullscreen" then
    self.editing_allowed = false  -- block room editing
  end
  Window.addWindow(self, window)
end
```

- Only one window per `modal_class` allowed
- `modal_class = "main"` or `"fullscreen"` → disables room editing

### 9.6 Drawing

```lua
function UI:draw(canvas)
  -- 1. Background (main menu)
  if self.background then ... end
  -- 2. All windows (via Window.draw)
  Window.draw(self, canvas, 0, 0)
  -- 3. Tooltip
  self:drawTooltip(canvas)
  -- 4. Simulated cursor
  if self.simulated_cursor then self.simulated_cursor.draw(canvas, self.cursor_x, self.cursor_y) end
end
```

---

## 10. GameUI Class — In-Game Specializations

### 10.1 Constructor

```lua
function GameUI:GameUI(app, local_hospital, map_editor)
  self:UI(app, false)
  self.hospital = local_hospital
  if map_editor then
    self.map_editor = UIMapEditor(self); self:addWindow(self.map_editor)
  else
    self.adviser = UIAdviser(self)
    self.bottom_panel = UIBottomPanel(self)
    self.bottom_panel:addWindow(self.adviser)
    self:addWindow(self.bottom_panel)
  end
  self.menu_bar = UIMenuBar(self, self.map_editor); self:addWindow(self.menu_bar)
  self.subtitles = Subtitles(self); self:addWindow(self.subtitles)
  
  -- Camera / zoom
  local scr_w, scr_h = app.video:getRenderSize()
  self.visible_diamond = self:makeVisibleDiamond(scr_w, scr_h)
  self.screen_offset_x, self.screen_offset_y = app.map:WorldToScreen(
    app.map.th:getCameraTile(local_hospital:getPlayerIndex()))
  self.zoom_factor = 1
  self:scrollMap(-scr_w/2, 16 - scr_h/2)
  self.limit_to_visible_diamond = not self.map_editor
  self.transparent_walls = false
  self.do_world_hit_test = true
  
  -- Momentum scrolling
  self.momentum = app.config.scrolling_momentum
  self.current_momentum = {x=0, y=0, z=0}
  self.tick_scroll_mult = 1
  
  self.announcer = Announcer(app)
  self.app:setCaptureMouse()
end
```

### 10.2 Zoom System

```lua
function GameUI:setZoom(factor)
  if factor <= 0 or math.abs(factor-1) < 0.001 then factor = 1 end
  local scr_w, scr_h = TheApp.video:getRenderSize()
  local new_diamond = self:makeVisibleDiamond(scr_w/factor, scr_h/factor)
  if new_diamond.w < 0 or new_diamond.h < 0 then return false end
  
  self.visible_diamond = new_diamond
  local refx, refy = self.cursor_x or scr_w/2, self.cursor_y or scr_h/2
  local cx, cy = self:ScreenToWorld(refx, refy)
  self.zoom_factor = factor
  cx, cy = self.app.map:WorldToScreen(cx, cy)
  cx = cx - self.screen_offset_x - refx/factor
  cy = cy - self.screen_offset_y - refy/factor
  self:scrollMap(cx, cy)
  return true
end
```

**Minimum Zoom** (`game_ui.lua:197-210`):
```lua
function GameUI:calculateMinimumZoom()
  local scr_w, scr_h = TheApp.video:getRenderSize()
  local map_h = self.app.map.height
  local factor = (scr_w + 2*scr_h) / (64 * map_h) + 0.001
  return factor
end
```

### 10.3 Scrolling & Momentum

**Mouse Drag Scroll** (middle/right button):
```lua
function GameUI:onMouseMove(x, y, dx, dy)
  if self:_isMouseScrollButtonDown() then
    local zoom = self.zoom_factor
    self.current_momentum.x = self.current_momentum.x - dx/zoom
    self.current_momentum.y = self.current_momentum.y - dy/zoom
    self.current_momentum.z = 0  -- stop zoom
    self:scrollMap(math.round(self.current_momentum.x), math.round(self.current_momentum.y))
    -- preserve fractional remainder
  end
end
```

**Edge Scrolling**:
```lua
local scroll_region_size = self.app.config.fullscreen and 1 or 8
if x < scroll_region_size then scroll_dx = -7
elseif x >= scr_w - scroll_region_size then scroll_dx = 7 end
-- similar for y
self.tick_scroll_amount_mouse = {x=scroll_dx, y=scroll_dy}
```

**Keyboard Scroll** (`updateKeyScroll`):
```lua
for key, scr in pairs(self.scroll_keys) do
  if self.buttons_down[key] then dx=dx+scr.x; dy=dy+scr.y end
end
if dx~=0 or dy~=0 then
  local mag = math.sqrt(dx^2+dy^2)
  dx, dy = (dx/mag)*10, (dy/mag)*10  -- normalized * key_scroll_speed
  self.tick_scroll_amount = {x=dx, y=dy}
end
```

**Tick Processing** (`onTick`):
```lua
-- Momentum decay
if not mouse_scroll_down then
  if |momentum| < 0.2 then momentum=0
  else momentum = momentum * self.momentum; scrollMap(momentum) end
  if |momentum.z| > 0.2 then adjustZoom(momentum.z) end
  momentum.z = momentum.z * self.momentum
end

-- Accelerated continuous scroll
if tick_scroll_amount or tick_scroll_amount_mouse then
  mult = mult + 0.02 (capped at 2)
  if shift_held then mult *= config.shift_scroll_speed * 0.25
  else mult *= config.scroll_speed * 0.25 end
  scrollMap(dx*mult, dy*mult)
else mult = 1 end
```

### 10.4 Screen Shake

```lua
function GameUI:beginShakeScreen(intensity)
  self.shake_screen_intensity = self.app.config.enable_screen_shake and intensity or 0
end

function GameUI:endShakeScreen()
  self.shake_screen_intensity = 0
end

-- In draw():
local dx = self.screen_offset_x + math.floor((0.5-math.random()) * intensity * 50 * 2)
local dy = self.screen_offset_y + math.floor((0.5-math.random()) * intensity * 50 * 2)
```

### 10.5 World Hit Testing & Cursor Feedback

```lua
function GameUI:onCursorWorldPositionChange()
  local zoom = self.zoom_factor
  local x = math.floor(self.screen_offset_x + self.cursor_x/zoom)
  local y = math.floor(self.screen_offset_y + self.cursor_y/zoom)
  local overwindow = self:hitTest(self.cursor_x, self.cursor_y)
  
  if self.do_world_hit_test and not overwindow then
    entity = self.app.map.th:hitTestObjects(x, y)
    -- Optional: limit to room non-door objects
  end
  
  -- Cursor updates based on entity type, epidemic state, editing mode
  -- Queue mood indicators for patients
  -- Dynamic info panel updates
end
```

### 10.6 Tutorial System

```lua
self.tutorial = { chapter = 0, phase = 0 }
tutorial_phases = {
  { -- Chapter 1: Build Reception
    { text=..., begin_callback=..., end_callback=... },
    ...
  },
  ...
}

function GameUI:tutorialStep(chapter, phase_from, phase_to, ...)
  -- Validates current chapter/phase
  -- Runs end_callback of old phase
  -- Updates chapter/phase
  -- Runs begin_callback of new phase
  -- Shows adviser text
end
```

### 10.7 Map Recall Positions

```lua
function GameUI:setMapRecallPosition(index)
  local scr_w, scr_h = TheApp.video:getRenderSize()
  local cx, cy = self:ScreenToWorld(scr_w/2, scr_h/2)
  self.recallpositions[index] = {x=cx, y=cy, z=self.zoom_factor}
end

function GameUI:recallMapPosition(index)
  if self.recallpositions[index] then
    self:setZoom(self.recallpositions[index].z)
    self:scrollMapTo(...)
  end
end
```

---

## 11. Modal Dialog System

### 11.1 Modal Classes

| Modal Class | Purpose | Blocks Editing |
|-------------|---------|----------------|
| `"main"` | Build, Furnish, Hire windows | Yes |
| `"fullscreen"` | Full-screen dialogs | Yes |
| Custom | Disease info, confirmations, etc. | No (unless coded) |

### 11.2 Enforcement

```lua
-- In UI:addWindow
if window.modal_class then
  while self.modal_windows[window.modal_class] do
    self.modal_windows[window.modal_class]:close()
  end
  self.modal_windows[window.modal_class] = window
end
if window.modal_class == "main" or window.modal_class == "fullscreen" then
  self.editing_allowed = false
end
```

### 11.3 Input Blocking

- Modal windows are added to `UI.windows` like normal windows
- Hit testing checks child windows first (top-down)
- `editing_allowed` flag checked by room editing code
- No automatic keyboard/mouse blocking — relies on z-order and hit-test

---

## 12. Event Flow & Input Processing

### 12.1 Event Entry Points (from C++/SDL)

| Event | UI Method | GameUI Override |
|-------|-----------|-----------------|
| Key Down | `UI:onKeyDown(rawchar, modifiers)` | `GameUI:onKeyDown` (calls super, then handles scroll keys) |
| Key Up | `UI:onKeyUp(rawchar, modifiers)` | `GameUI:onKeyUp` (calls super, handles shift scroll release) |
| Text Input | `UI:onTextInput(text)` | — |
| Mouse Down | `UI:onMouseDown(code, x, y)` | `GameUI:onMouseDown` (not overridden) |
| Mouse Up | `UI:onMouseUp(code, x, y)` | `GameUI:onMouseUp` (handles edit room, vaccination) |
| Mouse Move | `UI:onMouseMove(x, y, dx, dy)` | `GameUI:onMouseMove` (world hit-test, edge scroll, drag scroll) |
| Mouse Wheel | `UI:onMouseWheel(x, y)` | `GameUI:onMouseWheel(x, y, touch, flipped)` (zoom) |
| Pinch Begin/Update/End | `UI:onPinchBegin/Update/End` | `GameUI:onPinchBegin/Update/End` (zoom momentum) |
| Window Focus | `UI:onWindowActive(gain)` | `GameUI:onWindowActive` (clears edge scroll) |
| Window Resize | `UI:onWindowResized(w, h)` | — |
| Tick | `UI:onTick()` | `GameUI:onTick()` (momentum, scroll, announcer) |

### 12.2 Key Down Flow

```
UI:onKeyDown(rawchar, modifiers)
  → _determineKeyPressed() → (rawchar_transformed, key)
  → For each active textbox: box:keyInput(key, rawchar) → handled?
  → For each active hotkeybox: box:keyInput(key, rawchar, modifiers) → handled?
  → If not handled: lookup key_handlers[key]
       → For each handler: if modifiers match exactly → callback(window, ...)
  → Store buttons_down[key] = true, modifiers_down = modifiers
```

### 12.3 Mouse Down Flow

```
UI:onMouseDown(code, x, y)
  → setMouseReleased(false)
  → If movie playing: stop on left click
  → Update cursor (down_cursor)
  → Window:onMouseDown(button, x, y)
       → For each child window (top-down): child:onMouseDown(...)
       → If not handled: check buttons under cursor
            → Set sprite_index_active, lowered=true, active_button=btn
            → If repeat button: fire once, set btn_repeat_delay=10
       → Check scrollbars under cursor → active_scrollbar
       → If hitTest(window) and left click: beginDrag()
  → updateTooltip()
```

### 12.4 Mouse Move Flow

```
UI:onMouseMove(x, y, dx, dy)  /  GameUI:onMouseMove
  → Update cursor position
  → If drag_mouse_move: call it (window dragging)
  → Window:onMouseMove(x, y, dx, dy)
       → Propagate to child windows
       → Update active_button highlight (enter/leave)
       → Update active_scrollbar position
  → updateTooltip()
  → GameUI: onCursorWorldPositionChange() (entity hover, cursor update)
  → GameUI: Edge scroll detection → tick_scroll_amount_mouse
  → GameUI: Middle/right drag → momentum scroll
```

### 12.5 Tick Flow

```
UI:onTick()
  → tooltip_counter countdown
  → Window:onTick()
       → Repeat button handling (btn_repeat_delay)
       → Blinking button animation
       → Textbox cursor blink (onTick per textbox)
       → Child window onTick

GameUI:onTick() (extends UI)
  → Momentum decay & scroll
  → Zoom momentum
  → Accelerated tick_scroll (keyboard + mouse edge)
  → onCursorWorldPositionChange()
  → Announcer tick
```

---

## 13. Code Examples

### 13.1 Creating a Simple Dialog Window

```lua
class "MyDialog" (Window)

function MyDialog:MyDialog(ui)
  self:Window()
  self.ui = ui
  self:setSize(400, 300)
  self:setDefaultPosition(0.5, 0.5)  -- centered
  
  -- Load sprite sheet
  self.panel_sprites = ui.app.gfx:loadSpriteTable("MyDialog", "my_dialog")
  
  -- Background panel
  local bg = self:addPanel(0, 0, 0, 400, 300)
  
  -- Title panel
  local title = self:addPanel(1, 10, 10)
  title:setLabel("My Dialog", ui.app.gfx:loadFontAndSpriteTable("QData", "Font01V"), "center")
  
  -- Close button
  local close_btn = bg:makeButton(360, 10, 30, 30, 2, function() self:close() end)
  close_btn:setTooltip("Close")
  
  -- Action button
  local action_btn = bg:makeButton(150, 250, 100, 30, 3, function()
    print("Action clicked!")
  end)
  action_btn:setLabel("Do Action")
  
  -- Make modal
  self.modal_class = "main"
end

-- Usage
ui:addWindow(MyDialog(ui))
```

### 13.2 Creating a Scrollable List

```lua
function MyDialog:createList(items)
  local list_panel = self:addPanel(0, 20, 50, 360, 200)
  list_panel:setSize(360, 200)
  
  -- Scrollbar track panel
  local scroll_track = self:addPanel(4, 380, 50, 20, 200)
  
  local scrollbar = self:makeScrollbarOnPanel(scroll_track, 
    {red=100, green=100, blue=100},  -- slider color
    function() self:refreshList() end,  -- callback
    1, #items, 10, 1  -- min, max, page_size, value
  )
  
  self.list_items = items
  self.list_scrollbar = scrollbar
  self.list_panel = list_panel
end

function MyDialog:refreshList()
  local value = self.list_scrollbar.value
  local page = self.list_scrollbar.page_size
  local y = 0
  for i = value, math.min(value + page - 1, #self.list_items) do
    local item = self.list_items[i]
    -- Draw item at y position...
    y = y + 20
  end
end
```

### 13.3 Textbox with Validation

```lua
local name_panel = self:addColourPanel(50, 100, 200, 30, 50, 50, 50)
local textbox = self:makeTextboxOnPanel(name_panel,
  function()  -- confirm
    local name = textbox.text
    if name ~= "" then
      print("Name entered:", name)
      self:close()
    end
  end,
  function()  -- abort
    print("Cancelled")
  end
)

textbox:allowedInput({"alpha", "misc"})  -- letters, space, hyphen
textbox:characterLimit(30)
textbox:setText("Player Name")
```

### 13.4 Hotkey Capture Box

```lua
local hk_panel = self:addBevelPanel(50, 150, 200, 30, {red=80,green=80,blue=80})
local hotkeybox = self:makeHotkeyBoxOnPanel(hk_panel,
  function()  -- confirm
    print("Hotkey set to:", table.concat(hotkeybox.noted_keys, "+"))
  end,
  function() print("Cancelled") end
)
hotkeybox:setText("Click and press keys...")
```

### 13.5 Registering Global Hotkeys

```lua
function MyWindow:MyWindow(ui)
  self:Window()
  self.ui = ui
  -- Register Escape to close
  self:addKeyHandler("global_cancel", self, self.close)
  -- Register custom hotkey (must exist in hotkeys.txt config)
  self:addKeyHandler("my_custom_action", self, function()
    print("Custom action!")
  end)
end

function MyWindow:close()
  self:removeKeyHandler("global_cancel")
  self:removeKeyHandler("my_custom_action")
  Window.close(self)
end
```

### 13.6 Custom Tooltip Region

```lua
-- Static tooltip region
self:makeTooltip("This area shows helpful info", 10, 10, 200, 50)

-- Dynamic tooltip (evaluated on hover)
self:makeDynamicTooltip(function(x, y)
  local entity = self.ui:getEntityAt(x, y)
  if entity then return entity:getDescription() end
  return nil
end, 10, 70, 200, 100)
```

### 13.7 Draggable Window with Saved Position

```lua
function MyWindow:MyWindow(ui)
  self:Window()
  self.ui = ui
  self:setSize(300, 200)
  self:setDefaultPosition(0.1, 0.1)  -- default top-left
  self.draggable = true  -- default
  
  function self:getSavedWindowPositionName()
    return "MyWindow"  -- shared across instances
  end
end
```

### 13.8 GameUI: Zoom to Cursor

```lua
function GameUI:zoomAtCursor(delta)
  local new_zoom = self.zoom_factor + delta
  new_zoom = math.max(self:calculateMinimumZoom(), math.min(4, new_zoom))
  self:setZoom(new_zoom)
end

-- Mouse wheel handler (in GameUI:onMouseWheel)
if not inside_window then
  self.current_momentum.z = self.current_momentum.z + y
end
```

### 13.9 Screen Shake Trigger

```lua
-- Earthquake event
ui:beginShakeScreen(0.5)  -- half intensity
-- Later:
ui:endShakeScreen()
```

### 13.10 Modal Confirmation Dialog Pattern

```lua
class "UIConfirmDialog" (Window)
function UIConfirmDialog:UIConfirmDialog(ui, title, message, on_confirm, on_cancel)
  self:Window()
  self.ui = ui
  self:setSize(400, 150)
  self:setDefaultPosition(0.5, 0.5)
  self.modal_class = "confirm"
  
  -- ... build UI ...
  
  local yes_btn = panel:makeButton(..., function() on_confirm(); self:close() end)
  local no_btn = panel:makeButton(..., function() if on_cancel then on_cancel() end; self:close() end)
  
  -- Escape closes = cancel
  self:addKeyHandler("global_cancel", self, function() if on_cancel then on_cancel() end; self:close() end)
end

-- Usage
ui:addWindow(UIConfirmDialog(ui, "Confirm", "Delete room?", function()
  room:delete()
end))
```

---

## Appendix: Key File Line References

| Feature | window.lua | ui.lua | game_ui.lua |
|---------|------------|--------|-------------|
| Window constructor | 33-61 | 138-198 | 50-104 |
| setPosition / coordinate system | 80-102 | — | — |
| Panel types (sprite/color/bevel) | 398-522 | — | — |
| Button creation & types | 802-831, 648-672 | — | — |
| Scrollbar | 834-940 | — | — |
| Textbox | 943-1339 | 568-579, 752-755, 848-854 | — |
| HotkeyBox | 1342-1500 | 581-592, 759-763, 796-834 | — |
| Key handlers | 150-159 | 329-516 | 106-174 |
| Modal windows | — | 165-167, 1079-1090 | — |
| Cursor management | — | 255-284, 455-472 | 455-472 |
| Tooltip system | 2026-2128 | 286-300, 948-966 | — |
| Drag & drop | 1805-1841, 1699-1718 | — | — |
| Zoom | — | — | 212-236 |
| Scrolling/momentum | — | — | 308-330, 827-897 |
| Screen shake | — | — | 973-984 |
| World hit-test | — | 927-940 | 424-546 |
| Tutorial | — | — | 1033-1222 |
| Map recall positions | — | — | 1226-1242 |
| Drawing pipeline | 1509-1549 | 302-320 | 238-261 |
| Hit testing | 1571-1631 | — | 768-777 |
| Mouse event handlers | 1633-1754, 1851-1906 | 872-921, 1013-1035 | 562-663, 665-736 |
| onTick | 1909-1945 | 1058-1070 | 827-897 |

---

*End of Document*
