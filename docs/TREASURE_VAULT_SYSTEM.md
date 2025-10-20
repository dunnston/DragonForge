# Treasure Vault System - Integration Guide

## 🏛️ Overview

The **Treasure Vault** is the central resource management system for Frankenstein Dragon Factory. It replaces the simple ResourceManager with a thematic, visual, and strategic system where:

- Your treasure **grows** as dragons succeed in exploration and defense
- Your treasure **shrinks** when you lose defense battles
- More treasure = **stronger and more frequent attacks** (risk/reward)
- **Milestone rewards** unlock new features as your vault grows
- **Protected storage** can be unlocked to safeguard precious resources

---

## 🎯 Core Features

### 1. Resource Storage
**Gold** - Primary currency
- Used to hire scientists
- Used to upgrade scientists
- Earned from defense victories and exploration

**Dragon Parts** (by element)
- Required to build new dragons (1 of each part type)
- Earned from defense victories and exploration
- 5 types: FIRE, ICE, LIGHTNING, NATURE, SHADOW

**Artifacts** (future expansion)
- Special rare items from exploration
- High value (100g each)
- Can unlock unique features

### 2. Protected Storage
**Unlocked at 2,500 gold milestone**

- Move resources from vulnerable → protected storage
- Protected resources **cannot be stolen** when defense fails
- Strategic choice: protect resources or risk them for faster growth

### 3. Vault Tiers (Visual System)
The vault has 6 visual tiers based on total value:

| Tier | Value Required | Visual Color | Attack Multiplier |
|------|---------------|--------------|-------------------|
| 1 | 0g | Bronze | 1.0x |
| 2 | 500g | Silver | 1.4x |
| 3 | 1,500g | Gold | 1.8x |
| 4 | 5,000g | Pink (Gems) | 2.2x |
| 5 | 10,000g | Cyan (Magic) | 2.6x |
| 6 | 25,000g | Legendary Gold | 3.0x |

**Total Vault Value** = Gold + (Parts × 20g each) + (Artifacts × 100g each)

### 4. Milestone Rewards

| Gold Value | Reward | Description |
|------------|--------|-------------|
| 500 | First Scientist Slot | Can hire your first scientist |
| 1,000 | Second Scientist Slot | Can hire a second scientist |
| 2,500 | Protected Storage | Unlock vault protection feature |
| 5,000 | Third Scientist Slot | Can hire a third scientist |
| 10,000 | Builder Scientist | Unlock Builder scientist type |
| 25,000 | Vault Mastery | ??? (future expansion) |

### 5. Risk/Reward System

**More treasure = More danger!**

**Attack Difficulty Multiplier**
- Formula: `1.0 + (vault_tier * 0.4)`
- Tier 1: 1.0x (normal)
- Tier 6: 3.0x (HARD!)

**Attack Frequency Multiplier**
- Formula: `1.0 + (vault_tier * 0.2)`
- Tier 1: 1.0x (every 5 minutes)
- Tier 6: 2.0x (every 2.5 minutes!)

**Strategic Tension**: Do you hoard resources and face harder attacks, or spend quickly to keep attacks manageable?

### 6. Raid Loss System

When defense fails, you lose resources:

**Loss Calculation**
- Base loss: 15% + (1% per wave number), capped at 30%
- Only **unprotected** resources can be stolen
- Protected resources are always safe
- No defenders = 50% loss!

**Example**:
- You have 1000 gold (500 unprotected, 500 protected)
- You have 10 FIRE parts (7 unprotected, 3 protected)
- Defense fails at wave 5 (20% loss)
- **Lost**: 100 gold (20% of 500), 1 FIRE part (20% of 7)
- **Safe**: 500 protected gold, 3 protected FIRE parts

---

## 🔧 Setup & Integration

### 1. Add to Autoload (Godot Project Settings)

**Project → Project Settings → Autoload**

Add these singletons in order:
1. `TreasureVault` → `res://scripts/managers/treasure_vault.gd`
2. `DefenseManager` → `res://scripts/managers/defense_manager.gd`

### 2. Add to Main Scene

```gdscript
# In your main game scene (e.g., main.gd)
extends Node2D

func _ready():
    # Treasure vault is auto-loaded, just verify it exists
    if TreasureVault.instance:
        print("Treasure Vault loaded successfully!")
        TreasureVault.instance.print_vault_status()

    # Connect to vault signals for UI updates
    TreasureVault.instance.milestone_reached.connect(_on_milestone_reached)
    TreasureVault.instance.vault_tier_changed.connect(_on_vault_tier_changed)

    # Defense manager is also auto-loaded
    if DefenseManager.instance:
        print("Defense Manager loaded successfully!")
        DefenseManager.instance.wave_incoming.connect(_on_wave_incoming)
        DefenseManager.instance.wave_completed.connect(_on_wave_completed)

func _on_milestone_reached(value: int, reward_id: String):
    # Show celebration UI
    print("🎉 MILESTONE: %d gold - Unlocked: %s" % [value, reward_id])

func _on_vault_tier_changed(new_tier: int, old_tier: int):
    if new_tier > old_tier:
        print("⬆️ Vault tier increased to %d!" % new_tier)
    else:
        print("⬇️ Vault tier decreased to %d" % new_tier)

func _on_wave_incoming(time_remaining: float):
    print("⚠️ WAVE INCOMING IN %.0fs!" % time_remaining)

func _on_wave_completed(victory: bool, rewards: Dictionary):
    if victory:
        print("✅ VICTORY! +%d gold" % rewards.get("gold", 0))
    else:
        print("❌ DEFEAT! Check your vault for losses")
```

### 3. Add Visual Display (Optional but Recommended)

Create a UI scene with the TreasureVaultDisplay script:

```
Control (TreasureVaultDisplay script)
├── VaultContainer
│   ├── TreasurePile (ColorRect - grows/shrinks)
│   ├── GoldLabel (Label - shows gold)
│   ├── TierLabel (Label - shows tier)
│   └── PartsContainer (VBoxContainer - lists parts)
└── MilestonePopup (Control - celebration UI)
```

---

## 📖 Usage Examples

### Example 1: Dragon Returns from Exploration

```gdscript
# In ExplorationManager when exploration completes
func _complete_exploration(dragon_id: String):
    # ... exploration logic ...

    # Calculate rewards
    var gold_reward = 20 * duration_minutes
    var parts_reward = 1 + (duration_minutes / 30)

    # Add to vault
    TreasureVault.instance.add_gold(gold_reward)
    for i in parts_reward:
        var random_element = DragonPart.Element.values().pick_random()
        TreasureVault.instance.add_part(random_element)

    # Grant XP to dragon
    DragonStateManager.instance.gain_experience(dragon, 30 * duration_minutes)
```

### Example 2: Player Hires a Scientist

```gdscript
# In ScientistManager
func hire_scientist(job_type: Scientist.Job) -> Scientist:
    var cost = _get_hire_cost(job_type)

    # Check milestone (scientist slots unlocked?)
    var slots_available = 0
    if TreasureVault.instance.has_reached_milestone(500):
        slots_available += 1
    if TreasureVault.instance.has_reached_milestone(1000):
        slots_available += 1
    if TreasureVault.instance.has_reached_milestone(5000):
        slots_available += 1

    if scientists.size() >= slots_available:
        print("Need more vault value to hire more scientists!")
        return null

    # Spend gold from vault
    if not TreasureVault.instance.spend_gold(cost):
        print("Not enough gold! Need %d" % cost)
        return null

    # Create scientist
    var scientist = Scientist.new()
    scientist.job_type = job_type
    scientists.append(scientist)

    return scientist
```

### Example 3: Player Builds a Dragon

```gdscript
# In DragonFactory
func create_dragon(head: DragonPart.Element, body: DragonPart.Element, tail: DragonPart.Element) -> Dragon:
    # Check if player has parts
    if not TreasureVault.instance.can_build_dragon(head, body, tail):
        print("Not enough parts!")
        return null

    # Spend parts from vault
    TreasureVault.instance.spend_part(head, 1)
    TreasureVault.instance.spend_part(body, 1)
    TreasureVault.instance.spend_part(tail, 1)

    # Create dragon
    var dragon = Dragon.new()
    dragon.head_part = PartLibrary.instance.get_part(DragonPart.Type.HEAD, head)
    dragon.body_part = PartLibrary.instance.get_part(DragonPart.Type.BODY, body)
    dragon.tail_part = PartLibrary.instance.get_part(DragonPart.Type.TAIL, tail)

    # ... rest of dragon creation ...

    return dragon
```

### Example 4: Defense Wave Victory

```gdscript
# In DefenseManager (already implemented)
func _apply_rewards(rewards: Dictionary):
    # Add gold
    TreasureVault.instance.add_gold(rewards["gold"])

    # Add random parts
    for i in rewards["parts"]:
        var random_element = DragonPart.Element.values().pick_random()
        TreasureVault.instance.add_part(random_element)
```

### Example 5: Defense Wave Defeat

```gdscript
# In DefenseManager (already implemented)
func _apply_raid_loss():
    # Calculate loss percentage (higher waves = bigger losses)
    var loss_percentage = min(0.30, 0.15 + (wave_number * 0.01))

    # Apply loss to vault (only unprotected resources stolen)
    var stolen = TreasureVault.instance.apply_raid_loss(loss_percentage)

    print("Raiders stole %d gold!" % stolen["gold"])
    # Player's protected resources are safe!
```

### Example 6: Player Protects Resources

```gdscript
# In UI when player clicks "Protect 100 Gold" button
func _on_protect_gold_button_pressed():
    # Check if protected storage is unlocked
    if not TreasureVault.instance.has_reached_milestone(2500):
        show_tooltip("Reach 2,500 gold to unlock protected storage!")
        return

    # Protect gold
    if TreasureVault.instance.protect_gold(100):
        print("Protected 100 gold from raids!")
    else:
        print("Not enough unprotected gold!")
```

---

## 🧪 Testing

### Quick Test in Godot Console

```gdscript
# Add gold
TreasureVault.instance.add_gold(500)

# Add parts
TreasureVault.instance.add_part(DragonPart.Element.FIRE, 5)
TreasureVault.instance.add_part(DragonPart.Element.ICE, 3)

# Check vault status
TreasureVault.instance.print_vault_status()

# Test raid loss
TreasureVault.instance.apply_raid_loss(0.25)  # Lose 25%

# Protect some resources
TreasureVault.instance.protect_gold(200)
TreasureVault.instance.protect_part(DragonPart.Element.FIRE, 2)

# Test another raid
TreasureVault.instance.apply_raid_loss(0.25)  # Protected resources safe!

# Check status again
TreasureVault.instance.print_vault_status()
```

### Test Defense Wave

```gdscript
# Assign a dragon to defense
DefenseManager.instance.assign_dragon_to_defense(my_dragon)

# Force next wave immediately (for testing)
DefenseManager.instance.force_next_wave()

# Check vault after wave
TreasureVault.instance.print_vault_status()
```

---

## 🎮 Player Experience

### Early Game (Tier 1-2)
- Start with 100 gold, 5 parts (1 of each element)
- Build your first dragon
- Defend against weak knights (1-2 enemies)
- Earn ~10-20 gold per wave
- Send dragon exploring for 15 minutes → 20 gold, 1 part
- After ~5 waves: Reach 500 gold milestone → Hire first scientist!

### Mid Game (Tier 3-4)
- 2-3 dragons defending
- 1-2 scientists automating tasks
- Waves getting harder (more enemies, more damage)
- Risk/reward decision: Spend gold to hire scientists OR hoard for milestones?
- Some defeats happen → lose resources but not game-ending
- Unlock protected storage at 2,500g → can safeguard precious resources

### Late Game (Tier 5-6)
- 3+ dragons, fully automated by scientists
- Vault overflowing with treasure
- Attacks are HARD and FREQUENT
- Strategic resource protection essential
- Builder scientist creating new dragons automatically
- Collection completion gameplay

---

## 🔄 Integration with Save/Load

The Treasure Vault serializes all state:

```gdscript
# In SaveManager
func save_game():
    var save_data = {
        "vault": TreasureVault.instance.to_dict(),
        "defense": DefenseManager.instance.to_dict(),
        # ... other systems ...
    }
    # Save to file

func load_game():
    # Load from file
    TreasureVault.instance.from_dict(save_data["vault"])
    DefenseManager.instance.from_dict(save_data["defense"])
    # ... other systems ...
```

---

## 📊 Balance Tuning

### Current Values (Adjust as needed)

**Starting Resources**:
- Gold: 100
- Parts: 1 of each element (5 total)

**Defense Rewards**:
- Gold: 10 + (wave_number × 5) per enemy
- Parts: 1 per enemy

**Exploration Rewards**:
- Gold: 20 × duration_minutes
- Parts: 1 + (duration_minutes / 30)
- XP: 30 × duration_minutes

**Scientist Costs**:
- Feeder: 50 gold
- Healer: 100 gold
- Trainer: 150 gold
- Builder: 200 gold

**Loss on Defeat**:
- Base: 15% + (1% per wave), max 30%
- No defenders: 50%

**Part Value**:
- 20 gold each (for vault value calculation)

---

## 🚀 Future Expansion Ideas

1. **Artifact System**: Rare items from exploration with unique effects
2. **Vault Upgrades**: Expand protected storage capacity
3. **Insurance**: Pay gold to reduce raid losses
4. **Decoy Vault**: Fake treasure to reduce attack difficulty
5. **Vault Traps**: Damage raiders for extra rewards
6. **Prestige System**: "Bank" vault and reset for permanent bonuses

---

## ✅ Implementation Checklist

- [x] Create TreasureVault.gd singleton
- [x] Create TreasureVaultDisplay.gd UI script
- [x] Create DefenseManager.gd with vault integration
- [ ] Add TreasureVault to autoload
- [ ] Add DefenseManager to autoload
- [ ] Create UI scene with TreasureVaultDisplay
- [ ] Connect vault signals to UI
- [ ] Test full gameplay loop:
  - [ ] Start game → Has initial resources
  - [ ] Win defense → Gain resources → Vault grows
  - [ ] Lose defense → Lose resources → Vault shrinks
  - [ ] Reach milestone → Unlock feature
  - [ ] Protect resources → Safe from raids
  - [ ] Save/load → State preserved

---

## 🎯 Summary

The **Treasure Vault** system transforms resource management from abstract numbers into a tangible, strategic, and thematic system:

✅ **Thematic**: Dragons defend treasure from knights (core fantasy)
✅ **Visual**: Vault grows/shrinks based on wealth (satisfying feedback)
✅ **Strategic**: Risk/reward tension (hoard or spend?)
✅ **Progressive**: Milestones unlock features (sense of advancement)
✅ **Forgiving**: Protected storage prevents total loss (not punishing)

This replaces the simple ResourceManager from the original plan with something much more engaging and fitting for a game jam project!

---

**Questions?** Check the code comments in `treasure_vault.gd` for detailed explanations!
