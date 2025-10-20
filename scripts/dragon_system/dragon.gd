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

# Combat Constants (Phase 3)
const FATIGUE_PER_COMBAT: float = 0.1  # 10% fatigue per battle
const FATIGUE_RECOVERY_RATE: float = 0.05  # 5% per minute when idle
const COMBAT_XP_BASE: int = 10  # Base XP per victory
const EXPLORATION_FATIGUE = {
	15: 0.15,  # 15min = 15% fatigue
	30: 0.25,  # 30min = 25% fatigue
	60: 0.40   # 60min = 40% fatigue
}
const FATIGUE_THRESHOLD: float = 0.8  # Auto-remove at 80%+ fatigue
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

# Phase 3: Combat & Exploration Properties
@export var exploration_start_time: int = 0  # When exploration began
@export var exploration_duration: int = 0   # How long exploration takes (seconds)

# Computed Stats (recalculated on load)
var total_attack: int = 0
var total_health: int = 0
var total_speed: int = 0

# Life Systems (computed from timestamps)
var hunger_level: float = 0.0     # 0.0 = fed, 1.0 = starving
var fatigue_level: float = 0.0    # 0.0 = rested, 1.0 = exhausted

# Phase 3: New Signals for Combat & Exploration
signal assignment_changed(dragon: Dragon, old_state: DragonState, new_state: DragonState)
signal exploration_started(dragon: Dragon, duration_minutes: int)
signal exploration_completed(dragon: Dragon)

# Existing Signals for Integration  
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
	
	# Apply mutation bonus (Holy Shit Moment!)
	if is_chimera_mutation:
		_apply_chimera_mutation()
	else:
		# Regular element synergy bonuses
		_apply_element_synergy()
	
	# Apply starvation/fatigue penalties
	_apply_status_penalties()

func _apply_chimera_mutation() -> void:
	# Chimera dragons get massive stat bonuses!
	total_attack = int(total_attack * 2.5)
	total_health = int(total_health * 2.0)
	total_speed = int(total_speed * 1.5)
	
	# Update current health proportionally if it was at max
	if current_health >= (total_health / 2.0):
		current_health = total_health

func _apply_element_synergy() -> void:
	# Check for element combinations that provide synergy bonuses
	var elements = [head_part.element, body_part.element, tail_part.element]
	
	# All same element = pure bonus
	if elements[0] == elements[1] and elements[1] == elements[2]:
		total_attack += 5 * level
		total_health += 10 * level
		total_speed += 2 * level
	# Two same elements = partial bonus
	elif elements[0] == elements[1] or elements[1] == elements[2] or elements[0] == elements[2]:
		total_attack += 2 * level
		total_health += 5 * level
		total_speed += 1 * level

func _apply_status_penalties() -> void:
	# Apply hunger penalties
	if hunger_level > 0.5:
		var penalty = (hunger_level - 0.5) * 0.4  # Up to 20% penalty at max hunger
		total_attack = int(total_attack * (1.0 - penalty))
		total_speed = int(total_speed * (1.0 - penalty))
	
	# Apply fatigue penalties
	if fatigue_level > 0.7:
		var penalty = (fatigue_level - 0.7) * 0.5  # Up to 15% penalty at max fatigue
		total_attack = int(total_attack * (1.0 - penalty))

func get_combination_key() -> String:
	# Create a unique key for this dragon combination
	if not head_part or not body_part or not tail_part:
		return "incomplete"
	
	return "%s_%s_%s" % [
		DragonPart.Element.keys()[head_part.element],
		DragonPart.Element.keys()[body_part.element], 
		DragonPart.Element.keys()[tail_part.element]
	]

func update_life_systems() -> void:
	# Update hunger and fatigue based on time passage
	var current_time = Time.get_unix_time_from_system()
	
	# Calculate hunger level
	var time_since_fed = current_time - last_fed_time
	hunger_level = min(1.0, time_since_fed / float(HUNGER_INTERVAL))
	
	# Calculate fatigue level (based on activity state)
	if current_state != DragonState.RESTING:
		var time_in_state = current_time - state_start_time
		fatigue_level = min(1.0, time_in_state / float(FATIGUE_TIME))
	else:
		# Resting reduces fatigue
		var time_resting = current_time - state_start_time
		var fatigue_reduction = time_resting / float(REST_TIME)
		fatigue_level = max(0.0, fatigue_level - fatigue_reduction)
	
	# Recalculate stats with new status effects
	calculate_stats()

func feed() -> void:
	# Reset hunger and restore some health
	last_fed_time = Time.get_unix_time_from_system()
	hunger_level = 0.0
	
	# Restore health when fed
	var heal_amount = int(total_health * 0.2)  # 20% heal
	current_health = min(total_health, current_health + heal_amount)
	
	# Recalculate stats
	calculate_stats()

func set_state(new_state: DragonState) -> void:
	if current_state != new_state:
		var old_state = current_state
		current_state = new_state
		state_start_time = Time.get_unix_time_from_system()
		state_changed.emit(self, old_state, new_state)

func gain_experience(amount: int) -> void:
	if is_dead or level >= MAX_LEVEL:
		return
		
	experience += amount
	_check_level_up()

func _check_level_up() -> void:
	var exp_needed = _get_experience_for_level(level + 1)
	if experience >= exp_needed and level < MAX_LEVEL:
		level += 1
		calculate_stats()  # Recalculate stats with new level
		level_up.emit(self, level)
		
		# Check for next level up (in case of massive exp gain)
		if level < MAX_LEVEL:
			_check_level_up()

func _get_experience_for_level(target_level: int) -> int:
	if target_level <= 1:
		return 0
	
	var total_exp = 0
	for i in range(2, target_level + 1):
		total_exp += int(EXP_BASE * pow(EXP_MULTIPLIER, i - 2))
	return total_exp

func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	current_health = max(0, current_health - amount)
	health_changed.emit(self, current_health, total_health)
	
	if current_health <= 0:
		_die()

func _die() -> void:
	if is_dead:
		return
		
	is_dead = true
	death.emit(self)
