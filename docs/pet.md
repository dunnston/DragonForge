I'm building a dragon factory idle game in Godot 4. I need you to implement a special "Pet Dragon" system where the player's first dragon becomes their permanent companion that serves as a failsafe and creates emotional attachment.

## GAME CONTEXT

**The Problem:**
- Players can lose all dragons in combat and get stuck
- No emotional connection to dragons (they're just tools)
- Game can reach unwinnable state (no dragons + no gold + no parts)
- Missing the "pet" element in what should be a pet game

**The Solution:**
The first dragon created becomes the player's permanent pet companion. This dragon:
- Cannot die or be assigned to defense
- Only explores (brings back gold and parts)
- Auto-explores continuously (especially important for AFK)
- Has personality, memories, and bonding mechanics
- Serves as guaranteed failsafe against game over

---

## PET DRAGON SPECIFICATIONS

### **What Makes Pet Dragon Special:**

| Feature | Pet Dragon | Regular Dragons |
|---------|-----------|-----------------|
| Can die | ❌ Never | ✅ Yes |
| Can defend | ❌ No (exploring only) | ✅ Yes |
| Can explore | ✅ Yes (primary job) | ✅ Yes |
| Can train | ✅ Yes | ✅ Yes |
| Auto-explores | ✅ Yes (when idle) | ❌ No |
| Has personality | ✅ Unique traits | ❌ Generic |
| Has memories | ✅ Tracks history | ❌ No |
| Player-named | ✅ Required | ❌ Optional |
| Affection system | ✅ Yes | ❌ No |

---

## DATA STRUCTURE

### **PetDragon Class:**

**File: `pet_dragon.gd`**
```gdscript
extends Dragon
class_name PetDragon

enum Personality {
    CURIOUS,      # 10% higher chance for rare finds
    BRAVE,        # Can explore dangerous locations at level 10+
    LAZY,         # +50% exploration time, but 0% failure rate
    ENERGETIC,    # -25% exploration time
    GREEDY,       # +20% gold rewards
    GENTLE        # +15% part recovery rate from explorations
}

# Core pet data
@export var is_pet: bool = true
@export var personality: Personality
@export var player_given_name: String = ""
@export var affection_level: int = 0  # 0-100

# Statistics tracking
@export var times_fed: int = 0
@export var times_petted: int = 0
@export var times_gifted: int = 0
@export var expeditions_completed: int = 0
@export var days_together: int = 0
@export var total_gold_earned: int = 0
@export var total_parts_found: int = 0
@export var creation_timestamp: int = 0  # Unix timestamp

# Memories
@export var favorite_destination: String = ""
@export var destination_visit_counts: Dictionary = {}  # destination -> count
@export var memorable_moments: Array[Dictionary] = []
@export var last_pet_time: int = 0  # Unix timestamp

# Gifts
@export var pending_gifts: Array[Dictionary] = []

const AFFECTION_THRESHOLDS = {
    "acquaintance": 0,
    "friend": 21,
    "close_friend": 41,
    "best_friend": 61,
    "soulbound": 81
}

func _init():
    super._init()
    is_pet = true
    creation_timestamp = Time.get_unix_time_from_system()

func get_affection_tier() -> String:
    if affection_level >= 81:
        return "soulbound"
    elif affection_level >= 61:
        return "best_friend"
    elif affection_level >= 41:
        return "close_friend"
    elif affection_level >= 21:
        return "friend"
    else:
        return "acquaintance"

func get_affection_bonus() -> float:
    match get_affection_tier():
        "friend":
            return 1.05  # 5% bonus
        "close_friend":
            return 1.10  # 10% bonus
        "best_friend":
            return 1.15  # 15% bonus
        "soulbound":
            return 1.25  # 25% bonus
        _:
            return 1.0

func get_personality_bonus(reward_type: String) -> float:
    match personality:
        Personality.CURIOUS:
            if reward_type == "rare_find":
                return 1.10
        Personality.BRAVE:
            if reward_type == "dangerous_location" and level >= 10:
                return 1.20
        Personality.ENERGETIC:
            if reward_type == "time":
                return 0.75  # 25% faster
        Personality.GREEDY:
            if reward_type == "gold":
                return 1.20
        Personality.GENTLE:
            if reward_type == "parts":
                return 1.15
    return 1.0

func add_affection(amount: int):
    affection_level = clamp(affection_level + amount, 0, 100)

func can_be_petted() -> bool:
    var current_time = Time.get_unix_time_from_system()
    var time_since_last_pet = current_time - last_pet_time
    return time_since_last_pet >= 3600  # 1 hour cooldown

func pet():
    if can_be_petted():
        times_petted += 1
        add_affection(1)
        last_pet_time = Time.get_unix_time_from_system()
        return true
    return false

func feed():
    times_fed += 1
    add_affection(2)
    hunger = 100.0

func give_gift():
    times_gifted += 1
    add_affection(5)

func complete_expedition(destination: String, gold_earned: int, parts_found: int):
    expeditions_completed += 1
    total_gold_earned += gold_earned
    total_parts_found += parts_found
    
    add_affection(5)  # Affection for completing expedition
    
    # Track favorite destination
    if not destination_visit_counts.has(destination):
        destination_visit_counts[destination] = 0
    destination_visit_counts[destination] += 1
    
    # Update favorite
    var max_visits = 0
    for dest in destination_visit_counts:
        if destination_visit_counts[dest] > max_visits:
            max_visits = destination_visit_counts[dest]
            favorite_destination = dest
    
    # Chance to generate gift based on affection
    if _should_generate_gift():
        _generate_gift(destination)

func _should_generate_gift() -> bool:
    var chance = 0.0
    match get_affection_tier():
        "friend":
            chance = 0.05
        "close_friend":
            chance = 0.10
        "best_friend":
            chance = 0.20
        "soulbound":
            chance = 0.35
    
    return randf() < chance

func _generate_gift(from_destination: String):
    var gift = {
        "type": "",
        "destination": from_destination,
        "timestamp": Time.get_unix_time_from_system()
    }
    
    # Determine gift type based on affection
    var roll = randf()
    match get_affection_tier():
        "friend":
            gift.type = "decoration_common"
        "close_friend":
            if roll < 0.7:
                gift.type = "decoration_rare"
            else:
                gift.type = "part_rare"
        "best_friend":
            if roll < 0.5:
                gift.type = "decoration_epic"
            else:
                gift.type = "part_epic"
        "soulbound":
            if roll < 0.3:
                gift.type = "decoration_legendary"
            else:
                gift.type = "part_legendary"
    
    pending_gifts.append(gift)

func add_memorable_moment(title: String, description: String):
    memorable_moments.append({
        "day": days_together,
        "title": title,
        "description": description,
        "timestamp": Time.get_unix_time_from_system()
    })
    
    # Keep only last 20 moments
    if memorable_moments.size() > 20:
        memorable_moments.pop_front()

func update_days_together():
    var current_time = Time.get_unix_time_from_system()
    var seconds_together = current_time - creation_timestamp
    days_together = int(seconds_together / 86400)  # Convert to days

func get_personality_dialogue() -> Array[String]:
    match personality:
        Personality.CURIOUS:
            return [
                "I wonder what's over there...",
                "Did you know the Ancient Forest has 47 different types of flowers?",
                "I found something weird! Let me show you!"
            ]
        Personality.BRAVE:
            return [
                "Don't worry, I've got this!",
                "The Shadow Realm doesn't scare me!",
                "I'll keep exploring no matter what!"
            ]
        Personality.LAZY:
            return [
                "Do I have to go exploring again...?",
                "Can't we just nap today?",
                "I found something cool... but it took forever."
            ]
        Personality.ENERGETIC:
            return [
                "Let's go! Let's go! Let's GO!",
                "I'm already back! Send me again!",
                "I LOVE exploring!"
            ]
        Personality.GREEDY:
            return [
                "Look at all this gold I found!",
                "Ooh, shiny things!",
                "We're going to be SO rich!"
            ]
        Personality.GENTLE:
            return [
                "I found these parts very carefully.",
                "I hope this helps with your experiments.",
                "I worry when you send the other dragons to fight..."
            ]
    return []

func get_random_dialogue() -> String:
    var dialogues = get_personality_dialogue()
    if dialogues.is_empty():
        return "..."
    return dialogues[randi() % dialogues.size()]

func to_save_dict() -> Dictionary:
    var data = super.to_save_dict()
    data.merge({
        "is_pet": is_pet,
        "personality": personality,
        "player_given_name": player_given_name,
        "affection_level": affection_level,
        "times_fed": times_fed,
        "times_petted": times_petted,
        "times_gifted": times_gifted,
        "expeditions_completed": expeditions_completed,
        "days_together": days_together,
        "total_gold_earned": total_gold_earned,
        "total_parts_found": total_parts_found,
        "creation_timestamp": creation_timestamp,
        "favorite_destination": favorite_destination,
        "destination_visit_counts": destination_visit_counts,
        "memorable_moments": memorable_moments,
        "last_pet_time": last_pet_time,
        "pending_gifts": pending_gifts
    })
    return data

func load_from_dict(data: Dictionary):
    super.load_from_dict(data)
    is_pet = data.get("is_pet", true)
    personality = data.get("personality", Personality.CURIOUS)
    player_given_name = data.get("player_given_name", "")
    affection_level = data.get("affection_level", 0)
    times_fed = data.get("times_fed", 0)
    times_petted = data.get("times_petted", 0)
    times_gifted = data.get("times_gifted", 0)
    expeditions_completed = data.get("expeditions_completed", 0)
    days_together = data.get("days_together", 0)
    total_gold_earned = data.get("total_gold_earned", 0)
    total_parts_found = data.get("total_parts_found", 0)
    creation_timestamp = data.get("creation_timestamp", 0)
    favorite_destination = data.get("favorite_destination", "")
    destination_visit_counts = data.get("destination_visit_counts", {})
    memorable_moments = data.get("memorable_moments", [])
    last_pet_time = data.get("last_pet_time", 0)
    pending_gifts = data.get("pending_gifts", [])
```

---

### **Pet Dragon Manager Singleton:**

**File: `pet_dragon_manager.gd`**
```gdscript
extends Node
class_name PetDragonManager

signal pet_created(pet: PetDragon)
signal pet_expedition_completed(pet: PetDragon, rewards: Dictionary)
signal affection_increased(pet: PetDragon, new_level: int)
signal affection_tier_changed(pet: PetDragon, new_tier: String)
signal gift_received(pet: PetDragon, gift: Dictionary)
signal memorable_moment_added(pet: PetDragon, moment: Dictionary)

var pet_dragon: PetDragon = null
var auto_explore_enabled: bool = true
var auto_explore_timer: Timer

func _ready():
    # Setup auto-explore timer
    auto_explore_timer = Timer.new()
    auto_explore_timer.timeout.connect(_check_auto_explore)
    auto_explore_timer.wait_time = 10.0  # Check every 10 seconds
    auto_explore_timer.autostart = true
    add_child(auto_explore_timer)

func create_pet_dragon(head: DragonPart, body: DragonPart, tail: DragonPart) -> PetDragon:
    """
    Creates the player's first dragon as a pet
    This should be called when the first dragon is created
    """
    pet_dragon = PetDragon.new()
    
    # Set parts
    pet_dragon.head_part = head
    pet_dragon.body_part = body
    pet_dragon.tail_part = tail
    
    # Assign random personality
    pet_dragon.personality = randi() % PetDragon.Personality.size()
    
    # Initialize stats
    pet_dragon.level = 1
    pet_dragon.hp = 100
    pet_dragon.max_hp = 100
    pet_dragon.hunger = 100
    pet_dragon.fatigue = 0
    
    # Add first memorable moment
    pet_dragon.add_memorable_moment(
        "First Meeting",
        "The day we first met. I knew this was the beginning of something special."
    )
    
    pet_created.emit(pet_dragon)
    
    return pet_dragon

func set_pet_name(name: String):
    if pet_dragon:
        pet_dragon.player_given_name = name
        pet_dragon.dragon_name = name

func is_pet_exploring() -> bool:
    if not pet_dragon:
        return false
    return ExplorationManager.is_dragon_exploring(pet_dragon)

func can_auto_explore() -> bool:
    if not pet_dragon:
        return false
    if not auto_explore_enabled:
        return false
    if is_pet_exploring():
        return false
    if pet_dragon.hunger < 30:
        return false  # Too hungry to explore
    return true

func _check_auto_explore():
    """Called every 10 seconds to auto-send pet exploring"""
    if can_auto_explore():
        start_auto_exploration()

func start_auto_exploration():
    """Automatically sends pet on exploration"""
    if not can_auto_explore():
        return
    
    # Choose destination
    var destination = _choose_exploration_destination()
    
    # Start exploration
    ExplorationManager.start_exploration(pet_dragon, destination)

func _choose_exploration_destination() -> String:
    # Prefer favorite destination if set
    if pet_dragon.favorite_destination != "":
        return pet_dragon.favorite_destination
    
    # Otherwise choose based on personality
    match pet_dragon.personality:
        PetDragon.Personality.CURIOUS:
            return _random_destination()
        PetDragon.Personality.BRAVE:
            if pet_dragon.level >= 10:
                return "shadow_realm"  # Most dangerous
            else:
                return "volcanic_caves"
        PetDragon.Personality.LAZY:
            return "volcanic_caves"  # Shortest expedition
        PetDragon.Personality.ENERGETIC:
            return "volcanic_caves"  # Quick turnaround
        PetDragon.Personality.GREEDY:
            return "ancient_forest"  # Good gold
        PetDragon.Personality.GENTLE:
            return "frozen_tundra"  # Safe, good parts
    
    return "volcanic_caves"  # Default shortest

func _random_destination() -> String:
    var destinations = ["ancient_forest", "frozen_tundra", "thunder_peak", "volcanic_caves", "shadow_realm"]
    return destinations[randi() % destinations.size()]

func on_pet_expedition_complete(destination: String, rewards: Dictionary):
    """Called by exploration system when pet returns"""
    if not pet_dragon:
        return
    
    # Apply personality bonuses
    if pet_dragon.personality == PetDragon.Personality.GREEDY:
        rewards.gold = int(rewards.gold * 1.20)
    elif pet_dragon.personality == PetDragon.Personality.GENTLE:
        # Increase part quality/quantity
        pass
    
    # Apply affection bonuses
    var affection_mult = pet_dragon.get_affection_bonus()
    rewards.gold = int(rewards.gold * affection_mult)
    
    # Track in pet stats
    pet_dragon.complete_expedition(destination, rewards.gold, rewards.parts.size())
    
    # Check for gifts
    if pet_dragon.pending_gifts.size() > 0:
        var gift = pet_dragon.pending_gifts.pop_front()
        gift_received.emit(pet_dragon, gift)
    
    pet_expedition_completed.emit(pet_dragon, rewards)
    
    # Check for milestone moments
    _check_milestones()

func _check_milestones():
    # Check for memorable milestones
    if pet_dragon.expeditions_completed == 1:
        pet_dragon.add_memorable_moment(
            "First Expedition",
            "The first time %s went exploring. They were so excited!" % pet_dragon.player_given_name
        )
    elif pet_dragon.expeditions_completed == 10:
        pet_dragon.add_memorable_moment(
            "Experienced Explorer",
            "%s has completed 10 expeditions! They're getting really good at this." % pet_dragon.player_given_name
        )
    elif pet_dragon.expeditions_completed == 50:
        pet_dragon.add_memorable_moment(
            "Veteran Adventurer",
            "50 expeditions! %s is a true explorer now." % pet_dragon.player_given_name
        )
    elif pet_dragon.expeditions_completed == 100:
        pet_dragon.add_memorable_moment(
            "Century Club",
            "100 expeditions! %s and I have seen so much together." % pet_dragon.player_given_name
        )
    
    # Check affection milestones
    var tier = pet_dragon.get_affection_tier()
    if tier == "friend" and pet_dragon.affection_level == 21:
        pet_dragon.add_memorable_moment("Friends", "We've become friends!")
    elif tier == "close_friend" and pet_dragon.affection_level == 41:
        pet_dragon.add_memorable_moment("Close Friends", "We're really close now.")
    elif tier == "best_friend" and pet_dragon.affection_level == 61:
        pet_dragon.add_memorable_moment("Best Friends", "Best friends forever!")
    elif tier == "soulbound" and pet_dragon.affection_level == 81:
        pet_dragon.add_memorable_moment("Soulbound", "Our bond is unbreakable.")

func pet_dragon_interaction():
    """Player pets the dragon"""
    if pet_dragon and pet_dragon.pet():
        return true
    return false

func feed_pet_dragon():
    """Player feeds the pet dragon"""
    if pet_dragon:
        pet_dragon.feed()

func give_gift_to_pet():
    """Player gives gift to pet"""
    if pet_dragon:
        pet_dragon.give_gift()

func calculate_offline_progress(seconds_offline: int) -> Dictionary:
    """
    Calculate what pet dragon did while player was offline
    Returns rewards and events that happened
    """
    if not pet_dragon:
        return {}
    
    var results = {
        "expeditions": [],
        "levels_gained": 0,
        "total_gold": 0,
        "total_parts": [],
        "gifts": []
    }
    
    # Calculate how many expeditions completed
    var expedition_duration = 900  # 15 minutes base
    
    # Apply personality time modifier
    if pet_dragon.personality == PetDragon.Personality.ENERGETIC:
        expedition_duration = int(expedition_duration * 0.75)
    elif pet_dragon.personality == PetDragon.Personality.LAZY:
        expedition_duration = int(expedition_duration * 1.50)
    
    var time_remaining = seconds_offline
    
    while time_remaining >= expedition_duration:
        # Generate expedition
        var destination = _choose_exploration_destination()
        var rewards = _generate_offline_expedition_rewards(destination)
        
        results.expeditions.append({
            "destination": destination,
            "gold": rewards.gold,
            "parts": rewards.parts
        })
        
        results.total_gold += rewards.gold
        results.total_parts.append_array(rewards.parts)
        
        # Track in pet
        pet_dragon.complete_expedition(destination, rewards.gold, rewards.parts.size())
        
        # Check for level up
        pet_dragon.xp += 100  # Adjust to your XP system
        if pet_dragon.should_level_up():  # Implement in Dragon class
            pet_dragon.level_up()
            results.levels_gained += 1
        
        # Check for gifts
        if pet_dragon.pending_gifts.size() > 0:
            results.gifts.append(pet_dragon.pending_gifts.pop_front())
        
        time_remaining -= expedition_duration
    
    return results

func _generate_offline_expedition_rewards(destination: String) -> Dictionary:
    # Generate rewards for offline expedition
    # Similar to normal exploration but guaranteed success
    var base_gold = 100
    var rewards = {
        "gold": base_gold,
        "parts": []
    }
    
    # Apply personality bonuses
    if pet_dragon.personality == PetDragon.Personality.GREEDY:
        rewards.gold = int(rewards.gold * 1.20)
    
    # Apply affection bonuses
    rewards.gold = int(rewards.gold * pet_dragon.get_affection_bonus())
    
    # Chance for parts
    if randf() < 0.3:  # 30% chance per expedition
        # Generate random part
        var part = DragonPart.new()
        # Set part properties based on destination
        rewards.parts.append(part)
    
    return rewards

func generate_emergency_rewards() -> Dictionary:
    """
    Called when player is completely stuck (no gold, no parts, no dragons)
    Pet dragon returns with guaranteed minimum resources
    """
    return {
        "gold": max(500, pet_dragon.level * 50),
        "parts": [
            _generate_random_part(),
            _generate_random_part(),
            _generate_random_part()
        ],
        "message": "I won't let our laboratory fail!"
    }

func _generate_random_part() -> DragonPart:
    # Generate a random dragon part
    var part = DragonPart.new()
    # Randomize properties
    part.part_type = randi() % DragonPart.PartType.size()
    part.element = randi() % DragonPart.Element.size()
    return part

func to_save_dict() -> Dictionary:
    if not pet_dragon:
        return {"has_pet": false}
    
    return {
        "has_pet": true,
        "pet_data": pet_dragon.to_save_dict(),
        "auto_explore_enabled": auto_explore_enabled
    }

func load_from_dict(data: Dictionary):
    if not data.get("has_pet", false):
        return
    
    pet_dragon = PetDragon.new()
    pet_dragon.load_from_dict(data.pet_data)
    auto_explore_enabled = data.get("auto_explore_enabled", true)
```

---

## UI COMPONENTS

### **1. PET INTRODUCTION POPUP**

**File: `pet_introduction_popup.tscn` + `pet_introduction_popup.gd`**

**Visual Layout:**
```
╔════════════════════════════════════════════════════════════╗
║           ✨ CONGRATULATIONS! YOUR FIRST DRAGON ✨         ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║              [Dragon Portrait - Animated]                  ║
║                                                            ║
║         This is no ordinary dragon. This is YOUR           ║
║              companion - your partner in this              ║
║                  mad scientific endeavor.                  ║
║                                                            ║
║  Unlike the other dragons you'll create, this one can      ║
║  never die. They'll be by your side through thick and      ║
║  thin, exploring the world and bringing back treasures.    ║
║                                                            ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                            ║
║               What will you name them?                     ║
║                                                            ║
║               [Text Input Field]                           ║
║                                                            ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                            ║
║  Your companion will:                                      ║
║  ✓ Explore the world and bring back gold & parts          ║
║  ✓ Never be in danger - they always return safely         ║
║  ✓ Remember your adventures together                      ║
║  ✓ Keep you company even when everything else fails       ║
║                                                            ║
║  [MEET YOUR COMPANION]                                     ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

**Scene Structure:**
```
PetIntroductionPopup (Control - CanvasLayer)
├── DimBackground (ColorRect - semi-transparent black)
└── CenterContainer
    └── PanelContainer
        └── MarginContainer
            └── VBoxContainer
                ├── TitleLabel ("✨ CONGRATULATIONS! YOUR FIRST DRAGON ✨")
                ├── DragonPortrait (TextureRect)
                ├── IntroTextLabel (RichTextLabel)
                ├── Separator1
                ├── NamePromptLabel ("What will you name them?")
                ├── NameInput (LineEdit)
                ├── Separator2
                ├── BenefitsLabel ("Your companion will:")
                ├── BenefitsList (VBoxContainer)
                │   ├── Benefit1 ("✓ Explore the world...")
                │   ├── Benefit2 ("✓ Never be in danger...")
                │   ├── Benefit3 ("✓ Remember your adventures...")
                │   └── Benefit4 ("✓ Keep you company...")
                └── ConfirmButton ("MEET YOUR COMPANION")
```

**Script:**
```gdscript
extends Control
class_name PetIntroductionPopup

@onready var dragon_portrait = $Center/Panel/Margin/VBox/Portrait
@onready var name_input = $Center/Panel/Margin/VBox/NameInput
@onready var confirm_button = $Center/Panel/Margin/VBox/ConfirmButton

var pet_dragon: PetDragon
var pet_manager: PetDragonManager

func _ready():
    pet_manager = get_node("/root/PetDragonManager")
    name_input.grab_focus()
    
    # Setup portrait
    if pet_dragon:
        dragon_portrait.texture = pet_dragon.get_portrait()  # Implement portrait system
        
        # Show personality hint
        var personality_hint = _get_personality_hint()
        $Center/Panel/Margin/VBox/IntroText.text += "\n\n" + personality_hint

func setup(pet: PetDragon):
    pet_dragon = pet

func _get_personality_hint() -> String:
    match pet_dragon.personality:
        PetDragon.Personality.CURIOUS:
            return "This dragon has a curious gleam in their eyes..."
        PetDragon.Personality.BRAVE:
            return "This dragon stands proud and fearless..."
        PetDragon.Personality.LAZY:
            return "This dragon yawns contentedly..."
        PetDragon.Personality.ENERGETIC:
            return "This dragon bounces with excitement..."
        PetDragon.Personality.GREEDY:
            return "This dragon's eyes sparkle at the thought of treasure..."
        PetDragon.Personality.GENTLE:
            return "This dragon has a gentle, caring demeanor..."
    return ""

func _on_confirm_button_pressed():
    var pet_name = name_input.text.strip_edges()
    
    if pet_name.is_empty():
        # Show error
        _show_error("Please enter a name for your companion!")
        return
    
    if pet_name.length() > 20:
        _show_error("Name is too long! (Max 20 characters)")
        return
    
    # Set pet name
    pet_manager.set_pet_name(pet_name)
    
    # Show welcome message
    _show_welcome_message()

func _show_error(message: String):
    # Show temporary error message
    pass

func _show_welcome_message():
    # Close this popup and show welcome
    var welcome = preload("res://scenes/ui/pet_welcome_popup.tscn").instantiate()
    get_tree().root.add_child(welcome)
    queue_free()

func _on_name_input_text_submitted(new_text: String):
    _on_confirm_button_pressed()
```

---

### **2. WELCOME BACK POPUP (After AFK)**

**File: `welcome_back_popup.tscn` + `welcome_back_popup.gd`**

**Visual Layout:**
```
╔════════════════════════════════════════════════════════════╗
║              🌟 WELCOME BACK! 🌟                           ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  You were away for: 8 hours, 23 minutes                   ║
║                                                            ║
║         [Sparkles bouncing happily animation]              ║
║                                                            ║
║  Sparkles missed you! While you were gone:                 ║
║                                                            ║
║  🗺️ Completed 4 expeditions:                              ║
║     • Ancient Forest → Found Fire Head (Uncommon)         ║
║     • Volcanic Caves → 450g                                ║
║     • Thunder Peak → Found Lightning Tail (Rare!)         ║
║     • Shadow Realm → 680g                                  ║
║                                                            ║
║  💰 Total Gold: 1,130g                                     ║
║  🔧 Total Parts: 2                                         ║
║                                                            ║
║  💝 Sparkles left you a gift:                              ║
║     [Mystery Box] - Special find from Ancient Forest      ║
║                                                            ║
║  ✨ Sparkles gained 2 levels! (Now Level 8)                ║
║                                                            ║
║  💭 "I kept things running while you were gone! I hope    ║
║      you like what I found!" - Sparkles                   ║
║                                                            ║
║  [COLLECT REWARDS] [PET SPARKLES]                         ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

**Scene Structure:**
```
WelcomeBackPopup (Control - CanvasLayer)
├── DimBackground (ColorRect)
└── CenterContainer
    └── PanelContainer
        └── MarginContainer
            └── VBoxContainer
                ├── TitleLabel ("🌟 WELCOME BACK! 🌟")
                ├── TimeAwayLabel
                ├── DragonAnimatedSprite
                ├── MissedYouLabel
                ├── ExpeditionsList (VBoxContainer)
                ├── TotalsContainer (HBoxContainer)
                │   ├── GoldTotal
                │   └── PartsTotal
                ├── GiftSection (visible if has gift)
                ├── LevelUpSection (visible if leveled up)
                ├── DialogueLabel
                └── ButtonsContainer (HBoxContainer)
                    ├── CollectButton
                    └── PetButton
```

**Script:**
```gdscript
extends Control
class_name WelcomeBackPopup

@onready var time_away_label = $Center/Panel/Margin/VBox/TimeAway
@onready var expeditions_list = $Center/Panel/Margin/VBox/ExpeditionsList
@onready var gold_total = $Center/Panel/Margin/VBox/Totals/GoldTotal
@onready var parts_total = $Center/Panel/Margin/VBox/Totals/PartsTotal
@onready var gift_section = $Center/Panel/Margin/VBox/GiftSection
@onready var levelup_section = $Center/Panel/Margin/VBox/LevelUpSection
@onready var dialogue_label = $Center/Panel/Margin/VBox/Dialogue
@onready var dragon_sprite = $Center/Panel/Margin/VBox/DragonSprite

var offline_results: Dictionary
var pet_manager: PetDragonManager

func _ready():
    pet_manager = get_node("/root/PetDragonManager")

func setup(results: Dictionary, seconds_offline: int):
    offline_results = results
    
    # Display time away
    var hours = seconds_offline / 3600
    var minutes = (seconds_offline % 3600) / 60
    time_away_label.text = "You were away for: %d hours, %d minutes" % [hours, minutes]
    
    # Display expeditions
    _display_expeditions()
    
    # Display totals
    gold_total.text = "💰 Total Gold: %dg" % results.total_gold
    parts_total.text = "🔧 Total Parts: %d" % results.total_parts.size()
    
    # Display gift if any
    if results.gifts.size() > 0:
        gift_section.visible = true
        _display_gift(results.gifts[0])
    else:
        gift_section.visible = false
    
    # Display level ups
    if results.levels_gained > 0:
        levelup_section.visible = true
        levelup_section.get_node("Label").text = "✨ %s gained %d level%s! (Now Level %d)" % [
            pet_manager.pet_dragon.player_given_name,
            results.levels_gained,
            "s" if results.levels_gained > 1 else "",
            pet_manager.pet_dragon.level
        ]
    else:
        levelup_section.visible = false
    
    # Display dialogue
    dialogue_label.text = '💭 "%s" - %s' % [
        pet_manager.pet_dragon.get_random_dialogue(),
        pet_manager.pet_dragon.player_given_name
    ]
    
    # Animate dragon
    _animate_dragon()

func _display_expeditions():
    # Clear existing
    for child in expeditions_list.get_children():
        child.queue_free()
    
    var header = Label.new()
    header.text = "🗺️ Completed %d expedition%s:" % [
        offline_results.expeditions.size(),
        "s" if offline_results.expeditions.size() != 1 else ""
    ]
    expeditions_list.add_child(header)
    
    # Show each expedition
    for expedition in offline_results.expeditions:
        var exp_label = Label.new()
        
        var text = "  • %s → " % expedition.destination.capitalize()
        
        if expedition.parts.size() > 0:
            for part in expedition.parts:
                text += "Found %s (Rarity) " % _part_description(part)
        
        text += "%dg" % expedition.gold
        
        exp_label.text = text
        expeditions_list.add_child(exp_label)

func _display_gift(gift: Dictionary):
    gift_section.get_node("Label").text = "💝 %s left you a gift:\n   [%s] - Special find from %s" % [
        pet_manager.pet_dragon.player_given_name,
        _gift_type_name(gift.type),
        gift.destination.capitalize()
    ]

func _gift_type_name(type: String) -> String:
    match type:
        "decoration_common":
            return "Common Decoration"
        "decoration_rare":
            return "Rare Decoration"
        "decoration_epic":
            return "Epic Decoration"
        "decoration_legendary":
            return "Legendary Decoration"
        "part_rare":
            return "Rare Dragon Part"
        "part_epic":
            return "Epic Dragon Part"
        "part_legendary":
            return "Legendary Dragon Part"
    return "Mystery Gift"

func _part_description(part: DragonPart) -> String:
    var element_name = ["Fire", "Ice", "Lightning", "Nature", "Shadow"][part.element]
    var part_name = ["Head", "Body", "Tail"][part.part_type]
    return "%s %s" % [element_name, part_name]

func _animate_dragon():
    # Play happy bounce animation
    var tween = create_tween()
    tween.set_loops()
    tween.tween_property(dragon_sprite, "position:y", dragon_sprite.position.y - 10, 0.5)
    tween.tween_property(dragon_sprite, "position:y", dragon_sprite.position.y, 0.5)

func _on_collect_button_pressed():
    # Give player the rewards
    GameState.gold += offline_results.total_gold
    
    for part in offline_results.total_parts:
        PartInventory.add_part(part)
    
    for gift in offline_results.gifts:
        _collect_gift(gift)
    
    queue_free()

func _on_pet_button_pressed():
    # Collect rewards first
    _on_collect_button_pressed()
    
    # Open pet interaction screen
    var interaction = preload("res://scenes/ui/pet_interaction_ui.tscn").instantiate()
    get_tree().root.add_child(interaction)

func _collect_gift(gift: Dictionary):
    # Add gift to inventory
    # Implement based on gift type
    pass
```

---

### **3. PET INTERACTION SCREEN**

**File: `pet_interaction_ui.tscn` + `pet_interaction_ui.gd`**

**Visual Layout:**
```
╔════════════════════════════════════════════════════════════╗
║                    INTERACT WITH SPARKLES                  ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║            [Animated Pet Dragon - Happy Idle]              ║
║                                                            ║
║  Sparkles looks happy to see you!                          ║
║  Affection: ❤️❤️❤️❤️🤍 (Best Friend - 80/100)             ║
║  Personality: Curious Explorer                             ║
║                                                            ║
║  [🖐️ PET] [🍖 FEED] [🎁 GIFT] [💬 TALK] [📖 JOURNAL]     ║
║                                                            ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                            ║
║  Status: Resting (well fed, healthy)                       ║
║  Mood: 😊 Content                                          ║
║  Level: 8 | XP: 450/1000                                   ║
║                                                            ║
║  Next Expedition: Ready when you are!                      ║
║  [SEND EXPLORING]                                          ║
║                                                            ║
║  [Close]                                                   ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

**Scene Structure:**
```
PetInteractionUI (Control)
├── BackButton
└── MarginContainer
    └── VBoxContainer
        ├── TitleLabel
        ├── DragonDisplayContainer
        │   └── AnimatedSprite2D (pet dragon)
        ├── StatusContainer (VBoxContainer)
        │   ├── GreetingLabel
        │   ├── AffectionDisplay
        │   └── PersonalityLabel
        ├── ActionButtons (HBoxContainer)
        │   ├── PetButton
        │   ├── FeedButton
        │   ├── GiftButton
        │   ├── TalkButton
        │   └── JournalButton
        ├── Separator
        ├── InfoContainer (VBoxContainer)
        │   ├── StatusLabel
        │   ├── MoodLabel
        │   └── LevelLabel
        ├── ExplorationContainer
        │   ├── ExplorationStatus
        │   └── SendExploringButton
        └── CloseButton
```

**Script:**
```gdscript
extends Control
class_name PetInteractionUI

@onready var dragon_sprite = $Margin/VBox/DragonDisplay/AnimatedSprite
@onready var greeting_label = $Margin/VBox/Status/Greeting
@onready var affection_display = $Margin/VBox/Status/Affection
@onready var personality_label = $Margin/VBox/Status/Personality
@onready var status_label = $Margin/VBox/Info/Status
@onready var mood_label = $Margin/VBox/Info/Mood
@onready var level_label = $Margin/VBox/Info/Level
@onready var exploration_status = $Margin/VBox/Exploration/Status
@onready var send_exploring_button = $Margin/VBox/Exploration/SendButton

@onready var pet_button = $Margin/VBox/Actions/PetButton
@onready var feed_button = $Margin/VBox/Actions/FeedButton
@onready var gift_button = $Margin/VBox/Actions/GiftButton
@onready var talk_button = $Margin/VBox/Actions/TalkButton
@onready var journal_button = $Margin/VBox/Actions/JournalButton

var pet_manager: PetDragonManager
var pet_dragon: PetDragon

func _ready():
    pet_manager = get_node("/root/PetDragonManager")
    pet_dragon = pet_manager.pet_dragon
    
    _update_display()
    
    # Connect signals
    pet_manager.affection_increased.connect(_on_affection_changed)

func _process(_delta):
    _update_exploration_status()

func _update_display():
    if not pet_dragon:
        return
    
    # Greeting
    greeting_label.text = "%s looks happy to see you!" % pet_dragon.player_given_name
    
    # Affection
    var hearts = ""
    var full_hearts = int(pet_dragon.affection_level / 20)
    var empty_hearts = 5 - full_hearts
    
    for i in range(full_hearts):
        hearts += "❤️"
    for i in range(empty_hearts):
        hearts += "🤍"
    
    affection_display.text = "Affection: %s (%s - %d/100)" % [
        hearts,
        pet_dragon.get_affection_tier().capitalize().replace("_", " "),
        pet_dragon.affection_level
    ]
    
    # Personality
    var personality_names = {
        PetDragon.Personality.CURIOUS: "Curious Explorer",
        PetDragon.Personality.BRAVE: "Brave Adventurer",
        PetDragon.Personality.LAZY: "Relaxed Wanderer",
        PetDragon.Personality.ENERGETIC: "Energetic Sprinter",
        PetDragon.Personality.GREEDY: "Treasure Hunter",
        PetDragon.Personality.GENTLE: "Gentle Soul"
    }
    personality_label.text = "Personality: %s" % personality_names[pet_dragon.personality]
    
    # Status
    var health_status = "healthy" if pet_dragon.hp > pet_dragon.max_hp * 0.8 else "injured"
    var hunger_status = "well fed" if pet_dragon.hunger > 60 else "hungry"
    status_label.text = "Status: Resting (%s, %s)" % [hunger_status, health_status]
    
    # Mood
    var mood = "😊 Content"
    if pet_dragon.affection_level >= 81:
        mood = "🥰 Adoring"
    elif pet_dragon.affection_level >= 61:
        mood = "😄 Happy"
    elif pet_dragon.affection_level >= 41:
        mood = "🙂 Friendly"
    elif pet_dragon.hunger < 30:
        mood = "😟 Hungry"
    mood_label.text = "Mood: %s" % mood
    
    # Level
    level_label.text = "Level: %d | XP: %d/%d" % [
        pet_dragon.level,
        pet_dragon.xp,
        pet_dragon.xp_to_next_level()
    ]
    
    # Button states
    pet_button.disabled = not pet_dragon.can_be_petted()
    if pet_button.disabled:
        var time_until = 3600 - (Time.get_unix_time_from_system() - pet_dragon.last_pet_time)
        var minutes = time_until / 60
        pet_button.text = "🖐️ PET (Ready in %dm)" % minutes
    else:
        pet_button.text = "🖐️ PET"

func _update_exploration_status():
    if pet_manager.is_pet_exploring():
        exploration_status.text = "Currently exploring..."
        send_exploring_button.visible = false
        # TODO: Show time remaining
    else:
        exploration_status.text = "Next Expedition: Ready when you are!"
        send_exploring_button.visible = true

func _on_pet_button_pressed():
    if pet_dragon.pet():
        _show_interaction_result("You pet %s. They purr happily! (+1 affection)" % pet_dragon.player_given_name)
        _update_display()
        _play_happy_animation()

func _on_feed_button_pressed():
    # Check if player has food/gold
    if GameState.gold < 50:
        _show_error("Not enough gold to buy food! (Need 50g)")
        return
    
    GameState.gold -= 50
    pet_dragon.feed()
    _show_interaction_result("%s eats happily! (+2 affection)" % pet_dragon.player_given_name)
    _update_display()
    _play_eating_animation()

func _on_gift_button_pressed():
    # Open gift selection screen
    var gift_selector = preload("res://scenes/ui/gift_selector_popup.tscn").instantiate()
    add_child(gift_selector)

func _on_talk_button_pressed():
    # Show dialogue from pet
    var dialogue = pet_dragon.get_random_dialogue()
    _show_dialogue_popup(dialogue)

func _on_journal_button_pressed():
    # Open journal screen
    var journal = preload("res://scenes/ui/pet_journal_ui.tscn").instantiate()
    journal.setup(pet_dragon)
    get_tree().root.add_child(journal)

func _on_send_exploring_button_pressed():
    # Let player choose destination or use auto
    pet_manager.start_auto_exploration()
    _update_exploration_status()

func _show_interaction_result(message: String):
    # Show temporary message
    var label = Label.new()
    label.text = message
    label.add_theme_color_override("font_color", Color.GREEN)
    $Margin/VBox/Status.add_child(label)
    
    await get_tree().create_timer(3.0).timeout
    label.queue_free()

func _show_error(message: String):
    # Show error message
    var label = Label.new()
    label.text = message
    label.add_theme_color_override("font_color", Color.RED)
    $Margin/VBox/Status.add_child(label)
    
    await get_tree().create_timer(3.0).timeout
    label.queue_free()

func _show_dialogue_popup(dialogue: String):
    # Show speech bubble popup
    pass

func _play_happy_animation():
    # Play happy bounce animation
    var tween = create_tween()
    tween.tween_property(dragon_sprite, "scale", Vector2(1.1, 1.1), 0.2)
    tween.tween_property(dragon_sprite, "scale", Vector2(1.0, 1.0), 0.2)

func _play_eating_animation():
    # Play eating animation
    pass

func _on_affection_changed(_pet: PetDragon, _new_level: int):
    _update_display()

func _on_close_button_pressed():
    queue_free()
```

---

### **4. PET JOURNAL UI**

**File: `pet_journal_ui.tscn` + `pet_journal_ui.gd`**

**Visual Layout:**
```
╔════════════════════════════════════════════════════════════╗
║                  🐉 SPARKLES' JOURNAL 🐉                   ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  Days Together: 37 days                                    ║
║  Affection: ❤️❤️❤️❤️🤍 (Best Friend)                      ║
║                                                            ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                            ║
║  ADVENTURE STATS:                                          ║
║  🗺️ Expeditions: 142                                      ║
║  💰 Gold Earned: 45,280g                                   ║
║  🔧 Parts Found: 89                                        ║
║  ⭐ Favorite Place: Ancient Forest (visited 34 times)     ║
║                                                            ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                            ║
║  MEMORABLE MOMENTS:                                        ║
║                                                            ║
║  📖 Day 1: First Meeting                                   ║
║     "The day we first met. I knew this was the beginning  ║
║      of something special."                                ║
║                                                            ║
║  📖 Day 3: First Expedition                                ║
║     "The first time Sparkles went exploring. So brave!"   ║
║                                                            ║
║  📖 Day 12: Friends                                        ║
║     "We've become friends!"                                ║
║                                                            ║
║  📖 Day 23: Century Club                                   ║
║     "100 expeditions! We've seen so much together."        ║
║                                                            ║
║  [Show More] [Close]                                       ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

**Scene Structure:**
```
PetJournalUI (Control)
└── MarginContainer
    └── VBoxContainer
        ├── TitleLabel
        ├── HeaderInfo (VBoxContainer)
        │   ├── DaysLabel
        │   └── AffectionLabel
        ├── Separator1
        ├── StatsLabel ("ADVENTURE STATS:")
        ├── StatsContainer (VBoxContainer)
        │   ├── ExpeditionsLabel
        │   ├── GoldLabel
        │   ├── PartsLabel
        │   └── FavoriteLabel
        ├── Separator2
        ├── MomentsLabel ("MEMORABLE MOMENTS:")
        ├── MomentsScrollContainer
        │   └── MomentsList (VBoxContainer)
        └── ButtonsContainer (HBoxContainer)
            ├── ShowMoreButton
            └── CloseButton
```

**Script:**
```gdscript
extends Control
class_name PetJournalUI

@onready var days_label = $Margin/VBox/Header/Days
@onready var affection_label = $Margin/VBox/Header/Affection
@onready var expeditions_label = $Margin/VBox/Stats/Expeditions
@onready var gold_label = $Margin/VBox/Stats/Gold
@onready var parts_label = $Margin/VBox/Stats/Parts
@onready var favorite_label = $Margin/VBox/Stats/Favorite
@onready var moments_list = $Margin/VBox/MomentsScroll/MomentsList
@onready var show_more_button = $Margin/VBox/Buttons/ShowMore

var pet_dragon: PetDragon
var showing_all_moments: bool = false

func setup(pet: PetDragon):
    pet_dragon = pet
    _populate_journal()

func _populate_journal():
    # Update days together
    pet_dragon.update_days_together()
    days_label.text = "Days Together: %d days" % pet_dragon.days_together
    
    # Affection
    var hearts = ""
    var full_hearts = int(pet_dragon.affection_level / 20)
    for i in range(full_hearts):
        hearts += "❤️"
    for i in range(5 - full_hearts):
        hearts += "🤍"
    
    affection_label.text = "Affection: %s (%s)" % [
        hearts,
        pet_dragon.get_affection_tier().capitalize().replace("_", " ")
    ]
    
    # Stats
    expeditions_label.text = "🗺️ Expeditions: %d" % pet_dragon.expeditions_completed
    gold_label.text = "💰 Gold Earned: %s" % _format_number(pet_dragon.total_gold_earned)
    parts_label.text = "🔧 Parts Found: %d" % pet_dragon.total_parts_found
    
    if pet_dragon.favorite_destination != "":
        var visits = pet_dragon.destination_visit_counts[pet_dragon.favorite_destination]
        favorite_label.text = "⭐ Favorite Place: %s (visited %d times)" % [
            pet_dragon.favorite_destination.capitalize().replace("_", " "),
            visits
        ]
    else:
        favorite_label.text = "⭐ Favorite Place: Not yet determined"
    
    # Memorable moments
    _display_moments()

func _display_moments():
    # Clear existing
    for child in moments_list.get_children():
        child.queue_free()
    
    var moments_to_show = pet_dragon.memorable_moments
    if not showing_all_moments and moments_to_show.size() > 5:
        moments_to_show = moments_to_show.slice(0, 5)
        show_more_button.visible = true
    else:
        show_more_button.visible = false
    
    # Display each moment
    for moment in moments_to_show:
        var moment_container = VBoxContainer.new()
        
        var title_label = Label.new()
        title_label.text = "📖 Day %d: %s" % [moment.day, moment.title]
        title_label.add_theme_color_override("font_color", Color.YELLOW)
        moment_container.add_child(title_label)
        
        var desc_label = Label.new()
        desc_label.text = '   "%s"' % moment.description
        desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
        moment_container.add_child(desc_label)
        
        moments_list.add_child(moment_container)
        
        # Add spacer
        var spacer = Control.new()
        spacer.custom_minimum_size.y = 10
        moments_list.add_child(spacer)

func _format_number(num: int) -> String:
    # Format large numbers with commas
    var num_str = str(num)
    var result = ""
    var count = 0
    
    for i in range(num_str.length() - 1, -1, -1):
        result = num_str[i] + result
        count += 1
        if count % 3 == 0 and i != 0:
            result = "," + result
    
    return result + "g"

func _on_show_more_pressed():
    showing_all_moments = true
    _display_moments()

func _on_close_pressed():
    queue_free()
```

---

### **5. PET STATUS WIDGET (Main Screen)**

**Small always-visible widget on main game screen:**

**File: `pet_status_widget.tscn` + `pet_status_widget.gd`**

**Visual Layout:**
```
╔══════════════════════════════════════╗
║  🐉 SPARKLES                         ║
║  Level 12 | ❤️❤️❤️❤️❤️ (Soulbound)  ║
║                                      ║
║  Status: 🗺️ Exploring Ancient Forest ║
║  Returns in: 8m 34s                  ║
║                                      ║
║  [View Details]                      ║
╚══════════════════════════════════════╝
```

**Scene Structure:**
```
PetStatusWidget (PanelContainer)
└── MarginContainer
    └── VBoxContainer
        ├── NameAndAffection (HBoxContainer)
        │   ├── NameLabel
        │   └── AffectionHearts
        ├── StatusLabel
        ├── TimeLabel
        └── DetailsButton
```

**Script:**
```gdscript
extends PanelContainer
class_name PetStatusWidget

@onready var name_label = $Margin/VBox/NameAffection/Name
@onready var affection_hearts = $Margin/VBox/NameAffection/Hearts
@onready var status_label = $Margin/VBox/Status
@onready var time_label = $Margin/VBox/Time
@onready var details_button = $Margin/VBox/DetailsButton

var pet_manager: PetDragonManager
var pet_dragon: PetDragon

func _ready():
    pet_manager = get_node("/root/PetDragonManager")
    pet_dragon = pet_manager.pet_dragon
    
    if not pet_dragon:
        visible = false
        return
    
    _update_display()

func _process(_delta):
    if pet_dragon:
        _update_status()

func _update_display():
    # Name and level
    name_label.text = "🐉 %s - Level %d" % [pet_dragon.player_given_name, pet_dragon.level]
    
    # Affection hearts
    var hearts = ""
    var full = int(pet_dragon.affection_level / 20)
    for i in range(full):
        hearts += "❤️"
    for i in range(5 - full):
        hearts += "🤍"
    affection_hearts.text = hearts

func _update_status():
    if pet_manager.is_pet_exploring():
        status_label.text = "Status: 🗺️ Exploring"
        
        # Get time remaining
        var time_remaining = ExplorationManager.get_time_remaining(pet_dragon)
        var minutes = time_remaining / 60
        var seconds = time_remaining % 60
        time_label.text = "Returns in: %dm %ds" % [minutes, seconds]
        time_label.visible = true
    else:
        status_label.text = "Status: 🏠 Resting"
        time_label.visible = false

func _on_details_button_pressed():
    var interaction_ui = preload("res://scenes/ui/pet_interaction_ui.tscn").instantiate()
    get_tree().root.add_child(interaction_ui)
```

---

## INTEGRATION POINTS

### **1. First Dragon Creation:**
```gdscript
# In your dragon creation system
func create_first_dragon(head: DragonPart, body: DragonPart, tail: DragonPart):
    # Check if this is the first dragon ever
    if not PetDragonManager.pet_dragon:
        # Create as pet
        var pet = PetDragonManager.create_pet_dragon(head, body, tail)
        
        # Show introduction popup
        var intro = preload("res://scenes/ui/pet_introduction_popup.tscn").instantiate()
        intro.setup(pet)
        get_tree().root.add_child(intro)
        
        return pet
    else:
        # Create normal dragon
        return create_normal_dragon(head, body, tail)
```

---

### **2. Game Start (Check Offline Progress):**
```gdscript
# In your main game initialization
func _on_game_loaded():
    # Calculate offline time
    var last_save_time = SaveSystem.get_last_save_time()
    var current_time = Time.get_unix_time_from_system()
    var seconds_offline = current_time - last_save_time
    
    # If player was offline for significant time
    if seconds_offline > 600:  # More than 10 minutes
        # Calculate pet's offline progress
        var results = PetDragonManager.calculate_offline_progress(seconds_offline)
        
        # Show welcome back popup
        var welcome = preload("res://scenes/ui/welcome_back_popup.tscn").instantiate()
        welcome.setup(results, seconds_offline)
        get_tree().root.add_child(welcome)
```

---

### **3. Game Over Prevention:**
```gdscript
# In your game state manager
func check_for_game_over() -> bool:
    var total_dragons = get_all_dragons().size()
    var has_resources = GameState.gold > 0 or PartInventory.get_total_parts() >= 3
    
    # If player only has pet dragon left and no resources
    if total_dragons == 1 and not has_resources:
        # Check if pet is exploring (will save them)
        if PetDragonManager.is_pet_exploring():
            _show_crisis_message("Don't worry - your companion is out exploring and will return with help soon!")
            return false
        
        # Pet is idle - trigger emergency expedition
        _trigger_emergency_rescue()
        return false
    
    return false  # With pet system, game over is impossible

func _trigger_emergency_rescue():
    # Show crisis popup
    var crisis = preload("res://scenes/ui/crisis_popup.tscn").instantiate()
    get_tree().root.add_child(crisis)
    
    # Force pet on emergency expedition
    var rewards = PetDragonManager.generate_emergency_rewards()
    
    # Give player the emergency rewards after short delay
    await get_tree().create_timer(2.0).timeout
    GameState.gold += rewards.gold
    for part in rewards.parts:
        PartInventory.add_part(part)
    
    _show_message("%s returned with emergency supplies!" % PetDragonManager.pet_dragon.player_given_name)
```

---

### **4. Expedition Completion:**
```gdscript
# In your exploration system
func on_expedition_complete(dragon: Dragon, destination: String, rewards: Dictionary):
    # Check if this is the pet dragon
    if dragon.is_pet:
        PetDragonManager.on_pet_expedition_complete(destination, rewards)
    
    # Normal expedition handling
    # ...
```

---

## PERSONALITY SYSTEM DETAILS

### **Personality Trait Effects:**
```gdscript
# In pet_dragon_manager.gd

func apply_personality_modifiers(destination: String, base_rewards: Dictionary) -> Dictionary:
    var modified = base_rewards.duplicate()
    
    match pet_dragon.personality:
        PetDragon.Personality.CURIOUS:
            # 10% higher chance for rare finds
            if randf() < 0.10:
                modified.parts.append(_generate_rare_part())
        
        PetDragon.Personality.BRAVE:
            # Can explore dangerous locations at level 10+
            # 20% bonus rewards from dangerous places
            if pet_dragon.level >= 10 and destination == "shadow_realm":
                modified.gold = int(modified.gold * 1.20)
        
        PetDragon.Personality.LAZY:
            # Takes 50% longer but never fails
            # This is handled in exploration duration
            pass
        
        PetDragon.Personality.ENERGETIC:
            # 25% faster exploration
            # This is handled in exploration duration
            pass
        
        PetDragon.Personality.GREEDY:
            # 20% more gold
            modified.gold = int(modified.gold * 1.20)
        
        PetDragon.Personality.GENTLE:
            # 15% better part recovery
            if randf() < 0.15:
                modified.parts.append(_generate_random_part())
    
    return modified
```

---

## VISUAL POLISH

### **Animations:**
- Pet bounces happily when petted
- Eating animation when fed
- Sparkle effect when affection increases
- Glow pulse when affection tier changes
- Excited bounce when returning from expedition
- Sad droopy animation when hungry

### **Particle Effects:**
- Heart particles when petting
- Sparkles when affection increases
- Gold coins when collecting expedition rewards
- Gift box shimmer when present available

### **Color Coding:**
- Affection hearts: Red gradient
- Personality icon: Color-coded by type
- Status indicators: Green (good), Yellow (warning), Red (urgent)

---

## AUDIO FEEDBACK

**Pet Interactions:**
- Pet: Happy purr/coo sound
- Feed: Eating/crunching sound
- Gift: Joyful chirp
- Talk: Gentle dragon vocalization
- Level up: Triumphant roar

**Events:**
- Expedition complete: Success fanfare
- Gift received: Magical chime
- Affection tier up: Achievement sound
- Emergency rescue: Heroic music sting

---

## BALANCE CONSIDERATIONS

### **Affection Gain Rates:**
- Designed so Soulbound takes ~30-50 days of regular play
- Expeditions are primary source (encourages using the pet)
- Petting is limited by cooldown (prevents exploitation)
- Feeding costs gold (trade-off decision)

### **Emergency Rewards:**
- Guaranteed 500g minimum (enough for basic needs)
- Always 3 parts (can create one dragon)
- Scales with pet level (rewards long-term players)
- Not exploitable (only triggers when truly stuck)

### **Offline Rewards:**
- Similar to active play, not better (prevents exploit)
- Pet continues what it was doing (natural behavior)
- Capped by hunger system (can't be infinite)
- Feels generous but not game-breaking

---

## DELIVERABLES

Please provide:

1. **pet_dragon.gd** - PetDragon class extending Dragon
2. **pet_dragon_manager.gd** - Manager singleton with all pet logic
3. **pet_introduction_popup.tscn + .gd** - First meeting UI
4. **welcome_back_popup.tscn + .gd** - Offline progress UI
5. **pet_interaction_ui.tscn + .gd** - Main interaction screen
6. **pet_journal_ui.tscn + .gd** - Memory journal screen
7. **pet_status_widget.tscn + .gd** - Always-visible widget
8. **README.md** - Integration instructions

**Code Quality:**
- Godot 4 syntax
- Clean, commented code
- Signal-based architecture
- Save/load compatible
- Handles offline progress correctly
- Performance optimized

Create a pet system that makes players genuinely care about their companion and eliminates the possibility of game over!