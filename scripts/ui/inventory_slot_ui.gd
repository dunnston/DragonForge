# InventorySlotUI - Visual representation of a single inventory slot
extends PanelContainer

signal slot_clicked(slot_index: int)
signal slot_hovered(slot_index: int, item: Item)

@onready var item_icon: TextureRect = $MarginContainer/ItemIcon
@onready var stack_label: Label = $StackLabel
@onready var empty_indicator: ColorRect = $EmptyIndicator

var slot_index: int = -1
var current_item: Item = null
var stack_count: int = 0

# Visual settings
const SLOT_SIZE: Vector2 = Vector2(80, 80)
const EMPTY_COLOR: Color = Color(0.1, 0.15, 0.15, 0.8)
const FILLED_COLOR: Color = Color(0.15, 0.25, 0.25, 1.0)

func _ready():
	custom_minimum_size = SLOT_SIZE

	# Connect mouse events
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	gui_input.connect(_on_gui_input)

	# Start empty
	set_empty()

func set_slot_index(index: int):
	"""Set the index of this slot in the inventory"""
	slot_index = index

func update_slot(slot: InventorySlot):
	"""Update the visual display based on inventory slot data"""
	if not slot or slot.is_empty():
		set_empty()
		return

	current_item = slot.get_item()
	stack_count = slot.get_quantity()

	# Show item icon
	if current_item:
		var icon_texture = current_item.get_icon()
		if icon_texture:
			item_icon.texture = icon_texture
			item_icon.visible = true
		else:
			# Use placeholder color based on item type
			_set_placeholder_visual()

	# Show stack count
	if stack_count > 1:
		stack_label.text = "x%d" % stack_count
		stack_label.visible = true
	else:
		stack_label.visible = false

	# Update background
	empty_indicator.visible = false
	self_modulate = FILLED_COLOR

func set_empty():
	"""Set slot to empty state"""
	current_item = null
	stack_count = 0

	item_icon.visible = false
	stack_label.visible = false
	empty_indicator.visible = true
	self_modulate = EMPTY_COLOR

func _set_placeholder_visual():
	"""Show a colored placeholder when no icon exists"""
	item_icon.visible = true

	# Create a simple colored rect as placeholder
	var placeholder_color = Color.WHITE

	if current_item:
		# Color code by item type/element
		if current_item.is_dragon_part():
			match current_item.element:
				"FIRE": placeholder_color = Color(1, 0.3, 0.2)
				"ICE": placeholder_color = Color(0.4, 0.7, 1)
				"LIGHTNING": placeholder_color = Color(1, 1, 0.3)
				"NATURE": placeholder_color = Color(0.3, 1, 0.3)
				"SHADOW": placeholder_color = Color(0.6, 0.4, 1)
		elif current_item.is_consumable():
			match current_item.category:
				"xp_boost": placeholder_color = Color(1, 0.84, 0)
				"healing": placeholder_color = Color(1, 0.4, 0.4)
				"food": placeholder_color = Color(0.8, 0.6, 0.4)
				"happiness": placeholder_color = Color(0.9, 0.5, 0.9)

	item_icon.modulate = placeholder_color

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(slot_index)

func _on_mouse_entered():
	if current_item:
		slot_hovered.emit(slot_index, current_item)
		# Highlight effect
		self_modulate = self_modulate.lightened(0.2)

func _on_mouse_exited():
	# Reset highlight
	if current_item:
		self_modulate = FILLED_COLOR
	else:
		self_modulate = EMPTY_COLOR

func get_item() -> Item:
	"""Get the item in this slot"""
	return current_item

func get_stack_count() -> int:
	"""Get the stack count"""
	return stack_count
