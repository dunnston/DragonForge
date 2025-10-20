# Treasure Vault Display - Visual Representation of Player's Hoard
extends Control

# === UI ELEMENTS ===
@onready var vault_container: Control = $VaultContainer
@onready var treasure_pile: ColorRect = $VaultContainer/TreasurePile
@onready var gold_label: Label = $VaultContainer/GoldLabel
@onready var tier_label: Label = $VaultContainer/TierLabel
@onready var parts_container: VBoxContainer = $VaultContainer/PartsContainer
@onready var milestone_popup: Control = $MilestonePopup

# === VISUAL CONFIG ===
const PILE_COLORS = {
	1: Color(0.6, 0.5, 0.3),  # Bronze
	2: Color(0.7, 0.7, 0.5),  # Silver
	3: Color(0.9, 0.8, 0.3),  # Gold
	4: Color(0.9, 0.5, 0.9),  # Pink (gems)
	5: Color(0.5, 0.9, 0.9),  # Cyan (magic)
	6: Color(1.0, 0.9, 0.0)   # Legendary Gold
}

const PILE_SIZES = {
	1: Vector2(100, 80),
	2: Vector2(150, 100),
	3: Vector2(200, 130),
	4: Vector2(250, 160),
	5: Vector2(300, 200),
	6: Vector2(350, 250)
}

func _ready():
	if TreasureVault.instance:
		# Connect to vault signals
		TreasureVault.instance.gold_changed.connect(_on_gold_changed)
		TreasureVault.instance.parts_changed.connect(_on_parts_changed)
		TreasureVault.instance.vault_tier_changed.connect(_on_vault_tier_changed)
		TreasureVault.instance.milestone_reached.connect(_on_milestone_reached)
		TreasureVault.instance.resources_stolen.connect(_on_resources_stolen)

		# Initial update
		_update_display()
	else:
		print("[TreasureVaultDisplay] ERROR: TreasureVault instance not found!")

func _update_display():
	if not TreasureVault.instance:
		return

	var vault = TreasureVault.instance

	# Update gold display
	gold_label.text = "Gold: %d" % vault.get_total_gold()
	if vault.protected_gold > 0:
		gold_label.text += " ([PROTECTED] %d)" % vault.protected_gold

	# Update tier display
	tier_label.text = "Vault Tier: %d" % vault.vault_tier

	# Update treasure pile visual
	_update_treasure_pile(vault.vault_tier)

	# Update parts display
	_update_parts_display()

func _update_treasure_pile(tier: int):
	if not treasure_pile:
		return

	# Change color based on tier
	treasure_pile.color = PILE_COLORS.get(tier, PILE_COLORS[1])

	# Change size based on tier
	var target_size = PILE_SIZES.get(tier, PILE_SIZES[1])

	# Animate size change
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(treasure_pile, "custom_minimum_size", target_size, 0.5)

func _update_parts_display():
	if not parts_container:
		return

	# Clear existing part labels
	for child in parts_container.get_children():
		child.queue_free()

	var vault = TreasureVault.instance
	if not vault:
		return

	# Create labels for each element type
	for element in DragonPart.Element.values():
		var count = vault.get_part_count(element)
		var protected = vault.get_protected_part_count(element)

		if count > 0 or protected > 0:
			var label = Label.new()
			var element_name = DragonPart.Element.keys()[element]
			label.text = "%s Parts: %d" % [element_name, count]
			if protected > 0:
				label.text += " ([PROTECTED] %d)" % protected
			parts_container.add_child(label)

# === SIGNAL HANDLERS ===

func _on_gold_changed(new_amount: int, delta: int):
	_update_display()

	# Show floating text for gold changes
	if delta != 0:
		_show_floating_text("+%d gold" % delta if delta > 0 else "%d gold" % delta, Color.GOLD)

func _on_parts_changed(element: DragonPart.Element, new_count: int):
	_update_display()

func _on_vault_tier_changed(new_tier: int, old_tier: int):
	_update_display()

	# Show tier up notification
	if new_tier > old_tier:
		_show_floating_text("VAULT TIER UP!", Color.GOLD)
		_play_tier_up_effect()

func _on_milestone_reached(value: int, reward_id: String):
	# Show milestone popup
	_show_milestone_popup(value, reward_id)

func _on_resources_stolen(stolen_resources: Dictionary):
	var gold_lost = stolen_resources.get("gold", 0)
	var parts_lost = stolen_resources.get("parts", {})

	# Show raid warning
	_show_floating_text("RAIDED! -%d gold" % gold_lost, Color.RED)
	_play_raid_effect()

	_update_display()

# === VISUAL EFFECTS ===

func _show_floating_text(text: String, color: Color):
	# TODO: Create floating text effect
	print("[VaultDisplay] %s" % text)

func _play_tier_up_effect():
	# TODO: Particle effects or animation
	if treasure_pile:
		var tween = create_tween()
		tween.tween_property(treasure_pile, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(treasure_pile, "scale", Vector2(1.0, 1.0), 0.2)

func _play_raid_effect():
	# TODO: Screen shake or flash red
	if treasure_pile:
		var tween = create_tween()
		tween.tween_property(treasure_pile, "modulate", Color.RED, 0.1)
		tween.tween_property(treasure_pile, "modulate", Color.WHITE, 0.1)
		tween.tween_property(treasure_pile, "modulate", Color.RED, 0.1)
		tween.tween_property(treasure_pile, "modulate", Color.WHITE, 0.1)

func _show_milestone_popup(value: int, reward_id: String):
	# TODO: Show fancy popup
	print("[VaultDisplay] [MILESTONE] Unlocked at %d gold: %s" % [value, reward_id])

# === MANUAL UPDATE (for debugging) ===

func force_update():
	_update_display()
