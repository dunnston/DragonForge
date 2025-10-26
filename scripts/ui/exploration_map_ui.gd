extends Control
class_name ExplorationMapUI

# Scene reference
const TravelingDragonScene = preload("res://scenes/exploration/traveling_dragon.tscn")

# UI components
@onready var map_image: TextureRect = $MapImage
@onready var dragons_layer: Node2D = $MapImage/DragonsLayer
@onready var active_label: Label = $UIOverlay/TopBar/ActiveExpeditionsLabel
@onready var close_button: Button = $UIOverlay/BottomPanel/CloseButton
@onready var title_label: Label = $UIOverlay/TopBar/TitleLabel
@onready var dragon_selector: ExplorationDragonSelector = $ExplorationDragonSelector

# Energy Tonic UI (created programmatically)
var energy_tonic_button: Button
var energy_tonic_label: Label
var energy_tonic_timer_label: Label

# Location button areas
@onready var ancient_forest_button: Button = $MapImage/LocationButtons/AncientForest/ClickArea
@onready var ancient_forest_label: Label = $MapImage/LocationButtons/AncientForest/HoverLabel
@onready var frozen_tundra_button: Button = $MapImage/LocationButtons/FrozenTundra/ClickArea
@onready var frozen_tundra_label: Label = $MapImage/LocationButtons/FrozenTundra/HoverLabel
@onready var thunder_peak_button: Button = $MapImage/LocationButtons/TunderPeak/ClickArea
@onready var thunder_peak_label: Label = $MapImage/LocationButtons/TunderPeak/HoverLabel
@onready var volcanic_caves_button: Button = $MapImage/LocationButtons/VolcanicCaves/ClickArea
@onready var volcanic_caves_label: Label = $MapImage/LocationButtons/VolcanicCaves/HoverLabel

# Location markers (start and end points)
@onready var forest_start: Sprite2D = $MapImage/Markers/ForestStart
@onready var forest_end: Sprite2D = $MapImage/Markers/ForestEnd
@onready var tundra_start: Sprite2D = $MapImage/Markers/TundraStart
@onready var tundra_end: Sprite2D = $MapImage/Markers/TundraEnd
@onready var thunder_start: Sprite2D = $MapImage/Markers/ThuderPeakStart
@onready var thunder_end: Sprite2D = $MapImage/Markers/ThuderPeakEnd
@onready var volcanic_start: Sprite2D = $MapImage/Markers/VolcanicCavesStart
@onready var volcanic_end: Sprite2D = $MapImage/Markers/VolcanicCavesEnd

# Map constants - will be populated with actual positions in _ready()
var DESTINATIONS = {}

# Active traveling dragons
var active_traveling_dragons: Dictionary = {}  # dragon_id -> TravelingDragon node

# Dragon factory reference
var dragon_factory: DragonFactory

# Pending selection state
var pending_destination_key: String
var pending_destination_info: Dictionary

# Signals
signal back_to_factory_requested
signal expedition_started(dragon_id: String, destination: String)

func _ready():
	print("[ExplorationMapUI] Initializing")

	# Initialize destinations with actual marker positions
	_initialize_destinations()

	# Connect location button signals
	if ancient_forest_button:
		ancient_forest_button.pressed.connect(_on_location_clicked.bind("ancient_forest"))
		ancient_forest_button.mouse_entered.connect(_on_location_hover.bind(ancient_forest_label, true))
		ancient_forest_button.mouse_exited.connect(_on_location_hover.bind(ancient_forest_label, false))
	if frozen_tundra_button:
		frozen_tundra_button.pressed.connect(_on_location_clicked.bind("frozen_tundra"))
		frozen_tundra_button.mouse_entered.connect(_on_location_hover.bind(frozen_tundra_label, true))
		frozen_tundra_button.mouse_exited.connect(_on_location_hover.bind(frozen_tundra_label, false))
	if thunder_peak_button:
		thunder_peak_button.pressed.connect(_on_location_clicked.bind("thunder_peak"))
		thunder_peak_button.mouse_entered.connect(_on_location_hover.bind(thunder_peak_label, true))
		thunder_peak_button.mouse_exited.connect(_on_location_hover.bind(thunder_peak_label, false))
	if volcanic_caves_button:
		volcanic_caves_button.pressed.connect(_on_location_clicked.bind("volcanic_caves"))
		volcanic_caves_button.mouse_entered.connect(_on_location_hover.bind(volcanic_caves_label, true))
		volcanic_caves_button.mouse_exited.connect(_on_location_hover.bind(volcanic_caves_label, false))

	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Connect dragon selector signals
	if dragon_selector:
		dragon_selector.dragon_selected.connect(_on_dragon_selector_confirmed)
		dragon_selector.cancelled.connect(_on_dragon_selector_cancelled)
		dragon_selector.visible = false  # Hide by default

	# Connect to ExplorationManager signals
	if ExplorationManager and ExplorationManager.instance:
		ExplorationManager.instance.exploration_started.connect(_on_exploration_started)
		ExplorationManager.instance.exploration_completed.connect(_on_exploration_completed)
		ExplorationManager.instance.energy_tonic_activated.connect(_on_energy_tonic_activated)
		ExplorationManager.instance.energy_tonic_expired.connect(_on_energy_tonic_expired)
		print("[ExplorationMapUI] Connected to ExplorationManager")
	else:
		push_error("[ExplorationMapUI] ExplorationManager not found!")

	# Create energy tonic UI
	_create_energy_tonic_ui()

	# Load any in-progress explorations
	_load_active_explorations()

	# Update UI
	_update_active_count()
	_update_energy_tonic_ui()

func _initialize_destinations():
	"""Initialize destination data with actual marker positions from the scene"""
	DESTINATIONS = {
		"ancient_forest": {
			"start_position": forest_start.position if forest_start else Vector2(299, 316),
			"end_position": forest_end.position if forest_end else Vector2(192, 251),
			"name": "Ancient Forest",
			"element": "Nature",
			"duration_minutes": 5,
			"color": Color(0.2, 1.0, 0.2)
		},
		"frozen_tundra": {
			"start_position": tundra_start.position if tundra_start else Vector2(467, 362),
			"end_position": tundra_end.position if tundra_end else Vector2(523, 205),
			"name": "Frozen Tundra",
			"element": "Ice",
			"duration_minutes": 10,
			"color": Color(0.3, 0.8, 1.0)
		},
		"thunder_peak": {
			"start_position": thunder_start.position if thunder_start else Vector2(518, 450),
			"end_position": thunder_end.position if thunder_end else Vector2(842, 262),
			"name": "Thunder Peak",
			"element": "Lightning",
			"duration_minutes": 15,
			"color": Color(1.0, 1.0, 0.2)
		},
		"volcanic_caves": {
			"start_position": volcanic_start.position if volcanic_start else Vector2(530, 519),
			"end_position": volcanic_end.position if volcanic_end else Vector2(808, 520),
			"name": "Volcanic Caves",
			"element": "Fire",
			"duration_minutes": 1,
			"color": Color(1.0, 0.3, 0.0)
		}
	}
	print("[ExplorationMapUI] Destinations initialized with marker positions")

func set_dragon_factory(factory: DragonFactory):
	"""Set the dragon factory reference"""
	dragon_factory = factory
	print("[ExplorationMapUI] Dragon factory set")

func _load_active_explorations():
	"""Load any dragons currently exploring and spawn them on the map"""
	if not ExplorationManager or not ExplorationManager.instance:
		return

	var active_explorations = ExplorationManager.instance.get_active_explorations()
	print("[ExplorationMapUI] Loading %d active explorations" % active_explorations.size())

	for exploration in active_explorations:
		var dragon = exploration.get("dragon")
		var destination = exploration.get("destination")

		if dragon and destination:
			_spawn_traveling_dragon_from_existing(dragon, destination, exploration)

func _spawn_traveling_dragon_from_existing(dragon: Dragon, destination: String, exploration_data: Dictionary):
	"""Spawn a dragon that's already exploring (for loading saved state)"""
	if not DESTINATIONS.has(destination):
		push_error("[ExplorationMapUI] Unknown destination: %s" % destination)
		return

	var dest_info = DESTINATIONS[destination]
	var dragon_dict = {
		"id": dragon.dragon_id,
		"name": dragon.dragon_name,
		"level": dragon.level,
		"element": DragonPart.Element.keys()[dragon.head_part.element]
	}

	# Get exploration details - use ACTUAL duration from exploration_data (accounts for tonic)
	var start_time = exploration_data.get("start_time", 0)
	var actual_duration_seconds = exploration_data.get("duration", dest_info["duration_minutes"] * 60)

	# Calculate remaining time
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - start_time
	var remaining = actual_duration_seconds - elapsed

	# Safety check: Skip if exploration is almost complete (< 8 seconds remaining)
	# This prevents visual glitches from very short animation durations
	if remaining < 8:
		print("[ExplorationMapUI] Skipping existing exploration - too close to completion (%.1fs remaining, need 8+)" % remaining)
		return

	# Spawn the traveling dragon
	var traveling_dragon = TravelingDragonScene.instantiate()

	dragons_layer.add_child(traveling_dragon)

	# Setup with existing progress
	traveling_dragon.dragon_data = dragon_dict
	traveling_dragon.destination_key = destination
	traveling_dragon.start_position = dest_info["start_position"]
	traveling_dragon.end_position = dest_info["end_position"]
	traveling_dragon.start_time = start_time
	traveling_dragon.duration_seconds = actual_duration_seconds

	print("[ExplorationMapUI] Loading existing exploration with ACTUAL duration: %d seconds" % actual_duration_seconds)

	# Calculate current position based on elapsed time (round-trip logic)
	# (current_time and elapsed already calculated above for safety check)
	var progress = float(elapsed) / float(traveling_dragon.duration_seconds)
	progress = clamp(progress, 0.0, 1.0)

	# Determine if outbound or returning (halfway point at 0.5)
	var current_pos: Vector2
	if progress < 0.5:
		# Outbound: start -> end
		var outbound_progress = progress * 2.0  # 0.0 to 1.0
		current_pos = dest_info["start_position"].lerp(dest_info["end_position"], outbound_progress)
		traveling_dragon.is_outbound = true
	else:
		# Return: end -> start
		var return_progress = (progress - 0.5) * 2.0  # 0.0 to 1.0
		current_pos = dest_info["end_position"].lerp(dest_info["start_position"], return_progress)
		traveling_dragon.is_outbound = false

	traveling_dragon.position = current_pos

	# Update appearance
	if traveling_dragon.dragon_sprite:
		traveling_dragon._setup_sprite_appearance()
	if traveling_dragon.name_label:
		traveling_dragon.name_label.text = dragon_dict["name"]
	if traveling_dragon.trail_particles:
		traveling_dragon._setup_particles()

	# Connect signals
	traveling_dragon.exploration_complete.connect(_on_traveling_dragon_complete)

	# Store reference
	active_traveling_dragons[dragon.dragon_id] = traveling_dragon

	print("[ExplorationMapUI] Loaded traveling dragon: %s to %s (%.1f%% complete)" % [
		dragon.dragon_name,
		destination,
		progress * 100
	])

func spawn_traveling_dragon(dragon: Dictionary, destination_key: String):
	"""
	Creates a traveling dragon on the map using default duration
	Args:
		dragon: Dictionary with {id, name, level, element}
		destination_key: One of the DESTINATIONS keys
	"""
	if not DESTINATIONS.has(destination_key):
		push_error("[ExplorationMapUI] Unknown destination: %s" % destination_key)
		return

	var dest_info = DESTINATIONS[destination_key]
	var duration_seconds = dest_info["duration_minutes"] * 60
	spawn_traveling_dragon_with_duration(dragon, destination_key, duration_seconds)

func spawn_traveling_dragon_with_duration(dragon: Dictionary, destination_key: String, duration_seconds: int):
	"""
	Creates a traveling dragon on the map with specific duration
	Args:
		dragon: Dictionary with {id, name, level, element}
		destination_key: One of the DESTINATIONS keys
		duration_seconds: Actual duration in seconds (may be affected by tonic)
	"""
	# Call the new function with current time as start_time
	spawn_traveling_dragon_with_timing(dragon, destination_key, Time.get_unix_time_from_system(), duration_seconds)

func spawn_traveling_dragon_with_timing(dragon: Dictionary, destination_key: String, start_time: float, duration_seconds: int):
	"""
	Creates a traveling dragon on the map with specific start time and duration
	Args:
		dragon: Dictionary with {id, name, level, element}
		destination_key: One of the DESTINATIONS keys
		start_time: Unix timestamp when exploration started (from ExplorationManager)
		duration_seconds: Actual duration in seconds (may be affected by tonic)
	"""
	if not DESTINATIONS.has(destination_key):
		push_error("[ExplorationMapUI] Unknown destination: %s" % destination_key)
		return

	var dest_info = DESTINATIONS[destination_key]

	var traveling_dragon = TravelingDragonScene.instantiate()
	dragons_layer.add_child(traveling_dragon)

	# Setup the dragon directly with the exact timing from ExplorationManager
	traveling_dragon.dragon_data = dragon
	traveling_dragon.destination_key = destination_key
	traveling_dragon.start_position = dest_info["start_position"]
	traveling_dragon.end_position = dest_info["end_position"]
	traveling_dragon.start_time = start_time  # Use ExplorationManager's start_time
	traveling_dragon.duration_seconds = duration_seconds  # Use ExplorationManager's duration
	traveling_dragon.position = dest_info["start_position"]

	# Setup visuals
	if traveling_dragon.dragon_sprite:
		traveling_dragon._setup_sprite_appearance()
	if traveling_dragon.name_label:
		traveling_dragon.name_label.text = dragon.get("name", "Dragon")

	# Start the animation (deferred to ensure scene is ready)
	traveling_dragon.call_deferred("_animate_round_trip")

	# Connect signal
	traveling_dragon.exploration_complete.connect(_on_traveling_dragon_complete)

	# Store reference
	active_traveling_dragons[dragon.id] = traveling_dragon

	_update_active_count()

	print("[ExplorationMapUI] Spawned traveling dragon: %s -> %s (%d seconds, synced with ExplorationManager)" % [dragon.name, destination_key, duration_seconds])

func remove_traveling_dragon(dragon_id: String):
	"""Remove a traveling dragon from the map"""
	if active_traveling_dragons.has(dragon_id):
		var dragon_node = active_traveling_dragons[dragon_id]
		dragon_node.queue_free()
		active_traveling_dragons.erase(dragon_id)
		_update_active_count()
		print("[ExplorationMapUI] Removed traveling dragon: %s" % dragon_id)

func _on_exploration_started(dragon: Dragon, destination: String):
	"""Called when ExplorationManager starts a new exploration"""
	print("[ExplorationMapUI] Exploration started: %s -> %s" % [dragon.dragon_name, destination])

	var dragon_dict = {
		"id": dragon.dragon_id,
		"name": dragon.dragon_name,
		"level": dragon.level,
		"element": DragonPart.Element.keys()[dragon.head_part.element]
	}

	# Get the ACTUAL exploration duration AND start time from ExplorationManager (accounts for tonic)
	var actual_duration_seconds = 0
	var actual_start_time = 0
	if ExplorationManager and ExplorationManager.instance:
		var explorations = ExplorationManager.instance.get_active_explorations()
		for exploration_data in explorations:
			var exploring_dragon = exploration_data.get("dragon")
			if exploring_dragon and exploring_dragon.dragon_id == dragon.dragon_id:
				actual_duration_seconds = exploration_data["duration"]
				actual_start_time = exploration_data["start_time"]
				print("[ExplorationMapUI] Found actual duration: %d seconds, start_time: %d (accounts for tonic)" % [actual_duration_seconds, actual_start_time])
				break

	# Safety check: Only spawn visual dragon if exploration has reasonable duration
	# Very short explorations (< 8 seconds) can cause visual glitches due to scene setup delays
	# This is especially important when energy tonic is active (4x speed = 1/4 duration)
	if actual_duration_seconds < 8:
		print("[ExplorationMapUI] Skipping visual spawn - exploration too short (%d seconds, need 8+)" % actual_duration_seconds)
		print("[ExplorationMapUI] Dragon will complete exploration silently (you'll still get rewards!)")
		return

	spawn_traveling_dragon_with_timing(dragon_dict, destination, actual_start_time, actual_duration_seconds)

func _on_exploration_completed(dragon: Dragon, destination: String, rewards: Dictionary):
	"""Called when ExplorationManager completes an exploration"""
	print("[ExplorationMapUI] Exploration completed: %s from %s" % [dragon.dragon_name, destination])

	# The traveling dragon will emit its own signal when the return animation completes
	# We don't remove it here - let the animation finish first

func _on_traveling_dragon_complete(dragon_data: Dictionary):
	"""Called when a traveling dragon completes its return animation"""
	print("[ExplorationMapUI] Traveling dragon returned: %s" % dragon_data.get("name", "Unknown"))

	# Remove from active list
	var dragon_id = dragon_data.get("id", "")
	if dragon_id and active_traveling_dragons.has(dragon_id):
		active_traveling_dragons.erase(dragon_id)
		_update_active_count()

func _update_active_count():
	"""Update the active expeditions label"""
	var count = active_traveling_dragons.size()
	if active_label:
		active_label.text = "%d dragon%s exploring" % [count, "s" if count != 1 else ""]

func get_destination_info(dest_key: String) -> Dictionary:
	"""Get information about a destination"""
	return DESTINATIONS.get(dest_key, {})

func get_all_destinations() -> Dictionary:
	"""Get all available destinations"""
	return DESTINATIONS

func _on_close_pressed():
	"""Handle close button press"""
	print("[ExplorationMapUI] Close button pressed")
	back_to_factory_requested.emit()

func _on_location_hover(label: Label, show: bool):
	"""Handle hovering over a location - show/hide tooltip"""
	if label:
		label.visible = show

func _on_location_clicked(destination_key: String):
	"""Handle location button press - show dragon selection dialog"""
	print("[ExplorationMapUI] Location clicked: %s" % destination_key)

	var destination_info = DESTINATIONS.get(destination_key)
	if not destination_info:
		push_error("[ExplorationMapUI] Unknown destination: %s" % destination_key)
		return

	# Get available dragons
	var available_dragons = _get_available_dragons()

	if available_dragons.is_empty():
		_show_error_dialog("No Available Dragons", "All dragons are either exploring, dead, or too fatigued (>50%).\n\nWait for dragons to return or rest them before sending on expeditions.")
		return

	# Show dragon selection dialog
	_show_dragon_selection_dialog(destination_key, destination_info, available_dragons)

func _show_dragon_selection_dialog(destination_key: String, destination_info: Dictionary, available_dragons: Array):
	"""Show the visual dragon selector modal"""
	if not dragon_selector:
		push_error("[ExplorationMapUI] Dragon selector not found!")
		return

	# Store for callback
	pending_destination_key = destination_key
	pending_destination_info = destination_info

	# Show the visual selector
	dragon_selector.show_for_destination(destination_key, destination_info, available_dragons)

func _on_dragon_selector_confirmed(selected_dragon: Dragon):
	"""Called when a dragon is selected from the visual selector"""
	print("[ExplorationMapUI] Dragon selector confirmed: %s" % selected_dragon.dragon_name)
	_start_exploration_for_dragon(selected_dragon, pending_destination_key, pending_destination_info)

func _on_dragon_selector_cancelled():
	"""Called when dragon selector is cancelled"""
	print("[ExplorationMapUI] Dragon selector cancelled")

func _start_exploration_for_dragon(dragon: Dragon, destination_key: String, destination_info: Dictionary):
	"""Start an exploration for the selected dragon"""
	if not ExplorationManager or not ExplorationManager.instance:
		_show_error_dialog("Error", "ExplorationManager not found!")
		return

	# Check if this is a pet dragon with affection restrictions
	if dragon is PetDragon:
		if not dragon.can_explore_destination(destination_key):
			var tier = dragon.get_affection_tier()
			var next_unlock = dragon.get_next_unlock_destination()
			var error_msg = "Your pet cannot explore this area yet!\n\n"
			error_msg += "Current Bond: %s\n" % tier
			if next_unlock:
				error_msg += "Next unlock: %s (needs %d affection)" % [next_unlock["destination"].capitalize().replace("_", " "), next_unlock["affection_required"]]
			_show_error_dialog("Area Locked", error_msg)
			return

	# Start the exploration through the manager
	var duration_minutes = destination_info["duration_minutes"]
	if ExplorationManager.instance.start_exploration(dragon, duration_minutes, destination_key):
		print("[ExplorationMapUI] Started exploration for %s to %s (%d min)" % [
			dragon.dragon_name,
			destination_info["name"],
			duration_minutes
		])
	else:
		_show_error_dialog("Cannot Explore", "Dragon cannot explore right now.\nCheck fatigue level and current state.")

func _get_available_dragons() -> Array:
	"""Get list of dragons that can be sent exploring"""
	var available: Array = []

	if not dragon_factory:
		return available

	var all_dragons = dragon_factory.get_all_dragons()
	for dragon in all_dragons:
		# Check if dragon can explore
		if dragon.is_dead:
			continue
		if dragon.current_state == Dragon.DragonState.EXPLORING:
			continue
		if dragon.fatigue_level > 0.5:  # Too tired
			continue

		available.append(dragon)

	return available

func _show_error_dialog(title: String, message: String):
	"""Show a simple error dialog"""
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.title = title
	dialog.dialog_text = message
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.popup_centered()

# === ENERGY TONIC UI ===

func _create_energy_tonic_ui():
	"""Create the energy tonic button and status display"""
	# Find or create the top bar to add the button
	var top_bar = $UIOverlay/TopBar
	if not top_bar:
		print("[ExplorationMapUI] WARNING: TopBar not found, can't create energy tonic UI")
		return

	# Create Energy Tonic button
	energy_tonic_button = Button.new()
	energy_tonic_button.name = "EnergyTonicButton"
	energy_tonic_button.text = "Use Energy Tonic"
	energy_tonic_button.custom_minimum_size = Vector2(150, 40)
	energy_tonic_button.pressed.connect(_on_energy_tonic_button_pressed)
	top_bar.add_child(energy_tonic_button)

	# Create count label
	energy_tonic_label = Label.new()
	energy_tonic_label.name = "EnergyTonicLabel"
	energy_tonic_label.text = "Tonics: 0"
	top_bar.add_child(energy_tonic_label)

	# Create timer label
	energy_tonic_timer_label = Label.new()
	energy_tonic_timer_label.name = "EnergyTonicTimerLabel"
	energy_tonic_timer_label.text = ""
	energy_tonic_timer_label.visible = false
	top_bar.add_child(energy_tonic_timer_label)

	# Add a timer to update the display every second
	var update_timer = Timer.new()
	update_timer.wait_time = 1.0
	update_timer.timeout.connect(_update_energy_tonic_ui)
	update_timer.autostart = true
	add_child(update_timer)

func _update_energy_tonic_ui():
	"""Update the energy tonic button and status display"""
	if not energy_tonic_button or not energy_tonic_label:
		return

	# Get tonic count from inventory
	var tonic_count = 0
	if InventoryManager and InventoryManager.instance:
		tonic_count = InventoryManager.instance.get_item_count("energy_tonic")

	# Update count label
	energy_tonic_label.text = "Tonics: %d" % tonic_count

	# Check if tonic is active
	var is_active = false
	var time_remaining = 0.0
	if ExplorationManager and ExplorationManager.instance:
		is_active = ExplorationManager.instance.is_energy_tonic_active()
		time_remaining = ExplorationManager.instance.get_energy_tonic_time_remaining()

	# Update button state
	if is_active:
		energy_tonic_button.disabled = true
		energy_tonic_button.text = "Tonic Active"
		energy_tonic_timer_label.visible = true
		energy_tonic_timer_label.text = "Boost: %ds remaining" % int(time_remaining)
	else:
		energy_tonic_button.disabled = (tonic_count <= 0)
		energy_tonic_button.text = "Use Energy Tonic (4x speed)"
		energy_tonic_timer_label.visible = false

func _on_energy_tonic_button_pressed():
	"""Handle energy tonic button press"""
	if not ExplorationManager or not ExplorationManager.instance:
		_show_error_dialog("Error", "ExplorationManager not found!")
		return

	if ExplorationManager.instance.consume_energy_tonic():
		print("[ExplorationMapUI] Energy Tonic consumed!")
		_update_energy_tonic_ui()
	else:
		_show_error_dialog("Cannot Use Tonic", "Either you have no tonics, or one is already active!")

func _on_energy_tonic_activated(duration: float):
	"""Called when energy tonic is activated - update UI and traveling dragon animations"""
	_update_energy_tonic_ui()

	# Update all traveling dragons with new timing from ExplorationManager
	if ExplorationManager and ExplorationManager.instance:
		for dragon_id in active_traveling_dragons.keys():
			var traveling_dragon = active_traveling_dragons[dragon_id]

			# Get updated exploration data from manager
			var explorations = ExplorationManager.instance.get_active_explorations()
			for exploration_data in explorations:
				var exploring_dragon = exploration_data.get("dragon")
				if exploring_dragon and exploring_dragon.dragon_id == dragon_id:
					# Update the traveling dragon's timing to match the sped-up exploration
					var new_start_time = exploration_data["start_time"]
					var new_duration = exploration_data["duration"]
					traveling_dragon.update_timing(new_start_time, new_duration)
					print("[ExplorationMapUI] Updated traveling dragon animation for: %s" % dragon_id)
					break

func _on_energy_tonic_expired():
	"""Called when energy tonic expires"""
	_update_energy_tonic_ui()
