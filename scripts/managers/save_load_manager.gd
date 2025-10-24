extends Node

# Save/Load Manager - Handles saving and loading game state to/from localStorage (user:// directory)

# === SINGLETON ===
static var instance

# === CONSTANTS ===
const SAVE_FILE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 1
const AUTO_SAVE_INTERVAL: float = 120.0  # Auto-save every 2 minutes

# === STATE ===
var auto_save_enabled: bool = true
var auto_save_timer: Timer
var should_load_on_start: bool = false  # Flag set by title screen to trigger load

# === SIGNALS ===
signal game_saved(success: bool, message: String)
signal game_loaded(success: bool, message: String)
signal auto_save_triggered()

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	print("[SaveLoadManager] Initialized")

	# Setup auto-save timer
	_setup_auto_save()

func _setup_auto_save():
	"""Setup automatic saving"""
	auto_save_timer = Timer.new()
	add_child(auto_save_timer)
	auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	auto_save_timer.timeout.connect(_on_auto_save_timeout)

	if auto_save_enabled:
		auto_save_timer.start()
		print("[SaveLoadManager] Auto-save enabled (every %.0f seconds)" % AUTO_SAVE_INTERVAL)

func _on_auto_save_timeout():
	"""Called when auto-save timer triggers"""
	if auto_save_enabled:
		print("[SaveLoadManager] Auto-save triggered")
		auto_save_triggered.emit()
		save_game()

# === SAVE GAME ===

func save_game() -> bool:
	"""
	Save the complete game state to localStorage.

	Returns true if save was successful, false otherwise.
	"""
	print("\n[SaveLoadManager] === SAVING GAME ===")

	var save_data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"save_date": Time.get_datetime_string_from_system()
	}

	# Wait one frame to ensure all managers are ready
	await get_tree().process_frame

	# Serialize TreasureVault
	if TreasureVault and TreasureVault.instance:
		save_data["treasure_vault"] = TreasureVault.instance.to_dict()
		print("[SaveLoadManager] ✓ Saved TreasureVault (Gold: %d)" % TreasureVault.instance.get_total_gold())
	else:
		push_error("[SaveLoadManager] ERROR: TreasureVault not found!")
		game_saved.emit(false, "TreasureVault not found")
		return false

	# Serialize InventoryManager
	if InventoryManager and InventoryManager.instance:
		save_data["inventory"] = InventoryManager.instance.to_dict()
		print("[SaveLoadManager] ✓ Saved InventoryManager")
	else:
		push_error("[SaveLoadManager] ERROR: InventoryManager not found!")
		game_saved.emit(false, "InventoryManager not found")
		return false

	# Serialize DefenseManager
	if DefenseManager and DefenseManager.instance:
		save_data["defense_manager"] = DefenseManager.instance.to_dict()
		print("[SaveLoadManager] ✓ Saved DefenseManager (Wave: %d)" % DefenseManager.instance.wave_number)
	else:
		push_error("[SaveLoadManager] ERROR: DefenseManager not found!")
		game_saved.emit(false, "DefenseManager not found")
		return false

	# Serialize DefenseTowerManager
	if DefenseTowerManager and DefenseTowerManager.instance:
		save_data["defense_tower_manager"] = DefenseTowerManager.instance.to_dict()
		print("[SaveLoadManager] ✓ Saved DefenseTowerManager (Towers: %d)" % DefenseTowerManager.instance.get_total_towers())
	else:
		push_error("[SaveLoadManager] ERROR: DefenseTowerManager not found!")
		game_saved.emit(false, "DefenseTowerManager not found")
		return false

	# Get DragonFactory reference (it's not an autoload, so we need to find it)
	var dragon_factory = _find_dragon_factory()
	if not dragon_factory:
		push_error("[SaveLoadManager] ERROR: DragonFactory not found!")
		game_saved.emit(false, "DragonFactory not found")
		return false

	# Serialize DragonFactory
	save_data["dragon_factory"] = dragon_factory.to_dict()
	print("[SaveLoadManager] ✓ Saved DragonFactory (%d dragons)" % dragon_factory.active_dragons.size())

	# Serialize ExplorationManager
	if ExplorationManager and ExplorationManager.instance:
		save_data["exploration_manager"] = ExplorationManager.instance.to_dict()
		print("[SaveLoadManager] ✓ Saved ExplorationManager (%d active)" % ExplorationManager.instance.get_active_explorations_count())
	else:
		push_error("[SaveLoadManager] ERROR: ExplorationManager not found!")
		game_saved.emit(false, "ExplorationManager not found")
		return false

	# Get ScientistManager reference (autoload singleton)
	var scientist_manager = _find_scientist_manager()
	if scientist_manager:
		save_data["scientist_manager"] = scientist_manager.to_dict()
		print("[SaveLoadManager] ✓ Saved ScientistManager")
	else:
		print("[SaveLoadManager] WARNING: ScientistManager not found, skipping")
		save_data["scientist_manager"] = {}

	# Get TrainingManager reference (autoload singleton)
	if TrainingManager and TrainingManager.instance:
		save_data["training_manager"] = TrainingManager.instance.to_dict()
		print("[SaveLoadManager] ✓ Saved TrainingManager (%d/%d slots)" % [TrainingManager.instance.get_occupied_count(), TrainingManager.instance.get_capacity()])
	else:
		print("[SaveLoadManager] WARNING: TrainingManager not found, skipping")
		save_data["training_manager"] = {}

	# Serialize DragonDeathManager
	if DragonDeathManager and DragonDeathManager.instance:
		save_data["dragon_death_manager"] = DragonDeathManager.instance.to_save_dict()
		print("[SaveLoadManager] ✓ Saved DragonDeathManager (Freezer Lvl: %d, Recovered: %d)" % [DragonDeathManager.instance.freezer_level, DragonDeathManager.instance.recovered_parts.size()])
	else:
		print("[SaveLoadManager] WARNING: DragonDeathManager not found, skipping")
		save_data["dragon_death_manager"] = {}

	# Serialize PetDragonManager
	if PetDragonManager and PetDragonManager.instance:
		save_data["pet_dragon_manager"] = PetDragonManager.instance.to_dict()
		if PetDragonManager.instance.has_pet():
			var pet = PetDragonManager.instance.get_pet_dragon()
			print("[SaveLoadManager] ✓ Saved PetDragonManager (Pet: %s, Lvl %d, Affection: %d)" % [pet.dragon_name, pet.level, pet.affection])
		else:
			print("[SaveLoadManager] ✓ Saved PetDragonManager (No pet yet)")
	else:
		print("[SaveLoadManager] WARNING: PetDragonManager not found, skipping")
		save_data["pet_dragon_manager"] = {}

	# Serialize DragonNameManager
	if DragonNameManager and DragonNameManager.instance:
		save_data["dragon_name_manager"] = DragonNameManager.instance.to_dict()
		print("[SaveLoadManager] ✓ Saved DragonNameManager (%d available, %d used)" % [DragonNameManager.instance.get_available_count(), DragonNameManager.instance.get_used_count()])
	else:
		print("[SaveLoadManager] WARNING: DragonNameManager not found, skipping")
		save_data["dragon_name_manager"] = {}

	# Convert to JSON
	var json_string = JSON.stringify(save_data, "\t")

	# Write to file
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		var error = FileAccess.get_open_error()
		push_error("[SaveLoadManager] ERROR: Failed to open save file! Error: %d" % error)
		game_saved.emit(false, "Failed to open save file")
		return false

	file.store_string(json_string)
	file.close()

	print("[SaveLoadManager] ✓ Game saved successfully to: %s" % SAVE_FILE_PATH)
	print("[SaveLoadManager] === SAVE COMPLETE ===\n")
	game_saved.emit(true, "Game saved successfully")
	return true

# === LOAD GAME ===

func load_game() -> bool:
	"""
	Load the complete game state from localStorage.

	Returns true if load was successful, false otherwise.
	"""
	print("\n[SaveLoadManager] === LOADING GAME ===")

	# Check if save file exists
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[SaveLoadManager] No save file found at: %s" % SAVE_FILE_PATH)
		game_loaded.emit(false, "No save file found")
		return false

	# Read save file
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		var error = FileAccess.get_open_error()
		push_error("[SaveLoadManager] ERROR: Failed to open save file! Error: %d" % error)
		game_loaded.emit(false, "Failed to open save file")
		return false

	var json_string = file.get_as_text()
	file.close()

	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("[SaveLoadManager] ERROR: Failed to parse save file JSON! Error: %d" % parse_result)
		game_loaded.emit(false, "Failed to parse save file")
		return false

	var save_data = json.data

	# Validate save version
	if not save_data.has("version"):
		push_error("[SaveLoadManager] ERROR: Save file has no version!")
		game_loaded.emit(false, "Invalid save file format")
		return false

	if save_data["version"] != SAVE_VERSION:
		push_error("[SaveLoadManager] ERROR: Save version mismatch! Expected %d, got %d" % [SAVE_VERSION, save_data["version"]])
		game_loaded.emit(false, "Save file version mismatch")
		return false

	print("[SaveLoadManager] Loading save from: %s" % save_data.get("save_date", "Unknown"))

	# Wait one frame to ensure all managers are ready
	await get_tree().process_frame

	# Load TreasureVault
	if save_data.has("treasure_vault") and TreasureVault and TreasureVault.instance:
		TreasureVault.instance.from_dict(save_data["treasure_vault"])
		print("[SaveLoadManager] ✓ Loaded TreasureVault (Gold: %d)" % TreasureVault.instance.get_total_gold())
	else:
		push_error("[SaveLoadManager] ERROR: Failed to load TreasureVault!")
		game_loaded.emit(false, "Failed to load TreasureVault")
		return false

	# Load InventoryManager
	if save_data.has("inventory") and InventoryManager and InventoryManager.instance:
		InventoryManager.instance.from_dict(save_data["inventory"])
		print("[SaveLoadManager] ✓ Loaded InventoryManager")
	else:
		push_error("[SaveLoadManager] ERROR: Failed to load InventoryManager!")
		game_loaded.emit(false, "Failed to load InventoryManager")
		return false

	# Load DragonFactory (must load before other managers that reference dragons)
	var dragon_factory = _find_dragon_factory()
	if save_data.has("dragon_factory") and dragon_factory:
		dragon_factory.from_dict(save_data["dragon_factory"])
		print("[SaveLoadManager] ✓ Loaded DragonFactory (%d dragons)" % dragon_factory.active_dragons.size())
	else:
		push_error("[SaveLoadManager] ERROR: Failed to load DragonFactory!")
		game_loaded.emit(false, "Failed to load DragonFactory")
		return false

	# Load DefenseTowerManager (must load before DefenseManager for capacity checks)
	if save_data.has("defense_tower_manager") and DefenseTowerManager and DefenseTowerManager.instance:
		DefenseTowerManager.instance.from_dict(save_data["defense_tower_manager"])
		print("[SaveLoadManager] ✓ Loaded DefenseTowerManager (Towers: %d)" % DefenseTowerManager.instance.get_total_towers())
	else:
		push_error("[SaveLoadManager] ERROR: Failed to load DefenseTowerManager!")
		game_loaded.emit(false, "Failed to load DefenseTowerManager")
		return false

	# Load DefenseManager (depends on DragonFactory and DefenseTowerManager)
	if save_data.has("defense_manager") and DefenseManager and DefenseManager.instance:
		DefenseManager.instance.from_dict(save_data["defense_manager"], dragon_factory)
		print("[SaveLoadManager] ✓ Loaded DefenseManager (Wave: %d)" % DefenseManager.instance.wave_number)
	else:
		push_error("[SaveLoadManager] ERROR: Failed to load DefenseManager!")
		game_loaded.emit(false, "Failed to load DefenseManager")
		return false

	# Load ExplorationManager (depends on DragonFactory)
	if save_data.has("exploration_manager") and ExplorationManager and ExplorationManager.instance:
		ExplorationManager.instance.from_dict(save_data["exploration_manager"], dragon_factory)
		print("[SaveLoadManager] ✓ Loaded ExplorationManager (%d active)" % ExplorationManager.instance.get_active_explorations_count())
	else:
		push_error("[SaveLoadManager] ERROR: Failed to load ExplorationManager!")
		game_loaded.emit(false, "Failed to load ExplorationManager")
		return false

	# Load ScientistManager
	var scientist_manager = _find_scientist_manager()
	if save_data.has("scientist_manager") and scientist_manager:
		scientist_manager.from_dict(save_data["scientist_manager"])
		print("[SaveLoadManager] ✓ Loaded ScientistManager")
	else:
		print("[SaveLoadManager] WARNING: ScientistManager not found or no data, skipping")

	# Load TrainingManager
	if save_data.has("training_manager") and TrainingManager and TrainingManager.instance:
		TrainingManager.instance.from_dict(save_data["training_manager"])
		print("[SaveLoadManager] ✓ Loaded TrainingManager")
	else:
		print("[SaveLoadManager] WARNING: TrainingManager not found or no data, skipping")

	# Load DragonDeathManager
	if save_data.has("dragon_death_manager") and DragonDeathManager and DragonDeathManager.instance:
		DragonDeathManager.instance.load_from_dict(save_data["dragon_death_manager"])
		print("[SaveLoadManager] ✓ Loaded DragonDeathManager")
	else:
		print("[SaveLoadManager] WARNING: DragonDeathManager not found or no data, skipping")

	# Load PetDragonManager (must load after DragonFactory since pet references dragon parts)
	if save_data.has("pet_dragon_manager") and PetDragonManager and PetDragonManager.instance:
		PetDragonManager.instance.from_dict(save_data["pet_dragon_manager"])
		if PetDragonManager.instance.has_pet():
			var pet = PetDragonManager.instance.get_pet_dragon()
			print("[SaveLoadManager] ✓ Loaded PetDragonManager (Pet: %s, Lvl %d, Affection: %d)" % [pet.dragon_name, pet.level, pet.affection])
		else:
			print("[SaveLoadManager] ✓ Loaded PetDragonManager (No pet yet)")
	else:
		print("[SaveLoadManager] WARNING: PetDragonManager not found or no data, skipping")

	# Load DragonNameManager
	if save_data.has("dragon_name_manager") and DragonNameManager and DragonNameManager.instance:
		DragonNameManager.instance.from_dict(save_data["dragon_name_manager"])
		print("[SaveLoadManager] ✓ Loaded DragonNameManager (%d available, %d used)" % [DragonNameManager.instance.get_available_count(), DragonNameManager.instance.get_used_count()])
	else:
		print("[SaveLoadManager] WARNING: DragonNameManager not found or no data, skipping")

	# Refresh UI to show loaded dragons and scientists
	_refresh_ui()

	print("[SaveLoadManager] ✓ Game loaded successfully")
	print("[SaveLoadManager] === LOAD COMPLETE ===\n")
	game_loaded.emit(true, "Game loaded successfully")
	return true

# === UTILITY FUNCTIONS ===

func _find_dragon_factory() -> DragonFactory:
	"""Find the DragonFactory instance in the scene tree"""
	# DragonFactory is added as a child of FactoryManager
	var factory_managers = get_tree().get_nodes_in_group("factory_manager")
	if factory_managers.size() > 0:
		for child in factory_managers[0].get_children():
			if child is DragonFactory:
				return child

	# Fallback: search entire tree
	return _find_node_by_type(get_tree().root, DragonFactory)

func _find_scientist_manager():
	"""Get the ScientistManager autoload singleton"""
	# ScientistManager is now an autoload singleton, access it directly
	if ScientistManager and ScientistManager.instance:
		return ScientistManager.instance

	push_error("[SaveLoadManager] ScientistManager autoload not found!")
	return null

func _find_node_by_type(node: Node, type) -> Node:
	"""Recursively search for a node of a specific type"""
	if is_instance_of(node, type):
		return node

	for child in node.get_children():
		var result = _find_node_by_type(child, type)
		if result:
			return result

	return null

func _refresh_ui():
	"""Refresh UI after loading game"""
	# Find FactoryManager and tell it to update its display
	var factory_managers = get_tree().get_nodes_in_group("factory_manager")
	if factory_managers.size() > 0:
		var factory_manager = factory_managers[0]
		if factory_manager.has_method("force_update"):
			factory_manager.force_update()
			print("[SaveLoadManager] ✓ UI refreshed")
	else:
		print("[SaveLoadManager] WARNING: FactoryManager not found, UI not refreshed")

func has_save_file() -> bool:
	"""Check if a save file exists"""
	return FileAccess.file_exists(SAVE_FILE_PATH)

func delete_save_file() -> bool:
	"""Delete the save file"""
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var dir = DirAccess.open("user://")
		var error = dir.remove(SAVE_FILE_PATH)
		if error == OK:
			print("[SaveLoadManager] Save file deleted")
			return true
		else:
			push_error("[SaveLoadManager] ERROR: Failed to delete save file! Error: %d" % error)
			return false
	return false

func set_auto_save_enabled(enabled: bool):
	"""Enable or disable auto-save"""
	auto_save_enabled = enabled

	if enabled and auto_save_timer:
		auto_save_timer.start()
		print("[SaveLoadManager] Auto-save enabled")
	elif auto_save_timer:
		auto_save_timer.stop()
		print("[SaveLoadManager] Auto-save disabled")

func get_save_info() -> Dictionary:
	"""Get information about the current save file"""
	if not has_save_file():
		return {}

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}

	var save_data = json.data
	return {
		"version": save_data.get("version", 0),
		"timestamp": save_data.get("timestamp", 0),
		"save_date": save_data.get("save_date", "Unknown"),
		"dragon_count": save_data.get("dragon_factory", {}).get("dragons", []).size() if save_data.has("dragon_factory") else 0,
		"gold": save_data.get("treasure_vault", {}).get("gold", 0) if save_data.has("treasure_vault") else 0
	}
