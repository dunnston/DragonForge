extends Node

## Singleton manager for tracking and storing battle history

const MAX_BATTLE_LOGS = 100  # Keep last 100 battles

var battle_history: Array[BattleRecord] = []
var current_battle_record: BattleRecord = null

signal battle_logged(record: BattleRecord)
signal battle_started(wave_number: int)

func _ready():
	# Connect to defense manager signals
	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.wave_started.connect(_on_wave_started)
		DefenseManager.instance.wave_completed.connect(_on_wave_completed)

func start_battle_tracking(wave_number: int, enemies: Array, defenders: Array):
	"""Begin tracking a new battle"""
	current_battle_record = BattleRecord.new()
	current_battle_record.wave_number = wave_number
	current_battle_record.active_tower_count = DefenseTowerManager.instance.get_active_towers() if DefenseTowerManager and DefenseTowerManager.instance else 0

	# Store enemy data
	for enemy in enemies:
		current_battle_record.enemies.append({
			"type": _get_enemy_type_string(enemy.get("enemy_type", 0)),
			"level": enemy.get("level", 1),
			"attack": enemy.get("attack", 10),
			"health": enemy.get("max_health", 50),
			"speed": enemy.get("speed", 5),
			"reward_gold": enemy.get("reward_gold", 10),
			"elemental_type": enemy.get("elemental_type", -1),
			"killed": false
		})

	# Store defender data (initial state)
	for dragon in defenders:
		if dragon:
			current_battle_record.defenders.append({
				"dragon_id": dragon.dragon_id,
				"dragon_name": dragon.dragon_name,
				"level": dragon.level,
				"element_head": DragonPart.Element.keys()[dragon.head_part.element],
				"element_body": DragonPart.Element.keys()[dragon.body_part.element],
				"element_tail": DragonPart.Element.keys()[dragon.tail_part.element],
				"initial_health": dragon.current_health,
				"xp_gained": 0,
				"damage_taken": 0,
				"damage_dealt": 0,
				"survived": true
			})

	battle_started.emit(wave_number)

func update_combat_log(log_text: String):
	"""Update the combat log for the current battle"""
	if current_battle_record:
		current_battle_record.combat_log = log_text

func update_round_count(rounds: int):
	"""Update the number of rounds in the current battle"""
	if current_battle_record:
		current_battle_record.round_count = rounds

func update_battle_duration(duration: float):
	"""Update the duration of the battle"""
	if current_battle_record:
		current_battle_record.duration_seconds = duration

func mark_enemy_killed(enemy_index: int):
	"""Mark an enemy as killed in the current battle"""
	if current_battle_record and enemy_index < current_battle_record.enemies.size():
		current_battle_record.enemies[enemy_index]["killed"] = true

func update_defender_stats(dragon_id: String, xp_gained: int = 0, damage_taken: int = 0, damage_dealt: int = 0, survived: bool = true):
	"""Update stats for a defending dragon"""
	if not current_battle_record:
		return

	for defender in current_battle_record.defenders:
		if defender["dragon_id"] == dragon_id:
			defender["xp_gained"] += xp_gained
			defender["damage_taken"] += damage_taken
			defender["damage_dealt"] += damage_dealt
			defender["survived"] = survived
			break

func complete_battle(victory: bool, rewards: Dictionary):
	"""Finalize the current battle record"""
	if not current_battle_record:
		return

	current_battle_record.victory = victory
	current_battle_record.rewards_gold = rewards.get("gold", 0)
	current_battle_record.rewards_meat = rewards.get("meat", 0)
	current_battle_record.vault_gold_stolen = rewards.get("vault_gold_stolen", 0)
	current_battle_record.vault_parts_stolen = rewards.get("vault_parts_stolen", [])
	current_battle_record.tower_damage_dealt = rewards.get("tower_damage", 0)
	current_battle_record.towers_destroyed = rewards.get("towers_destroyed", 0)

	# Add to history (newest first)
	battle_history.push_front(current_battle_record)

	# Limit history size
	if battle_history.size() > MAX_BATTLE_LOGS:
		battle_history.resize(MAX_BATTLE_LOGS)

	battle_logged.emit(current_battle_record)
	current_battle_record = null

func get_battle_history() -> Array[BattleRecord]:
	"""Get all battle records (newest first)"""
	return battle_history

func get_recent_battles(count: int) -> Array[BattleRecord]:
	"""Get the most recent N battles"""
	var recent: Array[BattleRecord] = []
	for i in min(count, battle_history.size()):
		recent.append(battle_history[i])
	return recent

func get_total_battles() -> int:
	return battle_history.size()

func get_victory_count() -> int:
	var count = 0
	for record in battle_history:
		if record.victory:
			count += 1
	return count

func get_defeat_count() -> int:
	var count = 0
	for record in battle_history:
		if not record.victory:
			count += 1
	return count

func get_win_rate() -> float:
	if battle_history.is_empty():
		return 0.0
	return float(get_victory_count()) / float(battle_history.size())

func clear_history():
	"""Clear all battle logs"""
	battle_history.clear()
	current_battle_record = null

func _on_wave_started(wave_number: int, enemies: Array):
	"""Automatically start tracking when wave begins"""
	var defenders = []
	if DefenseManager and DefenseManager.instance:
		# Get all assigned dragons
		for tower_index in DefenseManager.instance.tower_assignments:
			var dragon = DefenseManager.instance.tower_assignments[tower_index]
			if dragon:
				defenders.append(dragon)

	start_battle_tracking(wave_number, enemies, defenders)

func _on_wave_completed(victory: bool, rewards: Dictionary):
	"""Automatically finalize battle when wave completes"""
	complete_battle(victory, rewards)

func _get_enemy_type_string(enemy_type: int) -> String:
	match enemy_type:
		0: return "Knight"
		1: return "Wizard"
		2: return "Boss"
		_: return "Unknown"

# Serialization for save/load
func to_dict() -> Dictionary:
	var battle_data = []
	for record in battle_history:
		battle_data.append(record.to_dict())

	return {
		"battle_history": battle_data
	}

func from_dict(data: Dictionary):
	battle_history.clear()

	var battle_data = data.get("battle_history", [])
	for record_data in battle_data:
		battle_history.append(BattleRecord.from_dict(record_data))
