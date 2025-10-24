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
	else:
		hide()

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

	# Add section: Dragon Debug Controls
	_add_dragon_debug_section()

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
