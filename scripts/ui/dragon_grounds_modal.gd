extends Control
class_name DragonGroundsModal

# Dragon Grounds - View all dragons in a grid with hover tooltips

const DragonCardSmallScene = preload("res://scenes/ui/dragon_card_small.tscn")

@onready var close_button = $Panel/MarginContainer/VBox/Header/CloseButton
@onready var dragon_grid = $Panel/MarginContainer/VBox/ScrollContainer/DragonGrid
@onready var tooltip_panel = $TooltipPanel
@onready var tooltip_name = $TooltipPanel/TooltipVBox/NameLabel
@onready var tooltip_stats = $TooltipPanel/TooltipVBox/StatsLabel
@onready var tooltip_health = $TooltipPanel/TooltipVBox/HealthLabel
@onready var tooltip_hunger = $TooltipPanel/TooltipVBox/HungerLabel
@onready var tooltip_fatigue = $TooltipPanel/TooltipVBox/FatigueLabel
@onready var dragon_count_label = $Panel/MarginContainer/VBox/Header/CountLabel

var dragon_factory: DragonFactory

signal closed()
signal dragon_clicked(dragon: Dragon)

func _ready():
	# Hide by default
	visible = false

	# Connect close button
	close_button.pressed.connect(_on_close_pressed)

	# Hide tooltip initially
	tooltip_panel.visible = false

func open(factory: DragonFactory):
	"""Open the modal and populate with dragons"""
	dragon_factory = factory
	visible = true

	# Populate dragons
	_populate_dragons()

func _populate_dragons():
	"""Populate the grid with dragon cards"""
	# Clear existing cards
	for child in dragon_grid.get_children():
		child.queue_free()

	if not dragon_factory:
		print("[DragonGrounds] No dragon factory provided!")
		return

	var dragons = dragon_factory.get_all_dragons()

	# Update count label
	dragon_count_label.text = "Dragons: %d" % dragons.size()

	# Create card for each dragon
	for dragon in dragons:
		var card = DragonCardSmallScene.instantiate()
		card.setup(dragon)

		# Connect signals
		card.card_clicked.connect(_on_dragon_card_clicked)
		card.card_hovered.connect(_on_dragon_card_hovered)
		card.card_unhovered.connect(_on_dragon_card_unhovered)

		dragon_grid.add_child(card)

	print("[DragonGrounds] Populated with %d dragons" % dragons.size())

func _on_close_pressed():
	"""Close the modal"""
	visible = false
	tooltip_panel.visible = false
	closed.emit()

func _on_dragon_card_clicked(dragon: Dragon):
	"""Handle dragon card click - emit signal and close modal"""
	print("[DragonGrounds] Dragon clicked: %s" % dragon.dragon_name)

	# Hide tooltip
	tooltip_panel.visible = false

	# Close modal
	visible = false

	# Emit signal so factory manager can open appropriate modal
	dragon_clicked.emit(dragon)
	closed.emit()

func _on_dragon_card_hovered(dragon: Dragon):
	"""Show tooltip when hovering a dragon card"""
	if not dragon:
		return

	# Update tooltip content
	tooltip_name.text = dragon.dragon_name
	if dragon.is_chimera_mutation:
		tooltip_name.text += " ⭐ CHIMERA"

	# Stats
	var stats_text = "ATK: %d | HP: %d | SPD: %d" % [
		dragon.get_attack(),
		dragon.get_health(),
		dragon.get_speed()
	]
	tooltip_stats.text = stats_text

	# Health
	var health_pct = (float(dragon.current_health) / float(dragon.get_health())) * 100
	tooltip_health.text = "Health: %.0f%%" % health_pct

	# Hunger
	var hunger_pct = dragon.hunger_level * 100
	tooltip_hunger.text = "Hunger: %.0f%%" % hunger_pct

	# Fatigue
	var fatigue_pct = dragon.fatigue_level * 100
	tooltip_fatigue.text = "Fatigue: %.0f%%" % fatigue_pct

	# Position tooltip near mouse
	tooltip_panel.visible = true
	_update_tooltip_position()

func _on_dragon_card_unhovered():
	"""Hide tooltip when not hovering"""
	tooltip_panel.visible = false

func _update_tooltip_position():
	"""Position tooltip near mouse cursor"""
	var mouse_pos = get_viewport().get_mouse_position()

	# Offset from cursor
	var offset = Vector2(20, 20)
	var tooltip_size = tooltip_panel.size

	# Keep within screen bounds
	var screen_size = get_viewport_rect().size
	var pos = mouse_pos + offset

	# Check right edge
	if pos.x + tooltip_size.x > screen_size.x:
		pos.x = mouse_pos.x - tooltip_size.x - 20

	# Check bottom edge
	if pos.y + tooltip_size.y > screen_size.y:
		pos.y = mouse_pos.y - tooltip_size.y - 20

	tooltip_panel.position = pos

func _process(_delta):
	"""Update tooltip position while hovering"""
	if tooltip_panel.visible:
		_update_tooltip_position()

func refresh():
	"""Refresh the dragon display"""
	if visible:
		_populate_dragons()
