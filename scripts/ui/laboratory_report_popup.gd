extends Control
class_name LaboratoryReportPopup

## Scrollable laboratory report popup showing multiple dragon deaths and decay events

signal closed

@onready var title_label: Label = $Overlay/CenterContainer/PopupPanel/MarginContainer/VBox/TitleLabel
@onready var content_vbox: VBoxContainer = $Overlay/CenterContainer/PopupPanel/MarginContainer/VBox/ScrollContainer/ContentVBox
@onready var continue_button: Button = $Overlay/CenterContainer/PopupPanel/MarginContainer/VBox/ContinueButton
@onready var overlay: ColorRect = $Overlay

func _ready():
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	hide()

func setup(deaths: Array, decayed_parts: Array):
	"""Initialize the popup with death and decay information"""
	print("\n🪟 [LaboratoryReportPopup] setup() called")
	print("   Deaths: %d" % deaths.size())
	print("   Decayed parts: %d" % decayed_parts.size())

	# Clear previous content
	for child in content_vbox.get_children():
		child.queue_free()

	# Set title based on content
	if deaths.size() > 0:
		title_label.text = "💀 LABORATORY REPORT 💀"
	else:
		title_label.text = "⚠️ DECAY ALERT ⚠️"

	# Deaths section
	if not deaths.is_empty():
		_add_deaths_section(deaths)

	# Decay section
	if not decayed_parts.is_empty():
		if not deaths.is_empty():
			# Add separator if we have both sections
			_add_separator()
		_add_decay_section(decayed_parts)

	# Show popup with fade-in animation
	show()
	_animate_in()
	print("✅ [LaboratoryReportPopup] setup() complete\n")

func _add_deaths_section(deaths: Array):
	"""Add the deaths section to the content"""
	# Section title
	var deaths_title = Label.new()
	deaths_title.text = "DRAGONS LOST: %d" % deaths.size()
	deaths_title.add_theme_font_size_override("font_size", 20)
	deaths_title.add_theme_color_override("font_color", Color(1, 0.6, 0.6))
	content_vbox.add_child(deaths_title)

	# Add spacing
	_add_spacing(5)

	# List each death
	for death in deaths:
		var death_container = VBoxContainer.new()
		death_container.add_theme_constant_override("separation", 5)

		# Dragon name and level
		var name_label = Label.new()
		name_label.text = "  • %s (Level %d)" % [
			death["dragon_name"],
			death["dragon_level"]
		]
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.8))
		death_container.add_child(name_label)

		# Cause of death
		var cause_label = Label.new()
		cause_label.text = "     %s" % _format_death_cause(death["cause"])
		cause_label.add_theme_font_size_override("font_size", 14)
		cause_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.7))
		death_container.add_child(cause_label)

		content_vbox.add_child(death_container)

	# Parts recovered section
	var total_recovered = 0
	for death in deaths:
		total_recovered += death["recovered_parts"].size()

	_add_spacing(10)

	var recovered_label = Label.new()
	recovered_label.text = "PARTS RECOVERED: %d" % total_recovered
	recovered_label.add_theme_font_size_override("font_size", 18)
	recovered_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	content_vbox.add_child(recovered_label)

	_add_spacing(5)

	# List recovered parts
	for death in deaths:
		for part in death["recovered_parts"]:
			var part_line = Label.new()
			part_line.text = "  ✓ %s (Decays in 24h)" % part.get_display_name()
			part_line.add_theme_font_size_override("font_size", 14)
			part_line.add_theme_color_override("font_color", Color(0.8, 1, 0.8))
			content_vbox.add_child(part_line)

func _add_decay_section(decayed_parts: Array):
	"""Add the decay section to the content"""
	# Section title
	var decay_title = Label.new()
	decay_title.text = "PARTS LOST TO DECAY: %d" % decayed_parts.size()
	decay_title.add_theme_font_size_override("font_size", 18)
	decay_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	content_vbox.add_child(decay_title)

	_add_spacing(5)

	# List decayed parts
	for part in decayed_parts:
		var decay_line = Label.new()
		decay_line.text = "  ✗ %s crumbled to dust" % part.get_display_name()
		decay_line.add_theme_font_size_override("font_size", 14)
		decay_line.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		content_vbox.add_child(decay_line)

func _add_separator():
	"""Add a visual separator"""
	_add_spacing(10)
	var sep = HSeparator.new()
	content_vbox.add_child(sep)
	_add_spacing(10)

func _add_spacing(height: int):
	"""Add vertical spacing"""
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	content_vbox.add_child(spacer)

func _format_death_cause(cause: String) -> String:
	"""Get human-readable death cause"""
	match cause:
		"combat_defending":
			return "Defeated in combat defending laboratory"
		"combat_failed":
			return "Killed when defenses were overwhelmed"
		"starvation":
			return "Died of starvation"
		"exploration_accident":
			return "Lost during exploration expedition"
		_:
			return "Unknown cause"

func _animate_in():
	"""Fade in animation"""
	if overlay:
		overlay.modulate = Color(1, 1, 1, 1)

func _on_continue_pressed():
	"""Close the popup"""
	closed.emit()
	
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)
