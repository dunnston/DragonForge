# Treasure Vault - Central Resource Storage System
# The player's hoard that dragons defend and exploration adds to
extends Node

# === SINGLETON ===
static var instance: TreasureVault

# === RESOURCE STORAGE ===
var gold: int = 100  # Starting gold
var artifacts: Dictionary = {}  # Special items {artifact_name: count}

# === VAULT STATE ===
var total_vault_value: int = 0  # Combined value of all resources
var vault_tier: int = 1  # Visual tier (1-5) based on total value
var milestones_reached: Array[int] = []  # Track which milestones hit

# === PROTECTED STORAGE ===
# Resources that can't be stolen (upgraded vault feature)
var protected_gold: int = 0

# === MILESTONE THRESHOLDS ===
const MILESTONES = {
	500: "first_scientist_slot",
	1000: "second_scientist_slot",
	2500: "protected_storage_unlock",
	5000: "third_scientist_slot",
	10000: "builder_scientist_unlock",
	25000: "vault_mastery"
}

# === VAULT TIERS (for visual representation) ===
const TIER_THRESHOLDS = [0, 500, 1500, 5000, 10000, 25000]

# === SIGNALS ===
signal gold_changed(new_amount: int, delta: int)
signal artifact_added(artifact_name: String, count: int)
signal vault_value_changed(new_value: int)
signal vault_tier_changed(new_tier: int, old_tier: int)
signal milestone_reached(value: int, reward_id: String)
signal resources_stolen(stolen_resources: Dictionary)
signal resources_protected(protected_resources: Dictionary)

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	_update_vault_value()

# === GOLD MANAGEMENT ===

func add_gold(amount: int):
	if amount <= 0:
		return

	gold += amount
	_update_vault_value()
	gold_changed.emit(gold, amount)

	# Play gold sound
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_gold()

	print("[TreasureVault] +%d gold (Total: %d)" % [amount, gold])

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true

	# Can spend from protected + unprotected gold
	var available = gold + protected_gold
	if available < amount:
		# Play error sound for insufficient gold
		if AudioManager and AudioManager.instance:
			AudioManager.instance.play_error()

		print("[TreasureVault] Insufficient gold! Need %d, have %d" % [amount, available])
		return false

	# Deduct from unprotected first, then protected
	if gold >= amount:
		gold -= amount
	else:
		var remainder = amount - gold
		gold = 0
		protected_gold -= remainder

	_update_vault_value()
	gold_changed.emit(gold, -amount)

	# Play gold sound
	if AudioManager and AudioManager.instance:
		AudioManager.instance.play_gold()

	print("[TreasureVault] -%d gold (Total: %d)" % [amount, gold])
	return true

func get_total_gold() -> int:
	return gold + protected_gold

# === ARTIFACTS (Special Items) ===

func add_artifact(artifact_name: String, count: int = 1):
	if not artifacts.has(artifact_name):
		artifacts[artifact_name] = 0

	artifacts[artifact_name] += count
	_update_vault_value()
	artifact_added.emit(artifact_name, artifacts[artifact_name])
	print("[TreasureVault] Found artifact: %s x%d" % [artifact_name, count])

func get_artifact_count(artifact_name: String) -> int:
	return artifacts.get(artifact_name, 0)

# === VAULT VALUE & TIER SYSTEM ===

func _update_vault_value():
	# Calculate total vault value
	var new_value = gold + protected_gold

	# Artifacts worth 100 gold each
	for artifact in artifacts:
		new_value += artifacts[artifact] * 100

	var old_value = total_vault_value
	total_vault_value = new_value
	vault_value_changed.emit(total_vault_value)

	# Check tier changes
	var old_tier = vault_tier
	vault_tier = _calculate_tier()
	if vault_tier != old_tier:
		vault_tier_changed.emit(vault_tier, old_tier)
		print("[TreasureVault] Vault tier changed: %d → %d" % [old_tier, vault_tier])

	# Check milestones
	_check_milestones()

func _calculate_tier() -> int:
	for i in range(TIER_THRESHOLDS.size() - 1, -1, -1):
		if total_vault_value >= TIER_THRESHOLDS[i]:
			return i
	return 1

func _check_milestones():
	for milestone_value in MILESTONES.keys():
		if total_vault_value >= milestone_value and milestone_value not in milestones_reached:
			milestones_reached.append(milestone_value)
			var reward_id = MILESTONES[milestone_value]
			milestone_reached.emit(milestone_value, reward_id)
			print("[TreasureVault] [MILESTONE] REACHED: %d gold - Unlocked: %s" % [milestone_value, reward_id])

func has_reached_milestone(value: int) -> bool:
	return value in milestones_reached

# === LOSS MECHANICS (When Defense Fails) ===

func apply_raid_loss(loss_percentage: float = 0.25) -> Dictionary:
	"""
	Called when defense fails. Lose a percentage of unprotected resources.
	Protected resources are safe!

	Args:
		loss_percentage: Percentage of unprotected resources to lose (0.0 - 1.0)

	Returns:
		Dictionary of what was stolen: {"gold": X, "parts": {...}}
	"""
	loss_percentage = clamp(loss_percentage, 0.0, 1.0)

	var stolen = {
		"gold": 0
	}

	# Lose gold (unprotected only)
	if gold > 0:
		var gold_loss = int(gold * loss_percentage)
		gold_loss = max(1, gold_loss)  # Always lose at least 1 gold if you have any
		gold_loss = min(gold, gold_loss)

		gold -= gold_loss
		stolen["gold"] = gold_loss

	_update_vault_value()

	# Emit signals
	resources_stolen.emit(stolen)
	print("[TreasureVault] [RAID] LOSS: Lost %d gold!" % stolen["gold"])

	# Show what was protected
	if protected_gold > 0:
		var protected = {
			"gold": protected_gold
		}
		resources_protected.emit(protected)
		print("[TreasureVault] [PROTECTED] Resources safe: %d gold" % protected_gold)

	return stolen

# === PROTECTED STORAGE (Upgrade Feature) ===

func protect_gold(amount: int) -> bool:
	"""Move gold from vulnerable to protected storage"""
	if gold < amount:
		return false

	gold -= amount
	protected_gold += amount
	print("[TreasureVault] [PROTECTED] Secured %d gold" % amount)
	return true

func unprotect_gold(amount: int) -> bool:
	"""Move gold from protected to vulnerable storage"""
	if protected_gold < amount:
		return false

	protected_gold -= amount
	gold += amount
	return true

# === RISK/REWARD CALCULATION ===

func get_attack_difficulty_multiplier() -> float:
	"""
	Returns a multiplier for attack difficulty based on vault value.
	More treasure = stronger/more frequent attacks!

	Returns: 1.0 at tier 1, up to 3.0 at tier 6
	"""
	return 1.0 + (vault_tier * 0.4)

func get_attack_frequency_multiplier() -> float:
	"""
	Returns a multiplier for attack frequency.
	More treasure = more frequent attacks!

	Returns: 1.0 at tier 1, up to 2.0 at tier 6
	"""
	return 1.0 + (vault_tier * 0.2)

# === SERIALIZATION ===

func to_dict() -> Dictionary:
	return {
		"gold": gold,
		"protected_gold": protected_gold,
		"artifacts": artifacts.duplicate(),
		"milestones_reached": Array(milestones_reached),  # Convert typed array to generic array
		"total_vault_value": total_vault_value,
		"vault_tier": vault_tier
	}

func from_dict(data: Dictionary):
	gold = data.get("gold", 100)
	protected_gold = data.get("protected_gold", 0)
	artifacts = data.get("artifacts", {})

	# Convert generic array back to typed array
	var loaded_milestones = data.get("milestones_reached", [])
	milestones_reached.clear()
	for milestone in loaded_milestones:
		if milestone is int:
			milestones_reached.append(milestone)

	total_vault_value = data.get("total_vault_value", 0)
	vault_tier = data.get("vault_tier", 1)

	# Emit all change signals to update UI
	gold_changed.emit(gold, 0)
	vault_value_changed.emit(total_vault_value)
	vault_tier_changed.emit(vault_tier, vault_tier)

# === DEBUG / TESTING ===

func print_vault_status():
	print("\n=== TREASURE VAULT STATUS ===")
	print("Total Value: %d gold (Tier %d)" % [total_vault_value, vault_tier])
	print("Gold: %d (Protected: %d)" % [gold, protected_gold])
	if artifacts.size() > 0:
		print("Artifacts:")
		for artifact in artifacts:
			print("  - %s: %d" % [artifact, artifacts[artifact]])
	print("Milestones: %s" % str(milestones_reached))
	print("Attack Difficulty: %.1fx" % get_attack_difficulty_multiplier())
	print("Attack Frequency: %.1fx" % get_attack_frequency_multiplier())
	print("============================\n")
