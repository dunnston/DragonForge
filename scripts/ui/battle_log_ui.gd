extends Control
class_name BattleLogUI

## UI for viewing battle history logs

@onready var battle_list: VBoxContainer = %BattleList
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var detail_text: RichTextLabel = %DetailText
@onready var close_button: Button = %CloseButton
@onready var stats_label: Label = %StatsLabel

var selected_record: BattleRecord = null

signal closed

func _ready():
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	refresh_battle_list()
	update_stats()

func refresh_battle_list():
	"""Populate the list with all battle records"""
	# Clear existing entries
	if battle_list:
		for child in battle_list.get_children():
			child.queue_free()

	if not BattleLogManager:
		return

	var battles = BattleLogManager.get_battle_history()

	if battles.is_empty():
		var no_battles = Label.new()
		no_battles.text = "No battles yet!"
		no_battles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_battles.add_theme_font_size_override("font_size", 18)
		battle_list.add_child(no_battles)
		return

	# Add each battle as an entry
	for record in battles:
		var entry = _create_battle_entry(record)
		battle_list.add_child(entry)

func _create_battle_entry(record: BattleRecord) -> Control:
	"""Create a battle entry panel"""
	var entry = Panel.new()
	entry.custom_minimum_size = Vector2(0, 80)

	# Style
	var style = StyleBoxFlat.new()
	if record.victory:
		style.bg_color = Color(0.1, 0.3, 0.1, 0.5)  # Green tint for victory
		style.border_color = Color(0.2, 0.8, 0.2, 1)
	else:
		style.bg_color = Color(0.3, 0.1, 0.1, 0.5)  # Red tint for defeat
		style.border_color = Color(0.8, 0.2, 0.2, 1)

	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	entry.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	entry.add_child(margin)

	var vbox = VBoxContainer.new()
	margin.add_child(vbox)

	# Top row: Wave number and result
	var hbox_top = HBoxContainer.new()
	vbox.add_child(hbox_top)

	var wave_label = Label.new()
	wave_label.text = "Wave %d" % record.wave_number
	wave_label.add_theme_font_size_override("font_size", 18)
	wave_label.add_theme_color_override("font_color", Color.WHITE)
	hbox_top.add_child(wave_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_top.add_child(spacer)

	var result_label = Label.new()
	result_label.text = "VICTORY" if record.victory else "DEFEAT"
	result_label.add_theme_font_size_override("font_size", 18)
	result_label.add_theme_color_override("font_color", Color.GREEN if record.victory else Color.RED)
	hbox_top.add_child(result_label)

	# Middle row: Quick stats
	var stats_text = "%s | %d rounds | %d enemies" % [
		record.get_date_time_string(),
		record.round_count,
		record.get_total_enemies()
	]

	var stats = Label.new()
	stats.text = stats_text
	stats.add_theme_font_size_override("font_size", 14)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(stats)

	# Bottom row: Rewards/losses
	var rewards_label = Label.new()
	if record.victory:
		rewards_label.text = "Rewards: +%d gold, +%d meat" % [record.rewards_gold, record.rewards_meat]
		rewards_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	else:
		if record.vault_gold_stolen > 0:
			rewards_label.text = "Lost: -%d gold stolen" % record.vault_gold_stolen
			rewards_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		else:
			rewards_label.text = "No rewards"
			rewards_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

	rewards_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(rewards_label)

	# Make entry clickable
	var button = Button.new()
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_battle_entry_clicked.bind(record))
	entry.add_child(button)

	return entry

func _on_battle_entry_clicked(record: BattleRecord):
	"""Show detailed view of a battle"""
	selected_record = record
	show_battle_details(record)

func show_battle_details(record: BattleRecord):
	"""Display detailed battle information"""
	if not detail_text:
		return

	var details = ""

	# Header
	details += "[center][b][color=yellow]═══ WAVE %d ═══[/color][/b][/center]\n" % record.wave_number
	details += "[center]%s[/center]\n\n" % record.get_date_time_string()

	# Result
	if record.victory:
		details += "[center][b][color=green]🐉 VICTORY 🐉[/color][/b][/center]\n\n"
	else:
		details += "[center][b][color=red]⚔ DEFEAT ⚔[/color][/b][/center]\n\n"

	# Battle Stats
	details += "[b]Battle Statistics:[/b]\n"
	details += "  Rounds: %d\n" % record.round_count
	details += "  Duration: %.1f seconds\n" % record.duration_seconds
	details += "  Active Towers: %d\n\n" % record.active_tower_count

	# Defenders
	details += "[b][color=lightblue]Defending Dragons:[/color][/b]\n"
	for defender in record.defenders:
		var status_icon = "✓" if defender.get("survived", true) else "💀"
		var status_color = "green" if defender.get("survived", true) else "red"
		details += "  [color=%s]%s[/color] %s (Lv %d)\n" % [status_color, status_icon, defender["dragon_name"], defender["level"]]
		details += "    [color=gray]Damage Dealt: %d | Damage Taken: %d[/color]\n" % [defender.get("damage_dealt", 0), defender.get("damage_taken", 0)]

	details += "\n"

	# Enemies
	details += "[b][color=orange]Enemy Forces:[/color][/b]\n"
	details += "  Total Enemies: %d\n" % record.get_total_enemies()
	details += "  Defeated: %d\n" % record.get_enemies_defeated()

	var enemy_types = {}
	for enemy in record.enemies:
		var enemy_type = enemy.get("type", "Unknown")
		enemy_types[enemy_type] = enemy_types.get(enemy_type, 0) + 1

	for enemy_type in enemy_types:
		details += "    %s x%d\n" % [enemy_type, enemy_types[enemy_type]]

	details += "\n"

	# Rewards/Losses
	if record.victory:
		details += "[b][color=yellow]Rewards:[/color][/b]\n"
		details += "  Gold: +%d\n" % record.rewards_gold
		details += "  Meat: +%d\n\n" % record.rewards_meat
	else:
		details += "[b][color=red]Losses:[/color][/b]\n"
		if record.vault_gold_stolen > 0:
			details += "  Gold Stolen: -%d\n" % record.vault_gold_stolen
		if record.tower_damage_dealt > 0:
			details += "  Tower Damage: -%d HP\n" % record.tower_damage_dealt
		if record.towers_destroyed > 0:
			details += "  Towers Destroyed: %d\n" % record.towers_destroyed
		details += "\n"

	# Combat Log
	if record.combat_log and not record.combat_log.is_empty():
		details += "[b]Combat Log:[/b]\n"
		details += "[color=gray]─────────────────────────────────────[/color]\n"
		details += record.combat_log

	detail_text.text = details

	# Make detail panel visible
	if detail_panel:
		detail_panel.visible = true

func update_stats():
	"""Update overall battle statistics"""
	if not stats_label or not BattleLogManager:
		return

	var total = BattleLogManager.get_total_battles()
	var victories = BattleLogManager.get_victory_count()
	var defeats = BattleLogManager.get_defeat_count()
	var win_rate = BattleLogManager.get_win_rate() * 100

	stats_label.text = "Total Battles: %d | Victories: %d | Defeats: %d | Win Rate: %.1f%%" % [
		total,
		victories,
		defeats,
		win_rate
	]

func _on_close_pressed():
	"""Close the battle log UI"""
	closed.emit()
	queue_free()
