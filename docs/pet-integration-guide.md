# Pet Dragon System - Integration Guide

## ✅ What's Been Created

### Core Scripts (All Complete)
- ✅ `scripts/dragon_system/pet_dragon.gd` - PetDragon class
- ✅ `scripts/managers/pet_dragon_manager.gd` - Pet manager singleton
- ✅ `scripts/pet/pet_walking_character.gd` - Walking pet visual
- ✅ `scripts/ui/pet/pet_introduction_popup.gd` - First meeting UI
- ✅ `scripts/ui/pet/pet_interaction_ui.gd` - Main interaction UI
- ✅ `scripts/ui/pet/pet_status_widget.gd` - HUD widget
- ✅ `scripts/ui/pet/pet_journal_ui.gd` - Memory book
- ✅ `scripts/ui/pet/welcome_back_popup.gd` - Offline progress UI
- ✅ `project.godot` - PetDragonManager added to autoload

---

## 🎯 Next Steps (Manual Setup Required)

### Step 1: Create Scene Files in Godot Editor

You need to create `.tscn` files for each UI component. Here's the structure:

#### A. `scenes/pet/pet_walking_character.tscn`

```
PetWalkingCharacter (CharacterBody2D) [script: pet_walking_character.gd]
├── DragonVisual (Node2D) [unique name: %DragonVisual]
│   └── Sprite2D [with dragon shader material]
├── CollisionShape2D
├── WanderTimer (Timer)
├── ClickArea (Area2D)
│   └── CollisionShape2D
├── MoodIndicator (Node2D)
└── AnimationPlayer
    ├── idle (animation)
    ├── walk (animation)
    └── happy_bounce (animation)
```

#### B. `scenes/ui/pet/pet_introduction_popup.tscn`

```
PetIntroductionPopup (Control) [script: pet_introduction_popup.gd]
├── Panel (Panel)
│   ├── VBoxContainer
│   │   ├── TitleLabel (Label) [unique: %TitleLabel]
│   │   ├── DragonVisual (Node2D) [unique: %DragonVisual]
│   │   ├── PersonalityLabel (Label) [unique: %PersonalityLabel]
│   │   ├── PersonalityDescription (Label) [unique: %PersonalityDescription]
│   │   ├── InfoLabel (Label) [unique: %InfoLabel]
│   │   ├── NameInput (LineEdit) [unique: %NameInput]
│   │   └── ConfirmButton (Button) [unique: %ConfirmButton]
```

#### C. `scenes/ui/pet/pet_interaction_ui.tscn`

```
PetInteractionUI (Control) [script: pet_interaction_ui.gd]
├── Panel (Panel)
│   ├── HBoxContainer
│   │   ├── LeftPanel (VBoxContainer)
│   │   │   ├── DragonVisual [unique: %DragonVisual]
│   │   │   ├── MoodLabel [unique: %MoodLabel]
│   │   │   ├── PersonalityLabel [unique: %PersonalityLabel]
│   │   │   ├── AffectionLabel [unique: %AffectionLabel]
│   │   │   └── DaysTogetherLabel [unique: %DaysTogetherLabel]
│   │   └── RightPanel (VBoxContainer)
│   │       ├── NameLabel [unique: %NameLabel]
│   │       ├── LevelLabel [unique: %LevelLabel]
│   │       ├── XPProgress (ProgressBar) [unique: %XPProgress]
│   │       ├── StatsContainer
│   │       │   ├── HealthLabel [unique: %HealthLabel]
│   │       │   ├── HungerLabel [unique: %HungerLabel]
│   │       │   └── FatigueLabel [unique: %FatigueLabel]
│   │       ├── ActionsContainer
│   │       │   ├── PetButton [unique: %PetButton]
│   │       │   ├── FeedButton [unique: %FeedButton]
│   │       │   ├── GiftButton [unique: %GiftButton]
│   │       │   ├── TalkButton [unique: %TalkButton]
│   │       │   └── JournalButton [unique: %JournalButton]
│   │       ├── ExplorationContainer
│   │       │   ├── ExplorationStatusLabel [unique: %ExplorationStatusLabel]
│   │       │   ├── ExplorationProgress [unique: %ExplorationProgress]
│   │       │   └── SendExploringButton [unique: %SendExploringButton]
│   │       ├── DialogueLabel [unique: %DialogueLabel]
│   │       └── CloseButton [unique: %CloseButton]
```

#### D. `scenes/ui/pet/pet_status_widget.tscn`

```
PetStatusWidget (Control) [script: pet_status_widget.gd]
├── HBoxContainer
│   ├── Portrait (TextureRect) [unique: %Portrait]
│   ├── InfoContainer (VBoxContainer)
│   │   ├── NameLevelLabel [unique: %NameLevelLabel]
│   │   ├── AffectionLabel [unique: %AffectionLabel]
│   │   └── StatusLabel [unique: %StatusLabel]
│   └── ViewButton [unique: %ViewButton]
```

#### E. `scenes/ui/pet/pet_journal_ui.tscn`

```
PetJournalUI (Control) [script: pet_journal_ui.gd]
├── Panel
│   ├── HBoxContainer
│   │   ├── StatsPage (VBoxContainer)
│   │   │   ├── DaysTogetherLabel [unique: %DaysTogetherLabel]
│   │   │   ├── AffectionLabel [unique: %AffectionLabel]
│   │   │   ├── ExpeditionsLabel [unique: %ExpeditionsLabel]
│   │   │   ├── GoldEarnedLabel [unique: %GoldEarnedLabel]
│   │   │   ├── PartsFoundLabel [unique: %PartsFoundLabel]
│   │   │   ├── FavoriteDestLabel [unique: %FavoriteDestLabel]
│   │   │   ├── TimesFedLabel [unique: %TimesFedLabel]
│   │   │   └── TimesPettedLabel [unique: %TimesPettedLabel]
│   │   └── MomentsPage (ScrollContainer)
│   │       └── MomentsContainer (VBoxContainer) [unique: %MomentsContainer]
│   └── CloseButton [unique: %CloseButton]
```

#### F. `scenes/ui/pet/welcome_back_popup.tscn`

```
WelcomeBackPopup (Control) [script: welcome_back_popup.gd]
├── Panel
│   ├── VBoxContainer
│   │   ├── TimeAwayLabel [unique: %TimeAwayLabel]
│   │   ├── PetNameLabel [unique: %PetNameLabel]
│   │   ├── DragonVisual [unique: %DragonVisual]
│   │   ├── ResultsContainer (VBoxContainer) [unique: %ResultsContainer]
│   │   ├── DialogueLabel [unique: %DialogueLabel]
│   │   ├── ButtonsContainer (HBoxContainer)
│   │   │   ├── PetButton [unique: %PetButton]
│   │   │   └── CollectButton [unique: %CollectButton]
```

**IMPORTANT**: Use `%NodeName` (unique names) in the scene tree for all referenced nodes!

---

### Step 2: Integration with ExplorationManager

Modify `scripts/managers/exploration_manager.gd`:

```gdscript
# In _complete_exploration() function, add after calculating rewards:

func _complete_exploration(dragon: Dragon, destination: String, rewards: Dictionary):
    # ... existing reward calculation ...

    # Check if this is the pet dragon
    if dragon is PetDragon and PetDragonManager and PetDragonManager.instance:
        # Notify PetDragonManager
        PetDragonManager.instance.on_pet_expedition_complete(destination, rewards)

        # Apply personality bonuses
        var personality_bonus = dragon.get_personality_bonus("gold")
        rewards["gold"] = int(rewards["gold"] * personality_bonus)

        # Apply affection bonus
        var affection_bonus = dragon.get_affection_bonus()
        rewards["gold"] = int(rewards["gold"] * affection_bonus)

    # ... rest of existing code ...
```

---

### Step 3: Integration with SaveLoadManager

Modify `scripts/managers/save_load_manager.gd`:

```gdscript
# In save_game() function, add:

func save_game() -> bool:
    # ... existing save data ...

    # Save PetDragonManager
    if PetDragonManager and PetDragonManager.instance:
        save_data["pet_dragon_manager"] = PetDragonManager.instance.to_dict()
        print("[SaveLoadManager] ✓ Saved PetDragonManager")

    # ... rest of save code ...

# In load_game() function, add:

func load_game() -> bool:
    # ... existing load code ...

    # Load PetDragonManager (after loading dragons)
    if save_data.has("pet_dragon_manager") and PetDragonManager and PetDragonManager.instance:
        PetDragonManager.instance.from_dict(save_data["pet_dragon_manager"])
        print("[SaveLoadManager] ✓ Loaded PetDragonManager")

    # ... rest of load code ...
```

---

### Step 4: First Dragon Creation Hook

Find where the first dragon is created (likely in tutorial or `NewPlayerInit`).

Add this code:

```gdscript
func create_first_dragon(head_part: DragonPart, body_part: DragonPart, tail_part: DragonPart):
    # Create the pet dragon
    var pet = PetDragonManager.instance.create_pet_dragon(head_part, body_part, tail_part)

    # Show introduction popup
    var intro_popup = preload("res://scenes/ui/pet/pet_introduction_popup.tscn").instantiate()
    intro_popup.setup(pet)
    get_tree().root.add_child(intro_popup)

    # Wait for player to name the pet
    await intro_popup.name_confirmed

    print("[Game] Pet dragon created and named: %s" % pet.dragon_name)
```

---

### Step 5: Add Pet to Main Scene

Modify `scenes/main_scene/main_scene.tscn`:

1. Add `PetWalkingCharacter` as a child node
2. Add `PetStatusWidget` to the UI layer (top-right corner)
3. Add to group: "pet_walking_character" for the walking pet

In `scripts/main_scene/main_scene.gd`:

```gdscript
@onready var pet_walking: PetWalkingCharacter = $PetWalkingCharacter
@onready var pet_status_widget: PetStatusWidget = $UI/PetStatusWidget

func _ready():
    # ... existing setup ...

    # Setup pet components
    if PetDragonManager.instance and PetDragonManager.instance.has_pet():
        var pet = PetDragonManager.instance.get_pet_dragon()
        pet_walking.setup(pet)
        pet_status_widget.setup(pet)

        # Connect click signal
        pet_walking.pet_clicked.connect(_on_pet_clicked)
    else:
        pet_walking.hide()
        pet_status_widget.hide()

func _on_pet_clicked(pet: PetDragon):
    # Open pet interaction UI
    var pet_ui = preload("res://scenes/ui/pet/pet_interaction_ui.tscn").instantiate()
    add_child(pet_ui)
```

---

### Step 6: Offline Progress on Game Load

Modify the game's startup sequence (likely in `main_scene.gd` or `title_screen.gd`):

```gdscript
func _on_game_loaded():
    # Get time since last save
    var last_save_time = SaveLoadManager.instance.get_last_save_timestamp()
    var current_time = Time.get_unix_time_from_system()
    var seconds_offline = current_time - last_save_time

    # If offline > 10 minutes (600 seconds) and has pet
    if seconds_offline > 600 and PetDragonManager.instance and PetDragonManager.instance.has_pet():
        # Calculate offline progress
        var results = PetDragonManager.instance.calculate_offline_progress(seconds_offline)

        # Show welcome back popup
        await get_tree().process_frame  # Wait for scene to be ready
        var welcome_popup = preload("res://scenes/ui/pet/welcome_back_popup.tscn").instantiate()
        welcome_popup.setup(results, seconds_offline)
        get_tree().root.add_child(welcome_popup)

        # Apply rewards to game state
        if TreasureVault.instance:
            TreasureVault.instance.add_gold(results.get("gold", 0))

        # Add parts to inventory
        if InventoryManager.instance:
            for i in results.get("parts", 0):
                var random_element = DragonPart.Element.values().pick_random()
                var random_type = [DragonPart.PartType.HEAD, DragonPart.PartType.BODY, DragonPart.PartType.TAIL].pick_random()
                var part = PartLibrary.instance.get_part_by_element_and_type(random_element, random_type)
                InventoryManager.instance.add_dragon_part(part)
```

---

### Step 7: Emergency Rescue System (Optional)

Create `scripts/managers/game_state_checker.gd`:

```gdscript
extends Node

# Check for crisis every 30 seconds
var check_timer: Timer
var last_emergency_time: int = 0
const EMERGENCY_COOLDOWN: int = 3600  # 1 hour

func _ready():
    check_timer = Timer.new()
    check_timer.wait_time = 30.0
    check_timer.timeout.connect(_check_for_crisis)
    add_child(check_timer)
    check_timer.start()

func _check_for_crisis():
    if not PetDragonManager.instance or not PetDragonManager.instance.has_pet():
        return

    # Check if player is stuck (low gold, no parts, only pet alive)
    var gold = TreasureVault.instance.get_total_gold() if TreasureVault.instance else 0
    var has_parts = InventoryManager.instance.has_dragon_parts() if InventoryManager.instance else false

    var current_time = Time.get_unix_time_from_system()
    var can_trigger = (current_time - last_emergency_time) > EMERGENCY_COOLDOWN

    if gold < 100 and not has_parts and can_trigger:
        _trigger_emergency_rescue()

func _trigger_emergency_rescue():
    var rewards = PetDragonManager.instance.generate_emergency_rewards()

    # Apply rewards
    if TreasureVault.instance:
        TreasureVault.instance.add_gold(rewards["gold"])

    if InventoryManager.instance:
        for element in rewards["parts"]:
            var part = PartLibrary.instance.get_part_by_element_and_type(element, DragonPart.PartType.BODY)
            InventoryManager.instance.add_dragon_part(part)

    # Show popup
    print("[GameStateChecker] Emergency rescue triggered!")

    last_emergency_time = Time.get_unix_time_from_system()
```

Then add to `project.godot`:

```ini
GameStateChecker="*res://scripts/managers/game_state_checker.gd"
```

---

## 🧪 Testing Checklist

### Basic Functionality
- [ ] Create first dragon → Pet introduction popup appears
- [ ] Can name the pet
- [ ] Pet appears walking around main scene
- [ ] Clicking pet opens interaction UI
- [ ] Can feed pet (costs 50 gold, reduces hunger)
- [ ] Can pet dragon (1-hour cooldown)
- [ ] Pet status widget visible in top-right

### Exploration
- [ ] Can send pet on exploration (15 min)
- [ ] Pet auto-explores when idle and not too hungry/tired
- [ ] Pet disappears from screen when exploring
- [ ] Pet returns after exploration with rewards
- [ ] Personality bonuses apply to rewards
- [ ] Affection bonuses apply to rewards

### Affection & Personality
- [ ] Feeding increases affection (+2)
- [ ] Petting increases affection (+5, 1hr cooldown)
- [ ] Exploration increases affection (+1 per trip)
- [ ] Affection tier changes trigger memorable moments
- [ ] Personality affects exploration destination choice
- [ ] Random dialogue reflects personality

### Save/Load
- [ ] Pet data saves correctly
- [ ] Pet data loads correctly
- [ ] All stats preserved (affection, stats, moments, etc.)
- [ ] Exploration state preserved

### Offline Progress
- [ ] Offline for >10 min → Welcome back popup shows
- [ ] Correct number of expeditions calculated
- [ ] Rewards applied (gold, parts, XP, gifts)
- [ ] Level-ups counted
- [ ] Can pet from welcome popup

### Pet Cannot Die
- [ ] Pet health never goes below 1
- [ ] Pet cannot be assigned to defense
- [ ] Damage is taken but death prevented
- [ ] Memorable moment added when saved from death

---

## 🎨 Visual Assets Needed

To complete the pet system visually, you'll need:

1. **Dragon sprite with shader** - Already exists (DragonVisual)
2. **Mood icons** - Hunger, tired, happy icons for MoodIndicator
3. **UI panels** - Panel backgrounds for popups
4. **Portrait texture** - Small dragon portrait for status widget
5. **Sparkle effect** - Particle effect for pet return (optional)
6. **Heart particles** - When petting (optional)

---

## 📊 Constants to Balance

Located in the script files:

### PetDragon.gd
- `PET_COOLDOWN: 3600` - Time between pets (1 hour)
- `FEED_AFFECTION: 2` - Affection from feeding
- `PET_AFFECTION: 5` - Affection from petting
- `GIFT_AFFECTION: 5` - Affection from gifts
- `EXPEDITION_AFFECTION: 1` - Affection per exploration

### PetDragonManager.gd
- `AUTO_EXPLORE_CHECK_INTERVAL: 10.0` - Seconds between auto-explore checks
- `AUTO_EXPLORE_HUNGER_THRESHOLD: 0.7` - Don't explore if too hungry
- `AUTO_EXPLORE_DURATION: 15` - Always 15-minute explorations
- `EMERGENCY_GOLD: 500` - Gold from rescue
- `EMERGENCY_PARTS: 3` - Parts from rescue
- `MAX_OFFLINE_TIME: 86400` - Max offline time (24 hours)

### PetInteractionUI.gd
- `FEED_COST: 50` - Gold cost to feed pet

---

## 🚀 Quick Start Guide

**To get the pet system working:**

1. ✅ Core scripts are done
2. 🔲 Create all scene files (.tscn) in Godot editor
3. 🔲 Add PetDragonManager integration to ExplorationManager
4. 🔲 Add PetDragonManager integration to SaveLoadManager
5. 🔲 Hook first dragon creation to create pet
6. 🔲 Add pet walking and status widget to main scene
7. 🔲 Add offline progress check on game load
8. 🔲 Test everything!

**Total estimated time**: 2-4 hours for scene creation and integration.

---

## 💡 Tips

- Start with the PetIntroductionPopup - it's the simplest UI
- Test each UI component individually before integrating
- Use DevMenu to test offline progress (manipulate time)
- Use DevMenu to test affection/personality changes
- Pet cannot defend - this is intentional!
- Pet cannot die - this is the core feature!

Good luck! 🐉✨
