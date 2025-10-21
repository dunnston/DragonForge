# InventoryManager - Manages a grid-based inventory with stackable items
extends Node

# === SINGLETON ===
static var instance: InventoryManager

# === INVENTORY SETTINGS ===
const INVENTORY_SIZE: int = 50  # Total number of slots
var inventory_slots: Array[InventorySlot] = []

# === SIGNALS ===
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal slot_changed(slot_index: int)
signal inventory_full()

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	# Initialize empty inventory slots
	for i in range(INVENTORY_SIZE):
		inventory_slots.append(InventorySlot.new())

	print("[InventoryManager] Initialized with %d slots" % INVENTORY_SIZE)

# === ITEM MANAGEMENT ===

func add_item_by_id(item_id: String, quantity: int = 1) -> bool:
	"""
	Add items to inventory by item ID.
	Returns true if all items were added, false if some couldn't fit.
	"""
	if not ItemDatabase or not ItemDatabase.instance:
		print("[InventoryManager] ERROR: ItemDatabase not available")
		return false

	if not ItemDatabase.instance.item_exists(item_id):
		print("[InventoryManager] ERROR: Invalid item ID: %s" % item_id)
		return false

	var remaining = quantity

	# First, try to add to existing stacks
	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		if slot.is_empty():
			continue

		if slot.get_item_id() == item_id and not slot.is_full():
			var item = ItemDatabase.instance.get_item(item_id)
			var overflow = slot.add_item(item, remaining)
			var added = remaining - overflow
			remaining = overflow

			if added > 0:
				slot_changed.emit(i)

			if remaining <= 0:
				item_added.emit(item_id, quantity)
				return true

	# Then, fill empty slots
	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		if not slot.is_empty():
			continue

		var item = ItemDatabase.instance.get_item(item_id)
		var overflow = slot.add_item(item, remaining)
		var added = remaining - overflow
		remaining = overflow

		if added > 0:
			slot_changed.emit(i)

		if remaining <= 0:
			item_added.emit(item_id, quantity)
			return true

	# If we still have items left, inventory is full
	if remaining > 0:
		inventory_full.emit()
		item_added.emit(item_id, quantity - remaining)
		print("[InventoryManager] Inventory full! Could not add %d %s" % [remaining, item_id])
		return false

	return true

func remove_item_by_id(item_id: String, quantity: int = 1) -> int:
	"""
	Remove items from inventory by item ID.
	Returns the actual number of items removed.
	"""
	var removed_total = 0
	var remaining = quantity

	# Remove from slots (starting from the end to maintain order)
	for i in range(inventory_slots.size() - 1, -1, -1):
		var slot = inventory_slots[i]
		if slot.is_empty():
			continue

		if slot.get_item_id() != item_id:
			continue

		var amount_to_remove = min(remaining, slot.get_quantity())
		var actually_removed = slot.remove_item(amount_to_remove)
		removed_total += actually_removed
		remaining -= actually_removed

		slot_changed.emit(i)

		if remaining <= 0:
			break

	if removed_total > 0:
		item_removed.emit(item_id, removed_total)

	return removed_total

func get_item_count(item_id: String) -> int:
	"""Get total quantity of an item across all slots"""
	var total = 0
	for slot in inventory_slots:
		if not slot.is_empty() and slot.get_item_id() == item_id:
			total += slot.get_quantity()
	return total

func has_item(item_id: String, quantity: int = 1) -> bool:
	"""Check if inventory contains at least the specified quantity of an item"""
	return get_item_count(item_id) >= quantity

func get_slot(index: int) -> InventorySlot:
	"""Get a specific inventory slot"""
	if index < 0 or index >= inventory_slots.size():
		return null
	return inventory_slots[index]

func get_all_slots() -> Array[InventorySlot]:
	"""Get all inventory slots"""
	return inventory_slots

func get_slot_count() -> int:
	"""Get total number of slots"""
	return inventory_slots.size()

func get_empty_slot_count() -> int:
	"""Get number of empty slots"""
	var count = 0
	for slot in inventory_slots:
		if slot.is_empty():
			count += 1
	return count

func is_full() -> bool:
	"""Check if inventory has no empty slots"""
	return get_empty_slot_count() == 0

func clear_inventory():
	"""Remove all items from inventory"""
	for i in range(inventory_slots.size()):
		inventory_slots[i] = InventorySlot.new()
		slot_changed.emit(i)

# === ITEM QUERIES ===

func get_all_dragon_parts() -> Array:
	"""Get all dragon parts in inventory with their quantities"""
	var parts: Array = []
	for slot in inventory_slots:
		if slot.is_empty():
			continue
		var item = slot.get_item()
		if item and item.is_dragon_part():
			parts.append({
				"item_id": slot.get_item_id(),
				"item": item,
				"quantity": slot.get_quantity()
			})
	return parts

func get_dragon_parts_by_type(part_type: String) -> Array:
	"""Get dragon parts filtered by type (HEAD, BODY, TAIL)"""
	var parts: Array = []
	for slot in inventory_slots:
		if slot.is_empty():
			continue
		var item = slot.get_item()
		if item and item.is_dragon_part() and item.part_type == part_type:
			parts.append({
				"item_id": slot.get_item_id(),
				"item": item,
				"quantity": slot.get_quantity()
			})
	return parts

func can_craft_dragon(head_id: String, body_id: String, tail_id: String) -> bool:
	"""Check if we have the parts needed to craft a dragon"""
	return has_item(head_id, 1) and has_item(body_id, 1) and has_item(tail_id, 1)

# === SERIALIZATION ===

func to_dict() -> Dictionary:
	"""Save inventory to dictionary"""
	var slots_data: Array = []
	for slot in inventory_slots:
		slots_data.append(slot.to_dict())

	return {
		"slots": slots_data,
		"inventory_size": INVENTORY_SIZE
	}

func from_dict(data: Dictionary):
	"""Load inventory from dictionary"""
	var slots_data = data.get("slots", [])

	# Clear current inventory
	inventory_slots.clear()

	# Load slots
	for slot_data in slots_data:
		inventory_slots.append(InventorySlot.from_dict(slot_data))

	# Fill remaining slots if needed
	while inventory_slots.size() < INVENTORY_SIZE:
		inventory_slots.append(InventorySlot.new())

	# Emit all slot changed signals
	for i in range(inventory_slots.size()):
		slot_changed.emit(i)

	print("[InventoryManager] Loaded %d slots" % inventory_slots.size())

# === DEBUG ===

func print_inventory():
	"""Debug: Print inventory contents"""
	print("\n=== INVENTORY ===")
	print("Slots: %d/%d used" % [INVENTORY_SIZE - get_empty_slot_count(), INVENTORY_SIZE])

	var item_counts: Dictionary = {}
	for slot in inventory_slots:
		if slot.is_empty():
			continue
		var item_id = slot.get_item_id()
		if not item_counts.has(item_id):
			item_counts[item_id] = 0
		item_counts[item_id] += slot.get_quantity()

	for item_id in item_counts:
		print("  %s: x%d" % [item_id, item_counts[item_id]])

	print("=================\n")

func add_starting_items():
	"""Add starting items for testing/new game"""
	# Add some dragon parts
	for element in ["fire", "ice", "lightning", "nature", "shadow"]:
		add_item_by_id(element + "_head", 2)
		add_item_by_id(element + "_body", 2)
		add_item_by_id(element + "_tail", 2)

	# Add some consumables
	add_item_by_id("food", 5)
	add_item_by_id("treat", 3)
	add_item_by_id("health_potion", 2)
	add_item_by_id("toy", 2)

	print("[InventoryManager] Added starting items")
