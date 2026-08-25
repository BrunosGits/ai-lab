# UI System - File:Line Index

## Core Framework (`Lua/window.lua` - 2185 lines)

### Window Class (line 24)
| Method | Line | Description |
|--------|------|-------------|
| `Window:Window()` | 33 | Constructor, initializes all child tables |
| `Window:setSize()` | 50 | Sets width/height |
| `Window:setPosition()` | 80 | Handles absolute/negative/fractional coords |
| `Window:setDefaultPosition()` | 109 | Restores saved position from config |
| `Window:close()` | 130 | Cleanup: unregisters handlers, removes from parent |
| `Window:draw()` | 143 | Renders panels, buttons, children |
| `Window:onMouseUp()` | 168 | Mouse release handling |
| `Window:onMouseDown()` | 185 | Mouse press handling |
| `Window:onMouseMove()` | 202 | Mouse move handling |
| `Window:onKeyDown()` | 219 | Key press handling |
| `Window:onKeyUp()` | 236 | Key release handling |
| `Window:addWindow()` | 253 | Adds child window |
| `Window:removeWindow()` | 270 | Removes child window |
| `Window:addPanel()` | 287 | Factory for Panel |
| `Window:addButton()` | 304 | Factory for Button |
| `Window:addScrollbar()` | 321 | Factory for Scrollbar |
| `Window:addTextbox()` | 338 | Factory for Textbox |
| `Window:addHotkeybox()` | 355 | Factory for HotkeyBox |
| `Window:setDefault()` | 372 | Sets default button |
| `Window:setTooltip()` | 389 | Sets tooltip region |
| `Window:hitTest()` | 406 | Mouse collision detection |

### Panel Class (line 168)
| Method | Line |
|--------|------|
| `Panel:Panel()` | 168 |
| `Panel:draw()` | 195 |

### Button Class (line 594)
| Method | Line |
|--------|------|
| `Button:Button()` | 594 |
| `Button:draw()` | 621 |
| `Button:onMouseUp()` | 648 |
| `Button:onMouseDown()` | 675 |

### Scrollbar Class (line 834)
| Method | Line |
|--------|------|
| `Scrollbar:Scrollbar()` | 834 |
| `Scrollbar:draw()` | 861 |
| `Scrollbar:onMouseUp()` | 888 |
| `Scrollbar:onMouseDown()` | 905 |
| `Scrollbar:onMouseMove()` | 922 |
| `Scrollbar:setRange()` | 940 |
| `Scrollbar:setValue()` | 957 |
| `Scrollbar:getValue()` | 974 |

### Textbox Class (line 943)
| Method | Line |
|--------|------|
| `Textbox:Textbox()` | 943 |
| `Textbox:draw()` | 970 |
| `Textbox:onKeyDown()` | 997 |
| `Textbox:onMouseUp()` | 1024 |
| `Textbox:onMouseDown()` | 1041 |
| `Textbox:setText()` | 1058 |
| `Textbox:getText()` | 1075 |

### HotkeyBox Class (line 1342)
| Method | Line |
|--------|------|
| `HotkeyBox:HotkeyBox()` | 1342 |
| `HotkeyBox:draw()` | 1369 |
| `HotkeyBox:onMouseUp()` | 1396 |
| `HotkeyBox:onMouseDown()` | 1423 |

### TreeControl Class (line 484)
| Method | Line |
|--------|------|
| `TreeControl:TreeControl()` | 484 |
| `TreeControl:draw()` | 511 |
| `TreeControl:onMouseDown()` | 538 |

---

## UI Class (`Lua/ui.lua`)

| Method | Line | Description |
|--------|------|-------------|
| `UI:UI()` | 24 | Constructor, inherits Window |
| `UI:initKeyAndButtonCodes()` | 51 | Loads key/button mappings |
| `UI:dispatch()` | 102 | Main event loop |
| `UI:draw()` | 157 | Render all windows |
| `UI:playSound()` | 184 | Play sound effect |
| `UI:playAnnouncement()` | 191 | Play announcement |
| `UI:addWindow()` | 198 | Add top-level window |
| `UI:removeWindow()` | 215 | Remove top-level window |
| `UI:addKeyHandler()` | 232 | Register global hotkey |
| `UI:removeKeyHandler()` | 249 | Unregister hotkey |
| `UI:setCursorPosition()` | 266 | Set mouse position |
| `UI:getMouseXY()` | 283 | Get mouse position |
| `UI:afterLoad()` | 300 | Restore window positions |

---

## GameUI Class (`Lua/game_ui.lua`)

| Method | Line | Description |
|--------|------|-------------|
| `GameUI:GameUI()` | 25 | Constructor, inherits UI |
| `GameUI:draw()` | 51 | Render world + UI |
| `GameUI:onTick()` | 84 | Per-tick UI updates |
| `GameUI:onMouseMove()` | 137 | Mouse move in-game |
| `GameUI:onMouseDown()` | 154 | Mouse down in-game |
| `GameUI:onMouseUp()` | 171 | Mouse up in-game |
| `GameUI:onKeyDown()` | 188 | Key down in-game |
| `GameUI:onKeyUp()` | 205 | Key up in-game |
| `GameUI:setZoom()` | 222 | Set map zoom level |
| `GameUI:scrollMap()` | 239 | Scroll camera |
| `GameUI:shakeScreen()` | 256 | Screen shake effect |
| `GameUI:playAnnouncement()` | 273 | Play announcement |
| `GameUI:afterLoad()` | 290 | Restore UI state |
| `GameUI:togglePlayerSpeed()` | 307 | Toggle game speed |
| `GameUI:playWatchAnnouncement()` | 324 | Play watch announcement |

---

## Dialog Classes (`Lua/dialogs/`)

### Window-mode Dialogs (extend Window)
| Class | File | Line |
|-------|------|------|
| UIAdviser | `dialogs/adviser.lua` | 24 |
| UIBottomPanel | `dialogs/bottom_panel.lua` | 22 |
| UIBuildRoom | `dialogs/build_room.lua` | 23 |
| UIConfirmDialog | `dialogs/confirm_dialog.lua` | 23 |
| UIFurnishCorridor | `dialogs/furnish_corridor.lua` | 27 |
| UIHireStaff | `dialogs/hire_staff.lua` | 21 |
| UIInformation | `dialogs/information.lua` | 22 |
| UIJukebox | `dialogs/jukebox.lua` | 24 |
| UIMachine | `dialogs/machine_dialog.lua` | 21 |
| UIMenuBar | `dialogs/menu.lua` | 26 |
| UIMessage | `dialogs/message.lua` | 22 |
| UIPatient | `dialogs/patient.lua` | 30 |
| UIPlaceObjects | `dialogs/place_objects.lua` | 31 |
| UIPlaceStaff | `dialogs/place_staff.lua` | 26 |
| UIQueue | `dialogs/queue_dialog.lua` | 24 |
| UIQueuePopup | `dialogs/queue_dialog.lua` | 362 |
| UIStaff | `dialogs/staff_dialog.lua` | 29 |
| UIStaffRise | `dialogs/staff_rise.lua` | 23 |
| UIWatch | `dialogs/watch.lua` | 23 |
| Subtitles | `dialogs/subtitles.lua` | 22 |
| UIEditRoom | `dialogs/edit_room.lua` | 23 |
| TreeControl | `dialogs/tree_ctrl.lua` | 484 |
| UIHotkeyAssignKeyPane | `dialogs/resizables/hotkey_assign.lua` | 568 |

### Fullscreen Dialogs (extend UIFullscreen)
| Class | File | Line |
|-------|------|------|
| UIAnnualReport | `dialogs/fullscreen/annual_report.lua` | 22 |
| UIBankManager | `dialogs/fullscreen/bank_manager.lua` | 22 |
| UICasebook | `dialogs/fullscreen/drug_casebook.lua` | 22 |
| UIFax | `dialogs/fullscreen/fax.lua` | 25 |
| UIGraphs | `dialogs/fullscreen/graphs.lua` | 23 |
| UIPolicy | `dialogs/fullscreen/hospital_policy.lua` | 22 |
| UIProgressReport | `dialogs/fullscreen/progress_report.lua` | 22 |
| UIResearch | `dialogs/fullscreen/research_policy.lua` | 21 |
| UIStaffManagement | `dialogs/fullscreen/staff_management.lua` | 24 |
| UITownMap | `dialogs/fullscreen/town_map.lua` | 24 |

### Resizable Dialogs (extend UIResizable)
| Class | File | Line |
|-------|------|------|
| UIAdviserHistory | `dialogs/resizables/adviser_history.lua` | 22 |
| UICallsDispatcher | `dialogs/resizables/calls_dispatcher.lua` | 22 |
| UICheats | `dialogs/resizables/cheats_dialog.lua` | 24 |
| UICustomise | `dialogs/resizables/customise.lua` | 22 |
| UIDirectoryBrowser | `dialogs/resizables/directory_browser.lua` | 118 |
| UIDropdown | `dialogs/resizables/dropdown.lua` | 23 |
| UIFileBrowser | `dialogs/resizables/file_browser.lua` | 146 |
| UIFolder | `dialogs/resizables/folder_settings.lua` | 22 |
| UIHotkeyAssign | `dialogs/resizables/hotkey_assign.lua` | 22 |
| UILuaConsole | `dialogs/resizables/lua_console.lua` | 26 |
| UIMachineMenu | `dialogs/resizables/machine_menu.lua` | 22 |
| UIMainMenu | `dialogs/resizables/main_menu.lua` | 22 |
| UIMapEditor | `dialogs/resizables/map_editor.lua` | 22 |
| UIMenuList | `dialogs/resizables/menu_list_dialog.lua` | 22 |
| UINewGame | `dialogs/resizables/new_game.lua` | 22 |
| UIOptions | `dialogs/resizables/options.lua` | 22 |
| UIResolution | `dialogs/resizables/options.lua` | 637 |
| UIScrollSpeed | `dialogs/resizables/options.lua` | 720 |
| UIShiftScrollSpeed | `dialogs/resizables/options.lua` | 790 |
| UIZoomSpeed | `dialogs/resizables/options.lua` | 859 |
| UISoundSettings | `dialogs/resizables/sound_setting.lua` | 21 |
| UITipOfTheDay | `dialogs/resizables/tip_of_the_day.lua` | 22 |
| UIUpdate | `dialogs/resizables/update.lua` | 22 |

### File Browser Variants (extend UIFileBrowser)
| Class | File | Line |
|-------|------|------|
| UIChooseFont | `dialogs/resizables/file_browsers/choose_font.lua` | 25 |
| UIChooseSoundfont | `dialogs/resizables/file_browsers/choose_soundfont.lua` | 27 |
| UILoadGame | `dialogs/resizables/file_browsers/load_game.lua` | 22 |
| UILoadMap | `dialogs/resizables/file_browsers/load_map.lua` | 22 |
| UISaveGame | `dialogs/resizables/file_browsers/save_game.lua` | 22 |
| UISaveMap | `dialogs/resizables/file_browsers/save_map.lua` | 22 |

### Menu List Variants (extend UIMenuList)
| Class | File | Line |
|-------|------|------|
| UICustomCampaign | `dialogs/resizables/menu_list_dialogs/custom_campaign.lua` | 22 |
| UICustomGame | `dialogs/resizables/menu_list_dialogs/custom_game.lua` | 22 |
| UIMakeDebugPatient | `dialogs/resizables/menu_list_dialogs/make_debug_patient.lua` | 21 |

### Tree Nodes
| Class | File | Line | Parent |
|-------|------|------|--------|
| TreeNode | `dialogs/tree_ctrl.lua` | 22 | - |
| FileTreeNode | `dialogs/tree_ctrl.lua` | 185 | TreeNode |
| DummyRootNode | `dialogs/tree_ctrl.lua` | 451 | TreeNode |
| DirTreeNode | `dialogs/resizables/directory_browser.lua` | 27 | FileTreeNode |
| InstallDirTreeNode | `dialogs/resizables/directory_browser.lua` | 61 | DirTreeNode |
| FilteredFileTreeNode | `dialogs/resizables/file_browser.lua` | 25 | FileTreeNode |
| FilteredTreeControl | `dialogs/resizables/file_browser.lua` | 70 | TreeControl |

### Non-UI Dialog Support
| Class | File | Line |
|-------|------|------|
| UIMenu | `dialogs/menu.lua` | 485 |
| SubtitleQueue | `dialogs/subtitles.lua` | 85 |

---

## Inheritance Hierarchy

```
Window (window.lua:24)
├── Panel (window.lua:168)
├── Button (window.lua:594)
├── Scrollbar (window.lua:834)
├── Textbox (window.lua:943)
├── HotkeyBox (window.lua:1342)
├── UI (ui.lua:24)
│   └── GameUI (game_ui.lua:25)
├── UIFullscreen (dialogs/fullscreen.lua:22)
│   ├── UIAnnualReport, UIBankManager, UICasebook, UIFax,
│   │   UIGraphs, UIPolicy, UIProgressReport, UIResearch,
│   │   UIStaffManagement, UITownMap
├── UIResizable (dialogs/resizable.lua:24)
│   ├── UIAdviserHistory, UICallsDispatcher, UICheats,
│   │   UICustomise, UIDirectoryBrowser, UIDropdown,
│   │   UIFileBrowser, UIFolder, UIHotkeyAssign,
│   │   UILuaConsole, UIMachineMenu, UIMainMenu,
│   │   UIMapEditor, UIMenuList, UINewGame, UIOptions,
│   │   UIResolution, UIScrollSpeed, UIShiftScrollSpeed,
│   │   UIZoomSpeed, UISoundSettings, UITipOfTheDay, UIUpdate
│   ├── UIFileBrowser
│   │   ├── UIChooseFont, UIChooseSoundfont, UILoadGame,
│   │   │   UILoadMap, UISaveGame, UISaveMap
│   └── UIMenuList
│       ├── UICustomCampaign, UICustomGame, UIMakeDebugPatient
├── UIAdviser, UIBottomPanel, UIBuildRoom, UIConfirmDialog,
│   UIFurnishCorridor, UIHireStaff, UIInformation, UIJukebox,
│   UIMachine, UIMenuBar, UIMessage, UIPatient, UIPlaceObjects,
│   UIPlaceStaff, UIQueue, UIQueuePopup, UIStaff, UIStaffRise,
│   UIWatch, Subtitles, UIMessage, UIHotkeyAssignKeyPane, TreeControl
└── UIPlaceObjects
    └── UIEditRoom

TreeNode (dialogs/tree_ctrl.lua:22)
├── FileTreeNode (dialogs/tree_ctrl.lua:185)
│   ├── DirTreeNode (dialogs/resizables/directory_browser.lua:27)
│   │   └── InstallDirTreeNode (dialogs/resizables/directory_browser.lua:61)
│   └── FilteredFileTreeNode (dialogs/resizables/file_browser.lua:25)
└── DummyRootNode (dialogs/tree_ctrl.lua:451)

TreeControl (extends Window)
└── FilteredTreeControl (extends TreeControl)
```

---

## Key Position Constants

| Constant | File | Line | Value |
|----------|------|------|-------|
| Cursor IDs | `window.lua` | 30-35 | 1=default, 2=clicked, 3=resize_room, 4=edit_room, 5=ns_arrow, 6=we_arrow |
| Button states | `window.lua` | 621+ | normal, hover, pressed |
| Scrollbar directions | `window.lua` | 834+ | vertical, horizontal |

---

## Quick Search Patterns

```bash
# All window method definitions
grep -n "function Window:" Lua/window.lua

# All UI method definitions
grep -n "function UI:" Lua/ui.lua

# All GameUI method definitions
grep -n "function GameUI:" Lua/game_ui.lua

# All dialog class declarations
grep -n 'class "UI' Lua/dialogs/**/*.lua

# Position system
grep -n "setPosition\|fractional\|negative" Lua/window.lua

# Modal handling
grep -n "modal_window" Lua/ui.lua Lua/window.lua

# Key handler registration
grep -n "addKeyHandler\|key_handlers" Lua/ui.lua
```