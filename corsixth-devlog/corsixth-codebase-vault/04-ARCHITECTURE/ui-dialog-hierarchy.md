# UI Dialog Hierarchy

## Overview
CorsixTH uses a hierarchical window/dialog system built on a base `Window` class with support for panels, dialogs, fullscreen dialogs, and resizable dialogs.

## Window Class Hierarchy
```lua
class "Window"
  ├── ui: UI
  ├── x, y, width, height
  ├── visible, on_top
  ├── children: array of Window
  ├── parent: Window
  ├── onTop: boolean
  └── modal: boolean

class "Panel" (Window)
  ├── background_color
  ├── border
  └── title_bar

class "UIResizable" (Window)
  ├── min_width, min_height
  ├── resize_handle
  └── onResize()

class "UIFullscreen" (UIResizable)
  ├── fullscreen_mode
  └── background

class "UIDialog" (Window)
  ├── modal
  ├── buttons
  └── title
```

## Dialog Categories

### Standard Dialogs (Window)
| Dialog | Purpose | Parent |
|--------|---------|--------|
| `UIPatient` | Patient info | Window |
| `UIStaff` | Staff info | Window |
| `UIStaffRise` | Staff promotion | Window |
| `UIHireStaff` | Hire dialog | Window |
| `UIMachine` | Machine info | Window |
| `UIMachineMenu` | Machine menu | Window |
| `UIPlaceObjects` | Place objects | Window |
| `UIFurnishCorridor` | Corridor furnishing | Window |
| `UIEditRoom` | Edit room | Window |
| `UIBuildRoom` | Build room | Window |
| `UIWatch` | Game time | Window |
| `UIConfirmDialog` | Confirmation | Window |
| `UIInformation` | Info popup | Window |
| `UIAdviser` | Adviser messages | Window |
| `UIJukebox` | Music player | Window |

### Fullscreen Dialogs (UIFullscreen)
| Dialog | Purpose |
|--------|---------|
| `UIAnnualReport` | Year-end report |
| `UIBankManager` | Bank/loan management |
| `UIGraphs` | Statistics graphs |
| `UIStaffManagement` | Staff hiring/management |
| `UICasebook` | Disease database |
| `UIFax` | Fax messages |
| `UITownMap` | Map overview |
| `UIHospitalPolicy` | Hospital policies |
| `UIResearch` | Research tree |
| `UIProgressReport` | Monthly report |

### Resizable Dialogs (UIResizable)
| Dialog | Purpose |
|--------|---------|
| `UILuaConsole` | Lua REPL |
| `UICheats` | Cheat codes |
| `UIMachineMenu` | Machine interaction |
| `UIAdviserHistory` | Message history |

### Panel-based (UIBottomPanel)
| Dialog | Purpose |
|--------|---------|
| `UIBottomPanel` | Main bottom bar |
| `UIMessage` | Message display |
| `UIQueue` | Room queue |
| `UIQueuePopup` | Queue details |

## Window Management

### Window Stack
```lua
UI.windows = {}  -- All windows, bottom to top
UI.modal_window = nil  -- Currently modal window

function UI:addWindow(window)
  table.insert(self.windows, window)
  window.ui = self
end

function UI:bringToFront(window)
  for i, w in ipairs(self.windows) do
    if w == window then
      table.remove(self.windows, i)
      table.insert(self.windows, w)
      break
    end
  end
end
```

### Modal Dialogs
```lua
function UI:showModal(window)
  self.modal_window = window
  window.modal = true
  self:addWindow(window)
end

function UI:closeModal()
  if self.modal_window then
    self.modal_window:close()
    self.modal_window = nil
  end
end
```

### Input Handling
```lua
function UI:onMouseDown(x, y)
  -- Check top-down for clicks
  for i = #self.windows, 1, -1 do
    local window = self.windows[i]
    if window:hitTest(x, y) then
      if window.modal and window ~= self.modal_window then
        return false  -- Blocked by modal
      end
      window:onMouseDown(x, y)
      return true
    end
  end
end
```

## Dialog Lifecycle
```lua
function Window:open()
  self.visible = true
  self.ui:addWindow(self)
  self:onOpen()
end

function Window:close()
  self.visible = false
  self:onClose()
  self.ui:removeWindow(self)
end

function Window:onOpen() end
function Window:onClose() end
```

## Cross-References
- [[world-entity-flow]] - How UI interacts with world
- [[entity-action-system]] - UI triggers actions
- Area: [[01-CODEBASE/17-ui-system]], [[01-CODEBASE/18-cpp-bindings]]


## Related Pages

- [[entity-action-system]]
- [[performance]]
- [[room-hospital-hierarchy]]
- [[save-load-migrations]]
- [[world-entity-flow]]
