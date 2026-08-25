# UI System - Pre-Fix Checklist

## Overview
This checklist ensures safe changes to the UI system (`window.lua`, `ui.lua`, `game_ui.lua`, dialog files).

---

## 🔴 Critical (Must Verify Before Merge)

### Core Window Mechanics
- [ ] `Window:close()` properly unregisters all handlers, key handlers, textboxes, hotkeyboxes
- [ ] `Window:hitTest()` correctly handles fractional/negative positions
- [ ] `Window:setPosition()` handles all three coordinate types (absolute, negative, fractional)
- [ ] Child window management (`addWindow`/`removeWindow`) maintains parent references
- [ ] Modal dialog stack: `modal_window` set/cleared correctly, blocks input properly

### Input Handling
- [ ] `key_handlers` registered/unregistered correctly (no leaks)
- [ ] `buttons_down` state tracked accurately for all three mouse buttons
- [ ] `key_remaps`/`button_remaps` applied before handler dispatch
- [ ] Textbox focus gained/lost events fire correctly
- [ ] HotkeyBox rebinding works without conflicts

### Button/Interactive Elements
- [ ] Button `on_click` fires only when enabled and mouse inside bounds
- [ ] Button visual states (normal/hover/pressed) render correctly
- [ ] Scrollbar thumb position syncs with `value`/`range`
- [ ] Scrollbar dragging updates value smoothly
- [ ] Textbox caret position updates on click/key input

---

## 🟠 High (Should Verify)

### Layout & Rendering
- [ ] Panel `draw()` respects `lowered`/`visible` flags
- [ ] Button sprite indices correct for each state
- [ ] Scrollbar track/thumb sprites align
- [ ] Textbox text clipping at panel boundaries
- [ ] Window z-order: children drawn after parents, modals on top
- [ ] Fractional positions `[0,1)` scale with parent resize

### Dialog System
- [ ] `UIFullscreen` dialogs cover entire screen
- [ ] `UIResizable` dialogs respect `min_width`/`min_height`
- [ ] `UIFileBrowser` variants navigate correctly
- [ ] `UIMenuList` variants populate items correctly
- [ ] `TreeControl`/`FilteredTreeControl` expand/collapse works
- [ ] Dialog `close()` cleans up all child widgets

### GameUI Specific
- [ ] `GameUI:onTick()` updates all HUD elements
- [ ] `GameUI:scrollMap()` updates camera correctly
- [ ] `GameUI:setZoom()` clamps to valid range
- [ ] `GameUI:shakeScreen()` decays over time
- [ ] `GameUI:draw()` renders world + UI in correct order
- [ ] Bottom panel / menu bar / adviser visible toggles work

---

## 🟡 Medium (Good to Verify)

### Performance
- [ ] No widget created in `draw()` loop
- [ ] `hitTest()` called only when needed
- [ ] Modal dialogs don't render background world unnecessarily
- [ ] Textbox cursor blink uses timer, not frame counter

### Accessibility
- [ ] All buttons have tooltips
- [ ] Keyboard navigation works (Tab/Enter/Escape)
- [ ] Color contrast sufficient for lowered/raised panels
- [ ] Font scaling respects `UIScale` setting (2x/3x)

### Save/Load
- [ ] `UI:afterLoad()` restores window positions
- [ ] Modal dialog state restored correctly
- [ ] Textbox content persisted
- [ ] Key remaps survive save/load

---

## 🟢 Low (Nice to Verify)

### Code Quality
- [ ] No magic numbers (use constants from `window.lua`)
- [ ] Consistent naming: `onX` for callbacks, `addX`/`removeX` for management
- [ ] Comments for complex position calculations
- [ ] Widget factory methods return created widget

### Documentation
- [ ] New widget types documented in `window.lua` header
- [ ] Dialog subclass responsibilities clear
- [ ] Input flow documented (dispatch → handlers → widgets)

---

## Testing Requirements

### Unit Tests (Busted)
- [ ] `Window` position/size/hitTest
- [ ] `Button` click/enable/disable
- [ ] `Scrollbar` value/range/drag
- [ ] `Textbox` input/caret/selection
- [ ] `UI` key handlers/modal management
- [ ] `GameUI` zoom/scroll/shake

### Integration Tests
- [ ] Full dialog open/close cycle
- [ ] Modal stacking (multiple modals)
- [ ] Nested window hierarchies
- [ ] Save/load UI state round-trip

### Manual Tests
- [ ] Open every dialog type in-game
- [ ] Test 2x/3x UI scaling
- [ ] Test keyboard-only navigation
- [ ] Test resize (if `UIResizable`)
- [ ] Test file browser navigation
- [ ] Test map editor tools

---

## Regression Risks

| Change Area | Risk | Mitigation |
|-------------|------|------------|
| Position system | All dialogs misaligned | Test all 3 coordinate types |
| Modal stack | Input leaks through | Test nested modals |
| Key handlers | Hotkeys stop working | Test all bound keys |
| Textbox focus | Can't type in fields | Test focus gain/loss |
| Scrollbar range | Crashes at extremes | Test min/max values |
| Fractional coords | Breaks on resize | Test window resize |

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Author | | | |
| Reviewer | | | |
| QA | | | |

---

## Quick Reference

### Key Files
- `Lua/window.lua` - Core widget framework (2185 lines)
- `Lua/ui.lua` - UI class (input, cursor, modals)
- `Lua/game_ui.lua` - GameUI class (HUD, map interaction)
- `Lua/dialogs/*.lua` - 75+ dialog implementations

### Key Methods
| Class | Methods |
|-------|---------|
| Window | `setSize`, `setPosition`, `hitTest`, `addWindow`, `close`, `draw` |
| UI | `dispatch`, `addKeyHandler`, `addWindow`, `playSound` |
| GameUI | `onTick`, `scrollMap`, `setZoom`, `shakeScreen`, `draw` |

### Position Types
| Type | Range | Meaning |
|------|-------|---------|
| Absolute | `>= 0` | Pixels from left/top |
| Negative | `< 0` | Pixels from right/bottom |
| Fractional | `[0, 1)` | Fraction of parent size |

## Related Pages

- [[17-ui-system/SUMMARY]]
- [[17-ui-system/MAP]]
- [[17-ui-system/SCAFFOLD]]
