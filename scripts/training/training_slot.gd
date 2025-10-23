extends Resource
class_name TrainingSlot

# Individual training slot that holds one dragon
# Tracks training progress and time

@export var slot_id: int = 0
@export var is_unlocked: bool = false
@export var assigned_dragon_id: String = ""  # Reference to dragon by ID
@export var training_start_time: int = 0  # Unix timestamp
@export var training_duration: int = 0    # Total seconds needed

# Reference to actual dragon (not saved, resolved at runtime)
var assigned_dragon: Dragon = null

func is_occupied() -> bool:
	return assigned_dragon != null

func get_progress() -> float:
	if not is_occupied():
		return 0.0
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - training_start_time
	return clamp(float(elapsed) / float(training_duration), 0.0, 1.0)

func get_time_remaining() -> int:
	if not is_occupied():
		return 0
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - training_start_time
	var remaining = training_duration - elapsed
	return max(0, remaining)

func is_training_complete() -> bool:
	return is_occupied() and get_time_remaining() <= 0

func assign_dragon(dragon: Dragon, trainer_bonus: bool = false):
	assigned_dragon = dragon
	assigned_dragon_id = dragon.dragon_id
	training_start_time = Time.get_unix_time_from_system()

	# Calculate training duration
	var base_duration = _calculate_training_time(dragon.level)
	training_duration = base_duration if not trainer_bonus else int(base_duration * 0.5)

	# Mark dragon as training
	dragon.set_state(Dragon.DragonState.TRAINING)

func _calculate_training_time(current_level: int) -> int:
	# Base: 2 hours for Lv1→2, scales by 1.5x per level
	var base_seconds = 7200  # 2 hours
	return int(base_seconds * pow(1.5, current_level - 1))

func remove_dragon() -> Dragon:
	var dragon = assigned_dragon
	if dragon:
		dragon.set_state(Dragon.DragonState.IDLE)
	assigned_dragon = null
	assigned_dragon_id = ""
	training_start_time = 0
	training_duration = 0
	return dragon

func collect_trained_dragon() -> Dragon:
	if not is_training_complete():
		return null

	var dragon = assigned_dragon

	# Level up the dragon
	dragon.level += 1
	dragon.calculate_stats()  # Recalculate with new level
	dragon.set_state(Dragon.DragonState.IDLE)

	assigned_dragon = null
	assigned_dragon_id = ""
	training_start_time = 0
	training_duration = 0

	return dragon

func to_dict() -> Dictionary:
	"""Serialize for save system"""
	return {
		"slot_id": slot_id,
		"is_unlocked": is_unlocked,
		"assigned_dragon_id": assigned_dragon_id,
		"training_start_time": training_start_time,
		"training_duration": training_duration
	}

func from_dict(data: Dictionary):
	"""Restore from save system"""
	slot_id = data.get("slot_id", 0)
	is_unlocked = data.get("is_unlocked", false)
	assigned_dragon_id = data.get("assigned_dragon_id", "")
	training_start_time = data.get("training_start_time", 0)
	training_duration = data.get("training_duration", 0)
	# Note: assigned_dragon reference will be resolved by TrainingManager