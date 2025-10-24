# ItemDatabase - Singleton that loads and manages item definitions from JSON
extends Node

# === SINGLETON ===
static var instance: ItemDatabase

# === ITEM STORAGE ===
var items: Dictionary = {}  # {item_id: item_definition_dict}
var dragon_parts: Dictionary = {}  # Filtered dragon parts
var consumables: Dictionary = {}  # Filtered consumables

const ITEMS_PATH = "res://data/items.json"

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	load_items()

func load_items():
	"""Load all item definitions from JSON"""
	if not FileAccess.file_exists(ITEMS_PATH):
		print("[ItemDatabase] ERROR: items.json not found at %s" % ITEMS_PATH)
		return

	var file = FileAccess.open(ITEMS_PATH, FileAccess.READ)
	if not file:
		print("[ItemDatabase] ERROR: Could not open items.json")
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		print("[ItemDatabase] ERROR: Failed to parse items.json at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return

	var data = json.data

	# Load dragon parts
	if data.has("dragon_parts"):
		for part_id in data["dragon_parts"]:
			var part_data = data["dragon_parts"][part_id]
			items[part_id] = part_data
			dragon_parts[part_id] = part_data

			# Also create a "_recovered" variant for parts recovered from death
			# These stack separately and show decay timers
			var recovered_id = part_id + "_recovered"
			var recovered_data = part_data.duplicate(true)
			recovered_data["id"] = recovered_id
			recovered_data["name"] = part_data["name"] + " (Recovered)"
			recovered_data["description"] = part_data.get("description", "") + " - Recovered from a fallen dragon. Will decay in 24 hours."
			items[recovered_id] = recovered_data
			dragon_parts[recovered_id] = recovered_data

	# Load consumables
	if data.has("consumables"):
		for item_id in data["consumables"]:
			var item_data = data["consumables"][item_id]
			items[item_id] = item_data
			consumables[item_id] = item_data

	print("[ItemDatabase] Loaded %d total items (%d dragon parts, %d consumables)" % [
		items.size(),
		dragon_parts.size(),
		consumables.size()
	])

func get_item(item_id: String) -> Item:
	"""Create a new Item instance from the database"""
	if not items.has(item_id):
		print("[ItemDatabase] WARNING: Item ID '%s' not found" % item_id)
		return null

	return Item.new(items[item_id])

func get_item_data(item_id: String) -> Dictionary:
	"""Get raw item data dictionary"""
	return items.get(item_id, {})

func item_exists(item_id: String) -> bool:
	"""Check if an item ID exists in the database"""
	return items.has(item_id)

func get_all_dragon_parts() -> Array:
	"""Get all dragon part item IDs"""
	return dragon_parts.keys()

func get_dragon_parts_by_type(part_type: String) -> Array:
	"""Get dragon part IDs filtered by type (HEAD, BODY, TAIL)"""
	var result: Array = []
	for part_id in dragon_parts:
		var part_data = dragon_parts[part_id]
		if part_data.get("part_type", "") == part_type:
			result.append(part_id)
	return result

func get_dragon_parts_by_element(element: String) -> Array:
	"""Get dragon part IDs filtered by element"""
	var result: Array = []
	for part_id in dragon_parts:
		var part_data = dragon_parts[part_id]
		if part_data.get("element", "") == element:
			result.append(part_id)
	return result

func get_all_consumables() -> Array:
	"""Get all consumable item IDs"""
	return consumables.keys()

func get_consumables_by_category(category: String) -> Array:
	"""Get consumable IDs filtered by category"""
	var result: Array = []
	for item_id in consumables:
		var item_data = consumables[item_id]
		if item_data.get("category", "") == category:
			result.append(item_id)
	return result

func print_database_info():
	"""Debug: Print information about loaded items"""
	print("\n=== ITEM DATABASE ===")
	print("Total Items: %d" % items.size())
	print("\nDragon Parts: %d" % dragon_parts.size())
	for element in ["FIRE", "ICE", "LIGHTNING", "NATURE", "SHADOW"]:
		var parts = get_dragon_parts_by_element(element)
		print("  %s: %d parts" % [element, parts.size()])
	print("\nConsumables: %d" % consumables.size())
	for category in ["xp_boost", "healing", "food", "happiness"]:
		var items_in_category = get_consumables_by_category(category)
		print("  %s: %d items" % [category, items_in_category.size()])
	print("====================\n")
