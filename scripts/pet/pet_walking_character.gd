extends CharacterBody2D
class_name PetWalkingCharacter

## Wandering pet dragon visual that walks around the main scene
## Click to open interaction UI

# Constants
const WALK_SPEED: float = 40.0  # Base walking speed (slower, more casual pace)
const DIRECTION_CHANGE_INTERVAL: float = 5.0  # Seconds between direction changes
const WALK_ANIMATION_SPEED: float = 6.0  # Frames per second for walking animation (slower to match speed)
const WALK_ANIMATION_FRAMES: int = 6  # Number of frames in walking animation (first row)

# Export for scene setup
@export var viewport_size: Vector2 = Vector2(1920, 1080)  # Configurable viewport size

# Walking boundaries (center panel area, below the animate button)
const WALK_AREA_MIN_X: float = 250.0
const WALK_AREA_MAX_X: float = 1050.0
const WALK_AREA_Y: float = 490.0  # Fixed Y position for horizontal walking

# Node references (assigned in scene or code)
@onready var dragon_visual: Node2D = %DragonVisual if has_node("%DragonVisual") else null
@onready var walking_sprite: Sprite2D = $DragonVisual/WalkingSprite if has_node("DragonVisual/WalkingSprite") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var wander_timer: Timer = $WanderTimer if has_node("WanderTimer") else null
@onready var click_area: Area2D = $ClickArea if has_node("ClickArea") else null
@onready var click_button: Button = $ClickButton if has_node("ClickButton") else null
@onready var mood_indicator: Node2D = $MoodIndicator if has_node("MoodIndicator") else null

# State
var pet: PetDragon = null
var current_direction: Vector2 = Vector2.ZERO
var is_moving: bool = false
var animation_time: float = 0.0
var current_frame: int = 0
var mouse_over: bool = false

# Signals
signal pet_clicked(pet: PetDragon)

func _ready():
	print("[PetWalkingCharacter] _ready() called")

	# Setup wander timer if not in scene
	if not wander_timer:
		wander_timer = Timer.new()
		wander_timer.wait_time = DIRECTION_CHANGE_INTERVAL
		wander_timer.timeout.connect(_on_wander_timer_timeout)
		add_child(wander_timer)
		wander_timer.start()

	# Connect click button (more reliable than Area2D for mouse input)
	if click_button:
		click_button.pressed.connect(_on_pet_clicked)
		click_button.mouse_entered.connect(_on_mouse_entered)
		click_button.mouse_exited.connect(_on_mouse_exited)

		# Disable all visual feedback from the button
		click_button.focus_mode = Control.FOCUS_NONE  # Disable focus
		click_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND  # Show hand cursor

		# Make button completely transparent (no background, border, or focus indicators)
		click_button.add_theme_color_override("font_color", Color.TRANSPARENT)
		click_button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
		click_button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
		click_button.add_theme_color_override("font_focus_color", Color.TRANSPARENT)
		click_button.add_theme_color_override("font_disabled_color", Color.TRANSPARENT)

		print("[PetWalkingCharacter] ClickButton connected")
	else:
		push_error("[PetWalkingCharacter] ClickButton not found!")

	# Start with random direction
	_change_direction()

	# Pet will be set up via setup() call from factory manager
	print("[PetWalkingCharacter] Waiting for setup() call from factory manager")

func setup(new_pet: PetDragon):
	"""Setup the walking character with a pet dragon"""
	pet = new_pet
	print("[PetWalkingCharacter] setup() called with pet: %s" % (pet.dragon_name if pet else "null"))

	# Scale based on level (starts at 0.5, grows to 0.8 at max level)
	if walking_sprite and pet:
		var scale_factor = 0.5 + (pet.level / float(Dragon.MAX_LEVEL)) * 0.3
		walking_sprite.scale = Vector2(scale_factor, scale_factor)

	# Start visible if not exploring
	visible = not _is_exploring()
	print("[PetWalkingCharacter] Pet visible: %s" % visible)

func _process(delta):
	if not pet:
		return

	# Check visibility based on exploration state AND whether factory UI is visible
	# Only show pet if: not exploring AND factory main UI is visible (not on other screens)
	var is_exploring = _is_exploring()
	var is_factory_screen = _is_on_factory_screen()
	var should_be_visible = not is_exploring and is_factory_screen

	if visible != should_be_visible:
		visible = should_be_visible
		if should_be_visible:
			print("[PetWalkingCharacter] Pet returned from exploration, showing character")
			_show_return_effect()
		else:
			if is_exploring:
				print("[PetWalkingCharacter] Pet started exploring, hiding character")
			else:
				print("[PetWalkingCharacter] Switched to different screen, hiding character")

	# Only update animations if visible
	if not visible:
		return

	# Disable click button if any modal is open
	if click_button:
		click_button.disabled = _is_any_modal_open()

	# Update sprite animation
	if is_moving and walking_sprite:
		animation_time += delta * WALK_ANIMATION_SPEED
		current_frame = int(animation_time) % WALK_ANIMATION_FRAMES
		walking_sprite.frame = current_frame
	else:
		# Idle frame (frame 0)
		if walking_sprite:
			walking_sprite.frame = 0
		animation_time = 0.0

	# Update mood indicator
	_update_mood_indicator()

func _physics_process(delta):
	if not is_moving or not visible:
		velocity = Vector2.ZERO
		return

	# Calculate personality-based speed
	var speed_multiplier = _get_speed_multiplier()
	var target_speed = WALK_SPEED * speed_multiplier

	# Apply movement
	velocity = current_direction * target_speed

	# Check boundaries and reverse if needed
	_check_boundaries()

	# Move
	move_and_slide()

	# Update animation state
	_update_animation()

func _change_direction():
	"""Change to a new random direction"""
	# Horizontal movement only (left or right)
	if randf() < 0.5:
		current_direction = Vector2.RIGHT
	else:
		current_direction = Vector2.LEFT

	# Always moving (pet is active)
	is_moving = true

	# Reset timer
	if wander_timer:
		wander_timer.wait_time = randf_range(3.0, 8.0)  # Vary the interval
		wander_timer.start()

func _check_boundaries():
	"""Check if pet is near boundaries and reverse direction if needed"""
	var pos = global_position

	# Check left/right boundaries (horizontal walking area)
	if pos.x <= WALK_AREA_MIN_X:
		current_direction = Vector2.RIGHT  # Turn right
		global_position.x = WALK_AREA_MIN_X
	elif pos.x >= WALK_AREA_MAX_X:
		current_direction = Vector2.LEFT  # Turn left
		global_position.x = WALK_AREA_MAX_X

	# Lock Y position to stay on horizontal line
	global_position.y = WALK_AREA_Y

func _get_speed_multiplier() -> float:
	"""Get speed multiplier based on personality"""
	if not pet:
		return 1.0

	match pet.personality:
		PetDragon.Personality.ENERGETIC:
			return 1.5  # 50% faster
		PetDragon.Personality.LAZY:
			return 0.6  # 40% slower
		_:
			return 1.0

func _is_exploring() -> bool:
	"""Check if pet is currently exploring"""
	if not pet:
		return false
	return pet.current_state == Dragon.DragonState.EXPLORING

func _is_on_factory_screen() -> bool:
	"""Check if we're currently on the factory screen (not defense/training/exploration)"""
	# Walk up the scene tree to find the factory manager's main UI
	var parent = get_parent()
	while parent:
		# Look for the MarginContainer that the factory manager hides when switching screens
		var margin_container = parent.get_node_or_null("MarginContainer")
		if margin_container:
			# If the MarginContainer is visible, we're on the factory screen
			return margin_container.visible
		parent = parent.get_parent()

	# Default to true if we can't find the marker (backward compatibility)
	return true

func _is_any_modal_open() -> bool:
	"""Check if any modal is currently open in the factory manager"""
	# Walk up the scene tree to find the factory manager
	var parent = get_parent()
	if not parent:
		return false

	# Check for common modals
	var inventory_panel = parent.get_node_or_null("InventoryPanel")
	if inventory_panel and inventory_panel.visible:
		return true

	var part_selector = parent.get_node_or_null("PartSelector")
	if part_selector and part_selector.visible:
		return true

	var dragon_details_modal = parent.get_node_or_null("DragonDetailsModal")
	if dragon_details_modal and dragon_details_modal.visible:
		return true

	var dragon_grounds_modal = parent.get_node_or_null("DragonGroundsModal")
	if dragon_grounds_modal and dragon_grounds_modal.visible:
		return true

	var defense_towers_ui = parent.get_node_or_null("DefenseTowersUI")
	if defense_towers_ui and defense_towers_ui.visible:
		return true

	var training_yard_ui = parent.get_node_or_null("TrainingYardUI")
	if training_yard_ui and training_yard_ui.visible:
		return true

	var exploration_map_ui = parent.get_node_or_null("ExplorationMapUI")
	if exploration_map_ui and exploration_map_ui.visible:
		return true

	var scientist_management_ui = parent.get_node_or_null("ScientistManagementUI")
	if scientist_management_ui and scientist_management_ui.visible:
		return true

	var pet_interaction_ui = parent.get_node_or_null("PetInteractionUI")
	if pet_interaction_ui and pet_interaction_ui.visible:
		return true

	var save_exit_popup = parent.get_node_or_null("SaveExitPopup")
	if save_exit_popup and save_exit_popup.visible:
		return true

	return false

func _update_animation():
	"""Update animation based on movement state"""
	# Flip sprite based on direction (sprite faces left by default)
	if walking_sprite and current_direction.x != 0:
		walking_sprite.flip_h = current_direction.x > 0  # Flip when moving right

func _update_mood_indicator():
	"""Update mood indicator based on pet's state"""
	if not mood_indicator or not pet:
		return

	var mood = pet.get_mood_state()

	# This would show different icons/sprites based on mood
	# For now, just toggle visibility
	mood_indicator.visible = (mood == "hungry" or mood == "tired")

	# TODO: Set specific mood icon based on state
	# mood_indicator.set_mood(mood)

func _show_return_effect():
	"""Show sparkle effect when pet returns from exploration"""
	# TODO: Add particle effect
	# var particles = preload("res://scenes/effects/sparkle_effect.tscn").instantiate()
	# add_child(particles)
	pass

# === CLICK HANDLING ===

func _on_click_area_input(_viewport: Node, event: InputEvent, _shape_idx: int):
	"""Handle click on pet"""
	print("[PetWalkingCharacter] Click detected on pet!")
	print("[PetWalkingCharacter] Event type: %s" % event.get_class())

	if event is InputEventMouseButton:
		print("[PetWalkingCharacter] Event is InputEventMouseButton")
		print("[PetWalkingCharacter] Button index: %s (LEFT=%s)" % [event.button_index, MOUSE_BUTTON_LEFT])
		print("[PetWalkingCharacter] Pressed: %s" % event.pressed)

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("[PetWalkingCharacter] Left mouse button pressed on pet!")
			_on_pet_clicked()
		else:
			print("[PetWalkingCharacter] Button check failed!")
	else:
		print("[PetWalkingCharacter] Event is NOT InputEventMouseButton")

func _on_pet_clicked():
	"""Called when pet is clicked"""
	print("[PetWalkingCharacter] _on_pet_clicked called!")
	if pet:
		print("[PetWalkingCharacter] Emitting pet_clicked signal for: %s" % pet.dragon_name)
		pet_clicked.emit(pet)

		# Play happy bounce animation
		if animation_player and animation_player.has_animation("happy_bounce"):
			animation_player.play("happy_bounce")

		# Show dialogue
		print("[PetWalkingCharacter] %s says: %s" % [pet.dragon_name, pet.get_random_dialogue()])

func _on_mouse_entered():
	"""Show hover effect"""
	print("[PetWalkingCharacter] Mouse entered pet area")
	mouse_over = true
	if walking_sprite:
		print("[PetWalkingCharacter] Setting hover brightness")
		walking_sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)  # Much brighter so it's obvious
	else:
		print("[PetWalkingCharacter] ERROR: walking_sprite is null!")

func _on_mouse_exited():
	"""Remove hover effect"""
	print("[PetWalkingCharacter] Mouse exited pet area")
	mouse_over = false
	if walking_sprite:
		walking_sprite.modulate = Color.WHITE

# === TIMER CALLBACK ===

func _on_wander_timer_timeout():
	"""Timer callback to change direction"""
	_change_direction()

# === PUBLIC METHODS ===

func pause_animation():
	"""Pause the walking animation (called when interaction modal opens)"""
	is_moving = false
	if wander_timer:
		wander_timer.stop()
	print("[PetWalkingCharacter] Animation paused")

func resume_animation():
	"""Resume the walking animation (called when interaction modal closes)"""
	is_moving = true
	if wander_timer:
		wander_timer.start()
	print("[PetWalkingCharacter] Animation resumed")

func play_pet_animation():
	"""Play animation when pet is petted"""
	if animation_player and animation_player.has_animation("happy_bounce"):
		animation_player.play("happy_bounce")

func play_feed_animation():
	"""Play animation when pet is fed"""
	if animation_player and animation_player.has_animation("eating"):
		animation_player.play("eating")
	elif animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
