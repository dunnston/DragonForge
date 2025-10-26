extends Control
class_name DefenseTowersUI

# Main UI for managing defense towers

const TowerCardScene = preload("res://scenes/ui/towers/tower_card.tscn")
const BuildCardScene = preload("res://scenes/ui/towers/build_card.tscn")
const LockedCardScene = preload("res://scenes/ui/towers/locked_card.tscn")
const DragonPickerModalScene = preload("res://scenes/ui/dragon_picker_modal.tscn")
const BattleArenaScene = preload("res://scenes/idle_defense/battle_arena.tscn")
const BattleLogUIScene = preload("res://scenes/ui/battle_log_ui.tscn")
const WaveResultPopupScene = preload("res://scenes/ui/wave_result_popup.tscn")
const BattleSummaryPopupScene = preload("res://scenes/ui/battle_summary_popup.tscn")

@onready var back_button = $MarginContainer/VBox/HeaderPanel/HeaderHBox/BackButton
@onready var battle_log_button: Button = %BattleLogButton
@onready var tower_container = $MarginContainer/VBox/ScrollContainer/TowerContainer
@onready var repair_all_button = $MarginContainer/VBox/FooterPanel/HBox/RepairAllButton
@onready var stats_label = $MarginContainer/VBox/FooterPanel/HBox/StatsLabel
@onready var battle_notification_panel: PanelContainer = %BattleNotificationPanel
@onready var battle_label: Label = %BattleLabel
@onready var scout_button: Button = %ScoutButton

var wave_timer_label: Label  # Created dynamically
var dragon_picker_modal: DragonPickerModal
var dragon_factory: DragonFactory  # Reference to factory
var battle_arena: Control  # Battle visualization
var enemy_scout_screen: Control  # Enemy scout screen

# Store last wave results to show after animation
var last_wave_victory: bool = false
var last_wave_rewards: Dictionary = {}
var current_wave_number: int = 0  # Track which wave we've shown popup for

# Store scouted enemies for preview
var scouted_enemies: Array = []
var scouted_wave_number: int = 0

# Track if user manually closed battle arena (don't auto-show if they did)
var battle_arena_manually_closed: bool = false

signal back_to_factory_requested

func set_dragon_factory(factory: DragonFactory):
	"""Set the dragon factory reference"""
	dragon_factory = factory

func _ready():
	# Add to group so DefenseManager can refresh this UI
	add_to_group("defense_towers_ui")
	
	# Create wave timer label in header
	_create_wave_timer_label()
	
	# Populate towers on startup
	_populate_towers()
	_update_footer()

	# Connect to manager signals for real-time updates
	if DefenseTowerManager and DefenseTowerManager.instance:
		DefenseTowerManager.instance.tower_built.connect(_on_tower_built)
		DefenseTowerManager.instance.tower_damaged.connect(_on_tower_damaged)
		DefenseTowerManager.instance.tower_repaired.connect(_on_tower_repaired)
		DefenseTowerManager.instance.tower_capacity_changed.connect(_on_capacity_changed)

	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.dragon_assigned_to_defense.connect(_on_dragon_assigned)
		DefenseManager.instance.dragon_removed_from_defense.connect(_on_dragon_removed)
		DefenseManager.instance.wave_incoming_scout.connect(_on_wave_incoming_scout)
		DefenseManager.instance.wave_started.connect(_on_wave_started)
		DefenseManager.instance.wave_completed.connect(_on_wave_completed)

	if TreasureVault and TreasureVault.instance:
		TreasureVault.instance.gold_changed.connect(_on_gold_changed)

	# Connect buttons
	back_button.pressed.connect(_on_back_pressed)
	battle_log_button.pressed.connect(_on_battle_log_pressed)
	repair_all_button.pressed.connect(_on_repair_all_pressed)
	scout_button.pressed.connect(_on_scout_button_pressed)

	# Style the battle notification panel
	if battle_notification_panel:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.4, 0.1, 0.1, 0.9)  # Dark red background
		style_box.border_width_left = 3
		style_box.border_width_right = 3
		style_box.border_width_top = 3
		style_box.border_width_bottom = 3
		style_box.border_color = Color(1, 0.3, 0.3, 1)  # Bright red border
		battle_notification_panel.add_theme_stylebox_override("panel", style_box)

	# Create dragon picker modal
	dragon_picker_modal = DragonPickerModalScene.instantiate()
	add_child(dragon_picker_modal)
	dragon_picker_modal.dragon_selected.connect(_on_dragon_selected)
	
	# Show cumulative rewards if any battles happened while UI was closed
	_show_cumulative_rewards()
	
	# Create battle arena (hidden by default)
	battle_arena = BattleArenaScene.instantiate()
	add_child(battle_arena)
	battle_arena.visible = false
	battle_arena.battle_animation_complete.connect(_on_battle_animation_complete)
	battle_arena.battle_result_determined.connect(_on_battle_result_determined)
	battle_arena.back_button_pressed.connect(_on_battle_arena_back_pressed)

	# Update every second to keep UI fresh
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_ui)
	add_child(timer)
	timer.start()

func _create_wave_timer_label():
	"""Create and add wave timer label to header"""
	var header_hbox = $MarginContainer/VBox/HeaderPanel/HeaderHBox
	if not header_hbox:
		return
	
	# Create wave number label
	var wave_num_label = Label.new()
	wave_num_label.name = "WaveNumberLabel"
	wave_num_label.text = "Wave 1"
	wave_num_label.add_theme_font_size_override("font_size", 18)
	wave_num_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1, 1))  # Light blue
	
	# Add spacer before timer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)
	
	# Add wave number label
	header_hbox.add_child(wave_num_label)
	
	# Add spacer between wave number and timer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.x = 40
	header_hbox.add_child(spacer2)
	
	# Create timer label
	wave_timer_label = Label.new()
	wave_timer_label.name = "WaveTimerLabel"
	wave_timer_label.text = "Next Wave: --:--"
	wave_timer_label.add_theme_font_size_override("font_size", 18)
	wave_timer_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))  # Yellow/gold
	
	# Add timer label
	header_hbox.add_child(wave_timer_label)

func _update_ui():
	"""Update both footer stats and wave timer"""
	_update_footer()
	_update_wave_timer()
	_update_battle_notification()

func _update_wave_timer():
	"""Update the wave timer display"""
	if not wave_timer_label or not DefenseManager.instance:
		return
	
	# Update wave number
	var header_hbox = $MarginContainer/VBox/HeaderPanel/HeaderHBox
	if header_hbox:
		var wave_num_label = header_hbox.get_node_or_null("WaveNumberLabel")
		if wave_num_label:
			wave_num_label.text = "Wave %d" % DefenseManager.instance.wave_number
	
	var time_remaining = DefenseManager.instance.get_time_until_wave()
	
	# Check if raids are paused due to no resources (only if no defenders assigned)
	if DefenseManager.instance.tower_assignments.is_empty() and DefenseManager.instance._is_player_out_of_resources():
		wave_timer_label.text = "⏸ RAIDS PAUSED (No Resources)"
		wave_timer_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))  # Gray
	# Check if in combat
	elif DefenseManager.instance.is_in_combat:
		wave_timer_label.text = "⚔ COMBAT! ⚔"
		wave_timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))  # Red
	# Check if in scout period
	elif scouted_enemies.size() > 0:
		var minutes = int(time_remaining / 60)
		var seconds = int(time_remaining) % 60
		wave_timer_label.text = "⚠ WAVE INCOMING: %d:%02d ⚠" % [minutes, seconds]
		wave_timer_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2, 1))  # Orange - warning!
	else:
		# Format time as MM:SS
		var minutes = int(time_remaining / 60)
		var seconds = int(time_remaining) % 60
		wave_timer_label.text = "Next Wave: %d:%02d" % [minutes, seconds]

		# Color based on urgency
		if time_remaining <= 10:
			wave_timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))  # Red - urgent!
		elif time_remaining <= 30:
			wave_timer_label.add_theme_color_override("font_color", Color(1, 0.6, 0.2, 1))  # Orange - soon
		else:
			wave_timer_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))  # Yellow/gold - normal

func _populate_towers():
	# Clear existing cards
	for child in tower_container.get_children():
		child.queue_free()

	if not DefenseTowerManager or not DefenseTowerManager.instance:
		print("[DefenseTowersUI] ERROR: DefenseTowerManager not found!")
		return

	var tower_manager = DefenseTowerManager.instance
	var towers = tower_manager.get_towers()

	# Add cards for existing towers
	for i in range(towers.size()):
		var tower = towers[i]
		var card = TowerCardScene.instantiate()
		card.setup(tower, i)
		card.repair_clicked.connect(_on_repair_clicked)
		card.rebuild_clicked.connect(_on_rebuild_clicked)
		card.card_clicked.connect(_on_tower_card_clicked)
		card.assign_dragon_requested.connect(_on_assign_dragon_requested)
		tower_container.add_child(card)

	# Add build card if we can build more
	if tower_manager.can_build_tower():
		var build_card = BuildCardScene.instantiate()
		build_card.setup(towers.size())
		build_card.build_clicked.connect(_on_build_clicked)
		tower_container.add_child(build_card)

	# Add locked cards for remaining slots
	var locked_slots = DefenseTowerManager.MAX_TOWERS - towers.size()
	if tower_manager.can_build_tower():
		locked_slots -= 1  # One slot is the build card

	for i in range(locked_slots):
		var locked_card = LockedCardScene.instantiate()
		locked_card.setup(towers.size() + 1 + i)
		tower_container.add_child(locked_card)

func _update_footer():
	if not DefenseTowerManager or not DefenseTowerManager.instance:
		return
	if not DefenseManager or not DefenseManager.instance:
		return
	if not TreasureVault or not TreasureVault.instance:
		return

	var tower_manager = DefenseTowerManager.instance
	var defense_manager = DefenseManager.instance

	# Update slots display
	var capacity = tower_manager.get_defense_capacity()
	var defending = defense_manager.get_defending_dragons().size()
	stats_label.text = "Slots: %d/%d" % [defending, capacity]

	# Update repair all button
	var damaged_count = tower_manager.get_damaged_towers()
	if damaged_count > 0:
		var total_cost = 0
		for tower in tower_manager.get_towers():
			if tower.needs_repair() and not tower.is_destroyed():
				total_cost += tower_manager.get_tower_repair_cost(tower)

		repair_all_button.text = "Repair All: %dg" % total_cost
		repair_all_button.visible = true

		if TreasureVault.instance.get_total_gold() < total_cost:
			repair_all_button.disabled = true
			repair_all_button.modulate = Color(0.6, 0.6, 0.6)
		else:
			repair_all_button.disabled = false
			repair_all_button.modulate = Color(1, 1, 1)
	else:
		repair_all_button.visible = false

func _refresh_tower_cards():
	# Refresh all tower cards without rebuilding
	for child in tower_container.get_children():
		if child.has_method("refresh"):
			child.refresh()

func _on_repair_clicked(tower_index: int):
	if not DefenseTowerManager or not DefenseTowerManager.instance:
		return

	var tower_manager = DefenseTowerManager.instance
	var towers = tower_manager.get_towers()

	if tower_index < 0 or tower_index >= towers.size():
		return

	var tower = towers[tower_index]
	var success = tower_manager.repair_tower(tower)

	if success:
		print("[DefenseTowersUI] Tower %d repaired!" % tower_index)
		_refresh_tower_cards()
		_update_footer()
	else:
		print("[DefenseTowersUI] Failed to repair tower %d" % tower_index)

func _on_rebuild_clicked(tower_index: int):
	if not DefenseTowerManager or not DefenseTowerManager.instance:
		return
	
	var tower_manager = DefenseTowerManager.instance
	var success = tower_manager.rebuild_tower(tower_index)
	
	if success:
		print("[DefenseTowersUI] Tower %d rebuilt!" % tower_index)
		_refresh_tower_cards()
		_update_footer()
	else:
		print("[DefenseTowersUI] Failed to rebuild tower %d" % tower_index)

func _on_build_clicked(tower_index: int):
	if not DefenseTowerManager or not DefenseTowerManager.instance:
		return

	var tower_manager = DefenseTowerManager.instance
	var new_tower = tower_manager.build_tower()

	if new_tower:
		print("[DefenseTowersUI] New tower built!")
		# Rebuild UI to show new tower
		_populate_towers()
		_update_footer()
	else:
		print("[DefenseTowersUI] Failed to build tower")

func _on_tower_card_clicked(tower_index: int):
	# Future: Open tower details or dragon assignment UI
	print("[DefenseTowersUI] Tower %d clicked" % tower_index)

func _on_repair_all_pressed():
	if not DefenseTowerManager or not DefenseTowerManager.instance:
		return

	var tower_manager = DefenseTowerManager.instance
	var repaired = tower_manager.repair_all_towers()

	if repaired > 0:
		print("[DefenseTowersUI] Repaired %d towers" % repaired)
		_refresh_tower_cards()
		_update_footer()

# Signal handlers for real-time updates

func _on_tower_built(tower: DefenseTower):
	_populate_towers()
	_update_footer()

func _on_tower_damaged(tower: DefenseTower, damage: int):
	_refresh_tower_cards()
	_update_footer()

func _on_tower_repaired(tower: DefenseTower, amount: int):
	_refresh_tower_cards()
	_update_footer()

func _on_capacity_changed(new_capacity: int):
	_update_footer()

func _on_dragon_assigned(dragon):
	_refresh_tower_cards()
	_update_footer()

func _on_dragon_removed(dragon):
	_refresh_tower_cards()
	_update_footer()

func _on_wave_incoming_scout(wave_num: int, enemies: Array, time_remaining: float):
	"""Called 90 seconds before wave - store scout data"""
	print("[DefenseTowersUI] ===== WAVE %d INCOMING (%.0fs) - SCOUT AVAILABLE =====" % [wave_num, time_remaining])
	scouted_enemies = enemies
	scouted_wave_number = wave_num

func _on_wave_started(wave_number: int, enemies: Array):
	"""Show battle arena when wave starts (only if not manually closed)"""
	# Clear scout data when battle starts
	scouted_enemies.clear()

	# Reset the manually closed flag for new battles
	battle_arena_manually_closed = false

	# Only auto-show battle arena if user didn't manually close it
	# (If they're in the tower UI, they can click "Watch Battle" to open it)
	if battle_arena and not battle_arena_manually_closed:
		battle_arena.visible = true

func _on_wave_completed(victory: bool, rewards: Dictionary):
	# Update UI immediately when wave completes
	_refresh_tower_cards()
	_update_ui()

	# Reset manually closed flag for next wave
	battle_arena_manually_closed = false

	# Store results to show after animation completes
	last_wave_victory = victory
	last_wave_rewards = rewards

	print("[DefenseTowersUI] Stored wave results - Victory: %s, Gold: %d" % [victory, rewards.get("gold", 0)])

	# Update factory manager to refresh dragon list and gold
	_update_factory_manager()

	# Only show popup if this UI is visible (prevents showing on wrong scene)
	if visible and DefenseManager.instance and DefenseManager.instance.should_show_wave_result_popup():
		_show_wave_rewards_popup(victory, rewards)
		print("[DefenseTowersUI] Showing wave popup")
	elif not visible:
		print("[DefenseTowersUI] This UI not visible, skipping popup")
	else:
		print("[DefenseTowersUI] Popup already shown by another UI, skipping")

	# Battle arena stays open for player to read results and close manually via back button

func _on_battle_result_determined(victory: bool):
	"""Called when visual combat determines the winner"""
	print("[DefenseTowersUI] Battle result determined: Victory=%s" % victory)
	
	# Pass result to DefenseManager
	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.on_visual_combat_result(victory)

func _on_battle_animation_complete():
	"""Called when battle animation finishes"""
	print("[DefenseTowersUI] Battle animation complete")

	# Resume wave timer by ending combat state (which triggers _complete_wave)
	if DefenseManager and DefenseManager.instance:
		DefenseManager.instance.end_combat()

func _on_battle_arena_back_pressed():
	"""Called when player clicks back button in battle arena"""
	print("[DefenseTowersUI] Player closed battle arena (battle continues in background)")
	
	# Mark that user manually closed it - don't auto-show again
	battle_arena_manually_closed = true
	
	if battle_arena:
		battle_arena.visible = false

func _update_battle_notification():
	"""Update battle notification panel visibility and text"""
	if not battle_notification_panel or not DefenseManager or not DefenseManager.instance:
		return

	var is_scouting = scouted_enemies.size() > 0
	var is_in_combat = DefenseManager.instance.is_in_combat

	# Show notification if in combat or scouting
	if is_in_combat or is_scouting:
		battle_notification_panel.visible = true

		if is_scouting:
			# Scout mode
			battle_label.text = "⚠ WAVE %d INCOMING! ⚠" % scouted_wave_number
			scout_button.text = "SCOUT ENEMIES"
		elif is_in_combat:
			# Combat mode
			battle_label.text = "⚔ BATTLE IN PROGRESS ⚔"
			scout_button.text = "WATCH BATTLE"
	else:
		battle_notification_panel.visible = false

func _on_scout_button_pressed():
	"""Handle scout/watch battle button click"""
	print("[DefenseTowersUI] Scout button pressed!")

	# Check if we're in scout mode
	if scout_button.text == "SCOUT ENEMIES":
		print("[DefenseTowersUI] Opening enemy scout screen...")
		_open_enemy_scout_screen()
	else:
		# Watch battle mode - show battle arena
		print("[DefenseTowersUI] Opening battle arena...")
		if battle_arena:
			# User explicitly wants to watch - clear the manually closed flag
			battle_arena_manually_closed = false
			battle_arena.visible = true

func _open_enemy_scout_screen():
	"""Open the enemy scout screen to preview incoming wave"""
	# Check if scout screen already exists and is visible
	if enemy_scout_screen and is_instance_valid(enemy_scout_screen):
		print("[DefenseTowersUI] Enemy scout screen already open, updating...")
		if enemy_scout_screen.has_method("show_scout_info"):
			var time_remaining = DefenseManager.instance.time_until_next_wave if DefenseManager and DefenseManager.instance else 90.0
			enemy_scout_screen.show_scout_info(scouted_wave_number, scouted_enemies, time_remaining)
		enemy_scout_screen.visible = true
		return

	# Load and create the enemy scout screen scene
	var scout_scene = load("res://scenes/idle_defense/enemy_scout_screen.tscn")
	if not scout_scene:
		print("[DefenseTowersUI] ERROR: Could not load enemy scout screen scene!")
		return

	enemy_scout_screen = scout_scene.instantiate()
	enemy_scout_screen.name = "EnemyScoutScreen"

	# Set z-index to appear above everything else
	enemy_scout_screen.z_index = 150
	enemy_scout_screen.z_as_relative = false

	# Add to scene tree
	add_child(enemy_scout_screen)

	# Show scout info with current data
	if enemy_scout_screen.has_method("show_scout_info"):
		var time_remaining = DefenseManager.instance.time_until_next_wave if DefenseManager and DefenseManager.instance else 90.0
		enemy_scout_screen.show_scout_info(scouted_wave_number, scouted_enemies, time_remaining)

	print("[DefenseTowersUI] Enemy scout screen opened!")

func _update_factory_manager():
	"""Update factory manager UI to refresh dragons and gold after combat"""
	# Find factory manager in the scene tree
	var factory_manager_nodes = get_tree().get_nodes_in_group("factory_manager")
	
	for node in factory_manager_nodes:
		# Call update methods if they exist
		if node.has_method("_update_dragons_list"):
			node._update_dragons_list()
			print("[DefenseTowersUI] Updated factory manager dragon list")
		if node.has_method("_update_gold_display"):
			var gold = TreasureVault.instance.get_total_gold() if TreasureVault.instance else 0
			node._update_gold_display(gold)
			print("[DefenseTowersUI] Updated factory manager gold display")
		if node.has_method("_update_display"):
			node._update_display()
			print("[DefenseTowersUI] Updated factory manager display")

func _on_gold_changed(new_amount: int, delta: int):
	# Update button states when gold changes
	_refresh_tower_cards()
	_update_footer()

func _on_assign_dragon_requested(tower_index: int):
	if not dragon_factory:
		print("[DefenseTowersUI] ERROR: DragonFactory not set!")
		return

	# Open dragon picker modal
	dragon_picker_modal.open(dragon_factory, tower_index)

func _on_dragon_selected(dragon: Dragon, tower_index: int):
	if not DefenseManager or not DefenseManager.instance:
		print("[DefenseTowersUI] ERROR: DefenseManager not found!")
		return

	# Assign dragon to the specific tower
	var success = DefenseManager.instance.assign_dragon_to_tower(dragon, tower_index)
	if success:
		print("[DefenseTowersUI] Dragon %s assigned to tower %d" % [dragon.dragon_name, tower_index])
	else:
		print("[DefenseTowersUI] Failed to assign dragon to tower %d" % tower_index)

	# Refresh UI to show updated dragon assignment
	_refresh_tower_cards()
	_update_footer()

func _on_back_pressed():
	# Emit signal for parent to handle navigation
	back_to_factory_requested.emit()
	# Or handle directly:
	visible = false

func _on_battle_log_pressed():
	"""Open the battle log UI to view battle history"""
	var battle_log_ui = BattleLogUIScene.instantiate()
	add_child(battle_log_ui)
	battle_log_ui.closed.connect(func(): battle_log_ui.queue_free())

func _show_wave_rewards_popup(victory: bool, rewards: Dictionary):
	"""Show wave result popup using themed popup scene"""
	var popup = WaveResultPopupScene.instantiate()

	# Set z-index to appear above battle arena
	popup.z_index = 200
	popup.z_as_relative = false

	add_child(popup)

	# Setup with wave data
	popup.setup({
		"victory": victory,
		"rewards": rewards
	})

	# Connect closed signal to clean up
	popup.closed.connect(func(): popup.queue_free())

	print("[DefenseTowersUI] Showing wave %s popup (themed, z-index: 200)" % ("victory" if victory else "defeat"))

func _show_cumulative_rewards():
	"""Show cumulative rewards from battles that happened while UI was closed"""
	if not DefenseManager or not DefenseManager.instance:
		return

	var cumulative = DefenseManager.instance.get_cumulative_rewards()

	# Only show if there were battles
	if cumulative["total_waves"] == 0:
		return

	# Don't show cumulative rewards if this is the first wave (new player just starting)
	if DefenseManager.instance.is_first_wave:
		print("[DefenseTowersUI] Skipping cumulative rewards - player is new and hasn't completed first wave yet")
		return

	# Create themed popup to show battle summary
	var popup = BattleSummaryPopupScene.instantiate()

	# Set z-index to appear above battle arena
	popup.z_index = 200
	popup.z_as_relative = false

	add_child(popup)

	# Setup with cumulative data
	popup.setup(cumulative)

	# Reset cumulative rewards after popup is closed
	popup.closed.connect(func():
		DefenseManager.instance.reset_cumulative_rewards()
		popup.queue_free()
	)

	print("[DefenseTowersUI] Showing cumulative battle summary (themed, z-index: 200)")
