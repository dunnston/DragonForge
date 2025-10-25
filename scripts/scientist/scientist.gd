extends Resource
class_name Scientist

# Scientist Upgrade System - Resource Class
# Represents a single scientist with tier progression and abilities

# === ENUMS ===

enum Type {
	STITCHER,    # Creation & Deployment Specialist
	CARETAKER,   # Health & Welfare Specialist
	TRAINER      # Training Yard Specialist
}

# === STATE ===

@export var scientist_type: Type
@export var tier: int = 0  # 0 = not hired, 1-5 = upgrade level
@export var is_hired: bool = false

# === TIER DATA TABLES ===

const TIER_DATA = {
	Type.STITCHER: [
		{"name": "Not Hired", "cost": 0, "salary": 0},
		{"name": "Apprentice Stitcher", "cost": 500, "salary": 10},
		{"name": "Journeyman Stitcher", "cost": 1500, "salary": 20},
		{"name": "Master Stitcher", "cost": 5000, "salary": 40},
		{"name": "Grand Stitcher", "cost": 15000, "salary": 75},
		{"name": "Legendary Stitcher", "cost": 50000, "salary": 150}
	],
	Type.CARETAKER: [
		{"name": "Not Hired", "cost": 0, "salary": 0},
		{"name": "Apprentice Caretaker", "cost": 400, "salary": 8},
		{"name": "Experienced Caretaker", "cost": 1200, "salary": 16},
		{"name": "Master Caretaker", "cost": 4000, "salary": 32},
		{"name": "Grand Caretaker", "cost": 12000, "salary": 60},
		{"name": "Tower Guardian", "cost": 40000, "salary": 120}
	],
	Type.TRAINER: [
		{"name": "Not Hired", "cost": 0, "salary": 0},
		{"name": "Apprentice Trainer", "cost": 600, "salary": 12},
		{"name": "Experienced Trainer", "cost": 1800, "salary": 24},
		{"name": "Master Trainer", "cost": 6000, "salary": 48},
		{"name": "Grand Master", "cost": 18000, "salary": 90},
		{"name": "Legendary Sensei", "cost": 60000, "salary": 180}
	]
}

const UNLOCK_REQUIREMENTS = [
	0,   # Tier 0: N/A
	0,   # Tier 1: Available from start
	25,  # Tier 2: 25 waves
	50,  # Tier 3: 50 waves
	100, # Tier 4: 100 waves
	200  # Tier 5: 200 waves
]

# === GETTER METHODS ===

func get_tier_name() -> String:
	"""Get the display name for current tier"""
	if tier < 0 or tier >= TIER_DATA[scientist_type].size():
		return "Unknown"
	return TIER_DATA[scientist_type][tier]["name"]

func get_salary() -> int:
	"""Get current salary cost per wave"""
	if tier < 0 or tier >= TIER_DATA[scientist_type].size():
		return 0
	return TIER_DATA[scientist_type][tier]["salary"]

func get_upgrade_cost() -> int:
	"""Get cost to upgrade to next tier (0 if already max tier)"""
	if tier >= 5:
		return 0  # Already max tier
	if tier < 0:
		return 0  # Invalid state
	return TIER_DATA[scientist_type][tier + 1]["cost"]

func get_next_tier_name() -> String:
	"""Get the name of the next tier (empty if max tier)"""
	if tier >= 5:
		return ""
	return TIER_DATA[scientist_type][tier + 1]["name"]

func get_next_tier_salary() -> int:
	"""Get the salary of the next tier (0 if max tier)"""
	if tier >= 5:
		return 0
	return TIER_DATA[scientist_type][tier + 1]["salary"]

func can_upgrade(waves_completed: int) -> bool:
	"""Check if scientist can be upgraded based on wave requirements"""
	if tier >= 5:
		return false  # Already max tier
	if tier < 1:
		return false  # Not hired yet, use hire_scientist instead

	var required_waves = UNLOCK_REQUIREMENTS[tier + 1]
	return waves_completed >= required_waves

func get_waves_required_for_next_tier() -> int:
	"""Get number of waves required to unlock next tier"""
	if tier >= 5:
		return 0  # Already max tier
	return UNLOCK_REQUIREMENTS[tier + 1]

# === ABILITY CHECKS - STITCHER ===

func can_create_dragons() -> bool:
	"""Tier 1: Auto-creates dragons from available parts"""
	return scientist_type == Type.STITCHER and tier >= 1

func can_auto_assign_defense() -> bool:
	"""Tier 2: Auto-assigns created dragons to defense towers"""
	return scientist_type == Type.STITCHER and tier >= 2

func can_auto_explore() -> bool:
	"""Tier 3: Auto-sends idle dragons exploring when defense is full"""
	return scientist_type == Type.STITCHER and tier >= 3

func can_emergency_recall() -> bool:
	"""Tier 4: Auto-recalls explorers when defense needs help"""
	return scientist_type == Type.STITCHER and tier >= 4

func can_auto_freeze() -> bool:
	"""Tier 5: Auto-freezes recovered parts before decay (<6 hours)"""
	return scientist_type == Type.STITCHER and tier >= 5

# === ABILITY CHECKS - CARETAKER ===

func can_feed() -> bool:
	"""Tier 1: Auto-feeds hungry dragons (>50% hunger)"""
	return scientist_type == Type.CARETAKER and tier >= 1

func can_heal() -> bool:
	"""Tier 2: Auto-heals damaged dragons (<75% HP)"""
	return scientist_type == Type.CARETAKER and tier >= 2

func can_rest() -> bool:
	"""Tier 3: Auto-rests fatigued defending dragons (>70% fatigue)"""
	return scientist_type == Type.CARETAKER and tier >= 3

func can_prevent_starvation() -> bool:
	"""Tier 4: Prevents starvation deaths (aggressive feeding at 20% hunger)"""
	return scientist_type == Type.CARETAKER and tier >= 4

func can_repair_towers() -> bool:
	"""Tier 5: Auto-repairs damaged towers (<50% HP)"""
	return scientist_type == Type.CARETAKER and tier >= 5

# === ABILITY CHECKS - TRAINER ===

func enables_training() -> bool:
	"""Tier 1: Enables training yard with 50% speed bonus"""
	return scientist_type == Type.TRAINER and tier >= 1

func can_auto_fill_training() -> bool:
	"""Tier 2: Auto-fills empty training slots with idle dragons"""
	return scientist_type == Type.TRAINER and tier >= 2

func can_auto_collect_training() -> bool:
	"""Tier 3: Auto-collects dragons that complete training"""
	return scientist_type == Type.TRAINER and tier >= 3

func can_auto_rotate() -> bool:
	"""Tier 4: Auto-rotates collected dragons back to training (loop)"""
	return scientist_type == Type.TRAINER and tier >= 4

func can_passive_xp() -> bool:
	"""Tier 5: Dragons gain passive XP while defending/exploring"""
	return scientist_type == Type.TRAINER and tier >= 5

# === SAVE/LOAD SERIALIZATION ===

func to_save_dict() -> Dictionary:
	"""Serialize scientist state for saving"""
	return {
		"type": scientist_type,
		"tier": tier,
		"hired": is_hired
	}

func load_from_dict(data: Dictionary):
	"""Restore scientist state from save data"""
	scientist_type = data.get("type", Type.STITCHER)
	tier = data.get("tier", 0)
	is_hired = data.get("hired", false)

# === DEBUG/UTILITY ===

func get_type_name() -> String:
	"""Get human-readable type name"""
	match scientist_type:
		Type.STITCHER:
			return "Stitcher"
		Type.CARETAKER:
			return "Caretaker"
		Type.TRAINER:
			return "Trainer"
		_:
			return "Unknown"

func get_all_abilities() -> Array[String]:
	"""Get list of all abilities for this scientist type"""
	match scientist_type:
		Type.STITCHER:
			return [
				"Creates dragons",
				"Assigns to defense",
				"Sends exploring",
				"Emergency recalls",
				"Auto-freezes parts"
			]
		Type.CARETAKER:
			return [
				"Feeds dragons",
				"Heals dragons",
				"Rests dragons",
				"Prevents starvation",
				"Repairs towers"
			]
		Type.TRAINER:
			return [
				"Training yard (+50%)",
				"Fills training slots",
				"Collects trained",
				"Auto-rotates training",
				"Passive XP gain"
			]
		_:
			return []

func is_ability_unlocked(ability_index: int) -> bool:
	"""Check if specific ability (0-4) is unlocked"""
	if ability_index < 0 or ability_index > 4:
		return false
	return tier > ability_index  # ability 0 = tier 1, ability 1 = tier 2, etc.