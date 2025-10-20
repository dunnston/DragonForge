# Part Selector - Visual inventory grid for selecting dragon parts
extends Control

signal part_selected(element: DragonPart.Element)

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/Title
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var parts_grid: GridContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/PartsGrid

var current_part_type: DragonPart.PartType = DragonPart.PartType.HEAD

const ELEMENT_COLORS = {
	DragonPart.Element.FIRE: Color(1, 0.3, 0.2),
	DragonPart.Element.ICE: Color(0.4, 0.7, 1),
	DragonPart.Element.LIGHTNING: Color(1, 1, 0.3),
	DragonPart.Element.NATURE: Color(0.3, 1, 0.3),
	DragonPart.Element.SHADOW: Color(0.6, 0.4, 1)
}

const ELEMENT_NAMES = {
	DragonPart.Element.FIRE: "Fire",
	DragonPart.Element.ICE: "Ice",
	DragonPart.Element.LIGHTNING: "Lightning",
	DragonPart.Element.NATURE: "Nature",
	DragonPart.Element.SHADOW: "Shadow"
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

	# Populate grid with available parts
	_populate_parts_grid()

	show()

func _populate_parts_grid():
	if not TreasureVault:
		return

	# Create a box for each element type
	for element in DragonPart.Element.values():
		var count = TreasureVault.get_part_count(element)

		# Create part box
		var part_box = _create_part_box(element, count)
		parts_grid.add_child(part_box)

func _create_part_box(element: DragonPart.Element, count: int) -> Control:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(120, 120)

	# Disable if no parts available
	var available = count > 0

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(vbox)

	# Part icon (colored square)
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.color = ELEMENT_COLORS[element]
	if not available:
		icon.color = icon.color.darkened(0.5)
	vbox.add_child(icon)

	# Element name
	var name_label = Label.new()
	name_label.text = ELEMENT_NAMES[element]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.theme_override_colors["font_color"] = Color(0.8, 1, 0.8, 1) if available else Color(0.5, 0.5, 0.5, 1)
	name_label.theme_override_font_sizes["font_size"] = 14
	vbox.add_child(name_label)

	# Count label
	var count_label = Label.new()
	count_label.text = "×%d" % count
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.theme_override_colors["font_color"] = Color(1, 0.843, 0, 1) if available else Color(0.5, 0.5, 0.5, 1)
	count_label.theme_override_font_sizes["font_size"] = 12
	vbox.add_child(count_label)

	# Make clickable if available
	if available:
		var button = Button.new()
		button.flat = true
		button.custom_minimum_size = Vector2(120, 120)
		button.pressed.connect(func(): _on_part_selected(element))
		container.add_child(button)

		# Add hover tooltip
		button.tooltip_text = "%s %s part (%d available)" % [
			ELEMENT_NAMES[element],
			DragonPart.PartType.keys()[current_part_type].capitalize(),
			count
		]

	return container

func _on_part_selected(element: DragonPart.Element):
	part_selected.emit(element)
	hide()

func _on_close_pressed():
	hide()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and visible:
		hide()
		get_viewport().set_input_as_handled()
