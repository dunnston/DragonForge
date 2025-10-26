extends Control
class_name BattleArena

# Visual battle arena for tower defense combat
# Shows knights attacking and dragons defending

@onready var battlefield = $MarginContainer/VBox/MainContent/BattlefieldContainer
@onready var knights_container: GridContainer = $MarginContainer/VBox/MainContent/BattlefieldContainer/KnightsCenter/KnightsContainer
@onready var dragons_container: GridContainer = $MarginContainer/VBox/MainContent/BattlefieldContainer/DragonsCenter/DragonsContainer
@onready var combat_log = $MarginContainer/VBox/MainContent/CombatLogPanel/ScrollContainer/CombatLog
@onready var back_button: Button = %BackButton

# Preload dragon visual scene
const DragonVisualScene = preload("res://assets/Icons/dragons/dragon-base.tscn")

var active_knights: Array = []
var active_dragons: Array = []
var knight_data: Array = []
var dragon_data: Array[Dragon] = []
var is_in_combat: bool = false

# Battle tracking
var battle_start_time: float = 0.0
var dragon_damage_tracker: Dictionary = {}  # {dragon_id: {dealt: int, taken: int}}

signal battle_animation_complete
signal battle_result_determined(victory: bool)
signal back_button_pressed

func _ready():
	# Connect to defense manager
	if DefenseManager.instance:
		DefenseManager.instance.wave_started.connect(_on_wave_started)
		DefenseManager.instance.wave_completed.connect(_on_wave_completed)

		# Check if we have enemy data to display (battle in progress OR recently completed)
		# NOTE: Don't auto-trigger battle setup here - let the parent (DefenseTowersUI) control visibility
		# The battle animation will be running in the background, we just show/hide the view
		var enemies = DefenseManager.instance.current_wave_enemies
		if enemies and enemies.size() > 0 and DefenseManager.instance.is_in_combat:
			# Battle is in progress - setup visuals but stay hidden
			# Parent will show us if needed
			print("[BattleArena] Battle in progress (wave %d, %d enemies) - setting up visuals" % [DefenseManager.instance.wave_number, enemies.size()])
			_on_wave_started(DefenseManager.instance.wave_number, enemies)

	# Connect back button
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed():
	"""Called when the back button is pressed"""
	print("[BattleArena] Back button pressed - hiding battle view (battle continues in background)")

	# DON'T clear battlefield - just hide the view and let battle continue in background
	# The visual units will keep animating even when hidden
	# _clear_battlefield()  # Removed - this was ending battle prematurely

	back_button_pressed.emit()
	# Note: Parent is responsible for hiding or destroying this node

func _on_wave_started(wave_number: int, enemies: Array):
	"""Start visual combat when wave begins"""
	print("[BattleArena] Wave started! Wave: %d, Enemies: %d" % [wave_number, enemies.size()])
	is_in_combat = true
	
	# Clear battlefield from previous battle (if any)
	_clear_battlefield()
	
	knight_data = enemies
	dragon_data = DefenseManager.instance.get_defending_dragons()
	
	print("[BattleArena] Knights container exists: %s" % (knights_container != null))
	print("[BattleArena] Dragons container exists: %s" % (dragons_container != null))
	
	if knights_container:
		print("[BattleArena] Knights container size: %s, visible: %s" % [knights_container.size, knights_container.visible])
	if dragons_container:
		print("[BattleArena] Dragons container size: %s, visible: %s" % [dragons_container.size, dragons_container.visible])
	
	# Wait for containers to be properly sized (especially important for first battle)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Set grid columns based on unit count for optimal layout
	_update_grid_columns(knights_container, enemies.size())
	_update_grid_columns(dragons_container, dragon_data.size())
	
	# Calculate dynamic card sizes based on available space (matching tower card size)
	var knight_card_size = await _calculate_card_size(knights_container, enemies.size())
	var dragon_card_size = await _calculate_card_size(dragons_container, dragon_data.size())
	
	# Keep dragons same size as in tower UI for consistency
	# (Removed 1.2x multiplier to match tower cards exactly)
	
	print("[BattleArena] Knight card size: %s, Dragon card size: %s" % [knight_card_size, dragon_card_size])
	
	# Spawn knights on LEFT side
	for i in enemies.size():
		var enemy = enemies[i]
		print("[BattleArena] Spawning knight %d" % i)
		_spawn_knight(enemy, i, knight_card_size)
	
	# Spawn defending dragons on RIGHT side
	for i in dragon_data.size():
		var dragon = dragon_data[i]
		print("[BattleArena] Spawning dragon %d: %s" % [i, dragon.dragon_name])
		_spawn_dragon(dragon, i, dragon_card_size)
	
	print("[BattleArena] Active knights: %d, Active dragons: %d" % [active_knights.size(), active_dragons.size()])
	
	# Start battle animation with longer intro
	await get_tree().create_timer(1.5).timeout
	_animate_battle()

func _update_grid_columns(container: GridContainer, unit_count: int):
	"""Update grid container columns based on unit count for optimal layout"""
	if not container or unit_count == 0:
		return
	
	# Calculate columns to create 2-3 rows maximum
	if unit_count <= 2:
		# 1 row
		container.columns = unit_count
	elif unit_count <= 6:
		# 2 rows
		container.columns = ceili(unit_count / 2.0)
	else:
		# 3 rows for 11+ units
		container.columns = ceili(unit_count / 3.0)
	
	print("[BattleArena] Set grid columns to %d for %d units" % [container.columns, unit_count])

func _calculate_card_size(container: GridContainer, unit_count: int) -> Vector2:
	"""Calculate optimal card size based on available space and unit count"""
	if not container or unit_count == 0:
		return Vector2(180, 320)  # Default size matching tower cards
	
	# Wait a frame to ensure container has proper size
	await get_tree().process_frame
	
	# Get the actual available size from the CenterContainer's parent (battlefield container)
	# Container hierarchy: GridContainer -> CenterContainer -> BattlefieldContainer
	var center_container = container.get_parent()
	var available_size = center_container.size if center_container else Vector2(800, 600)
	
	# Check if we have a valid size (first battle might have 0 size containers)
	if available_size.x < 100 or available_size.y < 100:
		print("[BattleArena] Container size too small (%s), using default tower card size" % available_size)
		return Vector2(180, 320)  # Default size matching tower cards
	
	# Account for the combat log taking up space
	var usable_width = available_size.x * 0.52  # Each side gets 52% of total width (more space for cards)
	var usable_height = available_size.y * 0.92  # 92% of height (leaving space for margins)
	
	# Calculate rows
	var columns = container.columns
	var rows = ceili(float(unit_count) / float(columns))
	
	# Calculate maximum card size that fits
	var h_separation = container.get_theme_constant("h_separation")
	var v_separation = container.get_theme_constant("v_separation")
	
	var card_width = (usable_width - (columns - 1) * h_separation) / columns
	var card_height = (usable_height - (rows - 1) * v_separation) / rows
	
	# Clamp to tower card size (180x320) - match defense towers UI
	card_width = clamp(card_width, 70, 180)
	card_height = clamp(card_height, 100, 320)
	
	# Maintain aspect ratio matching tower cards (1:1.78)
	var target_height = card_width * 1.78
	card_height = min(card_height, target_height)
	
	return Vector2(card_width, card_height)

func _spawn_knight(enemy_data: Dictionary, index: int, card_size: Vector2 = Vector2(180, 260)):
	"""Spawn a knight unit on the LEFT side of battlefield"""
	var knight = Panel.new()
	knight.custom_minimum_size = card_size
	knight.name = "Knight_%d" % index
	
	# Add a visible background to the Panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.25, 1)  # Dark gray background
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.8, 0.2, 0.2, 1)  # Red border
	knight.add_theme_stylebox_override("panel", style_box)
	knight.z_index = 10  # Ensure knights render on top
	
	# Visual container
	var vbox = VBoxContainer.new()
	knight.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	
	# Scale factors based on card size
	var scale_factor = card_size.x / 180.0  # Base size is 180
	
	# Knight sprite/icon
	var sprite = TextureRect.new()
	var sprite_size = max(50, card_size.x * 0.7)
	sprite.custom_minimum_size = Vector2(sprite_size, sprite_size)
	sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Load texture based on enemy type
	var enemy_texture: Texture2D
	var enemy_label = "Knight"

	if enemy_data.get("is_wizard", false):
		enemy_texture = load("res://assets/Icons/units/wizard.png")
		enemy_label = "Wizard"
	else:
		enemy_texture = load("res://assets/Icons/units/knight.png")

	if enemy_texture:
		sprite.texture = enemy_texture
		vbox.add_child(sprite)
		print("[BattleArena] %s texture loaded successfully" % enemy_label)
	else:
		# Fallback: colored panel
		var fallback = ColorRect.new()
		fallback.color = Color(0.7, 0.7, 0.7, 1)
		fallback.custom_minimum_size = Vector2(sprite_size, sprite_size)
		vbox.add_child(fallback)
		print("[BattleArena] %s texture FAILED to load - using fallback" % enemy_label)

	# Health bar
	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	var bar_width = max(60, card_size.x * 0.85)
	health_bar.custom_minimum_size = Vector2(bar_width, max(10, 14 * scale_factor))
	health_bar.max_value = enemy_data.get("health", 50)
	health_bar.value = enemy_data.get("health", 50)
	health_bar.show_percentage = false

	# Red health bar style
	var health_style = StyleBoxFlat.new()
	health_style.bg_color = Color(0.8, 0.2, 0.2, 1)  # Red
	health_bar.add_theme_stylebox_override("fill", health_style)

	var health_bg = StyleBoxFlat.new()
	health_bg.bg_color = Color(0.2, 0.2, 0.2, 1)  # Dark gray
	health_bar.add_theme_stylebox_override("background", health_bg)

	vbox.add_child(health_bar)

	# Dynamic font size based on card size
	var font_size_hp = max(8, int(11 * scale_factor))
	var font_size_stats = max(7, int(10 * scale_factor))
	var font_size_type = max(8, int(11 * scale_factor))

	# HP text label above bar
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "%d / %d HP" % [enemy_data.get("health", 50), enemy_data.get("health", 50)]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", font_size_hp)
	hp_label.clip_text = true
	hp_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hp_label.custom_minimum_size = Vector2(card_size.x - 10, 0)
	vbox.add_child(hp_label)

	# Stats label (ATK only now)
	var stats = Label.new()
	stats.name = "StatsLabel"
	stats.text = "ATK: %d" % enemy_data.get("attack", 10)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", font_size_stats)
	stats.clip_text = true
	stats.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stats.custom_minimum_size = Vector2(card_size.x - 10, 0)
	vbox.add_child(stats)
	
	# Type label
	var type_label = Label.new()
	var enemy_type = enemy_data.get("type", "knight")
	
	if enemy_type == "boss":
		type_label.text = "BOSS"
		type_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	elif enemy_type == "wizard":
		var element_names = ["🔥Fire", "❄Ice", "⚡Lightning", "☠Poison", "🌑Shadow"]
		var element_idx = enemy_data.get("elemental_type", 0)
		type_label.text = "WIZARD\n%s" % element_names[element_idx]
		type_label.add_theme_color_override("font_color", Color(0.6, 0.4, 1.0))  # Purple for wizard
	else:
		type_label.text = "KNIGHT"
		type_label.add_theme_color_override("font_color", Color(1, 1, 1))
	
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", font_size_type)
	type_label.clip_text = true
	type_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	type_label.custom_minimum_size = Vector2(card_size.x - 10, 0)
	vbox.add_child(type_label)
	
	# Add to knights container (LEFT side)
	if knights_container:
		knights_container.add_child(knight)
		var unit_label = "Wizard" if enemy_data.get("is_wizard", false) else "Knight"
		print("[BattleArena] %s %d added to container. Container children: %d" % [unit_label, index, knights_container.get_child_count()])
	else:
		print("[BattleArena] ERROR: knights_container is null!")
	
	# Make sure knight is visible (start fully visible, skip fade animation for now)
	knight.modulate.a = 1.0
	knight.visible = true
	
	active_knights.append(knight)

func _spawn_dragon(dragon: Dragon, index: int, card_size: Vector2 = Vector2(180, 320)):
	"""Spawn a dragon visual on the RIGHT side of battlefield"""
	var dragon_panel = Panel.new()
	dragon_panel.custom_minimum_size = card_size
	dragon_panel.name = "Dragon_%d" % index
	
	# Add a visible background to the Panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.25, 0.2, 1)  # Dark greenish background
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.2, 0.8, 0.4, 1)  # Green border
	dragon_panel.add_theme_stylebox_override("panel", style_box)
	dragon_panel.z_index = 5  # Dragons render below knights
	
	# Visual container
	var vbox = VBoxContainer.new()
	dragon_panel.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	
	# Scale factors based on card size
	var scale_factor = card_size.x / 180.0  # Base size is 180
	
	# Add actual DragonVisual wrapped in SubViewport for proper rendering
	var dragon_visual_instance = DragonVisualScene.instantiate()
	if dragon_visual_instance:
		# Create a SubViewport to properly render Node2D inside Control
		var viewport_size = max(60, int(card_size.x * 0.9))
		var viewport = SubViewport.new()
		viewport.size = Vector2i(viewport_size, viewport_size)
		viewport.transparent_bg = true
		viewport.add_child(dragon_visual_instance)

		# Position dragon in center of viewport - scaled
		dragon_visual_instance.position = Vector2(viewport_size / 2.0, viewport_size * 0.4)
		var dragon_scale = max(0.08, 0.13 * scale_factor)
		dragon_visual_instance.scale = Vector2(dragon_scale, dragon_scale)

		# Create SubViewportContainer to display it - fits in panel
		var container_size = max(50, card_size.x * 0.65)
		var viewport_container = SubViewportContainer.new()
		viewport_container.custom_minimum_size = Vector2(container_size, container_size)
		viewport_container.stretch = true
		viewport_container.add_child(viewport)

		vbox.add_child(viewport_container)

		# Set dragon colors from parts AFTER adding to scene tree
		# Call deferred to ensure shader material is fully ready
		if dragon.head_part and dragon.body_part and dragon.tail_part:
			dragon_visual_instance.set_dragon_colors.call_deferred(
				dragon.head_part.element,
				dragon.body_part.element,
				dragon.tail_part.element
			)
	
	# Dynamic font size based on card size
	var font_size_name = max(8, int(11 * scale_factor))
	var font_size_hp = max(8, int(11 * scale_factor))
	var font_size_stats = max(7, int(10 * scale_factor))

	# Dragon name
	var name_label = Label.new()
	name_label.text = dragon.dragon_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", font_size_name)
	name_label.add_theme_color_override("font_color", Color(0.8, 1, 0.8))
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.custom_minimum_size = Vector2(card_size.x - 10, 0)
	vbox.add_child(name_label)

	# Health bar
	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	var bar_width = max(60, card_size.x * 0.85)
	health_bar.custom_minimum_size = Vector2(bar_width, max(10, 14 * scale_factor))
	health_bar.max_value = dragon.get_health()
	health_bar.value = dragon.current_health
	health_bar.show_percentage = false

	# Green health bar style
	var health_style = StyleBoxFlat.new()
	health_style.bg_color = Color(0.2, 0.8, 0.2, 1)  # Green
	health_bar.add_theme_stylebox_override("fill", health_style)

	var health_bg = StyleBoxFlat.new()
	health_bg.bg_color = Color(0.2, 0.2, 0.2, 1)  # Dark gray
	health_bar.add_theme_stylebox_override("background", health_bg)

	vbox.add_child(health_bar)

	# HP text label above bar
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "%d / %d HP" % [dragon.current_health, dragon.get_health()]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", font_size_hp)
	hp_label.clip_text = true
	hp_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hp_label.custom_minimum_size = Vector2(card_size.x - 10, 0)
	vbox.add_child(hp_label)

	# Stats (ATK only now)
	var stats = Label.new()
	stats.name = "StatsLabel"
	stats.text = "ATK: %d" % dragon.get_attack()
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", font_size_stats)
	stats.clip_text = true
	stats.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stats.custom_minimum_size = Vector2(card_size.x - 10, 0)
	vbox.add_child(stats)
	
	# Add to dragons container (RIGHT side)
	if dragons_container:
		dragons_container.add_child(dragon_panel)
	
	# Make sure dragon is visible (start fully visible, skip fade animation for now)
	dragon_panel.modulate.a = 1.0
	dragon_panel.visible = true
	
	active_dragons.append(dragon_panel)

func _animate_battle():
	"""Animate the battle sequence with actual HP-based combat - TURN BASED"""
	# Start battle tracking
	battle_start_time = Time.get_ticks_msec() / 1000.0
	dragon_damage_tracker.clear()

	# Initialize damage tracking for each dragon
	for dragon in dragon_data:
		dragon_damage_tracker[dragon.dragon_id] = {"dealt": 0, "taken": 0}

	if combat_log:
		combat_log.text = "[center][b]⚔ BATTLE BEGINS! ⚔[/b][/center]\n\n"

	var round_num = 1

	# Fight until one side has no units with HP > 0
	while _has_living_knights() and _has_living_dragons():
		# === ROUND START ===
		await get_tree().create_timer(1.5).timeout  # Pause between rounds

		if combat_log:
			combat_log.text += "\n[center][color=yellow]━━━ ROUND %d ━━━[/color][/center]\n\n" % round_num

		# === KNIGHTS TURN ===
		if _has_living_knights():
			if combat_log:
				combat_log.text += "[color=orange][b]⚔ KNIGHTS' TURN[/b][/color]\n"

			await get_tree().create_timer(1.0).timeout  # Delay before knights attack
			await _combat_round_attacks(true)  # Knights attack
			await get_tree().create_timer(1.5).timeout  # Pause to see damage

		# Check if dragons survived
		if not _has_living_dragons():
			break

		# === DRAGONS TURN ===
		if combat_log:
			combat_log.text += "\n[color=lightblue][b]🐉 DRAGONS' TURN[/b][/color]\n"

		await get_tree().create_timer(1.0).timeout  # Delay before dragons attack
		await _combat_round_attacks(false)  # Dragons counter-attack
		await get_tree().create_timer(1.5).timeout  # Pause to see damage

		round_num += 1

		# Safety limit to prevent infinite loops
		if round_num > 50:
			if combat_log:
				combat_log.text += "\n[color=red]Battle reached max rounds![/color]\n"
			break
	
	# Determine winner based on actual HP-based combat
	var victory = _has_living_dragons()

	# Calculate battle duration
	var battle_duration = (Time.get_ticks_msec() / 1000.0) - battle_start_time

	# Send battle data to BattleLogManager
	if BattleLogManager:
		BattleLogManager.update_combat_log(combat_log.text if combat_log else "")
		BattleLogManager.update_round_count(round_num - 1)
		BattleLogManager.update_battle_duration(battle_duration)

		# Update defender stats
		for dragon in dragon_data:
			var damage_data = dragon_damage_tracker.get(dragon.dragon_id, {"dealt": 0, "taken": 0})
			BattleLogManager.update_defender_stats(
				dragon.dragon_id,
				0,  # XP will be added by DefenseManager
				damage_data["taken"],
				damage_data["dealt"],
				dragon.current_health > 0
			)

		# Mark killed enemies
		for i in range(knight_data.size()):
			if knight_data[i].get("health", 0) <= 0:
				BattleLogManager.mark_enemy_killed(i)

	# Report result to DefenseManager FIRST
	print("[BattleArena] Battle determined! Victory: %s" % victory)
	battle_result_determined.emit(victory)

	if combat_log:
		combat_log.text += "\n"
		if victory:
			combat_log.text += "[center][b][color=green]🐉 DRAGONS VICTORIOUS! 🐉[/color][/b][/center]\n"
		else:
			combat_log.text += "[center][b][color=red]⚔ KNIGHTS VICTORIOUS! ⚔[/color][/b][/center]\n"

	# Fade out defeated units
	if victory:
		print("[BattleArena] Dragons won - fading out knights")
		_fade_out_units(active_knights)
	else:
		print("[BattleArena] Knights won - fading out dragons")
		_fade_out_units(active_dragons)

	# Wait before finishing (brief pause to show result)
	await get_tree().create_timer(0.5).timeout

	print("[BattleArena] Battle animation complete!")
	battle_animation_complete.emit()
	
	# Show death summary popup if there were any deaths during battle
	if DragonDeathManager and DragonDeathManager.instance:
		if DragonDeathManager.instance.has_pending_deaths():
			print("[BattleArena] Showing death summary popup after battle")
			DragonDeathManager.instance.show_death_summary_if_needed()

func _has_living_knights() -> bool:
	"""Check if any knights are still alive"""
	for knight in knight_data:
		if knight.get("health", 0) > 0:
			return true
	return false

func _has_living_dragons() -> bool:
	"""Check if any dragons are still alive"""
	for dragon in dragon_data:
		if dragon.current_health > 0:
			return true
	return false

func _get_living_knight_indices() -> Array[int]:
	"""Get indices of knights that are still alive"""
	var living: Array[int] = []
	for i in range(knight_data.size()):
		if knight_data[i].get("health", 0) > 0:
			living.append(i)
	return living

func _get_living_dragon_indices() -> Array[int]:
	"""Get indices of dragons that are still alive"""
	var living: Array[int] = []
	for i in range(dragon_data.size()):
		if dragon_data[i].current_health > 0:
			living.append(i)
	return living

func _combat_round_attacks(knights_attacking: bool):
	"""Execute actual combat with HP reduction"""
	var attackers = active_knights if knights_attacking else active_dragons
	
	if knights_attacking:
		# Knights attack dragons
		var living_knights = _get_living_knight_indices()
		var living_dragons = _get_living_dragon_indices()
		
		if living_knights.is_empty() or living_dragons.is_empty():
			return
		
		# Shake attacking units
		_shake_units(attackers, true)
		
		for knight_idx in living_knights:
			var knight_panel = active_knights[knight_idx]
			var knight = knight_data[knight_idx]
			var damage = knight.get("attack", 10)
			var enemy_type = knight.get("type", "knight")
			
			# Wizards deal bonus elemental damage
			if enemy_type == "wizard":
				var elemental_dmg = knight.get("elemental_damage", 0)
				damage += elemental_dmg
			
			# Pick a random living dragon to attack
			var target_idx = living_dragons[randi() % living_dragons.size()]
			var target_dragon = dragon_data[target_idx]
			var target_panel = active_dragons[target_idx]
			
			# Deal damage
			target_dragon.current_health = max(0, target_dragon.current_health - damage)

			# Track damage taken by dragon
			if dragon_damage_tracker.has(target_dragon.dragon_id):
				dragon_damage_tracker[target_dragon.dragon_id]["taken"] += damage

			# Show damage text on target
			_show_damage_text(target_panel, damage, false)

			# Update dragon HP display
			_update_dragon_hp(target_idx)
			
			# Log with enemy type
			if combat_log:
				var enemy_label = "Wizard" if enemy_type == "wizard" else "Knight"
				var color = "purple" if enemy_type == "wizard" else "orange"
				var element_icons = ["🔥", "❄", "⚡", "☠", "🌑"]
				var element_icon = element_icons[knight.get("elemental_type", 0)] if enemy_type == "wizard" else ""
				
				combat_log.text += "[color=%s]%s %d%s[/color] deals [b]%d[/b] damage to [color=lightblue]%s[/color]! (HP: %d)\n" % [color, enemy_label, knight_idx, element_icon, damage, target_dragon.dragon_name, target_dragon.current_health]
			
			# Mark dead dragons and actually kill them
			if target_dragon.current_health <= 0:
				_mark_unit_dead(target_panel)
				
				# Actually kill the dragon in the game system
				target_dragon._die()
				print("[BattleArena] Dragon %s died in combat!" % target_dragon.dragon_name)
				
				# Find which tower this dragon was defending and destroy it
				var tower_to_destroy: int = -1
				if DefenseManager and DefenseManager.instance:
					for tower_idx in DefenseManager.instance.tower_assignments.keys():
						if DefenseManager.instance.tower_assignments[tower_idx] == target_dragon:
							tower_to_destroy = tower_idx
							break
					
					# Destroy the tower
					if tower_to_destroy >= 0:
						print("[BattleArena] Destroying tower %d because %s died" % [tower_to_destroy, target_dragon.dragon_name])
						
						if DefenseTowerManager and DefenseTowerManager.instance:
							var towers = DefenseTowerManager.instance.get_towers()
							if tower_to_destroy < towers.size():
								towers[tower_to_destroy].current_health = 0
						
						# Remove from tower assignments
						DefenseManager.instance.tower_assignments.erase(tower_to_destroy)
				
				# Remove from factory manager's active dragons list
				_remove_dragon_from_factory(target_dragon)
				
				# Remove from dragon state manager
				if DragonStateManager and DragonStateManager.instance:
					DragonStateManager.instance.unregister_dragon(target_dragon)
					print("[BattleArena] Unregistered dead dragon %s from state manager" % target_dragon.dragon_name)

				# Trigger part recovery and death notification
				if DragonDeathManager and DragonDeathManager.instance:
					DragonDeathManager.instance.handle_dragon_death(target_dragon, "combat_defending")
					print("[BattleArena] Triggered part recovery for %s" % target_dragon.dragon_name)

				# Refresh all UIs immediately
				_refresh_all_uis()

				if combat_log:
					combat_log.text += "[color=red]💀 %s has fallen![/color]\n" % target_dragon.dragon_name
	else:
		# Dragons attack knights
		var living_dragons = _get_living_dragon_indices()
		var living_knights = _get_living_knight_indices()
		
		if living_dragons.is_empty() or living_knights.is_empty():
			return
		
		# Shake attacking units
		_shake_units(attackers, false)
		
		for dragon_idx in living_dragons:
			var dragon_panel = active_dragons[dragon_idx]
			var dragon = dragon_data[dragon_idx]
			var damage = dragon.get_attack()
			
			# Pick a random living knight to attack
			var target_idx = living_knights[randi() % living_knights.size()]
			var target_knight = knight_data[target_idx]
			var target_panel = active_knights[target_idx]
			
			# Deal damage
			target_knight["health"] = max(0, target_knight.get("health", 0) - damage)

			# Track damage dealt by dragon
			if dragon_damage_tracker.has(dragon.dragon_id):
				dragon_damage_tracker[dragon.dragon_id]["dealt"] += damage

			# Show damage text on target
			_show_damage_text(target_panel, damage, true)

			# Update knight HP display
			_update_knight_hp(target_idx)
			
			# Log
			if combat_log:
				var enemy_label = "Wizard" if target_knight.get("type") == "wizard" else "Knight"
				var color = "purple" if target_knight.get("type") == "wizard" else "orange"
				
				combat_log.text += "[color=lightblue]%s[/color] deals [b]%d[/b] damage to [color=%s]%s %d[/color]! (HP: %d)\n" % [dragon.dragon_name, damage, color, enemy_label, target_idx, target_knight["health"]]
			
			# Mark dead knights
			if target_knight["health"] <= 0:
				_mark_unit_dead(target_panel)
				if combat_log:
					var enemy_label = "Wizard" if target_knight.get("type") == "wizard" else "Knight"
					combat_log.text += "[color=red]💀 %s %d has fallen![/color]\n" % [enemy_label, target_idx]
	
	await get_tree().create_timer(0.5).timeout  # Pause after each individual attack

func _show_damage_text(unit: Control, damage: int, is_knight: bool):
	"""Show floating damage text above a unit"""
	var damage_label = Label.new()
	damage_label.text = "-%d" % damage
	damage_label.add_theme_font_size_override("font_size", 20)
	damage_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))

	# Add to the battlefield container (not the unit) so it renders on top
	var battlefield_container = unit.get_parent()
	if battlefield_container:
		battlefield_container.add_child(damage_label)

		# Position above the unit (absolute position)
		var horizontal_offset = randf_range(-50, 50)
		damage_label.global_position = unit.global_position + Vector2(unit.size.x / 2 + horizontal_offset, -20)

		# High z-index to ensure it's on top of everything
		damage_label.z_index = 200
		damage_label.z_as_relative = false

		# Animate damage text floating up and fading
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(damage_label, "global_position:y", damage_label.global_position.y - 80, 1.0)
		tween.tween_property(damage_label, "modulate:a", 0.0, 1.0)
		tween.finished.connect(func(): damage_label.queue_free())

func _update_knight_hp(knight_idx: int):
	"""Update the HP display on a knight panel"""
	if knight_idx >= active_knights.size():
		return

	var knight_panel = active_knights[knight_idx]
	var knight = knight_data[knight_idx]

	# Update health bar
	var health_bar = knight_panel.find_child("HealthBar", true, false)
	if health_bar:
		health_bar.value = knight.get("health", 0)

	# Update HP label
	var hp_label = knight_panel.find_child("HPLabel", true, false)
	if hp_label:
		hp_label.text = "%d / %d HP" % [knight.get("health", 0), health_bar.max_value if health_bar else 100]

func _update_dragon_hp(dragon_idx: int):
	"""Update the HP display on a dragon panel"""
	if dragon_idx >= active_dragons.size():
		return

	var dragon_panel = active_dragons[dragon_idx]
	var dragon = dragon_data[dragon_idx]

	# Update health bar
	var health_bar = dragon_panel.find_child("HealthBar", true, false)
	if health_bar:
		health_bar.value = dragon.current_health

	# Update HP label
	var hp_label = dragon_panel.find_child("HPLabel", true, false)
	if hp_label:
		hp_label.text = "%d / %d HP" % [dragon.current_health, dragon.get_health()]

func _mark_unit_dead(unit_panel: Control):
	"""Mark a unit as dead by graying it out"""
	if unit_panel:
		var tween = create_tween()
		tween.tween_property(unit_panel, "modulate", Color(0.3, 0.3, 0.3, 0.5), 0.3)

func _shake_units(units: Array, move_right: bool = false):
	"""Shake units to simulate attacking motion - different for attackers vs defenders"""
	
	for unit in units:
		if unit:
			var tween = create_tween()
			
			if move_right:
				# Knights attacking - lunge forward (right) aggressively
				tween.tween_property(unit, "position:x", unit.position.x + 30, 0.15)
				tween.tween_property(unit, "rotation", 0.1, 0.1)  # Lean forward
				tween.tween_property(unit, "position:x", unit.position.x, 0.15)
				tween.tween_property(unit, "rotation", 0.0, 0.1)  # Return to normal
			else:
				# Dragons counter-attacking - quick strike (left)
				tween.tween_property(unit, "position:x", unit.position.x - 25, 0.12)
				tween.tween_property(unit, "scale", Vector2(1.1, 1.1), 0.08)  # Grow slightly
				tween.tween_property(unit, "position:x", unit.position.x, 0.12)
				tween.tween_property(unit, "scale", Vector2(1.0, 1.0), 0.08)  # Return to normal

func _on_wave_completed(victory: bool, rewards: Dictionary):
	"""Called AFTER battle animation and stat changes - just cleanup"""
	is_in_combat = false

	print("[BattleArena] Wave completed callback received - battle already shown")

	# Battle results were already shown in _animate_battle()
	# Don't clear battlefield - let player read results and close manually

func _fade_out_units(units: Array):
	"""Fade out units"""
	for unit in units:
		if unit:
			var tween = create_tween()
			tween.tween_property(unit, "modulate:a", 0.0, 1.0)

func _clear_battlefield():
	"""Clear all units from battlefield"""
	for knight in active_knights:
		if knight:
			knight.queue_free()
	active_knights.clear()
	
	for dragon in active_dragons:
		if dragon:
			dragon.queue_free()
	active_dragons.clear()
	
	knight_data.clear()
	dragon_data.clear()
	
	if combat_log:
		combat_log.clear()

func _remove_dragon_from_factory(dragon: Dragon):
	"""Remove dead dragon from factory manager and all systems"""
	# Try to find factory through the scene tree
	var factory_manager_nodes = get_tree().get_nodes_in_group("factory_manager")
	
	for node in factory_manager_nodes:
		if node.has_method("get") and node.get("factory"):
			var factory = node.get("factory")
			if factory and factory.has_method("remove_dragon"):
				factory.remove_dragon(dragon)
				print("[BattleArena] Removed dead dragon %s from factory" % dragon.dragon_name)
				return
	
	# Fallback: try to access through DragonFactory class if available
	print("[BattleArena] Warning: Could not find factory to remove dragon from")

func _refresh_all_uis():
	"""Refresh factory manager and tower UI immediately after dragon death"""
	# Refresh factory manager
	var factory_manager_nodes = get_tree().get_nodes_in_group("factory_manager")
	for node in factory_manager_nodes:
		if node.has_method("_update_dragons_list"):
			node._update_dragons_list()
			print("[BattleArena] Refreshed factory manager UI")
	
	# Refresh tower UI
	var tower_ui_nodes = get_tree().get_nodes_in_group("defense_towers_ui")
	for node in tower_ui_nodes:
		if node.has_method("_refresh_tower_cards"):
			node._refresh_tower_cards()
			print("[BattleArena] Refreshed tower UI")
