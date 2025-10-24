extends Node

static var instance

var available_names: Array[String] = []
var used_names: Array[String] = []

const NAMES_FILE_PATH = "res://docs/dragon_names.md"

func _init():
	if instance == null:
		instance = self

func _ready():
	_load_names()

func _load_names():
	"""Load dragon names from the names file"""
	available_names.clear()

	var file = FileAccess.open(NAMES_FILE_PATH, FileAccess.READ)
	if not file:
		push_error("[DragonNameManager] Failed to open dragon names file: %s" % NAMES_FILE_PATH)
		_load_fallback_names()
		return

	# Read all lines and extract names
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		# Skip empty lines
		if line.is_empty():
			continue
		available_names.append(line)

	file.close()

	print("[DragonNameManager] Loaded %d dragon names from file" % available_names.size())

func _load_fallback_names():
	"""Fallback names in case file loading fails"""
	available_names = [
		"Azryth", "Drakonis", "Seryth", "Vyrran", "Kaelthar",
		"Obryss", "Zeryphon", "Thalyss", "Myrridon", "Xytheris"
	]
	print("[DragonNameManager] Using fallback names (%d)" % available_names.size())

func get_random_name() -> String:
	"""Get a random unused name from the list"""
	if available_names.is_empty():
		# If we've used all names, reset the pool
		_reset_name_pool()

	if available_names.is_empty():
		# Still empty? Return a generated name as last resort
		return "Dragon_%d" % randi_range(1000, 9999)

	# Pick a random name
	var index = randi_range(0, available_names.size() - 1)
	var name = available_names[index]

	# Move from available to used
	available_names.remove_at(index)
	used_names.append(name)

	return name

func _reset_name_pool():
	"""Reset the name pool when all names have been used"""
	print("[DragonNameManager] All names used, resetting pool")
	available_names = used_names.duplicate()
	used_names.clear()

func get_available_count() -> int:
	"""Get the number of available unused names"""
	return available_names.size()

func get_used_count() -> int:
	"""Get the number of names already used"""
	return used_names.size()

# === SAVE/LOAD SERIALIZATION ===

func to_dict() -> Dictionary:
	"""Serialize name manager state for saving"""
	return {
		"available_names": available_names.duplicate(),
		"used_names": used_names.duplicate()
	}

func from_dict(data: Dictionary):
	"""Restore name manager state from saved data"""
	if data.has("available_names"):
		available_names = data["available_names"].duplicate()

	if data.has("used_names"):
		used_names = data["used_names"].duplicate()

	print("[DragonNameManager] Restored state: %d available, %d used" % [
		available_names.size(),
		used_names.size()
	])