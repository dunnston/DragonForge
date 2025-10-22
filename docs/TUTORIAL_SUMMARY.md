# Tutorial System - Summary

A complete opening scene and tutorial system for your dragon factory idle game has been created!

## What's Been Built

### 1. Opening Letter Scene
A dramatic introduction where the player inherits the dragon laboratory from Professor Von Drakescale.

**Features:**
- Typewriter effect (configurable speed)
- Thunder sound effects on dramatic moments
- Background music
- Skip functionality (press any key)
- Smooth fade transitions
- Parchment/aged paper aesthetic

**Files:**
- [scripts/opening/opening_letter.gd](scripts/opening/opening_letter.gd) - Letter logic with typewriter effect
- [scenes/opening/opening_letter.tscn](scenes/opening/opening_letter.tscn) - Letter scene UI

### 2. Interactive Tutorial System
A 7-step guided tutorial teaching all core game mechanics.

**Tutorial Steps:**
1. **Create Your First Dragon** - Learn the assembly system (head/body/tail)
2. **Assign to Defense** - Protect against knight waves
3. **Feed Your Dragon** - Understand hunger and maintenance
4. **Send on Exploration** - Gather resources while keeping defenses up
5. **Rest & Fatigue** - Manage dragon energy levels
6. **Hire Scientists** - Learn about automation (Stitcher, Caretaker, Trainer)
7. **Tutorial Complete** - Final tips and transition to main game

**Features:**
- Modal popups that block other interactions
- Highlight/spotlight specific UI elements
- Animated arrows pointing to relevant UI
- Progress tracking and save state
- Skip tutorial option
- Wait for player actions or manual continue
- Extensible step system

**Files:**
- [scripts/opening/tutorial_manager.gd](scripts/opening/tutorial_manager.gd) - Tutorial step logic
- [scenes/opening/tutorial_manager.tscn](scenes/opening/tutorial_manager.tscn) - Tutorial UI overlay

### 3. New Player Detection & Initialization
Utilities for detecting first-time players and initializing starting resources.

**Features:**
- Detect new vs. returning players
- Initialize starting inventory (30 gold + 6 dragon parts)
- Guaranteed at least 1 head, 1 body, 1 tail
- Random element distribution
- Save tutorial completion state

**Files:**
- [scripts/opening/new_player_init.gd](scripts/opening/new_player_init.gd) - New player utilities

### 4. Documentation
Comprehensive guides for integration and customization.

**Files:**
- [TUTORIAL_INTEGRATION.md](TUTORIAL_INTEGRATION.md) - Complete integration guide
- [assets/audio/TUTORIAL_AUDIO_SETUP.md](assets/audio/TUTORIAL_AUDIO_SETUP.md) - Audio setup instructions
- [TUTORIAL_SUMMARY.md](TUTORIAL_SUMMARY.md) - This file

## Quick Start

### Minimum Required Steps

1. **Add audio to the opening letter scene:**
   ```
   Open: scenes/opening/opening_letter.tscn
   Assign streams to: TypingSound, ThunderSound, DramaticMusic nodes
   (See assets/audio/TUTORIAL_AUDIO_SETUP.md for file recommendations)
   ```

2. **Add an arrow sprite for tutorial highlights:**
   ```
   Create/import: res://assets/ui/arrow.png
   Open: scenes/opening/tutorial_manager.tscn
   Assign to: HighlightArrow node's Texture property
   ```

3. **Integrate with your title screen or main scene:**
   ```gdscript
   # In your title screen _ready():
   func _ready() -> void:
       if NewPlayerInit.is_new_player():
           NewPlayerInit.initialize_starting_resources()
           NewPlayerInit.start_new_player_experience()
       else:
           get_tree().change_scene_to_file("res://scenes/main_scene/main_scene.tscn")
   ```

4. **Add the DefenseManager signal:**
   ```gdscript
   # In scripts/managers/defense_manager.gd
   signal dragon_assigned(dragon: Dragon)

   # Emit it when dragons are assigned to defense
   func assign_dragon(dragon: Dragon) -> void:
       # ... existing code ...
       dragon_assigned.emit(dragon)
   ```

5. **Tag your factory manager:**
   ```
   Open: scenes/ui/factory_manager.tscn
   Select: Root node
   Add group: "factory_manager"
   ```

That's it! The tutorial is now integrated.

## Testing

### Test as New Player
1. Delete `user://savegame.json` and `user://tutorial_save.json`
2. Run the game
3. Should see: Letter → Tutorial → Main game with 30 gold + 6 parts

### Test as Returning Player
1. Complete tutorial once
2. Close and reopen game
3. Should skip directly to main game

## File Structure

```
res://
├── scenes/
│   └── opening/
│       ├── opening_letter.tscn         ✅ Created
│       └── tutorial_manager.tscn       ✅ Created
├── scripts/
│   └── opening/
│       ├── opening_letter.gd           ✅ Created
│       ├── tutorial_manager.gd         ✅ Created
│       └── new_player_init.gd          ✅ Created
├── assets/
│   └── audio/
│       ├── typewriter-typing-68696.mp3                        ✅ Exists
│       ├── loud-rolling-thunder-with-gentle-rainfall-422430.mp3  ✅ Exists
│       ├── The Clockwork Ghost.mp3                           ✅ Exists
│       └── TUTORIAL_AUDIO_SETUP.md                           ✅ Created
├── TUTORIAL_INTEGRATION.md             ✅ Created (detailed guide)
└── TUTORIAL_SUMMARY.md                 ✅ Created (this file)
```

## Customization

### Change Tutorial Steps
Edit `tutorial_manager.gd` → `setup_tutorial_steps()` function

### Modify Starting Resources
Edit `new_player_init.gd` → `initialize_starting_resources()` function

### Adjust Typewriter Speed
Edit `opening_letter.gd` → `@export var characters_per_second: float = 30.0`

### Change Letter Text
Edit `opening_letter.gd` → `const LETTER_TEXT` variable

### Disable Skip Option
Edit `tutorial_manager.tscn` → Set `Can Skip Tutorial = false`

See [TUTORIAL_INTEGRATION.md](TUTORIAL_INTEGRATION.md) for detailed customization instructions.

## Technical Details

### Signal Flow
The tutorial listens for these game events:
- `DragonFactory.dragon_created` → Advances step 1
- `DefenseManager.dragon_assigned` → Advances step 2
- `InventoryManager.item_removed` (food) → Advances step 3
- `ExplorationManager.exploration_started` → Advances step 4

### Save Files
- `user://tutorial_save.json` - Tutorial completion state
- `user://savegame.json` - Game progress (checked for returning players)

### Integration Points
- Title screen → Check new player → Start letter
- Letter → Fade transition → Tutorial
- Tutorial → Initialize inventory → Main game
- Main game → Never show tutorial again

## Known Limitations

1. **Audio files must be assigned manually** in the Godot editor (can't be done via .tscn text)
2. **Arrow sprite must be created/imported** (not included)
3. **Tutorial assumes specific manager structure** (autoloaded singletons)
4. **UI highlighting uses basic spotlight** (can be enhanced with shaders)

## Future Enhancements

Potential improvements you could add:

- [ ] Add particle effects to tutorial highlights
- [ ] Animated letter scroll effect (instead of fade)
- [ ] Voice acting for the letter
- [ ] Tutorial replay option from settings menu
- [ ] Per-step completion tracking (resume tutorial mid-way)
- [ ] Tutorial hints that appear during normal gameplay
- [ ] Achievement for completing tutorial
- [ ] Easter eggs in the professor's letter

## Credits

This tutorial system was designed for a dragon factory idle game using:
- Godot 4.x
- Signal-based architecture
- Resource management patterns
- AFK/idle game mechanics

Built with extensibility in mind - easy to add new steps, integrate with existing systems, and customize for your game jam theme.

## Support

If you encounter issues:
1. Check [TUTORIAL_INTEGRATION.md](TUTORIAL_INTEGRATION.md) troubleshooting section
2. Verify all signals are connected properly
3. Check Godot console for error messages
4. Ensure all managers are autoloaded
5. Test with a clean save state (delete save files)

---

**Ready to go!** Follow the Quick Start steps above to integrate the tutorial into your game.

Good luck with your game jam! 🐉
