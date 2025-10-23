extends Control
class_name DragonPickerModal

# Modal for selecting a dragon to assign to defense

const DragonCardSmallScene = preload("res://scenes/ui/dragon_card_small.tscn")

@onready var close_button = $Panel/MarginContainer/VBox/Header/CloseButton
@onready var title_label = $Panel/MarginContainer/VBox/Header/TitleLabel
@onready var dragon_grid = $Panel/MarginContainer/VBox/ScrollContainer/DragonGrid
@onready var info_label = $Panel/MarginContainer/VBox/InfoLabel

var dragon_factory: DragonFactory
var tower_index: int = -1

signal dragon_selected(dragon: Dragon, tower_index: int)
signal closed()

func _ready():
	# Hide by default
	visible = false

	# Connect close button
	close_button.pressed.connect(_on_close_pressed)

func open(factory: DragonFactory, for_tower_index: int = -1):
	"""Open the modal to pick a dragon"""
	dragon_factory = factory
	tower_index = for_tower_index
	visible = true

	# Update title
	if tower_index >= 0:
		title_label.text = "SELECT DRAGON FOR TOWER %d" % (tower_index + 1)
	else:
		title_label.text = "SELECT DRAGON"

	# Populate dragons
	_populate_dragons()

func _populate_dragons():
	"""Populate the grid with available dragons"""
	# Clear existing cards
	for child in dragon_grid.get_children():
		child.queue_free()

	if not dragon_factory:
		info_label.text = "No dragons available"
		return

	var all_dragons = dragon_factory.get_all_dragons()

	# Filter to show only idle and non-dead dragons
	var available_dragons: Array[Dragon] = []
	for dragon in all_dragons:
		if not dragon.is_dead and dragon.current_state == Dragon.DragonState.IDLE:
			available_dragons.append(dragon)

	if available_dragons.is_empty():
		info_label.text = "No idle dragons available for defense"
		return

	info_label.text = "Select a dragon (%d available)" % available_dragons.size()

	# Create card for each available dragon
	for dragon in available_dragons:
		var card = DragonCardSmallScene.instantiate()
		card.setup(dragon)

		# Connect click signal
		card.card_clicked.connect(_on_dragon_card_clicked)

		dragon_grid.add_child(card)

func _on_dragon_card_clicked(dragon: Dragon):
	"""Handle dragon selection"""
	if not dragon:
		return

	# Check if dragon can defend (not too fatigued)
	if dragon.fatigue_level > 0.5:
		print("[DragonPicker] %s is too fatigued to defend (%.0f%%)" % [dragon.dragon_name, dragon.fatigue_level * 100])
		_show_error("This dragon is too fatigued to defend!\n(Needs to be below 50% fatigue)")
		return

	# Emit selection
	dragon_selected.emit(dragon, tower_index)

	# Close modal
	visible = false
	closed.emit()

func _on_close_pressed():
	"""Close the modal without selecting"""
	visible = false
	closed.emit()

func _show_error(message: String):
	"""Show an error dialog"""
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.title = "Cannot Assign Dragon"
	dialog.dialog_text = message
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.popup_centered()
