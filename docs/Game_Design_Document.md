Frankenstein Dragon Factory - Game Design Document
Executive Summary
Core Loop: Idle dragon factory where mismatched dragons defend treasure from knights while scientists breed, train, and care for them. Progress continues while AFK through automated scientist routines and dragon defense.
Hook: "What if dragons were Frankensteined together from mismatched parts, and you ran the mad science lab that made them?"

1. Core Gameplay Loop (Simplified for 7-Day Build)
Primary Loop (Active Play)
Collect resources from defending waves and exploration
Combine dragon parts to create new defenders
Assign dragons to defense or exploration
Upgrade scientists to improve automation
Idle Loop (AFK Progress)
Scientists automatically feed dragons (health regeneration)
Scientists auto-craft random dragons from available parts
Dragons defend against knight waves (auto-battle)
Exploration missions complete and return loot

2. Minimum Viable Features (Week 1 Priority)
🎮 Core Systems
Dragon Creation System
3 Body Parts: Head, Body, Tail
5 Part Types per Slot: Fire, Ice, Lightning, Nature, Shadow
Simple Stats: Each part adds specific bonuses
Head → Attack Power
Body → Health
Tail → Speed (affects turn order)
Element → Special bonus (e.g., Fire = +10% vs Ice enemies)
Example: Fire Head + Ice Body + Lightning Tail = unique stat combination
Scientist System (AFK Automation)
3 Scientists max (unlockable)
Each scientist has ONE job:
Breeder: Auto-creates dragons every X minutes using available parts
Trainer: Auto-levels up assigned dragons (+XP over time)
Caretaker: Auto-feeds dragons (prevents death/stat penalties)
Upgrade Path: Reduce timers, increase efficiency
Defense System (Auto-Battle)
Wave-based knight attacks every 5 minutes (scales with progress)
Dragon Squad: Assign up to 3 dragons as defenders
Simple Combat: Compare total stats, winner determined by stat advantage
Rewards: Gold, parts, occasional rare components
Failure State: Lose treasure = reduced income until recovered
Exploration System
Send 1 dragon on timed expeditions (15/30/60 min options)
Risk/Reward: Longer missions = better loot but dragon unavailable for defense
Returns: Parts, gold, treasure, rare blueprints
No failure: Always returns, just varying rewards

3. Progression Systems (AFK Focused)
Three Parallel Progressions
Dragon Collection
125 possible combinations (5×5×5 parts) (could be extended with AI)
"Pokedex" style collection: Track which dragons you've created
Rarity tiers: Common → Rare → Epic based on part combinations
Discovery bonus: First-time creations grant extra resources and a social badge. 
Treasure Vault
Visible treasure pile that grows/shrinks
Milestone rewards: Every 1000 gold unlocks upgrades
Attack frequency increases with treasure amount (risk/reward)
Scientist Upgrades
Automation improvements:
Faster breeding/training/feeding
Quality improvements (better dragons, more XP, fuller meals)
Multi-tasking (eventually handle 2 dragons at once)

4. "Holy Shit" Moments (Required by Jam)
Week 1 Implementation:
Legendary Mutation: When parts are combined, 1% chance for a "Chimera Mutation" - dragon gets ALL elements' bonuses (visual spectacle + OP stats)
Mega Wave: Random "Legendary Knight" raid with 10x rewards but requires your best 3 dragons working together
Discovery Rush: When you create your 25th/50th/100th unique dragon, trigger a "Eureka Moment" - all scientists work at 10x speed for 5 minutes

5. AI Enhancements (Required by Jam)
Implementation:
Dragon Name Generator: AI generates unique names based on part combinations
"Frostbite the Voltaic Serpent" (Ice Body + Lightning Tail)
Uses Claude API with caching for common combinations
Smart Scientist AI: Breeder learns your playstyle
If you favor Fire dragons, auto-prioritizes Fire parts
Tracks which combinations you keep vs recycle
Adaptive behavior improves AFK efficiency
Dynamic Knight Difficulty: AI analyzes your dragon power level and adjusts waves to stay challenging but beatable (60-70% win rate target)

6. MVP Feature Breakdown (7-Day Timeline)
Days 1-2: Foundation
Basic UI layout (lab view, dragon slots, scientist stations)
Dragon part system + stat calculation
Simple drag-and-drop creation interface
Save/load system (localStorage)
Days 3-4: Core Loops
Auto-battle system for knight waves
Scientist automation (breeding, training, feeding)
Exploration timer system
Basic progression (gold accumulation)
Days 5-6: Polish & AI
AI name generation integration
Mutation system + visual effects
Collection tracking UI
Balance tuning + playtesting
Day 7: Juice & Deploy
Particle effects for key moments
Sound effects (optional but recommended)
Mobile responsive layout
Final bug fixes + submission

7. Visual Design (Simple but Effective)
Art Style: Retro Pixel Lab
Color Palette: Dark lab background, neon element colors
Dragons: Simple 3-sprite system (head/body/tail swap)
Scientists: Chibi mad scientist sprites with different lab coats
UI: Clean, modern interface with gothic/steampunk accents
Key Screens:
Lab View: Central crafting area with 3 part slots
Defense View: Dragon lineup vs incoming knight sprites
Exploration Map: Simple node-based map with timers
Collection: Grid of silhouettes with discovered dragons filled in

8. Technical Stack Recommendation
GDscriot with Orca Game Engine
Visuals: Canvas/Pixi.js for dragons, CSS for UI
AI: Claude API for name generation
Hosting: Itch.io

9. Monetization Potential (Post-Jam Extension)
Free-to-Play Friendly:
Premium Scientists: Unlock 4th/5th scientist slots
Cosmetic Parts: Visual-only dragon customization
Speed-ups: Optional timers reduction
Battle Pass: Seasonal dragon part collections
Critical: Keep all core gameplay F2P. Monetize convenience, not power.

10. Scalability Path (Post-Launch)
Month 1-3 Additions:
PvP Arena: Players raid each other's treasure vaults
Guilds: Team up to defend shared mega-vault
Expeditions: Story-based exploration with permanent unlocks
Prestige System: Reset for powerful ancient dragon parts
Breeding Genetics: Parts can have hidden traits passed down
Seasonal Events: Limited-time parts and knight types

11. Success Metrics (Jam Judging)
What Makes This Win:
✅ Clear AFK Loop: Everything progresses while away
 ✅ Meaningful Choices: Which dragons to create/send exploring
 ✅ "Holy Shit": Chimera mutations + mega waves
 ✅ AI Integration: Smart scientist + procedural names
 ✅ Scalable: Obviously could be full game
 ✅ Unique: Frankenstein dragons defending treasure is fresh

12. Risk Mitigation
Scope Cuts if Behind Schedule:
Drop Exploration: Focus only on defense loop
Reduce Parts: 3 types instead of 5 (27 vs 125 combinations)
Single Scientist: One multi-purpose automation worker
Manual Combat: Click to trigger waves instead of auto-timer
Must-Have for Submission:
Dragon creation works
Scientists automate at least ONE thing
Some form of AFK progress
Collection tracking visible
AI does SOMETHING (even just names)

Pitch Summary (For Jam Page)
"Frankenstein Dragon Factory"
You're a mad scientist running a dragon genetics lab. Mix and match heads, bodies, and tails to create 125+ unique defenders. While you're away, your AI-powered scientists breed new specimens, train your beasts, and keep them fed. Knights attack in waves—pair the right elemental combo to protect your growing treasure hoard. Send dragons exploring for rare parts, and pray for a legendary Chimera mutation.
Tamagotchi meets Cookie Clicker meets Monster Rancher

Next Steps
Validate core loop: Prototype dragon creation + stat system (Day 1 AM)
Get one full cycle working: Create → Defend → Earn → Upgrade (Day 2)
Add juice incrementally: Don't wait until Day 7 to make it feel good
Test AFK every day: Make sure it's satisfying to come back after hours away
Most Important: Keep it simple. A polished simple game beats a buggy complex one. You can always add more dragon parts post-jam—but you need the core loop SOLID.

