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
signal exploration_started(dragon: Dragon, duration_minutes: int)
signal exploration_completed(dragon: Dragon, rewards: Dictionary)
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

func start_exploration(dragon: Dragon, duration_minutes: int) -> bool:
	"""
	Send a dragon on an exploration mission.

	Args:
		dragon: The dragon to send exploring
		duration_minutes: How long to explore (15, 30, or 60)

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

	if dragon.current_state != Dragon.DragonState.IDLE:
		exploration_failed.emit(dragon, "Dragon is not idle")
		return false

	# Check if dragon is too fatigued
	if dragon.fatigue_level > 0.8:
		exploration_failed.emit(dragon, "Dragon is too fatigued to explore")
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

	var current_time = Time.get_unix_time_from_system()

	# Set dragon state
	dragon.current_state = Dragon.DragonState.EXPLORING
	dragon.exploration_start_time = current_time
	dragon.exploration_duration = duration_seconds

	# Track exploration
	active_explorations[dragon.dragon_id] = {
		"start_time": current_time,
		"duration": duration_seconds,
		"duration_minutes": duration_minutes,
		"dragon": dragon
	}

	exploration_started.emit(dragon, duration_minutes)
	var time_unit = "seconds" if DEV_MODE else "minutes"
	print("[ExplorationManager] %s started exploring for %d %s" % [dragon.dragon_name, duration_minutes, time_unit])
	return true

func cancel_exploration(dragon: Dragon) -> bool:
	"""Cancel an active exploration early (no rewards)"""
	if not dragon or not active_explorations.has(dragon.dragon_id):
		return false

	active_explorations.erase(dragon.dragon_id)
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

	# Calculate rewards
	var rewards = _calculate_rewards(dragon, duration_minutes)

	# Apply rewards to vault and inventory
	_apply_rewards(rewards)

	# Apply XP to dragon
	if rewards["xp"] > 0 and DragonStateManager and DragonStateManager.instance:
		DragonStateManager.instance.gain_experience(dragon, rewards["xp"])

	# Apply costs (hunger, fatigue, damage)
	_apply_exploration_costs(dragon, duration_minutes)

	# Return dragon to idle
	dragon.current_state = Dragon.DragonState.IDLE

	# Emit completion signal
	exploration_completed.emit(dragon, rewards)
	active_explorations.erase(dragon_id)

	print("[ExplorationManager] %s returned from exploration!" % dragon.dragon_name)

# === REWARD CALCULATION ===

func _calculate_rewards(dragon: Dragon, duration_minutes: int) -> Dictionary:
	"""
	Calculate exploration rewards based on duration and dragon level.

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

	rewards["gold"] = int(base_gold * level_multiplier)
	rewards["xp"] = int(base_xp * level_multiplier)

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

	# Apply fatigue (from Dragon.EXPLORATION_FATIGUE constants)
	match duration_minutes:
		15: dragon.fatigue_level = min(1.0, dragon.fatigue_level + 0.15)
		30: dragon.fatigue_level = min(1.0, dragon.fatigue_level + 0.25)
		60: dragon.fatigue_level = min(1.0, dragon.fatigue_level + 0.40)

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
