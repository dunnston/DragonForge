# DragonForge
## Complete Game Design Document
### Playful AI Game Jam Submission - October 2025

---

## 📋 Executive Summary

**Title**: DragonForge
**Genre**: Idle Management / Virtual Pet Simulator / Tower Defense Hybrid
**Platform**: Web (HTML5), with future mobile support
**Target Audience**: Casual gamers, idle game fans, pet simulation enthusiasts (Ages 13+)
**Elevator Pitch**: You're the head scientist of a dragon genetics laboratory. Create Frankenstein-style dragons from mismatched parts, hire assistant scientists to automate care, defend against knight raids, and grow from a scrappy one-dragon operation into a fully automated dragon empire—all while you're AFK.

**Core Hook**: "What if you ran a mad science lab that Frankensteins dragons together, and it kept working while you slept?"

---

## 🎮 Game Overview

### High Concept
DragonForge cmbines the engagement of virtual pet care (Tamagotchi), the satisfaction of automation progression (Factorio), and the strategic depth of tower defense—all wrapped in an AFK-friendly package where your laboratory keeps running even when you're away.

### Genre Blend
- **60% Idle Management**: Core progression happens through automation
- **25% Virtual Pet**: Direct dragon care creates emotional attachment
- **15% Tower Defense**: Strategic dragon assignment for defense

### Unique Selling Points
1. **Frankenstein Creation System**: 125+ unique dragons from mixing body parts
2. **Manual → Automated Progression**: Start hands-on, end as overseer
3. **Chimera Mutations**: Rare 1% chance for dramatically powerful dragons
4. **AI-Powered Scientists**: Assistants learn your playstyle and optimize automatically
5. **Cross-Session Continuity**: Real progress while AFK with meaningful catch-up rewards

---

## 🏗️ Game Vision: Two Versions

### Version 1.0: Game Jam MVP (Current Build)
**Scope**: 7-day development sprint
**Focus**: Core loop proof-of-concept with essential AFK mechanics

**Feature Set**:
- Dragon creation (5 elements × 3 body parts = 125 combinations)
- Manual dragon care (feed, heal, train)
- Knight raid defense system (wave-based combat)
- Exploration missions (timed expeditions)
- Scientist automation (4 types: Feeder, Healer, Trainer, Builder)
- Resource management (gold + dragon parts)
- Save/load system
- AI integration (dragon names + scientist behavior)
- Chimera mutation system

**Gameplay Duration**: 2-4 hour satisfying loop, infinite replayability

---

### Version 2.0: Full Vision (Post-Jam)
**Scope**: 3-6 month development cycle
**Focus**: Expand into full-featured game with exploration and social features

**Major Additions**:

#### 1. Laboratory Exploration (2D Top-Down)
**Overview**: Transform from menu-based to explorable world
- **Laboratory Building**:
  - Walk through your lab with WASD/Arrow keys
  - Multiple rooms: Breeding Chamber, Training Grounds, Medical Bay, Storage Vault
  - Interact with dragons directly (click to feed/pet/train)
  - Scientists visible as NPCs moving between stations
  - Visual progression: Lab upgrades reflected in environment

- **Dragon Interactions**:
  - Pet dragons for happiness boost
  - Watch them perform animations (eating, sleeping, training)
  - See personality traits emerge based on care quality
  - Unlock dragon idle behaviors (playing, sunbathing, sparring)

#### 2. Town Hub & NPC System
**Overview**: Vibrant town where you interact with the world
- **Town Layout**:
  - Central Plaza (quest board, social hub)
  - Marketplace (shops and trading)
  - Guild Hall (multiplayer/cooperative features)
  - Dragon Arena (PvP battles)
  - Research Library (lore and unlockables)

- **NPC Merchants**:
  - **Parts Dealer**: Sells random dragon parts (refreshes daily)
  - **Equipment Vendor**: Scientist upgrade tools and dragon accessories
  - **Black Market Broker**: Rare/legendary parts at premium prices
  - **Quest Giver NPCs**: Daily/weekly missions for rewards

- **NPC Interactions**:
  - Dialogue trees with story progression
  - Relationship system (unlock discounts, exclusive items)
  - Rival scientists competing for prestige
  - Town events (festivals, tournaments, special raids)

#### 3. Advanced Shop System
**Multiple Shop Types**:

**Dragon Parts Emporium**:
- Common parts: 50 gold
- Rare parts: 200 gold (2x stat bonus)
- Epic parts: 500 gold (3x stats + visual glow)
- Legendary parts: 1000 gold (unique abilities)
- Mystery boxes: Random rarity guaranteed

**Scientist Academy**:
- Hire additional scientists (up to 10 total)
- Specialist classes:
  - **Geneticist**: Increases mutation chance
  - **Combat Trainer**: Doubles defense XP gain
  - **Explorer**: Reduces exploration time by 50%
  - **Archaeologist**: Finds blueprint fragments
- Scientist cosmetics (lab coats, tools, animations)

**Laboratory Upgrades**:
- Dragon capacity: +1 slot (up to 20 dragons)
- Automation speed boosts
- Quality-of-life improvements (auto-assign, batch operations)
- Visual upgrades (decorations, themes)

**Dragon Accessories**:
- Collars (stat bonuses)
- Armor (defense boost)
- Wings (exploration speed)
- Toys (happiness/training efficiency)

#### 4. Expanded Crafting System
**Resource Types**:
- Dragon parts (Fire, Ice, Lightning, Nature, Shadow)
- Essence fragments (extracted from retired dragons)
- Blueprint scrolls (combine parts in specific ways)
- Mutation catalysts (increase chimera chance)
- Ancient relics (exploration rewards)

**Crafting Recipes**:
- **Dragon Fusion**: Combine 2 dragons → 1 superior hybrid (stats averaged + bonus)
- **Essence Extraction**: Retire old dragon → gain parts + essence
- **Blueprint Crafting**: Use recipe to guarantee specific dragon
- **Mutation Enhancement**: Spend catalyst for guaranteed mutation
- **Equipment Forging**: Craft accessories from exploration loot

**Crafting Station**:
- Alchemy Lab: Potion brewing (temporary stat boosts)
- Forge: Equipment and tools
- Gene Splicer: Advanced dragon manipulation
- Ritual Circle: Legendary dragon summons

#### 5. Achievement System
**Categories**:

**Collection Achievements**:
- "Draconic Census": Create 25/50/100/125 unique dragons
- "Element Master": Create 10 dragons of each element
- "Chimera Hunter": Obtain 5 chimera mutations
- "Rainbow Collection": Own one dragon with every part combination type

**Progression Achievements**:
- "Factory Foreman": Hire 5 scientists
- "Defense Veteran": Survive 100 knight raids
- "Exploration Expert": Complete 50 expeditions
- "Treasure Hoard": Accumulate 10,000 gold
- "Dragon Tycoon": Own 10 dragons simultaneously

**Combat Achievements**:
- "Flawless Victory": Win raid without losing health
- "Legendary Defense": Defeat mega-wave boss
- "Speed Run": Win raid in under 30 seconds
- "Underdog": Win with dragons 5 levels below enemies

**Special Achievements**:
- "Mad Scientist": Create 3 chimeras in one session
- "Dragon Whisperer": Max happiness on 10 dragons
- "AFK Master": Earn 1000 gold while offline
- "Town Hero": Complete all NPC quests

**Rewards**:
- Gold bonuses
- Exclusive parts/blueprints
- Cosmetic unlocks (scientist outfits, lab themes)
- Titles and badges
- Stat multipliers

#### 6. Enhanced AI Systems
**Smart Scientist Behavior**:
- **Learning Algorithm**: Scientists track your decisions:
  - Which dragons you keep vs retire
  - Preferred element combinations
  - Care patterns (frequent feeding vs hands-off)
- **Adaptive Automation**:
  - Builder prioritizes your favorite elements
  - Trainer focuses on dragons you use in defense
  - Feeder learns optimal feeding schedule per dragon
- **Efficiency Reports**: Weekly summary of scientist performance

**AI Quest Generation**:
- Procedurally generated daily quests
- Personalized to your play style:
  - "Create 3 Fire dragons" if you favor Fire
  - "Win 5 raids" if you're combat-focused
  - "Complete 2 long explorations" if you're idle-focused
- Dynamic difficulty scaling

**AI-Driven Economy**:
- Shop prices fluctuate based on your wealth
- Rare parts become available when you're ready
- Event timing adapts to your play sessions

#### 7. Multiplayer Features
**Asynchronous Multiplayer**:
- **Dragon Trading**: Exchange parts/dragons with friends
- **Guild System**:
  - Join labs with 10-50 players
  - Contribute to guild vault for shared upgrades
  - Guild-exclusive raids and challenges
- **Leaderboards**:
  - Dragon collection completion %
  - Total defense wins
  - Rarest chimera owned
  - Guild prestige ranking

**Cooperative Defense**:
- Call for help during raids
- Borrow friend's dragon for 1 raid
- Guild raid bosses require multiple players

---

## 🎯 Core Gameplay Loop

### Game Jam Version (Manual → Automated)

**Phase 1: The Struggling Scientist (First 10 minutes)**
```
Start with 1 dragon → Manually feed/heal/train →
Assign to first defense → Earn 10 gold →
Send on exploration → Wait 15 minutes
```

**Phase 2: First Automation (10-30 minutes)**
```
Return from exploration → 20 gold + parts →
Hire Feeder scientist (50 gold) →
Assign dragon to Feeder → Dragon auto-feeds now! →
Create 2nd dragon with earned parts →
Defend with 2 dragons → Earn more gold
```

**Phase 3: Factory Manager (30+ minutes)**
```
Hire Healer + Trainer scientists →
All care automated → You just assign tasks →
Hire Builder scientist → New dragons auto-created →
You're now making strategic decisions, not doing busywork
```

**Endgame Loop (AFK)**: All systems automated, you return to collect rewards, assign dragons to new tasks, and optimize your factory.

---

### Full Vision Version (Expanded Loop)

**Morning Routine** (5 minutes):
```
Wake up → Open game → Collect offline earnings →
Check town notice board for daily quests →
Visit shop for new parts → Assign new dragons to tasks →
Pet favorite dragons for happiness boost
```

**Active Play Session** (20-30 minutes):
```
Walk around lab → Check scientist performance →
Start new dragon fusion experiment →
Accept NPC quest ("Create 3 Lightning dragons") →
Complete quest → Earn blueprint →
Visit arena for PvP match →
Craft new equipment from exploration loot →
Start 60-minute exploration missions
```

**Evening Check-In** (5 minutes):
```
Return to collect exploration rewards →
Spend gold on scientist upgrades →
Prepare defense squad for overnight raids →
Set auto-functions → Close game →
Factory keeps running!
```

---

## 🐉 Dragon System (Deep Dive)

### Part Anatomy System

**Body Parts** (3):
1. **Head**: Determines Attack stat (10-50 base)
2. **Body**: Determines Health stat (50-200 base)
3. **Tail**: Determines Speed stat (5-30 base)

**Elements** (5):
- 🔥 **Fire**: High attack, bonus vs Nature
- ❄️ **Ice**: High health, bonus vs Lightning
- ⚡ **Lightning**: High speed, bonus vs Ice
- 🌿 **Nature**: Balanced stats, bonus vs Fire
- 🌑 **Shadow**: Critical hit chance, bonus vs all (rare)

### Synergy System
**Matching Elements Bonus**:
- 2 matching parts: +25% to both part stats
- 3 matching parts: +50% to all stats + "Pure [Element]" title
- Example: Full Fire dragon = 50% stronger than mixed elements

**Opposing Elements Penalty**:
- Fire + Ice on same dragon: -10% to both stats
- Lightning + Nature on same dragon: -10% to both stats
- Encourages thoughtful building, not random mixing

### Chimera Mutation (1% Chance)
**Trigger**: During dragon creation, 1 in 100 chance
**Effect**:
- Dragon gains ALL element bonuses
- Base stats multiplied by 2.5×
- Visual: Rainbow shimmer + particle effects + crown icon
- Unique name prefix: "Chimera [Name]"
**Rarity**: Extremely valuable, tradeable at premium

### Dragon Care Needs

**Hunger System**:
- Increases 1.67% per minute (empty in 60 minutes)
- Fed dragons regenerate health at 5% per minute
- Starving dragons lose 2% health per minute
- Death occurs at 0 health from starvation

**Fatigue System**:
- Increases while dragon is active (training, defending, exploring)
- 45 minutes of activity = 100% fatigue
- Must rest for 15 minutes to fully recover
- Fatigue reduces stats by up to 50% at max

**Health System**:
- Can be damaged during failed defense raids
- Regenerates when fed + not hungry
- Critical health (<25%) prevents dragon from working
- Death is permanent without revival item (post-jam feature)

**Happiness System** (Full Vision):
- Increased by: Petting, winning raids, successful exploration
- Decreased by: Starvation, injuries, being idle too long
- High happiness = +10% to all stats
- Low happiness = -10% to all stats

### Leveling & Experience

**Level Range**: 1-10 (game jam) / 1-100 (full vision)

**XP Gain**:
- Training: 10 XP per minute
- Defense wins: 50 XP per wave × wave number
- Exploration: 30 XP per mission × duration multiplier
- Trainer scientist: +5 XP per minute passively

**Level-Up Bonuses**:
- +5% to all base stats per level
- Every 2 levels: Unlock new ability slot (full vision)
- Level 10: Dragon gains "Veteran" title (+10% stats)

**Abilities** (Full Vision Only):
- Unlocked at levels 5/10/20/50/100
- Examples: "Regeneration", "Critical Strike", "Elemental Burst"
- Equipped to customize dragon beyond base stats

---

## 🧪 Scientist System (Deep Dive)

### Scientist Types (Game Jam - 4 Types)

#### 1. Feeder
**Role**: Automated feeding
- **Cost**: 50 gold
- **Base Capacity**: 1 dragon
- **Function**: Auto-feeds assigned dragon when hunger > 50%
- **Upgrade Path**:
  - Level 2 (50g): Capacity +1, feeds at hunger > 40%
  - Level 3 (100g): Capacity +1, feeds at hunger > 30%
  - Level 4 (150g): Capacity +2, instant feeding

#### 2. Healer
**Role**: Automated healing
- **Cost**: 100 gold
- **Base Capacity**: 1 dragon
- **Function**: Auto-heals assigned dragon when health < 70%
- **Upgrade Path**:
  - Level 2 (100g): Capacity +1, heals at < 80%
  - Level 3 (150g): Capacity +1, healing efficiency +25%
  - Level 4 (200g): Capacity +2, full heal instantly

#### 3. Trainer
**Role**: Passive XP generation
- **Cost**: 150 gold
- **Base Capacity**: 1 dragon
- **Function**: Grants 5 XP per minute to assigned training dragon
- **Upgrade Path**:
  - Level 2 (150g): Capacity +1, 7 XP per minute
  - Level 3 (200g): Capacity +1, 10 XP per minute
  - Level 4 (250g): Capacity +2, 15 XP per minute

#### 4. Builder
**Role**: Automated dragon creation
- **Cost**: 200 gold
- **Base Capacity**: Builds 1 dragon per 5 minutes
- **Function**: Auto-creates dragon using random available parts
- **Upgrade Path**:
  - Level 2 (200g): Build time reduced to 4 minutes
  - Level 3 (250g): Build time 3 minutes, smart part selection
  - Level 4 (300g): Build time 2 minutes, +5% mutation chance

### Scientist System (Full Vision - 10+ Types)

**Specialist Scientists** (New):

#### 5. Geneticist
**Role**: Mutation enhancement
- Increases chimera chance by +1% (2% total)
- Can force mutation for 500 gold
- Unlocks gene splicing recipes

#### 6. Combat Tactician
**Role**: Defense optimization
- Analyzes enemy composition, suggests best defenders
- Grants +20% stats to defending dragons
- Auto-swaps defenders between waves based on elements

#### 7. Explorer Guide
**Role**: Exploration efficiency
- Reduces exploration time by 33%
- Doubles exploration rewards
- Unlocks new exploration locations

#### 8. Archaeologist
**Role**: Rare finds
- 25% chance to find blueprint on any exploration
- Unlocks legendary part drops
- Can appraise items for extra gold

#### 9. Alchemist
**Role**: Potion brewing
- Creates temporary stat boost potions
- Can extend dragon lifespan
- Unlocks transmutation (parts → gold)

#### 10. Public Relations Manager
**Role**: Town & social features
- Manages your lab's reputation
- Unlocks special NPC quests
- Increases guild contribution rewards

### AI-Powered Scientist Behavior

**Learning Algorithm**:
```gdscript
# Pseudocode for Builder scientist AI

func smart_part_selection():
    var preferences = analyze_player_history()
    # What elements do they use most?
    # Which dragons do they keep vs retire?
    # What synergies do they prefer?

    var parts = []
    for part_slot in [HEAD, BODY, TAIL]:
        var weights = {
            FIRE: preferences.fire_score,
            ICE: preferences.ice_score,
            # ... etc
        }
        parts.append(weighted_random(weights))

    return parts
```

**Performance Tracking**:
- Scientists show "efficiency rating" (0-100%)
- Based on: Tasks completed, resources saved, time optimization
- Low efficiency = needs upgrade
- High efficiency = reward bonus

---

## ⚔️ Combat System (Deep Dive)

### Knight Raid Defense (Game Jam)

**Wave Mechanics**:
- Wave spawns every 5 minutes (300 seconds)
- Countdown visible in UI
- Can't be paused or skipped
- Missing a defense = auto-loss (no dragons assigned)

**Enemy Types** (Game Jam - 3 types):
1. **Knight**: Balanced stats, common
2. **Mage**: High attack, low health
3. **Boss**: Appears every 10 waves, 2× stats

**Combat Resolution** (Automatic):
```
Dragon Total Power =
  (Attack × 1.0) + (Health × 0.5) + (Speed × 0.3)
  × (1.0 - Hunger × 0.2)  // Hungry dragons weaker
  × (1.0 - Fatigue × 0.15)  // Tired dragons weaker
  × Element_Bonus  // Advantage vs enemy type

Victory if: Dragon_Power >= Enemy_Power × 1.1
```

**Victory Rewards**:
- Gold: 10 + (wave_number × 5)
- Parts: 1 random element per enemy
- XP: 50 × wave_number per dragon

**Defeat Consequences**:
- Each dragon loses: Enemy_Power / Dragon_Count health
- Dragons can die if health reaches 0
- No rewards earned
- Wave counter resets to 1 (penalty)

### Combat System (Full Vision)

**Enemy Variety** (20+ types):
- Knights (tank), Archers (ranged), Mages (magic), Assassins (speed)
- Elite variants (+50% stats)
- Boss types (Legendary Knight, Dragon Slayer, Evil Scientist)

**Elemental Weakness Chart**:
```
Fire > Nature > Lightning > Ice > Fire
Shadow > All (20% bonus) but Rare to defend against
```

**Advanced Combat Features**:
- **Turn-based** (speed determines turn order)
- **Dragon abilities** trigger during combat
- **Combo system**: Multiple dragons of same element = bonus damage
- **Positioning**: Front/middle/back line strategy
- **Critical hits**: Shadow dragons have 25% crit chance

**Raid Types**:
- **Standard**: Every 5 minutes
- **Ambush**: Random, no warning, higher rewards
- **Siege**: 10-wave marathon, accumulating rewards
- **Boss Raid**: Single powerful enemy, epic loot
- **Guild Raid**: Cooperative multiplayer challenge

---

## 🗺️ Exploration System (Deep Dive)

### Exploration Locations (Game Jam - Simple)

**Mission Durations**:
- **Quick Scout** (15 min): 20 gold, 30 XP, 1 part
- **Standard Expedition** (30 min): 40 gold, 60 XP, 2 parts
- **Long Journey** (60 min): 80 gold, 120 XP, 3 parts

**Risk System**:
- 10% chance: Dragon takes 20% health damage
- 5% chance: Dragon finds bonus reward (+1 part)
- 1% chance: Dragon finds blueprint

**Fatigue Cost**:
- 15 min: +15% fatigue
- 30 min: +25% fatigue
- 60 min: +40% fatigue
- Cannot explore if fatigue > 80%

### Exploration System (Full Vision)

**World Map**:
- **5 Regions**: Forest, Mountain, Desert, Tundra, Volcano
- **25 Locations**: Each with unique rewards
- **Unlock System**: Complete exploration to unlock adjacent locations

**Location Types**:

**Resource Nodes** (common):
- Guaranteed gold + parts
- Short duration (10-15 min)
- Low risk, consistent rewards

**Dungeon Challenges** (uncommon):
- Combat encounters
- High XP + rare parts
- Medium duration (30 min)
- Moderate risk

**Treasure Vaults** (rare):
- Huge gold rewards
- Blueprint fragments
- Long duration (60 min)
- High risk (injury chance)

**Mystery Ruins** (legendary):
- Random rewards (could be nothing or jackpot)
- Ancient relics
- Very long duration (120 min)
- High risk but high reward

**Events**:
- Time-limited locations appear randomly
- "Meteor Crash" = guaranteed rare parts
- "Merchant Caravan" = trade parts for gold
- "Lost Dragon Egg" = adopt pre-made dragon

**Expedition Teams**:
- Send multiple dragons together
- Rewards multiplied by team size
- Fatigue shared across team
- Unlock at Level 20

---

## 🏪 Economy & Progression

### Currency Systems

**Gold** (Primary currency):
- Earned from: Defense victories, exploration, selling parts
- Spent on: Scientists, upgrades, shop items
- Starting amount: 100
- Typical endgame bank: 5000+

**Dragon Parts** (Crafting resource):
- 5 types (Fire, Ice, Lightning, Nature, Shadow)
- Earned from: Defense, exploration, part extraction
- Spent on: Creating dragons
- Storage: Unlimited

**Gems** (Premium - Full Vision):
- Earned from: Achievements, rare drops, IAP
- Spent on: Cosmetics, time skips, inventory expansion
- Starting amount: 50 (free)

**Essence** (Endgame - Full Vision):
- Earned from: Retiring level 10+ dragons
- Spent on: Legendary crafting, prestige upgrades
- Hard to acquire, powerful rewards

### Progression Curve

**Early Game** (0-30 minutes):
- Struggling for resources
- Every gold matters
- 1-2 dragons, manual care
- Learning systems

**Mid Game** (30-120 minutes):
- First automation (Feeder hired)
- Starting to accumulate resources
- 3-5 dragons
- Strategic decision-making begins

**Late Game** (2+ hours):
- Full automation (all scientists hired)
- Swimming in resources
- 5-10 dragons
- Optimizing efficiency

**Endgame** (Full Vision):
- Prestige system (reset for bonuses)
- Legendary dragon hunting
- Guild raids and PvP
- Collection completion

### Upgrade Paths

**Scientists**:
- Each level: 50 gold × current_level
- Benefits: Faster, more efficient, higher capacity
- Max level: 5 (game jam) / 10 (full vision)

**Laboratory** (Full Vision):
- Dragon capacity: +1 slot for 200 gold (max 20)
- Automation speed: +10% for 300 gold
- Storage upgrades: +50 inventory for 150 gold
- Visual upgrades: Decorations for 100-500 gold

**Dragons**:
- Cannot directly upgrade (level via XP)
- Can equip accessories (full vision)
- Can gene splice for stat boost (full vision)

---

## 🎨 Art & Visual Design

### Art Style (Current)
**Theme**: Gothic Mad Science Laboratory
- **Color Palette**: Dark purples, neon greens, electric blues
- **Style**: Pixel art / Low-poly 3D (depending on final choice)
- **Inspiration**: Frankenstein + How to Train Your Dragon

### UI Design

**Main Lab Screen**:
```
┌─────────────────────────────────────────┐
│  🏠 LAB  |  👤 SCIENTISTS  |  💰 SHOP   │
├─────────────────────────────────────────┤
│                                          │
│     [Dragon 1]    [Dragon 2]    [+]     │
│      🐉 HP: 80%    🐉 HP: 95%    Create  │
│      🍖 Hunger:    🍖 Hunger:             │
│        60%          20%                  │
│      ⚡ Fatigue:   ⚡ Fatigue:            │
│        30%          10%                  │
│                                          │
│     [Feed] [Heal]  [Feed] [Heal]        │
│     [Train]        [Explore]            │
│     [Defend]       [Rest]               │
│                                          │
├─────────────────────────────────────────┤
│  💰 Gold: 150  |  ⚔️ Next Raid: 2:34    │
│  📦 Parts: 🔥×3 ❄️×2 ⚡×1               │
└─────────────────────────────────────────┘
```

**Dragon Visual Design**:
- **Modular Sprites**: Head + Body + Tail separate sprites
- **Element Colors**:
  - 🔥 Fire: Red/Orange glow
  - ❄️ Ice: Blue/White frost
  - ⚡ Lightning: Yellow/Purple sparks
  - 🌿 Nature: Green/Brown vines
  - 🌑 Shadow: Black/Purple smoke
- **Animations**:
  - Idle: Breathing, slight movement
  - Eating: Chomping animation
  - Training: Attack motions
  - Resting: Sleeping with Zzz
  - Chimera: Rainbow shimmer effect

### Sound Design (Full Vision)

**Music**:
- Main lab theme: Quirky science music
- Town theme: Medieval marketplace ambience
- Combat: Epic orchestral
- Victory jingle: Triumphant fanfare

**Sound Effects**:
- Dragon sounds: Roars, purrs (different per element)
- UI clicks: Steampunk gadget sounds
- Feeding: Chomping, satisfied sounds
- Level up: Magical chime
- Chimera spawn: Dramatic mystical sound

---

## 🤖 AI Integration (Jam Requirement)

### AI Usage #1: Dragon Name Generation

**System**: Claude API with prompt caching
```
Prompt: "Generate a unique fantasy dragon name based on:
- Head element: Fire
- Body element: Ice
- Tail element: Lightning
Style: Epic, memorable, hints at mixed elements"

Output: "Frostbite the Voltaic Wyrm"
```

**Implementation**:
- Names generated on dragon creation
- Cached common combinations (saves API calls)
- Fallback to random generator if API fails
- Player can regenerate name (costs 10 gold)

### AI Usage #2: Smart Scientist Behavior

**Learning Algorithm**:
```python
class ScientistAI:
    def __init__(self):
        self.player_preferences = {
            'fire_usage': 0,
            'ice_usage': 0,
            # ... track element preferences
            'keep_rate': {},  # Which dragons kept vs retired
            'synergy_preference': 0  # Matching vs mixed
        }

    def observe_player_action(self, action):
        if action.type == "create_dragon":
            for part in action.parts:
                self.player_preferences[f'{part}_usage'] += 1

        if action.type == "retire_dragon":
            dragon_key = action.dragon.get_part_combo()
            self.player_preferences['keep_rate'][dragon_key] -= 1

    def smart_build_dragon(self):
        # Weight elements by usage frequency
        # Favor high keep_rate combinations
        # Apply synergy if player prefers it
        return optimized_part_selection()
```

**Visible AI Behavior**:
- Builder prioritizes player's favorite elements (60% of time)
- Trainer focuses on dragons used in defense
- Healer heals combat dragons first
- Feeder learns optimal feeding schedule per dragon

### AI Usage #3: Dynamic Difficulty (Full Vision)

**System**: Adaptive enemy scaling
```python
def calculate_wave_difficulty():
    player_power = sum(dragon.total_stats for dragon in active_dragons)
    recent_win_rate = last_10_battles.win_rate()

    target_win_rate = 0.65  # Aim for 65% win rate

    if recent_win_rate > 0.75:
        # Player winning too much, increase difficulty
        enemy_power = player_power * 1.2
    elif recent_win_rate < 0.50:
        # Player struggling, decrease difficulty
        enemy_power = player_power * 0.9
    else:
        # Balanced
        enemy_power = player_power * 1.1

    return generate_enemies(enemy_power)
```

**Benefits**:
- Always challenging but not impossible
- New players don't get frustrated
- Veterans don't get bored
- Smooth difficulty curve

---

## 📱 Platform & Technical

### Game Jam Build (Web)
**Engine**: Godot 4.x with GDScript
**Target**: HTML5 export for itch.io
**Requirements**:
- Runs in modern browsers (Chrome, Firefox, Safari)
- Mobile responsive (touch controls)
- LocalStorage for save/load

**Performance Targets**:
- 60 FPS on mid-range devices
- < 50 MB total size
- < 5 second load time

### Full Vision Build
**Platforms**:
- Web (primary)
- Android (secondary)
- iOS (tertiary)
- Steam (long-term)

**Additional Requirements**:
- Cloud save sync
- Cross-platform progression
- Push notifications (mobile)
- Social features (friends, leaderboards)

**Technical Stack**:
- Godot for game logic
- Custom UI framework
- Backend: Node.js + PostgreSQL (for multiplayer)
- AI: Claude API (or Azure OpenAI)

---

## 📊 Monetization (Post-Jam Only)

### Free-to-Play Model

**100% Free Core Game**:
- All dragons unlockable
- All scientists available
- All locations accessible
- No paywalls

**Optional Purchases** (Ethical):

**Convenience** (Not Power):
- 2× Speed scientist upgrades: $2.99
- Instant exploration completion: $0.99 per use
- Extra save slots: $1.99

**Cosmetics**:
- Scientist outfit packs: $3.99
- Laboratory themes: $2.99
- Dragon skins (non-stat): $1.99-4.99
- Particle effects: $0.99

**Battle Pass** (Seasonal):
- $9.99 per season (3 months)
- Exclusive cosmetics + premium currency
- Free track also included (no FOMO)

**Expected Revenue**:
- Free players: 80% (fully enjoy game)
- Buyers: 20%
- Average LTV: $5-10
- Goal: Sustainable, not exploitative

---

## 🎯 Success Metrics

### Game Jam Judging Criteria

**AFK Mechanics** (Required):
✅ Hunger system (passive need)
✅ Fatigue system (time-based)
✅ Scientist automation (4 types)
✅ Defense raids (auto-battle)
✅ Exploration (continues while AFK)
**Score: 5/5 systems**

**Virtual Pet** (Required):
✅ Manual feeding
✅ Healing
✅ Training
✅ Emotional investment (naming, visual attachment)
**Score: Complete**

**AI Integration** (Required):
✅ Dragon name generation (Claude API)
✅ Smart scientist behavior (learning algorithm)
✅ Procedural content (dynamic raids)
**Score: Multiple uses**

**"Holy Shit" Moment** (Required):
✅ Chimera mutation (1% chance, 2.5× stats, epic visual)
**Score: Memorable**

**Scalability** (Required):
✅ Clear roadmap to full game
✅ Systems designed for expansion
✅ This GDD proves vision
**Score: Obvious potential**

### Player Engagement Metrics (Post-Launch)

**Day 1 Retention**: Target 40%
- Do players come back after first session?
- Tutorial clarity critical

**Week 1 Retention**: Target 20%
- Are they hooked on the loop?
- AFK rewards must feel good

**Month 1 Retention**: Target 10%
- Long-term engagement
- Content updates needed

**Session Length**:
- Average: 10-15 minutes (ideal for idle game)
- Hardcore players: 1-2 hours

**Social Sharing**:
- "Look at my chimera!" screenshots
- Trading with friends
- Guild participation

---

## 📅 Development Roadmap

### Phase 1: Game Jam (7 Days) ✅
**Status**: COMPLETE
- All core systems implemented
- Playable web build
- AI integration functional
- Save/load working
- Ready for submission

### Phase 2: Post-Jam Polish (2 Weeks)
**Goals**: Fix bugs, balance, QoL
- Bug fixes from jam feedback
- Balance tuning (gold costs, timers)
- UI improvements
- Performance optimization
- Mobile testing

### Phase 3: Laboratory Exploration (1 Month)
**Goals**: Add 2D world
- Top-down lab environment
- Walk around and interact
- Visual dragon interactions
- Scientist NPCs with pathfinding
- Laboratory upgrade visuals

### Phase 4: Town & NPCs (1 Month)
**Goals**: Expand world
- Town hub with 5 locations
- 10+ NPC merchants and quest givers
- Shop system (multiple vendors)
- Dialogue system
- Reputation mechanics

### Phase 5: Crafting & Economy (2 Weeks)
**Goals**: Deepen systems
- Advanced crafting recipes
- Dragon fusion
- Equipment system
- New resource types
- Alchemy and forging

### Phase 6: Achievements & Meta (2 Weeks)
**Goals**: Replayability
- 50+ achievements
- Leaderboards
- Collection UI
- Prestige system
- Titles and badges

### Phase 7: Multiplayer (1 Month)
**Goals**: Social features
- Friend system
- Dragon trading
- Guild system
- Cooperative raids
- Asynchronous PvP

### Phase 8: Content Expansion (Ongoing)
**Goals**: Keep players engaged
- New dragon parts (6th element?)
- New exploration regions
- Seasonal events
- Story campaigns
- Boss rush mode

**Total Timeline**: 4-6 months to Version 2.0

---

## 🎮 Player Personas

### Persona 1: The Collector
**Profile**: Sarah, 28, casual gamer
**Motivation**: Wants to "catch 'em all"
**Play Style**:
- Focuses on creating every dragon combination
- Checks collection % obsessively
- Willing to grind for rare parts
- Loves achievements

**What They Need**:
- Clear collection tracking UI
- Pokedex-style completion rewards
- Blueprint system for missing dragons
- Achievement notifications

### Persona 2: The Optimizer
**Profile**: Jason, 35, strategy gamer
**Motivation**: Maximum efficiency
**Play Style**:
- Spreadsheets for optimal scientist assignments
- Min-maxes dragon stats
- Always testing new strategies
- Cares about leaderboards

**What They Need**:
- Detailed stat breakdowns
- Scientist efficiency metrics
- Combat logs
- Competitive features

### Persona 3: The Pet Lover
**Profile**: Emily, 22, animal lover
**Motivation**: Emotional attachment to dragons
**Play Style**:
- Names every dragon
- Upset when dragons die
- Pets dragons frequently (full vision)
- Prefers exploration over combat

**What They Need**:
- Dragon personality traits
- Interaction animations
- Death prevention mechanics
- Happiness system

### Persona 4: The AFK Player
**Profile**: Michael, 40, busy professional
**Motivation**: Progress without time investment
**Play Style**:
- Checks game 2-3 times per day
- Relies heavily on automation
- Long exploration missions
- Doesn't micromanage

**What They Need**:
- Strong offline progression
- Clear automation status
- Push notifications (mobile)
- Quick session gameplay (5 min)

---

## 🎓 Lessons & Design Philosophy

### Core Principles

**1. Respect Player Time**
- No forced waiting without purpose
- AFK progress is meaningful
- Short sessions are valid playstyle
- Can leave and return anytime

**2. Choices Over Grinding**
- Strategic decisions > repetitive tasks
- Automation removes busywork
- Focus on interesting choices (which dragons to build, where to explore)

**3. Fail Forward**
- Losing a defense still gives partial rewards
- Dead dragons can be resurrected (full vision)
- Mistakes are learning opportunities
- No dead-end progression paths

**4. Clear Feedback**
- Every action has visible result
- Progress bars and numbers everywhere
- Celebration of milestones
- Tooltips explain everything

**5. Accessible Complexity**
- Simple to start (feed dragon, assign to defense)
- Deep to master (optimal synergy builds, scientist management)
- Optional complexity (can ignore advanced features)

### What Makes This Game Special

**Unique Blend**:
- Most idle games lack manual control (Cookie Clicker)
- Most pet games lack automation (Tamagotchi)
- Most tower defense lacks persistence (Bloons)
- **This game combines all three**

**Emotional Hook**:
- You care about your dragons (virtual pet)
- You feel smart automating (idle progression)
- You feel powerful defending (tower defense)

**Satisfying AFK Loop**:
- Log off with confidence (scientists working)
- Return to tangible rewards (gold, new dragons)
- Immediate dopamine hit (claim rewards)
- New goals appear (next upgrade)

---

## 🎯 Pitch & Marketing

### Elevator Pitch (30 seconds)
"DragonForgeis an idle management game where you run a mad science lab creating Frankenstein-style dragons from mismatched parts. Start by manually caring for one dragon—feeding, healing, training—then hire AI-powered scientists to automate everything. Defend against knight raids, send dragons exploring, and build your way to a fully automated dragon empire. It's Tamagotchi meets Cookie Clicker meets Tower Defense, all designed to progress while you're AFK."

### Key Selling Points
✅ **125+ unique dragons** from part combinations
✅ **Manual → Automated progression** feels incredible
✅ **Chimera mutations** create "holy shit" moments
✅ **AI-powered scientists** learn your playstyle
✅ **True AFK progress** with meaningful offline rewards
✅ **Free-to-play** with ethical monetization
✅ **Cross-platform** with cloud save sync

### Target Platforms (Launch)
- Itch.io (game jam)
- Newgrounds
- Kongregate
- Mobile web

### Target Platforms (Full Release)
- iOS App Store
- Google Play Store
- Steam
- Epic Games Store

### Comparable Games
- **Idle**: Cookie Clicker, Adventure Capitalist
- **Pet Sim**: Tamagotchi, Neopets, Pokémon
- **Tower Defense**: Bloons TD, Kingdom Rush
- **Crafting**: Little Alchemy, Doodle God

**Our Differentiator**: Only game combining ALL of these genres with true AFK progression.

---

## 📋 Conclusion

DragonForgerepresents a unique fusion of beloved game genres—virtual pet care, idle progression, and tower defense—all wrapped in an AFK-friendly package that respects player time. The game jam build demonstrates a solid core loop with all required features (AFK mechanics, virtual pet, AI integration, "holy shit" moments, and clear scalability).

The full vision expands this foundation into a deep, engaging experience with:
- Explorable 2D laboratory and town
- Rich NPC interactions and questing
- Comprehensive shop and crafting systems
- 50+ achievements for replayability
- Enhanced AI driving adaptive gameplay
- Ethical free-to-play monetization
- Multiplayer and social features

**What makes this game special**: It's not just another idle clicker. It's a game you actively enjoy playing while also respecting that you have a life outside the game. You form genuine attachment to your dragons, feel clever optimizing your automation, and experience satisfying progression whether you play for 5 minutes or 5 hours.

**For the game jam**: We've delivered on every requirement with polish and heart.
**For the future**: We have a clear, executable roadmap to a full commercial release.

This is a game that could grow into something truly special—a cozy, engaging experience players return to daily for years.

---

## 📞 Contact & Credits

**Game Jam Team**: [Your Names]
**AI Integration**: Claude (Anthropic) via Orca Game Engine
**Engine**: Godot 4.x
**Submission Date**: October 26, 2025

**Special Thanks**:
- Playful AI for hosting this jam
- The Godot community
- Our playtesters

---

## 🔗 Appendices

### Appendix A: Full Element Chart
| Element | Attack | Health | Speed | Strong vs | Weak vs |
|---------|--------|--------|-------|-----------|---------|
| Fire    | 40     | 100    | 20    | Nature    | Ice     |
| Ice     | 25     | 150    | 15    | Lightning | Fire    |
| Lightning| 35    | 90     | 30    | Ice       | Nature  |
| Nature  | 30     | 120    | 18    | Fire      | Lightning|
| Shadow  | 50     | 80     | 25    | All       | All     |

### Appendix B: Scientist Upgrade Costs
| Scientist | Level 1 | Level 2 | Level 3 | Level 4 | Level 5 |
|-----------|---------|---------|---------|---------|---------|
| Feeder    | 50g     | 50g     | 100g    | 150g    | 200g    |
| Healer    | 100g    | 100g    | 150g    | 200g    | 250g    |
| Trainer   | 150g    | 150g    | 200g    | 250g    | 300g    |
| Builder   | 200g    | 200g    | 250g    | 300g    | 350g    |

### Appendix C: Exploration Rewards Table
| Duration | Gold | XP | Parts | Blueprint Chance |
|----------|------|----|----- |------------------|
| 15 min   | 20   | 30 | 1    | 1%               |
| 30 min   | 40   | 60 | 2    | 3%               |
| 60 min   | 80   | 120| 3    | 5%               |

### Appendix D: Achievement List Preview
- **"First Flight"**: Create your first dragon
- **"Automation Pioneer"**: Hire your first scientist
- **"Dragon Hoard"**: Own 5 dragons simultaneously
- **"Element Master"**: Create 10 dragons of each element
- **"Chimera Hunter"**: Obtain a chimera mutation
- **"Defense Veteran"**: Win 100 knight raids
- **"Explorer Extraordinaire"**: Complete 50 explorations
- **"Mad Scientist"**: Create 100 unique dragons
- **"Factory Tycoon"**: Accumulate 10,000 gold
- **"Completionist"**: Create all 125 dragon combinations

---

**END OF DOCUMENT**

*Total Word Count: ~8,500 words*
*Last Updated: October 26, 2025*
