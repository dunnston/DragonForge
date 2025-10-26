extends Control
class_name PartsInventoryUI

## Main inventory screen for managing recovered parts and freezer

# Node references
@onready var close_button = $CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/HeaderContainer/CloseButton
@onready var recovered_parts_container = $CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/RecoveredPartsSection/ScrollContainer/PartsVBox
@onready var freezer_locked_panel = $CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/FreezerSection/FreezerLockedPanel
@onready var freezer_unlocked_panel = $CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/FreezerSection/FreezerUnlockedPanel
@onready var freezer_progress_bar = $CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/FreezerSection/FreezerLockedPanel/MarginContainer/VBox/ProgressBar
@onready var freezer_progress_label = $CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/FreezerSection/FreezerLockedPanel/MarginContainer/VBox/ProgressLabel
@onready var unlock_button = $CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/FreezerSection/FreezerLockedPanel/MarginContainer/VBox/UnlockButton
@onready var freezer_title_label = $CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/FreezerSection/FreezerUnlockedPanel/FreezerHeader/TitleLabel
@onready var upgrade_button = $CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/FreezerSection/FreezerUnlockedPanel/FreezerHeader/UpgradeButton
@onready var freezer_slots_grid = $CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/FreezerSection/FreezerUnlockedPanel/SlotsGrid
@onready var freeze_all_button = $CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/RecoveredPartsSection/RecoveredHeader/FreezeAllButton

# Preloaded scenes
const RECOVERED_PART_CARD = preload("res://scenes/ui/recovered_part_card.tscn")
const FREEZER_SLOT = preload("res://scenes/ui/freezer_slot.tscn")

# State
var death_manager: DragonDeathManager
var selected_part_for_freezing: DragonPart = null

func _ready():
	# Get reference to death manager
	death_manager = DragonDeathManager.instance

	if not death_manager:
		push_error("[PartsInventoryUI] DragonDeathManager not found!")
		return

	# Connect button signals
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if unlock_button:
		unlock_button.pressed.connect(_on_unlock_freezer_pressed)
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_freezer_pressed)
	if freeze_all_button:
		freeze_all_button.pressed.connect(_on_freeze_all_pressed)

	# Connect to death manager signals
	death_manager.part_recovered.connect(_on_part_recovered)
	death_manager.part_decayed.connect(_on_part_decayed)
	death_manager.part_frozen.connect(_on_part_frozen)
	death_manager.part_unfrozen.connect(_on_part_unfrozen)
	death_manager.freezer_unlocked.connect(_on_freezer_unlocked)
	death_manager.freezer_upgraded.connect(_on_freezer_upgraded)
	death_manager.freezer_data_loaded.connect(_on_freezer_data_loaded)

	# Initial display
	_refresh_display()

func _refresh_display():
	"""Refresh all UI elements"""
	_display_recovered_parts()
	_display_freezer_section()
	_update_buttons()

func _display_recovered_parts():
	"""Display all recovered parts with decay timers"""
	if not recovered_parts_container:
		return

	# Clear existing cards - queue for deletion
	var children = recovered_parts_container.get_children()
	for child in children:
		recovered_parts_container.remove_child(child)
		child.queue_free()

	var parts = death_manager.recovered_parts

	# Filter to only show parts that still exist in inventory
	var available_parts: Array[DragonPart] = []
	for part in parts:
		var item_id = _convert_part_to_item_id(part)
		if not item_id.is_empty() and InventoryManager and InventoryManager.instance:
			if InventoryManager.instance.has_item(item_id, 1):
				available_parts.append(part)
			else:
				# Part was consumed but not removed from recovered_parts array
				# Remove it from the array to keep things in sync
				death_manager.recovered_parts.erase(part)

	if available_parts.is_empty():
		var label = Label.new()
		label.text = "No recovered parts"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		recovered_parts_container.add_child(label)
		return

	# Sort by time remaining (most urgent first)
	var sorted_parts = available_parts.duplicate()
	sorted_parts.sort_custom(func(a, b): return a.get_time_until_decay() < b.get_time_until_decay())

	# Create card for each part
	for part in sorted_parts:
		var card = RECOVERED_PART_CARD.instantiate()

		# Add to scene tree first so @onready vars are initialized
		recovered_parts_container.add_child(card)

		# Now setup after nodes are ready
		card.setup(part)
		card.freeze_clicked.connect(_on_freeze_part_clicked.bind(part))
		card.use_clicked.connect(_on_use_part_clicked.bind(part))

func _display_freezer_section():
	"""Display freezer section (locked or unlocked)"""
	if not death_manager:
		return

	if death_manager.freezer_level == 0:
		_show_freezer_locked()
	else:
		_show_freezer_unlocked()

func _show_freezer_locked():
	"""Show locked freezer panel with progress"""
	if freezer_locked_panel:
		freezer_locked_panel.visible = true
	if freezer_unlocked_panel:
		freezer_unlocked_panel.visible = false

	# Update progress
	var progress = death_manager.get_freezer_unlock_progress()
	var waves_needed = DragonDeathManager.FREEZER_UNLOCK_WAVES
	var waves_current = 0

	if DefenseManager and DefenseManager.instance:
		waves_current = DefenseManager.instance.wave_number

	if freezer_progress_bar:
		freezer_progress_bar.value = progress * 100

	if freezer_progress_label:
		freezer_progress_label.text = "Progress: %d/%d waves" % [waves_current, waves_needed]

	# Update unlock button
	var can_unlock = death_manager.can_unlock_freezer()
	if unlock_button:
		unlock_button.disabled = not can_unlock
		if can_unlock:
			unlock_button.text = "UNLOCK FREEZER (500g)"
		else:
			var remaining = waves_needed - waves_current
			unlock_button.text = "LOCKED - %d more waves" % remaining

func _show_freezer_unlocked():
	"""Show unlocked freezer with slots"""
	if freezer_locked_panel:
		freezer_locked_panel.visible = false
	if freezer_unlocked_panel:
		freezer_unlocked_panel.visible = true

	var capacity = death_manager.get_freezer_capacity()
	var used = death_manager.get_freezer_used_slots()

	# Update title
	if freezer_title_label:
		freezer_title_label.text = "FREEZER (Level %d): ❄️ %d/%d slots" % [
			death_manager.freezer_level,
			used,
			capacity
		]

	# Show/hide upgrade button
	if death_manager.can_upgrade_freezer():
		var upgrade_info = death_manager.get_next_freezer_upgrade()
		if upgrade_button:
			upgrade_button.visible = true
			upgrade_button.text = "UPGRADE TO LEVEL %d: %dg (+%d slots)" % [
				upgrade_info.level,
				upgrade_info.cost,
				upgrade_info.capacity - capacity
			]

			# Check if can afford
			var can_afford = false
			if TreasureVault and TreasureVault.instance:
				can_afford = TreasureVault.instance.gold >= upgrade_info.cost
			upgrade_button.disabled = not can_afford
	else:
		if upgrade_button:
			upgrade_button.visible = false

	# Display freezer slots
	_display_freezer_slots()

func _display_freezer_slots():
	"""Display grid of freezer slots"""
	if not freezer_slots_grid:
		return

	# Clear existing slots - queue for deletion
	var children = freezer_slots_grid.get_children()
	for child in children:
		freezer_slots_grid.remove_child(child)
		child.queue_free()

	var capacity = death_manager.get_freezer_capacity()

	# Create slot for each capacity
	for i in range(capacity):
		var slot = FREEZER_SLOT.instantiate()

		# Add to scene tree first so @onready vars are initialized
		freezer_slots_grid.add_child(slot)

		# Now setup after nodes are ready
		slot.setup(i)

		var part = death_manager.get_part_in_freezer_slot(i)
		if part:
			slot.set_part(part)
			slot.unfreeze_clicked.connect(_on_unfreeze_clicked.bind(i))
		else:
			slot.set_empty()
			slot.empty_clicked.connect(_on_empty_slot_clicked.bind(i))

func _update_buttons():
	"""Update button states"""
	# Freeze All button
	if freeze_all_button:
		var has_parts = not death_manager.recovered_parts.is_empty()
		var has_space = death_manager.get_freezer_empty_slots() > 0
		freeze_all_button.disabled = not (has_parts and has_space and death_manager.freezer_level > 0)

# ═══════════════════════════════════════════════════════════
# BUTTON HANDLERS
# ═══════════════════════════════════════════════════════════

func _on_unlock_freezer_pressed():
	"""Attempt to unlock freezer"""
	if death_manager.unlock_freezer():
		print("[PartsInventoryUI] Freezer unlocked!")
		# Don't call _refresh_display() here - freezer_unlocked signal will handle it
	else:
		print("[PartsInventoryUI] Failed to unlock freezer")

func _on_upgrade_freezer_pressed():
	"""Attempt to upgrade freezer"""
	if death_manager.upgrade_freezer():
		print("[PartsInventoryUI] Freezer upgraded!")
		# Don't call _refresh_display() here - freezer_upgraded signal will handle it
	else:
		print("[PartsInventoryUI] Failed to upgrade freezer")

func _on_freeze_part_clicked(part: DragonPart):
	"""Handle freeze button on part card"""
	# Find first empty slot
	var empty_slot = -1
	for i in range(death_manager.get_freezer_capacity()):
		if death_manager.is_freezer_slot_empty(i):
			empty_slot = i
			break

	if empty_slot >= 0:
		if death_manager.freeze_part(part, empty_slot):
			print("[PartsInventoryUI] Froze part in slot %d" % empty_slot)
			# Don't call _refresh_display() here - it's already called by the part_frozen signal handler
	else:
		print("[PartsInventoryUI] No empty freezer slots!")

func _on_empty_slot_clicked(slot_index: int):
	"""Handle click on empty freezer slot"""
	# Could show part picker here
	print("[PartsInventoryUI] Empty slot %d clicked" % slot_index)

func _on_unfreeze_clicked(slot_index: int):
	"""Handle unfreeze button on slot"""
	if death_manager.unfreeze_part(slot_index):
		print("[PartsInventoryUI] Unfroze part from slot %d" % slot_index)
		# Don't call _refresh_display() here - part_unfrozen signal will handle it

func _on_use_part_clicked(part: DragonPart):
	"""Handle use button on part card - slots it into factory manager"""
	if not part:
		return

	print("[PartsInventoryUI] Using part: %s" % part.get_display_name())

	# Convert part to item_id (e.g. "fire_head_recovered")
	var item_id = _convert_part_to_item_id(part)
	if item_id.is_empty():
		print("[PartsInventoryUI] ERROR: Could not convert part to item_id")
		return

	# Find the factory manager
	var factory_manager = _find_factory_manager()
	if not factory_manager:
		print("[PartsInventoryUI] ERROR: Could not find FactoryManager")
		return

	# Determine which slot to fill based on part type
	var slot_to_fill = ""
	match part.part_type:
		DragonPart.PartType.HEAD:
			slot_to_fill = "head"
		DragonPart.PartType.BODY:
			slot_to_fill = "body"
		DragonPart.PartType.TAIL:
			slot_to_fill = "tail"

	# Set the appropriate slot in factory manager and update display
	match slot_to_fill:
		"head":
			factory_manager.selected_head_id = item_id
			factory_manager._update_slot_display(
				factory_manager.head_slot_label,
				factory_manager.head_slot_rect,
				factory_manager.head_slot_icon,
				item_id
			)
			print("[PartsInventoryUI] Slotted %s into HEAD slot" % part.get_display_name())
		"body":
			factory_manager.selected_body_id = item_id
			factory_manager._update_slot_display(
				factory_manager.body_slot_label,
				factory_manager.body_slot_rect,
				factory_manager.body_slot_icon,
				item_id
			)
			print("[PartsInventoryUI] Slotted %s into BODY slot" % part.get_display_name())
		"tail":
			factory_manager.selected_tail_id = item_id
			factory_manager._update_slot_display(
				factory_manager.tail_slot_label,
				factory_manager.tail_slot_rect,
				factory_manager.tail_slot_icon,
				item_id
			)
			print("[PartsInventoryUI] Slotted %s into TAIL slot" % part.get_display_name())

	# Update the animate button state (enables it if all parts are selected)
	factory_manager._check_can_create_dragon()

	# Close this UI
	queue_free()

	print("[PartsInventoryUI] Part successfully slotted and UI closed")

func _on_freeze_all_pressed():
	"""Freeze all recovered parts into available slots"""
	var parts_to_freeze = death_manager.recovered_parts.duplicate()
	var next_slot = 0
	var frozen_count = 0

	for part in parts_to_freeze:
		# Find next empty slot
		while next_slot < death_manager.get_freezer_capacity():
			if death_manager.is_freezer_slot_empty(next_slot):
				if death_manager.freeze_part(part, next_slot):
					frozen_count += 1
				next_slot += 1
				break
			next_slot += 1

	print("[PartsInventoryUI] Froze %d parts" % frozen_count)
	_refresh_display()

func _on_close_pressed():
	"""Close the inventory UI"""
	_cleanup_signals()
	queue_free()

func _exit_tree():
	"""Clean up when node is removed from tree"""
	_cleanup_signals()

func _cleanup_signals():
	"""Disconnect all signal connections to prevent memory leaks"""
	if not death_manager:
		return

	# Disconnect all death manager signals
	if death_manager.part_recovered.is_connected(_on_part_recovered):
		death_manager.part_recovered.disconnect(_on_part_recovered)

	if death_manager.part_decayed.is_connected(_on_part_decayed):
		death_manager.part_decayed.disconnect(_on_part_decayed)

	if death_manager.part_frozen.is_connected(_on_part_frozen):
		death_manager.part_frozen.disconnect(_on_part_frozen)

	if death_manager.part_unfrozen.is_connected(_on_part_unfrozen):
		death_manager.part_unfrozen.disconnect(_on_part_unfrozen)

	if death_manager.freezer_unlocked.is_connected(_on_freezer_unlocked):
		death_manager.freezer_unlocked.disconnect(_on_freezer_unlocked)

	if death_manager.freezer_upgraded.is_connected(_on_freezer_upgraded):
		death_manager.freezer_upgraded.disconnect(_on_freezer_upgraded)

	if death_manager.freezer_data_loaded.is_connected(_on_freezer_data_loaded):
		death_manager.freezer_data_loaded.disconnect(_on_freezer_data_loaded)

# ═══════════════════════════════════════════════════════════
# SIGNAL HANDLERS
# ═══════════════════════════════════════════════════════════

func _on_part_recovered(part: DragonPart):
	"""Handle part recovered event"""
	_refresh_display()

func _on_part_decayed(part: DragonPart):
	"""Handle part decay event"""
	_refresh_display()
	# TODO: Show decay notification

func _on_part_frozen(part: DragonPart, slot_index: int):
	"""Handle part frozen event"""
	_refresh_display()

func _on_part_unfrozen(part: DragonPart):
	"""Handle part unfrozen event"""
	_refresh_display()

func _on_freezer_unlocked(level: int):
	"""Handle freezer unlock event"""
	_refresh_display()

func _on_freezer_upgraded(new_level: int, new_capacity: int):
	"""Handle freezer upgrade event"""
	_refresh_display()

func _on_freezer_data_loaded():
	"""Handle freezer data loaded event (from save game)"""
	_refresh_display()

# ═══════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════

func _convert_part_to_item_id(part: DragonPart) -> String:
	"""Convert a DragonPart to an inventory item_id (e.g. 'fire_head_recovered')"""
	if not part:
		return ""

	# Get element name (FIRE → "fire")
	var element_name = ""
	match part.element:
		DragonPart.Element.FIRE:
			element_name = "fire"
		DragonPart.Element.ICE:
			element_name = "ice"
		DragonPart.Element.LIGHTNING:
			element_name = "lightning"
		DragonPart.Element.NATURE:
			element_name = "nature"
		DragonPart.Element.SHADOW:
			element_name = "shadow"

	# Get part type name (HEAD → "head")
	var part_type_name = ""
	match part.part_type:
		DragonPart.PartType.HEAD:
			part_type_name = "head"
		DragonPart.PartType.BODY:
			part_type_name = "body"
		DragonPart.PartType.TAIL:
			part_type_name = "tail"

	# Add "_recovered" suffix so they stack separately from normal parts
	return "%s_%s_recovered" % [element_name, part_type_name]

func _find_factory_manager():
	"""Find the FactoryManager node in the scene tree"""
	# Search in the root's children
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "FactoryManager" or child is Control and child.has_method("_update_creation_slots"):
			return child

	# Fallback: search more deeply
	return _find_node_by_class(root, "FactoryManager")

func _find_node_by_class(node: Node, target_class_name: String):
	"""Recursively find a node by checking its script's class name"""
	if node.get_script():
		var script = node.get_script()
		if script.resource_path.contains("factory_manager"):
			return node

	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result:
			return result

	return null
