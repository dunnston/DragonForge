# Knight Raid System - Implementation Summary

## Overview
This document summarizes the implementation of the wave-based knight raid system with tower destruction, dragon deaths, and knight meat drops.

---

## ✅ Completed Implementation

### 1. **Knight Meat Item** (`data/items.json`)
- Added `knight_meat` consumable item
- **Effects:**
  - Hunger reduction: -30% (better than regular food's -25%)
  - Fatigue increase: +15% (heavy meat penalty)
- **Rarity:** 2 (uncommon)
- **Icon:** `res://assets/ui/knight-meat.png`

### 2. **Defense Manager Updates** (`scripts/managers/defense_manager.gd`)
**Changed from array-based to tower-specific dragon assignment:**
- `defending_dragons: Array[Dragon]` → `tower_assignments: Dictionary`
- New methods:
  - `assign_dragon_to_tower(dragon, tower_index)` - Assign dragon to specific tower
  - `remove_dragon_from_tower(tower_index)` - Remove dragon from tower
  - `get_dragon_for_tower(tower_index)` - Get dragon for specific tower
  - `get_tower_assignments()` - Get all assignments

**Knight Meat Drop System:**
- Chance-based drops (not guaranteed):
  - Normal knights: 50% chance → 1 meat
  - Boss knights: 75% chance → 2-3 meat
- Added to inventory via `InventoryManager`

**Dragon Death on Tower Destruction:**
- Tracks which towers are destroyed during wave
- Kills dragons assigned to destroyed towers
- Calls `dragon._die()` and notifies `DragonStateManager`
- Removes dead dragons from assignments

**Updated Serialization:**
- Saves tower assignments as `{tower_index: dragon_id}`
- Restores assignments on load

### 3. **Defense Tower Manager Updates** (`scripts/managers/defense_tower_manager.gd`)
**New Constants:**
- `REBUILD_COST = 75` - Flat cost to rebuild destroyed tower
- `MASSIVE_DAMAGE = 40` - Damage when no defenders (for future use)

**New Methods:**
- `can_rebuild_tower(tower_index)` - Check if tower can be rebuilt
- `rebuild_tower(tower_index)` - Rebuild destroyed tower for 75 gold
  - Restores tower to full HP
  - Emits `tower_repaired` signal
  - Updates defense capacity

### 4. **Dragon State Manager Updates** (`scripts/dragon_system/dragon_state_manager.gd`)
**New Constants:**
- `KNIGHT_MEAT_HUNGER_HEAL = 0.30` - 30% hunger reduction
- `KNIGHT_MEAT_FATIGUE_COST = 0.15` - 15% fatigue increase

**New Method:**
- `use_knight_meat_on_dragon(dragon)` - Feed knight meat to dragon
  - Reduces hunger by 30%
  - Increases fatigue by 15%
  - Updates last_fed_time
  - Prints detailed feedback

### 5. **Dragon Details Modal Updates** (`scripts/ui/dragon_details_modal.gd`)
**Added Knight Meat Button:**
- New button: "Feed Knight Meat"
- Handler: `_on_knight_meat_pressed()`
- Calls `DragonStateManager.use_knight_meat_on_dragon()`
- Refreshes display on success

### 6. **Defense Tower UI Updates** (`scripts/ui/defense_towers_ui.gd`)
**Updated Dragon Assignment:**
- Now uses `assign_dragon_to_tower(dragon, tower_index)`
- Passes tower_index to dragon picker modal
- Shows success/failure feedback

**New Rebuild Handler:**
- `_on_rebuild_clicked(tower_index)` - Handles rebuild button press
- Calls `DefenseTowerManager.rebuild_tower()`
- Refreshes UI on success

### 7. **Tower Card Updates** (`scripts/ui/tower_card.gd`)
**Tower-Specific Dragon Assignment:**
- Updated `_get_assigned_dragon()` to use `get_dragon_for_tower(tower_index)`
- Updated `_unassign_dragon()` to use `remove_dragon_from_tower(tower_index)`

**Rebuild Button Logic:**
- Shows rebuild button only for destroyed towers
- Hides repair button for destroyed towers
- Shows cost (75g) and disables if insufficient gold
- Emits `rebuild_clicked` signal

---

## ⚠️ Manual Steps Required

### 1. **Add Images to Assets**
You need to copy these images to the project:

**Source:** Provided by user (knight.png, knight-meat.png)
**Destination:** `assets/ui/`

```
assets/ui/knight.png        (Knight sprite)
assets/ui/knight-meat.png   (Meat icon)
```

### 2. **Update Tower Card Scene** (`scenes/ui/towers/tower_card.tscn`)
The `tower_card.gd` script expects a `RebuildButton` node. Add it to the scene:

**In Godot Editor:**
1. Open `scenes/ui/towers/tower_card.tscn`
2. Find the `VBox` container
3. Add a new `Button` node after `RepairButton`
4. Name it: `RebuildButton`
5. Add child `Label` node named `CostLabel` (for displaying "75g")
6. Configure button:
   - Text: "Rebuild Tower"
   - Custom minimum size: Similar to RepairButton
   - Initially visible: false (script will show/hide)

**Node Structure:**
```
VBox
  ├── RepairButton
  │   └── CostLabel
  ├── RebuildButton (NEW)
  │   └── CostLabel (NEW)
  └── ...
```

---

## 🎮 Game Flow Summary

### Combat Flow
```
Wave Starts
  ↓
Knights Attack (check for defenders)
  ↓
[IF DEFENDERS EXIST]
  Dragons Fight Knights
    ↓
    [VICTORY]
      - Knights die → 50% chance drop 1 meat (boss: 75% → 2-3 meat)
      - Towers take 5 damage each
      - Dragons gain XP, +10% fatigue
    ↓
    [DEFEAT]
      - Towers take 20 damage each
      - Dragons take damage
      - Vault loses resources
      - Check tower destruction → Kill assigned dragons
  ↓
[IF NO DEFENDERS]
  Auto-Loss
    - Towers take 40 damage each (future)
    - Vault loses 50% resources
    - Check tower destruction (no dragons to kill)
```

### Tower System
```
Tower States:
  - Healthy (100 HP) → Normal operation
  - Damaged (1-99 HP) → Can REPAIR (10g per HP)
  - Destroyed (0 HP) → Can REBUILD (75g flat)

Tower-Dragon Relationship:
  - Each tower has 1 dedicated dragon slot
  - Tower 0 → Dragon A
  - Tower 1 → Dragon B
  - etc.

Tower Destruction:
  - Dragon assigned to that tower DIES permanently
  - Tower becomes ruins (grayed out)
  - Defense capacity reduced
  - Can rebuild for 75g
```

### Knight Meat
```
Acquisition:
  - Normal knight defeated: 50% → 1 meat
  - Boss knight defeated: 75% → 2-3 meat

Usage:
  - Feed to dragon (like regular food)
  - Reduces hunger: -30% (better than food's -25%)
  - Increases fatigue: +15% (penalty)

Strategy:
  - Best used on idle/resting dragons
  - Don't feed to active defenders (fatigue penalty)
  - More efficient hunger reduction than regular food
```

---

## 🧪 Testing Checklist

### Dragon Assignment
- [ ] Can assign dragon to specific tower
- [ ] Can remove dragon from tower
- [ ] Cannot assign dragon to destroyed tower
- [ ] Cannot assign same dragon to multiple towers
- [ ] Cannot assign dragon with >50% fatigue

### Combat & Rewards
- [ ] Knights drop meat on victory (check RNG)
- [ ] No meat drops on defeat
- [ ] Boss knights drop 2-3 meat
- [ ] Meat added to inventory

### Tower Destruction
- [ ] Dragon dies when tower destroyed
- [ ] Death message shows tower index
- [ ] Dragon removed from assignments
- [ ] DragonStateManager notified

### Rebuild System
- [ ] Rebuild button shows for destroyed towers
- [ ] Rebuild button hidden for healthy towers
- [ ] Rebuild costs 75 gold
- [ ] Rebuild restores to full HP
- [ ] Defense capacity restored

### Knight Meat Consumption
- [ ] Feed Knight Meat button appears
- [ ] Reduces hunger by 30%
- [ ] Increases fatigue by 15%
- [ ] Proper feedback message

### Save/Load
- [ ] Tower assignments save correctly
- [ ] Tower assignments restore on load
- [ ] Dragons restore to DEFENDING state

---

## 🔧 Debug Commands

```gdscript
# Force next wave (in console)
DefenseManager.instance.force_next_wave()

# Force tower damage
DefenseTowerManager.instance.force_damage_all_towers(30)

# Check tower assignments
print(DefenseManager.instance.get_tower_assignments())

# Add knight meat
InventoryManager.instance.add_item_by_id("knight_meat", 10)
```

---

## 📊 Balance Numbers

### Knight Meat
- Drop rate (normal): 50% → ~0.5 meat/wave average
- Drop rate (boss): 75% → 2-3 meat every 10 waves
- Hunger reduction: 30% vs food's 25% (+20% effectiveness)
- Fatigue cost: 15% (use wisely!)

### Tower Costs
- Repair 50 HP: 500 gold (10g/HP)
- Rebuild destroyed: 75 gold
- Build new (1st extra): 100 gold
- Build new (2nd extra): 150 gold
- Build new (3rd extra): 225 gold
→ **Rebuilding is 25-75% cheaper than building new!**

### Combat Damage
- Victory: 5 HP per tower
- Defeat: 20 HP per tower
- Undefended: 40 HP per tower (future implementation)

---

## 🎯 Design Rationale

### Why Tower-Specific Assignment?
- **High Stakes:** Losing a tower = losing that specific dragon
- **Strategic Placement:** Players must choose which dragons guard which towers
- **Clear Consequences:** Easier to understand "Tower 2 destroyed → Dragon at Tower 2 dies"

### Why Chance-Based Meat Drops?
- **Rarity = Value:** Makes meat feel more special
- **RNG Excitement:** Surprise loot drops are fun
- **Balanced Economy:** Prevents meat flooding

### Why 75g Rebuild Cost?
- **Accessible Recovery:** Cheaper than building new (encourages defense)
- **Not Trivial:** Still hurts to lose a tower
- **Sweet Spot:** Between repair costs (variable) and build costs (exponential)

### Why Fatigue Penalty on Knight Meat?
- **Interesting Choice:** Better hunger reduction, but at a cost
- **Thematic:** Heavy, rich meat is exhausting to digest
- **Strategic Use:** Feed to idle dragons, not active defenders
- **Balance:** Prevents knight meat from being strictly better than food

---

## 🚀 Future Enhancements

1. **Visual Knight Sprites:** Display knight.png in combat UI
2. **Meat Drop Animation:** Show meat icons floating up on victory
3. **Tower Ruins Visual:** Different sprite for destroyed towers
4. **Dragon Death Cutscene:** Special visual when dragon dies with tower
5. **Undefended Damage:** Implement MASSIVE_DAMAGE (40 HP) for towers with no defenders
6. **Tower-Specific Defense Bonuses:** Different towers provide different bonuses
7. **Knight Variants:** Different knight types with unique drops

---

## 📝 File Summary

### Modified Files (7)
1. `data/items.json` - Added knight_meat item
2. `scripts/managers/defense_manager.gd` - Tower assignments, meat drops, dragon deaths
3. `scripts/managers/defense_tower_manager.gd` - Rebuild functionality
4. `scripts/dragon_system/dragon_state_manager.gd` - Knight meat consumption
5. `scripts/ui/dragon_details_modal.gd` - Knight meat button
6. `scripts/ui/defense_towers_ui.gd` - Rebuild handler, tower assignment
7. `scripts/ui/tower_card.gd` - Rebuild button, tower-specific dragons

### Files to Create/Add (2)
1. `assets/ui/knight.png` - Knight sprite image
2. `assets/ui/knight-meat.png` - Meat icon image

### Scenes to Update (1)
1. `scenes/ui/towers/tower_card.tscn` - Add RebuildButton node

---

## ✨ Credits
Implementation based on user requirements:
- 1 dragon per tower
- Chance-based meat drops
- 75g rebuild cost
- Dragon death on tower destruction
- Knight meat with fatigue penalty

---

**Status:** ✅ Code implementation complete. Manual steps required for images and scene updates.

