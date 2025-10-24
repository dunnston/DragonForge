extends Control

## Test scene for dragon death and part recovery system
## Shows how to use the system and test all features

@onready var status_label = $VBox/StatusLabel
@onready var buttons_vbox = $VBox/ButtonsVBox

func _ready():
	_update_status()

	# Update status every second
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_status)
	add_child(timer)
	timer.start()

func _update_status():
	"""Update the status display"""
	if not DragonDeathManager or not DragonDeathManager.instance:
		status_label.text = "ERROR: DragonDeathManager not found!"
		return

	var status = DragonDeathManager.instance.get_status()
	var text = ""
	text += "=== DRAGON DEATH SYSTEM TEST ===\n\n"
	text += "Freezer Level: %d\n" % status.freezer_level
	text += "Freezer Capacity: %d slots\n" % status.freezer_capacity
	text += "Freezer Used: %d/%d\n" % [status.freezer_used, status.freezer_capacity]
	text += "Recovered Parts: %d\n" % status.recovered_parts
	text += "Parts About to Decay: %d\n\n" % status.decay_warnings

	# Show part details
	if DragonDeathManager.instance.recovered_parts.size() > 0:
		text += "RECOVERED PARTS:\n"
		for part in DragonDeathManager.instance.recovered_parts:
			var urgency = part.get_decay_urgency()
			var time = part.format_time_remaining()
			text += "  - %s (%s) - %s [%s]\n" % [part.get_display_name(), part.get_rarity_name(), time, urgency]
	else:
		text += "No recovered parts\n"

	status_label.text = text

# ═══════════════════════════════════════════════════════════
# TEST BUTTONS
# ═══════════════════════════════════════════════════════════

func _on_test_death_pressed():
	"""Simulate a dragon death"""
	# Create a test dragon
	var head = PartLibrary.instance.get_part_by_element_and_type(DragonPart.Element.FIRE, DragonPart.PartType.HEAD)
	var body = PartLibrary.instance.get_part_by_element_and_type(DragonPart.Element.FIRE, DragonPart.PartType.BODY)
	var tail = PartLibrary.instance.get_part_by_element_and_type(DragonPart.Element.FIRE, DragonPart.PartType.TAIL)

	var test_dragon = Dragon.new(head, body, tail)
	test_dragon.dragon_name = "Test Dragon"
	test_dragon.level = 5

	# Trigger death
	DragonDeathManager.instance.handle_dragon_death(test_dragon, "combat_defending")
	print("[TEST] Dragon death triggered!")

func _on_add_part_pressed():
	"""Add a test recovered part"""
	DragonDeathManager.instance.debug_add_recovered_part(
		DragonPart.Element.values().pick_random(),
		DragonPart.PartType.values().pick_random()
	)
	print("[TEST] Added random recovered part")

func _on_unlock_freezer_pressed():
	"""Force unlock freezer"""
	DragonDeathManager.instance.debug_unlock_freezer()
	print("[TEST] Freezer unlocked!")

func _on_open_inventory_pressed():
	"""Open the parts inventory UI"""
	var inventory_scene = load("res://scenes/ui/parts_inventory_ui.tscn")
	if inventory_scene:
		var inventory = inventory_scene.instantiate()
		get_tree().root.add_child(inventory)
		print("[TEST] Opened parts inventory")
	else:
		print("[TEST] ERROR: Could not load inventory scene")

func _on_freeze_random_pressed():
	"""Freeze a random part"""
	if DragonDeathManager.instance.recovered_parts.is_empty():
		print("[TEST] No parts to freeze!")
		return

	if DragonDeathManager.instance.freezer_level == 0:
		print("[TEST] Freezer not unlocked!")
		return

	var part = DragonDeathManager.instance.recovered_parts[0]
	var empty_slot = -1

	# Find empty slot
	for i in range(DragonDeathManager.instance.get_freezer_capacity()):
		if DragonDeathManager.instance.is_freezer_slot_empty(i):
			empty_slot = i
			break

	if empty_slot >= 0:
		DragonDeathManager.instance.freeze_part(part, empty_slot)
		print("[TEST] Froze part in slot %d" % empty_slot)
	else:
		print("[TEST] No empty freezer slots!")

func _on_force_decay_pressed():
	"""Force a part to decay immediately"""
	if DragonDeathManager.instance.recovered_parts.is_empty():
		print("[TEST] No parts to decay!")
		return

	var part = DragonDeathManager.instance.recovered_parts[0]
	DragonDeathManager.instance.debug_force_decay(part)
	print("[TEST] Forced part to decay")
