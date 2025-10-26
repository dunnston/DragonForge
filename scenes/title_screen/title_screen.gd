extends Control
#TitleScreen.gd

@export var main_scene: PackedScene
@export var dragon_factory_scene: PackedScene

@onready var continue_button = $ButtonVBox/StartGameButton2

# Reference to settings UI and about UI
var settings_ui: Control = null
var about_ui: Control = null


func _ready() -> void:
	# Start menu background music
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_menu_music()

	# Disable continue button if no save exists
	if SaveLoadManager and SaveLoadManager.instance:
		if not SaveLoadManager.instance.has_save_file():
			continue_button.disabled = true


func _on_start_game_button_pressed() -> void:
	get_tree().change_scene_to_packed(dragon_factory_scene)


func _on_new_game_button_pressed() -> void:
	# Start opening letter and tutorial sequence
	# Note: Starting resources are initialized in opening_letter.gd after the letter is read
	NewPlayerInit.start_new_player_experience()


func _on_continue_button_pressed() -> void:
	# Set flag to load game when factory scene is ready
	if SaveLoadManager and SaveLoadManager.instance:
		SaveLoadManager.instance.should_load_on_start = true
	# Go to main game scene (will load save in _ready())
	get_tree().change_scene_to_packed(dragon_factory_scene)


func _on_settings_button_pressed() -> void:
	"""Open settings UI"""
	print("[TitleScreen] Opening settings")

	# Load and instantiate settings UI if not already created
	if not settings_ui:
		var settings_scene = load("res://scenes/ui/settings_ui.tscn")
		if settings_scene:
			settings_ui = settings_scene.instantiate()
			settings_ui.z_index = 200  # Above title screen
			settings_ui.z_as_relative = false
			add_child(settings_ui)

			# Connect closed signal
			if settings_ui.has_signal("closed"):
				settings_ui.closed.connect(_on_settings_closed)
		else:
			push_error("[TitleScreen] Failed to load settings UI scene!")
			return

	# Open settings
	if settings_ui and settings_ui.has_method("open"):
		settings_ui.open()

func _on_settings_closed():
	"""Called when settings UI is closed"""
	print("[TitleScreen] Settings closed")


func _on_about_game_button_pressed() -> void:
	"""Open about UI"""
	print("[TitleScreen] Opening about")

	# Load and instantiate about UI if not already created
	if not about_ui:
		var about_scene = load("res://scenes/ui/about_ui.tscn")
		if about_scene:
			about_ui = about_scene.instantiate()
			about_ui.z_index = 200  # Above title screen
			about_ui.z_as_relative = false
			add_child(about_ui)

			# Connect closed signal
			if about_ui.has_signal("closed"):
				about_ui.closed.connect(_on_about_closed)
		else:
			push_error("[TitleScreen] Failed to load about UI scene!")
			return

	# Open about
	if about_ui and about_ui.has_method("open"):
		about_ui.open()

func _on_about_closed():
	"""Called when about UI is closed"""
	print("[TitleScreen] About closed")


func _on_exit_game_button_pressed() -> void:
	get_tree().quit()
