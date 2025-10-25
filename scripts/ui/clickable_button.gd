extends Button
## Reusable button script that plays click and hover sounds automatically
##
## Usage: Attach this script to any Button node to add automatic click and hover sounds
## The button will play sounds when clicked or hovered over

func _ready():
	# Connect to pressed signal to play click sound
	pressed.connect(_on_button_pressed)

	# Connect to mouse_entered signal to play hover sound
	mouse_entered.connect(_on_button_hovered)

func _on_button_pressed():
	# Play button click sound
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_button_click()

func _on_button_hovered():
	# Play button hover sound
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_button_hover()
