# Inventory Panel - Detailed Treasure Vault Viewer
extends Control

# === UI ELEMENTS ===
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var vault_tier_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VaultInfo/VaultTierLabel
@onready var total_value_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/VaultInfo/TotalValueLabel

# Gold
@onready var gold_amount: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/GoldSection/GoldDisplay/Amount
@onready var protected_gold_amount: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/GoldSection/ProtectedGoldDisplay/Amount

# Parts
@onready var fire_count: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PartsSection/PartsGrid/FireCount
@onready var ice_count: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PartsSection/PartsGrid/IceCount
@onready var lightning_count: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PartsSection/PartsGrid/LightningCount
@onready var nature_count: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PartsSection/PartsGrid/NatureCount
@onready var shadow_count: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PartsSection/PartsGrid/ShadowCount

# Risk info
@onready var attack_risk_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/InfoSection/AttackRiskLabel
@onready var attack_freq_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/InfoSection/AttackFreqLabel

func _ready():
	# Connect close button
	close_button.pressed.connect(_on_close_pressed)

	# Connect to TreasureVault signals
	if TreasureVault:
		TreasureVault.gold_changed.connect(_on_vault_changed)
		TreasureVault.parts_changed.connect(_on_vault_changed)
		TreasureVault.vault_tier_changed.connect(_on_vault_changed)

	# Start hidden
	hide()

func _on_close_pressed():
	hide()

func open():
	"""Show the inventory panel and update all displays"""
	show()
	_update_display()

func _on_vault_changed(_arg1 = null, _arg2 = null):
	"""Update display when vault changes"""
	if visible:
		_update_display()

func _update_display():
	if not TreasureVault:
		print("[InventoryPanel] ERROR: TreasureVault not available")
		return

	# Vault tier and value
	vault_tier_label.text = "Vault Tier: %d" % TreasureVault.vault_tier
	total_value_label.text = "Total Value: %d gold" % TreasureVault.total_vault_value

	# Gold
	gold_amount.text = "%d (Vulnerable)" % TreasureVault.gold
	protected_gold_amount.text = "%d (Protected)" % TreasureVault.protected_gold

	# Parts
	fire_count.text = _format_part_count(DragonPart.Element.FIRE)
	ice_count.text = _format_part_count(DragonPart.Element.ICE)
	lightning_count.text = _format_part_count(DragonPart.Element.LIGHTNING)
	nature_count.text = _format_part_count(DragonPart.Element.NATURE)
	shadow_count.text = _format_part_count(DragonPart.Element.SHADOW)

	# Risk info
	attack_risk_label.text = "Attack Difficulty: %.1fx" % TreasureVault.get_attack_difficulty_multiplier()
	attack_freq_label.text = "Attack Frequency: %.1fx" % TreasureVault.get_attack_frequency_multiplier()

func _format_part_count(element: DragonPart.Element) -> String:
	var vulnerable = TreasureVault.get_part_count(element)
	var protected = TreasureVault.get_protected_part_count(element)

	if protected > 0:
		return "%d (+ %d protected)" % [vulnerable, protected]
	else:
		return str(vulnerable)

func _input(event):
	# Close on ESC key
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and visible:
		hide()
		get_viewport().set_input_as_handled()
