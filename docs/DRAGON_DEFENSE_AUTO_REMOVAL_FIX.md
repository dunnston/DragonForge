# Dragon Defense Auto-Removal System Fix

## Issue
Dragons were not being automatically removed from defense towers when:
1. Their fatigue level increased above 50% (e.g., after combat or exploration)
2. They started exploring, training, or resting
3. They transitioned to other incompatible states

This caused a mismatch where dragons could be defending while also in other states, or remain assigned to defense even when too fatigued to actually defend.

This issue affected all non-IDLE states: **EXPLORING**, **TRAINING**, and **RESTING**.

## Solution Summary

✅ **Bidirectional State Management**: Dragons are automatically removed from defense when they start exploring, training, or resting  
✅ **Fatigue-Based Removal**: Dragons with >50% fatigue are automatically removed from defense  
✅ **Smart Auto-Rest**: Fatigued dragons are automatically put to rest when removed, ensuring optimal recovery  
✅ **Assignment Blocking**: Prevents assigning busy/fatigued dragons to defense with clear error messages

## Solution Implemented

### 1. Added `check_and_remove_invalid_defenders()` function to DefenseManager
**File:** `scripts/managers/defense_manager.gd`

This new function checks all currently defending dragons and automatically removes any that:
- Have fatigue > 50% (**automatically put to rest**)
- Are in EXPLORING state
- Are in TRAINING state
- Are in RESTING state
- Are dead or have health <= 0

The function is called automatically at key moments when dragon states change.

**Special Feature:** Dragons removed due to high fatigue (>50%) are automatically transitioned to the RESTING state to recover, providing a seamless gameplay experience where fatigued defenders are automatically managed.

### 2. Automatic Removal Triggers

#### After Combat Ends
**File:** `scripts/managers/defense_manager.gd` - `end_combat()`
- After applying combat fatigue to dragons, the system now checks all defenders
- Dragons that became too fatigued during combat are automatically removed from their towers
- This prevents over-fatigued dragons from staying on defense duty

#### When Exploration Starts
**File:** `scripts/managers/exploration_manager.gd` - `start_exploration()`
- Before starting exploration, if the dragon is currently DEFENDING, they are automatically removed from defense
- This ensures dragons can't be in two places at once

#### After Exploration Completes
**File:** `scripts/managers/exploration_manager.gd` - `_complete_exploration()`
- After applying exploration fatigue, the system checks all defenders
- If any other defending dragons became too fatigued, they are removed
- This handles the case where multiple dragons are exploring and their fatigue changes might affect defense assignments

#### When Training Starts
**File:** `scripts/managers/training_manager.gd` - `assign_dragon_to_slot()`
- Before assigning a dragon to a training slot, if they are currently DEFENDING, they are automatically removed from defense
- This ensures dragons can't train and defend simultaneously

#### When Resting Starts
**File:** `scripts/dragon_system/dragon_state_manager.gd` - `start_resting()`
- Before putting a dragon to rest, if they are currently DEFENDING, they are automatically removed from defense
- This ensures dragons can properly recover without being interrupted for defense duty

#### After Consuming Knight Meat
**File:** `scripts/dragon_system/dragon_state_manager.gd` - `use_knight_meat_on_dragon()`
- Knight meat increases fatigue by 15%
- After consuming, the system checks if the dragon (or any other defender) should be removed from defense
- This prevents players from unknowingly disabling their defenders by feeding them

### 3. Prevention of Invalid Assignments

#### Block Assigning Busy Dragons
**File:** `scripts/managers/defense_manager.gd` - `assign_dragon_to_tower()`
- Added checks to prevent assigning dragons in incompatible states to defense:
  - **EXPLORING**: "Dragon is currently exploring and cannot defend!"
  - **TRAINING**: "Dragon is currently training and cannot defend!"
  - **RESTING**: "Dragon is currently resting and cannot defend!"
- These checks happen before the fatigue check, so players get immediate, clear feedback
- Only IDLE dragons can be assigned to defense (DEFENDING dragons switching towers is already handled separately)

## How It Works

### Bidirectional Protection
The system now works **both ways**:

1. **State → Defense**: When a dragon changes state (exploring, training, resting), they are removed from defense
2. **Fatigue → Defense**: When a dragon's fatigue increases above 50%, they are removed from defense

### User Feedback
When dragons are auto-removed, the system prints clear messages:
```
[DefenseManager] Removing DragonName from tower 0 (too fatigued (65%))
[DefenseManager] DragonName automatically sent to rest due to fatigue
[DefenseManager] Removing DragonName from tower 1 (now exploring)
[DefenseManager] Removing DragonName from tower 2 (now training)
[DefenseManager] Removing DragonName from tower 0 (now resting)
```

**Note:** Dragons removed due to fatigue get an additional message showing they've been automatically sent to rest.

### UI Updates
After removing dragons, the system automatically:
- Refreshes the tower UI to show empty slots
- Updates the defender count
- Allows players to assign new dragons to the freed slots

## Testing Scenarios

To verify the fix works, test these scenarios:

1. **Combat Fatigue with Auto-Rest**:
   - Assign dragon with 40% fatigue to defense
   - Complete a combat wave (adds ~10-15% fatigue)
   - Dragon should be auto-removed if fatigue > 50%
   - **Dragon should automatically transition to RESTING state**
   - Check dragon card to verify it shows "Resting" status

2. **Exploration Start**:
   - Assign dragon to defense
   - Send dragon exploring
   - Dragon should be removed from defense tower immediately

3. **Exploration Return with Auto-Rest**:
   - Have 2 dragons defending with ~40% fatigue each
   - Send one on 15-minute exploration (adds 25% fatigue)
   - After return, if fatigue > 50%, should be auto-removed
   - **Dragon should automatically start resting**
   - Verify dragon shows "Resting" status in UI

4. **Knight Meat with Auto-Rest**:
   - Assign dragon with 40% fatigue to defense
   - Feed knight meat (+15% fatigue)
   - Dragon should be auto-removed if fatigue > 50%
   - **Dragon should automatically transition to RESTING state**
   - Fatigue should start decreasing at 4.5% per 30 seconds (RESTING rate)

5. **Training Assignment**:
   - Assign dragon to defense
   - Assign same dragon to training slot
   - Dragon should be auto-removed from defense tower

6. **Resting Assignment**:
   - Assign dragon with 60% fatigue to defense
   - Press "Rest" button to start resting
   - Dragon should be auto-removed from defense tower

7. **Invalid Assignment Prevention (Exploring)**:
   - Send dragon exploring
   - Try to assign to defense tower
   - Should show error: "Dragon is currently exploring and cannot defend!"

8. **Invalid Assignment Prevention (Training)**:
   - Assign dragon to training slot
   - Try to assign to defense tower
   - Should show error: "Dragon is currently training and cannot defend!"

9. **Invalid Assignment Prevention (Resting)**:
   - Set dragon to rest
   - Try to assign to defense tower
   - Should show error: "Dragon is currently resting and cannot defend!"

## Files Modified

1. `scripts/managers/defense_manager.gd`
   - Added `check_and_remove_invalid_defenders()` function
   - Updated `assign_dragon_to_tower()` to block exploring, training, and resting dragons
   - Updated `end_combat()` to check defenders after applying fatigue

2. `scripts/managers/exploration_manager.gd`
   - Updated `start_exploration()` to remove dragon from defense first
   - Updated `_complete_exploration()` to check all defenders after applying costs

3. `scripts/managers/training_manager.gd`
   - Updated `assign_dragon_to_slot()` to remove dragon from defense before training

4. `scripts/dragon_system/dragon_state_manager.gd`
   - Updated `use_knight_meat_on_dragon()` to check defenders after increasing fatigue
   - Updated `start_resting()` to remove dragon from defense before resting

## Benefits

- **Prevents Bugs**: Dragons can't be in multiple states simultaneously (defending + exploring/training/resting)
- **Better UX**: Players immediately see when their defenders become unavailable due to state changes
- **Automatic Management**: System handles edge cases without player micromanagement across all activities
- **Smart Auto-Rest**: Fatigued dragons (>50%) are automatically sent to rest when removed from defense, ensuring they recover faster
- **Clear Feedback**: Console logs show exactly why dragons were removed (fatigue, exploring, training, resting)
- **Fail-Safe**: Multiple checkpoints ensure consistency across all dragon activity systems
- **Complete Coverage**: Handles all non-IDLE dragon states (EXPLORING, TRAINING, RESTING) consistently
- **Reduced Micromanagement**: Players don't need to manually rest fatigued defenders - the system does it automatically

