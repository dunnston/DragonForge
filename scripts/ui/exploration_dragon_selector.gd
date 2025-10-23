extends Control
class_name ExplorationDragonSelector

# UI components
@onready var title_label: Label = $Panel/VBox/TitleBar/Title
@onready var destination_info_label: Label = $Panel/VBox/DestinationInfo
@onready var dragon_list: VBoxContainer = $Panel/VBox/ScrollContainer/DragonList
@onready var no_dragons_label: Label = $Panel/VBox/NoDragonsLabel
@onready var close_button: Button = $Panel/VBox/TitleBar/CloseButton

# Data
var destination_key: String
var destination_info: Dictionary
var available_dragons: Array = []

# Signals
signal dragon_selected(dragon: Dragon)
signal cancelled

func _ready():
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func show_for_destination(dest_key: String, dest_info: Dictionary, dragons: Array):
	"""Show the selector populated with available dragons"""
	destination_key = dest_key
	destination_info = dest_info
	available_dragons = dragons

	# Update destination info label
	if destination_info_label:
		destination_info_label.text = "%s (%d minutes)" % [
			dest_info["name"],
			dest_info["duration_minutes"]
		]

	# Clear previous dragon cards
	for child in dragon_list.get_children():
		child.queue_free()

	if available_dragons.is_empty():
		# Show no dragons message
		if no_dragons_label:
			no_dragons_label.visible = true
		return
	else:
		if no_dragons_label:
			no_dragons_label.visible = false

	# Create dragon selection cards
	for dragon in available_dragons:
		_create_dragon_card(dragon)

	# Show the modal
	visible = true

func _create_dragon_card(dragon: Dragon):
	"""Create a clickable card for a dragon"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	card.add_child(hbox)

	# Dragon visual (actual dragon rendering)
	var dragon_visual_container = CenterContainer.new()
	dragon_visual_container.custom_minimum_size = Vector2(80, 80)

	# Load and instantiate the DragonVisual scene
	var dragon_visual_scene = load("res://assets/Icons/dragons/dragon-base.tscn")
	if dragon_visual_scene:
		# Wrap Node2D in a Control so CenterContainer can position it
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(80, 80)

		var dragon_visual: DragonVisual = dragon_visual_scene.instantiate()
		dragon_visual.scale = Vector2(0.08, 0.08)  # Scale down the large dragon sprite
		dragon_visual.position = Vector2(40, 40)  # Center in the 80x80 wrapper
		wrapper.add_child(dragon_visual)
		dragon_visual_container.add_child(wrapper)
		hbox.add_child(dragon_visual_container)

		# Defer the color application until the node is in the tree
		call_deferred("_apply_dragon_colors", dragon_visual, dragon)
	else:
		# Fallback to colored square
		var fallback = ColorRect.new()
		fallback.custom_minimum_size = Vector2(80, 80)
		fallback.color = _get_element_color(dragon.head_part.element)
		dragon_visual_container.add_child(fallback)
		hbox.add_child(dragon_visual_container)

	# Dragon info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = dragon.dragon_name
	name_label.add_theme_color_override("font_color", Color(0, 1, 0))
	name_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(name_label)

	var stats_label = Label.new()
	stats_label.text = "Level %d | HP: %d/%d | Fatigue: %d%%" % [
		dragon.level,
		int(dragon.current_health),
		int(dragon.get_health()),
		int(dragon.fatigue_level * 100)
	]
	stats_label.add_theme_color_override("font_color", Color(0.8, 1, 0.8))
	stats_label.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(stats_label)

	var element_label = Label.new()
	element_label.text = "Element: %s" % DragonPart.Element.keys()[dragon.head_part.element]
	element_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	element_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(element_label)

	# Select button
	var select_button = Button.new()
	select_button.text = "SELECT"
	select_button.custom_minimum_size = Vector2(100, 60)
	select_button.pressed.connect(_on_dragon_selected.bind(dragon))
	hbox.add_child(select_button)

	dragon_list.add_child(card)

func _apply_dragon_colors(dragon_visual: DragonVisual, dragon: Dragon):
	"""Apply dragon colors after the visual is in the scene tree"""
	if not is_instance_valid(dragon_visual):
		return

	dragon_visual.set_dragon_colors_from_parts(
		dragon.head_part,
		dragon.body_part,
		dragon.tail_part
	)

func _get_element_color(element: DragonPart.Element) -> Color:
	"""Get color for dragon element"""
	match element:
		DragonPart.Element.FIRE:
			return Color(1.0, 0.3, 0.0)
		DragonPart.Element.ICE:
			return Color(0.3, 0.8, 1.0)
		DragonPart.Element.LIGHTNING:
			return Color(1.0, 1.0, 0.2)
		DragonPart.Element.NATURE:
			return Color(0.2, 1.0, 0.2)
		DragonPart.Element.SHADOW:
			return Color(0.6, 0.2, 0.8)
		_:
			return Color(1.0, 1.0, 1.0)

func _on_dragon_selected(dragon: Dragon):
	"""Called when a dragon is selected"""
	print("[ExplorationDragonSelector] Dragon selected: %s" % dragon.dragon_name)
	dragon_selected.emit(dragon)
	visible = false

func _on_close_pressed():
	"""Called when close button is pressed"""
	print("[ExplorationDragonSelector] Cancelled")
	cancelled.emit()
	visible = false
