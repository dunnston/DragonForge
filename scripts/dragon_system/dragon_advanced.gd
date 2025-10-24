extends Resource
class_name DragonAdvanced

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

# State Management
enum DragonState { IDLE, DEFENDING, EXPLORING, TRAINING, RESTING, DEAD }

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

# Computed Stats (recalculated on load)
var total_attack: int = 0
var total_health: int = 0
var total_speed: int = 0

# Life Systems (computed from timestamps)
var hunger_level: float = 0.0     # 0.0 = fed, 1.0 = starving
var fatigue_level: float = 0.0    # 0.0 = rested, 1.0 = exhausted

# Signals for Integration
signal state_changed(dragon: Dragon, old_state: DragonState, new_state: DragonState)
signal level_up(dragon: Dragon, new_level: int)
signal hunger_changed(dragon: Dragon, hunger_level: float)
signal health_changed(dragon: Dragon, current_health: int, max_health: int)
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
	current_health = total_health

func generate_unique_id() -> String:
	# Generate a unique ID using timestamp and random number
	var timestamp = Time.get_unix_time_from_system()
	var random_part = randi() % 10000
	return "dragon_%d_%04d" % [timestamp, random_part]

func calculate_stats() -> void:
	if not head_part or not body_part or not tail_part:
		return

	# Base stats from parts
	total_attack = 10 + (head_part.attack_bonus * level)
	total_health = 50 + (body_part.health_bonus * level)
	total_speed = 5 + (tail_part.speed_bonus * level)

	# Initialize current_health if not set
	if current_health <= 0:
		current_health = total_health

	# Apply mutation bonus if chimera
	if is_chimera_mutation:
		total_attack = int(total_attack * 2.5)
		total_health = int(total_health * 2.0)
		total_speed = int(total_speed * 1.5)
