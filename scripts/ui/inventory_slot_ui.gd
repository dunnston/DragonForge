# InventorySlotUI - Visual representation of a single inventory slot
extends PanelContainer

signal slot_clicked(slot_index: int)
signal slot_hovered(slot_index: int, item: Item)

@onready var item_icon: TextureRect = $MarginContainer/ItemIcon
@onready var stack_label: Label = $StackLabel
@onready var empty_indicator: ColorRect = $EmptyIndicator
@onready var decay_timer_label: Label = $DecayTimerLabel

var slot_index: int = -1
var current_item: Item = null
var stack_count: int = 0
var is_decaying_item: bool = false

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

	# Check if this is a recovered part (has decay timer)
	is_decaying_item = current_item.id.ends_with("_recovered")
	if is_decaying_item:
		decay_timer_label.visible = true
		_update_decay_timer()
	else:
		decay_timer_label.visible = false

	# Update background
	empty_indicator.visible = false
	self_modulate = FILLED_COLOR

func set_empty():
	"""Set slot to empty state"""
	current_item = null
	stack_count = 0
	is_decaying_item = false

	item_icon.visible = false
	stack_label.visible = false
	decay_timer_label.visible = false
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

func _process(_delta):
	"""Update decay timer every frame for decaying items"""
	if is_decaying_item and decay_timer_label.visible:
		_update_decay_timer()

func _update_decay_timer():
	"""Update the decay timer display"""
	if not current_item or not DragonDeathManager or not DragonDeathManager.instance:
		return

	# Find the soonest decay time for this part type
	var soonest_decay_time = -1
	for part in DragonDeathManager.instance.recovered_parts:
		# Convert part to item_id to match
		var part_item_id = DragonDeathManager.instance._convert_part_to_item_id(part)
		if part_item_id == current_item.id:
			var time_remaining = part.get_time_until_decay()
			if soonest_decay_time == -1 or time_remaining < soonest_decay_time:
				soonest_decay_time = time_remaining

	# Display time remaining
	if soonest_decay_time > 0:
		decay_timer_label.text = _format_time_remaining(soonest_decay_time)

		# Color code by urgency
		var hours_remaining = soonest_decay_time / 3600.0
		if hours_remaining < 1:
			decay_timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))  # Red - critical
		elif hours_remaining < 3:
			decay_timer_label.add_theme_color_override("font_color", Color(1, 0.6, 0))  # Orange - urgent
		elif hours_remaining < 6:
			decay_timer_label.add_theme_color_override("font_color", Color(1, 1, 0.3))  # Yellow - warning
		else:
			decay_timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))  # Gray - safe
	elif soonest_decay_time == 0:
		decay_timer_label.text = "DECAYED"
		decay_timer_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		decay_timer_label.visible = false

func _format_time_remaining(seconds: int) -> String:
	"""Format seconds as '23h 45m' or '45m' or '30s'"""
	if seconds <= 0:
		return "0s"

	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	var secs = seconds % 60

	if hours > 0:
		return "%dh %dm" % [hours, minutes]
	elif minutes > 0:
		return "%dm" % minutes
	else:
		return "%ds" % secs
