extends Resource
class_name Dragon

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

@export var dragon_id: String
@export var dragon_name: String = "Unnamed Dragon"
@export var head_part: DragonPart
@export var body_part: DragonPart
@export var tail_part: DragonPart
# Core Stats & Progression
var total_attack: int = 0
var total_health: int = 0
var total_speed: int = 0
var current_health: int = 0
var level: int = 1
var experience: int = 0

# State Management
enum DragonState { IDLE, DEFENDING, EXPLORING, TRAINING, RESTING }
var current_state: DragonState = DragonState.IDLE
var state_start_time: int = 0

# Life Systems
var last_fed_time: int = 0        # Unix timestamp of last feeding
var created_at: int = 0           # When dragon was created
var hunger_level: float = 0.0     # 0.0 = fed, 1.0 = starving
var fatigue_level: float = 0.0    # 0.0 = rested, 1.0 = exhausted
var is_dead: bool = false         # Death from starvation

# Special Properties
var is_chimera_mutation: bool = false  # Holy shit moment!
var mutation_bonus_applied: bool = false
# Signals for integration
signal state_changed(dragon: Dragon, old_state: DragonState, new_state: DragonState)
signal level_up(dragon: Dragon, new_level: int)
signal hunger_changed(dragon: Dragon, hunger_level: float)
signal health_changed(dragon: Dragon, current_health: int, max_health: int)
signal death(dragon: Dragon)
signal mutation_discovered(dragon: Dragon)
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
	current_health = total_health
	tail_part = tail
	calculate_stats()
	current_health = total_health

func calculate_stats() -> void:
	if not head_part or not body_part or not tail_part:
		return
	
	# Base stats from parts
	total_attack = 10 + (head_part.attack_bonus * level)
	total_health = 50 + (body_part.health_bonus * level)
	total_speed = 5 + (tail_part.speed_bonus * level)
	
	# Element synergy bonuses (if 2+ parts match)
	var elements = [head_part.element, body_part.element, tail_part.element]
	var element_counts = {}
	for e in elements:
		element_counts[e] = element_counts.get(e, 0) + 1
	
	for element in element_counts:
		if element_counts[element] >= 2:
			# Synergy bonus: +20% to all stats
			total_attack = int(total_attack * 1.2)
			total_health = int(total_health * 1.2)
			total_speed = int(total_speed * 1.2)
			break

func get_combination_key() -> String:
	# Unique identifier for this part combination
	return "%s_%s_%s" % [
		DragonPart.Element.keys()[head_part.element],
		DragonPart.Element.keys()[body_part.element],
		DragonPart.Element.keys()[tail_part.element]
	]

func generate_unique_id() -> String:
	return "dragon_%d" % Time.get_ticks_msec()

func to_dict() -> Dictionary:
	return {
		"id": dragon_id,
		"name": dragon_name,
		"head": head_part.get_part_id() if head_part else "",
		"body": body_part.get_part_id() if body_part else "",
		"tail": tail_part.get_part_id() if tail_part else "",
		"level": level,
		"experience": experience,
		"current_health": current_health,
		"is_defending": is_defending,
		"is_exploring": is_exploring,
		"last_fed_time": last_fed_time
	}

static func from_dict(data: Dictionary) -> Dragon:
	# TODO: Reconstruct dragon from saved data
	# Will need access to PartLibrary to lookup parts
	return null
