# Pre-Fix Checklist: Entity Iteration & Destruction

**Use this checklist before modifying any code that touches entity iteration, destruction, or the tick loops.**

---

## 🔴 Critical: Modifying Iteration Loops

- [ ] **Does this modify `self.entities` during iteration?**
  - If YES: Use `World:destroyEntity(entity)` — NEVER direct `table.remove`
  - If adding new loop: Copy the EXACT pattern from existing loops (§1)

- [ ] **Does `destroyEntity` get called during a tick loop?**
  - Check all three loops: `onTick`, `onEndDay`, `onEndMonth`
  - Verify `entity.to_destroy` guard is present in loop condition
  - Verify `self.current_tick_entity` is set before callback
  - Verify `self.current_tick_entity = nil` after loop
  - Verify `self:_flushDestroyedEntities()` called after loop

- [ ] **Are all marked entities flushed?**
  - `_flushDestroyedEntities` must be called exactly once per loop
  - Must iterate backwards: `for i = #self.entities, 1, -1`
  - Must clear `entity.to_destroy` for each flushed entity
  - Must reset `self.entities_to_destroy = {}`

---

## 🟠 High: Destruction Logic Changes

- [ ] **Does `destroyEntity` logic change?**
  - Must preserve: `to_destroy` early-return guard
  - Must preserve: `current_tick_entity` check for deferral
  - Must preserve: lazy `entities_to_destroy` creation
  - Must preserve: immediate `onDestroy` call (cleanup runs NOW)
  - Must preserve: immediate removal when NOT in loop

- [ ] **Does `onDestroy` behavior change?**
  - Must remain idempotent (safe to call multiple times)
  - Must not assume entity is already removed from `self.entities`
  - Cascading `destroyEntity` calls from `onDestroy` are SUPPORTED

- [ ] **New entity type added?**
  - Implement `onDestroy` for cleanup (tile, mood, dispatcher)
  - Set `ticks = true` if it needs per-tick updates
  - Set `kind = "humanoid"` or `"plant"` if it needs day-tick
  - Implement `checkForDeadlock` if it can deadlock

---

## 🟡 Medium: Savegame & Compatibility

- [ ] **Old savegames handled?**
  - `entities_to_destroy` may be `nil` — lazy creation in `destroyEntity`
  - `_flushDestroyedEntities` must handle `nil` queue gracefully
  - Test loading savegame from before deferred destruction feature

- [ ] **Error recovery path works?**
  - `app.lua` clears `current_tick_entity` on timer error WITHOUT flush
  - Next loop must flush stale queue (tested in `world_spec.lua:290`)
  - Don't break this by moving flush before `current_tick_entity = nil`

---

## 🟢 Low: Testing & Documentation

- [ ] **Test coverage for new behavior?**
  - Add test case to `world_spec.lua` following existing patterns
  - Test: immediate, deferred, cascade, self-destroy, nested, added-during-loop
  - Test: all three loops (tick, tickDay, deadlock)

- [ ] **Documentation updated?**
  - Update this checklist if new invariants discovered
  - Update SUMMARY.md if new patterns added
  - Comment complex destruction logic in code

---

## 📋 Quick Reference: The Three Loop Patterns

### onTick (world.lua:971-978)
```lua
for _, entity in ipairs(self.entities) do
  if entity.ticks and not entity.to_destroy then
    self.current_tick_entity = entity
    entity:tick()
  end
end
self.current_tick_entity = nil
self:_flushDestroyedEntities()
```

### onEndDay (world.lua:1055-1065)
```lua
for _, entity in ipairs(self.entities) do
  if entity.ticks and class.is(entity, Humanoid) and not entity.to_destroy then
    self.current_tick_entity = entity
    entity:tickDay()
  elseif class.is(entity, Plant) and not entity.to_destroy then
    self.current_tick_entity = entity
    entity:tickDay()
  end
end
self.current_tick_entity = nil
self:_flushDestroyedEntities()
```

### onEndMonth (world.lua:1179-1186)
```lua
for _, entity in ipairs(self.entities) do
  if entity.checkForDeadlock and not entity.to_destroy then
    self.current_tick_entity = entity
    entity:checkForDeadlock()
  end
end
self.current_tick_entity = nil
self:_flushDestroyedEntities()
```

---

## ❌ FORBIDDEN PATTERNS

| Pattern | Why | Alternative |
|---------|-----|-------------|
| `table.remove(self.entities, i)` inside tick | Skips entities | `world:destroyEntity(entity)` |
| `for i=1,#entities do ... remove ... end` | Index shift | Backwards loop in `_flushDestroyedEntities` only |
| `entity:onDestroy()` called twice | Double cleanup | Guarded by `to_destroy` in `destroyEntity` |
| Clearing `current_tick_entity` before flush | Stale queue not flushed | Order: clear → flush |
| New loop without `to_destroy` guard | Dead entities ticked | Copy exact guard from above |

---

## ✅ REQUIRED PATTERNS

| Pattern | Location |
|---------|----------|
| `if entity.to_destroy then return end` | Start of `destroyEntity` |
| `if self.current_tick_entity then ... defer ... else ... immediate ... end` | `destroyEntity` |
| `entity:onDestroy()` called in BOTH branches | `destroyEntity` |
| `self.entities_to_destroy = {}` at flush start | `_flushDestroyedEntities` |
| Backwards iteration `for i = #self.entities, 1, -1` | `_flushDestroyedEntities` |
| `entity.to_destroy = nil` after removal | `_flushDestroyedEntities` |

---

## 🧪 Test Cases That Must Pass

Run `busted Luatest/spec/world_spec.lua` — all 23 tests must pass:

1. Immediate destroy outside loop
2. Destroy entity not in list
3. Deferred removal during iteration
4. Queue entity only once
5. Flush multiple deferred
6. Flush empty queue
7. No skip when earlier destroyed
8. No tick for later destroyed
9. Self-destroy during tick
10. Cascading destructions
11. Entities added during loop
12. Recovery from interrupted loop
13. Destroy already-queued outside loop
14. Immediate destroy with pending queue
15. Reuse queue across loops
16. tickDay loop no skip
17. tickDay plant deferral
18. Deadlock loop no skip
19. Flush with nil queue (old savegame)
20. Lazy queue creation on old savegame
21. Stray entity destroy during loop
22. Double flush safety
23. Nested iteration defers to outer

---

## 🚨 Emergency: If You Break Iteration

**Symptoms:** Entities skipped, crashes in flush, double-destroy, savegame corruption.

**Immediate actions:**
1. Revert to known-good `world.lua` iteration loops
2. Run full `world_spec.lua` test suite
3. Check `app.lua:1242` error handler still clears `current_tick_entity`
4. Verify old savegame loads (nil `entities_to_destroy`)

**Debug tips:**
- Add `print("FLUSH", #queue, #self.entities)` in `_flushDestroyedEntities`
- Log `current_tick_entity` at loop start/end
- Verify `to_destroy` flag transitions: `false → true → nil`

---

**Last Updated:** Based on CorsixTH commit analysis
**Test File:** `/tmp/CorsixTH/CorsixTH/Luatest/spec/world_spec.lua` (23 tests)
**Core Files:** `world.lua:971-978, 1055-1065, 1179-1186, 1844-1893`, `entity.lua:281-294`, `app.lua:1242-1248`
