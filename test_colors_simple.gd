extends Node

# Simple color test without async issues
func _ready():
	print("=== Simple Dragon Color Test ===")
	
	# Test PartLibrary access
	if not PartLibrary:
		print("ERROR: PartLibrary not accessible!")
		return
		
	print("PartLibrary found: ", PartLibrary.all_parts.size(), " parts")
	
	# Get one part of each element for testing
	var fire_head = null
	var ice_body = null
	var lightning_tail = null
	
	for part in PartLibrary.get_parts_of_type(DragonPart.PartType.HEAD):
		if part.element == DragonPart.Element.FIRE:
			fire_head = part
			break
	
	for part in PartLibrary.get_parts_of_type(DragonPart.PartType.BODY):
		if part.element == DragonPart.Element.ICE:
			ice_body = part
			break
	
	for part in PartLibrary.get_parts_of_type(DragonPart.PartType.TAIL):
		if part.element == DragonPart.Element.LIGHTNING:
			lightning_tail = part
			break
	
	if fire_head and ice_body and lightning_tail:
		print("Parts found successfully:")
		print("  Fire head: ", DragonPart.Element.keys()[fire_head.element])
		print("  Ice body: ", DragonPart.Element.keys()[ice_body.element])
		print("  Lightning tail: ", DragonPart.Element.keys()[lightning_tail.element])
		
		# Create dragon directly (no factory async issues)
		var dragon = Dragon.new(fire_head, ice_body, lightning_tail)
		dragon.dragon_name = "Test Dragon"
		
		if dragon:
			print("\\nDragon created successfully:")
			print("  Attack: ", dragon.total_attack)
			print("  Health: ", dragon.total_health) 
			print("  Speed: ", dragon.total_speed)
			
			# Test color functions
			var display = DragonDisplay.new()
			var fire_color = display._get_element_color(DragonPart.Element.FIRE)
			var ice_color = display._get_element_color(DragonPart.Element.ICE)
			var lightning_color = display._get_element_color(DragonPart.Element.LIGHTNING)
			var nature_color = display._get_element_color(DragonPart.Element.NATURE)
			var shadow_color = display._get_element_color(DragonPart.Element.SHADOW)
			
			print("\\nColor test results:")
			print("  Fire: ", fire_color, " (should be red)")
			print("  Ice: ", ice_color, " (should be cyan)")
			print("  Lightning: ", lightning_color, " (should be yellow)")
			print("  Nature: ", nature_color, " (should be green)")
			print("  Shadow: ", shadow_color, " (should be purple)")
		else:
			print("ERROR: Failed to create dragon!")
	else:
		print("ERROR: Could not find required parts!")
		print("  Fire head found: ", fire_head != null)
		print("  Ice body found: ", ice_body != null)
		print("  Lightning tail found: ", lightning_tail != null)
	
	print("=== Color Test Complete ===")
