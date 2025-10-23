extends PanelContainer
class_name TrainingLockedCard

# Card representing a locked training slot

@onready var lock_icon = $VBox/LockIcon
@onready var locked_label = $VBox/LockedLabel

func setup(slot_number: int):
	if lock_icon:
		lock_icon.text = "🔒"
	if locked_label:
		locked_label.text = "LOCKED"

	# Gray out appearance
	modulate = Color(0.5, 0.5, 0.5)
