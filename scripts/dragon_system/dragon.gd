extends Resource
class_name Dragon

@export var dragon_id: String
@export var dragon_name: String = "Unnamed Dragon"
@export var head_part: DragonPart
@export var body_part: DragonPart
@export var tail_part: DragonPart

# Computed stats
var total_attack: int = 0
var total_health: int = 0
var total_speed: int = 0
var current_health: int = 0
var level: int = 1
var experience: int = 0

# State tracking
var is_defending: bool = false
var is_exploring: bool = false
var last_fed_time: int = 0  # Unix timestamp

func _init(head: DragonPart = null, body: DragonPart = null, tail: DragonPart = null):
	dragon_id = generate_unique_id()
	head_part = head
	body_part = body
	tail_part = tail
	calculate_stats()
	current_health = total_health

func calculate_stats() -> void:
	if not head_part or not body_part or not tail_part:
		return
	
	# Base stats from parts
	total_attack = 10 + (head_part.attack_bonus * level)
	total_health = 50 + (body_part.health_bonus * level)
	total_speed = 5 + (tail_part.speed_bonus * level)
	
	# Element synergy bonuses (if 2+ parts match)
	var elements = [head_part.element, body_part.element, tail_part.element]
	var element_counts = {}
	for e in elements:
		element_counts[e] = element_counts.get(e, 0) + 1
	
	for element in element_counts:
		if element_counts[element] >= 2:
			# Synergy bonus: +20% to all stats
			total_attack = int(total_attack * 1.2)
			total_health = int(total_health * 1.2)
			total_speed = int(total_speed * 1.2)
			break

func get_combination_key() -> String:
	# Unique identifier for this part combination
	return "%s_%s_%s" % [
		DragonPart.Element.keys()[head_part.element],
		DragonPart.Element.keys()[body_part.element],
		DragonPart.Element.keys()[tail_part.element]
	]

func generate_unique_id() -> String:
	return "dragon_%d" % Time.get_ticks_msec()

func to_dict() -> Dictionary:
	return {
		"id": dragon_id,
		"name": dragon_name,
		"head": head_part.get_part_id() if head_part else "",
		"body": body_part.get_part_id() if body_part else "",
		"tail": tail_part.get_part_id() if tail_part else "",
		"level": level,
		"experience": experience,
		"current_health": current_health,
		"is_defending": is_defending,
		"is_exploring": is_exploring,
		"last_fed_time": last_fed_time
	}

static func from_dict(data: Dictionary) -> Dragon:
	# TODO: Reconstruct dragon from saved data
	# Will need access to PartLibrary to lookup parts
	return null
