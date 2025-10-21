extends Resource
class_name Dragon

# Time Constants (in seconds)
const HUNGER_RATE: float = 0.01 / 60.0  # 1% per minute (0.01 per 60 seconds)
const STARVATION_TIME: int = 6000  # 100 minutes until full starvation
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

# Phase 3: Combat & Exploration Properties
@export var exploration_start_time: int = 0  # When exploration began
@export var exploration_duration: int = 0   # How long exploration takes (seconds)

# Computed Stats (recalculated on load)
var total_attack: int = 0
var total_health: int = 0
var total_speed: int = 0
var total_defense: int = 0

# Elemental Attack (determined by parts)
var primary_element: DragonPart.Element = DragonPart.Element.FIRE
var secondary_elements: Array[DragonPart.Element] = []
var elemental_attack_bonus: float = 1.0  # Multiplier for matching elements

# Elemental Defense (1.0 = normal, 0.5 = resistant, 1.5 = weak)
var elemental_resistances: Dictionary = {
	DragonPart.Element.FIRE: 1.0,
	DragonPart.Element.ICE: 1.0,
	DragonPart.Element.LIGHTNING: 1.0,
	DragonPart.Element.NATURE: 1.0,
	DragonPart.Element.SHADOW: 1.0
}

# Life Systems (computed from timestamps)
var hunger_level: float = 0.0     # 0.0 = fed, 1.0 = starving
var fatigue_level: float = 0.0    # 0.0 = rested, 1.0 = exhausted
var happiness_level: float = 0.5  # 0.0 = sad, 1.0 = happy (starts at 50%)

# Equipped Items
@export var equipped_toy_id: String = ""  # ID of equipped toy item

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
	total_defense = 5 + (body_part.defense_bonus * level)
	
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

	# Calculate elemental resistances
	_calculate_elemental_resistances()

	# Calculate elemental attack
	_calculate_elemental_attack()

func _apply_chimera_mutation() -> void:
	# Chimera dragons get massive stat bonuses!
	total_attack = int(total_attack * 2.5)
	total_health = int(total_health * 2.0)
	total_speed = int(total_speed * 1.5)
	total_defense = int(total_defense * 2.0)

	# Chimera dragons have superior elemental balance
	# Reduce all weaknesses and improve all resistances
	for element in elemental_resistances:
		if elemental_resistances[element] < 1.0:  # Resistance
			elemental_resistances[element] = max(0.3, elemental_resistances[element] - 0.2)  # Even more resistant
		elif elemental_resistances[element] > 1.0:  # Weakness
			elemental_resistances[element] = min(1.2, elemental_resistances[element] - 0.3)  # Less weak

	# Chimera dragons have enhanced elemental attacks
	# Boost elemental attack bonus by 20% (1.3 -> 1.5, 1.15 -> 1.35, 1.0 -> 1.2)
	elemental_attack_bonus += 0.2

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
		total_defense += 3 * level
	# Two same elements = partial bonus
	elif elements[0] == elements[1] or elements[1] == elements[2] or elements[0] == elements[2]:
		total_attack += 2 * level
		total_health += 5 * level
		total_speed += 1 * level
		total_defense += 1 * level

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

func _calculate_elemental_resistances() -> void:
	# Reset all resistances to neutral
	for element in DragonPart.Element.values():
		elemental_resistances[element] = 1.0

	# Count how many parts of each element the dragon has
	var element_counts: Dictionary = {}
	var parts = [head_part, body_part, tail_part]

	for part in parts:
		if part:
			if not element_counts.has(part.element):
				element_counts[part.element] = 0
			element_counts[part.element] += 1

	# Grant resistance based on parts (0.1 resistance per part = up to 30% resistance)
	for element in element_counts:
		var resistance_bonus = element_counts[element] * 0.1
		elemental_resistances[element] = max(0.5, 1.0 - resistance_bonus)  # Min 50% damage taken

	# Apply elemental weaknesses (counters)
	for element in element_counts:
		var weakness_element = _get_element_weakness(element)
		if weakness_element != -1:
			# Each part of an element makes you weaker to its counter (10% per part)
			var weakness_penalty = element_counts[element] * 0.1
			elemental_resistances[weakness_element] = min(1.5, elemental_resistances[weakness_element] + weakness_penalty)

func _get_element_weakness(element: DragonPart.Element) -> int:
	# Returns the element this element is weak against
	match element:
		DragonPart.Element.FIRE:
			return DragonPart.Element.ICE  # Fire weak to Ice
		DragonPart.Element.ICE:
			return DragonPart.Element.FIRE  # Ice weak to Fire
		DragonPart.Element.LIGHTNING:
			return DragonPart.Element.NATURE  # Lightning weak to Nature (grounded)
		DragonPart.Element.NATURE:
			return DragonPart.Element.SHADOW  # Nature weak to Shadow (decay)
		DragonPart.Element.SHADOW:
			return DragonPart.Element.LIGHTNING  # Shadow weak to Lightning (light)
	return -1

func _calculate_elemental_attack() -> void:
	# Primary element comes from HEAD part (determines attack type)
	if head_part:
		primary_element = head_part.element

	# Secondary elements from other parts
	secondary_elements.clear()
	if body_part and body_part.element != primary_element:
		secondary_elements.append(body_part.element)
	if tail_part and tail_part.element != primary_element and (not body_part or tail_part.element != body_part.element):
		secondary_elements.append(tail_part.element)

	# Calculate elemental attack bonus based on element matching
	var element_counts: Dictionary = {}
	var parts = [head_part, body_part, tail_part]

	for part in parts:
		if part:
			if not element_counts.has(part.element):
				element_counts[part.element] = 0
			element_counts[part.element] += 1

	# Pure element dragons (all 3 parts same) get +30% elemental damage
	if element_counts.has(primary_element) and element_counts[primary_element] == 3:
		elemental_attack_bonus = 1.3
	# 2 matching parts = +15% elemental damage
	elif element_counts.has(primary_element) and element_counts[primary_element] == 2:
		elemental_attack_bonus = 1.15
	# Mixed elements = normal damage but can hit multiple weaknesses
	else:
		elemental_attack_bonus = 1.0

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

	# Calculate hunger level linearly (1% per minute)
	var time_since_fed = current_time - last_fed_time
	hunger_level = min(1.0, time_since_fed * HUNGER_RATE)

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

func calculate_elemental_damage_against(target: Dragon) -> int:
	"""Calculate total damage this dragon would deal to a target, including elemental bonuses"""
	if not target or is_dead:
		return 0

	# Base damage from attack stat
	var base_damage = total_attack

	# Apply elemental attack bonus (pure element dragons hit harder)
	var elemental_damage = base_damage * elemental_attack_bonus

	# Apply target's elemental resistance to primary element
	var resistance_multiplier = target.get_elemental_resistance(primary_element)
	var final_damage = elemental_damage * resistance_multiplier

	# Mixed element dragons can exploit multiple weaknesses
	# Add bonus damage for each secondary element the target is weak to
	if secondary_elements.size() > 0:
		for secondary_element in secondary_elements:
			var secondary_resistance = target.get_elemental_resistance(secondary_element)
			# If target is weak to this secondary element, add 15% of base attack as bonus damage
			if secondary_resistance > 1.0:
				final_damage += base_damage * 0.15 * (secondary_resistance - 1.0)

	return int(final_damage)

func _die() -> void:
	if is_dead:
		return

	is_dead = true
	current_state = DragonState.DEAD
	death.emit(self)

# === GETTERS FOR EXTERNAL ACCESS ===

func get_attack() -> int:
	return total_attack

func get_health() -> int:
	return total_health

func get_speed() -> int:
	return total_speed

func get_defense() -> int:
	return total_defense

func get_elemental_resistance(element: DragonPart.Element) -> float:
	return elemental_resistances.get(element, 1.0)

func get_all_elemental_resistances() -> Dictionary:
	return elemental_resistances.duplicate()

func get_primary_element() -> DragonPart.Element:
	return primary_element

func get_secondary_elements() -> Array[DragonPart.Element]:
	return secondary_elements.duplicate()

func get_elemental_attack_bonus() -> float:
	return elemental_attack_bonus
