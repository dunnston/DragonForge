extends PanelContainer
class_name TrainingExpansionCard

# Card for expanding training slots (unlocking new slots)

@onready var cost_label = $VBox/CostLabel
@onready var expand_button = $VBox/ExpandButton
@onready var icon_label = $VBox/IconLabel

var slot_id: int
var cost: int
var is_ready: bool = false

signal expand_clicked(slot_id: int)

func _ready():
	is_ready = true

	if expand_button:
		expand_button.pressed.connect(_on_expand_button_pressed)

	# Make card clickable
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Update display if already setup
	if cost_label:
		_update_display()

func setup(expansion_slot_id: int, expansion_cost: int):
	slot_id = expansion_slot_id
	cost = expansion_cost

	if is_ready:
		_update_display()

func _update_display():
	if not is_ready:
		return

	if cost_label:
		cost_label.text = "Cost: %dg" % cost

	if icon_label:
		icon_label.text = "+"

	if expand_button:
		expand_button.text = "EXPAND SLOT"

		# Check if player can afford
		if TreasureVault and TreasureVault.instance:
			if TreasureVault.instance.get_total_gold() < cost:
				expand_button.disabled = true
				expand_button.modulate = Color(0.5, 0.5, 0.5)
			else:
				expand_button.disabled = false
				expand_button.modulate = Color(1, 1, 1)

func _on_expand_button_pressed():
	expand_clicked.emit(slot_id)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Only emit if we can afford it
			if expand_button and not expand_button.disabled:
				expand_clicked.emit(slot_id)

func _on_mouse_entered():
	# Hover effect (only if affordable)
	if expand_button and not expand_button.disabled:
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

# Public method to refresh display (e.g., when gold changes)
func refresh():
	_update_display()
