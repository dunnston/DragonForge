extends Control
class_name AboutUI

## About UI - Shows game information, credits, and premise

# Node references
@onready var close_button: Button = %CloseButton if has_node("%CloseButton") else null

# Signals
signal closed()

func _ready():
	# Start hidden
	visible = false

	# Setup close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	print("[AboutUI] Initialized")

func open():
	"""Open the about UI"""
	visible = true
	print("[AboutUI] Opened")

func _on_close_pressed():
	"""Close the about UI"""
	visible = false
	closed.emit()
	print("[AboutUI] Closed")
