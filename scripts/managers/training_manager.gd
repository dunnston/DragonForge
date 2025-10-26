extends Node
# Note: No class_name needed - this script is an autoload singleton

# Training Ground Management System
# Manages training slots where dragons level up over time

# === SINGLETON ===
static var instance

# === CONSTANTS ===
const MAX_SLOTS = 10
const STARTING_SLOTS = 2
const EXPANSION_COSTS = [0, 0, 500, 1000, 2000, 4000, 4000, 4000, 4000, 4000]

# === STATE ===
var training_slots: Array[TrainingSlot] = []
var trainer_assigned: bool = false

# === REFERENCES ===
var treasure_vault: TreasureVault
var scientist_manager: ScientistManager
var dragon_factory: DragonFactory

# === SIGNALS ===
signal slot_unlocked(slot_id: int)
signal dragon_assigned(slot_id: int, dragon: Dragon)
signal dragon_removed(slot_id: int, dragon: Dragon)
signal training_completed(slot_id: int, dragon: Dragon)
signal dragon_collected(dragon: Dragon, new_level: int)
signal capacity_changed(new_capacity: int)

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	_initialize_slots()
	_setup_manager_references()

	# Check for completed training every second
	var timer = Timer.new()
	timer.timeout.connect(_check_completed_training)
	timer.wait_time = 1.0
	timer.autostart = true
	add_child(timer)

	print("[TrainingManager] Initialized with %d starting slots" % STARTING_SLOTS)

func _setup_manager_references():
	"""Get references to required managers"""
	await get_tree().process_frame

	treasure_vault = TreasureVault.instance
	scientist_manager = ScientistManager.instance

	print("[TrainingManager] Manager references:")
	print("  - TreasureVault: %s" % (treasure_vault != null))
	print("  - ScientistManager: %s" % (scientist_manager != null))

	if not treasure_vault:
		push_error("TrainingManager: TreasureVault not found!")
	if not scientist_manager:
		push_warning("TrainingManager: ScientistManager not found (trainer bonus disabled)")

	# Check if trainer is already hired
	if scientist_manager:
		_update_trainer_status()

func set_dragon_factory(factory: DragonFactory):
	"""Set the dragon factory reference (called by FactoryManager or main)"""
	dragon_factory = factory
	print("[TrainingManager] Dragon factory reference set")

func _initialize_slots():
	for i in range(MAX_SLOTS):
		var slot = TrainingSlot.new()
		slot.slot_id = i
		slot.is_unlocked = (i < STARTING_SLOTS)
		training_slots.append(slot)

func get_slot(slot_id: int) -> TrainingSlot:
	if slot_id >= 0 and slot_id < training_slots.size():
		return training_slots[slot_id]
	return null

func get_unlocked_slots() -> Array[TrainingSlot]:
	return training_slots.filter(func(slot): return slot.is_unlocked)

func get_occupied_count() -> int:
	return get_unlocked_slots().filter(func(slot): return slot.is_occupied()).size()

func get_capacity() -> int:
	return get_unlocked_slots().size()

func get_expansion_cost(slot_id: int) -> int:
	if slot_id >= 0 and slot_id < EXPANSION_COSTS.size():
		return EXPANSION_COSTS[slot_id]
	return 0

func get_next_expansion_slot() -> int:
	for i in range(training_slots.size()):
		if not training_slots[i].is_unlocked:
			return i
	return -1

func can_expand() -> bool:
	return get_next_expansion_slot() >= 0

func expand_slot(slot_id: int) -> bool:
	"""Expand a training slot (requires gold)"""
	if slot_id < 0 or slot_id >= training_slots.size():
		return false
	if training_slots[slot_id].is_unlocked:
		return false

	# Check if we can afford it
	var cost = get_expansion_cost(slot_id)
	if not treasure_vault or not treasure_vault.spend_gold(cost):
		print("[TrainingManager] Not enough gold to expand slot %d (cost: %d)" % [slot_id, cost])
		return false

	training_slots[slot_id].is_unlocked = true
	slot_unlocked.emit(slot_id)
	capacity_changed.emit(get_capacity())

	print("[TrainingManager] Expanded slot %d for %d gold" % [slot_id, cost])
	return true

func assign_dragon_to_slot(slot_id: int, dragon: Dragon) -> bool:
	"""Assign a dragon to a training slot"""
	var slot = get_slot(slot_id)
	if not slot or not slot.is_unlocked or slot.is_occupied():
		print("[TrainingManager] Cannot assign to slot %d (unlocked: %s, occupied: %s)" % [slot_id, slot.is_unlocked if slot else false, slot.is_occupied() if slot else false])
		return false

	# Check if dragon is already training elsewhere
	if dragon.current_state == Dragon.DragonState.TRAINING:
		print("[TrainingManager] Dragon %s is already training!" % dragon.dragon_name)
		return false

	# If dragon is currently defending, remove them from defense first
	if dragon.current_state == Dragon.DragonState.DEFENDING:
		if DefenseManager and DefenseManager.instance:
			var removed = DefenseManager.instance.remove_dragon_from_defense(dragon)
			if removed:
				print("[TrainingManager] Removed %s from defense to start training" % dragon.dragon_name)
			else:
				print("[TrainingManager] WARNING: Failed to remove %s from defense" % dragon.dragon_name)

	slot.assign_dragon(dragon, trainer_assigned)
	dragon_assigned.emit(slot_id, dragon)

	# Play dragon growl when assigned to training
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_dragon_growl()

	print("[TrainingManager] Assigned %s to slot %d (duration: %d seconds)" % [dragon.dragon_name, slot_id, slot.training_duration])
	return true

func remove_dragon_from_slot(slot_id: int) -> Dragon:
	"""Remove a dragon from training (returns to idle)"""
	var slot = get_slot(slot_id)
	if not slot or not slot.is_occupied():
		return null

	var dragon = slot.remove_dragon()
	dragon_removed.emit(slot_id, dragon)

	print("[TrainingManager] Removed %s from slot %d" % [dragon.dragon_name, slot_id])
	return dragon

func collect_from_slot(slot_id: int) -> Dragon:
	"""Collect a trained dragon (levels up)"""
	var slot = get_slot(slot_id)
	if not slot or not slot.is_training_complete():
		return null

	var old_level = slot.assigned_dragon.level
	var dragon = slot.collect_trained_dragon()

	if dragon:
		# Play level up sound (if method exists)
		if AudioManager and AudioManager.instance and AudioManager.instance.has_method("play_level_up"):
			AudioManager.instance.play_level_up()

		dragon_collected.emit(dragon, dragon.level)
		print("[TrainingManager] Collected %s from slot %d (Lv %d → Lv %d)" % [dragon.dragon_name, slot_id, old_level, dragon.level])

	return dragon

func collect_all_completed() -> Array[Dragon]:
	"""Collect all completed dragons"""
	var collected: Array[Dragon] = []
	for slot in get_unlocked_slots():
		if slot.is_training_complete():
			var dragon = collect_from_slot(slot.slot_id)
			if dragon:
				collected.append(dragon)
	return collected

func get_completed_count() -> int:
	return get_unlocked_slots().filter(func(slot): return slot.is_training_complete()).size()

func _update_trainer_status():
	"""Check if trainer scientist is hired"""
	if not scientist_manager:
		return

	var was_assigned = trainer_assigned
	trainer_assigned = scientist_manager.is_scientist_hired(Scientist.Type.TRAINER)

	if was_assigned != trainer_assigned:
		print("[TrainingManager] Trainer status changed: %s" % ("HIRED" if trainer_assigned else "NOT HIRED"))
		_recalculate_training_times()

func set_trainer_assigned(assigned: bool):
	"""Manually set trainer status (for integration with scientist system)"""
	if trainer_assigned == assigned:
		return

	trainer_assigned = assigned
	print("[TrainingManager] Trainer manually set to: %s" % ("HIRED" if assigned else "NOT HIRED"))
	_recalculate_training_times()

func _recalculate_training_times():
	"""Recalculate all active training times when trainer status changes"""
	for slot in get_unlocked_slots():
		if slot.is_occupied() and not slot.is_training_complete():
			var progress = slot.get_progress()
			var base_duration = slot._calculate_training_time(slot.assigned_dragon.level)
			slot.training_duration = base_duration if not trainer_assigned else int(base_duration * 0.5)

			# Adjust start time to maintain progress percentage
			var current_time = Time.get_unix_time_from_system()
			slot.training_start_time = current_time - int(slot.training_duration * progress)

			print("[TrainingManager] Recalculated training time for %s (new duration: %d seconds)" % [slot.assigned_dragon.dragon_name, slot.training_duration])

func _check_completed_training():
	"""Check for completed training every second"""
	for slot in get_unlocked_slots():
		if slot.is_training_complete():
			training_completed.emit(slot.slot_id, slot.assigned_dragon)

func to_dict() -> Dictionary:
	"""Serialize for save system"""
	var slots_data = []
	for slot in training_slots:
		slots_data.append(slot.to_dict())

	return {
		"slots": slots_data,
		"trainer_assigned": trainer_assigned
	}

func from_dict(data: Dictionary):
	"""Restore from save system"""
	if not data.has("slots"):
		return

	# Restore trainer status
	trainer_assigned = data.get("trainer_assigned", false)

	# Restore slots
	var slots_data = data["slots"]
	for i in range(min(slots_data.size(), training_slots.size())):
		training_slots[i].from_dict(slots_data[i])

	# Resolve dragon references
	if dragon_factory:
		_resolve_dragon_references()

	print("[TrainingManager] Loaded training state (%d occupied slots)" % get_occupied_count())

func _resolve_dragon_references():
	"""Resolve dragon ID references to actual dragon objects"""
	if not dragon_factory:
		return

	for slot in training_slots:
		if slot.assigned_dragon_id != "":
			# Find dragon by ID
			for dragon in dragon_factory.active_dragons:
				if dragon.dragon_id == slot.assigned_dragon_id:
					slot.assigned_dragon = dragon
					dragon.set_state(Dragon.DragonState.TRAINING)
					print("[TrainingManager] Resolved dragon reference: %s in slot %d" % [dragon.dragon_name, slot.slot_id])
					break
