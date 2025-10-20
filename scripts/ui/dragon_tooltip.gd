# Dragon Tooltip - Shows detailed dragon info on hover
extends Control

@onready var name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/NameLabel
@onready var level_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatsSection/LevelLabel
@onready var attack_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatsSection/AttackLabel
@onready var health_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatsSection/HealthLabel
@onready var speed_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatsSection/SpeedLabel
@onready var state_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusSection/StateLabel
@onready var hunger_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusSection/HungerLabel
@onready var fatigue_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusSection/FatigueLabel
@onready var feed_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionsSection/FeedButton
@onready var train_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionsSection/TrainButton
@onready var rest_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionsSection/RestButton

var current_dragon: Dragon = null

func _ready():
	feed_button.pressed.connect(_on_feed_pressed)
	train_button.pressed.connect(_on_train_pressed)
	rest_button.pressed.connect(_on_rest_pressed)

func show_for_dragon(dragon: Dragon, at_position: Vector2):
	current_dragon = dragon
	_update_display()

	# Position tooltip near the mouse
	position = at_position + Vector2(10, 10)

	# Make sure tooltip doesn't go off screen
	var viewport_size = get_viewport_rect().size
	var tooltip_size = $PanelContainer.size

	if position.x + tooltip_size.x > viewport_size.x:
		position.x = viewport_size.x - tooltip_size.x - 10

	if position.y + tooltip_size.y > viewport_size.y:
		position.y = at_position.y - tooltip_size.y - 10

	show()

func _update_display():
	if not current_dragon:
		return

	# Name
	name_label.text = current_dragon.dragon_name if current_dragon.dragon_name else "Unnamed Dragon"

	# Stats
	level_label.text = "Level: %d" % current_dragon.level
	attack_label.text = "Attack: %d" % current_dragon.get_attack()
	health_label.text = "Health: %d/%d" % [current_dragon.current_health, current_dragon.get_health()]
	speed_label.text = "Speed: %d" % current_dragon.get_speed()

	# Status
	state_label.text = "State: %s" % _get_state_text(current_dragon.current_state)
	hunger_label.text = "Hunger: %d%%" % int(current_dragon.hunger_level * 100)
	fatigue_label.text = "Fatigue: %d%%" % int(current_dragon.fatigue_level * 100)

	# Update button states
	_update_button_states()

func _update_button_states():
	if not current_dragon:
		return

	# Can only perform actions if dragon is IDLE
	var is_idle = current_dragon.current_state == Dragon.DragonState.IDLE

	# Feed: only if hungry and idle
	feed_button.disabled = not is_idle or current_dragon.hunger_level < 0.1

	# Train: only if not too fatigued and idle
	train_button.disabled = not is_idle or current_dragon.fatigue_level > 0.8

	# Rest: only if fatigued and idle
	rest_button.disabled = not is_idle or current_dragon.fatigue_level < 0.1

func _get_state_text(state: Dragon.DragonState) -> String:
	match state:
		Dragon.DragonState.IDLE: return "Idle"
		Dragon.DragonState.DEFENDING: return "Defending"
		Dragon.DragonState.EXPLORING: return "Exploring"
		Dragon.DragonState.TRAINING: return "Training"
		Dragon.DragonState.RESTING: return "Resting"
		Dragon.DragonState.DEAD: return "Dead"
	return "Unknown"

func _on_feed_pressed():
	if current_dragon and DragonStateManager:
		DragonStateManager.feed_dragon(current_dragon)
		_update_display()

func _on_train_pressed():
	if current_dragon and DragonStateManager:
		DragonStateManager.start_training(current_dragon)
		_update_display()
		hide()  # Hide tooltip since dragon is no longer idle

func _on_rest_pressed():
	if current_dragon and DragonStateManager:
		DragonStateManager.start_resting(current_dragon)
		_update_display()
		hide()  # Hide tooltip since dragon is no longer idle

func hide_tooltip():
	hide()
