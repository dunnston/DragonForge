extends Control
class_name CollectionModal

# References to UI elements (created dynamically)
var close_button: Button
var title_label: Label
var progress_label: Label
var grid_container: GridContainer
var scroll_container: ScrollContainer

# Reference to factory
var factory: DragonFactory

# Element colors for UI
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
	_build_ui()

func setup(dragon_factory: DragonFactory):
	"""Setup the collection modal with a factory reference"""
	factory = dragon_factory
	_populate_collection()

func _build_ui():
	"""Build the modal UI structure"""
	# Make this modal fill the screen with semi-transparent background
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Set high z-index to render above everything including pet
	z_index = 100
	z_as_relative = false  # Use absolute z-index

	# Dark semi-transparent background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Center panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 600)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)

	# Main VBox
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(main_vbox)

	# Header HBox
	var header_hbox = HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	# Title
	title_label = Label.new()
	title_label.text = "DRAGON COLLECTION"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_label)

	# Close button
	close_button = Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(40, 40)
	close_button.pressed.connect(_on_close_pressed)
	header_hbox.add_child(close_button)

	# Progress label
	progress_label = Label.new()
	progress_label.text = "Discovered: 0/125"
	progress_label.add_theme_font_size_override("font_size", 16)
	main_vbox.add_child(progress_label)

	# Info label
	var info_label = Label.new()
	info_label.text = "Create dragons with different element combinations to complete your collection!"
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_vbox.add_child(info_label)

	# Scroll container for grid
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size = Vector2(0, 400)
	main_vbox.add_child(scroll_container)

	# Grid container for collection entries
	grid_container = GridContainer.new()
	grid_container.columns = 5  # 5 columns for 5 elements
	grid_container.add_theme_constant_override("h_separation", 5)
	grid_container.add_theme_constant_override("v_separation", 5)
	scroll_container.add_child(grid_container)

func _populate_collection():
	"""Populate the collection with all 125 possible combinations"""
	if not factory:
		return

	# Clear existing entries
	for child in grid_container.get_children():
		child.queue_free()

	# Get collection progress
	var progress = factory.get_collection_progress()
	progress_label.text = "Discovered: %d/%d (%.1f%%)" % [
		progress["discovered"],
		progress["total"],
		progress["percentage"]
	]

	# Get discovered combinations
	var discovered = factory.dragon_collection

	# Generate all 125 combinations
	var elements = [
		DragonPart.Element.FIRE,
		DragonPart.Element.ICE,
		DragonPart.Element.LIGHTNING,
		DragonPart.Element.NATURE,
		DragonPart.Element.SHADOW
	]

	for head in elements:
		for body in elements:
			for tail in elements:
				var combo_key = "%s_%s_%s" % [
					DragonPart.Element.keys()[head],
					DragonPart.Element.keys()[body],
					DragonPart.Element.keys()[tail]
				]

				var is_discovered = discovered.has(combo_key)
				_create_collection_entry(head, body, tail, is_discovered)

func _create_collection_entry(head: DragonPart.Element, body: DragonPart.Element, tail: DragonPart.Element, discovered: bool):
	"""Create a single collection entry card"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(160, 100)

	# Style the card based on discovered status
	var stylebox = StyleBoxFlat.new()
	if discovered:
		stylebox.bg_color = Color(0.2, 0.2, 0.3, 1.0)
		stylebox.border_color = Color(0.5, 0.5, 0.7, 1.0)
	else:
		stylebox.bg_color = Color(0.1, 0.1, 0.1, 1.0)
		stylebox.border_color = Color(0.3, 0.3, 0.3, 1.0)

	# Set border widths individually
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2

	# Set corner radii individually
	stylebox.corner_radius_top_left = 5
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_left = 5
	stylebox.corner_radius_bottom_right = 5

	card.add_theme_stylebox_override("panel", stylebox)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	card.add_child(vbox)

	if discovered:
		# Show the combination
		var head_label = Label.new()
		head_label.text = "🐲 " + ELEMENT_NAMES[head]
		head_label.add_theme_color_override("font_color", ELEMENT_COLORS[head])
		head_label.add_theme_font_size_override("font_size", 11)
		head_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(head_label)

		var body_label = Label.new()
		body_label.text = "🦎 " + ELEMENT_NAMES[body]
		body_label.add_theme_color_override("font_color", ELEMENT_COLORS[body])
		body_label.add_theme_font_size_override("font_size", 11)
		body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(body_label)

		var tail_label = Label.new()
		tail_label.text = "🐍 " + ELEMENT_NAMES[tail]
		tail_label.add_theme_color_override("font_color", ELEMENT_COLORS[tail])
		tail_label.add_theme_font_size_override("font_size", 11)
		tail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(tail_label)

		# Check if it's a pure element dragon (all same element)
		if head == body and body == tail:
			var pure_label = Label.new()
			pure_label.text = "⭐ PURE"
			pure_label.add_theme_font_size_override("font_size", 10)
			pure_label.add_theme_color_override("font_color", Color(1, 1, 0.3))
			pure_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(pure_label)
	else:
		# Show as undiscovered
		var mystery_label = Label.new()
		mystery_label.text = "???"
		mystery_label.add_theme_font_size_override("font_size", 24)
		mystery_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		mystery_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mystery_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mystery_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(mystery_label)

		var hint_label = Label.new()
		hint_label.text = "Undiscovered"
		hint_label.add_theme_font_size_override("font_size", 9)
		hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(hint_label)

	grid_container.add_child(card)

func _on_close_pressed():
	"""Close the modal"""
	queue_free()

func show_modal():
	"""Show the modal"""
	visible = true

func hide_modal():
	"""Hide the modal"""
	visible = false
