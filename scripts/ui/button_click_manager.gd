extends Node
## Global Button Click Sound Manager
## Automatically adds click sounds to all buttons in the scene tree
##
## This autoload singleton scans for buttons and adds click sounds automatically

static var instance: Node

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	# Wait for scene tree to be ready
	await get_tree().process_frame

	# Connect to node added signal to catch new buttons
	get_tree().node_added.connect(_on_node_added)

	# Scan existing buttons
	_scan_and_connect_buttons(get_tree().root)

	print("[ButtonClickManager] Initialized - Auto-adding click sounds to buttons")

func _on_node_added(node: Node):
	"""Called when a new node is added to the scene tree"""
	if node is Button or node is TextureButton:
		_connect_button(node)

	# Also scan children of the new node
	_scan_and_connect_buttons(node)

func _scan_and_connect_buttons(root: Node):
	"""Recursively scan for buttons and connect click sounds"""
	for child in root.get_children():
		if child is Button or child is TextureButton:
			_connect_button(child)
		# Recurse into children
		_scan_and_connect_buttons(child)

func _connect_button(button: Node):
	"""Connect click and hover sounds to a button"""
	if not button:
		return

	# Check if already connected (avoid duplicate connections)
	if button.has_meta("button_click_connected"):
		return

	# Connect to pressed signal for click sound
	if button.has_signal("pressed"):
		if not button.pressed.is_connected(_on_button_clicked):
			button.pressed.connect(_on_button_clicked)

	# Connect to mouse_entered signal for hover sound
	if button.has_signal("mouse_entered"):
		if not button.mouse_entered.is_connected(_on_button_hovered):
			button.mouse_entered.connect(_on_button_hovered)

	# Mark as connected
	button.set_meta("button_click_connected", true)

func _on_button_clicked():
	"""Play button click sound"""
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_button_click()

func _on_button_hovered():
	"""Play button hover sound"""
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_button_hover()
