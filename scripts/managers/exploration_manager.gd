# Exploration Manager - Handle dragon exploration missions
# Dragons can explore for 15/30/60 minutes and return with loot
extends Node

# === SINGLETON ===
static var instance: ExplorationManager

# === EXPLORATION TRACKING ===
var active_explorations: Dictionary = {}  # {dragon_id: exploration_data}

# === ENERGY TONIC TRACKING ===
var energy_tonic_active: bool = false
var energy_tonic_end_time: float = 0.0

# === EXPLORATION DURATIONS (in seconds) ===
const DURATION_VERY_SHORT: int = 60   # 1 minute (Volcanic Caves)
const DURATION_SHORT: int = 300       # 5 minutes (Ancient Forest)
const DURATION_MEDIUM: int = 600      # 10 minutes (Frozen Tundra)
const DURATION_LONG: int = 900        # 15 minutes (Thunder Peak)

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

# Damage chances are now handled inline in _apply_exploration_costs()

# === SIGNALS ===
signal exploration_started(dragon: Dragon, destination: String)
signal exploration_completed(dragon: Dragon, destination: String, rewards: Dictionary)
signal exploration_failed(dragon: Dragon, reason: String)
signal energy_tonic_activated(duration: float)
signal energy_tonic_expired()

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	print("[ExplorationManager] Initialized - Exploration durations: 1/5/10/15 minutes")

	# Check explorations every 10 seconds
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.timeout.connect(_check_explorations)
	add_child(timer)
	timer.start()

	# Check energy tonic expiration every second
	var tonic_timer = Timer.new()
	tonic_timer.wait_time = 1.0
	tonic_timer.timeout.connect(_check_energy_tonic)
	add_child(tonic_timer)
	tonic_timer.start()

# === EXPLORATION MANAGEMENT ===

func start_exploration(dragon: Dragon, duration_minutes: int, destination: String = "unknown") -> bool:
	"""
	Send a dragon on an exploration mission.

	Args:
		dragon: The dragon to send exploring
		duration_minutes: How long to explore (5, 10, 15, or 20)
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
		if AudioManager and AudioManager.instance:
			AudioManager.instance.play_error()
		return false

	# Allow exploration from IDLE, RESTING, TRAINING, and DEFENDING states
	# But not from EXPLORING (can't explore twice) or DEAD
	if dragon.current_state == Dragon.DragonState.EXPLORING:
		exploration_failed.emit(dragon, "Dragon is already exploring")
		if AudioManager and AudioManager.instance:
			AudioManager.instance.play_error()
		return false

	# Check if dragon is too fatigued (must be at least 50% rested)
	if dragon.fatigue_level > 0.5:
		exploration_failed.emit(dragon, "Dragon is too fatigued to explore (needs 50% rest)")
		if AudioManager and AudioManager.instance:
			AudioManager.instance.play_error()
		return false

	# Validate duration
	if duration_minutes not in [1, 5, 10, 15]:
		print("[ExplorationManager] ERROR: Invalid duration %d (must be 1, 5, 10, or 15)" % duration_minutes)
		return false

	# Calculate duration in seconds
	var duration_seconds = duration_minutes * 60

	# Apply energy tonic speed boost if active
	if energy_tonic_active:
		duration_seconds = int(duration_seconds / 4.0)  # 4x faster = quarter the time
		print("[ExplorationManager] Energy Tonic active! Exploration time reduced to 25%!")

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

	# Play dragon exploring sound
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_dragon_exploring()

	print("[ExplorationManager] %s started exploring for %d minutes" % [dragon.dragon_name, duration_minutes])
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

# === ENERGY TONIC ===

func consume_energy_tonic() -> bool:
	"""
	Consume an energy tonic to boost all dragon exploration speed by 4x for 2 minutes.
	Affects both new explorations and dragons already exploring!
	Returns true if successful, false if no tonics available or already active.
	"""
	# Check if already active
	if energy_tonic_active:
		print("[ExplorationManager] Energy Tonic already active! Wait for it to expire.")
		return false

	# Check if player has energy tonics
	if not InventoryManager or not InventoryManager.instance:
		print("[ExplorationManager] ERROR: InventoryManager not found!")
		return false

	# Try to consume one energy tonic
	if not InventoryManager.instance.has_item("energy_tonic", 1):
		print("[ExplorationManager] No Energy Tonics available!")
		return false

	if not InventoryManager.instance.remove_item_by_id("energy_tonic", 1):
		print("[ExplorationManager] Failed to consume Energy Tonic!")
		return false

	# Activate the tonic
	energy_tonic_active = true
	energy_tonic_end_time = Time.get_unix_time_from_system() + 120.0  # 2 minutes

	# Apply speed boost to all currently active explorations
	_apply_tonic_to_active_explorations()

	energy_tonic_activated.emit(120.0)
	print("[ExplorationManager] Energy Tonic activated! All dragons explore 4x faster for 2 minutes!")
	return true

func _apply_tonic_to_active_explorations():
	"""Apply 4x speed boost to all dragons currently exploring"""
	var current_time = Time.get_unix_time_from_system()
	var boosted_count = 0

	for dragon_id in active_explorations.keys():
		var exploration = active_explorations[dragon_id]
		var start_time = exploration["start_time"]
		var duration = exploration["duration"]

		# Calculate elapsed and remaining time
		var elapsed = current_time - start_time
		var remaining = duration - elapsed

		if remaining > 0:
			# Speed up remaining time by 4x (divide by 4)
			var new_remaining = remaining / 4.0

			# Adjust start_time so exploration ends at: current_time + new_remaining
			# Formula: new_start_time = current_time + new_remaining - duration
			var new_start_time = current_time + new_remaining - duration

			exploration["start_time"] = new_start_time
			boosted_count += 1

			var dragon: Dragon = exploration.get("dragon")
			if dragon:
				print("[ExplorationManager] Boosted %s - remaining time: %.0fs → %.0fs" % [
					dragon.dragon_name,
					remaining,
					new_remaining
				])

	if boosted_count > 0:
		print("[ExplorationManager] Applied tonic boost to %d active exploration(s)" % boosted_count)

func _check_energy_tonic():
	"""Check if energy tonic has expired"""
	if not energy_tonic_active:
		return

	var current_time = Time.get_unix_time_from_system()
	if current_time >= energy_tonic_end_time:
		energy_tonic_active = false
		energy_tonic_expired.emit()
		print("[ExplorationManager] Energy Tonic expired!")

func is_energy_tonic_active() -> bool:
	"""Check if energy tonic is currently active"""
	return energy_tonic_active

func get_energy_tonic_time_remaining() -> float:
	"""Get seconds remaining on energy tonic effect"""
	if not energy_tonic_active:
		return 0.0

	var current_time = Time.get_unix_time_from_system()
	return max(0.0, energy_tonic_end_time - current_time)

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

	# Play notification sound when exploration completes
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_notification()

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
	# Guaranteed parts until first wave completes, then use chance-based system
	var first_wave_done = false
	if DefenseManager and DefenseManager.instance:
		first_wave_done = DefenseManager.instance.first_wave_completed

	var parts_count = 0
	match duration_minutes:
		1:
			if first_wave_done:
				parts_count = 1 if randf() < PARTS_DROP_CHANCE else 0  # 30% chance after first wave
			else:
				parts_count = 1  # Guaranteed until first wave
		5:
			if first_wave_done:
				parts_count = 1 if randf() < PARTS_DROP_CHANCE else 0  # 30% chance after first wave
			else:
				parts_count = 1  # Guaranteed until first wave
		10:
			if first_wave_done:
				parts_count = 1 if randf() < PARTS_DROP_CHANCE else 0  # 30% chance after first wave
			else:
				parts_count = 1  # Guaranteed until first wave
		15: parts_count = 2 if randf() < PARTS_DROP_CHANCE else 1

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
		if duration_minutes >= 5:
			num_rolls = 2
		if duration_minutes >= 10:
			num_rolls = 3
		if duration_minutes >= 15:
			num_rolls = 4

		var item_count = 0
		for roll in num_rolls:
			if randf() < drop_chance:
				item_count += 1

		if item_count > 0:
			var item_id = item_id_map[item_type]
			rewards["items"][item_id] = item_count

	# Energy Tonic drops (only from higher tier areas: Frozen Tundra 10min, Thunder Peak 15min)
	if duration_minutes >= 10:
		var tonic_chance = 0.15  # 15% base chance for 10min
		if duration_minutes >= 15:
			tonic_chance = 0.25  # 25% chance for 15min

		if randf() < tonic_chance:
			rewards["items"]["energy_tonic"] = 1
			print("[ExplorationManager] Energy Tonic dropped! (%.0f%% chance)" % (tonic_chance * 100))

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
		1: base_fatigue = 0.05
		5: base_fatigue = 0.10
		10: base_fatigue = 0.15
		15: base_fatigue = 0.25

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
	var hunger_increase = duration_minutes / 15.0  # 1min=0.067, 5min=0.33, 10min=0.67, 15min=1.0
	dragon.hunger_level = min(1.0, dragon.hunger_level + (hunger_increase * 0.3))

	# Random damage based on duration
	var damage_chance = 0.0
	match duration_minutes:
		1: damage_chance = 0.02   # 2% chance
		5: damage_chance = 0.05   # 5% chance
		10: damage_chance = 0.10  # 10% chance
		15: damage_chance = 0.20  # 20% chance

	if randf() < damage_chance:
		var damage_percent = 0.0
		match duration_minutes:
			1: damage_percent = randf_range(0.02, 0.05)  # 2-5% damage
			5: damage_percent = randf_range(0.05, 0.10)  # 5-10% damage
			10: damage_percent = randf_range(0.10, 0.15)  # 10-15% damage
			15: damage_percent = randf_range(0.15, 0.25)  # 15-25% damage

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

# === SAVE/LOAD SERIALIZATION ===

func to_dict() -> Dictionary:
	"""Serialize active explorations to a dictionary for saving"""
	var data = {
		"active_explorations": [],
		"energy_tonic_active": energy_tonic_active,
		"energy_tonic_end_time": energy_tonic_end_time
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

	# Restore energy tonic state
	energy_tonic_active = data.get("energy_tonic_active", false)
	energy_tonic_end_time = data.get("energy_tonic_end_time", 0.0)

	# Check if saved tonic has expired
	if energy_tonic_active:
		var current_time = Time.get_unix_time_from_system()
		if current_time >= energy_tonic_end_time:
			energy_tonic_active = false
			print("[ExplorationManager] Loaded energy tonic had expired")

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
