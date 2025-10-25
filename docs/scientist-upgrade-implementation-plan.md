# Scientist Upgrade System - Implementation Plan

**Project:** Frankenstein Dragon Factory
**Feature:** Tier-based Scientist Upgrade System
**Start Date:** 2025-10-25
**Status:** 🔄 In Progress

---

## 📊 Progress Overview

- [x] **Phase 1:** Create Scientist Resource Class ✅
- [x] **Phase 2:** Rewrite ScientistManager ✅
- [x] **Phase 3:** Integrate Salary Payments ✅
- [x] **Phase 4:** Stitcher Automation (5 tiers) ✅
- [x] **Phase 5:** Caretaker Automation (5 tiers) ✅
- [x] **Phase 6:** Trainer Automation (5 tiers) ✅
- [x] **Phase 7:** ScientistCard UI Component ✅
- [x] **Phase 8:** ScientistManagementUI Screen ✅
- [ ] **Phase 9:** Save/Load Integration
- [ ] **Phase 10:** Integration Testing
- [ ] **Phase 11:** Balance Tuning & Bug Fixes

**Overall Progress:** 8/11 phases complete (73%)

---

## 🎯 Project Goals

Transform the current flat scientist system into a rich progression system with:
- **5 upgrade tiers** per scientist (Tier 0 = not hired, Tier 1-5 = upgrade levels)
- **Wave-based salary payments** (deducted after each wave)
- **Wave unlock requirements** (Tier 2 @ 25 waves, Tier 3 @ 50, Tier 4 @ 100, Tier 5 @ 200)
- **15 total automation abilities** (5 per scientist, unlocked progressively)
- **Full management UI** with upgrade cards showing abilities and costs

---

## 📋 Current State Analysis

### ✅ What Exists
- Basic scientist system with 3 types (Stitcher, Caretaker, Trainer)
- Flat hire cost + per-minute salary model
- Simple automation: dragon creation, feeding/healing, XP granting
- Scientists tracked as boolean flags in dictionary
- Working wave defense system with tower assignments
- TreasureVault (gold), InventoryManager (parts), DragonFactory (dragons)
- Part decay system with freezer storage

### ❌ What's Missing
- No tier/level system
- No upgrade mechanics
- No wave-based payments
- No wave unlock requirements
- Missing 12 automation abilities
- No upgrade UI
- No scientist state serialization for save/load

---

## 🔧 Phase-by-Phase Implementation

---

### **PHASE 1: Create Scientist Resource Class** ⏳

**Goal:** Create the core Scientist resource with tier data and ability checks

**File:** `scripts/scientist/scientist.gd`

**Tasks:**
- [ ] Create `scientist.gd` with `class_name Scientist extends Resource`
- [ ] Add `enum Type { STITCHER, CARETAKER, TRAINER }`
- [ ] Add state variables: `scientist_type`, `tier` (0-5), `is_hired`
- [ ] Define `TIER_DATA` constants for all 3 scientists (names, costs, salaries)
- [ ] Define `UNLOCK_REQUIREMENTS` array [0, 0, 25, 50, 100, 200]
- [ ] Add getter methods: `get_tier_name()`, `get_salary()`, `get_upgrade_cost()`
- [ ] Add validation: `can_upgrade(waves_completed)`
- [ ] Add 15 ability check methods:
  - Stitcher: `can_create_dragons()`, `can_auto_assign_defense()`, `can_auto_explore()`, `can_emergency_recall()`, `can_auto_freeze()`
  - Caretaker: `can_feed()`, `can_heal()`, `can_rest()`, `can_prevent_starvation()`, `can_repair_towers()`
  - Trainer: `enables_training()`, `can_auto_fill_training()`, `can_auto_collect_training()`, `can_auto_rotate()`, `can_passive_xp()`
- [ ] Add save/load: `to_save_dict()`, `load_from_dict()`

**Acceptance Criteria:**
- Can create Scientist instance: `var s = Scientist.new()`
- Can check abilities by tier: `s.tier = 3; s.can_auto_explore() == true`
- Can get upgrade info: `s.get_upgrade_cost()` returns correct value
- Wave requirements work: `s.can_upgrade(30)` returns correct bool

**Dependencies:** None

**Estimated Time:** 1-2 hours

---

### **PHASE 2: Rewrite ScientistManager** ⏳

**Goal:** Replace boolean dictionary with Scientist instances and tier-based hiring/upgrading

**File:** `scripts/managers/scientist_manager.gd`

**Tasks:**
- [ ] **BACKUP:** Copy current `scientist_manager.gd` → `scientist_manager_backup.gd`
- [ ] Replace `var hired_scientists: Dictionary` with:
  ```gdscript
  var stitcher: Scientist
  var caretaker: Scientist
  var trainer: Scientist
  ```
- [ ] In `_ready()`: Initialize 3 Scientist instances
- [ ] Rewrite `hire_scientist(type)`:
  - Check if already hired (tier >= 1)
  - Deduct Tier 1 hire cost from TreasureVault
  - Set `scientist.tier = 1` and `scientist.is_hired = true`
  - Emit `scientist_hired` signal
- [ ] Add new `upgrade_scientist(type)`:
  - Check if scientist is hired
  - Check wave requirements: `scientist.can_upgrade(DefenseManager.wave_number)`
  - Deduct upgrade cost
  - Increment `scientist.tier += 1`
  - Emit `scientist_upgraded` signal
- [ ] Update `get_total_salary()`: Sum salaries from all 3 scientists
- [ ] Add `pay_salaries()` method (called by DefenseManager):
  - Calculate total salary cost
  - Deduct from TreasureVault
  - Return success/failure
  - Emit `salary_paid` or `salary_failed` signal
- [ ] Remove per-minute cost timers (no longer needed)
- [ ] Update all automation methods to use tier checks:
  - `if stitcher.can_create_dragons():` instead of `if hired_scientists[STITCHER]:`
- [ ] Update `to_dict()` / `from_dict()` to serialize Scientist objects

**Acceptance Criteria:**
- Can hire scientist at Tier 1: `hire_scientist(Scientist.Type.STITCHER)`
- Can upgrade scientist: `upgrade_scientist(Scientist.Type.STITCHER)` increases tier
- Salary payments work: `pay_salaries()` deducts correct gold amount
- Wave requirements block upgrades: Can't upgrade to Tier 2 until 25 waves
- Automation still works with tier checks

**Dependencies:** Phase 1 (Scientist class must exist)

**Estimated Time:** 2-3 hours

---

### **PHASE 3: Integrate Salary Payments** ⏳

**Goal:** Hook salary payments into wave completion system

**File:** `scripts/managers/defense_manager.gd`

**Tasks:**
- [ ] Open `defense_manager.gd`, find `_complete_wave()` method
- [ ] Add salary payment call after wave victory:
  ```gdscript
  if victory:
      var rewards = _calculate_rewards(enemies)
      _apply_rewards(rewards)

      # Pay scientist salaries
      if ScientistManager.instance:
          ScientistManager.instance.pay_salaries()

      wave_number += 1
  ```
- [ ] Test salary deduction happens after each wave
- [ ] Handle insufficient funds (show notification or auto-fire scientists)

**Acceptance Criteria:**
- Salaries deducted after each wave victory
- Gold correctly deducted from TreasureVault
- Signals emit for UI updates
- Game doesn't crash if player can't afford salaries

**Dependencies:** Phase 2 (ScientistManager must have `pay_salaries()`)

**Estimated Time:** 30 minutes

---

### **PHASE 4: Stitcher Automation (5 Tiers)** ⏳

**Goal:** Implement all 5 Stitcher automation abilities

**File:** `scripts/managers/scientist_manager.gd`

**Tasks:**

#### Tier 1: Auto-create dragons ✓ (Already exists)
- [ ] Add tier check to existing `_on_stitcher_work()`:
  ```gdscript
  if not stitcher.can_create_dragons():
      return
  ```
- [ ] Keep existing dragon creation logic

#### Tier 2: Auto-assign to defense
- [ ] Add `_auto_assign_defense()` method
- [ ] Get idle dragons from dragon factory
- [ ] Find empty defense tower slots via `DefenseTowerManager`
- [ ] Call `DefenseManager.assign_dragon_to_tower(dragon, tower_index)`
- [ ] Emit action performed signal

#### Tier 3: Auto-send exploring
- [ ] Add `_auto_send_exploring()` method
- [ ] Check if defense is full: `DefenseManager.get_defending_dragons().size() == max_defenders`
- [ ] Get idle dragons
- [ ] Send on shortest exploration: `ExplorationManager.start_exploration(dragon, 1, "volcanic_caves")`
- [ ] Emit action performed signal

#### Tier 4: Emergency recall
- [ ] Add `_auto_emergency_recall()` method
- [ ] Detect if defense needs help:
  - Empty tower slots: `DefenseManager.tower_assignments.size() < max_defenders`
  - Damaged towers: Check `DefenseTowerManager.get_towers()` health
- [ ] Get exploring dragons: `ExplorationManager.active_explorations`
- [ ] Find nearest (soonest to complete) explorer
- [ ] Recall early (create new method in ExplorationManager if needed)
- [ ] Reassign to defense

#### Tier 5: Auto-freeze parts
- [ ] Add `_auto_freeze_parts()` method
- [ ] Loop through `DragonDeathManager.instance.recovered_parts`
- [ ] Check decay time: `part.get_time_until_decay() < 21600` (< 6 hours)
- [ ] Find empty freezer slot: `DragonDeathManager.instance.is_freezer_slot_empty(i)`
- [ ] Freeze part: `DragonDeathManager.instance.freeze_part(part, slot_index)`
- [ ] Emit action performed signal

**Acceptance Criteria:**
- Tier 1: Dragons auto-created from 3+ parts every 60 seconds
- Tier 2: Created dragons auto-assigned to empty defense towers
- Tier 3: Idle dragons auto-sent exploring when defense is full
- Tier 4: Explorers recalled when tower destroyed or dragon dies
- Tier 5: Parts auto-frozen when < 6 hours from decay

**Dependencies:** Phase 2

**Estimated Time:** 3-4 hours

---

### **PHASE 5: Caretaker Automation (5 Tiers)** ⏳

**Goal:** Implement all 5 Caretaker automation abilities

**File:** `scripts/managers/scientist_manager.gd`

**Tasks:**

#### Tier 1: Auto-feed ✓ (Already exists)
- [ ] Add tier check to existing `_on_caretaker_work()`:
  ```gdscript
  if not caretaker.can_feed():
      return
  ```
- [ ] Keep existing feeding logic (hunger > 50%)

#### Tier 2: Auto-heal ✓ (Already exists)
- [ ] Add tier check: `if caretaker.can_heal():`
- [ ] Keep existing healing logic (HP < 75%)

#### Tier 3: Auto-rest fatigued dragons
- [ ] Add `_auto_rest_dragons()` method
- [ ] Get defending dragons: `DefenseManager.get_defending_dragons()`
- [ ] Check fatigue: `dragon.fatigue_level > 0.7`
- [ ] Remove from defense: `DefenseManager.remove_dragon_from_defense(dragon)`
- [ ] Dragon returns to IDLE state to rest
- [ ] Emit action performed signal

#### Tier 4: Prevent starvation
- [ ] Modify existing feed logic:
  ```gdscript
  var hunger_threshold = 50.0
  if caretaker.can_prevent_starvation():
      hunger_threshold = 20.0  # More aggressive

  if dragon.hunger_level > (100 - hunger_threshold):
      _feed_dragon(dragon)
  ```
- [ ] Priority feed dragons below 20% hunger

#### Tier 5: Auto-repair towers
- [ ] Add `_auto_repair_towers()` method
- [ ] Get all towers: `DefenseTowerManager.instance.get_towers()`
- [ ] Check tower health: `tower.current_health < tower.max_health * 0.5`
- [ ] Spend gold to repair: `TreasureVault.spend_gold(repair_cost)`
- [ ] Restore tower HP: `tower.current_health = tower.max_health`
- [ ] Emit action performed signal

**Acceptance Criteria:**
- Tier 1: Dragons fed when hunger > 50%
- Tier 2: Dragons healed when HP < 75%
- Tier 3: Fatigued defenders (>70%) removed from defense to rest
- Tier 4: Emergency feeding when hunger > 80% (prevents starvation)
- Tier 5: Towers repaired when HP < 50%

**Dependencies:** Phase 2

**Estimated Time:** 2-3 hours

---

### **PHASE 6: Trainer Automation (5 Tiers)** ⏳

**Goal:** Implement all 5 Trainer automation abilities

**File:** `scripts/managers/scientist_manager.gd`

**Tasks:**

#### Tier 1: Enable training yard
- [ ] Add flag to TrainingManager: `var trainer_enabled: bool = false`
- [ ] Check in TrainingManager when assigning dragons:
  ```gdscript
  func can_train() -> bool:
      if not ScientistManager.instance:
          return false
      return ScientistManager.instance.trainer.enables_training()
  ```
- [ ] Apply 50% speed bonus to training XP gain
- [ ] Block training UI if trainer not hired

#### Tier 2: Auto-fill training slots
- [ ] Add `_auto_fill_training()` method
- [ ] Get empty slots: `TrainingManager.instance.get_unlocked_slots().filter(not occupied)`
- [ ] Get idle dragons from factory
- [ ] Assign to training: `TrainingManager.instance.assign_to_training(dragon, slot)`
- [ ] Emit action performed signal

#### Tier 3: Auto-collect trained dragons
- [ ] Add `_auto_collect_training()` method
- [ ] Check all training slots for completion
- [ ] Collect completed dragons: `TrainingManager.instance.collect_from_slot(slot_id)`
- [ ] Dragons return to IDLE pool
- [ ] Emit action performed signal

#### Tier 4: Auto-rotate training
- [ ] Extend `_auto_collect_training()`:
  ```gdscript
  if trainer.can_auto_rotate():
      await get_tree().create_timer(10.0).timeout
      if dragon.current_state == Dragon.DragonState.IDLE:
          # Send back to training
          var empty_slots = TrainingManager.get_empty_slots()
          if empty_slots.size() > 0:
              TrainingManager.assign_to_training(dragon, empty_slots[0])
  ```
- [ ] Creates continuous training loop

#### Tier 5: Passive XP gain
- [ ] Add to existing `_on_trainer_work()`:
  ```gdscript
  if trainer.can_passive_xp():
      for dragon in factory.active_dragons:
          if dragon.current_state == Dragon.DragonState.DEFENDING:
              dragon_state_manager.gain_experience(dragon, 1)  # 10% of normal
          elif dragon.current_state == Dragon.DragonState.EXPLORING:
              dragon_state_manager.gain_experience(dragon, 0.5)  # 5% of normal
  ```
- [ ] Supplements regular training, doesn't replace it

**Acceptance Criteria:**
- Tier 1: Training yard enabled, 50% faster XP gain
- Tier 2: Idle dragons auto-assigned to empty training slots
- Tier 3: Dragons auto-collected when training completes
- Tier 4: Collected dragons auto-sent back to training (loop)
- Tier 5: Defending/exploring dragons gain passive XP every 30s

**Dependencies:** Phase 2

**Estimated Time:** 2-3 hours

---

### **PHASE 7: ScientistCard UI Component** ⏳

**Goal:** Create individual scientist card showing tier, abilities, and upgrade options

**Files:**
- `scenes/ui/scientist_card.tscn`
- `scripts/ui/scientist_card.gd`

**Tasks:**

#### Scene Structure
- [ ] Create `PanelContainer` root node
- [ ] Add `MarginContainer` → `VBoxContainer` layout
- [ ] Header: Icon + Name label
- [ ] Content (HBoxContainer):
  - Left panel: Portrait, Tier dots, Salary, Status
  - Right panel: Abilities list (5 items)
- [ ] Separator
- [ ] Upgrade section: Next tier info, cost, requirement, upgrade button
- [ ] Hire button (only visible if tier = 0)

#### Script Logic
- [ ] Add `@export var scientist_type: Scientist.Type`
- [ ] Store reference to actual Scientist instance
- [ ] Add `setup(type: Scientist.Type)` method
- [ ] Implement `_update_display()`:
  - Show current tier and name
  - Display tier dots (●●●○○)
  - Show salary per wave
  - List all 5 abilities with checkmarks (✓ unlocked, ○ locked)
- [ ] Implement `_show_upgrade_option()`:
  - Show next tier name and cost
  - Display new ability being unlocked
  - Check wave requirements
  - Enable/disable upgrade button
- [ ] Connect upgrade button to `ScientistManager.upgrade_scientist()`
- [ ] Connect hire button to `ScientistManager.hire_scientist()`
- [ ] Listen to signals for auto-refresh

**Visual Design:**
```
╔════════════════════════════════════════════════════════╗
║  🧵 STITCHER - Master Stitcher (Tier 3/5)             ║
╠════════════════════════════════════════════════════════╣
║                                                        ║
║  [Portrait]              CURRENT ABILITIES:           ║
║                          ✓ Creates dragons            ║
║  Tier: ●●●○○             ✓ Assigns to defense        ║
║                          ✓ Sends exploring            ║
║  Salary: 40g/wave        ○ Emergency recalls          ║
║  Status: ✓ Working       ○ Auto-freezes parts        ║
║                                                        ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                        ║
║  NEXT UPGRADE: Tier 4 - Grand Stitcher                ║
║  + NEW: Auto-recalls explorers for defense            ║
║  Cost: 15,000g  |  New Salary: 75g/wave               ║
║  Requires: 100 waves defeated (currently 73)          ║
║  [UPGRADE] (Locked - 27 more waves)                   ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
```

**Acceptance Criteria:**
- Card displays correctly for all 3 scientist types
- Tier dots update when upgraded
- Abilities show locked/unlocked states
- Upgrade button locks until wave requirement met
- Upgrade button disabled if insufficient gold
- Hire button works for tier 0 scientists

**Dependencies:** Phase 2 (ScientistManager must have upgrade methods)

**Estimated Time:** 3-4 hours

---

### **PHASE 8: ScientistManagementUI Screen** ⏳

**Goal:** Create full-screen management UI with all 3 scientist cards

**Files:**
- `scenes/ui/scientist_management_ui.tscn`
- `scripts/ui/scientist_management_ui.gd`

**Tasks:**

#### Scene Structure
- [ ] Create `Control` root (full screen overlay)
- [ ] Add dark overlay background
- [ ] Add `CenterContainer` with `PanelContainer`
- [ ] Add `MarginContainer` → `VBoxContainer` layout
- [ ] Title label: "SCIENTIST MANAGEMENT"
- [ ] Card container (HBoxContainer):
  - Instance ScientistCard (Stitcher)
  - Instance ScientistCard (Caretaker)
  - Instance ScientistCard (Trainer)
- [ ] Separator
- [ ] Footer panel:
  - Total salary label
  - Next payment label
  - Treasury balance label
- [ ] Close button

#### Script Logic
- [ ] Get references to 3 ScientistCard instances
- [ ] In `_ready()`: Setup each card with its type
- [ ] Connect to ScientistManager signals for updates
- [ ] Implement `_update_footer()`:
  - Calculate total salaries: `ScientistManager.get_total_salary()`
  - Show next payment wave: `DefenseManager.wave_number + 1`
  - Calculate waves affordable: `gold / total_salary`
- [ ] Update footer every frame in `_process()`
- [ ] Close button returns to game

**Visual Design:**
```
╔════════════════════════════════════════════════════════╗
║                  SCIENTIST MANAGEMENT                  ║
╠════════════════════════════════════════════════════════╣
║                                                        ║
║  [Stitcher Card]  [Caretaker Card]  [Trainer Card]    ║
║                                                        ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                        ║
║  TOTAL SALARIES: 142g/wave                            ║
║  Next Payment In: Wave 48 (3m 15s)                    ║
║  Treasury Balance: 2,847g (20 waves of salaries)      ║
║                                                        ║
║  [Close]                                               ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
```

**Acceptance Criteria:**
- All 3 scientist cards display correctly
- Footer shows accurate financial info
- Close button works
- UI updates when scientists hired/upgraded
- Responsive to screen size

**Dependencies:** Phase 7 (ScientistCard must exist)

**Estimated Time:** 2-3 hours

---

### **PHASE 9: Save/Load Integration** ⏳

**Goal:** Persist scientist tier state across game sessions

**File:** `scripts/managers/save_load_manager.gd`

**Tasks:**
- [ ] Find save/load methods in SaveLoadManager
- [ ] Update save method to include:
  ```gdscript
  save_data["scientists"] = ScientistManager.instance.to_dict()
  ```
- [ ] Update load method to restore:
  ```gdscript
  if save_data.has("scientists"):
      ScientistManager.instance.from_dict(save_data["scientists"])
  ```
- [ ] Ensure ScientistManager.to_dict() returns:
  ```gdscript
  {
      "stitcher": stitcher.to_save_dict(),
      "caretaker": caretaker.to_save_dict(),
      "trainer": trainer.to_save_dict()
  }
  ```
- [ ] Ensure ScientistManager.from_dict() restores all 3 scientists

**Acceptance Criteria:**
- Save game with Tier 3 Stitcher
- Quit and reload
- Stitcher still at Tier 3 with correct abilities
- Automation still works after load

**Dependencies:** Phase 2 (Scientist serialization methods)

**Estimated Time:** 1 hour

---

### **PHASE 10: Integration Testing** ⏳

**Goal:** Test all features working together

**Test Cases:**

#### Hiring & Upgrading
- [ ] Hire Stitcher at Tier 1 (costs 500g)
- [ ] Verify salary deducted after wave (10g)
- [ ] Upgrade to Tier 2 at wave 25 (costs 1,500g)
- [ ] Verify can't upgrade to Tier 3 before wave 50
- [ ] Verify salary increases after upgrade (20g)

#### Stitcher Automation
- [ ] Tier 1: Dragons auto-created from parts
- [ ] Tier 2: Created dragons auto-assigned to defense
- [ ] Tier 3: Idle dragons auto-sent exploring when defense full
- [ ] Tier 4: Explorers recalled when tower destroyed
- [ ] Tier 5: Parts auto-frozen when < 6 hours decay

#### Caretaker Automation
- [ ] Tier 1: Dragons auto-fed when hunger > 50%
- [ ] Tier 2: Dragons auto-healed when HP < 75%
- [ ] Tier 3: Fatigued defenders removed from defense
- [ ] Tier 4: Emergency feeding at hunger > 80%
- [ ] Tier 5: Towers auto-repaired when HP < 50%

#### Trainer Automation
- [ ] Tier 1: Training yard enabled, 50% faster
- [ ] Tier 2: Idle dragons auto-fill training slots
- [ ] Tier 3: Completed dragons auto-collected
- [ ] Tier 4: Collected dragons auto-rotated back to training
- [ ] Tier 5: Passive XP for defending/exploring dragons

#### UI Testing
- [ ] ScientistCard shows correct tier and abilities
- [ ] Upgrade button locks until wave requirement met
- [ ] Upgrade button disabled if insufficient gold
- [ ] Footer shows correct salary totals
- [ ] UI updates when scientist hired/upgraded

#### Save/Load Testing
- [ ] Save with multiple scientists at different tiers
- [ ] Quit and reload
- [ ] Verify all tiers restored correctly
- [ ] Verify automation still works

**Acceptance Criteria:**
- All 15 automation abilities working
- All tier unlocks working at correct waves
- Salary payments deducting correctly
- UI displaying accurate information
- Save/load preserving all state

**Dependencies:** Phases 1-9

**Estimated Time:** 2-3 hours

---

### **PHASE 11: Balance Tuning & Bug Fixes** ⏳

**Goal:** Adjust costs/benefits and fix any discovered issues

**Tasks:**

#### Balance Review
- [ ] Test early game (waves 1-25):
  - Can player afford Tier 1 Caretaker?
  - Are salaries too expensive?
- [ ] Test mid game (waves 25-100):
  - Can player afford multiple Tier 2-3 scientists?
  - Is progression too fast/slow?
- [ ] Test late game (waves 100+):
  - Can player afford Tier 4-5 scientists?
  - Are high-tier abilities worth the cost?

#### Cost Adjustments (if needed)
- [ ] Adjust hire costs if too cheap/expensive
- [ ] Adjust upgrade costs if progression too fast/slow
- [ ] Adjust salaries if bankrupting player

#### Bug Fixes
- [ ] Fix any crashes found during testing
- [ ] Fix any automation not working correctly
- [ ] Fix any UI display issues
- [ ] Fix any save/load bugs

#### Polish
- [ ] Add sound effects for hire/upgrade
- [ ] Add visual feedback for automation actions
- [ ] Add tooltips for abilities
- [ ] Add animations for tier upgrades

**Acceptance Criteria:**
- No crashes during normal gameplay
- Costs feel balanced for progression pace
- All automation working reliably
- UI looks polished and professional

**Dependencies:** Phase 10 (testing must reveal issues first)

**Estimated Time:** 2-4 hours

---

## 📈 Success Metrics

**Feature Complete When:**
- ✅ All 3 scientists have 5 functional tiers
- ✅ All 15 automation abilities working correctly
- ✅ Wave-based salary payments integrated
- ✅ UI shows all scientist info clearly
- ✅ Save/load preserves scientist state
- ✅ No crashes or game-breaking bugs
- ✅ Balanced progression from waves 1-200+

**Quality Gates:**
- Each phase tested before moving to next
- No regressions in existing systems
- Performance acceptable (60 FPS maintained)
- Code documented with comments

---

## 🔗 Integration Points

**Systems This Feature Touches:**
- `ScientistManager` - Complete rewrite
- `DefenseManager` - Salary payment hook
- `DragonFactory` - Dragon creation/assignment
- `DefenseTowerManager` - Tower assignments
- `ExplorationManager` - Exploration starts/recalls
- `TrainingManager` - Training automation
- `DragonDeathManager` - Part freezing
- `TreasureVault` - Gold deductions
- `SaveLoadManager` - State persistence

**New Files Created:**
- `scripts/scientist/scientist.gd` (NEW)
- `scripts/managers/scientist_manager_backup.gd` (BACKUP)
- `scenes/ui/scientist_card.tscn` (NEW)
- `scripts/ui/scientist_card.gd` (NEW)
- `scenes/ui/scientist_management_ui.tscn` (NEW)
- `scripts/ui/scientist_management_ui.gd` (NEW)

**Modified Files:**
- `scripts/managers/scientist_manager.gd` (MAJOR REWRITE)
- `scripts/managers/defense_manager.gd` (MINOR - add salary payment)
- `scripts/managers/save_load_manager.gd` (MINOR - add scientist save/load)

---

## 🚨 Risk Mitigation

**Potential Issues:**

1. **Breaking Existing Automation**
   - Mitigation: Backup original file, test thoroughly after Phase 2
   - Rollback: Restore `scientist_manager_backup.gd`

2. **Save Game Compatibility**
   - Mitigation: Add migration logic for old saves
   - Fallback: Default all scientists to tier 0 if load fails

3. **Performance Impact**
   - Mitigation: Keep automation timer intervals (60s/30s)
   - Monitor: Check FPS during automation cycles

4. **Balance Issues**
   - Mitigation: Placeholder costs based on spec, adjust in Phase 11
   - Iteration: Playtest at different wave counts

---

## 📝 Notes & Decisions

### Design Decisions
- **Why per-wave salary instead of per-minute?**
  - Aligns with game's core loop (wave-based progression)
  - More predictable costs for player
  - Easier to balance with wave rewards

- **Why tier 0 = "not hired" instead of tier 1?**
  - Allows consistent array indexing (tier matches array index)
  - Clear state: tier 0 = disabled, tier 1+ = active

- **Why 6 hours for auto-freeze threshold?**
  - Gives players time to manually freeze if desired
  - Prevents last-minute decay for offline players
  - Matches "warning" urgency level in part system

### Open Questions
- [ ] Should scientists auto-fire if player can't afford salary?
- [ ] Should there be a "pause scientists" toggle?
- [ ] Should scientist portraits change per tier?

---

## 📅 Timeline Estimate

**Total Estimated Time:** 25-35 hours

**Breakdown:**
- Phase 1: 1-2 hours
- Phase 2: 2-3 hours
- Phase 3: 0.5 hours
- Phase 4: 3-4 hours
- Phase 5: 2-3 hours
- Phase 6: 2-3 hours
- Phase 7: 3-4 hours
- Phase 8: 2-3 hours
- Phase 9: 1 hour
- Phase 10: 2-3 hours
- Phase 11: 2-4 hours

**Target Completion:** Based on current date (Oct 25), could be completed in 3-5 work sessions

---

## ✅ Completion Checklist

**Phase 1 Complete When:**
- [ ] Scientist.gd file created and tested
- [ ] All ability check methods working
- [ ] Save/load methods implemented

**Phase 2 Complete When:**
- [ ] ScientistManager rewritten and tested
- [ ] Backup created
- [ ] Hiring/upgrading working
- [ ] Automation using tier checks

**Phase 3 Complete When:**
- [ ] Salaries deducted after each wave
- [ ] No crashes during payment

**Phase 4 Complete When:**
- [ ] All 5 Stitcher tiers working
- [ ] Actions logged to console

**Phase 5 Complete When:**
- [ ] All 5 Caretaker tiers working
- [ ] Actions logged to console

**Phase 6 Complete When:**
- [ ] All 5 Trainer tiers working
- [ ] Actions logged to console

**Phase 7 Complete When:**
- [ ] ScientistCard displays all info correctly
- [ ] Upgrade button works

**Phase 8 Complete When:**
- [ ] Management UI shows all 3 cards
- [ ] Footer calculates correctly

**Phase 9 Complete When:**
- [ ] Save/load tested and working
- [ ] No data loss on reload

**Phase 10 Complete When:**
- [ ] All test cases pass
- [ ] No critical bugs found

**Phase 11 Complete When:**
- [ ] Costs balanced
- [ ] All bugs fixed
- [ ] Feature polished and ready to ship

---

**Last Updated:** 2025-10-25
**Next Review:** After each phase completion