extends Resource
class_name DragonPart

enum PartType {
	HEAD,
	BODY,
	TAIL
}

enum Element {
	FIRE,
	ICE,
	LIGHTNING,
	NATURE,
	SHADOW
}

enum Source {
	NORMAL,      # Regular parts from exploration/rewards
	RECOVERED,   # Parts recovered from dead dragons (decay in 24h)
	FROZEN       # Parts preserved in freezer (no decay)
}

@export var part_type: PartType
@export var element: Element
@export var sprite_texture: Texture2D
@export var icon_path: String = ""  # Path to icon for UI display
@export var rarity: int = 1  # 1-5 for future expansion

# Stats each part contributes
@export var attack_bonus: int = 0
@export var health_bonus: int = 0
@export var speed_bonus: int = 0
@export var defense_bonus: int = 0
@export var element_power: int = 0  # Special element bonus

# Part recovery and decay system (Phase 3)
@export var part_id: String = ""  # Unique identifier for tracking
@export var source: Source = Source.NORMAL  # Where this part came from
@export var recovery_timestamp: int = 0  # Unix timestamp when recovered (0 if not recovered)
@export var decay_duration: int = 86400  # 24 hours in seconds
@export var freezer_slot_index: int = -1  # -1 if not in freezer, else slot index

func get_part_id() -> String:
	return "%s_%s" % [PartType.keys()[part_type], Element.keys()[element]]

func get_icon() -> Texture2D:
	"""Load and return the part icon for UI display"""
	if icon_path.is_empty():
		return null

	if ResourceLoader.exists(icon_path):
		return load(icon_path)
	else:
		print("[DragonPart] Icon not found: %s" % icon_path)
		return null

# === PART RECOVERY & DECAY SYSTEM ===

func is_recovered() -> bool:
	"""Check if this part was recovered from a dead dragon"""
	return source == Source.RECOVERED

func is_frozen() -> bool:
	"""Check if this part is currently in the freezer"""
	return source == Source.FROZEN

func get_time_until_decay() -> int:
	"""Get seconds remaining until this part decays (returns -1 if not recovered)"""
	if not is_recovered():
		return -1

	var current_time = Time.get_unix_time_from_system()
	var decay_time = recovery_timestamp + decay_duration
	return max(0, decay_time - current_time)

func is_decayed() -> bool:
	"""Check if this recovered part has decayed"""
	return is_recovered() and get_time_until_decay() <= 0

func get_decay_urgency() -> String:
	"""Get urgency level for UI display: safe, warning, urgent, critical"""
	var time_left = get_time_until_decay()

	if time_left == -1:
		return "none"  # Not a recovered part

	if time_left > 43200:  # >12 hours
		return "safe"
	elif time_left > 21600:  # >6 hours
		return "warning"
	elif time_left > 3600:  # >1 hour
		return "urgent"
	else:
		return "critical"

func format_time_remaining() -> String:
	"""Format time remaining for UI display"""
	var seconds = get_time_until_decay()

	if seconds == -1:
		return "N/A"

	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60

	if hours >= 1:
		return "%dh %dm" % [hours, minutes]
	elif minutes >= 1:
		return "%dm" % minutes
	else:
		return "%ds" % seconds

func get_element_name() -> String:
	"""Get human-readable element name"""
	match element:
		Element.FIRE: return "Fire"
		Element.ICE: return "Ice"
		Element.LIGHTNING: return "Lightning"
		Element.NATURE: return "Nature"
		Element.SHADOW: return "Shadow"
	return "Unknown"

func get_part_type_name() -> String:
	"""Get human-readable part type name"""
	match part_type:
		PartType.HEAD: return "Head"
		PartType.BODY: return "Body"
		PartType.TAIL: return "Tail"
	return "Unknown"

func get_display_name() -> String:
	"""Get full display name (e.g., 'Fire Head')"""
	return "%s %s" % [get_element_name(), get_part_type_name()]

func get_rarity_name() -> String:
	"""Get human-readable rarity name"""
	match rarity:
		1: return "Common"
		2: return "Uncommon"
		3: return "Rare"
		4: return "Epic"
		5: return "Legendary"
	return "Common"
