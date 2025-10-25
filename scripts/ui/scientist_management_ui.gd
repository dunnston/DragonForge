extends Control

# Scientist Management UI - Full Screen Management Interface
# Displays all 3 scientist cards and overall financial information

# === SIGNALS ===
signal back_to_factory_requested

# === UI REFERENCES ===
@onready var stitcher_card: Control = %StitcherCard
@onready var caretaker_card: Control = %CaretakerCard
@onready var trainer_card: Control = %TrainerCard

@onready var total_salary_label: Label = %TotalSalaryLabel
@onready var next_payment_label: Label = %NextPaymentLabel
@onready var treasury_label: Label = %TreasuryLabel
@onready var waves_affordable_label: Label = %WavesAffordableLabel

@onready var close_button: Button = %CloseButton

func _ready():
	# Make this a full-screen overlay
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Setup scientist cards with their types
	if stitcher_card:
		stitcher_card.scientist_type = Scientist.Type.STITCHER
	if caretaker_card:
		caretaker_card.scientist_type = Scientist.Type.CARETAKER
	if trainer_card:
		trainer_card.scientist_type = Scientist.Type.TRAINER

	print("[ScientistManagementUI] Initialized")

func _process(_delta):
	_update_footer()

func _update_footer():
	"""Update footer with financial information"""
	if not ScientistManager or not ScientistManager.instance:
		return

	# Total salaries
	var total_salary = ScientistManager.instance.get_total_salary()
	if total_salary_label:
		total_salary_label.text = "Total Salaries: %d gold/wave" % total_salary

	# Next payment info
	if next_payment_label:
		var next_wave = 1
		var time_until_wave = 0.0

		if DefenseManager and DefenseManager.instance:
			next_wave = DefenseManager.instance.wave_number + 1
			time_until_wave = DefenseManager.instance.time_until_next_wave

		var minutes = int(time_until_wave / 60)
		var seconds = int(time_until_wave) % 60

		if time_until_wave > 0:
			next_payment_label.text = "Next Payment: Wave %d (in %d:%02d)" % [next_wave, minutes, seconds]
		else:
			next_payment_label.text = "Next Payment: Wave %d" % next_wave

	# Treasury balance
	if treasury_label:
		var gold = 0
		if TreasureVault and TreasureVault.instance:
			gold = TreasureVault.instance.get_total_gold()
		treasury_label.text = "Treasury: %d gold" % gold

	# Waves affordable
	if waves_affordable_label:
		var gold = 0
		if TreasureVault and TreasureVault.instance:
			gold = TreasureVault.instance.get_total_gold()

		var waves_affordable = 0
		if total_salary > 0:
			waves_affordable = int(gold / total_salary)
		else:
			waves_affordable = 999  # No scientists hired

		if waves_affordable > 100:
			waves_affordable_label.text = "Can afford: 100+ waves"
			waves_affordable_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		elif waves_affordable >= 20:
			waves_affordable_label.text = "Can afford: %d waves" % waves_affordable
			waves_affordable_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		elif waves_affordable >= 5:
			waves_affordable_label.text = "Can afford: %d waves" % waves_affordable
			waves_affordable_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
		else:
			waves_affordable_label.text = "Can afford: %d waves ⚠️" % waves_affordable
			waves_affordable_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))

func _on_close_pressed():
	"""Close the management UI"""
	print("[ScientistManagementUI] Closing")
	back_to_factory_requested.emit()
	visible = false
