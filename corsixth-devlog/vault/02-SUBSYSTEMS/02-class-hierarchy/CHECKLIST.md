# Class Hierarchy Change Checklist

> **Use before any modification to class.lua, class declarations, or inheritance structure**
> **All items must be ✅ checked before committing**

---

## Pre-Flight Checks

### [ ] Base Class Impact Analysis
- [ ] Does the change affect `Entity` (root of entity hierarchy)?
- [ ] Does the change affect `Window` (root of UI hierarchy)?
- [ ] Does the change affect `Room` (root of room hierarchy)?
- [ ] Does the change affect `Hospital` (root of hospital hierarchy)?
- [ ] Does the change affect `HumanoidAction` (root of action hierarchy)?
- [ ] Does the change affect `class.lua` (core OOP mechanics)?

**If YES to any above:** Requires full regression test run + manual gameplay test

### [ ] Subclass Coverage
- [ ] All 15 Entity-hierarchy classes tested? (Entity, Humanoid, Patient, Staff, Doctor, Nurse, Handyman, Receptionist, Vip, Inspector, GrimReaper, Object, Machine, Door, Litter + variants)
- [ ] All 24 Room subclasses tested? (GPRoom, OperatingTheatreRoom, WardRoom, ResearchRoom, TrainingRoom, PharmacyRoom, PsychRoom, StaffRoom, ToiletRoom, BloodMachineRoom, CardiogramRoom, DecontaminationRoom, DNAFixerRoom, ElectrolysisRoom, FractureRoom, GeneralDiagRoom, HairRestorationRoom, InflationRoom, JellyVatRoom, ScannerRoom, SlackTongueRoom, UltrascanRoom, XRayRoom)
- [ ] All 32 UI/Window classes tested? (Window, UI, GameUI, UIFullscreen, UIResizable + 28 dialogs)
- [ ] All 33 HumanoidAction subclasses tested?
- [ ] All 7 TreeNode classes tested?
- [ ] All 3 Hospital classes tested?
- [ ] All 21 standalone classes tested?

### [ ] Method Resolution Order (MRO) Preservation
- [ ] `__index` chain intact for all hierarchies?
- [ ] Superclass calls (`Parent.method(self)`) still resolve correctly?
- [ ] No accidental `__index` / `__newindex` overrides on class tables?
- [ ] Adoption (mixin) pattern still works — methods copied, not linked?
- [ ] Multiple adoption order preserved (last wins)?

### [ ] Type Checking Integrity
- [ ] `class.is(instance, Class)` returns correct hierarchy results?
- [ ] `class.type(instance)` returns exact class (not superclass)?
- [ ] `class.is` returns `false` for non-tables, plain tables, sibling classes?
- [ ] `class.type` returns `nil` for non-instances?
- [ ] Humanoid `:isType("ClassName")` helper still works?

### [ ] Adoption / Mixin Patterns
- [ ] `Object.slaveMixinClass()` still works for OperatingSink, RadiationShield, OperatingTable?
- [ ] Mixin methods participate in MRO correctly?
- [ ] Mixin `__init` not called automatically (by design)?
- [ ] No mixin methods leaked to unrelated classes?

### [ ] Save/Load Compatibility
- [ ] All classes implement `afterLoad()`?
- [ ] `afterLoad()` chains to parent (`Parent.afterLoad(self)`)?
- [ ] Migration logic in `afterLoad` handles version differences?
- [ ] No new required fields without default values in `__init`?

### [ ] Instantiation & Initialization
- [ ] All `__init` methods call `Parent.__init(self, ...)` FIRST?
- [ ] No `__init` calls `self:method()` before parent init complete?
- [ ] Constructor `ClassName(args)` works for all classes?
- [ ] `self.super` reference available in `__init`?

### [ ] Metatable Integrity
- [ ] Class tables have `__name`, `__class`, `super` fields?
- [ ] Instance metatables point to correct class table?
- [ ] No circular `__index` references?
- [ ] Class tables not modified at runtime (except intentional adoption)?

---

## Test Execution Requirements

### [ ] Unit Tests (Busted)
- [ ] Run `busted spec/class_spec.lua` — core class system
- [ ] Run `busted spec/class_hierarchy_spec.lua` — this scaffold
- [ ] Run `busted spec/entities/humanoid_spec.lua` — entity hierarchy
- [ ] Run `busted spec/entities/object_spec.lua` — object hierarchy
- [ ] Run `busted spec/room_spec.lua` — room hierarchy
- [ ] Run `busted spec/dialogs/` — UI hierarchy

### [ ] Integration Tests
- [ ] Spawn Patient → verify `class.is(patient, Entity/Humanoid/Patient)`
- [ ] Spawn Doctor → verify `class.is(doctor, Entity/Humanoid/Staff/Doctor)`
- [ ] Build Room → verify `class.is(room, Room/GPRoom/etc)`
- [ ] Open UI Dialog → verify `class.is(dialog, Window/UI/DialogClass)`
- [ ] Queue Action → verify `class.is(action, HumanoidAction/SpecificAction)`

### [ ] Manual Gameplay Tests
- [ ] Start new game — no crashes in first 5 minutes
- [ ] Build all room types — verify functionality
- [ ] Hire all staff types — verify behavior
- [ ] Trigger emergency — verify VIP/Inspector/GrimReaper spawn
- [ ] Save game → Load game — verify state restored
- [ ] Test all UI dialogs open/close correctly

---

## Code Review Checklist

### [ ] Class Declaration Style
- [ ] Uses `class "Name" (Parent) (function(_ENV) ... end)` syntax?
- [ ] `__init` calls `Parent.__init(self, ...)` first?
- [ ] Methods use `function ClassName:method(self, ...)` colon syntax?
- [ ] Static methods use `function ClassName.method(...)` dot syntax?
- [ ] No global pollution (all in `_ENV`)?

### [ ] Inheritance Correctness
- [ ] Single inheritance only (no multiple parents)?
- [ ] No circular inheritance?
- [ ] Depth ≤ 4 (max observed in codebase)?
- [ ] Abstract intermediate classes documented?

### [ ] Method Override Safety
- [ ] Override calls `Parent.method(self, ...)` unless intentional full replacement?
- [ ] `onDestroy` cleanup order: derived first, then parent?
- [ ] `tick` order: parent first, then derived?
- [ ] `__init` order: parent first, then derived?

### [ ] Mixin/Adoption Safety
- [ ] Adoption via `MixinFunction(_ENV)` pattern?
- [ ] Mixin doesn't define `__init` (or documents it's not auto-called)?
- [ ] Conflict resolution documented (last adoption wins)?
- [ ] Mixin methods don't assume specific subclass fields?

---

## Documentation Updates

### [ ] SUMMARY.md Updated
- [ ] Hierarchy diagrams reflect changes?
- [ ] File:line references accurate?
- [ ] New classes added to category tables?
- [ ] Depth statistics updated?
- [ ] Pattern examples still valid?

### [ ] MAP.md Updated
- [ ] New class declarations indexed?
- [ ] Moved classes updated with new file:line?
- [ ] Category organization maintained?

### [ ] Inline Code Comments
- [ ] Class declaration has purpose comment?
- [ ] Non-obvious overrides have rationale?
- [ ] Adoption usage commented?
- [ ] `afterLoad` migration logic explained?

---

## Risk Assessment

| Change Type | Risk Level | Required Verification |
|-------------|------------|----------------------|
| `class.lua` core mechanics | CRITICAL | Full test suite + 30min gameplay |
| Base class (`Entity`, `Window`, `Room`, `Hospital`, `HumanoidAction`) | HIGH | All subclass tests + integration |
| New class declaration | MEDIUM | Type checks + instantiation + save/load |
| Method override in leaf class | LOW | Specific class tests + related features |
| Adoption/mixin change | MEDIUM | All adopting classes + MRO tests |
| `__init` signature change | HIGH | All subclasses + instantiation tests |
| `afterLoad` change | MEDIUM | Save/load cycle test |

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Author | | | |
| Reviewer | | | |
| QA Lead | | | |

---

**Remember:** The class system touches ALL game systems. A broken `__init` chain breaks entity spawning. A broken MRO breaks UI rendering. A broken `class.is` breaks type checks everywhere. **Test thoroughly.**
