#!/usr/bin/env python3
"""
Fix dragon details modal by adding DragonVisual properly
"""

import time

time.sleep(3)  # Wait for Godot to release file

# Read the file
with open('scenes/ui/dragon_details_modal.tscn', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find the line with HSeparator after Header
dragon_visual_nodes = """
[node name="DragonVisualContainer" type="CenterContainer" parent="CenterContainer/PanelContainer/MarginContainer/VBoxContainer"]
layout_mode = 2
custom_minimum_size = Vector2(0, 150)

[node name="DragonVisual" parent="CenterContainer/PanelContainer/MarginContainer/VBoxContainer/DragonVisualContainer" instance=ExtResource("2_dragon_visual")]
unique_name_in_owner = true
scale = Vector2(0.3, 0.3)

[node name="HSeparator2_DragonSpacer" type="HSeparator" parent="CenterContainer/PanelContainer/MarginContainer/VBoxContainer"]
layout_mode = 2

"""

# Find and insert after the first HSeparator
new_lines = []
inserted = False
for i, line in enumerate(lines):
    new_lines.append(line)
    # Look for HSeparator right after Header section
    if not inserted and '[node name="HSeparator" type="HSeparator"' in line and i > 40:
        # Add the next line too (layout_mode)
        if i + 1 < len(lines):
            new_lines.append(lines[i + 1])
            # Insert dragon visual nodes
            new_lines.append(dragon_visual_nodes)
            inserted = True
            # Skip the next line since we already added it
            continue

# Write back
with open('scenes/ui/dragon_details_modal.tscn', 'w', encoding='utf-8') as f:
    # Handle the skipped line
    result_lines = []
    skip_next = False
    for i, line in enumerate(new_lines):
        if skip_next:
            skip_next = False
            continue
        result_lines.append(line)
        # If this is the HSeparator line and next line is layout_mode, check if we're about to add dragon visual
        if '[node name="HSeparator" type="HSeparator"' in line and i < len(new_lines) - 1:
            if 'layout_mode' in new_lines[i + 1] and i + 2 < len(new_lines) and 'DragonVisualContainer' in new_lines[i + 2]:
                skip_next = True  # Skip the duplicate layout_mode line

    f.writelines(new_lines)

print("SUCCESS: Added DragonVisual to modal")
