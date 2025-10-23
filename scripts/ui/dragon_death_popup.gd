extends Control
class_name DragonDeathPopup

## Popup displayed when a dragon dies, showing recovered parts

# Node references
@onready var overlay = $Overlay
@onready var popup_panel = $Overlay/CenterContainer/PopupPanel
@onready var dragon_name_label = $Overlay/CenterContainer/PopupPanel/MarginContainer/VBox/TitleContainer/DragonNameLabel
@onready var portrait_container = $Overlay/CenterContainer/PopupPanel/MarginContainer/VBox/PortraitContainer
@onready var dragon_visual: DragonVisual = %DragonVisual
@onready var cause_label = $Overlay/CenterContainer/PopupPanel/MarginContainer/VBox/CauseLabel
@onready var separator = $Overlay/CenterContainer/PopupPanel/MarginContainer/VBox/Separator
@onready var parts_count_label = $Overlay/CenterContainer/PopupPanel/MarginContainer/VBox/PartsRecoveredLabel
@onready var parts_grid = $Overlay/CenterContainer/PopupPanel/MarginContainer/VBox/PartsGrid
@onready var decay_warning = $Overlay/CenterContainer/PopupPanel/MarginContainer/VBox/DecayWarning
@onready var buttons_hbox = $Overlay/CenterContainer/PopupPanel/MarginContainer/VBox/Buttons
@onready var continue_button = $Overlay/CenterContainer/PopupPanel/MarginContainer/VBox/Buttons/ContinueButton

func _ready():
	# Connect button signals
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

	# Start hidden
	hide()

func setup(dragon: Dragon, death_cause: String, recovered_parts: Array):
	"""Initialize the popup with dragon death information"""
	print("\n🪟 [DragonDeathPopup] setup() called")
	print("   Dragon: %s" % (dragon.dragon_name if dragon else "NULL"))
	print("   Cause: %s" % death_cause)
	print("   Parts: %d" % recovered_parts.size())

	if not dragon:
		print("❌ [DragonDeathPopup] Dragon is null, aborting")
		return

	# Set dragon name
	if dragon_name_label:
		dragon_name_label.text = "%s (Level %d)" % [dragon.dragon_name, dragon.level]
		print("✅ [DragonDeathPopup] Set dragon name: %s" % dragon_name_label.text)

	# Set death cause
	if cause_label:
		cause_label.text = "Cause of Death: %s" % _format_death_cause(death_cause)
		print("✅ [DragonDeathPopup] Set death cause: %s" % cause_label.text)

	# Set dragon visual colors (dragon visual is now in the scene file)
	if dragon_visual and dragon.head_part and dragon.body_part and dragon.tail_part:
		# Set dragon colors from parts
		dragon_visual.set_dragon_colors_from_parts(dragon.head_part, dragon.body_part, dragon.tail_part)

		# Gray out to indicate death
		dragon_visual.set_modulate_tint(Color(0.6, 0.6, 0.6))

		print("✅ [DragonDeathPopup] Set dragon visual colors")
	else:
		# Hide dragon visual if parts are missing (offline death without parts)
		if dragon_visual:
			dragon_visual.visible = false
		print("⚠️ [DragonDeathPopup] Missing dragon parts for visual")

	# Display recovered parts
	if recovered_parts.is_empty():
		print("⚠️ [DragonDeathPopup] No parts recovered")
		if parts_count_label:
			parts_count_label.text = "NO PARTS RECOVERED"
		if decay_warning:
			decay_warning.visible = false
	else:
		print("📦 [DragonDeathPopup] Displaying %d recovered parts" % recovered_parts.size())
		if parts_count_label:
			parts_count_label.text = "PARTS RECOVERED: %d/3" % recovered_parts.size()

		_display_recovered_parts(recovered_parts)

		if decay_warning:
			decay_warning.visible = true

	# Show the popup with fade-in animation
	print("🎬 [DragonDeathPopup] Showing popup and animating in...")
	show()
	_animate_in()
	print("✅ [DragonDeathPopup] setup() complete\n")

func _display_recovered_parts(parts: Array):
	"""Display grid of recovered parts"""
	if not parts_grid:
		return

	# Clear existing children
	for child in parts_grid.get_children():
		child.queue_free()

	# Create a simple display for each part
	for part in parts:
		var part_display = _create_simple_part_display(part)
		parts_grid.add_child(part_display)

func _create_simple_part_display(part: DragonPart) -> Control:
	"""Create a simple part display (since we may not have the full card component)"""
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(100, 80)

	# Icon placeholder
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(60, 60)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Try to load part icon
	var part_icon = part.get_icon()
	if part_icon:
		icon.texture = part_icon

	container.add_child(icon)

	# Name label
	var name_label = Label.new()
	name_label.text = part.get_display_name()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", _get_element_color(part.element))
	name_label.add_theme_font_size_override("font_size", 11)
	container.add_child(name_label)

	# Rarity label
	var rarity_label = Label.new()
	rarity_label.text = part.get_rarity_name()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1, 1))
	rarity_label.add_theme_font_size_override("font_size", 9)
	container.add_child(rarity_label)

	return container

func _get_element_color(element: int) -> Color:
	"""Get color for each element type"""
	match element:
		DragonPart.Element.FIRE:
			return Color(1, 0.4, 0.4)  # Red
		DragonPart.Element.ICE:
			return Color(0.4, 0.8, 1)  # Blue
		DragonPart.Element.LIGHTNING:
			return Color(1, 1, 0.3)  # Yellow
		DragonPart.Element.NATURE:
			return Color(0.4, 1, 0.4)  # Green
		DragonPart.Element.SHADOW:
			return Color(0.8, 0.4, 1)  # Purple
	return Color.WHITE

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
	print("🎬 [DragonDeathPopup] _animate_in() called")

	if overlay:
		print("   Overlay found, animating...")
		# TEMPORARY: Skip animation for debugging - just make it visible
		overlay.modulate = Color(1, 1, 1, 1)
		print("   ✅ Overlay modulate set to fully visible")
		#overlay.modulate = Color(1, 1, 1, 0)
		#var tween = create_tween()
		#tween.tween_property(overlay, "modulate:a", 1.0, 0.3)
	else:
		print("   ❌ No overlay found!")

	if popup_panel:
		print("   Popup panel found, setting scale...")
		popup_panel.scale = Vector2.ONE
		print("   ✅ Panel scale set to 1.0")
		#popup_panel.scale = Vector2(0.8, 0.8)
		#var tween2 = create_tween()
		#tween2.tween_property(popup_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		print("   ❌ No popup_panel found!")

	print("✅ [DragonDeathPopup] _animate_in() complete")

func _on_continue_pressed():
	"""Close the popup"""
	_animate_out()

func _animate_out():
	"""Fade out animation before closing"""
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)
