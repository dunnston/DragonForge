extends Node

# Test script to check dragon colors and parts
func _ready():
	print("=== Testing Dragon Colors & Parts ===")
	
	# Test PartLibrary access
	print("PartLibrary instance exists: ", PartLibrary != null)
	if PartLibrary:
		print("Total parts in library: ", PartLibrary.all_parts.size())
		
		# Test getting parts of each type
		var head_parts = PartLibrary.get_parts_of_type(DragonPart.PartType.HEAD)
		var body_parts = PartLibrary.get_parts_of_type(DragonPart.PartType.BODY)
		var tail_parts = PartLibrary.get_parts_of_type(DragonPart.PartType.TAIL)
		
		print("Head parts: ", head_parts.size())
		print("Body parts: ", body_parts.size())
		print("Tail parts: ", tail_parts.size())
		
		# Test individual parts
		if head_parts.size() > 0:
			var fire_head = null
			for part in head_parts:
				if part.element == DragonPart.Element.FIRE:
					fire_head = part
					break
			
			if fire_head:
				print("Fire head part found:")
				print("  Element: ", DragonPart.Element.keys()[fire_head.element])
				print("  Attack bonus: ", fire_head.attack_bonus)
			else:
				print("ERROR: No fire head part found!")
		
		# Test dragon creation
		var factory = DragonFactory.new()
		var dragon = factory.create_random_dragon()
		if dragon:
			print("\\nDragon created successfully:")
			print("  Name: ", dragon.dragon_name)
			print("  Head element: ", DragonPart.Element.keys()[dragon.head_part.element])
			print("  Body element: ", DragonPart.Element.keys()[dragon.body_part.element]) 
			print("  Tail element: ", DragonPart.Element.keys()[dragon.tail_part.element])
			print("  Attack: ", dragon.total_attack)
			print("  Health: ", dragon.total_health)
			print("  Speed: ", dragon.total_speed)
			
			# Test color function from DragonDisplay
			var display = preload("res://scripts/dragon_system/dragon_display.gd").new()
			var fire_color = display._get_element_color(DragonPart.Element.FIRE)
			var ice_color = display._get_element_color(DragonPart.Element.ICE)
			var lightning_color = display._get_element_color(DragonPart.Element.LIGHTNING)
			
			print("\\nColor test:")
			print("  Fire color: ", fire_color)
			print("  Ice color: ", ice_color)
			print("  Lightning color: ", lightning_color)
		else:
			print("ERROR: Failed to create dragon!")
	else:
		print("ERROR: PartLibrary not accessible!")
	
	print("=== Test Complete ===")
