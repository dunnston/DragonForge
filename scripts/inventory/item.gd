# Item - Represents a single item instance in the inventory
extends Resource
class_name Item

# Item properties
var id: String
var name: String
var type: String  # "dragon_part" or "consumable"
var description: String
var icon_path: String
var stackable: bool = true
var max_stack: int = 99
var rarity: int = 1

# Dragon part specific
var part_type: String  # "HEAD", "BODY", "TAIL"
var element: String  # "FIRE", "ICE", "LIGHTNING", "NATURE", "SHADOW"
var stats: Dictionary = {}  # {"attack": 10, "health": 20, "speed": 5}

# Consumable specific
var category: String  # "xp_boost", "healing", "food", "happiness"
var effect: Dictionary = {}  # {"type": "xp_gain", "amount": 50}

func _init(data: Dictionary = {}):
	if data.is_empty():
		return

	# Basic properties
	id = data.get("id", "")
	name = data.get("name", "Unknown Item")
	type = data.get("type", "")
	description = data.get("description", "")
	icon_path = data.get("icon", "")
	stackable = data.get("stackable", true)
	max_stack = data.get("max_stack", 99)
	rarity = data.get("rarity", 1)

	# Dragon part specific
	part_type = data.get("part_type", "")
	element = data.get("element", "")
	stats = data.get("stats", {})

	# Consumable specific
	category = data.get("category", "")
	effect = data.get("effect", {})

func is_dragon_part() -> bool:
	return type == "dragon_part"

func is_consumable() -> bool:
	return type == "consumable"

func can_stack_with(other_item: Item) -> bool:
	"""Check if this item can stack with another item"""
	if not stackable or not other_item or not other_item.stackable:
		return false

	# Items can stack if they have the same ID
	return id == other_item.id

func get_display_name() -> String:
	"""Get the name for UI display"""
	return name

func get_icon() -> Texture2D:
	"""Load and return the item icon"""
	if icon_path.is_empty():
		return null

	if ResourceLoader.exists(icon_path):
		return load(icon_path)
	else:
		# Return a placeholder icon if the file doesn't exist
		print("[Item] Icon not found: %s" % icon_path)
		return null

func to_dict() -> Dictionary:
	"""Convert item to dictionary for saving"""
	return {
		"id": id,
		"name": name,
		"type": type,
		"description": description,
		"icon_path": icon_path,
		"stackable": stackable,
		"max_stack": max_stack,
		"rarity": rarity,
		"part_type": part_type,
		"element": element,
		"stats": stats.duplicate(),
		"category": category,
		"effect": effect.duplicate()
	}

static func from_dict(data: Dictionary) -> Item:
	"""Create item from dictionary (for loading)"""
	return Item.new(data)
