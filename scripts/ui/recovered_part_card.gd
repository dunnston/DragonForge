extends PanelContainer
class_name RecoveredPartCard

## Displays a recovered part with decay timer and urgency styling

# Node references
@onready var icon_texture = $HBox/Icon
@onready var info_vbox = $HBox/VBox
@onready var name_label = $HBox/VBox/NameLabel
@onready var rarity_label = $HBox/VBox/RarityLabel
@onready var timer_label = $HBox/VBox/TimerLabel
@onready var buttons_hbox = $HBox/Buttons
@onready var use_button = $HBox/Buttons/UseButton
@onready var freeze_button = $HBox/Buttons/FreezeButton

# Signals
signal freeze_clicked
signal use_clicked

# State
var part: DragonPart
var pulse_tween: Tween

func _ready():
	# Connect button signals
	if use_button:
		use_button.pressed.connect(_on_use_pressed)
	if freeze_button:
		freeze_button.pressed.connect(_on_freeze_pressed)

func setup(recovered_part: DragonPart):
	"""Initialize the card with a recovered part"""
	part = recovered_part
	_update_display()

func _process(_delta):
	"""Update timer every frame"""
	if part and part.is_recovered():
		_update_timer()

func _update_display():
	"""Update all visual elements"""
	if not part:
		return

	# Set name
	if name_label:
		name_label.text = part.get_display_name()

	# Set rarity
	if rarity_label:
		rarity_label.text = part.get_rarity_name()

	# Set icon
	if icon_texture:
		var icon = part.get_icon()
		if icon:
			icon_texture.texture = icon

	# Initial timer update
	_update_timer()

	# Apply urgency styling
	_apply_urgency_styling()

func _update_timer():
	"""Update the decay timer text"""
	if not timer_label or not part:
		return

	var time_str = part.format_time_remaining()
	timer_label.text = "⏱️ %s" % time_str

func _apply_urgency_styling():
	"""Apply color coding and effects based on urgency"""
	if not part:
		return

	var urgency = part.get_decay_urgency()

	# Stop any existing pulse animation
	if pulse_tween:
		pulse_tween.kill()

	match urgency:
		"safe":  # >12 hours
			modulate = Color.WHITE
			if timer_label:
				timer_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4))  # Green

		"warning":  # 6-12 hours
			modulate = Color.WHITE
			if timer_label:
				timer_label.add_theme_color_override("font_color", Color(1, 1, 0.3))  # Yellow
			if name_label:
				name_label.text = "⚠️ " + part.get_display_name()

		"urgent":  # 1-6 hours
			modulate = Color(1.2, 1.0, 0.8)  # Orange tint
			if timer_label:
				timer_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2))  # Orange

		"critical":  # <1 hour
			modulate = Color(1.3, 0.8, 0.8)  # Red tint
			if timer_label:
				timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))  # Red
			if name_label:
				name_label.text = "🚨 " + part.get_display_name()

			# Add pulsing animation for critical
			_pulse_warning()

func _pulse_warning():
	"""Create pulsing animation for critical urgency"""
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(self, "modulate:a", 0.7, 0.5)
	pulse_tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_use_pressed():
	"""Handle use button click"""
	use_clicked.emit()

func _on_freeze_pressed():
	"""Handle freeze button click"""
	freeze_clicked.emit()
