I'm building a dragon factory idle game in Godot 4. I need you to create a Training Yard system where dragons can be trained to level up over time.

## GAME CONTEXT

**Training Yard Purpose:**
- Dragons gain experience and level up through training
- Training happens in real-time (continues while AFK)
- Players assign dragons to training slots
- Training slots can be expanded with gold
- Trainer scientist speeds up training by 50%
- Each level up increases dragon stats (ATK, HP, SPD)

**Integration Points:**
- Dragons are already implemented with level/XP system
- Trainer scientist exists (can be hired/assigned)
- Gold currency system exists
- Save/load system must persist training progress across sessions

---

## TRAINING YARD SPECIFICATIONS

### CORE MECHANICS

**Training Slots:**
- Start with 2 free training slots
- Maximum 10 slots total
- Each slot can hold 1 dragon
- Expansion costs scale: 500g, 1000g, 2000g, 4000g, 4000g, 4000g, 4000g, 4000g

**Training Times (Without Trainer):**
- Lv 1→2: 2 hours (7200 seconds)
- Lv 2→3: 3 hours (10800 seconds)
- Lv 3→4: 4.5 hours (16200 seconds)
- Lv 4→5: 6 hours (21600 seconds)
- Formula: base_time = 7200 * (1.5 ^ (target_level - 2))

**Trainer Effect:**
- If Trainer scientist is assigned: -50% training time
- Training times halved: 1h, 1.5h, 2.25h, 3h, etc.

**Training Process:**
1. Player drags/assigns dragon to empty slot
2. Training timer starts (tracks elapsed time)
3. Progress bar fills based on elapsed_time / total_time
4. When complete: Dragon ready to collect
5. Collect dragon: Dragon levels up, stats increase, returns to idle

**Stat Gains Per Level:**
- ATK: +5 per level (affected by dragon parts/elements)
- HP: +15 per level (affected by dragon parts/elements)
- SPD: +2 per level (affected by dragon parts/elements)
- (Use existing dragon stat calculation system)

---

## DATA STRUCTURE

### Training Slot Class
```gdscript
class_name TrainingSlot extends Resource

@export var slot_id: int
@export var is_unlocked: bool = false
@export var assigned_dragon: Dragon = null
@export var training_start_time: int = 0  # Unix timestamp
@export var training_duration: int = 0    # Total seconds needed

func is_occupied() -> bool:
    return assigned_dragon != null

func get_progress() -> float:
    if not is_occupied():
        return 0.0
    var current_time = Time.get_unix_time_from_system()
    var elapsed = current_time - training_start_time
    return clamp(float(elapsed) / float(training_duration), 0.0, 1.0)

func get_time_remaining() -> int:
    if not is_occupied():
        return 0
    var current_time = Time.get_unix_time_from_system()
    var elapsed = current_time - training_start_time
    var remaining = training_duration - elapsed
    return max(0, remaining)

func is_training_complete() -> bool:
    return is_occupied() and get_time_remaining() <= 0

func assign_dragon(dragon: Dragon, trainer_bonus: bool = false):
    assigned_dragon = dragon
    training_start_time = Time.get_unix_time_from_system()
    
    # Calculate training duration
    var base_duration = _calculate_training_time(dragon.level)
    training_duration = base_duration if not trainer_bonus else int(base_duration * 0.5)
    
    dragon.is_training = true  # Mark dragon as unavailable

func _calculate_training_time(current_level: int) -> int:
    # Base: 2 hours for Lv1→2, scales by 1.5x per level
    var base_seconds = 7200  # 2 hours
    return int(base_seconds * pow(1.5, current_level - 1))

func remove_dragon() -> Dragon:
    var dragon = assigned_dragon
    if dragon:
        dragon.is_training = false
    assigned_dragon = null
    training_start_time = 0
    training_duration = 0
    return dragon

func collect_trained_dragon() -> Dragon:
    if not is_training_complete():
        return null
    
    var dragon = assigned_dragon
    dragon.level += 1
    dragon.calculate_stats()  # Recalculate with new level
    dragon.is_training = false
    
    assigned_dragon = null
    training_start_time = 0
    training_duration = 0
    
    return dragon
```

---

### Training Manager Singleton
```gdscript
class_name TrainingManager extends Node

signal slot_unlocked(slot_id: int)
signal dragon_assigned(slot_id: int, dragon: Dragon)
signal dragon_removed(slot_id: int, dragon: Dragon)
signal training_completed(slot_id: int, dragon: Dragon)
signal dragon_collected(dragon: Dragon, new_level: int)

const MAX_SLOTS = 10
const STARTING_SLOTS = 2
const EXPANSION_COSTS = [0, 0, 500, 1000, 2000, 4000, 4000, 4000, 4000, 4000]

var training_slots: Array[TrainingSlot] = []
var trainer_assigned: bool = false

func _ready():
    _initialize_slots()
    # Check for completed training every second
    var timer = Timer.new()
    timer.timeout.connect(_check_completed_training)
    timer.wait_time = 1.0
    timer.autostart = true
    add_child(timer)

func _initialize_slots():
    for i in range(MAX_SLOTS):
        var slot = TrainingSlot.new()
        slot.slot_id = i
        slot.is_unlocked = (i < STARTING_SLOTS)
        training_slots.append(slot)

func get_slot(slot_id: int) -> TrainingSlot:
    if slot_id >= 0 and slot_id < training_slots.size():
        return training_slots[slot_id]
    return null

func get_unlocked_slots() -> Array[TrainingSlot]:
    return training_slots.filter(func(slot): return slot.is_unlocked)

func get_occupied_count() -> int:
    return get_unlocked_slots().filter(func(slot): return slot.is_occupied()).size()

func get_capacity() -> int:
    return get_unlocked_slots().size()

func get_expansion_cost(slot_id: int) -> int:
    if slot_id >= 0 and slot_id < EXPANSION_COSTS.size():
        return EXPANSION_COSTS[slot_id]
    return 0

func get_next_expansion_slot() -> int:
    for i in range(training_slots.size()):
        if not training_slots[i].is_unlocked:
            return i
    return -1

func can_expand() -> bool:
    return get_next_expansion_slot() >= 0

func expand_slot(slot_id: int) -> bool:
    if slot_id < 0 or slot_id >= training_slots.size():
        return false
    if training_slots[slot_id].is_unlocked:
        return false
    
    training_slots[slot_id].is_unlocked = true
    slot_unlocked.emit(slot_id)
    return true

func assign_dragon_to_slot(slot_id: int, dragon: Dragon) -> bool:
    var slot = get_slot(slot_id)
    if not slot or not slot.is_unlocked or slot.is_occupied():
        return false
    
    slot.assign_dragon(dragon, trainer_assigned)
    dragon_assigned.emit(slot_id, dragon)
    return true

func remove_dragon_from_slot(slot_id: int) -> Dragon:
    var slot = get_slot(slot_id)
    if not slot or not slot.is_occupied():
        return null
    
    var dragon = slot.remove_dragon()
    dragon_removed.emit(slot_id, dragon)
    return dragon

func collect_from_slot(slot_id: int) -> Dragon:
    var slot = get_slot(slot_id)
    if not slot or not slot.is_training_complete():
        return null
    
    var old_level = slot.assigned_dragon.level
    var dragon = slot.collect_trained_dragon()
    dragon_collected.emit(dragon, dragon.level)
    return dragon

func collect_all_completed() -> Array[Dragon]:
    var collected = []
    for slot in get_unlocked_slots():
        if slot.is_training_complete():
            var dragon = collect_from_slot(slot.slot_id)
            if dragon:
                collected.append(dragon)
    return collected

func get_completed_count() -> int:
    return get_unlocked_slots().filter(func(slot): return slot.is_training_complete()).size()

func set_trainer_assigned(assigned: bool):
    trainer_assigned = assigned
    # Recalculate all active training times
    for slot in get_unlocked_slots():
        if slot.is_occupied() and not slot.is_training_complete():
            var progress = slot.get_progress()
            var base_duration = slot._calculate_training_time(slot.assigned_dragon.level)
            slot.training_duration = base_duration if not trainer_assigned else int(base_duration * 0.5)
            # Adjust start time to maintain progress percentage
            var current_time = Time.get_unix_time_from_system()
            slot.training_start_time = current_time - int(slot.training_duration * progress)

func _check_completed_training():
    for slot in get_unlocked_slots():
        if slot.is_training_complete():
            training_completed.emit(slot.slot_id, slot.assigned_dragon)

func to_save_dict() -> Dictionary:
    var slots_data = []
    for slot in training_slots:
        slots_data.append({
            "id": slot.slot_id,
            "unlocked": slot.is_unlocked,
            "dragon_id": slot.assigned_dragon.dragon_id if slot.assigned_dragon else "",
            "start_time": slot.training_start_time,
            "duration": slot.training_duration
        })
    
    return {
        "slots": slots_data,
        "trainer_assigned": trainer_assigned
    }

func load_from_dict(data: Dictionary):
    # Restore training state from save data
    # Match dragons by ID and restore timers
    pass
```

---

## UI IMPLEMENTATION

### LAYOUT DESIGN - Training Yard Screen

**Scene Structure:**
```
TrainingYardUI (Control)
├── MarginContainer
│   └── VBoxContainer
│       ├── HeaderPanel
│       │   ├── TitleLabel ("TRAINING YARD")
│       │   └── HBoxContainer
│       │       ├── TrainerStatusLabel
│       │       └── SpeedBonusLabel
│       ├── ScrollContainer (horizontal scroll)
│       │   └── HBoxContainer (slot_container)
│       │       ├── TrainingSlotCard (x2 unlocked)
│       │       ├── ExpansionCard
│       │       └── LockedSlotCard (x7 locked)
│       └── FooterPanel
│           └── HBoxContainer
│               ├── CollectAllButton
│               ├── AutoRotateButton (if trainer assigned)
│               └── CapacityLabel
```

**Visual Layout:**
```
╔════════════════════════════════════════════════════════════╗
║                   TRAINING YARD                            ║
╠════════════════════════════════════════════════════════════╣
║  Trainer: Dr. Scales ✓          Training Speed: +50%       ║
║                                                            ║
║  [Slot 1]    [Slot 2]    [Slot 3]    [+Expand]   [Locked] ║
║  ┌───────┐  ┌───────┐  ┌───────┐   ┌───────┐            ║
║  │  🐉   │  │  🐉   │  │ Empty │   │   +   │    🔒      ║
║  │Pyro   │  │Volt   │  │       │   │ Expand│            ║
║  │Lv 4   │  │Lv 2   │  │       │   │ Slot  │            ║
║  ├───────┤  ├───────┤  ├───────┤   ├───────┤            ║
║  │▓▓▓▓░░ │  │▓▓░░░░ │  │ Drag  │   │       │            ║
║  │  70%  │  │  30%  │  │Dragon │   │ 500g  │            ║
║  │→ Lv 5 │  │→ Lv 3 │  │ Here  │   │       │            ║
║  ├───────┤  ├───────┤  ├───────┤   ├───────┤            ║
║  │Gains: │  │Gains: │  │       │   │[BUILD]│            ║
║  │ATK +5 │  │ATK +3 │  │       │   └───────┘            ║
║  │HP +15 │  │HP +10 │  │       │                        ║
║  │SPD +2 │  │SPD +1 │  │       │                        ║
║  ├───────┤  ├───────┤  ├───────┤                        ║
║  │⏱ 2h15m│  │⏱ 5h42m│  │       │                        ║
║  │[Remove]│ │[Remove]│ │[Assign]│                        ║
║  │[Rush] │  │[Rush] │  └───────┘                        ║
║  └───────┘  └───────┘                                    ║
║                                                            ║
║  [Collect All Ready: 0] [Auto-Rotate]  Capacity: 2/10     ║
╚════════════════════════════════════════════════════════════╝
```

---

### TRAINING SLOT CARD COMPONENT

**File: `training_slot_card.tscn` + `training_slot_card.gd`**
```gdscript
extends PanelContainer
class_name TrainingSlotCard

@onready var dragon_portrait = $VBox/DragonPortrait
@onready var dragon_name_label = $VBox/DragonName
@onready var level_label = $VBox/LevelLabel
@onready var progress_bar = $VBox/ProgressBar
@onready var progress_label = $VBox/ProgressLabel
@onready var target_level_label = $VBox/TargetLevelLabel
@onready var stats_container = $VBox/StatsGains
@onready var timer_label = $VBox/TimerLabel
@onready var remove_button = $VBox/RemoveButton
@onready var rush_button = $VBox/RushButton
@onready var assign_button = $VBox/AssignButton
@onready var collect_button = $VBox/CollectButton

var slot: TrainingSlot
var slot_id: int

signal dragon_removed(slot_id: int)
signal dragon_assigned_clicked(slot_id: int)
signal dragon_collected(slot_id: int)
signal rush_clicked(slot_id: int)

func setup(training_slot: TrainingSlot):
    slot = training_slot
    slot_id = slot.slot_id
    _update_display()

func _process(_delta):
    if slot and slot.is_occupied():
        _update_progress()

func _update_display():
    if not slot.is_occupied():
        _show_empty_state()
    elif slot.is_training_complete():
        _show_ready_state()
    else:
        _show_training_state()

func _show_empty_state():
    dragon_portrait.visible = false
    dragon_name_label.visible = false
    level_label.visible = false
    progress_bar.visible = false
    progress_label.visible = false
    target_level_label.visible = false
    stats_container.visible = false
    timer_label.visible = false
    remove_button.visible = false
    rush_button.visible = false
    collect_button.visible = false
    
    assign_button.visible = true
    assign_button.text = "Assign Dragon"

func _show_training_state():
    var dragon = slot.assigned_dragon
    
    dragon_portrait.visible = true
    dragon_name_label.visible = true
    dragon_name_label.text = dragon.dragon_name
    
    level_label.visible = true
    level_label.text = "Lv %d" % dragon.level
    
    target_level_label.visible = true
    target_level_label.text = "→ Lv %d" % (dragon.level + 1)
    
    progress_bar.visible = true
    progress_label.visible = true
    
    stats_container.visible = true
    _update_stat_gains(dragon)
    
    timer_label.visible = true
    remove_button.visible = true
    rush_button.visible = true
    
    assign_button.visible = false
    collect_button.visible = false
    
    _update_progress()

func _show_ready_state():
    _show_training_state()
    
    remove_button.visible = false
    rush_button.visible = false
    timer_label.text = "READY!"
    timer_label.add_theme_color_override("font_color", Color.GOLD)
    
    collect_button.visible = true
    collect_button.text = "Collect"
    
    # Add glow/pulse effect
    modulate = Color(1.2, 1.2, 1.0)  # Slight yellow tint

func _update_progress():
    var progress = slot.get_progress()
    progress_bar.value = progress * 100
    progress_label.text = "%d%%" % int(progress * 100)
    
    var remaining = slot.get_time_remaining()
    timer_label.text = _format_time(remaining)

func _update_stat_gains(dragon: Dragon):
    # Show what stats will be gained at next level
    # This depends on your dragon stat calculation system
    var atk_gain = 5  # Base gain, adjust based on dragon parts
    var hp_gain = 15
    var spd_gain = 2
    
    stats_container.get_node("ATKLabel").text = "ATK +%d" % atk_gain
    stats_container.get_node("HPLabel").text = "HP +%d" % hp_gain
    stats_container.get_node("SPDLabel").text = "SPD +%d" % spd_gain

func _format_time(seconds: int) -> String:
    var hours = seconds / 3600
    var minutes = (seconds % 3600) / 60
    var secs = seconds % 60
    
    if hours > 0:
        return "%dh %dm" % [hours, minutes]
    elif minutes > 0:
        return "%dm %ds" % [minutes, secs]
    else:
        return "%ds" % secs

func _on_remove_button_pressed():
    dragon_removed.emit(slot_id)

func _on_assign_button_pressed():
    dragon_assigned_clicked.emit(slot_id)

func _on_collect_button_pressed():
    dragon_collected.emit(slot_id)

func _on_rush_button_pressed():
    rush_clicked.emit(slot_id)
```

---

### EXPANSION CARD COMPONENT

**File: `expansion_card.tscn` + `expansion_card.gd`**
```gdscript
extends PanelContainer
class_name ExpansionCard

@onready var cost_label = $VBox/CostLabel
@onready var expand_button = $VBox/ExpandButton
@onready var icon = $VBox/Icon

var slot_id: int
var cost: int

signal expand_clicked(slot_id: int)

func setup(expansion_slot_id: int, expansion_cost: int):
    slot_id = expansion_slot_id
    cost = expansion_cost
    
    cost_label.text = "Cost: %dg" % cost
    expand_button.disabled = GameState.gold < cost  # Adjust to your gold system
    
    icon.text = "+"
    expand_button.text = "EXPAND"

func _on_expand_button_pressed():
    expand_clicked.emit(slot_id)
```

---

### LOCKED SLOT CARD COMPONENT

**File: `locked_slot_card.tscn` + `locked_slot_card.gd`**
```gdscript
extends PanelContainer
class_name LockedSlotCard

@onready var lock_icon = $VBox/LockIcon
@onready var locked_label = $VBox/LockedLabel

func setup(slot_number: int):
    lock_icon.text = "🔒"
    locked_label.text = "LOCKED"
    
    # Gray out appearance
    modulate = Color(0.5, 0.5, 0.5)
```

---

### MAIN TRAINING YARD UI

**File: `training_yard_ui.tscn` + `training_yard_ui.gd`**
```gdscript
extends Control
class_name TrainingYardUI

const TrainingSlotCardScene = preload("res://scenes/ui/training_slot_card.tscn")
const ExpansionCardScene = preload("res://scenes/ui/expansion_card.tscn")
const LockedSlotCardScene = preload("res://scenes/ui/locked_slot_card.tscn")

@onready var slot_container = $Margin/VBox/Scroll/SlotContainer
@onready var trainer_status_label = $Margin/VBox/Header/TrainerStatus
@onready var speed_bonus_label = $Margin/VBox/Header/SpeedBonus
@onready var collect_all_button = $Margin/VBox/Footer/CollectAllButton
@onready var auto_rotate_button = $Margin/VBox/Footer/AutoRotateButton
@onready var capacity_label = $Margin/VBox/Footer/CapacityLabel

var training_manager: TrainingManager

func _ready():
    training_manager = get_node("/root/TrainingManager")  # Adjust path
    _connect_signals()
    _populate_slots()
    _update_header()
    _update_footer()

func _connect_signals():
    training_manager.slot_unlocked.connect(_on_slot_unlocked)
    training_manager.dragon_assigned.connect(_on_dragon_assigned)
    training_manager.dragon_removed.connect(_on_dragon_removed)
    training_manager.training_completed.connect(_on_training_completed)
    training_manager.dragon_collected.connect(_on_dragon_collected)

func _populate_slots():
    # Clear existing cards
    for child in slot_container.get_children():
        child.queue_free()
    
    # Add slot cards
    for i in range(TrainingManager.MAX_SLOTS):
        var slot = training_manager.get_slot(i)
        
        if slot.is_unlocked:
            # Unlocked training slot
            var card = TrainingSlotCardScene.instantiate()
            card.setup(slot)
            card.dragon_removed.connect(_on_card_remove_clicked)
            card.dragon_assigned_clicked.connect(_on_card_assign_clicked)
            card.dragon_collected.connect(_on_card_collect_clicked)
            card.rush_clicked.connect(_on_card_rush_clicked)
            slot_container.add_child(card)
            
        elif i == training_manager.get_next_expansion_slot():
            # Next expansion slot
            var expansion_card = ExpansionCardScene.instantiate()
            var cost = training_manager.get_expansion_cost(i)
            expansion_card.setup(i, cost)
            expansion_card.expand_clicked.connect(_on_expansion_clicked)
            slot_container.add_child(expansion_card)
            
        else:
            # Locked slot
            var locked_card = LockedSlotCardScene.instantiate()
            locked_card.setup(i)
            slot_container.add_child(locked_card)

func _update_header():
    # Update trainer status
    if training_manager.trainer_assigned:
        trainer_status_label.text = "Trainer: Dr. Scales ✓"
        speed_bonus_label.text = "Training Speed: +50%"
        speed_bonus_label.add_theme_color_override("font_color", Color.GREEN)
    else:
        trainer_status_label.text = "Trainer: None"
        speed_bonus_label.text = "Hire Trainer for +50% speed"
        speed_bonus_label.add_theme_color_override("font_color", Color.GRAY)

func _update_footer():
    var completed = training_manager.get_completed_count()
    collect_all_button.text = "Collect All Ready: %d" % completed
    collect_all_button.disabled = completed == 0
    
    auto_rotate_button.visible = training_manager.trainer_assigned
    
    var occupied = training_manager.get_occupied_count()
    var capacity = training_manager.get_capacity()
    capacity_label.text = "Capacity: %d/%d" % [occupied, capacity]

func _on_card_assign_clicked(slot_id: int):
    # Open dragon selection dialog
    # This depends on your existing dragon management UI
    # For now, stub it:
    print("Open dragon selector for slot %d" % slot_id)
    # Example: DragonSelectorDialog.show(slot_id)

func _on_card_remove_clicked(slot_id: int):
    var dragon = training_manager.remove_dragon_from_slot(slot_id)
    if dragon:
        _refresh_slot_card(slot_id)
        _update_footer()

func _on_card_collect_clicked(slot_id: int):
    var dragon = training_manager.collect_from_slot(slot_id)
    if dragon:
        # Show level up notification
        _show_level_up_popup(dragon)
        _refresh_slot_card(slot_id)
        _update_footer()

func _on_card_rush_clicked(slot_id: int):
    # Implement rush/speed-up with gold
    # Cost: 50g to instantly complete
    var rush_cost = 50
    if GameState.gold >= rush_cost:
        GameState.gold -= rush_cost
        var slot = training_manager.get_slot(slot_id)
        # Set training to complete
        slot.training_start_time = Time.get_unix_time_from_system() - slot.training_duration
        _refresh_slot_card(slot_id)

func _on_expansion_clicked(slot_id: int):
    var cost = training_manager.get_expansion_cost(slot_id)
    if GameState.gold >= cost:
        GameState.gold -= cost
        training_manager.expand_slot(slot_id)
        _populate_slots()  # Rebuild UI
        _update_footer()

func _on_collect_all_pressed():
    var collected = training_manager.collect_all_completed()
    if collected.size() > 0:
        _show_batch_level_up_popup(collected)
        _populate_slots()
        _update_footer()

func _on_auto_rotate_pressed():
    # Implement auto-rotation logic
    # Trainer automatically fills empty slots with idle dragons
    pass

func _on_slot_unlocked(slot_id: int):
    _populate_slots()

func _on_dragon_assigned(slot_id: int, dragon: Dragon):
    _refresh_slot_card(slot_id)
    _update_footer()

func _on_dragon_removed(slot_id: int, dragon: Dragon):
    _refresh_slot_card(slot_id)
    _update_footer()

func _on_training_completed(slot_id: int, dragon: Dragon):
    _refresh_slot_card(slot_id)
    _update_footer()
    # Optional: Play notification sound
    # Optional: Show toast notification

func _on_dragon_collected(dragon: Dragon, new_level: int):
    _update_footer()

func _refresh_slot_card(slot_id: int):
    # Find and update specific card without rebuilding everything
    var cards = slot_container.get_children()
    for card in cards:
        if card is TrainingSlotCard and card.slot_id == slot_id:
            card.setup(training_manager.get_slot(slot_id))
            break

func _show_level_up_popup(dragon: Dragon):
    # Show celebratory popup
    # "Pyrofrost reached Level 5!"
    # Display stat gains
    # Play fanfare sound
    pass

func _show_batch_level_up_popup(dragons: Array[Dragon]):
    # Show popup for multiple dragons
    # "3 dragons completed training!"
    pass
```

---

## INTEGRATION REQUIREMENTS

### 1. Dragon Class Modifications

Add to your existing Dragon class:
```gdscript
# In dragon.gd
@export var is_training: bool = false

func can_be_assigned_to_training() -> bool:
    return not is_training and not is_defending and not is_exploring
```

### 2. Scientist Integration

When Trainer is hired/assigned:
```gdscript
# When trainer assigned
TrainingManager.set_trainer_assigned(true)

# When trainer unassigned/fired
TrainingManager.set_trainer_assigned(false)
```

### 3. Save/Load Integration

Add to your save system:
```gdscript
# When saving
save_data["training_yard"] = TrainingManager.to_save_dict()

# When loading
TrainingManager.load_from_dict(save_data["training_yard"])
```

### 4. UI Navigation

Add Training Yard access point:

**Option A:** Bottom panel tab
```gdscript
# Add to your main UI
[DEFENSE] [EXPLORATION] [TRAINING] [COLLECTION]
```

**Option B:** Left sidebar button
```gdscript
# In scientist panel
FACILITIES
- Training Yard [Click to open]
```

---

## VISUAL POLISH

### Animations

**Dragon enters training:**
- Slide in from left
- Scale up effect
- Particle sparkles

**Progress filling:**
- Smooth bar animation
- Pulse effect at 25/50/75/100%
- Color shift: blue → green → gold

**Training complete:**
- Gold glow pulse
- Bounce animation
- Confetti particles
- Sound: Victory fanfare

**Level up collected:**
- Dragon card flashes
- "+1 LEVEL" text floats up
- Stat numbers count up
- Sound: Power-up sound

### Color Scheme (Match Your UI)
```css
Background: #1a1a1a (dark)
Card border: #00ff00 (neon green)
Progress bar empty: #333333
Progress bar fill: #00ff00 (green) → #ffaa00 (gold when near complete)
Text: #00ff00 or #ffffff
Buttons: Green border, dark fill
Locked elements: #666666 (gray)
```

### States Visual Feedback

**Empty slot:**
- Dashed green border
- "Drop dragon here" text
- Hover: Brighten border

**Training:**
- Solid green border
- Pulsing glow
- Progress bar animated

**Ready:**
- Gold border
- Glow effect
- Bounce animation

**Locked:**
- Gray/desaturated
- Lock icon
- No interaction

---

## OPTIONAL FEATURES (If Time Permits)

### 1. Training Queue
```gdscript
var training_queue: Array[Dragon] = []

func add_to_queue(dragon: Dragon):
    training_queue.append(dragon)

func process_queue():
    # When slot opens, auto-fill from queue
    for slot in get_unlocked_slots():
        if not slot.is_occupied() and training_queue.size() > 0:
            var dragon = training_queue.pop_front()
            assign_dragon_to_slot(slot.slot_id, dragon)
```

### 2. Rush/Speed Up
```gdscript
const RUSH_COST_PER_HOUR = 25  # Gold

func rush_training(slot_id: int) -> int:
    var slot = get_slot(slot_id)
    var remaining_hours = ceil(slot.get_time_remaining() / 3600.0)
    return remaining_hours * RUSH_COST_PER_HOUR
```

### 3. Training Statistics
```gdscript
var total_dragons_trained: int = 0
var total_levels_gained: int = 0
var total_training_time: int = 0  # seconds

func record_training_completion(dragon: Dragon):
    total_dragons_trained += 1
    total_levels_gained += 1
    # Update stats
```

---

## DELIVERABLES

Please provide:

1. **training_slot.gd** - TrainingSlot resource class
2. **training_manager.gd** - TrainingManager singleton
3. **training_slot_card.tscn** - Training slot UI component
4. **training_slot_card.gd** - Slot card script
5. **expansion_card.tscn** - Expansion slot component
6. **expansion_card.gd** - Expansion card script
7. **locked_slot_card.tscn** - Locked slot component  
8. **locked_slot_card.gd** - Locked card script
9. **training_yard_ui.tscn** - Main training yard scene
10. **training_yard_ui.gd** - Main UI controller
11. **README.md** - Integration instructions

**Code Quality:**
- Godot 4 syntax
- Clean, commented code
- Signal-based architecture
- Save/load compatible
- Performance optimized (handle 10 slots smoothly)
- Mobile-friendly layouts

**Make this feel polished for a game jam submission. Training should feel rewarding and satisfying!**