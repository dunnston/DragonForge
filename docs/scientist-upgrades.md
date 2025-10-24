I'm building a dragon factory idle game in Godot 4. I need you to implement a scientist upgrade system with 3 scientists, each having 5 upgrade tiers that unlock new automation abilities.

## GAME CONTEXT

**Scientist System Overview:**
- 3 Scientists: Stitcher, Caretaker, Trainer
- Each has 5 upgrade tiers (levels)
- Each tier unlocks a new automation ability (not speed boosts)
- Higher tiers cost more gold and have higher salaries per wave
- Salaries are paid every knight wave (every 5 minutes)
- Scientists work automatically in the background
- Perfect for AFK/idle gameplay

**Core Philosophy:**
- Simple boolean flags per tier (not complex percentages)
- Each tier adds ONE clear new ability
- Easy to understand what each upgrade does
- Focus on automation quality-of-life improvements

---

## SCIENTIST SPECIFICATIONS

### **1. STITCHER (Creation & Deployment Specialist)**

**Role:** Handles dragon creation and job assignments

| Tier | Name | Hire Cost | Salary/Wave | Unlock Requirement | New Ability |
|------|------|-----------|-------------|-------------------|-------------|
| 0 | Not Hired | - | - | - | - |
| 1 | Apprentice Stitcher | 500g | 10g | Available from start | Auto-creates dragons from parts |
| 2 | Journeyman Stitcher | 1,500g | 20g | 25 waves defeated | + Auto-assigns created dragons to defense |
| 3 | Master Stitcher | 5,000g | 40g | 50 waves defeated | + Auto-sends excess idle dragons exploring |
| 4 | Grand Stitcher | 15,000g | 75g | 100 waves defeated | + Auto-recalls explorers when defense needs help |
| 5 | Legendary Stitcher | 50,000g | 150g | 200 waves defeated | + Auto-freezes recovered parts before decay |

**Automation Logic:**

**Tier 1:** 
- Checks if 3+ parts available
- Creates dragon automatically
- Dragon becomes idle

**Tier 2:**
- After creating dragon, checks defense towers
- If empty defense slot exists → Assigns dragon there
- If no slots → Dragon stays idle

**Tier 3:**
- If dragon is idle AND defense is full (all slots occupied)
- Sends dragon on exploration (shortest duration expedition)
- Only explores if defense is already covered

**Tier 4:**
- Monitors defense status during waves
- If dragon dies defending OR tower destroyed
- Recalls nearest exploring dragon early (gets partial rewards)
- Reassigns to defense immediately
- Emergency defense response system

**Tier 5:**
- Monitors recovered parts inventory
- If part has < 6 hours until decay
- Automatically moves to first available freezer slot
- Prevents part loss from decay

---

### **2. CARETAKER (Health & Welfare Specialist)**

**Role:** Maintains dragon health and wellbeing

| Tier | Name | Hire Cost | Salary/Wave | Unlock Requirement | New Ability |
|------|------|-----------|-------------|-------------------|-------------|
| 0 | Not Hired | - | - | - | - |
| 1 | Apprentice Caretaker | 400g | 8g | Available from start | Auto-feeds hungry dragons |
| 2 | Experienced Caretaker | 1,200g | 16g | 25 waves defeated | + Auto-heals damaged dragons |
| 3 | Master Caretaker | 4,000g | 32g | 50 waves defeated | + Auto-rests fatigued dragons |
| 4 | Grand Caretaker | 12,000g | 60g | 100 waves defeated | + Prevents starvation deaths |
| 5 | Tower Guardian | 40,000g | 120g | 200 waves defeated | + Auto-repairs damaged towers |

**Automation Logic:**

**Tier 1:**
- Checks all dragons (defending, exploring, training, idle)
- If hunger < 50% → Feeds dragon
- Uses food from inventory (costs gold)

**Tier 2:**
- Checks all dragons
- If HP < 75% of max HP → Heals dragon
- Costs gold per heal

**Tier 3:**
- Checks defending dragons only
- If fatigue > 70% → Unassigns from defense tower
- Dragon returns to idle pool to rest
- Fatigue decreases while resting

**Tier 4:**
- Always keeps dragon hunger above 20%
- Emergency feeding priority for any dragon below 20%
- Prevents death from starvation
- More aggressive feeding schedule

**Tier 5:**
- Monitors all defense towers
- If tower HP < 50% → Automatically repairs
- Spends gold to restore tower HP
- Prevents tower destruction during waves

---

### **3. TRAINER (Training Yard Specialist)**

**Role:** Manages dragon training and experience gain

| Tier | Name | Hire Cost | Salary/Wave | Unlock Requirement | New Ability |
|------|------|-----------|-------------|-------------------|-------------|
| 0 | Not Hired | - | - | - | - |
| 1 | Apprentice Trainer | 600g | 12g | Available from start | Enables training yard (+50% speed) |
| 2 | Experienced Trainer | 1,800g | 24g | 25 waves defeated | + Auto-fills empty training slots |
| 3 | Master Trainer | 6,000g | 48g | 50 waves defeated | + Auto-collects trained dragons |
| 4 | Grand Master | 18,000g | 90g | 100 waves defeated | + Auto-rotates dragons through training |
| 5 | Legendary Sensei | 60,000g | 180g | 200 waves defeated | + Dragons gain XP while defending/exploring |

**Automation Logic:**

**Tier 1:**
- Enables training yard functionality
- Training speed increased by 50% (2 hours → 1 hour for level up)
- Required to use training at all

**Tier 2:**
- Checks for empty training slots
- Searches idle dragons
- Assigns idle dragons to training automatically
- ONLY takes dragons from idle pool (never pulls from defense/exploration)

**Tier 3:**
- Monitors training slots
- When dragon completes training (reaches next level)
- Automatically collects dragon
- Dragon returns to idle pool

**Tier 4:**
- After collecting trained dragon (Tier 3)
- If dragon is still idle after 10 seconds
- Automatically sends back to training
- Creates continuous training loop

**Tier 5:**
- Dragons gain 10% of normal training XP while defending
- Dragons gain 5% of normal training XP while exploring
- Passive experience system
- Doesn't replace training, just supplements it

---

## DATA STRUCTURE

### **Scientist Class:**

**File: `scientist.gd`**
```gdscript
extends Resource
class_name Scientist

enum Type { STITCHER, CARETAKER, TRAINER }

@export var scientist_type: Type
@export var tier: int = 0  # 0 = not hired, 1-5 = upgrade level
@export var is_hired: bool = false

# Tier definitions
const TIER_DATA = {
    Type.STITCHER: [
        {"name": "Not Hired", "cost": 0, "salary": 0},
        {"name": "Apprentice Stitcher", "cost": 500, "salary": 10},
        {"name": "Journeyman Stitcher", "cost": 1500, "salary": 20},
        {"name": "Master Stitcher", "cost": 5000, "salary": 40},
        {"name": "Grand Stitcher", "cost": 15000, "salary": 75},
        {"name": "Legendary Stitcher", "cost": 50000, "salary": 150}
    ],
    Type.CARETAKER: [
        {"name": "Not Hired", "cost": 0, "salary": 0},
        {"name": "Apprentice Caretaker", "cost": 400, "salary": 8},
        {"name": "Experienced Caretaker", "cost": 1200, "salary": 16},
        {"name": "Master Caretaker", "cost": 4000, "salary": 32},
        {"name": "Grand Caretaker", "cost": 12000, "salary": 60},
        {"name": "Tower Guardian", "cost": 40000, "salary": 120}
    ],
    Type.TRAINER: [
        {"name": "Not Hired", "cost": 0, "salary": 0},
        {"name": "Apprentice Trainer", "cost": 600, "salary": 12},
        {"name": "Experienced Trainer", "cost": 1800, "salary": 24},
        {"name": "Master Trainer", "cost": 6000, "salary": 48},
        {"name": "Grand Master", "cost": 18000, "salary": 90},
        {"name": "Legendary Sensei", "cost": 60000, "salary": 180}
    ]
}

const UNLOCK_REQUIREMENTS = [
    0,   # Tier 0: N/A
    0,   # Tier 1: Available from start
    25,  # Tier 2: 25 waves
    50,  # Tier 3: 50 waves
    100, # Tier 4: 100 waves
    200  # Tier 5: 200 waves
]

func get_tier_name() -> String:
    return TIER_DATA[scientist_type][tier].name

func get_salary() -> int:
    return TIER_DATA[scientist_type][tier].salary

func get_upgrade_cost() -> int:
    if tier >= 5:
        return 0  # Max tier
    return TIER_DATA[scientist_type][tier + 1].cost

func can_upgrade(waves_completed: int) -> bool:
    if tier >= 5:
        return false
    return waves_completed >= UNLOCK_REQUIREMENTS[tier + 1]

# Ability checks for Stitcher
func can_create_dragons() -> bool:
    return scientist_type == Type.STITCHER and tier >= 1

func can_auto_assign_defense() -> bool:
    return scientist_type == Type.STITCHER and tier >= 2

func can_auto_explore() -> bool:
    return scientist_type == Type.STITCHER and tier >= 3

func can_emergency_recall() -> bool:
    return scientist_type == Type.STITCHER and tier >= 4

func can_auto_freeze() -> bool:
    return scientist_type == Type.STITCHER and tier >= 5

# Ability checks for Caretaker
func can_feed() -> bool:
    return scientist_type == Type.CARETAKER and tier >= 1

func can_heal() -> bool:
    return scientist_type == Type.CARETAKER and tier >= 2

func can_rest() -> bool:
    return scientist_type == Type.CARETAKER and tier >= 3

func can_prevent_starvation() -> bool:
    return scientist_type == Type.CARETAKER and tier >= 4

func can_repair_towers() -> bool:
    return scientist_type == Type.CARETAKER and tier >= 5

# Ability checks for Trainer
func enables_training() -> bool:
    return scientist_type == Type.TRAINER and tier >= 1

func can_auto_fill_training() -> bool:
    return scientist_type == Type.TRAINER and tier >= 2

func can_auto_collect_training() -> bool:
    return scientist_type == Type.TRAINER and tier >= 3

func can_auto_rotate() -> bool:
    return scientist_type == Type.TRAINER and tier >= 4

func can_passive_xp() -> bool:
    return scientist_type == Type.TRAINER and tier >= 5

func to_save_dict() -> Dictionary:
    return {
        "type": scientist_type,
        "tier": tier,
        "hired": is_hired
    }

func load_from_dict(data: Dictionary):
    scientist_type = data.type
    tier = data.tier
    is_hired = data.hired
```

---

### **Scientist Manager Singleton:**

**File: `scientist_manager.gd`**
```gdscript
extends Node
class_name ScientistManager

signal scientist_hired(type: Scientist.Type)
signal scientist_upgraded(type: Scientist.Type, new_tier: int)
signal salary_payment_due(total_cost: int)
signal salary_paid(total_cost: int)
signal salary_failed(total_cost: int)

var stitcher: Scientist
var caretaker: Scientist
var trainer: Scientist

# Automation timer
var automation_timer: Timer

func _ready():
    # Initialize scientists
    stitcher = Scientist.new()
    stitcher.scientist_type = Scientist.Type.STITCHER
    
    caretaker = Scientist.new()
    caretaker.scientist_type = Scientist.Type.CARETAKER
    
    trainer = Scientist.new()
    trainer.scientist_type = Scientist.Type.TRAINER
    
    # Setup automation timer (runs every 5 seconds)
    automation_timer = Timer.new()
    automation_timer.timeout.connect(_run_automation_cycle)
    automation_timer.wait_time = 5.0
    automation_timer.autostart = true
    add_child(automation_timer)

# ═══════════════════════════════════════════════════════════
# HIRING & UPGRADING
# ═══════════════════════════════════════════════════════════

func hire_scientist(type: Scientist.Type) -> bool:
    var scientist = _get_scientist(type)
    
    if scientist.is_hired:
        return false  # Already hired
    
    var cost = scientist.get_upgrade_cost()  # Tier 1 cost
    
    if GameState.gold < cost:
        return false
    
    GameState.gold -= cost
    scientist.tier = 1
    scientist.is_hired = true
    
    scientist_hired.emit(type)
    return true

func upgrade_scientist(type: Scientist.Type) -> bool:
    var scientist = _get_scientist(type)
    
    if not scientist.is_hired:
        return false
    
    if scientist.tier >= 5:
        return false  # Max tier
    
    if not scientist.can_upgrade(GameState.waves_completed):
        return false  # Not enough waves
    
    var cost = scientist.get_upgrade_cost()
    
    if GameState.gold < cost:
        return false
    
    GameState.gold -= cost
    scientist.tier += 1
    
    scientist_upgraded.emit(type, scientist.tier)
    return true

func can_afford_scientist(type: Scientist.Type) -> bool:
    var scientist = _get_scientist(type)
    var cost = scientist.get_upgrade_cost() if scientist.is_hired else scientist.TIER_DATA[type][1].cost
    return GameState.gold >= cost

func is_scientist_hired(type: Scientist.Type) -> bool:
    return _get_scientist(type).is_hired

func get_scientist_tier(type: Scientist.Type) -> int:
    return _get_scientist(type).tier

# ═══════════════════════════════════════════════════════════
# SALARY SYSTEM
# ═══════════════════════════════════════════════════════════

func get_total_salary() -> int:
    var total = 0
    if stitcher.is_hired:
        total += stitcher.get_salary()
    if caretaker.is_hired:
        total += caretaker.get_salary()
    if trainer.is_hired:
        total += trainer.get_salary()
    return total

func pay_salaries() -> bool:
    """Called after each wave completes"""
    var total = get_total_salary()
    
    if total == 0:
        return true  # No scientists hired
    
    salary_payment_due.emit(total)
    
    if GameState.gold >= total:
        GameState.gold -= total
        salary_paid.emit(total)
        return true
    else:
        salary_failed.emit(total)
        # TODO: Implement penalty (scientists go on strike?)
        return false

# ═══════════════════════════════════════════════════════════
# AUTOMATION CYCLE
# ═══════════════════════════════════════════════════════════

func _run_automation_cycle():
    """Runs every 5 seconds - performs all automated tasks"""
    
    # Run in priority order to prevent conflicts
    _run_stitcher_automation()
    _run_caretaker_automation()
    _run_trainer_automation()

func _run_stitcher_automation():
    if not stitcher.is_hired:
        return
    
    # Tier 1: Create dragons
    if stitcher.can_create_dragons():
        _auto_create_dragons()
    
    # Tier 2: Assign to defense
    if stitcher.can_auto_assign_defense():
        _auto_assign_defense()
    
    # Tier 3: Send exploring
    if stitcher.can_auto_explore():
        _auto_send_exploring()
    
    # Tier 4: Emergency recall
    if stitcher.can_emergency_recall():
        _auto_emergency_recall()
    
    # Tier 5: Auto-freeze parts
    if stitcher.can_auto_freeze():
        _auto_freeze_parts()

func _auto_create_dragons():
    # Check if we have 3+ parts available
    var available_parts = PartInventory.get_available_parts()  # Adjust to your system
    
    while available_parts.size() >= 3:
        # Create dragon from random parts
        var head = available_parts[0]
        var body = available_parts[1]
        var tail = available_parts[2]
        
        var dragon = DragonFactory.create_dragon(head, body, tail)  # Adjust to your system
        
        # Add to idle pool
        GameState.idle_dragons.append(dragon)
        
        # Remove used parts
        available_parts.erase(head)
        available_parts.erase(body)
        available_parts.erase(tail)

func _auto_assign_defense():
    # Get idle dragons
    var idle = GameState.idle_dragons.duplicate()
    
    for dragon in idle:
        # Find empty defense slot
        var empty_slot = TowerManager.get_first_empty_slot()  # Adjust to your system
        
        if empty_slot:
            TowerManager.assign_dragon(dragon, empty_slot)
            GameState.idle_dragons.erase(dragon)
        else:
            break  # No more empty slots

func _auto_send_exploring():
    # Only send if defense is FULL
    if not TowerManager.is_defense_full():
        return
    
    # Get idle dragons
    var idle = GameState.idle_dragons.duplicate()
    
    for dragon in idle:
        # Send on shortest exploration
        ExplorationManager.start_exploration(dragon, "shortest_destination")
        GameState.idle_dragons.erase(dragon)

func _auto_emergency_recall():
    # Check if defense needs help
    var needs_help = TowerManager.has_empty_slots() or TowerManager.get_total_hp() < TowerManager.get_max_hp() * 0.5
    
    if needs_help:
        # Recall nearest exploring dragon
        var explorers = ExplorationManager.get_exploring_dragons()
        if explorers.size() > 0:
            var nearest = _find_nearest_explorer(explorers)
            ExplorationManager.recall_early(nearest)

func _auto_freeze_parts():
    # Get recovered parts
    var recovered = DragonDeathManager.recovered_parts
    
    for part in recovered:
        # If decaying soon (< 6 hours)
        if part.get_time_until_decay() < 21600:
            # Find empty freezer slot
            for i in range(DragonDeathManager.get_freezer_capacity()):
                if DragonDeathManager.is_freezer_slot_empty(i):
                    DragonDeathManager.freeze_part(part, i)
                    break

func _run_caretaker_automation():
    if not caretaker.is_hired:
        return
    
    var all_dragons = _get_all_dragons()
    
    # Tier 1: Feed
    if caretaker.can_feed():
        for dragon in all_dragons:
            var hunger_threshold = 50.0
            if caretaker.can_prevent_starvation():
                hunger_threshold = 20.0  # Tier 4: More aggressive
            
            if dragon.hunger < hunger_threshold:
                _feed_dragon(dragon)
    
    # Tier 2: Heal
    if caretaker.can_heal():
        for dragon in all_dragons:
            if dragon.hp < dragon.max_hp * 0.75:
                _heal_dragon(dragon)
    
    # Tier 3: Rest
    if caretaker.can_rest():
        var defending = TowerManager.get_defending_dragons()
        for dragon in defending:
            if dragon.fatigue > 70:
                TowerManager.unassign_dragon(dragon)
                GameState.idle_dragons.append(dragon)
    
    # Tier 5: Repair towers
    if caretaker.can_repair_towers():
        for tower in TowerManager.get_all_towers():
            if tower.hp < tower.max_hp * 0.5:
                _repair_tower(tower)

func _run_trainer_automation():
    if not trainer.is_hired:
        return
    
    # Tier 2: Auto-fill training
    if trainer.can_auto_fill_training():
        var empty_slots = TrainingManager.get_empty_training_slots()
        var idle = GameState.idle_dragons.duplicate()
        
        for slot in empty_slots:
            if idle.size() > 0:
                var dragon = idle.pop_front()
                TrainingManager.assign_to_training(dragon, slot)
                GameState.idle_dragons.erase(dragon)
    
    # Tier 3: Auto-collect
    if trainer.can_auto_collect_training():
        var completed = TrainingManager.get_completed_training()
        for dragon in completed:
            TrainingManager.collect_from_training(dragon)
            GameState.idle_dragons.append(dragon)
            
            # Tier 4: Auto-rotate
            if trainer.can_auto_rotate():
                # Wait 10 seconds then send back
                await get_tree().create_timer(10.0).timeout
                if dragon in GameState.idle_dragons:
                    var empty = TrainingManager.get_empty_training_slots()
                    if empty.size() > 0:
                        TrainingManager.assign_to_training(dragon, empty[0])
                        GameState.idle_dragons.erase(dragon)

# ═══════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════

func _get_scientist(type: Scientist.Type) -> Scientist:
    match type:
        Scientist.Type.STITCHER:
            return stitcher
        Scientist.Type.CARETAKER:
            return caretaker
        Scientist.Type.TRAINER:
            return trainer
    return null

func _get_all_dragons() -> Array:
    var all = []
    all.append_array(GameState.idle_dragons)
    all.append_array(TowerManager.get_defending_dragons())
    all.append_array(ExplorationManager.get_exploring_dragons())
    all.append_array(TrainingManager.get_training_dragons())
    return all

func _feed_dragon(dragon: Dragon):
    # Implement feeding logic
    # Cost gold, increase hunger
    pass

func _heal_dragon(dragon: Dragon):
    # Implement healing logic
    # Cost gold, restore HP
    pass

func _repair_tower(tower: DefenseTower):
    # Implement repair logic
    # Cost gold, restore tower HP
    pass

func _find_nearest_explorer(explorers: Array) -> Dragon:
    # Find explorer closest to returning
    # Check time remaining on expedition
    return explorers[0]  # Placeholder

# ═══════════════════════════════════════════════════════════
# SAVE/LOAD
# ═══════════════════════════════════════════════════════════

func to_save_dict() -> Dictionary:
    return {
        "stitcher": stitcher.to_save_dict(),
        "caretaker": caretaker.to_save_dict(),
        "trainer": trainer.to_save_dict()
    }

func load_from_dict(data: Dictionary):
    stitcher.load_from_dict(data.stitcher)
    caretaker.load_from_dict(data.caretaker)
    trainer.load_from_dict(data.trainer)
```

---

## UI COMPONENTS

### **1. SCIENTIST MANAGEMENT SCREEN**

**File: `scientist_management_ui.tscn` + `scientist_management_ui.gd`**

**Visual Layout:**
```
╔════════════════════════════════════════════════════════════╗
║                  SCIENTIST MANAGEMENT                      ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  [Stitcher Card]  [Caretaker Card]  [Trainer Card]        ║
║                                                            ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                            ║
║  TOTAL SALARIES: 142g/wave                                ║
║  Next Payment In: Wave 48 (3m 15s)                        ║
║  Treasury Balance: 2,847g (20 waves of salaries)          ║
║                                                            ║
║  [Close]                                                   ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

**Scene Structure:**
```
ScientistManagementUI (Control)
├── MarginContainer
│   └── VBoxContainer
│       ├── TitleLabel ("SCIENTIST MANAGEMENT")
│       ├── ScientistCardsContainer (HBoxContainer)
│       │   ├── StitcherCard (ScientistCard instance)
│       │   ├── CaretakerCard (ScientistCard instance)
│       │   └── TrainerCard (ScientistCard instance)
│       ├── Separator
│       └── FooterPanel
│           ├── TotalSalaryLabel
│           ├── NextPaymentLabel
│           ├── BalanceLabel
│           └── CloseButton
```

**Script:**
```gdscript
extends Control
class_name ScientistManagementUI

@onready var stitcher_card = $Margin/VBox/Cards/StitcherCard
@onready var caretaker_card = $Margin/VBox/Cards/CaretakerCard
@onready var trainer_card = $Margin/VBox/Cards/TrainerCard
@onready var total_salary_label = $Margin/VBox/Footer/TotalSalary
@onready var next_payment_label = $Margin/VBox/Footer/NextPayment
@onready var balance_label = $Margin/VBox/Footer/Balance

var scientist_manager: ScientistManager

func _ready():
    scientist_manager = get_node("/root/ScientistManager")
    
    # Setup cards
    stitcher_card.setup(Scientist.Type.STITCHER)
    caretaker_card.setup(Scientist.Type.CARETAKER)
    trainer_card.setup(Scientist.Type.TRAINER)
    
    # Connect signals
    scientist_manager.scientist_hired.connect(_on_scientist_changed)
    scientist_manager.scientist_upgraded.connect(_on_scientist_changed)
    
    _update_footer()

func _process(_delta):
    _update_footer()

func _update_footer():
    var total = scientist_manager.get_total_salary()
    total_salary_label.text = "Total Salaries: %dg/wave" % total
    
    # Calculate waves until payment
    var waves_until = 1  # Placeholder - adjust to your wave system
    next_payment_label.text = "Next Payment: Wave %d" % (GameState.current_wave + 1)
    
    # Calculate how many waves player can afford
    var waves_affordable = 0
    if total > 0:
        waves_affordable = int(GameState.gold / total)
    balance_label.text = "Treasury: %dg (%d waves of salaries)" % [GameState.gold, waves_affordable]

func _on_scientist_changed(_type = null, _tier = null):
    _update_footer()
```

---

### **2. SCIENTIST CARD COMPONENT**

**File: `scientist_card.tscn` + `scientist_card.gd`**

**Visual Layout:**
```
╔════════════════════════════════════════════════════════╗
║  🧵 STITCHER - Master Stitcher (Tier 3/5)             ║
╠════════════════════════════════════════════════════════╣
║                                                        ║
║  [Portrait]              CURRENT ABILITIES:           ║
║                          ✓ Creates dragons            ║
║  Tier: ●●●○○             ✓ Assigns to defense        ║
║                          ✓ Sends exploring            ║
║  Salary: 40g/wave        ○ Emergency recalls          ║
║  Status: ✓ Working       ○ Auto-freezes parts        ║
║                                                        ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║                                                        ║
║  NEXT UPGRADE: Tier 4 - Grand Stitcher                ║
║                                                        ║
║  + NEW: Auto-recalls explorers for defense            ║
║                                                        ║
║  Cost: 15,000g  |  New Salary: 75g/wave               ║
║  Requires: 100 waves defeated (currently 73)          ║
║                                                        ║
║  [UPGRADE] (Locked - 27 more waves)                   ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
```

**Scene Structure:**
```
ScientistCard (PanelContainer)
└── MarginContainer
    └── VBoxContainer
        ├── HeaderContainer (HBoxContainer)
        │   ├── IconLabel
        │   └── NameLabel
        ├── ContentContainer (HBoxContainer)
        │   ├── LeftPanel (VBoxContainer)
        │   │   ├── Portrait
        │   │   ├── TierDisplay
        │   │   ├── SalaryLabel
        │   │   └── StatusLabel
        │   └── RightPanel (VBoxContainer)
        │       ├── AbilitiesLabel ("CURRENT ABILITIES:")
        │       └── AbilitiesList (VBoxContainer)
        ├── Separator
        ├── UpgradeSection (VBoxContainer)
        │   ├── UpgradeTitleLabel
        │   ├── NewAbilityLabel
        │   ├── CostLabel
        │   ├── RequirementLabel
        │   └── UpgradeButton
        └── HireButton (only visible if not hired)
```

**Script:**
```gdscript
extends PanelContainer
class_name ScientistCard

@onready var icon_label = $Margin/VBox/Header/Icon
@onready var name_label = $Margin/VBox/Header/Name
@onready var portrait = $Margin/VBox/Content/Left/Portrait
@onready var tier_display = $Margin/VBox/Content/Left/TierDisplay
@onready var salary_label = $Margin/VBox/Content/Left/Salary
@onready var status_label = $Margin/VBox/Content/Left/Status
@onready var abilities_list = $Margin/VBox/Content/Right/AbilitiesList
@onready var upgrade_section = $Margin/VBox/UpgradeSection
@onready var upgrade_button = $Margin/VBox/UpgradeSection/UpgradeButton
@onready var hire_button = $Margin/VBox/HireButton

var scientist_type: Scientist.Type
var scientist: Scientist
var scientist_manager: ScientistManager

const ABILITY_DESCRIPTIONS = {
    Scientist.Type.STITCHER: [
        "Creates dragons",
        "Assigns to defense",
        "Sends exploring",
        "Emergency recalls",
        "Auto-freezes parts"
    ],
    Scientist.Type.CARETAKER: [
        "Feeds dragons",
        "Heals dragons",
        "Rests dragons",
        "Prevents starvation",
        "Repairs towers"
    ],
    Scientist.Type.TRAINER: [
        "Training yard (+50%)",
        "Fills training slots",
        "Collects trained",
        "Auto-rotates training",
        "Passive XP gain"
    ]
}

const ICONS = {
    Scientist.Type.STITCHER: "🧵",
    Scientist.Type.CARETAKER: "🍖",
    Scientist.Type.TRAINER: "💪"
}

func setup(type: Scientist.Type):
    scientist_type = type
    scientist_manager = get_node("/root/ScientistManager")
    scientist = scientist_manager._get_scientist(type)
    
    _update_display()

func _update_display():
    # Header
    icon_label.text = ICONS[scientist_type]
    
    if scientist.is_hired:
        name_label.text = "%s - %s (Tier %d/5)" % [
            _get_type_name(),
            scientist.get_tier_name(),
            scientist.tier
        ]
        hire_button.visible = false
        _show_hired_view()
    else:
        name_label.text = "%s - Not Hired" % _get_type_name()
        hire_button.visible = true
        _show_hire_view()

func _show_hired_view():
    # Portrait
    portrait.visible = true
    
    # Tier display (5 dots)
    tier_display.text = ""
    for i in range(5):
        if i < scientist.tier:
            tier_display.text += "●"
        else:
            tier_display.text += "○"
    
    # Salary
    salary_label.text = "Salary: %dg/wave" % scientist.get_salary()
    
    # Status
    status_label.text = "Status: ✓ Working"
    status_label.add_theme_color_override("font_color", Color.GREEN)
    
    # Abilities
    _display_abilities()
    
    # Upgrade section
    if scientist.tier < 5:
        _show_upgrade_option()
    else:
        upgrade_section.visible = false

func _show_hire_view():
    portrait.visible = false
    tier_display.text = "Not Hired"
    salary_label.text = "Hire Cost: %dg" % scientist.TIER_DATA[scientist_type][1].cost
    status_label.text = "Status: Available"
    status_label.add_theme_color_override("font_color", Color.GRAY)
    
    abilities_list.visible = false
    upgrade_section.visible = false
    
    hire_button.text = "HIRE FOR %dg" % scientist.TIER_DATA[scientist_type][1].cost
    hire_button.disabled = not scientist_manager.can_afford_scientist(scientist_type)

func _display_abilities():
    # Clear existing
    for child in abilities_list.get_children():
        child.queue_free()
    
    var descriptions = ABILITY_DESCRIPTIONS[scientist_type]
    
    for i in range(5):
        var label = Label.new()
        var ability_text = descriptions[i]
        
        if i < scientist.tier:
            label.text = "✓ " + ability_text
            label.add_theme_color_override("font_color", Color.GREEN)
        else:
            label.text = "○ " + ability_text
            label.add_theme_color_override("font_color", Color.GRAY)
        
        abilities_list.add_child(label)

func _show_upgrade_option():
    upgrade_section.visible = true
    
    var next_tier = scientist.tier + 1
    var next_name = scientist.TIER_DATA[scientist_type][next_tier].name
    var cost = scientist.get_upgrade_cost()
    var new_salary = scientist.TIER_DATA[scientist_type][next_tier].salary
    
    upgrade_section.get_node("TitleLabel").text = "NEXT UPGRADE: Tier %d - %s" % [next_tier, next_name]
    
    var next_ability = ABILITY_DESCRIPTIONS[scientist_type][next_tier - 1]
    upgrade_section.get_node("NewAbilityLabel").text = "+ NEW: " + next_ability
    
    upgrade_section.get_node("CostLabel").text = "Cost: %dg  |  New Salary: %dg/wave" % [cost, new_salary]
    
    # Check unlock requirement
    var required_waves = scientist.UNLOCK_REQUIREMENTS[next_tier]
    var current_waves = GameState.waves_completed
    
    if current_waves >= required_waves:
        upgrade_section.get_node("RequirementLabel").text = "Requirement: ✓ %d waves defeated" % required_waves
        upgrade_section.get_node("RequirementLabel").add_theme_color_override("font_color", Color.GREEN)
        
        upgrade_button.text = "UPGRADE FOR %dg" % cost
        upgrade_button.disabled = GameState.gold < cost
    else:
        var waves_needed = required_waves - current_waves
        upgrade_section.get_node("RequirementLabel").text = "Requires: %d waves defeated (currently %d)" % [required_waves, current_waves]
        upgrade_section.get_node("RequirementLabel").add_theme_color_override("font_color", Color.ORANGE)
        
        upgrade_button.text = "LOCKED - %d more waves needed" % waves_needed
        upgrade_button.disabled = true

func _on_hire_button_pressed():
    if scientist_manager.hire_scientist(scientist_type):
        _update_display()

func _on_upgrade_button_pressed():
    if scientist_manager.upgrade_scientist(scientist_type):
        _update_display()

func _get_type_name() -> String:
    match scientist_type:
        Scientist.Type.STITCHER:
            return "STITCHER"
        Scientist.Type.CARETAKER:
            return "CARETAKER"
        Scientist.Type.TRAINER:
            return "TRAINER"
    return "Unknown"
```

---

### **3. QUICK STATUS WIDGET (Optional)**

**Small UI widget showing scientist status on main screen:**
```
╔═══════════════════════════════════╗
║  SCIENTISTS                       ║
╠═══════════════════════════════════╣
║  🧵 Stitcher (T3)    ✓ Working   ║
║     Last: Created dragon (2m ago) ║
║                                   ║
║  🍖 Caretaker (T2)   ✓ Working   ║
║     Last: Fed 3 dragons (15s ago) ║
║                                   ║
║  💪 Trainer (Not Hired)           ║
║     [Hire for 600g]               ║
║                                   ║
║  [Manage Scientists]              ║
╚═══════════════════════════════════╝
```

---

## INTEGRATION POINTS

### **Wave Completion Handler:**
```gdscript
# In your wave system
func _on_wave_completed(wave_number: int):
    # Pay scientist salaries
    ScientistManager.pay_salaries()
    
    # Update wave count for unlock checks
    GameState.waves_completed = wave_number
```

### **Main Game UI:**
```gdscript
# Add button to open scientist management
func _on_scientists_button_pressed():
    var scientist_ui = preload("res://scenes/ui/scientist_management_ui.tscn").instantiate()
    get_tree().root.add_child(scientist_ui)
```

### **Tutorial Integration:**
```gdscript
# After tutorial completes
func _on_tutorial_finished():
    # Show scientist introduction popup
    _show_scientist_unlock_notification()
```

---

## VISUAL POLISH

**Scientist Portraits:**
- Tier 1: Simple lab coat, young appearance
- Tier 2: Better coat, more confident
- Tier 3: Advanced equipment, assistants visible
- Tier 4: Prestigious robes, large workspace
- Tier 5: Glowing aura, masterwork laboratory

**Animations:**
- Tier upgrade: Flash effect, particles
- Ability unlocked: Glow pulse
- Working status: Subtle idle animation
- Salary payment: Coin stack animation

**Color Coding:**
- Stitcher: Blue/Cyan theme
- Caretaker: Green/Nature theme
- Trainer: Red/Orange theme

---

## AUDIO FEEDBACK

**Hire Scientist:** Achievement fanfare  
**Upgrade Scientist:** Power-up sound  
**Salary Payment:** Cash register ding  
**Salary Failed:** Error buzzer  
**Ability Triggered:** Subtle positive chime  

---

## BALANCE NOTES

**Early Game (Waves 1-25):**
- Can afford 1-2 Tier 1 scientists
- Focus on Caretaker (prevents deaths)

**Mid Game (Waves 25-100):**
- All 3 scientists at Tier 2-3
- Balanced automation

**Late Game (Waves 100+):**
- Push toward Tier 4-5
- Near-full AFK capability

**Salary pressure should be ~20-30% of wave income**

---

## DELIVERABLES

Please provide:

1. **scientist.gd** - Scientist resource class
2. **scientist_manager.gd** - Manager singleton with automation
3. **scientist_management_ui.tscn + .gd** - Main management screen
4. **scientist_card.tscn + .gd** - Individual scientist card component
5. **README.md** - Integration instructions

**Code Quality:**
- Godot 4 syntax
- Clean, commented code
- Signal-based architecture
- Save/load compatible
- Performance optimized

Make the automation feel intelligent and helpful, not overwhelming. Each upgrade should feel like a meaningful quality-of-life improvement!