# Exploration Return Popup - Shows when dragon returns from exploration
extends Control

signal confirmed  # Legacy signal (kept for compatibility)
signal closed  # Emitted when popup is closed (for NotificationQueueManager)

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

	# Dragon Parts (now uses item IDs)
	if rewards.has("parts") and rewards["parts"].size() > 0:
		var parts_count = {}
		for item_id in rewards["parts"]:
			# Get item from database to get the display name
			var item_name = item_id
			if ItemDatabase and ItemDatabase.instance:
				var item = ItemDatabase.instance.get_item(item_id)
				if item:
					item_name = item.name

			if not parts_count.has(item_name):
				parts_count[item_name] = 0
			parts_count[item_name] += 1

		for item_name in parts_count:
			var part_label = Label.new()
			part_label.text = "+ %d %s" % [parts_count[item_name], item_name]
			part_label.add_theme_font_size_override("font_size", 16)
			part_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1, 1))  # Light blue
			rewards_container.add_child(part_label)

	# Items (consumables like treats, health potions, etc.)
	if rewards.has("items"):
		for item_id in rewards["items"]:
			var count = rewards["items"][item_id]
			var item_label = Label.new()

			# Get display name from database
			var display_name = item_id
			if ItemDatabase and ItemDatabase.instance:
				var item = ItemDatabase.instance.get_item(item_id)
				if item:
					display_name = item.name

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

func _on_confirm_pressed():
	confirmed.emit()  # Legacy signal
	closed.emit()  # For NotificationQueueManager
	hide()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and visible:
		_on_confirm_pressed()
		get_viewport().set_input_as_handled()
