extends Node
class_name DragonFactory

signal dragon_created(dragon: Dragon)
signal dragon_name_generated(dragon: Dragon, name: String) 
signal mutation_discovered(dragon: Dragon)  # Holy Shit Moment!

var active_dragons: Array[Dragon] = []
var dragon_collection: Dictionary = {}  # combination_key -> bool (discovered)

func create_dragon(head: DragonPart, body: DragonPart, tail: DragonPart) -> Dragon:
	if not head or not body or not tail:
		push_error("Cannot create dragon with missing parts")
		return null

	var dragon = Dragon.new(head, body, tail)

	# Check for Chimera Mutation (Holy Shit Moment!)
	if DragonStateManager.instance:
		DragonStateManager.instance.attempt_chimera_mutation(dragon)
		# Register dragon for state management
		DragonStateManager.instance.register_dragon(dragon)

	active_dragons.append(dragon)

	# Track collection
	var combo_key = dragon.get_combination_key()
	if not dragon_collection.has(combo_key):
		dragon_collection[combo_key] = true
		print("New dragon discovered: %s" % combo_key)

	dragon_created.emit(dragon)

	# Trigger AI name generation (async)
	_generate_dragon_name(dragon)

	return dragon

func _generate_dragon_name(dragon: Dragon):
	# Placeholder for Orca AI integration
	# Your teammate will implement the actual Orca call
	dragon.dragon_name = await _request_ai_name(dragon)
	dragon_name_generated.emit(dragon, dragon.dragon_name)

func _request_ai_name(dragon: Dragon) -> String:
	# === ORCA AI INTEGRATION POINT ===
	# Replace this function with actual Orca AI call
	
	# Expected input: dragon part combination
	# Expected output: string (dragon name)
	
	var prompt = "Generate a fantasy dragon name for: %s head, %s body, %s tail" % [
		DragonPart.Element.keys()[dragon.head_part.element],
		DragonPart.Element.keys()[dragon.body_part.element],
		DragonPart.Element.keys()[dragon.tail_part.element]
	]
	
	# TODO: Call Orca AI Engine here
	# var ai_response = await OrcaAI.generate_text(prompt)
	# return ai_response
	
	# Fallback for now...
	return await _generate_fallback_name(dragon)

func _generate_fallback_name(dragon: Dragon) -> String:
	# Temporary fallback names
	var element_names = {
		DragonPart.Element.FIRE: "Pyro",
		DragonPart.Element.ICE: "Frost",
		DragonPart.Element.LIGHTNING: "Volt",
		DragonPart.Element.NATURE: "Terra",
		DragonPart.Element.SHADOW: "Umbra"
	}
	
	# Simulate API delay - use Engine for non-scene-tree dependent delay
	for i in 30:  # Simple frame-based delay (about 0.5 seconds at 60 FPS)
		await Engine.get_main_loop().process_frame
	
	var prefix = element_names[dragon.head_part.element]
	var suffix = element_names[dragon.body_part.element].to_lower()
	return "%s%s the Wyrm" % [prefix, suffix]

func create_random_dragon() -> Dragon:
	var head = PartLibrary.instance.get_random_part(DragonPart.PartType.HEAD)
	var body = PartLibrary.instance.get_random_part(DragonPart.PartType.BODY)
	var tail = PartLibrary.instance.get_random_part(DragonPart.PartType.TAIL)
	return create_dragon(head, body, tail)

func get_dragon_by_id(dragon_id: String) -> Dragon:
	for dragon in active_dragons:
		if dragon.dragon_id == dragon_id:
			return dragon
	return null

func remove_dragon(dragon: Dragon):
	active_dragons.erase(dragon)

func get_collection_progress() -> Dictionary:
	var total_combinations = 125  # 5^3
	var discovered = dragon_collection.size()
	return {
		"discovered": discovered,
		"total": total_combinations,
		"percentage": (discovered / float(total_combinations)) * 100
	}
