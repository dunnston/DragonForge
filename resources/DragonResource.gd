extends Resource
class_name DragonResource

@export var dragon_name: String
@export var head: DragonPartResource
@export var body: DragonPartResource
@export var tail: DragonPartResource
@export var stats: Dictionary = { "attack": 0, "health": 0, "speed": 0 }
@export var level: int = 1
@export var xp: float = 0.0
@export var element_combo: Array[String] = [] # e.g. ["fire", "ice", "lightning"]
@export var rarity: String = "common"
@export var is_chimera: bool = false
@export var assigned_role: String = "none" # defense / exploration / idle
