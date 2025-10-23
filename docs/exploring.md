I'm building a dragon factory idle game in Godot 4. I have an exploration map image and need you to implement a system where dragons visually travel from the laboratory to destinations and back.

## GAME CONTEXT

**Exploration System:**
- Dragons can be sent on timed expeditions (15/30/60 minutes)
- While exploring, dragons should appear on a map traveling to destinations
- Dragons travel from the laboratory (center) to one of 5 destinations
- When exploration completes, dragons return to the lab with rewards
- Multiple dragons can explore simultaneously

**Map Asset:**
- Location: `res://assets/map.png`
- Resolution: Approximately 1280x800
- Style: Dark gothic with neon green accents
- Laboratory at center, 5 destinations around it

---

## MAP DESTINATION COORDINATES

Based on the provided map image, here are the approximate positions (1280x800 scale):
```gdscript
# Laboratory starting position (center)
const LAB_POSITION = Vector2(470, 565)

# Destination positions
const DESTINATIONS = {
    "ancient_forest": {
        "position": Vector2(200, 200),
        "name": "Ancient Forest",
        "element": "Nature",
        "duration_minutes": 30,
        "color": Color(0.2, 1.0, 0.2)  # Green
    },
    "frozen_tundra": {
        "position": Vector2(615, 180),
        "name": "Frozen Tundra",
        "element": "Ice",
        "duration_minutes": 45,
        "color": Color(0.3, 0.8, 1.0)  # Cyan
    },
    "thunder_peak": {
        "position": Vector2(1005, 200),
        "name": "Thunder Peak",
        "element": "Lightning",
        "duration_minutes": 60,
        "color": Color(1.0, 1.0, 0.2)  # Yellow
    },
    "volcanic_caves": {
        "position": Vector2(1075, 610),
        "name": "Volcanic Caves",
        "element": "Fire",
        "duration_minutes": 15,
        "color": Color(1.0, 0.3, 0.0)  # Orange-red
    },
    "shadow_realm": {
        "position": Vector2(140, 665),
        "name": "Shadow Realm",
        "element": "Shadow",
        "duration_minutes": 60,
        "color": Color(0.6, 0.2, 0.8)  # Purple
    }
}
```

---

## WHAT I NEED YOU TO BUILD

### 1. TRAVELING DRAGON COMPONENT

Create a visual component that represents a dragon traveling on the map.

**File: `traveling_dragon.tscn` + `traveling_dragon.gd`**

**Visual Requirements:**
- Small dragon sprite (use colored circle/square placeholder if no sprite available)
- Dragon name label above sprite
- Small progress bar below dragon
- Particle trail behind dragon (element-colored)
- Shadow/glow effect

**Behavior:**
1. Spawns at LAB_POSITION when exploration starts
2. Smoothly animates (tween) to destination over the exploration duration
3. Dragon sprite faces direction of travel
4. Progress bar shows expedition completion %
5. When complete, quickly animates back to lab (3 seconds)
6. Shows celebration particles on return
7. Emits signal when returned for reward collection

**Script Structure:**
```gdscript
extends Node2D
class_name TravelingDragon

# Visual components
@onready var dragon_sprite = $Sprite2D  # Placeholder: ColorRect or small sprite
@onready var name_label = $NameLabel
@onready var progress_bar = $ProgressBar
@onready var trail_particles = $CPUParticles2D

# Data
var dragon_data: Dictionary  # Contains dragon info (name, level, element)
var destination_key: String
var destination_position: Vector2
var start_time: int  # Unix timestamp
var duration_seconds: int
var is_returning: bool = false

signal exploration_complete(dragon_data: Dictionary)
signal arrived_at_destination

# Methods to implement:
func setup(dragon: Dictionary, dest_key: String) -> void:
    # Initialize dragon on map
    # Set sprite color based on element
    # Start journey animation
    pass

func _animate_to_destination() -> void:
    # Tween from LAB_POSITION to destination_position
    # Duration matches exploration time
    # Use EASE_IN_OUT for smooth movement
    pass

func _animate_return() -> void:
    # Tween back to LAB_POSITION
    # Fast return (3 seconds)
    # Add celebration effects
    pass

func _process(delta: float) -> void:
    # Update progress bar based on elapsed time
    # Rotate sprite to face movement direction
    # Check if exploration complete
    pass

func get_progress() -> float:
    # Return 0.0 to 1.0 based on elapsed time
    pass

func get_time_remaining() -> int:
    # Return seconds until exploration completes
    pass
```

---

### 2. EXPLORATION MAP UI

Create the main exploration screen that displays the map and manages traveling dragons.

**File: `exploration_map_ui.tscn` + `exploration_map_ui.gd`**

**Scene Structure:**
```
ExplorationMapUI (Control)
├── Background (ColorRect - dark background)
├── MapImage (TextureRect)
│   └── texture: res://assets/map.png
├── DragonsLayer (Node2D)
│   └── [TravelingDragon instances spawn here]
├── UIOverlay (Control)
│   ├── TitleLabel ("EXPLORATION MAP")
│   ├── ActiveExpeditionsLabel ("3 dragons exploring")
│   └── BottomPanel
│       ├── SendExpeditionButton
│       └── CloseButton
└── DestinationMarkers (Node2D)
    ├── AncientForestMarker (Marker2D)
    ├── FrozenTundraMarker (Marker2D)
    ├── ThunderPeakMarker (Marker2D)
    ├── VolcanicCavesMarker (Marker2D)
    └── ShadowRealmMarker (Marker2D)
```

**Main Script:**
```gdscript
extends Control
class_name ExplorationMapUI

const TravelingDragonScene = preload("res://scenes/traveling_dragon.tscn")

@onready var dragons_layer = $DragonsLayer
@onready var map_image = $MapImage
@onready var active_label = $UIOverlay/ActiveExpeditionsLabel

# Map constants
const LAB_POSITION = Vector2(470, 565)
const DESTINATIONS = { ... }  # As defined above

var active_traveling_dragons: Dictionary = {}  # dragon_id -> TravelingDragon node

func _ready():
    # Set up map image
    # Position destination markers
    # Connect to exploration manager signals
    # Load any in-progress explorations from save
    pass

func spawn_traveling_dragon(dragon: Dictionary, destination_key: String):
    """
    Creates a traveling dragon on the map
    Args:
        dragon: Dictionary with {id, name, level, element, etc.}
        destination_key: One of the DESTINATIONS keys
    """
    var traveling_dragon = TravelingDragonScene.instantiate()
    traveling_dragon.setup(dragon, destination_key)
    
    dragons_layer.add_child(traveling_dragon)
    active_traveling_dragons[dragon.id] = traveling_dragon
    
    traveling_dragon.exploration_complete.connect(_on_exploration_complete)
    
    _update_active_count()

func remove_traveling_dragon(dragon_id: String):
    if active_traveling_dragons.has(dragon_id):
        var dragon_node = active_traveling_dragons[dragon_id]
        dragon_node.queue_free()
        active_traveling_dragons.erase(dragon_id)
        _update_active_count()

func _on_exploration_complete(dragon_data: Dictionary):
    # Called when dragon returns to lab
    # Collect rewards from exploration
    # Notify main game system
    # Remove traveling dragon from map
    pass

func _update_active_count():
    var count = active_traveling_dragons.size()
    active_label.text = "%d dragon%s exploring" % [count, "s" if count != 1 else ""]

func get_destination_info(dest_key: String) -> Dictionary:
    return DESTINATIONS.get(dest_key, {})
```

---

### 3. INTEGRATION WITH EXISTING EXPLORATION SYSTEM

**Connect to your existing exploration manager:**

Assuming you have an ExplorationManager singleton that handles the exploration logic:
```gdscript
# In exploration_manager.gd (your existing system)

signal exploration_started(dragon: Dragon, destination: String, duration: int)
signal exploration_completed(dragon: Dragon, rewards: Dictionary)

func start_exploration(dragon: Dragon, destination_key: String) -> bool:
    # Your existing logic to start exploration
    # ...
    
    # NEW: Notify map to spawn traveling dragon
    var dragon_dict = {
        "id": dragon.dragon_id,
        "name": dragon.dragon_name,
        "level": dragon.level,
        "element": dragon.head_part.element
    }
    
    exploration_started.emit(dragon_dict, destination_key, duration)
    return true

func complete_exploration(dragon_id: String) -> Dictionary:
    # Your existing logic to complete exploration
    # Generate rewards, level up dragon, etc.
    # ...
    
    var rewards = _generate_rewards(destination)
    exploration_completed.emit(dragon, rewards)
    return rewards
```

**Connect signals in ExplorationMapUI:**
```gdscript
func _ready():
    # Connect to exploration manager
    var exploration_mgr = get_node("/root/ExplorationManager")
    exploration_mgr.exploration_started.connect(_on_exploration_started)
    exploration_mgr.exploration_completed.connect(_on_exploration_completed)

func _on_exploration_started(dragon_dict: Dictionary, dest_key: String, duration: int):
    spawn_traveling_dragon(dragon_dict, dest_key)

func _on_exploration_completed(dragon: Dragon, rewards: Dictionary):
    # Show rewards popup
    # Play celebration animation
    # Remove traveling dragon
    remove_traveling_dragon(dragon.dragon_id)
```

---

### 4. VISUAL POLISH REQUIREMENTS

**Dragon Sprite Appearance:**
- Use simple colored square/circle (40x40px) as placeholder
- Color based on element:
  - Fire: Orange/Red (#FF5500)
  - Ice: Cyan (#33CCFF)
  - Lightning: Yellow (#FFFF33)
  - Nature: Green (#33FF33)
  - Shadow: Purple (#9933FF)
- Add white border (2px) for visibility
- Optional: Add simple dragon icon/emoji if available

**Animation Details:**
- Journey tween: Use `Tween.TRANS_CUBIC` and `Tween.EASE_IN_OUT`
- Movement speed: Match exploration duration (15min = dragon takes 15 real minutes to reach destination)
- Return animation: Fast 3-second return regardless of distance
- Rotation: Dragon sprite faces travel direction (use `look_at()` or manual rotation)

**Particle Trail:**
- CPUParticles2D following dragon
- Color matches dragon element
- Emission rate: 10-20 particles/sec
- Lifetime: 1-2 seconds
- Direction: Opposite to movement (trailing effect)
- Gravity: None (particles float)

**Progress Bar:**
- Small bar (60x8px) below dragon
- Green fill showing completion %
- Background: Dark gray/black
- Border: Light green matching map aesthetic
- Updates every frame based on elapsed time

**Name Label:**
- Above dragon sprite
- Small font (10-12px)
- Color: Neon green (#00FF00) matching map
- Shadow/outline for readability
- Shows dragon name only (not stats)

---

### 5. SAVE/LOAD COMPATIBILITY

**Handle in-progress explorations:**
```gdscript
# When saving game
func save_exploration_state() -> Array:
    var state = []
    for dragon_id in active_traveling_dragons:
        var dragon_node = active_traveling_dragons[dragon_id]
        state.append({
            "dragon_id": dragon_id,
            "destination": dragon_node.destination_key,
            "start_time": dragon_node.start_time,
            "duration": dragon_node.duration_seconds
        })
    return state

# When loading game
func load_exploration_state(state: Array):
    for exploration in state:
        # Check if exploration completed while offline
        var elapsed = Time.get_unix_time_from_system() - exploration.start_time
        
        if elapsed >= exploration.duration:
            # Exploration completed offline - collect rewards immediately
            _collect_offline_exploration(exploration)
        else:
            # Still in progress - spawn traveling dragon at correct position
            _restore_traveling_dragon(exploration, elapsed)

func _restore_traveling_dragon(exploration: Dictionary, elapsed_time: int):
    # Spawn dragon on map
    # Calculate current position based on elapsed time
    # Continue animation from current position
    pass
```

---

### 6. UI/UX FEATURES

**Hovering over traveling dragon:**
```gdscript
func _on_dragon_mouse_entered():
    # Show tooltip with:
    # - Dragon name
    # - Current level
    # - Destination name
    # - Time remaining
    # - Expected rewards
    pass
```

**Click traveling dragon:**
```gdscript
func _on_dragon_clicked():
    # Show detailed popup:
    # - Option to recall early (partial rewards)
    # - Expedition details
    # - Dragon stats
    pass
```

**Map zoom/pan (optional):**
```gdscript
# If map is larger than viewport
# Add zoom controls and drag to pan
func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_in()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_out()
```

---

### 7. AUDIO FEEDBACK

**Sound effects to add:**
- Dragon departure: Wing flap + departure sound
- During travel: Ambient wind/environment sounds (very subtle)
- Arrival at destination: Arrival chime
- Return to lab: Triumphant fanfare + coin/loot sounds
- Reward collection: Satisfying collection sound

---

## TESTING CHECKLIST

Create a test scene to verify:

- [ ] Dragon spawns at laboratory position
- [ ] Dragon smoothly animates to destination
- [ ] Progress bar updates correctly
- [ ] Time remaining calculates accurately
- [ ] Dragon faces direction of travel
- [ ] Particle trail follows dragon
- [ ] Multiple dragons can travel simultaneously
- [ ] Return animation plays when exploration completes
- [ ] Rewards collected properly on return
- [ ] Save/load preserves in-progress explorations
- [ ] Offline explorations complete correctly
- [ ] Map displays correctly at different resolutions
- [ ] UI elements don't overlap dragon sprites

---

## DELIVERABLES

Please provide:

1. **traveling_dragon.tscn** - Dragon component scene
2. **traveling_dragon.gd** - Dragon movement and animation script
3. **exploration_map_ui.tscn** - Main map scene
4. **exploration_map_ui.gd** - Map controller script
5. **destination_marker.tscn** - Optional marker component for destinations
6. **README.md** - Integration instructions and API documentation

**Code Quality:**
- Godot 4 syntax
- Clean, commented code
- Signal-based architecture
- Performance: Handle 5+ dragons traveling simultaneously
- Mobile-friendly (touch support for clicking dragons)
- Responsive layout (scales to different screen sizes)

**Visual Quality:**
- Smooth animations (60 FPS target)
- Consistent art style matching map
- Clear visual feedback for all interactions
- Professional game-jam quality

Make this feel polished and satisfying to watch! Dragons traveling on the map should be one of the most visually appealing parts of the game.