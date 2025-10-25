extends PanelContainer
class_name TowerCard

# Individual tower card showing health, dragon count, and repair option

@onready var tower_icon = $VBox/TowerIcon
@onready var dragon_visual_container = $VBox/DragonVisualContainer
@onready var dragon_visual = $VBox/DragonVisualContainer/DragonVisual
@onready var dragon_info_panel = $VBox/DragonInfo
@onready var dragon_name_label = $VBox/DragonInfo/HeaderContainer/NameLabel
@onready var remove_dragon_button = $VBox/DragonInfo/HeaderContainer/RemoveButton
@onready var dragon_stats_label = $VBox/DragonInfo/StatsLabel
@onready var no_dragon_label = $VBox/NoDragonLabel
@onready var health_bar = $VBox/HealthContainer/HealthBar
@onready var health_label = $VBox/HealthContainer/HealthLabel
@onready var repair_button = $VBox/RepairButton
@onready var repair_cost_label = $VBox/RepairButton/CostLabel
@onready var rebuild_button = $VBox/RebuildButton
@onready var rebuild_cost_label = $VBox/RebuildButton/CostLabel

var tower: DefenseTower
var tower_index: int = -1
var is_ready: bool = false
var assigned_dragon: Dragon = null

signal repair_clicked(tower_index: int)
signal rebuild_clicked(tower_index: int)
signal card_clicked(tower_index: int)
signal assign_dragon_requested(tower_index: int)

func _ready():
	is_ready = true

	repair_button.pressed.connect(_on_repair_pressed)

	if rebuild_button:
		rebuild_button.pressed.connect(_on_rebuild_pressed)

	if remove_dragon_button:
		remove_dragon_button.pressed.connect(_on_remove_dragon_pressed)

	# Style repair and rebuild buttons
	_style_action_button(repair_button, Color(0.2, 0.6, 0.3))  # Green for repair
	_style_action_button(rebuild_button, Color(0.5, 0.4, 0.2))  # Orange for rebuild

	# Add hover effects
	repair_button.mouse_entered.connect(_on_button_hover.bind(repair_button, true))
	repair_button.mouse_exited.connect(_on_button_hover.bind(repair_button, false))
	rebuild_button.mouse_entered.connect(_on_button_hover.bind(rebuild_button, true))
	rebuild_button.mouse_exited.connect(_on_button_hover.bind(rebuild_button, false))

	# Make card clickable
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Update display if tower data already set
	if tower:
		_update_display()

func setup(tower_data: DefenseTower, index: int):
	tower = tower_data
	tower_index = index

	# Only update if _ready has been called
	if is_ready:
		_update_display()

func _update_display():
	if not tower or not is_ready:
		return

	# Null safety check for nodes
	if not health_bar or not health_label or not repair_button:
		return

	# Update health bar
	var health_percent = tower.get_health_percentage()
	health_bar.value = health_percent * 100
	health_label.text = "%d%%" % (health_percent * 100)

	# Color code health bar
	if health_percent >= 0.7:
		health_bar.modulate = Color(0.2, 0.8, 0.2)  # Green
	elif health_percent >= 0.3:
		health_bar.modulate = Color(0.9, 0.9, 0.2)  # Yellow
	else:
		health_bar.modulate = Color(0.9, 0.2, 0.2)  # Red

	# Check if tower is destroyed
	if tower.is_destroyed():
		modulate = Color(0.5, 0.5, 0.5)  # Gray out
		tower_icon.modulate = Color(0.3, 0.3, 0.3)
		health_bar.modulate = Color(0.5, 0.5, 0.5)
	else:
		modulate = Color(1, 1, 1)
		tower_icon.modulate = Color(1, 1, 1)

	# Update dragon assignment display
	_update_dragon_display()

	# Show/hide repair button (only for damaged but not destroyed towers)
	if tower.needs_repair() and not tower.is_destroyed():
		repair_button.visible = true
		var repair_cost = DefenseTowerManager.instance.get_tower_repair_cost(tower)
		repair_cost_label.text = "REPAIR: %dg" % repair_cost

		# Check if player can afford
		if TreasureVault.instance.get_total_gold() < repair_cost:
			repair_button.disabled = true
			repair_button.modulate = Color(0.5, 0.5, 0.5)
		else:
			repair_button.disabled = false
			repair_button.modulate = Color(1, 1, 1)
	else:
		repair_button.visible = false

	# Show/hide rebuild button (only for destroyed towers)
	if rebuild_button:
		if tower.is_destroyed():
			rebuild_button.visible = true
			rebuild_cost_label.text = "REBUILD: %dg" % DefenseTowerManager.REBUILD_COST

			# Check if player can afford
			if TreasureVault.instance.get_total_gold() < DefenseTowerManager.REBUILD_COST:
				rebuild_button.disabled = true
				rebuild_button.modulate = Color(0.5, 0.5, 0.5)
			else:
				rebuild_button.disabled = false
				rebuild_button.modulate = Color(1, 1, 1)
		else:
			rebuild_button.visible = false

func _update_dragon_display():
	"""Update the display based on assigned dragon"""
	# Get the dragon assigned to this specific tower slot
	assigned_dragon = _get_assigned_dragon()

	if assigned_dragon and not assigned_dragon.is_dead and assigned_dragon.current_health > 0:
		# Show dragon info and visual
		dragon_visual_container.visible = true
		dragon_info_panel.visible = true
		no_dragon_label.visible = false

		# Display dragon visual
		if dragon_visual:
			dragon_visual.set_dragon_colors_from_parts(
				assigned_dragon.head_part,
				assigned_dragon.body_part,
				assigned_dragon.tail_part
			)

		# Display dragon name
		dragon_name_label.text = assigned_dragon.dragon_name

		# Display stats: Health %, Fatigue %, Attack, Defense
		var health_pct = (float(assigned_dragon.current_health) / float(assigned_dragon.get_health())) * 100
		var fatigue_pct = assigned_dragon.fatigue_level * 100

		dragon_stats_label.text = "HP: %.0f%%  Fatigue: %.0f%%\nATK: %d  DEF: %d" % [
			health_pct,
			fatigue_pct,
			assigned_dragon.get_attack(),
			assigned_dragon.get_defense()
		]
	else:
		# No dragon assigned
		dragon_visual_container.visible = false
		dragon_info_panel.visible = false
		no_dragon_label.visible = true

func _get_assigned_dragon() -> Dragon:
	"""Get the dragon assigned to this specific tower"""
	if not DefenseManager or not DefenseManager.instance:
		return null
	
	# Use the new tower-specific assignment system
	return DefenseManager.instance.get_dragon_for_tower(tower_index)

func _on_repair_pressed():
	repair_clicked.emit(tower_index)

func _on_rebuild_pressed():
	rebuild_clicked.emit(tower_index)

func _on_remove_dragon_pressed():
	"""Called when X button is clicked to remove dragon"""
	_unassign_dragon()

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Don't allow clicks on destroyed towers
			if tower and tower.is_destroyed():
				return

			# Check if clicking dragon info area (to unassign) or empty area (to assign)
			if assigned_dragon:
				# Right click to unassign
				if event.button_index == MOUSE_BUTTON_RIGHT:
					_unassign_dragon()
			else:
				# Left click to assign
				assign_dragon_requested.emit(tower_index)

			card_clicked.emit(tower_index)

func _on_mouse_entered():
	# Hover effect
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

func _unassign_dragon():
	"""Unassign the dragon from this tower"""
	if not assigned_dragon:
		return

	if DefenseManager and DefenseManager.instance:
		# Store dragon name before removing (assigned_dragon will become null)
		var dragon_name = assigned_dragon.dragon_name
		# Use tower-specific removal
		DefenseManager.instance.remove_dragon_from_tower(tower_index)
		print("[TowerCard] Unassigned %s from tower %d" % [dragon_name, tower_index])
		refresh()

# Public method to refresh display
func refresh():
	_update_display()

func _style_action_button(button: Button, base_color: Color):
	"""Apply consistent styling to repair/rebuild buttons"""
	if not button:
		return

	# Create normal state style
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = base_color
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = base_color.lightened(0.2)
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4

	# Create hover state style (brighter)
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = base_color.lightened(0.2)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 2
	style_hover.border_color = base_color.lightened(0.4)
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4

	# Create pressed state style (darker)
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = base_color.darkened(0.2)
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_top = 2
	style_pressed.border_width_bottom = 2
	style_pressed.border_color = base_color
	style_pressed.corner_radius_top_left = 4
	style_pressed.corner_radius_top_right = 4
	style_pressed.corner_radius_bottom_left = 4
	style_pressed.corner_radius_bottom_right = 4

	# Create disabled state style (grayed out)
	var style_disabled = StyleBoxFlat.new()
	style_disabled.bg_color = Color(0.3, 0.3, 0.3, 0.5)
	style_disabled.border_width_left = 2
	style_disabled.border_width_right = 2
	style_disabled.border_width_top = 2
	style_disabled.border_width_bottom = 2
	style_disabled.border_color = Color(0.4, 0.4, 0.4)
	style_disabled.corner_radius_top_left = 4
	style_disabled.corner_radius_top_right = 4
	style_disabled.corner_radius_bottom_left = 4
	style_disabled.corner_radius_bottom_right = 4

	# Apply styles to button
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("disabled", style_disabled)

	# Set minimum height for better clickability
	button.custom_minimum_size = Vector2(0, 35)

	# Make cursor show it's clickable
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Style the cost label inside the button
	var label = button.get_node_or_null("CostLabel")
	if label:
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color.WHITE)
		# Add slight shadow for better readability
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)

func _on_button_hover(button: Button, is_hovering: bool):
	"""Add extra visual feedback on button hover"""
	if not button or button.disabled:
		return

	if is_hovering:
		# Scale up slightly
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.15)
	else:
		# Reset scale
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)
