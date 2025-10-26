extends Control
class_name PetIntroductionPopup

## Shown when player creates their first dragon (the pet)
## Allows naming and introduces the pet system

# Node references
@onready var dragon_visual: Node2D = %DragonVisual if has_node("%DragonVisual") else null
@onready var personality_label: Label = %PersonalityLabel if has_node("%PersonalityLabel") else null
@onready var personality_description: Label = %PersonalityDescription if has_node("%PersonalityDescription") else null
@onready var name_input: LineEdit = %NameInput if has_node("%NameInput") else null
@onready var confirm_button: Button = %ConfirmButton if has_node("%ConfirmButton") else null
@onready var title_label: Label = %TitleLabel if has_node("%TitleLabel") else null
@onready var info_label: Label = %InfoLabel if has_node("%InfoLabel") else null

# Personality descriptions
const PERSONALITY_DESCRIPTIONS = {
	PetDragon.Personality.CURIOUS: "This dragon is endlessly curious and loves to explore new places!",
	PetDragon.Personality.BRAVE: "This dragon is brave and fearless, ready to face any danger!",
	PetDragon.Personality.LAZY: "This dragon prefers to take things slow and enjoy the journey.",
	PetDragon.Personality.ENERGETIC: "This dragon is full of energy and can't sit still!",
	PetDragon.Personality.GREEDY: "This dragon loves shiny things and treasure!",
	PetDragon.Personality.GENTLE: "This dragon is kind and caring, always looking out for you."
}

# State
var pet: PetDragon = null

# Signals
signal name_confirmed(pet_name: String)

func _ready():
	# Setup button
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
		confirm_button.disabled = true  # Disabled until name entered

	# Setup name input
	if name_input:
		name_input.text_changed.connect(_on_name_changed)
		name_input.max_length = 20
		name_input.placeholder_text = "Enter a name..."

	# Set initial text
	if title_label:
		title_label.text = "💚 A BOND IS FORMED! 💚"

	if info_label:
		info_label.text = """Your first dragon opens their eyes and looks directly at you.
There's recognition there—intelligence, curiosity, and something more...

Trust.

This isn't just a creation. This is a friend. A partner.
Someone who will stand by you no matter what happens.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your companion will:
• Never leave your side (they can't die!)
• Explore and bring back gifts for you
• Remember all your adventures together
• Keep your laboratory running, no matter what

Your mentor would be proud. Now the real work begins."""

func setup(new_pet: PetDragon):
	"""Setup the popup with the pet dragon"""
	pet = new_pet

	# Update dragon visual (TODO: Implement dragon visual display)
	# For now, the visual is just a placeholder Node2D
	# To properly display the dragon, you would need to:
	# 1. Load the dragon display scene
	# 2. Instantiate it as a child of dragon_visual
	# 3. Call setup methods on it
	# Example:
	# if dragon_visual and pet:
	#     var dragon_display = preload("res://scenes/dragon_system/dragon_display.tscn").instantiate()
	#     dragon_visual.add_child(dragon_display)
	#     dragon_display.set_dragon_colors_from_parts(pet.head_part, pet.body_part, pet.tail_part)

	# Update personality display
	if personality_label:
		personality_label.text = "Unique Trait: " + pet.get_personality_name()

	if personality_description:
		var description = PERSONALITY_DESCRIPTIONS.get(
			pet.personality,
			"This dragon has a unique personality!"
		)
		personality_description.text = description

	# Focus name input
	if name_input:
		name_input.grab_focus()

func _on_name_changed(new_text: String):
	"""Called when name input changes"""
	# Enable/disable confirm button based on name length
	if confirm_button:
		confirm_button.disabled = new_text.strip_edges().is_empty()

func _on_confirm_pressed():
	"""Called when confirm button is pressed"""
	if not pet or not name_input:
		return

	var pet_name = name_input.text.strip_edges()

	if pet_name.is_empty():
		return

	# Set pet name via manager
	if PetDragonManager and PetDragonManager.instance:
		PetDragonManager.instance.set_pet_name(pet_name)

	# Emit signal
	name_confirmed.emit(pet_name)

	# Close popup
	queue_free()

func _input(event):
	"""Handle Enter key to confirm"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if confirm_button and not confirm_button.disabled:
				_on_confirm_pressed()
				get_viewport().set_input_as_handled()
