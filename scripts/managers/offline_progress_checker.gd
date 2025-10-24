extends Node

## Offline Progress Checker
## Automatically checks for offline progress when game loads
## Shows welcome back popup if player was away for > 10 minutes

const MIN_OFFLINE_TIME: int = 60  # 1 minute in seconds (changed from 10 min for testing)

signal offline_progress_calculated(results: Dictionary)

func _ready():
	# Connect to SaveLoadManager's game_loaded signal
	# This ensures we only check offline progress AFTER a save is loaded
	if SaveLoadManager and SaveLoadManager.instance:
		SaveLoadManager.instance.game_loaded.connect(_on_game_loaded)

func _on_game_loaded(success: bool, message: String):
	"""Called when a save file is loaded"""
	if not success:
		return

	# Wait a frame to ensure all managers are fully initialized with loaded data
	await get_tree().process_frame

	# Check for offline progress
	_check_offline_progress()

func _check_offline_progress():
	"""Check if player has offline progress to claim"""
	# Make sure SaveLoadManager exists
	if not SaveLoadManager or not SaveLoadManager.instance:
		return

	# Make sure PetDragonManager exists and has a pet
	if not PetDragonManager or not PetDragonManager.instance:
		return

	if not PetDragonManager.instance.has_pet():
		return

	# Get last save time
	var save_info = SaveLoadManager.instance.get_save_info()
	var last_save_time = save_info.get("timestamp", 0)

	if last_save_time == 0:
		return

	# Calculate time offline
	var current_time = Time.get_unix_time_from_system()
	var seconds_offline = current_time - last_save_time

	# Only show welcome back if offline > MIN_OFFLINE_TIME
	if seconds_offline < MIN_OFFLINE_TIME:
		return

	print("[OfflineProgressChecker] Welcome back! You were offline for %.1f minutes" % (seconds_offline / 60.0))

	# Calculate offline progress
	var results = PetDragonManager.instance.calculate_offline_progress(seconds_offline)

	# Apply rewards
	_apply_offline_rewards(results)

	# Show welcome back popup
	await _show_welcome_back_popup(results, seconds_offline)

	# Emit signal
	offline_progress_calculated.emit(results)

func _apply_offline_rewards(results: Dictionary):
	"""Apply offline progress rewards to the game"""
	# Apply gold
	if results.has("gold") and results["gold"] > 0:
		if TreasureVault and TreasureVault.instance:
			TreasureVault.instance.add_gold(results["gold"])

	# Apply dragon parts
	if results.has("parts") and results["parts"] > 0:
		if InventoryManager and InventoryManager.instance:
			# Generate random parts
			var elements = ["fire", "ice", "lightning", "nature", "shadow"]
			var part_types = ["head", "body", "tail"]

			for i in results["parts"]:
				var random_element = elements.pick_random()
				var random_type = part_types.pick_random()
				var part_id = random_element + "_" + random_type
				InventoryManager.instance.add_item_by_id(part_id, 1)

func _show_welcome_back_popup(results: Dictionary, seconds_offline: int):
	"""Show the welcome back popup to the player"""
	# Load and instantiate welcome back popup scene
	var popup_scene_path = "res://scenes/ui/pet/welcome_back_popup.tscn"

	if not ResourceLoader.exists(popup_scene_path):
		push_warning("[OfflineProgressChecker] Welcome back popup scene not found at: %s" % popup_scene_path)
		print("[OfflineProgressChecker] Skipping popup (scene not created yet)")
		return

	var popup_scene = load(popup_scene_path)
	if not popup_scene:
		push_error("[OfflineProgressChecker] Failed to load welcome back popup scene!")
		return

	var popup = popup_scene.instantiate()

	# Add to scene tree FIRST (so @onready variables get initialized)
	get_tree().root.add_child(popup)

	# Wait for next frame to ensure _ready() has been called
	await get_tree().process_frame

	# NOW setup popup with results (after @onready variables are initialized)
	if popup.has_method("setup"):
		popup.setup(results, seconds_offline)
