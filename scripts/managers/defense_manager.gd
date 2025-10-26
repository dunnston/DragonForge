# Defense Manager - Wave-based Knight Attacks
# Protects the Treasure Vault from raiders
extends Node

# === SINGLETON ===
static var instance: DefenseManager

# === WAVE CONFIG ===
const BASE_WAVE_INTERVAL: float = 180.0  # 3 minutes between waves (after first wave)
const FIRST_WAVE_GRACE_PERIOD: float = 360.0  # 6 minutes for new players to set up

# === STATE ===
var wave_number: int = 1
var tower_assignments: Dictionary = {}  # {tower_index: Dragon} - maps tower to defending dragon
var time_until_next_wave: float = FIRST_WAVE_GRACE_PERIOD  # Start with grace period for new players
var is_in_combat: bool = false
var is_first_wave: bool = true  # Track if this is the first wave
var first_wave_completed: bool = false  # Track if first wave has finished (for exploration rewards)

# Store pending stat changes to apply after battle animation
var pending_stat_changes: Array[Dictionary] = []

# Store pending wave completion data
var pending_wave_victory: bool = false
var pending_wave_rewards: Dictionary = {}
var pending_wave_enemies: Array = []  # Store enemies for reward calculation
var current_wave_enemies: Array = []  # Current battle enemies (for mid-battle viewers)

# Store scouted enemies for preview (generated at 90 seconds)
var scouted_wave_enemies: Array = []
var has_shown_scout_warning: bool = false

# === CUMULATIVE REWARDS (since last UI open) ===
var cumulative_rewards: Dictionary = {
	"gold": 0,
	"meat": 0,
	"waves_won": 0,
	"waves_lost": 0,
	"total_waves": 0
}

# === SIGNALS ===
signal wave_incoming(time_remaining: float)
signal wave_incoming_scout(wave_number: int, enemies: Array, time_remaining: float)  # For 90-second warning with enemy data
signal wave_started(wave_number: int, enemies: Array)
signal wave_completed(victory: bool, rewards: Dictionary)
signal dragon_damaged(dragon: Dragon, damage: int)
signal dragon_defended_successfully(dragon: Dragon, enemies_defeated: int)
signal dragon_assigned_to_defense(dragon: Dragon)
signal dragon_removed_from_defense(dragon: Dragon)
signal defense_slots_full()

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

	print("[DefenseManager] Initialized - First wave in %.0f seconds (%.1f min grace period)" % [FIRST_WAVE_GRACE_PERIOD, FIRST_WAVE_GRACE_PERIOD / 60.0])

# === WAVE TIMER ===

func _update_wave_timer():
	if is_in_combat:
		return

	# Check if player is completely out of resources - pause raids if so
	# BUT if there are defenders assigned, let the waves continue
	if tower_assignments.is_empty() and _is_player_out_of_resources():
		print("[DefenseManager] Raids PAUSED - Vault is empty, no parts, and no dragons to explore")
		return

	# Apply vault risk multiplier (more treasure = more frequent attacks)
	var frequency_multiplier = 1.0
	if TreasureVault.instance:
		frequency_multiplier = TreasureVault.instance.get_attack_frequency_multiplier()

	time_until_next_wave -= frequency_multiplier

	# Emit scout warning at 90 seconds with enemy preview
	if time_until_next_wave <= 90 and not has_shown_scout_warning:
		has_shown_scout_warning = true
		scouted_wave_enemies = _generate_wave(wave_number)
		wave_incoming_scout.emit(wave_number, scouted_wave_enemies, time_until_next_wave)
		print("[DefenseManager] SCOUT WARNING: Wave %d incoming in 90 seconds! %d enemies detected." % [wave_number, scouted_wave_enemies.size()])

	# Emit warning signals (for other systems)
	if time_until_next_wave <= 30 and int(time_until_next_wave) % 10 == 0:
		wave_incoming.emit(time_until_next_wave)
		print("[DefenseManager] WARNING: Wave incoming in %.0f seconds!" % time_until_next_wave)

	# Start wave
	if time_until_next_wave <= 0:
		_start_wave()

func reset_wave_timer():
	# Reset scout warning flag for next wave
	has_shown_scout_warning = false
	scouted_wave_enemies.clear()

	# After first wave, use normal interval
	if is_first_wave:
		is_first_wave = false
		first_wave_completed = true
		print("[DefenseManager] First wave completed - subsequent waves will occur every %.0f seconds" % BASE_WAVE_INTERVAL)
		print("[DefenseManager] Exploration part drops will now use chance-based system")
	time_until_next_wave = BASE_WAVE_INTERVAL

func _is_player_out_of_resources() -> bool:
	"""Check if player has no resources left (empty vault, no parts, no dragons to send)"""
	
	# Check 1: Is vault empty (no gold)?
	var has_gold = false
	if TreasureVault and TreasureVault.instance:
		has_gold = TreasureVault.instance.get_total_gold() > 75
	
	# Check 2: Are there any dragon parts available?
	var has_parts = false
	if InventoryManager and InventoryManager.instance:
		var parts = InventoryManager.instance.get_all_dragon_parts()
		has_parts = parts.size() > 3
	
	# Check 3: Are there any idle dragons that could explore for parts?
	var has_explorable_dragons = false
	var factory_manager_nodes = get_tree().get_nodes_in_group("factory_manager")
	for node in factory_manager_nodes:
		if node.has_method("get") and node.get("factory"):
			var factory = node.get("factory")
			if factory and "active_dragons" in factory:
				var dragons = factory.active_dragons
				for dragon in dragons:
					# Check if dragon is idle and not too fatigued
					if dragon.current_state == Dragon.DragonState.IDLE and dragon.fatigue_level < 0.5:
						has_explorable_dragons = true
						break
	
	# Pause raids only if ALL resources are depleted
	if not has_gold and not has_parts and not has_explorable_dragons:
		print("[DefenseManager] ❌ RAIDS PAUSED: Vault empty (Gold: %s, Parts: %s, Explorable Dragons: %s)" % 
			[has_gold, has_parts, has_explorable_dragons])
		return true
	
	return false

# === DRAGON ASSIGNMENT ===

func assign_dragon_to_tower(dragon: Dragon, tower_index: int) -> bool:
	"""Assign a dragon to defend a specific tower"""
	
	# Validate tower index
	if not DefenseTowerManager or not DefenseTowerManager.instance:
		print("[DefenseManager] ERROR: DefenseTowerManager not found!")
		return false
	
	var towers = DefenseTowerManager.instance.get_towers()
	if tower_index < 0 or tower_index >= towers.size():
		print("[DefenseManager] Invalid tower index: %d" % tower_index)

	# Check if dragon is a pet (pets cannot be assigned to defense)
	if dragon is PetDragon:
		print("[DefenseManager] %s is a pet and cannot be assigned to defense!" % dragon.dragon_name)
		return false

	# Check tower capacity instead of hardcoded limit
	var max_defenders = 3  # Default fallback
	if DefenseTowerManager and DefenseTowerManager.instance:
		max_defenders = DefenseTowerManager.instance.get_defense_capacity()

	if tower_assignments.size() >= max_defenders:
		print("[DefenseManager] Maximum %d defenders (based on tower capacity)!" % max_defenders)
		defense_slots_full.emit()
		return false
	
	var tower = towers[tower_index]
	if tower.is_destroyed():
		print("[DefenseManager] Cannot assign to destroyed tower!")
		return false
	
	# Check if tower already has a dragon
	if tower_assignments.has(tower_index):
		print("[DefenseManager] Tower %d already has a defender!" % tower_index)
		return false
	
	# Check if dragon is already defending another tower
	for t_idx in tower_assignments.keys():
		if tower_assignments[t_idx] == dragon:
			print("[DefenseManager] %s is already defending tower %d!" % [dragon.dragon_name, t_idx])
			return false
	
	# Check dragon status
	if dragon.current_health <= 0 or dragon.is_dead:
		print("[DefenseManager] Dragon is dead!")
		return false
	
	if dragon.fatigue_level > 0.5:
		print("[DefenseManager] %s is too fatigued to defend (needs 50%% rest)!" % dragon.dragon_name)
		return false
	
	# Assign dragon to tower
	tower_assignments[tower_index] = dragon

	# Set dragon state to DEFENDING
	if DragonStateManager.instance:
		DragonStateManager.instance.set_dragon_state(dragon, Dragon.DragonState.DEFENDING)
	else:
		dragon.current_state = Dragon.DragonState.DEFENDING

	dragon_assigned_to_defense.emit(dragon)

	# Play dragon growl when assigned to defense
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_dragon_growl()

	print("[DefenseManager] %s assigned to tower %d (Total defenders: %d)" % [dragon.dragon_name, tower_index, tower_assignments.size()])
	return true

func remove_dragon_from_tower(tower_index: int) -> bool:
	"""Remove dragon assignment from a specific tower"""
	if not tower_assignments.has(tower_index):
		return false
	
	var dragon = tower_assignments[tower_index]
	tower_assignments.erase(tower_index)
	
	# Set dragon state to IDLE
	if DragonStateManager.instance:
		DragonStateManager.instance.set_dragon_state(dragon, Dragon.DragonState.IDLE)
	else:
		dragon.current_state = Dragon.DragonState.IDLE
	
	dragon_removed_from_defense.emit(dragon)
	print("[DefenseManager] %s removed from tower %d" % [dragon.dragon_name, tower_index])
	return true

func get_dragon_for_tower(tower_index: int) -> Dragon:
	"""Get the dragon assigned to a specific tower"""
	return tower_assignments.get(tower_index, null)

func get_defending_dragons() -> Array[Dragon]:
	"""Get all currently defending dragons"""
	var dragons: Array[Dragon] = []
	for dragon in tower_assignments.values():
		dragons.append(dragon)
	return dragons

func get_tower_assignments() -> Dictionary:
	"""Get the complete tower assignment dictionary"""
	return tower_assignments.duplicate()

func get_max_defenders() -> int:
	"""Returns the maximum number of dragons that can defend (based on tower capacity)"""
	if DefenseTowerManager and DefenseTowerManager.instance:
		return DefenseTowerManager.instance.get_defense_capacity()
	return 3  # Default fallback

# === BACKWARD COMPATIBILITY ===

func assign_dragon_to_defense(dragon: Dragon) -> bool:
	"""
	Legacy method for backward compatibility.
	Assigns dragon to the first available tower slot.
	"""
	if not DefenseTowerManager or not DefenseTowerManager.instance:
		print("[DefenseManager] ERROR: DefenseTowerManager not found!")
		return false
	
	var towers = DefenseTowerManager.instance.get_towers()
	
	# Find first available tower (not destroyed, no dragon assigned)
	for i in range(towers.size()):
		if not towers[i].is_destroyed() and not tower_assignments.has(i):
			return assign_dragon_to_tower(dragon, i)
	
	print("[DefenseManager] No available tower slots!")
	defense_slots_full.emit()
	return false

func remove_dragon_from_defense(dragon: Dragon) -> bool:
	"""
	Legacy method for backward compatibility.
	Removes dragon from whichever tower it's assigned to.
	"""
	# Find which tower this dragon is assigned to
	for tower_idx in tower_assignments.keys():
		if tower_assignments[tower_idx] == dragon:
			return remove_dragon_from_tower(tower_idx)
	
	print("[DefenseManager] Dragon not found in any tower assignment")
	return false

# === WAVE GENERATION & COMBAT ===

func _start_wave():
	is_in_combat = true

	# Clear previous wave's enemy data before starting new wave
	current_wave_enemies.clear()

	# Use pre-scouted enemies if available, otherwise generate new ones
	var enemies: Array
	if scouted_wave_enemies.size() > 0:
		enemies = scouted_wave_enemies.duplicate(true)  # Deep copy to avoid reference issues
		print("[DefenseManager] Using pre-scouted enemies for wave %d" % wave_number)
	else:
		enemies = _generate_wave(wave_number)
		print("[DefenseManager] Generating enemies for wave %d (no scout data)" % wave_number)

	print("[DefenseManager] COMBAT: WAVE %d - %d enemies attacking!" % [wave_number, enemies.size()])

	# Store enemies for mid-battle viewers (and late viewers after battle ends)
	current_wave_enemies = enemies

	# Give players 3 seconds to see notification and click "WATCH BATTLE"
	print("[DefenseManager] Battle notification shown - waiting 3 seconds before combat starts...")
	wave_started.emit(wave_number, enemies)

	# Play wave start sound
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_wave_start()

	await get_tree().create_timer(3.0).timeout
	print("[DefenseManager] Starting combat now!")

	# Get all defending dragons
	var defending_dragons = get_defending_dragons()

	# Check if we have defenders
	if defending_dragons.is_empty():
		print("[DefenseManager] ERROR: NO DEFENDERS! Auto-loss!")
		_apply_auto_loss()
		_complete_wave(false, {})
		return

	# Calculate pending stat changes for after combat
	_resolve_combat(defending_dragons, enemies)
	
	# Store enemies for reward calculation later
	pending_wave_enemies = enemies
	
	# DON'T determine victory here - wait for visual combat to report actual result!

func on_visual_combat_result(victory: bool):
	"""Called by visual combat when the winner is determined"""
	print("[DefenseManager] Visual combat result received: Victory=%s" % victory)
	
	# Now apply the actual result
	if victory:
		var rewards = _calculate_rewards(pending_wave_enemies)
		_apply_rewards(rewards)
		wave_number += 1
		print("[DefenseManager] ✅ VICTORY! Wave %d complete. Rewards: %d gold, %d meat 🍖" % [wave_number - 1, rewards.get("gold", 0), rewards.get("meat", 0)])

		# Add tower damage info to rewards (5 damage per tower on victory)
		var active_towers = DefenseTowerManager.instance.get_active_towers() if DefenseTowerManager and DefenseTowerManager.instance else 0
		rewards["tower_damage"] = active_towers * 5  # SMALL_DAMAGE constant from DefenseTowerManager
		rewards["towers_destroyed"] = 0

		# Store for after animation
		pending_wave_victory = true
		pending_wave_rewards = rewards
	else:
		var stolen = _apply_raid_loss()
		print("[DefenseManager] ❌ DEFEAT! Raiders stole from your vault!")

		# Calculate tower damage (20 damage per tower on defeat)
		var active_towers = DefenseTowerManager.instance.get_active_towers() if DefenseTowerManager and DefenseTowerManager.instance else 0
		var tower_damage = active_towers * 20  # LARGE_DAMAGE constant from DefenseTowerManager

		# Store for after animation - include stolen amounts and tower damage
		pending_wave_victory = false
		pending_wave_rewards = {
			"gold": 0,
			"meat": 0,
			"vault_gold_stolen": stolen.get("gold", 0),
			"vault_parts_stolen": stolen.get("parts", []),
			"tower_damage": tower_damage,
			"towers_destroyed": 0  # Will be calculated in end_combat if any tower health reaches 0
		}

func _generate_wave(wave_num: int) -> Array:
	var enemies: Array = []

	# Apply vault risk multiplier (more treasure = stronger enemies)
	var difficulty_multiplier = 1.0
	#if TreasureVault.instance:
	#	difficulty_multiplier = TreasureVault.instance.get_attack_difficulty_multiplier()

	# Base enemy count increases with wave number
	var enemy_count = 1 + int(wave_num / 5.0)
	enemy_count = int(enemy_count * difficulty_multiplier)
	enemy_count = max(1, enemy_count)  # At least 1 enemy

	for i in enemy_count:
		# Random enemy type: 60% knight, 30% wizard, 10% mixed
		var rand = randf()
		var enemy: Dictionary
		
		if rand < 0.60:
			enemy = _create_knight(wave_num, difficulty_multiplier)
		else:
			enemy = _create_wizard(wave_num, difficulty_multiplier)
		
		enemies.append(enemy)

	# Boss every 10 waves
	#if wave_num % 10 == 0:
	#	var boss = _create_boss(wave_num, difficulty_multiplier)
	#	enemies.append(boss)
	#	print("[DefenseManager] [BOSS] BOSS WAVE!")

	return enemies

func _create_knight(wave_num: int, difficulty_mult: float = 1.0) -> Dictionary:
	return {
		"type": "knight",
		"level": wave_num,
		"attack": int((8 + wave_num * 3) * difficulty_mult),
		"health": int((40 + wave_num * 10) * difficulty_mult),
		"speed": int((5 + wave_num) * difficulty_mult),
		"reward_gold": int((10 + wave_num * 5) * difficulty_mult)
	}

func _create_wizard(wave_num: int, difficulty_mult: float = 1.0) -> Dictionary:
	# Wizards have lower health but higher attack and elemental damage
	var random_element = randi() % DragonPart.Element.size()
	return {
		"type": "wizard",
		"is_wizard": true,  # Flag for visual identification
		"level": wave_num,
		"attack": int((6 + wave_num * 3) * difficulty_mult),  # Higher base attack than knight
		"health": int((30 + wave_num * 7) * difficulty_mult),  # Lower health than knight
		"speed": int((8 + wave_num * 1.5) * difficulty_mult),
		"reward_gold": int((15 + wave_num * 7) * difficulty_mult),
		"elemental_type": random_element,  # Fire, Ice, Lightning, Poison, Shadow
		"elemental_damage": int((5 + wave_num * 2) * difficulty_mult)  # Extra elemental damage
	}

func _create_boss(wave_num: int, difficulty_mult: float = 1.0) -> Dictionary:
	return {
		"type": "boss",
		"level": wave_num,
		"attack": int((25 + wave_num * 6) * difficulty_mult),
		"health": int((150 + wave_num * 20) * difficulty_mult),
		"speed": int((10 + wave_num * 2) * difficulty_mult),
		"reward_gold": int((50 + wave_num * 10) * difficulty_mult)
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
		
		# Wizards deal elemental damage
		if enemy.get("type") == "wizard" and dragons.size() > 0:
			var elemental_bonus = _calculate_elemental_damage(enemy, dragons)
			e_power += elemental_bonus
			print("[DefenseManager] Wizard elemental damage: +%.1f" % elemental_bonus)
		
		enemy_power += e_power

	print("[DefenseManager] Dragon power: %.1f vs Enemy power: %.1f" % [dragon_power, enemy_power])

	# Victory if dragons have at least 10% more power
	if dragon_power >= enemy_power * 1.1:
		# Victory - store stat changes to apply after animation
		pending_stat_changes.clear()
		for dragon in dragons:
			pending_stat_changes.append({
				"dragon": dragon,
				"xp": 50 * wave_number,
				"fatigue": 0.1,
				"damage": 0,
				"victory": true
			})

		return true
	else:
		# Defeat - store stat changes to apply after animation
		var damage_per_dragon = (enemy_power - dragon_power) / dragons.size()
		damage_per_dragon = max(10, damage_per_dragon)  # Minimum 10 damage
		
		pending_stat_changes.clear()
		for dragon in dragons:
			pending_stat_changes.append({
				"dragon": dragon,
				"xp": 0,
				"fatigue": 0.15,
				"damage": int(damage_per_dragon),
				"victory": false
			})

		return false

func _calculate_elemental_damage(wizard: Dictionary, dragons: Array[Dragon]) -> float:
	"""Calculate bonus damage from wizard's elemental attack against dragons"""
	var base_elemental_damage = wizard.get("elemental_damage", 0)
	var wizard_element = wizard.get("elemental_type", 0)
	
	# Calculate average elemental effectiveness against all defending dragons
	var total_effectiveness = 0.0
	for dragon in dragons:
		# Get dragon's resistance to wizard's element
		var resistance = dragon.get_elemental_resistance(wizard_element)
		# Convert resistance multiplier to effectiveness
		# resistance > 1.0 = weak to element (more damage)
		# resistance < 1.0 = resistant to element (less damage)
		total_effectiveness += resistance
	
	var avg_effectiveness = total_effectiveness / dragons.size()
	var final_damage = base_elemental_damage * avg_effectiveness
	
	return final_damage

# === REWARDS & LOSSES ===

func _calculate_rewards(enemies: Array) -> Dictionary:
	var total_gold = 0
	var total_meat = 0

	for enemy in enemies:
		total_gold += enemy.get("reward_gold", 10)
		
		# Chance-based meat drops (only from knights and bosses, not wizards)
		if enemy.get("type") == "knight":
			if randf() < 0.50:  # 50% chance for normal knights
				total_meat += 1
		elif enemy.get("type") == "boss":
			if randf() < 0.75:  # 75% chance for bosses
				total_meat += randi_range(2, 3)
		# Wizards don't drop meat

	return {
		"gold": total_gold,
		"meat": total_meat
	}

func _apply_rewards(rewards: Dictionary):
	if not TreasureVault.instance:
		print("[DefenseManager] ERROR: No TreasureVault instance!")
		return

	# Add gold
	TreasureVault.instance.add_gold(rewards["gold"])
	
	# Add knight meat to inventory
	var meat_count = rewards.get("meat", 0)
	if meat_count > 0 and InventoryManager.instance:
		InventoryManager.instance.add_item_by_id("knight_meat", meat_count)
		print("[DefenseManager] [LOOT] Gained %d knight meat!" % meat_count)
	
	# Track cumulative rewards
	cumulative_rewards["gold"] += rewards.get("gold", 0)
	cumulative_rewards["meat"] += rewards.get("meat", 0)

func _apply_raid_loss() -> Dictionary:
	if not TreasureVault.instance:
		return {}

	# Calculate loss percentage (higher waves = bigger losses, but capped at 30%)
	var loss_percentage = min(0.30, 0.15 + (wave_number * 0.01))

	# Apply loss to vault
	var stolen = TreasureVault.instance.apply_raid_loss(loss_percentage)

	print("[DefenseManager] [STOLEN] Raiders stole %d gold and parts!" % stolen.get("gold", 0))
	return stolen

func _apply_auto_loss():
	"""When player has no defenders, lose a fixed amount"""
	if not TreasureVault.instance:
		return

	# Harsher penalty for no defenders (50% loss)
	var stolen = TreasureVault.instance.apply_raid_loss(0.50)
	print("[DefenseManager] [STOLEN] UNDEFENDED! Raiders stole %d gold and parts!" % stolen.get("gold", 0))

func _complete_wave(victory: bool, rewards: Dictionary):
	# Don't set is_in_combat to false yet - wait for battle animation to finish
	# This keeps the wave timer paused during the battle animation

	# Track cumulative wave stats
	cumulative_rewards["total_waves"] += 1
	if victory:
		cumulative_rewards["waves_won"] += 1
	else:
		cumulative_rewards["waves_lost"] += 1

	# Pay scientist salaries after each wave (victory or defeat)
	if ScientistManager and ScientistManager.instance:
		var salary_paid = ScientistManager.instance.pay_salaries()
		if not salary_paid:
			print("[DefenseManager] ⚠️ WARNING: Failed to pay scientist salaries!")
		# Note: pay_salaries() returns false if insufficient funds

	# Note: Dragon death and tower destruction is now handled in end_combat()
	# after the battle animation finishes

	# Play battle won sound if victorious
	if victory and AudioManager and AudioManager.instance:
		AudioManager.instance.play_battle_won()

	reset_wave_timer()
	wave_completed.emit(victory, rewards)
	
	# Safety fallback: If no battle animation happens, end combat after 5 seconds
	# This handles background battles when UI isn't open
	get_tree().create_timer(5.0).timeout.connect(func():
		if is_in_combat:
			print("[DefenseManager] No battle animation detected, auto-ending combat")
			end_combat()
	)

func end_combat():
	"""Called when battle animation finishes - resumes wave timer and applies stat changes"""
	is_in_combat = false
	# DON'T clear current_wave_enemies here - keep it so late viewers can still see the battle
	# It will be cleared when the next wave starts
	print("[DefenseManager] Combat ended, applying stat changes to dragons...")
	
	# Apply all pending stat changes now that animation is done
	for change in pending_stat_changes:
		var dragon = change["dragon"]
		
		# Skip if dragon died during combat
		if dragon.is_dead:
			continue
		
		# Apply XP
		if change["xp"] > 0 and DragonStateManager.instance:
			DragonStateManager.instance.gain_experience(dragon, change["xp"])
			print("[DefenseManager] %s gained %d XP" % [dragon.dragon_name, change["xp"]])
		
		# Apply fatigue
		dragon.fatigue_level = min(1.0, dragon.fatigue_level + change["fatigue"])
		print("[DefenseManager] %s fatigue: %.1f%%" % [dragon.dragon_name, dragon.fatigue_level * 100])
		
		# Apply damage
		if change["damage"] > 0:
			dragon.take_damage(change["damage"])
			dragon_damaged.emit(dragon, change["damage"])

			# Play attack hit sound
			if AudioManager and AudioManager.instance:
				AudioManager.instance.play_attack_hit()

			print("[DefenseManager] %s took %d damage (HP: %.0f/%.0f)" %
				[dragon.dragon_name, change["damage"], dragon.current_health, dragon.get_health()])
			
			# Check if dragon died from damage
			if dragon.is_dead or dragon.current_health <= 0:
				print("[DefenseManager] DEAD: %s has fallen!" % dragon.dragon_name)
				_handle_dragon_death(dragon)
		
		# Emit success signal for victories
		if change["victory"]:
			dragon_defended_successfully.emit(dragon, 1)
	
	pending_stat_changes.clear()
	print("[DefenseManager] Wave timer resumed")

	# Apply tower damage based on wave result
	if DefenseTowerManager and DefenseTowerManager.instance:
		DefenseTowerManager.instance.apply_wave_damage(pending_wave_victory)
		print("[DefenseManager] Applied tower damage - Victory: %s" % pending_wave_victory)

	# Refresh all UIs on next frame to ensure dragon data is fully updated
	await get_tree().process_frame
	_refresh_all_dragon_uis()

	# NOW complete the wave after animation and stat changes
	_complete_wave(pending_wave_victory, pending_wave_rewards)

func _handle_dragon_death(dragon: Dragon):
	"""Handle all cleanup when a dragon dies"""
	print("[DefenseManager] Handling death of %s" % dragon.dragon_name)
	
	# Ensure dragon is marked as dead
	if not dragon.is_dead:
		dragon._die()
	
	# Find which tower this dragon was defending and destroy it
	var tower_to_destroy: int = -1
	for tower_idx in tower_assignments.keys():
		if tower_assignments[tower_idx] == dragon:
			tower_to_destroy = tower_idx
			break
	
	if tower_to_destroy >= 0:
		print("[DefenseManager] Destroying tower %d because %s died" % [tower_to_destroy, dragon.dragon_name])
		
		# Destroy the tower
		if DefenseTowerManager and DefenseTowerManager.instance:
			var towers = DefenseTowerManager.instance.get_towers()
			if tower_to_destroy < towers.size():
				var tower = towers[tower_to_destroy]
				tower.current_health = 0
				print("[DefenseManager] Tower %d health set to 0" % tower_to_destroy)
		
		# Remove dragon from tower assignments
		tower_assignments.erase(tower_to_destroy)
	
	# Remove from dragon state manager
	if DragonStateManager and DragonStateManager.instance:
		DragonStateManager.instance.unregister_dragon(dragon)
	
	# Remove from factory
	_remove_dragon_from_factory(dragon)

	# Refresh tower UI if it's open
	_refresh_tower_ui()

	# Trigger part recovery and death notification
	if DragonDeathManager and DragonDeathManager.instance:
		DragonDeathManager.instance.handle_dragon_death(dragon, "combat_defending")
		print("[DefenseManager] Triggered part recovery for %s" % dragon.dragon_name)

func _remove_dragon_from_factory(dragon: Dragon):
	"""Remove dead dragon from factory manager and refresh UI"""
	var factory_manager_nodes = get_tree().get_nodes_in_group("factory_manager")
	
	for node in factory_manager_nodes:
		if node.has_method("get") and node.get("factory"):
			var factory = node.get("factory")
			if factory and factory.has_method("remove_dragon"):
				factory.remove_dragon(dragon)
				print("[DefenseManager] Removed %s from factory" % dragon.dragon_name)
				
				# Force immediate UI refresh
				if node.has_method("_update_dragons_list"):
					node._update_dragons_list()
					print("[DefenseManager] Refreshed factory manager UI after dragon death")
				return

func _refresh_tower_ui():
	"""Refresh defense tower UI to remove dead dragons"""
	var tower_ui_nodes = get_tree().get_nodes_in_group("defense_towers_ui")
	
	for node in tower_ui_nodes:
		if node.has_method("_refresh_tower_cards"):
			node._refresh_tower_cards()
			print("[DefenseManager] Refreshed tower UI after dragon death")

func _refresh_all_dragon_uis():
	"""Refresh all UIs that display dragon data after combat"""
	# Refresh factory manager dragon list
	var factory_manager_nodes = get_tree().get_nodes_in_group("factory_manager")
	for node in factory_manager_nodes:
		if node.has_method("_update_dragons_list"):
			node._update_dragons_list()
			print("[DefenseManager] Refreshed factory manager dragon list after combat")
	
	# Refresh dragon details modal if it's open
	var dragon_details_nodes = get_tree().get_nodes_in_group("dragon_details_modal")
	for node in dragon_details_nodes:
		if node.visible and node.has_method("_update_display"):
			node._update_display()
			print("[DefenseManager] Refreshed dragon details modal after combat")
	
	# Refresh tower UI
	_refresh_tower_ui()

# === CUMULATIVE REWARDS ===

func get_cumulative_rewards() -> Dictionary:
	"""Get cumulative rewards since last UI open"""
	return cumulative_rewards.duplicate()

func reset_cumulative_rewards():
	"""Reset cumulative rewards (called when UI is opened and rewards are shown)"""
	cumulative_rewards = {
		"gold": 0,
		"meat": 0,
		"waves_won": 0,
		"waves_lost": 0,
		"total_waves": 0
	}

# === SERIALIZATION ===

func to_dict() -> Dictionary:
	# Save tower assignments as {tower_index: dragon_id}
	var assignments_data: Dictionary = {}
	for tower_idx in tower_assignments.keys():
		var dragon = tower_assignments[tower_idx]
		assignments_data[str(tower_idx)] = dragon.dragon_id

	return {
		"wave_number": wave_number,
		"time_until_next_wave": time_until_next_wave,
		"tower_assignments": assignments_data,
		"is_first_wave": is_first_wave,
		"first_wave_completed": first_wave_completed
	}

func from_dict(data: Dictionary, dragon_factory = null):
	wave_number = data.get("wave_number", 1)
	time_until_next_wave = data.get("time_until_next_wave", BASE_WAVE_INTERVAL)
	is_first_wave = data.get("is_first_wave", false)  # Default to false for saved games
	first_wave_completed = data.get("first_wave_completed", false)

	# Restore tower assignments if factory is provided
	tower_assignments.clear()
	if dragon_factory and data.has("tower_assignments"):
		var assignments_data = data["tower_assignments"]
		for tower_idx_str in assignments_data.keys():
			var tower_idx = int(tower_idx_str)
			var dragon_id = assignments_data[tower_idx_str]
			var dragon = dragon_factory.get_dragon_by_id(dragon_id)

			if dragon and not dragon.is_dead:
				tower_assignments[tower_idx] = dragon
				dragon.current_state = Dragon.DragonState.DEFENDING
				print("[DefenseManager] Restored tower %d defender: %s" % [tower_idx, dragon.dragon_name])
			else:
				print("[DefenseManager] WARNING: Could not restore defending dragon %s for tower %d" % [dragon_id, tower_idx])

	# Refresh tower UI to display restored assignments
	await get_tree().process_frame  # Wait one frame for UI to be ready
	_refresh_tower_ui()
	print("[DefenseManager] Refreshed tower UI after loading save data")

# === DEBUG ===

func force_next_wave():
	"""Debug function to trigger wave immediately"""
	time_until_next_wave = 0

func get_time_until_wave() -> float:
	return time_until_next_wave
