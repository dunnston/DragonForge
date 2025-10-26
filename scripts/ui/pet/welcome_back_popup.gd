extends Control
class_name WelcomeBackPopup

## Shown when player returns after being offline
## Displays what the pet accomplished while away

# Node references
@onready var time_away_label: Label = %TimeAwayLabel if has_node("%TimeAwayLabel") else null
@onready var pet_name_label: Label = %PetNameLabel if has_node("%PetNameLabel") else null
@onready var results_container: VBoxContainer = %ResultsContainer if has_node("%ResultsContainer") else null
@onready var dialogue_label: Label = %DialogueLabel if has_node("%DialogueLabel") else null
@onready var story_label: Label = %StoryLabel if has_node("%StoryLabel") else null
@onready var collect_button: Button = %CollectButton if has_node("%CollectButton") else null
@onready var pet_button: Button = %PetButton if has_node("%PetButton") else null
@onready var dragon_visual: Control = %DragonVisual if has_node("%DragonVisual") else null

# State
var results: Dictionary = {}
var seconds_offline: int = 0
var pet: PetDragon = null

# Signals
signal rewards_collected()

func _ready():
	# This popup should work even when game is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Setup buttons
	if collect_button:
		collect_button.pressed.connect(_on_collect_pressed)

	if pet_button:
		pet_button.pressed.connect(_on_pet_pressed)

func setup(offline_results: Dictionary, time_offline: int):
	"""Setup popup with offline results"""
	results = offline_results
	seconds_offline = time_offline

	# Get pet from manager
	if PetDragonManager and PetDragonManager.instance:
		pet = PetDragonManager.instance.get_pet_dragon()

	# Update display
	_update_display()

	# Pause the game while showing popup
	get_tree().paused = true

	# Hide the pet walking character (the dragon at bottom of screen)
	_hide_pet_walking_character()

	# Show the popup!
	visible = true

func _update_display():
	"""Update all UI elements"""
	# Update time away with better formatting
	if time_away_label:
		var hours = seconds_offline / 3600
		var minutes = (seconds_offline % 3600) / 60
		var seconds = seconds_offline % 60

		if hours > 0:
			time_away_label.text = "You were away for %d hour(s) and %d minute(s)" % [hours, minutes]
		elif minutes > 0:
			time_away_label.text = "You were away for %d minute(s)" % minutes
		else:
			time_away_label.text = "You were away for %d second(s)" % seconds

	# Update pet name
	if pet_name_label and pet:
		pet_name_label.text = "%s kept working while you were away!" % pet.dragon_name

	# Setup dragon animation
	_setup_dragon_animation()

	# Update dialogue with personality-based message
	if dialogue_label and pet:
		dialogue_label.text = _get_personality_welcome_message()

	# Update story with random return message
	if story_label:
		story_label.text = _get_random_return_story()

	# Hide pet button (not needed here)
	if pet_button:
		pet_button.visible = false

	# Populate results
	_populate_results()

	# Update button text if no rewards
	_update_button_state()

func _populate_results():
	"""Populate results list"""
	if not results_container:
		return

	# Clear existing children
	for child in results_container.get_children():
		child.queue_free()

	# Add result entries
	if results.has("num_expeditions"):
		_add_result_entry("Completed %d expeditions" % results["num_expeditions"])

	if results.has("gold"):
		_add_result_entry("Earned %d gold" % results["gold"])

	if results.has("parts"):
		_add_result_entry("Found %d dragon parts" % results["parts"])

	if results.has("levels_gained") and results["levels_gained"] > 0:
		_add_result_entry("Gained %d levels!" % results["levels_gained"])

	if results.has("gifts_found") and results["gifts_found"] > 0:
		_add_result_entry("Brought back %d gifts" % results["gifts_found"])

func _add_result_entry(text: String):
	"""Add a result entry to the list"""
	var label = Label.new()
	label.text = "• " + text
	label.add_theme_font_size_override("font_size", 16)
	results_container.add_child(label)

func _on_collect_pressed():
	"""Collect the rewards and close popup"""
	# Rewards are already applied by PetDragonManager
	# This button just acknowledges them

	rewards_collected.emit()

	# Unpause the game
	get_tree().paused = false

	# Show the pet walking character again
	_show_pet_walking_character()

	# Close popup
	queue_free()

func _on_pet_pressed():
	"""Pet the dragon from welcome back screen"""
	if pet and pet.can_pet():
		pet.pet()

		# Update dialogue
		if dialogue_label:
			dialogue_label.text = pet.get_random_dialogue()

		# Disable button
		if pet_button:
			pet_button.disabled = true
			pet_button.text = "❤️ Petted!"

func _get_personality_welcome_message() -> String:
	"""Get personality-specific welcome back message"""
	if not pet:
		return "Welcome back!"

	match pet.personality:
		PetDragon.Personality.CURIOUS:
			return "Welcome back! I explored SO many places while you were gone!"
		PetDragon.Personality.BRAVE:
			return "You're back! I handled everything while you were away!"
		PetDragon.Personality.LAZY:
			return "Oh, you're back... I was just resting between expeditions..."
		PetDragon.Personality.ENERGETIC:
			return "You're back! You're back! I went on so many adventures!"
		PetDragon.Personality.GREEDY:
			return "Look at all the treasure I found for us!"
		PetDragon.Personality.GENTLE:
			return "Welcome back! I missed you so much..."
		_:
			return "Welcome back!"

func _setup_dragon_animation():
	"""Setup the happy dragon animation"""
	if not dragon_visual:
		return

	# Create AnimatedSprite2D if it doesn't exist
	var animated_sprite = dragon_visual.get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.name = "AnimatedSprite2D"
		animated_sprite.centered = true  # Ensure sprite is centered on its position
		dragon_visual.add_child(animated_sprite)

	# Position at center of Control parent (120x120)
	animated_sprite.position = Vector2(60, 60)

	# Load the sprite frames
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("happy")

	# Load the happy dragon sprite sheet
	var texture = load("res://assets/sprites/happy-dragon.png")
	if texture:
		# The sprite sheet has 6 columns and 6 rows (36 frames total)
		var frame_width = texture.get_width() / 6
		var frame_height = texture.get_height() / 6

		# Add frames (using all 36 frames for smooth animation)
		for row in range(6):
			for col in range(6):
				var atlas = AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
				sprite_frames.add_frame("happy", atlas)

		# Set animation speed
		sprite_frames.set_animation_speed("happy", 12.0)
		sprite_frames.set_animation_loop("happy", true)

		# Apply to sprite
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.animation = "happy"
		animated_sprite.centered = true  # Ensure centered
		animated_sprite.play()

		# Scale to reasonable size
		animated_sprite.scale = Vector2(0.6, 0.6)

		# Ensure positioned at center (120x120 Control)
		animated_sprite.position = Vector2(60, 60)

func _update_button_state():
	"""Update collect button based on rewards"""
	if not collect_button:
		return

	# Check if there are any rewards
	var has_rewards = false
	if results.has("num_expeditions") and results["num_expeditions"] > 0:
		has_rewards = true
	elif results.has("gold") and results["gold"] > 0:
		has_rewards = true
	elif results.has("parts") and results["parts"] > 0:
		has_rewards = true

	if has_rewards:
		collect_button.text = "Collect Rewards"
	else:
		collect_button.text = "Okay"

func _hide_pet_walking_character():
	"""Hide the pet walking character at bottom of screen"""
	var pet_character = get_tree().root.find_child("PetWalkingCharacter", true, false)
	if pet_character:
		pet_character.visible = false

func _show_pet_walking_character():
	"""Show the pet walking character at bottom of screen"""
	var pet_character = get_tree().root.find_child("PetWalkingCharacter", true, false)
	if pet_character:
		pet_character.visible = true

func _get_random_return_story() -> String:
	"""Load and return a random story from return_messages.md"""
	var pet_name = pet.dragon_name if pet else "Your dragon"
	var file_path = "res://docs/return_messages.md"

	# Check if file exists
	if not FileAccess.file_exists(file_path):
		return "%s had an adventure while you were away!" % pet_name

	# Read the file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return "%s had an adventure while you were away!" % pet_name

	var messages: Array[String] = []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		# Skip empty lines and lines that are just headers/categories
		if line.length() > 0 and not line.ends_with(":") and not line.begins_with("#"):
			# Remove quotes if present
			if line.begins_with("\"") and line.ends_with("\""):
				line = line.substr(1, line.length() - 2)
			# Replace "Your dragon" with the pet's actual name
			line = line.replace("Your dragon", pet_name)
			messages.append(line)

	file.close()

	# Return a random message
	if messages.size() > 0:
		return messages.pick_random()
	else:
		return "%s had an adventure while you were away!" % pet_name
