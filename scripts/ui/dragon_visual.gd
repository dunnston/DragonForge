extends Node2D
class_name DragonVisual

## Visual representation of a dragon using shader-based colorization
## Uses the mask texture to color head, body, and tail independently

@onready var sprite: Sprite2D = %Sprite2D

# Element to color mapping
const ELEMENT_COLORS = {
	DragonPart.Element.FIRE: Color("#FF6B35"),      # Orange-red
	DragonPart.Element.ICE: Color("#6FDBFF"),       # Light cyan
	DragonPart.Element.LIGHTNING: Color("#FFEB3B"), # Bright yellow
	DragonPart.Element.NATURE: Color("#4CAF50"),    # Green
	DragonPart.Element.SHADOW: Color("#6A0572")     # Dark purple
}

func _ready():
	# Default colors are set in the scene
	pass

func set_dragon_colors(head_element: DragonPart.Element, body_element: DragonPart.Element, tail_element: DragonPart.Element):
	"""Set the dragon's colors based on its part elements"""
	var head_color = get_element_color(head_element)
	var body_color = get_element_color(body_element)
	var tail_color = get_element_color(tail_element)

	apply_colors(head_color, body_color, tail_color)

func set_dragon_colors_from_parts(head_part: DragonPart, body_part: DragonPart, tail_part: DragonPart):
	"""Set the dragon's colors based on DragonPart objects"""
	if head_part and body_part and tail_part:
		set_dragon_colors(head_part.element, body_part.element, tail_part.element)

func apply_colors(head_color: Color, body_color: Color, tail_color: Color):
	"""Apply colors directly to the shader"""
	if not sprite or not sprite.material:
		push_error("[DragonVisual] Sprite or material not found!")
		return

	var material = sprite.material as ShaderMaterial
	if not material:
		push_error("[DragonVisual] ShaderMaterial not found!")
		return

	material.set_shader_parameter("head_color", head_color)
	material.set_shader_parameter("body_color", body_color)
	material.set_shader_parameter("tail_color", tail_color)

func get_element_color(element: DragonPart.Element) -> Color:
	"""Get the color associated with an element"""
	return ELEMENT_COLORS.get(element, Color.WHITE)

func set_scale_uniform(scale_factor: float):
	"""Set uniform scale for the dragon visual"""
	scale = Vector2(scale_factor, scale_factor)

func set_modulate_tint(tint: Color):
	"""Apply an additional tint/modulation to the entire dragon"""
	if sprite:
		sprite.modulate = tint
