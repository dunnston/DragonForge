# Exploration Return Popup - Shows when dragon returns from exploration
extends Control

signal confirmed

@onready var dragon_name_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/DragonNameLabel
@onready var health_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatusSection/HealthLabel
@onready var hunger_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatusSection/HungerLabel
@onready var fatigue_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatusSection/FatigueLabel
@onready var rewards_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RewardsSection/RewardsContainer
@onready var confirm_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ConfirmButton

func _ready():
	confirm_button.pressed.connect(_on_confirm_pressed)
	hide()

func show_return(dragon: Dragon, rewards: Dictionary):
	"""Display the exploration return message with dragon status and rewards"""
	if not dragon:
		return

	# Update dragon info
	dragon_name_label.text = dragon.dragon_name

	# Update status
	health_label.text = "Health: %d/%d" % [dragon.current_health, dragon.get_health()]
	hunger_label.text = "Hunger: %d%%" % int(dragon.hunger_level * 100)
	fatigue_label.text = "Fatigue: %d%%" % int(dragon.fatigue_level * 100)

	# Apply color coding to health
	var health_percent = float(dragon.current_health) / float(dragon.get_health())
	if health_percent < 0.3:
		health_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))  # Red
	elif health_percent < 0.6:
		health_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))  # Yellow
	else:
		health_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4, 1))  # Green

	# Clear previous rewards
	for child in rewards_container.get_children():
		child.queue_free()

	# Display rewards
	_display_rewards(rewards)

	# Show popup
	show()

func _display_rewards(rewards: Dictionary):
	"""Create labels for each reward type"""

	# Gold
	if rewards.has("gold") and rewards["gold"] > 0:
		var gold_label = Label.new()
		gold_label.text = "+ %d Gold" % rewards["gold"]
		gold_label.add_theme_font_size_override("font_size", 16)
		gold_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))  # Gold color
		rewards_container.add_child(gold_label)

	# XP
	if rewards.has("xp") and rewards["xp"] > 0:
		var xp_label = Label.new()
		xp_label.text = "+ %d XP" % rewards["xp"]
		xp_label.add_theme_font_size_override("font_size", 16)
		xp_label.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))  # Yellow
		rewards_container.add_child(xp_label)

	# Dragon Parts
	if rewards.has("parts") and rewards["parts"].size() > 0:
		var parts_count = {}
		for part_element in rewards["parts"]:
			var element_name = DragonPart.Element.keys()[part_element]
			if not parts_count.has(element_name):
				parts_count[element_name] = 0
			parts_count[element_name] += 1

		for element_name in parts_count:
			var part_label = Label.new()
			part_label.text = "+ %d %s Part(s)" % [parts_count[element_name], element_name.capitalize()]
			part_label.add_theme_font_size_override("font_size", 16)
			part_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1, 1))  # Light blue
			rewards_container.add_child(part_label)

	# Items
	if rewards.has("items"):
		for item_type in rewards["items"]:
			var count = rewards["items"][item_type]
			var item_label = Label.new()
			var display_name = _get_item_display_name(item_type)
			item_label.text = "+ %d %s" % [count, display_name]
			item_label.add_theme_font_size_override("font_size", 16)
			item_label.add_theme_color_override("font_color", Color(0.8, 1, 0.8, 1))  # Light green
			rewards_container.add_child(item_label)

	# If no rewards, show a message
	if rewards_container.get_child_count() == 0:
		var no_rewards_label = Label.new()
		no_rewards_label.text = "No loot found..."
		no_rewards_label.add_theme_font_size_override("font_size", 16)
		no_rewards_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))  # Gray
		rewards_container.add_child(no_rewards_label)

func _get_item_display_name(item_type: String) -> String:
	"""Convert item type to display name"""
	match item_type:
		"treats": return "Treat(s)"
		"health_pots": return "Health Potion(s)"
		"food": return "Food"
		"toys": return "Toy(s)"
	return item_type.capitalize()

func _on_confirm_pressed():
	confirmed.emit()
	hide()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and visible:
		_on_confirm_pressed()
		get_viewport().set_input_as_handled()
