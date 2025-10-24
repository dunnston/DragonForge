extends PanelContainer
class_name DragonCard

## Reusable dragon card component with shader-based coloring
## Displays dragon visual, name, stats, and state

signal card_clicked(dragon: Dragon)

@onready var dragon_visual: DragonVisual = %DragonVisual
@onready var name_label: Label = %NameLabel
@onready var stats_label: Label = %StatsLabel
@onready var state_label: Label = %StateLabel

var dragon: Dragon
var _needs_update: bool = false

func _ready():
	gui_input.connect(_on_gui_input)

	# If dragon was set before _ready, update now
	if _needs_update:
		_update_display()

func set_dragon(new_dragon: Dragon):
	"""Set the dragon for this card and update all displays"""
	dragon = new_dragon

	# Check if nodes are ready (node is in scene tree)
	if is_node_ready():
		_update_display()
	else:
		# Defer update until _ready() is called
		_needs_update = true

func _update_display():
	if not dragon:
		return

	_needs_update = false

	# Update dragon visual colors
	if dragon_visual:
		dragon_visual.set_dragon_colors_from_parts(
			dragon.head_part,
			dragon.body_part,
			dragon.tail_part
		)

	# Update name
	if name_label:
		name_label.text = dragon.dragon_name if dragon.dragon_name else "Unnamed Dragon"

	# Update stats
	if stats_label:
		stats_label.text = "HP: %d/%d  Lvl: %d" % [
			dragon.current_health,
			dragon.get_health(),
			dragon.level
		]

	# Update state
	if state_label:
		state_label.text = _get_state_text(dragon.current_state)

func _get_state_text(state: Dragon.DragonState) -> String:
	match state:
		Dragon.DragonState.IDLE: return "Idle"
		Dragon.DragonState.DEFENDING: return "Defending"
		Dragon.DragonState.EXPLORING: return "Exploring"
		Dragon.DragonState.TRAINING: return "Training"
		Dragon.DragonState.RESTING: return "Resting"
		_: return "Unknown"

func refresh():
	"""Force a refresh of the display (called when dragon data changes)"""
	_update_display()

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(dragon)
