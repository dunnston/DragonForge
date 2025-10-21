# Inventory Panel - Grid-based Inventory Display
extends Control

const InventorySlotUIScene = preload("res://scenes/ui/inventory_slot_ui.tscn")

# === UI ELEMENTS ===
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var gold_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/GoldLabel
@onready var inventory_grid: GridContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/InventorySection/ScrollContainer/InventoryGrid
@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var tooltip_name: Label = $TooltipPanel/MarginContainer/VBoxContainer/NameLabel
@onready var tooltip_desc: Label = $TooltipPanel/MarginContainer/VBoxContainer/DescLabel
@onready var tooltip_stats: Label = $TooltipPanel/MarginContainer/VBoxContainer/StatsLabel

# Inventory display
var slot_ui_nodes: Array = []
const COLUMNS: int = 8
const VISIBLE_ROWS: int = 6
const TOTAL_SLOTS: int = 50

func _ready():
	# Connect close button
	close_button.pressed.connect(_on_close_pressed)

	# Hide tooltip initially
	tooltip_panel.visible = false

	# Create inventory slot UIs
	_create_inventory_slots()

	# Connect to InventoryManager signals
	if InventoryManager and InventoryManager.instance:
		InventoryManager.instance.slot_changed.connect(_on_slot_changed)

	# Start hidden
	hide()

func _create_inventory_slots():
	"""Create all inventory slot UI elements"""
	inventory_grid.columns = COLUMNS

	for i in range(TOTAL_SLOTS):
		var slot_ui = InventorySlotUIScene.instantiate()
		slot_ui.set_slot_index(i)
		slot_ui.slot_clicked.connect(_on_slot_clicked)
		slot_ui.slot_hovered.connect(_on_slot_hovered)
		slot_ui.mouse_exited.connect(_on_slot_mouse_exited)

		inventory_grid.add_child(slot_ui)
		slot_ui_nodes.append(slot_ui)

func open():
	"""Show the inventory panel and update all displays"""
	show()
	_update_all_slots()
	_update_gold_display()

func _on_close_pressed():
	hide()
	tooltip_panel.visible = false

func _on_slot_changed(slot_index: int):
	"""Update a specific slot when it changes"""
	if visible:
		_update_slot(slot_index)

func _update_all_slots():
	"""Refresh all inventory slot displays"""
	if not InventoryManager or not InventoryManager.instance:
		return

	for i in range(TOTAL_SLOTS):
		_update_slot(i)

func _update_slot(slot_index: int):
	"""Update a single slot display"""
	if slot_index < 0 or slot_index >= slot_ui_nodes.size():
		return

	if not InventoryManager or not InventoryManager.instance:
		return

	var slot_data = InventoryManager.instance.get_slot(slot_index)
	var slot_ui = slot_ui_nodes[slot_index]

	if slot_data:
		slot_ui.update_slot(slot_data)
	else:
		slot_ui.set_empty()

func _update_gold_display():
	"""Update the gold counter"""
	if TreasureVault and TreasureVault.instance:
		var total_gold = TreasureVault.instance.get_total_gold()
		gold_label.text = "%d Gold" % total_gold

func _on_slot_clicked(slot_index: int):
	"""Handle clicking on an inventory slot"""
	print("[InventoryPanel] Clicked slot %d" % slot_index)
	# TODO: Implement item use/equip functionality

func _on_slot_hovered(slot_index: int, item: Item):
	"""Show tooltip when hovering over an item"""
	if not item:
		tooltip_panel.visible = false
		return

	# Update tooltip content
	tooltip_name.text = item.get_display_name()
	tooltip_desc.text = item.description

	# Show stats for dragon parts
	if item.is_dragon_part():
		var stats_text = "Type: %s %s\n" % [item.element.capitalize(), item.part_type.capitalize()]
		if item.stats.has("attack") and item.stats["attack"] > 0:
			stats_text += "Attack: +%d\n" % item.stats["attack"]
		if item.stats.has("health") and item.stats["health"] > 0:
			stats_text += "Health: +%d\n" % item.stats["health"]
		if item.stats.has("speed") and item.stats["speed"] > 0:
			stats_text += "Speed: +%d\n" % item.stats["speed"]
		tooltip_stats.text = stats_text
		tooltip_stats.visible = true
	elif item.is_consumable():
		var effect_text = "Effect: "
		if item.effect.has("type"):
			match item.effect["type"]:
				"xp_gain": effect_text += "+%d XP" % item.effect.get("amount", 0)
				"heal": effect_text += "Restore full health"
				"feed": effect_text += "Remove hunger"
				"happiness_xp": effect_text += "+%d Happiness, +%d XP" % [item.effect.get("happiness", 0), item.effect.get("xp", 0)]
		tooltip_stats.text = effect_text
		tooltip_stats.visible = true
	else:
		tooltip_stats.visible = false

	# Position tooltip near mouse
	tooltip_panel.visible = true
	tooltip_panel.global_position = get_global_mouse_position() + Vector2(15, 15)

func _on_slot_mouse_exited():
	"""Hide tooltip when mouse leaves slot"""
	await get_tree().create_timer(0.1).timeout  # Small delay to prevent flicker
	var mouse_pos = get_global_mouse_position()
	var tooltip_rect = Rect2(tooltip_panel.global_position, tooltip_panel.size)

	# Only hide if mouse is not over the tooltip itself
	if not tooltip_rect.has_point(mouse_pos):
		tooltip_panel.visible = false

func _input(event):
	# Close on ESC key
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and visible:
		hide()
		tooltip_panel.visible = false
		get_viewport().set_input_as_handled()

func _process(_delta):
	# Update gold display continuously (in case it changes)
	if visible:
		_update_gold_display()
