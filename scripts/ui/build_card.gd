extends PanelContainer
class_name BuildCard

# Card for building a new tower

@onready var cost_label = $VBox/CostLabel
@onready var build_button = $VBox/BuildButton

var tower_index: int = -1
var cost: int = 0
var is_ready: bool = false

signal build_clicked(tower_index: int)

func _ready():
	is_ready = true

	build_button.pressed.connect(_on_build_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Update display if already set up
	if tower_index >= 0:
		_update_display()

func setup(index: int):
	tower_index = index
	cost = DefenseTowerManager.instance.get_next_tower_cost()

	# Only update if _ready has been called
	if is_ready:
		_update_display()

func _update_display():
	if not is_ready or not cost_label or not build_button:
		return

	cost_label.text = "%dg" % cost

	# Check if player can afford
	if not TreasureVault or not TreasureVault.instance:
		return

	if TreasureVault.instance.get_total_gold() < cost:
		build_button.disabled = true
		build_button.modulate = Color(0.6, 0.6, 0.6)
	else:
		build_button.disabled = false
		build_button.modulate = Color(1, 1, 1)

func _on_build_pressed():
	build_clicked.emit(tower_index)

func _on_mouse_entered():
	# Hover effect
	if not build_button.disabled:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2)

func _on_mouse_exited():
	# Reset scale
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

func refresh():
	_update_display()
