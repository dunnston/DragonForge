# NotificationQueueManager - Universal notification queue system
# Ensures only ONE notification popup is visible at a time
# All game systems should queue notifications through this manager
extends Node

# === SINGLETON ===
static var instance: NotificationQueueManager

# === QUEUE STATE ===
var notification_queue: Array[Notification] = []
var current_notification_popup: Control = null
var is_showing: bool = false
var notification_layer: CanvasLayer = null  # High-priority layer for notifications

# === BATCHING STATE ===
var pending_batch: Dictionary = {}  # {context: [Notification, Notification, ...]}
var batch_timers: Dictionary = {}  # {context: Timer}

# === CONFIGURATION ===
const BATCH_WINDOW_SECONDS: float = 2.0  # Time window for batching notifications
const MAX_QUEUE_SIZE: int = 50  # Safety limit to prevent queue overflow

# === SIGNALS ===
signal notification_queued(notification: Notification)
signal notification_shown(notification: Notification)
signal notification_closed(notification: Notification)
signal queue_emptied()

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	# Create a high-priority CanvasLayer for notifications to appear on top of everything
	notification_layer = CanvasLayer.new()
	notification_layer.layer = 100  # Very high layer to ensure notifications are always on top
	notification_layer.name = "NotificationLayer"
	add_child(notification_layer)

	print("[NotificationQueue] Initialized - Universal notification system ready (Layer: %d)" % notification_layer.layer)

# === PUBLIC API ===

func queue_notification(notification_data: Dictionary) -> bool:
	"""
	Queue a notification to be shown to the player.

	Args:
		notification_data: Dictionary with keys:
			- type: String (required)
			- title: String (required)
			- data: Dictionary (required)
			- popup_scene: PackedScene (required)
			- context: String (optional, for batching)
			- can_batch: bool (optional, default false)
			- priority: int (optional, default 0)

	Returns:
		true if notification was queued, false if rejected
	"""
	# Debug: Log notification queueing
	var notif_type = notification_data.get("type", "MISSING")
	var notif_title = notification_data.get("title", "MISSING")
	print("[NotificationQueue] Queueing: %s - %s" % [notif_type, notif_title])

	# Validate required fields
	if not notification_data.has("type") or not notification_data.has("popup_scene"):
		push_error("[NotificationQueue] Invalid notification data - missing required fields")
		return false

	# Safety check: Prevent queue overflow
	if notification_queue.size() >= MAX_QUEUE_SIZE:
		push_error("[NotificationQueue] Queue full! Rejecting notification: %s" % notification_data.get("title", "Unknown"))
		return false

	# Create notification object
	var notification = Notification.new(
		notification_data.get("type", ""),
		notification_data.get("title", "Notification"),
		notification_data.get("data", {}),
		notification_data.get("popup_scene"),
		notification_data.get("context", ""),
		notification_data.get("can_batch", false),
		notification_data.get("priority", 0)
	)

	# Handle batching if enabled
	if notification.can_batch and notification.context != "":
		_add_to_batch(notification)
		return true

	# Add to queue
	notification_queue.append(notification)
	notification_queued.emit(notification)

	print("[NotificationQueue] Added to queue (size: %d, showing: %s)" % [notification_queue.size(), is_showing])

	# Show immediately if nothing is currently showing
	if not is_showing:
		_show_next()

	return true

func clear_queue():
	"""Clear all pending notifications"""
	notification_queue.clear()
	pending_batch.clear()

	# Cancel all batch timers
	for timer in batch_timers.values():
		timer.stop()
		timer.queue_free()
	batch_timers.clear()

	print("[NotificationQueue] Queue cleared")

func get_queue_size() -> int:
	"""Get number of notifications waiting in queue"""
	return notification_queue.size()

func is_notification_showing() -> bool:
	"""Check if a notification is currently being displayed"""
	return is_showing

# === PRIVATE METHODS ===

func _show_next():
	"""Show the next notification in the queue"""
	if notification_queue.is_empty():
		is_showing = false
		queue_emptied.emit()
		return

	# SAFETY CHECK: Verify nothing is already showing
	if is_showing:
		push_warning("[NotificationQueue] Attempted to show notification while one is already visible!")
		return

	# SAFETY CHECK: Double-check no popup nodes exist
	var existing_popups = get_tree().get_nodes_in_group("notification_popup")
	if not existing_popups.is_empty():
		push_warning("[NotificationQueue] WARNING: Popup already exists, cleaning up...")
		# Force cleanup
		for popup in existing_popups:
			popup.queue_free()
		# Try again next frame
		await get_tree().process_frame
		return

	# Take first notification from queue
	var notif: Notification = notification_queue.pop_front()

	print("[NotificationQueue] Showing: %s (type: %s, remaining: %d)" %
		[notif.title, notif.type, notification_queue.size()])

	# Instantiate the popup
	if not notif.popup_scene:
		push_error("[NotificationQueue] No popup scene for notification: %s" % notif.title)
		_show_next()  # Skip to next
		return

	current_notification_popup = notif.popup_scene.instantiate()

	if not current_notification_popup:
		push_error("[NotificationQueue] Failed to instantiate popup!")
		_show_next()
		return

	# Add to notification_popup group for safety checks
	current_notification_popup.add_to_group("notification_popup")

	# Add to high-priority CanvasLayer FIRST so _ready() runs and @onready variables are initialized
	# This ensures notifications always appear on top of all other UI (battle scenes, factory, etc.)
	notification_layer.add_child(current_notification_popup)

	# Check if popup has a setup method
	if current_notification_popup.has_method("setup"):
		# Call setup with unpacked arguments based on notification type
		match notif.type:
			"dragon_death", "dragon_death_batch":
				# DragonDeathPopup.setup(dragon, death_cause, recovered_parts)
				var dragon = notif.data.get("dragon")
				var cause = notif.data.get("cause")
				var parts = notif.data.get("recovered_parts", [])
				print("[NotificationQueue] Calling DragonDeathPopup.setup()")
				print("   Dragon: %s" % (dragon.dragon_name if dragon else "NULL"))
				print("   Cause: %s" % cause)
				print("   Parts: %d" % parts.size())
				current_notification_popup.setup(dragon, cause, parts)
				print("[NotificationQueue] Setup complete")
			"exploration_complete":
				# ExplorationReturnPopup.show_return(dragon, rewards)
				if current_notification_popup.has_method("show_return"):
					current_notification_popup.show_return(
						notif.data.get("dragon"),
						notif.data.get("rewards", {})
					)
			"wave_complete", "wave_failed":
				# Simple message popup - pass whole data dictionary
				current_notification_popup.setup(notif.data)
			_:
				# Default: Try to call setup with the whole data dictionary
				current_notification_popup.setup(notif.data)

	# Connect to closed signal (all popups must emit this)
	if current_notification_popup.has_signal("closed"):
		current_notification_popup.closed.connect(_on_notification_closed.bind(notif))
	else:
		push_warning("[NotificationQueue] Popup does not have 'closed' signal: %s" % notif.title)
		# Fallback: Try to find close button
		_setup_fallback_close_detection(current_notification_popup, notif)

	# Mark as showing
	is_showing = true
	notification_shown.emit(notif)

func _on_notification_closed(notif: Notification):
	"""Called when player closes a notification popup"""
	print("[NotificationQueue] Notification closed: %s" % notif.title)

	# Clean up current popup reference
	current_notification_popup = null
	is_showing = false

	notification_closed.emit(notif)

	# Show next notification in queue (if any)
	_show_next()

func _setup_fallback_close_detection(popup: Control, notif: Notification):
	"""Fallback for popups without closed signal - detect when they're freed"""
	popup.tree_exited.connect(func():
		if is_showing and current_notification_popup == popup:
			_on_notification_closed(notif)
	)

# === BATCHING SYSTEM ===

func _add_to_batch(notif: Notification):
	"""Add notification to batch queue with timer"""
	var context = notif.context

	# Initialize batch for this context if needed
	if not pending_batch.has(context):
		pending_batch[context] = []

	# Add to batch
	pending_batch[context].append(notif)

	print("[NotificationQueue] Added to batch '%s' (batch size: %d)" %
		[context, pending_batch[context].size()])

	# Start or reset batch timer
	if batch_timers.has(context):
		# Reset existing timer
		batch_timers[context].start(BATCH_WINDOW_SECONDS)
		print("[NotificationQueue] Reset batch timer for context: %s" % context)
	else:
		# Create new timer
		var timer = Timer.new()
		timer.wait_time = BATCH_WINDOW_SECONDS
		timer.one_shot = true
		timer.timeout.connect(_flush_batch.bind(context))
		add_child(timer)
		timer.start()
		batch_timers[context] = timer
		print("[NotificationQueue] Started batch timer for context: %s (%.1fs)" % [context, BATCH_WINDOW_SECONDS])

func _flush_batch(context: String):
	"""Flush a batch of notifications (create single batched notification)"""
	if not pending_batch.has(context) or pending_batch[context].is_empty():
		return

	var batched_notifications: Array = pending_batch[context]
	var count = batched_notifications.size()

	print("[NotificationQueue] Flushing batch '%s' with %d notifications" % [context, count])

	# If only one notification in batch, just queue it normally
	if count == 1:
		var single_notification: Notification = batched_notifications[0]
		notification_queue.append(single_notification)
		notification_queued.emit(single_notification)
	else:
		# Create batched notification
		var first_notification: Notification = batched_notifications[0]
		var batched_data = {
			"notifications": batched_notifications,
			"count": count,
			"type": first_notification.type
		}

		# Determine batched popup scene based on type
		var batched_popup_scene = _get_batched_popup_scene(first_notification.type)

		var batched_notification = Notification.new(
			first_notification.type + "_batch",
			"%d %s" % [count, first_notification.title],
			batched_data,
			batched_popup_scene,
			context,
			false,  # Already batched, don't batch again
			first_notification.priority
		)

		notification_queue.append(batched_notification)
		notification_queued.emit(batched_notification)

	# Clean up batch
	pending_batch.erase(context)
	if batch_timers.has(context):
		batch_timers[context].queue_free()
		batch_timers.erase(context)

	# Show if nothing is currently showing
	if not is_showing:
		_show_next()

func _get_batched_popup_scene(type: String) -> PackedScene:
	"""Get the appropriate batched popup scene for a notification type"""
	match type:
		"dragon_death":
			# TODO: Create batched death popup scene
			return preload("res://scenes/ui/dragon_death_popup.tscn")  # Fallback to single for now
		_:
			push_warning("[NotificationQueue] No batched popup scene for type: %s" % type)
			return null

func force_flush_all_batches():
	"""Immediately flush all pending batches (for testing or event completion)"""
	print("[NotificationQueue] Force flushing all batches")
	for context in pending_batch.keys():
		_flush_batch(context)

# === DEBUG / TESTING ===

func print_queue_status():
	"""Debug: Print current queue status"""
	print("\n=== NOTIFICATION QUEUE STATUS ===")
	print("Is showing: %s" % is_showing)
	print("Queue size: %d" % notification_queue.size())
	print("Pending batches: %d" % pending_batch.size())

	if not notification_queue.is_empty():
		print("\nQueued notifications:")
		for i in notification_queue.size():
			print("  %d. %s" % [i + 1, notification_queue[i]])

	if not pending_batch.is_empty():
		print("\nPending batches:")
		for context in pending_batch.keys():
			print("  %s: %d notifications" % [context, pending_batch[context].size()])

	print("================================\n")
