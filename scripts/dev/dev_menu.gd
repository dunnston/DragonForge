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
		# Refresh dragon list in case new dragons were created
		_refresh_dragon_selector()
		# Refresh save info
		_refresh_save_info()
		# Refresh gold display
		_refresh_gold_display()
	else:
		hide()

func _refresh_gold_display():
	"""Refresh the gold label"""
	var label = items_container.get_node_or_null("GoldLabel")
	if label:
		_update_gold_label(label)

func _refresh_dragon_selector():
	"""Refresh the dragon selector dropdown"""
	# Find the dragon selector in the items container
	for child in items_container.get_children():
		if child is HBoxContainer:
			for subchild in child.get_children():
				if subchild is OptionButton and subchild.name == "DragonSelector":
					_refresh_dragon_list(subchild)
					return

func _refresh_save_info():
	"""Refresh the save info label"""
	var label = items_container.get_node_or_null("SaveInfoLabel")
	if label:
		_update_save_info_label(label)

var current_dragon: Dragon = null

func _populate_items():
	"""Create buttons for all items in the database"""
	if not ItemDatabase or not ItemDatabase.instance:
		print("[DevMenu] ItemDatabase not available!")
		return

	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()

	# Add section: Save/Load Controls
	_add_save_load_section()

	_add_separator()

	# Add section: Resources (Gold & Parts)
	_add_resources_section()

	_add_separator()

	# Add section: Dragon Creation
	_add_dragon_creation_section()

	_add_separator()

	# Add section: Dragon Debug Controls
	_add_dragon_debug_section()

	_add_separator()

	# Add section: Defense Debug Controls
	_add_defense_debug_section()

	_add_separator()

	# Add section: Pet Debug Controls
	_add_pet_debug_section()

	_add_separator()

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

# === SAVE/LOAD SECTION ===

func _add_save_load_section():
	"""Add save/load controls"""
	_add_section_label("SAVE / LOAD SYSTEM")

	# Save info label
	var save_info_label = Label.new()
	save_info_label.name = "SaveInfoLabel"
	save_info_label.add_theme_font_size_override("font_size", 12)
	save_info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	_update_save_info_label(save_info_label)
	items_container.add_child(save_info_label)

	# Save/Load buttons row
	var save_load_hbox = HBoxContainer.new()
	save_load_hbox.add_theme_constant_override("separation", 10)

	var save_button = Button.new()
	save_button.text = "Save Game"
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(_on_save_game_pressed)
	save_load_hbox.add_child(save_button)

	var load_button = Button.new()
	load_button.text = "Load Game"
	load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_button.pressed.connect(_on_load_game_pressed)
	save_load_hbox.add_child(load_button)

	items_container.add_child(save_load_hbox)

	# Delete save button
	var delete_button = Button.new()
	delete_button.text = "Delete Save File"
	delete_button.pressed.connect(_on_delete_save_pressed)
	delete_button.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1))
	items_container.add_child(delete_button)

	# Auto-save toggle
	var auto_save_hbox = HBoxContainer.new()
	var auto_save_label = Label.new()
	auto_save_label.text = "Auto-save:"
	auto_save_hbox.add_child(auto_save_label)

	var auto_save_check = CheckButton.new()
	auto_save_check.name = "AutoSaveCheckbox"
	auto_save_check.button_pressed = SaveLoadManager.instance.auto_save_enabled if SaveLoadManager and SaveLoadManager.instance else true
	auto_save_check.toggled.connect(_on_auto_save_toggled)
	auto_save_hbox.add_child(auto_save_check)

	var auto_save_info = Label.new()
	auto_save_info.text = "(every 2 minutes)"
	auto_save_info.add_theme_font_size_override("font_size", 11)
	auto_save_info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	auto_save_hbox.add_child(auto_save_info)

	items_container.add_child(auto_save_hbox)

func _update_save_info_label(label: Label):
	"""Update the save info label with current save file info"""
	if not SaveLoadManager or not SaveLoadManager.instance:
		label.text = "SaveLoadManager not available"
		return

	if SaveLoadManager.instance.has_save_file():
		var save_info = SaveLoadManager.instance.get_save_info()
		label.text = "Save exists: %s\nDragons: %d | Gold: %d" % [
			save_info.get("save_date", "Unknown"),
			save_info.get("dragon_count", 0),
			save_info.get("gold", 0)
		]
	else:
		label.text = "No save file found"

func _on_save_game_pressed():
	"""Save the current game"""
	if not SaveLoadManager or not SaveLoadManager.instance:
		print("[DevMenu] SaveLoadManager not available!")
		return

	print("[DevMenu] Saving game...")
	await SaveLoadManager.instance.save_game()

	# Update save info label
	var label = items_container.get_node_or_null("SaveInfoLabel")
	if label:
		_update_save_info_label(label)

func _on_load_game_pressed():
	"""Load the saved game"""
	if not SaveLoadManager or not SaveLoadManager.instance:
		print("[DevMenu] SaveLoadManager not available!")
		return

	print("[DevMenu] Loading game...")
	await SaveLoadManager.instance.load_game()

	# Refresh UI
	_update_inventory_counts()
	_refresh_dragon_selector()

	# Update save info label
	var label = items_container.get_node_or_null("SaveInfoLabel")
	if label:
		_update_save_info_label(label)

func _on_delete_save_pressed():
	"""Delete the save file"""
	if not SaveLoadManager or not SaveLoadManager.instance:
		print("[DevMenu] SaveLoadManager not available!")
		return

	if SaveLoadManager.instance.delete_save_file():
		print("[DevMenu] Save file deleted")
	else:
		print("[DevMenu] No save file to delete")

	# Update save info label
	var label = items_container.get_node_or_null("SaveInfoLabel")
	if label:
		_update_save_info_label(label)

func _on_auto_save_toggled(enabled: bool):
	"""Toggle auto-save on/off"""
	if not SaveLoadManager or not SaveLoadManager.instance:
		return

	SaveLoadManager.instance.set_auto_save_enabled(enabled)
	print("[DevMenu] Auto-save %s" % ("enabled" if enabled else "disabled"))

# === RESOURCES SECTION ===

func _add_resources_section():
	"""Add resource controls (gold and parts)"""
	_add_section_label("RESOURCES")

	# Gold controls
	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.add_theme_font_size_override("font_size", 12)
	gold_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))  # Gold color
	_update_gold_label(gold_label)
	items_container.add_child(gold_label)

	var gold_hbox = HBoxContainer.new()
	_add_button_to_hbox(gold_hbox, "+100 Gold", func(): _add_gold(100))
	_add_button_to_hbox(gold_hbox, "+1000 Gold", func(): _add_gold(1000))
	_add_button_to_hbox(gold_hbox, "+10000 Gold", func(): _add_gold(10000))
	items_container.add_child(gold_hbox)

	# Dragon Parts controls
	var parts_label = Label.new()
	parts_label.text = "Dragon Parts:"
	parts_label.add_theme_font_size_override("font_size", 12)
	items_container.add_child(parts_label)

	var parts_hbox = HBoxContainer.new()
	_add_button_to_hbox(parts_hbox, "+10 All Parts", _add_all_parts_10)
	_add_button_to_hbox(parts_hbox, "+50 All Parts", _add_all_parts_50)
	items_container.add_child(parts_hbox)

func _update_gold_label(label: Label):
	"""Update the gold display"""
	var current_gold = 0
	if TreasureVault and TreasureVault.instance:
		current_gold = TreasureVault.instance.gold
	label.text = "Gold: %d" % current_gold

func _add_gold(amount: int):
	"""Add gold to the player"""
	if not TreasureVault or not TreasureVault.instance:
		print("[DevMenu] TreasureVault not available!")
		return

	TreasureVault.instance.add_gold(amount)
	print("[DevMenu] Added %d gold (Total: %d)" % [amount, TreasureVault.instance.gold])

	# Update gold label
	var label = items_container.get_node_or_null("GoldLabel")
	if label:
		_update_gold_label(label)

func _add_all_parts_10():
	"""Add 10 of each dragon part"""
	_add_all_parts(10)

func _add_all_parts_50():
	"""Add 50 of each dragon part"""
	_add_all_parts(50)

func _add_all_parts(amount: int):
	"""Add a specific amount of each dragon part"""
	if not InventoryManager or not InventoryManager.instance:
		print("[DevMenu] InventoryManager not available!")
		return

	var part_ids = [
		"fire_head", "fire_body", "fire_tail",
		"ice_head", "ice_body", "ice_tail",
		"lightning_head", "lightning_body", "lightning_tail",
		"nature_head", "nature_body", "nature_tail",
		"shadow_head", "shadow_body", "shadow_tail"
	]

	for part_id in part_ids:
		InventoryManager.instance.add_item_by_id(part_id, amount)

	print("[DevMenu] Added %d of each dragon part type" % amount)

# === DRAGON CREATION SECTION ===

func _add_dragon_creation_section():
	"""Add dragon creation controls"""
	_add_section_label("DRAGON CREATION")

	# Quick create buttons
	var quick_create_hbox = HBoxContainer.new()
	_add_button_to_hbox(quick_create_hbox, "Create Random Dragon", _create_random_dragon)
	_add_button_to_hbox(quick_create_hbox, "Create Pure Fire", func(): _create_pure_dragon(DragonPart.Element.FIRE))
	items_container.add_child(quick_create_hbox)

	var quick_create_hbox2 = HBoxContainer.new()
	_add_button_to_hbox(quick_create_hbox2, "Create Pure Ice", func(): _create_pure_dragon(DragonPart.Element.ICE))
	_add_button_to_hbox(quick_create_hbox2, "Create Pure Lightning", func(): _create_pure_dragon(DragonPart.Element.LIGHTNING))
	items_container.add_child(quick_create_hbox2)

	var quick_create_hbox3 = HBoxContainer.new()
	_add_button_to_hbox(quick_create_hbox3, "Create Pure Nature", func(): _create_pure_dragon(DragonPart.Element.NATURE))
	_add_button_to_hbox(quick_create_hbox3, "Create Pure Shadow", func(): _create_pure_dragon(DragonPart.Element.SHADOW))
	items_container.add_child(quick_create_hbox3)

	# Create 5 random dragons button
	var batch_btn = Button.new()
	batch_btn.text = "🐉 Create 5 Random Dragons"
	batch_btn.pressed.connect(_create_5_random_dragons)
	batch_btn.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))
	items_container.add_child(batch_btn)

func _get_dragon_factory() -> DragonFactory:
	"""Get the DragonFactory from the factory manager"""
	var factory_manager_nodes = get_tree().get_nodes_in_group("factory_manager")
	if factory_manager_nodes.is_empty():
		return null

	var factory_manager = factory_manager_nodes[0]
	if factory_manager.has_method("get") and factory_manager.get("factory"):
		return factory_manager.get("factory")

	return null

func _create_random_dragon():
	"""Create a dragon with random parts"""
	var factory = _get_dragon_factory()
	if not factory:
		print("[DevMenu] DragonFactory not available!")
		return

	var elements = [
		DragonPart.Element.FIRE,
		DragonPart.Element.ICE,
		DragonPart.Element.LIGHTNING,
		DragonPart.Element.NATURE,
		DragonPart.Element.SHADOW
	]

	var head = elements.pick_random()
	var body = elements.pick_random()
	var tail = elements.pick_random()

	# Get DragonPart objects from PartLibrary
	var head_part = PartLibrary.instance.get_part_by_element_and_type(head, DragonPart.PartType.HEAD)
	var body_part = PartLibrary.instance.get_part_by_element_and_type(body, DragonPart.PartType.BODY)
	var tail_part = PartLibrary.instance.get_part_by_element_and_type(tail, DragonPart.PartType.TAIL)

	var dragon = factory.create_dragon(head_part, body_part, tail_part)
	if dragon:
		print("[DevMenu] Created random dragon: %s" % dragon.dragon_name)
		_refresh_dragon_selector()
	else:
		print("[DevMenu] Failed to create dragon!")

func _create_pure_dragon(element: DragonPart.Element):
	"""Create a pure elemental dragon (all parts same element)"""
	var factory = _get_dragon_factory()
	if not factory:
		print("[DevMenu] DragonFactory not available!")
		return

	# Get DragonPart objects from PartLibrary
	var head_part = PartLibrary.instance.get_part_by_element_and_type(element, DragonPart.PartType.HEAD)
	var body_part = PartLibrary.instance.get_part_by_element_and_type(element, DragonPart.PartType.BODY)
	var tail_part = PartLibrary.instance.get_part_by_element_and_type(element, DragonPart.PartType.TAIL)

	var dragon = factory.create_dragon(head_part, body_part, tail_part)
	if dragon:
		var element_name = DragonPart.Element.keys()[element]
		print("[DevMenu] Created pure %s dragon: %s" % [element_name, dragon.dragon_name])
		_refresh_dragon_selector()
	else:
		print("[DevMenu] Failed to create dragon!")

func _create_5_random_dragons():
	"""Create 5 random dragons at once"""
	for i in 5:
		_create_random_dragon()
	print("[DevMenu] Created 5 random dragons!")

# === DRAGON DEBUG SECTION ===

func _add_dragon_debug_section():
	"""Add dragon debugging controls"""
	_add_section_label("DRAGON DEBUG")

	# Dragon selector
	var selector_hbox = HBoxContainer.new()
	var selector_label = Label.new()
	selector_label.text = "Select Dragon:"
	selector_hbox.add_child(selector_label)

	var dragon_selector = OptionButton.new()
	dragon_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dragon_selector.item_selected.connect(_on_dragon_selected)
	dragon_selector.name = "DragonSelector"
	selector_hbox.add_child(dragon_selector)
	items_container.add_child(selector_hbox)

	# Populate dragons
	_refresh_dragon_list(dragon_selector)

	# Hunger controls
	var hunger_label = Label.new()
	hunger_label.text = "Hunger:"
	hunger_label.add_theme_font_size_override("font_size", 12)
	items_container.add_child(hunger_label)

	var hunger_hbox = HBoxContainer.new()
	_add_button_to_hbox(hunger_hbox, "0%", func(): _set_dragon_hunger(0.0))
	_add_button_to_hbox(hunger_hbox, "50%", func(): _set_dragon_hunger(0.5))
	_add_button_to_hbox(hunger_hbox, "100%", func(): _set_dragon_hunger(1.0))
	items_container.add_child(hunger_hbox)

	# Fatigue controls
	var fatigue_label = Label.new()
	fatigue_label.text = "Fatigue:"
	fatigue_label.add_theme_font_size_override("font_size", 12)
	items_container.add_child(fatigue_label)

	var fatigue_hbox = HBoxContainer.new()
	_add_button_to_hbox(fatigue_hbox, "0%", func(): _set_dragon_fatigue(0.0))
	_add_button_to_hbox(fatigue_hbox, "50%", func(): _set_dragon_fatigue(0.5))
	_add_button_to_hbox(fatigue_hbox, "100%", func(): _set_dragon_fatigue(1.0))
	items_container.add_child(fatigue_hbox)

	# Health controls
	var health_label = Label.new()
	health_label.text = "Health:"
	health_label.add_theme_font_size_override("font_size", 12)
	items_container.add_child(health_label)

	var health_hbox = HBoxContainer.new()
	_add_button_to_hbox(health_hbox, "Damage 25%", func(): _damage_dragon(0.25))
	_add_button_to_hbox(health_hbox, "Damage 50%", func(): _damage_dragon(0.5))
	_add_button_to_hbox(health_hbox, "Heal Full", _heal_dragon_full)
	items_container.add_child(health_hbox)

	# Level controls
	var level_label = Label.new()
	level_label.text = "Level & XP:"
	level_label.add_theme_font_size_override("font_size", 12)
	items_container.add_child(level_label)

	var level_hbox = HBoxContainer.new()
	_add_button_to_hbox(level_hbox, "+1 Level", _level_up_dragon)
	_add_button_to_hbox(level_hbox, "Max Level", _max_level_dragon)
	_add_button_to_hbox(level_hbox, "+100 XP", func(): _add_xp_dragon(100))
	items_container.add_child(level_hbox)

	# Time controls
	var time_label = Label.new()
	time_label.text = "Time Passage:"
	time_label.add_theme_font_size_override("font_size", 12)
	items_container.add_child(time_label)

	var time_hbox = HBoxContainer.new()
	_add_button_to_hbox(time_hbox, "30 min", func(): _simulate_time(0.5))
	_add_button_to_hbox(time_hbox, "1 hour", func(): _simulate_time(1.0))
	_add_button_to_hbox(time_hbox, "2 hours", func(): _simulate_time(2.0))
	items_container.add_child(time_hbox)

	# Mutation button
	var mutation_btn = Button.new()
	mutation_btn.text = "Force Chimera Mutation"
	mutation_btn.pressed.connect(_force_mutation)
	items_container.add_child(mutation_btn)

	# Kill Dragon button (for testing death system)
	var kill_btn = Button.new()
	kill_btn.text = "💀 Kill Dragon (Test Death System)"
	kill_btn.pressed.connect(_kill_dragon)
	kill_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1))
	items_container.add_child(kill_btn)

	# Reset button
	var reset_btn = Button.new()
	reset_btn.text = "Reset Dragon to Perfect Condition"
	reset_btn.pressed.connect(_reset_dragon)
	items_container.add_child(reset_btn)

func _add_button_to_hbox(hbox: HBoxContainer, text: String, callback: Callable):
	"""Helper to add a button to an HBoxContainer"""
	var btn = Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(callback)
	hbox.add_child(btn)

func _refresh_dragon_list(selector: OptionButton):
	"""Populate dragon selector (excluding dead dragons)"""
	selector.clear()

	if not DragonStateManager or not DragonStateManager.instance:
		selector.add_item("No dragons available")
		return

	var all_dragons = DragonStateManager.instance.managed_dragons.values()

	# Filter out dead dragons
	var living_dragons = []
	for dragon in all_dragons:
		if not dragon.is_dead:
			living_dragons.append(dragon)

	if living_dragons.is_empty():
		selector.add_item("No living dragons")
		current_dragon = null
		return

	for i in range(living_dragons.size()):
		var dragon = living_dragons[i]
		selector.add_item(dragon.dragon_name, i)

	# Auto-select first living dragon
	if living_dragons.size() > 0:
		selector.select(0)
		current_dragon = living_dragons[0]

func _on_dragon_selected(index: int):
	"""Dragon selected in dropdown"""
	if not DragonStateManager or not DragonStateManager.instance:
		return

	# Get only living dragons (same filter as refresh)
	var all_dragons = DragonStateManager.instance.managed_dragons.values()
	var living_dragons = []
	for dragon in all_dragons:
		if not dragon.is_dead:
			living_dragons.append(dragon)

	if index >= 0 and index < living_dragons.size():
		current_dragon = living_dragons[index]
		print("[DevMenu] Selected dragon: %s" % current_dragon.dragon_name)

# === DRAGON DEBUG FUNCTIONS ===

func _set_dragon_hunger(percent: float):
	if current_dragon and DragonStateManager.instance:
		DragonStateManager.instance.force_hunger(current_dragon, percent)

func _set_dragon_fatigue(percent: float):
	if current_dragon and DragonStateManager.instance:
		DragonStateManager.instance.force_fatigue(current_dragon, percent)

func _damage_dragon(percent: float):
	if current_dragon and DragonStateManager.instance:
		DragonStateManager.instance.force_damage(current_dragon, percent)

func _heal_dragon_full():
	if current_dragon:
		current_dragon.current_health = current_dragon.total_health
		if DragonStateManager.instance:
			DragonStateManager.instance.dragon_health_changed.emit(current_dragon, current_dragon.current_health, current_dragon.total_health)
		print("🧪 DEBUG: Fully healed %s" % current_dragon.dragon_name)

func _level_up_dragon():
	if current_dragon and DragonStateManager.instance:
		DragonStateManager.instance.force_level_up(current_dragon)

func _max_level_dragon():
	if current_dragon and DragonStateManager.instance:
		DragonStateManager.instance.force_level_up(current_dragon, 10)

func _add_xp_dragon(amount: int):
	if current_dragon and DragonStateManager.instance:
		DragonStateManager.instance.gain_experience(current_dragon, amount)
		print("🧪 DEBUG: Added %d XP to %s" % [amount, current_dragon.dragon_name])

func _simulate_time(hours: float):
	if current_dragon and DragonStateManager.instance:
		DragonStateManager.instance.simulate_time_passage(current_dragon, hours)

func _force_mutation():
	if current_dragon and DragonStateManager.instance:
		DragonStateManager.instance.force_mutation(current_dragon)

func _reset_dragon():
	if current_dragon and DragonStateManager.instance:
		DragonStateManager.instance.reset_dragon_state(current_dragon)

func _kill_dragon():
	"""Kill the current dragon and trigger the death system"""
	print("\n🔪 [DevMenu] _kill_dragon() called")

	if not current_dragon:
		print("❌ [DevMenu] No dragon selected!")
		return

	if current_dragon.is_dead:
		print("⚠️ [DevMenu] Dragon is already dead!")
		return

	print("✅ [DevMenu] Killing dragon: %s" % current_dragon.dragon_name)
	print("   Current health: %d" % current_dragon.current_health)
	print("   Current state: %s" % Dragon.DragonState.keys()[current_dragon.current_state])

	# Kill the dragon
	current_dragon.is_dead = true
	current_dragon.current_state = Dragon.DragonState.DEAD
	current_dragon.current_health = 0

	print("💀 [DevMenu] Dragon marked as dead")
	print("   is_dead: %s" % current_dragon.is_dead)
	print("   health: %d" % current_dragon.current_health)
	print("   state: %s" % Dragon.DragonState.keys()[current_dragon.current_state])

	# Trigger death system with combat cause (most generous recovery)
	print("🎯 [DevMenu] Calling DragonDeathManager.handle_dragon_death()")
	if DragonDeathManager and DragonDeathManager.instance:
		DragonDeathManager.instance.handle_dragon_death(current_dragon, "combat_defending")
		print("✅ [DevMenu] DragonDeathManager.handle_dragon_death() called")
		print("💀 [DevMenu] Killed %s - Death popup should appear!" % current_dragon.dragon_name)
	else:
		print("❌ [DevMenu] DragonDeathManager not available!")

	# Refresh dragon list (dead dragons should be hidden)
	_refresh_dragon_selector()

# === PET DEBUG SECTION ===

func _add_pet_debug_section():
	"""Add pet debugging controls"""
	_add_section_label("PET DEBUG")

	# Force Gift button
	var force_gift_btn = Button.new()
	force_gift_btn.text = "🎁 Force Pet Gift"
	force_gift_btn.pressed.connect(_force_pet_gift)
	force_gift_btn.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 1))
	items_container.add_child(force_gift_btn)

	# Pet affection controls
	var affection_label = Label.new()
	affection_label.text = "Pet Affection:"
	affection_label.add_theme_font_size_override("font_size", 12)
	items_container.add_child(affection_label)

	var affection_hbox = HBoxContainer.new()
	_add_button_to_hbox(affection_hbox, "+10", func(): _add_pet_affection(10))
	_add_button_to_hbox(affection_hbox, "+25", func(): _add_pet_affection(25))
	_add_button_to_hbox(affection_hbox, "Max (100)", func(): _set_pet_affection(100))
	items_container.add_child(affection_hbox)

func _force_pet_gift():
	"""Force a pet gift to appear"""
	if PetDragonManager and PetDragonManager.instance:
		print("[DevMenu] 🎁 Force Gift button pressed - triggering gift...")
		PetDragonManager.instance.trigger_gift(true)  # Force = true bypasses all checks
		print("[DevMenu] ✓ Gift triggered!")
	else:
		print("[DevMenu] ❌ PetDragonManager not found!")

func _add_pet_affection(amount: int):
	"""Add affection to pet"""
	if PetDragonManager and PetDragonManager.instance:
		var pet = PetDragonManager.instance.get_pet_dragon()
		if pet:
			pet.affection = min(100, pet.affection + amount)
			print("[DevMenu] Added %d affection to pet (now %d)" % [amount, pet.affection])
		else:
			print("[DevMenu] No pet dragon found!")
	else:
		print("[DevMenu] PetDragonManager not found!")

func _set_pet_affection(value: int):
	"""Set pet affection to specific value"""
	if PetDragonManager and PetDragonManager.instance:
		var pet = PetDragonManager.instance.get_pet_dragon()
		if pet:
			pet.affection = value
			print("[DevMenu] Set pet affection to %d" % value)
		else:
			print("[DevMenu] No pet dragon found!")
	else:
		print("[DevMenu] PetDragonManager not found!")

# === DEFENSE DEBUG SECTION ===

func _add_defense_debug_section():
	"""Add defense debugging controls"""
	_add_section_label("DEFENSE DEBUG")

	# Trigger Wave buttons
	var trigger_wave_hbox = HBoxContainer.new()

	var trigger_wave_10s_btn = Button.new()
	trigger_wave_10s_btn.text = "⚔ WAVE IN 10s"
	trigger_wave_10s_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trigger_wave_10s_btn.pressed.connect(_trigger_wave_in_10s)
	trigger_wave_10s_btn.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	trigger_wave_hbox.add_child(trigger_wave_10s_btn)

	var trigger_wave_100s_btn = Button.new()
	trigger_wave_100s_btn.text = "🔍 WAVE IN 100s"
	trigger_wave_100s_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trigger_wave_100s_btn.pressed.connect(_trigger_wave_in_100s)
	trigger_wave_100s_btn.add_theme_color_override("font_color", Color(1, 0.7, 0.3, 1))
	trigger_wave_hbox.add_child(trigger_wave_100s_btn)

	items_container.add_child(trigger_wave_hbox)

	# Wave info label
	var wave_info = Label.new()
	wave_info.name = "WaveInfoLabel"
	wave_info.add_theme_font_size_override("font_size", 11)
	wave_info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	_update_wave_info_label(wave_info)
	items_container.add_child(wave_info)

	# Force Wave Completion buttons
	var force_wave_label = Label.new()
	force_wave_label.text = "Force Wave Completion (for scientist upgrades):"
	force_wave_label.add_theme_font_size_override("font_size", 12)
	force_wave_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))
	items_container.add_child(force_wave_label)

	var force_wave_hbox1 = HBoxContainer.new()
	_add_button_to_hbox(force_wave_hbox1, "+1 Wave", _force_complete_wave)
	_add_button_to_hbox(force_wave_hbox1, "+10 Waves", func(): _add_waves(10))
	_add_button_to_hbox(force_wave_hbox1, "+25 Waves", func(): _add_waves(25))
	items_container.add_child(force_wave_hbox1)

	var force_wave_hbox2 = HBoxContainer.new()
	_add_button_to_hbox(force_wave_hbox2, "Set to Wave 25", func(): _set_wave_number(25))
	_add_button_to_hbox(force_wave_hbox2, "Set to Wave 50", func(): _set_wave_number(50))
	items_container.add_child(force_wave_hbox2)

	var force_wave_hbox3 = HBoxContainer.new()
	_add_button_to_hbox(force_wave_hbox3, "Set to Wave 100", func(): _set_wave_number(100))
	_add_button_to_hbox(force_wave_hbox3, "Set to Wave 200", func(): _set_wave_number(200))
	items_container.add_child(force_wave_hbox3)

func _update_wave_info_label(label: Label):
	"""Update wave info display"""
	if not DefenseManager or not DefenseManager.instance:
		label.text = "DefenseManager not available"
		return

	var time_remaining = DefenseManager.instance.time_until_next_wave
	var minutes = int(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	var in_combat = DefenseManager.instance.is_in_combat

	label.text = "Wave %d | Next: %d:%02d %s" % [
		DefenseManager.instance.wave_number,
		minutes,
		seconds,
		"(IN COMBAT)" if in_combat else ""
	]

func _trigger_wave_in_10s():
	"""Set the next wave to trigger in 10 seconds"""
	print("[DevMenu] 🗡️ TRIGGER WAVE IN 10s button pressed!")

	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.time_until_next_wave = 10.0
		DefenseManager.instance.has_shown_scout_warning = true  # Skip scout since we're testing quick wave
		print("[DevMenu] ✓ Wave timer set to 10 seconds - battle will start in 10s!")

		# Update wave info
		var label = items_container.get_node_or_null("WaveInfoLabel")
		if label:
			_update_wave_info_label(label)
	else:
		print("[DevMenu] ❌ DefenseManager not available!")

func _trigger_wave_in_100s():
	"""Set the next wave to trigger in 100 seconds (10s before scout warning)"""
	print("[DevMenu] 🔍 TRIGGER WAVE IN 100s button pressed!")

	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.time_until_next_wave = 100.0
		DefenseManager.instance.has_shown_scout_warning = false  # Reset to allow scout warning
		print("[DevMenu] ✓ Wave timer set to 100 seconds - scout warning will appear at 90s!")

		# Update wave info
		var label = items_container.get_node_or_null("WaveInfoLabel")
		if label:
			_update_wave_info_label(label)
	else:
		print("[DevMenu] ❌ DefenseManager not available!")

func _force_complete_wave():
	"""Force complete the current wave and increment wave number"""
	print("[DevMenu] ⚔️ FORCE COMPLETE WAVE button pressed!")

	if DefenseManager and DefenseManager.instance:
		# Increment wave number
		DefenseManager.instance.wave_number += 1
		print("[DevMenu] ✓ Wave completed! Now on Wave %d" % DefenseManager.instance.wave_number)

		# Reset timer to 3 minutes (180 seconds)
		DefenseManager.instance.time_until_next_wave = 180.0
		DefenseManager.instance.has_shown_scout_warning = false

		# Update wave info
		var label = items_container.get_node_or_null("WaveInfoLabel")
		if label:
			_update_wave_info_label(label)
	else:
		print("[DevMenu] ❌ DefenseManager not available!")

func _add_waves(count: int):
	"""Add multiple waves to the wave counter"""
	print("[DevMenu] 📈 Adding %d waves!" % count)

	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.wave_number += count
		print("[DevMenu] ✓ Added %d waves! Now on Wave %d" % [count, DefenseManager.instance.wave_number])

		# Update wave info
		var label = items_container.get_node_or_null("WaveInfoLabel")
		if label:
			_update_wave_info_label(label)
	else:
		print("[DevMenu] ❌ DefenseManager not available!")

func _set_wave_number(wave_num: int):
	"""Set wave number to a specific value"""
	print("[DevMenu] 🎯 Setting wave number to %d!" % wave_num)

	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.wave_number = wave_num
		print("[DevMenu] ✓ Wave number set to %d!" % wave_num)

		# Reset timer
		DefenseManager.instance.time_until_next_wave = DefenseManager.instance.WAVE_INTERVAL
		DefenseManager.instance.has_shown_scout_warning = false

		# Update wave info
		var label = items_container.get_node_or_null("WaveInfoLabel")
		if label:
			_update_wave_info_label(label)
	else:
		print("[DevMenu] ❌ DefenseManager not available!")
