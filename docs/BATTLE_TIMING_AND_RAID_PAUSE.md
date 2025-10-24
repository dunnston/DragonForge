# Battle Timing & Raid Pause System

## Overview
This document details two major quality-of-life improvements to the tower defense system:
1. **Extended Battle Animations** - Slower, more dramatic combat sequences
2. **Automatic Raid Pausing** - Raids pause when the player has no resources

---

## 1. Extended Battle Animations

### Problem
Battle sequences were too fast, making it difficult to follow the action and appreciate the combat.

### Solution
Significantly increased all timing delays in the battle animation system to create a more cinematic, watchable experience.

### Timing Changes

#### **Battle Start**
- **Old:** 0.5 seconds
- **New:** 1.5 seconds
- *Purpose:* Longer intro to let players see the combatants

#### **Round Start Delay**
- **Old:** 0.8 seconds
- **New:** 2.0 seconds
- *Purpose:* Clear separation between combat rounds

#### **After Knight Attacks**
- **Old:** 0.5 seconds
- **New:** 1.5 seconds
- *Purpose:* Time to see damage and read combat log

#### **After Dragon Counter-Attacks**
- **Old:** 0.3 seconds
- **New:** 1.2 seconds
- *Purpose:* Watch dragons retaliate

#### **After Each Individual Attack**
- **Old:** 0.4 seconds
- **New:** 1.0 seconds
- *Purpose:* See damage numbers and HP updates

#### **Battle Conclusion**
- **Old:** 1.5 seconds
- **New:** 3.0 seconds
- *Purpose:* Dramatic pause before showing rewards

### Example Battle Timeline

**Old System (3 rounds):**
- Total time: ~7-8 seconds
- Feels: Rushed, hard to follow

**New System (3 rounds):**
- Total time: ~20-25 seconds
- Feels: Cinematic, readable, engaging

### Code Location
All timing changes in: `scripts/idle_defense/battle_arena.gd`

```gdscript
# Example of increased timing
await get_tree().create_timer(2.0).timeout  # Was 0.8
await get_tree().create_timer(1.5).timeout  # Was 0.5
await get_tree().create_timer(3.0).timeout  # Was 1.5
```

---

## 2. Automatic Raid Pause System

### Problem
When players run out of all resources (gold, parts, and dragons), they enter a "game over" state where they can't progress but raids continue to attack, creating frustration.

### Solution
Raids automatically pause when the player has **NO** resources remaining, giving them time to recover without pressure.

### Pause Conditions

Raids pause **ONLY** when **ALL THREE** conditions are true:

#### **Condition 1: Empty Vault**
```gdscript
var has_gold = TreasureVault.instance.get_total_gold() > 0
```
- No gold remaining to build/repair towers or hire scientists

#### **Condition 2: No Dragon Parts**
```gdscript
var has_parts = InventoryManager.instance.get_all_dragon_parts().size() > 0
```
- No parts in inventory to build new dragons

#### **Condition 3: No Explorable Dragons**
```gdscript
# At least one dragon must be:
# - Idle (not defending, training, or exploring)
# - Not too fatigued (< 80% fatigue)
dragon.current_state == Dragon.DragonState.IDLE and dragon.fatigue_level < 0.8
```
- No healthy idle dragons that could be sent to explore for parts

### When Raids Resume

Raids automatically resume when the player gains **ANY** of the following:
- ✅ Receives gold (from any source)
- ✅ Gets dragon parts (exploration rewards, inventory)
- ✅ Has a dragon become available (finishes training/resting)

### Visual Indicator

**Tower Defense UI displays:**
```
⏸ RAIDS PAUSED (No Resources)
```
- Text color: Gray (Color(0.6, 0.6, 0.6, 1))
- Replaces the normal wave countdown timer
- Updates every second

### Console Messages

```
[DefenseManager] Raids PAUSED - Vault is empty, no parts, and no dragons to explore
[DefenseManager] ❌ RAIDS PAUSED: Vault empty (Gold: false, Parts: false, Explorable Dragons: false)
```

### Implementation Details

#### **Check Function**
`scripts/managers/defense_manager.gd`
```gdscript
func _is_player_out_of_resources() -> bool:
    """Check if player has no resources left"""
    
    # Check vault
    var has_gold = TreasureVault.instance.get_total_gold() > 0
    
    # Check inventory
    var has_parts = InventoryManager.instance.get_all_dragon_parts().size() > 0
    
    # Check dragons
    var has_explorable_dragons = false
    # ... (checks for idle dragons < 80% fatigue)
    
    # Pause only if ALL are false
    return not has_gold and not has_parts and not has_explorable_dragons
```

#### **Wave Timer Integration**
```gdscript
func _update_wave_timer():
    if is_in_combat:
        return
    
    # NEW: Check for resource depletion
    if _is_player_out_of_resources():
        print("[DefenseManager] Raids PAUSED - Vault is empty...")
        return  # Don't decrement timer
    
    # Normal wave countdown continues...
    time_until_next_wave -= frequency_multiplier
```

#### **UI Display**
`scripts/ui/defense_towers_ui.gd`
```gdscript
func _update_wave_timer():
    # Check for pause FIRST
    if DefenseManager.instance._is_player_out_of_resources():
        wave_timer_label.text = "⏸ RAIDS PAUSED (No Resources)"
        wave_timer_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
    elif DefenseManager.instance.is_in_combat:
        wave_timer_label.text = "⚔ COMBAT! ⚔"
    else:
        # Normal countdown
```

### Strategic Implications

#### **For Players:**
1. **Grace Period:** Time to send dragons exploring without raid pressure
2. **Recovery Planning:** Can strategize comeback without immediate threats
3. **No Soft Lock:** Game never enters unwinnable state

#### **For Game Flow:**
1. **Prevents Frustration:** No repeated defeats when defenseless
2. **Encourages Exploration:** Shows value of keeping dragons available
3. **Teaches Resource Management:** Clear feedback when too depleted

### Edge Cases Handled

#### **Case 1: Dragon Returns from Exploration**
- Player gets parts → Raids resume immediately
- Status: ✅ Handled (parts check runs every second)

#### **Case 2: Dragon Finishes Resting**
- Dragon becomes available (< 80% fatigue) → Raids resume
- Status: ✅ Handled (dragon check runs every second)

#### **Case 3: Player Uses Last Gold**
- If no parts or dragons → Raids pause
- Status: ✅ Handled (gold check runs every second)

#### **Case 4: All Dragons Defending**
- Even if have gold/parts, can't send anyone exploring
- Status: ✅ Handled (checks for IDLE dragons specifically)

### Testing Checklist

- [ ] Raids pause when gold = 0, parts = 0, explorable dragons = 0
- [ ] Raids resume when dragon returns with parts
- [ ] Raids resume when dragon finishes resting (fatigue drops below 80%)
- [ ] UI shows "⏸ RAIDS PAUSED" in gray
- [ ] Console logs pause message
- [ ] Wave timer stops counting down when paused
- [ ] Wave timer resumes when resources available
- [ ] Pause works across scene transitions
- [ ] Pause works after game load

---

## Files Modified

### Battle Timing
1. **`scripts/idle_defense/battle_arena.gd`**
   - Increased all `create_timer()` delays
   - Extended intro, round pauses, and conclusion

### Raid Pause System
2. **`scripts/managers/defense_manager.gd`**
   - Added `_is_player_out_of_resources()` function
   - Modified `_update_wave_timer()` to check pause condition
   - Added console logging for pause state

3. **`scripts/ui/defense_towers_ui.gd`**
   - Modified `_update_wave_timer()` display
   - Added gray "RAIDS PAUSED" message
   - Priority check before combat/countdown

---

## Summary

### Battle Timing
- **~3x slower** combat sequences
- More readable damage numbers
- Clear round separation
- Dramatic conclusions

### Raid Pause
- **Automatic safety net** for depleted players
- **Zero-resource detection** across gold, parts, and dragons
- **Visual feedback** in tower defense UI
- **Automatic resumption** when resources available

Both systems work together to create a more **polished, forgiving, and enjoyable** tower defense experience! 🐉⚔️

