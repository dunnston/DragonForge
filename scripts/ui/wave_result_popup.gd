# Wave Result Popup - Shows victory or defeat after wave completes
extends Control
class_name WaveResultPopup

signal closed  # For NotificationQueueManager

@onready var title: Label = %Title
@onready var result_label: Label = %ResultLabel
@onready var message_label: Label = %MessageLabel
@onready var gold_label: Label = %GoldLabel
@onready var meat_label: Label = %MeatLabel
@onready var rewards_container: VBoxContainer = %RewardsContainer
@onready var confirm_button: Button = %ConfirmButton

func _ready():
	if confirm_button:
		confirm_button.pressed.connect(_on_close_pressed)

func setup(data: Dictionary):
	"""Setup the popup with wave result data

	Expected data:
	- victory: bool
	- rewards: Dictionary {gold, meat, etc}
	- wave_number: int (optional)
	"""
	var victory = data.get("victory", false)
	var rewards = data.get("rewards", {})

	# Set title and result based on victory/defeat
	if victory:
		if title:
			title.text = "Wave Complete!"
		if result_label:
			result_label.text = "🐉 VICTORY! 🐉"
		if message_label:
			message_label.text = "Your dragons have successfully defended!"
	else:
		if title:
			title.text = "Wave Failed!"
		if result_label:
			result_label.text = "⚔ DEFEAT ⚔"
		if message_label:
			message_label.text = "The raiders have breached your defenses!\nSome resources may have been stolen..."

	# Update rewards display
	var gold = rewards.get("gold", 0)
	var meat = rewards.get("meat", 0)

	if gold_label:
		if gold > 0:
			gold_label.text = "💰 Gold: +%d" % gold
			gold_label.visible = true
		else:
			gold_label.visible = false

	if meat_label:
		if meat > 0:
			meat_label.text = "🍖 Knight Meat: +%d" % meat
			meat_label.visible = true
		else:
			meat_label.visible = false

	# Hide rewards container if no rewards
	if rewards_container:
		rewards_container.visible = victory and (gold > 0 or meat > 0)

	show()

func _on_close_pressed():
	closed.emit()
	queue_free()
