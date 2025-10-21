# InventorySlot - Represents a single slot in the inventory that can hold stacked items
extends Resource
class_name InventorySlot

var item: Item = null
var quantity: int = 0

func _init(item_instance: Item = null, qty: int = 0):
	item = item_instance
	quantity = qty

func is_empty() -> bool:
	"""Check if this slot is empty"""
	return item == null or quantity <= 0

func can_add_item(new_item: Item, amount: int = 1) -> bool:
	"""Check if we can add an item to this slot"""
	# Empty slot can accept any item
	if is_empty():
		return true

	# Non-empty slot can only accept stackable matching items
	if not item.can_stack_with(new_item):
		return false

	# Check if we have room in the stack
	return (quantity + amount) <= item.max_stack

func add_item(new_item: Item, amount: int = 1) -> int:
	"""
	Add items to this slot
	Returns: number of items that couldn't be added (overflow)
	"""
	# If slot is empty, just set the item
	if is_empty():
		item = new_item
		var amount_to_add = min(amount, item.max_stack)
		quantity = amount_to_add
		return amount - amount_to_add

	# Check if items can stack
	if not item.can_stack_with(new_item):
		return amount  # Can't add any

	# Add to existing stack
	var space_left = item.max_stack - quantity
	var amount_to_add = min(amount, space_left)
	quantity += amount_to_add

	return amount - amount_to_add  # Return overflow

func remove_item(amount: int = 1) -> int:
	"""
	Remove items from this slot
	Returns: number of items actually removed
	"""
	if is_empty():
		return 0

	var amount_to_remove = min(amount, quantity)
	quantity -= amount_to_remove

	# Clear slot if empty
	if quantity <= 0:
		item = null
		quantity = 0

	return amount_to_remove

func get_item_id() -> String:
	"""Get the ID of the item in this slot"""
	if item:
		return item.id
	return ""

func get_quantity() -> int:
	"""Get the quantity of items in this slot"""
	return quantity

func get_item() -> Item:
	"""Get the item in this slot"""
	return item

func is_full() -> bool:
	"""Check if this slot is at max capacity"""
	if is_empty():
		return false
	return quantity >= item.max_stack

func get_remaining_space() -> int:
	"""Get how many more items can fit in this slot"""
	if is_empty():
		return 99  # Assume max stack of 99 for empty slots
	return item.max_stack - quantity

func to_dict() -> Dictionary:
	"""Convert slot to dictionary for saving"""
	if is_empty():
		return {"empty": true}

	return {
		"empty": false,
		"item": item.to_dict() if item else {},
		"quantity": quantity
	}

static func from_dict(data: Dictionary) -> InventorySlot:
	"""Create slot from dictionary (for loading)"""
	if data.get("empty", true):
		return InventorySlot.new()

	var item_instance = Item.from_dict(data.get("item", {}))
	var qty = data.get("quantity", 0)
	return InventorySlot.new(item_instance, qty)

func clone() -> InventorySlot:
	"""Create a copy of this slot"""
	if is_empty():
		return InventorySlot.new()
	return InventorySlot.new(item, quantity)
