# Factory Manager - Main UI for Dragon Factory Management
extends Control

# === PRELOADS ===
const WaveResultPopupScene = preload("res://scenes/ui/wave_result_popup.tscn")

# === SYSTEMS ===
var factory: DragonFactory
var scientist_manager: ScientistManager

# === UI ELEMENTS - Top Bar ===
@onready var gold_label: Label = $MarginContainer/MainVBox/TopBar/GoldDisplay/HBox/GoldLabel
@onready var view_inventory_button: Button = $MarginContainer/MainVBox/TopBar/ViewInventoryButton
@onready var view_freezer_button: Button = $MarginContainer/MainVBox/TopBar/ViewFreezerButton
@onready var manage_defenses_button: Button = $MarginContainer/MainVBox/TopBar/ManageDefensesButton
@onready var manage_training_button: Button = $MarginContainer/MainVBox/TopBar/ManageTrainingButton
@onready var exploration_map_button: Button = $MarginContainer/MainVBox/TopBar/ExplorationMapButton
@onready var manage_scientists_button: Button = $MarginContainer/MainVBox/TopBar/ManageScientistsButton

@onready var fire_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/FireParts/Count
@onready var ice_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/IceParts/Count
@onready var lightning_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/LightningParts/Count
@onready var nature_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/NatureParts/Count
@onready var shadow_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/ShadowParts/Count

# === UI ELEMENTS - Scientists ===
@onready var stitcher_panel = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/ScrollContainer/ScientistsList/StitcherPanel
@onready var caretaker_panel = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/ScrollContainer/ScientistsList/CaretakerPanel
@onready var trainer_panel = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/ScrollContainer/ScientistsList/TrainerPanel
@onready var hire_modal = $ScientistHireModal

# === UI ELEMENTS - Dragon Creation ===
@onready var head_slot_label: Label = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/HeadSlot/VBox/SlotRect/PartLabel
@onready var body_slot_label: Label = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/BodySlot/VBox/SlotRect/PartLabel
@onready var tail_slot_label: Label = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/TailSlot/VBox/SlotRect/PartLabel
@onready var animate_button: Button = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/AnimateButton

@onready var head_slot_icon: TextureRect = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/HeadSlot/VBox/SlotRect/PartIcon
@onready var body_slot_icon: TextureRect = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/BodySlot/VBox/SlotRect/PartIcon
@onready var tail_slot_icon: TextureRect = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/TailSlot/VBox/SlotRect/PartIcon

@onready var head_slot_panel: PanelContainer = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/HeadSlot
@onready var body_slot_panel: PanelContainer = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/BodySlot
@onready var tail_slot_panel: PanelContainer = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/TailSlot

@onready var head_slot_rect: ColorRect = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/HeadSlot/VBox/SlotRect
@onready var body_slot_rect: ColorRect = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/BodySlot/VBox/SlotRect
@onready var tail_slot_rect: ColorRect = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/TailSlot/VBox/SlotRect

# === UI ELEMENTS - Dragons List ===
@onready var dragons_list: VBoxContainer = $MarginContainer/MainVBox/MainContent/RightPanel/DragonsVBox/ScrollContainer/DragonsList
@onready var dragon_grounds_button: Button = $MarginContainer/MainVBox/MainContent/RightPanel/DragonsVBox/DragonGroundsButton

# === UI ELEMENTS - Bottom Bar ===
@onready var wave_label: Label = $MarginContainer/MainVBox/BottomBar/DefensePanel/VBox/HBox/WaveLabel
@onready var timer_label: Label = $MarginContainer/MainVBox/BottomBar/DefensePanel/VBox/TimerLabel
@onready var defenders_label: Label = $MarginContainer/MainVBox/BottomBar/DefensePanel/VBox/DefendersLabel
@onready var battle_notification_panel: PanelContainer = %BattleNotificationPanel
@onready var battle_label: Label = %BattleLabel
@onready var watch_battle_button: Button = %WatchBattleButton
@onready var active_missions_label: Label = $MarginContainer/MainVBox/BottomBar/ExplorationPanel/VBox/ActiveLabel
@onready var collection_progress: Label = $MarginContainer/MainVBox/BottomBar/CollectionPanel/VBox/ProgressLabel
@onready var view_collection_button: Button = $MarginContainer/MainVBox/BottomBar/CollectionPanel/VBox/ViewButton

# === DEFENSE SLOTS (created dynamically) ===
var defense_slot_container: HBoxContainer
var defense_slots: Array[Label] = []

# === BATTLE ARENA ===
var battle_arena: Control = null  # Reference to the battle arena UI

# === SCOUT NOTIFICATION ===
var scouted_enemies: Array = []  # Enemies for the incoming wave
var scouted_wave_number: int = 0  # Wave number for scouting
var enemy_scout_screen: Control = null  # Reference to the enemy scout screen

# === UI PANELS ===
@onready var inventory_panel: Control = $InventoryPanel
@onready var part_selector: Control = $PartSelector
@onready var dragon_tooltip: Control = $DragonTooltip
@onready var dragon_details_modal: Control = $DragonDetailsModal
@onready var dragon_grounds_modal: DragonGroundsModal = $DragonGroundsModal
@onready var save_exit_popup: Control = $SaveExitPopup

# Defense Towers UI (created dynamically)
var defense_towers_ui: DefenseTowersUI

# Training Grounds UI (created dynamically)
var training_yard_ui: TrainingYardUI

# Exploration Map UI (created dynamically)
var exploration_map_ui: ExplorationMapUI

# Scientist Management UI (created dynamically)
var scientist_management_ui: Control

# === PET SYSTEM STATE ===
var pet_ui_setup_complete: bool = false  # Track if pet UI is already set up
var walking_pet_character: Node = null  # Reference to the walking pet character

# === BATTLE STATE ===
var pending_wave_result: Dictionary = {}  # Store wave result to show after animation

# === DRAGON CREATION STATE ===
var selected_head_id: String = ""
var selected_body_id: String = ""
var selected_tail_id: String = ""
var current_selecting_slot: String = ""  # Track which slot is being selected

# === ANIMATION STATE ===
const ANIMATION_DURATION: float = 5.0  # 5 seconds to animate
var is_animating: bool = false
var animation_progress: float = 0.0
var animation_timer: Timer
var animation_progress_bar: ProgressBar
var animation_label: Label
# Store parts for creation after animation
var pending_head_part: DragonPart
var pending_body_part: DragonPart
var pending_tail_part: DragonPart
# Audio and visual effects
var creation_audio: AudioStreamPlayer
var lightning_effect: LightningEffect

# === ELEMENT COLORS ===
const ELEMENT_COLORS = {
	DragonPart.Element.FIRE: Color(1, 0.3, 0.2),
	DragonPart.Element.ICE: Color(0.4, 0.7, 1),
	DragonPart.Element.LIGHTNING: Color(1, 1, 0.3),
	DragonPart.Element.NATURE: Color(0.3, 1, 0.3),
	DragonPart.Element.SHADOW: Color(0.6, 0.4, 1)
}

func _ready():
	# Add to factory_manager group so SaveLoadManager can find us
	add_to_group("factory_manager")

	# Create DragonFactory instance
	factory = DragonFactory.new()
	add_child(factory)

	# Get ScientistManager singleton reference (it's an autoload)
	scientist_manager = ScientistManager.instance
	if scientist_manager:
		scientist_manager.set_dragon_factory(factory)
	else:
		push_error("[FactoryManager] ScientistManager singleton not found!")

	# Connect factory signals
	factory.dragon_created.connect(_on_dragon_created)
	factory.dragon_name_generated.connect(_on_dragon_named)
	factory.pet_introduction_completed.connect(_on_pet_introduction_completed)

	# Connect to PetDragonManager signals
	if PetDragonManager and PetDragonManager.instance:
		PetDragonManager.instance.pet_created.connect(_on_pet_created)

	# Connect to SaveLoadManager signals
	if SaveLoadManager and SaveLoadManager.instance:
		SaveLoadManager.instance.game_loaded.connect(_on_game_loaded)

	# Connect scientist manager signals
	if scientist_manager:
		scientist_manager.scientist_hired.connect(_on_scientist_hired)
		scientist_manager.scientist_upgraded.connect(_on_scientist_upgraded)
		scientist_manager.scientist_action_performed.connect(_on_scientist_action)
		scientist_manager.insufficient_gold_for_hire.connect(_on_insufficient_gold_for_hire)
		scientist_manager.insufficient_gold_for_upgrade.connect(_on_insufficient_gold_for_upgrade)

	# Connect exploration manager signals
	if ExplorationManager and ExplorationManager.instance:
		ExplorationManager.instance.exploration_started.connect(_on_exploration_started)
		ExplorationManager.instance.exploration_completed.connect(_on_exploration_completed)

	# Connect defense manager signals
	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.dragon_assigned_to_defense.connect(_on_dragon_assigned_to_defense)
		DefenseManager.instance.dragon_removed_from_defense.connect(_on_dragon_removed_from_defense)
		DefenseManager.instance.wave_incoming_scout.connect(_on_wave_incoming_scout)
		DefenseManager.instance.wave_started.connect(_on_wave_started)
		DefenseManager.instance.wave_completed.connect(_on_wave_completed)

	# Connect defense tower manager signals
	if DefenseTowerManager and DefenseTowerManager.instance:
		DefenseTowerManager.instance.tower_built.connect(_on_tower_built)
		DefenseTowerManager.instance.tower_capacity_changed.connect(_on_tower_capacity_changed)

	# Connect button signals
	animate_button.pressed.connect(_on_animate_button_pressed)
	view_inventory_button.pressed.connect(_on_view_inventory_pressed)
	view_freezer_button.pressed.connect(_on_view_freezer_pressed)
	manage_defenses_button.pressed.connect(_on_manage_defenses_pressed)
	manage_training_button.pressed.connect(_on_manage_training_pressed)
	exploration_map_button.pressed.connect(_on_exploration_map_pressed)
	manage_scientists_button.pressed.connect(_on_manage_scientists_pressed)
	dragon_grounds_button.pressed.connect(_on_dragon_grounds_pressed)
	view_collection_button.pressed.connect(_on_view_collection_pressed)
	watch_battle_button.pressed.connect(_on_watch_battle_pressed)

	# Debug: Check if battle notification panel exists
	if battle_notification_panel:
		print("[FactoryManager] Battle notification panel found!")
		# Add a red background to make it stand out
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.4, 0.1, 0.1, 0.9)  # Dark red background
		style_box.border_width_left = 3
		style_box.border_width_right = 3
		style_box.border_width_top = 3
		style_box.border_width_bottom = 3
		style_box.border_color = Color(1, 0.3, 0.3, 1)  # Bright red border
		battle_notification_panel.add_theme_stylebox_override("panel", style_box)
	else:
		print("[FactoryManager] ERROR: Battle notification panel NOT FOUND!")

	# Create Defense Towers UI
	_setup_defense_towers_ui()

	# Create Training Grounds UI
	_setup_training_yard_ui()

	# Create Exploration Map UI
	_setup_exploration_map_ui()

	# Create Scientist Management UI
	_setup_scientist_management_ui()

	# Connect Dragon Grounds modal
	if dragon_grounds_modal:
		dragon_grounds_modal.closed.connect(_on_dragon_grounds_closed)
		dragon_grounds_modal.dragon_clicked.connect(_on_dragon_grounds_dragon_clicked)

	# Connect part selector signal
	if part_selector:
		part_selector.part_selected.connect(_on_part_selected)

	# Connect dragon details modal signal
	if dragon_details_modal:
		dragon_details_modal.dragon_updated.connect(_on_dragon_updated_from_modal)

	# Set z-index for all modals to ensure they appear above the pet dragon
	if inventory_panel:
		inventory_panel.z_index = 100
		inventory_panel.z_as_relative = false
	if part_selector:
		part_selector.z_index = 100
		part_selector.z_as_relative = false
	if dragon_details_modal:
		dragon_details_modal.z_index = 100
		dragon_details_modal.z_as_relative = false
	if dragon_grounds_modal:
		dragon_grounds_modal.z_index = 100
		dragon_grounds_modal.z_as_relative = false
	if hire_modal:
		# Check if it's a Window-based dialog (AcceptDialog, ConfirmationDialog, etc.)
		if hire_modal is Window:
			hire_modal.always_on_top = true
		else:
			# It's a Control-based modal
			hire_modal.z_index = 100
			hire_modal.z_as_relative = false
	if save_exit_popup:
		save_exit_popup.z_index = 200  # Highest priority - should be on top of everything
		save_exit_popup.z_as_relative = false

	# Connect to TreasureVault signals for gold
	if TreasureVault:
		TreasureVault.gold_changed.connect(_on_gold_changed)

	# Connect to InventoryManager signals for parts
	if InventoryManager and InventoryManager.instance:
		InventoryManager.instance.slot_changed.connect(_on_inventory_changed)

	# Connect to ExplorationManager signals for exploration completion
	if ExplorationManager and ExplorationManager.instance:
		ExplorationManager.instance.exploration_completed.connect(_on_exploration_completed)

	# Connect to DefenseManager signals
	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.dragon_assigned_to_defense.connect(_on_dragon_assigned_to_defense)
		DefenseManager.instance.dragon_removed_from_defense.connect(_on_dragon_removed_from_defense)
		DefenseManager.instance.defense_slots_full.connect(_on_defense_slots_full)

	# Connect to DragonStateManager death signal
	if DragonStateManager and DragonStateManager.instance:
		DragonStateManager.instance.dragon_death.connect(_on_dragon_died)

	# Connect to DragonDeathManager signals
	if DragonDeathManager and DragonDeathManager.instance:
		DragonDeathManager.instance.dragon_died.connect(_on_dragon_death_processed)

	# Initial update
	_update_display()

	# Make head/body/tail slots clickable
	_setup_part_slot_buttons()

	# Make scientist panels clickable
	_setup_scientist_panel_buttons()

	# Create animation progress bar UI
	_setup_animation_progress_ui()

	# Create defense slots UI
	_setup_defense_slots_ui()

	# Setup audio and visual effects
	_setup_creation_effects()

	# Start gameplay background music
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_gameplay_music()

	# Check if we should load from save (set by Continue button)
	if SaveLoadManager and SaveLoadManager.instance and SaveLoadManager.instance.should_load_on_start:
		print("[FactoryManager] Loading game from save...")
		SaveLoadManager.instance.should_load_on_start = false  # Reset flag
		await SaveLoadManager.instance.load_game()
		# Pet system will be set up by _on_game_loaded callback
	else:
		# Setup pet dragon system for new game
		_setup_pet_system()

	print("[FactoryManager] Factory Manager UI initialized")

func _process(_delta):
	"""Continuously update the wave timer"""
	if DefenseManager and DefenseManager.instance:
		_update_defense_display()

	# Update Training Grounds button state
	_update_training_button_state()

	# Update Freezer button notification
	_update_freezer_button_display()
func _input(event):
	"""Handle ESC key to show save & exit popup"""
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# Don't show popup if another modal is already open
		if inventory_panel and inventory_panel.visible:
			return
		if part_selector and part_selector.visible:
			return
		if dragon_details_modal and dragon_details_modal.visible:
			return
		if dragon_grounds_modal and dragon_grounds_modal.visible:
			return
		if defense_towers_ui and defense_towers_ui.visible:
			return
		if training_yard_ui and training_yard_ui.visible:
			return
		if exploration_map_ui and exploration_map_ui.visible:
			return
		if scientist_management_ui and scientist_management_ui.visible:
			return
		if save_exit_popup and save_exit_popup.visible:
			return

		# Show save & exit popup
		if save_exit_popup:
			save_exit_popup.show_popup()
			get_viewport().set_input_as_handled()

func _setup_part_slot_buttons():
	# Use gui_input on the slot rectangles (the "Empty" areas) for click detection
	head_slot_rect.gui_input.connect(func(event): _on_slot_input(event, "head"))
	body_slot_rect.gui_input.connect(func(event): _on_slot_input(event, "body"))
	tail_slot_rect.gui_input.connect(func(event): _on_slot_input(event, "tail"))

	print("[FactoryManager] Slot buttons set up")

func _setup_scientist_panel_buttons():
	# Connect scientist panel signals
	print("[FactoryManager] Setting up scientist panels...")
	print("  - stitcher_panel: %s" % stitcher_panel)
	print("  - caretaker_panel: %s" % caretaker_panel)
	print("  - trainer_panel: %s" % trainer_panel)
	print("  - hire_modal: %s" % hire_modal)

	if stitcher_panel:
		stitcher_panel.hire_requested.connect(_on_scientist_hire_requested)
		stitcher_panel.fire_requested.connect(_on_scientist_fire_requested)
		print("  - Connected stitcher_panel signals")

	if caretaker_panel:
		caretaker_panel.hire_requested.connect(_on_scientist_hire_requested)
		caretaker_panel.fire_requested.connect(_on_scientist_fire_requested)
		print("  - Connected caretaker_panel signals")

	if trainer_panel:
		trainer_panel.hire_requested.connect(_on_scientist_hire_requested)
		trainer_panel.fire_requested.connect(_on_scientist_fire_requested)
		print("  - Connected trainer_panel signals")

	print("[FactoryManager] Scientist panel buttons set up")

func _setup_animation_progress_ui():
	"""Create the animation progress bar UI (hidden by default)"""
	# Create a container for the progress bar overlay
	var progress_container = VBoxContainer.new()
	progress_container.name = "AnimationProgressContainer"
	progress_container.visible = false
	progress_container.set_anchors_preset(Control.PRESET_CENTER)
	progress_container.position = Vector2(400, 300)  # Center of creation area
	progress_container.add_theme_constant_override("separation", 10)

	# Add label
	animation_label = Label.new()
	animation_label.text = "Animating Dragon..."
	animation_label.add_theme_font_size_override("font_size", 20)
	animation_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))
	animation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_container.add_child(animation_label)

	# Create progress bar
	animation_progress_bar = ProgressBar.new()
	animation_progress_bar.custom_minimum_size = Vector2(300, 30)
	animation_progress_bar.max_value = 100
	animation_progress_bar.value = 0
	animation_progress_bar.show_percentage = true
	progress_container.add_child(animation_progress_bar)

	# Add to the center panel (where dragon creation happens)
	var center_panel = $MarginContainer/MainVBox/MainContent/CenterPanel
	if center_panel:
		center_panel.add_child(progress_container)

	# Create animation timer
	animation_timer = Timer.new()
	animation_timer.wait_time = 0.05  # Update 20 times per second for smooth progress
	animation_timer.timeout.connect(_on_animation_timer_timeout)
	add_child(animation_timer)

	print("[FactoryManager] Animation progress UI created")

func _setup_defense_slots_ui():
	"""Create the defense slots UI to show defending dragons"""
	var defense_panel = $MarginContainer/MainVBox/BottomBar/DefensePanel/VBox
	if not defense_panel:
		print("[FactoryManager] ERROR: Could not find DefensePanel")
		return

	# Create container for slots
	defense_slot_container = HBoxContainer.new()
	defense_slot_container.name = "DefenseSlots"
	defense_slot_container.add_theme_constant_override("separation", 8)
	defense_panel.add_child(defense_slot_container)

	# Create 3 defense slots
	for i in range(3):
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(120, 40)

		var slot_label = Label.new()
		slot_label.text = "Empty"
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		slot_label.add_theme_font_size_override("font_size", 12)

		slot_panel.add_child(slot_label)
		defense_slot_container.add_child(slot_panel)
		defense_slots.append(slot_label)

	print("[FactoryManager] Defense slots UI created")

func _setup_creation_effects():
	"""Setup audio and visual effects for dragon creation"""
	# Create audio player for creation sound
	creation_audio = AudioStreamPlayer.new()
	var audio_stream = load("res://assets/audio/High_voltage_electri_#2-1761092568383.mp3")
	if audio_stream:
		creation_audio.stream = audio_stream
		# Enable looping by setting the loop mode on the stream
		if audio_stream is AudioStreamMP3:
			audio_stream.loop = true
	creation_audio.volume_db = 0.0
	creation_audio.bus = "Master"
	add_child(creation_audio)

	# Create lightning effect overlay
	lightning_effect = LightningEffect.new()
	lightning_effect.visible = false
	lightning_effect.z_index = 100  # Render on top of everything
	add_child(lightning_effect)

	print("[FactoryManager] Creation effects initialized")

func _on_slot_input(event: InputEvent, slot_name: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[FactoryManager] Clicked slot: %s" % slot_name)
		_on_slot_clicked(slot_name)

# === SLOT SELECTION ===

func _on_slot_clicked(slot_name: String):
	# Store which slot is being selected
	current_selecting_slot = slot_name

	# Determine part type based on slot
	var part_type: DragonPart.PartType
	match slot_name:
		"head":
			part_type = DragonPart.PartType.HEAD
		"body":
			part_type = DragonPart.PartType.BODY
		"tail":
			part_type = DragonPart.PartType.TAIL

	# Open part selector
	if part_selector:
		part_selector.open(part_type)

func _on_part_selected(item_id: String):
	# Update the appropriate slot based on which one was clicked
	match current_selecting_slot:
		"head":
			selected_head_id = item_id
			_update_slot_display(head_slot_label, head_slot_rect, head_slot_icon, item_id)
		"body":
			selected_body_id = item_id
			_update_slot_display(body_slot_label, body_slot_rect, body_slot_icon, item_id)
		"tail":
			selected_tail_id = item_id
			_update_slot_display(tail_slot_label, tail_slot_rect, tail_slot_icon, item_id)

	_check_can_create_dragon()

func _update_slot_display(label: Label, rect: ColorRect, icon: TextureRect, item_id: String):
	if item_id.is_empty():
		label.text = "Empty"
		label.visible = true
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		rect.color = Color(0.2, 0.25, 0.2, 1)
		icon.visible = false
		icon.texture = null
	else:
		# Get item from database to display icon and color
		if ItemDatabase and ItemDatabase.instance:
			var item = ItemDatabase.instance.get_item(item_id)
			if item:
				# Try to load and display the icon
				var icon_texture = item.get_icon()
				if icon_texture:
					icon.texture = icon_texture
					icon.visible = true
					label.visible = false  # Hide text when icon is shown
				else:
					# Fallback to text if icon fails to load
					label.text = item.element
					label.visible = true
					icon.visible = false

				label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
				# Convert element string to enum for color lookup
				var element_enum = _get_element_enum_from_string(item.element)
				rect.color = ELEMENT_COLORS.get(element_enum, Color.WHITE) * 0.4
		else:
			label.text = item_id
			label.visible = true
			label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
			rect.color = Color(0.5, 0.5, 0.5, 1)
			icon.visible = false

func _get_element_enum_from_string(element_str: String) -> DragonPart.Element:
	match element_str.to_upper():
		"FIRE": return DragonPart.Element.FIRE
		"ICE": return DragonPart.Element.ICE
		"LIGHTNING": return DragonPart.Element.LIGHTNING
		"NATURE": return DragonPart.Element.NATURE
		"SHADOW": return DragonPart.Element.SHADOW
	return DragonPart.Element.FIRE  # Default

func _check_can_create_dragon():
	var can_create = not selected_head_id.is_empty() and not selected_body_id.is_empty() and not selected_tail_id.is_empty()
	# Also disable if currently animating
	animate_button.disabled = not can_create or is_animating

# === DRAGON CREATION ===

func _on_animate_button_pressed():
	# Prevent starting animation if already animating
	if is_animating:
		print("[FactoryManager] Animation already in progress!")
		return

	if selected_head_id.is_empty() or selected_body_id.is_empty() or selected_tail_id.is_empty():
		print("[FactoryManager] Cannot create dragon: missing parts")
		return

	# Check if InventoryManager is available
	if not InventoryManager or not InventoryManager.instance:
		print("[FactoryManager] ERROR: InventoryManager not available")
		return

	# Check if we have the parts in inventory
	if not InventoryManager.instance.has_item(selected_head_id, 1):
		print("[FactoryManager] Not enough head parts in inventory!")
		return
	if not InventoryManager.instance.has_item(selected_body_id, 1):
		print("[FactoryManager] Not enough body parts in inventory!")
		return
	if not InventoryManager.instance.has_item(selected_tail_id, 1):
		print("[FactoryManager] Not enough tail parts in inventory!")
		return

	# Get Item objects from database
	var head_item = ItemDatabase.instance.get_item(selected_head_id)
	var body_item = ItemDatabase.instance.get_item(selected_body_id)
	var tail_item = ItemDatabase.instance.get_item(selected_tail_id)

	if not head_item or not body_item or not tail_item:
		print("[FactoryManager] ERROR: Failed to get items from database!")
		return

	# Convert element strings to enums
	var head_element = _get_element_enum_from_string(head_item.element)
	var body_element = _get_element_enum_from_string(body_item.element)
	var tail_element = _get_element_enum_from_string(tail_item.element)

	# Get DragonPart objects from PartLibrary
	var head_part = PartLibrary.get_part_by_element_and_type(head_element, DragonPart.PartType.HEAD)
	var body_part = PartLibrary.get_part_by_element_and_type(body_element, DragonPart.PartType.BODY)
	var tail_part = PartLibrary.get_part_by_element_and_type(tail_element, DragonPart.PartType.TAIL)

	if not head_part or not body_part or not tail_part:
		print("[FactoryManager] ERROR: Failed to get dragon parts from library!")
		return

	# Deduct parts from inventory
	if not InventoryManager.instance.remove_item_by_id(selected_head_id, 1):
		print("[FactoryManager] Failed to remove head part from inventory!")
		return
	if not InventoryManager.instance.remove_item_by_id(selected_body_id, 1):
		print("[FactoryManager] Failed to remove body part from inventory!")
		return
	if not InventoryManager.instance.remove_item_by_id(selected_tail_id, 1):
		print("[FactoryManager] Failed to remove tail part from inventory!")
		return

	# Start animation instead of immediately creating dragon
	_start_dragon_animation(head_part, body_part, tail_part)

func _start_dragon_animation(head_part: DragonPart, body_part: DragonPart, tail_part: DragonPart):
	"""Start the 5-second dragon animation"""
	# Store parts for creation after animation
	pending_head_part = head_part
	pending_body_part = body_part
	pending_tail_part = tail_part

	# Reset and start animation
	is_animating = true
	animation_progress = 0.0

	# Show progress bar
	var progress_container = $MarginContainer/MainVBox/MainContent/CenterPanel/AnimationProgressContainer
	if progress_container:
		progress_container.visible = true

	# Reset and start timer
	if animation_progress_bar:
		animation_progress_bar.value = 0

	animation_timer.start()

	# Start audio and visual effects
	if creation_audio:
		creation_audio.play()
	if lightning_effect:
		var colors: Array[Color] = []
		colors.append(ELEMENT_COLORS.get(head_part.element, Color.WHITE))
		colors.append(ELEMENT_COLORS.get(body_part.element, Color.WHITE))
		colors.append(ELEMENT_COLORS.get(tail_part.element, Color.WHITE))
		lightning_effect.start_effect(colors)

	# Disable animate button during animation
	animate_button.disabled = true

	print("[FactoryManager] Starting dragon animation (%.0f seconds)..." % ANIMATION_DURATION)

# === DISPLAY UPDATES ===

func _update_display():
	if TreasureVault:
		_update_gold_display(TreasureVault.get_total_gold())
		_update_parts_display()

	_update_dragons_list()
	_update_defense_display()
	_update_exploration_display()
	_update_collection_display()

func _update_gold_display(amount: int):
	gold_label.text = str(amount)

func _update_parts_display():
	if not InventoryManager or not InventoryManager.instance:
		return

	# Count all parts of each element from inventory
	var fire_count = 0
	var ice_count = 0
	var lightning_count = 0
	var nature_count = 0
	var shadow_count = 0

	# Get all dragon parts from inventory
	var all_parts = InventoryManager.instance.get_all_dragon_parts()
	for part_data in all_parts:
		var item: Item = part_data["item"]
		var quantity: int = part_data["quantity"]
		match item.element.to_upper():
			"FIRE": fire_count += quantity
			"ICE": ice_count += quantity
			"LIGHTNING": lightning_count += quantity
			"NATURE": nature_count += quantity
			"SHADOW": shadow_count += quantity

	fire_parts_count.text = str(fire_count)
	ice_parts_count.text = str(ice_count)
	lightning_parts_count.text = str(lightning_count)
	nature_parts_count.text = str(nature_count)
	shadow_parts_count.text = str(shadow_count)

func _update_dragons_list():
	# Clear existing list
	for child in dragons_list.get_children():
		child.queue_free()

	if not factory:
		return

	# Add dragon entries (exclude dead dragons and pet dragon)
	var dragons = factory.active_dragons
	for dragon in dragons:
		# Skip dead dragons
		if dragon.is_dead:
			continue

		# Skip pet dragon (first dragon is the pet)
		if dragon is PetDragon:
			continue

		var dragon_entry = _create_dragon_entry(dragon)
		dragons_list.add_child(dragon_entry)

func _create_dragon_entry(dragon: Dragon) -> PanelContainer:
	# Use the DragonCard component with proper dragon visual
	var dragon_card_scene = load("res://scenes/ui/dragon_card.tscn")
	var dragon_card: DragonCard = dragon_card_scene.instantiate()

	# Set the dragon data (automatically updates visual with correct colors)
	dragon_card.set_dragon(dragon)

	# Connect click to open details modal
	dragon_card.card_clicked.connect(func(d):
		if dragon_details_modal:
			dragon_details_modal.open_for_dragon(d)
	)

	return dragon_card

func _on_dragon_entry_input(event: InputEvent, dragon: Dragon):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Don't open dragon modal if another modal is already open
		if inventory_panel and inventory_panel.visible:
			return
		if part_selector and part_selector.visible:
			return
		if dragon_details_modal and dragon_details_modal.visible:
			return
		if dragon_grounds_modal and dragon_grounds_modal.visible:
			return
		if defense_towers_ui and defense_towers_ui.visible:
			return
		if training_yard_ui and training_yard_ui.visible:
			return
		if exploration_map_ui and exploration_map_ui.visible:
			return
		if scientist_management_ui and scientist_management_ui.visible:
			return
		if save_exit_popup and save_exit_popup.visible:
			return

		print("[FactoryManager] Clicked dragon: %s" % dragon.dragon_name)
		if dragon_details_modal:
			dragon_details_modal.open_for_dragon(dragon)

func _on_dragon_updated_from_modal():
	# Refresh the dragon list when changes are made in the modal
	_update_dragons_list()

func _get_state_text(state: Dragon.DragonState) -> String:
	match state:
		Dragon.DragonState.IDLE: return "Idle"
		Dragon.DragonState.DEFENDING: return "Defending"
		Dragon.DragonState.EXPLORING: return "Exploring"
		Dragon.DragonState.TRAINING: return "Training"
		Dragon.DragonState.RESTING: return "Resting"
		Dragon.DragonState.DEAD: return "Dead"
	return "Unknown"

func _update_defense_display():
	if not DefenseManager or not DefenseManager.instance:
		wave_label.text = "Wave: 1"
		timer_label.text = "Next: 5:00"
		defenders_label.text = "Defenders: 0/3"
		return

	# Update wave info
	wave_label.text = "Wave: %d" % DefenseManager.instance.wave_number

	# Update timer
	var time_remaining = DefenseManager.instance.time_until_next_wave
	var minutes = int(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	timer_label.text = "Next: %d:%02d" % [minutes, seconds]

	# Update defenders count
	var defending_dragons = DefenseManager.instance.get_defending_dragons()
	var max_capacity = DefenseTowerManager.instance.get_defense_capacity() if DefenseTowerManager and DefenseTowerManager.instance else 3
	defenders_label.text = "Defenders: %d/%d" % [defending_dragons.size(), max_capacity]

	# Show battle notification if in combat OR during scout period
	var is_scouting = scouted_enemies.size() > 0

	if DefenseManager.instance.is_in_combat or is_scouting:
		# Hide defense slots, show battle notification
		if defense_slot_container:
			defense_slot_container.visible = false
		if battle_notification_panel:
			battle_notification_panel.visible = true
	else:
		# Show defense slots, hide battle notification
		if defense_slot_container:
			defense_slot_container.visible = true
		if battle_notification_panel:
			battle_notification_panel.visible = false
		# Update defense slots
		_update_defense_slots(defending_dragons)

func _update_exploration_display():
	if ExplorationManager and ExplorationManager.instance:
		var count = ExplorationManager.instance.get_active_explorations_count()
		active_missions_label.text = "Active: %d" % count
	else:
		active_missions_label.text = "Active: 0"

func _update_collection_display():
	if factory:
		var progress = factory.get_collection_progress()
		collection_progress.text = "%d/%d" % [progress["discovered"], progress["total"]]
	else:
		collection_progress.text = "0/125"

func _update_freezer_button_display():
	"""Update freezer button with notification badge for decaying parts"""
	if not view_freezer_button or not DragonDeathManager or not DragonDeathManager.instance:
		return

	var death_manager = DragonDeathManager.instance
	var recovered_count = death_manager.recovered_parts.size()

	if recovered_count == 0:
		# No recovered parts - normal state
		view_freezer_button.text = "❄️ FREEZER"
		view_freezer_button.modulate = Color.WHITE
		return

	# Check for critical parts (<1 hour decay time)
	var critical_count = 0
	var warning_count = 0

	for part in death_manager.recovered_parts:
		var urgency = part.get_decay_urgency()
		if urgency == "critical":
			critical_count += 1
		elif urgency == "urgent" or urgency == "warning":
			warning_count += 1

	# Update button text with badge
	if critical_count > 0:
		view_freezer_button.text = "❄️ FREEZER 🚨 %d" % recovered_count
		# Flash red for critical
		var flash = sin(Time.get_ticks_msec() / 200.0) * 0.3 + 0.7
		view_freezer_button.modulate = Color(1.0, flash, flash)
	elif warning_count > 0:
		view_freezer_button.text = "❄️ FREEZER ⚠️ %d" % recovered_count
		view_freezer_button.modulate = Color(1.0, 1.0, 0.7)  # Yellow tint
	else:
		view_freezer_button.text = "❄️ FREEZER (%d)" % recovered_count
		view_freezer_button.modulate = Color(0.7, 1.0, 0.7)  # Green tint

func _update_training_button_state():
	"""Update Training Grounds button based on Trainer hire status"""
	if not manage_training_button:
		return

	if ScientistManager and ScientistManager.instance:
		var trainer_hired = ScientistManager.instance.is_scientist_hired(Scientist.Type.TRAINER)
		manage_training_button.disabled = not trainer_hired

		if trainer_hired:
			manage_training_button.text = "TRAINING GROUNDS"
			manage_training_button.tooltip_text = ""
		else:
			manage_training_button.text = "TRAINING GROUNDS (LOCKED)"
			manage_training_button.tooltip_text = "Hire the Trainer scientist to unlock"

# === SIGNAL HANDLERS ===

func _on_gold_changed(new_amount: int, delta: int):
	# Always get total gold (unprotected + protected) for display
	_update_gold_display(TreasureVault.get_total_gold())

func _on_inventory_changed(slot_index: int):
	# Update parts display when inventory changes
	_update_parts_display()

func _on_dragon_created(dragon: Dragon):
	print("[FactoryManager] Dragon created: %s" % dragon.dragon_id)
	_update_dragons_list()
	_update_collection_display()

	# Don't spawn pet yet - wait for naming to complete

func _on_pet_created(pet: PetDragon):
	"""Called when a pet dragon is created"""
	# Don't spawn pet yet - wait for introduction popup to close
	print("[FactoryManager] Pet dragon created! Waiting for introduction popup...")

func _on_dragon_named(dragon: Dragon, name: String):
	print("[FactoryManager] Dragon named: %s" % name)
	_update_dragons_list()
	# Pet spawning is now handled by _on_pet_introduction_completed

func _on_pet_introduction_completed(pet: PetDragon):
	"""Called when the pet introduction popup closes"""
	print("[FactoryManager] _on_pet_introduction_completed called!")
	print("[FactoryManager] pet_ui_setup_complete = %s" % pet_ui_setup_complete)

	if pet_ui_setup_complete:
		print("[FactoryManager] Pet UI already set up, skipping")
		return  # Already set up

	print("[FactoryManager] Pet introduction completed! Now spawning walking pet character...")
	pet_ui_setup_complete = true
	_add_walking_pet_character(pet)

func _on_game_loaded(success: bool, message: String):
	"""Called when save game is loaded - refresh pet system"""
	print("[FactoryManager] Game loaded: %s - %s" % [success, message])

	if success:
		# Refresh dragons list
		_update_dragons_list()

		# Re-setup pet system now that data is loaded
		print("[FactoryManager] Re-setting up pet system after load...")
		_setup_pet_system()

func _on_view_inventory_pressed():
	if inventory_panel:
		inventory_panel.open()

func _on_view_freezer_pressed():
	"""Open the Parts Inventory UI (Freezer & Recovered Parts)"""
	print("[FactoryManager] Opening Parts Inventory UI (Freezer)")

	# Load and instantiate the parts inventory UI
	var parts_inventory_scene = load("res://scenes/ui/parts_inventory_ui.tscn")
	if parts_inventory_scene:
		var parts_inventory_ui = parts_inventory_scene.instantiate()
		# Add as overlay
		get_tree().root.add_child(parts_inventory_ui)
		parts_inventory_ui.z_index = 100  # Make sure it's on top
	else:
		print("[FactoryManager] ERROR: Could not load parts_inventory_ui scene")

# === SCIENTIST MANAGEMENT ===

func _on_scientist_hire_requested(scientist_type: Scientist.Type):
	"""Show hire modal when scientist panel is clicked"""
	print("[FactoryManager] Hire requested for type: %s" % scientist_type)
	print("[FactoryManager] hire_modal is: %s" % hire_modal)
	if hire_modal:
		hire_modal.show_for_scientist(scientist_type)
	else:
		print("[FactoryManager] ERROR: hire_modal is null!")

func _on_scientist_fire_requested(scientist_type: Scientist.Type):
	"""Old system - scientists can't be fired in tier-based system"""
	# NOTE: In the new tier-based system, scientists cannot be fired.
	# They can only be upgraded. If you can't afford salaries, scientists
	# continue working but you receive a warning via the salary_failed signal.
	print("[FactoryManager] Fire requested but not supported in tier system")
	pass


func _on_scientist_hired(type: Scientist.Type):
	print("[FactoryManager] Scientist hired: %s" % type)
	_update_gold_display(TreasureVault.get_total_gold())

func _on_scientist_upgraded(type: Scientist.Type, new_tier: int):
	print("[FactoryManager] Scientist upgraded: %s to Tier %d" % [type, new_tier])
	_update_gold_display(TreasureVault.get_total_gold())

func _on_scientist_action(type: Scientist.Type, action_description: String):
	print("[FactoryManager] Scientist action: %s - %s" % [type, action_description])
	# Update UI when scientists do things
	_update_dragons_list()
	_update_parts_display()

func _on_insufficient_gold_for_hire(type: Scientist.Type):
	var scientist = scientist_manager._get_scientist(type)
	var scientist_name = scientist.get_tier_name()
	print("[FactoryManager] Insufficient gold to hire %s!" % scientist_name)

	# Show warning dialog
	var dialog = AcceptDialog.new()
	dialog.always_on_top = true
	add_child(dialog)
	dialog.title = "Insufficient Gold"
	dialog.dialog_text = "Not enough gold to hire %s!\nCost: %d gold" % [scientist_name, scientist.get_upgrade_cost()]
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.popup_centered()

func _on_insufficient_gold_for_upgrade(type: Scientist.Type):
	var scientist = scientist_manager._get_scientist(type)
	var scientist_name = scientist.get_tier_name()
	print("[FactoryManager] Insufficient gold to upgrade %s!" % scientist_name)

	# Show warning dialog
	var dialog = AcceptDialog.new()
	dialog.always_on_top = true
	add_child(dialog)
	dialog.title = "Insufficient Gold"
	dialog.dialog_text = "Not enough gold to upgrade %s!\nCost: %d gold" % [scientist_name, scientist.get_upgrade_cost()]
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.popup_centered()

func _on_exploration_completed(dragon: Dragon, destination: String, rewards: Dictionary):
	"""Called when ANY dragon completes exploration - shows popup for all dragons"""
	print("[FactoryManager] Dragon %s returned from exploration at %s!" % [dragon.dragon_name, destination])

	# Play dragon roar sound effect
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_dragon_roar()

	# Update the exploration display counter
	_update_exploration_display()

	# Update the dragons list to reflect the new state
	_update_dragons_list()

	# Show exploration return popup
	_show_exploration_return_popup(dragon, rewards)

func _show_exploration_return_popup(dragon: Dragon, rewards: Dictionary):
	"""Show the exploration return popup with rewards"""
	# Load and show the return popup
	var popup_scene = load("res://scenes/ui/exploration_return_popup.tscn")
	if not popup_scene:
		print("ERROR: Could not load exploration_return_popup.tscn")
		return

	var popup = popup_scene.instantiate()

	# Set z-index to appear above pet dragon
	if popup is Window:
		popup.always_on_top = true
	else:
		popup.z_index = 100
		popup.z_as_relative = false

	get_tree().root.add_child(popup)
	popup.confirmed.connect(func():
		popup.queue_free()
	)
	popup.show_return(dragon, rewards)

# === PUBLIC API ===

func force_update():
	_update_display()
	_refresh_scientist_panels()

func _refresh_scientist_panels():
	"""Refresh all scientist panels (useful after loading game)"""
	if stitcher_panel and stitcher_panel.has_method("refresh"):
		stitcher_panel.refresh()
	if caretaker_panel and caretaker_panel.has_method("refresh"):
		caretaker_panel.refresh()
	if trainer_panel and trainer_panel.has_method("refresh"):
		trainer_panel.refresh()

# === ANIMATION SYSTEM ===

func _on_animation_timer_timeout():
	"""Update animation progress every tick"""
	if not is_animating:
		return

	# Increment progress
	animation_progress += animation_timer.wait_time / ANIMATION_DURATION

	# Update progress bar
	if animation_progress_bar:
		animation_progress_bar.value = animation_progress * 100

	# Check if animation complete
	if animation_progress >= 1.0:
		_complete_dragon_animation()

func _complete_dragon_animation():
	"""Complete the dragon animation and create the dragon"""
	# Stop timer and hide progress UI
	animation_timer.stop()
	is_animating = false
	animation_progress = 0.0

	# Stop audio and visual effects
	if creation_audio and creation_audio.playing:
		creation_audio.stop()
	if lightning_effect:
		lightning_effect.stop_effect()

	# Hide progress bar
	var progress_container = $MarginContainer/MainVBox/MainContent/CenterPanel/AnimationProgressContainer
	if progress_container:
		progress_container.visible = false

	# Create dragon with the pending parts
	if pending_head_part and pending_body_part and pending_tail_part:
		var dragon = factory.create_dragon(pending_head_part, pending_body_part, pending_tail_part)

		if dragon:
			print("[FactoryManager] Dragon created: %s" % dragon.dragon_name)

			# Reset slots
			selected_head_id = ""
			selected_body_id = ""
			selected_tail_id = ""
			_update_slot_display(head_slot_label, head_slot_rect, head_slot_icon, "")
			_update_slot_display(body_slot_label, body_slot_rect, body_slot_icon, "")
			_update_slot_display(tail_slot_label, tail_slot_rect, tail_slot_icon, "")
			_check_can_create_dragon()

			# Update dragons list
			_update_dragons_list()
		else:
			print("[FactoryManager] ERROR: Failed to create dragon")

	# Clear pending parts
	pending_head_part = null
	pending_body_part = null
	pending_tail_part = null

	# Re-enable animate button
	animate_button.disabled = false

# === DEFENSE SLOT MANAGEMENT ===

func _update_defense_slots(defending_dragons: Array[Dragon]):
	"""Update the defense slot displays"""
	if defense_slots.is_empty():
		return

	# Update each slot
	for i in range(3):
		if i < defending_dragons.size():
			# Slot occupied
			var dragon = defending_dragons[i]
			defense_slots[i].text = dragon.dragon_name
			defense_slots[i].add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))
		else:
			# Slot empty
			defense_slots[i].text = "Empty"
			defense_slots[i].add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))

func _on_dragon_assigned_to_defense(dragon: Dragon):
	"""Called when a dragon is assigned to defense"""
	print("[FactoryManager] Dragon %s assigned to defense" % dragon.dragon_name)
	_update_defense_display()
	_update_dragons_list()

func _on_dragon_removed_from_defense(dragon: Dragon):
	"""Called when a dragon is removed from defense"""
	print("[FactoryManager] Dragon %s removed from defense" % dragon.dragon_name)
	_update_defense_display()
	_update_dragons_list()

func _on_defense_slots_full():
	"""Called when trying to assign a dragon but all defense slots are full"""
	print("[FactoryManager] Defense slots are full!")

	# Get current tower capacity
	var max_capacity = 3  # Default fallback
	if DefenseTowerManager and DefenseTowerManager.instance:
		max_capacity = DefenseTowerManager.instance.get_defense_capacity()

	# Show error dialog
	var dialog = AcceptDialog.new()
	dialog.always_on_top = true
	add_child(dialog)
	dialog.title = "Defense Slots Full"
	dialog.dialog_text = "All %d of your defense towers are occupied!\n\nBuild more towers to increase defense capacity." % max_capacity
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.popup_centered()

func _on_dragon_died(dragon: Dragon):
	"""Called when a dragon dies (from DragonStateManager)"""
	print("[FactoryManager] Dragon died: %s" % dragon.dragon_name)
	# Refresh the dragons list to remove dead dragon
	_update_dragons_list()

func _on_dragon_death_processed(dragon_name: String, cause: String, recovered_parts: Array):
	"""Called when DragonDeathManager processes a death"""
	print("[FactoryManager] Dragon death processed: %s (cause: %s, parts: %d)" % [dragon_name, cause, recovered_parts.size()])
	# The death popup should have appeared
	# Refresh UI to ensure dead dragon is removed
	_update_dragons_list()

# === DEFENSE TOWERS UI ===

func _setup_defense_towers_ui():
	"""Create and setup the defense towers UI"""
	var DefenseTowersUIScene = preload("res://scenes/ui/towers/defense_towers_ui.tscn")
	defense_towers_ui = DefenseTowersUIScene.instantiate()
	add_child(defense_towers_ui)

	# Set factory reference
	defense_towers_ui.set_dragon_factory(factory)

	# Hide by default
	defense_towers_ui.visible = false

	# Connect back button signal
	defense_towers_ui.back_to_factory_requested.connect(_on_defense_towers_back_pressed)

	print("[FactoryManager] Defense Towers UI created")

func _on_manage_defenses_pressed():
	"""Called when the Manage Defenses button is pressed"""
	print("[FactoryManager] Manage Defenses button pressed")

	# Hide factory UI, show defense towers UI
	$MarginContainer.visible = false
	inventory_panel.visible = false
	part_selector.visible = false
	dragon_tooltip.visible = false
	dragon_details_modal.visible = false

	# Hide walking pet dragon
	if walking_pet_character:
		walking_pet_character.visible = false

	defense_towers_ui.visible = true

func _on_defense_towers_back_pressed():
	"""Called when back button is pressed in defense towers UI"""
	print("[FactoryManager] Returning from Defense Towers UI")

	# Show factory UI, hide defense towers UI
	$MarginContainer.visible = true
	defense_towers_ui.visible = false

	# Show walking pet dragon
	if walking_pet_character:
		walking_pet_character.visible = true

# === TRAINING GROUNDS UI ===

func _setup_training_yard_ui():
	"""Create and setup the training grounds UI"""
	var TrainingYardUIScene = preload("res://scenes/ui/training/training_yard_ui.tscn")
	training_yard_ui = TrainingYardUIScene.instantiate()
	add_child(training_yard_ui)

	# Set factory reference
	training_yard_ui.set_dragon_factory(factory)

	# Set TrainingManager's dragon factory reference
	if TrainingManager and TrainingManager.instance:
		TrainingManager.instance.set_dragon_factory(factory)

	# Hide by default
	training_yard_ui.visible = false

	# Connect back button signal
	training_yard_ui.back_to_factory_requested.connect(_on_training_yard_back_pressed)

	print("[FactoryManager] Training Grounds UI created")

func _on_manage_training_pressed():
	"""Called when the Manage Training button is pressed"""
	print("[FactoryManager] Manage Training button pressed")

	# Check if Trainer scientist is hired
	if ScientistManager and ScientistManager.instance:
		if not ScientistManager.instance.is_scientist_hired(Scientist.Type.TRAINER):
			# Show error dialog
			var dialog = AcceptDialog.new()
			dialog.always_on_top = true
			add_child(dialog)
			dialog.title = "Trainer Required"
			dialog.dialog_text = "You must hire the Trainer scientist to unlock the Training Yard!\n\nHire the Trainer from the Scientist Management screen."
			dialog.confirmed.connect(func(): dialog.queue_free())
			dialog.popup_centered()
			return

	# Hide factory UI, show training yard UI
	$MarginContainer.visible = false
	inventory_panel.visible = false
	part_selector.visible = false
	dragon_tooltip.visible = false
	dragon_details_modal.visible = false

	# Hide walking pet dragon
	if walking_pet_character:
		walking_pet_character.visible = false

	training_yard_ui.visible = true

func _on_training_yard_back_pressed():
	"""Called when back button is pressed in training yard UI"""
	print("[FactoryManager] Returning from Training Grounds UI")

	# Show factory UI, hide training yard UI
	$MarginContainer.visible = true
	training_yard_ui.visible = false

	# Show walking pet dragon
	if walking_pet_character:
		walking_pet_character.visible = true

	# Refresh factory UI to show updated dragons
	_update_dragons_list()

# === EXPLORATION MAP UI ===

func _setup_exploration_map_ui():
	"""Create and setup the exploration map UI"""
	var ExplorationMapUIScene = preload("res://scenes/ui/exploration_map_ui.tscn")
	exploration_map_ui = ExplorationMapUIScene.instantiate()
	add_child(exploration_map_ui)

	# Set factory reference
	exploration_map_ui.set_dragon_factory(factory)

	# Hide by default
	exploration_map_ui.visible = false

	# Connect back button signal
	exploration_map_ui.back_to_factory_requested.connect(_on_exploration_map_back_pressed)

	print("[FactoryManager] Exploration Map UI created")

func _on_exploration_map_pressed():
	"""Called when the Exploration Map button is pressed"""
	print("[FactoryManager] Exploration Map button pressed")

	# Hide factory UI, show exploration map UI
	$MarginContainer.visible = false
	inventory_panel.visible = false
	part_selector.visible = false
	dragon_tooltip.visible = false
	dragon_details_modal.visible = false
	if defense_towers_ui:
		defense_towers_ui.visible = false
	if training_yard_ui:
		training_yard_ui.visible = false

	# Hide walking pet dragon
	if walking_pet_character:
		walking_pet_character.visible = false

	exploration_map_ui.visible = true

func _on_exploration_map_back_pressed():
	"""Called when back button is pressed in exploration map UI"""
	print("[FactoryManager] Returning from Exploration Map UI")

	# Show factory UI, hide exploration map UI
	$MarginContainer.visible = true
	exploration_map_ui.visible = false

	# Show walking pet dragon
	if walking_pet_character:
		walking_pet_character.visible = true

	# Refresh factory UI to show updated dragons
	_update_dragons_list()

# === SCIENTIST MANAGEMENT UI ===

func _setup_scientist_management_ui():
	"""Create and setup the scientist management UI"""
	var ScientistManagementUIScene = preload("res://scenes/ui/scientist_management_ui.tscn")
	scientist_management_ui = ScientistManagementUIScene.instantiate()
	add_child(scientist_management_ui)

	# Hide by default
	scientist_management_ui.visible = false

	# Set z-index to appear above everything
	scientist_management_ui.z_index = 100
	scientist_management_ui.z_as_relative = false

	# Connect back button signal
	scientist_management_ui.back_to_factory_requested.connect(_on_scientist_management_back_pressed)

	print("[FactoryManager] Scientist Management UI created")

func _on_manage_scientists_pressed():
	"""Called when the Manage Scientists button is pressed"""
	print("[FactoryManager] Manage Scientists button pressed")

	# Hide factory UI, show scientist management UI
	$MarginContainer.visible = false
	inventory_panel.visible = false
	part_selector.visible = false
	dragon_tooltip.visible = false
	dragon_details_modal.visible = false
	if defense_towers_ui:
		defense_towers_ui.visible = false
	if training_yard_ui:
		training_yard_ui.visible = false
	if exploration_map_ui:
		exploration_map_ui.visible = false

	# Hide walking pet dragon
	if walking_pet_character:
		walking_pet_character.visible = false

	scientist_management_ui.visible = true

func _on_scientist_management_back_pressed():
	"""Called when back button is pressed in scientist management UI"""
	print("[FactoryManager] Returning from Scientist Management UI")

	# Show factory UI, hide scientist management UI
	$MarginContainer.visible = true
	scientist_management_ui.visible = false

	# Show walking pet dragon
	if walking_pet_character:
		walking_pet_character.visible = true

# === DRAGON GROUNDS MODAL ===

func _on_dragon_grounds_pressed():
	"""Called when the Dragon Grounds button is pressed"""
	print("[FactoryManager] Opening Dragon Grounds modal")

	if dragon_grounds_modal:
		dragon_grounds_modal.open(factory)

func _on_dragon_grounds_closed():
	"""Called when the Dragon Grounds modal is closed"""
	print("[FactoryManager] Dragon Grounds modal closed")

	# Refresh dragons list in case any state changed
	_update_dragons_list()

func _on_dragon_grounds_dragon_clicked(dragon: Dragon):
	"""Called when a dragon is clicked in the Dragon Grounds modal"""
	print("[FactoryManager] Dragon clicked in grounds: %s" % dragon.dragon_name)

	# Check if it's a pet dragon
	if dragon is PetDragon:
		print("[FactoryManager] Opening pet interaction modal")
		_open_pet_interaction_ui(dragon)
	else:
		print("[FactoryManager] Opening dragon details modal")
		if dragon_details_modal:
			dragon_details_modal.open_for_dragon(dragon)

# === PET DRAGON SYSTEM ===

func _setup_pet_system():
	"""Setup pet dragon walking character"""
	# Check if walking character already exists in the scene
	var existing_character = get_node_or_null("PetWalkingCharacter")
	if existing_character:
		print("[FactoryManager] Walking character already exists, skipping setup")
		return

	if not PetDragonManager or not PetDragonManager.instance:
		print("[FactoryManager] PetDragonManager not available, skipping pet setup")
		return

	# Check if pet exists
	if not PetDragonManager.instance.has_pet():
		print("[FactoryManager] No pet dragon yet, pet UI will be shown after first dragon creation")
		return

	var pet = PetDragonManager.instance.get_pet_dragon()
	print("[FactoryManager] Setting up pet system for: %s" % pet.dragon_name)

	pet_ui_setup_complete = true

	# Add walking pet character only (no persistent status widget)
	_add_walking_pet_character(pet)

func _add_walking_pet_character(pet: Dragon):
	"""Add the walking pet character to the scene"""
	var walking_pet_scene = load("res://scenes/pet/pet_walking_character.tscn")
	if not walking_pet_scene:
		push_error("[FactoryManager] Failed to load pet walking character scene!")
		return

	var walking_pet = walking_pet_scene.instantiate()
	walking_pet.name = "PetWalkingCharacter"
	walking_pet.add_to_group("pet_walking_character")  # Add to group for easy finding

	# Set z-index to appear above UI but below modals
	walking_pet.z_index = 50
	walking_pet.z_as_relative = false  # Use absolute z-index

	# Add to the main scene (in front of UI)
	add_child(walking_pet)

	# Store reference for later show/hide
	walking_pet_character = walking_pet

	# Setup with pet dragon
	if walking_pet.has_method("setup"):
		walking_pet.setup(pet)

	# Connect click signal to open interaction UI
	if walking_pet.has_signal("pet_clicked"):
		walking_pet.pet_clicked.connect(_on_pet_clicked)

	print("[FactoryManager] Pet walking character added to scene")

func _on_pet_clicked(pet: Dragon):
	"""Called when the walking pet is clicked"""
	# Don't open pet interaction modal if another modal is already open
	if inventory_panel and inventory_panel.visible:
		return
	if part_selector and part_selector.visible:
		return
	if dragon_details_modal and dragon_details_modal.visible:
		return
	if dragon_grounds_modal and dragon_grounds_modal.visible:
		return
	if defense_towers_ui and defense_towers_ui.visible:
		return
	if training_yard_ui and training_yard_ui.visible:
		return
	if exploration_map_ui and exploration_map_ui.visible:
		return
	if scientist_management_ui and scientist_management_ui.visible:
		return
	if save_exit_popup and save_exit_popup.visible:
		return

	print("[FactoryManager] _on_pet_clicked received! Pet: %s" % pet.dragon_name)
	_open_pet_interaction_ui(pet)

func _open_pet_interaction_ui(pet: Dragon):
	"""Open the pet interaction UI"""
	print("[FactoryManager] Opening pet interaction UI...")

	var interaction_scene = load("res://scenes/ui/pet/pet_interaction_ui.tscn")
	if not interaction_scene:
		push_error("[FactoryManager] Failed to load pet interaction UI scene!")
		return

	var interaction_ui = interaction_scene.instantiate()
	interaction_ui.name = "PetInteractionUI"

	# Set z-index to appear above pet dragon
	if interaction_ui is Window:
		interaction_ui.always_on_top = true
	else:
		interaction_ui.z_index = 100
		interaction_ui.z_as_relative = false

	print("[FactoryManager] Pet interaction UI instantiated")

	# Add to scene tree
	add_child(interaction_ui)

	print("[FactoryManager] Pet interaction UI added to scene tree")

	# Setup with pet dragon
	if interaction_ui.has_method("setup"):
		print("[FactoryManager] Calling setup on pet interaction UI...")
		interaction_ui.setup(pet)
		interaction_ui.visible = true
		print("[FactoryManager] Pet interaction UI setup complete and visible")
	else:
		push_error("[FactoryManager] Pet interaction UI missing setup() method!")

	print("[FactoryManager] Pet interaction UI opened")

func _on_view_collection_pressed():
	"""Called when the View Collection button is pressed"""
	print("[FactoryManager] View Collection button pressed")

	# Load and show collection modal
	var collection_modal_script = load("res://scripts/ui/collection_modal.gd")
	if not collection_modal_script:
		push_error("[FactoryManager] Failed to load collection modal script!")
		return

	var collection_modal = Control.new()
	collection_modal.set_script(collection_modal_script)

	# Add to scene tree
	add_child(collection_modal)

	# Wait a frame for _ready to be called
	await get_tree().process_frame

	# Setup with factory
	if collection_modal.has_method("setup"):
		collection_modal.setup(factory)
	else:
		push_error("[FactoryManager] Collection modal missing setup() method!")
		collection_modal.queue_free()

func _on_exploration_started(dragon: Dragon, destination: String):
	"""Called when an exploration starts"""
	print("[FactoryManager] Exploration started: %s -> %s" % [dragon.dragon_name, destination])
	_update_exploration_display()
	_update_dragons_list()  # Update dragon list to show exploration status

func _on_tower_built(tower):
	"""Called when a defense tower is built"""
	print("[FactoryManager] Defense tower built: %s" % tower.tower_id)
	_update_defense_display()  # Update to show increased capacity

func _on_tower_capacity_changed(new_capacity: int):
	"""Called when defense tower capacity changes"""
	print("[FactoryManager] Defense capacity changed to: %d" % new_capacity)
	_update_defense_display()  # Update to show new capacity

# === BATTLE NOTIFICATION SYSTEM ===

func _on_wave_incoming_scout(wave_num: int, enemies: Array, time_remaining: float):
	"""Called 90 seconds before wave starts - allows player to scout enemies"""
	print("[FactoryManager] ===== WAVE %d INCOMING (%.0fs) - SCOUT AVAILABLE =====" % [wave_num, time_remaining])
	print("[FactoryManager] Detected %d enemies for scouting" % enemies.size())

	# Store enemy data for scout screen
	scouted_enemies = enemies
	scouted_wave_number = wave_num

	# Update label to show scout notification
	if battle_label:
		battle_label.text = "⚠ WAVE %d INCOMING! ⚠" % wave_num

	# Change button text to "SCOUT ENEMIES"
	if watch_battle_button:
		watch_battle_button.text = "SCOUT ENEMIES"

	# Play notification sound
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_notification()

	_update_defense_display()  # Show notification

func _on_wave_started(wave_number: int, enemies: Array):
	"""Called when a battle wave starts"""
	print("[FactoryManager] ===== WAVE %d STARTED! =====" % wave_number)
	print("[FactoryManager] Enemies: %d" % enemies.size())
	print("[FactoryManager] is_in_combat: %s" % DefenseManager.instance.is_in_combat)

	# Clear scout data
	scouted_enemies.clear()

	# Update label to show battle is starting
	if battle_label:
		battle_label.text = "⚔ WAVE %d INCOMING! ⚔" % wave_number

	# Reset button text to "WATCH BATTLE"
	if watch_battle_button:
		watch_battle_button.text = "WATCH BATTLE"

	_update_defense_display()  # Show battle notification

	# After 3 seconds, update to "IN PROGRESS"
	await get_tree().create_timer(3.0).timeout
	if battle_label and DefenseManager.instance and DefenseManager.instance.is_in_combat:
		battle_label.text = "⚔ BATTLE IN PROGRESS ⚔"

func _on_wave_completed(victory: bool, rewards: Dictionary):
	"""Called when a battle wave completes"""
	print("[FactoryManager] Wave completed! Victory: %s, Rewards: %s" % [victory, rewards])

	# Store result to show after animation
	pending_wave_result = {
		"victory": victory,
		"rewards": rewards
	}

	print("[FactoryManager] Stored pending_wave_result: %s" % pending_wave_result)

	_update_defense_display()  # Hide battle notification

	# If battle arena is not open (background battle) AND this UI is visible, show popup immediately
	if visible and (not battle_arena or not is_instance_valid(battle_arena) or not battle_arena.visible):
		print("[FactoryManager] Background battle completed - checking if popup should be shown")
		# Wait one frame for end_combat to complete
		await get_tree().process_frame
		if not pending_wave_result.is_empty():
			# Check if another UI already showed the popup
			if DefenseManager.instance and DefenseManager.instance.should_show_wave_result_popup():
				_show_wave_result_popup()
			else:
				print("[FactoryManager] Popup already shown by another UI, skipping")
			pending_wave_result = {}  # Clear after showing
	elif not visible:
		print("[FactoryManager] This UI not visible, skipping popup")
		pending_wave_result = {}  # Clear to prevent showing later

func _on_watch_battle_pressed():
	"""Called when the Watch Battle button is pressed"""
	print("[FactoryManager] Watch Battle button pressed!")

	# Check if we're in scout mode (button says "SCOUT ENEMIES")
	if watch_battle_button and watch_battle_button.text == "SCOUT ENEMIES":
		print("[FactoryManager] Opening enemy scout screen...")
		_open_enemy_scout_screen()
		return

	# Otherwise, open battle arena
	# Check if battle arena already exists
	if battle_arena and is_instance_valid(battle_arena):
		print("[FactoryManager] Battle arena already open")
		battle_arena.visible = true
		return

	# Load and create the battle arena scene
	var battle_arena_scene = load("res://scenes/idle_defense/battle_arena.tscn")
	if not battle_arena_scene:
		print("[FactoryManager] ERROR: Could not load battle arena scene!")
		return

	battle_arena = battle_arena_scene.instantiate()
	battle_arena.name = "BattleArena"

	# Set z-index to appear above everything else
	battle_arena.z_index = 150
	battle_arena.z_as_relative = false

	# Add to scene tree
	add_child(battle_arena)

	# Connect signals
	if battle_arena.has_signal("battle_animation_complete"):
		battle_arena.battle_animation_complete.connect(_on_battle_animation_complete)
	if battle_arena.has_signal("back_button_pressed"):
		battle_arena.back_button_pressed.connect(_on_battle_arena_closed)
	if battle_arena.has_signal("battle_result_determined"):
		battle_arena.battle_result_determined.connect(_on_battle_result_determined)

	print("[FactoryManager] Battle arena opened!")

func _on_battle_animation_complete():
	"""Called when battle animation finishes"""
	print("[FactoryManager] Battle animation complete")
	print("[FactoryManager] pending_wave_result before end_combat: %s" % pending_wave_result)

	# End combat state in DefenseManager
	# This triggers wave_completed signal which populates pending_wave_result
	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.end_combat()

	# Wait one frame to ensure signal processing completes
	await get_tree().process_frame

	print("[FactoryManager] pending_wave_result after end_combat: %s" % pending_wave_result)

	# Show wave result popup if we have pending results
	if not pending_wave_result.is_empty():
		# Check if another UI already showed the popup
		if DefenseManager.instance and DefenseManager.instance.should_show_wave_result_popup():
			print("[FactoryManager] Calling _show_wave_result_popup()")
			_show_wave_result_popup()
		else:
			print("[FactoryManager] Popup already shown by another UI, skipping")
		pending_wave_result = {}  # Clear after showing
	else:
		print("[FactoryManager] WARNING: pending_wave_result is empty, not showing popup!")

func _on_battle_result_determined(victory: bool):
	"""Called when visual combat determines the winner"""
	print("[FactoryManager] Battle result determined: Victory=%s" % victory)

	# Pass result to DefenseManager
	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.on_visual_combat_result(victory)

func _on_battle_arena_closed():
	"""Called when player clicks back button in battle arena"""
	print("[FactoryManager] Player closed battle arena")

	# Remove the battle arena
	if battle_arena and is_instance_valid(battle_arena):
		battle_arena.queue_free()
		battle_arena = null

func _show_wave_result_popup():
	"""Show the wave result popup"""
	if not pending_wave_result.has("victory") or not pending_wave_result.has("rewards"):
		return

	var popup = WaveResultPopupScene.instantiate()

	# Set z-index higher than battle arena (which is 150)
	popup.z_index = 200
	popup.z_as_relative = false

	add_child(popup)

	# Setup with wave data
	popup.setup(pending_wave_result)

	# Connect closed signal to clean up
	popup.closed.connect(func(): popup.queue_free())

	print("[FactoryManager] Showing wave result popup (z-index: 200)")

func _open_enemy_scout_screen():
	"""Open the enemy scout screen to preview incoming wave"""
	# Check if scout screen already exists and is visible
	if enemy_scout_screen and is_instance_valid(enemy_scout_screen):
		print("[FactoryManager] Enemy scout screen already open, updating...")
		if enemy_scout_screen.has_method("show_scout_info"):
			var time_remaining = DefenseManager.instance.time_until_next_wave if DefenseManager and DefenseManager.instance else 90.0
			enemy_scout_screen.show_scout_info(scouted_wave_number, scouted_enemies, time_remaining)
		enemy_scout_screen.visible = true
		return

	# Load and create the enemy scout screen scene
	var scout_scene = load("res://scenes/idle_defense/enemy_scout_screen.tscn")
	if not scout_scene:
		print("[FactoryManager] ERROR: Could not load enemy scout screen scene!")
		return

	enemy_scout_screen = scout_scene.instantiate()
	enemy_scout_screen.name = "EnemyScoutScreen"

	# Set z-index to appear above everything else
	enemy_scout_screen.z_index = 150
	enemy_scout_screen.z_as_relative = false

	# Add to scene tree
	add_child(enemy_scout_screen)

	# Show scout info with current data
	if enemy_scout_screen.has_method("show_scout_info"):
		var time_remaining = DefenseManager.instance.time_until_next_wave if DefenseManager and DefenseManager.instance else 90.0
		enemy_scout_screen.show_scout_info(scouted_wave_number, scouted_enemies, time_remaining)

	print("[FactoryManager] Enemy scout screen opened!")
