extends PanelContainer
class_name LockedCard

# Card for locked tower slots

@onready var lock_icon = $VBox/LockIcon
@onready var locked_label = $VBox/LockedLabel

var tower_index: int = -1
var is_ready: bool = false

func _ready():
	is_ready = true

	# Darken the locked card
	modulate = Color(0.5, 0.5, 0.5)

	# Update if already set up
	if tower_index >= 0 and locked_label:
		locked_label.text = "LOCKED"

func setup(index: int):
	tower_index = index

	# Only update if _ready has been called
	if is_ready and locked_label:
		locked_label.text = "LOCKED"
