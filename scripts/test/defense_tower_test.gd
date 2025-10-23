extends Node

# Defense Tower System Test Script
# Tests tower building, damage, repair, and integration with defense

func _ready():
	print("\n=== DEFENSE TOWER SYSTEM TEST ===\n")

	# Wait for managers to initialize
	await get_tree().create_timer(0.5).timeout

	# Run tests
	test_initial_state()
	test_tower_building()
	test_tower_capacity()
	test_tower_damage()
	test_tower_repair()
	test_save_load()

	print("\n=== ALL TESTS COMPLETE ===\n")

func test_initial_state():
	print("TEST 1: Initial State")
	print("---------------------")

	if not DefenseTowerManager or not DefenseTowerManager.instance:
		print("❌ FAIL: DefenseTowerManager not found!")
		return

	var tower_manager = DefenseTowerManager.instance

	# Should start with 3 towers
	assert(tower_manager.get_total_towers() == 3, "Should start with 3 towers")
	assert(tower_manager.get_defense_capacity() == 3, "Defense capacity should be 3")
	assert(tower_manager.can_build_tower(), "Should be able to build more towers")

	print("✓ Starting towers: %d" % tower_manager.get_total_towers())
	print("✓ Defense capacity: %d" % tower_manager.get_defense_capacity())
	print("✓ Next tower cost: %d gold" % tower_manager.get_next_tower_cost())
	print("")

func test_tower_building():
	print("TEST 2: Tower Building")
	print("----------------------")

	var tower_manager = DefenseTowerManager.instance
	var vault = TreasureVault.instance

	# Add gold for building
	vault.add_gold(1000)

	var initial_towers = tower_manager.get_total_towers()
	var initial_gold = vault.get_total_gold()
	var tower_cost = tower_manager.get_next_tower_cost()

	# Build a tower
	var new_tower = tower_manager.build_tower()

	assert(new_tower != null, "Tower should be built")
	assert(tower_manager.get_total_towers() == initial_towers + 1, "Tower count should increase")
	assert(vault.get_total_gold() == initial_gold - tower_cost, "Gold should be deducted")

	print("✓ Tower built successfully")
	print("✓ Total towers: %d" % tower_manager.get_total_towers())
	print("✓ Gold spent: %d" % tower_cost)
	print("✓ Next tower cost: %d gold" % tower_manager.get_next_tower_cost())
	print("")

func test_tower_capacity():
	print("TEST 3: Tower Capacity & Defense Limit")
	print("---------------------------------------")

	var tower_manager = DefenseTowerManager.instance
	var defense_manager = DefenseManager.instance

	var capacity = tower_manager.get_defense_capacity()
	var max_defenders = defense_manager.get_max_defenders()

	assert(capacity == max_defenders, "Defense capacity should match max defenders")

	print("✓ Tower capacity: %d" % capacity)
	print("✓ Max defenders: %d" % max_defenders)
	print("✓ Capacity integration working correctly")
	print("")

func test_tower_damage():
	print("TEST 4: Tower Damage")
	print("--------------------")

	var tower_manager = DefenseTowerManager.instance
	var towers = tower_manager.get_towers()

	if towers.size() == 0:
		print("❌ FAIL: No towers to test!")
		return

	var first_tower = towers[0]
	var initial_health = first_tower.current_health

	# Apply wave damage (victory = small damage)
	tower_manager.apply_wave_damage(true)

	assert(first_tower.current_health < initial_health, "Tower should take damage")
	print("✓ Tower took damage on wave success")
	print("✓ Health: %d -> %d" % [initial_health, first_tower.current_health])

	# Apply wave damage (defeat = large damage)
	initial_health = first_tower.current_health
	tower_manager.apply_wave_damage(false)

	var damage_taken = initial_health - first_tower.current_health
	print("✓ Tower took %d damage on wave failure" % damage_taken)
	print("✓ Health: %d -> %d" % [initial_health, first_tower.current_health])
	print("")

func test_tower_repair():
	print("TEST 5: Tower Repair")
	print("--------------------")

	var tower_manager = DefenseTowerManager.instance
	var vault = TreasureVault.instance
	var towers = tower_manager.get_towers()

	if towers.size() == 0:
		print("❌ FAIL: No towers to test!")
		return

	# Find a damaged tower
	var damaged_tower = null
	for tower in towers:
		if tower.needs_repair():
			damaged_tower = tower
			break

	if not damaged_tower:
		print("⚠ SKIP: No damaged towers to repair")
		print("")
		return

	# Add gold for repair
	vault.add_gold(500)

	var initial_health = damaged_tower.current_health
	var repair_cost = tower_manager.get_tower_repair_cost(damaged_tower)
	var initial_gold = vault.get_total_gold()

	# Repair tower
	var success = tower_manager.repair_tower(damaged_tower)

	assert(success, "Repair should succeed")
	assert(damaged_tower.current_health == damaged_tower.max_health, "Tower should be fully repaired")
	assert(vault.get_total_gold() == initial_gold - repair_cost, "Gold should be deducted")

	print("✓ Tower repaired successfully")
	print("✓ Health: %d -> %d" % [initial_health, damaged_tower.current_health])
	print("✓ Repair cost: %d gold" % repair_cost)
	print("")

func test_save_load():
	print("TEST 6: Save/Load Integration")
	print("------------------------------")

	var tower_manager = DefenseTowerManager.instance

	# Save current state
	var save_data = tower_manager.to_dict()
	var original_count = tower_manager.get_total_towers()
	var original_capacity = tower_manager.get_defense_capacity()

	print("✓ Saved state: %d towers, %d capacity" % [original_count, original_capacity])

	# Modify state
	tower_manager.get_towers()[0].take_damage(50)

	# Restore from save
	tower_manager.from_dict(save_data)

	assert(tower_manager.get_total_towers() == original_count, "Tower count should match after load")
	assert(tower_manager.get_defense_capacity() == original_capacity, "Capacity should match after load")

	print("✓ Loaded state: %d towers, %d capacity" % [tower_manager.get_total_towers(), tower_manager.get_defense_capacity()])
	print("✓ Save/Load working correctly")
	print("")

func assert(condition: bool, message: String):
	if not condition:
		push_error("ASSERTION FAILED: " + message)
		print("❌ FAIL: " + message)
