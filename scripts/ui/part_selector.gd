# Part Selector - Visual inventory grid for selecting dragon parts from inventory
extends Control

signal part_selected(item_id: String)

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/Title
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var parts_grid: GridContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/PartsGrid

var current_part_type: DragonPart.PartType = DragonPart.PartType.HEAD

const ELEMENT_COLORS = {
	"FIRE": Color(1, 0.3, 0.2),
	"ICE": Color(0.4, 0.7, 1),
	"LIGHTNING": Color(1, 1, 0.3),
	"NATURE": Color(0.3, 1, 0.3),
	"SHADOW": Color(0.6, 0.4, 1)
}

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	hide()

func open(part_type: DragonPart.PartType):
	current_part_type = part_type

	# Update title
	var type_name = DragonPart.PartType.keys()[part_type].capitalize()
	title_label.text = "SELECT %s PART" % type_name

	# Clear existing grid
	for child in parts_grid.get_children():
		child.queue_free()

	# Populate grid with available parts from inventory
	_populate_parts_grid()

	show()

func _populate_parts_grid():
	if not InventoryManager or not InventoryManager.instance:
		print("[PartSelector] ERROR: InventoryManager not available")
		return

	# Get the part type string (HEAD, BODY, TAIL)
	var type_string = DragonPart.PartType.keys()[current_part_type]

	# Get all dragon parts of this type from inventory
	var available_parts = InventoryManager.instance.get_dragon_parts_by_type(type_string)

	# Group by element for organized display
	var parts_by_element: Dictionary = {}

	for part_data in available_parts:
		var item: Item = part_data["item"]
		var element = item.element
		if not parts_by_element.has(element):
			parts_by_element[element] = {
				"item_id": part_data["item_id"],
				"item": item,
				"quantity": 0
			}
		parts_by_element[element]["quantity"] += part_data["quantity"]

	# If no parts available, show message
	if parts_by_element.is_empty():
		var message = Label.new()
		message.text = "No %s parts in inventory!" % type_string.to_lower()
		message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		message.add_theme_font_size_override("font_size", 16)
		message.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
		parts_grid.add_child(message)
		return

	# Create a box for each element that has parts
	for element in parts_by_element.keys():
		var data = parts_by_element[element]
		var part_box = _create_part_box(data["item_id"], data["item"], data["quantity"])
		parts_grid.add_child(part_box)

func _create_part_box(item_id: String, item: Item, count: int) -> Control:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(120, 120)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(vbox)

	# Part icon (actual texture)
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Try to load the actual icon
	var icon_texture = item.get_icon()
	if icon_texture:
		icon.texture = icon_texture
	else:
		# Fallback to colored square if icon not found
		print("[PartSelector] WARNING: No icon for item %s (icon_path: '%s')" % [item.id, item.icon_path])
		var fallback = ColorRect.new()
		fallback.custom_minimum_size = Vector2(80, 80)
		fallback.color = ELEMENT_COLORS.get(item.element, Color.WHITE)
		vbox.add_child(fallback)
		icon = null

	if icon:
		vbox.add_child(icon)

	# Element name
	var name_label = Label.new()
	name_label.text = item.element.capitalize()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(0.8, 1, 0.8, 1))
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)

	# Count label
	var count_label = Label.new()
	count_label.text = "×%d" % count
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_color_override("font_color", Color(1, 0.843, 0, 1))
	count_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(count_label)

	# Make clickable
	var button = Button.new()
	button.flat = true
	button.custom_minimum_size = Vector2(120, 120)
	button.pressed.connect(func(): _on_part_selected(item_id))
	container.add_child(button)

	# Add hover tooltip
	button.tooltip_text = "%s (%d available)" % [item.get_display_name(), count]

	return container

func _on_part_selected(item_id: String):
	part_selected.emit(item_id)
	hide()

func _on_close_pressed():
	hide()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and visible:
		hide()
		get_viewport().set_input_as_handled()
