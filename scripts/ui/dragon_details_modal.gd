# Dragon Details Modal - Full modal dialog for dragon management
extends Control

signal dragon_updated

@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var name_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/NameLabel

# Stats
@onready var level_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsSection/LevelLabel
@onready var attack_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsSection/AttackLabel
@onready var health_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsSection/HealthLabel
@onready var speed_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsSection/SpeedLabel
@onready var xp_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsSection/XPLabel

# Status
@onready var state_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatusSection/StateLabel
@onready var hunger_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatusSection/HungerLabel
@onready var fatigue_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatusSection/FatigueLabel

# Parts
@onready var head_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PartsSection/HeadLabel
@onready var body_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PartsSection/BodyLabel
@onready var tail_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PartsSection/TailLabel

# Action buttons
@onready var feed_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsSection/ButtonsGrid/FeedButton
@onready var train_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsSection/ButtonsGrid/TrainButton
@onready var rest_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsSection/ButtonsGrid/RestButton
@onready var defend_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsSection/ButtonsGrid/DefendButton

var current_dragon: Dragon = null

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	feed_button.pressed.connect(_on_feed_pressed)
	train_button.pressed.connect(_on_train_pressed)
	rest_button.pressed.connect(_on_rest_pressed)
	defend_button.pressed.connect(_on_defend_pressed)
	hide()

func open_for_dragon(dragon: Dragon):
	current_dragon = dragon
	_update_display()
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

	# Calculate XP to next level
	var xp_needed = current_dragon.level * 100
	xp_label.text = "XP: %d/%d" % [current_dragon.experience, xp_needed]

	# Status
	state_label.text = "State: %s" % _get_state_text(current_dragon.current_state)
	hunger_label.text = "Hunger: %d%%" % int(current_dragon.hunger_level * 100)
	fatigue_label.text = "Fatigue: %d%%" % int(current_dragon.fatigue_level * 100)

	# Parts
	head_label.text = "Head: %s" % _get_element_name(current_dragon.head_part.element)
	body_label.text = "Body: %s" % _get_element_name(current_dragon.body_part.element)
	tail_label.text = "Tail: %s" % _get_element_name(current_dragon.tail_part.element)

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

	# Defend: only if idle
	defend_button.disabled = not is_idle

func _get_state_text(state: Dragon.DragonState) -> String:
	match state:
		Dragon.DragonState.IDLE: return "Idle"
		Dragon.DragonState.DEFENDING: return "Defending"
		Dragon.DragonState.EXPLORING: return "Exploring"
		Dragon.DragonState.TRAINING: return "Training"
		Dragon.DragonState.RESTING: return "Resting"
		Dragon.DragonState.DEAD: return "Dead"
	return "Unknown"

func _get_element_name(element: DragonPart.Element) -> String:
	return DragonPart.Element.keys()[element].capitalize()

func _on_close_pressed():
	hide()

func _on_feed_pressed():
	if current_dragon and DragonStateManager:
		DragonStateManager.feed_dragon(current_dragon)
		_update_display()
		dragon_updated.emit()

func _on_train_pressed():
	if current_dragon and DragonStateManager:
		DragonStateManager.start_training(current_dragon)
		_update_display()
		dragon_updated.emit()

func _on_rest_pressed():
	if current_dragon and DragonStateManager:
		DragonStateManager.start_resting(current_dragon)
		_update_display()
		dragon_updated.emit()

func _on_defend_pressed():
	if current_dragon and DefenseManager:
		DefenseManager.assign_dragon_to_defense(current_dragon)
		_update_display()
		dragon_updated.emit()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and visible:
		hide()
		get_viewport().set_input_as_handled()
