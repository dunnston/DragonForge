# Notification - Data structure for queued notifications
# Represents a single notification that will be shown to the player
class_name Notification extends Resource

# Notification type identifier (e.g., "dragon_death", "wave_complete", "exploration_complete")
@export var type: String = ""

# Display title for the notification
@export var title: String = ""

# All data needed to populate the popup (dragon, rewards, etc.)
@export var data: Dictionary = {}

# The popup scene to instantiate for this notification
@export var popup_scene: PackedScene

# When this notification was queued (unix timestamp)
@export var timestamp: float = 0.0

# Context for batching related notifications (e.g., "wave_5", "exploration_batch")
@export var context: String = ""

# Whether this notification can be batched with others of the same type/context
@export var can_batch: bool = false

# Priority level (higher = shows first, 0 = normal FIFO order)
@export var priority: int = 0

func _init(
	p_type: String = "",
	p_title: String = "",
	p_data: Dictionary = {},
	p_popup_scene: PackedScene = null,
	p_context: String = "",
	p_can_batch: bool = false,
	p_priority: int = 0
):
	type = p_type
	title = p_title
	data = p_data
	popup_scene = p_popup_scene
	context = p_context
	can_batch = p_can_batch
	priority = p_priority
	timestamp = Time.get_unix_time_from_system()

func _to_string() -> String:
	return "[Notification type=%s, title=%s, context=%s, can_batch=%s]" % [type, title, context, can_batch]
