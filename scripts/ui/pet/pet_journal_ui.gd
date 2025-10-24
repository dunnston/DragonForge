extends Control
class_name PetJournalUI

## Memory book showing pet's journey and statistics

# Node references
@onready var days_together_label: Label = %DaysTogetherLabel if has_node("%DaysTogetherLabel") else null
@onready var affection_label: Label = %AffectionLabel if has_node("%AffectionLabel") else null
@onready var expeditions_label: Label = %ExpeditionsLabel if has_node("%ExpeditionsLabel") else null
@onready var gold_earned_label: Label = %GoldEarnedLabel if has_node("%GoldEarnedLabel") else null
@onready var parts_found_label: Label = %PartsFoundLabel if has_node("%PartsFoundLabel") else null
@onready var favorite_dest_label: Label = %FavoriteDestLabel if has_node("%FavoriteDestLabel") else null
@onready var times_fed_label: Label = %TimesFedLabel if has_node("%TimesFedLabel") else null
@onready var times_petted_label: Label = %TimesPettedLabel if has_node("%TimesPettedLabel") else null

# Memorable moments
@onready var moments_container: VBoxContainer = %MomentsContainer if has_node("%MomentsContainer") else null
@onready var close_button: Button = %CloseButton if has_node("%CloseButton") else null

# State
var pet: PetDragon = null

func _ready():
	# Setup close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Load pet from manager
	if PetDragonManager and PetDragonManager.instance:
		pet = PetDragonManager.instance.get_pet_dragon()
		if pet:
			setup(pet)

func setup(new_pet: PetDragon):
	"""Setup journal with pet data"""
	pet = new_pet
	_populate_stats()
	_populate_moments()

	# Show the journal
	show()

func _populate_stats():
	"""Populate statistics page"""
	if not pet:
		return

	# Days together
	if days_together_label:
		days_together_label.text = "Days Together: %d" % pet.get_days_together()

	# Affection
	if affection_label:
		var tier = pet.get_affection_tier()
		var hearts = _get_affection_hearts(pet.affection)
		affection_label.text = "Affection: %s (%s)" % [hearts, tier]

	# Expeditions
	if expeditions_label:
		expeditions_label.text = "Total Expeditions: %d" % pet.expeditions_completed

	# Gold earned
	if gold_earned_label:
		gold_earned_label.text = "Gold Earned: %d" % pet.total_gold_earned

	# Parts found
	if parts_found_label:
		parts_found_label.text = "Parts Found: %d" % pet.total_parts_found

	# Favorite destination
	if favorite_dest_label:
		var dest = pet.favorite_destination if pet.favorite_destination != "" else "None yet"
		favorite_dest_label.text = "Favorite Place: %s" % dest.capitalize().replace("_", " ")

	# Times fed
	if times_fed_label:
		times_fed_label.text = "Times Fed: %d" % pet.times_fed

	# Times petted
	if times_petted_label:
		times_petted_label.text = "Times Petted: %d" % pet.times_petted

func _populate_moments():
	"""Populate memorable moments list"""
	if not pet or not moments_container:
		return

	# Clear existing moments
	for child in moments_container.get_children():
		child.queue_free()

	# Get sorted moments (most recent first)
	var moments = pet.get_memorable_moments_sorted()

	# Add moments to container
	for moment in moments:
		var moment_entry = _create_moment_entry(moment)
		moments_container.add_child(moment_entry)

func _create_moment_entry(moment: Dictionary) -> Control:
	"""Create a UI element for a memorable moment"""
	var entry = VBoxContainer.new()
	entry.add_theme_constant_override("separation", 4)

	# Get category icon
	var icon = _get_category_icon(moment.get("title", ""))

	# Title with icon
	var title_label = Label.new()
	title_label.text = "%s %s" % [icon, moment.get("title", "Unknown Event")]
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))  # Light yellow
	entry.add_child(title_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = moment.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	entry.add_child(desc_label)

	# Timestamp (relative time)
	var time_label = Label.new()
	time_label.text = "(%s)" % _get_relative_time(moment.get("timestamp", 0))
	time_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))  # Gray
	time_label.add_theme_font_size_override("font_size", 12)
	entry.add_child(time_label)

	# Separator
	var separator = HSeparator.new()
	entry.add_child(separator)

	return entry

func _get_affection_hearts(affection: int) -> String:
	"""Convert affection to heart string based on tier"""
	# Map tier to heart count (1-5 hearts) - matches pet_interaction_ui.gd
	var tier_hearts = {
		"Acquaintance": 1,
		"Friend": 2,
		"Companion": 3,
		"Best Friend": 4,
		"Soulbound": 5
	}

	var tier = pet.get_affection_tier() if pet else "Acquaintance"
	var filled = tier_hearts.get(tier, 1)
	var empty = 5 - filled
	return "❤️".repeat(filled) + "🤍".repeat(empty)

func _get_category_icon(title: String) -> String:
	"""Get icon based on title keywords"""
	var title_lower = title.to_lower()

	if "level" in title_lower or "gained" in title_lower:
		return "⭐"  # Leveling
	elif "friend" in title_lower or "companion" in title_lower or "affection" in title_lower or "bond" in title_lower:
		return "❤️"  # Affection
	elif "gift" in title_lower or "present" in title_lower:
		return "🎁"  # Gift
	elif "emergency" in title_lower or "rescue" in title_lower or "saved" in title_lower:
		return "⚠️"  # Emergency
	elif "exploration" in title_lower or "explored" in title_lower or "discovered" in title_lower or "expedition" in title_lower:
		return "🗺️"  # Exploration
	elif "milestone" in title_lower or "achievement" in title_lower or "reached" in title_lower:
		return "🏆"  # Milestone
	else:
		return "📝"  # Default

func _get_relative_time(timestamp: int) -> String:
	"""Convert unix timestamp to relative time string"""
	var current_time = Time.get_unix_time_from_system()
	var seconds_ago = current_time - timestamp

	if seconds_ago < 0:
		return "Just now"
	elif seconds_ago < 60:
		return "Just now"
	elif seconds_ago < 3600:
		var minutes = int(seconds_ago / 60)
		return "%d minute%s ago" % [minutes, "s" if minutes != 1 else ""]
	elif seconds_ago < 86400:
		var hours = int(seconds_ago / 3600)
		return "%d hour%s ago" % [hours, "s" if hours != 1 else ""]
	elif seconds_ago < 604800:
		var days = int(seconds_ago / 86400)
		return "%d day%s ago" % [days, "s" if days != 1 else ""]
	elif seconds_ago < 2592000:
		var weeks = int(seconds_ago / 604800)
		return "%d week%s ago" % [weeks, "s" if weeks != 1 else ""]
	else:
		var months = int(seconds_ago / 2592000)
		return "%d month%s ago" % [months, "s" if months != 1 else ""]

func _on_close_pressed():
	"""Close the journal"""
	queue_free()
