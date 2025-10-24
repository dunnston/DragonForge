# 🐉 PET DRAGON SYSTEM - IMPLEMENTATION PLAN

## Overview
The Pet Dragon is your player's **first dragon** that becomes a permanent companion with:
- **Unique gameplay**: Cannot die, cannot defend (explore & train only)
- **Tamagotchi-style bonding**: Feed, pet, gift, personality, moods, memories
- **Visual presence**: Walks around the main screen, click to open interaction modal
- **Failsafe mechanic**: Prevents game-over by auto-exploring and providing emergency resources
- **Offline progress**: Continues exploring while player is AFK

---

## PHASE 1: Core Pet Dragon Class (2-3 hours)

### 1.1 Create PetDragon Class
**File**: `scripts/dragon_system/pet_dragon.gd`

Extends the existing `Dragon` class with:
- **6 Personality types**: Curious, Brave, Lazy, Energetic, Greedy, Gentle
- **Affection system**: 0-100 scale with 5 tiers (Acquaintance → Soulbound)
- **Statistics tracking**: Times fed/petted/gifted, expeditions completed, gold/parts earned
- **Memory system**: Memorable moments with timestamps
- **Gift system**: Pending gifts from explorations
- **Special overrides**:
  - `take_damage()` - Pet cannot die (health never goes below 1)
  - `_die()` - Disabled for pet dragons
  - Personality-based bonuses for exploration rewards

**Key Methods:**
```gdscript
func get_affection_tier() -> String
func get_affection_bonus() -> float  # 1.0 to 1.25x multiplier
func get_personality_bonus(reward_type: String) -> float
func add_affection(amount: int)
func pet() -> bool  # 1-hour cooldown
func feed()  # +2 affection
func give_gift()  # +5 affection
func complete_expedition(...)  # Track stats + generate gifts
func add_memorable_moment(title, description)
func get_random_dialogue() -> String  # Personality-based
```

**Personality Types & Bonuses:**
- **Curious**: +15% parts from exploration, explores random destinations
- **Brave**: +10% all rewards from dangerous locations (level 10+)
- **Lazy**: +50% exploration time but +20% food rewards
- **Energetic**: -25% exploration time but -10% gold rewards
- **Greedy**: +25% gold from exploration
- **Gentle**: +15% affection gain, safe exploration choices

**Affection Tiers:**
1. **Acquaintance** (0-19): No bonus
2. **Friend** (20-39): +5% exploration rewards
3. **Companion** (40-59): +10% exploration rewards
4. **Best Friend** (60-79): +15% exploration rewards
5. **Soulbound** (80-100): +25% exploration rewards

**Statistics to Track:**
```gdscript
@export var times_fed: int = 0
@export var times_petted: int = 0
@export var times_gifted: int = 0
@export var expeditions_completed: int = 0
@export var total_gold_earned: int = 0
@export var total_parts_found: int = 0
@export var days_together: int = 0
@export var favorite_destination: String = ""
@export var memorable_moments: Array = []  # {title, description, timestamp}
@export var pending_gifts: Array = []  # Items to show player
```

---

## PHASE 2: Pet Dragon Manager (3-4 hours)

### 2.1 Create PetDragonManager Singleton
**File**: `scripts/managers/pet_dragon_manager.gd`

**Autoload**: Add to Project Settings → Autoload as `PetDragonManager`

Manages the **single pet dragon** instance with:

**Core Responsibilities:**
1. **Creation**: First dragon → Pet dragon with random personality
2. **Auto-exploration**: Checks every 10 seconds, auto-sends pet when idle
3. **Offline progress**: Calculates expeditions while player was away
4. **Emergency rescue**: Provides guaranteed resources when player is stuck
5. **Integration**: Hooks into ExplorationManager for pet-specific rewards

**Key Properties:**
```gdscript
var pet_dragon: PetDragon = null
var last_pet_time: int = 0  # Timestamp of last pet action
var auto_explore_enabled: bool = true
var check_timer: Timer
```

**Key Methods:**
```gdscript
func create_pet_dragon(head, body, tail) -> PetDragon
func set_pet_name(name: String)
func is_pet_exploring() -> bool
func can_auto_explore() -> bool
func start_auto_exploration()
func on_pet_expedition_complete(destination, rewards)
func calculate_offline_progress(seconds_offline) -> Dictionary
func generate_emergency_rewards() -> Dictionary
func to_dict() -> Dictionary  # Save/load
func from_dict(data: Dictionary)
```

**Auto-Exploration Logic:**
- Timer checks every 10 seconds
- If pet is IDLE and hunger < 70%: auto-send exploring (15-min exploration)
- Destination chosen based on personality:
  - **Curious**: Random
  - **Brave**: Dangerous locations (level 10+)
  - **Lazy/Energetic**: Short trips (volcanic_caves)
  - **Greedy**: Gold-rich (ancient_forest)
  - **Gentle**: Safe + parts (frozen_tundra)

**Offline Progress:**
- Calculate how many 15-min expeditions completed while offline
- Apply personality time modifiers (Energetic -25%, Lazy +50%)
- Generate rewards for each expedition
- Track level-ups and gifts
- Return summary dictionary for WelcomeBackPopup

**Emergency Rescue:**
- Triggered when: Only pet left + gold < 100 + no parts
- Gives: 500 gold + 3 random parts
- Shows popup: "Your pet sensed danger and returned with supplies!"
- Can only trigger once per hour (prevent exploitation)

---

## PHASE 3: Walking Pet Visual (2-3 hours)

### 3.1 Create PetWalkingCharacter Scene
**File**: `scenes/pet/pet_walking_character.tscn`

A **CharacterBody2D** that wanders around the main scene:

**Scene Structure:**
```
PetWalkingCharacter (CharacterBody2D)
├── CollisionShape2D (for movement)
├── DragonVisual (Node2D - reuse existing dragon visual system)
├── AnimationPlayer (idle, walk, happy_bounce)
├── WanderTimer (Timer - changes direction every 5-10 seconds)
├── ClickArea (Area2D + CollisionShape2D for mouse detection)
│   └── CollisionShape2D
└── MoodIndicator (Node2D - shows hearts/hunger/sleep icons)
```

**Script**: `scripts/pet/pet_walking_character.gd`

**Behavior:**
- **Wander AI**:
  - Random direction changes every 5-10 seconds
  - Smooth movement with velocity
  - Stays within bounds (50px from edges)
  - Speed: 50-100 pixels/second (personality-based)
- **Animations**:
  - Idle when velocity near zero
  - Walk when moving
  - Happy bounce when petted (particle hearts)
- **Click detection**:
  - When ClickArea receives mouse click → open PetInteractionUI
  - Hover shows name tooltip
- **Visual updates**:
  - Shows pet's current mood (happy/hungry/tired icons)
  - Scale based on level (larger as pet levels up)
  - Hidden when pet is exploring
- **Boundary checking**:
  - Stays within visible screen area
  - Reverses direction when hitting boundaries

**Integration:**
- Add to `main_scene.tscn` as child node
- Initially positioned at (200, 600) - bottom-left area
- References `PetDragonManager.pet_dragon` for visual state
- Hides itself when pet state == EXPLORING
- Shows sparkle effect when returning from exploration

---

## PHASE 4: UI Components (4-5 hours)

### 4.1 Pet Introduction Popup
**Files**: `scenes/ui/pet/pet_introduction_popup.tscn` + `scripts/ui/pet/pet_introduction_popup.gd`

Shown when creating first dragon:
- **Layout**: Center panel (600x500px)
- **Elements**:
  - Title: "Meet Your New Companion!"
  - Dragon visual display (animated)
  - Personality badge (icon + name)
  - Personality description text
  - Name input field (LineEdit, max 20 chars, required)
  - Info text: "This special dragon will be your companion throughout your journey. They'll explore the world and bring you treasures!"
  - [Confirm Name] button (disabled until name entered)

**Script Methods:**
```gdscript
func setup(pet: PetDragon)
func _on_confirm_pressed()
func _on_name_changed(new_text: String)
```

### 4.2 Welcome Back Popup
**Files**: `scenes/ui/pet/welcome_back_popup.tscn` + `scripts/ui/pet/welcome_back_popup.gd`

Shown on game start if offline > 10 minutes:
- **Layout**: Center panel (700x600px)
- **Elements**:
  - Title: "Welcome Back!"
  - Time away display: "You were gone for X hours Y minutes"
  - Pet name + "kept working while you were away!"
  - Scrollable results list:
    - "Completed X expeditions"
    - "Earned X gold"
    - "Found X dragon parts"
    - "Gained X levels" (if any)
    - "Brought back X gifts"
  - Pet dialogue quote (personality-based)
  - Sparkle particle effects
  - [Collect Rewards] button (adds rewards to inventory)
  - [Pet Your Companion] button (adds affection + plays animation)

**Script Methods:**
```gdscript
func setup(results: Dictionary, seconds_offline: int)
func _on_collect_pressed()
func _on_pet_pressed()
```

### 4.3 Pet Interaction UI
**Files**: `scenes/ui/pet/pet_interaction_ui.tscn` + `scripts/ui/pet/pet_interaction_ui.gd`

Main interaction modal (opened by clicking walking pet):
- **Layout**: Center panel (800x700px), left-right split
- **Left Panel** (400px):
  - Large animated pet display
  - Mood indicator (happy/hungry/tired)
  - Personality label with icon
  - Affection display (hearts visual, e.g., ❤️❤️❤️🤍🤍)
  - Days together counter
- **Right Panel** (400px):
  - Pet name (large header)
  - Level + XP bar
  - Stats grid:
    - Health: [===] / max
    - Hunger: [===]
    - Fatigue: [===]
  - Action buttons (vertical list):
    - [❤️ Pet] (greyed if on cooldown, shows "Available in X min")
    - [🍖 Feed] (shows cost: 50 gold)
    - [🎁 Give Gift] (shows available gifts, greyed if none)
    - [💬 Talk] (shows random dialogue)
    - [📖 Journal] (opens Pet Journal UI)
  - Exploration section:
    - Status: "Resting" / "Exploring at X"
    - If exploring: Progress bar + time remaining
    - If idle: [🗺️ Send Exploring] button
  - [Close] button (bottom-right)

**Script Methods:**
```gdscript
func _ready()
func _update_display()
func _on_pet_pressed()
func _on_feed_pressed()
func _on_gift_pressed()
func _on_talk_pressed()
func _on_journal_pressed()
func _on_send_exploring_pressed()
```

**Feed Cost**: 50 gold (configurable constant)

**Pet Cooldown**: 1 hour (3600 seconds)

### 4.4 Pet Journal UI
**Files**: `scenes/ui/pet/pet_journal_ui.tscn` + `scripts/ui/pet/pet_journal_ui.gd`

Memory book showing pet's journey:
- **Layout**: Center panel (900x700px), book-style layout
- **Left Page** (Adventure Stats):
  - Days Together: X
  - Affection: ❤️❤️❤️❤️🤍 (Companion)
  - Total Expeditions: X
  - Gold Earned: X
  - Parts Found: X
  - Favorite Destination: X (most visited)
- **Right Page** (Memorable Moments):
  - Scrollable list of moments:
    - "First Meeting" - [date]
    - "Reached Companion Status" - [date]
    - "Rescued You From Crisis" - [date]
    - "Found a Legendary Part" - [date]
    - etc.
  - Each moment has title + description + timestamp
  - Recent moments at top
- **Buttons**:
  - [Previous Page] / [Next Page] (if multiple pages)
  - [Close] button

**Script Methods:**
```gdscript
func setup(pet: PetDragon)
func _populate_stats()
func _populate_moments()
func _on_close_pressed()
```

### 4.5 Pet Status Widget
**Files**: `scenes/ui/pet/pet_status_widget.tscn` + `scripts/ui/pet/pet_status_widget.gd`

Always-visible widget in main scene UI:
- **Layout**: Top-right corner (300x80px), compact horizontal layout
- **Elements**:
  - Pet portrait (small, 60x60px)
  - Name + Level (e.g., "Sparkwing Lv.5")
  - Affection hearts (❤️❤️❤️🤍🤍)
  - Status indicator:
    - If exploring: "Exploring at [destination]" + countdown timer
    - If resting: "Resting"
    - If training: "Training"
  - [👁️ View] button (opens PetInteractionUI)
- **Updates**: Refreshes every second to update countdown

**Script Methods:**
```gdscript
func _ready()
func _process(delta)
func _update_status()
func _on_view_pressed()
```

**Integration**: Add to main_scene.tscn UI layer

---

## PHASE 5: Integration with Existing Systems (2-3 hours)

### 5.1 First Dragon Creation Hook
**Modify**: First dragon creation flow

**Location**: Likely in tutorial or opening sequence where first dragon is created

```gdscript
# After player selects parts for first dragon:
func create_first_dragon(head_part, body_part, tail_part):
    # Create the pet dragon
    var pet = PetDragonManager.instance.create_pet_dragon(head_part, body_part, tail_part)

    # Show introduction popup
    var intro_popup = preload("res://scenes/ui/pet/pet_introduction_popup.tscn").instantiate()
    intro_popup.setup(pet)
    get_tree().root.add_child(intro_popup)

    # Add memorable moment
    pet.add_memorable_moment("First Meeting", "The day we met and began our journey together.")

    # Start the walking pet visual
    _spawn_walking_pet()
```

**Files to Modify**:
- `scripts/opening/new_player_init.gd` (if this handles first dragon)
- Or wherever the tutorial creates the first dragon

### 5.2 Exploration System Integration
**Modify**: `scripts/managers/exploration_manager.gd`

Add pet-specific logic to `_complete_exploration()`:

```gdscript
func _complete_exploration(dragon_id: String):
    # ... existing reward calculation ...

    var dragon = exploration["dragon"]

    # Check if this is the pet dragon
    if dragon is PetDragon and PetDragonManager and PetDragonManager.instance:
        # Notify PetDragonManager
        PetDragonManager.instance.on_pet_expedition_complete(destination, rewards)

        # Apply personality bonuses to rewards
        var personality_bonus = dragon.get_personality_bonus("all")
        rewards["gold"] = int(rewards["gold"] * personality_bonus)
        rewards["xp"] = int(rewards["xp"] * personality_bonus)

        # Apply affection bonuses
        var affection_bonus = dragon.get_affection_bonus()
        rewards["gold"] = int(rewards["gold"] * affection_bonus)
        rewards["xp"] = int(rewards["xp"] * affection_bonus)

    # ... rest of existing code ...
```

### 5.3 Game Start Offline Progress
**Modify**: Main scene or title screen game load sequence

**Location**: `scenes/main_scene/main_scene.gd` or `scenes/title_screen/title_screen.gd`

```gdscript
func _on_game_loaded():
    # Get time since last save
    var save_info = SaveLoadManager.instance.get_save_info()
    var last_save_time = save_info.get("timestamp", 0)
    var current_time = Time.get_unix_time_from_system()
    var seconds_offline = current_time - last_save_time

    # If offline > 10 minutes (600 seconds) and has pet
    if seconds_offline > 600 and PetDragonManager.instance and PetDragonManager.instance.pet_dragon:
        # Calculate offline progress
        var results = PetDragonManager.instance.calculate_offline_progress(seconds_offline)

        # Show welcome back popup
        await get_tree().process_frame  # Wait for scene to be ready
        var welcome_popup = preload("res://scenes/ui/pet/welcome_back_popup.tscn").instantiate()
        welcome_popup.setup(results, seconds_offline)
        get_tree().root.add_child(welcome_popup)
```

### 5.4 Game Over Prevention
**Create**: `scripts/managers/game_state_checker.gd` (new file)

Or add to existing manager like `PetDragonManager`:

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
    if not PetDragonManager.instance or not PetDragonManager.instance.pet_dragon:
        return

    var all_dragons = DragonFactory.instance.get_all_dragons() if DragonFactory.instance else []
    var total_dragons = all_dragons.size()
    var alive_dragons = all_dragons.filter(func(d): return not d.is_dead).size()
    var has_resources = TreasureVault.instance.get_total_gold() > 100 if TreasureVault.instance else false
    var has_parts = InventoryManager.instance.has_any_parts() if InventoryManager.instance else false

    # Crisis condition: Only pet alive + low resources + not recently rescued
    var current_time = Time.get_unix_time_from_system()
    var can_trigger = (current_time - last_emergency_time) > EMERGENCY_COOLDOWN

    if alive_dragons == 1 and not has_resources and not has_parts and can_trigger:
        _trigger_emergency_rescue()

func _trigger_emergency_rescue():
    var rewards = PetDragonManager.instance.generate_emergency_rewards()

    # Apply rewards
    if TreasureVault.instance:
        TreasureVault.instance.add_gold(rewards["gold"])

    if InventoryManager.instance:
        for part_id in rewards["parts"]:
            InventoryManager.instance.add_item_by_id(part_id, 1)

    # Show popup
    var popup = preload("res://scenes/ui/pet/emergency_rescue_popup.tscn").instantiate()
    popup.setup(rewards)
    get_tree().root.add_child(popup)

    # Add memorable moment
    var pet = PetDragonManager.instance.pet_dragon
    pet.add_memorable_moment(
        "Emergency Rescue",
        "Sensed you were in trouble and rushed back with supplies!"
    )

    last_emergency_time = Time.get_unix_time_from_system()
    print("[GameStateChecker] Emergency rescue triggered!")
```

**Add to Autoload**: Project Settings → Autoload as `GameStateChecker`

### 5.5 Save/Load Integration
**Modify**: `scripts/managers/save_load_manager.gd`

Add PetDragonManager to save/load sequence:

```gdscript
# In save_game() function, add:
func save_game() -> bool:
    # ... existing save data ...

    # Serialize PetDragonManager
    if PetDragonManager and PetDragonManager.instance:
        save_data["pet_dragon_manager"] = PetDragonManager.instance.to_dict()
        print("[SaveLoadManager] ✓ Saved PetDragonManager")
    else:
        print("[SaveLoadManager] WARNING: PetDragonManager not found, skipping")
        save_data["pet_dragon_manager"] = {}

    # ... rest of save code ...

# In load_game() function, add:
func load_game() -> bool:
    # ... existing load code ...

    # Load PetDragonManager (must load after DragonFactory)
    if save_data.has("pet_dragon_manager") and PetDragonManager and PetDragonManager.instance:
        PetDragonManager.instance.from_dict(save_data["pet_dragon_manager"])
        print("[SaveLoadManager] ✓ Loaded PetDragonManager")
    else:
        print("[SaveLoadManager] WARNING: PetDragonManager data not found, skipping")

    # ... rest of load code ...
```

### 5.6 Main Scene Integration
**Modify**: `scenes/main_scene/main_scene.tscn` and `.gd`

Add UI components to main scene:
1. Instantiate `pet_walking_character.tscn` as child node
2. Add `pet_status_widget.tscn` to UI layer (top-right)

```gdscript
# In main_scene.gd:
@onready var pet_walking = $PetWalkingCharacter
@onready var pet_status_widget = $UI/PetStatusWidget

func _ready():
    # ... existing setup ...

    # Setup pet components
    if PetDragonManager.instance and PetDragonManager.instance.pet_dragon:
        pet_walking.setup(PetDragonManager.instance.pet_dragon)
        pet_status_widget.setup(PetDragonManager.instance.pet_dragon)
    else:
        pet_walking.hide()
        pet_status_widget.hide()
```

---

## PHASE 6: Polish & Testing (2 hours)

### 6.1 Visual Polish

**Animations**:
- Pet bounce animation when petted (AnimationPlayer)
- Heart particle effect when affection increases (CPUParticles2D)
- Sparkle effect when gift received (CPUParticles2D)
- Happy/sad/hungry visual states for walking pet (sprite modulation)
- Level-up celebration animation

**Visual States for Walking Pet**:
```gdscript
# In pet_walking_character.gd:
func update_mood_visual():
    if pet.hunger_level > 0.7:
        # Show hunger icon
        mood_indicator.show_hunger()
    elif pet.fatigue_level > 0.8:
        # Show sleep icon
        mood_indicator.show_tired()
    elif pet.affection >= 80:
        # Show hearts occasionally
        mood_indicator.show_happy()
```

**UI Polish**:
- Smooth transitions for modals (fade in/out)
- Button hover effects
- Affection heart fill animation
- Journal page-turn animation
- Exploration progress bar smooth update

### 6.2 Audio Integration

**Sound Effects** (using AudioManager if available):
- **Pet action**: Happy purr/chirp sound
- **Feed**: Eating/munching sound
- **Gift received**: Pleasant chime
- **Affection tier up**: Achievement/level-up sound
- **Exploration complete**: Return jingle
- **Emergency rescue**: Urgent/helpful music sting

**Implementation**:
```gdscript
# In PetDragon.gd:
func pet() -> bool:
    if can_pet():
        # ... pet logic ...
        if AudioManager.instance:
            AudioManager.instance.play_sfx("pet_happy")
        return true
    return false
```

### 6.3 Balance Testing

**Affection Gain Rates**:
- Feed: +2 affection
- Pet: +5 affection (1-hour cooldown)
- Gift: +5 affection (limited by gifts found)
- Exploration: +1 affection per 15-min expedition
- Target: Reach Soulbound (80) in 30-50 days of active play

**Expected Timeline**:
- Day 1: 0-10 affection (Acquaintance)
- Week 1: 20-30 affection (Friend)
- Week 2: 40-50 affection (Companion)
- Week 3-4: 60-70 affection (Best Friend)
- Month 1-2: 80+ affection (Soulbound)

**Emergency Rescue Balance**:
- Gold: 500 (enough to buy scientist or build dragon)
- Parts: 3 random (enough for 1 dragon)
- Cooldown: 1 hour (prevent exploitation)
- Should feel helpful, not better than active play

**Auto-Exploration Frequency**:
- Check interval: 10 seconds
- Trigger condition: IDLE + hunger < 70%
- Duration: Always 15 minutes (shortest option)
- Expected rate: 4-6 expeditions per hour if not manually managed

**Offline Rewards Balance**:
- Should be fair but not better than active play
- Max offline time: 24 hours (cap to prevent exploit)
- Personality time modifiers apply
- Example: 8 hours AFK = ~32 expeditions (if Energetic) = ~960 gold + ~48 parts

**Testing Checklist**:
- [ ] Pet creation flow works correctly
- [ ] Name can be set and persists
- [ ] Auto-exploration triggers reliably
- [ ] Offline progress calculates correctly
- [ ] Affection gains feel rewarding
- [ ] Pet cannot die (health minimum = 1)
- [ ] Emergency rescue triggers when needed
- [ ] Walking pet stays in bounds
- [ ] Clicking pet opens interaction UI
- [ ] All modals open/close properly
- [ ] Save/load preserves all pet data
- [ ] Personality bonuses apply correctly
- [ ] Journal displays all stats accurately
- [ ] Gifts are awarded and can be opened
- [ ] Memorable moments are recorded

---

## FILE STRUCTURE

```
scripts/
├── dragon_system/
│   └── pet_dragon.gd (NEW - extends Dragon)
├── managers/
│   ├── pet_dragon_manager.gd (NEW - AUTOLOAD singleton)
│   └── game_state_checker.gd (NEW - AUTOLOAD singleton)
├── pet/
│   └── pet_walking_character.gd (NEW)
└── ui/
    └── pet/
        ├── pet_introduction_popup.gd (NEW)
        ├── welcome_back_popup.gd (NEW)
        ├── pet_interaction_ui.gd (NEW)
        ├── pet_journal_ui.gd (NEW)
        ├── pet_status_widget.gd (NEW)
        └── emergency_rescue_popup.gd (NEW)

scenes/
├── pet/
│   └── pet_walking_character.tscn (NEW)
└── ui/
    └── pet/
        ├── pet_introduction_popup.tscn (NEW)
        ├── welcome_back_popup.tscn (NEW)
        ├── pet_interaction_ui.tscn (NEW)
        ├── pet_journal_ui.tscn (NEW)
        ├── pet_status_widget.tscn (NEW)
        └── emergency_rescue_popup.tscn (NEW)
```

---

## IMPLEMENTATION ORDER (Recommended)

1. ✅ **Phase 1: PetDragon class** - Foundation for everything else
2. ✅ **Phase 2: PetDragonManager** - Core logic and auto-exploration
3. ✅ **Phase 4.1: Pet Introduction Popup** - First user touchpoint
4. ✅ **Phase 4.3: Pet Interaction UI** - Main UI for bonding
5. ✅ **Phase 3: Pet Walking Character** - Visual presence on screen
6. ✅ **Phase 4.5: Pet Status Widget** - Always-visible status
7. ✅ **Phase 4.4: Pet Journal UI** - Memory system
8. ✅ **Phase 4.2: Welcome Back Popup** - Offline progress
9. ✅ **Phase 5: Integration hooks** - Connect to existing systems
10. ✅ **Phase 6: Polish & Testing** - Final touches

---

## KEY DESIGN DECISIONS

### Why Pet Cannot Die?
- **Failsafe**: Prevents game-over scenarios
- **Emotional safety**: Players won't lose their companion
- **Always exploring**: Can continuously earn resources
- **Implementation**: Override `take_damage()` to clamp health at minimum 1

### Why Auto-Explore?
- **AFK gameplay**: Works even when player is away
- **Consistent income**: Guarantees resource generation
- **Low maintenance**: Pet takes care of itself
- **Implementation**: Timer checks every 10 seconds, auto-sends if idle

### Why Personality System?
- **Variety**: Each pet feels unique (6 personalities)
- **Replayability**: Different bonuses encourage new games
- **Emergent narrative**: Personality affects dialogue and behavior
- **Implementation**: Enum + switch statements for bonuses

### Why Affection Tiers?
- **Progression**: Long-term goal beyond dragon creation
- **Rewards**: Tangible benefits (up to +25% exploration rewards at Soulbound)
- **Emotional investment**: Players care about relationship growth
- **Implementation**: Integer 0-100, 5 tiers with thresholds

### Why Memorable Moments?
- **Narrative**: Creates emergent story of player + pet journey
- **Nostalgia**: Players can look back on milestones
- **Emotional connection**: Makes pet feel like a real companion
- **Implementation**: Array of dictionaries with title/description/timestamp

---

## TECHNICAL CONSIDERATIONS

### Performance
- Walking pet uses CharacterBody2D physics (efficient)
- Update timers at reasonable intervals (10s for auto-explore, 1s for UI)
- Offline calculation is one-time on load (not continuous)
- Particle effects are lightweight (CPUParticles2D)

### Save/Load
- All pet data serialized in `to_dict()` / `from_dict()`
- Pet dragon saved within DragonFactory (is a Dragon subclass)
- PetDragonManager saves reference to pet + last_pet_time
- Offline progress calculated on load using timestamp delta

### Edge Cases
- **No pet exists**: Hide walking pet and status widget
- **Pet exploring when clicked**: Show exploration status in interaction UI
- **Player deletes pet somehow**: Prevent via code (pet cannot be removed)
- **Multiple game restarts**: Only trigger welcome back if offline > 10 min
- **Emergency rescue spam**: 1-hour cooldown prevents exploitation

### Extensibility
- Easy to add new personalities (just add to enum + bonuses)
- Easy to add new memorable moments (just call `add_memorable_moment()`)
- Easy to add new dialogue (expand dialogue arrays)
- Easy to balance rewards (all constants at top of files)

---

## CONSTANTS & CONFIGURATION

```gdscript
# PetDragon.gd
const AFFECTION_TIERS = {
    "Acquaintance": {"min": 0, "max": 19, "bonus": 1.0},
    "Friend": {"min": 20, "max": 39, "bonus": 1.05},
    "Companion": {"min": 40, "max": 59, "bonus": 1.10},
    "Best Friend": {"min": 60, "max": 79, "bonus": 1.15},
    "Soulbound": {"min": 80, "max": 100, "bonus": 1.25}
}

const PET_COOLDOWN: int = 3600  # 1 hour in seconds
const FEED_AFFECTION: int = 2
const PET_AFFECTION: int = 5
const GIFT_AFFECTION: int = 5
const EXPEDITION_AFFECTION: int = 1

# PetDragonManager.gd
const AUTO_EXPLORE_CHECK_INTERVAL: float = 10.0  # seconds
const AUTO_EXPLORE_HUNGER_THRESHOLD: float = 0.7  # Don't explore if > 70% hungry
const AUTO_EXPLORE_DURATION: int = 15  # Always use 15-min explorations

const EMERGENCY_GOLD: int = 500
const EMERGENCY_PARTS: int = 3
const EMERGENCY_COOLDOWN: int = 3600  # 1 hour

const MAX_OFFLINE_TIME: int = 86400  # 24 hours max

# PetInteractionUI.gd
const FEED_COST: int = 50  # Gold cost to feed pet

# GameStateChecker.gd
const CRISIS_CHECK_INTERVAL: float = 30.0  # seconds
const CRISIS_GOLD_THRESHOLD: int = 100
```

---

## SUCCESS CRITERIA

### Minimum Viable Product
- [ ] Pet dragon is created as first dragon
- [ ] Player can name their pet
- [ ] Pet walks around main screen
- [ ] Clicking pet opens interaction UI
- [ ] Player can feed, pet, and interact
- [ ] Pet auto-explores when idle
- [ ] Affection system works and shows progression
- [ ] Personality affects exploration rewards
- [ ] Pet cannot die (health minimum = 1)
- [ ] Pet appears in dragon factory list
- [ ] Save/load preserves all pet data

### Full Feature Set
- [ ] All 6 personalities implemented with bonuses
- [ ] All 5 affection tiers with reward scaling
- [ ] Offline progress calculates correctly
- [ ] Welcome back popup shows offline rewards
- [ ] Pet journal displays all stats and moments
- [ ] Emergency rescue triggers when needed
- [ ] Pet status widget always visible
- [ ] Memorable moments auto-record
- [ ] Gifts system works (find + give)
- [ ] All animations and visual polish complete
- [ ] Audio integration complete

### Polish & Feel
- [ ] Pet feels alive (wander AI is convincing)
- [ ] Affection progression feels rewarding
- [ ] Personality makes each pet unique
- [ ] Offline rewards feel fair
- [ ] Emergency rescue feels helpful, not exploitable
- [ ] Journal creates nostalgic feeling
- [ ] Player feels emotional connection to pet

---

## NEXT STEPS

Current status: **Planning complete, ready to implement**

Start with **Phase 1** (PetDragon class) as it's the foundation for all other phases.

Would you like me to:
1. Start implementing Phase 1 (PetDragon class)?
2. Set up all the file scaffolding first?
3. Begin with a specific phase you're most excited about?
4. Make any modifications to this plan?
