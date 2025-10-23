I'm building a dragon factory idle game in Godot 4. I have the tower data structure already implemented. I need you to create ONLY the UI layer for the Defense Tower system.

## EXISTING BACKEND (Already Built)

I already have these classes working:
```gdscript
# DefenseTower class - already exists
class_name DefenseTower
- tower_id: int
- max_health: int
- current_health: int
- dragon_slots: Array[Dragon] (max 3)
- is_unlocked: bool
- tier: int

# TowerManager singleton - already exists
- towers: Array[DefenseTower]
- get_tower(id: int) -> DefenseTower
- get_unlocked_towers() -> Array[DefenseTower]
- get_next_buildable_tower_index() -> int
- get_build_cost(tower_index: int) -> int
- build_tower(tower_index: int) -> bool
- repair_tower(tower_id: int) -> int
- repair_all_towers() -> int
- get_total_dragon_slots() -> int
- get_occupied_slots() -> int
```

## WHAT I NEED YOU TO BUILD

Create a UI system that displays and manages defense towers using a **horizontal scrollable row layout**.

### UI LAYOUT SPECIFICATION

**Visual Design - Tower Row:**
```
╔════════════════════════════════════════════════════════════════╗
║                    DEFENSE PERIMETER                           ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  [Tower 1]  [Tower 2]  [Tower 3]  [+Build]  [Locked] [Locked] ║
║   ┌─────┐   ┌─────┐   ┌─────┐   ┌─────┐                      ║
║   │ 🏰  │   │ 🏰  │   │ 🏰  │   │  +  │    🔒      🔒        ║
║   ├─────┤   ├─────┤   ├─────┤   └─────┘                      ║
║   │ 🐉  │   │ 🐉  │   │ --- │   250g                          ║
║   │ 🐉  │   │ --- │   │ --- │                                ║
║   │ 🐉  │   │ --- │   │ --- │                                ║
║   ├─────┤   ├─────┤   ├─────┤                                ║
║   │███░│   │████│   │█░░░│                                   ║
║   │100%│   │ 85%│   │ 25%│                                   ║
║   └─────┘   └─────┘   └─────┘                                ║
║            [Repair]  [Repair]                                 ║
║              15g       75g                                     ║
║                                                                ║
║  ← Scroll ──────────────────────────────────────────────→     ║
║                                                                ║
║  [Repair All: 90g]  [Auto-Assign Dragons]  Slots: 8/9        ║
╚════════════════════════════════════════════════════════════════╝
```

---

### 1. TOWER CARD COMPONENT

**File: `tower_card.tscn` + `tower_card.gd`**

Each tower card should display:

**Visual Elements:**
- **Tower sprite/icon** (changes based on tier and damage state)
  - Tier 1: Simple watchtower icon
  - Tier 2-4: Progressively fancier tower sprites
  - Damage overlay: Clean → Cracked → Heavily damaged
  
- **Dragon slots** (3 slots per tower)
  - If dragon assigned: Show mini dragon portrait/icon
  - If empty: Show empty slot (dashed border)
  - Clickable to assign/unassign dragons
  
- **Health bar**
  - Visual bar showing current_health/max_health
  - Color coded:
    - Green: 100-70%
    - Yellow: 69-30%
    - Red: 29-1%
    - Gray: 0% (destroyed)
  - Percentage text below bar
  
- **Repair button** (conditional)
  - Only shows if current_health < max_health
  - Displays repair cost
  - Button states:
    - Normal: Can afford repair
    - Disabled: Cannot afford (show in red/gray)
    - Hidden: Tower at full health

**Tower Card States:**

**Unlocked Tower:**
```
┌─────────────┐
│    🏰       │ ← Tower sprite
├─────────────┤
│  🐉 🐉 --   │ ← Dragon slots (2/3 filled)
├─────────────┤
│ ████████░░  │ ← Health bar
│    85%      │ ← Health percentage
├─────────────┤
│ [Repair 15g]│ ← Repair button (if damaged)
└─────────────┘
```

**Build Slot (Next unlockable tower):**
```
┌─────────────┐
│      +      │
│             │
│  BUILD NEW  │
│   TOWER     │
│             │
│   Cost:     │
│   250g      │
│             │
│   [BUILD]   │
└─────────────┘
```

**Locked Tower:**
```
┌─────────────┐
│     🔒      │
│             │
│   LOCKED    │
│             │
│  Unlocks    │
│  after      │
│  Tower 4    │
│             │
└─────────────┘
```

**Code Structure:**
```gdscript
extends PanelContainer
class_name TowerCard

@onready var tower_sprite = $VBox/TowerSprite
@onready var dragon_slot_1 = $VBox/DragonSlots/Slot1
@onready var dragon_slot_2 = $VBox/DragonSlots/Slot2
@onready var dragon_slot_3 = $VBox/DragonSlots/Slot3
@onready var health_bar = $VBox/HealthBar
@onready var health_label = $VBox/HealthLabel
@onready var repair_button = $VBox/RepairButton

var tower: DefenseTower
var tower_id: int

signal dragon_slot_clicked(tower_id: int, slot_index: int)
signal repair_clicked(tower_id: int)

func setup(tower_data: DefenseTower):
    tower = tower_data
    tower_id = tower.tower_id
    _update_display()

func _update_display():
    # Update tower sprite based on tier and damage
    # Update dragon slots
    # Update health bar
    # Show/hide repair button
    # Update repair cost
    pass

func _on_repair_button_pressed():
    repair_clicked.emit(tower_id)

func _on_dragon_slot_clicked(slot_index: int):
    dragon_slot_clicked.emit(tower_id, slot_index)
```

---

### 2. MAIN DEFENSE UI CONTAINER

**File: `defense_towers_ui.tscn` + `defense_towers_ui.gd`**

**Scene Structure:**
```
DefenseTowersUI (Control)
├── MarginContainer
│   └── VBoxContainer
│       ├── HeaderPanel
│       │   └── Label ("DEFENSE PERIMETER")
│       ├── ScrollContainer (horizontal scroll enabled)
│       │   └── HBoxContainer (tower_card_container)
│       │       ├── TowerCard (instance)
│       │       ├── TowerCard (instance)
│       │       ├── BuildCard (instance)
│       │       └── LockedCard (instances)
│       └── FooterPanel
│           └── HBoxContainer
│               ├── RepairAllButton
│               ├── AutoAssignButton
│               └── StatsLabel ("Slots: 8/15")
```

**Main UI Script:**
```gdscript
extends Control
class_name DefenseTowersUI

const TowerCardScene = preload("res://scenes/ui/tower_card.tscn")
const BuildCardScene = preload("res://scenes/ui/build_card.tscn")
const LockedCardScene = preload("res://scenes/ui/locked_card.tscn")

@onready var tower_container = $Margin/VBox/Scroll/TowerContainer
@onready var repair_all_button = $Margin/VBox/Footer/RepairAllButton
@onready var auto_assign_button = $Margin/VBox/Footer/AutoAssignButton
@onready var stats_label = $Margin/VBox/Footer/StatsLabel

var tower_manager: TowerManager

func _ready():
    tower_manager = get_node("/root/TowerManager") # Adjust path to your singleton
    _populate_towers()
    _connect_signals()
    _update_footer()

func _populate_towers():
    # Clear existing cards
    for child in tower_container.get_children():
        child.queue_free()
    
    # Add tower cards for each tower
    for i in range(TowerManager.MAX_TOWERS):
        var tower = tower_manager.get_tower(i)
        
        if tower.is_unlocked:
            # Create unlocked tower card
            var card = TowerCardScene.instantiate()
            card.setup(tower)
            card.dragon_slot_clicked.connect(_on_dragon_slot_clicked)
            card.repair_clicked.connect(_on_repair_clicked)
            tower_container.add_child(card)
            
        elif i == tower_manager.get_next_buildable_tower_index():
            # Create build card
            var build_card = BuildCardScene.instantiate()
            build_card.setup(i, tower_manager.get_build_cost(i))
            build_card.build_clicked.connect(_on_build_clicked)
            tower_container.add_child(build_card)
            
        else:
            # Create locked card
            var locked_card = LockedCardScene.instantiate()
            locked_card.setup(i)
            tower_container.add_child(locked_card)

func _on_dragon_slot_clicked(tower_id: int, slot_index: int):
    # Open dragon assignment dialog
    # Or trigger dragon selection mode
    print("Assign dragon to tower %d, slot %d" % [tower_id, slot_index])

func _on_repair_clicked(tower_id: int):
    var cost = tower_manager.towers[tower_id].get_repair_cost()
    if GameState.gold >= cost: # Adjust to your game state manager
        GameState.gold -= cost
        tower_manager.repair_tower(tower_id)
        _refresh_tower_card(tower_id)
        _update_footer()

func _on_build_clicked(tower_index: int):
    var cost = tower_manager.get_build_cost(tower_index)
    if GameState.gold >= cost:
        if tower_manager.build_tower(tower_index):
            GameState.gold -= cost
            _populate_towers() # Rebuild UI
            _update_footer()

func _on_repair_all_pressed():
    var total_cost = tower_manager.repair_all_towers()
    if GameState.gold >= total_cost:
        GameState.gold -= total_cost
        _populate_towers()
        _update_footer()

func _on_auto_assign_pressed():
    # Call your auto-assign dragon logic
    tower_manager.auto_assign_dragons()
    _populate_towers()

func _update_footer():
    var total_slots = tower_manager.get_total_dragon_slots()
    var occupied = tower_manager.get_occupied_slots()
    stats_label.text = "Slots: %d/%d" % [occupied, total_slots]
    
    var repair_cost = tower_manager.get_total_repair_cost()
    if repair_cost > 0:
        repair_all_button.text = "Repair All: %dg" % repair_cost
        repair_all_button.disabled = GameState.gold < repair_cost
        repair_all_button.visible = true
    else:
        repair_all_button.visible = false

func _refresh_tower_card(tower_id: int):
    # Find and update specific tower card without rebuilding everything
    var cards = tower_container.get_children()
    for card in cards:
        if card is TowerCard and card.tower_id == tower_id:
            card.setup(tower_manager.get_tower(tower_id))
            break
```

---

### 3. BUILD TOWER CARD

**File: `build_card.tscn` + `build_card.gd`**
```gdscript
extends PanelContainer
class_name BuildCard

@onready var cost_label = $VBox/CostLabel
@onready var build_button = $VBox/BuildButton

var tower_index: int
var cost: int

signal build_clicked(tower_index: int)

func setup(index: int, build_cost: int):
    tower_index = index
    cost = build_cost
    cost_label.text = "Cost: %dg" % cost
    build_button.disabled = GameState.gold < cost

func _on_build_button_pressed():
    build_clicked.emit(tower_index)
```

---

### 4. VISUAL POLISH REQUIREMENTS

**Color Scheme:**
- Background: Dark gray/brown (gothic lab aesthetic)
- Tower cards: Stone texture or solid panel
- Health bars: Standard traffic light colors
- Damaged towers: Red tint/overlay
- Locked towers: Desaturated, darkened

**Hover Effects:**
- Tower cards: Slight scale up (1.05x)
- Buttons: Brightness increase
- Tooltips: Show detailed tower stats

**Animations:**
- Tower takes damage: Shake effect + red flash
- Tower repaired: Green glow pulse
- New tower built: Scale up from 0 with particle effect
- Dragon assigned: Slide in from side

**Responsive Design:**
- Works at 1920x1080 (desktop)
- Works at 1280x720 (smaller screens)
- Mobile: Ensure cards are large enough for touch (min 100px wide)

---

### 5. INTEGRATION REQUIREMENTS

**Connect to existing systems:**
- Read tower data from `TowerManager` singleton
- Deduct gold from `GameState.gold` (or your equivalent)
- Trigger dragon assignment dialog/system (stub this if not built yet)
- Listen for tower damage events and update UI in real-time

**Signals to handle:**
```gdscript
# Listen to TowerManager signals
tower_manager.tower_damaged.connect(_on_tower_damaged)
tower_manager.tower_repaired.connect(_on_tower_repaired)
tower_manager.tower_built.connect(_on_tower_built)
tower_manager.tower_destroyed.connect(_on_tower_destroyed)
```

---

### 6. OPTIONAL FEATURES (If Time Permits)

**Tooltip System:**
- Hover over tower: Show detailed stats
  - Current HP / Max HP
  - Assigned dragons list
  - Damage taken this session
  - Total defenses won

**Context Menu:**
- Right-click tower: Quick actions
  - Repair
  - Unassign all dragons
  - View tower history

**Batch Operations:**
- Select multiple towers
- Repair selected
- Mass unassign

---

## DELIVERABLES

Please provide:

1. **tower_card.tscn** - Tower card scene
2. **tower_card.gd** - Tower card script with all logic
3. **build_card.tscn** - Build tower card scene
4. **build_card.gd** - Build card script
5. **locked_card.tscn** - Locked tower card scene
6. **locked_card.gd** - Locked card script
7. **defense_towers_ui.tscn** - Main UI container
8. **defense_towers_ui.gd** - Main UI script with all connections
9. **README.md** - Integration instructions

**Code Quality:**
- Clean, commented code
- Signal-based architecture (loose coupling)
- Godot 4 syntax
- Responsive layout (anchors/containers)
- Performance: Handle 15 towers without lag

**Visual Assets Needed (I'll provide or you can placeholder):**
- Tower sprites (4 tiers)
- Damaged tower overlays
- Dragon slot icons
- Lock icon
- Plus icon for build
- Health bar texture (optional)

Make this feel polished and professional for a game jam. The UI should be intuitive and satisfying to interact with.