# Playful Game Jam - Quick Reference Guide

## Dragon Stats Quick Reference

### Base Stats Formula
```
Attack   = 10 + (head.attack * level)
Health   = 50 + (body.health * level)
Speed    = 5 + (tail.speed * level)
Defense  = 5 + (body.defense * level)
```

### Element Bonuses
- **Fire:** +3 attack
- **Ice:** +3 health, +3 defense
- **Lightning:** +3 speed
- **Nature:** +2 balanced
- **Shadow:** +2 attack, +2 defense

### Synergy Bonuses
- **All 3 Same:** +5 ATK, +10 HP, +2 SPD, +3 DEF per level
- **2 Same:** +2 ATK, +5 HP, +1 SPD, +1 DEF per level

### Chimera Mutation (1% chance)
- 2.5x Attack, 2.0x Health, 1.5x Speed, 2.0x Defense
- +0.2 elemental attack bonus

---

## Exploration Quick Reference

### Rewards (30 min example, Level 1 dragon)
- Gold: 60 base (2 × 30)
- XP: 90 base (3 × 30)
- Parts: 1-2 random
- Items: 2 rolls per type

### Fatigue Cost
- 15 min: +15%
- 30 min: +25%
- 60 min: +40%

### Damage Risk
- 15 min: 15% chance 10-20% damage
- 30 min: 25% chance 15-30% damage
- 60 min: 35% chance 20-40% damage

---

## Scientist Costs & Functions

| Scientist | Hire Cost | Ongoing | Function |
|-----------|-----------|---------|----------|
| Stitcher | 50 gold | 2/min | Auto-create dragons |
| Caretaker | 100 gold | 3/min | Auto-feed & heal |
| Trainer | 150 gold | 5/min | Auto-grant XP |

---

## Hunger & Fatigue System

### Hunger
- Rate: 1% per minute
- Starvation point: 100 minutes (6000 sec)
- Damage: 10% health/hour when starving
- Death: When health <= 0 + starving

### Fatigue Recovery
- IDLE: -1% per 30 sec (50 min full recovery)
- RESTING: -4.5% per 30 sec (11 min full recovery)

### Happiness
- Decay: -0.5% per minute
- Toy Equipped: +2% per minute (net +1.5%)
- Treat: +15% per treat

---

## Defense Wave Scaling

### Enemies Per Wave
- Wave 1: 1 enemy
- Wave 5: 1-2 enemies
- Wave 10: 2 enemies + 1 BOSS

### Enemy Stats Growth
```
Knight Attack   = (10 + wave*3) × difficulty
Knight Health   = (50 + wave*10) × difficulty
Boss Attack     = (25 + wave*6) × difficulty
Boss Health     = (150 + wave*20) × difficulty
```

### Difficulty Multiplier
- Tier 1 vault: 1.4x
- Tier 2 vault: 1.8x
- Tier 5 vault: 3.0x

### Raid Loss
- Wave 1: 15% loss
- Wave 10: 25% loss
- Wave 15+: 30% (capped)

---

## Resource Values

| Resource | Vault Value |
|----------|-------------|
| 1 Gold | 1 value |
| 1 Part | 20 value |
| 1 Artifact | 100 value |
| 1 Treat/Potion/Food/Toy | 10 value |

---

## XP Requirements

| Level | Total XP Needed |
|-------|-----------------|
| 2 | 100 |
| 3 | 250 |
| 4 | 475 |
| 5 | 867 |
| 6 | 1,550 |
| 7 | 2,825 |
| 8 | 5,237 |
| 9 | 9,855 |
| 10 | 18,582 |

Formula: Sum of (100 × 1.5^(i-2)) for i from 2 to target level

---

## Elemental Resistance Chart

### Rock-Paper-Scissors Weaknesses
```
Fire    ← weak to → Ice
Ice     ← weak to → Fire
Lightning ← weak to → Nature
Nature  ← weak to → Shadow
Shadow  ← weak to → Lightning
```

### Resistance Values
- 1.0x = Normal damage
- < 1.0x = Resistant (takes less)
- > 1.0x = Weak (takes more)
- Range: 0.5x to 1.5x

---

## Dragon States

```
IDLE       - Doing nothing, normal recovery
DEFENDING  - In defense wave (max 3 simultaneous)
EXPLORING  - On mission (15/30/60 min)
TRAINING   - Getting XP (+10/30sec from Trainer)
RESTING    - Fast fatigue recovery (-4.5%/30sec)
DEAD       - Permanent (no revival)
```

---

## Key Formulas

### Exploration Reward Scaling
```
Gold Multiplier = 1.0 + (level - 1) × 0.15
XP Multiplier = 1.0 + (level - 1) × 0.15
```

### Defense Power
```
Base = attack + (health × 0.5) + (speed × 0.3)
Hunger Penalty = 1.0 - (hunger × 0.2)
Fatigue Penalty = 1.0 - (fatigue × 0.15)
Final = base × hunger_penalty × fatigue_penalty
```

### Elemental Damage
```
Damage = base_attack × elemental_bonus × target_resistance
Pure Dragon Bonus = 1.3x
Hybrid Dragon Bonus = 1.15x
Mixed Dragon Bonus = 1.0x + (0.15 per secondary weakness)
```

---

## Dev Mode Settings

### Exploration Manager
- Set `DEV_MODE = true` for quick testing
- 15 min = 15 sec, 30 min = 30 sec, 60 min = 60 sec

### Debug Functions
```gdscript
# Dragon state management
DragonStateManager.force_hunger(dragon, 0.5)      # 50% hunger
DragonStateManager.force_fatigue(dragon, 0.8)     # 80% fatigue
DragonStateManager.force_damage(dragon, 0.3)      # 30% damage
DragonStateManager.force_level_up(dragon, 10)     # Level to 10
DragonStateManager.force_mutation(dragon)         # Force chimera

# Wave testing
DefenseManager.force_next_wave()                   # Start wave now

# Exploration
ExplorationManager.print_exploration_status()     # Debug output
ExplorationManager.complete_all_explorations()    # Finish all
```

---

## Item IDs

### Dragon Parts
- fire_head, ice_head, lightning_head, nature_head, shadow_head
- fire_body, ice_body, lightning_body, nature_body, shadow_body
- fire_tail, ice_tail, lightning_tail, nature_tail, shadow_tail

### Consumables
- treat (50 XP + 15% happiness)
- health_potion (full heal)
- food (25% hunger reduction)
- toy (equip for +2% happiness/min)

---

## Vault Tiers

| Tier | Value Range | Unlocks |
|------|-------------|---------|
| 0 | 0-499 | - |
| 1 | 500-1499 | 1st Scientist |
| 2 | 1500-4999 | - |
| 3 | 5000-9999 | 2nd Scientist |
| 4 | 10000-24999 | Protected Storage |
| 5 | 25000+ | 3rd Scientist, Mastery |

---

## File Locations

**Key Scripts:**
- `/scripts/dragon_system/dragon.gd` - Core dragon class
- `/scripts/managers/exploration_manager.gd` - Exploration
- `/scripts/managers/scientist_manager.gd` - Scientists
- `/scripts/managers/defense_manager.gd` - Waves
- `/scripts/ui/dragon_details_modal.gd` - Dragon UI

**Data:**
- `/data/items.json` - Item database
- `/GAME_SYSTEMS_DOCUMENTATION.md` - Full documentation

