# Save Exit Popup - Shows when player presses ESC to confirm save & exit
extends Control

signal cancelled

@onready var save_exit_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/SaveExitButton
@onready var settings_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/SettingsButton
@onready var cancel_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/CancelButton
@onready var last_save_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LastSaveLabel

# Reference to settings UI
var settings_ui: Control = null

func _ready():
	save_exit_button.pressed.connect(_on_save_exit_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	hide()

func show_popup():
	"""Display the save and exit popup with last save info"""
	_update_last_save_label()
	show()

func _update_last_save_label():
	"""Update the label showing when the game was last saved"""
	if not SaveLoadManager or not SaveLoadManager.instance:
		last_save_label.text = "Last saved: Unknown"
		return

	var save_info = SaveLoadManager.instance.get_save_info()
	if save_info.is_empty() or not save_info.has("save_date"):
		last_save_label.text = "Last saved: Never"
	else:
		last_save_label.text = "Last saved: %s" % save_info["save_date"]

func _on_save_exit_pressed():
	"""Save the game and exit"""
	print("[SaveExitPopup] Saving and exiting...")

	# Disable buttons to prevent multiple clicks
	save_exit_button.disabled = true
	cancel_button.disabled = true

	# Update button text to show saving status
	save_exit_button.text = "Saving..."

	# Save the game
	if SaveLoadManager and SaveLoadManager.instance:
		var success = await SaveLoadManager.instance.save_game()

		if success:
			print("[SaveExitPopup] Game saved successfully, exiting...")
			save_exit_button.text = "Saved! Exiting..."
			# Wait a brief moment so player sees the confirmation
			await get_tree().create_timer(0.5).timeout
			# Exit the game
			get_tree().quit()
		else:
			print("[SaveExitPopup] ERROR: Failed to save game!")
			save_exit_button.text = "Save Failed!"
			save_exit_button.disabled = false
			cancel_button.disabled = false
			# Reset button text after a moment
			await get_tree().create_timer(1.5).timeout
			save_exit_button.text = "Save & Exit"
	else:
		push_error("[SaveExitPopup] ERROR: SaveLoadManager not found!")
		save_exit_button.text = "Error!"
		save_exit_button.disabled = false
		cancel_button.disabled = false

func _on_settings_pressed():
	"""Open settings UI"""
	print("[SaveExitPopup] Opening settings")

	# Load and instantiate settings UI if not already created
	if not settings_ui:
		var settings_scene = load("res://scenes/ui/settings_ui.tscn")
		if settings_scene:
			settings_ui = settings_scene.instantiate()
			settings_ui.z_index = 300  # Above save/exit popup
			settings_ui.z_as_relative = false
			get_parent().add_child(settings_ui)

			# Connect closed signal
			if settings_ui.has_signal("closed"):
				settings_ui.closed.connect(_on_settings_closed)

	# Open settings
	if settings_ui and settings_ui.has_method("open"):
		settings_ui.open()

func _on_settings_closed():
	"""Called when settings UI is closed"""
	print("[SaveExitPopup] Settings closed")

func _on_cancel_pressed():
	"""Cancel and return to game"""
	print("[SaveExitPopup] Cancelled exit")
	cancelled.emit()
	hide()

func _input(event):
	"""Handle ESC key to close the popup"""
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and visible:
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()
