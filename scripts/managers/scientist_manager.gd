extends Node
# Note: No class_name needed - this script is an autoload singleton

# Scientist Management System - TIER-BASED VERSION
# Handles hiring, upgrading, and automation for all scientist types

# === SINGLETON ===
static var instance

# === SCIENTIST INSTANCES ===
var stitcher: Scientist
var caretaker: Scientist
var trainer: Scientist

# === REFERENCES ===
var treasure_vault: TreasureVault
var dragon_factory: DragonFactory
var inventory_manager: InventoryManager
var dragon_state_manager: DragonStateManager

# === AUTOMATION TIMERS ===
var stitcher_work_timer: Timer
var caretaker_work_timer: Timer
var trainer_work_timer: Timer

# === SIGNALS ===
signal scientist_hired(type: Scientist.Type)
signal scientist_upgraded(type: Scientist.Type, new_tier: int)
signal scientist_action_performed(type: Scientist.Type, action_description: String)
signal salary_payment_due(total_cost: int)
signal salary_paid(total_cost: int)
signal salary_failed(total_cost: int)
signal insufficient_gold_for_hire(type: Scientist.Type)
signal insufficient_gold_for_upgrade(type: Scientist.Type)
signal wave_requirement_not_met(type: Scientist.Type, required_waves: int, current_waves: int)

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	# Initialize scientist instances
	stitcher = Scientist.new()
	stitcher.scientist_type = Scientist.Type.STITCHER

	caretaker = Scientist.new()
	caretaker.scientist_type = Scientist.Type.CARETAKER

	trainer = Scientist.new()
	trainer.scientist_type = Scientist.Type.TRAINER

	# Get manager references
	_setup_manager_references()

	# Setup automation timers (these run constantly but only work if scientist is hired)
	_setup_automation_timers()

	print("[ScientistManager] Tier-based system initialized - 3 scientists ready")

func _setup_manager_references():
	"""Get references to required managers"""
	# Wait for managers to be ready
	await get_tree().process_frame

	treasure_vault = TreasureVault.instance
	dragon_state_manager = DragonStateManager.instance
	inventory_manager = InventoryManager.instance

	print("[ScientistManager] Manager references:")
	print("  - TreasureVault: %s" % (treasure_vault != null))
	print("  - DragonStateManager: %s" % (dragon_state_manager != null))
	print("  - InventoryManager: %s" % (inventory_manager != null))

	if not treasure_vault:
		push_error("ScientistManager: TreasureVault not found!")
	if not dragon_state_manager:
		push_error("ScientistManager: DragonStateManager not found!")
	if not inventory_manager:
		push_error("ScientistManager: InventoryManager not found!")

func set_dragon_factory(factory: DragonFactory):
	"""Set the dragon factory reference (called by FactoryManager)"""
	dragon_factory = factory
	print("[ScientistManager] Dragon factory reference set")

func _setup_automation_timers():
	"""Create timers for each scientist's automation"""
	# Stitcher: Works every 60 seconds
	stitcher_work_timer = Timer.new()
	add_child(stitcher_work_timer)
	stitcher_work_timer.wait_time = 60.0
	stitcher_work_timer.timeout.connect(_on_stitcher_work)
	stitcher_work_timer.start()
	print("[ScientistManager] Stitcher work timer started (60s intervals)")

	# Caretaker: Works every 30 seconds
	caretaker_work_timer = Timer.new()
	add_child(caretaker_work_timer)
	caretaker_work_timer.wait_time = 30.0
	caretaker_work_timer.timeout.connect(_on_caretaker_work)
	caretaker_work_timer.start()
	print("[ScientistManager] Caretaker work timer started (30s intervals)")

	# Trainer: Works every 30 seconds
	trainer_work_timer = Timer.new()
	add_child(trainer_work_timer)
	trainer_work_timer.wait_time = 30.0
	trainer_work_timer.timeout.connect(_on_trainer_work)
	trainer_work_timer.start()
	print("[ScientistManager] Trainer work timer started (30s intervals)")

# ═══════════════════════════════════════════════════════════
# HIRING & UPGRADING
# ═══════════════════════════════════════════════════════════

func can_hire_scientist(type: Scientist.Type) -> bool:
	"""Check if scientist can be hired (not already hired + enough gold)"""
	var scientist = _get_scientist(type)

	if scientist.is_hired:
		return false  # Already hired

	var hire_cost = scientist.get_upgrade_cost()  # Gets Tier 1 cost
	return treasure_vault and treasure_vault.get_total_gold() >= hire_cost

func hire_scientist(type: Scientist.Type) -> bool:
	"""Hire a scientist at Tier 1"""
	var scientist = _get_scientist(type)

	if scientist.is_hired:
		print("[ScientistManager] %s already hired at Tier %d" % [scientist.get_type_name(), scientist.tier])
		return false

	var hire_cost = scientist.get_upgrade_cost()  # Tier 1 cost

	if not treasure_vault or not treasure_vault.spend_gold(hire_cost):
		insufficient_gold_for_hire.emit(type)
		print("[ScientistManager] Cannot hire %s - insufficient gold (need %d)" % [scientist.get_type_name(), hire_cost])
		return false

	# Hire at Tier 1
	scientist.tier = 1
	scientist.is_hired = true

	# Play hired sound effect (if available)
	if AudioManager and AudioManager.instance and AudioManager.instance.has_method("play_scientist_hired"):
		AudioManager.instance.play_scientist_hired()

	scientist_hired.emit(type)
	print("[ScientistManager] ✅ Hired %s (Tier 1) for %d gold - Salary: %d gold/wave" % [
		scientist.get_tier_name(),
		hire_cost,
		scientist.get_salary()
	])
	return true

func can_upgrade_scientist(type: Scientist.Type) -> bool:
	"""Check if scientist can be upgraded"""
	var scientist = _get_scientist(type)

	if not scientist.is_hired:
		return false

	if scientist.tier >= 5:
		return false  # Already max tier

	# Check wave requirement
	var current_waves = 0
	if DefenseManager and DefenseManager.instance:
		current_waves = DefenseManager.instance.wave_number

	if not scientist.can_upgrade(current_waves):
		return false

	# Check gold
	var upgrade_cost = scientist.get_upgrade_cost()
	return treasure_vault and treasure_vault.get_total_gold() >= upgrade_cost

func upgrade_scientist(type: Scientist.Type) -> bool:
	"""Upgrade scientist to next tier"""
	var scientist = _get_scientist(type)

	if not scientist.is_hired:
		print("[ScientistManager] Cannot upgrade %s - not hired yet!" % scientist.get_type_name())
		return false

	if scientist.tier >= 5:
		print("[ScientistManager] %s already at max tier" % scientist.get_type_name())
		return false

	# Check wave requirement
	var current_waves = 0
	if DefenseManager and DefenseManager.instance:
		current_waves = DefenseManager.instance.wave_number

	if not scientist.can_upgrade(current_waves):
		var required = scientist.get_waves_required_for_next_tier()
		wave_requirement_not_met.emit(type, required, current_waves)
		print("[ScientistManager] Cannot upgrade %s - need %d waves (currently %d)" % [
			scientist.get_type_name(),
			required,
			current_waves
		])
		return false

	var upgrade_cost = scientist.get_upgrade_cost()

	if not treasure_vault or not treasure_vault.spend_gold(upgrade_cost):
		insufficient_gold_for_upgrade.emit(type)
		print("[ScientistManager] Cannot upgrade %s - insufficient gold (need %d)" % [
			scientist.get_type_name(),
			upgrade_cost
		])
		return false

	# Upgrade to next tier
	scientist.tier += 1

	# Play upgrade sound effect (if available)
	if AudioManager and AudioManager.instance and AudioManager.instance.has_method("play_scientist_upgraded"):
		AudioManager.instance.play_scientist_upgraded()

	scientist_upgraded.emit(type, scientist.tier)
	print("[ScientistManager] ⬆️ Upgraded %s to Tier %d (%s) - New salary: %d gold/wave" % [
		scientist.get_type_name(),
		scientist.tier,
		scientist.get_tier_name(),
		scientist.get_salary()
	])
	return true

# ═══════════════════════════════════════════════════════════
# SALARY SYSTEM (WAVE-BASED)
# ═══════════════════════════════════════════════════════════

func get_total_salary() -> int:
	"""Get total salary cost per wave for all hired scientists"""
	var total = 0
	if stitcher.is_hired:
		total += stitcher.get_salary()
	if caretaker.is_hired:
		total += caretaker.get_salary()
	if trainer.is_hired:
		total += trainer.get_salary()
	return total

func pay_salaries() -> bool:
	"""
	Pay salaries for all hired scientists (called after each wave).
	Returns true if payment successful, false if insufficient funds.
	"""
	var total = get_total_salary()

	if total == 0:
		return true  # No scientists hired, nothing to pay

	salary_payment_due.emit(total)

	if not treasure_vault:
		push_error("[ScientistManager] Cannot pay salaries - TreasureVault not found!")
		return false

	if treasure_vault.spend_gold(total):
		salary_paid.emit(total)
		print("[ScientistManager] 💰 Paid scientist salaries: %d gold" % total)
		return true
	else:
		salary_failed.emit(total)
		print("[ScientistManager] ⚠️ INSUFFICIENT FUNDS - Cannot pay scientist salaries (%d gold needed)" % total)
		# TODO: Implement penalty (scientists go on strike? reduce efficiency?)
		return false

# ═══════════════════════════════════════════════════════════
# STITCHER AUTOMATION
# ═══════════════════════════════════════════════════════════

func _on_stitcher_work():
	"""Stitcher automation cycle - runs every 60 seconds"""
	if not stitcher.is_hired:
		return

	# Tier 1: Create dragons from parts
	if stitcher.can_create_dragons():
		_auto_create_dragons()

	# Tier 2: Auto-assign to defense
	if stitcher.can_auto_assign_defense():
		_auto_assign_defense()

	# Tier 3: Auto-send exploring
	if stitcher.can_auto_explore():
		_auto_send_exploring()

	# Tier 4: Emergency recall
	if stitcher.can_emergency_recall():
		_auto_emergency_recall()

	# Tier 5: Auto-freeze parts
	if stitcher.can_auto_freeze():
		_auto_freeze_parts()

func _auto_create_dragons():
	"""Tier 1: Auto-create dragons from available parts"""
	if not dragon_factory or not inventory_manager:
		return

	# Try to get parts for a dragon
	var head = _get_available_part(DragonPart.PartType.HEAD)
	var body = _get_available_part(DragonPart.PartType.BODY)
	var tail = _get_available_part(DragonPart.PartType.TAIL)

	if not head or not body or not tail:
		return  # Not enough parts

	# Remove parts from inventory
	var head_id = _get_item_id_for_part(head)
	var body_id = _get_item_id_for_part(body)
	var tail_id = _get_item_id_for_part(tail)

	if not inventory_manager.remove_item_by_id(head_id, 1):
		return
	if not inventory_manager.remove_item_by_id(body_id, 1):
		inventory_manager.add_item_by_id(head_id, 1)  # Refund
		return
	if not inventory_manager.remove_item_by_id(tail_id, 1):
		inventory_manager.add_item_by_id(head_id, 1)  # Refund
		inventory_manager.add_item_by_id(body_id, 1)
		return

	# Create the dragon
	var dragon = dragon_factory.create_dragon(head, body, tail)

	if dragon:
		# Play dragon finished sound effect (if available)
		if AudioManager and AudioManager.instance and AudioManager.instance.has_method("play_dragon_finished"):
			AudioManager.instance.play_dragon_finished()

		scientist_action_performed.emit(Scientist.Type.STITCHER, "Created dragon: %s" % dragon.dragon_name)
		print("[Stitcher T1] ✅ Auto-created dragon: %s" % dragon.dragon_name)

func _auto_assign_defense():
	"""Tier 2: Auto-assign created dragons to defense towers"""
	if not dragon_factory or not DefenseManager or not DefenseManager.instance:
		return

	# Get all idle dragons
	var idle_dragons = dragon_factory.active_dragons.filter(func(d):
		return d.current_state == Dragon.DragonState.IDLE and not d.is_dead and d.fatigue_level <= 0.5
	)

	if idle_dragons.is_empty():
		return

	# Try to assign idle dragons to defense
	for dragon in idle_dragons:
		if DefenseManager.instance.assign_dragon_to_defense(dragon):
			scientist_action_performed.emit(Scientist.Type.STITCHER, "Assigned %s to defense" % dragon.dragon_name)
			print("[Stitcher T2] ✅ Auto-assigned %s to defense" % dragon.dragon_name)
			break  # Only assign one dragon per cycle

func _auto_send_exploring():
	"""Tier 3: Auto-send idle dragons exploring when defense is full"""
	if not dragon_factory or not DefenseManager or not DefenseManager.instance:
		return

	if not ExplorationManager or not ExplorationManager.instance:
		return

	# Check if defense slots are full
	var max_defenders = 3
	if DefenseTowerManager and DefenseTowerManager.instance:
		max_defenders = DefenseTowerManager.instance.get_defense_capacity()

	var current_defenders = DefenseManager.instance.tower_assignments.size()

	if current_defenders < max_defenders:
		return  # Defense not full, don't send exploring yet

	# Get idle dragons
	var idle_dragons = dragon_factory.active_dragons.filter(func(d):
		return d.current_state == Dragon.DragonState.IDLE and not d.is_dead and d.fatigue_level <= 0.5
	)

	if idle_dragons.is_empty():
		return

	# Send one idle dragon exploring (shortest duration)
	for dragon in idle_dragons:
		if ExplorationManager.instance.start_exploration(dragon, 1, "volcanic_caves"):
			scientist_action_performed.emit(Scientist.Type.STITCHER, "Sent %s exploring" % dragon.dragon_name)
			print("[Stitcher T3] ✅ Auto-sent %s exploring (defense full)" % dragon.dragon_name)
			break  # Only send one per cycle

func _auto_emergency_recall():
	"""Tier 4: Auto-recall explorers when defense needs help"""
	if not DefenseManager or not DefenseManager.instance:
		return

	if not ExplorationManager or not ExplorationManager.instance:
		return

	# Check if defense needs help (has empty slots or damaged towers)
	var max_defenders = 3
	if DefenseTowerManager and DefenseTowerManager.instance:
		max_defenders = DefenseTowerManager.instance.get_defense_capacity()

	var current_defenders = DefenseManager.instance.tower_assignments.size()

	# Only recall if we have empty defense slots AND active explorations
	if current_defenders >= max_defenders:
		return  # Defense is full, no need to recall

	var active_explorations = ExplorationManager.instance.active_explorations

	if active_explorations.is_empty():
		return  # No one exploring to recall

	# Find the explorer closest to finishing (least time remaining)
	var closest_explorer = null
	var shortest_time = INF
	var current_time = Time.get_unix_time_from_system()

	for dragon_id in active_explorations:
		var exploration_data = active_explorations[dragon_id]
		var dragon = exploration_data["dragon"]
		var time_remaining = (exploration_data["start_time"] + exploration_data["duration"]) - current_time

		if time_remaining < shortest_time:
			shortest_time = time_remaining
			closest_explorer = dragon

	# Recall the closest explorer and assign to defense
	if closest_explorer:
		ExplorationManager.instance.cancel_exploration(closest_explorer)

		# Wait a frame for state to update
		await get_tree().process_frame

		# Assign to defense
		if DefenseManager.instance.assign_dragon_to_defense(closest_explorer):
			scientist_action_performed.emit(Scientist.Type.STITCHER, "Recalled %s for defense" % closest_explorer.dragon_name)
			print("[Stitcher T4] ✅ Emergency recalled %s for defense" % closest_explorer.dragon_name)

func _auto_freeze_parts():
	"""Tier 5: Auto-freeze parts before decay (<6 hours)"""
	if not DragonDeathManager or not DragonDeathManager.instance:
		return

	var death_manager = DragonDeathManager.instance

	# Check if freezer is unlocked
	if death_manager.freezer_level == 0:
		return

	# Check all recovered parts for decay urgency
	for part in death_manager.recovered_parts:
		var time_until_decay = part.get_time_until_decay()

		# If less than 6 hours (21600 seconds) until decay, freeze it
		if time_until_decay > 0 and time_until_decay < 21600:
			# Find first available freezer slot
			var capacity = death_manager.get_freezer_capacity()

			for slot_index in range(capacity):
				if death_manager.is_freezer_slot_empty(slot_index):
					if death_manager.freeze_part(part, slot_index):
						var time_str = part.format_time_remaining()
						scientist_action_performed.emit(
							Scientist.Type.STITCHER,
							"Froze %s (%s remaining)" % [part.get_display_name(), time_str]
						)
						print("[Stitcher T5] ❄️ Auto-froze %s with %s until decay" % [part.get_display_name(), time_str])
					break  # Move to next part

# ═══════════════════════════════════════════════════════════
# CARETAKER AUTOMATION
# ═══════════════════════════════════════════════════════════

func _on_caretaker_work():
	"""Caretaker automation cycle - runs every 30 seconds"""
	if not caretaker.is_hired:
		return

	if not dragon_factory or not dragon_state_manager:
		return

	var all_dragons = dragon_factory.active_dragons

	# Tier 1: Feed hungry dragons
	if caretaker.can_feed():
		for dragon in all_dragons:
			if dragon.is_dead:
				continue

			# Tier 4: More aggressive feeding (prevent starvation)
			var hunger_threshold = 0.50  # Default: feed at 50% hunger
			if caretaker.can_prevent_starvation():
				hunger_threshold = 0.80  # Aggressive: feed at 80% hunger (20% remaining)

			if dragon.hunger_level > hunger_threshold:
				if dragon_state_manager.use_food_on_dragon(dragon):
					scientist_action_performed.emit(Scientist.Type.CARETAKER, "Fed %s" % dragon.dragon_name)

	# Tier 2: Heal damaged dragons
	if caretaker.can_heal():
		for dragon in all_dragons:
			if dragon.is_dead:
				continue

			if dragon.current_health < dragon.total_health * 0.75:
				if dragon_state_manager.use_health_pot_on_dragon(dragon):
					scientist_action_performed.emit(Scientist.Type.CARETAKER, "Healed %s" % dragon.dragon_name)

	# Tier 3: Rest fatigued defenders
	if caretaker.can_rest():
		_auto_rest_dragons()

	# Tier 5: Repair damaged towers
	if caretaker.can_repair_towers():
		_auto_repair_towers()

func _auto_rest_dragons():
	"""Tier 3: Auto-rest fatigued defending dragons"""
	if not DefenseManager or not DefenseManager.instance:
		return

	# Get all defending dragons
	var defending_dragons = []
	for tower_index in DefenseManager.instance.tower_assignments:
		var dragon = DefenseManager.instance.tower_assignments[tower_index]
		if dragon and not dragon.is_dead:
			defending_dragons.append(dragon)

	# Check for fatigued defenders (>70% fatigue)
	for dragon in defending_dragons:
		if dragon.fatigue_level > 0.7:
			# Remove from defense so they can rest
			if DefenseManager.instance.remove_dragon_from_defense(dragon):
				scientist_action_performed.emit(Scientist.Type.CARETAKER, "Rested %s (%.0f%% fatigue)" % [dragon.dragon_name, dragon.fatigue_level * 100])
				print("[Caretaker T3] 😴 Auto-rested %s (%.0f%% fatigued)" % [dragon.dragon_name, dragon.fatigue_level * 100])
				break  # Only rest one dragon per cycle

func _auto_repair_towers():
	"""Tier 5: Auto-repair damaged towers"""
	if not DefenseTowerManager or not DefenseTowerManager.instance:
		return

	var towers = DefenseTowerManager.instance.get_towers()

	# Find towers that need repair (<50% HP)
	for tower in towers:
		if tower.is_destroyed():
			continue  # Can't repair destroyed towers (need rebuild)

		var health_percent = tower.get_health_percentage()

		if health_percent < 0.5:  # Less than 50% HP
			# Attempt to repair to full
			if DefenseTowerManager.instance.repair_tower(tower):
				scientist_action_performed.emit(Scientist.Type.CARETAKER, "Repaired tower (was %.0f%% HP)" % (health_percent * 100))
				print("[Caretaker T5] 🔧 Auto-repaired tower from %.0f%% to 100%%" % (health_percent * 100))
				break  # Only repair one tower per cycle (expensive!)

# ═══════════════════════════════════════════════════════════
# TRAINER AUTOMATION
# ═══════════════════════════════════════════════════════════

func _on_trainer_work():
	"""Trainer automation cycle - runs every 30 seconds"""
	if not trainer.is_hired:
		return

	if not dragon_factory or not dragon_state_manager:
		return

	# Tier 1: Enable training yard with 50% speed bonus
	if trainer.enables_training():
		_enable_training_yard()

	# Tier 2: Auto-fill training slots
	if trainer.can_auto_fill_training():
		_auto_fill_training()

	# Tier 3: Auto-collect trained dragons
	if trainer.can_auto_collect_training():
		_auto_collect_training()

	# Tier 5: Passive XP for defending/exploring dragons
	if trainer.can_passive_xp():
		_grant_passive_xp()

func _enable_training_yard():
	"""Tier 1: Enable training yard with 50% speed bonus"""
	if not TrainingManager or not TrainingManager.instance:
		return

	# Ensure trainer is marked as assigned (enables 50% speed bonus)
	if not TrainingManager.instance.trainer_assigned:
		TrainingManager.instance.set_trainer_assigned(true)
		print("[Trainer T1] ✅ Training yard enabled (+50% speed bonus)")

func _auto_fill_training():
	"""Tier 2: Auto-fill empty training slots"""
	if not TrainingManager or not TrainingManager.instance:
		return

	if not dragon_factory:
		return

	# Get all idle dragons (not training, not defending, not exploring)
	var idle_dragons = dragon_factory.active_dragons.filter(func(d):
		return (d.current_state == Dragon.DragonState.IDLE or d.current_state == Dragon.DragonState.RESTING) and not d.is_dead
	)

	if idle_dragons.is_empty():
		return

	# Find empty training slots
	var empty_slots = []
	for slot in TrainingManager.instance.get_unlocked_slots():
		if not slot.is_occupied():
			empty_slots.append(slot)

	if empty_slots.is_empty():
		return

	# Assign idle dragons to empty slots
	for slot in empty_slots:
		if idle_dragons.is_empty():
			break

		var dragon = idle_dragons.pop_front()
		if TrainingManager.instance.assign_dragon_to_slot(slot.slot_id, dragon):
			scientist_action_performed.emit(Scientist.Type.TRAINER, "Assigned %s to training" % dragon.dragon_name)
			print("[Trainer T2] ✅ Auto-assigned %s to training slot %d" % [dragon.dragon_name, slot.slot_id])

func _auto_collect_training():
	"""Tier 3: Auto-collect completed training"""
	if not TrainingManager or not TrainingManager.instance:
		return

	var completed_count = TrainingManager.instance.get_completed_count()

	if completed_count == 0:
		return

	# Collect all completed dragons
	var collected = TrainingManager.instance.collect_all_completed()

	for dragon in collected:
		scientist_action_performed.emit(Scientist.Type.TRAINER, "Collected %s (Lv %d)" % [dragon.dragon_name, dragon.level])
		print("[Trainer T3] ✅ Auto-collected %s from training (now Lv %d)" % [dragon.dragon_name, dragon.level])

		# Tier 4: Auto-rotate - immediately reassign to training if enabled
		if trainer.can_auto_rotate():
			# Wait a moment for state to update
			await get_tree().create_timer(0.5).timeout

			# Find an empty slot
			for slot in TrainingManager.instance.get_unlocked_slots():
				if not slot.is_occupied():
					if TrainingManager.instance.assign_dragon_to_slot(slot.slot_id, dragon):
						scientist_action_performed.emit(Scientist.Type.TRAINER, "Rotated %s back to training" % dragon.dragon_name)
						print("[Trainer T4] ♻️ Auto-rotated %s back to training (continuous loop)" % dragon.dragon_name)
					break

func _grant_passive_xp():
	"""Tier 5: Grant passive XP to defending/exploring dragons"""
	if not dragon_factory or not dragon_state_manager:
		return

	var xp_granted = 0

	for dragon in dragon_factory.active_dragons:
		if dragon.is_dead:
			continue

		var xp_amount = 0

		# Defending dragons: 2 XP per cycle (30 seconds) = ~4 XP/minute
		if dragon.current_state == Dragon.DragonState.DEFENDING:
			xp_amount = 2

		# Exploring dragons: 1 XP per cycle (30 seconds) = ~2 XP/minute
		elif dragon.current_state == Dragon.DragonState.EXPLORING:
			xp_amount = 1

		if xp_amount > 0:
			dragon_state_manager.gain_experience(dragon, xp_amount)
			xp_granted += xp_amount

	if xp_granted > 0:
		scientist_action_performed.emit(Scientist.Type.TRAINER, "Granted %d passive XP" % xp_granted)
		print("[Trainer T5] ✨ Granted %d passive XP to defending/exploring dragons" % xp_granted)

# ═══════════════════════════════════════════════════════════
# HELPER FUNCTIONS (from old system)
# ═══════════════════════════════════════════════════════════

func _get_available_part(part_type: DragonPart.PartType) -> DragonPart:
	"""Get a random available dragon part from inventory"""
	if not inventory_manager or not PartLibrary.instance:
		return null

	# Get all dragon parts from inventory
	var all_parts = inventory_manager.get_all_dragon_parts()
	var available_parts = []

	for part_data in all_parts:
		var item: Item = part_data["item"]
		var quantity: int = part_data["quantity"]

		if quantity > 0:
			# Convert element string to enum
			var element = _get_element_enum_from_string(item.element)
			var part = PartLibrary.get_part_by_element_and_type(element, part_type)
			if part:
				available_parts.append(part)

	if available_parts.is_empty():
		return null

	# Return a random part
	return available_parts.pick_random()

func _get_item_id_for_part(part: DragonPart) -> String:
	"""Get the inventory item ID for a dragon part"""
	if not part:
		return ""

	var element_str = DragonPart.Element.keys()[part.element].to_lower()
	var type_str = DragonPart.PartType.keys()[part.part_type].to_lower()
	# Format: "fire_head", "ice_body", etc. (matches items.json)
	return "%s_%s" % [element_str, type_str]

func _get_element_enum_from_string(element_str: String) -> DragonPart.Element:
	"""Convert element string to enum"""
	match element_str.to_upper():
		"FIRE": return DragonPart.Element.FIRE
		"ICE": return DragonPart.Element.ICE
		"LIGHTNING": return DragonPart.Element.LIGHTNING
		"NATURE": return DragonPart.Element.NATURE
		"SHADOW": return DragonPart.Element.SHADOW
	return DragonPart.Element.FIRE  # Default

func _get_scientist(type: Scientist.Type) -> Scientist:
	"""Get scientist instance by type"""
	match type:
		Scientist.Type.STITCHER:
			return stitcher
		Scientist.Type.CARETAKER:
			return caretaker
		Scientist.Type.TRAINER:
			return trainer
	return null

# ═══════════════════════════════════════════════════════════
# UTILITY FUNCTIONS (for UI)
# ═══════════════════════════════════════════════════════════

func get_scientist(type: Scientist.Type) -> Scientist:
	"""Get scientist instance (for UI access)"""
	return _get_scientist(type)

func is_scientist_hired(type: Scientist.Type) -> bool:
	"""Check if a scientist is currently hired"""
	var scientist = _get_scientist(type)
	return scientist and scientist.is_hired

func get_scientist_tier(type: Scientist.Type) -> int:
	"""Get current tier of a scientist"""
	var scientist = _get_scientist(type)
	return scientist.tier if scientist else 0

func get_all_hired_scientists() -> Array:
	"""Get list of all currently hired scientist types"""
	var hired = []
	if stitcher.is_hired:
		hired.append(Scientist.Type.STITCHER)
	if caretaker.is_hired:
		hired.append(Scientist.Type.CARETAKER)
	if trainer.is_hired:
		hired.append(Scientist.Type.TRAINER)
	return hired

# === WORK TIMER ACCESS (for UI progress bars) ===

func get_stitcher_work_timer() -> Timer:
	"""Get the stitcher work timer for progress tracking"""
	return stitcher_work_timer

func get_caretaker_work_timer() -> Timer:
	"""Get the caretaker work timer for progress tracking"""
	return caretaker_work_timer

func get_trainer_work_timer() -> Timer:
	"""Get the trainer work timer for progress tracking"""
	return trainer_work_timer

# ═══════════════════════════════════════════════════════════
# SAVE/LOAD SERIALIZATION
# ═══════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	"""Serialize scientist manager state for saving"""
	return {
		"stitcher": stitcher.to_save_dict(),
		"caretaker": caretaker.to_save_dict(),
		"trainer": trainer.to_save_dict()
	}

func from_dict(data: Dictionary):
	"""Restore scientist manager state from saved data"""
	if data.has("stitcher"):
		stitcher.load_from_dict(data["stitcher"])
		print("[ScientistManager] Loaded Stitcher: Tier %d, Hired: %s" % [stitcher.tier, stitcher.is_hired])

	if data.has("caretaker"):
		caretaker.load_from_dict(data["caretaker"])
		print("[ScientistManager] Loaded Caretaker: Tier %d, Hired: %s" % [caretaker.tier, caretaker.is_hired])

	if data.has("trainer"):
		trainer.load_from_dict(data["trainer"])
		print("[ScientistManager] Loaded Trainer: Tier %d, Hired: %s" % [trainer.tier, trainer.is_hired])

# ============================================================================
# BACKWARD COMPATIBILITY API
# These functions provide compatibility with old UI components
# ============================================================================

func get_scientist_name(type: Scientist.Type) -> String:
	"""Get simple name for scientist type (for old UI components)"""
	match type:
		Scientist.Type.STITCHER: return "Stitcher"
		Scientist.Type.CARETAKER: return "Caretaker"
		Scientist.Type.TRAINER: return "Trainer"
	return "Unknown"

func get_scientist_description(type: Scientist.Type) -> String:
	"""Get description for scientist type (for old UI components)"""
	match type:
		Scientist.Type.STITCHER:
			return "Creates dragons automatically and manages deployment"
		Scientist.Type.CARETAKER:
			return "Takes care of dragon health, hunger, and fatigue"
		Scientist.Type.TRAINER:
			return "Manages the training yard and dragon leveling"
	return ""

func get_scientist_hire_cost(type: Scientist.Type) -> int:
	"""Get Tier 1 hire cost (for old UI components)"""
	var scientist = _get_scientist(type)
	if scientist.tier == 0:
		return scientist.get_upgrade_cost()  # Cost to go from 0 -> 1
	return 0

func get_scientist_ongoing_cost(type: Scientist.Type) -> int:
	"""Get current salary per wave (for old UI components)"""
	var scientist = _get_scientist(type)
	return scientist.get_salary()

# Note: is_scientist_hired() already exists earlier in this file (line 767)
# Note: Timer getter functions already exist earlier in this file (lines 790-800)
