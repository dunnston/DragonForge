# Scientist Upgrade System - Testing Guide

## ⚠️ IMPORTANT: Scene File Changes Required

Before testing, you need to add the "Manage Scientists" button to the UI:

### Add Button to Top Bar

Open `scenes/main_scene/main_scene.tscn` (or wherever the factory UI scene is) and add a new Button node:

1. Find the TopBar HBoxContainer (where `ManageDefensesButton`, `ManageTrainingButton`, etc. are)
2. Add a new Button node called `ManageScientistsButton`
3. Set its text property to "MANAGE SCIENTISTS"
4. Position it next to the other management buttons
5. Set its unique name in owner to `true` if using `%` references

The button is already wired up in [factory_manager.gd](../scripts/ui/factory_manager.gd:186) to call `_on_manage_scientists_pressed()`.

---

## Phase 10: Integration Testing Checklist

### ✅ Step 1: UI Integration Test

**Goal**: Verify the Scientist Management UI opens and closes correctly

**Steps**:
1. Run the game
2. Look for "MANAGE SCIENTISTS" button in the top bar
3. Click the button
4. **Expected**: Full-screen Scientist Management UI appears with 3 scientist cards
5. Verify footer shows:
   - Total Salaries: 0 gold/wave
   - Next Payment: Wave X (timer)
   - Treasury: [current gold]
   - Can afford: 999+ waves (no scientists hired yet)
6. Click "CLOSE" button
7. **Expected**: Returns to factory UI

**Status**: ⬜ PASS / ⬜ FAIL

---

### ✅ Step 2: Hire Flow Test

**Goal**: Verify hiring scientists works correctly

**Prerequisites**: Have at least 600 gold (to hire Stitcher)

**Steps - Hire Stitcher**:
1. Open Scientist Management UI
2. Find the "STITCHER (Not Hired)" card
3. Verify it shows:
   - Tier: Not Hired
   - Tier dots: ○ ○ ○ ○ ○
   - Salary: --
   - Status: Idle (gray)
   - All 5 abilities showing with "○" (locked)
   - "HIRE (500 gold)" button visible and enabled
4. Click "HIRE (500 gold)" button
5. **Expected**:
   - Gold deducted by 500
   - Card updates to show "STITCHER - Apprentice Stitcher"
   - Tier: 1/5
   - Tier dots: ● ○ ○ ○ ○
   - Salary: 10 gold/wave
   - Status: Working (green)
   - First ability has "✓ Creates dragons" (unlocked, green)
   - Remaining 4 abilities still "○" (locked, gray)
   - Hire button disappears
   - Upgrade section appears showing:
     - "NEXT: Tier 2 - Journeyman Stitcher"
     - "+ NEW: Assigns to defense"
     - "Cost: 1,500 gold"
     - "New Salary: 20 gold/wave"
     - "Requires: 25 waves (X/25)"
6. Check footer:
   - Total Salaries: 10 gold/wave
   - Can afford: [treasury/10] waves

**Steps - Hire Caretaker** (if 400+ gold):
1. Find "CARETAKER (Not Hired)" card
2. Click "HIRE (400 gold)" button
3. Verify same transition as Stitcher
4. Check footer shows: Total Salaries: 18 gold/wave

**Steps - Hire Trainer** (if 600+ gold):
1. Find "TRAINER (Not Hired)" card
2. Click "HIRE (600 gold)" button
3. Verify same transition
4. Check footer shows: Total Salaries: 30 gold/wave

**Status**: ⬜ PASS / ⬜ FAIL

---

### ✅ Step 3: Wave-Based Salary Deduction Test

**Goal**: Verify salaries are deducted after each wave

**Prerequisites**: At least 1 scientist hired

**Steps**:
1. Note current treasury gold amount
2. Note current wave number
3. Note "Total Salaries" from footer
4. Wait for next wave to complete (or trigger manually)
5. **Expected**: After wave completes:
   - Gold deducted by total salary amount
   - Check console for: `[DefenseManager] ⚠️ WARNING: Failed to pay scientist salaries!` (if insufficient gold)
   - OR check for successful payment

**Test insufficient funds**:
1. Use console/debug to set gold to less than total salary
2. Complete a wave
3. **Expected**: Scientists should still function (payment just fails)

**Status**: ⬜ PASS / ⬜ FAIL

---

### ✅ Step 4: Upgrade Flow Test

**Goal**: Verify scientist upgrades work correctly

**Prerequisites**:
- Stitcher hired at Tier 1
- 25+ waves completed
- 1,500+ gold

**Steps - Upgrade Stitcher to Tier 2**:
1. Open Scientist Management UI
2. Find Stitcher card
3. Verify upgrade section shows:
   - "Requires: 25 waves (X/25)" where X >= 25
   - "UPGRADE (1,500 gold)" button is **enabled**
4. Click "UPGRADE (1,500 gold)" button
5. **Expected**:
   - Gold deducted by 1,500
   - Card updates:
     - Name: "STITCHER - Journeyman Stitcher"
     - Tier: 2/5
     - Tier dots: ● ● ○ ○ ○
     - Salary: 20 gold/wave
     - First ability: "✓ Creates dragons"
     - **Second ability: "✓ Assigns to defense"** (now unlocked, green)
     - Remaining 3 abilities still locked
     - Upgrade section shows Tier 3 info:
       - "NEXT: Tier 3 - Master Stitcher"
       - "+ NEW: Sends exploring"
       - "Cost: 5,000 gold"
       - "New Salary: 40 gold/wave"
       - "Requires: 50 waves (X/50)"
6. Check footer: Total Salaries increased by 10

**Test wave requirement blocking**:
1. If current wave < 50, verify upgrade button is **disabled**
2. Button text shows: "UPGRADE (Need X more waves)"

**Test gold requirement blocking**:
1. Set gold to < 5,000
2. Verify button is **disabled**
3. Button text shows: "UPGRADE (Need 5,000 gold)"

**Status**: ⬜ PASS / ⬜ FAIL

---

### ✅ Step 5: Stitcher Automation Tests

**Goal**: Verify all 5 Stitcher automation abilities

#### Tier 1: Auto-Create Dragons (every 60s)
**Prerequisites**: Stitcher Tier 1+, 3+ dragon parts in inventory

**Steps**:
1. Ensure you have at least 3 parts of any element in inventory
2. Note current dragon count
3. Wait 60 seconds
4. **Expected**: Console shows `[Stitcher T1] 🧬 Auto-created dragon: [name]`
5. Dragon list updates with new dragon
6. Parts removed from inventory

**Status**: ⬜ PASS / ⬜ FAIL

#### Tier 2: Auto-Assign to Defense (every 60s)
**Prerequisites**: Stitcher Tier 2+, idle dragon available, defense slot available

**Steps**:
1. Have at least 1 idle dragon
2. Ensure defense tower has empty slots
3. Wait 60 seconds
4. **Expected**:
   - Console shows `[Stitcher T2] 🛡️ Auto-assigned [dragon] to defense`
   - Dragon's state changes to DEFENDING
   - Defense slot filled

**Status**: ⬜ PASS / ⬜ FAIL

#### Tier 3: Auto-Send Exploring (every 60s)
**Prerequisites**: Stitcher Tier 3+, idle dragon available, defense slots FULL

**Steps**:
1. Fill all defense slots with dragons
2. Have at least 1 idle dragon
3. Wait 60 seconds
4. **Expected**:
   - Console shows `[Stitcher T3] 🗺️ Auto-sent [dragon] exploring to [location]`
   - Dragon's state changes to EXPLORING

**Status**: ⬜ PASS / ⬜ FAIL

#### Tier 4: Emergency Recall (every 60s)
**Prerequisites**: Stitcher Tier 4+, dragon exploring, defense slot empty

**Steps**:
1. Have 1+ dragon exploring
2. Ensure at least 1 defense slot is empty
3. Remove a dragon from defense (to create need)
4. Wait 60 seconds
5. **Expected**:
   - Console shows `[Stitcher T4] 🚨 Emergency recalled [dragon] from exploration`
   - Dragon's state changes from EXPLORING to DEFENDING

**Status**: ⬜ PASS / ⬜ FAIL

#### Tier 5: Auto-Freeze Parts (every 60s)
**Prerequisites**: Stitcher Tier 5+, recovered dragon part with < 6 hours until decay, empty freezer slot

**Steps**:
1. Kill a dragon to get recovered parts (or use existing recovered parts)
2. Wait until a part has < 6 hours until decay
3. Ensure at least 1 freezer slot is empty
4. Wait 60 seconds
5. **Expected**:
   - Console shows `[Stitcher T5] ❄️ Auto-froze [part name]`
   - Part moved from recovered parts to freezer

**Status**: ⬜ PASS / ⬜ FAIL

---

### ✅ Step 6: Caretaker Automation Tests

**Goal**: Verify all 5 Caretaker automation abilities

#### Tier 1: Auto-Feed (every 30s)
**Prerequisites**: Caretaker Tier 1+, dragon with hunger > 50%

**Steps**:
1. Have a dragon with > 50% hunger
2. Ensure you have food in inventory
3. Wait 30 seconds
4. **Expected**:
   - Console shows `[Caretaker T1] 🍖 Auto-fed [dragon]`
   - Dragon's hunger level decreased

**Status**: ⬜ PASS / ⬜ FAIL

#### Tier 2: Auto-Heal (every 30s)
**Prerequisites**: Caretaker Tier 2+, dragon with HP < 75%

**Steps**:
1. Damage a dragon so HP < 75% (via battle or debug)
2. Wait 30 seconds
3. **Expected**:
   - Console shows `[Caretaker T2] ❤️ Auto-healed [dragon] to full HP`
   - Dragon's HP restored to 100%

**Status**: ⬜ PASS / ⬜ FAIL

#### Tier 3: Auto-Rest (every 30s)
**Prerequisites**: Caretaker Tier 3+, defending dragon with fatigue > 70%

**Steps**:
1. Have a dragon assigned to defense with > 70% fatigue
2. Wait 30 seconds
3. **Expected**:
   - Console shows `[Caretaker T3] 😴 Sent [dragon] to rest from defense`
   - Dragon removed from defense, state = RESTING

**Status**: ⬜ PASS / ⬜ FAIL

#### Tier 4: Prevent Starvation (every 30s)
**Prerequisites**: Caretaker Tier 4+, dragon with hunger > 80% (20% food remaining)

**Steps**:
1. Let a dragon's hunger rise to > 80%
2. Ensure you have food
3. Wait 30 seconds
4. **Expected**:
   - Console shows `[Caretaker T4] 🚨 PREVENTED STARVATION for [dragon]`
   - Dragon fed aggressively

**Status**: ⬜ PASS / ⬜ FAIL

#### Tier 5: Auto-Repair Towers (every 30s)
**Prerequisites**: Caretaker Tier 5+, defense tower with HP < 50%

**Steps**:
1. Damage a defense tower to < 50% HP (via battle or debug)
2. Ensure you have repair materials
3. Wait 30 seconds
4. **Expected**:
   - Console shows `[Caretaker T5] 🔧 Auto-repaired tower [ID]`
   - Tower HP restored to 100%

**Status**: ⬜ PASS / ⬜ FAIL

---

### ✅ Step 7: Trainer Automation Tests

**Goal**: Verify all 5 Trainer automation abilities

#### Tier 1: Training Yard Enabled (+50% speed)
**Prerequisites**: Trainer Tier 1+

**Steps**:
1. Open Training Yard UI
2. Manually assign a dragon to training
3. **Expected**: Training completes 50% faster than without trainer

**Status**: ⬜ PASS / ⬜ FAIL

#### Tier 2: Auto-Fill Training (every 30s)
**Prerequisites**: Trainer Tier 2+, idle dragon, empty training slot

**Steps**:
1. Ensure training yard has empty slots
2. Have at least 1 idle dragon
3. Wait 30 seconds
4. **Expected**:
   - Console shows `[Trainer T2] 📚 Auto-assigned [dragon] to training`
   - Dragon state = TRAINING

**Status**: ⬜ PASS / ⬜ FAIL

#### Tier 3: Auto-Collect Training (every 30s)
**Prerequisites**: Trainer Tier 3+, dragon with completed training

**Steps**:
1. Have a dragon complete training (100% progress)
2. Wait 30 seconds
3. **Expected**:
   - Console shows `[Trainer T3] 🎓 Auto-collected [dragon] from training`
   - Dragon removed from training slot
   - Dragon gained XP
   - Dragon state = IDLE

**Status**: ⬜ PASS / ⬜ FAIL

#### Tier 4: Auto-Rotate Training (every 30s)
**Prerequisites**: Trainer Tier 4+, dragon collected from training, empty training slot

**Steps**:
1. Have Tier 3 auto-collect a dragon
2. Ensure training slot is now empty
3. Wait 30 seconds
4. **Expected**:
   - Console shows `[Trainer T4] 🔄 Auto-rotated [dragon] back to training`
   - Same dragon re-assigned to training (continuous loop)

**Status**: ⬜ PASS / ⬜ FAIL

#### Tier 5: Passive XP Gain (every 30s)
**Prerequisites**: Trainer Tier 5+, dragon in DEFENDING or EXPLORING state

**Steps**:
1. Have a dragon assigned to defense or exploration
2. Note dragon's current XP
3. Wait 30 seconds
4. **Expected**:
   - Console shows `[Trainer T5] ⭐ [dragon] gained 5 passive XP while [state]`
   - Dragon XP increased by 5

**Status**: ⬜ PASS / ⬜ FAIL

---

### ✅ Step 8: Save/Load Persistence Test

**Goal**: Verify all scientist state persists across save/load

**Steps**:
1. Hire all 3 scientists
2. Upgrade at least 1 scientist to Tier 2+
3. Note:
   - Each scientist's tier
   - Each scientist's hire status
   - Total salaries amount
4. Save the game (ESC → Save & Exit)
5. Completely quit and restart the game
6. Load the save file
7. Open Scientist Management UI
8. **Expected**:
   - All 3 scientists still hired
   - All tier levels preserved
   - All abilities unlocked/locked correctly
   - Total salaries matches saved state
   - Automation continues working

**Status**: ⬜ PASS / ⬜ FAIL

---

### ✅ Step 9: Max Tier Test

**Goal**: Verify Tier 5 (max tier) behavior

**Prerequisites**: Scientist at Tier 5, 200+ waves completed, 50,000+ gold

**Steps**:
1. Upgrade a scientist to Tier 5
2. Open Scientist Management UI
3. Find the Tier 5 scientist card
4. **Expected**:
   - Tier: 5/5
   - Tier dots: ● ● ● ● ●
   - All 5 abilities showing "✓" (unlocked)
   - Upgrade section shows:
     - "MAX TIER REACHED" (no next tier info)
     - No upgrade button
     - No cost/salary/wave requirement labels

**Status**: ⬜ PASS / ⬜ FAIL

---

## 🐛 Bug Tracking

### Known Issues
- [ ] (Add any bugs found during testing here)

### Fixed Issues
- [ ] (Move fixed bugs here)

---

## 📊 Testing Summary

**Total Tests**: 9
**Passed**: ___
**Failed**: ___
**Not Tested**: ___

**Overall Status**: ⬜ READY FOR MERGE / ⬜ NEEDS FIXES

---

## 🎯 Next Steps After Testing

1. **If all tests pass**:
   - Move to Phase 11: Balance tuning
   - Consider adjusting costs, salaries, and wave requirements based on playtesting
   - Merge to main branch

2. **If bugs found**:
   - Document bugs in "Known Issues" section
   - Create GitHub issues for tracking
   - Fix bugs and re-test

3. **Balance tuning suggestions**:
   - Are hire costs too high/low?
   - Are salaries sustainable?
   - Are wave requirements appropriate for progression pace?
   - Do automation intervals feel good (60s for Stitcher, 30s for Caretaker/Trainer)?
