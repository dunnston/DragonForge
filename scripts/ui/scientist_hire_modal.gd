extends AcceptDialog

## Modal dialog for hiring a scientist
## Shows scientist image, description, and costs

signal scientist_hired(scientist_type: Scientist.Type)

@onready var scientist_image: TextureRect = %ScientistImage
@onready var scientist_name_label: Label = %ScientistName
@onready var description_label: Label = %Description
@onready var hire_cost_label: Label = %HireCostLabel
@onready var ongoing_cost_label: Label = %OngoingCostLabel
@onready var warning_label: Label = %WarningLabel

var current_scientist_type: Scientist.Type

func show_for_scientist(scientist_type: Scientist.Type):
	"""Configure and show the modal for a specific scientist"""
	current_scientist_type = scientist_type

	# Load scientist image
	var scientist_name = ScientistManager.instance.get_scientist_name(scientist_type).to_lower()

	# Handle the typo in the filename (sticher instead of stitcher)
	if scientist_name == "stitcher":
		scientist_name = "sticher"

	var image_path = "res://assets/Icons/scientists/" + scientist_name + ".png"

	if ResourceLoader.exists(image_path):
		scientist_image.texture = load(image_path)
	else:
		push_warning("Scientist image not found: " + image_path)

	# Set scientist info
	scientist_name_label.text = ScientistManager.instance.get_scientist_name(scientist_type).to_upper()
	description_label.text = ScientistManager.instance.get_scientist_description(scientist_type)

	# Set costs
	var hire_cost = ScientistManager.instance.get_scientist_hire_cost(scientist_type)
	var ongoing_cost = ScientistManager.instance.get_scientist_ongoing_cost(scientist_type)

	hire_cost_label.text = "Hire Cost: " + str(hire_cost) + " gold"
	ongoing_cost_label.text = "Ongoing: -" + str(ongoing_cost) + " gold/wave"

	# Check if player can afford
	var can_afford = TreasureVault.instance.get_total_gold() >= hire_cost

	if can_afford:
		warning_label.visible = false
		get_ok_button().disabled = false
	else:
		warning_label.visible = true
		warning_label.text = "Not enough gold! (Need " + str(hire_cost) + ", have " + str(TreasureVault.instance.get_total_gold()) + ")"
		get_ok_button().disabled = true

	# Show the modal
	popup_centered()

func _on_confirmed():
	"""Player confirmed hiring the scientist"""
	if ScientistManager.instance.hire_scientist(current_scientist_type):
		scientist_hired.emit(current_scientist_type)

func _on_canceled():
	"""Player canceled hiring"""
	pass
