# Playful Game Jam - Comprehensive Game Systems Documentation

## Project Overview
This is a Godot-based idle/incremental game featuring dragon breeding, exploration, training, and defense mechanics. The game uses GDScript and follows a singleton pattern for manager classes.

---

## 1. DRAGON STATS AND CALCULATIONS

### Dragon Attributes (Dragon.gd)

**Base Stats:**
- `total_attack`: Attack power (10 base + head_part.attack_bonus * level)
- `total_health`: Health pool (50 base + body_part.health_bonus * level)
- `total_speed`: Speed stat (5 base + tail_part.speed_bonus * level)
- `total_defense`: Defense (5 base + body_part.defense_bonus * level)
- `current_health`: Current HP (max is total_health)

**Life Systems:**
- `hunger_level`: 0.0 (fed) to 1.0 (starving)
- `fatigue_level`: 0.0 (rested) to 1.0 (exhausted)
- `happiness_level`: 0.0 (sad) to 1.0 (happy, starts at 0.5)

**Progression:**
- `level`: 1-10 max
- `experience`: Total XP earned
- `is_chimera_mutation`: Special "Holy Shit Moment" mutation flag

**Elemental System:**
- `primary_element`: From head part (Fire, Ice, Lightning, Nature, Shadow)
- `secondary_elements`: Array of elements from body/tail if different
- `elemental_attack_bonus`: 1.0 (mixed), 1.15 (2 parts same), 1.3 (all 3 same)
- `elemental_resistances`: Dictionary tracking damage multipliers for each element

### Stat Calculation Formula

```
Base Stats:
- Attack = 10 + (head.attack_bonus * level)
- Health = 50 + (body.health_bonus * level)
- Speed = 5 + (tail.speed_bonus * level)
- Defense = 5 + (body.defense_bonus * level)

Element Synergy Bonuses:
- All 3 same: +5 ATK, +10 HP, +2 SPD, +3 DEF per level
- 2 same: +2 ATK, +5 HP, +1 SPD, +1 DEF per level

Status Penalties:
- Hunger > 50%: (hunger - 0.5) * 0.4 penalty (up to 20%)
- Fatigue > 70%: (fatigue - 0.7) * 0.5 penalty (up to 15%)
```

### Chimera Mutation (Holy Shit Moment!)

**Chance:** 1% when creating a dragon
**Benefits:**
- Attack: 2.5x multiplier
- Health: 2.0x multiplier
- Speed: 1.5x multiplier
- Defense: 2.0x multiplier
- Elemental resistances improved: weak resistances -20%, weak vulnerabilities capped at 1.2x
- Elemental attack bonus: +0.2 (so 1.3→1.5, 1.15→1.35, 1.0→1.2)

### Elemental Resistance System

**Resistance Calculation:**
- Base: 1.0x (normal damage)
- Resistance: 0.5-0.7x per matching element (up to 30% reduction)
- Weakness: +10% per opposing element

**Element Weaknesses (Rock-Paper-Scissors):**
- Fire weak to Ice
- Ice weak to Fire
- Lightning weak to Nature (grounded)
- Nature weak to Shadow (decay)
- Shadow weak to Lightning (light)

### Elemental Attack Bonus

```
Pure Dragon (3 same parts):
- Elemental Attack Bonus: 1.3x
- +30% damage when attacking matching weakness

Hybrid Dragon (2 same parts):
- Elemental Attack Bonus: 1.15x
- +15% damage when attacking matching weakness

Mixed Dragon (all different):
- Elemental Attack Bonus: 1.0x
- Can exploit multiple weaknesses for +15% bonus per secondary element weakness
```

### Dragon Parts (DragonPart.gd)

**Part Types:** HEAD, BODY, TAIL

**Part Stats by Type:**
- HEAD: attack_bonus (5 + element modifier)
- BODY: health_bonus (10 + modifier), defense_bonus (4 + modifier)
- TAIL: speed_bonus (3 per tail)

**Element Modifiers (PartLibrary.gd):**
- Fire: +3 attack
- Ice: +3 health and defense
- Lightning: +3 speed
- Nature: +2 balanced
- Shadow: +2 attack, +2 defense, +1 other

---

## 2. DRAGON CREATION AND LIFECYCLE

### Dragon Creation Process (DragonFactory.gd)

1. **Create Dragon:** Requires head, body, tail DragonParts
2. **Check Mutation:** 1% chance for Chimera mutation (calls `attempt_chimera_mutation`)
3. **Register Dragon:** Added to DragonStateManager for state tracking
4. **Generate Name:** Async AI name generation (fallback: Element prefix + element suffix + "the Wyrm")
5. **Emit Signal:** dragon_created signal fires

### Dragon States (Dragon.DragonState enum)

```
IDLE       - No activity
DEFENDING  - Protecting vault in defense waves
EXPLORING  - On an exploration mission
TRAINING   - Active training for XP
RESTING    - Recovering from fatigue
DEAD       - Permanently dead (no resurrection)
```

### Dragon Lifecycle Events

**Creation:**
- Initialize with current timestamp
- Set last_fed_time to now
- Set state_start_time to now
- Calculate all stats

**Living (Updates every 30 seconds):**
- Hunger increases (1% per minute)
- Fatigue changes based on state (recover during IDLE/RESTING, accumulate during EXPLORING/TRAINING)
- Happiness decays (-0.5% per minute, +2% per minute if toy equipped)
- Health decreases if starving (10% per hour after full starvation)
- Check for death if health <= 0 and starving

**Death:**
- Triggered by starvation (hunger >= 1.0 for 100 minutes)
- Cannot be revived
- Removed from active dragons

### Dragon Collection

The game tracks unique dragon combinations (5 elements × 3 parts = 125 possible combinations). When a new combination is discovered, it's logged in `dragon_collection`.

---

## 3. EXPLORATION SYSTEM

### Overview
Dragons can be sent on 15, 30, or 60 minute missions to gather loot and XP. Longer missions = greater rewards but higher fatigue/hunger cost and damage risk.

### Exploration Manager (ExplorationManager.gd)

**DEV MODE:** Set `DEV_MODE = true` to use seconds instead of minutes for testing (15sec/30sec/60sec)

### Exploration Durations
- **15 minutes:** 15 sec in dev mode
- **30 minutes:** 30 sec in dev mode
- **60 minutes:** 60 sec in dev mode

### Exploration Requirements
- Dragon not already exploring
- Dragon not dead
- Fatigue level <= 0.5 (must be 50% rested)
- Valid duration (15, 30, or 60 only)

### Reward Calculation

```
Base Gold: BASE_GOLD_PER_MINUTE (2) * duration_minutes
Base XP: BASE_XP_PER_MINUTE (3) * duration_minutes

Level Multiplier: 1.0 + (dragon.level - 1) * 0.15
Applied to: gold *= multiplier, xp *= multiplier

Dragon Parts Drop:
- 15min: 1 guaranteed
- 30min: 2 guaranteed or 1 if unlucky
- 60min: 3 guaranteed or 2 if unlucky
Chance: 30% to get any parts at all

Item Drop Chances (multiple rolls based on duration):
- 1 roll: 15min
- 2 rolls: 30min
- 3 rolls: 60min

Per roll:
- Treats (XP items): 25%
- Health potions: 20%
- Food: 30%
- Toys: 15%
```

### Example Rewards

**15-minute exploration (Level 1 dragon):**
- Gold: 30 (2 × 15)
- XP: 45 (3 × 15)
- Parts: 1-2 random dragon parts
- Items: 1 roll per item type

**60-minute exploration (Level 5 dragon):**
- Gold: 180 (60 × 2 × 1.6 multiplier)
- XP: 270 (60 × 3 × 1.6 multiplier)
- Parts: 2-3 random dragon parts
- Items: 3 rolls per item type

### Exploration Costs

**Fatigue (Added on completion):**
- 15min: +15% fatigue
- 30min: +25% fatigue
- 60min: +40% fatigue

**Hunger (Added on completion):**
- 15min: +5% hunger (15/30 * 0.3)
- 30min: +10% hunger (30/30 * 0.3)
- 60min: +20% hunger (60/30 * 0.3)

**Damage Risk (Random):**
- 15min: 15% chance of 10-20% damage
- 30min: 25% chance of 15-30% damage
- 60min: 35% chance of 20-40% damage

---

## 4. FATIGUE SYSTEM AND RESTING

### Fatigue Mechanics (DragonStateManager.gd)

**Hunger Rate:**
- Linear: 1% per minute (time_since_fed * 0.01/60)
- Cap: 1.0 (100% starving)

**Starvation:**
- After 100 minutes at 100% hunger, dragon takes damage
- 10% health loss per hour while starving
- Death when health reaches 0

### Fatigue Recovery

**State-based Recovery (every 30 seconds):**
- IDLE: -1% fatigue per 30 seconds (full recovery ~50 minutes)
- RESTING: -4.5% fatigue per 30 seconds (full recovery ~11 minutes)
- EXPLORING/TRAINING/DEFENDING: No recovery, fatigue locked

### Fatigue Penalties

When fatigue > 70%:
- Attack penalty: (fatigue - 0.7) * 0.5 (up to 15% loss)
- Cannot explore if fatigue > 50%
- Can still defend if fatigue <= 50%
- Resting is ideal way to recover

---

## 5. SCIENTISTS AND THEIR FUNCTIONS

### ScientistManager.gd

Three types of scientists available, each with hire cost and ongoing maintenance cost:

### Stitcher

**Function:** Automatically creates dragons from available parts
- **Hire Cost:** 50 gold
- **Ongoing Cost:** 2 gold/minute
- **Work Interval:** Every 60 seconds
- **Requirements:** 1 head part, 1 body part, 1 tail part available
- **Action:** Creates dragon automatically, consumes parts from inventory

### Caretaker

**Function:** Automatically feeds and heals dragons
- **Hire Cost:** 100 gold
- **Ongoing Cost:** 3 gold/minute
- **Work Interval:** Every 30 seconds
- **Priority System:**
  1. Heal dragons < 30% health (use health potions)
  2. Feed dragons > 75% hunger (use food)
  3. Feed dragons > 50% hunger (use food)
  4. Heal any damaged dragons (use health potions)

### Trainer

**Function:** Automatically grants XP to training dragons
- **Hire Cost:** 150 gold
- **Ongoing Cost:** 5 gold/minute
- **Work Interval:** Every 30 seconds
- **XP Grant:** 10 XP per trigger to dragons in TRAINING state

### Hiring and Firing

```
Hire Requirements:
- Not already hired
- Sufficient gold for hire_cost

Auto-Fire:
- If insufficient gold for ongoing_cost each minute
- No refund on hire cost

Status Tracking:
- Hired scientists emit scientist_hired signal
- Fired scientists emit scientist_fired signal
```

---

## 6. RESOURCE MANAGEMENT

### TreasureVault.gd - Central Resource System

**Resources Stored:**
- Gold (both vulnerable and protected)
- Dragon Parts (5 element types, both vulnerable and protected)
- Artifacts (special items)
- Consumable Items (treats, health potions, food, toys)

**Starting Resources:**
- Gold: 100
- Dragon Parts: 3 of each element type
- Consumables: 0

### Consumable Items

**Treats (XP Items)**
- Grants: 50 XP + 15% happiness boost
- Use: Dragon care button in modal

**Health Potions**
- Effect: Restore dragon to full health
- Use: Dragon care button in modal
- Priority: Used by Caretaker on critical health (< 30%)

**Food**
- Effect: Reduces hunger by 25%
- Use: Feed button in modal
- Priority: Used by Caretaker on hungry dragons

**Toys**
- Effect: +2% happiness per minute when equipped
- Use: Equip via toy slot UI
- Maximum: 1 equipped at a time

### Vault Tier System

**Tiers Based on Total Value:**
- Tier 0: 0-499 gold
- Tier 1: 500-1499 gold (Unlock first scientist slot)
- Tier 2: 1500-4999 gold
- Tier 3: 5000-9999 gold (Unlock second scientist slot)
- Tier 4: 10000-24999 gold (Unlock protected storage)
- Tier 5: 25000+ gold (Unlock third scientist slot, "vault mastery")

### Item Valuation for Vault Value

```
Gold: 1 gold = 1 vault value
Parts: 1 part = 20 vault value
Artifacts: 1 artifact = 100 vault value
Treats: 1 treat = 10 vault value
Health Pots: 1 potion = 10 vault value
Food: 1 food = 10 vault value
Toys: 1 toy = 10 vault value
```

### Protected Storage

- Move gold/parts to protected storage to avoid losses in raids
- Protected resources are never stolen
- Can unprotect to move back to vulnerable storage

### Raid Loss System

When defense fails:
```
Loss Percentage: min(0.30, 0.15 + (wave_number * 0.01))
- Wave 1: 15% loss
- Wave 10: 25% loss
- Wave 15+: 30% capped

Only Unprotected Resources Lost:
- Protected gold is safe
- Protected parts are safe
```

---

## 7. DEFENSE SYSTEM

### DefenseManager.gd - Wave-Based Combat

**Wave Mechanics:**
- Waves spawn every 5 minutes (adjustable via BASE_WAVE_INTERVAL)
- Frequency scales with vault value (more treasure = more frequent attacks)
- Maximum 3 dragons can defend simultaneously

### Wave Scaling

```
Enemy Count: 1 + int(wave_num / 5) * difficulty_mult
- Wave 1: 1 enemy
- Wave 5: 1-2 enemies
- Wave 10: 2 enemies + 1 BOSS

Difficulty Multiplier: 1.0 + (vault_tier * 0.4)
- Tier 1: 1.4x difficulty
- Tier 5: 3.0x difficulty max
```

### Knight Enemy Stats

```
Knight (per wave):
- Attack: (10 + wave_num * 3) * difficulty_mult
- Health: (50 + wave_num * 10) * difficulty_mult
- Speed: (5 + wave_num) * difficulty_mult
- Reward: (10 + wave_num * 5) gold + 1 part
```

### Boss Enemy Stats

```
Boss (every 10 waves):
- Attack: (25 + wave_num * 6) * difficulty_mult
- Health: (150 + wave_num * 20) * difficulty_mult
- Speed: (10 + wave_num * 2) * difficulty_mult
- Reward: (50 + wave_num * 10) gold + 3 parts
```

### Combat Resolution

```
Dragon Power Calculation:
- Base: attack + (health * 0.5) + (speed * 0.3)
- Hunger Penalty: 1.0 - (hunger_level * 0.2) [up to -20%]
- Fatigue Penalty: 1.0 - (fatigue_level * 0.15) [up to -15%]
- Total Power: base * hunger_penalty * fatigue_penalty

Enemy Power: Same calculation for all enemies combined

Victory Condition:
- Dragon power >= enemy power * 1.1 (dragons need 10% more power)

Victory Rewards:
- 50 * wave_number XP per dragon
- +10% fatigue per dragon
- Random parts from defeated enemies

Defeat Consequences:
- Damage = (enemy_power - dragon_power) / dragon_count
- Minimum 10 damage per dragon
- +15% fatigue from defeat
- Dragons can die if health reaches 0
- Resources stolen from vault (see Raid Loss)
```

---

## 8. INVENTORY SYSTEM

### InventoryManager.gd - Grid-Based Inventory

**Specs:**
- 50 total slots
- Stackable items with max_stack limits
- Signals on item add/remove/slot change

**Item Types:**
1. Dragon Parts (fire_head, ice_body, etc.)
2. Consumables (treat, health_potion, food, toy)

**Operations:**
- `add_item_by_id(item_id, quantity)` - Returns true if all added
- `remove_item_by_id(item_id, quantity)` - Returns actual amount removed
- `get_item_count(item_id)` - Total across all slots
- `get_all_dragon_parts()` - Array of parts with quantities
- `can_craft_dragon(head_id, body_id, tail_id)` - Check if parts available

---

## 9. AUDIO AND VISUAL EFFECTS

### AudioManager.gd

**Singleton Audio System:**

**Music:**
- Menu Music: "Dragon Lab Blues.mp3" (looping)
- Gameplay Music: "The Clockwork Ghost.mp3" (looping)

**Sound Effects:**
- Scientist Hired: "ReadyToWork.mp3"
- Dragon Finished: "DragonsFinished.mp3"
- Dragon Roar: "Undead_dragon_roar-1761092513184.mp3"

**Volume Control:**
- Separate control for music and SFX
- All routed to Master audio bus

### LightningEffect.gd - Visual Effect

**Triggered during:**
- Dragon creation (shows excitement/magic)

**Effect:**
- 8 simultaneous lightning bolts across screen
- 12 segments per bolt with random jagged offsets
- Lightning width: 3.0 pixels
- Flash interval: 150ms between updates
- Duration: 50ms per flash

---

## 10. EXPERIENCE AND LEVELING

### Experience System

**Experience Curve:**
```
Level 2: 100 XP
Level 3: 100 + 150 = 250 XP
Level 4: 100 + 150 + 225 = 475 XP
...
Formula: Sum of (100 * 1.5^(i-2)) for i from 2 to target_level

Max Level: 10
```

**XP Sources:**
- Defense waves: 50 * wave_number per dragon
- Exploration: 3 base XP per minute (scaled by dragon level)
- Treats: 50 XP per treat used
- Trainer scientist: 10 XP every 30 seconds (TRAINING state only)

**Level Up:**
- Recalculate all stats
- Emit level_up signal
- Can level up multiple times from single large XP gain

---

## 11. HAPPINESS SYSTEM

### Happiness Mechanics (DragonStateManager.gd)

**Happiness Range:** 0.0 (sad) to 1.0 (happy), starts at 0.5

**Decay:**
- Base: -0.5% per minute (every 30 second update = -0.0041666%)

**Happiness Boost:**
- Toy Equipped: +2% per minute
- Treat Used: +15% per treat
- Toy Equipped effectively = 1.5% net per minute

**UI Display:** Shows as percentage in dragon details modal

---

## 12. UI SYSTEMS AND MODALS

### Dragon Details Modal (dragon_details_modal.gd)

**Sections:**

1. **Dragon Visual:** Color representation from parts
2. **Stats Display:**
   - Level, Attack, Health, Speed, XP progress
   - Defense, Primary Element, Elemental Attack Bonus
   - Secondary Elements, Elemental Resistances

3. **Status Section:**
   - Current State (Idle/Defending/Exploring/Training/Resting)
   - Hunger percentage
   - Fatigue percentage
   - Happiness percentage
   - Toy slot status

4. **Items Section:**
   - Use Treat button (+XP/Happy)
   - Use Health Potion button (full heal)

5. **Toy Slot:**
   - Shows equipped toy or "No toy equipped"
   - Equip/Unequip toggle button

6. **Action Buttons:**
   - Feed (consumes food, reduces hunger 25%)
   - Train (toggle, grants XP over time)
   - Rest (toggle, recovers fatigue faster)
   - Defend (toggle, adds to defense team)

7. **Exploration Section:**
   - Shows remaining time if exploring
   - 15/30/60 minute buttons (shows "sec" in dev mode)
   - Status: "Ready to explore" / "Too fatigued" / "Exploring..."

### Other Modal Dialogs

**Scientist Hire Modal:** Shows scientist options, costs, descriptions
**Explore Return Popup:** Displays rewards when dragon completes exploration
**Part Selector:** UI for choosing parts when creating dragons

---

## 13. GAME CONSTANTS AND FORMULAS

### Time Constants (all in seconds)

```
Hunger Rate: 1% per 60 seconds (0.01/60)
Hunger Starvation Point: 100 minutes (6000 seconds)
Fatigue Time: 45 minutes (2700 seconds) to max fatigue
Fatigue Rest Time: 15 minutes (900 seconds) to full recovery
```

### Level Progression

```
MAX_LEVEL: 10
EXP_BASE: 100
EXP_MULTIPLIER: 1.5
Formula: 100 * 1.5^(level-2)
```

### Mutation

```
MUTATION_CHANCE: 1% (0.01)
CHIMERA_STAT_MULTIPLIERS:
- Attack: 2.5x
- Health: 2.0x
- Speed: 1.5x
- Defense: 2.0x
```

### Combat Constants

```
FATIGUE_PER_COMBAT: 10% (0.1)
FATIGUE_RECOVERY_RATE: 5% per minute (0.05)
COMBAT_XP_BASE: 10 per victory
```

---

## 14. SAVE/LOAD SYSTEM

### Serialization Methods

**Entities with save support:**
- Dragon (Resource extends)
- TreasureVault (to_dict/from_dict)
- InventoryManager (to_dict/from_dict)
- DefenseManager (to_dict/from_dict)

**Data Persisted:**
- All dragon stats, level, XP
- Vault gold, parts, artifacts
- Inventory slots and items
- Defense wave number, timer
- Scientists (hired status, timers)

---

## 15. KEY FORMULAS SUMMARY

### Dragon Damage Formula
```
Elemental Damage = Base Attack * Elemental Bonus
Final Damage = Elemental Damage * Target Resistance
Mixed Element Bonus = +15% per secondary weakness
```

### Experience Requirement
```
XP_Required(level) = Sum of (100 * 1.5^(i-2)) for i from 2 to level
```

### Vault Difficulty Scaling
```
Attack Frequency = 1.0 + (vault_tier * 0.2)
Attack Difficulty = 1.0 + (vault_tier * 0.4)
```

### Exploration Reward Scaling
```
Gold = (BASE_GOLD * duration_minutes) * (1.0 + (level-1)*0.15)
XP = (BASE_XP * duration_minutes) * (1.0 + (level-1)*0.15)
```

---

## 16. PROJECT STRUCTURE

```
/scripts/
  /dragon_system/
    dragon.gd                 - Core dragon class
    dragon_factory.gd         - Dragon creation
    dragon_state_manager.gd   - State & life system management
    dragon_part.gd           - Part definition
    part_library.gd          - Part registry & queries
    
  /managers/
    treasure_vault.gd        - Resource storage
    exploration_manager.gd   - Exploration missions
    scientist_manager.gd     - Scientist automation
    defense_manager.gd       - Wave-based combat
    audio_manager.gd         - Audio playback
    
  /inventory/
    inventory_manager.gd     - Grid-based inventory
    inventory_slot.gd        - Individual slot management
    item.gd                  - Item definition
    item_database.gd         - Item registry
    
  /ui/
    dragon_details_modal.gd  - Main dragon management UI
    dragon_card.gd           - Dragon display card
    dragon_visual.gd         - Dragon color rendering
    scientist_panel.gd       - Scientist management UI
    factory_manager.gd       - Dragon creation UI
    dragon_tooltip.gd        - Info tooltips
    
  /effects/
    lightning_effect.gd      - Visual effect
    
/data/
  items.json                 - Item database

/resources/
  DragonResource.gd          - Dragon save format
  DragonPartResource.gd      - Part save format
```

---

## 17. DEBUGGING AND TESTING

### Dev Mode Features

**Exploration Manager:**
- `DEV_MODE = true` uses seconds instead of minutes
- 15 min = 15 sec, 30 min = 30 sec, 60 min = 60 sec

**DragonStateManager Debug Functions:**
- `force_hunger(dragon, 0.0-1.0)` - Set hunger
- `force_fatigue(dragon, 0.0-1.0)` - Set fatigue
- `force_damage(dragon, percent)` - Damage dragon
- `force_level_up(dragon, target_level)` - Set level
- `force_mutation(dragon)` - Force Chimera mutation
- `simulate_time_passage(dragon, hours)` - Skip time
- `reset_dragon_state(dragon)` - Perfect condition

**Manager Debug Functions:**
- `DefenseManager.force_next_wave()` - Trigger wave immediately
- `ExplorationManager.print_exploration_status()` - Debug output
- `TreasureVault.print_vault_status()` - Vault details
- `InventoryManager.print_inventory()` - Inventory details

---

This documentation covers all major game systems and their mechanics. Key design principles:
1. Singleton managers for global systems
2. Signals for event-driven updates
3. Time-based AFK mechanics
4. Risk/reward scaling with player progression
5. Comprehensive stat formula system with elements and synergies
