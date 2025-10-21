# DevMenu - Developer menu for adding items (Toggle with ` key)
extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var items_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ItemsContainer
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var clear_inventory_button: Button = $Panel/MarginContainer/VBoxContainer/Header/ClearButton
@onready var add_all_button: Button = $Panel/MarginContainer/VBoxContainer/Header/AddAllButton

var is_open: bool = false

func _ready():
	# Hide on start
	hide()

	# Connect buttons
	close_button.pressed.connect(_on_close_pressed)
	clear_inventory_button.pressed.connect(_on_clear_inventory_pressed)
	add_all_button.pressed.connect(_on_add_all_pressed)

	# Wait for ItemDatabase to load
	await get_tree().process_frame

	# Build item list
	_populate_items()

func _input(event):
	# Toggle with backtick key
	if event is InputEventKey and event.pressed and event.keycode == KEY_QUOTELEFT:
		toggle_menu()
		get_viewport().set_input_as_handled()

func toggle_menu():
	"""Toggle dev menu visibility"""
	is_open = !is_open

	if is_open:
		show()
		# Refresh inventory display
		_update_inventory_counts()
	else:
		hide()

func _populate_items():
	"""Create buttons for all items in the database"""
	if not ItemDatabase or not ItemDatabase.instance:
		print("[DevMenu] ItemDatabase not available!")
		return

	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()

	# Add section: Dragon Parts
	_add_section_label("DRAGON PARTS")

	# Group by element
	var elements = ["fire", "ice", "lightning", "nature", "shadow"]
	var part_types = ["head", "body", "tail"]

	for element in elements:
		for part_type in part_types:
			var item_id = "%s_%s" % [element, part_type]
			if ItemDatabase.instance.item_exists(item_id):
				_add_item_button(item_id)

	# Add separator
	_add_separator()

	# Add section: Consumables
	_add_section_label("CONSUMABLES")

	var consumables = ItemDatabase.instance.get_all_consumables()
	for item_id in consumables:
		_add_item_button(item_id)

func _add_section_label(text: String):
	"""Add a section header label"""
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))
	items_container.add_child(label)

func _add_separator():
	"""Add a visual separator"""
	var separator = HSeparator.new()
	items_container.add_child(separator)

func _add_item_button(item_id: String):
	"""Create a button for adding an item"""
	var item_data = ItemDatabase.instance.get_item_data(item_id)
	if item_data.is_empty():
		return

	# Container for item row
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# Item name label
	var name_label = Label.new()
	name_label.text = item_data.get("name", item_id)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_label)

	# Quantity in inventory label
	var count_label = Label.new()
	count_label.name = "CountLabel_" + item_id
	var current_count = 0
	if InventoryManager and InventoryManager.instance:
		current_count = InventoryManager.instance.get_item_count(item_id)
	count_label.text = "x%d" % current_count
	count_label.custom_minimum_size = Vector2(50, 0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	hbox.add_child(count_label)

	# Add +1 button
	var add_1_button = Button.new()
	add_1_button.text = "+1"
	add_1_button.custom_minimum_size = Vector2(50, 30)
	add_1_button.pressed.connect(_on_add_item.bind(item_id, 1))
	hbox.add_child(add_1_button)

	# Add +10 button
	var add_10_button = Button.new()
	add_10_button.text = "+10"
	add_10_button.custom_minimum_size = Vector2(50, 30)
	add_10_button.pressed.connect(_on_add_item.bind(item_id, 10))
	hbox.add_child(add_10_button)

	items_container.add_child(hbox)

func _on_add_item(item_id: String, quantity: int):
	"""Add item to inventory"""
	if not InventoryManager or not InventoryManager.instance:
		print("[DevMenu] InventoryManager not available!")
		return

	var success = InventoryManager.instance.add_item_by_id(item_id, quantity)

	if success:
		print("[DevMenu] Added %d x %s" % [quantity, item_id])
	else:
		print("[DevMenu] Failed to add %s (inventory full?)" % item_id)

	# Update count display
	_update_item_count(item_id)

func _update_item_count(item_id: String):
	"""Update the count label for a specific item"""
	var count_label_name = "CountLabel_" + item_id

	# Find the label
	for child in items_container.get_children():
		if child is HBoxContainer:
			for subchild in child.get_children():
				if subchild.name == count_label_name:
					var new_count = InventoryManager.instance.get_item_count(item_id)
					subchild.text = "x%d" % new_count
					return

func _update_inventory_counts():
	"""Update all item count displays"""
	if not InventoryManager or not InventoryManager.instance:
		return

	for child in items_container.get_children():
		if child is HBoxContainer:
			for subchild in child.get_children():
				if subchild.name.begins_with("CountLabel_"):
					var item_id = subchild.name.replace("CountLabel_", "")
					var count = InventoryManager.instance.get_item_count(item_id)
					subchild.text = "x%d" % count

func _on_close_pressed():
	"""Close the dev menu"""
	toggle_menu()

func _on_clear_inventory_pressed():
	"""Clear all items from inventory"""
	if not InventoryManager or not InventoryManager.instance:
		return

	InventoryManager.instance.clear_inventory()
	print("[DevMenu] Inventory cleared!")
	_update_inventory_counts()

func _on_add_all_pressed():
	"""Add all items to inventory (useful for testing)"""
	if not InventoryManager or not InventoryManager.instance:
		return

	InventoryManager.instance.add_starting_items()
	print("[DevMenu] Added starting items!")
	_update_inventory_counts()
