# Factory Manager - Main UI for Dragon Factory Management
extends Control

# === SYSTEMS ===
var factory: DragonFactory

# === UI ELEMENTS - Top Bar ===
@onready var gold_label: Label = $MarginContainer/MainVBox/TopBar/GoldDisplay/HBox/GoldLabel
@onready var view_inventory_button: Button = $MarginContainer/MainVBox/TopBar/ViewInventoryButton

@onready var fire_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/FireParts/Count
@onready var ice_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/IceParts/Count
@onready var lightning_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/LightningParts/Count
@onready var nature_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/NatureParts/Count
@onready var shadow_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/ShadowParts/Count

# === UI ELEMENTS - Scientists ===
@onready var breeder_status: Label = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/BreederPanel/VBox/StatusLabel
@onready var trainer_status: Label = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/TrainerPanel/VBox/StatusLabel
@onready var caretaker_status: Label = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/CaretakerPanel/VBox/StatusLabel

# === UI ELEMENTS - Dragon Creation ===
@onready var head_slot_label: Label = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/HeadSlot/VBox/SlotRect/PartLabel
@onready var body_slot_label: Label = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/BodySlot/VBox/SlotRect/PartLabel
@onready var tail_slot_label: Label = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/TailSlot/VBox/SlotRect/PartLabel
@onready var animate_button: Button = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/AnimateButton

@onready var head_slot_panel: PanelContainer = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/HeadSlot
@onready var body_slot_panel: PanelContainer = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/BodySlot
@onready var tail_slot_panel: PanelContainer = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/TailSlot

@onready var head_slot_rect: ColorRect = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/HeadSlot/VBox/SlotRect
@onready var body_slot_rect: ColorRect = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/BodySlot/VBox/SlotRect
@onready var tail_slot_rect: ColorRect = $MarginContainer/MainVBox/MainContent/CenterPanel/CreationVBox/TailSlot/VBox/SlotRect

# === UI ELEMENTS - Dragons List ===
@onready var dragons_list: VBoxContainer = $MarginContainer/MainVBox/MainContent/RightPanel/DragonsVBox/ScrollContainer/DragonsList

# === UI ELEMENTS - Bottom Bar ===
@onready var wave_label: Label = $MarginContainer/MainVBox/BottomBar/DefensePanel/VBox/HBox/WaveLabel
@onready var timer_label: Label = $MarginContainer/MainVBox/BottomBar/DefensePanel/VBox/TimerLabel
@onready var defenders_label: Label = $MarginContainer/MainVBox/BottomBar/DefensePanel/VBox/DefendersLabel
@onready var active_missions_label: Label = $MarginContainer/MainVBox/BottomBar/ExplorationPanel/VBox/ActiveLabel
@onready var collection_progress: Label = $MarginContainer/MainVBox/BottomBar/CollectionPanel/VBox/ProgressLabel

# === UI PANELS ===
@onready var inventory_panel: Control = $InventoryPanel
@onready var part_selector: Control = $PartSelector
@onready var dragon_tooltip: Control = $DragonTooltip
@onready var dragon_details_modal: Control = $DragonDetailsModal

# === DRAGON CREATION STATE ===
var selected_head: DragonPart.Element = -1
var selected_body: DragonPart.Element = -1
var selected_tail: DragonPart.Element = -1
var current_selecting_slot: String = ""  # Track which slot is being selected

# === ELEMENT COLORS ===
const ELEMENT_COLORS = {
	DragonPart.Element.FIRE: Color(1, 0.3, 0.2),
	DragonPart.Element.ICE: Color(0.4, 0.7, 1),
	DragonPart.Element.LIGHTNING: Color(1, 1, 0.3),
	DragonPart.Element.NATURE: Color(0.3, 1, 0.3),
	DragonPart.Element.SHADOW: Color(0.6, 0.4, 1)
}

func _ready():
	# Create DragonFactory instance
	factory = DragonFactory.new()
	add_child(factory)

	# Connect factory signals
	factory.dragon_created.connect(_on_dragon_created)
	factory.dragon_name_generated.connect(_on_dragon_named)

	# Connect button signals
	animate_button.pressed.connect(_on_animate_button_pressed)
	view_inventory_button.pressed.connect(_on_view_inventory_pressed)

	# Connect part selector signal
	if part_selector:
		part_selector.part_selected.connect(_on_part_selected)

	# Connect dragon details modal signal
	if dragon_details_modal:
		dragon_details_modal.dragon_updated.connect(_on_dragon_updated_from_modal)

	# Connect to TreasureVault signals if available
	if TreasureVault:
		TreasureVault.gold_changed.connect(_on_gold_changed)
		TreasureVault.parts_changed.connect(_on_parts_changed)

		# Initial update
		_update_display()
	else:
		print("[FactoryManager] WARNING: TreasureVault not found!")
		# Set default values for testing
		_update_gold_display(100)
		_update_parts_display()

	# Make head/body/tail slots clickable
	_setup_part_slot_buttons()

	print("[FactoryManager] Factory Manager UI initialized")

func _setup_part_slot_buttons():
	# Use gui_input on the slot rectangles (the "Empty" areas) for click detection
	head_slot_rect.gui_input.connect(func(event): _on_slot_input(event, "head"))
	body_slot_rect.gui_input.connect(func(event): _on_slot_input(event, "body"))
	tail_slot_rect.gui_input.connect(func(event): _on_slot_input(event, "tail"))

	print("[FactoryManager] Slot buttons set up")

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

func _on_part_selected(element: DragonPart.Element):
	# Update the appropriate slot based on which one was clicked
	match current_selecting_slot:
		"head":
			selected_head = element
			_update_slot_display(head_slot_label, head_slot_rect, element)
		"body":
			selected_body = element
			_update_slot_display(body_slot_label, body_slot_rect, element)
		"tail":
			selected_tail = element
			_update_slot_display(tail_slot_label, tail_slot_rect, element)

	_check_can_create_dragon()

func _update_slot_display(label: Label, rect: ColorRect, element: DragonPart.Element):
	if element == -1:
		label.text = "Empty"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		rect.color = Color(0.2, 0.25, 0.2, 1)
	else:
		var element_name = DragonPart.Element.keys()[element]
		label.text = element_name
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		rect.color = ELEMENT_COLORS.get(element, Color.WHITE) * 0.4

func _check_can_create_dragon():
	var can_create = selected_head != -1 and selected_body != -1 and selected_tail != -1
	animate_button.disabled = not can_create

# === DRAGON CREATION ===

func _on_animate_button_pressed():
	if selected_head == -1 or selected_body == -1 or selected_tail == -1:
		print("[FactoryManager] Cannot create dragon: missing parts")
		return

	# Check if we have the parts in inventory
	if not TreasureVault:
		print("[FactoryManager] ERROR: TreasureVault not available")
		return

	if not TreasureVault.can_build_dragon(selected_head, selected_body, selected_tail):
		print("[FactoryManager] Not enough parts to build dragon!")
		return

	# Deduct parts from inventory
	if not TreasureVault.spend_part(selected_head, 1):
		print("[FactoryManager] Failed to spend head part!")
		return
	if not TreasureVault.spend_part(selected_body, 1):
		print("[FactoryManager] Failed to spend body part!")
		return
	if not TreasureVault.spend_part(selected_tail, 1):
		print("[FactoryManager] Failed to spend tail part!")
		return

	# Get DragonPart objects from PartLibrary
	var head_part = PartLibrary.get_part_by_element_and_type(selected_head, DragonPart.PartType.HEAD)
	var body_part = PartLibrary.get_part_by_element_and_type(selected_body, DragonPart.PartType.BODY)
	var tail_part = PartLibrary.get_part_by_element_and_type(selected_tail, DragonPart.PartType.TAIL)

	if not head_part or not body_part or not tail_part:
		print("[FactoryManager] ERROR: Failed to get dragon parts from library!")
		return

	# Create dragon
	var dragon = factory.create_dragon(head_part, body_part, tail_part)

	if dragon:
		print("[FactoryManager] Dragon created: %s" % dragon.dragon_name)

		# Reset slots
		selected_head = -1
		selected_body = -1
		selected_tail = -1
		_update_slot_display(head_slot_label, head_slot_rect, -1)
		_update_slot_display(body_slot_label, body_slot_rect, -1)
		_update_slot_display(tail_slot_label, tail_slot_rect, -1)
		_check_can_create_dragon()

		# Update dragons list
		_update_dragons_list()
	else:
		print("[FactoryManager] ERROR: Failed to create dragon")

# === DISPLAY UPDATES ===

func _update_display():
	if TreasureVault:
		_update_gold_display(TreasureVault.get_total_gold())
		_update_parts_display()

	_update_scientists_display()
	_update_dragons_list()
	_update_defense_display()
	_update_exploration_display()
	_update_collection_display()

func _update_gold_display(amount: int):
	gold_label.text = str(amount)

func _update_parts_display():
	if not TreasureVault:
		return

	fire_parts_count.text = str(TreasureVault.get_part_count(DragonPart.Element.FIRE))
	ice_parts_count.text = str(TreasureVault.get_part_count(DragonPart.Element.ICE))
	lightning_parts_count.text = str(TreasureVault.get_part_count(DragonPart.Element.LIGHTNING))
	nature_parts_count.text = str(TreasureVault.get_part_count(DragonPart.Element.NATURE))
	shadow_parts_count.text = str(TreasureVault.get_part_count(DragonPart.Element.SHADOW))

func _update_scientists_display():
	# TODO: Connect to ScientistManager when implemented
	breeder_status.text = "Not hired"
	trainer_status.text = "Not hired"
	caretaker_status.text = "Not hired"

func _update_dragons_list():
	# Clear existing list
	for child in dragons_list.get_children():
		child.queue_free()

	if not factory:
		return

	# Add dragon entries
	var dragons = factory.active_dragons
	for dragon in dragons:
		var dragon_entry = _create_dragon_entry(dragon)
		dragons_list.add_child(dragon_entry)

func _create_dragon_entry(dragon: Dragon) -> PanelContainer:
	var panel = PanelContainer.new()

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# Dragon name
	var name_label = Label.new()
	name_label.text = dragon.dragon_name if dragon.dragon_name else "Unnamed Dragon"
	name_label.add_theme_color_override("font_color", Color(0.8, 1, 0.8, 1))
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	# Dragon stats
	var stats_label = Label.new()
	stats_label.text = "HP: %d  Lvl: %d" % [dragon.current_health, dragon.level]
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	stats_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(stats_label)

	# Dragon state
	var state_label = Label.new()
	state_label.text = _get_state_text(dragon.current_state)
	state_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6, 1))
	state_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(state_label)

	# Add click detection to open modal
	panel.gui_input.connect(func(event): _on_dragon_entry_input(event, dragon))

	return panel

func _on_dragon_entry_input(event: InputEvent, dragon: Dragon):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
	# TODO: Connect to DefenseManager when implemented
	wave_label.text = "Wave: 1"
	timer_label.text = "Next: 5:00"
	defenders_label.text = "Defenders: 0/3"

func _update_exploration_display():
	# TODO: Connect to ExplorationManager when implemented
	active_missions_label.text = "Active: 0"

func _update_collection_display():
	if factory:
		var progress = factory.get_collection_progress()
		collection_progress.text = "%d/%d" % [progress["discovered"], progress["total"]]
	else:
		collection_progress.text = "0/125"

# === SIGNAL HANDLERS ===

func _on_gold_changed(new_amount: int, delta: int):
	_update_gold_display(new_amount)

func _on_parts_changed(element: DragonPart.Element, new_count: int):
	_update_parts_display()

func _on_dragon_created(dragon: Dragon):
	print("[FactoryManager] Dragon created: %s" % dragon.dragon_id)
	_update_dragons_list()
	_update_collection_display()

func _on_dragon_named(dragon: Dragon, name: String):
	print("[FactoryManager] Dragon named: %s" % name)
	_update_dragons_list()

func _on_view_inventory_pressed():
	if inventory_panel:
		inventory_panel.open()

# === PUBLIC API ===

func force_update():
	_update_display()
