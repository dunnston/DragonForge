extends Node

# Dragon State Management & Progression (Phase 2)
# Manages hunger, fatigue, level progression, mutations, and AFK systems

# Time Constants (in seconds)
const HUNGER_RATE: float = 0.01 / 60.0  # 1% per minute (0.01 per 60 seconds)
const STARVATION_THRESHOLD: float = 1.0  # 100% hunger triggers starvation
const STARVATION_TIME: int = 6000  # 100 minutes until full starvation (100 minutes at 1% per min)
const FATIGUE_TIME: int = 2700     # 45 minutes until tired from activity

# Fatigue Recovery Rates (per 30 second update)
const FATIGUE_RECOVERY_IDLE: float = 0.01    # 1% per 30 seconds (50 minutes to fully recover)
const FATIGUE_RECOVERY_RESTING: float = 0.045  # 4.5% per 30 seconds (~11 minutes to fully recover)

# Food/Healing Constants
const FOOD_HUNGER_HEAL: float = 0.25  # Food heals 25% hunger
const KNIGHT_MEAT_HUNGER_HEAL: float = 0.30  # Knight meat heals 30% hunger
const KNIGHT_MEAT_FATIGUE_COST: float = 0.15  # Knight meat adds 15% fatigue

# Happiness Constants
const HAPPINESS_DECAY_RATE: float = 0.005 / 60.0  # 0.5% per minute (slower than hunger)
const TOY_HAPPINESS_BOOST: float = 0.02 / 60.0  # +2% per minute when toy equipped
const TREAT_HAPPINESS_BOOST: float = 0.15  # +15% happiness per treat
const TREAT_XP_AMOUNT: int = 50  # XP granted by treats

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
signal dragon_happiness_changed(dragon: Dragon, happiness_level: float)
signal dragon_toy_equipped(dragon: Dragon, toy_id: String)
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
	_update_happiness_system(dragon, current_time)
	_update_health_system(dragon, current_time)
	_check_death_conditions(dragon)

# === HUNGER SYSTEM ===

func _update_hunger_system(dragon: Dragon, current_time: int):
	"""Update dragon hunger based on time since last feeding"""
	var time_since_fed = current_time - dragon.last_fed_time

	# Calculate hunger level linearly (1% per minute)
	# hunger_level = time_since_fed * HUNGER_RATE
	var old_hunger = dragon.hunger_level
	dragon.hunger_level = min(1.0, time_since_fed * HUNGER_RATE)

	# Emit signal if hunger changed significantly
	if abs(dragon.hunger_level - old_hunger) > 0.05:
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
	# Recover from fatigue during idle or rest
	if dragon.current_state == Dragon.DragonState.IDLE or dragon.current_state == Dragon.DragonState.RESTING:
		if dragon.fatigue_level > 0.0:
			# Use different recovery rates for IDLE vs RESTING
			var recovery_amount = 0.0
			if dragon.current_state == Dragon.DragonState.RESTING:
				recovery_amount = FATIGUE_RECOVERY_RESTING  # 4.5% per 30 seconds
			else:
				recovery_amount = FATIGUE_RECOVERY_IDLE  # 1% per 30 seconds

			dragon.fatigue_level = max(0.0, dragon.fatigue_level - recovery_amount)

			# Automatically stop resting when fully recovered
			if dragon.fatigue_level <= 0.0 and dragon.current_state == Dragon.DragonState.RESTING:
				set_dragon_state(dragon, Dragon.DragonState.IDLE)

	# For active states (EXPLORING, TRAINING, DEFENDING), fatigue does NOT change
	# Fatigue will be added when the activity completes (handled by respective managers)

# === HAPPINESS SYSTEM ===

func _update_happiness_system(dragon: Dragon, current_time: int):
	"""Update dragon happiness based on time and equipped toy"""
	var old_happiness = dragon.happiness_level

	# Base happiness decay (0.5% per minute)
	var time_delta = 30.0  # Updated every 30 seconds
	dragon.happiness_level -= HAPPINESS_DECAY_RATE * time_delta

	# Toy happiness boost if equipped
	if dragon.equipped_toy_id != "":
		dragon.happiness_level += TOY_HAPPINESS_BOOST * time_delta

	# Clamp happiness between 0 and 1
	dragon.happiness_level = clamp(dragon.happiness_level, 0.0, 1.0)

	# Emit signal if happiness changed significantly
	if abs(dragon.happiness_level - old_happiness) > 0.05:
		dragon_happiness_changed.emit(dragon, dragon.happiness_level)

# === HEALTH SYSTEM ===

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

		# Trigger part recovery system
		if DragonDeathManager and DragonDeathManager.instance:
			DragonDeathManager.instance.handle_dragon_death(dragon, "starvation")

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

# === HELPER FUNCTIONS FOR STATE TRANSITIONS ===

func start_training(dragon: Dragon) -> bool:
	"""Start training a dragon (convenience wrapper)"""
	return set_dragon_state(dragon, Dragon.DragonState.TRAINING)

func start_resting(dragon: Dragon) -> bool:
	"""Start resting a dragon (convenience wrapper)"""
	return set_dragon_state(dragon, Dragon.DragonState.RESTING)

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
	"""Use a treat to grant XP and happiness to dragon"""
	if not dragon or dragon.is_dead:
		return false

	var consumed = false

	# Try InventoryManager (items are stored here)
	if InventoryManager and InventoryManager.instance:
		var removed = InventoryManager.instance.remove_item_by_id("treat", 1)
		if removed > 0:
			consumed = true

	if not consumed:
		print("[DragonStateManager] No treats available!")
		return false

	# Treats grant XP and happiness
	gain_experience(dragon, TREAT_XP_AMOUNT)
	dragon.happiness_level = min(1.0, dragon.happiness_level + TREAT_HAPPINESS_BOOST)
	dragon_happiness_changed.emit(dragon, dragon.happiness_level)

	print("[DragonStateManager] %s enjoyed a treat! +%d XP, +%.0f%% happiness" % [dragon.dragon_name, TREAT_XP_AMOUNT, TREAT_HAPPINESS_BOOST * 100])
	return true

func use_health_pot_on_dragon(dragon: Dragon) -> bool:
	"""Use a health potion to heal dragon to full health"""
	if not dragon or dragon.is_dead:
		return false

	if dragon.current_health >= dragon.total_health:
		print("[DragonStateManager] %s is already at full health!" % dragon.dragon_name)
		return false

	var consumed = false

	# Try InventoryManager (items are stored here)
	if InventoryManager and InventoryManager.instance:
		var removed = InventoryManager.instance.remove_item_by_id("health_potion", 1)
		if removed > 0:
			consumed = true

	if not consumed:
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

	# Try InventoryManager (items are stored here)
	if InventoryManager and InventoryManager.instance:
		var removed = InventoryManager.instance.remove_item_by_id("food", 1)
		if removed > 0:
			# Reduce hunger by 25%
			var old_hunger = dragon.hunger_level
			dragon.hunger_level = max(0.0, dragon.hunger_level - FOOD_HUNGER_HEAL)

			# Update last_fed_time to reflect the new hunger level
			# Since hunger = time_since_fed * HUNGER_RATE
			# We need: time_since_fed = hunger_level / HUNGER_RATE
			var current_time = Time.get_unix_time_from_system()
			var new_time_since_fed = dragon.hunger_level / HUNGER_RATE
			dragon.last_fed_time = int(current_time - new_time_since_fed)

			dragon_hunger_changed.emit(dragon, dragon.hunger_level)
			print("[DragonStateManager] %s ate food! Hunger reduced from %.0f%% to %.0f%%" % [dragon.dragon_name, old_hunger * 100, dragon.hunger_level * 100])
			return true

	print("[DragonStateManager] No food available!")
	return false

func use_knight_meat_on_dragon(dragon: Dragon) -> bool:
	"""Use knight meat to feed dragon (30% hunger reduction, 15% fatigue increase)"""
	if not dragon or dragon.is_dead:
		return false
	
	# Only feed if dragon has at least 5% hunger
	if dragon.hunger_level < 0.05:
		print("[DragonStateManager] %s is not hungry!" % dragon.dragon_name)
		return false
	
	# Try InventoryManager
	if InventoryManager and InventoryManager.instance:
		var removed = InventoryManager.instance.remove_item_by_id("knight_meat", 1)
		if removed > 0:
			# Reduce hunger by 30%
			var old_hunger = dragon.hunger_level
			dragon.hunger_level = max(0.0, dragon.hunger_level - KNIGHT_MEAT_HUNGER_HEAL)
			
			# Add fatigue by 15%
			var old_fatigue = dragon.fatigue_level
			dragon.fatigue_level = min(1.0, dragon.fatigue_level + KNIGHT_MEAT_FATIGUE_COST)
			
			# Update last_fed_time to reflect the new hunger level
			var current_time = Time.get_unix_time_from_system()
			var new_time_since_fed = dragon.hunger_level / HUNGER_RATE
			dragon.last_fed_time = int(current_time - new_time_since_fed)
			
			dragon_hunger_changed.emit(dragon, dragon.hunger_level)
			print("[DragonStateManager] %s ate knight meat! Hunger: %.0f%% -> %.0f%%, Fatigue: %.0f%% -> %.0f%%" % 
				[dragon.dragon_name, old_hunger * 100, dragon.hunger_level * 100, old_fatigue * 100, dragon.fatigue_level * 100])
			return true
		else:
			print("[DragonStateManager] No knight meat available!")
			return false
	
	print("[DragonStateManager] No inventory system available!")
	return false

# === TOY EQUIPMENT SYSTEM ===

func equip_toy_to_dragon(dragon: Dragon, toy_id: String) -> bool:
	"""Equip a toy to a dragon for passive happiness boost"""
	if not dragon or dragon.is_dead:
		return false

	# Check if dragon already has this toy equipped
	if dragon.equipped_toy_id == toy_id:
		print("[DragonStateManager] %s already has this toy equipped!" % dragon.dragon_name)
		return false

	# Unequip current toy if any
	if dragon.equipped_toy_id != "":
		unequip_toy_from_dragon(dragon)

	# Check if toy exists in inventory
	if InventoryManager and InventoryManager.instance:
		var toy_count = InventoryManager.instance.get_item_count(toy_id)
		if toy_count <= 0:
			print("[DragonStateManager] No %s in inventory!" % toy_id)
			return false

	# Equip the toy
	dragon.equipped_toy_id = toy_id
	dragon_toy_equipped.emit(dragon, toy_id)
	print("[DragonStateManager] %s equipped %s! (+2%% happiness per minute)" % [dragon.dragon_name, toy_id])
	return true

func unequip_toy_from_dragon(dragon: Dragon) -> bool:
	"""Unequip the currently equipped toy from a dragon"""
	if not dragon:
		return false

	if dragon.equipped_toy_id == "":
		print("[DragonStateManager] %s has no toy equipped!" % dragon.dragon_name)
		return false

	var old_toy_id = dragon.equipped_toy_id
	dragon.equipped_toy_id = ""
	dragon_toy_equipped.emit(dragon, "")
	print("[DragonStateManager] %s unequipped %s" % [dragon.dragon_name, old_toy_id])
	return true

# === DEBUG & TESTING FUNCTIONS ===

# Debug time multiplier (set > 1.0 to speed up time for testing)
var debug_time_multiplier: float = 1.0

func set_time_multiplier(multiplier: float):
	"""Debug: Set time multiplier for faster testing (e.g., 60.0 = 1 hour per minute)"""
	debug_time_multiplier = max(1.0, multiplier)
	print("🧪 DEBUG: Time multiplier set to %.1fx (1 real minute = %.1f game minutes)" % [debug_time_multiplier, debug_time_multiplier])

func force_hunger(dragon: Dragon, hunger_percent: float):
	"""Debug: Set dragon hunger to specific level (0.0 = fed, 1.0 = starving)"""
	if not dragon:
		return

	hunger_percent = clamp(hunger_percent, 0.0, 1.0)
	var current_time = Time.get_unix_time_from_system()

	# Directly set hunger level
	dragon.hunger_level = hunger_percent

	# Calculate appropriate last_fed_time for new linear system
	# hunger_level = time_since_fed * HUNGER_RATE
	# Solve for time_since_fed: time_since_fed = hunger_level / HUNGER_RATE
	var time_since_fed = int(hunger_percent / HUNGER_RATE)
	dragon.last_fed_time = current_time - time_since_fed

	# Emit signal
	dragon_hunger_changed.emit(dragon, dragon.hunger_level)
	print("🧪 DEBUG: Set %s hunger to %.0f%% (last fed %.1f minutes ago)" % [dragon.dragon_name, hunger_percent * 100, time_since_fed / 60.0])

func force_fatigue(dragon: Dragon, fatigue_percent: float):
	"""Debug: Set dragon fatigue to specific level (0.0 = rested, 1.0 = exhausted)"""
	if not dragon:
		return

	fatigue_percent = clamp(fatigue_percent, 0.0, 1.0)
	dragon.fatigue_level = fatigue_percent

	# Update state_start_time to match the fatigue level
	var current_time = Time.get_unix_time_from_system()
	if dragon.current_state == Dragon.DragonState.IDLE or dragon.current_state == Dragon.DragonState.RESTING:
		# For idle/resting, fatigue should be decreasing
		dragon.state_start_time = current_time
	else:
		# For active states, calculate how long they've been active
		var time_active = int(fatigue_percent * FATIGUE_TIME)
		dragon.state_start_time = current_time - time_active

	print("🧪 DEBUG: Set %s fatigue to %.0f%%" % [dragon.dragon_name, fatigue_percent * 100])

func force_damage(dragon: Dragon, damage_percent: float):
	"""Debug: Damage dragon by percentage of max health"""
	if not dragon or dragon.is_dead:
		return

	var damage = int(dragon.total_health * clamp(damage_percent, 0.0, 1.0))
	dragon.current_health = max(0, dragon.current_health - damage)
	dragon_health_changed.emit(dragon, dragon.current_health, dragon.total_health)
	print("🧪 DEBUG: Damaged %s for %d HP (%.0f%%)" % [dragon.dragon_name, damage, damage_percent * 100])

	_check_death_conditions(dragon)

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

func reset_dragon_state(dragon: Dragon):
	"""Debug: Reset dragon to perfect condition"""
	if not dragon:
		return

	var current_time = Time.get_unix_time_from_system()
	dragon.last_fed_time = current_time
	dragon.state_start_time = current_time
	dragon.hunger_level = 0.0
	dragon.fatigue_level = 0.0
	dragon.current_health = dragon.total_health
	dragon.is_dead = false

	update_dragon_systems(dragon)
	print("🧪 DEBUG: Reset %s to perfect condition" % dragon.dragon_name)

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
