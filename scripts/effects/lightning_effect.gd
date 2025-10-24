extends Control
class_name LightningEffect

# Lightning visual effect for dragon creation
# Creates random lightning bolts across the screen during animation

var lightning_lines: Array[Line2D] = []
var lightning_timer: Timer
var flash_timer: Timer
var is_active: bool = false

#Custom colors for this animation
var colors: Array[Color] = []


# Settings
const LIGHTNING_COUNT: int = 8  # Number of simultaneous lightning bolts
const BOLT_SEGMENTS: int = 12   # Segments per bolt
const LIGHTNING_WIDTH: float = 3.0
const FLASH_INTERVAL: float = 0.15  # Seconds between flashes
const BOLT_OFFSET: float = 30.0  # Random offset for jagged effect

func _ready():
	# Set to full screen size
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse events

	# Create lightning timer
	lightning_timer = Timer.new()
	lightning_timer.wait_time = FLASH_INTERVAL
	lightning_timer.timeout.connect(_on_lightning_timer_timeout)
	add_child(lightning_timer)

	# Create flash timer for short duration flashes
	flash_timer = Timer.new()
	flash_timer.one_shot = true
	flash_timer.wait_time = 0.05  # Very short flash duration
	flash_timer.timeout.connect(_hide_lightning)
	add_child(flash_timer)

func start_effect(custom_colors: Array = []):
	"""Start the lightning effect"""
	is_active = true
	visible = true
	colors = custom_colors.duplicate() if not custom_colors.is_empty() else []
	lightning_timer.start()
	_create_lightning_flash()

func stop_effect():
	"""Stop the lightning effect"""
	is_active = false
	lightning_timer.stop()
	flash_timer.stop()
	_clear_lightning()
	visible = false

func _on_lightning_timer_timeout():
	"""Create a new lightning flash"""
	if is_active:
		_create_lightning_flash()

func _create_lightning_flash():
	"""Create random lightning bolts across the screen"""
	_clear_lightning()

	var screen_size = get_viewport_rect().size

	# Create multiple lightning bolts
	for i in LIGHTNING_COUNT:
		var line = Line2D.new()
		line.width = LIGHTNING_WIDTH
		if not colors.is_empty():
			line.default_color = colors[randi() % colors.size()]
		else:
			line.default_color = Color(0.8 + randf() * 0.2, 0.9 + randf() * 0.1, 1.0, 0.9)
		line.antialiased = true

		# Random start position at top of screen
		var start_x = randf() * screen_size.x
		var start_y = randf() * screen_size.y * 0.2  # Top 20% of screen

		# Random end position
		var end_x = start_x + (randf() - 0.5) * 200.0
		var end_y = screen_size.y * (0.3 + randf() * 0.5)  # 30-80% down the screen

		# Create jagged lightning bolt
		var current_pos = Vector2(start_x, start_y)
		var target_pos = Vector2(end_x, end_y)

		line.add_point(current_pos)

		# Add intermediate segments with random offsets
		for segment in range(BOLT_SEGMENTS):
			var progress = (segment + 1) / float(BOLT_SEGMENTS)
			var next_pos = current_pos.lerp(target_pos, 1.0 / (BOLT_SEGMENTS - segment))

			# Add random perpendicular offset for jagged effect
			var offset = Vector2(
				(randf() - 0.5) * BOLT_OFFSET,
				(randf() - 0.5) * BOLT_OFFSET * 0.5
			)
			next_pos += offset

			line.add_point(next_pos)
			current_pos = next_pos

		add_child(line)
		lightning_lines.append(line)

	# Start flash timer to hide lightning shortly
	flash_timer.start()

func _hide_lightning():
	"""Hide the lightning (called by flash timer)"""
	_clear_lightning()

func _clear_lightning():
	"""Remove all lightning lines"""
	for line in lightning_lines:
		if line:
			line.queue_free()
	lightning_lines.clear()

func _exit_tree():
	"""Cleanup when removed from tree"""
	stop_effect()
