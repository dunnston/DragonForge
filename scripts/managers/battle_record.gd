class_name BattleRecord extends Resource

## Stores detailed information about a single battle/wave

@export var battle_id: String
@export var timestamp: int  # Unix timestamp
@export var wave_number: int
@export var victory: bool
@export var round_count: int
@export var duration_seconds: float

# Dragon battle stats
@export var defenders: Array[Dictionary] = []  # [{dragon_id, name, level, xp_gained, damage_taken, damage_dealt, survived}]

# Enemy composition
@export var enemies: Array[Dictionary] = []  # [{type, level, attack, health, speed, reward_gold, elemental_type}]

# Rewards and losses
@export var rewards_gold: int = 0
@export var rewards_meat: int = 0
@export var vault_gold_stolen: int = 0
@export var vault_parts_stolen: Array = []

# Tower information
@export var tower_damage_dealt: int = 0
@export var towers_destroyed: int = 0
@export var active_tower_count: int = 0

# Combat narrative
@export var combat_log: String = ""

func _init():
	battle_id = str(Time.get_ticks_msec())
	timestamp = Time.get_unix_time_from_system()

func get_date_time_string() -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%02d/%02d/%04d %02d:%02d" % [
		datetime.month,
		datetime.day,
		datetime.year,
		datetime.hour,
		datetime.minute
	]

func get_total_enemies() -> int:
	return enemies.size()

func get_enemies_defeated() -> int:
	var defeated = 0
	for enemy in enemies:
		if enemy.get("killed", false):
			defeated += 1
	return defeated

func get_surviving_dragons() -> int:
	var alive = 0
	for defender in defenders:
		if defender.get("survived", true):
			alive += 1
	return alive

func get_total_damage_dealt() -> int:
	var total = 0
	for defender in defenders:
		total += defender.get("damage_dealt", 0)
	return total

func get_total_damage_taken() -> int:
	var total = 0
	for defender in defenders:
		total += defender.get("damage_taken", 0)
	return total

func to_dict() -> Dictionary:
	return {
		"battle_id": battle_id,
		"timestamp": timestamp,
		"wave_number": wave_number,
		"victory": victory,
		"round_count": round_count,
		"duration_seconds": duration_seconds,
		"defenders": defenders,
		"enemies": enemies,
		"rewards_gold": rewards_gold,
		"rewards_meat": rewards_meat,
		"vault_gold_stolen": vault_gold_stolen,
		"vault_parts_stolen": vault_parts_stolen,
		"tower_damage_dealt": tower_damage_dealt,
		"towers_destroyed": towers_destroyed,
		"active_tower_count": active_tower_count,
		"combat_log": combat_log
	}

static func from_dict(data: Dictionary) -> BattleRecord:
	var record = BattleRecord.new()
	record.battle_id = data.get("battle_id", "")
	record.timestamp = data.get("timestamp", 0)
	record.wave_number = data.get("wave_number", 0)
	record.victory = data.get("victory", false)
	record.round_count = data.get("round_count", 0)
	record.duration_seconds = data.get("duration_seconds", 0.0)
	record.defenders = data.get("defenders", [])
	record.enemies = data.get("enemies", [])
	record.rewards_gold = data.get("rewards_gold", 0)
	record.rewards_meat = data.get("rewards_meat", 0)
	record.vault_gold_stolen = data.get("vault_gold_stolen", 0)
	record.vault_parts_stolen = data.get("vault_parts_stolen", [])
	record.tower_damage_dealt = data.get("tower_damage_dealt", 0)
	record.towers_destroyed = data.get("towers_destroyed", 0)
	record.active_tower_count = data.get("active_tower_count", 0)
	record.combat_log = data.get("combat_log", "")
	return record
