# Battle Visualization System

## Overview
Visual combat system that shows knights attacking and dragons defending during tower defense waves.

## Features

### Visual Elements
1. **Battle Arena** - Full-screen overlay during combat
2. **Knight Units** - Visual representation of attacking knights
   - Shows knight sprite (knight.png)
   - Displays HP and ATK stats
   - Boss knights labeled in red
3. **Dragon Units** - Visual representation of defending dragons
   - Color-coded by element type
   - Shows dragon name and stats
   - Displays current HP and attack power

### Battle Flow
```
Wave Starts (20 seconds)
  ↓
Battle Arena Appears
  ↓
Knights Spawn (right side)
Dragons Exit Towers (left side)
  ↓
Combat Animation
  • 3 clash cycles
  • Units shake to simulate fighting
  • Combat log shows action
  ↓
Battle Resolves (1 second)
  ↓
Victory or Defeat Shown
  • Victory: Knights fade out
  • Defeat: Dragons fade out
  • Rewards displayed in log
  ↓
Battle Arena Hides (after 3 seconds)
```

### Element Colors
- 🔥 **Fire:** Red
- ❄️ **Ice:** Blue
- ⚡ **Lightning:** Yellow
- 🌿 **Nature:** Green
- 🌑 **Shadow:** Purple

### Combat Log
Real-time text display showing:
- Battle start announcement
- Clash events (*CLASH!*)
- Combat resolution
- Victory/defeat status
- Rewards earned (gold, parts, meat)

## Technical Details

### Files Created
- `scripts/idle_defense/battle_arena.gd` - Battle logic
- `scenes/idle_defense/battle_arena.tscn` - Battle scene

### Integration
Battle arena is integrated into `DefenseTowersUI`:
- Automatically shows when wave starts
- Hides after combat completes
- Doesn't block tower management UI when hidden

### Signals Used
- `DefenseManager.wave_started` - Triggers battle visualization
- `DefenseManager.wave_completed` - Shows outcome and hides arena
- `battle_animation_complete` - Internal animation sync

## Customization

### Adjust Battle Speed
In `battle_arena.gd`:
```gdscript
# Change clash count (line ~148)
for i in range(3):  # Change 3 to more/less clashes

# Change clash delay (line ~149)
await get_tree().create_timer(0.3).timeout  # Adjust 0.3
```

### Modify Unit Appearance
In `_spawn_knight()` and `_spawn_dragon()`:
- Change `custom_minimum_size` for unit panel size
- Modify label font sizes
- Adjust colors and styling

### Combat Log Messages
In `_animate_battle()` and `_on_wave_completed()`:
- Edit text messages
- Add more detailed combat descriptions
- Customize victory/defeat messages

## Future Enhancements

### Suggested Improvements
1. **Dragon Animations**
   - Use actual DragonVisual component
   - Show elemental effects (fire breath, ice shards, etc.)
   - Animate dragons moving from towers

2. **Knight Animations**
   - Move knights across screen toward towers
   - Show attack animations
   - Add defeat animations

3. **Effects**
   - Particle effects for attacks
   - Screen flash on critical hits
   - Sound effects for combat

4. **Advanced Combat Log**
   - Show individual attack rolls
   - Display damage numbers
   - Color-code messages by severity

5. **Interactive Elements**
   - Click units to see detailed stats
   - Pause/play combat animation
   - Speed controls (1x, 2x, skip)

## Usage

The battle arena automatically activates when:
1. You're on the Tower Defense UI
2. A wave starts (every 20 seconds for testing)
3. The arena appears as a full-screen overlay

No manual activation needed - it's fully automatic!

## Testing

With the 20-second wave timer:
1. Open Tower Defense UI
2. Assign dragons to towers
3. Wait for "Next Wave: 0:00"
4. Watch battle animation play
5. See victory/defeat and rewards
6. Arena hides automatically

## Performance Notes

- Battle arena only exists when Tower Defense UI is open
- Hidden when not in combat (no performance impact)
- All units cleaned up after each battle
- Minimal memory footprint

## Known Limitations

1. Knight sprite must exist at `res://assets/ui/knight.png`
   - Falls back to gray rectangle if missing
2. Dragons shown as colored squares (not full DragonVisual yet)
3. Combat is purely visual - actual resolution happens in DefenseManager
4. No mid-combat interaction (can't cancel or speed up)

## Troubleshooting

### Battle doesn't appear
- Check if you're on Tower Defense UI
- Verify DefenseManager is triggering waves
- Check console for connection errors

### Knights/Dragons not showing
- Verify DefenseManager has defenders and enemies
- Check battlefield container is visible
- Look for spawn errors in console

### Animation glitches
- Restart scene to reset state
- Check timer conflicts
- Verify tweens aren't overlapping

---

**Status:** ✅ Fully implemented and integrated
**Testing:** Use 20-second wave timer for rapid testing
**Production:** Change to 300 seconds (5 minutes) for normal gameplay

