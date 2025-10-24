# Exploration Manager - Handle dragon exploration missions
# Dragons can explore for 15/30/60 minutes and return with loot
extends Node

# === SINGLETON ===
static var instance: ExplorationManager

# === DEV MODE (SET TO false FOR PRODUCTION) ===
const DEV_MODE: bool = true  # When true, uses SECONDS instead of MINUTES for exploration
const DEV_TIME_SCALE: int = 1  # 1 = seconds, 60 = minutes

# === EXPLORATION TRACKING ===
var active_explorations: Dictionary = {}  # {dragon_id: exploration_data}

# === EXPLORATION DURATIONS (in seconds) ===
const DURATION_SHORT: int = 900   # 15 minutes (or 15 seconds in DEV_MODE)
const DURATION_MEDIUM: int = 1800  # 30 minutes (or 30 seconds in DEV_MODE)
const DURATION_LONG: int = 3600    # 60 minutes (or 60 seconds in DEV_MODE)

# === RISK/REWARD CONSTANTS ===
# Base rewards (scaled by duration and dragon level)
const BASE_GOLD_PER_MINUTE: int = 2
const BASE_XP_PER_MINUTE: int = 3
const PARTS_DROP_CHANCE: float = 0.3  # 30% chance per exploration

# Gold reward randomness
const GOLD_VARIANCE: float = 0.25  # ±25% random variance

# Destination difficulty multipliers (affects gold, XP, and risk)
const DESTINATION_MULTIPLIERS = {
	"volcanic_caves": 1.0,      # Easy - starter area
	"ancient_forest": 1.5,      # Medium - Friend tier required
	"frozen_tundra": 2.0,       # Hard - Companion tier required
	"thunder_peak": 2.5,        # Very Hard - Best Friend tier required
	"unknown": 1.0              # Default fallback
}

# Item drop rates
const ITEM_DROP_CHANCES = {
	"treats": 0.25,      # 25% chance
	"health_pots": 0.20, # 20% chance
	"food": 0.30,        # 30% chance
	"toys": 0.15         # 15% chance
}

# Damage and hunger penalties (percentage of max)
const DAMAGE_RISK = {
	15: 0.15,  # 15% chance of taking 10-20% damage
	30: 0.25,  # 25% chance of taking 15-30% damage
	60: 0.35   # 35% chance of taking 20-40% damage
}

# === SIGNALS ===
signal exploration_started(dragon: Dragon, destination: String)
signal exploration_completed(dragon: Dragon, destination: String, rewards: Dictionary)
signal exploration_failed(dragon: Dragon, reason: String)

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	# Print DEV_MODE status on startup
	if DEV_MODE:
		print("\n⚡ [EXPLORATION MANAGER] DEV MODE ENABLED ⚡")
		print("   → Explorations use SECONDS instead of MINUTES")
		print("   → 15min = 15sec, 30min = 30sec, 60min = 60sec")
		print("   → Set DEV_MODE = false for production\n")
	else:
		print("[ExplorationManager] Production mode - using real-time durations")

	# Check explorations every 10 seconds (or 1 second in dev mode for responsiveness)
	var timer = Timer.new()
	timer.wait_time = 1.0 if DEV_MODE else 10.0
	timer.timeout.connect(_check_explorations)
	add_child(timer)
	timer.start()

# === EXPLORATION MANAGEMENT ===

func start_exploration(dragon: Dragon, duration_minutes: int, destination: String = "unknown") -> bool:
	"""
	Send a dragon on an exploration mission.

	Args:
		dragon: The dragon to send exploring
		duration_minutes: How long to explore (15, 30, or 60)
		destination: Which destination to explore (for map visualization)

	Returns:
		true if exploration started, false if failed
	"""
	# Validation checks
	if not dragon:
		print("[ExplorationManager] ERROR: Invalid dragon")
		return false

	if dragon.is_dead:
		exploration_failed.emit(dragon, "Dragon is dead")
		return false

	# Allow exploration from IDLE, RESTING, TRAINING, and DEFENDING states
	# But not from EXPLORING (can't explore twice) or DEAD
	if dragon.current_state == Dragon.DragonState.EXPLORING:
		exploration_failed.emit(dragon, "Dragon is already exploring")
		return false

	# Check if dragon is too fatigued (must be at least 50% rested)
	if dragon.fatigue_level > 0.5:
		exploration_failed.emit(dragon, "Dragon is too fatigued to explore (needs 50% rest)")
		return false

	# Validate duration
	if duration_minutes not in [15, 30, 60]:
		print("[ExplorationManager] ERROR: Invalid duration %d (must be 15, 30, or 60)" % duration_minutes)
		return false

	# Calculate duration in seconds (uses seconds instead of minutes in DEV_MODE)
	var duration_seconds = duration_minutes * 60
	if DEV_MODE:
		duration_seconds = duration_minutes  # Use seconds for fast testing
		print("[ExplorationManager] [DEV MODE] Using %d SECONDS instead of minutes" % duration_minutes)

	# Apply speed bonus for PetDragons with high affection
	if dragon is PetDragon:
		var speed_bonus = dragon.get_exploration_speed_bonus()
		duration_seconds = int(duration_seconds * speed_bonus)
		if speed_bonus < 1.0:
			print("[ExplorationManager] Pet affection speed bonus: %d%% faster!" % int((1.0 - speed_bonus) * 100))

	var current_time = Time.get_unix_time_from_system()

	# Set dragon state (use proper state setter to update state_start_time)
	if DragonStateManager and DragonStateManager.instance:
		DragonStateManager.instance.set_dragon_state(dragon, Dragon.DragonState.EXPLORING)
	else:
		dragon.current_state = Dragon.DragonState.EXPLORING
	dragon.exploration_start_time = current_time
	dragon.exploration_duration = duration_seconds

	# Track exploration
	active_explorations[dragon.dragon_id] = {
		"start_time": current_time,
		"duration": duration_seconds,
		"duration_minutes": duration_minutes,
		"destination": destination,
		"dragon": dragon
	}

	exploration_started.emit(dragon, destination)
	var time_unit = "seconds" if DEV_MODE else "minutes"
	print("[ExplorationManager] %s started exploring for %d %s" % [dragon.dragon_name, duration_minutes, time_unit])
	return true

func cancel_exploration(dragon: Dragon) -> bool:
	"""Cancel an active exploration early (no rewards)"""
	if not dragon or not active_explorations.has(dragon.dragon_id):
		return false

	active_explorations.erase(dragon.dragon_id)
	# Use proper state setter to update state_start_time
	if DragonStateManager and DragonStateManager.instance:
		DragonStateManager.instance.set_dragon_state(dragon, Dragon.DragonState.IDLE)
	else:
		dragon.current_state = Dragon.DragonState.IDLE
	print("[ExplorationManager] %s exploration cancelled" % dragon.dragon_name)
	return true

func get_exploration_progress(dragon: Dragon) -> float:
	"""Get exploration completion percentage (0.0 to 1.0)"""
	if not dragon or not active_explorations.has(dragon.dragon_id):
		return 0.0

	var exploration = active_explorations[dragon.dragon_id]
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - exploration["start_time"]
	var progress = min(1.0, elapsed / float(exploration["duration"]))
	return progress

func get_time_remaining(dragon: Dragon) -> int:
	"""Get seconds remaining in exploration"""
	if not dragon or not active_explorations.has(dragon.dragon_id):
		return 0

	var exploration = active_explorations[dragon.dragon_id]
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - exploration["start_time"]
	var remaining = max(0, exploration["duration"] - elapsed)
	return int(remaining)

func get_exploration_destination(dragon: Dragon) -> String:
	"""Get the destination name for a dragon's current exploration"""
	if not dragon or not active_explorations.has(dragon.dragon_id):
		return "unknown"

	var exploration = active_explorations[dragon.dragon_id]
	return exploration.get("destination", "unknown")

func get_exploration_duration_minutes(dragon: Dragon) -> int:
	"""Get the original duration in minutes for a dragon's exploration"""
	if not dragon or not active_explorations.has(dragon.dragon_id):
		return 0

	var exploration = active_explorations[dragon.dragon_id]
	return exploration.get("duration_minutes", 0)

# === EXPLORATION UPDATES ===

func _check_explorations():
	"""Check all active explorations for completion"""
	var current_time = Time.get_unix_time_from_system()
	var completed_ids: Array = []

	for dragon_id in active_explorations.keys():
		var exploration = active_explorations[dragon_id]
		var elapsed = current_time - exploration["start_time"]

		if elapsed >= exploration["duration"]:
			completed_ids.append(dragon_id)

	# Complete explorations
	for dragon_id in completed_ids:
		_complete_exploration(dragon_id)

func _complete_exploration(dragon_id: String):
	"""Complete an exploration and grant rewards"""
	if not active_explorations.has(dragon_id):
		return

	var exploration = active_explorations[dragon_id]
	var dragon: Dragon = exploration["dragon"]

	if not dragon:
		active_explorations.erase(dragon_id)
		return

	var duration_minutes = exploration["duration_minutes"]
	var destination = exploration.get("destination", "unknown")

	# Calculate rewards (pass destination for difficulty scaling)
	var rewards = _calculate_rewards(dragon, duration_minutes, destination)

	# Apply pet bonuses if this is a pet dragon
	if dragon is PetDragon and PetDragonManager and PetDragonManager.instance:
		# Apply personality bonuses
		var gold_bonus = dragon.get_personality_bonus("gold")
		rewards["gold"] = int(rewards["gold"] * gold_bonus)

		var parts_bonus = dragon.get_personality_bonus("parts")
		if parts_bonus > 1.0 and randf() < (parts_bonus - 1.0):
			# Curious dragons have chance for extra part
			if not rewards["parts"].is_empty():
				rewards["parts"].append(rewards["parts"].pick_random())

		# Apply affection bonuses (scales all rewards)
		var affection_bonus = dragon.get_affection_bonus()
		rewards["gold"] = int(rewards["gold"] * affection_bonus)
		rewards["xp"] = int(rewards["xp"] * affection_bonus)

		# Notify PetDragonManager about expedition completion
		PetDragonManager.instance.on_pet_expedition_complete(destination, rewards)

		print("[ExplorationManager] Pet bonuses applied: Gold x%.2f, Affection x%.2f" % [gold_bonus, affection_bonus])

	# Apply rewards to vault and inventory
	_apply_rewards(rewards)

	# Apply XP to dragon
	if rewards["xp"] > 0 and DragonStateManager and DragonStateManager.instance:
		DragonStateManager.instance.gain_experience(dragon, rewards["xp"])

	# Apply costs (hunger, fatigue, damage)
	_apply_exploration_costs(dragon, duration_minutes)

	# Return dragon to idle (use proper state setter to update state_start_time)
	if DragonStateManager and DragonStateManager.instance:
		DragonStateManager.instance.set_dragon_state(dragon, Dragon.DragonState.IDLE)
	else:
		dragon.current_state = Dragon.DragonState.IDLE

	# Emit completion signal
	exploration_completed.emit(dragon, destination, rewards)
	active_explorations.erase(dragon_id)

	print("[ExplorationManager] %s returned from exploration!" % dragon.dragon_name)

# === REWARD CALCULATION ===

func _calculate_rewards(dragon: Dragon, duration_minutes: int, destination: String = "unknown") -> Dictionary:
	"""
	Calculate exploration rewards based on duration, dragon level, and destination difficulty.

	Returns a Dictionary with:
	- gold: int
	- xp: int
	- parts: Array[DragonPart.Element]
	- items: Dictionary {"treats": X, "health_pots": Y, ...}
	"""
	var rewards = {
		"gold": 0,
		"xp": 0,
		"parts": [],
		"items": {}
	}

	# Base rewards scale with duration
	var base_gold = BASE_GOLD_PER_MINUTE * duration_minutes
	var base_xp = BASE_XP_PER_MINUTE * duration_minutes

	# Scale with dragon level (higher level = better rewards)
	var level_multiplier = 1.0 + (dragon.level - 1) * 0.15  # +15% per level above 1

	# Scale with destination difficulty
	var difficulty_multiplier = DESTINATION_MULTIPLIERS.get(destination, 1.0)

	# Apply multipliers to base rewards
	var scaled_gold = base_gold * level_multiplier * difficulty_multiplier
	var scaled_xp = base_xp * level_multiplier * difficulty_multiplier

	# Add random variance to gold (±25%)
	var variance = randf_range(1.0 - GOLD_VARIANCE, 1.0 + GOLD_VARIANCE)
	rewards["gold"] = int(scaled_gold * variance)
	rewards["xp"] = int(scaled_xp)  # XP stays consistent

	# Dragon parts drop chance (now returns specific item IDs)
	var parts_count = 0
	match duration_minutes:
		15: parts_count = 1 if randf() < PARTS_DROP_CHANCE else 0
		30: parts_count = 2 if randf() < PARTS_DROP_CHANCE else 1
		60: parts_count = 3 if randf() < PARTS_DROP_CHANCE else 2

	# Select random dragon parts from database
	var possible_parts = ["fire", "ice", "lightning", "nature", "shadow"]
	var part_types = ["head", "body", "tail"]

	for i in parts_count:
		var random_element = possible_parts.pick_random()
		var random_part_type = part_types.pick_random()
		var part_id = "%s_%s" % [random_element, random_part_type]  # e.g. "fire_head"
		rewards["parts"].append(part_id)

	# Item drops (random rolls) - now uses item IDs from database
	var item_id_map = {
		"treats": "treat",
		"health_pots": "health_potion",
		"food": "food",
		"toys": "toy"
	}

	for item_type in ITEM_DROP_CHANCES.keys():
		var drop_chance = ITEM_DROP_CHANCES[item_type]

		# Longer explorations get more rolls
		var num_rolls = 1
		if duration_minutes >= 30:
			num_rolls = 2
		if duration_minutes >= 60:
			num_rolls = 3

		var item_count = 0
		for roll in num_rolls:
			if randf() < drop_chance:
				item_count += 1

		if item_count > 0:
			var item_id = item_id_map[item_type]
			rewards["items"][item_id] = item_count

	return rewards

func _apply_rewards(rewards: Dictionary):
	"""Apply calculated rewards to the inventory and vault"""
	# Add gold to TreasureVault
	if rewards["gold"] > 0 and TreasureVault and TreasureVault.instance:
		TreasureVault.instance.add_gold(rewards["gold"])

	# Add items to InventoryManager
	if not InventoryManager or not InventoryManager.instance:
		print("[ExplorationManager] WARNING: InventoryManager not found!")
		return

	# Add dragon parts (now as specific items)
	for part_id in rewards["parts"]:
		InventoryManager.instance.add_item_by_id(part_id, 1)

	# Add consumable items
	for item_id in rewards["items"]:
		var count = rewards["items"][item_id]
		InventoryManager.instance.add_item_by_id(item_id, count)

# === EXPLORATION COSTS ===

func _apply_exploration_costs(dragon: Dragon, duration_minutes: int):
	"""Apply fatigue, hunger, and potential damage from exploration"""

	# Calculate base fatigue gain
	var base_fatigue = 0.0
	match duration_minutes:
		15: base_fatigue = 0.15
		30: base_fatigue = 0.25
		60: base_fatigue = 0.40

	# Apply fatigue resistance if this is a pet dragon
	var fatigue_multiplier = 1.0
	if dragon is PetDragon:
		fatigue_multiplier = dragon.get_fatigue_resistance()
		print("[ExplorationManager] Pet %s has %.0f%% fatigue resistance (Level %d)" % [
			dragon.dragon_name,
			(1.0 - fatigue_multiplier) * 100,
			dragon.level
		])

	# Apply fatigue with resistance
	var final_fatigue = base_fatigue * fatigue_multiplier
	dragon.fatigue_level = min(1.0, dragon.fatigue_level + final_fatigue)

	# Apply hunger (longer exploration = more hunger)
	var hunger_increase = duration_minutes / 30.0  # 15min=0.5, 30min=1.0, 60min=2.0
	dragon.hunger_level = min(1.0, dragon.hunger_level + (hunger_increase * 0.3))

	# Random damage based on duration
	var damage_chance = DAMAGE_RISK.get(duration_minutes, 0.0)
	if randf() < damage_chance:
		var damage_percent = 0.0
		match duration_minutes:
			15: damage_percent = randf_range(0.10, 0.20)  # 10-20% damage
			30: damage_percent = randf_range(0.15, 0.30)  # 15-30% damage
			60: damage_percent = randf_range(0.20, 0.40)  # 20-40% damage

		var damage = int(dragon.get_health() * damage_percent)
		dragon.current_health = max(0, dragon.current_health - damage)
		print("[ExplorationManager] %s took %d damage during exploration!" % [dragon.dragon_name, damage])

		# Check if dragon died from exploration accident
		if dragon.current_health <= 0 and not dragon.is_dead:
			dragon.is_dead = true
			print("[ExplorationManager] FATAL: %s died during exploration!" % dragon.dragon_name)

			# Trigger part recovery system
			if DragonDeathManager and DragonDeathManager.instance:
				DragonDeathManager.instance.handle_dragon_death(dragon, "exploration_accident")

	# Recalculate stats with new hunger/fatigue
	dragon.calculate_stats()

# === DEBUG / TESTING ===

func force_complete_exploration(dragon: Dragon):
	"""Debug: Instantly complete an exploration"""
	if not dragon or not active_explorations.has(dragon.dragon_id):
		print("[ExplorationManager] Dragon is not exploring")
		return

	_complete_exploration(dragon.dragon_id)
	print("[ExplorationManager] DEBUG: Forced completion of %s's exploration" % dragon.dragon_name)

func get_active_explorations_count() -> int:
	"""Get number of dragons currently exploring"""
	return active_explorations.size()

func get_active_explorations() -> Array:
	"""Get list of all active explorations for map visualization"""
	var explorations: Array = []
	for dragon_id in active_explorations.keys():
		var exploration = active_explorations[dragon_id]
		explorations.append({
			"dragon": exploration["dragon"],
			"destination": exploration.get("destination", "unknown"),
			"start_time": exploration["start_time"],
			"duration": exploration["duration"],
			"duration_minutes": exploration["duration_minutes"]
		})
	return explorations

func print_exploration_status():
	"""Debug: Print all active explorations"""
	print("\n=== EXPLORATION STATUS ===")
	print("DEV_MODE: %s" % ("ENABLED (using seconds)" if DEV_MODE else "DISABLED (using minutes)"))
	print("Active Explorations: %d" % active_explorations.size())

	for dragon_id in active_explorations:
		var exploration = active_explorations[dragon_id]
		var dragon: Dragon = exploration["dragon"]
		var remaining = get_time_remaining(dragon)
		var progress = get_exploration_progress(dragon)

		print("  - %s: %d%% complete (%d seconds remaining)" % [
			dragon.dragon_name,
			int(progress * 100),
			remaining
		])
	print("==========================\n")

func complete_all_explorations():
	"""Debug: Instantly complete ALL active explorations"""
	var count = active_explorations.size()
	var dragon_ids = active_explorations.keys().duplicate()

	for dragon_id in dragon_ids:
		_complete_exploration(dragon_id)

	print("[ExplorationManager] DEBUG: Force-completed %d explorations" % count)

func get_dev_mode_info() -> String:
	"""Returns info about DEV_MODE status"""
	if DEV_MODE:
		return "DEV MODE ENABLED - Explorations use SECONDS instead of minutes (15s/30s/60s)"
	else:
		return "Production Mode - Explorations use real time (15min/30min/60min)"

# === SAVE/LOAD SERIALIZATION ===

func to_dict() -> Dictionary:
	"""Serialize active explorations to a dictionary for saving"""
	var data = {
		"active_explorations": []
	}

	for dragon_id in active_explorations.keys():
		var exploration = active_explorations[dragon_id]
		data["active_explorations"].append({
			"dragon_id": dragon_id,
			"start_time": exploration["start_time"],
			"duration": exploration["duration"],
			"duration_minutes": exploration["duration_minutes"],
			"destination": exploration.get("destination", "unknown")
		})

	return data

func from_dict(data: Dictionary, dragon_factory: DragonFactory):
	"""Restore active explorations from saved data"""
	if not data.has("active_explorations"):
		return

	active_explorations.clear()

	for exploration_data in data["active_explorations"]:
		var dragon_id = exploration_data["dragon_id"]
		var dragon = dragon_factory.get_dragon_by_id(dragon_id)

		if not dragon:
			print("[ExplorationManager] WARNING: Could not find dragon %s for exploration" % dragon_id)
			continue

		# Restore exploration data
		active_explorations[dragon_id] = {
			"start_time": exploration_data["start_time"],
			"duration": exploration_data["duration"],
			"duration_minutes": exploration_data["duration_minutes"],
			"destination": exploration_data.get("destination", "unknown"),
			"dragon": dragon
		}

		# Restore dragon's exploration state
		dragon.exploration_start_time = exploration_data["start_time"]
		dragon.exploration_duration = exploration_data["duration"]

		print("[ExplorationManager] Restored exploration for %s" % dragon.dragon_name)
