extends PanelContainer

# Scientist Card UI Component
# Displays a single scientist's info, tier, abilities, and upgrade options

# === CONFIGURATION ===
@export var scientist_type: Scientist.Type = Scientist.Type.STITCHER

# === UI REFERENCES ===
@onready var scientist_name_label: Label = %ScientistNameLabel
@onready var tier_label: Label = %TierLabel
@onready var tier_dots_label: Label = %TierDotsLabel
@onready var salary_label: Label = %SalaryLabel
@onready var status_label: Label = %StatusLabel

@onready var abilities_container: VBoxContainer = %AbilitiesContainer
@onready var ability_labels: Array = []  # Will hold 5 ability labels

@onready var upgrade_section: VBoxContainer = %UpgradeSection
@onready var next_tier_label: Label = %NextTierLabel
@onready var new_ability_label: Label = %NewAbilityLabel
@onready var upgrade_cost_label: Label = %UpgradeCostLabel
@onready var upgrade_salary_label: Label = %UpgradeSalaryLabel
@onready var wave_requirement_label: Label = %WaveRequirementLabel
@onready var upgrade_button: Button = %UpgradeButton
@onready var hire_button: Button = %HireButton

# === STATE ===
var scientist: Scientist
var is_initialized: bool = false

func _ready():
	# Wait for ScientistManager to be ready
	await get_tree().process_frame

	if not ScientistManager or not ScientistManager.instance:
		push_error("[ScientistCard] ScientistManager not found!")
		return

	# Get scientist instance
	scientist = ScientistManager.instance.get_scientist(scientist_type)

	if not scientist:
		push_error("[ScientistCard] Could not get scientist for type %d" % scientist_type)
		return

	# Connect signals
	if ScientistManager.instance:
		ScientistManager.instance.scientist_hired.connect(_on_scientist_hired)
		ScientistManager.instance.scientist_upgraded.connect(_on_scientist_upgraded)

	# Connect buttons
	if hire_button:
		hire_button.pressed.connect(_on_hire_pressed)
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_pressed)

	is_initialized = true
	_update_display()

func _process(_delta):
	if is_initialized:
		_update_display()

func _update_display():
	"""Update all UI elements based on current scientist state"""
	if not scientist:
		return

	# Update name and tier
	if scientist_name_label:
		var type_name = scientist.get_type_name().to_upper()
		if scientist.is_hired:
			scientist_name_label.text = "%s - %s" % [type_name, scientist.get_tier_name()]
		else:
			scientist_name_label.text = "%s (Not Hired)" % type_name

	# Update tier display
	if tier_label:
		if scientist.is_hired:
			tier_label.text = "Tier %d/5" % scientist.tier
		else:
			tier_label.text = "Not Hired"

	# Update tier dots (●●●○○)
	if tier_dots_label:
		tier_dots_label.text = _get_tier_dots_string()

	# Update salary
	if salary_label:
		if scientist.is_hired:
			salary_label.text = "Salary: %d gold/wave" % scientist.get_salary()
		else:
			salary_label.text = "Salary: --"

	# Update status
	if status_label:
		if scientist.is_hired:
			status_label.text = "Status: Working"
			status_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		else:
			status_label.text = "Status: Idle"
			status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

	# Update abilities list
	_update_abilities_list()

	# Update upgrade section
	_update_upgrade_section()

func _get_tier_dots_string() -> String:
	"""Generate tier dots visual (●●●○○)"""
	var dots = ""
	for i in range(5):
		if i < scientist.tier:
			dots += "●"
		else:
			dots += "○"
		if i < 4:
			dots += " "
	return dots

func _update_abilities_list():
	"""Update the list of abilities showing which are unlocked"""
	if not abilities_container:
		return

	# Get all abilities for this scientist type
	var abilities = scientist.get_all_abilities()

	# Clear existing labels (except keep them if we already have them)
	while ability_labels.size() < abilities.size():
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 14)
		abilities_container.add_child(label)
		ability_labels.append(label)

	# Update each ability label
	for i in range(abilities.size()):
		var is_unlocked = scientist.is_ability_unlocked(i)
		var ability_text = abilities[i]

		if is_unlocked:
			ability_labels[i].text = "✓ %s" % ability_text
			ability_labels[i].add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		else:
			ability_labels[i].text = "○ %s" % ability_text
			ability_labels[i].add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

func _update_upgrade_section():
	"""Update upgrade/hire section based on current state"""
	if not upgrade_section:
		return

	# Show hire button if not hired
	if hire_button:
		hire_button.visible = not scientist.is_hired

	# Show upgrade section if hired
	if upgrade_section:
		upgrade_section.visible = scientist.is_hired

	if not scientist.is_hired:
		# Update hire button
		if hire_button:
			var hire_cost = scientist.get_upgrade_cost()  # Tier 1 cost
			hire_button.text = "HIRE (%d gold)" % hire_cost

			# Check if can afford
			var can_afford = false
			if TreasureVault and TreasureVault.instance:
				can_afford = TreasureVault.instance.get_total_gold() >= hire_cost

			hire_button.disabled = not can_afford
		return

	# Already hired - show upgrade info
	if scientist.tier >= 5:
		# Max tier reached
		if next_tier_label:
			next_tier_label.text = "MAX TIER REACHED"
		if upgrade_button:
			upgrade_button.visible = false
		if new_ability_label:
			new_ability_label.visible = false
		if upgrade_cost_label:
			upgrade_cost_label.visible = false
		if upgrade_salary_label:
			upgrade_salary_label.visible = false
		if wave_requirement_label:
			wave_requirement_label.visible = false
		return

	# Can potentially upgrade
	var next_tier_name = scientist.get_next_tier_name()
	var upgrade_cost = scientist.get_upgrade_cost()
	var next_salary = scientist.get_next_tier_salary()
	var waves_required = scientist.get_waves_required_for_next_tier()
	var current_waves = 0
	if DefenseManager and DefenseManager.instance:
		current_waves = DefenseManager.instance.wave_number

	# Update labels
	if next_tier_label:
		next_tier_label.text = "NEXT: Tier %d - %s" % [scientist.tier + 1, next_tier_name]

	if new_ability_label:
		var abilities = scientist.get_all_abilities()
		var next_ability = abilities[scientist.tier] if scientist.tier < abilities.size() else "???"
		new_ability_label.text = "+ NEW: %s" % next_ability

	if upgrade_cost_label:
		upgrade_cost_label.text = "Cost: %d gold" % upgrade_cost

	if upgrade_salary_label:
		upgrade_salary_label.text = "New Salary: %d gold/wave" % next_salary

	if wave_requirement_label:
		if waves_required > 0:
			wave_requirement_label.text = "Requires: %d waves (%d/%d)" % [waves_required, current_waves, waves_required]
			wave_requirement_label.visible = true
		else:
			wave_requirement_label.visible = false

	# Update upgrade button state
	if upgrade_button:
		upgrade_button.visible = true

		var can_afford = false
		if TreasureVault and TreasureVault.instance:
			can_afford = TreasureVault.instance.get_total_gold() >= upgrade_cost

		var waves_met = current_waves >= waves_required

		if not can_afford:
			upgrade_button.text = "UPGRADE (Need %d gold)" % upgrade_cost
			upgrade_button.disabled = true
		elif not waves_met:
			upgrade_button.text = "UPGRADE (Need %d more waves)" % (waves_required - current_waves)
			upgrade_button.disabled = true
		else:
			upgrade_button.text = "UPGRADE (%d gold)" % upgrade_cost
			upgrade_button.disabled = false

func _on_hire_pressed():
	"""Handle hire button press"""
	if not ScientistManager or not ScientistManager.instance:
		return

	if ScientistManager.instance.hire_scientist(scientist_type):
		print("[ScientistCard] Successfully hired %s!" % scientist.get_type_name())
		# Play hire sound if available
		if AudioManager and AudioManager.instance and AudioManager.instance.has_method("play_button_click"):
			AudioManager.instance.play_button_click()
	else:
		print("[ScientistCard] Failed to hire %s" % scientist.get_type_name())

func _on_upgrade_pressed():
	"""Handle upgrade button press"""
	if not ScientistManager or not ScientistManager.instance:
		return

	if ScientistManager.instance.upgrade_scientist(scientist_type):
		print("[ScientistCard] Successfully upgraded %s to Tier %d!" % [scientist.get_type_name(), scientist.tier])
		# Play upgrade sound if available
		if AudioManager and AudioManager.instance and AudioManager.instance.has_method("play_button_click"):
			AudioManager.instance.play_button_click()
	else:
		print("[ScientistCard] Failed to upgrade %s" % scientist.get_type_name())

func _on_scientist_hired(type: Scientist.Type):
	"""React to scientist being hired"""
	if type == scientist_type:
		_update_display()

func _on_scientist_upgraded(type: Scientist.Type, new_tier: int):
	"""React to scientist being upgraded"""
	if type == scientist_type:
		_update_display()
		print("[ScientistCard] %s upgraded to Tier %d!" % [scientist.get_type_name(), new_tier])
