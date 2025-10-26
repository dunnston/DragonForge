extends Node

# Dragon Death & Part Recovery Manager
# Handles dragon death, part recovery, decay timers, and freezer storage system

# ═══════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════

const FREEZER_UNLOCK_WAVES = 10
const FREEZER_LEVELS = [
	{"level": 1, "capacity": 5, "cost": 500},
	{"level": 2, "capacity": 10, "cost": 1500},
	{"level": 3, "capacity": 15, "cost": 4000},
	{"level": 4, "capacity": 20, "cost": 10000},
	{"level": 5, "capacity": 25, "cost": 25000}
]

# Recovery chance distributions by death cause
const RECOVERY_CHANCES = {
	"combat_defending": [0.20, 0.50, 0.25, 0.05],  # 0, 1, 2, 3 parts
	"combat_failed": [0.40, 0.40, 0.15, 0.05],
	"starvation": [0.50, 0.35, 0.10, 0.05],
	"exploration_accident": [0.30, 0.45, 0.20, 0.05]
}

# ═══════════════════════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════════════════════

signal dragon_died(dragon_name: String, cause: String, recovered_parts: Array)
signal part_recovered(part: DragonPart)
signal part_decayed(part: DragonPart)
signal freezer_unlocked(level: int)
signal freezer_upgraded(new_level: int, new_capacity: int)
signal part_frozen(part: DragonPart, slot_index: int)
signal part_unfrozen(part: DragonPart)
signal freezer_data_loaded()  # Emitted when freezer data is loaded from save

# ═══════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════

# Singleton instance
static var instance: Node = null

# Freezer system
var freezer_level: int = 0  # 0 = locked, 1-5 = upgrade level
var recovered_parts: Array[DragonPart] = []
var freezer_slots: Array = []  # Array of DragonPart or null (empty slots)

# Death notification tracking (for consolidated notifications)
var pending_deaths: Array = []  # [{dragon_name, cause, recovered_parts}]
var recently_decayed_parts: Array[DragonPart] = []
var show_summary_on_ready: bool = false

# ═══════════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════════

func _ready():
	instance = self
	_resize_freezer_slots()

	# Wait a frame for save system to load, then check for offline events
	await get_tree().process_frame
	_check_part_decay()  # Remove any parts that decayed while offline

	# Show consolidated death summary if there were offline deaths
	if show_summary_on_ready or not pending_deaths.is_empty():
		await get_tree().create_timer(0.5).timeout  # Brief delay for UI to load
		_show_death_summary()

	# Start decay check timer (check every 60 seconds)
	var decay_timer = Timer.new()
	decay_timer.wait_time = 60.0
	decay_timer.timeout.connect(_check_part_decay)
	decay_timer.autostart = true
	add_child(decay_timer)

	print("[DragonDeathManager] Initialized - Decay timer active")

# ═══════════════════════════════════════════════════════════
# DRAGON DEATH HANDLING
# ═══════════════════════════════════════════════════════════

func handle_dragon_death(dragon: Dragon, death_cause: String):
	"""
	Called when a dragon dies
	Args:
		dragon: The dragon that died
		death_cause: "combat_defending", "combat_failed", "starvation", "exploration_accident"
	"""
	print("\n💀 [DragonDeathManager] handle_dragon_death() called")
	print("   Dragon: %s" % (dragon.dragon_name if dragon else "NULL"))
	print("   Cause: %s" % death_cause)

	if not dragon:
		print("❌ [DragonDeathManager] Dragon is null, aborting")
		return

	# Roll for part recovery
	print("🎲 [DragonDeathManager] Rolling for part recovery...")
	var num_parts = _roll_part_recovery(death_cause)
	print("   Recovered %d parts" % num_parts)

	# Select which parts to recover
	var recovered = _select_parts_from_dragon(dragon, num_parts)
	print("📦 [DragonDeathManager] Selected %d parts from dragon" % recovered.size())

	# Mark parts as recovered with timestamp and add to inventory
	for part in recovered:
		part.source = DragonPart.Source.RECOVERED
		part.recovery_timestamp = Time.get_unix_time_from_system()
		part.part_id = _generate_part_id()
		recovered_parts.append(part)
		part_recovered.emit(part)
		print("   ✅ Recovered: %s (Decays in 24h)" % part.get_display_name())

		# Add part to inventory system
		var item_id = _convert_part_to_item_id(part)
		if item_id and InventoryManager and InventoryManager.instance:
			if InventoryManager.instance.add_item_by_id(item_id, 1):
				print("   📦 Added %s to inventory" % item_id)
			else:
				print("   ⚠️ Failed to add %s to inventory (full?)" % item_id)

	# Emit death signal
	print("📡 [DragonDeathManager] Emitting dragon_died signal")
	dragon_died.emit(dragon.dragon_name, death_cause, recovered)

	# Play death sound
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_dragon_death()

	# Queue death for consolidated notification (save dragon parts for visual)
	pending_deaths.append({
		"dragon_name": dragon.dragon_name,
		"dragon_level": dragon.level,
		"cause": death_cause,
		"recovered_parts": recovered,
		"head_part": dragon.head_part,
		"body_part": dragon.body_part,
		"tail_part": dragon.tail_part
	})
	print("📋 [DragonDeathManager] Death queued for summary notification")

	# Don't show popup during battle - let the battle arena trigger it after battle ends
	print("✅ [DragonDeathManager] handle_dragon_death() complete\n")

func _roll_part_recovery(death_cause: String) -> int:
	"""Roll dice to determine how many parts are recovered"""
	var chances = RECOVERY_CHANCES.get(death_cause, RECOVERY_CHANCES["combat_failed"])

	var roll = randf()
	var cumulative = 0.0

	for i in range(4):  # 0, 1, 2, 3 parts
		cumulative += chances[i]
		if roll <= cumulative:
			return i

	return 0

func _select_parts_from_dragon(dragon: Dragon, count: int) -> Array[DragonPart]:
	"""Randomly select 'count' parts from the dragon"""
	if not dragon or count <= 0:
		return []

	# Get all parts from dragon
	var available = []
	if dragon.head_part:
		var part_copy = dragon.head_part.duplicate(true)  # Deep duplicate
		print("[DragonDeathManager] Duplicating head part - icon_path: '%s'" % part_copy.icon_path)
		available.append(part_copy)
	if dragon.body_part:
		var part_copy = dragon.body_part.duplicate(true)  # Deep duplicate
		print("[DragonDeathManager] Duplicating body part - icon_path: '%s'" % part_copy.icon_path)
		available.append(part_copy)
	if dragon.tail_part:
		var part_copy = dragon.tail_part.duplicate(true)  # Deep duplicate
		print("[DragonDeathManager] Duplicating tail part - icon_path: '%s'" % part_copy.icon_path)
		available.append(part_copy)

	# Shuffle and take first 'count' parts
	available.shuffle()

	var recovered: Array[DragonPart] = []
	for i in range(min(count, available.size())):
		recovered.append(available[i])

	return recovered

func _generate_part_id() -> String:
	"""Generate unique ID for part tracking"""
	return "%d_%d" % [Time.get_ticks_msec(), randi()]

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
	# This allows decay timers to be shown on recovered stacks only
	return "%s_%s_recovered" % [element_name, part_type_name]

func _show_death_notification(dragon: Dragon, cause: String, parts: Array):
	"""Create and show death popup"""
	# Print to console
	print("═══════════════════════════════════════════════")
	print("💀 DRAGON LOST: %s" % dragon.dragon_name)
	print("Cause: %s" % _format_death_cause(cause))
	print("Parts Recovered: %d/3" % parts.size())
	for part in parts:
		print("  - %s" % part.get_display_name())
	print("═══════════════════════════════════════════════")

	# Show death popup UI
	print("📂 [DragonDeathManager] Loading death popup scene...")
	var popup_scene = load("res://scenes/ui/dragon_death_popup.tscn")

	if popup_scene:
		print("✅ [DragonDeathManager] Scene loaded successfully")
		print("🎬 [DragonDeathManager] Instantiating popup...")
		var popup = popup_scene.instantiate()

		if popup:
			print("✅ [DragonDeathManager] Popup instantiated")

			# Ensure popup is on top of everything
			if popup is Control:
				popup.z_index = 1000
				print("🔝 [DragonDeathManager] Set z_index to 1000")

			print("🌲 [DragonDeathManager] Adding popup to scene tree...")
			get_tree().root.add_child(popup)

			# Move to front after adding
			popup.move_to_front()
			print("✅ [DragonDeathManager] Popup added to scene tree")

			# NOW call setup after @onready vars are initialized
			print("⚙️ [DragonDeathManager] Calling popup.setup()...")
			popup.setup(dragon, cause, parts)
			print("✅ [DragonDeathManager] Popup setup complete - should be visible now!")
		else:
			print("❌ [DragonDeathManager] Failed to instantiate popup!")
	else:
		print("❌ [DragonDeathManager] Warning: Death popup scene not found!")

func _format_death_cause(cause: String) -> String:
	"""Get human-readable death cause"""
	match cause:
		"combat_defending":
			return "Defeated in combat defending laboratory"
		"combat_failed":
			return "Killed when defenses were overwhelmed"
		"starvation":
			return "Died of starvation"
		"exploration_accident":
			return "Lost during exploration expedition"
		_:
			return "Unknown cause"

func _show_single_dragon_death_popup(death_data: Dictionary):
	"""Queue notification for a single dragon death"""
	# Create a temporary dragon object with the saved data
	var temp_dragon = Dragon.new()
	temp_dragon.dragon_name = death_data.get("dragon_name", "Unknown")
	temp_dragon.level = death_data.get("dragon_level", 1)

	# Set dragon parts for visual recreation
	if death_data.has("head_part"):
		temp_dragon.head_part = death_data["head_part"]
	if death_data.has("body_part"):
		temp_dragon.body_part = death_data["body_part"]
	if death_data.has("tail_part"):
		temp_dragon.tail_part = death_data["tail_part"]

	var cause = death_data.get("cause", "unknown")
	var recovered_parts = death_data.get("recovered_parts", [])

	print("\n💀 [DragonDeathManager] Queuing death notification for %s" % temp_dragon.dragon_name)
	print("   Cause: %s" % cause)
	print("   Parts recovered: %d" % recovered_parts.size())

	# Load popup scene
	print("   Loading popup scene...")
	var popup_scene = load("res://scenes/ui/dragon_death_popup.tscn")

	if not popup_scene:
		print("   ❌ FAILED: Death popup scene not found!")
		return

	print("   ✅ Popup scene loaded: %s" % popup_scene)

	# Queue notification through NotificationQueueManager
	if NotificationQueueManager and NotificationQueueManager.instance:
		print("   Calling NotificationQueueManager.queue_notification()...")
		var result = NotificationQueueManager.instance.queue_notification({
			"type": "dragon_death",
			"title": "Dragon Lost",
			"data": {
				"dragon": temp_dragon,
				"cause": cause,
				"recovered_parts": recovered_parts
			},
			"popup_scene": popup_scene,
			"context": "",  # Single deaths don't need batching context
			"can_batch": false  # Already handled batching in DragonDeathManager
		})
		print("   Queue result: %s" % result)
		if result:
			print("   ✅ Death notification successfully queued!\n")
		else:
			print("   ❌ Failed to queue death notification!\n")
	else:
		print("   ❌ NotificationQueueManager not available!\n")

func has_pending_deaths() -> bool:
	"""Check if there are any pending deaths to report"""
	return not pending_deaths.is_empty()

func show_death_summary_if_needed():
	"""Public function to show death summary - called after battle ends"""
	if not pending_deaths.is_empty() or not recently_decayed_parts.is_empty():
		_show_death_summary()

func _show_death_summary():
	"""Show consolidated notification for multiple deaths and decayed parts"""
	if pending_deaths.is_empty() and recently_decayed_parts.is_empty():
		return

	print("\n📊 [DragonDeathManager] Showing death summary...")
	print("   Pending deaths: %d" % pending_deaths.size())
	print("   Recently decayed: %d" % recently_decayed_parts.size())

	# If only 1 death and no decay, use the beautiful single-dragon popup
	if pending_deaths.size() == 1 and recently_decayed_parts.is_empty():
		var death = pending_deaths[0]
		print("   Using single-dragon popup (prettier!)")
		_show_single_dragon_death_popup(death)
		pending_deaths.clear()
		return

	# Otherwise, show consolidated summary for multiple events
	
	# Load the new scrollable laboratory report popup
	var popup_scene = load("res://scenes/ui/laboratory_report_popup.tscn")
	if not popup_scene:
		print("❌ [DragonDeathManager] Laboratory report popup scene not found!")
		return
	
	var popup = popup_scene.instantiate()
	if not popup:
		print("❌ [DragonDeathManager] Failed to instantiate laboratory report popup!")
		return
	
	# Add to scene tree first so @onready variables are initialized
	popup.z_index = 1000
	get_tree().root.add_child(popup)
	popup.move_to_front()
	
	# Setup popup with death and decay data (after _ready() is called)
	popup.setup(pending_deaths, recently_decayed_parts)
	
	# Clear pending notifications
	pending_deaths.clear()
	recently_decayed_parts.clear()

	print("✅ [DragonDeathManager] Death summary shown and cleared\n")

# ═══════════════════════════════════════════════════════════
# DECAY SYSTEM
# ═══════════════════════════════════════════════════════════

func _check_part_decay():
	"""Called every minute to check for decayed parts"""
	var decayed: Array[DragonPart] = []

	for part in recovered_parts:
		if part.is_decayed():
			decayed.append(part)

	# Remove decayed parts from recovered list and inventory
	for part in decayed:
		recovered_parts.erase(part)
		recently_decayed_parts.append(part)  # Track for summary notification
		part_decayed.emit(part)

		# Remove from inventory
		var item_id = _convert_part_to_item_id(part)
		if item_id and InventoryManager and InventoryManager.instance:
			InventoryManager.instance.remove_item_by_id(item_id, 1)
			print("[DragonDeathManager] 💀 %s decayed and removed from inventory" % part.get_display_name())
		_show_decay_notification(part)
		print("[DragonDeathManager] 💀 %s has decayed and crumbled to dust!" % part.get_display_name())

func _show_decay_notification(part: DragonPart):
	"""Show notification that part has decayed"""
	# TODO: Show in-game notification popup
	pass

func get_decay_warnings() -> Array[DragonPart]:
	"""Returns parts that are close to decaying (<1 hour)"""
	var warnings: Array[DragonPart] = []
	for part in recovered_parts:
		if part.get_time_until_decay() < 3600:  # Less than 1 hour
			warnings.append(part)
	return warnings

# ═══════════════════════════════════════════════════════════
# FREEZER SYSTEM - UNLOCK & UPGRADE
# ═══════════════════════════════════════════════════════════

func can_unlock_freezer() -> bool:
	"""Check if player has met requirements to unlock freezer"""
	if freezer_level > 0:
		return false  # Already unlocked

	if not DefenseManager or not DefenseManager.instance:
		return false

	var waves = DefenseManager.instance.wave_number
	return waves >= FREEZER_UNLOCK_WAVES

func get_freezer_unlock_progress() -> float:
	"""Get progress towards freezer unlock (0.0 to 1.0)"""
	if not DefenseManager or not DefenseManager.instance:
		return 0.0

	var waves = DefenseManager.instance.wave_number
	return clampf(float(waves) / float(FREEZER_UNLOCK_WAVES), 0.0, 1.0)

func unlock_freezer() -> bool:
	"""Purchase Level 1 freezer"""
	if not can_unlock_freezer():
		print("[DragonDeathManager] Cannot unlock freezer yet!")
		return false

	var cost = FREEZER_LEVELS[0].cost

	if not TreasureVault or not TreasureVault.instance:
		print("[DragonDeathManager] TreasureVault not available!")
		return false

	if not TreasureVault.instance.spend_gold(cost):
		print("[DragonDeathManager] Not enough gold! Need %d" % cost)
		return false

	freezer_level = 1
	_resize_freezer_slots()
	freezer_unlocked.emit(1)
	print("[DragonDeathManager] ❄️ Freezer unlocked! (Level 1, 5 slots)")
	return true

func can_upgrade_freezer() -> bool:
	"""Check if freezer can be upgraded"""
	return freezer_level > 0 and freezer_level < FREEZER_LEVELS.size()

func get_next_freezer_upgrade() -> Dictionary:
	"""Returns info about next upgrade level or empty dict if maxed"""
	if not can_upgrade_freezer():
		return {}
	return FREEZER_LEVELS[freezer_level]  # Next level (0-indexed)

func upgrade_freezer() -> bool:
	"""Purchase next freezer upgrade level"""
	if not can_upgrade_freezer():
		print("[DragonDeathManager] Freezer already maxed or not unlocked!")
		return false

	var upgrade = get_next_freezer_upgrade()

	if not TreasureVault or not TreasureVault.instance:
		print("[DragonDeathManager] TreasureVault not available!")
		return false

	if not TreasureVault.instance.spend_gold(upgrade.cost):
		print("[DragonDeathManager] Not enough gold! Need %d" % upgrade.cost)
		return false

	freezer_level += 1
	_resize_freezer_slots()
	freezer_upgraded.emit(freezer_level, get_freezer_capacity())
	print("[DragonDeathManager] ❄️ Freezer upgraded to Level %d! (%d slots)" % [freezer_level, get_freezer_capacity()])
	return true

func get_freezer_capacity() -> int:
	"""Returns current maximum freezer slots"""
	if freezer_level == 0:
		return 0
	return FREEZER_LEVELS[freezer_level - 1].capacity

func get_freezer_used_slots() -> int:
	"""Returns number of slots currently occupied"""
	var count = 0
	for slot in freezer_slots:
		if slot != null:
			count += 1
	return count

func get_freezer_empty_slots() -> int:
	"""Returns number of available empty slots"""
	return get_freezer_capacity() - get_freezer_used_slots()

func _resize_freezer_slots():
	"""Resize freezer_slots array to match current capacity"""
	var capacity = get_freezer_capacity()
	freezer_slots.resize(capacity)

	# Initialize new slots to null
	for i in range(freezer_slots.size()):
		if i >= freezer_slots.size() or freezer_slots[i] == null:
			freezer_slots[i] = null

# ═══════════════════════════════════════════════════════════
# FREEZER SYSTEM - PART MANAGEMENT
# ═══════════════════════════════════════════════════════════

func freeze_part(part: DragonPart, slot_index: int) -> bool:
	"""
	Move a recovered part into freezer slot
	Args:
		part: The DragonPart to freeze
		slot_index: Which freezer slot to use (0-based)
	Returns:
		true if successful
	"""
	# Validate
	if freezer_level == 0:
		print("[DragonDeathManager] Freezer not unlocked!")
		return false

	if slot_index < 0 or slot_index >= get_freezer_capacity():
		print("[DragonDeathManager] Invalid slot index: %d" % slot_index)
		return false

	if freezer_slots[slot_index] != null:
		print("[DragonDeathManager] Slot %d is already occupied!" % slot_index)
		return false

	if not part in recovered_parts:
		print("[DragonDeathManager] Part not in recovered inventory!")
		return false

	# Remove from recovered inventory
	recovered_parts.erase(part)

	# Change part state
	part.source = DragonPart.Source.FROZEN
	part.recovery_timestamp = 0  # Clear decay timer
	part.freezer_slot_index = slot_index

	# Add to freezer
	freezer_slots[slot_index] = part

	part_frozen.emit(part, slot_index)
	print("[DragonDeathManager] ❄️ Froze %s in slot %d" % [part.get_display_name(), slot_index])
	return true

func unfreeze_part(slot_index: int) -> bool:
	"""
	Remove part from freezer and return to recovered inventory
	Args:
		slot_index: Freezer slot to remove from
	Returns:
		true if successful
	"""
	if slot_index < 0 or slot_index >= freezer_slots.size():
		print("[DragonDeathManager] Invalid slot index: %d" % slot_index)
		return false

	var part = freezer_slots[slot_index]
	if part == null:
		print("[DragonDeathManager] Slot %d is empty!" % slot_index)
		return false

	# Remove from freezer
	freezer_slots[slot_index] = null

	# Change part state back to recovered
	part.source = DragonPart.Source.RECOVERED
	part.recovery_timestamp = Time.get_unix_time_from_system()  # Reset decay timer (24h from now)
	part.freezer_slot_index = -1

	# Add to recovered inventory
	recovered_parts.append(part)

	part_unfrozen.emit(part)
	print("[DragonDeathManager] Unfroze %s from slot %d (24h decay timer started)" % [part.get_display_name(), slot_index])
	return true

func get_part_in_freezer_slot(slot_index: int) -> DragonPart:
	"""Returns part in slot or null if empty"""
	if slot_index >= 0 and slot_index < freezer_slots.size():
		return freezer_slots[slot_index]
	return null

func is_freezer_slot_empty(slot_index: int) -> bool:
	"""Check if freezer slot is empty"""
	if slot_index < 0 or slot_index >= freezer_slots.size():
		return false
	return freezer_slots[slot_index] == null

# ═══════════════════════════════════════════════════════════
# SAVE/LOAD
# ═══════════════════════════════════════════════════════════

func to_save_dict() -> Dictionary:
	"""Serialize state for saving"""
	# Serialize pending deaths (convert DragonPart objects to dicts)
	var serialized_deaths = []
	for death in pending_deaths:
		var death_dict = {
			"dragon_name": death["dragon_name"],
			"dragon_level": death["dragon_level"],
			"cause": death["cause"],
			"recovered_parts": _serialize_parts(death["recovered_parts"])
		}

		# Serialize dragon parts if they exist (for visual recreation)
		if death.has("head_part") and death["head_part"]:
			death_dict["head_part"] = _serialize_single_part(death["head_part"])
		if death.has("body_part") and death["body_part"]:
			death_dict["body_part"] = _serialize_single_part(death["body_part"])
		if death.has("tail_part") and death["tail_part"]:
			death_dict["tail_part"] = _serialize_single_part(death["tail_part"])

		serialized_deaths.append(death_dict)

	return {
		"freezer_level": freezer_level,
		"recovered_parts": _serialize_parts(recovered_parts),
		"freezer_slots": _serialize_freezer_slots(),
		"pending_deaths": serialized_deaths,
		"recently_decayed": _serialize_parts(recently_decayed_parts)
	}

func load_from_dict(data: Dictionary):
	"""Restore state from save data"""
	freezer_level = data.get("freezer_level", 0)
	_resize_freezer_slots()

	recovered_parts = _deserialize_parts(data.get("recovered_parts", []))
	_deserialize_freezer_slots(data.get("freezer_slots", []))

	# Restore pending deaths (deserialize DragonPart objects)
	pending_deaths = []
	for death_data in data.get("pending_deaths", []):
		var death_dict = {
			"dragon_name": death_data.get("dragon_name", "Unknown"),
			"dragon_level": death_data.get("dragon_level", 1),
			"cause": death_data.get("cause", "unknown"),
			"recovered_parts": _deserialize_parts(death_data.get("recovered_parts", []))
		}

		# Deserialize dragon parts if they exist (for visual recreation)
		if death_data.has("head_part"):
			death_dict["head_part"] = _deserialize_single_part(death_data["head_part"])
		if death_data.has("body_part"):
			death_dict["body_part"] = _deserialize_single_part(death_data["body_part"])
		if death_data.has("tail_part"):
			death_dict["tail_part"] = _deserialize_single_part(death_data["tail_part"])

		pending_deaths.append(death_dict)

	recently_decayed_parts = _deserialize_parts(data.get("recently_decayed", []))

	# Flag to show summary on ready if there are pending events
	show_summary_on_ready = not pending_deaths.is_empty() or not recently_decayed_parts.is_empty()

	print("[DragonDeathManager] Loaded state - Freezer Level: %d, Recovered Parts: %d, Pending Deaths: %d, Decayed: %d" % [
		freezer_level,
		recovered_parts.size(),
		pending_deaths.size(),
		recently_decayed_parts.size()
	])
	
	# Emit signal so UI can refresh
	freezer_data_loaded.emit()

func _serialize_parts(parts: Array[DragonPart]) -> Array:
	"""Convert parts array to saveable format"""
	var result = []
	for part in parts:
		result.append(_serialize_single_part(part))
	return result

func _serialize_single_part(part: DragonPart) -> Dictionary:
	"""Convert a single DragonPart to a dictionary"""
	return {
		"id": part.part_id,
		"type": part.part_type,
		"element": part.element,
		"rarity": part.rarity,
		"timestamp": part.recovery_timestamp,
		"attack_bonus": part.attack_bonus,
		"health_bonus": part.health_bonus,
		"speed_bonus": part.speed_bonus,
		"defense_bonus": part.defense_bonus
	}

func _deserialize_parts(data: Array) -> Array[DragonPart]:
	"""Restore parts array from save data"""
	var parts: Array[DragonPart] = []
	for part_data in data:
		parts.append(_deserialize_single_part(part_data))
	return parts

func _deserialize_single_part(part_data: Dictionary) -> DragonPart:
	"""Restore a single DragonPart from save data"""
	var part = DragonPart.new()
	part.part_id = part_data.get("id", "")
	part.part_type = part_data.get("type", 0)
	part.element = part_data.get("element", 0)
	part.rarity = part_data.get("rarity", 1)
	part.source = DragonPart.Source.RECOVERED
	part.recovery_timestamp = part_data.get("timestamp", 0)
	part.attack_bonus = part_data.get("attack_bonus", 0)
	part.health_bonus = part_data.get("health_bonus", 0)
	part.speed_bonus = part_data.get("speed_bonus", 0)
	part.defense_bonus = part_data.get("defense_bonus", 0)
	
	# Get the icon_path from PartLibrary based on element and type
	if PartLibrary and PartLibrary.instance:
		var library_part = PartLibrary.instance.get_part_by_element_and_type(part.element, part.part_type)
		if library_part:
			part.icon_path = library_part.icon_path
	
	return part

func _serialize_freezer_slots() -> Array:
	"""Convert freezer slots to saveable format"""
	var result = []
	for i in range(freezer_slots.size()):
		if freezer_slots[i] != null:
			var part = freezer_slots[i]
			result.append({
				"slot": i,
				"id": part.part_id,
				"type": part.part_type,
				"element": part.element,
				"rarity": part.rarity,
				"attack_bonus": part.attack_bonus,
				"health_bonus": part.health_bonus,
				"speed_bonus": part.speed_bonus,
				"defense_bonus": part.defense_bonus
			})
	return result

func _deserialize_freezer_slots(data: Array):
	"""Restore freezer slots from save data"""
	for slot_data in data:
		var part = DragonPart.new()
		part.part_id = slot_data.get("id", "")
		part.part_type = slot_data.get("type", 0)
		part.element = slot_data.get("element", 0)
		part.rarity = slot_data.get("rarity", 1)
		part.source = DragonPart.Source.FROZEN
		part.freezer_slot_index = slot_data.get("slot", -1)
		part.attack_bonus = slot_data.get("attack_bonus", 0)
		part.health_bonus = slot_data.get("health_bonus", 0)
		part.speed_bonus = slot_data.get("speed_bonus", 0)
		part.defense_bonus = slot_data.get("defense_bonus", 0)

		# Get the icon_path from PartLibrary based on element and type
		if PartLibrary and PartLibrary.instance:
			var library_part = PartLibrary.instance.get_part_by_element_and_type(part.element, part.part_type)
			if library_part:
				part.icon_path = library_part.icon_path

		var slot_index = slot_data.get("slot", -1)
		if slot_index >= 0 and slot_index < freezer_slots.size():
			freezer_slots[slot_index] = part

# ═══════════════════════════════════════════════════════════
# DEBUG FUNCTIONS
# ═══════════════════════════════════════════════════════════

func debug_add_recovered_part(element: int, part_type: int):
	"""Debug: Manually add a recovered part"""
	var part = DragonPart.new()
	part.element = element
	part.part_type = part_type
	part.source = DragonPart.Source.RECOVERED
	part.recovery_timestamp = Time.get_unix_time_from_system()
	part.part_id = _generate_part_id()
	part.attack_bonus = randi() % 10 + 5
	part.health_bonus = randi() % 10 + 5
	part.speed_bonus = randi() % 10 + 5

	recovered_parts.append(part)
	print("[DragonDeathManager] 🧪 DEBUG: Added recovered %s" % part.get_display_name())

func debug_force_decay(part: DragonPart):
	"""Debug: Force a part to decay immediately"""
	if part in recovered_parts:
		part.recovery_timestamp = Time.get_unix_time_from_system() - 86401  # 1 second past 24h
		print("[DragonDeathManager] 🧪 DEBUG: Forced %s to decay" % part.get_display_name())

func debug_unlock_freezer():
	"""Debug: Force unlock freezer"""
	freezer_level = 1
	_resize_freezer_slots()
	print("[DragonDeathManager] 🧪 DEBUG: Freezer force-unlocked")

func debug_force_decay_all():
	"""Debug: Force all recovered parts to decay immediately"""
	print("[DragonDeathManager] 🧪 DEBUG: Forcing all recovered parts to decay...")
	for part in recovered_parts:
		part.recovery_timestamp = Time.get_unix_time_from_system() - 86401  # Past 24h
	_check_part_decay()
	print("[DragonDeathManager] 🧪 DEBUG: Decay check complete")

func debug_show_summary():
	"""Debug: Force show death summary with current pending data"""
	print("[DragonDeathManager] 🧪 DEBUG: Forcing death summary to show...")
	_show_death_summary()

func debug_add_fake_death(dragon_name: String = "Test Dragon"):
	"""Debug: Add a fake death to pending queue"""
	var fake_parts = []
	for i in range(randi() % 3 + 1):  # 1-3 random parts
		var part = DragonPart.new()
		part.element = randi() % 5
		part.part_type = randi() % 3
		part.source = DragonPart.Source.RECOVERED
		part.recovery_timestamp = Time.get_unix_time_from_system()
		part.part_id = _generate_part_id()
		fake_parts.append(part)

	pending_deaths.append({
		"dragon_name": dragon_name,
		"dragon_level": randi() % 10 + 1,
		"cause": ["combat_defending", "starvation", "exploration_accident", "combat_failed"][randi() % 4],
		"recovered_parts": fake_parts
	})
	print("[DragonDeathManager] 🧪 DEBUG: Added fake death for %s (%d parts)" % [dragon_name, fake_parts.size()])

func get_status() -> Dictionary:
	"""Get current status for debugging"""
	return {
		"freezer_level": freezer_level,
		"freezer_capacity": get_freezer_capacity(),
		"freezer_used": get_freezer_used_slots(),
		"recovered_parts": recovered_parts.size(),
		"decay_warnings": get_decay_warnings().size()
	}
