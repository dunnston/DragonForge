extends Control
class_name PetStatusWidget

## Always-visible widget showing pet status in HUD

# Node references
@onready var portrait: TextureRect = %Portrait if has_node("%Portrait") else null
@onready var name_level_label: Label = %NameLevelLabel if has_node("%NameLevelLabel") else null
@onready var affection_label: Label = %AffectionLabel if has_node("%AffectionLabel") else null
@onready var status_label: Label = %StatusLabel if has_node("%StatusLabel") else null
@onready var view_button: Button = %ViewButton if has_node("%ViewButton") else null

# State
var pet: PetDragon = null
var update_timer: Timer

# Signal
signal view_pressed()

func _ready():
	# Setup view button
	if view_button:
		view_button.pressed.connect(_on_view_pressed)

	# Setup update timer
	update_timer = Timer.new()
	update_timer.wait_time = 1.0
	update_timer.timeout.connect(_update_status)
	add_child(update_timer)
	update_timer.start()

	# Load pet from manager
	if PetDragonManager and PetDragonManager.instance:
		pet = PetDragonManager.instance.get_pet_dragon()
		if pet:
			_update_status()
		else:
			visible = false

func setup(new_pet: PetDragon):
	"""Setup widget with pet dragon"""
	pet = new_pet
	visible = pet != null
	_update_status()

func _update_status():
	"""Update all status displays"""
	if not pet:
		visible = false
		return

	visible = true

	# Update name and level
	if name_level_label:
		name_level_label.text = "%s Lv.%d" % [pet.dragon_name, pet.level]

	# Update affection hearts
	if affection_label:
		var hearts = _get_affection_hearts(pet.affection)
		affection_label.text = hearts

	# Update status
	if status_label:
		if pet.current_state == Dragon.DragonState.EXPLORING:
			var current_time = Time.get_unix_time_from_system()
			var elapsed = current_time - pet.exploration_start_time
			var remaining = pet.exploration_duration - elapsed

			if remaining > 0:
				var minutes = int(remaining / 60)
				var seconds = int(remaining) % 60
				status_label.text = "Exploring (%d:%02d)" % [minutes, seconds]
			else:
				status_label.text = "Returning..."
		else:
			status_label.text = pet.get_status_text()

func _get_affection_hearts(affection: int) -> String:
	"""Convert affection to heart string (compact - only 3 hearts)"""
	var filled = min(3, int(affection / 33.0))  # 0-3 hearts (0-32=0, 33-66=1, 67-99=2, 100=3)
	var empty = 3 - filled
	return "❤️".repeat(filled) + "🤍".repeat(empty)

func _on_view_pressed():
	"""Open pet interaction UI"""
	view_pressed.emit()

	# Create and show PetInteractionUI
	var pet_ui_scene = load("res://scenes/ui/pet/pet_interaction_ui.tscn")
	if pet_ui_scene:
		var pet_ui = pet_ui_scene.instantiate()
		get_tree().root.add_child(pet_ui)
	else:
		push_warning("[PetStatusWidget] pet_interaction_ui.tscn not found!")
