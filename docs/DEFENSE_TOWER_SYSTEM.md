# Defense Tower System Documentation

## Overview

The Defense Tower system controls how many dragons can be assigned to defend the treasure vault. Players start with 3 towers and can build up to 15, with each tower providing one defense slot for dragons. Towers take damage during wave attacks and can be repaired with gold.

## Key Features

### 1. Tower Capacity
- **Starting Towers**: 3 (providing 3 defense slots)
- **Maximum Towers**: 15 (up to 15 dragons can defend simultaneously)
- **Dynamic Capacity**: Only active (non-destroyed) towers count toward defense slots

### 2. Tower Building
- **Scaling Cost**: Cost increases exponentially with each tower built
  - Formula: `BASE_COST * (MULTIPLIER ^ towers_beyond_starting)`
  - Base Cost: 100 gold
  - Multiplier: 1.5x
  - Example costs:
    - 4th tower: 100 gold
    - 5th tower: 150 gold
    - 6th tower: 225 gold
    - 7th tower: 337 gold
    - etc.

### 3. Tower Damage
Towers automatically take damage during wave attacks:
- **Small Damage (Victory)**: 5 HP per tower
- **Large Damage (Defeat)**: 20 HP per tower
- **Tower Health**: 100 HP per tower

### 4. Tower Repair
- **Repair Cost**: 10 gold per HP
- **Full Repair**: Restores tower to maximum health
- **Partial Repair**: Can repair specific amounts
- **Repair All**: Convenient function to repair all damaged towers

## Architecture

### Class Structure

```
DefenseTower (Resource)
├── Properties
│   ├── tower_id: String
│   ├── current_health: int
│   └── max_health: int
├── Methods
│   ├── take_damage(amount: int)
│   ├── repair(amount: int)
│   ├── is_destroyed() -> bool
│   ├── get_health_percentage() -> float
│   └── needs_repair() -> bool
└── Serialization
    ├── to_dict() -> Dictionary
    └── from_dict(data: Dictionary) -> DefenseTower

DefenseTowerManager (Singleton Node)
├── Building
│   ├── build_tower() -> DefenseTower
│   ├── can_build_tower() -> bool
│   └── get_next_tower_cost() -> int
├── Repair
│   ├── repair_tower(tower, amount)
│   ├── repair_all_towers()
│   ├── get_tower_repair_cost(tower)
│   └── get_partial_repair_cost(tower, amount)
├── Damage
│   └── apply_wave_damage(victory: bool)
├── Capacity
│   ├── get_defense_capacity() -> int
│   ├── get_total_towers() -> int
│   ├── get_active_towers() -> int
│   ├── get_destroyed_towers() -> int
│   └── get_damaged_towers() -> int
└── Serialization
    ├── to_dict() -> Dictionary
    └── from_dict(data: Dictionary)
```

### Integration Points

#### DefenseManager Integration
The DefenseManager now queries tower capacity instead of using a hardcoded limit:

```gdscript
# Before
if defending_dragons.size() >= 3:
    # Reject assignment

# After
var max_defenders = DefenseTowerManager.instance.get_defense_capacity()
if defending_dragons.size() >= max_defenders:
    # Reject assignment
```

#### Wave Damage Integration
After each wave completes, towers automatically take damage:

```gdscript
func _complete_wave(victory: bool, rewards: Dictionary):
    # Apply damage to towers
    DefenseTowerManager.instance.apply_wave_damage(victory)
    # ... rest of wave completion
```

#### Save/Load Integration
DefenseTowerManager is now part of the save/load system:
- Saved after DefenseManager
- Loaded before DefenseManager (for capacity checks)

## API Reference

### DefenseTower

#### Properties
- `tower_id: String` - Unique identifier
- `current_health: int` - Current HP (0-100)
- `max_health: int` - Maximum HP (100)

#### Methods

**take_damage(amount: int)**
```gdscript
tower.take_damage(20)
# Tower takes damage, emits tower_damaged signal
# If health reaches 0, emits tower_destroyed signal
```

**repair(amount: int)**
```gdscript
tower.repair(50)
# Restores HP, capped at max_health
# Emits tower_repaired signal
```

**is_destroyed() -> bool**
```gdscript
if tower.is_destroyed():
    print("Tower is destroyed!")
```

**needs_repair() -> bool**
```gdscript
if tower.needs_repair():
    print("Tower needs repair")
```

**get_health_percentage() -> float**
```gdscript
var health_pct = tower.get_health_percentage()
print("Tower at %.0f%% health" % (health_pct * 100))
```

#### Signals
- `tower_damaged(tower: DefenseTower, damage: int)`
- `tower_destroyed(tower: DefenseTower)`
- `tower_repaired(tower: DefenseTower, amount: int)`

### DefenseTowerManager

#### Building Methods

**build_tower() -> DefenseTower**
```gdscript
var new_tower = DefenseTowerManager.instance.build_tower()
if new_tower:
    print("Tower built!")
else:
    print("Cannot build tower (max reached or insufficient gold)")
```

**can_build_tower() -> bool**
```gdscript
if DefenseTowerManager.instance.can_build_tower():
    # Show build button
```

**get_next_tower_cost() -> int**
```gdscript
var cost = DefenseTowerManager.instance.get_next_tower_cost()
print("Next tower costs %d gold" % cost)
```

#### Repair Methods

**repair_tower(tower: DefenseTower, repair_amount: int = -1) -> bool**
```gdscript
# Full repair
var success = DefenseTowerManager.instance.repair_tower(tower)

# Partial repair
var success = DefenseTowerManager.instance.repair_tower(tower, 50)
```

**repair_all_towers() -> int**
```gdscript
var repaired = DefenseTowerManager.instance.repair_all_towers()
print("Repaired %d towers" % repaired)
```

**get_tower_repair_cost(tower: DefenseTower) -> int**
```gdscript
var cost = DefenseTowerManager.instance.get_tower_repair_cost(tower)
print("Full repair costs %d gold" % cost)
```

**get_partial_repair_cost(tower: DefenseTower, repair_amount: int) -> int**
```gdscript
var cost = DefenseTowerManager.instance.get_partial_repair_cost(tower, 50)
print("Repairing 50 HP costs %d gold" % cost)
```

#### Damage Methods

**apply_wave_damage(wave_victory: bool)**
```gdscript
# Called automatically by DefenseManager after waves
DefenseTowerManager.instance.apply_wave_damage(victory)
```

#### Capacity Methods

**get_defense_capacity() -> int**
```gdscript
var max_defenders = DefenseTowerManager.instance.get_defense_capacity()
print("Can assign %d dragons to defense" % max_defenders)
```

**get_total_towers() -> int**
```gdscript
var total = DefenseTowerManager.instance.get_total_towers()
```

**get_active_towers() -> int**
```gdscript
var active = DefenseTowerManager.instance.get_active_towers()
```

**get_destroyed_towers() -> int**
```gdscript
var destroyed = DefenseTowerManager.instance.get_destroyed_towers()
```

**get_damaged_towers() -> int**
```gdscript
var damaged = DefenseTowerManager.instance.get_damaged_towers()
```

**get_towers() -> Array[DefenseTower]**
```gdscript
var towers = DefenseTowerManager.instance.get_towers()
for tower in towers:
    print("Tower: %d/%d HP" % [tower.current_health, tower.max_health])
```

#### Signals
- `tower_built(tower: DefenseTower)`
- `tower_damaged(tower: DefenseTower, damage: int)`
- `tower_destroyed(tower: DefenseTower)`
- `tower_repaired(tower: DefenseTower, amount: int)`
- `tower_capacity_changed(new_capacity: int)`
- `insufficient_gold_for_tower(cost: int)`
- `insufficient_gold_for_repair(cost: int)`
- `max_towers_reached()`

#### Debug Methods

**print_tower_status()**
```gdscript
DefenseTowerManager.instance.print_tower_status()
# Prints detailed tower information to console
```

**force_damage_all_towers(amount: int)**
```gdscript
DefenseTowerManager.instance.force_damage_all_towers(50)
# Debug: Damage all towers by specified amount
```

## Usage Examples

### Example 1: Building a Tower

```gdscript
func _on_build_tower_button_pressed():
    var tower_manager = DefenseTowerManager.instance
    var vault = TreasureVault.instance

    # Check if we can build
    if not tower_manager.can_build_tower():
        print("Maximum towers reached!")
        return

    # Get cost and check gold
    var cost = tower_manager.get_next_tower_cost()
    if vault.get_total_gold() < cost:
        print("Not enough gold! Need %d" % cost)
        return

    # Build tower
    var new_tower = tower_manager.build_tower()
    if new_tower:
        print("Tower built for %d gold!" % cost)
        print("Defense capacity: %d" % tower_manager.get_defense_capacity())
```

### Example 2: Repairing Damaged Towers

```gdscript
func _on_repair_all_button_pressed():
    var tower_manager = DefenseTowerManager.instance

    var damaged_count = tower_manager.get_damaged_towers()
    if damaged_count == 0:
        print("No towers need repair")
        return

    # Calculate total repair cost
    var total_cost = 0
    for tower in tower_manager.get_towers():
        if tower.needs_repair():
            total_cost += tower_manager.get_tower_repair_cost(tower)

    print("Repairing %d towers will cost %d gold" % [damaged_count, total_cost])

    # Repair all
    var repaired = tower_manager.repair_all_towers()
    print("Repaired %d towers" % repaired)
```

### Example 3: UI Update on Tower Capacity Change

```gdscript
func _ready():
    # Connect to capacity change signal
    DefenseTowerManager.instance.tower_capacity_changed.connect(_on_tower_capacity_changed)

func _on_tower_capacity_changed(new_capacity: int):
    # Update UI to show new defense slot count
    update_defense_slots_display(new_capacity)

    # Check if we need to remove excess defenders
    var defense_manager = DefenseManager.instance
    if defense_manager.get_defending_dragons().size() > new_capacity:
        print("WARNING: Tower destroyed! Too many defenders assigned!")
```

### Example 4: Displaying Tower Health

```gdscript
func update_tower_display():
    var tower_manager = DefenseTowerManager.instance
    var towers = tower_manager.get_towers()

    for i in towers.size():
        var tower = towers[i]
        var health_pct = tower.get_health_percentage()

        # Update health bar
        $TowerHealthBars[i].value = health_pct

        # Change color based on health
        if tower.is_destroyed():
            $TowerHealthBars[i].modulate = Color.GRAY
        elif health_pct < 0.3:
            $TowerHealthBars[i].modulate = Color.RED
        elif health_pct < 0.6:
            $TowerHealthBars[i].modulate = Color.YELLOW
        else:
            $TowerHealthBars[i].modulate = Color.GREEN
```

## Testing

A comprehensive test script is available at [scripts/test/defense_tower_test.gd](../scripts/test/defense_tower_test.gd).

Run tests by adding the test script to a scene and running it:

```gdscript
# Add to test scene
var test = preload("res://scripts/test/defense_tower_test.gd").new()
add_child(test)
```

Tests cover:
1. Initial state (3 towers, capacity 3)
2. Tower building (cost calculation, gold deduction)
3. Capacity integration with DefenseManager
4. Tower damage (victory vs defeat)
5. Tower repair (cost calculation, gold deduction)
6. Save/Load integration

## Constants Reference

```gdscript
# DefenseTowerManager
const STARTING_TOWERS: int = 3
const MAX_TOWERS: int = 15
const BASE_BUILD_COST: int = 100
const COST_MULTIPLIER: float = 1.5
const BASE_REPAIR_COST: int = 10
const SMALL_DAMAGE: int = 5   # Damage on wave victory
const LARGE_DAMAGE: int = 20  # Damage on wave defeat

# DefenseTower
const MAX_HEALTH: int = 100
```

## Future Enhancements

Potential improvements to consider:

1. **Tower Upgrades**: Increase individual tower health/capacity
2. **Tower Types**: Different towers with special abilities
3. **Visual Indicators**: 3D models showing tower damage state
4. **Tower Placement**: Spatial tower positioning mechanics
5. **Tower Abilities**: Active/passive tower bonuses (e.g., healing dragons)
6. **Rebuild Mechanic**: Rebuild destroyed towers at reduced cost
7. **Tower Maintenance**: Optional upkeep costs for better tower states

## Files

### Core Implementation
- [scripts/managers/defense_tower.gd](../scripts/managers/defense_tower.gd) - DefenseTower resource class
- [scripts/managers/defense_tower_manager.gd](../scripts/managers/defense_tower_manager.gd) - DefenseTowerManager singleton

### Integration
- [scripts/managers/defense_manager.gd](../scripts/managers/defense_manager.gd) - DefenseManager integration
- [scripts/managers/save_load_manager.gd](../scripts/managers/save_load_manager.gd) - Save/Load integration
- [project.godot](../project.godot) - Autoload configuration

### Testing
- [scripts/test/defense_tower_test.gd](../scripts/test/defense_tower_test.gd) - Comprehensive test suite

### Documentation
- [docs/DEFENSE_TOWER_SYSTEM.md](./DEFENSE_TOWER_SYSTEM.md) - This file
- [docs/GAME_SYSTEMS_DOCUMENTATION.md](./GAME_SYSTEMS_DOCUMENTATION.md) - Overall game systems

## Change Log

### v1.0 (Initial Implementation)
- Created DefenseTower resource class
- Created DefenseTowerManager singleton
- Integrated with DefenseManager for dynamic capacity
- Integrated with TreasureVault for gold costs
- Integrated with save/load system
- Added comprehensive test suite
- Tower damage on wave completion
- Tower repair with gold
- Scaling build costs (exponential)
- Starting with 3 towers, max 15
