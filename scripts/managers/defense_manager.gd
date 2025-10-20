# Defense Manager - Wave-based Knight Attacks
# Protects the Treasure Vault from raiders
extends Node

# === SINGLETON ===
static var instance: DefenseManager

# === WAVE CONFIG ===
const BASE_WAVE_INTERVAL: float = 300.0  # 5 minutes between waves (adjustable)

# === STATE ===
var wave_number: int = 1
var defending_dragons: Array[Dragon] = []
var time_until_next_wave: float = BASE_WAVE_INTERVAL
var is_in_combat: bool = false

# === SIGNALS ===
signal wave_incoming(time_remaining: float)
signal wave_started(wave_number: int, enemies: Array)
signal wave_completed(victory: bool, rewards: Dictionary)
signal dragon_damaged(dragon: Dragon, damage: int)
signal dragon_defended_successfully(dragon: Dragon, enemies_defeated: int)

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	# Update wave timer every second
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_wave_timer)
	add_child(timer)
	timer.start()

	print("[DefenseManager] Initialized - First wave in %.0f seconds" % BASE_WAVE_INTERVAL)

# === WAVE TIMER ===

func _update_wave_timer():
	if is_in_combat:
		return

	# Apply vault risk multiplier (more treasure = more frequent attacks)
	var frequency_multiplier = 1.0
	if TreasureVault.instance:
		frequency_multiplier = TreasureVault.instance.get_attack_frequency_multiplier()

	time_until_next_wave -= frequency_multiplier

	# Emit warning signals
	if time_until_next_wave <= 30 and int(time_until_next_wave) % 10 == 0:
		wave_incoming.emit(time_until_next_wave)
		print("[DefenseManager] WARNING: Wave incoming in %.0f seconds!" % time_until_next_wave)

	# Start wave
	if time_until_next_wave <= 0:
		_start_wave()

func reset_wave_timer():
	time_until_next_wave = BASE_WAVE_INTERVAL

# === DRAGON ASSIGNMENT ===

func assign_dragon_to_defense(dragon: Dragon) -> bool:
	if dragon in defending_dragons:
		print("[DefenseManager] Dragon already defending!")
		return false

	if defending_dragons.size() >= 3:
		print("[DefenseManager] Maximum 3 defenders!")
		return false

	if dragon.current_health <= 0:
		print("[DefenseManager] Dragon is dead!")
		return false

	defending_dragons.append(dragon)
	dragon.current_state = Dragon.DragonState.DEFENDING
	print("[DefenseManager] %s assigned to defense (Total: %d)" % [dragon.dragon_name, defending_dragons.size()])
	return true

func remove_dragon_from_defense(dragon: Dragon) -> bool:
	if dragon not in defending_dragons:
		return false

	defending_dragons.erase(dragon)
	dragon.current_state = Dragon.DragonState.IDLE
	print("[DefenseManager] %s removed from defense" % dragon.dragon_name)
	return true

func get_defending_dragons() -> Array[Dragon]:
	return defending_dragons.duplicate()

# === WAVE GENERATION & COMBAT ===

func _start_wave():
	is_in_combat = true

	# Generate enemies based on wave number and vault value
	var enemies = _generate_wave(wave_number)

	print("[DefenseManager] COMBAT: WAVE %d - %d enemies attacking!" % [wave_number, enemies.size()])
	wave_started.emit(wave_number, enemies)

	# Check if we have defenders
	if defending_dragons.is_empty():
		print("[DefenseManager] ERROR: NO DEFENDERS! Auto-loss!")
		_apply_auto_loss()
		_complete_wave(false, {})
		return

	# Resolve combat
	var victory = _resolve_combat(defending_dragons, enemies)

	if victory:
		var rewards = _calculate_rewards(enemies)
		_apply_rewards(rewards)
		wave_number += 1
		print("[DefenseManager] ✅ VICTORY! Wave %d complete. Rewards: %d gold" % [wave_number - 1, rewards["gold"]])
		_complete_wave(true, rewards)
	else:
		_apply_raid_loss()
		print("[DefenseManager] ❌ DEFEAT! Raiders stole from your vault!")
		_complete_wave(false, {})

func _generate_wave(wave_num: int) -> Array:
	var enemies: Array = []

	# Apply vault risk multiplier (more treasure = stronger enemies)
	var difficulty_multiplier = 1.0
	if TreasureVault.instance:
		difficulty_multiplier = TreasureVault.instance.get_attack_difficulty_multiplier()

	# Base enemy count increases with wave number
	var enemy_count = 1 + int(wave_num / 5.0)
	enemy_count = int(enemy_count * difficulty_multiplier)
	enemy_count = max(1, enemy_count)  # At least 1 enemy

	for i in enemy_count:
		var enemy = _create_knight(wave_num, difficulty_multiplier)
		enemies.append(enemy)

	# Boss every 10 waves
	if wave_num % 10 == 0:
		var boss = _create_boss(wave_num, difficulty_multiplier)
		enemies.append(boss)
		print("[DefenseManager] [BOSS] BOSS WAVE!")

	return enemies

func _create_knight(wave_num: int, difficulty_mult: float = 1.0) -> Dictionary:
	return {
		"type": "knight",
		"level": wave_num,
		"attack": int((10 + wave_num * 3) * difficulty_mult),
		"health": int((50 + wave_num * 10) * difficulty_mult),
		"speed": int((5 + wave_num) * difficulty_mult),
		"reward_gold": int((10 + wave_num * 5) * difficulty_mult),
		"reward_parts": 1
	}

func _create_boss(wave_num: int, difficulty_mult: float = 1.0) -> Dictionary:
	return {
		"type": "boss",
		"level": wave_num,
		"attack": int((25 + wave_num * 6) * difficulty_mult),
		"health": int((150 + wave_num * 20) * difficulty_mult),
		"speed": int((10 + wave_num * 2) * difficulty_mult),
		"reward_gold": int((50 + wave_num * 10) * difficulty_mult),
		"reward_parts": 3
	}

func _resolve_combat(dragons: Array[Dragon], enemies: Array) -> bool:
	"""
	Simple stat-based combat resolution.
	Returns true if dragons win, false if enemies win.
	"""

	# Calculate total dragon power
	var dragon_power: float = 0.0
	for dragon in dragons:
		var base_power = dragon.get_attack() + (dragon.get_health() * 0.5) + (dragon.get_speed() * 0.3)

		# Apply hunger/fatigue penalties
		var hunger_penalty = 1.0 - (dragon.hunger_level * 0.2)  # Up to -20%
		var fatigue_penalty = 1.0 - (dragon.fatigue_level * 0.15)  # Up to -15%

		var dragon_total = base_power * hunger_penalty * fatigue_penalty
		dragon_power += dragon_total

		print("[DefenseManager] %s power: %.1f (base %.1f, hunger %.0f%%, fatigue %.0f%%)" %
			[dragon.dragon_name, dragon_total, base_power, (1.0 - hunger_penalty) * 100, (1.0 - fatigue_penalty) * 100])

	# Calculate total enemy power
	var enemy_power: float = 0.0
	for enemy in enemies:
		var e_power = enemy["attack"] + (enemy["health"] * 0.5) + (enemy["speed"] * 0.3)
		enemy_power += e_power

	print("[DefenseManager] Dragon power: %.1f vs Enemy power: %.1f" % [dragon_power, enemy_power])

	# Victory if dragons have at least 10% more power
	if dragon_power >= enemy_power * 1.1:
		# Victory - dragons gain XP and fatigue
		for dragon in dragons:
			if DragonStateManager.instance:
				DragonStateManager.instance.gain_experience(dragon, 50 * wave_number)
			dragon.fatigue_level = min(1.0, dragon.fatigue_level + 0.1)  # Combat is tiring
			dragon_defended_successfully.emit(dragon, enemies.size())

		return true
	else:
		# Defeat - dragons take damage
		var damage_per_dragon = (enemy_power - dragon_power) / dragons.size()
		damage_per_dragon = max(10, damage_per_dragon)  # Minimum 10 damage

		for dragon in dragons:
			dragon.take_damage(int(damage_per_dragon))  # Use Dragon's take_damage method
			dragon.fatigue_level = min(1.0, dragon.fatigue_level + 0.15)  # Losing is exhausting
			dragon_damaged.emit(dragon, int(damage_per_dragon))

			print("[DefenseManager] %s took %.0f damage (HP: %.0f/%.0f)" %
				[dragon.dragon_name, damage_per_dragon, dragon.current_health, dragon.get_health()])

			# Death handled by Dragon.take_damage()
			if dragon.is_dead:
				print("[DefenseManager] DEAD: %s has fallen!" % dragon.dragon_name)

		return false

# === REWARDS & LOSSES ===

func _calculate_rewards(enemies: Array) -> Dictionary:
	var total_gold = 0
	var total_parts = 0

	for enemy in enemies:
		total_gold += enemy.get("reward_gold", 10)
		total_parts += enemy.get("reward_parts", 1)

	return {
		"gold": total_gold,
		"parts": total_parts
	}

func _apply_rewards(rewards: Dictionary):
	if not TreasureVault.instance:
		print("[DefenseManager] ERROR: No TreasureVault instance!")
		return

	# Add gold
	TreasureVault.instance.add_gold(rewards["gold"])

	# Add random parts
	for i in rewards["parts"]:
		var random_element = DragonPart.Element.values().pick_random()
		TreasureVault.instance.add_part(random_element)

func _apply_raid_loss():
	if not TreasureVault.instance:
		return

	# Calculate loss percentage (higher waves = bigger losses, but capped at 30%)
	var loss_percentage = min(0.30, 0.15 + (wave_number * 0.01))

	# Apply loss to vault
	var stolen = TreasureVault.instance.apply_raid_loss(loss_percentage)

	print("[DefenseManager] [STOLEN] Raiders stole %d gold and parts!" % stolen.get("gold", 0))

func _apply_auto_loss():
	"""When player has no defenders, lose a fixed amount"""
	if not TreasureVault.instance:
		return

	# Harsher penalty for no defenders (50% loss)
	var stolen = TreasureVault.instance.apply_raid_loss(0.50)
	print("[DefenseManager] [STOLEN] UNDEFENDED! Raiders stole %d gold and parts!" % stolen.get("gold", 0))

func _complete_wave(victory: bool, rewards: Dictionary):
	is_in_combat = false
	reset_wave_timer()
	wave_completed.emit(victory, rewards)

# === SERIALIZATION ===

func to_dict() -> Dictionary:
	var defending_ids: Array[String] = []
	for dragon in defending_dragons:
		defending_ids.append(dragon.id)

	return {
		"wave_number": wave_number,
		"time_until_next_wave": time_until_next_wave,
		"defending_dragon_ids": defending_ids
	}

func from_dict(data: Dictionary):
	wave_number = data.get("wave_number", 1)
	time_until_next_wave = data.get("time_until_next_wave", BASE_WAVE_INTERVAL)

	# Note: Defending dragons must be restored by SaveManager after dragons are loaded

# === DEBUG ===

func force_next_wave():
	"""Debug function to trigger wave immediately"""
	time_until_next_wave = 0

func get_time_until_wave() -> float:
	return time_until_next_wave
