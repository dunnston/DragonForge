extends Node2D
class_name DragonDisplay

@onready var head_sprite: ColorRect = $HeadSprite
@onready var body_sprite: ColorRect = $BodySprite
@onready var tail_sprite: ColorRect = $TailSprite
@onready var name_label: Label = $NameLabel
@onready var stats_label: Label = $StatsLabel

var dragon: Dragon

func set_dragon(new_dragon: Dragon):
	dragon = new_dragon
	_update_display()

func _update_display():
	if not dragon:
		return
	
	# Update name
	name_label.text = dragon.dragon_name
	
	# Update stats
	stats_label.text = "ATK: %d | HP: %d/%d | SPD: %d" % [
		dragon.total_attack,
		dragon.current_health,
		dragon.total_health,
		dragon.total_speed
	]
	
	# Update sprites (placeholder colored rectangles for now)
	_set_part_visual(head_sprite, dragon.head_part)
	_set_part_visual(body_sprite, dragon.body_part)
	_set_part_visual(tail_sprite, dragon.tail_part)

func _set_part_visual(color_rect: ColorRect, part: DragonPart):
	# Placeholder: color-coded rectangles
	# Your art teammate will replace with actual sprites
	var color = _get_element_color(part.element)
	color_rect.color = color
	
	# If actual textures exist:
	# if part.sprite_texture:
	#     sprite.texture = part.sprite_texture

func _get_element_color(element: DragonPart.Element) -> Color:
	match element:
		DragonPart.Element.FIRE:
			return Color.RED
		DragonPart.Element.ICE:
			return Color.CYAN
		DragonPart.Element.LIGHTNING:
			return Color.YELLOW
		DragonPart.Element.NATURE:
			return Color.GREEN
		DragonPart.Element.SHADOW:
			return Color.PURPLE
	return Color.WHITE
