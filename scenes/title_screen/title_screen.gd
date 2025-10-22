extends Control
#TitleScreen.gd

@export var main_scene: PackedScene
@export var dragon_factory_scene: PackedScene



func _ready() -> void:
	# Start menu background music
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_menu_music()


func _on_start_game_button_pressed() -> void:
	get_tree().change_scene_to_packed(dragon_factory_scene)


func _on_new_game_button_pressed() -> void:
	# Initialize starting resources (30 gold + 6 parts)
	NewPlayerInit.initialize_starting_resources()
	# Start opening letter and tutorial sequence
	NewPlayerInit.start_new_player_experience()


func _on_continue_button_pressed() -> void:
	# Load existing save
	if SaveLoadManager:
		SaveLoadManager.load_game()
	# Go to main game scene
	get_tree().change_scene_to_packed(dragon_factory_scene)


func _on_settings_button_pressed() -> void:
	pass


func _on_about_game_button_pressed() -> void:
	pass # Replace with function body.


func _on_exit_game_button_pressed() -> void:
	get_tree().quit()
