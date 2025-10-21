# Factory Manager - Main UI for Dragon Factory Management
extends Control

# === SYSTEMS ===
var factory: DragonFactory
var scientist_manager: ScientistManager

# === UI ELEMENTS - Top Bar ===
@onready var gold_label: Label = $MarginContainer/MainVBox/TopBar/GoldDisplay/HBox/GoldLabel
@onready var view_inventory_button: Button = $MarginContainer/MainVBox/TopBar/ViewInventoryButton

@onready var fire_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/FireParts/Count
@onready var ice_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/IceParts/Count
@onready var lightning_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/LightningParts/Count
@onready var nature_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/NatureParts/Count
@onready var shadow_parts_count: Label = $MarginContainer/MainVBox/TopBar/PartsDisplay/PartsHBox/ShadowParts/Count

# === UI ELEMENTS - Scientists ===
@onready var stitcher_panel = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/StitcherPanel
@onready var caretaker_panel = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/CaretakerPanel
@onready var trainer_panel = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/TrainerPanel
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
var selected_head_id: String = ""
var selected_body_id: String = ""
var selected_tail_id: String = ""
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

	# Create ScientistManager instance
	scientist_manager = ScientistManager.new()
	add_child(scientist_manager)
	scientist_manager.set_dragon_factory(factory)

	# Connect factory signals
	factory.dragon_created.connect(_on_dragon_created)
	factory.dragon_name_generated.connect(_on_dragon_named)

	# Connect scientist manager signals
	scientist_manager.scientist_hired.connect(_on_scientist_hired)
	scientist_manager.scientist_fired.connect(_on_scientist_fired)
	scientist_manager.scientist_action_performed.connect(_on_scientist_action)
	scientist_manager.insufficient_gold_for_scientist.connect(_on_insufficient_gold_for_scientist)

	# Connect button signals
	animate_button.pressed.connect(_on_animate_button_pressed)
	view_inventory_button.pressed.connect(_on_view_inventory_pressed)

	# Connect part selector signal
	if part_selector:
		part_selector.part_selected.connect(_on_part_selected)

	# Connect dragon details modal signal
	if dragon_details_modal:
		dragon_details_modal.dragon_updated.connect(_on_dragon_updated_from_modal)

	# Connect to TreasureVault signals for gold
	if TreasureVault:
		TreasureVault.gold_changed.connect(_on_gold_changed)

	# Connect to InventoryManager signals for parts
	if InventoryManager and InventoryManager.instance:
		InventoryManager.instance.slot_changed.connect(_on_inventory_changed)

	# Initial update
	_update_display()

	# Make head/body/tail slots clickable
	_setup_part_slot_buttons()

	# Make scientist panels clickable
	_setup_scientist_panel_buttons()

	print("[FactoryManager] Factory Manager UI initialized")

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
	animate_button.disabled = not can_create

# === DRAGON CREATION ===

func _on_animate_button_pressed():
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

	# Create dragon
	var dragon = factory.create_dragon(head_part, body_part, tail_part)

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

	# Add dragon entries
	var dragons = factory.active_dragons
	for dragon in dragons:
		var dragon_entry = _create_dragon_entry(dragon)
		dragons_list.add_child(dragon_entry)

func _create_dragon_entry(dragon: Dragon) -> PanelContainer:
	var panel = PanelContainer.new()

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	# Dragon image
	var dragon_image = TextureRect.new()
	dragon_image.custom_minimum_size = Vector2(60, 60)
	dragon_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	dragon_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var texture = load("res://assets/Icons/dragons/fire-dragon.png")
	if texture:
		dragon_image.texture = texture
	hbox.add_child(dragon_image)

	# Dragon info vbox
	var vbox = VBoxContainer.new()
	hbox.add_child(vbox)

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

func _on_inventory_changed(slot_index: int):
	# Update parts display when inventory changes
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

# === SCIENTIST MANAGEMENT ===

func _on_scientist_hire_requested(scientist_type: ScientistManager.ScientistType):
	"""Show hire modal when scientist panel is clicked"""
	print("[FactoryManager] Hire requested for type: %s" % scientist_type)
	print("[FactoryManager] hire_modal is: %s" % hire_modal)
	if hire_modal:
		hire_modal.show_for_scientist(scientist_type)
	else:
		print("[FactoryManager] ERROR: hire_modal is null!")

func _on_scientist_fire_requested(scientist_type: ScientistManager.ScientistType):
	"""Show confirmation dialog when fire button is clicked"""
	var scientist_name = ScientistManager.instance.get_scientist_name(scientist_type)

	var dialog = ConfirmationDialog.new()
	add_child(dialog)
	dialog.title = "Fire " + scientist_name + "?"
	dialog.dialog_text = "Are you sure you want to fire " + scientist_name + "?\n\nNo refund will be given.\nOngoing costs will stop."

	dialog.confirmed.connect(func():
		ScientistManager.instance.fire_scientist(scientist_type)
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	dialog.popup_centered()


func _on_scientist_hired(type: ScientistManager.ScientistType):
	print("[FactoryManager] Scientist hired: %s" % type)
	_update_gold_display(TreasureVault.get_total_gold())

func _on_scientist_fired(type: ScientistManager.ScientistType):
	print("[FactoryManager] Scientist fired: %s" % type)

func _on_scientist_action(type: ScientistManager.ScientistType, action_description: String):
	print("[FactoryManager] Scientist action: %s - %s" % [type, action_description])
	# Update UI when scientists do things
	_update_dragons_list()
	_update_parts_display()

func _on_insufficient_gold_for_scientist(type: ScientistManager.ScientistType):
	var info = scientist_manager.get_scientist_info(type)
	print("[FactoryManager] Insufficient gold for %s!" % info["name"])

	# Show warning dialog
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.title = "Insufficient Gold"
	dialog.dialog_text = "Not enough gold to pay %s!\nScientist has been auto-fired." % info["name"]
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.popup_centered()

# === PUBLIC API ===

func force_update():
	_update_display()
