# Defense Tower Manager - Manages all defense towers
# Towers provide dragon defense slots and take damage during attacks
extends Node

# === SINGLETON ===
static var instance: Node  # Will be DefenseTowerManager when autoloaded

# === CONSTANTS ===
const STARTING_TOWERS: int = 3
const MAX_TOWERS: int = 15
const BASE_BUILD_COST: int = 100  # Cost of first tower beyond starting
const COST_MULTIPLIER: float = 1.5  # Each tower costs 1.5x the previous
const BASE_REPAIR_COST: int = 1  # Cost per health point
const REBUILD_COST: int = 75  # Cost to rebuild a destroyed tower
const SMALL_DAMAGE: int = 5  # Damage per tower on successful defense
const LARGE_DAMAGE: int = 20  # Damage per tower on failed defense
const MASSIVE_DAMAGE: int = 40  # Damage per tower when undefended

# === STATE ===
var towers: Array[DefenseTower] = []
var total_towers_built: int = 0  # Track total built for cost calculation

# === SIGNALS ===
signal tower_built(tower: DefenseTower)
signal tower_damaged(tower: DefenseTower, damage: int)
signal tower_destroyed(tower: DefenseTower)
signal tower_repaired(tower: DefenseTower, amount: int)
signal tower_capacity_changed(new_capacity: int)
signal insufficient_gold_for_tower(cost: int)
signal insufficient_gold_for_repair(cost: int)
signal max_towers_reached()

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	# Create starting towers
	_create_starting_towers()
	print("[DefenseTowerManager] Initialized with %d towers (Max: %d)" % [towers.size(), MAX_TOWERS])

# === INITIALIZATION ===

func _create_starting_towers():
	"""Create the initial 3 towers"""
	for i in STARTING_TOWERS:
		var tower = DefenseTower.new()
		tower.tower_damaged.connect(_on_tower_damaged)
		tower.tower_destroyed.connect(_on_tower_destroyed)
		tower.tower_repaired.connect(_on_tower_repaired)
		towers.append(tower)
		total_towers_built += 1
		print("[DefenseTowerManager] Starting tower %d created" % (i + 1))

# === TOWER BUILDING ===

func can_build_tower() -> bool:
	"""Check if we can build more towers"""
	return towers.size() < MAX_TOWERS

func get_next_tower_cost() -> int:
	"""Calculate the cost of the next tower using exponential scaling"""
	# Cost formula: BASE_COST * (MULTIPLIER ^ towers_beyond_starting)
	var towers_beyond_starting = total_towers_built - STARTING_TOWERS
	if towers_beyond_starting < 0:
		towers_beyond_starting = 0

	var cost = BASE_BUILD_COST * pow(COST_MULTIPLIER, towers_beyond_starting)
	return int(cost)

func build_tower() -> DefenseTower:
	"""
	Build a new tower if possible.
	Returns the new tower, or null if failed.
	"""
	# Check tower limit
	if not can_build_tower():
		print("[DefenseTowerManager] Cannot build tower: Max towers reached (%d)" % MAX_TOWERS)
		max_towers_reached.emit()
		return null

	# Check gold cost
	var cost = get_next_tower_cost()
	if not TreasureVault.instance:
		print("[DefenseTowerManager] ERROR: TreasureVault not found!")
		return null

	if not TreasureVault.instance.spend_gold(cost):
		print("[DefenseTowerManager] Cannot build tower: Insufficient gold (need %d)" % cost)
		insufficient_gold_for_tower.emit(cost)
		return null

	# Build tower
	var tower = DefenseTower.new()
	tower.tower_damaged.connect(_on_tower_damaged)
	tower.tower_destroyed.connect(_on_tower_destroyed)
	tower.tower_repaired.connect(_on_tower_repaired)
	towers.append(tower)
	total_towers_built += 1

	tower_built.emit(tower)
	tower_capacity_changed.emit(get_defense_capacity())
	print("[DefenseTowerManager] Tower built for %d gold! (Total: %d/%d)" % [cost, towers.size(), MAX_TOWERS])

	return tower

# === TOWER REPAIR ===

func get_tower_repair_cost(tower: DefenseTower) -> int:
	"""Calculate the cost to fully repair a tower"""
	var damage = tower.max_health - tower.current_health
	return damage * BASE_REPAIR_COST

func get_partial_repair_cost(tower: DefenseTower, repair_amount: int) -> int:
	"""Calculate the cost to repair a specific amount"""
	return repair_amount * BASE_REPAIR_COST

func repair_tower(tower: DefenseTower, repair_amount: int = -1) -> bool:
	"""
	Repair a tower. If repair_amount is -1, repair to full.
	Returns true if successful.
	"""
	if tower not in towers:
		print("[DefenseTowerManager] Cannot repair tower: Tower not found!")
		return false

	if not tower.needs_repair():
		print("[DefenseTowerManager] Tower doesn't need repair (HP: %d/%d)" % [tower.current_health, tower.max_health])
		return false

	# Calculate actual repair amount
	if repair_amount == -1:
		repair_amount = tower.max_health - tower.current_health

	repair_amount = min(repair_amount, tower.max_health - tower.current_health)

	# Calculate cost
	var cost = get_partial_repair_cost(tower, repair_amount)

	# Check gold
	if not TreasureVault.instance:
		print("[DefenseTowerManager] ERROR: TreasureVault not found!")
		return false

	if not TreasureVault.instance.spend_gold(cost):
		print("[DefenseTowerManager] Cannot repair tower: Insufficient gold (need %d)" % cost)
		insufficient_gold_for_repair.emit(cost)
		return false

	# Repair tower
	tower.repair(repair_amount)
	print("[DefenseTowerManager] Tower repaired for %d gold (+%d HP)" % [cost, repair_amount])

	return true

func repair_all_towers() -> int:
	"""
	Repair all damaged towers. Returns number of towers repaired.
	"""
	var repaired_count = 0

	for tower in towers:
		if tower.needs_repair():
			if repair_tower(tower):
				repaired_count += 1
			else:
				# Stop if we run out of gold
				break

	return repaired_count

# === TOWER REBUILD ===

func can_rebuild_tower(tower_index: int) -> bool:
	"""Check if a tower can be rebuilt"""
	if tower_index < 0 or tower_index >= towers.size():
		return false
	return towers[tower_index].is_destroyed()

func rebuild_tower(tower_index: int) -> bool:
	"""
	Rebuild a destroyed tower for a flat cost.
	Returns true if successful.
	"""
	# Validate tower index
	if tower_index < 0 or tower_index >= towers.size():
		print("[DefenseTowerManager] Invalid tower index: %d" % tower_index)
		return false
	
	var tower = towers[tower_index]
	
	# Check if tower is destroyed
	if not tower.is_destroyed():
		print("[DefenseTowerManager] Tower %d is not destroyed (HP: %d/%d)" % [tower_index, tower.current_health, tower.max_health])
		return false
	
	# Check gold
	if not TreasureVault.instance:
		print("[DefenseTowerManager] ERROR: TreasureVault not found!")
		return false
	
	if not TreasureVault.instance.spend_gold(REBUILD_COST):
		print("[DefenseTowerManager] Cannot rebuild tower: Insufficient gold (need %d)" % REBUILD_COST)
		insufficient_gold_for_repair.emit(REBUILD_COST)
		return false
	
	# Rebuild tower to full health
	tower.current_health = tower.max_health
	tower_repaired.emit(tower, tower.max_health)
	tower_capacity_changed.emit(get_defense_capacity())
	
	print("[DefenseTowerManager] Tower %d rebuilt for %d gold! (HP: %d/%d)" % [tower_index, REBUILD_COST, tower.current_health, tower.max_health])
	
	return true

# === TOWER DAMAGE ===

func apply_wave_damage(wave_victory: bool):
	"""
	Apply damage to all towers after a wave.
	Small damage on victory, large damage on defeat.
	"""
	var damage_per_tower = SMALL_DAMAGE if wave_victory else LARGE_DAMAGE

	for tower in towers:
		if not tower.is_destroyed():
			tower.take_damage(damage_per_tower)

	var status = "SUCCESS" if wave_victory else "FAILURE"
	print("[DefenseTowerManager] Wave %s: All towers took %d damage" % [status, damage_per_tower])

func _on_tower_damaged(tower: DefenseTower, damage: int):
	"""Forward tower damaged signal"""
	tower_damaged.emit(tower, damage)

func _on_tower_destroyed(tower: DefenseTower):
	"""Handle tower destruction"""
	tower_destroyed.emit(tower)
	tower_capacity_changed.emit(get_defense_capacity())
	print("[DefenseTowerManager] [CRITICAL] Tower destroyed! Remaining capacity: %d" % get_defense_capacity())

func _on_tower_repaired(tower: DefenseTower, amount: int):
	"""Forward tower repaired signal"""
	tower_repaired.emit(tower, amount)

# === CAPACITY MANAGEMENT ===

func get_defense_capacity() -> int:
	"""
	Returns the number of dragons that can be assigned to defense.
	Only counts non-destroyed towers.
	"""
	var active_towers = 0
	for tower in towers:
		if not tower.is_destroyed():
			active_towers += 1
	return active_towers

func get_total_towers() -> int:
	"""Returns total number of towers (including destroyed)"""
	return towers.size()

func get_active_towers() -> int:
	"""Returns number of non-destroyed towers"""
	return get_defense_capacity()

func get_destroyed_towers() -> int:
	"""Returns number of destroyed towers"""
	var destroyed = 0
	for tower in towers:
		if tower.is_destroyed():
			destroyed += 1
	return destroyed

func get_damaged_towers() -> int:
	"""Returns number of towers that need repair"""
	var damaged = 0
	for tower in towers:
		if tower.needs_repair() and not tower.is_destroyed():
			damaged += 1
	return damaged

func get_towers() -> Array[DefenseTower]:
	"""Returns all towers"""
	return towers.duplicate()

# === SERIALIZATION ===

func to_dict() -> Dictionary:
	var towers_data: Array[Dictionary] = []
	for tower in towers:
		towers_data.append(tower.to_dict())

	return {
		"towers": towers_data,
		"total_towers_built": total_towers_built
	}

func from_dict(data: Dictionary):
	"""Load tower state from save data"""
	# Clear existing towers
	towers.clear()

	# Restore towers
	var towers_data = data.get("towers", [])
	for tower_data in towers_data:
		var tower = DefenseTower.from_dict(tower_data)
		tower.tower_damaged.connect(_on_tower_damaged)
		tower.tower_destroyed.connect(_on_tower_destroyed)
		tower.tower_repaired.connect(_on_tower_repaired)
		towers.append(tower)

	# BUGFIX: Ensure we always have at least the starting number of towers
	# This handles old save files from before the tower system was implemented
	if towers.size() < STARTING_TOWERS:
		print("[DefenseTowerManager] WARNING: Save file has %d towers, creating %d starting towers" % [towers.size(), STARTING_TOWERS - towers.size()])
		var towers_to_create = STARTING_TOWERS - towers.size()
		for i in towers_to_create:
			var tower = DefenseTower.new()
			tower.tower_damaged.connect(_on_tower_damaged)
			tower.tower_destroyed.connect(_on_tower_destroyed)
			tower.tower_repaired.connect(_on_tower_repaired)
			towers.append(tower)

	total_towers_built = data.get("total_towers_built", towers.size())
	# Ensure total_towers_built is at least STARTING_TOWERS
	total_towers_built = max(total_towers_built, STARTING_TOWERS)

	print("[DefenseTowerManager] Loaded %d towers (Capacity: %d)" % [towers.size(), get_defense_capacity()])
	tower_capacity_changed.emit(get_defense_capacity())

# === DEBUG ===

func print_tower_status():
	"""Debug function to print tower information"""
	print("\n=== DEFENSE TOWER STATUS ===")
	print("Total Towers: %d / %d" % [towers.size(), MAX_TOWERS])
	print("Active Towers: %d" % get_active_towers())
	print("Destroyed Towers: %d" % get_destroyed_towers())
	print("Damaged Towers: %d" % get_damaged_towers())
	print("Defense Capacity: %d dragons" % get_defense_capacity())
	print("Next Tower Cost: %d gold" % get_next_tower_cost())
	print("\nIndividual Towers:")
	for i in towers.size():
		var tower = towers[i]
		var status = "DESTROYED" if tower.is_destroyed() else "Active"
		print("  Tower %d: %s (HP: %d/%d - %.0f%%)" % [i + 1, status, tower.current_health, tower.max_health, tower.get_health_percentage() * 100])
	print("============================\n")

func force_damage_all_towers(amount: int):
	"""Debug function to damage all towers"""
	for tower in towers:
		tower.take_damage(amount)
	print("[DefenseTowerManager] [DEBUG] All towers damaged by %d" % amount)
