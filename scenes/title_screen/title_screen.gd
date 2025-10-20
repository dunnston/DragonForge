extends Control
#TitleScreen.gd

@export var main_scene: PackedScene 




func _ready() -> void:
	pass 


func _on_start_game_button_pressed() -> void:
	get_tree().change_scene_to_packed(main_scene)


func _on_settings_button_pressed() -> void:
	pass


func _on_about_game_button_pressed() -> void:
	pass # Replace with function body.


func _on_exit_game_button_pressed() -> void:
	get_tree().quit()
