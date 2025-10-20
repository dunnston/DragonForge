extends Resource
class_name DragonPhase3

# Phase 3: Dragon Combat Interface & Exploration Systems
# Built on top of Phase 1 (core systems) and Phase 2 (state management)

# Time Constants (in seconds)
const HUNGER_INTERVAL: int = 1800  # 30 minutes until hungry
const STARVATION_TIME: int = 3600  # 1 hour until starvation penalties
const FATIGUE_TIME: int = 2700     # 45 minutes until tired from activity
const REST_TIME: int = 900         # 15 minutes to recover from fatigue

# Experience Constants
const MAX_LEVEL: int = 10
const EXP_BASE: int = 100          # Base exp needed for level 2
const EXP_MULTIPLIER: float = 1.5  # Exponential curve

# Mutation Constants
const MUTATION_CHANCE: float = 0.01  # 1% chance

# Phase 3: Combat Constants
const FATIGUE_PER_COMBAT: float = 0.1  # 10% fatigue per battle
const FATIGUE_RECOVERY_RATE: float = 0.05  # 5% per minute when idle
const COMBAT_XP_BASE: int = 10  # Base XP per victory
const EXPLORATION_FATIGUE = {
	15: 0.15,  # 15min = 15% fatigue
	30: 0.25,  # 30min = 25% fatigue
	60: 0.40   # 60min = 40% fatigue
}
const FATIGUE_THRESHOLD: float = 0.8  # Auto-remove at 80%+ fatigue

# State Management
enum DragonState { IDLE, DEFENDING, EXPLORING, TRAINING, RESTING }

# Export Properties (saved with Resource)
@export var dragon_id: String
@export var dragon_name: String = "Unnamed Dragon"
@export var head_part: DragonPart
@export var body_part: DragonPart
@export var tail_part: DragonPart
@export var level: int = 1
@export var experience: int = 0
@export var current_health: int = 0
@export var current_state: DragonState = DragonState.IDLE
@export var state_start_time: int = 0
@export var last_fed_time: int = 0
@export var created_at: int = 0
@export var is_chimera_mutation: bool = false
@export var is_dead: bool = false

# Phase 3: Exploration Properties
@export var exploration_start_time: int = 0
@export var exploration_duration: int = 0
# Computed Stats (recalculated on load)
var total_attack: int = 0
var total_health: int = 0
var total_speed: int = 0

# Life Systems (computed from timestamps)
var hunger_level: float = 0.0     # 0.0 = fed, 1.0 = starving
var fatigue_level: float = 0.0    # 0.0 = rested, 1.0 = exhausted

# Phase 3: New Signals for Combat & Exploration
signal assignment_changed(dragon: DragonPhase3, old_state: DragonState, new_state: DragonState)
signal exploration_started(dragon: DragonPhase3, duration_minutes: int)
signal exploration_completed(dragon: DragonPhase3)

# Existing Signals for Integration  
signal state_changed(dragon: DragonPhase3, old_state: DragonState, new_state: DragonState)
signal level_up(dragon: DragonPhase3, new_level: int)
signal hunger_changed(dragon: DragonPhase3, hunger_level: float)
signal health_changed(dragon: DragonPhase3, current_health: int, max_health: int)
signal death(dragon: DragonPhase3)
signal mutation_discovered(dragon: DragonPhase3)

func _init(head: DragonPart = null, body: DragonPart = null, tail: DragonPart = null):
	dragon_id = generate_unique_id()
	head_part = head
	body_part = body
	tail_part = tail
	
	# Initialize life systems
	var current_time = Time.get_unix_time_from_system()
	created_at = current_time
	last_fed_time = current_time
	state_start_time = current_time
	
	calculate_stats()

func generate_unique_id() -> String:
	# Generate a unique ID using timestamp and random number
	var timestamp = Time.get_unix_time_from_system()
	var random_part = randi() % 10000
	return "dragon_%d_%04d" % [timestamp, random_part]
# ===== PHASE 3: COMBAT INTERFACE =====
