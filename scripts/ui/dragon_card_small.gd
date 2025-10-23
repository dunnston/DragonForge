extends PanelContainer
class_name DragonCardSmall

# Small dragon card for grid display in Dragon Grounds

@onready var dragon_visual = $VBox/DragonVisualContainer/DragonVisual
@onready var name_label = $VBox/NameLabel
@onready var level_label = $VBox/LevelLabel
@onready var state_indicator = $VBox/StateIndicator

var dragon: Dragon
var is_ready: bool = false

signal card_clicked(dragon: Dragon)
signal card_hovered(dragon: Dragon)
signal card_unhovered()

func _ready():
	is_ready = true

	# Make clickable
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Update display if dragon already set
	if dragon:
		_update_display()

func setup(dragon_data: Dragon):
	dragon = dragon_data

	# Only update if _ready has been called
	if is_ready:
		_update_display()

func _update_display():
	if not dragon or not is_ready:
		return

	# Null safety
	if not name_label or not level_label or not state_indicator:
		return

	# Set dragon name
	name_label.text = dragon.dragon_name

	# Set level
	level_label.text = "Lv.%d" % dragon.level

	# Set state indicator
	var state_text = ""
	var state_color = Color.WHITE

	match dragon.current_state:
		Dragon.DragonState.IDLE:
			state_text = "Idle"
			state_color = Color(0.7, 0.7, 0.7)
		Dragon.DragonState.DEFENDING:
			state_text = "Defending"
			state_color = Color(1, 0.3, 0.3)
		Dragon.DragonState.EXPLORING:
			state_text = "Exploring"
			state_color = Color(0.3, 0.7, 1)
		Dragon.DragonState.TRAINING:
			state_text = "Training"
			state_color = Color(1, 1, 0.3)
		Dragon.DragonState.RESTING:
			state_text = "Resting"
			state_color = Color(0.5, 1, 0.5)

	state_indicator.text = state_text
	state_indicator.add_theme_color_override("font_color", state_color)

	# Set dragon visual colors from parts
	if dragon_visual:
		dragon_visual.set_dragon_colors_from_parts(
			dragon.head_part,
			dragon.body_part,
			dragon.tail_part
		)

	# Apply chimera glow if applicable
	if dragon.is_chimera_mutation:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(self, "modulate:a", 0.8, 1.0)
		tween.tween_property(self, "modulate:a", 1.0, 1.0)

	# Gray out if dead
	if dragon.is_dead:
		modulate = Color(0.4, 0.4, 0.4)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(dragon)

func _on_mouse_entered():
	# Emit hover signal with dragon data
	card_hovered.emit(dragon)

	# Scale up slightly
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)

func _on_mouse_exited():
	# Emit unhover signal
	card_unhovered.emit()

	# Reset scale
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

func refresh():
	_update_display()
