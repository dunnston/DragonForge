extends PanelContainer

## Custom scientist panel UI that shows:
## - Black square with "Click to hire" when not hired
## - Scientist image when hired
## - Progress bar showing work progress
## - Fire button to dismiss scientist

signal hire_requested(scientist_type: ScientistManager.ScientistType)
signal fire_requested(scientist_type: ScientistManager.ScientistType)

@export var scientist_type: ScientistManager.ScientistType = ScientistManager.ScientistType.STITCHER

@onready var scientist_button: Button = %ScientistButton
@onready var placeholder_bg: ColorRect = %PlaceholderBG
@onready var placeholder_text: Label = %PlaceholderText
@onready var scientist_image: TextureRect = %ScientistImage
@onready var fire_button: Button = %FireButton
@onready var name_label: Label = %NameLabel
@onready var status_label: Label = %StatusLabel
@onready var progress_container: VBoxContainer = %ProgressContainer
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var progress_label: Label = %ProgressLabel

var scientist_texture: Texture2D
var is_hired: bool = false
var work_timer_duration: float = 60.0  # Default duration
var work_timer_elapsed: float = 0.0

func _ready():
	_load_scientist_image()

	# Wait for ScientistManager to be ready
	await get_tree().process_frame

	if ScientistManager.instance:
		ScientistManager.instance.scientist_hired.connect(_on_scientist_hired)
		ScientistManager.instance.scientist_fired.connect(_on_scientist_fired)
		ScientistManager.instance.scientist_action_performed.connect(_on_scientist_action)

	_update_visual_state()

func _process(delta: float):
	if is_hired and progress_container.visible:
		_update_progress_bar()

func _load_scientist_image():
	# Map scientist type to filename (without needing ScientistManager)
	var scientist_name = ""
	match scientist_type:
		ScientistManager.ScientistType.STITCHER:
			scientist_name = "sticher"  # Note: typo in actual filename
		ScientistManager.ScientistType.CARETAKER:
			scientist_name = "caretaker"
		ScientistManager.ScientistType.TRAINER:
			scientist_name = "trainer"

	if scientist_name == "":
		return

	var image_path = "res://assets/Icons/scientists/" + scientist_name + ".png"

	if ResourceLoader.exists(image_path):
		scientist_texture = load(image_path)
		scientist_image.texture = scientist_texture
	else:
		push_warning("Scientist image not found: " + image_path)

func _update_visual_state():
	if not ScientistManager.instance:
		return

	is_hired = ScientistManager.instance.is_scientist_hired(scientist_type)

	# Update name label
	name_label.text = ScientistManager.instance.get_scientist_name(scientist_type).to_upper()

	if is_hired:
		# Show scientist image
		placeholder_bg.visible = false
		placeholder_text.visible = false
		scientist_image.visible = true
		fire_button.visible = true

		# Update status
		var ongoing_cost = ScientistManager.instance.get_scientist_ongoing_cost(scientist_type)
		status_label.text = "Active (-" + str(ongoing_cost) + " gold/min)"
		status_label.add_theme_color_override("font_color", Color(0.2, 1, 0.2))

		# Show progress container
		progress_container.visible = true
		print("[ScientistPanel] Scientist hired! Progress container visible: %s" % progress_container.visible)

		# Set work timer duration based on scientist type
		match scientist_type:
			ScientistManager.ScientistType.STITCHER:
				work_timer_duration = 60.0
				progress_label.text = "Creating dragon..."
			ScientistManager.ScientistType.CARETAKER:
				work_timer_duration = 30.0
				progress_label.text = "Caring for dragons..."
			ScientistManager.ScientistType.TRAINER:
				work_timer_duration = 30.0
				progress_label.text = "Training dragons..."
	else:
		# Show placeholder
		placeholder_bg.visible = true
		placeholder_text.visible = true
		scientist_image.visible = false
		fire_button.visible = false

		# Update status
		var hire_cost = ScientistManager.instance.get_scientist_hire_cost(scientist_type)
		status_label.text = "Not hired (Cost: " + str(hire_cost) + " gold)"
		status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

		# Hide progress container
		progress_container.visible = false

func _update_progress_bar():
	if not ScientistManager.instance:
		return

	# Get the work timer for this scientist type
	var timer: Timer = null

	match scientist_type:
		ScientistManager.ScientistType.STITCHER:
			timer = ScientistManager.instance.get_stitcher_work_timer()
		ScientistManager.ScientistType.CARETAKER:
			timer = ScientistManager.instance.get_caretaker_work_timer()
		ScientistManager.ScientistType.TRAINER:
			timer = ScientistManager.instance.get_trainer_work_timer()

	if timer:
		var time_left = timer.time_left
		var wait_time = timer.wait_time
		var progress = 1.0 - (time_left / wait_time)
		progress_bar.value = progress

		# Debug removed to stop spam - progress bar is updating correctly!
	else:
		# Timer not found - try to debug why
		if scientist_type == ScientistManager.ScientistType.STITCHER:
			print("[ScientistPanel] WARNING: Stitcher timer is null!")

func _on_scientist_button_pressed():
	print("[ScientistPanel] Button pressed! is_hired: %s, scientist_type: %s" % [is_hired, scientist_type])
	if is_hired:
		# Already hired, do nothing (or could show info)
		pass
	else:
		# Request to hire
		print("[ScientistPanel] Emitting hire_requested signal for type: %s" % scientist_type)
		hire_requested.emit(scientist_type)

func _on_fire_button_pressed():
	# Stop the button press from propagating to scientist_button
	get_viewport().set_input_as_handled()
	fire_requested.emit(scientist_type)

func _on_scientist_hired(type: ScientistManager.ScientistType):
	if type == scientist_type:
		_update_visual_state()

func _on_scientist_fired(type: ScientistManager.ScientistType):
	if type == scientist_type:
		_update_visual_state()

func _on_scientist_action(type: ScientistManager.ScientistType, action_description: String):
	if type == scientist_type:
		# Reset progress bar when action completes
		progress_bar.value = 0.0
