# Wave Result Popup - Shows victory or defeat after wave completes
extends Control

signal closed  # For NotificationQueueManager

@onready var overlay = $Overlay
@onready var panel = $Overlay/CenterContainer/PanelContainer
@onready var title_label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/TitleLabel
@onready var message_label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/MessageLabel
@onready var rewards_label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/RewardsLabel
@onready var close_button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	hide()

func setup(data: Dictionary):
	"""Setup the popup with wave result data

	Expected data:
	- victory: bool
	- rewards: Dictionary {gold, meat, etc}
	- wave_number: int (optional)
	"""
	var victory = data.get("victory", false)
	var rewards = data.get("rewards", {})
	var wave_number = data.get("wave_number", 0)

	# Set title based on victory/defeat
	if victory:
		title_label.text = "🐉 VICTORY! 🐉"
		title_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))  # Green
	else:
		title_label.text = "⚔ DEFEAT ⚔"
		title_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))  # Red

	# Set message
	if victory:
		message_label.text = "Your dragons have successfully defended!"
	else:
		message_label.text = "The raiders have breached your defenses!\nSome resources may have been stolen..."

	# Set rewards
	var rewards_text = "REWARDS:\n"
	if victory:
		if rewards.get("gold", 0) > 0:
			rewards_text += "💰 Gold: +%d\n" % rewards["gold"]
		if rewards.get("meat", 0) > 0:
			rewards_text += "🍖 Knight Meat: +%d\n" % rewards["meat"]
	else:
		rewards_text = ""  # No rewards on defeat

	rewards_label.text = rewards_text
	rewards_label.visible = victory  # Only show rewards on victory

	show()

func _on_close_pressed():
	closed.emit()
	queue_free()
