extends Node2D

@onready var dragon_display: DragonDisplay = $DragonDisplay
@onready var instructions_label: Label = $Instructions
@onready var collection_info_label: Label = $CollectionInfo

var factory: DragonFactory
var part_library: PartLibrary

func _ready():
	# Create and initialize systems
	part_library = PartLibrary.new()
	factory = DragonFactory.new()
	
	add_child(part_library)
	add_child(factory)
	
	# Connect signals
	factory.dragon_created.connect(_on_dragon_created)
	factory.dragon_name_generated.connect(_on_dragon_named)
	
	# Test: Create a random dragon
	var dragon = factory.create_random_dragon()
	dragon_display.set_dragon(dragon)
	_update_collection_info()
	
	# Print stats
	print("=== Dragon System Test Started ===")
	print("Dragon ID: %s" % dragon.dragon_id)
	print("Combination: %s" % dragon.get_combination_key())
	print("Attack: %d" % dragon.total_attack)
	print("Health: %d" % dragon.total_health)
	print("Speed: %d" % dragon.total_speed)

func _on_dragon_created(dragon: Dragon):
	print("Dragon created signal received: %s" % dragon.dragon_id)
	_update_collection_info()

func _on_dragon_named(dragon: Dragon, name: String):
	print("Dragon named: %s" % name)
	dragon_display.set_dragon(dragon)  # Refresh display with name

func _update_collection_info():
	var progress = factory.get_collection_progress()
	collection_info_label.text = "Collection Progress: %d/%d (%.1f%%)" % [
		progress.discovered,
		progress.total,
		progress.percentage
	]

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Press SPACE to create another dragon
			var dragon = factory.create_random_dragon()
			dragon_display.set_dragon(dragon)
			
			print("\n=== New Dragon Created ===")
			print("ID: %s" % dragon.dragon_id)
			print("Name: %s" % dragon.dragon_name)
			print("Combination: %s" % dragon.get_combination_key())
			print("Stats - ATK: %d | HP: %d | SPD: %d" % [
				dragon.total_attack, dragon.total_health, dragon.total_speed
			])
			
			# Check for synergy
			var head_element = DragonPart.Element.keys()[dragon.head_part.element]
			var body_element = DragonPart.Element.keys()[dragon.body_part.element]
			var tail_element = DragonPart.Element.keys()[dragon.tail_part.element]
			
			if head_element == body_element or body_element == tail_element or head_element == tail_element:
				print("⚡ SYNERGY BONUS ACTIVE! (+20% all stats)")
			
			_test_part_library()

func _test_part_library():
	# Quick test of part library functionality
	print("\n--- Part Library Test ---")
	var fire_heads = []
	var all_heads = part_library.get_parts_of_type(DragonPart.PartType.HEAD)
	
	for part in all_heads:
		if part.element == DragonPart.Element.FIRE:
			fire_heads.append(part)
	
	print("Total parts loaded: %d" % part_library.all_parts.size())
	print("Total head parts: %d" % all_heads.size())
	print("Fire head parts: %d" % fire_heads.size())
