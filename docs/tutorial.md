I'm building a dragon factory idle game in Godot 4. I need you to create the opening scene and tutorial system.

## GAME CONTEXT

**Core Concept:** 
Players inherit a Frankenstein-style dragon laboratory. They assemble dragons from parts (head/body/tail), assign them to defend against knight waves, send them exploring, and care for them (feeding, training, resting).

**Key Mechanics:**
- Create dragons by combining 3 parts (head, body, tail)
- Each part has an element: Fire, Ice, Lightning, Nature, Shadow
- Dragons need feeding and rest (maintenance)
- Dragons can be assigned to: Defense, Exploration, or Training
- Scientists automate tasks: Engineer (creates dragons), Trainer (levels dragons), Caretaker (feeds dragons)
- Knights attack in waves - dragons auto-defend
- AFK progression - things happen while offline

## WHAT I NEED YOU TO BUILD

### 1. OPENING LETTER SCENE

**Visual Design:**
- Parchment/aged paper background
- Text appears with typewriter effect (one character at a time, with typing sound)
- Thunder sound effect on dramatic moments
- Fade to black transition to tutorial

**Letter Content (expand/improve this):**
```
To my dearest apprentice,

If you're reading this, I'm gone.

The knights have discovered our work. They've been hunting dragons to extinction, burning nests, destroying eggs. But I found another way - we can CREATE them. Assemble them from parts, like Dr. Frankenstein's great work.

The laboratory is yours now. I've left you what I could:
- 30 gold pieces
- 6 dragon parts from my collection (at least one head, body, and tail)

The knights know about the laboratory now. They will come. You must be ready.

Dragons are living creatures, even if assembled. They need food, rest, and training to grow strong. When you can afford it, hire scientists from town - they'll help automate the work.

Key lessons I taught you:
1. Always create your first defender immediately
2. Send dragons exploring to gather resources, but only when rested
3. Keep them fed and rested before you leave the laboratory
4. Training and treats make them powerful - hire a Trainer when possible
5. Never leave the lab undefended

The dragons need you. The world needs you.

Don't let my life's work die with me.

- Professor Von Drakescale

P.S. - Trust the process. Trust the dragons.
```

**Technical Requirements:**
- Text appears character-by-character with configurable speed
- Allow skipping (press any key to show full text instantly)
- After fully displayed, show "[Press any key to continue]" prompt
- Sound effects: typing sound loop, thunder on "they will come", dramatic music
- After player presses key, fade to black, then load tutorial scene

---

### 2. INTERACTIVE TUTORIAL SYSTEM

Create a step-by-step guided tutorial that teaches core mechanics. Use modal popups/tooltips that highlight relevant UI elements.

**Tutorial Flow:**

**STEP 1: CREATE YOUR FIRST DRAGON**
```
Tutorial Popup:
"Welcome to your laboratory. Let's create your first dragon.

Click the ASSEMBLY TABLE to begin."

[Arrow points to assembly table UI element]
[All other UI dimmed/disabled]
```

Once clicked:
```
"Select 3 parts to assemble your dragon:
- 1 Head (determines attack power)
- 1 Body (determines health) 
- 1 Tail (determines speed)

Choose from your starting parts."

[Show part selection UI - only allow selecting from the 6 starter parts]
[Highlight available parts]
```

After parts selected:
```
"Great choices! Now click CREATE DRAGON to bring it to life."

[Only CREATE button enabled]
```

After creation:
```
"Success! Meet your first dragon: [AI Generated Name]

Stats:
Attack: [X]
Health: [Y]
Speed: [Z]

Dragons are the foundation of your defense. Let's put this one to work."

[Show dragon display with stats]
[CONTINUE button]
```

---

**STEP 2: ASSIGN TO DEFENSE**
```
"Knights will attack in waves every 5 minutes. 
Assign your dragon to defense to protect your laboratory.

Click on your dragon, then click ASSIGN TO DEFENSE."

[Highlight dragon and defense slot]
```

After assignment:
```
"Perfect! Your dragon is now defending the laboratory.

When knights attack, combat resolves automatically.
Victories earn gold and dragon parts."

[CONTINUE]
```

---

**STEP 3: DRAGON NEEDS (FEEDING)**
```
"Dragons are living creatures. They need care.

HUNGER: Dragons must be fed regularly or they'll become weak.
FATIGUE: Dragons get tired from combat and exploration.

Let's feed your dragon now.

[Show dragon status: Hunger 70%, Fatigue 10%]

Click FEED DRAGON."

[Highlight feed button]
```

After feeding:
```
"Well fed! Your dragon is now at 100% hunger.

Always keep dragons fed, especially before logging off.
Hungry dragons lose stats and may die."

[CONTINUE]
```

---

**STEP 4: SEND ON EXPLORATION**
```
"Dragons can explore to find resources: gold, parts, and treasure.

Create a second dragon first - never leave your lab undefended!"

[If player has <2 dragons, show "CREATE ANOTHER DRAGON" prompt]
[Once they have 2 dragons:]

"Now you have backup defense. Let's send one dragon exploring.

Select your second dragon, then choose EXPLORE.

Pick expedition length:
- 15 min: Low risk, small rewards
- 30 min: Medium risk, medium rewards  
- 60 min: High risk, big rewards

Dragons must be well-rested to explore."

[Highlight dragon + exploration options]
```

After sending on exploration:
```
"Your dragon is now exploring! They'll return automatically.

While exploring, dragons can't defend. Plan accordingly.

Time remaining: [15:00]"

[CONTINUE]
```

---

**STEP 5: RESTING & FATIGUE**
```
"Notice your defending dragon's fatigue has increased.

Fatigue: 40%

Fatigued dragons perform poorly in combat.
Let them rest by unassigning them from duties.

[Show option to REST dragon or let it continue]

Important: Before logging off, always:
✓ Feed all dragons (100% hunger)
✓ Rest tired dragons (unassign them)
✓ Leave at least 1 dragon on defense"

[CONTINUE]
```

---

**STEP 6: SCIENTISTS & AUTOMATION**
```
"Managing many dragons is hard work. Scientists help automate tasks.

AVAILABLE SCIENTISTS (hire when you can afford them):

ENGINEER (Cost: 100 gold)
- Auto-creates dragons from available parts
- Works while you're offline

TRAINER (Cost: 150 gold)  
- Auto-trains assigned dragons
- Increases their level and stats
- Training + treats make dragons powerful

CARETAKER (Cost: 100 gold)
- Auto-feeds hungry dragons
- Prevents starvation

You have: 30 gold

Earn more gold by defending against waves and exploring.
Save up to hire your first scientist!"

[Show scientist hiring UI dimmed/locked with costs]
[CONTINUE]
```

---

**STEP 7: FINAL TIPS & TUTORIAL END**
```
"TUTORIAL COMPLETE!

Remember:
✓ Create dragons to defend and explore
✓ Keep them fed and rested  
✓ Hire scientists to automate work
✓ Defend against knight waves
✓ Collect all 125 dragon combinations

Your first wave arrives in 5 minutes.
Good luck!

The Professor believed in you.
Don't let him down.

[START PLAYING]"

[Tutorial ends, all UI enabled, timer starts for first wave]
```

---

## TECHNICAL REQUIREMENTS

**Starting Inventory (code must initialize this):**
```gdscript
var starting_gold = 30
var starting_parts = [
    # Randomly generate 6 parts with constraints:
    # - At least 1 HEAD (any element)
    # - At least 1 BODY (any element)  
    # - At least 1 TAIL (any element)
    # - Remaining 3 can be anything
]
```

**Tutorial System Features:**
- Modal popups that block other interactions
- Highlight/spotlight specific UI elements
- Dim/disable unrelated UI during tutorial steps
- Progress tracking (save which step player is on)
- Allow skipping tutorial (checkbox: "Skip tutorial" for experienced players)
- Save tutorial completion state (don't show again on reload)

**Audio:**
- Typewriter sound effect (loop while text appearing)
- Thunder crash sound (dramatic moments)
- UI click sounds
- Tutorial complete fanfare

**Visual Polish:**
- Smooth fade transitions between steps
- Animated arrows/highlights pointing to relevant UI
- Parchment/gothic theme consistent with game aesthetic
- Mobile-friendly (works on touch screens)

**Code Structure:**
```
res://scenes/opening/
├── opening_letter.tscn
├── opening_letter.gd
├── tutorial_manager.tscn
└── tutorial_manager.gd

res://scripts/
└── game_state.gd (handles starting inventory)
```

## DELIVERABLES

Please provide:

1. **opening_letter.gd** - Complete letter scene with typewriter effect
2. **opening_letter.tscn** - Scene file structure
3. **tutorial_manager.gd** - Tutorial step system with all 7 steps
4. **tutorial_manager.tscn** - Tutorial UI structure
5. **game_state.gd** - Starting inventory initialization
6. **README.md** - How to integrate into existing game

Make the code clean, commented, and extensible (easy to add more tutorial steps later).

Use Godot 4 syntax (not Godot 3).

Focus on making this feel polished and professional for a game jam submission.