# Defense Tower - Individual tower resource
# Tracks health and provides defense slots for dragons
class_name DefenseTower extends Resource

# === CONSTANTS ===
const MAX_HEALTH: int = 100

# === PROPERTIES ===
@export var tower_id: String
@export var current_health: int = MAX_HEALTH
@export var max_health: int = MAX_HEALTH

# === SIGNALS ===
signal tower_damaged(tower: DefenseTower, damage: int)
signal tower_destroyed(tower: DefenseTower)
signal tower_repaired(tower: DefenseTower, amount: int)

func _init():
	tower_id = _generate_id()
	current_health = max_health

func _generate_id() -> String:
	return "tower_%s" % str(Time.get_ticks_msec())

# === HEALTH MANAGEMENT ===

func take_damage(amount: int):
	"""Apply damage to the tower"""
	if amount <= 0:
		return

	current_health -= amount
	current_health = max(0, current_health)
	tower_damaged.emit(self, amount)

	print("[DefenseTower] Tower %s took %d damage (HP: %d/%d)" % [tower_id, amount, current_health, max_health])

	if current_health <= 0:
		tower_destroyed.emit(self)
		print("[DefenseTower] [DESTROYED] Tower %s destroyed!" % tower_id)

func repair(amount: int):
	"""Repair the tower"""
	if amount <= 0:
		return

	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	var actual_repair = current_health - old_health

	if actual_repair > 0:
		tower_repaired.emit(self, actual_repair)
		print("[DefenseTower] Tower %s repaired by %d (HP: %d/%d)" % [tower_id, actual_repair, current_health, max_health])

func is_destroyed() -> bool:
	return current_health <= 0

func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

func needs_repair() -> bool:
	return current_health < max_health

# === SERIALIZATION ===

func to_dict() -> Dictionary:
	return {
		"tower_id": tower_id,
		"current_health": current_health,
		"max_health": max_health
	}

static func from_dict(data: Dictionary) -> DefenseTower:
	var tower = DefenseTower.new()
	tower.tower_id = data.get("tower_id", tower.tower_id)
	tower.current_health = data.get("current_health", MAX_HEALTH)
	tower.max_health = data.get("max_health", MAX_HEALTH)
	return tower