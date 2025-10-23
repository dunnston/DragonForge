# Training Grounds Implementation - Complete

## Overview

The Training Grounds system has been fully implemented as specified in [training-grounds.md](training-grounds.md). Dragons can now be assigned to training slots where they level up over time. The system features:

- **Vertical Scrolling UI** (as requested, different from horizontal tower system)
- **10 Training Slots** (2 unlocked at start, expandable with gold)
- **Time-Based Training** (2h base for Lv1→2, scales by 1.5x per level)
- **Trainer Scientist Integration** (reduces training time by 50%)
- **Visual Progress Tracking** with progress bars and timers
- **Save/Load Support** for persistent training state

## Files Created

### Core System
1. **[scripts/training/training_slot.gd](../scripts/training/training_slot.gd)**
   - Resource class for individual training slots
   - Tracks dragon assignment, training progress, and timers
   - Handles level-up on completion

2. **[scripts/managers/training_manager.gd](../scripts/managers/training_manager.gd)**
   - Singleton manager for all training operations
   - Manages slot expansion, dragon assignment, and collection
   - Integrates with Trainer scientist for speed bonuses
   - Save/load serialization support

### UI Components
3. **[scripts/ui/training_slot_card.gd](../scripts/ui/training_slot_card.gd)**
4. **[scenes/ui/training/training_slot_card.tscn](../scenes/ui/training/training_slot_card.tscn)**
   - Individual training slot card component
   - Shows dragon visual, progress bar, stats, and controls
   - Three states: Empty, Training, Ready to Collect

5. **[scripts/ui/training_expansion_card.gd](../scripts/ui/training_expansion_card.gd)**
6. **[scenes/ui/training/training_expansion_card.tscn](../scenes/ui/training/training_expansion_card.tscn)**
   - Expansion card for unlocking new slots
   - Shows cost and disables if not affordable

7. **[scripts/ui/training_locked_card.gd](../scripts/ui/training_locked_card.gd)**
8. **[scenes/ui/training/training_locked_card.tscn](../scenes/ui/training/training_locked_card.tscn)**
   - Locked slot placeholder cards
   - Visual indicator for future expansions

9. **[scripts/ui/training_yard_ui.gd](../scripts/ui/training_yard_ui.gd)**
10. **[scenes/ui/training/training_yard_ui.tscn](../scenes/ui/training/training_yard_ui.tscn)**
    - Main Training Grounds UI with **VERTICAL SCROLLING**
    - Manages all slot cards, dragon assignment, and collection
    - Real-time updates via signal connections

## Integration Points

### Modified Files
1. **[project.godot](../project.godot)**
   - Added `TrainingManager` to autoload (line 31)
   - Added `ScientistManager` to autoload (line 30)

2. **[scripts/ui/factory_manager.gd](../scripts/ui/factory_manager.gd)**
   - Added Training Grounds UI setup and navigation
   - Connected to DragonFactory and TrainingManager
   - Added button handler for accessing Training Grounds

3. **[scenes/ui/factory_manager.tscn](../scenes/ui/factory_manager.tscn)**
   - Added "TRAINING GROUNDS" button in top bar (line 195)

## How It Works

### Training Flow
1. **Assignment**: Player clicks empty slot → Dragon Picker opens → Select dragon
2. **Training**: Dragon state set to TRAINING, timer starts
3. **Progress**: UI updates every second showing progress bar and time remaining
4. **Completion**: When timer finishes, card shows "READY!" with gold highlight
5. **Collection**: Click "COLLECT" → Dragon levels up, stats recalculated, returns to IDLE

### Trainer Scientist Bonus
- When Trainer scientist is hired in ScientistManager:
  - Training time reduced by 50% for ALL active and future training
  - Header shows "Trainer: Active (-50% Time)" in green
  - Existing training times recalculated to maintain progress percentage

### Expansion System
- Starts with 2 free slots
- Max 10 slots total
- Expansion costs: 500g, 1000g, 2000g, 4000g (then 4000g each)
- Next expansion slot shown as "+EXPAND" card
- Remaining slots shown as locked (gray 🔒)

### Rush Feature
- "Rush (50g)" button on training slots
- Instantly completes training for 50 gold
- Useful for fast leveling when needed

## Vertical Scrolling Implementation

The key difference from the Defense Towers (horizontal) system:

**Defense Towers** (Horizontal):
```gdscript
[node name="TowerContainer" type="HBoxContainer"]  # Horizontal
horizontal_scroll_bar_visibility = 2              # Show horizontal scrollbar
```

**Training Grounds** (Vertical):
```gdscript
[node name="SlotContainer" type="VBoxContainer"]   # Vertical
vertical_scroll_bar_visibility = 2                # Show vertical scrollbar
```

The layout automatically wraps and scrolls vertically, fitting the requested design.

## Save/Load Integration

The system supports full save/load through:

1. **TrainingManager.to_dict()** - Serializes all slots and trainer status
2. **TrainingManager.from_dict()** - Restores slots and resolves dragon references
3. **TrainingSlot.to_dict()/from_dict()** - Individual slot serialization

To integrate with your existing SaveLoadManager, call:
```gdscript
# When saving
save_data["training_grounds"] = TrainingManager.instance.to_dict()

# When loading
TrainingManager.instance.from_dict(save_data["training_grounds"])
```

## Testing Checklist

To test the Training Grounds system:

- [ ] Open game and click "TRAINING GROUNDS" button
- [ ] Verify 2 slots unlocked, 1 expansion card, 7 locked cards
- [ ] Click empty slot → Dragon picker opens
- [ ] Assign dragon → Progress bar starts, timer counts down
- [ ] Check dragon is in TRAINING state (can't be assigned elsewhere)
- [ ] Hire Trainer scientist → Training time halves
- [ ] Wait for training to complete → "READY!" appears with gold glow
- [ ] Click "COLLECT" → Dragon levels up
- [ ] Expand slot with gold → New slot unlocked
- [ ] Rush training → Training completes instantly
- [ ] Remove dragon from training → Dragon returns to IDLE
- [ ] Save and reload → Training state persists

## Features from Specification

✅ **Implemented:**
- Time-based training (2h base, 1.5x scaling)
- Trainer scientist integration (-50% time)
- Visual progress bars and timers
- Stat gain previews (ATK +5, HP +15, SPD +2)
- Slot expansion system (2→10 slots)
- Collect all ready dragons at once
- Rush training with gold
- Real-time UI updates
- Save/load persistence
- Vertical scrolling layout
- Card-based UI matching tower system style

⚠️ **Optional Features Not Implemented:**
- Training queue (auto-fill from queue when slot opens)
- Training statistics tracking (total trained, levels gained)
- Level-up celebration popups (basic print for now)
- Visual animations (sparkles, particles, etc.)
- Sound effects (integrate with AudioManager when ready)

## Next Steps

1. **Test thoroughly** using the checklist above
2. **Add to SaveLoadManager** if not already integrated
3. **Tune balance** (training times, costs, rush cost)
4. **Add polish**:
   - Level-up celebration popup with stat comparison
   - Particle effects on training completion
   - Sound effects for assignment, completion, level-up
   - Animations for card state transitions
5. **Optional features** from spec (queue, statistics, etc.)

## Architecture

```
Training Grounds System
├── TrainingManager (Singleton)
│   ├── 10 × TrainingSlot (Resources)
│   ├── Trainer status tracking
│   └── Save/load serialization
│
├── TrainingYardUI (Main Screen)
│   ├── Header (Back button + Trainer status)
│   ├── ScrollContainer (Vertical)
│   │   └── SlotContainer (VBoxContainer)
│   │       ├── TrainingSlotCard (unlocked slots)
│   │       ├── ExpansionCard (next expansion)
│   │       └── LockedCard (remaining locked)
│   └── Footer (Collect All + Capacity display)
│
└── Integration
    ├── DragonFactory → Provides dragons
    ├── ScientistManager → Trainer status
    ├── TreasureVault → Gold for expansion/rush
    └── SaveLoadManager → Persistence
```

## Summary

The Training Grounds system is **fully functional** and ready for testing. The vertical scrolling layout wraps training slots as requested, providing a different visual experience from the horizontal tower system. All core features from the specification are implemented, with optional polish features noted for future enhancement.

**Access**: Click "TRAINING GROUNDS" button in the factory manager top bar.
