# REPLACE the _create_dragon_entry function in factory_manager.gd (lines 381-426)
# WITH THIS SIMPLIFIED VERSION:

func _create_dragon_entry(dragon: Dragon) -> PanelContainer:
	# Use the DragonCard component with proper dragon visual
	var dragon_card_scene = load("res://scenes/ui/dragon_card.tscn")
	var dragon_card: DragonCard = dragon_card_scene.instantiate()

	# Set the dragon data (automatically updates visual with correct colors)
	dragon_card.set_dragon(dragon)

	# Connect click to open details modal
	dragon_card.card_clicked.connect(func(d):
		if dragon_details_modal:
			dragon_details_modal.open_for_dragon(d)
	)

	return dragon_card

# This replaces 45 lines of manual UI creation with 13 lines!
# Benefits:
# - Shows correct dragon visual with colors based on parts
# - Reuses DragonCard component
# - Much simpler code
# - Automatically updates when dragon changes
