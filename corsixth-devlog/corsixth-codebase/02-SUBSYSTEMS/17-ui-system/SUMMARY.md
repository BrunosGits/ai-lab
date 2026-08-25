# UI System - Technical Summary

## Overview
The UI system in CorsixTH is built on a custom window/widget framework implemented entirely in Lua. It handles all game interfaces: main menu, in-game HUD, dialogs, and editor tools.

**Key Files:**
- `Lua/window.lua` (2185 lines) - Core widget framework
- `Lua/ui.lua` - UI class (input handling, cursor, modal management)
- `Lua/game_ui.lua` - GameUI class (in-game HUD, map interaction)

---

## Core Classes

### Window (`window.lua:24`)
Root widget class. All UI elements inherit from this.

**Key Fields:**
```lua
x, y, width, height          -- Position/size (supports absolute, negative=right/bottom, fractional)
panels, buttons, tooltip_regions, scrollbars, textboxes, hotkeyboxes, windows  -- Child widgets
visible, draggable, modal_class  -- Behavior flags
panel_sprites                 -- Background sprites
```

**Key Methods:**
- `setSize(w, h)`, `setPosition(x, y)` - Layout
- `draw()` - Render (calls children in order)
- `onMouseUp/Down/Move()`, `onKeyDown/Up()` - Input events
- `addWindow(child)`, `removeWindow(child)` - Child management
- `addPanel()`, `addButton()`, `addScrollbar()`, `addTextbox()`, `addHotkeybox()` - Widget factory
- `hitTest(x, y)` - Mouse collision
- `close()` - Cleanup (unregisters handlers, removes from parent)

**Position System (`window.lua:80-101`):**
- `>= 0`: Absolute pixels from left/top
- `< 0`: Pixels from right/bottom edge
- `[0, 1)`: Fractional of parent size

---

### Panel (`window.lua:168`)
Visual container. Supports color, sprite, lowered/raised appearance.

**Fields:** `x, y, w, h, colour, lowered, visible, sprite, sprite_index`

---

### Button (`window.lua:594`)
Interactive button with tooltip, sound, enable/disable state.

**Fields:** `x, y, w, h, tooltip, on_click, enable, sound_done, visible`

**Events:** `onMouseUp()`, `onMouseDown()`

---

### Scrollbar (`window.lua:834`)
Vertical/horizontal scrollbar with thumb dragging.

**Fields:** `x, y, range, value, thumb_x, thumb_y, pressed`
**Methods:** `setRange()`, `setValue()`, `getValue()`

---

### Textbox (`window.lua:943`)
Text input with caret, focus, selection.

**Fields:** `x, y, text, font, caret, focused, enabled, panel`

---

### HotkeyBox (`window.lua:1342`)
Key binding display/edit.

---

### UI (`ui.lua:24`) - extends Window
Application-level UI manager.

**Key Fields:**
```lua
app                              -- App reference
key_handlers, key_remaps, button_remaps  -- Input mapping
cursor_x, cursor_y, buttons_down -- Mouse state
modal_window                     -- Active modal dialog
bottom_menu_visible, blue_filter_active
```

**Key Methods:**
- `dispatch()` - Main event loop
- `draw()` - Render all windows
- `playSound()`, `playAnnouncement()`
- `addWindow()`, `removeWindow()`
- `addKeyHandler(key, handler)` - Global hotkeys
- `setCursorPosition(x, y)`, `getMouseXY()`

---

### GameUI (`game_ui.lua:25`) - extends UI
In-game HUD and map interaction.

**Key Fields:**
```lua
hospital, tutorial, adviser, bottom_panel, menu_bar, subtitles
visible_diamond, scrolling, map_editor, announcer
```

**Key Methods:**
- `draw()` - World + UI rendering
- `onTick()` - Per-tick UI updates
- `onMouseMove/Down/Up()`, `onKeyDown/Up()`
- `setZoom()`, `scrollMap()`, `shakeScreen()`
- `togglePlayerSpeed()`, `playWatchAnnouncement()`

---

## Dialog Hierarchy

All dialogs extend `Window` (or `UIFullscreen`/`UIResizable`):

```
Window
├── UIAdviser, UIBottomPanel, UIBuildRoom, UIConfirmDialog
├── UIFurnishCorridor, UIHireStaff, UIInformation, UIJukebox
├── UIMachine, UIMenuBar, UIPatient, UIPlaceObjects, UIPlaceStaff
├── UIQueue, UIQueuePopup, UIStaff, UIStaffRise, UIWatch
├── Subtitles, UIMessage, UIHotkeyAssignKeyPane, TreeControl
├── UIFullscreen
│   ├── UIAnnualReport, UIBankManager, UICasebook, UIFax
│   ├── UIGraphs, UIPolicy, UIProgressReport, UIResearch
│   ├── UIStaffManagement, UITownMap
├── UIResizable
│   ├── UIAdviserHistory, UICallsDispatcher, UICheats, UICustomise
│   ├── UIDirectoryBrowser, UIDropdown, UIFileBrowser, UIFolder
│   ├── UIHotkeyAssign, UILuaConsole, UIMachineMenu, UIMainMenu
│   ├── UIMapEditor, UIMenuList, UINewGame, UIOptions
│   ├── UIResolution, UIScrollSpeed, UIShiftScrollSpeed, UIZoomSpeed
│   ├── UISoundSettings, UITipOfTheDay, UIUpdate
│   └── UIFileBrowser → UIChooseFont, UIChooseSoundfont, UILoadGame, UILoadMap, UISaveGame, UISaveMap
│   └── UIMenuList → UICustomCampaign, UICustomGame, UIMakeDebugPatient
└── UIPlaceObjects → UIEditRoom
```

---

## Modal System
- `modal_window` field tracks active modal
- Modal dialogs block input to windows behind them
- `close()` properly cleans up modal state

---

## Input Handling
- `key_handlers` map: `key -> handler function`
- `key_remaps`/`button_remaps` for customization
- Mouse: `buttons_down` table tracks `mouse_left`, `mouse_middle`, `mouse_right`
- Hotkeys: `HotkeyBox` widget for rebinding

---

## Rendering
- `draw()` called per frame
- Panels draw sprites/colors
- Buttons draw state (normal/hover/pressed)
- Textboxes render text + caret
- Scrollbars render track + thumb
- Child windows rendered in z-order

---

## Common Bug Patterns
1. **Modal stack corruption** - Not cleaning up `modal_window` on close
2. **Position calculation errors** - Fractional vs absolute confusion
3. **Event handler leaks** - Not unregistering handlers on close
3. **Z-order issues** - `addWindow` order determines draw order
4. **Textbox focus loss** - Click outside should blur
5. **Scrollbar thumb sync** - Value/range mismatch
6. **Hotkey conflicts** - Duplicate key bindings

## Related Pages

- [[17-ui-system/CHECKLIST]]
- [[17-ui-system/MAP]]
- [[17-ui-system/SCAFFOLD]]
