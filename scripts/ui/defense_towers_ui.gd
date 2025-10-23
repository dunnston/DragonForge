extends Control
class_name DefenseTowersUI

# Main UI for managing defense towers

const TowerCardScene = preload("res://scenes/ui/towers/tower_card.tscn")
const BuildCardScene = preload("res://scenes/ui/towers/build_card.tscn")
const LockedCardScene = preload("res://scenes/ui/towers/locked_card.tscn")
const DragonPickerModalScene = preload("res://scenes/ui/dragon_picker_modal.tscn")

@onready var back_button = $MarginContainer/VBox/HeaderPanel/HeaderHBox/BackButton
@onready var tower_container = $MarginContainer/VBox/ScrollContainer/TowerContainer
@onready var repair_all_button = $MarginContainer/VBox/FooterPanel/HBox/RepairAllButton
@onready var stats_label = $MarginContainer/VBox/FooterPanel/HBox/StatsLabel

var dragon_picker_modal: DragonPickerModal
var dragon_factory: DragonFactory  # Reference to factory

signal back_to_factory_requested

func set_dragon_factory(factory: DragonFactory):
	"""Set the dragon factory reference"""
	dragon_factory = factory

func _ready():
	# Populate towers on startup
	_populate_towers()
	_update_footer()

	# Connect to manager signals for real-time updates
	if DefenseTowerManager and DefenseTowerManager.instance:
		DefenseTowerManager.instance.tower_built.connect(_on_tower_built)
		DefenseTowerManager.instance.tower_damaged.connect(_on_tower_damaged)
		DefenseTowerManager.instance.tower_repaired.connect(_on_tower_repaired)
		DefenseTowerManager.instance.tower_capacity_changed.connect(_on_capacity_changed)

	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.dragon_assigned_to_defense.connect(_on_dragon_assigned)
		DefenseManager.instance.dragon_removed_from_defense.connect(_on_dragon_removed)

	if TreasureVault and TreasureVault.instance:
		TreasureVault.instance.gold_changed.connect(_on_gold_changed)

	# Connect buttons
	back_button.pressed.connect(_on_back_pressed)
	repair_all_button.pressed.connect(_on_repair_all_pressed)

	# Create dragon picker modal
	dragon_picker_modal = DragonPickerModalScene.instantiate()
	add_child(dragon_picker_modal)
	dragon_picker_modal.dragon_selected.connect(_on_dragon_selected)

	# Update every second to keep UI fresh
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_footer)
	add_child(timer)
	timer.start()

func _populate_towers():
	# Clear existing cards
	for child in tower_container.get_children():
		child.queue_free()

	if not DefenseTowerManager or not DefenseTowerManager.instance:
		print("[DefenseTowersUI] ERROR: DefenseTowerManager not found!")
		return

	var tower_manager = DefenseTowerManager.instance
	var towers = tower_manager.get_towers()

	# Add cards for existing towers
	for i in range(towers.size()):
		var tower = towers[i]
		var card = TowerCardScene.instantiate()
		card.setup(tower, i)
		card.repair_clicked.connect(_on_repair_clicked)
		card.card_clicked.connect(_on_tower_card_clicked)
		card.assign_dragon_requested.connect(_on_assign_dragon_requested)
		tower_container.add_child(card)

	# Add build card if we can build more
	if tower_manager.can_build_tower():
		var build_card = BuildCardScene.instantiate()
		build_card.setup(towers.size())
		build_card.build_clicked.connect(_on_build_clicked)
		tower_container.add_child(build_card)

	# Add locked cards for remaining slots
	var locked_slots = DefenseTowerManager.MAX_TOWERS - towers.size()
	if tower_manager.can_build_tower():
		locked_slots -= 1  # One slot is the build card

	for i in range(locked_slots):
		var locked_card = LockedCardScene.instantiate()
		locked_card.setup(towers.size() + 1 + i)
		tower_container.add_child(locked_card)

func _update_footer():
	if not DefenseTowerManager or not DefenseTowerManager.instance:
		return
	if not DefenseManager or not DefenseManager.instance:
		return
	if not TreasureVault or not TreasureVault.instance:
		return

	var tower_manager = DefenseTowerManager.instance
	var defense_manager = DefenseManager.instance

	# Update slots display
	var capacity = tower_manager.get_defense_capacity()
	var defending = defense_manager.get_defending_dragons().size()
	stats_label.text = "Slots: %d/%d" % [defending, capacity]

	# Update repair all button
	var damaged_count = tower_manager.get_damaged_towers()
	if damaged_count > 0:
		var total_cost = 0
		for tower in tower_manager.get_towers():
			if tower.needs_repair() and not tower.is_destroyed():
				total_cost += tower_manager.get_tower_repair_cost(tower)

		repair_all_button.text = "Repair All: %dg" % total_cost
		repair_all_button.visible = true

		if TreasureVault.instance.get_total_gold() < total_cost:
			repair_all_button.disabled = true
			repair_all_button.modulate = Color(0.6, 0.6, 0.6)
		else:
			repair_all_button.disabled = false
			repair_all_button.modulate = Color(1, 1, 1)
	else:
		repair_all_button.visible = false

func _refresh_tower_cards():
	# Refresh all tower cards without rebuilding
	for child in tower_container.get_children():
		if child.has_method("refresh"):
			child.refresh()

func _on_repair_clicked(tower_index: int):
	if not DefenseTowerManager or not DefenseTowerManager.instance:
		return

	var tower_manager = DefenseTowerManager.instance
	var towers = tower_manager.get_towers()

	if tower_index < 0 or tower_index >= towers.size():
		return

	var tower = towers[tower_index]
	var success = tower_manager.repair_tower(tower)

	if success:
		print("[DefenseTowersUI] Tower %d repaired!" % tower_index)
		_refresh_tower_cards()
		_update_footer()
	else:
		print("[DefenseTowersUI] Failed to repair tower %d" % tower_index)

func _on_build_clicked(tower_index: int):
	if not DefenseTowerManager or not DefenseTowerManager.instance:
		return

	var tower_manager = DefenseTowerManager.instance
	var new_tower = tower_manager.build_tower()

	if new_tower:
		print("[DefenseTowersUI] New tower built!")
		# Rebuild UI to show new tower
		_populate_towers()
		_update_footer()
	else:
		print("[DefenseTowersUI] Failed to build tower")

func _on_tower_card_clicked(tower_index: int):
	# Future: Open tower details or dragon assignment UI
	print("[DefenseTowersUI] Tower %d clicked" % tower_index)

func _on_repair_all_pressed():
	if not DefenseTowerManager or not DefenseTowerManager.instance:
		return

	var tower_manager = DefenseTowerManager.instance
	var repaired = tower_manager.repair_all_towers()

	if repaired > 0:
		print("[DefenseTowersUI] Repaired %d towers" % repaired)
		_refresh_tower_cards()
		_update_footer()

# Signal handlers for real-time updates

func _on_tower_built(tower: DefenseTower):
	_populate_towers()
	_update_footer()

func _on_tower_damaged(tower: DefenseTower, damage: int):
	_refresh_tower_cards()
	_update_footer()

func _on_tower_repaired(tower: DefenseTower, amount: int):
	_refresh_tower_cards()
	_update_footer()

func _on_capacity_changed(new_capacity: int):
	_update_footer()

func _on_dragon_assigned(dragon):
	_refresh_tower_cards()
	_update_footer()

func _on_dragon_removed(dragon):
	_refresh_tower_cards()
	_update_footer()

func _on_gold_changed(new_amount: int, delta: int):
	# Update button states when gold changes
	_refresh_tower_cards()
	_update_footer()

func _on_assign_dragon_requested(tower_index: int):
	if not dragon_factory:
		print("[DefenseTowersUI] ERROR: DragonFactory not set!")
		return

	# Open dragon picker modal
	dragon_picker_modal.open(dragon_factory, tower_index)

func _on_dragon_selected(dragon: Dragon, tower_index: int):
	if not DefenseManager or not DefenseManager.instance:
		print("[DefenseTowersUI] ERROR: DefenseManager not found!")
		return

	# Assign dragon to defense
	DefenseManager.instance.assign_dragon_to_defense(dragon)
	print("[DefenseTowersUI] Dragon %s assigned to tower %d" % [dragon.dragon_name, tower_index])

	# Refresh UI to show updated dragon assignment
	_refresh_tower_cards()
	_update_footer()

func _on_back_pressed():
	# Emit signal for parent to handle navigation
	back_to_factory_requested.emit()
	# Or handle directly:
	visible = false
