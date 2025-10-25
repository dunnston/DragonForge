extends Control
class_name TrainingYardUI

# Main UI for managing training grounds
# Dragons train here to level up over time

const TrainingSlotCardScene = preload("res://scenes/ui/training/training_slot_card.tscn")
const ExpansionCardScene = preload("res://scenes/ui/training/training_expansion_card.tscn")
const LockedCardScene = preload("res://scenes/ui/training/training_locked_card.tscn")
const DragonPickerModalScene = preload("res://scenes/ui/dragon_picker_modal.tscn")

@onready var back_button = $MarginContainer/VBox/HeaderPanel/HeaderHBox/BackButton
@onready var slot_container = $MarginContainer/VBox/ScrollContainer/SlotContainer
@onready var trainer_status_label = $MarginContainer/VBox/HeaderPanel/HeaderHBox/TrainerStatus
@onready var collect_all_button = $MarginContainer/VBox/FooterPanel/HBox/CollectAllButton
@onready var capacity_label = $MarginContainer/VBox/FooterPanel/HBox/CapacityLabel

var dragon_picker_modal: DragonPickerModal
var dragon_factory: DragonFactory
var training_manager: TrainingManager
var pending_slot_assignment: int = -1  # Track which slot we're assigning to

signal back_to_factory_requested

func set_dragon_factory(factory: DragonFactory):
	"""Set the dragon factory reference"""
	dragon_factory = factory

func _ready():
	# Get training manager reference
	training_manager = TrainingManager.instance
	if not training_manager:
		push_error("[TrainingYardUI] TrainingManager not found!")
		return

	# Populate slots on startup
	_populate_slots()
	_update_header()
	_update_footer()

	# Connect to manager signals for real-time updates
	if training_manager:
		training_manager.slot_unlocked.connect(_on_slot_unlocked)
		training_manager.dragon_assigned.connect(_on_dragon_assigned)
		training_manager.dragon_removed.connect(_on_dragon_removed)
		training_manager.training_completed.connect(_on_training_completed)
		training_manager.dragon_collected.connect(_on_dragon_collected)
		training_manager.capacity_changed.connect(_on_capacity_changed)

	if TreasureVault and TreasureVault.instance:
		TreasureVault.instance.gold_changed.connect(_on_gold_changed)

	if ScientistManager and ScientistManager.instance:
		ScientistManager.instance.scientist_hired.connect(_on_scientist_changed)
		ScientistManager.instance.scientist_upgraded.connect(func(t, tier): _on_scientist_changed(t))

	# Connect buttons
	back_button.pressed.connect(_on_back_pressed)
	collect_all_button.pressed.connect(_on_collect_all_pressed)

	# Create dragon picker modal
	dragon_picker_modal = DragonPickerModalScene.instantiate()
	add_child(dragon_picker_modal)
	dragon_picker_modal.dragon_selected.connect(_on_dragon_selected)

	# Update every second to keep timers fresh
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_footer)
	add_child(timer)
	timer.start()

func _populate_slots():
	"""Populate the UI with training slot cards"""
	# Clear existing cards
	for child in slot_container.get_children():
		child.queue_free()

	if not training_manager:
		return

	# Add cards for each slot
	for i in range(TrainingManager.MAX_SLOTS):
		var slot = training_manager.get_slot(i)

		if slot.is_unlocked:
			# Unlocked training slot
			var card = TrainingSlotCardScene.instantiate()
			card.setup(slot)
			card.dragon_removed.connect(_on_card_remove_clicked)
			card.dragon_assigned_clicked.connect(_on_card_assign_clicked)
			card.dragon_collected.connect(_on_card_collect_clicked)
			card.rush_clicked.connect(_on_card_rush_clicked)
			slot_container.add_child(card)

		elif i == training_manager.get_next_expansion_slot():
			# Next expansion slot
			var expansion_card = ExpansionCardScene.instantiate()
			var cost = training_manager.get_expansion_cost(i)
			expansion_card.setup(i, cost)
			expansion_card.expand_clicked.connect(_on_expansion_clicked)
			slot_container.add_child(expansion_card)

		else:
			# Locked slot
			var locked_card = LockedCardScene.instantiate()
			locked_card.setup(i)
			slot_container.add_child(locked_card)

func _update_header():
	"""Update header information"""
	if not training_manager or not trainer_status_label:
		return

	# Check if trainer is hired
	var trainer_hired = false
	if ScientistManager and ScientistManager.instance:
		trainer_hired = ScientistManager.instance.is_scientist_hired(Scientist.Type.TRAINER)
		training_manager.set_trainer_assigned(trainer_hired)

	# Update trainer status display
	if trainer_hired:
		trainer_status_label.text = "Trainer: Active (-50% Time)"
		trainer_status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))  # Green
	else:
		trainer_status_label.text = "Trainer: Not Hired"
		trainer_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))  # Gray

func _update_footer():
	"""Update footer information"""
	if not training_manager:
		return

	# Update collect all button
	var completed = training_manager.get_completed_count()
	if collect_all_button:
		collect_all_button.text = "Collect All Ready: %d" % completed
		collect_all_button.disabled = completed == 0

		if completed > 0:
			collect_all_button.modulate = Color(1.2, 1.2, 1.0)  # Highlight
		else:
			collect_all_button.modulate = Color(1, 1, 1)

	# Update capacity display
	var occupied = training_manager.get_occupied_count()
	var capacity = training_manager.get_capacity()
	if capacity_label:
		capacity_label.text = "Training: %d/%d" % [occupied, capacity]

func _refresh_slot_cards():
	"""Refresh all slot cards without rebuilding"""
	for child in slot_container.get_children():
		if child.has_method("refresh"):
			child.refresh()

func _on_card_assign_clicked(slot_id: int):
	"""Open dragon picker to assign a dragon to this slot"""
	if not dragon_factory:
		print("[TrainingYardUI] ERROR: DragonFactory not set!")
		return

	# Store which slot we're assigning to
	pending_slot_assignment = slot_id

	# Open dragon picker modal
	dragon_picker_modal.open(dragon_factory, slot_id)

func _on_card_remove_clicked(slot_id: int):
	"""Remove dragon from training slot"""
	if not training_manager:
		return

	var dragon = training_manager.remove_dragon_from_slot(slot_id)
	if dragon:
		print("[TrainingYardUI] Removed %s from slot %d" % [dragon.dragon_name, slot_id])
		_refresh_slot_cards()
		_update_footer()

func _on_card_collect_clicked(slot_id: int):
	"""Collect trained dragon from slot"""
	if not training_manager:
		return

	var dragon = training_manager.collect_from_slot(slot_id)
	if dragon:
		_show_level_up_popup(dragon)
		_refresh_slot_cards()
		_update_footer()

func _on_card_rush_clicked(slot_id: int):
	"""Rush training with gold"""
	if not training_manager:
		return

	var rush_cost = 50

	if not TreasureVault or not TreasureVault.instance:
		return

	if not TreasureVault.instance.spend_gold(rush_cost):
		print("[TrainingYardUI] Not enough gold to rush training!")
		return

	var slot = training_manager.get_slot(slot_id)
	if slot:
		# Set training to complete instantly
		slot.training_start_time = Time.get_unix_time_from_system() - slot.training_duration
		print("[TrainingYardUI] Rushed training for slot %d (cost: %d gold)" % [slot_id, rush_cost])
		_refresh_slot_cards()

func _on_expansion_clicked(slot_id: int):
	"""Expand a training slot"""
	if not training_manager:
		return

	var cost = training_manager.get_expansion_cost(slot_id)

	if training_manager.expand_slot(slot_id):
		print("[TrainingYardUI] Expanded slot %d for %d gold" % [slot_id, cost])
		_populate_slots()  # Rebuild UI
		_update_footer()
	else:
		print("[TrainingYardUI] Failed to expand slot %d" % slot_id)

func _on_collect_all_pressed():
	"""Collect all completed dragons"""
	if not training_manager:
		return

	var collected = training_manager.collect_all_completed()
	if collected.size() > 0:
		_show_batch_level_up_popup(collected)
		_populate_slots()
		_update_footer()

func _on_dragon_selected(dragon: Dragon, _slot_index: int):
	"""Called when dragon is selected from picker"""
	if pending_slot_assignment < 0:
		return

	if not training_manager:
		return

	# Assign dragon to the pending slot
	if training_manager.assign_dragon_to_slot(pending_slot_assignment, dragon):
		print("[TrainingYardUI] Assigned %s to slot %d" % [dragon.dragon_name, pending_slot_assignment])
		_refresh_slot_cards()
		_update_footer()
	else:
		print("[TrainingYardUI] Failed to assign %s to slot %d" % [dragon.dragon_name, pending_slot_assignment])

	pending_slot_assignment = -1

# === SIGNAL HANDLERS ===

func _on_slot_unlocked(slot_id: int):
	_populate_slots()
	_update_footer()

func _on_dragon_assigned(slot_id: int, dragon: Dragon):
	_refresh_slot_cards()
	_update_footer()

func _on_dragon_removed(slot_id: int, dragon: Dragon):
	_refresh_slot_cards()
	_update_footer()

func _on_training_completed(slot_id: int, dragon: Dragon):
	_refresh_slot_cards()
	_update_footer()
	# Optional: Play notification sound
	# Optional: Show toast notification

func _on_dragon_collected(dragon: Dragon, new_level: int):
	_update_footer()

func _on_capacity_changed(new_capacity: int):
	_update_footer()

func _on_gold_changed(new_amount: int, delta: int):
	# Update button states when gold changes
	_refresh_slot_cards()

func _on_scientist_changed(_type):
	# Update header when scientist status changes
	_update_header()

func _on_back_pressed():
	# Emit signal for parent to handle navigation
	back_to_factory_requested.emit()
	# Or handle directly:
	visible = false

# === UI POPUPS ===

func _show_level_up_popup(dragon: Dragon):
	"""Show celebratory popup for level up"""
	# TODO: Implement level up popup
	print("[TrainingYardUI] %s leveled up to %d!" % [dragon.dragon_name, dragon.level])
	# Play fanfare sound
	# Display stat gains
	# Show celebratory animation

func _show_batch_level_up_popup(dragons: Array[Dragon]):
	"""Show popup for multiple dragons leveling up"""
	# TODO: Implement batch level up popup
	print("[TrainingYardUI] %d dragons completed training!" % dragons.size())
	# Show all dragons that leveled up
	# Play celebration sound
