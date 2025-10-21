extends Control

## Demo scene showing how to use ScientistPanel and ScientistHireModal

@onready var stitcher_panel = %StitcherPanel
@onready var caretaker_panel = %CaretakerPanel
@onready var trainer_panel = %TrainerPanel
@onready var hire_modal = %HireModal

func _ready():
	# Connect scientist panel signals
	stitcher_panel.hire_requested.connect(_on_hire_requested)
	stitcher_panel.fire_requested.connect(_on_fire_requested)

	caretaker_panel.hire_requested.connect(_on_hire_requested)
	caretaker_panel.fire_requested.connect(_on_fire_requested)

	trainer_panel.hire_requested.connect(_on_hire_requested)
	trainer_panel.fire_requested.connect(_on_fire_requested)

func _on_hire_requested(scientist_type: ScientistManager.ScientistType):
	"""Show hire modal when scientist panel is clicked"""
	hire_modal.show_for_scientist(scientist_type)

func _on_fire_requested(scientist_type: ScientistManager.ScientistType):
	"""Show confirmation dialog when fire button is clicked"""
	var scientist_name = ScientistManager.instance.get_scientist_name(scientist_type)

	var dialog = ConfirmationDialog.new()
	add_child(dialog)
	dialog.title = "Fire " + scientist_name + "?"
	dialog.dialog_text = "Are you sure you want to fire " + scientist_name + "?\n\nNo refund will be given.\nOngoing costs will stop."

	dialog.confirmed.connect(func():
		ScientistManager.instance.fire_scientist(scientist_type)
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	dialog.popup_centered()
