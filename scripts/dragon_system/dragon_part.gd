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

@export var part_type: PartType
@export var element: Element
@export var sprite_texture: Texture2D
@export var rarity: int = 1  # 1-5 for future expansion

# Stats each part contributes
@export var attack_bonus: int = 0
@export var health_bonus: int = 0
@export var speed_bonus: int = 0
@export var defense_bonus: int = 0
@export var element_power: int = 0  # Special element bonus

func get_part_id() -> String:
	return "%s_%s" % [PartType.keys()[part_type], Element.keys()[element]]
