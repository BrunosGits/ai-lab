# Staff Training Area - Pre-Fix Checklist

This checklist must be completed before making any changes to the staff training system. Each item must be verified and signed off.

---

## 1. Code Understanding & Analysis

### 1.1 Base Staff System (staff.lua)
- [ ] Read and understand full `entities/humanoids/staff.lua` (775 lines)
- [ ] Identify all public methods and their contracts
- [ ] Map fatigue/happiness update loops
- [ ] Document training state machine
- [ ] Review serialization/deserialization format
- [ ] Identify all constants and magic numbers

### 1.2 Staff Type Specializations
- [ ] `entities/humanoids/staff/doctor.lua` - Diagnosis, treatment, surgery, research logic
- [ ] `entities/humanoids/staff/nurse.lua` - Patient care, pharmacy, ward management
- [ ] `entities/humanoids/staff/handyman.lua` - Repair, plants, transport, task queue
- [ ] `entities/humanoids/staff/receptionist.lua` - Check-in, queue prioritization, phone calls

### 1.3 Training Room System (training.lua:74-199)
- [ ] Understand `commandEnteringStaff` / `commandLeavingStaff` handlers
- [ ] Verify logarithmic training factor calculation
- [ ] Review equipment quality/condition impact
- [ ] Check trainer bonus implementation
- [ ] Validate MAX_TRAINING_FACTOR cap

### 1.4 Staff Profiles (staff_profile.lua:286 lines)
- [ ] Review all profile definitions
- [ ] Verify skill caps per level
- [ ] Check experience curve progression
- [ ] Validate trait effects
- [ ] Confirm hire costs

### 1.5 Salary System (hospital.lua:1207-1279)
- [ ] Trace `calculateSalary()` logic
- [ ] Verify level-up increase (15%)
- [ ] Check skill mastery bonus (5% per skill ≥90)
- [ ] Validate tenure bonus (2%/year)
- [ ] Confirm performance bonus (10% for >90 rating)
- [ ] Review annual review process

---

## 2. Regression Test Baseline

### 2.1 Automated Tests (Run Before Changes)
- [ ] `busted SCAFFOLD.lua` - All test suites pass
- [ ] Fatigue management tests pass
- [ ] Happiness management tests pass
- [ ] Salary progression tests pass
- [ ] Skill progression tests pass
- [ ] Training system tests pass
- [ ] Handyman task tests pass
- [ ] Receptionist behavior tests pass
- [ ] Training room factor tests pass
- [ ] Profile system tests pass
- [ ] Integration/serialization tests pass
- [ ] Edge case tests pass

### 2.2 Manual Playtesting Scenarios
- [ ] Hire each staff type, verify starting stats
- [ ] Work staff to fatigue, verify break behavior
- [ ] Send staff to training, verify skill gain
- [ ] Check salary increases on level up
- [ ] Verify handyman repairs machines
- [ ] Verify handyman waters plants
- [ ] Test receptionist queue prioritization
- [ ] Test receptionist phone call handling
- [ ] Verify training room equipment scaling
- [ ] Check save/load preserves staff state

---

## 3. Change Impact Assessment

### 3.1 Fatigue/Happiness Changes
- [ ] Does change affect break threshold? (70/90)
- [ ] Does change affect recovery rates?
- [ ] Does change affect staff room seeking?
- [ ] Does change impact happiness decay?
- [ ] Does change affect resignation threshold? (15)

### 3.2 Salary Changes
- [ ] Does change affect base salary tables?
- [ ] Does change affect increase percentages?
- [ ] Does change affect market rate calculation?
- [ ] Does change impact annual review?
- [ ] Does change affect hire costs?

### 3.3 Training Changes
- [ ] Does change affect training base rate? (0.1/sec)
- [ ] Does change affect primary skill modifier? (1.5x)
- [ ] Does change affect logarithmic equipment scaling?
- [ ] Does change affect MAX_TRAINING_FACTOR? (5.0)
- [ ] Does change affect session max? (20 points)
- [ ] Does change affect trainer bonus?
- [ ] Does change affect prerequisites?

### 3.4 Handyman Changes
- [ ] Does change affect task priorities?
- [ ] Does change affect repair speed/quality?
- [ ] Does change affect plant care?
- [ ] Does change affect breakdown formula?
- [ ] Does change affect interrupt logic?

### 3.5 Receptionist Changes
- [ ] Does change affect queue prioritization order?
- [ ] Does change affect check-in speed?
- [ ] Does change affect phone call frequency?
- [ ] Does change affect department assignment?

### 3.6 Cross-System Impacts
- [ ] Patient diagnosis/treatment speed
- [ ] Research progression
- [ ] Hospital reputation (plants, queue times)
- [ ] Financial balance (salaries)
- [ ] Save/load compatibility
- [ ] Multiplayer sync (if applicable)

---

## 4. Implementation Checklist

### 4.1 Code Changes
- [ ] Modify only intended files
- [ ] Update constants in single location
- [ ] Add/update inline documentation
- [ ] Follow existing code style (indentation, naming)
- [ ] No hardcoded magic numbers
- [ ] Proper error handling (nil checks, bounds)

### 4.2 Testing Changes
- [ ] Add new test cases for changed behavior
- [ ] Update existing tests if contracts changed
- [ ] Verify all existing tests still pass
- [ ] Test edge cases (min/max values, nil inputs)

### 4.3 Documentation Updates
- [ ] Update SUMMARY.md if architecture changed
- [ ] Update CHECKLIST.md if new checks needed
- [ ] Update MAP.md if file/line references changed
- [ ] Update any inline code comments

---

## 5. Pre-Commit Verification

### 5.1 Code Quality
- [ ] `luacheck` passes on all modified files
- [ ] No syntax errors
- [ ] No undefined globals
- [ ] Consistent indentation (tabs/spaces per project)
- [ ] Meaningful variable names

### 5.2 Functional Verification
- [ ] All busted tests pass
- [ ] Manual playtest scenarios work
- [ ] No console errors/warnings
- [ ] Performance acceptable (no frame drops)

### 5.3 Save/Load Testing
- [ ] Save game with staff in various states
- [ ] Load game, verify staff state restored
- [ ] Verify training progress preserved
- [ ] Verify fatigue/happiness preserved
- [ ] Verify salary/experience preserved

### 5.4 Scenario Testing
- [ ] Test in early game (low level staff)
- [ ] Test in late game (max level staff)
- [ ] Test with multiple hospitals
- [ ] Test with all staff types simultaneously
- [ ] Test training room at capacity

---

## 6. Rollback Plan

### 6.1 Git Preparation
- [ ] Create feature branch from main
- [ ] Commit baseline (all tests passing)
- [ ] Make changes in small, logical commits
- [ ] Tag pre-change state: `git tag pre-staff-training-fix`

### 6.2 Rollback Procedure
```bash
# If issues found:
git stash                    # Save current changes
git checkout main            # Return to stable
git tag rollback-point       # Mark rollback
# Or full revert:
git reset --hard pre-staff-training-fix
```

### 6.3 Verification After Rollback
- [ ] All tests pass on rolled-back code
- [ ] Manual scenarios work
- [ ] No save game corruption

---

## 7. Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Developer | | | |
| Code Reviewer | | | |
| QA Lead | | | |

---

## 8. Change Log Template

```markdown
## [Date] - Staff Training Change

### Summary
Brief description of what changed and why.

### Files Modified
- entities/humanoids/staff.lua
- entities/humanoids/staff/doctor.lua
- etc.

### Key Changes
1. **Fatigue**: Changed break threshold from 70 to 65
2. **Salary**: Increased level-up bonus from 15% to 20%
3. **Training**: Adjusted logarithmic base from ln(1+x) to ln(1+1.5x)

### Testing
- All automated tests pass
- Manual scenarios verified
- Save/load tested

### Rollback Tag
pre-staff-training-fix-YYYYMMDD
```

---

## 9. Emergency Contacts

- **Lead Developer**: For architectural questions
- **QA Lead**: For testing blockers
- **DevOps**: For CI/CD pipeline issues
- **Community Manager**: For player-facing communication

---

*Checklist Version: 1.0*
*Last Updated: 2026-08-25*
*Area: area-05-staff-training*
