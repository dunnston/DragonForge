extends Control

# Enemy Scout Screen - Display incoming wave enemies before battle
# Shows enemy stats so player can strategically plan defense

# === NODE REFERENCES ===
@onready var close_button = %CloseButton
@onready var back_button = %BackButton
@onready var wave_info_label = %WaveInfo
@onready var enemy_container = %EnemyContainer

# === PROPERTIES ===
var scouted_enemies: Array = []
var wave_number: int = 0
var time_remaining: float = 0.0

func _ready():
	# Connect buttons
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if back_button:
		back_button.pressed.connect(_on_close_pressed)

	# Hide by default
	hide()

func show_scout_info(wave_num: int, enemies: Array, time_until_wave: float):
	"""Display scouted enemy information"""
	wave_number = wave_num
	scouted_enemies = enemies
	time_remaining = time_until_wave

	_update_wave_info()
	_populate_enemy_cards()

	show()
	print("[EnemyScoutScreen] Showing scout info for wave %d with %d enemies" % [wave_num, enemies.size()])

func _update_wave_info():
	"""Update wave countdown display"""
	if not wave_info_label:
		return

	var minutes = int(time_remaining / 60.0)
	var seconds = int(time_remaining) % 60

	wave_info_label.text = "Wave %d - %d:%02d until attack" % [wave_number, minutes, seconds]

func _populate_enemy_cards():
	"""Create enemy cards for each scouted enemy"""
	if not enemy_container:
		return

	# Clear existing cards
	for child in enemy_container.get_children():
		child.queue_free()

	# Create card for each enemy
	for i in scouted_enemies.size():
		var enemy = scouted_enemies[i]
		var card = _create_enemy_card(enemy, i + 1)
		enemy_container.add_child(card)

func _create_enemy_card(enemy: Dictionary, enemy_number: int) -> PanelContainer:
	"""Create a card displaying enemy stats"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)

	# Main container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)

	# Enemy number/type
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(left_vbox)

	var number_label = Label.new()
	number_label.text = "#%d" % enemy_number
	number_label.add_theme_font_size_override("font_size", 18)
	number_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	left_vbox.add_child(number_label)

	var type_label = Label.new()
	type_label.text = _get_enemy_type_name(enemy)
	type_label.add_theme_font_size_override("font_size", 16)
	type_label.add_theme_color_override("font_color", _get_enemy_type_color(enemy))
	left_vbox.add_child(type_label)

	# Stats section
	var stats_vbox = VBoxContainer.new()
	stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(stats_vbox)

	# Health stat
	var health_hbox = HBoxContainer.new()
	stats_vbox.add_child(health_hbox)

	var health_icon = Label.new()
	health_icon.text = "❤"
	health_icon.add_theme_font_size_override("font_size", 14)
	health_hbox.add_child(health_icon)

	var health_label = Label.new()
	health_label.text = "HP: %d" % enemy["health"]
	health_label.add_theme_font_size_override("font_size", 14)
	health_hbox.add_child(health_label)

	# Attack stat
	var attack_hbox = HBoxContainer.new()
	stats_vbox.add_child(attack_hbox)

	var attack_icon = Label.new()
	attack_icon.text = "⚔"
	attack_icon.add_theme_font_size_override("font_size", 14)
	attack_hbox.add_child(attack_icon)

	var attack_label = Label.new()
	attack_label.text = "ATK: %d" % enemy["attack"]
	attack_label.add_theme_font_size_override("font_size", 14)
	attack_hbox.add_child(attack_label)

	# Element (for wizards)
	if enemy.get("type") == "wizard":
		var element_hbox = HBoxContainer.new()
		stats_vbox.add_child(element_hbox)

		var element_icon = Label.new()
		element_icon.text = _get_element_icon(enemy.get("elemental_type", 0))
		element_icon.add_theme_font_size_override("font_size", 14)
		element_hbox.add_child(element_icon)

		var element_label = Label.new()
		element_label.text = "Element: %s" % _get_element_name(enemy.get("elemental_type", 0))
		element_label.add_theme_font_size_override("font_size", 14)
		element_label.add_theme_color_override("font_color", _get_element_color(enemy.get("elemental_type", 0)))
		element_hbox.add_child(element_label)

	return card

func _get_enemy_type_name(enemy: Dictionary) -> String:
	"""Get display name for enemy type"""
	match enemy.get("type", "unknown"):
		"knight":
			return "Knight"
		"wizard":
			return "Wizard"
		_:
			return "Unknown"

func _get_enemy_type_color(enemy: Dictionary) -> Color:
	"""Get color for enemy type"""
	match enemy.get("type", "unknown"):
		"knight":
			return Color(0.8, 0.8, 0.9)  # Light blue-gray
		"wizard":
			return Color(0.9, 0.7, 1.0)  # Light purple
		_:
			return Color(1, 1, 1)

func _get_element_name(element) -> String:
	"""Get display name for element"""
	match element:
		0: return "Fire"
		1: return "Water"
		2: return "Earth"
		3: return "Air"
		4: return "Lightning"
		_: return "Unknown"

func _get_element_icon(element) -> String:
	"""Get icon for element"""
	match element:
		0: return "🔥"  # Fire
		1: return "💧"  # Water
		2: return "🌿"  # Earth
		3: return "💨"  # Air
		4: return "⚡"  # Lightning
		_: return "?"

func _get_element_color(element) -> Color:
	"""Get color for element"""
	match element:
		0: return Color(1.0, 0.4, 0.2)  # Fire - red-orange
		1: return Color(0.3, 0.6, 1.0)  # Water - blue
		2: return Color(0.4, 0.8, 0.4)  # Earth - green
		3: return Color(0.9, 0.9, 0.9)  # Air - white
		4: return Color(1.0, 1.0, 0.3)  # Lightning - yellow
		_: return Color(1, 1, 1)

func _on_close_pressed():
	"""Handle close button"""
	hide()
	print("[EnemyScoutScreen] Closed scout screen")

func _process(delta):
	"""Update countdown timer"""
	if visible and time_remaining > 0:
		time_remaining -= delta
		_update_wave_info()

		# Auto-close if wave has started
		if time_remaining <= 0:
			_on_close_pressed()
