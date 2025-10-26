# Simple Message Popup - Generic popup for simple messages
# Used for wave results and other simple notifications
extends Control

signal closed

var title_text: String = ""
var message_text: String = ""
var is_victory: bool = true

func _ready():
	# Set anchors to fill screen
	set_anchors_preset(PRESET_FULL_RECT)

	# Create overlay
	var overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	add_child(overlay)

	# Create center container
	var center = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	# Create panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 300)
	center.add_child(panel)

	# Create margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	# Create vbox
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	# Title label
	var title_label = Label.new()
	title_label.text = title_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)

	if is_victory:
		title_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))  # Green
	else:
		title_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))  # Red

	vbox.add_child(title_label)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Message label
	var message_label = Label.new()
	message_label.text = message_text
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(message_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	# Close button
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(120, 40)
	close_button.pressed.connect(_on_close_pressed)

	# Center the button
	var button_container = CenterContainer.new()
	button_container.add_child(close_button)
	vbox.add_child(button_container)

	# Show immediately
	show()

func setup(data: Dictionary):
	"""Setup with data from notification"""
	title_text = data.get("title", "Notification")
	message_text = data.get("message", "")
	is_victory = data.get("victory", true)

func _on_close_pressed():
	closed.emit()
	queue_free()
