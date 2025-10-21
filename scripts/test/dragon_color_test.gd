extends Control

## Test scene for dragon color system
## Allows interactive testing of different element combinations

@onready var dragon_visual: DragonVisual = %DragonBase

var current_head: DragonPart.Element = DragonPart.Element.FIRE
var current_body: DragonPart.Element = DragonPart.Element.NATURE
var current_tail: DragonPart.Element = DragonPart.Element.ICE

func _ready():
	_connect_buttons()
	_update_dragon()

func _connect_buttons():
	# Head buttons
	_connect_element_button("HeadOptions/FireHead", DragonPart.Element.FIRE, "head")
	_connect_element_button("HeadOptions/IceHead", DragonPart.Element.ICE, "head")
	_connect_element_button("HeadOptions/LightningHead", DragonPart.Element.LIGHTNING, "head")
	_connect_element_button("HeadOptions/NatureHead", DragonPart.Element.NATURE, "head")
	_connect_element_button("HeadOptions/ShadowHead", DragonPart.Element.SHADOW, "head")

	# Body buttons
	_connect_element_button("BodyOptions/FireBody", DragonPart.Element.FIRE, "body")
	_connect_element_button("BodyOptions/IceBody", DragonPart.Element.ICE, "body")
	_connect_element_button("BodyOptions/LightningBody", DragonPart.Element.LIGHTNING, "body")
	_connect_element_button("BodyOptions/NatureBody", DragonPart.Element.NATURE, "body")
	_connect_element_button("BodyOptions/ShadowBody", DragonPart.Element.SHADOW, "body")

	# Tail buttons
	_connect_element_button("TailOptions/FireTail", DragonPart.Element.FIRE, "tail")
	_connect_element_button("TailOptions/IceTail", DragonPart.Element.ICE, "tail")
	_connect_element_button("TailOptions/LightningTail", DragonPart.Element.LIGHTNING, "tail")
	_connect_element_button("TailOptions/NatureTail", DragonPart.Element.NATURE, "tail")
	_connect_element_button("TailOptions/ShadowTail", DragonPart.Element.SHADOW, "tail")

	# Preset buttons
	$MarginContainer/VBox/HBox/Controls/Presets/AllFire.pressed.connect(_on_preset_all_fire)
	$MarginContainer/VBox/HBox/Controls/Presets/AllIce.pressed.connect(_on_preset_all_ice)
	$MarginContainer/VBox/HBox/Controls/Presets/Rainbow.pressed.connect(_on_preset_rainbow)
	$MarginContainer/VBox/HBox/Controls/Presets/Random.pressed.connect(_on_preset_random)

func _connect_element_button(path: String, element: DragonPart.Element, part: String):
	var button = $MarginContainer/VBox/HBox/Controls.get_node(path) as Button
	if button:
		button.pressed.connect(func(): _on_element_selected(element, part))

func _on_element_selected(element: DragonPart.Element, part: String):
	match part:
		"head":
			current_head = element
		"body":
			current_body = element
		"tail":
			current_tail = element

	_update_dragon()

func _update_dragon():
	if dragon_visual:
		dragon_visual.set_dragon_colors(current_head, current_body, current_tail)
		print("Dragon colors updated: Head=%s, Body=%s, Tail=%s" % [
			DragonPart.Element.keys()[current_head],
			DragonPart.Element.keys()[current_body],
			DragonPart.Element.keys()[current_tail]
		])

func _on_preset_all_fire():
	current_head = DragonPart.Element.FIRE
	current_body = DragonPart.Element.FIRE
	current_tail = DragonPart.Element.FIRE
	_update_dragon()

func _on_preset_all_ice():
	current_head = DragonPart.Element.ICE
	current_body = DragonPart.Element.ICE
	current_tail = DragonPart.Element.ICE
	_update_dragon()

func _on_preset_rainbow():
	current_head = DragonPart.Element.FIRE
	current_body = DragonPart.Element.NATURE
	current_tail = DragonPart.Element.ICE
	_update_dragon()

func _on_preset_random():
	var elements = DragonPart.Element.values()
	current_head = elements[randi() % elements.size()]
	current_body = elements[randi() % elements.size()]
	current_tail = elements[randi() % elements.size()]
	_update_dragon()
