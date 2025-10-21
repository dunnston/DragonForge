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

# Exploration
@onready var exploration_status_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ExplorationSection/StatusLabel
@onready var explore_15_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ExplorationSection/DurationButtons/Explore15Button
@onready var explore_30_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ExplorationSection/DurationButtons/Explore30Button
@onready var explore_60_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ExplorationSection/DurationButtons/Explore60Button

var current_dragon: Dragon = null
var update_timer: Timer

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	feed_button.pressed.connect(_on_feed_pressed)
	train_button.pressed.connect(_on_train_pressed)
	rest_button.pressed.connect(_on_rest_pressed)
	defend_button.pressed.connect(_on_defend_pressed)

	# Exploration buttons
	explore_15_button.pressed.connect(_on_explore_pressed.bind(15))
	explore_30_button.pressed.connect(_on_explore_pressed.bind(30))
	explore_60_button.pressed.connect(_on_explore_pressed.bind(60))

	# Create update timer for exploration countdown
	update_timer = Timer.new()
	update_timer.wait_time = 1.0  # Update every second
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)

	# Connect to exploration signals
	if ExplorationManager and ExplorationManager.instance:
		ExplorationManager.instance.exploration_completed.connect(_on_exploration_completed)

	hide()

func open_for_dragon(dragon: Dragon):
	current_dragon = dragon
	_update_display()
	_update_exploration_button_labels()

	# Start update timer if dragon is exploring
	if current_dragon and current_dragon.current_state == Dragon.DragonState.EXPLORING:
		update_timer.start()
	else:
		update_timer.stop()

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
	var is_exploring = current_dragon.current_state == Dragon.DragonState.EXPLORING

	# Feed: only if hungry and idle
	feed_button.disabled = not is_idle or current_dragon.hunger_level < 0.1

	# Train: only if not too fatigued and idle
	train_button.disabled = not is_idle or current_dragon.fatigue_level > 0.8

	# Rest: only if fatigued and idle
	rest_button.disabled = not is_idle or current_dragon.fatigue_level < 0.1

	# Defend: only if idle
	defend_button.disabled = not is_idle

	# Exploration: only if idle and not too fatigued
	var can_explore = is_idle and current_dragon.fatigue_level <= 0.8
	explore_15_button.disabled = not can_explore
	explore_30_button.disabled = not can_explore
	explore_60_button.disabled = not can_explore

	# Update exploration status
	if is_exploring and ExplorationManager and ExplorationManager.instance:
		var remaining = ExplorationManager.instance.get_time_remaining(current_dragon)
		var minutes = int(remaining / 60)
		var seconds = remaining % 60
		exploration_status_label.text = "Exploring... Returns in %d:%02d" % [minutes, seconds]
		exploration_status_label.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
	elif not is_idle:
		exploration_status_label.text = "Dragon is %s" % _get_state_text(current_dragon.current_state)
		exploration_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	elif current_dragon.fatigue_level > 0.8:
		exploration_status_label.text = "Too fatigued to explore"
		exploration_status_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
	else:
		exploration_status_label.text = "Ready to explore!"
		exploration_status_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))

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

func _on_explore_pressed(duration_minutes: int):
	if not current_dragon or not ExplorationManager or not ExplorationManager.instance:
		return

	if ExplorationManager.instance.start_exploration(current_dragon, duration_minutes):
		_update_display()
		update_timer.start()
		dragon_updated.emit()
		print("Started %d minute exploration" % duration_minutes)

func _on_update_timer_timeout():
	"""Update exploration countdown every second"""
	if current_dragon and current_dragon.current_state == Dragon.DragonState.EXPLORING:
		_update_button_states()
	else:
		update_timer.stop()

func _on_exploration_completed(dragon: Dragon, rewards: Dictionary):
	"""Called when any dragon completes exploration"""
	# Only show popup if this is the current dragon being viewed
	if current_dragon and dragon.dragon_id == current_dragon.dragon_id:
		_show_exploration_return_popup(dragon, rewards)
		_update_display()
		update_timer.stop()
		dragon_updated.emit()

func _show_exploration_return_popup(dragon: Dragon, rewards: Dictionary):
	"""Show the exploration return popup with rewards"""
	# Load and show the return popup
	var popup_scene = load("res://scenes/ui/exploration_return_popup.tscn")
	if not popup_scene:
		print("ERROR: Could not load exploration_return_popup.tscn")
		return

	var popup = popup_scene.instantiate()
	get_tree().root.add_child(popup)
	popup.confirmed.connect(func():
		popup.queue_free()
	)
	popup.show_return(dragon, rewards)

func _update_exploration_button_labels():
	"""Update button labels based on DEV_MODE"""
	if not ExplorationManager or not ExplorationManager.instance:
		return

	var time_unit = "sec" if ExplorationManager.DEV_MODE else "min"
	explore_15_button.text = "15 %s" % time_unit
	explore_30_button.text = "30 %s" % time_unit
	explore_60_button.text = "60 %s" % time_unit

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and visible:
		hide()
		get_viewport().set_input_as_handled()
