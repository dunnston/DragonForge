extends Control
class_name PartsInventoryUI

## Main inventory screen for managing recovered parts and freezer

# Node references
@onready var close_button = $Panel/MarginContainer/VBox/Header/CloseButton
@onready var title_label = $Panel/MarginContainer/VBox/Header/TitleLabel
@onready var tab_container = $Panel/MarginContainer/VBox/Content
@onready var recovered_parts_container = $Panel/MarginContainer/VBox/Content/RecoveredParts/ScrollContainer/PartsVBox
@onready var freezer_section = $Panel/MarginContainer/VBox/Content/Freezer
@onready var freezer_locked_panel = $Panel/MarginContainer/VBox/Content/Freezer/LockedPanel
@onready var freezer_unlocked_panel = $Panel/MarginContainer/VBox/Content/Freezer/UnlockedPanel
@onready var freezer_progress_bar = $Panel/MarginContainer/VBox/Content/Freezer/LockedPanel/VBox/ProgressBar
@onready var freezer_progress_label = $Panel/MarginContainer/VBox/Content/Freezer/LockedPanel/VBox/ProgressLabel
@onready var unlock_button = $Panel/MarginContainer/VBox/Content/Freezer/LockedPanel/VBox/UnlockButton
@onready var freezer_title_label = $Panel/MarginContainer/VBox/Content/Freezer/UnlockedPanel/VBox/TitleLabel
@onready var upgrade_button = $Panel/MarginContainer/VBox/Content/Freezer/UnlockedPanel/VBox/UpgradeButton
@onready var freezer_slots_grid = $Panel/MarginContainer/VBox/Content/Freezer/UnlockedPanel/VBox/SlotsGrid
@onready var freeze_all_button = $Panel/MarginContainer/VBox/Footer/FreezeAllButton

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

	# Clear existing cards
	for child in recovered_parts_container.get_children():
		child.queue_free()

	var parts = death_manager.recovered_parts

	if parts.is_empty():
		var label = Label.new()
		label.text = "No recovered parts"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		recovered_parts_container.add_child(label)
		return

	# Sort by time remaining (most urgent first)
	var sorted_parts = parts.duplicate()
	sorted_parts.sort_custom(func(a, b): return a.get_time_until_decay() < b.get_time_until_decay())

	# Create card for each part
	for part in sorted_parts:
		var card = RECOVERED_PART_CARD.instantiate()
		card.setup(part)
		card.freeze_clicked.connect(_on_freeze_part_clicked.bind(part))
		card.use_clicked.connect(_on_use_part_clicked.bind(part))
		recovered_parts_container.add_child(card)

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

	# Clear existing slots
	for child in freezer_slots_grid.get_children():
		child.queue_free()

	var capacity = death_manager.get_freezer_capacity()

	# Create slot for each capacity
	for i in range(capacity):
		var slot = FREEZER_SLOT.instantiate()
		slot.setup(i)

		var part = death_manager.get_part_in_freezer_slot(i)
		if part:
			slot.set_part(part)
			slot.unfreeze_clicked.connect(_on_unfreeze_clicked.bind(i))
		else:
			slot.set_empty()
			slot.empty_clicked.connect(_on_empty_slot_clicked.bind(i))

		freezer_slots_grid.add_child(slot)

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
		_refresh_display()
	else:
		print("[PartsInventoryUI] Failed to unlock freezer")

func _on_upgrade_freezer_pressed():
	"""Attempt to upgrade freezer"""
	if death_manager.upgrade_freezer():
		print("[PartsInventoryUI] Freezer upgraded!")
		_refresh_display()
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
			_refresh_display()
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
		_refresh_display()

func _on_use_part_clicked(part: DragonPart):
	"""Handle use button on part card"""
	# TODO: Open dragon creation screen with this part pre-selected
	print("[PartsInventoryUI] Use part: %s (not yet implemented)" % part.get_display_name())

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
	queue_free()

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
