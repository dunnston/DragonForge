extends PanelContainer
class_name TrainingSlotCard

# Individual training slot card showing dragon, progress, and controls

@onready var dragon_visual_container = $VBox/DragonVisualContainer
@onready var dragon_visual = $VBox/DragonVisualContainer/DragonVisual
@onready var dragon_name_label = $VBox/DragonInfo/NameLabel
@onready var level_label = $VBox/DragonInfo/LevelLabel
@onready var target_level_label = $VBox/DragonInfo/TargetLevelLabel
@onready var progress_bar = $VBox/ProgressContainer/ProgressBar
@onready var progress_label = $VBox/ProgressContainer/ProgressLabel
@onready var stats_container = $VBox/StatsGains
@onready var atk_label = $VBox/StatsGains/ATKLabel
@onready var hp_label = $VBox/StatsGains/HPLabel
@onready var spd_label = $VBox/StatsGains/SPDLabel
@onready var timer_label = $VBox/TimerLabel
@onready var remove_button = $VBox/ButtonContainer/RemoveButton
@onready var rush_button = $VBox/ButtonContainer/RushButton
@onready var assign_button = $VBox/AssignButton
@onready var collect_button = $VBox/CollectButton
@onready var no_dragon_label = $VBox/NoDragonLabel
@onready var dragon_info = $VBox/DragonInfo

var slot: TrainingSlot
var slot_id: int
var is_ready: bool = false

signal dragon_removed(slot_id: int)
signal dragon_assigned_clicked(slot_id: int)
signal dragon_collected(slot_id: int)
signal rush_clicked(slot_id: int)

func _ready():
	is_ready = true

	# Connect buttons
	if remove_button:
		remove_button.pressed.connect(_on_remove_button_pressed)
	if assign_button:
		assign_button.pressed.connect(_on_assign_button_pressed)
	if collect_button:
		collect_button.pressed.connect(_on_collect_button_pressed)
	if rush_button:
		rush_button.pressed.connect(_on_rush_button_pressed)

	# Make card clickable
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Update display if already setup
	if slot:
		_update_display()

func setup(training_slot: TrainingSlot):
	slot = training_slot
	slot_id = slot.slot_id

	if is_ready:
		_update_display()

func _process(_delta):
	if slot and slot.is_occupied():
		_update_progress()

func _update_display():
	if not slot or not is_ready:
		return

	if not slot.is_occupied():
		_show_empty_state()
	elif slot.is_training_complete():
		_show_ready_state()
	else:
		_show_training_state()

func _show_empty_state():
	"""Show empty slot waiting for dragon assignment"""
	if dragon_visual_container:
		dragon_visual_container.visible = false
	if dragon_info:
		dragon_info.visible = false
	if progress_bar:
		progress_bar.visible = false
	if progress_label:
		progress_label.visible = false
	if stats_container:
		stats_container.visible = false
	if timer_label:
		timer_label.visible = false
	if remove_button:
		remove_button.visible = false
	if rush_button:
		rush_button.visible = false
	if collect_button:
		collect_button.visible = false

	if assign_button:
		assign_button.visible = true
		assign_button.text = "Assign Dragon"
	if no_dragon_label:
		no_dragon_label.visible = true
		no_dragon_label.text = "Click to Assign Dragon"

	# Reset visual effects
	modulate = Color(1, 1, 1)

func _show_training_state():
	"""Show dragon currently training"""
	var dragon = slot.assigned_dragon

	if dragon_visual_container:
		dragon_visual_container.visible = true
	if dragon_info:
		dragon_info.visible = true
	if progress_bar:
		progress_bar.visible = true
	if progress_label:
		progress_label.visible = true
	if stats_container:
		stats_container.visible = true
	if timer_label:
		timer_label.visible = true
	if remove_button:
		remove_button.visible = true
	if rush_button:
		rush_button.visible = true
	if assign_button:
		assign_button.visible = false
	if collect_button:
		collect_button.visible = false
	if no_dragon_label:
		no_dragon_label.visible = false

	# Display dragon visual
	if dragon_visual and dragon:
		dragon_visual.set_dragon_colors_from_parts(
			dragon.head_part,
			dragon.body_part,
			dragon.tail_part
		)

	# Display dragon info
	if dragon_name_label and dragon:
		dragon_name_label.text = dragon.dragon_name
	if level_label and dragon:
		level_label.text = "Lv %d" % dragon.level
	if target_level_label and dragon:
		target_level_label.text = "→ Lv %d" % (dragon.level + 1)

	# Update stat gains
	if dragon:
		_update_stat_gains(dragon)

	_update_progress()

	# Reset visual effects
	modulate = Color(1, 1, 1)

func _show_ready_state():
	"""Show training completed, ready to collect"""
	_show_training_state()

	if remove_button:
		remove_button.visible = false
	if rush_button:
		rush_button.visible = false
	if collect_button:
		collect_button.visible = true
		collect_button.text = "COLLECT"

	if timer_label:
		timer_label.text = "READY!"
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # Gold

	# Add glow/pulse effect
	modulate = Color(1.2, 1.2, 1.0)  # Slight yellow tint

func _update_progress():
	if not slot or not slot.is_occupied():
		return

	var progress = slot.get_progress()

	if progress_bar:
		progress_bar.value = progress * 100

	if progress_label:
		progress_label.text = "%d%%" % int(progress * 100)

	var remaining = slot.get_time_remaining()
	if timer_label:
		timer_label.text = _format_time(remaining)

func _update_stat_gains(dragon: Dragon):
	"""Show what stats will be gained at next level"""
	# Base stat gains per level
	var atk_gain = 5
	var hp_gain = 15
	var spd_gain = 2

	# Adjust based on dragon parts (simplified)
	if dragon.head_part:
		atk_gain += dragon.head_part.attack_bonus

	if dragon.body_part:
		hp_gain += dragon.body_part.health_bonus

	if dragon.tail_part:
		spd_gain += dragon.tail_part.speed_bonus

	if atk_label:
		atk_label.text = "ATK +%d" % atk_gain
	if hp_label:
		hp_label.text = "HP +%d" % hp_gain
	if spd_label:
		spd_label.text = "SPD +%d" % spd_gain

func _format_time(seconds: int) -> String:
	"""Format seconds into readable time string"""
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	var secs = seconds % 60

	if hours > 0:
		return "%dh %dm" % [hours, minutes]
	elif minutes > 0:
		return "%dm %ds" % [minutes, secs]
	else:
		return "%ds" % secs

func _on_remove_button_pressed():
	dragon_removed.emit(slot_id)

func _on_assign_button_pressed():
	dragon_assigned_clicked.emit(slot_id)

func _on_collect_button_pressed():
	dragon_collected.emit(slot_id)

func _on_rush_button_pressed():
	rush_clicked.emit(slot_id)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Left click on empty slot to assign
			if not slot.is_occupied():
				dragon_assigned_clicked.emit(slot_id)

func _on_mouse_entered():
	# Hover effect
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2)

func _on_mouse_exited():
	# Reset scale
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

# Public method to refresh display
func refresh():
	_update_display()
