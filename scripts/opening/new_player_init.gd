extends Node
## New Player Initialization
## Handles checking if this is a new player and starting the tutorial sequence

## Check if the player is new and should see the opening sequence
static func is_new_player() -> bool:
	"""Check if this is a new player (no save file and no tutorial completion)"""
	# Check if tutorial has been completed
	if FileAccess.file_exists("user://tutorial_save.json"):
		return false

	# Check if game save exists
	if FileAccess.file_exists("user://savegame.json"):
		return false

	return true


## Start the new player experience (opening letter + tutorial)
static func start_new_player_experience() -> void:
	"""Start the opening letter scene for new players"""
	# Change to opening letter scene
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		tree.change_scene_to_file("res://scenes/opening/opening_letter.tscn")


## Initialize starting inventory for new players
static func initialize_starting_resources() -> void:
	"""Initialize starting gold and dragon parts for new players"""
	# Set starting gold
	if TreasureVault and TreasureVault.instance:
		TreasureVault.instance.add_gold(30)
		print("[NewPlayerInit] Added 30 starting gold")

	# Generate 9 random starting parts with constraints (enough for 2 full dragons)
	var parts_to_add = generate_starting_parts()

	# Add parts to inventory
	if InventoryManager and InventoryManager.instance:
		for part in parts_to_add:
			InventoryManager.instance.add_item_by_id(part, 1)
		print("[NewPlayerInit] Added %d starting parts: %s" % [parts_to_add.size(), parts_to_add])

		# Add 5 starting Energy Tonics
		InventoryManager.instance.add_item_by_id("energy_tonic", 5)
		print("[NewPlayerInit] Added 5 starting Energy Tonics")


## Generate 9 starting parts with 3 of each type (enough for 2 full dragons)
static func generate_starting_parts() -> Array[String]:
	"""Generate 9 starting parts ensuring 3 heads, 3 bodies, 3 tails for building 2 dragons"""
	var parts: Array[String] = []
	var elements = ["fire", "ice", "lightning", "nature", "shadow"]
	var part_types = ["head", "body", "tail"]

	# Ensure 3 of each part type (3 heads, 3 bodies, 3 tails)
	for part_type in part_types:
		for i in range(3):
			var random_element = elements[randi() % elements.size()]
			parts.append(random_element + "_" + part_type)

	return parts


## Mark tutorial as skipped (for returning players or manual skip)
static func skip_tutorial() -> void:
	"""Mark tutorial as completed without going through it"""
	var save_data = {
		"tutorial_completed": true,
		"tutorial_skipped": true,
		"completed_at": Time.get_unix_time_from_system()
	}

	var save_file = FileAccess.open("user://tutorial_save.json", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
