#!/usr/bin/env python3
# Quick fix for the Array[String] type issue

with open('scripts/managers/dragon_name_manager.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the problematic lines
old_code = '''	if data.has("available_names"):
		available_names = data["available_names"].duplicate()

	if data.has("used_names"):
		used_names = data["used_names"].duplicate()'''

new_code = '''	if data.has("available_names"):
		var temp_available = data["available_names"].duplicate()
		available_names.clear()
		available_names.assign(temp_available)

	if data.has("used_names"):
		var temp_used = data["used_names"].duplicate()
		used_names.clear()
		used_names.assign(temp_used)'''

content = content.replace(old_code, new_code)

with open('scripts/managers/dragon_name_manager.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed dragon_name_manager.gd")
