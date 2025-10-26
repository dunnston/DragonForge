extends Node

# Singleton instance
static var instance

# Constants
const AUTO_EXPLORE_CHECK_INTERVAL: float = 10.0  # seconds
const AUTO_EXPLORE_HUNGER_THRESHOLD: float = 0.7  # Don't explore if > 70% hungry
const AUTO_EXPLORE_DURATION: int = 1  # Always use 1-min explorations (TESTING - change back to 15 later!)

const EMERGENCY_GOLD: int = 500
const EMERGENCY_PARTS: int = 3
const EMERGENCY_COOLDOWN: int = 3600  # 1 hour

const MAX_OFFLINE_TIME: int = 86400  # 24 hours max

# Gift System Constants
const GIFT_CHECK_MIN_INTERVAL: float = 120.0  # 2 minutes
const GIFT_CHECK_MAX_INTERVAL: float = 300.0  # 5 minutes
const GIFT_TRIGGER_CHANCE: float = 0.15  # 15% chance when check happens
const GIFT_COOLDOWN: float = 600.0  # 10 minutes minimum between gifts
const GIFT_MESSAGES_PATH: String = "res://docs/gift_messages.md"

# Exploration Destinations (matching ExplorationManager destinations)
const EXPLORATION_DESTINATIONS = {
	"volcanic_caves": {"min_level": 1, "danger": "low"},
	"ancient_forest": {"min_level": 3, "danger": "medium"},
	"frozen_tundra": {"min_level": 5, "danger": "medium"},
	"shadow_realm": {"min_level": 7, "danger": "high"},
	"crystal_peaks": {"min_level": 10, "danger": "high"}
}

# Properties
var pet_dragon: PetDragon = null
var last_pet_time: int = 0
var auto_explore_enabled: bool = false  # Disabled by default - pet stays visible
var last_emergency_time: int = 0

# Gift System Properties
var gift_messages: Array[String] = []
var last_gift_time: float = 0.0
var next_gift_check_time: float = 0.0

# Timers
var auto_explore_timer: Timer
var update_timer: Timer
var gift_timer: Timer

# Signals
signal pet_created(pet: PetDragon)
signal pet_auto_exploring(pet: PetDragon, destination: String)
signal pet_returned(pet: PetDragon, rewards: Dictionary)
signal emergency_rescue_triggered(rewards: Dictionary)
signal gift_received(message: String)

func _ready():
	if instance != null:
		push_warning("[PetDragonManager] Instance already exists!")
		queue_free()
		return

	instance = self

	# Load gift messages
	_load_gift_messages()

	# Setup auto-explore timer
	auto_explore_timer = Timer.new()
	auto_explore_timer.wait_time = AUTO_EXPLORE_CHECK_INTERVAL
	auto_explore_timer.timeout.connect(_check_auto_exploration)
	add_child(auto_explore_timer)
	auto_explore_timer.start()

	# Setup update timer (every second for UI updates)
	update_timer = Timer.new()
	update_timer.wait_time = 1.0
	update_timer.timeout.connect(_update_pet)
	add_child(update_timer)
	update_timer.start()

	# Setup gift timer with randomized interval
	gift_timer = Timer.new()
	gift_timer.one_shot = true
	gift_timer.timeout.connect(_check_gift_trigger)
	add_child(gift_timer)
	_schedule_next_gift_check()

	print("[PetDragonManager] ✓ Initialized (Loaded %d gift messages)" % gift_messages.size())

# === PET CREATION ===

func create_pet_dragon(head: DragonPart, body: DragonPart, tail: DragonPart) -> PetDragon:
	"""Create the player's pet dragon with random personality"""
	if pet_dragon != null:
		push_warning("[PetDragonManager] Pet dragon already exists!")
		return pet_dragon

	# Create pet with random personality
	pet_dragon = PetDragon.new(head, body, tail)
	pet_dragon.dragon_name = "Unnamed Pet"  # Will be named by player

	# Add first memorable moment
	pet_dragon.add_memorable_moment(
		"First Meeting",
		"The day we met and began our journey together."
	)

	print("[PetDragonManager] ✓ Created pet dragon: %s (Personality: %s)" % [
		pet_dragon.dragon_name,
		pet_dragon.get_personality_name()
	])

	pet_created.emit(pet_dragon)
	return pet_dragon

func set_pet_name(new_name: String) -> void:
	"""Set the pet dragon's name"""
	if pet_dragon:
		pet_dragon.dragon_name = new_name
		print("[PetDragonManager] Pet named: %s" % new_name)

# === AUTO-EXPLORATION ===

func _check_auto_exploration() -> void:
	"""Check if pet should auto-explore (called every 10 seconds)"""
	if not auto_explore_enabled or not pet_dragon:
		return

	if can_auto_explore():
		start_auto_exploration()

func can_auto_explore() -> bool:
	"""Check if pet dragon can automatically start exploring"""
	if not pet_dragon or pet_dragon.is_dead:
		return false

	# Don't auto-explore if already exploring
	if is_pet_exploring():
		return false

	# Don't auto-explore if not IDLE
	if pet_dragon.current_state != Dragon.DragonState.IDLE:
		return false

	# Don't auto-explore if too hungry
	if pet_dragon.hunger_level > AUTO_EXPLORE_HUNGER_THRESHOLD:
		return false

	# Don't auto-explore if too tired
	if pet_dragon.fatigue_level > 0.8:
		return false

	return true

func start_auto_exploration() -> void:
	"""Start automatic exploration based on personality"""
	if not pet_dragon:
		return

	var destination = _choose_destination_by_personality()

	# Use ExplorationManager if available
	if ExplorationManager and ExplorationManager.instance:
		var success = ExplorationManager.instance.start_exploration(
			pet_dragon,
			AUTO_EXPLORE_DURATION,
			destination
		)

		if success:
			print("[PetDragonManager] Auto-exploring: %s for %d min (Personality: %s)" % [
				destination,
				AUTO_EXPLORE_DURATION,
				pet_dragon.get_personality_name()
			])
			pet_auto_exploring.emit(pet_dragon, destination)
	else:
		push_warning("[PetDragonManager] ExplorationManager not available!")

func _choose_destination_by_personality() -> String:
	"""Choose exploration destination based on pet's personality"""
	if not pet_dragon:
		return "volcanic_caves"

	match pet_dragon.personality:
		PetDragon.Personality.CURIOUS:
			# Random destination
			return EXPLORATION_DESTINATIONS.keys().pick_random()

		PetDragon.Personality.BRAVE:
			# Dangerous locations (high level)
			var dangerous = []
			for dest in EXPLORATION_DESTINATIONS:
				if EXPLORATION_DESTINATIONS[dest]["danger"] == "high":
					dangerous.append(dest)
			return dangerous.pick_random() if not dangerous.is_empty() else "volcanic_caves"

		PetDragon.Personality.LAZY, PetDragon.Personality.ENERGETIC:
			# Short trips (low level)
			return "volcanic_caves"

		PetDragon.Personality.GREEDY:
			# Gold-rich location
			return "ancient_forest"

		PetDragon.Personality.GENTLE:
			# Safe + parts location
			return "frozen_tundra"

	return "volcanic_caves"

func is_pet_exploring() -> bool:
	"""Check if pet is currently exploring"""
	if not pet_dragon:
		return false

	return pet_dragon.current_state == Dragon.DragonState.EXPLORING

# === OFFLINE PROGRESS ===

func calculate_offline_progress(seconds_offline: int) -> Dictionary:
	"""Calculate what the pet accomplished while player was offline"""
	if not pet_dragon:
		return {}

	# Cap offline time to prevent exploitation
	var capped_offline = min(seconds_offline, MAX_OFFLINE_TIME)

	# Calculate base exploration duration (15 min = 900 seconds)
	var base_duration = AUTO_EXPLORE_DURATION * 60
	var time_modifier = pet_dragon.get_exploration_time_modifier()
	var actual_duration = base_duration * time_modifier

	# Calculate how many explorations completed
	var num_expeditions = int(capped_offline / actual_duration)

	# Calculate rewards
	var total_gold = 0
	var total_xp = 0
	var total_parts = 0
	var levels_gained = 0
	var gifts_found = 0

	for i in num_expeditions:
		# Simulate exploration rewards (simplified)
		var base_gold = 20 * AUTO_EXPLORE_DURATION
		var base_xp = 0.5 * AUTO_EXPLORE_DURATION  # Reduced from 30 to 0.5 for much slower leveling

		# Apply personality bonuses
		base_gold *= pet_dragon.get_personality_bonus("gold")
		var parts_count = 1

		# Apply affection bonus
		base_gold *= pet_dragon.get_affection_bonus()
		base_xp *= pet_dragon.get_affection_bonus()

		total_gold += int(base_gold)
		total_xp += int(base_xp)
		total_parts += parts_count

		# Chance for gifts
		if randf() < 0.2:
			gifts_found += 1

	# Simulate level-ups
	var starting_level = pet_dragon.level
	pet_dragon.gain_experience(total_xp)
	levels_gained = pet_dragon.level - starting_level

	# Update pet statistics
	pet_dragon.expeditions_completed += num_expeditions
	pet_dragon.total_gold_earned += total_gold
	pet_dragon.total_parts_found += total_parts

	# Add memorable moment if significant offline time
	if num_expeditions >= 10:
		pet_dragon.add_memorable_moment(
			"Worked While You Were Away",
			"Completed %d expeditions during your absence!" % num_expeditions
		)

	print("[PetDragonManager] Offline progress: %d expeditions, %d gold, %d XP, %d levels" % [
		num_expeditions,
		total_gold,
		total_xp,
		levels_gained
	])

	return {
		"num_expeditions": num_expeditions,
		"gold": total_gold,
		"xp": total_xp,
		"parts": total_parts,
		"levels_gained": levels_gained,
		"gifts_found": gifts_found
	}

# === EMERGENCY RESCUE ===

func generate_emergency_rewards() -> Dictionary:
	"""Generate emergency rewards when player is stuck"""
	var current_time = Time.get_unix_time_from_system()

	# Check cooldown
	if (current_time - last_emergency_time) < EMERGENCY_COOLDOWN:
		push_warning("[PetDragonManager] Emergency rescue on cooldown!")
		return {}

	last_emergency_time = current_time

	# Generate random parts
	var parts = []
	for i in EMERGENCY_PARTS:
		parts.append(DragonPart.Element.values().pick_random())

	# Add memorable moment
	if pet_dragon:
		pet_dragon.add_memorable_moment(
			"Emergency Rescue",
			"Sensed you were in trouble and rushed back with supplies!"
		)

	print("[PetDragonManager] Emergency rescue triggered! Gold: %d, Parts: %d" % [
		EMERGENCY_GOLD,
		EMERGENCY_PARTS
	])

	emergency_rescue_triggered.emit({
		"gold": EMERGENCY_GOLD,
		"parts": parts
	})

	return {
		"gold": EMERGENCY_GOLD,
		"parts": parts
	}

# === GIFT SYSTEM ===

func _load_gift_messages() -> void:
	"""Load gift messages from markdown file"""
	gift_messages.clear()

	if not FileAccess.file_exists(GIFT_MESSAGES_PATH):
		push_error("[PetDragonManager] Gift messages file not found: %s" % GIFT_MESSAGES_PATH)
		return

	var file = FileAccess.open(GIFT_MESSAGES_PATH, FileAccess.READ)
	if not file:
		push_error("[PetDragonManager] Failed to open gift messages file!")
		return

	var content = file.get_as_text()
	file.close()

	# Split by lines and filter out empty lines
	var lines = content.split("\n")
	for line in lines:
		var trimmed = line.strip_edges()
		if trimmed.length() > 0:
			gift_messages.append(trimmed)

	print("[PetDragonManager] Loaded %d gift messages" % gift_messages.size())

func _schedule_next_gift_check() -> void:
	"""Schedule the next gift check with randomized interval"""
	var interval = randf_range(GIFT_CHECK_MIN_INTERVAL, GIFT_CHECK_MAX_INTERVAL)
	gift_timer.start(interval)
	next_gift_check_time = Time.get_ticks_msec() / 1000.0 + interval

func _check_gift_trigger() -> void:
	"""Check if gift should be triggered (called by timer)"""
	# Schedule next check regardless
	_schedule_next_gift_check()

	# Check if we can give gift
	if not can_give_gift():
		return

	# Random chance to trigger
	if randf() < GIFT_TRIGGER_CHANCE:
		trigger_gift()

func can_give_gift() -> bool:
	"""Check if conditions are met for giving a gift"""
	if not pet_dragon or pet_dragon.is_dead:
		return false

	# Check cooldown
	var current_time = Time.get_ticks_msec() / 1000.0
	if (current_time - last_gift_time) < GIFT_COOLDOWN:
		return false

	# Only give gifts when pet is idle or resting (not exploring)
	if pet_dragon.current_state != Dragon.DragonState.IDLE and pet_dragon.current_state != Dragon.DragonState.RESTING:
		return false

	return true

func trigger_gift(force: bool = false) -> void:
	"""Trigger a gift from the pet (force bypasses checks for debug)"""
	if not force and not can_give_gift():
		return

	if gift_messages.is_empty():
		push_warning("[PetDragonManager] No gift messages loaded!")
		return

	# Get random gift message
	var message = gift_messages.pick_random()

	# Update last gift time
	last_gift_time = Time.get_ticks_msec() / 1000.0

	print("[PetDragonManager] 🎁 Pet gave a gift! Message: '%s'" % message)

	# Emit signal for popup to display
	gift_received.emit(message)

# === EXPLORATION INTEGRATION ===

func on_pet_expedition_complete(destination: String, rewards: Dictionary) -> void:
	"""Called when pet completes an exploration (from ExplorationManager)"""
	if not pet_dragon:
		return

	# Track expedition in pet
	pet_dragon.complete_expedition(
		destination,
		rewards.get("gold", 0),
		rewards.get("parts", []).size(),
		AUTO_EXPLORE_DURATION
	)

	print("[PetDragonManager] Pet completed exploration at %s: %d gold, %d parts" % [
		destination,
		rewards.get("gold", 0),
		rewards.get("parts", []).size()
	])

	pet_returned.emit(pet_dragon, rewards)

# === UPDATE ===

func _update_pet() -> void:
	"""Update pet dragon every second"""
	if pet_dragon:
		pet_dragon.update_life_systems()
		pet_dragon.update_days_together()

# === SAVE/LOAD ===

func to_dict() -> Dictionary:
	"""Serialize PetDragonManager for saving"""
	var data = {
		"has_pet": pet_dragon != null,
		"last_pet_time": last_pet_time,
		"auto_explore_enabled": auto_explore_enabled,
		"last_emergency_time": last_emergency_time
	}

	# Save pet dragon data if exists
	if pet_dragon:
		data["pet_dragon"] = pet_dragon.to_dict()

	return data

func from_dict(data: Dictionary) -> void:
	"""Restore PetDragonManager from saved data"""
	last_pet_time = data.get("last_pet_time", 0)
	auto_explore_enabled = data.get("auto_explore_enabled", true)
	last_emergency_time = data.get("last_emergency_time", 0)

	# Note: pet_dragon is restored by DragonFactory.from_dict()
	# We only need to restore manager-specific state here
	# The pet will already be set by DragonFactory when it loads the dragon with is_pet=true

	if pet_dragon:
		print("[PetDragonManager] ✓ Pet dragon already restored by DragonFactory: %s (Level %d, Affection %d)" % [
			pet_dragon.dragon_name,
			pet_dragon.level,
			pet_dragon.affection
		])
	else:
		# Fallback: If DragonFactory didn't restore the pet (shouldn't happen)
		if data.get("has_pet", false) and data.has("pet_dragon"):
			push_warning("[PetDragonManager] DragonFactory didn't restore pet, loading manually...")
			pet_dragon = PetDragon.new()
			pet_dragon.from_dict(data["pet_dragon"])

			print("[PetDragonManager] ✓ Loaded pet dragon: %s (Level %d, Affection %d)" % [
				pet_dragon.dragon_name,
				pet_dragon.level,
				pet_dragon.affection
			])

# === UTILITY ===

func get_pet_dragon() -> PetDragon:
	"""Get the pet dragon instance"""
	return pet_dragon

func has_pet() -> bool:
	"""Check if player has a pet dragon"""
	return pet_dragon != null
