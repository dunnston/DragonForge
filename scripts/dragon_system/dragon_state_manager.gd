extends Node

# Dragon State Management & Progression (Phase 2)
# Manages hunger, fatigue, level progression, mutations, and AFK systems

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
const MUTATION_CHANCE: float = 0.01  # 1% chance for Chimera Mutation

# Singleton instance
static var instance: DragonStateManager

# Signals for integration
signal dragon_state_changed(dragon: Dragon, old_state: int, new_state: int)
signal dragon_level_up(dragon: Dragon, new_level: int)
signal dragon_hunger_changed(dragon: Dragon, hunger_level: float)
signal dragon_health_changed(dragon: Dragon, current_health: int, max_health: int)
signal dragon_death(dragon: Dragon)
signal chimera_mutation_discovered(dragon: Dragon)

# State management
var managed_dragons: Dictionary = {}  # dragon_id -> dragon

func _ready():
	instance = self
	# Update all dragons every 30 seconds for AFK systems
	var update_timer = Timer.new()
	add_child(update_timer)
	update_timer.wait_time = 30.0
	update_timer.timeout.connect(_update_all_dragons)
	update_timer.start()

# === DRAGON REGISTRATION & MANAGEMENT ===

func register_dragon(dragon: Dragon):
	"""Register a dragon for state management"""
	if not dragon:
		return
	managed_dragons[dragon.dragon_id] = dragon
	print("Dragon %s registered for state management" % dragon.dragon_name)

func unregister_dragon(dragon: Dragon):
	"""Remove dragon from state management"""
	if dragon and managed_dragons.has(dragon.dragon_id):
		managed_dragons.erase(dragon.dragon_id)

func get_managed_dragon(dragon_id: String) -> Dragon:
	"""Get a managed dragon by ID"""
	return managed_dragons.get(dragon_id)

# === CORE UPDATE LOOP ===

func _update_all_dragons():
	"""Called every 30 seconds to update all AFK systems"""
	for dragon in managed_dragons.values():
		update_dragon_systems(dragon)

func update_dragon_systems(dragon: Dragon):
	"""Update all time-based systems for a dragon"""
	if not dragon or dragon.is_dead:
		return
		
	var current_time = Time.get_unix_time_from_system()
	
	# Update all systems
	_update_hunger_system(dragon, current_time)
	_update_fatigue_system(dragon, current_time)
	_update_health_system(dragon, current_time)
	_check_death_conditions(dragon)

# === HUNGER SYSTEM ===

func _update_hunger_system(dragon: Dragon, current_time: int):
	"""Update dragon hunger based on time since last feeding"""
	var time_since_fed = current_time - dragon.last_fed_time
	
	# Calculate hunger level (0.0 = fed, 1.0 = starving)
	var old_hunger = dragon.hunger_level
	if time_since_fed >= STARVATION_TIME:
		dragon.hunger_level = 1.0  # Full starvation
	elif time_since_fed >= HUNGER_INTERVAL:
		dragon.hunger_level = (time_since_fed - HUNGER_INTERVAL) / float(STARVATION_TIME - HUNGER_INTERVAL)
	else:
		dragon.hunger_level = 0.0  # Well fed
	
	# Emit signal if hunger changed significantly
	if abs(dragon.hunger_level - old_hunger) > 0.1:
		dragon_hunger_changed.emit(dragon, dragon.hunger_level)

func feed_dragon(dragon: Dragon) -> bool:
	"""Feed a dragon, resetting hunger and restoring health"""
	if not dragon or dragon.is_dead:
		return false
		
	dragon.last_fed_time = Time.get_unix_time_from_system()
	dragon.hunger_level = 0.0
	
	# Health regeneration when fed
	if dragon.current_health < dragon.total_health:
		dragon.current_health = min(dragon.total_health, dragon.current_health + (dragon.total_health * 0.3))
		dragon_health_changed.emit(dragon, dragon.current_health, dragon.total_health)
	
	dragon_hunger_changed.emit(dragon, 0.0)
	print("%s has been fed and feels much better!" % dragon.dragon_name)
	return true

func _update_fatigue_system(dragon: Dragon, current_time: int):
	"""Update dragon fatigue based on activity time"""
	# Skip fatigue for idle or resting dragons
	if dragon.current_state == Dragon.DragonState.IDLE or dragon.current_state == Dragon.DragonState.RESTING:
		# Recover from fatigue during rest
		if dragon.fatigue_level > 0.0:
			var rest_time = current_time - dragon.state_start_time
			if rest_time >= REST_TIME:
				dragon.fatigue_level = 0.0  # Fully rested
			else:
				dragon.fatigue_level = max(0.0, dragon.fatigue_level - (rest_time / float(REST_TIME)))
		return
	
	# Calculate fatigue for active dragons
	var activity_time = current_time - dragon.state_start_time
	if activity_time >= FATIGUE_TIME:
		dragon.fatigue_level = 1.0  # Exhausted
	else:
		dragon.fatigue_level = activity_time / float(FATIGUE_TIME)

func _update_health_system(dragon: Dragon, current_time: int):
	"""Update dragon health with regeneration and penalties"""
	var old_health = dragon.current_health
	
	# Starvation damage
	if dragon.hunger_level >= 1.0:
		# Lose 10% health per hour when starving
		var time_starving = current_time - (dragon.last_fed_time + STARVATION_TIME)
		var damage_per_hour = dragon.total_health * 0.1
		var hours_starving = time_starving / 3600.0
		var damage = int(damage_per_hour * hours_starving)
		
		dragon.current_health = max(0, dragon.current_health - damage)
	
	# Emit signal if health changed
	if dragon.current_health != old_health:
		dragon_health_changed.emit(dragon, dragon.current_health, dragon.total_health)

func _check_death_conditions(dragon: Dragon):
	"""Check if dragon should die from starvation"""
	if dragon.current_health <= 0 and dragon.hunger_level >= 1.0 and not dragon.is_dead:
		dragon.is_dead = true
		dragon_death.emit(dragon)
		print("[DEAD] %s has died from starvation!" % dragon.dragon_name)

# === EXPERIENCE & LEVELING SYSTEM ===

func gain_experience(dragon: Dragon, exp_amount: int):
	"""Grant experience points to a dragon and check for level up"""
	if not dragon or dragon.is_dead or dragon.level >= MAX_LEVEL:
		return
	
	dragon.experience += exp_amount
	_check_level_up(dragon)

func _check_level_up(dragon: Dragon):
	"""Check if dragon should level up and handle the process"""
	while dragon.level < MAX_LEVEL:
		var exp_needed = get_experience_for_level(dragon.level + 1)
		if dragon.experience >= exp_needed:
			dragon.level += 1
			dragon.calculate_stats()  # Recalculate with new level
			print("[LEVEL UP] %s reached level %d!" % [dragon.dragon_name, dragon.level])
			dragon_level_up.emit(dragon, dragon.level)
		else:
			break

func get_experience_for_level(level: int) -> int:
	"""Calculate total experience needed for a specific level"""
	if level <= 1:
		return 0
	
	var total_exp = 0
	for i in range(2, level + 1):
		total_exp += int(EXP_BASE * pow(EXP_MULTIPLIER, i - 2))
	return total_exp

func get_experience_to_next_level(dragon: Dragon) -> int:
	"""Get experience needed for dragon's next level"""
	if not dragon or dragon.level >= MAX_LEVEL:
		return 0
		
	var next_level_exp = get_experience_for_level(dragon.level + 1)
	return next_level_exp - dragon.experience

# === MUTATION SYSTEM (Holy Shit Moment!) ===

func attempt_chimera_mutation(dragon: Dragon) -> bool:
	"""Try to mutate dragon into a Chimera (1% chance)"""
	if not dragon or dragon.is_chimera_mutation:
		return false
		
	if randf() <= MUTATION_CHANCE:
		dragon.is_chimera_mutation = true
		dragon.dragon_name += " ⚡CHIMERA⚡"
		dragon.calculate_stats()  # Recalculate with ALL element bonuses!
		
		chimera_mutation_discovered.emit(dragon)
		print("🔥⚡ HOLY SHIT! %s has mutated into a CHIMERA DRAGON! ⚡🔥" % dragon.dragon_name)
		return true
	
	return false

# === STATE MANAGEMENT ===

func set_dragon_state(dragon: Dragon, new_state: int) -> bool:
	"""Change dragon's activity state"""
	if not dragon or dragon.is_dead:
		return false
		
	var old_state = dragon.current_state
	if old_state == new_state:
		return true
	
	dragon.current_state = new_state
	dragon.state_start_time = Time.get_unix_time_from_system()
	
	dragon_state_changed.emit(dragon, old_state, new_state)
	print("%s is now %s" % [dragon.dragon_name, _get_state_name(new_state)])
	return true

func _get_state_name(state: int) -> String:
	"""Get human-readable state name"""
	match state:
		Dragon.DragonState.IDLE: return "idling"
		Dragon.DragonState.DEFENDING: return "defending"
		Dragon.DragonState.EXPLORING: return "exploring"
		Dragon.DragonState.TRAINING: return "training"
		Dragon.DragonState.RESTING: return "resting"
		_: return "unknown"

# === ITEM USAGE (from Treasure Vault) ===

func use_treat_on_dragon(dragon: Dragon) -> bool:
	"""Use a treat to grant XP to dragon"""
	if not dragon or dragon.is_dead:
		return false

	if not TreasureVault or not TreasureVault.instance:
		return false

	if not TreasureVault.instance.use_item("treats", 1):
		print("[DragonStateManager] No treats available!")
		return false

	# Treats grant 50 XP
	var xp_amount = 50
	gain_experience(dragon, xp_amount)
	print("[DragonStateManager] %s enjoyed a treat and gained %d XP!" % [dragon.dragon_name, xp_amount])
	return true

func use_health_pot_on_dragon(dragon: Dragon) -> bool:
	"""Use a health potion to heal dragon to full health"""
	if not dragon or dragon.is_dead:
		return false

	if dragon.current_health >= dragon.total_health:
		print("[DragonStateManager] %s is already at full health!" % dragon.dragon_name)
		return false

	if not TreasureVault or not TreasureVault.instance:
		return false

	if not TreasureVault.instance.use_item("health_pots", 1):
		print("[DragonStateManager] No health potions available!")
		return false

	# Heal to full
	dragon.current_health = dragon.total_health
	dragon_health_changed.emit(dragon, dragon.current_health, dragon.total_health)
	print("[DragonStateManager] %s drank a health potion and is fully healed!" % dragon.dragon_name)
	return true

func use_food_on_dragon(dragon: Dragon) -> bool:
	"""Use food to reset dragon hunger"""
	if not dragon or dragon.is_dead:
		return false

	if dragon.hunger_level <= 0.0:
		print("[DragonStateManager] %s is not hungry!" % dragon.dragon_name)
		return false

	if not TreasureVault or not TreasureVault.instance:
		return false

	if not TreasureVault.instance.use_item("food", 1):
		print("[DragonStateManager] No food available!")
		return false

	# Reset hunger
	dragon.last_fed_time = Time.get_unix_time_from_system()
	dragon.hunger_level = 0.0
	dragon_hunger_changed.emit(dragon, 0.0)
	print("[DragonStateManager] %s ate food and is no longer hungry!" % dragon.dragon_name)
	return true

func use_toy_on_dragon(dragon: Dragon) -> bool:
	"""Use toy to increase dragon happiness (placeholder for future system)"""
	if not dragon or dragon.is_dead:
		return false

	if not TreasureVault or not TreasureVault.instance:
		return false

	if not TreasureVault.instance.use_item("toys", 1):
		print("[DragonStateManager] No toys available!")
		return false

	# TODO: Implement happiness system
	# For now, just provide a small XP bonus
	gain_experience(dragon, 25)
	print("[DragonStateManager] %s played with a toy and feels happy! (+25 XP)" % dragon.dragon_name)
	return true

# === DEBUG & TESTING FUNCTIONS ===

func force_level_up(dragon: Dragon, target_level: int = -1):
	"""Debug: Force level up dragon (for testing)"""
	if not dragon:
		return
	
	if target_level == -1:
		target_level = min(dragon.level + 1, MAX_LEVEL)
	else:
		target_level = min(target_level, MAX_LEVEL)
	
	dragon.experience = get_experience_for_level(target_level)
	_check_level_up(dragon)
	print("🧪 DEBUG: Forced %s to level %d" % [dragon.dragon_name, dragon.level])

func force_mutation(dragon: Dragon):
	"""Debug: Force Chimera mutation (for testing)"""
	if not dragon or dragon.is_chimera_mutation:
		return
		
	dragon.is_chimera_mutation = true
	dragon.dragon_name += " ⚡CHIMERA⚡"
	dragon.calculate_stats()
	
	chimera_mutation_discovered.emit(dragon)
	print("🧪 DEBUG: Forced mutation for %s" % dragon.dragon_name)

func simulate_time_passage(dragon: Dragon, hours: float):
	"""Debug: Simulate time passage (for testing AFK mechanics)"""
	if not dragon:
		return
	
	var seconds = int(hours * 3600)
	dragon.last_fed_time -= seconds
	dragon.state_start_time -= seconds
	
	update_dragon_systems(dragon)
	print("🧪 DEBUG: Simulated %.1f hours for %s" % [hours, dragon.dragon_name])

func get_dragon_status(dragon: Dragon) -> Dictionary:
	"""Get comprehensive dragon status for debugging"""
	if not dragon:
		return {}
		
	return {
		"name": dragon.dragon_name,
		"level": dragon.level,
		"experience": dragon.experience,
		"exp_to_next": get_experience_to_next_level(dragon),
		"health": "%d/%d" % [dragon.current_health, dragon.total_health],
		"hunger_level": "%.1f%%" % (dragon.hunger_level * 100),
		"fatigue_level": "%.1f%%" % (dragon.fatigue_level * 100),
		"state": _get_state_name(dragon.current_state),
		"is_chimera": dragon.is_chimera_mutation,
		"is_dead": dragon.is_dead,
		"stats": "ATK:%d HP:%d SPD:%d" % [dragon.total_attack, dragon.total_health, dragon.total_speed]
	}
