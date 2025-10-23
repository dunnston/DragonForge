# Defense Tower UI Integration Guide

## Overview

This UI system provides a visual interface for managing defense towers in the dragon factory game. It displays tower health, repair options, and allows players to build new towers.

## Files Created

### Scripts
- `scripts/ui/tower_card.gd` - Individual tower card component
- `scripts/ui/build_card.gd` - Build new tower card component
- `scripts/ui/locked_card.gd` - Locked tower slot component
- `scripts/ui/defense_towers_ui.gd` - Main UI controller

### Scenes
- `scenes/ui/towers/tower_card.tscn` - Tower card scene
- `scenes/ui/towers/build_card.tscn` - Build card scene
- `scenes/ui/towers/locked_card.tscn` - Locked card scene
- `scenes/ui/towers/defense_towers_ui.tscn` - Main UI scene

## Integration Steps

### 1. Add UI to Your Game Scene

Open your main game scene and add the DefenseTowersUI as a child node:

```gdscript
# In your main game scene or UI manager
var defense_ui = preload("res://scenes/ui/towers/defense_towers_ui.tscn").instantiate()
add_child(defense_ui)
```

Or in the Godot editor:
1. Open your main game scene
2. Click "Add Child Node" (+)
3. Select "Scene" and choose `res://scenes/ui/towers/defense_towers_ui.tscn`
4. Position it where you want it in your UI hierarchy

### 2. Verify Manager Dependencies

The UI requires these autoloaded singletons (already set up in your project):
- `DefenseTowerManager` - Tower management
- `DefenseManager` - Dragon assignment tracking
- `TreasureVault` - Gold/currency

All of these are already configured in your `project.godot`.

### 3. Add Tower Icon/Sprite (Optional)

For better visuals, you can add a tower icon:

1. Add a texture to `assets/ui/tower_icon.png`
2. In the editor, open `tower_card.tscn`
3. Select the `TowerIcon` TextureRect node
4. Set its `Texture` property to your tower icon

### 4. Customize Styling (Optional)

To match your game's aesthetic:

#### Via Theme
1. Create a theme resource: `res://assets/themes/tower_ui_theme.tres`
2. In `defense_towers_ui.tscn`, select the root Control node
3. Set the `Theme` property to your theme

#### Via StyleBox
1. Select any PanelContainer in the tower card scenes
2. In the Theme Overrides > Styles section
3. Add a StyleBoxFlat and customize colors/borders

### 5. Connect to Game Events

The UI automatically updates when:
- Towers take damage
- Towers are repaired
- Towers are built
- Dragons are assigned/removed
- Gold changes

No additional setup needed - it listens to the manager signals!

## Features

### Tower Cards
- **Health Display**: Color-coded progress bar (Green > Yellow > Red)
- **Dragon Count**: Shows number of defending dragons
- **Repair Button**: Appears when tower is damaged
  - Shows repair cost
  - Disabled if insufficient gold
  - Hidden at full health
- **Hover Effect**: Scales up 5% on mouse hover
- **Destroyed State**: Grayed out when health reaches 0

### Build Card
- **Build Cost**: Displays exponential cost for next tower
- **Build Button**: Disabled if insufficient gold
- **Hover Effect**: Scales up when affordable

### Locked Cards
- **Lock Icon**: Shows locked slots
- **Grayed Out**: Visual indication of unavailability

### Footer
- **Repair All Button**: Repairs all damaged towers at once
  - Shows total cost
  - Auto-hides when no repairs needed
- **Stats Display**: Shows current/max defense slots

## API for External Integration

### Triggering Updates

The UI updates automatically, but you can force a refresh:

```gdscript
# Get reference to UI
var defense_ui = get_node("DefenseTowersUI")

# Force refresh all cards (rarely needed - auto-updates)
defense_ui._refresh_tower_cards()

# Force rebuild entire UI (use after major changes)
defense_ui._populate_towers()
```

### Responding to Tower Clicks

Currently tower card clicks are stubbed out. To add dragon assignment UI:

```gdscript
# In defense_towers_ui.gd, modify _on_tower_card_clicked:
func _on_tower_card_clicked(tower_index: int):
    # Open your dragon assignment dialog
    var dragon_picker = preload("res://scenes/ui/dragon_picker.tscn").instantiate()
    dragon_picker.connect("dragon_selected", func(dragon):
        DefenseManager.instance.assign_dragon_to_defense(dragon)
    )
    add_child(dragon_picker)
```

## Customization

### Changing Card Size

In each card scene file, modify the `custom_minimum_size`:

```gdscript
# Current: 180x280
# Larger: 220x340
# Smaller: 150x240
custom_minimum_size = Vector2(180, 280)
```

### Changing Colors

In `tower_card.gd`, modify the health bar colors:

```gdscript
# Line ~40-46
if health_percent >= 0.7:
    health_bar.modulate = Color(0.2, 0.8, 0.2)  # Green
elif health_percent >= 0.3:
    health_bar.modulate = Color(0.9, 0.9, 0.2)  # Yellow
else:
    health_bar.modulate = Color(0.9, 0.2, 0.2)  # Red
```

### Adding Sound Effects

Add sounds to button presses and events:

```gdscript
# In tower_card.gd
func _on_repair_pressed():
    AudioManager.play_sfx("repair")  # Your audio system
    repair_clicked.emit(tower_index)

# In defense_towers_ui.gd
func _on_tower_built(tower: DefenseTower):
    AudioManager.play_sfx("build_tower")
    _populate_towers()
```

### Adding Animations

Add more visual feedback:

```gdscript
# Shake on damage
func _on_tower_damaged(tower: DefenseTower, damage: int):
    var card = _find_tower_card(tower)
    if card:
        var tween = create_tween()
        tween.tween_property(card, "position:x", card.position.x + 5, 0.05)
        tween.tween_property(card, "position:x", card.position.x - 5, 0.05)
        tween.tween_property(card, "position:x", card.position.x, 0.05)
```

## Troubleshooting

### "ERROR: DefenseTowerManager not found!"
- Verify `DefenseTowerManager` is in autoload (Project > Project Settings > Autoload)
- Check that it's named exactly `DefenseTowerManager` in autoload

### Cards not updating
- Check console for signal connection errors
- Verify managers are emitting signals correctly
- Try calling `_populate_towers()` manually

### Build button always disabled
- Check that `TreasureVault.instance.get_total_gold()` returns correct value
- Verify `DefenseTowerManager.instance.get_next_tower_cost()` is working

### Repair button not showing
- Ensure towers have taken damage (health < max_health)
- Check that tower is not destroyed (health > 0)

### UI not visible
- Check that the UI is added to the scene tree
- Verify anchors are set correctly (should be full rect)
- Check z-index / CanvasLayer ordering

## Performance Notes

- UI updates every 1 second via timer (footer stats)
- Cards refresh on signals (instant feedback)
- Full rebuild only on build/destroy events
- Handles 15 towers smoothly (tested)

## Future Enhancements

Suggested improvements for v2:

1. **Tooltips**: Hover to show detailed tower stats
2. **Context Menus**: Right-click for quick actions
3. **Batch Selection**: Select multiple towers to repair
4. **Tower Upgrades**: Add upgrade buttons/UI
5. **Damage Indicators**: Show damage numbers floating up
6. **Build Animation**: Particle effect on tower construction
7. **Dragon Assignment**: Visual drag-and-drop for dragons
8. **Tower History**: Track defenses won, damage taken

## Support

For issues or questions:
1. Check console for error messages
2. Verify all managers are properly initialized
3. Test with `defense_tower_test.gd` to ensure backend works
4. Review this README for integration steps

## License

This UI is part of the Frankenstein Dragon Factory game jam project.
