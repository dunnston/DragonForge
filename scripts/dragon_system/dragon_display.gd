extends Node2D
class_name DragonDisplay

## Displays a dragon with visual representation and stats
## Now uses shader-based colorization for realistic dragon appearance

@onready var dragon_visual: DragonVisual = %DragonVisual
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

	# Update dragon visual with shader-based coloring
	if dragon_visual:
		dragon_visual.set_dragon_colors_from_parts(
			dragon.head_part,
			dragon.body_part,
			dragon.tail_part
		)
