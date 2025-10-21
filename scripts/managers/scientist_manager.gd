extends Node
class_name ScientistManager

# Scientist Management System
# Handles hiring, firing, and automation for all scientist types

# === SINGLETON ===
static var instance: ScientistManager

# === SCIENTIST TYPES ===
enum ScientistType {
	STITCHER,    # Auto-creates dragons from parts
	CARETAKER,   # Auto-feeds and heals dragons
	TRAINER      # Auto-grants XP to training dragons
}

# === SCIENTIST COSTS ===
const SCIENTIST_DATA = {
	ScientistType.STITCHER: {
		"name": "Stitcher",
		"hire_cost": 50,
		"ongoing_cost_per_minute": 2,
		"description": "Automatically creates dragons from available parts"
	},
	ScientistType.CARETAKER: {
		"name": "Caretaker",
		"hire_cost": 100,
		"ongoing_cost_per_minute": 3,
		"description": "Automatically feeds hungry dragons and heals injured ones"
	},
	ScientistType.TRAINER: {
		"name": "Trainer",
		"hire_cost": 150,
		"ongoing_cost_per_minute": 5,
		"description": "Automatically trains dragons, granting them XP"
	}
}

# === SCIENTIST STATE ===
var hired_scientists: Dictionary = {}  # ScientistType -> bool (hired/not hired)
var scientist_timers: Dictionary = {}  # ScientistType -> Timer (for ongoing costs)

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
signal scientist_hired(type: ScientistType)
signal scientist_fired(type: ScientistType)
signal scientist_action_performed(type: ScientistType, action_description: String)
signal insufficient_gold_for_scientist(type: ScientistType)

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	# Initialize all scientists as not hired
	for type in ScientistType.values():
		hired_scientists[type] = false

	# Get manager references
	_setup_manager_references()

	# Setup automation timers (these run constantly but only work if scientist is hired)
	_setup_automation_timers()

func _setup_manager_references():
	"""Get references to required managers"""
	# Wait for managers to be ready
	await get_tree().process_frame

	treasure_vault = TreasureVault.instance
	dragon_state_manager = DragonStateManager.instance
	inventory_manager = InventoryManager.instance

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
	# Stitcher: Creates 1 dragon every 60 seconds
	stitcher_work_timer = Timer.new()
	add_child(stitcher_work_timer)
	stitcher_work_timer.wait_time = 60.0
	stitcher_work_timer.timeout.connect(_on_stitcher_work)
	stitcher_work_timer.start()

	# Caretaker: Checks and cares for dragons every 30 seconds
	caretaker_work_timer = Timer.new()
	add_child(caretaker_work_timer)
	caretaker_work_timer.wait_time = 30.0
	caretaker_work_timer.timeout.connect(_on_caretaker_work)
	caretaker_work_timer.start()

	# Trainer: Grants XP every 30 seconds
	trainer_work_timer = Timer.new()
	add_child(trainer_work_timer)
	trainer_work_timer.wait_time = 30.0
	trainer_work_timer.timeout.connect(_on_trainer_work)
	trainer_work_timer.start()

# === HIRE/FIRE SYSTEM ===

func can_hire_scientist(type: ScientistType) -> bool:
	"""Check if scientist can be hired (not already hired + enough gold)"""
	if hired_scientists[type]:
		return false

	var hire_cost = SCIENTIST_DATA[type]["hire_cost"]
	return treasure_vault.get_total_gold() >= hire_cost

func hire_scientist(type: ScientistType) -> bool:
	"""Hire a scientist - deducts hire cost and starts ongoing cost timer"""
	if hired_scientists[type]:
		print("Scientist already hired: %s" % SCIENTIST_DATA[type]["name"])
		return false

	var hire_cost = SCIENTIST_DATA[type]["hire_cost"]

	if not treasure_vault.spend_gold(hire_cost):
		insufficient_gold_for_scientist.emit(type)
		return false

	# Mark as hired
	hired_scientists[type] = true

	# Start ongoing cost timer (1 minute intervals)
	_start_ongoing_cost_timer(type)

	scientist_hired.emit(type)
	print("[ScientistManager] Hired %s for %d gold" % [SCIENTIST_DATA[type]["name"], hire_cost])
	return true

func fire_scientist(type: ScientistType) -> bool:
	"""Fire a scientist - no refund, just stops ongoing cost"""
	if not hired_scientists[type]:
		print("Scientist not hired: %s" % SCIENTIST_DATA[type]["name"])
		return false

	# Mark as not hired
	hired_scientists[type] = false

	# Stop ongoing cost timer
	_stop_ongoing_cost_timer(type)

	scientist_fired.emit(type)
	print("[ScientistManager] Fired %s" % SCIENTIST_DATA[type]["name"])
	return true

func is_scientist_hired(type: ScientistType) -> bool:
	"""Check if a scientist is currently hired"""
	return hired_scientists.get(type, false)

# === ONGOING COST SYSTEM ===

func _start_ongoing_cost_timer(type: ScientistType):
	"""Start a timer that deducts gold every minute"""
	# Create a timer for this scientist if it doesn't exist
	if scientist_timers.has(type):
		scientist_timers[type].start()
		return

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 60.0  # 1 minute
	timer.timeout.connect(func(): _deduct_ongoing_cost(type))
	scientist_timers[type] = timer
	timer.start()

func _stop_ongoing_cost_timer(type: ScientistType):
	"""Stop the ongoing cost timer for a scientist"""
	if scientist_timers.has(type):
		scientist_timers[type].stop()

func _deduct_ongoing_cost(type: ScientistType):
	"""Deduct ongoing cost from gold - if can't pay, auto-fire scientist"""
	if not hired_scientists[type]:
		return

	var cost = SCIENTIST_DATA[type]["ongoing_cost_per_minute"]

	if not treasure_vault.spend_gold(cost):
		# Can't afford to pay - auto fire!
		print("[ScientistManager] Can't afford %s! Auto-firing..." % SCIENTIST_DATA[type]["name"])
		fire_scientist(type)
		insufficient_gold_for_scientist.emit(type)

# === STITCHER AUTOMATION ===

func _on_stitcher_work():
	"""Stitcher attempts to create a dragon from available parts"""
	if not hired_scientists[ScientistType.STITCHER]:
		return

	if not dragon_factory or not inventory_manager:
		return

	# Try to get parts for a dragon
	var head = _get_available_part(DragonPart.PartType.HEAD)
	var body = _get_available_part(DragonPart.PartType.BODY)
	var tail = _get_available_part(DragonPart.PartType.TAIL)

	if not head or not body or not tail:
		# Silently skip if no parts available
		return

	# Remove parts from inventory
	var head_id = _get_item_id_for_part(head)
	var body_id = _get_item_id_for_part(body)
	var tail_id = _get_item_id_for_part(tail)

	if not inventory_manager.remove_item_by_id(head_id, 1):
		return
	if not inventory_manager.remove_item_by_id(body_id, 1):
		return
	if not inventory_manager.remove_item_by_id(tail_id, 1):
		return

	# Create the dragon
	var dragon = dragon_factory.create_dragon(head, body, tail)

	if dragon:
		scientist_action_performed.emit(ScientistType.STITCHER, "Created dragon: %s" % dragon.dragon_name)
		print("[Stitcher] Auto-created dragon: %s" % dragon.dragon_name)

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
	return "dragon_%s_%s" % [type_str, element_str]

func _get_element_enum_from_string(element_str: String) -> DragonPart.Element:
	"""Convert element string to enum"""
	match element_str.to_upper():
		"FIRE": return DragonPart.Element.FIRE
		"ICE": return DragonPart.Element.ICE
		"LIGHTNING": return DragonPart.Element.LIGHTNING
		"NATURE": return DragonPart.Element.NATURE
		"SHADOW": return DragonPart.Element.SHADOW
	return DragonPart.Element.FIRE  # Default

# === CARETAKER AUTOMATION ===

func _on_caretaker_work():
	"""Caretaker feeds hungry dragons and heals injured ones"""
	if not hired_scientists[ScientistType.CARETAKER]:
		return

	if not dragon_factory or not dragon_state_manager:
		return

	for dragon in dragon_factory.active_dragons:
		if dragon.is_dead:
			continue

		# Priority 1: Heal critical health (< 30%)
		if dragon.current_health < dragon.total_health * 0.3:
			if dragon_state_manager.use_health_pot_on_dragon(dragon):
				scientist_action_performed.emit(ScientistType.CARETAKER, "Healed %s with health potion" % dragon.dragon_name)
				continue

		# Priority 2: Feed very hungry dragons (> 75% hunger)
		if dragon.hunger_level > 0.75:
			if dragon_state_manager.use_food_on_dragon(dragon):
				scientist_action_performed.emit(ScientistType.CARETAKER, "Fed %s" % dragon.dragon_name)
				continue

		# Priority 3: Feed moderately hungry dragons (> 50% hunger)
		if dragon.hunger_level > 0.50:
			if dragon_state_manager.use_food_on_dragon(dragon):
				scientist_action_performed.emit(ScientistType.CARETAKER, "Fed %s" % dragon.dragon_name)
				continue

		# Priority 4: Heal any damaged dragons
		if dragon.current_health < dragon.total_health:
			if dragon_state_manager.use_health_pot_on_dragon(dragon):
				scientist_action_performed.emit(ScientistType.CARETAKER, "Healed %s" % dragon.dragon_name)
				continue

# === TRAINER AUTOMATION ===

func _on_trainer_work():
	"""Trainer grants XP to dragons that are training"""
	if not hired_scientists[ScientistType.TRAINER]:
		return

	if not dragon_factory or not dragon_state_manager:
		return

	var xp_per_update = 10  # Grants 10 XP every 30 seconds

	for dragon in dragon_factory.active_dragons:
		if dragon.is_dead:
			continue

		# Only train dragons that are in TRAINING state
		if dragon.current_state == Dragon.DragonState.TRAINING:
			dragon_state_manager.gain_experience(dragon, xp_per_update)
			scientist_action_performed.emit(ScientistType.TRAINER, "Trained %s (+%d XP)" % [dragon.dragon_name, xp_per_update])

# === UTILITY FUNCTIONS ===

func get_scientist_info(type: ScientistType) -> Dictionary:
	"""Get all info about a scientist type"""
	return SCIENTIST_DATA[type]

func get_scientist_status_text(type: ScientistType) -> String:
	"""Get status text for UI display"""
	if hired_scientists[type]:
		var cost = SCIENTIST_DATA[type]["ongoing_cost_per_minute"]
		return "Active (-%d gold/min)" % cost
	else:
		var hire_cost = SCIENTIST_DATA[type]["hire_cost"]
		return "Not hired (Cost: %d gold)" % hire_cost

func get_all_hired_scientists() -> Array:
	"""Get list of all currently hired scientist types"""
	var hired = []
	for type in hired_scientists:
		if hired_scientists[type]:
			hired.append(type)
	return hired
