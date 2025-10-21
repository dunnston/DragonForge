# Test script for inventory system
extends Node

func _ready():
	# Wait for singletons to load
	await get_tree().process_frame

	print("\n" + "=".repeat(50))
	print("INVENTORY SYSTEM TEST")
	print("=".repeat(50))

	# Test 1: Check if systems loaded
	print("\n[1] Checking Singletons...")
	if ItemDatabase and ItemDatabase.instance:
		print("  ✓ ItemDatabase loaded")
		ItemDatabase.instance.print_database_info()
	else:
		print("  ✗ ItemDatabase NOT loaded!")

	if InventoryManager and InventoryManager.instance:
		print("  ✓ InventoryManager loaded")
	else:
		print("  ✗ InventoryManager NOT loaded!")

	# Test 2: Add starting items
	print("\n[2] Adding Starting Items...")
	InventoryManager.instance.add_starting_items()

	# Test 3: Print inventory
	print("\n[3] Current Inventory:")
	InventoryManager.instance.print_inventory()

	# Test 4: Add specific items
	print("\n[4] Adding 10 fire heads...")
	InventoryManager.instance.add_item_by_id("fire_head", 10)

	print("Fire head count: %d" % InventoryManager.instance.get_item_count("fire_head"))

	# Test 5: Check crafting
	print("\n[5] Crafting Tests:")
	var can_craft_fire = InventoryManager.instance.can_craft_dragon("fire_head", "fire_body", "fire_tail")
	print("  Can craft FIRE dragon: %s" % ("YES" if can_craft_fire else "NO"))

	# Test 6: Get dragon parts by type
	print("\n[6] Dragon Parts by Type:")
	var heads = InventoryManager.instance.get_dragon_parts_by_type("HEAD")
	print("  HEADS in inventory: %d types" % heads.size())
	for part in heads:
		print("    - %s x%d" % [part["item"].name, part["quantity"]])

	# Test 7: Test stacking
	print("\n[7] Testing Stacking...")
	var initial_count = InventoryManager.instance.get_item_count("treat")
	print("  Treats before: %d" % initial_count)

	InventoryManager.instance.add_item_by_id("treat", 50)
	var new_count = InventoryManager.instance.get_item_count("treat")
	print("  Treats after adding 50: %d" % new_count)

	print("\n" + "=".repeat(50))
	print("TEST COMPLETE - Check Output above")
	print("=".repeat(50) + "\n")
