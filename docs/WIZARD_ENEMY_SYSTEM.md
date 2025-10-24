# Wizard Enemy System

## Overview
Wizards are a new enemy type that joins knights in attacking the dragon defense towers. Unlike knights who deal physical damage, wizards use elemental attacks that interact with dragon elemental resistances.

## Folder Restructuring

### Assets Folder Rename
- **Old Path:** `assets/Icons/knights/`
- **New Path:** `assets/Icons/units/`
- **Contains:**
  - `knight.png` - Knight sprite
  - `wizard.png` - Wizard sprite (new)
  - Import files for both

### Updated References
All references to `assets/Icons/knights/` have been updated to `assets/Icons/units/`:
- `battle_arena.gd` - Unit texture loading
- `knight.png.import` - Source file path
- `wizard.png.import` - New import file (created)

## Wizard Enemy Type

### Spawn Rates
Enemies are randomly spawned each wave:
- **60%** - Knights (physical attackers)
- **40%** - Wizards (elemental attackers)
- **Boss waves** (every 10 waves) - One boss knight added

### Wizard Stats
Compared to knights, wizards have:
- **Lower Health:** 35 + (wave × 7) vs 50 + (wave × 10)
- **Higher Attack:** 15 + (wave × 4) vs 10 + (wave × 3)
- **Elemental Damage:** 5 + (wave × 2) bonus damage
- **More Gold:** 15 + (wave × 7) vs 10 + (wave × 5)
- **No Meat Drops:** Wizards don't drop knight meat

### Elemental Types
Each wizard spawns with a random elemental type:
1. 🔥 **Fire**
2. ❄ **Ice**
3. ⚡ **Lightning**
4. ☠ **Poison**
5. 🌑 **Shadow**

## Elemental Damage System

### How It Works
Wizard elemental damage interacts with dragon elemental resistances:

```gdscript
func _calculate_elemental_damage(wizard: Dictionary, dragons: Array[Dragon]) -> float:
    var base_elemental_damage = wizard.get("elemental_damage", 0)
    var wizard_element = wizard.get("elemental_type", 0)
    
    # Calculate average effectiveness against all defending dragons
    var total_effectiveness = 0.0
    for dragon in dragons:
        var resistance = dragon.get_elemental_resistance(wizard_element)
        total_effectiveness += resistance
    
    var avg_effectiveness = total_effectiveness / dragons.size()
    return base_elemental_damage * avg_effectiveness
```

### Resistance Multipliers
- **Weak to Element:** resistance > 1.0 = wizard deals MORE damage
- **Neutral:** resistance = 1.0 = normal damage
- **Resistant:** resistance < 1.0 = wizard deals LESS damage

### Example
If a Fire Wizard (elemental_damage = 15) attacks:
- **Shadow Dragon** (weak to Fire, resistance = 1.2): 15 × 1.2 = **18 damage**
- **Ice Dragon** (neutral, resistance = 1.0): 15 × 1.0 = **15 damage**
- **Fire Dragon** (resistant, resistance = 0.8): 15 × 0.8 = **12 damage**

## Visual Representation

### Battle Arena
Wizards are visually distinguished from knights:

**Sprite:**
- Knights: `knight.png` (armored human)
- Wizards: `wizard.png` (robed wizard with glowing staff)

**Label Color:**
- Knights: White
- Wizards: Purple (Color(0.6, 0.4, 1.0))

**Label Text:**
```
KNIGHT          vs          WIZARD
                            🔥Fire
```

### Combat Log
Wizard attacks are displayed in purple with elemental icons:

```
[purple]Wizard 0🔥[/purple] deals 23 damage to [lightblue]Terraumbra the Wyrm[/lightblue]! (HP: 145)
[lightblue]Terraumbra the Wyrm[/lightblue] deals 42 damage to [purple]Wizard 0[/purple]! (HP: 28)
💀 Wizard 0 has fallen!
```

## Strategic Implications

### For Players
1. **Dragon Composition Matters:** Mixed elemental teams reduce wizard effectiveness
2. **Pure Element Risk:** Single-element defense vulnerable to counter-element wizards
3. **Wizard Priority:** Higher damage output means wizards are more dangerous
4. **No Meat from Wizards:** Only knights and bosses drop knight meat

### Combat Balance
- **Wizards:** Glass cannons (high damage, low HP)
- **Knights:** Balanced (medium damage, medium HP)
- **Bosses:** Tanks (high damage, very high HP)

## Code Files Modified

### Core Systems
1. **`scripts/managers/defense_manager.gd`**
   - Added `_create_wizard()` function
   - Modified `_generate_wave()` for random enemy spawning
   - Added `_calculate_elemental_damage()` function
   - Updated combat power calculation to include elemental damage
   - Modified meat drops to exclude wizards

2. **`scripts/idle_defense/battle_arena.gd`**
   - Updated texture loading to support both knight and wizard sprites
   - Modified enemy labels to show wizard type and element
   - Updated combat log messages to distinguish wizards
   - Added elemental damage calculation in combat rounds

### Assets
3. **`assets/Icons/units/knight.png.import`**
   - Updated source file path from `knights/` to `units/`

4. **`assets/Icons/units/wizard.png.import`** (NEW)
   - Created import configuration for wizard sprite

## Testing Checklist

- [x] Wizards spawn in waves (40% chance)
- [x] Wizard sprite displays correctly in battle arena
- [x] Wizard label shows "WIZARD" with elemental type
- [x] Elemental damage is calculated based on dragon resistances
- [x] Combat log distinguishes wizards with purple color
- [x] Wizards don't drop knight meat
- [x] Wizards give appropriate gold rewards
- [x] Dragon health updates correctly after wizard attacks
- [x] Mixed dragon teams face varied elemental threats

## Future Enhancements

Potential improvements to the wizard system:
1. **Boss Wizards:** Elemental bosses with multi-element attacks
2. **Wizard Loot:** Special magical items or consumables
3. **Elemental Combos:** Multiple wizards of same element deal bonus damage
4. **Dragon Buffs:** Resistance potions or elemental shields
5. **Wizard Variety:** Different wizard types (Pyromancer, Cryomancer, etc.)
6. **Visual Effects:** Elemental particles or attack animations
7. **Sound Effects:** Unique wizard attack sounds per element

## Summary

Wizards add strategic depth to the tower defense system by:
- Punishing single-element dragon compositions
- Rewarding diverse elemental dragon teams
- Creating dynamic combat where elemental matchups matter
- Providing higher risk/reward encounters (more gold, no meat, elemental threat)

The elemental damage system integrates seamlessly with the existing dragon part system, making dragon breeding and composition more meaningful!

