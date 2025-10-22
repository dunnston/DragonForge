# Save/Load System Documentation

## Overview

The Playful Game Jam save/load system provides comprehensive game state persistence using Godot's localStorage (the `user://` directory). The system automatically serializes all game managers, dragons, inventory, and progress.

## Features

- **Complete State Persistence**: All game state is saved including:
  - TreasureVault (gold, parts, artifacts, items)
  - InventoryManager (all inventory slots)
  - DragonFactory (all dragons and collection progress)
  - DefenseManager (wave progress, defending dragons)
  - ExplorationManager (active explorations)
  - ScientistManager (hired scientists)

- **Auto-Save**: Automatically saves every 2 minutes (configurable)
- **Manual Save/Load**: Save and load game via dev menu (backtick key `)
- **Save File Management**: View save info, delete saves
- **Error Handling**: Robust error checking and recovery
- **Version Control**: Save file versioning for future compatibility

## Save File Location

Save files are stored in the user data directory:
- **Windows**: `%APPDATA%/Godot/app_userdata/Playful AI GameJam/savegame.json`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/Playful AI GameJam/savegame.json`
- **Linux**: `~/.local/share/godot/app_userdata/Playful AI GameJam/savegame.json`

## Usage

### Accessing the Dev Menu

Press the backtick key (`) to open the developer menu.

### Saving the Game

1. Open the dev menu (`)
2. Click **"Save Game"** button
3. Confirmation message will appear in console

### Loading a Save

1. Open the dev menu (`)
2. Click **"Load Game"** button
3. Game state will be restored
4. UI will refresh automatically

### Auto-Save

Auto-save is enabled by default and triggers every 2 minutes.

To disable auto-save:
1. Open the dev menu (`)
2. Uncheck the **"Auto-save"** checkbox

### Deleting a Save

1. Open the dev menu (`)
2. Click **"Delete Save File"** button (red text)
3. Save file will be permanently deleted

## Save File Structure

The save file is stored as JSON with the following structure:

```json
{
  "version": 1,
  "timestamp": 1234567890,
  "save_date": "2025-01-15 14:30:45",
  "treasure_vault": {
    "gold": 500,
    "protected_gold": 100,
    "dragon_parts": { ... },
    "artifacts": { ... },
    "treats": 5,
    "health_pots": 3,
    "food": 10,
    "toys": 2
  },
  "inventory": {
    "slots": [ ... ]
  },
  "dragon_factory": {
    "dragons": [
      {
        "dragon_id": "dragon_12345_0001",
        "dragon_name": "Pyrofrost the Wyrm",
        "level": 5,
        "experience": 1000,
        "current_health": 150,
        "hunger_level": 0.2,
        "fatigue_level": 0.3,
        ...
      }
    ],
    "dragon_collection": { ... }
  },
  "defense_manager": {
    "wave_number": 8,
    "time_until_next_wave": 45.0,
    "defending_dragon_ids": [ ... ]
  },
  "exploration_manager": {
    "active_explorations": [
      {
        "dragon_id": "dragon_12345_0001",
        "start_time": 1234567890,
        "duration": 1800,
        "duration_minutes": 30
      }
    ]
  },
  "scientist_manager": {
    "hired_scientists": {
      "0": true,  // STITCHER
      "1": false, // CARETAKER
      "2": true   // TRAINER
    }
  }
}
```

## Technical Details

### Serialization Methods

All managers implement `to_dict()` and `from_dict()` methods:

```gdscript
# Serialization
func to_dict() -> Dictionary:
    return {
        "field1": value1,
        "field2": value2
    }

# Deserialization
func from_dict(data: Dictionary):
    field1 = data.get("field1", default_value)
    field2 = data.get("field2", default_value)
```

### Save Process

1. **SaveLoadManager** collects data from all managers
2. Each manager serializes its state via `to_dict()`
3. Dragon instances are serialized with all properties
4. Data is converted to JSON
5. JSON is written to `user://savegame.json`

### Load Process

1. **SaveLoadManager** reads `user://savegame.json`
2. JSON is parsed and validated
3. Each manager restores state via `from_dict()`
4. Dragons are recreated and re-registered
5. References between systems are restored
6. UI is refreshed

### State Dependencies

The load order is critical due to dependencies:

1. **TreasureVault** (no dependencies)
2. **InventoryManager** (no dependencies)
3. **DragonFactory** (must load before managers that reference dragons)
4. **DefenseManager** (depends on DragonFactory for defending dragons)
5. **ExplorationManager** (depends on DragonFactory for exploring dragons)
6. **ScientistManager** (depends on DragonFactory for dragon automation)

## Handled Edge Cases

### Time-Based Systems

- **Hunger/Fatigue**: Calculated from timestamps, naturally handles offline time
- **Explorations**: Active explorations resume with correct remaining time
- **Wave Timer**: Defense wave timer resumes from saved state

### References

- **Dragon References**: Dragons are looked up by ID when restoring references
- **Missing Dragons**: Warning logged if a reference can't be restored
- **Orphaned Data**: Invalid data is skipped with warnings

### Version Compatibility

- Save files include version number
- Future updates can migrate old save formats
- Version mismatch triggers load failure with clear error

## API Reference

### SaveLoadManager

#### Methods

```gdscript
# Save the current game state
func save_game() -> bool

# Load game state from save file
func load_game() -> bool

# Check if save file exists
func has_save_file() -> bool

# Delete the save file
func delete_save_file() -> bool

# Enable/disable auto-save
func set_auto_save_enabled(enabled: bool)

# Get save file information
func get_save_info() -> Dictionary
```

#### Signals

```gdscript
# Emitted when game is saved (success: bool, message: String)
signal game_saved(success, message)

# Emitted when game is loaded (success: bool, message: String)
signal game_loaded(success, message)

# Emitted when auto-save triggers
signal auto_save_triggered()
```

#### Constants

```gdscript
const SAVE_FILE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 1
const AUTO_SAVE_INTERVAL: float = 120.0  # 2 minutes
```

## Integration

### Adding New Manager to Save System

To add a new manager to the save system:

1. **Implement Serialization Methods**:
   ```gdscript
   func to_dict() -> Dictionary:
       return {
           "my_state": my_state_variable,
           "my_data": my_data_array
       }

   func from_dict(data: Dictionary):
       my_state_variable = data.get("my_state", default)
       my_data_array = data.get("my_data", [])
   ```

2. **Add to SaveLoadManager.save_game()**:
   ```gdscript
   if MyManager and MyManager.instance:
       save_data["my_manager"] = MyManager.instance.to_dict()
   ```

3. **Add to SaveLoadManager.load_game()**:
   ```gdscript
   if save_data.has("my_manager") and MyManager and MyManager.instance:
       MyManager.instance.from_dict(save_data["my_manager"])
   ```

### Adding New Dragon Properties

Dragon properties marked with `@export` are automatically saved. To add a new property:

1. Add the `@export` annotation:
   ```gdscript
   @export var my_new_property: int = 0
   ```

2. Add to Dragon's `to_dict()`:
   ```gdscript
   "my_new_property": my_new_property
   ```

3. Add to Dragon's `from_dict()`:
   ```gdscript
   my_new_property = data.get("my_new_property", 0)
   ```

## Best Practices

1. **Always use `to_dict()` and `from_dict()`** for serialization
2. **Provide default values** in `from_dict()` for backward compatibility
3. **Use timestamps** instead of relative time for time-based systems
4. **Store references as IDs** and look them up during load
5. **Test save/load** after adding new game features
6. **Never store Node references** directly (use IDs or paths)
7. **Validate data** during load to handle corrupted saves

## Troubleshooting

### Save File Won't Load

1. Check console for error messages
2. Verify save file exists at the correct path
3. Check for JSON syntax errors in save file
4. Ensure save version matches current game version

### Missing Data After Load

1. Check if serialization methods are implemented
2. Verify manager is added to SaveLoadManager
3. Check load order for dependency issues
4. Look for warnings in console about missing references

### Auto-Save Not Working

1. Check if auto-save is enabled in dev menu
2. Verify SaveLoadManager is in autoload
3. Check console for save errors
4. Ensure game is running (not paused)

## Future Enhancements

Potential improvements for the save system:

- [ ] Multiple save slots
- [ ] Cloud save support
- [ ] Compressed save files
- [ ] Encrypted saves (for anti-cheat)
- [ ] Save file migration for version updates
- [ ] Backup saves (rotating backups)
- [ ] Save on quit (automatic save on game close)
- [ ] Load screen with save previews
- [ ] Import/export saves

## Files Modified

This save/load implementation touched the following files:

### New Files
- `/scripts/managers/save_load_manager.gd` - Main save/load manager
- `/docs/SAVE_LOAD_SYSTEM.md` - This documentation

### Modified Files
- `/scripts/managers/exploration_manager.gd` - Added `to_dict()` and `from_dict()`
- `/scripts/managers/scientist_manager.gd` - Added `to_dict()` and `from_dict()`
- `/scripts/dragon_system/dragon_factory.gd` - Added `to_dict()` and `from_dict()`
- `/scripts/dragon_system/dragon.gd` - Added `to_dict()` and `from_dict()`
- `/scripts/dev/dev_menu.gd` - Added save/load UI controls
- `/project.godot` - Added SaveLoadManager to autoload

### Existing Files (Already Had Serialization)
- `/scripts/managers/treasure_vault.gd` - Already had `to_dict()` and `from_dict()`
- `/scripts/inventory/inventory_manager.gd` - Already had `to_dict()` and `from_dict()`
- `/scripts/managers/defense_manager.gd` - Already had partial `to_dict()` and `from_dict()`

## Conclusion

The save/load system provides robust, automatic game state persistence with minimal performance impact. The modular design makes it easy to extend and maintain as new features are added to the game.
