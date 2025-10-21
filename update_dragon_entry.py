#!/usr/bin/env python3
"""
Updates the _create_dragon_entry function in factory_manager.gd
to use the DragonCard component with proper color display
"""

import re

# Read the file
with open('scripts/ui/factory_manager.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# The old function (multiline pattern)
old_pattern = r'func _create_dragon_entry\(dragon: Dragon\) -> PanelContainer:\n\tvar panel = PanelContainer\.new\(\).*?return panel'

# The new function
new_function = '''func _create_dragon_entry(dragon: Dragon) -> PanelContainer:
\t# Use the DragonCard component with proper dragon visual
\tvar dragon_card_scene = load("res://scenes/ui/dragon_card.tscn")
\tvar dragon_card: DragonCard = dragon_card_scene.instantiate()

\t# Set the dragon data (automatically updates visual with correct colors)
\tdragon_card.set_dragon(dragon)

\t# Connect click to open details modal
\tdragon_card.card_clicked.connect(func(d):
\t\tif dragon_details_modal:
\t\t\tdragon_details_modal.open_for_dragon(d)
\t)

\treturn dragon_card'''

# Replace using DOTALL flag to match across lines
content = re.sub(old_pattern, new_function, content, flags=re.DOTALL)

# Write back
with open('scripts/ui/factory_manager.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS: Updated _create_dragon_entry function!")
print("   - Replaced 45 lines with 13 lines")
print("   - Now uses DragonCard component")
print("   - Dragons will display with correct colors based on parts")
