#!/usr/bin/env python3
"""
Fix dragon details modal by adding DragonVisual properly
"""

import time

time.sleep(2)  # Wait for Godot

# Read the file
with open('scenes/ui/dragon_details_modal.tscn', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# The nodes to insert (after line 65 which should be "layout_mode = 2" after HSeparator)
dragon_visual_text = """
[node name="DragonVisualContainer" type="CenterContainer" parent="CenterContainer/PanelContainer/MarginContainer/VBoxContainer"]
layout_mode = 2
custom_minimum_size = Vector2(0, 150)

[node name="DragonVisual" parent="CenterContainer/PanelContainer/MarginContainer/VBoxContainer/DragonVisualContainer" instance=ExtResource("2_dragon_visual")]
unique_name_in_owner = true
scale = Vector2(0.3, 0.3)

[node name="HSeparator2_DragonSpacer" type="HSeparator" parent="CenterContainer/PanelContainer/MarginContainer/VBoxContainer"]
layout_mode = 2

"""

# Insert after line 65 (0-indexed = 64)
lines.insert(66, dragon_visual_text)

# Write back
with open('scenes/ui/dragon_details_modal.tscn', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("SUCCESS: Added DragonVisual to dragon_details_modal.tscn")
print("The modal should now display the dragon image properly")
