# CorsixTH Data File Changes — Pre-Fix Checklist

> **Use before modifying any disease, room, or object data file.**  
> Run all checks locally. CI should fail if any check fails.

---

## 1. Disease File Changes (`Lua/diseases/*.lua`)

### 1.1 Required Fields Present
- [ ] `id` matches filename (e.g., `bloaty_head.lua` → `id = "bloaty_head"`)
- [ ] `expertise_id` — unique integer 1–35, not used by another disease
- [ ] Exactly **one** of `visuals_id` OR `non_visuals_id` (not both, not neither)
- [ ] `name`, `cause`, `symptoms`, `cure` — all reference `_S.diseases.<id>.<field>`
- [ ] `cure_price` — positive integer
- [ ] `emergency_sound` — valid `.wav` in `Sound/` (e.g., `emerg007.wav`)
- [ ] `emergency_number` — positive integer (typical 4–18)
- [ ] `contagious` — boolean
- [ ] `initPatient` — function accepting `patient` parameter
- [ ] `diagnosis_rooms` — non-empty table of room ID strings
- [ ] `treatment_rooms` — non-empty table of room ID strings (ordered)

### 1.2 Optional Fields Validated
- [ ] `requires_machine` — boolean (only if treatment room has machine object)
- [ ] `more_loo_use` — boolean (only for digestive diseases)
- [ ] `must_stand` — boolean (only if patient type lacks sit animation)
- [ ] `only_emergency` — boolean (only for alien_dna-style diseases)
- [ ] `yawn` — boolean (only for sleeping_illness)
- [ ] `effect` — `AnimationEffect.Glowing` or `AnimationEffect.Jelly`

### 1.3 initPatient Function
- [ ] Calls `patient:setType("...")` with valid patient type
- [ ] Sets layers 0–4 appropriately (`patient:setLayer(idx, value)`)
- [ ] Layer values are even numbers (animation frames come in pairs)
- [ ] If `cured_layers` used, all referenced layers defined
- [ ] No hardcoded animation IDs (use layer system)

### 1.4 Room References
- [ ] Every ID in `diagnosis_rooms` exists in `Lua/rooms/*.lua`
- [ ] Every ID in `treatment_rooms` exists in `Lua/rooms/*.lua`
- [ ] Treatment rooms have `objects_needed` matching disease requirements
- [ ] No circular dependencies (disease A → room X → object Y → disease B)

### 1.5 Localization
- [ ] Strings exist in `Lua/Languages/english.lua` under `diseases.<id>.{name,cause,symptoms,cure}`
- [ ] No hardcoded English strings in data file

---

## 2. Room File Changes (`Lua/rooms/*.lua`)

### 2.1 Required Fields Present
- [ ] `id` matches filename
- [ ] `level_config_id` — unique integer 1–30
- [ ] `class` — ends with "Room" (e.g., `GPRoom`, `WardRoom`)
- [ ] `name`, `long_name`, `tooltip` — reference `_S.rooms_short/long/tooltip.rooms.<id>`
- [ ] `objects_needed` — table `{ object_id = count, ... }`, all counts > 0
- [ ] `build_preview_animation` — valid animation ID
- [ ] `categories` — non-empty table `{ category = priority }`
- [ ] `minimum_size` — positive integer (≥ 4)
- [ ] `wall_type` — one of: `white`, `yellow`, `blue`, `green`
- [ ] `floor_tile` — valid floor tile ID
- [ ] `required_staff` — table `{ Role = count }`, at least one entry
- [ ] `call_sound` — valid `.wav` in `Sound/` (e.g., `reqd008.wav`)

### 2.2 Optional Fields Validated
- [ ] `vip_must_visit` — boolean (only for ward, operating_theatre, dna_fixer, research)
- [ ] `objects_additional` — array of object IDs (all must exist)
- [ ] `maximum_staff` — if present, ≥ `required_staff` for each role
- [ ] `handyman_call_sound` — valid `.wav` if present
- [ ] `has_no_queue_dialog` — boolean (only for training, staff_room)
- [ ] `swing_doors` — boolean (only for ward, operating_theatre, dna_fixer)

### 2.3 Object References
- [ ] Every ID in `objects_needed` exists in `Lua/objects/*.lua`
- [ ] Every ID in `objects_additional` exists in `Lua/objects/*.lua`
- [ ] Required objects have correct `research_category` for room type
- [ ] Machine objects (if `requires_machine` in disease) present in treatment room

### 2.4 Class Definition
- [ ] `class "ClassName" (Room)` matches `room.class`
- [ ] Constructor calls `self:Room(...)`
- [ ] Overrides only necessary methods (`commandEnteringPatient`, `roomFinished`, etc.)
- [ ] No direct global state mutation in constructor

### 2.5 Dynamic Capacity (if applicable)
- [ ] `roomFinished()` computes `maximum_staff` and/or `maximum_patients` from placed objects
- [ ] `getMaximumStaffCriteria()` returns computed table
- [ ] Handles save/load via `afterLoad(old, new)`

### 2.6 Localization
- [ ] Strings exist in `Lua/Languages/english.lua` under `rooms_short`, `rooms_long`, `tooltip.rooms`

---

## 3. Object File Changes (`Lua/objects/*.lua`)

### 3.1 Required Fields Present
- [ ] `id` matches filename
- [ ] `thob` — unique integer (THOB animation bank index)
- [ ] `name` — `_S.object.<id>`
- [ ] `tooltip` — `_S.tooltip.objects.<id>`
- [ ] `ticks` — boolean
- [ ] `build_preview_animation` — valid animation ID
- [ ] `orientations` — table with at least `north` and `east`

### 3.2 Optional Fields Validated
- [ ] `research_category` — `"diagnosis"` or `"cure"` (if researchable)
- [ ] `research_fallback` — expertise_id integer (if research_category set)
- [ ] `class` — custom class name if custom behavior needed
- [ ] `show_in_town_map` — boolean
- [ ] `idle_animations` — table per direction (north, east, south?, west?)
- [ ] `usage_animations` — per direction, per humanoid type
- [ ] `multi_usage_animations` — for two-humanoid interactions
- [ ] `crashed_animation` — animation ID if object can crash
- [ ] `corridor_object` — integer 1–7 (priority for corridor placement)
- [ ] `walk_in_to_use` — boolean
- [ ] `locked_to_wall` — `{ wall_dir = obj_dir }` mapping
- [ ] `slave_id` — references another object ID (for multi-tile objects)
- [ ] `multiple_users_allowed` — boolean
- [ ] `dynamic_info` — boolean

### 3.3 Orientation Structure
Each orientation must have:
- [ ] `footprint` — array of `{x, y, flags...}` cells
  - [ ] At least one `complete_cell = true`
  - [ ] Flags valid: `complete_cell`, `only_passable`, `only_side`, `invisible`, `shareable`, `need_north_side`, `need_south_side`, `need_east_side`, `need_west_side`
- [ ] `use_position` — `{x, y}` or `"passable"`
- [ ] `use_position_secondary` — for multi-use (if applicable)
- [ ] `render_attach_position` — for multi-tile rendering (if applicable)
- [ ] `early_list` — boolean for render order (if needed)

### 3.4 Animation Consistency
- [ ] `idle_animations` directions match `usage_animations` directions
- [ ] `usage_animations` has entries for all humanoid types that use object
- [ ] Animation IDs exist in THOB bank (`thob` value)
- [ ] `anim_mgr:setPatientMarker` / `setStaffMarker` called for all used animations

### 3.5 Custom Class (if `class` specified)
- [ ] `class "ClassName" (Object)` or `(Entity)`
- [ ] Constructor calls `self:Object(...)` or `self:Entity(...)`
- [ ] Implements required methods: `tick()`, `onClick()`, `resetUsageAndReservaton()`, `afterLoad()`
- [ ] Uses `corsixth.require("queue")` if queue needed
- [ ] Registers drawing layer via `getDrawingLayer()` if special layer needed

### 3.6 Localization
- [ ] Strings exist in `Lua/Languages/english.lua` under `object.<id>`, `tooltip.objects.<id>`

---

## 4. Cross-File Consistency

### 4.1 Disease ↔ Room
- [ ] All `diagnosis_rooms` IDs exist in rooms
- [ ] All `treatment_rooms` IDs exist in rooms
- [ ] Treatment rooms have correct staff type for disease (Doctor/Nurse/Psychiatrist/Surgeon/Researcher)
- [ ] Machine-requiring diseases have machine object in treatment room `objects_needed`

### 4.2 Room ↔ Object
- [ ] All `objects_needed` IDs exist in objects
- [ ] All `objects_additional` IDs exist in objects
- [ ] Object `research_category` matches room purpose (diagnosis/cure/facilities)
- [ ] No object referenced by room is missing `orientations`

### 4.3 Object ↔ Object
- [ ] All `slave_id` references exist
- [ ] Slave objects have empty `footprint` (typically)
- [ ] Master object `orientations` includes `slave_position`

### 4.4 No Orphans
- [ ] Every object (except special: litter, rathole, helicopter, door, reception_desk) is referenced by at least one room
- [ ] Every room is referenced by at least one disease OR is a facility (staff_room, toilets, training, research)

---

## 5. Testing & Validation

### 5.1 Automated Tests (run via `busted SCAFFOLD.lua`)
- [ ] All disease schema tests pass
- [ ] All room schema tests pass
- [ ] All object schema tests pass
- [ ] All cross-reference tests pass

### 5.2 Manual Verification
- [ ] Start game, build room, verify no Lua errors
- [ ] Spawn patient with disease, verify diagnosis/treatment path works
- [ ] Check object animations play correctly in all orientations
- [ ] Verify save/load preserves room state (run `afterLoad` logic)

### 5.3 Performance
- [ ] No excessive `math.random` calls in hot paths (initPatient, commandEnteringPatient)
- [ ] Object `tick()` functions are lightweight
- [ ] Room `roomFinished()` doesn't iterate entire map

---

## 6. Git & Documentation

- [ ] Commit message follows format: `data: <type> <id> — <summary>`
  - Example: `data: disease bloaty_head — adjust cure_price to 900`
- [ ] Related files updated in same commit (localization, level config if needed)
- [ ] CHANGELOG.md updated if user-facing change
- [ ] No debugging `print()` statements left in data files

---

## 7. Special Cases Quick Reference

| Change Type | Extra Checks |
|-------------|--------------|
| New disease | Add to `Lua/diseases/init.lua` loader, update `expertise_id` sequence |
| New room | Add to `Lua/rooms/init.lua`, assign `level_config_id`, update level config |
| New object | Add to `Lua/objects/init.lua`, assign unique `thob`, add animations |
| Change treatment room | Verify all diseases using it still work |
| Change object footprint | Test room placement in all 4 rotations |
| Add machine to disease | Set `requires_machine = true`, add object to treatment room |

---

## 8. Emergency Rollback

If a data change breaks the game:
1. `git revert <commit>` the data file change
2. Check `Lua/Languages/english.lua` for orphaned strings
3. Run full test suite: `busted SCAFFOLD.lua`
4. Verify clean start on new game


## Related Pages

- [[13-data-formats/SUMMARY]]
- [[13-data-formats/MAP]]
- [[13-data-formats/SCAFFOLD]]
