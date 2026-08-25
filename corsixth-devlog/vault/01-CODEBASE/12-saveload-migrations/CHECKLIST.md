# CorsixTH Save/Load Changes - Pre-Fix Checklist

## Overview

This checklist must be completed before any changes to the save/load system, migration hooks, or permanent object registration. Each item must be verified and signed off.

---

## 1. Architecture Understanding

- [ ] **Two-layer model understood**: C++ binary serializer (`persist_lua.cpp`) + Lua wrapper (`persistance.lua`)
- [ ] **Permanent object system understood**: `permanent()`/`unpermanent()` + `MakePermanentObjectsTable(inverted)`
- [ ] **Migration pattern understood**: `afterLoad(old, new)` with version gates (`if old < X then`)
- [ ] **Parent call chain understood**: Child `afterLoad` MUST call `Parent.afterLoad(self, old, new)`
- [ ] **Version semantics understood**: `old` = loaded save version, `new` = current code version, `original` = first version

---

## 2. Permanent Object Changes

### Adding New Permanents
- [ ] Registered via `permanent("unique.name", object)` in appropriate initialization code
- [ ] Name follows convention: `module.subsystem.object` (e.g., `objects.radiator`, `systems.pathfinding`)
- [ ] Added to `MakePermanentObjectsTable` coverage (global functions, classes, C libraries, app subsystems)
- [ ] **Inverted table tested**: Load path resolves name back to live object correctly
- [ ] `unpermanent()` called on cleanup (mod unload, game shutdown)

### Removing/Changing Permanents
- [ ] No existing savegames reference the old name (or migration handles it)
- [ ] All references updated in codebase
- [ ] `unpermanent()` called before re-registering with new name

---

## 3. Migration Hook Changes (`afterLoad`)

### Adding New Version Gate
- [ ] Version number > current `App.savegame_version` (in `app.lua`)
- [ ] Gate uses `if old < NEW_VERSION and new >= NEW_VERSION then` pattern
- [ ] Migration is **idempotent**: safe to run multiple times
- [ ] Migration only touches fields that exist in old saves
- [ ] Parent `afterLoad` called **after** child-specific migrations
- [ ] Added to correct class (App, World, Map, UI, Entity subclass, etc.)

### Migration Logic Review
- [ ] **No side effects** during migration that affect other migrations
- [ ] **No UI operations** (dialogs, windows) during migration
- [ ] **No file I/O** during migration
- [ ] **No random number generation** that affects game state (unless intentional)
- [ ] Data transformations are **reversible** or **deterministic**
- [ ] Cross-references updated (e.g., if object type added, all references fixed)

### Chained Migration Pattern (Staff-style)
- [ ] If splitting migration across versions: `Parent.afterLoad(self, old, MIDDLE); self:afterLoad(MIDDLE, new)`
- [ ] Middle version is a real historical version
- [ ] Both parent calls use correct version bounds

---

## 4. C++ Userdata Persistence

### Adding `__persist` / `__depersist`
- [ ] `__depersist_size` matches C++ object size exactly
- [ ] `__persist` writes all fields needed for reconstruction
- [ ] `__depersist` reads in **exact same order** as `__persist` writes
- [ ] `__pre_depersist` implemented if C++ placement new needed
- [ ] Sync marker `0x42` verified in `__depersist` (handled by C++)
- [ ] Cross-references to other userdata handled via `write_stack_object`/`read_stack_object`
- [ ] Deferred `__depersist` (return `true`) used for circular refs

### Changing Userdata Layout
- [ ] **Never remove fields** — only add at end
- [ ] `__depersist_size` updated
- [ ] Migration gate added for old saves to initialize new fields
- [ ] Version bump in `App.savegame_version`

---

## 5. SaveGame/LoadGame Flow Changes

### SaveGame Modifications
- [ ] `state` table includes all required subsystems
- [ ] `map:prepareForSave()` called before persist
- [ ] `map:afterSave()` called after persist
- [ ] No transient/cached data in saved state
- [ ] `persist.dump(state, MakePermanentObjectsTable(false))` used

### LoadGame Modifications
- [ ] `MakePermanentObjectsTable(true)` passed to `persist.load`
- [ ] Version heuristic for pre-166 saves preserved (`gfxSetHeuristic`)
- [ ] `TheApp:checkCompatibility()` called before state swap
- [ ] `state.ui:resync(TheApp.ui)` called before swap
- [ ] Global swap order: ui → world → map → RNG
- [ ] `TheApp.ui.menu_bar.ui = TheApp.ui` fixup preserved
- [ ] `TheApp:afterLoad()` called **after** globals swapped
- [ ] Post-load: `resetAnimations()`, `onChangeResolution()`

---

## 6. Compatibility & Testing

### Backward Compatibility
- [ ] Tested loading saves from **at least 3 major versions back**
- [ ] Tested loading **pre-versioning saves** (v0)
- [ ] Tested loading **demo vs full game** saves (gfx_set heuristic)
- [ ] Tested **newer save in older code** (debug mode warning)

### Forward Compatibility
- [ ] New fields have sensible defaults in `afterLoad`
- [ ] Optional fields handled gracefully (nil checks)
- [ ] No hard crashes on unknown data

### Round-trip Testing
- [ ] Save → Load → Save → Load produces identical state
- [ ] Entity identity preserved (same object references)
- [ ] RNG state restored (`math.randomseed`)
- [ ] UI state consistent (cursor, windows, menus)

### Migration Testing
- [ ] Each version gate tested with save from that version
- [ ] Chained migrations tested (Staff pattern)
- [ ] Edge cases: exactly at version boundary, skipping versions

---

## 7. Code Quality

### Lua Code
- [ ] `--[[persistable:name]]` annotations on all persisted functions
- [ ] `strict_declare_global` for new globals
- [ ] No global pollution in migration code
- [ ] Local functions preferred over globals
- [ ] Luacheck passes (no 212 unused param warnings unless intentional)

### C++ Code
- [ ] `static_assert` for `__depersist_size` vs `sizeof(T)`
- [ ] No raw pointer arithmetic in persist/load
- [ ] Error handling via `set_error()` not exceptions
- [ ] Sync marker validation in `__depersist`
- [ ] Memory safety: no use-after-free in deferred `__depersist`

---

## 8. Documentation

- [ ] Migration reason documented in code comment
- [ ] Version number and release noted
- [ ] Affected savegame versions noted
- [ ] `CHANGELOG.md` updated if user-visible
- [ ] `SUMMARY.md` architecture doc updated if structural change

---

## 9. Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Author | | | |
| Code Review | | | |
| QA Test | | | |
| Merge Approval | | | |

---

## 10. Emergency Rollback Plan

If a save/load change breaks existing saves:

1. **Immediate**: Revert commit, tag broken version
2. **Analysis**: Identify which migration gate caused failure
3. **Fix**: Add compatibility layer in `afterLoad` for broken version
4. **Test**: Verify with affected save files
5. **Release**: Hotfix with incremented version number

**Rollback command**: `git revert <commit-hash> && git tag -f v<version>-broken`

---

## Quick Reference: Version Gate Template

```lua
-- In Class:afterLoad(old, new)
if old < NEW_VERSION and new >= NEW_VERSION then
  -- Migration for saves older than NEW_VERSION
  -- Initialize new fields, fix renamed fields, recalculate derived data
  self.new_field = compute_default()
  self.renamed_field = self.old_field
  self.old_field = nil
end

-- ALWAYS call parent LAST
ParentClass.afterLoad(self, old, new)
```

## Quick Reference: Permanent Registration Template

```lua
-- In module init
local MySystem = {}
permanent("systems.my_system", MySystem)

-- In cleanup
unpermanent("systems.my_system")
```

## Quick Reference: C++ Userdata Template

```cpp
// In metatable setup
lua_pushstring(L, "__depersist_size");
lua_pushinteger(L, sizeof(MyClass));
lua_settable(L, -3);

lua_pushstring(L, "__persist");
lua_pushcfunction(L, [](lua_State* L) {
  auto* self = static_cast<MyClass*>(lua_touserdata(L, 1));
  auto* writer = static_cast<lua_persist_writer*>(lua_touserdata(L, 2));
  writer->write_int(self->field1);
  writer->write_string(self->field2);
  writer->write_stack_object(self->child);
  return 0;
});
lua_settable(L, -3);

lua_pushstring(L, "__depersist");
lua_pushcfunction(L, [](lua_State* L) {
  auto* self = static_cast<MyClass*>(lua_touserdata(L, 1));
  auto* reader = static_cast<lua_persist_reader*>(lua_touserdata(L, 2));
  reader->read_int(self->field1);
  reader->read_string(self->field2);
  self->child = reader->read_stack_object();
  return 0;
});
lua_settable(L, -3);
```

---

*Checklist version 1.0 — Update when architecture changes*
