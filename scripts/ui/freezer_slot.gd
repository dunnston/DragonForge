extends PanelContainer
class_name FreezerSlot

## Individual freezer slot component
## Displays either a frozen part or an empty slot

# Node references
@onready var content_container = $MarginContainer/VBox
@onready var icon_texture = $MarginContainer/VBox/Icon
@onready var name_label = $MarginContainer/VBox/NameLabel
@onready var preserved_label = $MarginContainer/VBox/PreservedLabel
@onready var unfreeze_button = $MarginContainer/VBox/UnfreezeButton
@onready var empty_button = $MarginContainer/VBox/EmptyButton

# Signals
signal unfreeze_clicked
signal empty_clicked

# State
var slot_index: int = -1
var stored_part: DragonPart = null

func _ready():
	# Connect button signals
	if unfreeze_button:
		unfreeze_button.pressed.connect(_on_unfreeze_pressed)
	if empty_button:
		empty_button.pressed.connect(_on_empty_pressed)

func setup(index: int):
	"""Initialize the slot with its index"""
	slot_index = index

func set_part(part: DragonPart):
	"""Display a frozen part in this slot"""
	stored_part = part

	# Show occupied UI
	if icon_texture:
		var icon = part.get_icon()
		if icon:
			icon_texture.texture = icon
			icon_texture.visible = true
		else:
			icon_texture.visible = false

	if name_label:
		name_label.visible = true
		name_label.text = part.get_display_name()

	if preserved_label:
		preserved_label.visible = true
		preserved_label.text = "❄️ Preserved"

	if unfreeze_button:
		unfreeze_button.visible = true

	if empty_button:
		empty_button.visible = false

	# Apply frost visual effect
	modulate = Color(0.7, 0.9, 1.0)  # Blue tint

func set_empty():
	"""Display an empty slot"""
	stored_part = null

	# Hide occupied UI
	if icon_texture:
		icon_texture.visible = false

	if name_label:
		name_label.visible = false

	if preserved_label:
		preserved_label.visible = false

	if unfreeze_button:
		unfreeze_button.visible = false

	if empty_button:
		empty_button.visible = true
		empty_button.text = "[+]"

	# Remove frost effect
	modulate = Color.WHITE

	# Add dashed border effect (using StyleBox if available)
	# This would be better done with a custom theme

func _on_unfreeze_pressed():
	"""Handle unfreeze button click"""
	unfreeze_clicked.emit()

func _on_empty_pressed():
	"""Handle empty slot click"""
	empty_clicked.emit()
