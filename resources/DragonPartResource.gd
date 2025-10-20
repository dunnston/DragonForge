extends Resource
class_name DragonPartResource


@export var part_type: String = "head" # head / body / tail
@export var element: String = "fire"   # fire / ice / lightning / nature / shadow
@export var stat_bonus: Dictionary = { "attack": 5, "health": 0, "speed": 0 }
@export var rarity: String = "common"
@export var sprite_path: String
@export var special_effect: String = "" # e.g. "bonus_vs_ice"
