extends Node
class_name DragonFactory

signal dragon_created(dragon: Dragon)
signal dragon_name_generated(dragon: Dragon, name: String)
signal mutation_discovered(dragon: Dragon)  # Holy Shit Moment!
signal pet_introduction_completed(pet: PetDragon)  # Emitted when pet intro popup closes

var active_dragons: Array[Dragon] = []
var dragon_collection: Dictionary = {}  # combination_key -> bool (discovered)

func create_dragon(head: DragonPart, body: DragonPart, tail: DragonPart) -> Dragon:
	if not head or not body or not tail:
		push_error("Cannot create dragon with missing parts")
		return null

	# Check if this should be the first pet dragon
	var is_first_dragon = active_dragons.is_empty()
	var needs_pet = PetDragonManager and PetDragonManager.instance and not PetDragonManager.instance.has_pet()

	var dragon: Dragon

	if is_first_dragon and needs_pet:
		# Create pet dragon instead of regular dragon
		dragon = PetDragonManager.instance.create_pet_dragon(head, body, tail)
		print("[DragonFactory] Created first dragon as PET DRAGON")

		# Show pet introduction popup after name is generated
		_show_pet_introduction_popup(dragon)
	else:
		# Create regular dragon
		dragon = Dragon.new(head, body, tail)

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
	# Check if this is a pet dragon - pets get AI/fallback names
	if dragon is PetDragon:
		# Placeholder for Orca AI integration
		# Your teammate will implement the actual Orca call
		dragon.dragon_name = await _request_ai_name(dragon)
	else:
		# Non-pet dragons get names from the curated list
		if DragonNameManager and DragonNameManager.instance:
			dragon.dragon_name = DragonNameManager.instance.get_random_name()
		else:
			# Fallback if name manager isn't available
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

func get_all_dragons() -> Array[Dragon]:
	"""Returns a copy of all active dragons"""
	return active_dragons.duplicate()

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

# === SAVE/LOAD SERIALIZATION ===

func to_dict() -> Dictionary:
	"""Serialize dragon factory state for saving"""
	var data = {
		"dragons": [],
		"dragon_collection": dragon_collection.duplicate()
	}

	# Serialize each dragon
	for dragon in active_dragons:
		data["dragons"].append(dragon.to_dict())

	return data

func from_dict(data: Dictionary):
	"""Restore dragon factory state from saved data"""
	# Clear existing dragons
	active_dragons.clear()

	# Restore dragon collection
	if data.has("dragon_collection"):
		dragon_collection = data["dragon_collection"].duplicate()

	# Restore dragons
	if data.has("dragons"):
		for dragon_data in data["dragons"]:
			var dragon: Dragon

			# Check if this is a pet dragon
			if dragon_data.get("is_pet", false):
				# Create PetDragon and register with PetDragonManager
				dragon = PetDragon.new()
				dragon.from_dict(dragon_data)

				# Register as the pet dragon
				if PetDragonManager and PetDragonManager.instance:
					PetDragonManager.instance.pet_dragon = dragon
					print("[DragonFactory] Restored PET dragon: %s (Level %d, Affection %d)" % [
						dragon.dragon_name,
						dragon.level,
						dragon.affection if dragon is PetDragon else 0
					])
			else:
				# Create regular dragon
				dragon = Dragon.new()
				dragon.from_dict(dragon_data)
				print("[DragonFactory] Restored dragon: %s (Level %d)" % [dragon.dragon_name, dragon.level])

			active_dragons.append(dragon)

			# Re-register with DragonStateManager
			if DragonStateManager and DragonStateManager.instance:
				DragonStateManager.instance.register_dragon(dragon)

# === PET DRAGON INTEGRATION ===

func _show_pet_introduction_popup(pet: Dragon):
	"""Show the pet introduction popup after the pet dragon's name is generated"""
	# Wait for name to be generated
	if pet.dragon_name == "":
		await dragon_name_generated

	# Wait one frame to ensure UI is ready
	await Engine.get_main_loop().process_frame

	# Load and show pet introduction popup
	var popup_scene = load("res://scenes/ui/pet/pet_introduction_popup.tscn")
	if not popup_scene:
		push_error("[DragonFactory] Failed to load pet introduction popup scene!")
		pet_introduction_completed.emit(pet)  # Still emit so game continues
		return

	var popup = popup_scene.instantiate()

	# Add to scene tree
	var root = Engine.get_main_loop().root
	root.add_child(popup)

	# Setup popup with pet dragon
	if popup.has_method("setup"):
		popup.setup(pet)
		popup.visible = true
		print("[DragonFactory] Showing pet introduction popup for %s" % pet.dragon_name)
	else:
		push_error("[DragonFactory] Pet introduction popup missing setup() method!")
		pet_introduction_completed.emit(pet)
		return

	# Connect to popup signals
	if popup.has_signal("name_confirmed"):
		popup.name_confirmed.connect(func(_name):
			print("[DragonFactory] Pet introduction popup closed")
			# Wait a frame for popup to actually close
			await Engine.get_main_loop().process_frame
			pet_introduction_completed.emit(pet)
		)
