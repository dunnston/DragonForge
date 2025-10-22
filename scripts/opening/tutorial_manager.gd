extends Control
## Tutorial Manager
## Step-by-step interactive tutorial system for new players

# --- Tutorial Step Definition ---
class TutorialStep:
	var step_id: String
	var title: String
	var description: String
	var highlight_nodes: Array[String] = []  # Node paths to highlight
	var disable_ui: bool = true  # Disable other UI elements
	var wait_for_action: String = ""  # Action to wait for: "dragon_created", "dragon_assigned", etc.
	var custom_check: Callable  # Custom completion condition
	var on_enter: Callable  # Called when step starts
	var on_exit: Callable  # Called when step completes

# --- Configuration ---
@export var can_skip_tutorial: bool = true
@export var fade_duration: float = 0.3

# --- Node References ---
@onready var tutorial_overlay: ColorRect = $TutorialOverlay
@onready var tutorial_panel: Panel = $TutorialPanel
@onready var step_title: Label = $TutorialPanel/MarginContainer/VBoxContainer/StepTitle
@onready var step_description: RichTextLabel = $TutorialPanel/MarginContainer/VBoxContainer/StepDescription
@onready var continue_button: Button = $TutorialPanel/MarginContainer/VBoxContainer/ContinueButton
@onready var skip_checkbox: CheckBox = $TutorialPanel/MarginContainer/VBoxContainer/SkipCheckbox
@onready var highlight_arrow: Sprite2D = $HighlightArrow
@onready var spotlight: Control = $Spotlight

# --- State ---
var current_step_index: int = 0
var tutorial_steps: Array[TutorialStep] = []
var tutorial_active: bool = false
var waiting_for_action: bool = false
var factory_manager: Node = null  # Reference to main game UI

# --- Signals ---
signal tutorial_complete
signal tutorial_skipped
signal step_changed(step_index: int)


func _ready() -> void:
	# Hide tutorial UI initially
	tutorial_panel.visible = false
	tutorial_overlay.visible = false
	highlight_arrow.visible = false
	spotlight.visible = false

	# Setup skip checkbox
	skip_checkbox.visible = can_skip_tutorial
	skip_checkbox.toggled.connect(_on_skip_toggled)

	# Setup continue button
	continue_button.pressed.connect(_on_continue_pressed)

	# Initialize tutorial steps
	setup_tutorial_steps()

	# Initialize starting inventory
	initialize_starting_inventory()

	# Wait a frame for scene to fully load
	await get_tree().process_frame

	# Start tutorial
	start_tutorial()


func setup_tutorial_steps() -> void:
	"""Define all tutorial steps"""
	tutorial_steps = [
		create_step_1_create_dragon(),
		create_step_2_assign_defense(),
		create_step_3_feeding(),
		create_step_4_exploration(),
		create_step_5_resting(),
		create_step_6_scientists(),
		create_step_7_complete()
	]


# =============================================================================
# STEP DEFINITIONS
# =============================================================================

func create_step_1_create_dragon() -> TutorialStep:
	"""Step 1: Create Your First Dragon"""
	var step = TutorialStep.new()
	step.step_id = "create_dragon"
	step.title = "Create Your First Dragon"
	step.description = """Welcome to your laboratory. Let's create your first dragon.

Dragons are assembled from three parts:
• HEAD - Determines attack power
• BODY - Determines health
• TAIL - Determines speed

Click the ASSEMBLY TABLE to begin creating your first defender."""

	step.wait_for_action = "dragon_created"
	step.highlight_nodes = ["FactoryManager/CreationPanel"]

	step.on_enter = func():
		# Ensure factory manager is accessible
		if factory_manager:
			# Enable only creation UI
			pass

	return step


func create_step_2_assign_defense() -> TutorialStep:
	"""Step 2: Assign Dragon to Defense"""
	var step = TutorialStep.new()
	step.step_id = "assign_defense"
	step.title = "Assign to Defense"
	step.description = """Excellent! You've created your first dragon.

Knights will attack in waves every 5 minutes. Your dragons must defend the laboratory.

Assign your dragon to DEFENSE to protect against incoming attacks.

When knights attack, combat resolves automatically. Victories earn gold and dragon parts."""

	step.wait_for_action = "dragon_assigned_defense"
	step.highlight_nodes = ["FactoryManager/DefensePanel"]

	return step


func create_step_3_feeding() -> TutorialStep:
	"""Step 3: Dragon Needs - Feeding"""
	var step = TutorialStep.new()
	step.step_id = "feeding"
	step.title = "Feed Your Dragon"
	step.description = """Dragons are living creatures. They need care to survive.

HUNGER: Dragons lose 1% hunger per minute
• Below 50% hunger: Attack and speed penalties
• At 100% hunger: Takes starvation damage (can die!)

FATIGUE: Dragons get tired from combat and exploration
• High fatigue reduces combat effectiveness

Let's feed your dragon now to keep it strong.

Click FEED DRAGON on your dragon's card."""

	step.wait_for_action = "dragon_fed"
	step.highlight_nodes = ["FactoryManager/DragonList"]

	return step


func create_step_4_exploration() -> TutorialStep:
	"""Step 4: Send on Exploration"""
	var step = TutorialStep.new()
	step.step_id = "exploration"
	step.title = "Send Dragon Exploring"
	step.description = """Dragons can explore to find valuable resources:
• Gold
• Dragon parts
• Consumables (treats, potions, food)

IMPORTANT: Never leave your lab undefended!

Create a second dragon first, then send one exploring while the other defends.

Exploration durations:
• 15 min: Low risk, small rewards
• 30 min: Medium risk, medium rewards
• 60 min: High risk, big rewards

Dragons must be well-rested to explore safely."""

	step.wait_for_action = "exploration_started"
	step.highlight_nodes = ["FactoryManager/ExplorationPanel"]

	step.custom_check = func() -> bool:
		# Check if player has at least 2 dragons
		if DragonFactory.active_dragons.size() < 2:
			return false
		return true

	return step


func create_step_5_resting() -> TutorialStep:
	"""Step 5: Resting & Fatigue Management"""
	var step = TutorialStep.new()
	step.step_id = "resting"
	step.title = "Rest Your Dragons"
	step.description = """Notice your defending dragon's fatigue has increased.

Fatigued dragons perform poorly in combat and cannot explore.

FATIGUE RECOVERY:
• IDLE: Recovers 1% per 30 seconds
• RESTING: Recovers 4.5% per 30 seconds (fastest!)

Before logging off, always:
✓ Feed all dragons (100% hunger)
✓ Rest tired dragons (unassign from duties)
✓ Leave at least 1 dragon on defense

This ensures your dragons stay healthy while you're away."""

	step.wait_for_action = "continue"  # Manual continue

	return step


func create_step_6_scientists() -> TutorialStep:
	"""Step 6: Scientists & Automation"""
	var step = TutorialStep.new()
	step.step_id = "scientists"
	step.title = "Hire Scientists"
	step.description = """Managing many dragons is hard work. Scientists automate tasks.

AVAILABLE SCIENTISTS:

STITCHER (50 gold, 2 gold/min)
• Auto-creates dragons from available parts
• Works while you're offline

CARETAKER (100 gold, 3 gold/min)
• Auto-feeds hungry dragons
• Prevents starvation deaths

TRAINER (150 gold, 5 gold/min)
• Auto-trains dragons to level them up
• Training + treats make dragons powerful

You currently have 30 gold.

Earn more by defending against waves and exploring. Save up to hire your first scientist!"""

	step.wait_for_action = "continue"  # Manual continue
	step.highlight_nodes = ["FactoryManager/ScientistPanel"]

	return step


func create_step_7_complete() -> TutorialStep:
	"""Step 7: Tutorial Complete"""
	var step = TutorialStep.new()
	step.step_id = "complete"
	step.title = "Tutorial Complete!"
	step.description = """You're ready to run the laboratory!

REMEMBER:
✓ Create dragons to defend and explore
✓ Keep them fed and rested
✓ Hire scientists to automate work
✓ Defend against knight waves
✓ Collect all 125 dragon combinations

Your first wave arrives in 5 minutes.

The Professor believed in you. Don't let him down.

Good luck!"""

	step.wait_for_action = "continue"

	step.on_exit = func():
		complete_tutorial()

	return step


# =============================================================================
# TUTORIAL FLOW
# =============================================================================

func start_tutorial() -> void:
	"""Start the tutorial sequence"""
	tutorial_active = true
	current_step_index = 0

	# Show tutorial UI
	tutorial_panel.visible = true
	tutorial_overlay.visible = true

	# Get reference to factory manager
	factory_manager = get_tree().get_first_node_in_group("factory_manager")

	# Show first step
	show_step(0)


func show_step(step_index: int) -> void:
	"""Display a specific tutorial step"""
	if step_index < 0 or step_index >= tutorial_steps.size():
		return

	var step = tutorial_steps[step_index]
	current_step_index = step_index

	# Update UI
	step_title.text = step.title
	step_description.text = step.description

	# Show/hide continue button based on wait condition
	if step.wait_for_action == "continue":
		continue_button.visible = true
		waiting_for_action = false
	else:
		continue_button.visible = false
		waiting_for_action = true

	# Apply highlights
	apply_highlights(step.highlight_nodes)

	# Call on_enter callback
	if step.on_enter:
		step.on_enter.call()

	# Emit step changed signal
	step_changed.emit(step_index)

	# Setup action listener
	if step.wait_for_action != "" and step.wait_for_action != "continue":
		setup_action_listener(step.wait_for_action)


func next_step() -> void:
	"""Advance to the next tutorial step"""
	var current_step = tutorial_steps[current_step_index]

	# Call on_exit callback
	if current_step.on_exit:
		current_step.on_exit.call()

	# Clear highlights
	clear_highlights()

	# Move to next step
	current_step_index += 1

	if current_step_index >= tutorial_steps.size():
		# Tutorial complete
		complete_tutorial()
	else:
		# Show next step
		show_step(current_step_index)


func complete_tutorial() -> void:
	"""Complete the tutorial and transition to main game"""
	tutorial_active = false

	# Save tutorial completion
	save_tutorial_completion()

	# Hide tutorial UI
	tutorial_panel.visible = false
	tutorial_overlay.visible = false

	# Emit completion signal
	tutorial_complete.emit()

	# Transition to main game
	get_tree().change_scene_to_file("res://scenes/main_scene/main_scene.tscn")


func skip_tutorial() -> void:
	"""Skip the tutorial entirely"""
	tutorial_active = false

	# Save tutorial as skipped
	save_tutorial_completion()

	# Emit skipped signal
	tutorial_skipped.emit()

	# Transition to main game
	get_tree().change_scene_to_file("res://scenes/main_scene/main_scene.tscn")


# =============================================================================
# ACTION LISTENERS
# =============================================================================

func setup_action_listener(action: String) -> void:
	"""Setup listeners for specific game actions"""
	match action:
		"dragon_created":
			if not DragonFactory.dragon_created.is_connected(_on_dragon_created):
				DragonFactory.dragon_created.connect(_on_dragon_created)

		"dragon_assigned_defense":
			if not DefenseManager.dragon_assigned.is_connected(_on_dragon_assigned_defense):
				DefenseManager.dragon_assigned.connect(_on_dragon_assigned_defense)

		"dragon_fed":
			# Connect to inventory change (food consumed)
			if not InventoryManager.item_removed.is_connected(_on_item_used):
				InventoryManager.item_removed.connect(_on_item_used)

		"exploration_started":
			if not ExplorationManager.exploration_started.is_connected(_on_exploration_started):
				ExplorationManager.exploration_started.connect(_on_exploration_started)


func _on_dragon_created(dragon: Dragon) -> void:
	"""Called when a dragon is created"""
	if waiting_for_action and tutorial_steps[current_step_index].wait_for_action == "dragon_created":
		next_step()


func _on_dragon_assigned_defense(dragon: Dragon) -> void:
	"""Called when a dragon is assigned to defense"""
	if waiting_for_action and tutorial_steps[current_step_index].wait_for_action == "dragon_assigned_defense":
		next_step()


func _on_item_used(item_id: String, quantity: int) -> void:
	"""Called when an item is used/consumed"""
	if waiting_for_action and tutorial_steps[current_step_index].wait_for_action == "dragon_fed":
		if item_id == "food":
			next_step()


func _on_exploration_started(dragon: Dragon, duration: int) -> void:
	"""Called when exploration starts"""
	if waiting_for_action and tutorial_steps[current_step_index].wait_for_action == "exploration_started":
		# Check if player has 2+ dragons (custom check)
		var step = tutorial_steps[current_step_index]
		if step.custom_check and step.custom_check.call():
			next_step()


# =============================================================================
# UI HELPERS
# =============================================================================

func apply_highlights(node_paths: Array[String]) -> void:
	"""Highlight specific UI elements"""
	# Clear previous highlights
	clear_highlights()

	# Apply new highlights
	for path in node_paths:
		var node = get_node_or_null(path)
		if node:
			# Add visual highlight (you can customize this)
			create_spotlight(node)
			create_arrow(node)


func clear_highlights() -> void:
	"""Remove all highlights"""
	spotlight.visible = false
	highlight_arrow.visible = false


func create_spotlight(target_node: Node) -> void:
	"""Create a spotlight effect on a node"""
	if not target_node is Control:
		return

	spotlight.visible = true
	spotlight.position = target_node.global_position
	spotlight.size = target_node.size


func create_arrow(target_node: Node) -> void:
	"""Create an arrow pointing to a node"""
	if not target_node is Control:
		return

	highlight_arrow.visible = true
	highlight_arrow.global_position = target_node.global_position + Vector2(-50, -50)


# =============================================================================
# STARTING INVENTORY
# =============================================================================

func initialize_starting_inventory() -> void:
	"""Initialize starting gold and dragon parts"""
	# Set starting gold
	TreasureVault.add_gold(30)

	# Generate 6 random starting parts with constraints
	var parts_to_add = generate_starting_parts()

	# Add parts to inventory
	for part in parts_to_add:
		InventoryManager.add_item_by_id(part, 1)


func generate_starting_parts() -> Array[String]:
	"""Generate 6 starting parts with at least 1 of each type"""
	var parts: Array[String] = []
	var elements = ["fire", "ice", "lightning", "nature", "shadow"]
	var part_types = ["head", "body", "tail"]

	# Ensure at least one of each type
	for part_type in part_types:
		var random_element = elements[randi() % elements.size()]
		parts.append(random_element + "_" + part_type)

	# Add 3 more random parts
	for i in range(3):
		var random_element = elements[randi() % elements.size()]
		var random_type = part_types[randi() % part_types.size()]
		parts.append(random_element + "_" + random_type)

	return parts


# =============================================================================
# SAVE/LOAD
# =============================================================================

func save_tutorial_completion() -> void:
	"""Save that the tutorial has been completed"""
	var save_data = {
		"tutorial_completed": true,
		"completed_at": Time.get_unix_time_from_system()
	}

	var save_file = FileAccess.open("user://tutorial_save.json", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()


func is_tutorial_completed() -> bool:
	"""Check if tutorial has been completed before"""
	if not FileAccess.file_exists("user://tutorial_save.json"):
		return false

	var save_file = FileAccess.open("user://tutorial_save.json", FileAccess.READ)
	if not save_file:
		return false

	var json_string = save_file.get_as_text()
	save_file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result == OK:
		var data = json.get_data()
		return data.get("tutorial_completed", false)

	return false


# =============================================================================
# SIGNALS
# =============================================================================

func _on_continue_pressed() -> void:
	"""Continue button pressed"""
	next_step()


func _on_skip_toggled(enabled: bool) -> void:
	"""Skip checkbox toggled"""
	if enabled:
		skip_tutorial()
