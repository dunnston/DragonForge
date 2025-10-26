extends Dragon
class_name PetDragon

# Personality Types
enum Personality { CURIOUS, BRAVE, LAZY, ENERGETIC, GREEDY, GENTLE }

# Affection Constants
const AFFECTION_TIERS = {
	"Acquaintance": {"min": 0, "max": 19, "bonus": 1.0},
	"Friend": {"min": 20, "max": 39, "bonus": 1.05},
	"Companion": {"min": 40, "max": 59, "bonus": 1.10},
	"Best Friend": {"min": 60, "max": 79, "bonus": 1.15},
	"Soulbound": {"min": 80, "max": 100, "bonus": 1.25}
}

const PET_COOLDOWN: int = 3600  # 1 hour in seconds
const FEED_AFFECTION: int = 2
const PET_AFFECTION: int = 5
const GIFT_AFFECTION: int = 5
const EXPEDITION_AFFECTION: int = 1

# Personality Dialogue
const PERSONALITY_DIALOGUE = {
	Personality.CURIOUS: [
		"What's that over there?",
		"I wonder what we'll find today!",
		"Let's explore somewhere new!",
		"Did you know...? Actually, I don't know either!",
		"*sniffs curiously*"
	],
	Personality.BRAVE: [
		"I'm ready for anything!",
		"Let's face the danger together!",
		"Nothing can stop us!",
		"I'll protect you!",
		"*stands tall and proud*"
	],
	Personality.LAZY: [
		"Can we rest a bit longer?",
		"*yawns* Five more minutes...",
		"Do we have to go now?",
		"I'm comfortable right here.",
		"*stretches lazily*"
	],
	Personality.ENERGETIC: [
		"Let's go! Let's go! Let's go!",
		"I can't sit still!",
		"What's next? What's next?",
		"*bounces excitedly*",
		"I have so much energy!"
	],
	Personality.GREEDY: [
		"Ooh, shiny!",
		"Is that gold? I love gold!",
		"Let's find more treasure!",
		"Mine! All mine!",
		"*eyes sparkle at the sight of gold*"
	],
	Personality.GENTLE: [
		"I'm happy when you're happy.",
		"Let's stay safe today.",
		"*nuzzles affectionately*",
		"I care about you.",
		"Take care of yourself."
	]
}

# Export Properties (saved)
@export var personality: Personality = Personality.CURIOUS
@export var affection: int = 0
@export var last_pet_time: int = 0
@export var last_affection_decay_check: int = 0
@export var affection_trend: int = 0  # -1 = decreasing, 0 = stable, 1 = increasing

# Statistics Tracking
@export var times_fed: int = 0
@export var times_petted: int = 0
@export var times_gifted: int = 0
@export var expeditions_completed: int = 0
@export var total_gold_earned: int = 0
@export var total_parts_found: int = 0
@export var days_together: int = 0
@export var favorite_destination: String = ""

# Memory System
@export var memorable_moments: Array = []  # [{title: String, description: String, timestamp: int}]

# Gift System
@export var pending_gifts: Array = []  # Items to show player

# Signals
signal affection_changed(pet: PetDragon, new_affection: int, tier: String)
signal personality_action(pet: PetDragon, action: String)
signal memorable_moment_added(pet: PetDragon, title: String)
signal gift_received(pet: PetDragon, gift: Dictionary)

func _init(head: DragonPart = null, body: DragonPart = null, tail: DragonPart = null, p_personality: Personality = -1):
	super._init(head, body, tail)

	# Assign random personality if not specified
	if p_personality == -1:
		personality = Personality.values().pick_random()
	else:
		personality = p_personality

	# Initialize pet-specific timestamps
	last_pet_time = Time.get_unix_time_from_system()
	last_affection_decay_check = Time.get_unix_time_from_system()

	# Pet dragons start at affection level 1 (Acquaintance tier)
	affection = 1
	affection_trend = 0

# === AFFECTION SYSTEM ===

func get_affection_tier() -> String:
	"""Returns the current affection tier name"""
	for tier_name in AFFECTION_TIERS:
		var tier = AFFECTION_TIERS[tier_name]
		if affection >= tier["min"] and affection <= tier["max"]:
			return tier_name
	return "Acquaintance"

func get_affection_bonus() -> float:
	"""Returns the multiplier bonus for current affection tier (1.0 to 1.25)"""
	var tier_name = get_affection_tier()
	return AFFECTION_TIERS[tier_name]["bonus"]

func add_affection(amount: int) -> void:
	"""Add affection points and emit signal if tier changes"""
	var old_tier = get_affection_tier()
	var old_affection = affection
	affection = clamp(affection + amount, 0, 100)
	var new_tier = get_affection_tier()

	# Update affection trend
	if amount > 0:
		affection_trend = 1  # Increasing
	elif amount < 0:
		affection_trend = -1  # Decreasing
	else:
		affection_trend = 0  # Stable

	affection_changed.emit(self, affection, new_tier)

	# Record memorable moment if tier changed
	if old_tier != new_tier:
		if affection > old_affection:
			add_memorable_moment(
				"Reached %s Status" % new_tier,
				"Your bond has deepened. You are now %s!" % new_tier
			)
		else:
			add_memorable_moment(
				"Dropped to %s Status" % new_tier,
				"Your bond has weakened. You are now %s." % new_tier
			)

# === PERSONALITY SYSTEM ===

func get_personality_name() -> String:
	"""Returns the personality name as a string"""
	return Personality.keys()[personality]

func get_personality_bonus(reward_type: String) -> float:
	"""Returns personality-based bonus multiplier for different reward types"""
	match personality:
		Personality.CURIOUS:
			if reward_type == "parts":
				return 1.15  # +15% parts
			return 1.0
		Personality.BRAVE:
			# Bonus applies to dangerous locations (level 10+) in exploration manager
			return 1.10  # +10% all rewards from dangerous locations
		Personality.LAZY:
			if reward_type == "food":
				return 1.20  # +20% food rewards
			return 1.0
		Personality.ENERGETIC:
			if reward_type == "gold":
				return 0.90  # -10% gold (trades gold for speed)
			return 1.0
		Personality.GREEDY:
			if reward_type == "gold":
				return 1.25  # +25% gold
			return 1.0
		Personality.GENTLE:
			# Safe exploration bonus, handled in exploration manager
			return 1.0
	return 1.0

func get_exploration_time_modifier() -> float:
	"""Returns time multiplier for exploration duration"""
	match personality:
		Personality.LAZY:
			return 1.5  # +50% exploration time
		Personality.ENERGETIC:
			return 0.75  # -25% exploration time
		_:
			return 1.0

func get_affection_gain_modifier() -> float:
	"""Returns affection gain multiplier"""
	match personality:
		Personality.GENTLE:
			return 1.15  # +15% affection gain
		_:
			return 1.0

func get_random_dialogue() -> String:
	"""Returns a random personality-based dialogue line"""
	var dialogues = PERSONALITY_DIALOGUE.get(personality, [])
	if dialogues.is_empty():
		return "*looks at you curiously*"
	return dialogues.pick_random()

# === PET ACTIONS ===

func can_pet() -> bool:
	"""Check if enough time has passed since last pet"""
	var current_time = Time.get_unix_time_from_system()
	return (current_time - last_pet_time) >= PET_COOLDOWN

func get_pet_cooldown_remaining() -> int:
	"""Returns seconds remaining until can pet again"""
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - last_pet_time
	var remaining = PET_COOLDOWN - elapsed
	return max(0, remaining)

func pet() -> bool:
	"""Pet the dragon, gaining affection. Returns true if successful."""
	if not can_pet():
		return false

	last_pet_time = Time.get_unix_time_from_system()
	times_petted += 1

	# Apply affection with personality modifier
	var affection_gain = int(PET_AFFECTION * get_affection_gain_modifier())
	add_affection(affection_gain)

	# Increase happiness
	happiness_level = min(1.0, happiness_level + 0.1)

	# Emit personality action
	personality_action.emit(self, "pet")

	return true

func feed() -> void:
	"""Override feed to track statistics and affection"""
	super.feed()

	times_fed += 1

	# Apply affection with personality modifier
	var affection_gain = int(FEED_AFFECTION * get_affection_gain_modifier())
	add_affection(affection_gain)

func give_gift() -> bool:
	"""Give a pending gift to the player, gaining affection"""
	if pending_gifts.is_empty():
		return false

	var gift = pending_gifts.pop_front()
	times_gifted += 1

	# Apply affection with personality modifier
	var affection_gain = int(GIFT_AFFECTION * get_affection_gain_modifier())
	add_affection(affection_gain)

	gift_received.emit(self, gift)
	return true

func receive_gift_from_player() -> void:
	"""Receive a gift from the player, gaining affection"""
	# Apply affection with personality modifier
	var affection_gain = int(GIFT_AFFECTION * get_affection_gain_modifier())
	add_affection(affection_gain)

	# Increase happiness
	happiness_level = min(1.0, happiness_level + 0.15)

func get_gift_cost() -> int:
	"""Get the gold cost to give a gift, based on affection tier"""
	var tier = get_affection_tier()
	match tier:
		"Acquaintance": return 200
		"Friend": return 400
		"Companion": return 600
		"Best Friend": return 800
		"Soulbound": return 1000
	return 200

# === EXPLORATION UNLOCKS ===

const EXPLORATION_UNLOCKS = {
	"volcanic_caves": 0,      # Acquaintance (0-19)
	"ancient_forest": 20,     # Friend (20-39)
	"frozen_tundra": 40,      # Companion (40-59)
	"thunder_peak": 60,       # Best Friend (60-79)
	"shadow_realm": 80,       # Soulbound (80-100)
	"crystal_peaks": 80       # Soulbound (80-100)
}

func can_explore_destination(destination: String) -> bool:
	"""Check if the destination is unlocked based on affection"""
	if not EXPLORATION_UNLOCKS.has(destination):
		return true  # Unknown destinations default to available

	var required_affection = EXPLORATION_UNLOCKS[destination]
	return affection >= required_affection

func get_locked_destinations() -> Array:
	"""Get list of destinations that are still locked"""
	var locked = []
	for destination in EXPLORATION_UNLOCKS:
		if not can_explore_destination(destination):
			locked.append(destination)
	return locked

func get_next_unlock_destination() -> Dictionary:
	"""Get the next destination that will be unlocked and affection needed"""
	var locked = get_locked_destinations()
	if locked.is_empty():
		return {}  # All unlocked

	# Find the destination with lowest requirement above current affection
	var next_dest = ""
	var next_required = 999
	for destination in EXPLORATION_UNLOCKS:
		var required = EXPLORATION_UNLOCKS[destination]
		if required > affection and required < next_required:
			next_dest = destination
			next_required = required

	if next_dest != "":
		return {"destination": next_dest, "affection_required": next_required}
	return {}

func get_exploration_speed_bonus() -> float:
	"""Get speed bonus when all areas are unlocked (Soulbound tier)"""
	if affection >= 80:
		# All areas unlocked, calculate speed bonus based on affection
		var bonus_percent = (affection - 80) * 0.01  # 0% at 80, 20% at 100
		return 1.0 - bonus_percent  # Lower is faster (0.8 = 20% faster)
	return 1.0  # No bonus

# === EXPEDITION TRACKING ===

func complete_expedition(destination: String, gold_earned: int, parts_found: int, duration_minutes: int) -> void:
	"""Track expedition completion and generate potential gifts"""
	expeditions_completed += 1
	total_gold_earned += gold_earned
	total_parts_found += parts_found

	# Apply affection
	add_affection(EXPEDITION_AFFECTION)

	# Update favorite destination
	if favorite_destination == "" or favorite_destination == destination:
		favorite_destination = destination

	# Chance to find a gift (20% base, +10% per affection tier)
	var gift_chance = 0.2 + (affection / 100.0) * 0.1
	if randf() < gift_chance:
		_generate_gift(destination)

	# Record memorable moments for milestones
	if expeditions_completed == 10:
		add_memorable_moment("First 10 Expeditions", "Completed 10 expeditions together!")
	elif expeditions_completed == 50:
		add_memorable_moment("Seasoned Explorer", "Completed 50 expeditions together!")
	elif expeditions_completed == 100:
		add_memorable_moment("Master Explorer", "Completed 100 expeditions together!")

func _generate_gift(destination: String) -> void:
	"""Generate a random gift based on destination"""
	var gifts = [
		{"name": "Shiny Pebble", "description": "A smooth, colorful stone from %s" % destination},
		{"name": "Ancient Coin", "description": "An old coin discovered during exploration"},
		{"name": "Pressed Flower", "description": "A beautiful flower preserved from the journey"},
		{"name": "Dragon Scale", "description": "A shed scale from another dragon"},
		{"name": "Crystal Fragment", "description": "A glowing crystal shard"}
	]

	var gift = gifts.pick_random()
	pending_gifts.append(gift)

	add_memorable_moment(
		"Found a Gift",
		"Brought back a %s from %s" % [gift["name"], destination]
	)

# === MEMORY SYSTEM ===

func add_memorable_moment(title: String, description: String) -> void:
	"""Add a memorable moment to the pet's history"""
	var moment = {
		"title": title,
		"description": description,
		"timestamp": Time.get_unix_time_from_system()
	}
	memorable_moments.append(moment)
	memorable_moment_added.emit(self, title)

func get_memorable_moments_sorted() -> Array:
	"""Returns memorable moments sorted by most recent first"""
	var sorted = memorable_moments.duplicate()
	sorted.sort_custom(func(a, b): return a["timestamp"] > b["timestamp"])
	return sorted

# === SPECIAL OVERRIDES ===

func calculate_stats() -> void:
	"""Override to give pets better Health scaling and fatigue resistance (exploration-focused stats)"""
	if not head_part or not body_part or not tail_part:
		return

	# Pet dragons get BETTER health scaling (1.5x multiplier)
	# They need more HP to survive exploration damage
	total_attack = 10 + (head_part.attack_bonus * level)  # Not used, but keep for compatibility
	total_health = 50 + int((body_part.health_bonus * level) * 1.5)  # 1.5x health scaling!
	total_speed = 5 + (tail_part.speed_bonus * level)  # Not used, but keep for compatibility
	total_defense = 5 + (body_part.defense_bonus * level)

	# Initialize current_health if not set
	if current_health <= 0:
		current_health = total_health

	# Apply mutation bonus if applicable
	if is_chimera_mutation:
		_apply_chimera_mutation()
	else:
		_apply_element_synergy()

	# Apply status penalties
	_apply_status_penalties()

	# Calculate elemental resistances
	_calculate_elemental_resistances()

	# Calculate elemental attack
	_calculate_elemental_attack()

	# Removed debug spam - stats recalculated silently

func get_fatigue_resistance() -> float:
	"""Get fatigue resistance multiplier based on level (pets get better at handling fatigue)"""
	# Pets gain 5% fatigue resistance per level
	# Level 1: 1.0 (normal), Level 5: 0.8 (20% less fatigue), Level 10: 0.5 (50% less fatigue)
	var resistance = 1.0 - (level - 1) * 0.05
	return max(0.5, resistance)  # Cap at 50% resistance

func update_life_systems() -> void:
	"""Override to use DragonStateManager's proper fatigue system instead of the legacy one"""
	var current_time = Time.get_unix_time_from_system()

	# Update hunger level linearly (1% per minute) - this part is fine
	var time_since_fed = current_time - last_fed_time
	hunger_level = min(1.0, time_since_fed * HUNGER_RATE)

	# DO NOT use the legacy fatigue calculation from super.update_life_systems()
	# DragonStateManager handles fatigue properly with correct recovery rates
	# The legacy calculation would give instant recovery which breaks game balance

	# Recalculate stats with new status effects
	calculate_stats()

	# Add affection decay checking
	update_affection_decay()

func take_damage(amount: int) -> void:
	"""Override to prevent pet from dying - health never goes below 1"""
	if is_dead:
		return

	# Calculate new health
	var new_health = current_health - amount

	# Pet dragons cannot die - minimum health is 1
	current_health = max(1, new_health)

	health_changed.emit(self, current_health, total_health)

	# Pet never dies, so we don't call _die()
	# But we do record if they were saved from death
	if new_health <= 0 and current_health == 1:
		add_memorable_moment(
			"Survived Mortal Danger",
			"Your bond kept me alive when I should have fallen!"
		)

func _die() -> void:
	"""Override to prevent pet from dying - this should never be called"""
	# Pet dragons cannot die!
	# If this is somehow called, just log it and do nothing
	push_warning("[PetDragon] Attempted to kill pet dragon %s - pets cannot die!" % dragon_name)

# === STATISTICS ===

func get_days_together() -> int:
	"""Calculate days since creation"""
	var current_time = Time.get_unix_time_from_system()
	var seconds_together = current_time - created_at
	return int(seconds_together / 86400.0)  # 86400 seconds in a day

func update_days_together() -> void:
	"""Update the cached days_together value"""
	days_together = get_days_together()

# === SAVE/LOAD ===

func to_dict() -> Dictionary:
	"""Override to include pet-specific data"""
	var data = super.to_dict()

	# Add pet-specific fields
	data["is_pet"] = true
	data["personality"] = personality
	data["affection"] = affection
	data["last_pet_time"] = last_pet_time
	data["last_affection_decay_check"] = last_affection_decay_check
	data["affection_trend"] = affection_trend
	data["times_fed"] = times_fed
	data["times_petted"] = times_petted
	data["times_gifted"] = times_gifted
	data["expeditions_completed"] = expeditions_completed
	data["total_gold_earned"] = total_gold_earned
	data["total_parts_found"] = total_parts_found
	data["days_together"] = days_together
	data["favorite_destination"] = favorite_destination
	data["memorable_moments"] = memorable_moments.duplicate()
	data["pending_gifts"] = pending_gifts.duplicate()

	return data

func from_dict(data: Dictionary) -> void:
	"""Override to restore pet-specific data"""
	super.from_dict(data)

	# Restore pet-specific fields
	personality = data.get("personality", Personality.CURIOUS)
	affection = data.get("affection", 0)
	last_pet_time = data.get("last_pet_time", Time.get_unix_time_from_system())
	last_affection_decay_check = data.get("last_affection_decay_check", Time.get_unix_time_from_system())
	affection_trend = data.get("affection_trend", 0)
	times_fed = data.get("times_fed", 0)
	times_petted = data.get("times_petted", 0)
	times_gifted = data.get("times_gifted", 0)
	expeditions_completed = data.get("expeditions_completed", 0)
	total_gold_earned = data.get("total_gold_earned", 0)
	total_parts_found = data.get("total_parts_found", 0)
	days_together = data.get("days_together", 0)
	favorite_destination = data.get("favorite_destination", "")
	memorable_moments = data.get("memorable_moments", [])
	pending_gifts = data.get("pending_gifts", [])

# === AFFECTION DECAY ===

const AFFECTION_DECAY_CHECK_INTERVAL: int = 600  # Check every 10 minutes
const NEGLECT_PENALTY: int = 1  # Points lost per check when neglected
const IGNORED_TIME_THRESHOLD: int = 14400  # 4 hours without petting

func update_affection_decay() -> void:
	"""Check for neglect and decay affection if conditions are met"""
	var current_time = Time.get_unix_time_from_system()

	# Only check every 10 minutes
	if current_time - last_affection_decay_check < AFFECTION_DECAY_CHECK_INTERVAL:
		return

	last_affection_decay_check = current_time

	# Count neglect factors
	var neglect_count = 0

	# Check if hungry (> 60%)
	if hunger_level > 0.6:
		neglect_count += 1

	# Check if tired (> 70%)
	if fatigue_level > 0.7:
		neglect_count += 1

	# Check if ignored (no petting in 4 hours)
	var time_since_pet = current_time - last_pet_time
	if time_since_pet > IGNORED_TIME_THRESHOLD:
		neglect_count += 1

	# Check if low health (< 50%)
	var health_percent = float(current_health) / float(get_health())
	if health_percent < 0.5:
		neglect_count += 1

	# Apply affection decay based on neglect
	if neglect_count > 0:
		var affection_loss = -NEGLECT_PENALTY * neglect_count
		add_affection(affection_loss)

		# If affection reaches minimum (Acquaintance floor at 0), show warning
		if affection <= 0 and neglect_count >= 3:
			add_memorable_moment(
				"Feeling Neglected",
				"I feel sad and uncared for. Please take better care of me..."
			)
	else:
		# If well cared for, trend becomes stable
		if affection_trend == -1:
			affection_trend = 0

# === HELPER METHODS ===

func get_mood_state() -> String:
	"""Returns the current mood based on stats and affection trend"""
	# Priority: physical needs first
	if hunger_level > 0.7:
		return "hungry"
	elif fatigue_level > 0.8:
		return "tired"

	# Then emotional state based on affection
	if affection_trend == -1:
		return "sad"  # Affection is dropping
	elif affection >= 80 or affection_trend == 1:
		return "happy"  # High affection or increasing
	elif happiness_level > 0.7:
		return "content"
	else:
		return "neutral"

func get_status_text() -> String:
	"""Returns a text description of current status"""
	match current_state:
		DragonState.IDLE:
			return "Resting"
		DragonState.EXPLORING:
			return "Exploring"
		DragonState.TRAINING:
			return "Training"
		DragonState.DEFENDING:
			return "Cannot Defend"  # Pet dragons cannot defend
		DragonState.RESTING:
			return "Resting"
		_:
			return "Unknown"