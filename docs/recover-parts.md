I'm building a dragon factory idle game in Godot 4. I need you to implement a dragon death system with part recovery, decay mechanics, and a freezer storage system.

## GAME CONTEXT

**Dragon Death System:**
- Dragons can die from combat, starvation, or exploration accidents
- When a dragon dies, there's a chance to recover 0-3 parts from it
- Recovered parts are stored separately from normal parts
- Recovered parts have a 24-hour real-time decay timer
- Players can purchase a freezer to preserve recovered parts

**Freezer System:**
- Unlocked after defeating 100 knight waves
- Has 5 upgrade levels with increasing capacity and cost
- Players must manually move parts into freezer slots
- Frozen parts are preserved indefinitely (no decay)
- Can unfreeze parts back to recovered inventory

---

## FREEZER SPECIFICATIONS

### **Freezer Upgrade Levels:**

| Level | Capacity | Cost | Unlock Requirement |
|-------|----------|------|-------------------|
| 1 | 5 slots | 500g | 100 waves defeated |
| 2 | 10 slots | 1,500g | Level 1 purchased |
| 3 | 15 slots | 4,000g | Level 2 purchased |
| 4 | 20 slots | 10,000g | Level 3 purchased |
| 5 | 25 slots | 25,000g | Level 4 purchased |

**Cost Scaling Formula:** 
- Level 1: 500g
- Each subsequent level: Previous cost × ~3

---

## PART RECOVERY MECHANICS

### **Recovery Chances by Death Cause:**
```gdscript
# Probability distribution for number of parts recovered
const RECOVERY_CHANCES = {
    "combat_defending": {
        0: 0.20,  # 20% chance no parts
        1: 0.50,  # 50% chance 1 part
        2: 0.25,  # 25% chance 2 parts
        3: 0.05   # 5% chance all 3 parts
    },
    "combat_failed": {
        0: 0.40,
        1: 0.40,
        2: 0.15,
        3: 0.05
    },
    "starvation": {
        0: 0.50,
        1: 0.35,
        2: 0.10,
        3: 0.05
    },
    "exploration_accident": {
        0: 0.30,
        1: 0.45,
        2: 0.20,
        3: 0.05
    }
}
```

### **Which Parts Are Recovered:**
- Random selection from the dragon's 3 parts (head, body, tail)
- Each part has equal chance to be selected
- No duplicate part types (can't recover 2 heads from same dragon)

---

## DECAY TIMER SYSTEM

### **Decay Specifications:**

**Timer Type:** Real-time (continues while offline)
- Decay Duration: 86400 seconds (24 hours)
- Timer starts when part is recovered
- Timer stored as Unix timestamp
- Check for decay every 60 seconds

**Decay Warnings:**
- 24-12h remaining: Green text, normal display
- 12-6h remaining: Yellow text, "⚠️" icon
- 6-1h remaining: Orange text, pulsing highlight
- <1h remaining: Red text, flashing, "🚨" icon
- <10 minutes: Critical warning notification

**When Part Decays:**
- Part is permanently deleted from recovered inventory
- Show notification to player
- Play sad/decay sound effect

---

## DATA STRUCTURES

### **Extended DragonPart Class:**
```gdscript
class_name DragonPart extends Resource

enum PartType { HEAD, BODY, TAIL }
enum Element { FIRE, ICE, LIGHTNING, NATURE, SHADOW }
enum Source { NORMAL, RECOVERED, FROZEN }

@export var part_id: String  # Unique identifier
@export var part_type: PartType
@export var element: Element
@export var rarity: String = "Common"  # Common, Uncommon, Rare, Epic, Legendary
@export var source: Source = Source.NORMAL
@export var stats: Dictionary = {}  # ATK, HP, SPD bonuses

# Decay system (only for recovered parts)
@export var recovery_timestamp: int = 0  # Unix timestamp when recovered
@export var decay_duration: int = 86400  # 24 hours

# Freezer system
@export var freezer_slot_index: int = -1  # -1 if not in freezer

func is_recovered() -> bool:
    return source == Source.RECOVERED

func is_frozen() -> bool:
    return source == Source.FROZEN

func get_time_until_decay() -> int:
    if not is_recovered():
        return -1
    var current_time = Time.get_unix_time_from_system()
    var decay_time = recovery_timestamp + decay_duration
    return max(0, decay_time - current_time)

func is_decayed() -> bool:
    return is_recovered() and get_time_until_decay() <= 0

func get_decay_urgency() -> String:
    # Returns: "safe", "warning", "urgent", "critical"
    var time_left = get_time_until_decay()
    if time_left > 43200:  # >12 hours
        return "safe"
    elif time_left > 21600:  # >6 hours
        return "warning"
    elif time_left > 3600:  # >1 hour
        return "urgent"
    else:
        return "critical"

func format_time_remaining() -> String:
    var seconds = get_time_until_decay()
    var hours = seconds / 3600
    var minutes = (seconds % 3600) / 60
    
    if hours >= 1:
        return "%dh %dm" % [hours, minutes]
    elif minutes >= 1:
        return "%dm" % minutes
    else:
        return "%ds" % seconds
```

---

## MANAGER SINGLETON

### **DragonDeathManager (Autoload Singleton):**

**File: `dragon_death_manager.gd`**
```gdscript
extends Node
class_name DragonDeathManager

signal dragon_died(dragon_name: String, cause: String, recovered_parts: Array)
signal part_recovered(part: DragonPart)
signal part_decayed(part: DragonPart)
signal freezer_unlocked(level: int)
signal freezer_upgraded(new_level: int, new_capacity: int)
signal part_frozen(part: DragonPart, slot_index: int)
signal part_unfrozen(part: DragonPart)

const FREEZER_UNLOCK_WAVES = 100
const FREEZER_LEVELS = [
    {"level": 1, "capacity": 5, "cost": 500},
    {"level": 2, "capacity": 10, "cost": 1500},
    {"level": 3, "capacity": 15, "cost": 4000},
    {"level": 4, "capacity": 20, "cost": 10000},
    {"level": 5, "capacity": 25, "cost": 25000}
]

# State
var freezer_level: int = 0  # 0 = locked, 1-5 = upgrade level
var recovered_parts: Array[DragonPart] = []
var freezer_slots: Array = []  # Array of DragonPart or null (empty slots)

func _ready():
    # Initialize freezer slots array (empty)
    _resize_freezer_slots()
    
    # Start decay check timer
    var decay_timer = Timer.new()
    decay_timer.timeout.connect(_check_part_decay)
    decay_timer.wait_time = 60.0  # Check every minute
    decay_timer.autostart = true
    add_child(decay_timer)

# ═══════════════════════════════════════════════════════════
# DRAGON DEATH HANDLING
# ═══════════════════════════════════════════════════════════

func handle_dragon_death(dragon: Dragon, death_cause: String):
    """
    Called when a dragon dies
    Args:
        dragon: The dragon that died
        death_cause: "combat_defending", "combat_failed", "starvation", "exploration_accident"
    """
    # Roll for part recovery
    var num_parts = _roll_part_recovery(death_cause)
    
    # Select which parts to recover
    var recovered = _select_parts_from_dragon(dragon, num_parts)
    
    # Mark parts as recovered with timestamp
    for part in recovered:
        part.source = DragonPart.Source.RECOVERED
        part.recovery_timestamp = Time.get_unix_time_from_system()
        part.part_id = _generate_part_id()
        recovered_parts.append(part)
        part_recovered.emit(part)
    
    # Emit death signal and show notification
    dragon_died.emit(dragon.dragon_name, death_cause, recovered)
    
    # Show death popup UI
    _show_death_notification(dragon, death_cause, recovered)

func _roll_part_recovery(death_cause: String) -> int:
    # Get probability distribution for this death cause
    var chances = _get_recovery_chances(death_cause)
    
    # Roll random number
    var roll = randf()
    var cumulative = 0.0
    
    # Determine number of parts recovered
    for i in range(4):  # 0, 1, 2, 3 parts
        cumulative += chances[i]
        if roll <= cumulative:
            return i
    
    return 0

func _get_recovery_chances(death_cause: String) -> Array[float]:
    match death_cause:
        "combat_defending":
            return [0.20, 0.50, 0.25, 0.05]
        "combat_failed":
            return [0.40, 0.40, 0.15, 0.05]
        "starvation":
            return [0.50, 0.35, 0.10, 0.05]
        "exploration_accident":
            return [0.30, 0.45, 0.20, 0.05]
        _:
            return [0.40, 0.40, 0.15, 0.05]

func _select_parts_from_dragon(dragon: Dragon, count: int) -> Array[DragonPart]:
    # Get all parts from dragon
    var available = [
        dragon.head_part.duplicate(),
        dragon.body_part.duplicate(),
        dragon.tail_part.duplicate()
    ]
    
    # Shuffle and take first 'count' parts
    available.shuffle()
    
    var recovered: Array[DragonPart] = []
    for i in range(min(count, 3)):
        recovered.append(available[i])
    
    return recovered

func _generate_part_id() -> String:
    # Generate unique ID for part tracking
    return "%d_%d" % [Time.get_ticks_msec(), randi()]

func _show_death_notification(dragon: Dragon, cause: String, parts: Array):
    # Create and show death popup
    var popup = load("res://scenes/ui/dragon_death_popup.tscn").instantiate()
    popup.setup(dragon, cause, parts)
    get_tree().root.add_child(popup)

# ═══════════════════════════════════════════════════════════
# DECAY SYSTEM
# ═══════════════════════════════════════════════════════════

func _check_part_decay():
    """Called every minute to check for decayed parts"""
    var decayed: Array[DragonPart] = []
    
    for part in recovered_parts:
        if part.is_decayed():
            decayed.append(part)
    
    # Remove decayed parts
    for part in decayed:
        recovered_parts.erase(part)
        part_decayed.emit(part)
        _show_decay_notification(part)

func _show_decay_notification(part: DragonPart):
    # Show notification that part has decayed
    var msg = "💀 %s %s has decayed!" % [
        _element_name(part.element),
        _part_type_name(part.part_type)
    ]
    # TODO: Show in-game notification
    print(msg)

func get_decay_warnings() -> Array[DragonPart]:
    """Returns parts that are close to decaying (<1 hour)"""
    var warnings: Array[DragonPart] = []
    for part in recovered_parts:
        if part.get_time_until_decay() < 3600:  # Less than 1 hour
            warnings.append(part)
    return warnings

# ═══════════════════════════════════════════════════════════
# FREEZER SYSTEM
# ═══════════════════════════════════════════════════════════

func can_unlock_freezer() -> bool:
    var waves = GameState.waves_completed  # Adjust to your wave tracking variable
    return waves >= FREEZER_UNLOCK_WAVES and freezer_level == 0

func get_freezer_unlock_progress() -> float:
    var waves = GameState.waves_completed
    return clampf(float(waves) / float(FREEZER_UNLOCK_WAVES), 0.0, 1.0)

func unlock_freezer() -> bool:
    """Purchase Level 1 freezer"""
    if not can_unlock_freezer():
        return false
    
    var cost = FREEZER_LEVELS[0].cost
    if GameState.gold < cost:
        return false
    
    GameState.gold -= cost
    freezer_level = 1
    _resize_freezer_slots()
    freezer_unlocked.emit(1)
    return true

func can_upgrade_freezer() -> bool:
    return freezer_level > 0 and freezer_level < FREEZER_LEVELS.size()

func get_next_freezer_upgrade() -> Dictionary:
    """Returns info about next upgrade level or empty dict if maxed"""
    if not can_upgrade_freezer():
        return {}
    return FREEZER_LEVELS[freezer_level]  # Next level (0-indexed)

func upgrade_freezer() -> bool:
    """Purchase next freezer upgrade level"""
    if not can_upgrade_freezer():
        return false
    
    var upgrade = get_next_freezer_upgrade()
    if GameState.gold < upgrade.cost:
        return false
    
    GameState.gold -= upgrade.cost
    freezer_level += 1
    _resize_freezer_slots()
    freezer_upgraded.emit(freezer_level, get_freezer_capacity())
    return true

func get_freezer_capacity() -> int:
    """Returns current maximum freezer slots"""
    if freezer_level == 0:
        return 0
    return FREEZER_LEVELS[freezer_level - 1].capacity

func get_freezer_used_slots() -> int:
    """Returns number of slots currently occupied"""
    var count = 0
    for slot in freezer_slots:
        if slot != null:
            count += 1
    return count

func get_freezer_empty_slots() -> int:
    return get_freezer_capacity() - get_freezer_used_slots()

func _resize_freezer_slots():
    """Resize freezer_slots array to match current capacity"""
    var capacity = get_freezer_capacity()
    freezer_slots.resize(capacity)
    
    # Initialize new slots to null
    for i in range(freezer_slots.size()):
        if freezer_slots[i] == null:
            freezer_slots[i] = null

func freeze_part(part: DragonPart, slot_index: int) -> bool:
    """
    Move a recovered part into freezer slot
    Args:
        part: The DragonPart to freeze
        slot_index: Which freezer slot to use (0-based)
    Returns:
        true if successful
    """
    # Validate
    if freezer_level == 0:
        return false
    if slot_index < 0 or slot_index >= get_freezer_capacity():
        return false
    if freezer_slots[slot_index] != null:
        return false  # Slot occupied
    if not part in recovered_parts:
        return false  # Part not in recovered inventory
    
    # Remove from recovered inventory
    recovered_parts.erase(part)
    
    # Change part state
    part.source = DragonPart.Source.FROZEN
    part.recovery_timestamp = 0  # Clear decay timer
    part.freezer_slot_index = slot_index
    
    # Add to freezer
    freezer_slots[slot_index] = part
    
    part_frozen.emit(part, slot_index)
    return true

func unfreeze_part(slot_index: int) -> bool:
    """
    Remove part from freezer and return to recovered inventory
    Args:
        slot_index: Freezer slot to remove from
    Returns:
        true if successful
    """
    if slot_index < 0 or slot_index >= freezer_slots.size():
        return false
    
    var part = freezer_slots[slot_index]
    if part == null:
        return false
    
    # Remove from freezer
    freezer_slots[slot_index] = null
    
    # Change part state back to recovered
    part.source = DragonPart.Source.RECOVERED
    part.recovery_timestamp = Time.get_unix_time_from_system()  # Reset decay timer
    part.freezer_slot_index = -1
    
    # Add to recovered inventory
    recovered_parts.append(part)
    
    part_unfrozen.emit(part)
    return true

func get_part_in_freezer_slot(slot_index: int) -> DragonPart:
    """Returns part in slot or null if empty"""
    if slot_index >= 0 and slot_index < freezer_slots.size():
        return freezer_slots[slot_index]
    return null

func is_freezer_slot_empty(slot_index: int) -> bool:
    if slot_index < 0 or slot_index >= freezer_slots.size():
        return false
    return freezer_slots[slot_index] == null

# ═══════════════════════════════════════════════════════════
# SAVE/LOAD
# ═══════════════════════════════════════════════════════════

func to_save_dict() -> Dictionary:
    return {
        "freezer_level": freezer_level,
        "recovered_parts": _serialize_parts(recovered_parts),
        "freezer_slots": _serialize_freezer_slots()
    }

func load_from_dict(data: Dictionary):
    freezer_level = data.get("freezer_level", 0)
    _resize_freezer_slots()
    
    recovered_parts = _deserialize_parts(data.get("recovered_parts", []))
    _deserialize_freezer_slots(data.get("freezer_slots", []))

func _serialize_parts(parts: Array[DragonPart]) -> Array:
    var result = []
    for part in parts:
        result.append({
            "id": part.part_id,
            "type": part.part_type,
            "element": part.element,
            "rarity": part.rarity,
            "timestamp": part.recovery_timestamp,
            "stats": part.stats
        })
    return result

func _deserialize_parts(data: Array) -> Array[DragonPart]:
    var parts: Array[DragonPart] = []
    for part_data in data:
        var part = DragonPart.new()
        part.part_id = part_data.id
        part.part_type = part_data.type
        part.element = part_data.element
        part.rarity = part_data.rarity
        part.source = DragonPart.Source.RECOVERED
        part.recovery_timestamp = part_data.timestamp
        part.stats = part_data.get("stats", {})
        parts.append(part)
    return parts

func _serialize_freezer_slots() -> Array:
    var result = []
    for i in range(freezer_slots.size()):
        if freezer_slots[i] != null:
            var part = freezer_slots[i]
            result.append({
                "slot": i,
                "id": part.part_id,
                "type": part.part_type,
                "element": part.element,
                "rarity": part.rarity,
                "stats": part.stats
            })
    return result

func _deserialize_freezer_slots(data: Array):
    for slot_data in data:
        var part = DragonPart.new()
        part.part_id = slot_data.id
        part.part_type = slot_data.type
        part.element = slot_data.element
        part.rarity = slot_data.rarity
        part.source = DragonPart.Source.FROZEN
        part.freezer_slot_index = slot_data.slot
        part.stats = slot_data.get("stats", {})
        
        freezer_slots[slot_data.slot] = part

# ═══════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════

func _element_name(element: DragonPart.Element) -> String:
    match element:
        DragonPart.Element.FIRE: return "Fire"
        DragonPart.Element.ICE: return "Ice"
        DragonPart.Element.LIGHTNING: return "Lightning"
        DragonPart.Element.NATURE: return "Nature"
        DragonPart.Element.SHADOW: return "Shadow"
    return "Unknown"

func _part_type_name(part_type: DragonPart.PartType) -> String:
    match part_type:
        DragonPart.PartType.HEAD: return "Head"
        DragonPart.PartType.BODY: return "Body"
        DragonPart.PartType.TAIL: return "Tail"
    return "Unknown"
```

---

## UI COMPONENTS

### **1. DRAGON DEATH POPUP**

**File: `dragon_death_popup.tscn` + `dragon_death_popup.gd`**

**Visual Layout:**
```
╔════════════════════════════════════════════════════════════╗
║                   💀 DRAGON LOST 💀                        ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║            [Dragon Portrait - Grayed Out]                  ║
║                                                            ║
║                   PYROFROST (Level 5)                      ║
║                                                            ║
║  Cause of Death: Defeated defending Tower 2               ║
║                                                            ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                            ║
║              PARTS RECOVERED: 2/3                          ║
║                                                            ║
║     [🔥 Fire Head]        [🔥 Fire Body]                  ║
║     Rare Quality          Common Quality                   ║
║                                                            ║
║  ⏱️ These parts will decay in 24 hours                    ║
║                                                            ║
║  [View Inventory] [Continue]                               ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

**Script:**
```gdscript
extends Control
class_name DragonDeathPopup

@onready var dragon_name_label = $VBox/DragonName
@onready var portrait = $VBox/Portrait
@onready var cause_label = $VBox/CauseLabel
@onready var parts_container = $VBox/PartsRecovered
@onready var decay_warning = $VBox/DecayWarning
@onready var view_inventory_button = $VBox/Buttons/ViewInventory
@onready var continue_button = $VBox/Buttons/Continue

func setup(dragon: Dragon, death_cause: String, recovered: Array):
    dragon_name_label.text = "%s (Level %d)" % [dragon.dragon_name, dragon.level]
    cause_label.text = "Cause of Death: %s" % _format_death_cause(death_cause)
    
    # Show recovered parts
    if recovered.is_empty():
        parts_container.get_node("CountLabel").text = "NO PARTS RECOVERED"
        decay_warning.visible = false
    else:
        parts_container.get_node("CountLabel").text = "PARTS RECOVERED: %d/3" % recovered.size()
        _display_recovered_parts(recovered)
        decay_warning.visible = true
    
    portrait.texture = dragon.portrait_texture
    portrait.modulate = Color(0.5, 0.5, 0.5)  # Gray out

func _display_recovered_parts(parts: Array):
    # Clear existing part displays
    var parts_grid = parts_container.get_node("PartsGrid")
    for child in parts_grid.get_children():
        child.queue_free()
    
    # Create part card for each recovered part
    for part in parts:
        var part_card = preload("res://scenes/ui/part_card_small.tscn").instantiate()
        part_card.setup(part)
        parts_grid.add_child(part_card)

func _format_death_cause(cause: String) -> String:
    match cause:
        "combat_defending":
            return "Defeated in combat defending your laboratory"
        "combat_failed":
            return "Killed when defenses were overwhelmed"
        "starvation":
            return "Died of starvation"
        "exploration_accident":
            return "Lost during exploration expedition"
        _:
            return "Unknown cause"

func _on_view_inventory_pressed():
    # Open parts inventory screen
    get_tree().change_scene_to_file("res://scenes/ui/parts_inventory.tscn")
    queue_free()

func _on_continue_pressed():
    queue_free()
```

---

### **2. PARTS INVENTORY SCREEN**

**File: `parts_inventory_ui.tscn` + `parts_inventory_ui.gd`**

**Visual Layout:**
```
╔════════════════════════════════════════════════════════════╗
║                   PARTS INVENTORY                          ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  [Normal Parts: 12] [Recovered: 6 ⏱️] [Freezer: 8/15 ❄️]  ║
║                                                            ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                            ║
║  RECOVERED PARTS (Decaying):                               ║
║                                                            ║
║  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    ║
║  │ 🔥 Fire Head │  │ ⚡ Lightning │  │ 🌲 Nature    │    ║
║  │              │  │    Body      │  │    Tail      │    ║
║  │ Rare         │  │ Common       │  │ Uncommon     │    ║
║  ├──────────────┤  ├──────────────┤  ├──────────────┤    ║
║  │ ⏱️ 18h 23m   │  │ ⏱️ 0h 47m ⚠️ │  │ ⏱️ 23h 12m   │    ║
║  ├──────────────┤  ├──────────────┤  ├──────────────┤    ║
║  │[Use][Freeze] │  │[Use][Freeze] │  │[Use][Freeze] │    ║
║  └──────────────┘  └──────────────┘  └──────────────┘    ║
║                                                            ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                            ║
║  FREEZER (Level 3): ❄️ 8/15 slots                         ║
║  [UPGRADE TO LEVEL 4: 10,000g]                            ║
║                                                            ║
║  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐           ║
║  │ 🧊   │ │ 🧊   │ │ 🧊   │ │Empty │ │Empty │           ║
║  │ Ice  │ │ Fire │ │Shadow│ │      │ │      │           ║
║  │ Head │ │ Tail │ │ Body │ │ [+]  │ │ [+]  │           ║
║  │[Unfrz]│ │[Unfrz]│ │[Unfrz]│ │      │ │      │           ║
║  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘           ║
║                                                            ║
║  [Close]                          [Freeze All Recovered]   ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

**Script:**
```gdscript
extends Control
class_name PartsInventoryUI

@onready var tab_buttons = $Header/TabButtons
@onready var recovered_container = $Content/RecoveredParts
@onready var freezer_container = $Content/FreezerSection
@onready var freezer_upgrade_button = $Content/FreezerSection/UpgradeButton
@onready var freezer_slots_grid = $Content/FreezerSection/SlotsGrid

var death_manager: DragonDeathManager
var selected_part_for_freezing: DragonPart = null

func _ready():
    death_manager = get_node("/root/DragonDeathManager")
    
    # Connect signals
    death_manager.part_recovered.connect(_on_part_recovered)
    death_manager.part_decayed.connect(_on_part_decayed)
    death_manager.part_frozen.connect(_on_part_frozen)
    death_manager.part_unfrozen.connect(_on_part_unfrozen)
    death_manager.freezer_upgraded.connect(_on_freezer_upgraded)
    
    _refresh_display()

func _refresh_display():
    _display_recovered_parts()
    _display_freezer_section()
    _update_tab_counts()

func _display_recovered_parts():
    # Clear existing
    for child in recovered_container.get_children():
        if child.name != "TitleLabel":
            child.queue_free()
    
    var parts = death_manager.recovered_parts
    
    if parts.is_empty():
        var label = Label.new()
        label.text = "No recovered parts"
        recovered_container.add_child(label)
        return
    
    # Sort by time remaining (most urgent first)
    parts.sort_custom(func(a, b): return a.get_time_until_decay() < b.get_time_until_decay())
    
    # Create card for each part
    for part in parts:
        var card = preload("res://scenes/ui/recovered_part_card.tscn").instantiate()
        card.setup(part)
        card.freeze_clicked.connect(_on_freeze_part_clicked.bind(part))
        card.use_clicked.connect(_on_use_part_clicked.bind(part))
        recovered_container.add_child(card)

func _display_freezer_section():
    if death_manager.freezer_level == 0:
        _show_freezer_locked()
        return
    
    _show_freezer_unlocked()

func _show_freezer_locked():
    freezer_container.get_node("LockedPanel").visible = true
    freezer_container.get_node("UnlockedPanel").visible = false
    
    var progress = death_manager.get_freezer_unlock_progress()
    var waves_needed = DragonDeathManager.FREEZER_UNLOCK_WAVES
    var waves_current = int(progress * waves_needed)
    
    freezer_container.get_node("LockedPanel/ProgressLabel").text = "%d/%d waves" % [waves_current, waves_needed]
    freezer_container.get_node("LockedPanel/ProgressBar").value = progress * 100
    
    var can_unlock = death_manager.can_unlock_freezer()
    var unlock_button = freezer_container.get_node("LockedPanel/UnlockButton")
    unlock_button.disabled = not can_unlock
    unlock_button.text = "UNLOCK FREEZER (500g)" if can_unlock else "LOCKED - %d more waves" % (waves_needed - waves_current)

func _show_freezer_unlocked():
    freezer_container.get_node("LockedPanel").visible = false
    freezer_container.get_node("UnlockedPanel").visible = true
    
    var capacity = death_manager.get_freezer_capacity()
    var used = death_manager.get_freezer_used_slots()
    
    freezer_container.get_node("UnlockedPanel/TitleLabel").text = "FREEZER (Level %d): ❄️ %d/%d slots" % [
        death_manager.freezer_level,
        used,
        capacity
    ]
    
    # Show upgrade button if possible
    if death_manager.can_upgrade_freezer():
        var upgrade_info = death_manager.get_next_freezer_upgrade()
        freezer_upgrade_button.visible = true
        freezer_upgrade_button.text = "UPGRADE TO LEVEL %d: %dg (+%d slots)" % [
            upgrade_info.level,
            upgrade_info.cost,
            upgrade_info.capacity - capacity
        ]
        freezer_upgrade_button.disabled = GameState.gold < upgrade_info.cost
    else:
        freezer_upgrade_button.visible = false
    
    # Display freezer slots
    _display_freezer_slots()

func _display_freezer_slots():
    # Clear existing
    for child in freezer_slots_grid.get_children():
        child.queue_free()
    
    var capacity = death_manager.get_freezer_capacity()
    
    for i in range(capacity):
        var slot = preload("res://scenes/ui/freezer_slot.tscn").instantiate()
        slot.setup(i)
        
        var part = death_manager.get_part_in_freezer_slot(i)
        if part:
            slot.set_part(part)
            slot.unfreeze_clicked.connect(_on_unfreeze_clicked.bind(i))
        else:
            slot.set_empty()
            slot.empty_clicked.connect(_on_empty_slot_clicked.bind(i))
        
        freezer_slots_grid.add_child(slot)

func _update_tab_counts():
    # Update tab button labels with counts
    var normal_count = GameState.get_normal_parts_count()  # Implement in your GameState
    var recovered_count = death_manager.recovered_parts.size()
    var frozen_count = death_manager.get_freezer_used_slots()
    
    tab_buttons.get_node("NormalTab").text = "Normal Parts: %d" % normal_count
    tab_buttons.get_node("RecoveredTab").text = "Recovered: %d ⏱️" % recovered_count
    tab_buttons.get_node("FreezerTab").text = "Freezer: %d/%d ❄️" % [frozen_count, death_manager.get_freezer_capacity()]

# ═══════════════════════════════════════════════════════════
# BUTTON HANDLERS
# ═══════════════════════════════════════════════════════════

func _on_unlock_freezer_pressed():
    if death_manager.unlock_freezer():
        _refresh_display()

func _on_upgrade_freezer_pressed():
    if death_manager.upgrade_freezer():
        _refresh_display()

func _on_freeze_part_clicked(part: DragonPart):
    # Show freezer slot picker
    selected_part_for_freezing = part
    _show_slot_picker()

func _on_empty_slot_clicked(slot_index: int):
    # User clicked empty freezer slot
    if selected_part_for_freezing:
        # Freeze the selected part into this slot
        if death_manager.freeze_part(selected_part_for_freezing, slot_index):
            selected_part_for_freezing = null
            _refresh_display()

func _on_unfreeze_clicked(slot_index: int):
    if death_manager.unfreeze_part(slot_index):
        _refresh_display()

func _on_use_part_clicked(part: DragonPart):
    # Open dragon creation screen with this part pre-selected
    # TODO: Implement navigation to dragon creation
    pass

func _on_freeze_all_pressed():
    # Freeze all recovered parts into available slots
    var parts_to_freeze = death_manager.recovered_parts.duplicate()
    var next_slot = 0
    
    for part in parts_to_freeze:
        # Find next empty slot
        while next_slot < death_manager.get_freezer_capacity():
            if death_manager.is_freezer_slot_empty(next_slot):
                death_manager.freeze_part(part, next_slot)
                next_slot += 1
                break
            next_slot += 1
    
    _refresh_display()

# ═══════════════════════════════════════════════════════════
# SIGNAL HANDLERS
# ═══════════════════════════════════════════════════════════

func _on_part_recovered(part: DragonPart):
    _refresh_display()

func _on_part_decayed(part: DragonPart):
    _refresh_display()
    # Show notification
    _show_decay_notification(part)

func _on_part_frozen(part: DragonPart, slot_index: int):
    _refresh_display()

func _on_part_unfrozen(part: DragonPart):
    _refresh_display()

func _on_freezer_upgraded(new_level: int, new_capacity: int):
    _refresh_display()

func _show_decay_notification(part: DragonPart):
    # TODO: Show toast notification
    pass

func _show_slot_picker():
    # Highlight empty freezer slots for selection
    pass
```

---

### **3. RECOVERED PART CARD**

**File: `recovered_part_card.tscn` + `recovered_part_card.gd`**
```gdscript
extends PanelContainer
class_name RecoveredPartCard

@onready var icon = $HBox/Icon
@onready var name_label = $HBox/VBox/NameLabel
@onready var rarity_label = $HBox/VBox/RarityLabel
@onready var timer_label = $HBox/VBox/TimerLabel
@onready var use_button = $HBox/Buttons/UseButton
@onready var freeze_button = $HBox/Buttons/FreezeButton

signal freeze_clicked
signal use_clicked

var part: DragonPart

func setup(recovered_part: DragonPart):
    part = recovered_part
    _update_display()

func _process(_delta):
    if part and part.is_recovered():
        _update_timer()

func _update_display():
    name_label.text = "%s %s" % [_element_name(part.element), _part_type_name(part.part_type)]
    rarity_label.text = part.rarity
    icon.texture = _get_part_icon(part)
    
    _update_timer()
    _apply_urgency_styling()

func _update_timer():
    timer_label.text = "⏱️ %s" % part.format_time_remaining()

func _apply_urgency_styling():
    var urgency = part.get_decay_urgency()
    
    match urgency:
        "safe":
            modulate = Color.WHITE
            timer_label.add_theme_color_override("font_color", Color.GREEN)
        "warning":
            modulate = Color.WHITE
            timer_label.add_theme_color_override("font_color", Color.YELLOW)
        "urgent":
            modulate = Color(1.2, 1.0, 0.8)
            timer_label.add_theme_color_override("font_color", Color.ORANGE)
        "critical":
            modulate = Color(1.3, 0.8, 0.8)
            timer_label.add_theme_color_override("font_color", Color.RED)
            # Add pulsing animation
            _pulse_warning()

func _pulse_warning():
    var tween = create_tween()
    tween.set_loops()
    tween.tween_property(self, "modulate:a", 0.7, 0.5)
    tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_use_button_pressed():
    use_clicked.emit()

func _on_freeze_button_pressed():
    freeze_clicked.emit()

func _element_name(element: DragonPart.Element) -> String:
    # Implement element name conversion
    return "Fire"  # Placeholder

func _part_type_name(part_type: DragonPart.PartType) -> String:
    # Implement part type name conversion
    return "Head"  # Placeholder

func _get_part_icon(part: DragonPart) -> Texture2D:
    # Return appropriate icon texture
    return null  # Placeholder
```

---

### **4. FREEZER SLOT**

**File: `freezer_slot.tscn` + `freezer_slot.gd`**
```gdscript
extends PanelContainer
class_name FreezerSlot

@onready var icon = $VBox/Icon
@onready var name_label = $VBox/NameLabel
@onready var preserved_label = $VBox/PreservedLabel
@onready var unfreeze_button = $VBox/UnfreezeButton
@onready var empty_button = $VBox/EmptyButton

signal unfreeze_clicked
signal empty_clicked

var slot_index: int = -1
var stored_part: DragonPart = null

func setup(index: int):
    slot_index = index

func set_part(part: DragonPart):
    stored_part = part
    
    icon.visible = true
    name_label.visible = true
    preserved_label.visible = true
    unfreeze_button.visible = true
    empty_button.visible = false
    
    name_label.text = "%s %s" % [_element_name(part.element), _part_type_name(part.part_type)]
    preserved_label.text = "❄️ Preserved"
    icon.texture = _get_part_icon(part)
    
    # Apply frost effect
    modulate = Color(0.7, 0.9, 1.0)  # Blue tint

func set_empty():
    stored_part = null
    
    icon.visible = false
    name_label.visible = false
    preserved_label.visible = false
    unfreeze_button.visible = false
    empty_button.visible = true
    
    empty_button.text = "[+]"
    
    # Remove frost effect
    modulate = Color.WHITE

func _on_unfreeze_button_pressed():
    unfreeze_clicked.emit()

func _on_empty_button_pressed():
    empty_clicked.emit()

func _element_name(element: DragonPart.Element) -> String:
    # Implement
    return "Fire"

func _part_type_name(part_type: DragonPart.PartType) -> String:
    # Implement
    return "Head"

func _get_part_icon(part: DragonPart) -> Texture2D:
    # Implement
    return null
```

---

## INTEGRATION POINTS

### **When Dragon Dies (in combat/exploration/starvation system):**
```gdscript
# In your combat system when dragon HP reaches 0
func _on_dragon_defeated(dragon: Dragon):
    DragonDeathManager.handle_dragon_death(dragon, "combat_defending")
    # Remove dragon from active roster
    # Update UI

# In exploration system when dragon dies
func _on_exploration_failed_fatally(dragon: Dragon):
    DragonDeathManager.handle_dragon_death(dragon, "exploration_accident")

# In hunger system when dragon starves
func _on_dragon_starved(dragon: Dragon):
    DragonDeathManager.handle_dragon_death(dragon, "starvation")
```

### **Access Inventory from Main UI:**
```gdscript
# Add button to main UI
func _on_parts_inventory_button_pressed():
    get_tree().change_scene_to_file("res://scenes/ui/parts_inventory_ui.tscn")
```

### **Check Freezer Unlock After Waves:**
```gdscript
# In your wave completion handler
func _on_wave_completed(wave_number: int):
    if wave_number == DragonDeathManager.FREEZER_UNLOCK_WAVES:
        # Show notification that freezer is now available
        _show_freezer_unlocked_notification()
```

---

## VISUAL POLISH REQUIREMENTS

**Death Popup:**
- Dark overlay background (semi-transparent black)
- Sad/dramatic music sting
- Dragon portrait grayed out and slightly desaturated
- Smooth fade-in animation

**Recovered Part Cards:**
- Color-coded borders by urgency (green → yellow → orange → red)
- Pulsing animation when <1 hour remaining
- Decay particle effects for critical parts
- Timer updates in real-time

**Freezer Slots:**
- Frost/ice texture overlay when occupied
- Blue-white color tint on frozen parts
- Snowflake particle effects
- Empty slots have dashed border
- Slight glow on hover

**Animations:**
- Part moving to freezer: Slide + fade with frost trail
- Part unfreezing: Ice crack effect + thaw animation
- Part decaying: Disintegration particle effect
- Freezer upgrade: Slots expanding animation

---

## AUDIO FEEDBACK

**Dragon Death:** Sad roar + dramatic music sting  
**Part Recovery:** Metallic clink (item drop)  
**Part Frozen:** Ice crystallization sound  
**Part Unfrozen:** Ice crack + thaw sound  
**Part Decay:** Disintegration/crumble sound + warning beep  
**Freezer Unlock:** Achievement fanfare  
**Freezer Upgrade:** Construction/upgrade sound  

---

## DELIVERABLES

Please provide:

1. **dragon_death_manager.gd** - Main manager singleton
2. **dragon_death_popup.tscn + .gd** - Death notification popup
3. **parts_inventory_ui.tscn + .gd** - Main inventory screen
4. **recovered_part_card.tscn + .gd** - Recovered part display card
5. **freezer_slot.tscn + .gd** - Individual freezer slot component
6. **README.md** - Integration instructions

**Code Quality:**
- Godot 4 syntax
- Clean, commented code
- Signal-based architecture
- Save/load compatible (handles offline decay correctly)
- Performance optimized
- Mobile-friendly touch support

Make this feel satisfying and create strategic decisions around managing decaying parts versus freezer space!