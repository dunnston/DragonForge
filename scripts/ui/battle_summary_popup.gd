extends Control
class_name BattleSummaryPopup

## Shows cumulative battle results from waves that happened while player was away

signal closed

@onready var total_waves_label: Label = %TotalWavesLabel
@onready var victories_label: Label = %VictoriesLabel
@onready var defeats_label: Label = %DefeatsLabel
@onready var gold_label: Label = %GoldLabel
@onready var meat_label: Label = %MeatLabel
@onready var rewards_container: VBoxContainer = %RewardsContainer
@onready var confirm_button: Button = %ConfirmButton

func _ready():
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)

func setup(cumulative_data: Dictionary):
	"""Setup the popup with cumulative battle data

	Expected data:
	- total_waves: int
	- waves_won: int
	- waves_lost: int
	- gold: int
	- meat: int
	"""
	var total_waves = cumulative_data.get("total_waves", 0)
	var waves_won = cumulative_data.get("waves_won", 0)
	var waves_lost = cumulative_data.get("waves_lost", 0)
	var gold = cumulative_data.get("gold", 0)
	var meat = cumulative_data.get("meat", 0)

	# Update stats
	if total_waves_label:
		total_waves_label.text = "Total Waves: %d" % total_waves

	if victories_label:
		victories_label.text = "Victories: %d ✅" % waves_won

	if defeats_label:
		defeats_label.text = "Defeats: %d ❌" % waves_lost

	# Update rewards
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
		rewards_container.visible = (gold > 0 or meat > 0)

	show()

func _on_confirm_pressed():
	closed.emit()
	queue_free()
