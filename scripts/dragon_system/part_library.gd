extends Node
# Singleton access
# Singleton access
static var instance: PartLibrary

var all_parts: Dictionary = {}  # part_id -> DragonPart
var parts_by_type: Dictionary = {
	DragonPart.PartType.HEAD: [],
	DragonPart.PartType.BODY: [],
	DragonPart.PartType.TAIL: []
}

func _ready():
	instance = self
	_initialize_parts()

func _initialize_parts():
	# Create all 15 base parts (5 elements × 3 types)
	var elements = DragonPart.Element.values()
	var part_types = DragonPart.PartType.values()
	
	for element in elements:
		for part_type in part_types:
			var part = _create_part(part_type, element)
			register_part(part)

func _create_part(part_type: DragonPart.PartType, element: DragonPart.Element) -> DragonPart:
	var part = DragonPart.new()
	part.part_type = part_type
	part.element = element
	
	# Assign stat bonuses based on type and element
	match part_type:
		DragonPart.PartType.HEAD:
			part.attack_bonus = 5 + _get_element_modifier(element, "attack")
		DragonPart.PartType.BODY:
			part.health_bonus = 10 + _get_element_modifier(element, "health")
			part.defense_bonus = 4 + _get_element_modifier(element, "defense")
		DragonPart.PartType.TAIL:
			part.speed_bonus = 3 + _get_element_modifier(element, "speed")
	
	part.element_power = _get_element_power(element)
	
	# TODO: Load actual sprite textures
	# part.sprite_texture = load("res://assets/parts/%s_%s.png" % [part_type, element])
	
	return part

func _get_element_modifier(element: DragonPart.Element, stat: String) -> int:
	# Element-specific stat bonuses
	match element:
		DragonPart.Element.FIRE:
			return 3 if stat == "attack" else 0
		DragonPart.Element.ICE:
			if stat == "health":
				return 3
			elif stat == "defense":
				return 3
			else:
				return 0
		DragonPart.Element.LIGHTNING:
			return 3 if stat == "speed" else 0
		DragonPart.Element.NATURE:
			return 2  # Balanced
		DragonPart.Element.SHADOW:
			if stat == "attack":
				return 2
			elif stat == "defense":
				return 2
			else:
				return 1
	return 0

func _get_element_power(element: DragonPart.Element) -> int:
	# Base element power for special abilities
	return 10

func register_part(part: DragonPart):
	var part_id = part.get_part_id()
	all_parts[part_id] = part
	parts_by_type[part.part_type].append(part)

func get_part(part_id: String) -> DragonPart:
	return all_parts.get(part_id)

func get_parts_of_type(part_type: DragonPart.PartType) -> Array:
	return parts_by_type.get(part_type, [])

func get_random_part(part_type: DragonPart.PartType) -> DragonPart:
	var parts = get_parts_of_type(part_type)
	if parts.is_empty():
		return null
	return parts[randi() % parts.size()]

func get_part_by_element_and_type(element: DragonPart.Element, part_type: DragonPart.PartType) -> DragonPart:
	"""Find a specific part by element and type"""
	var parts = get_parts_of_type(part_type)
	for part in parts:
		if part.element == element:
			return part
	return null
