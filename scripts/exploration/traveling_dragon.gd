extends Node2D
class_name TravelingDragon

# Visual components
@onready var dragon_sprite: AnimatedSprite2D = $DragonSprite
@onready var name_label: Label = $NameLabel
@onready var progress_bar: ProgressBar = $ProgressBar

# Data
var dragon_data: Dictionary  # Contains dragon info (id, name, level, element)
var destination_key: String
var start_position: Vector2  # Where the dragon starts the journey
var end_position: Vector2  # Where the dragon travels to
var start_time: int  # Unix timestamp
var duration_seconds: int
var is_outbound: bool = true  # true = going to end, false = returning to start

# Tween references
var travel_tween: Tween
var return_tween: Tween

# Signals
signal exploration_complete(dragon_data: Dictionary)
signal arrived_at_destination

func _ready():
	# Initial setup
	if name_label:
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if progress_bar:
		progress_bar.max_value = 100
		progress_bar.value = 0

func setup(dragon: Dictionary, dest_key: String, start_pos: Vector2, end_pos: Vector2, duration_mins: int) -> void:
	"""Initialize traveling dragon on the map with round-trip journey"""
	dragon_data = dragon
	destination_key = dest_key
	start_position = start_pos
	end_position = end_pos
	start_time = Time.get_unix_time_from_system()

	# Convert minutes to seconds
	duration_seconds = duration_mins * 60
	print("[TravelingDragon] Using %d seconds (%d minutes)" % [duration_seconds, duration_mins])

	# Set position at start point
	position = start_position
	print("[TravelingDragon] Starting at position: %v" % start_position)
	print("[TravelingDragon] Will travel to: %v" % end_position)

	# Set sprite appearance based on element
	if dragon_sprite:
		_setup_sprite_appearance()

	# Set name label
	if name_label:
		name_label.text = dragon.get("name", "Dragon")

	# Start round-trip journey animation (start -> end -> start)
	call_deferred("_animate_round_trip")

func _setup_sprite_appearance() -> void:
	"""Set sprite color based on dragon element and setup animation"""
	var element = dragon_data.get("element", "Fire")
	var color: Color

	match element:
		"Fire":
			color = Color(1.0, 0.33, 0.0)  # Orange-red
		"Ice":
			color = Color(0.2, 0.8, 1.0)  # Cyan
		"Lightning":
			color = Color(1.0, 1.0, 0.2)  # Yellow
		"Nature":
			color = Color(0.2, 1.0, 0.2)  # Green
		"Shadow":
			color = Color(0.6, 0.2, 0.8)  # Purple
		_:
			color = Color(1.0, 1.0, 1.0)  # White default

	# Apply color modulation to the animated sprite
	dragon_sprite.modulate = color

	# Create sprite frames if not already set
	if not dragon_sprite.sprite_frames:
		_create_sprite_frames()

	# Start playing the flight animation
	dragon_sprite.play("fly")

func _create_sprite_frames() -> void:
	"""Create SpriteFrames from the sprite sheet (6x6 grid = 36 frames)"""
	var sprite_frames = SpriteFrames.new()

	# Load the sprite sheet texture
	var texture = load("res://assets/sprites/Flying-Red-Dragon.png") as Texture2D
	if not texture:
		push_error("[TravelingDragon] Could not load dragon sprite sheet!")
		return

	# Create animation
	sprite_frames.add_animation("fly")
	sprite_frames.set_animation_loop("fly", true)
	sprite_frames.set_animation_speed("fly", 12.0)  # 12 FPS for smooth flight

	# Calculate frame size (6x6 grid in the sprite sheet)
	var frame_width = texture.get_width() / 6
	var frame_height = texture.get_height() / 6

	# Extract each frame from the sprite sheet
	for row in range(6):
		for col in range(6):
			var atlas = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
			sprite_frames.add_frame("fly", atlas)

	dragon_sprite.sprite_frames = sprite_frames

func _animate_round_trip() -> void:
	"""Animate a round trip: start -> end -> start, timed to complete when exploration ends"""
	print("[TravelingDragon] _animate_round_trip() called!")
	print("[TravelingDragon] Current position: %v" % position)
	print("[TravelingDragon] Start position: %v" % start_position)
	print("[TravelingDragon] End position: %v" % end_position)
	print("[TravelingDragon] Duration: %d seconds" % duration_seconds)

	if travel_tween:
		travel_tween.kill()

	travel_tween = create_tween()
	travel_tween.set_trans(Tween.TRANS_CUBIC)
	travel_tween.set_ease(Tween.EASE_IN_OUT)

	# Split exploration duration in half: half for outbound, half for return
	var half_duration = duration_seconds / 2.0
	print("[TravelingDragon] Half duration: %f seconds" % half_duration)

	# Outbound journey: start -> end
	travel_tween.tween_property(self, "position", end_position, half_duration)
	travel_tween.tween_callback(_on_reached_destination)

	# Return journey: end -> start
	travel_tween.tween_property(self, "position", start_position, half_duration)
	travel_tween.tween_callback(_on_returned_to_start)

	print("[TravelingDragon] %s started round-trip journey to %s (%d seconds total)" % [
		dragon_data.get("name", "Dragon"),
		destination_key,
		duration_seconds
	])
	print("[TravelingDragon] Tween created and playing!")

func _on_reached_destination() -> void:
	"""Called when dragon reaches the end point (halfway through exploration)"""
	is_outbound = false
	print("[TravelingDragon] %s reached %s" % [dragon_data.get("name", "Dragon"), destination_key])
	arrived_at_destination.emit()

func _on_returned_to_start() -> void:
	"""Called when dragon returns to start point (exploration complete)"""
	print("[TravelingDragon] %s returned to start point" % dragon_data.get("name", "Dragon"))
	exploration_complete.emit(dragon_data)

	# Clean up after a brief moment
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _process(_delta: float) -> void:
	"""Update progress bar and sprite rotation"""
	# Update progress bar
	var progress = get_progress()
	if progress_bar:
		progress_bar.value = progress * 100

	# Rotate sprite to face movement direction
	if travel_tween and travel_tween.is_running() and dragon_sprite:
		var direction: Vector2
		if is_outbound:
			# Going from start to end
			direction = (end_position - start_position).normalized()
		else:
			# Returning from end to start
			direction = (start_position - end_position).normalized()

		# Rotate sprite to face the direction of travel
		# Add PI/2 offset because sprite faces up in the sprite sheet
		var angle = direction.angle() + PI / 2
		dragon_sprite.rotation = angle

func get_progress() -> float:
	"""Return 0.0 to 1.0 based on elapsed time"""
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - start_time
	var progress = float(elapsed) / float(duration_seconds)
	return clamp(progress, 0.0, 1.0)

func get_time_remaining() -> int:
	"""Return seconds until exploration completes"""
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - start_time
	var remaining = duration_seconds - elapsed
	return max(0, remaining)

func get_time_remaining_formatted() -> String:
	"""Return formatted time remaining (e.g., '15:30')"""
	var seconds = get_time_remaining()
	var mins = seconds / 60
	var secs = seconds % 60
	return "%02d:%02d" % [mins, secs]

func update_timing(new_start_time: float, new_duration_seconds: int) -> void:
	"""Update the exploration timing when Energy Tonic is consumed"""
	print("[TravelingDragon] Updating timing for %s:" % dragon_data.get("name", "Dragon"))
	print("  Old: start_time=%d, duration=%d" % [start_time, duration_seconds])
	print("  New: start_time=%d, duration=%d" % [new_start_time, new_duration_seconds])

	start_time = new_start_time
	duration_seconds = new_duration_seconds

	# Restart the animation with new timing
	_animate_round_trip()
