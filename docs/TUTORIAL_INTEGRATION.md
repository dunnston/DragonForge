# Tutorial System Integration Guide

This guide explains how to integrate the opening letter scene and tutorial system into your dragon factory idle game.

## Files Created

### Scripts
- `scripts/opening/opening_letter.gd` - Opening letter with typewriter effect
- `scripts/opening/tutorial_manager.gd` - Interactive tutorial system with 7 steps
- `scripts/opening/new_player_init.gd` - New player detection and initialization

### Scenes
- `scenes/opening/opening_letter.tscn` - Opening letter scene
- `scenes/opening/tutorial_manager.tscn` - Tutorial UI overlay

## Integration Steps

### 1. Add Audio Files

The tutorial system expects these audio files. Add them to your project:

**Required Audio:**
- `res://assets/audio/typing_sound.wav` - Typewriter clicking sound (loopable)
- `res://assets/audio/thunder.wav` - Thunder crash sound effect
- `res://assets/audio/dramatic_music.mp3` - Background music for opening letter

**Optional but Recommended:**
- UI click sounds for tutorial buttons
- Tutorial completion fanfare

### 2. Update Audio Stream References

Open `scenes/opening/opening_letter.tscn` in the Godot editor and assign the audio streams:

1. Select the `TypingSound` node
2. In the Inspector, set the `Stream` property to your typewriter sound
3. Repeat for `ThunderSound` and `DramaticMusic` nodes

### 3. Add Arrow Sprite for Highlights

The tutorial uses an arrow to point at UI elements. Add an arrow sprite:

1. Create or import an arrow sprite: `res://assets/ui/arrow.png`
2. Open `scenes/opening/tutorial_manager.tscn`
3. Select the `HighlightArrow` node
4. In the Inspector, set the `Texture` property to your arrow sprite

### 4. Integrate with Title Screen or Main Scene

You have two options for starting the tutorial:

#### Option A: Automatic on First Launch (Recommended)

Modify your existing title screen or main scene script:

```gdscript
extends Control

func _ready() -> void:
    # Check if this is a new player
    if NewPlayerInit.is_new_player():
        # Initialize starting resources FIRST
        NewPlayerInit.initialize_starting_resources()
        # Then start the opening letter
        NewPlayerInit.start_new_player_experience()
    else:
        # Load main game for returning players
        get_tree().change_scene_to_file("res://scenes/main_scene/main_scene.tscn")
```

#### Option B: Manual "New Game" Button

Add a "New Game" button to your title screen:

```gdscript
func _on_new_game_pressed() -> void:
    # Initialize starting resources
    NewPlayerInit.initialize_starting_resources()
    # Start opening letter
    NewPlayerInit.start_new_player_experience()

func _on_continue_pressed() -> void:
    # Load existing save
    SaveLoadManager.load_game()
    get_tree().change_scene_to_file("res://scenes/main_scene/main_scene.tscn")
```

### 5. Update Main Scene Entry Point

The tutorial transitions to `res://scenes/main_scene/main_scene.tscn`. Ensure this path is correct for your project.

If your main game scene is at a different path, update these files:

**In `scripts/opening/opening_letter.gd`:**
```gdscript
# Line ~157
get_tree().change_scene_to_file("res://scenes/YOUR_MAIN_SCENE.tscn")
```

**In `scripts/opening/tutorial_manager.gd`:**
```gdscript
# Line ~286 and ~298
get_tree().change_scene_to_file("res://scenes/YOUR_MAIN_SCENE.tscn")
```

### 6. Add Factory Manager Group

The tutorial system needs to reference your main UI. Add this to your factory manager scene:

1. Open `scenes/ui/factory_manager.tscn`
2. Select the root node
3. In the Inspector, go to the "Node" tab
4. Under "Groups", add the group name: `factory_manager`

### 7. Connect Missing Signals

The tutorial listens for specific game events. Ensure these signals exist in your managers:

**DefenseManager** needs:
```gdscript
signal dragon_assigned(dragon: Dragon)
```

Add this signal and emit it when a dragon is assigned to defense:
```gdscript
func assign_dragon(dragon: Dragon) -> void:
    # ... your existing code ...
    dragon_assigned.emit(dragon)
```

### 8. Starting Inventory Initialization

The tutorial initializes starting resources (30 gold + 6 parts). You can either:

**Option A:** Let the tutorial handle it (default behavior in `tutorial_manager.gd`)

**Option B:** Call it manually before starting the tutorial:
```gdscript
NewPlayerInit.initialize_starting_resources()
```

## Tutorial Flow

The complete player experience:

1. **Opening Letter Scene** (`opening_letter.tscn`)
   - Typewriter effect displays the professor's letter
   - Thunder sound on dramatic moments
   - Player presses any key to continue
   - Fades to black and loads tutorial

2. **Tutorial Manager** (`tutorial_manager.tscn`)
   - 7 interactive steps teaching core mechanics
   - Highlights relevant UI elements
   - Waits for player actions or manual continue
   - Initializes starting inventory (30 gold + 6 parts)
   - Saves completion state

3. **Main Game**
   - Loads the main game scene
   - Player has starting resources
   - Tutorial won't show again

## Customization

### Adjust Typewriter Speed

In `scripts/opening/opening_letter.gd`:
```gdscript
@export var characters_per_second: float = 30.0  # Increase for faster typing
```

### Modify Starting Resources

In `scripts/opening/new_player_init.gd`:
```gdscript
# Change starting gold (line 28)
TreasureVault.add_gold(50)  # Give 50 instead of 30

# Change number of starting parts (line 31)
for i in range(5):  # Give 8 parts total instead of 6
```

### Disable Tutorial Skip Option

In `scenes/opening/tutorial_manager.tscn`:
1. Select the `TutorialManager` root node
2. In the Inspector, uncheck `Can Skip Tutorial`

Or in code:
```gdscript
@export var can_skip_tutorial: bool = false
```

### Customize Tutorial Steps

Edit `scripts/opening/tutorial_manager.gd` in the `setup_tutorial_steps()` function:

```gdscript
func setup_tutorial_steps() -> void:
    tutorial_steps = [
        create_step_1_create_dragon(),
        create_step_2_assign_defense(),
        # Add/remove/modify steps here
        create_your_custom_step(),
    ]
```

Create custom steps using the `TutorialStep` class:
```gdscript
func create_your_custom_step() -> TutorialStep:
    var step = TutorialStep.new()
    step.step_id = "unique_id"
    step.title = "Step Title"
    step.description = "Step description..."
    step.wait_for_action = "continue"  # or "dragon_created", etc.
    step.highlight_nodes = ["NodePath/To/Highlight"]

    step.on_enter = func():
        # Code to run when step starts
        pass

    step.on_exit = func():
        # Code to run when step completes
        pass

    return step
```

## Testing the Tutorial

### Test New Player Experience

1. Delete save files to simulate a new player:
   - Delete `user://savegame.json`
   - Delete `user://tutorial_save.json`

2. Run the game from your title screen or main scene

3. You should see:
   - Opening letter with typewriter effect
   - Tutorial system with step-by-step guidance
   - Starting inventory (30 gold + 6 parts)

### Test Tutorial Skip

1. In the tutorial, check the "Skip Tutorial" checkbox
2. Should immediately transition to main game
3. Starting inventory should still be initialized

### Test Returning Player

1. Complete the tutorial once
2. Close and reopen the game
3. Should skip directly to main game (no letter/tutorial)

## Troubleshooting

### "Node not found" errors

- Check that node paths match between `.tscn` and `.gd` files
- Ensure `@onready` variables point to correct node paths

### Tutorial doesn't detect actions

- Verify signals are connected in your managers
- Check that signal names match exactly
- Ensure managers are autoloaded (in Project Settings > Autoload)

### Audio doesn't play

- Verify audio files are imported correctly
- Check that Stream properties are assigned in the scene
- Ensure volume_db is not too low (try 0.0 for testing)

### Starting inventory not appearing

- Ensure `initialize_starting_resources()` is called before the tutorial
- Check that `TreasureVault` and `InventoryManager` are autoloaded
- Verify item IDs match your `items.json` data

### Tutorial shows every time

- Check that `user://tutorial_save.json` is being created
- Verify `save_tutorial_completion()` is called when tutorial finishes
- Check file permissions for the user:// directory

## Advanced: Multiple Tutorial Triggers

You can trigger specific tutorial steps at any time:

```gdscript
# In your game code
var tutorial = load("res://scenes/opening/tutorial_manager.tscn").instantiate()
add_child(tutorial)
tutorial.show_step(2)  # Show step 3 (feeding tutorial)
```

This allows you to show tutorial hints for new features added later in the game.

## Files Structure Summary

```
res://
├── scenes/
│   └── opening/
│       ├── opening_letter.tscn         # Opening scene
│       └── tutorial_manager.tscn       # Tutorial UI
├── scripts/
│   └── opening/
│       ├── opening_letter.gd           # Letter logic
│       ├── tutorial_manager.gd         # Tutorial steps
│       └── new_player_init.gd          # New player utilities
└── assets/
    └── audio/
        ├── typing_sound.wav            # (You need to add)
        ├── thunder.wav                 # (You need to add)
        └── dramatic_music.mp3          # (You need to add)
```

## Next Steps

1. Add the required audio files
2. Configure your title screen to check for new players
3. Test the complete flow (new player → letter → tutorial → main game)
4. Customize tutorial text to match your game's tone
5. Add polish (animations, particle effects, better arrow sprite)

The tutorial system is designed to be modular and extensible. You can easily add new steps, change the order, or integrate it with your existing UI systems.

Good luck with your game jam submission!
