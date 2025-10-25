extends Control
class_name PetInteractionUI

## Main interaction modal for the pet dragon
## Shows stats, actions, and exploration status

# Constants
const FOOD_ITEM_ID: String = "food"  # Item to consume when feeding
const HEALTH_POTION_ID: String = "health_potion"  # Item to consume when healing

# Node references - Header
@onready var name_label: Label = %NameLabel if has_node("%NameLabel") else null
@onready var level_label: Label = %LevelLabel if has_node("%LevelLabel") else null
@onready var subtitle_label: Label = %SubtitleLabel if has_node("%SubtitleLabel") else null

# Node references - Dragon panel
@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite if has_node("%AnimatedSprite") else null
@onready var dialogue_label: Label = %DialogueLabel if has_node("%DialogueLabel") else null
@onready var mood_label: Label = %MoodLabel if has_node("%MoodLabel") else null

# Node references - Bond panel
@onready var affection_label: Label = %AffectionLabel if has_node("%AffectionLabel") else null
@onready var tier_label: Label = %TierLabel if has_node("%TierLabel") else null
@onready var personality_label: Label = %PersonalityLabel if has_node("%PersonalityLabel") else null
@onready var personality_desc: Label = %PersonalityDesc if has_node("%PersonalityDesc") else null

# Node references - Exploration section
@onready var exploration_status_label: Label = %ExplorationStatusLabel if has_node("%ExplorationStatusLabel") else null
@onready var exploration_progress: ProgressBar = %ExplorationProgress if has_node("%ExplorationProgress") else null
@onready var time_label: Label = %TimeLabel if has_node("%TimeLabel") else null
@onready var rewards_label: Label = %RewardsLabel if has_node("%RewardsLabel") else null
@onready var recall_button: Button = %RecallButton if has_node("%RecallButton") else null
@onready var exploration_buttons: GridContainer = %ExplorationButtons if has_node("%ExplorationButtons") else null
@onready var forest_button: Button = %ForestButton if has_node("%ForestButton") else null
@onready var tundra_button: Button = %TundraButton if has_node("%TundraButton") else null
@onready var peak_button: Button = %PeakButton if has_node("%PeakButton") else null
@onready var caves_button: Button = %CavesButton if has_node("%CavesButton") else null

# Node references - Vitals section
@onready var hp_bar: ProgressBar = %HPBar if has_node("%HPBar") else null
@onready var hp_label: Label = %HPLabel if has_node("%HPLabel") else null
@onready var heal_button: Button = %HealButton if has_node("%HealButton") else null
@onready var hunger_bar: ProgressBar = %HungerBar if has_node("%HungerBar") else null
@onready var hunger_label: Label = %HungerLabel if has_node("%HungerLabel") else null
@onready var feed_button: Button = %FeedButton if has_node("%FeedButton") else null
@onready var energy_bar: ProgressBar = %EnergyBar if has_node("%EnergyBar") else null
@onready var energy_label: Label = %EnergyLabel if has_node("%EnergyLabel") else null
@onready var rest_button: Button = %RestButton if has_node("%RestButton") else null
@onready var xp_bar: ProgressBar = %XPBar if has_node("%XPBar") else null
@onready var xp_label: Label = %XPLabel if has_node("%XPLabel") else null

# Node references - Achievements
@onready var achievements_label: Label = %AchievementsLabel if has_node("%AchievementsLabel") else null

# Node references - Action buttons
@onready var pet_button: Button = %PetButton if has_node("%PetButton") else null
@onready var treat_button: Button = %TreatButton if has_node("%TreatButton") else null
@onready var gift_button: Button = %GiftButton if has_node("%GiftButton") else null
@onready var talk_button: Button = %TalkButton if has_node("%TalkButton") else null
@onready var journal_button: Button = %JournalButton if has_node("%JournalButton") else null
@onready var stats_button: Button = %StatsButton if has_node("%StatsButton") else null
@onready var close_button: Button = %CloseButton if has_node("%CloseButton") else null
@onready var close_button_x: Button = %CloseButtonX if has_node("%CloseButtonX") else null

# State
var pet: PetDragon = null
var update_timer: Timer
var walking_character: Node = null  # Reference to the walking pet character

func _ready():
	# Setup buttons
	if pet_button:
		pet_button.pressed.connect(_on_pet_pressed)
	if treat_button:
		treat_button.pressed.connect(_on_treat_pressed)
	if gift_button:
		gift_button.pressed.connect(_on_gift_pressed)
	# Talk and Stats buttons removed - not useful enough
	#if talk_button:
	#	talk_button.pressed.connect(_on_talk_pressed)
	#if stats_button:
	#	stats_button.pressed.connect(_on_stats_pressed)

	# Hide the buttons
	if talk_button:
		talk_button.hide()
	if stats_button:
		stats_button.hide()

	if journal_button:
		journal_button.pressed.connect(_on_journal_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if close_button_x:
		close_button_x.pressed.connect(_on_close_pressed)

	# Setup exploration buttons
	if forest_button:
		forest_button.pressed.connect(func(): _on_explore_destination_pressed("ancient_forest"))
	if tundra_button:
		tundra_button.pressed.connect(func(): _on_explore_destination_pressed("frozen_tundra"))
	if peak_button:
		peak_button.pressed.connect(func(): _on_explore_destination_pressed("thunder_peak"))
	if caves_button:
		caves_button.pressed.connect(func(): _on_explore_destination_pressed("volcanic_caves"))
	if recall_button:
		recall_button.pressed.connect(_on_recall_pressed)

	# Setup vitals buttons
	if heal_button:
		heal_button.pressed.connect(_on_heal_pressed)
	if feed_button:
		feed_button.pressed.connect(_on_feed_pressed)
	if rest_button:
		rest_button.pressed.connect(_on_rest_pressed)

	# Setup update timer for dialogue and general updates
	update_timer = Timer.new()
	update_timer.wait_time = 15.0  # Update every 15 seconds (dialogue changes less frequently)
	update_timer.timeout.connect(_update_display)
	add_child(update_timer)
	update_timer.start()

	# Setup fast update timer for real-time exploration progress
	var exploration_timer = Timer.new()
	exploration_timer.name = "ExplorationUpdateTimer"
	exploration_timer.wait_time = 1.0  # Update every 1 second for smooth progress
	exploration_timer.timeout.connect(_update_exploration_status)
	add_child(exploration_timer)
	exploration_timer.start()

	# Setup dragon animation
	_setup_dragon_animation()

	# Pause the walking character animation
	_pause_walking_character()

	# Load pet from manager
	if PetDragonManager and PetDragonManager.instance:
		pet = PetDragonManager.instance.get_pet_dragon()
		if pet:
			_update_display()

func setup(new_pet: PetDragon):
	"""Setup the UI with a specific pet"""
	pet = new_pet
	_update_display()

func _setup_dragon_animation():
	"""Setup the animated dragon sprite"""
	if not animated_sprite:
		return

	# Load the sprite sheet
	var texture = load("res://assets/sprites/Playing.png")
	if not texture:
		print("[PetInteractionUI] Failed to load Playing.png sprite sheet")
		return

	# Get texture dimensions to calculate frame size
	var texture_width = texture.get_width()
	var texture_height = texture.get_height()

	# The sprite sheet is 6x6 (36 frames)
	var columns = 6
	var rows = 6
	var frame_width = texture_width / columns
	var frame_height = texture_height / rows

	print("[PetInteractionUI] Sprite sheet: %dx%d, Frame size: %dx%d" % [texture_width, texture_height, frame_width, frame_height])

	# Create SpriteFrames
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("playing")

	# Extract each frame from the sprite sheet
	for row in range(rows):
		for col in range(columns):
			var atlas = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
			sprite_frames.add_frame("playing", atlas)

	# Set the animation speed (slower for smoother animation)
	sprite_frames.set_animation_speed("playing", 6.0)
	sprite_frames.set_animation_loop("playing", true)

	# Apply to animated sprite
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.animation = "playing"
	animated_sprite.play()

func _update_display():
	"""Update all UI elements"""
	if not pet:
		return

	# Update header
	_update_header()

	# Update bond panel
	_update_bond()

	# Update exploration
	_update_exploration_status()

	# Update vitals
	_update_vitals()

	# Update achievements
	_update_achievements()

	# Update buttons
	_update_buttons()

	# Update mood and dialogue
	_update_dragon_panel()

func _update_header():
	"""Update header section"""
	if name_label:
		name_label.text = "💝 %s - YOUR COMPANION 💝" % pet.dragon_name.to_upper()

	if level_label:
		level_label.text = "Level %d Pet Dragon (Leveling increases Health & Energy!)" % pet.level

	if subtitle_label:
		var personality_name = pet.get_personality_name().to_upper()
		var days = pet.get_days_together()
		subtitle_label.text = "⭐ %s • %d DAYS TOGETHER ⭐" % [personality_name, days]

func _update_dragon_panel():
	"""Update dragon visual panel"""
	if mood_label:
		var mood = pet.get_mood_state().capitalize()
		var emoji = _get_mood_emoji(pet.get_mood_state())
		mood_label.text = "Mood: %s %s" % [emoji, mood]

	if dialogue_label and pet:
		dialogue_label.text = "\"%s\"" % pet.get_random_dialogue()

func _get_mood_emoji(mood: String) -> String:
	match mood:
		"happy": return "😊"
		"content": return "😌"
		"sad": return "😢"
		"hungry": return "😋"
		"tired": return "😴"
		"excited": return "🤩"
		_: return "😊"

func _update_bond():
	"""Update bond & personality section"""
	if affection_label:
		var hearts = _get_affection_hearts(pet.affection)
		affection_label.text = "Affection: %s" % hearts

	if tier_label:
		var tier = pet.get_affection_tier()
		var next_tier = _get_next_affection_tier(pet.affection)
		if next_tier.is_empty():
			tier_label.text = "Tier: %s (%d/100) - Max Tier Reached! +25%% Rewards" % [tier, pet.affection]
		else:
			tier_label.text = "Tier: %s (%d/100) - Next: %s at %d affection" % [tier, pet.affection, next_tier["name"], next_tier["required"]]

	if personality_label:
		var personality_icon = _get_personality_icon(pet.personality)
		var personality_name = pet.get_personality_name()
		personality_label.text = "%s %s" % [personality_icon, personality_name]

	if personality_desc:
		personality_desc.text = _get_personality_description(pet.personality)

func _get_personality_icon(personality: int) -> String:
	match personality:
		0: return "🔍"  # Curious
		1: return "⚔️"  # Brave
		2: return "😴"  # Lazy
		3: return "💪"  # Energetic
		4: return "💰"  # Greedy
		5: return "💝"  # Gentle
		_: return "🔍"

func _get_personality_description(personality: int) -> String:
	match personality:
		0: return "• +15% more dragon parts\n• Loves exploring"
		1: return "• +10% rewards from dangerous areas\n• Fearless explorer"
		2: return "• +50% exploration time\n• -20% fatigue gain"
		3: return "• -25% exploration time\n• Fast returns"
		4: return "• +25% gold rewards\n• Loves treasure"
		5: return "• +15% affection gain\n• Safe explorations"
		_: return "• Unique traits"

func _update_exploration_status():
	"""Update exploration status display"""
	var is_exploring = pet.current_state == Dragon.DragonState.EXPLORING

	if exploration_status_label:
		if is_exploring:
			# Get destination from ExplorationManager
			var destination = "Unknown"
			if ExplorationManager and ExplorationManager.instance:
				destination = ExplorationManager.instance.get_exploration_destination(pet)
			exploration_status_label.text = "🗺️ EXPLORING: %s" % destination.capitalize().replace("_", " ")
		else:
			exploration_status_label.text = "🏠 RESTING: Ready for next adventure!"

	# Show/hide progress elements
	if exploration_progress:
		exploration_progress.visible = is_exploring
		if is_exploring:
			var current_time = Time.get_unix_time_from_system()
			var elapsed = current_time - pet.exploration_start_time
			var progress_percent = (elapsed / pet.exploration_duration) * 100.0
			exploration_progress.value = clamp(progress_percent, 0, 100)

	if time_label:
		time_label.visible = is_exploring
		if is_exploring:
			var current_time = Time.get_unix_time_from_system()
			var elapsed = current_time - pet.exploration_start_time
			var remaining = pet.exploration_duration - elapsed

			if remaining > 0:
				var minutes = int(remaining / 60)
				var seconds = int(remaining) % 60
				time_label.text = "⏰ Returns in: %dm %ds" % [minutes, seconds]
			else:
				time_label.text = "⏰ Returning soon..."

	if rewards_label:
		rewards_label.visible = is_exploring
		if is_exploring:
			# Get actual duration and destination from ExplorationManager
			var duration_minutes = 15  # Default fallback
			var destination = "volcanic_caves"  # Default fallback
			if ExplorationManager and ExplorationManager.instance:
				duration_minutes = ExplorationManager.instance.get_exploration_duration_minutes(pet)
				destination = ExplorationManager.instance.get_exploration_destination(pet)

			# Calculate expected rewards matching ExplorationManager's formula
			# Base: 2 gold per minute
			var base_gold = 2 * duration_minutes

			# Level multiplier: +15% per level above 1
			var level_multiplier = 1.0 + (pet.level - 1) * 0.15

			# Destination difficulty multiplier (1.0x to 2.5x)
			var difficulty_multipliers = {
				"volcanic_caves": 1.0,
				"ancient_forest": 1.5,
				"frozen_tundra": 2.0,
				"thunder_peak": 2.5,
				"unknown": 1.0
			}
			var difficulty_multiplier = difficulty_multipliers.get(destination, 1.0)

			# Calculate base expected gold
			var expected_gold = base_gold * level_multiplier * difficulty_multiplier

			# Apply personality bonus if applicable (Curious = 10% more loot)
			var personality_bonus = pet.get_personality_bonus("gold") if pet.has_method("get_personality_bonus") else 1.0
			expected_gold *= personality_bonus

			# Apply affection bonus (scales with bond tier)
			var affection_bonus = pet.get_affection_bonus() if pet.has_method("get_affection_bonus") else 1.0
			expected_gold *= affection_bonus

			# Calculate range with ±25% variance
			var min_gold = int(expected_gold * 0.75)
			var max_gold = int(expected_gold * 1.25)

			rewards_label.text = "💰 Expected: %d-%dg + parts" % [min_gold, max_gold]

	if recall_button:
		recall_button.visible = is_exploring

	if exploration_buttons:
		exploration_buttons.visible = not is_exploring

func _update_vitals():
	"""Update vitals section"""
	# HP
	if hp_bar and hp_label:
		var current_hp = int(pet.current_health)
		var max_hp = int(pet.get_health())
		hp_bar.value = (float(current_hp) / float(max_hp)) * 100.0
		hp_label.text = "HP: %d/%d" % [current_hp, max_hp]

	# Hunger
	if hunger_bar and hunger_label:
		var hunger_percent = int((1.0 - pet.hunger_level) * 100)  # Invert so 100 = full
		hunger_bar.value = hunger_percent
		hunger_label.text = "Hunger: %d/100" % hunger_percent

	# Energy (inverted fatigue - so 100 = fully rested, 0 = exhausted)
	if energy_bar and energy_label:
		var energy_percent = int((1.0 - pet.fatigue_level) * 100)  # Invert so 100 = full energy
		energy_bar.value = energy_percent
		energy_label.text = "Energy: %d/100" % energy_percent

	# XP
	if xp_bar and xp_label:
		var exp_needed = pet._get_experience_for_level(pet.level + 1)
		var exp_current_level = pet._get_experience_for_level(pet.level)
		var exp_progress = pet.experience - exp_current_level
		var exp_required = exp_needed - exp_current_level

		if exp_required > 0:
			xp_bar.max_value = exp_required
			xp_bar.value = exp_progress
			xp_label.text = "XP: %d/%d to Level %d" % [exp_progress, exp_required, pet.level + 1]
		else:
			xp_bar.value = 100
			xp_label.text = "XP: MAX LEVEL"

func _update_achievements():
	"""Update lifetime achievements"""
	if not achievements_label or not pet:
		return

	# Get all stats from the pet
	var expeditions = pet.expeditions_completed
	var gold_earned = pet.total_gold_earned
	var parts_found = pet.total_parts_found
	var gifts_given = pet.pending_gifts.size()  # Gifts the pet has ready to give you
	var pet_count = pet.times_petted
	var feed_count = pet.times_fed

	achievements_label.text = "🎖️ Expeditions Completed: %d
💰 Total Gold Brought Back: %dg
🔧 Total Parts Recovered: %d parts
🎁 Gifts Given to You: %d special treasures
💝 Times You've Pet Them: %d times
🍖 Times You've Fed Them: %d times" % [expeditions, gold_earned, parts_found, gifts_given, pet_count, feed_count]

func _update_buttons():
	"""Update button states"""
	# Pet button
	if pet_button:
		if pet.can_pet():
			pet_button.disabled = false
			pet_button.text = "🖐️ PET (Ready! +1 Affection)"
		else:
			pet_button.disabled = true
			var remaining = pet.get_pet_cooldown_remaining()
			var minutes = remaining / 60
			pet_button.text = "🖐️ PET (Available in %dm)" % minutes

	# Treat/Feed button
	if treat_button:
		var has_food = InventoryManager and InventoryManager.instance and InventoryManager.instance.has_item(FOOD_ITEM_ID, 1)
		treat_button.disabled = not has_food
		var food_count = InventoryManager.instance.get_item_count(FOOD_ITEM_ID) if InventoryManager and InventoryManager.instance else 0
		treat_button.text = "🍖 FEED (1 Food, +2 Affection) [%d]" % food_count

	# Feed button (vitals)
	if feed_button:
		var has_food = InventoryManager and InventoryManager.instance and InventoryManager.instance.has_item(FOOD_ITEM_ID, 1)
		feed_button.disabled = not has_food
		var food_count = InventoryManager.instance.get_item_count(FOOD_ITEM_ID) if InventoryManager and InventoryManager.instance else 0
		feed_button.text = "[+] Feed [%d]" % food_count

	# Heal button
	if heal_button:
		var needs_healing = pet.current_health < pet.get_health()
		var has_potion = InventoryManager and InventoryManager.instance and InventoryManager.instance.has_item(HEALTH_POTION_ID, 1)
		heal_button.disabled = not needs_healing or not has_potion
		var potion_count = InventoryManager.instance.get_item_count(HEALTH_POTION_ID) if InventoryManager and InventoryManager.instance else 0
		heal_button.text = "[+] Heal [%d]" % potion_count

	# Rest button
	if rest_button:
		var is_resting = pet.current_state == Dragon.DragonState.RESTING
		var is_tired = pet.fatigue_level > 0.1  # Only allow rest if at least 10% tired
		rest_button.disabled = not is_tired and not is_resting
		if is_resting:
			rest_button.text = "[✓] Resting"
		else:
			rest_button.text = "[💤] Rest"

	# Gift button (give gift TO pet)
	if gift_button:
		var gift_cost = pet.get_gift_cost()
		var can_afford = TreasureVault and TreasureVault.instance and TreasureVault.instance.get_total_gold() >= gift_cost
		gift_button.disabled = not can_afford
		gift_button.text = "🎁 GIVE GIFT (%dg, +5 Affection)" % gift_cost

	# Exploration destination buttons
	var can_explore = pet.current_state == Dragon.DragonState.IDLE and pet.hunger_level < 0.8 and pet.fatigue_level < 0.8

	if caves_button:
		var unlocked = pet.can_explore_destination("volcanic_caves")
		caves_button.disabled = not (can_explore and unlocked)
		if not unlocked:
			caves_button.text = "🔒 Volcanic Caves (Locked)"
		elif not can_explore:
			# Show reason why can't explore
			if pet.current_state != Dragon.DragonState.IDLE:
				caves_button.text = "🌋 Volcanic Caves (Busy)"
			elif pet.hunger_level >= 0.8:
				caves_button.text = "🌋 Volcanic Caves (Hungry)"
			elif pet.fatigue_level >= 0.8:
				caves_button.text = "🌋 Volcanic Caves (Tired)"
			else:
				caves_button.text = "🌋 Volcanic Caves (Easy)"
		else:
			caves_button.text = "🌋 Volcanic Caves (Easy)"

	if forest_button:
		var unlocked = pet.can_explore_destination("ancient_forest")
		forest_button.disabled = not (can_explore and unlocked)
		if not unlocked:
			forest_button.text = "🔒 Ancient Forest - Friend Tier (Need 20 affection, you have %d)" % pet.affection
		elif not can_explore:
			if pet.current_state != Dragon.DragonState.IDLE:
				forest_button.text = "🌲 Ancient Forest (Busy)"
			elif pet.hunger_level >= 0.8:
				forest_button.text = "🌲 Ancient Forest (Hungry)"
			elif pet.fatigue_level >= 0.8:
				forest_button.text = "🌲 Ancient Forest (Tired)"
			else:
				forest_button.text = "🌲 Ancient Forest (Medium)"
		else:
			forest_button.text = "🌲 Ancient Forest (Medium)"

	if tundra_button:
		var unlocked = pet.can_explore_destination("frozen_tundra")
		tundra_button.disabled = not (can_explore and unlocked)
		if not unlocked:
			tundra_button.text = "🔒 Frozen Tundra - Companion Tier (Need 40 affection, you have %d)" % pet.affection
		elif not can_explore:
			if pet.current_state != Dragon.DragonState.IDLE:
				tundra_button.text = "❄️ Frozen Tundra (Busy)"
			elif pet.hunger_level >= 0.8:
				tundra_button.text = "❄️ Frozen Tundra (Hungry)"
			elif pet.fatigue_level >= 0.8:
				tundra_button.text = "❄️ Frozen Tundra (Tired)"
			else:
				tundra_button.text = "❄️ Frozen Tundra (Hard)"
		else:
			tundra_button.text = "❄️ Frozen Tundra (Hard)"

	if peak_button:
		var unlocked = pet.can_explore_destination("thunder_peak")
		peak_button.disabled = not (can_explore and unlocked)
		if not unlocked:
			peak_button.text = "🔒 Thunder Peak - Best Friend Tier (Need 60 affection, you have %d)" % pet.affection
		elif not can_explore:
			if pet.current_state != Dragon.DragonState.IDLE:
				peak_button.text = "⚡ Thunder Peak (Busy)"
			elif pet.hunger_level >= 0.8:
				peak_button.text = "⚡ Thunder Peak (Hungry)"
			elif pet.fatigue_level >= 0.8:
				peak_button.text = "⚡ Thunder Peak (Tired)"
			else:
				peak_button.text = "⚡ Thunder Peak (Very Hard)"
		else:
			peak_button.text = "⚡ Thunder Peak (Very Hard)"

func _get_affection_hearts(affection: int) -> String:
	"""Convert affection to heart string based on tier"""
	# Map tier to heart count (1-5 hearts)
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

func _get_next_affection_tier(affection: int) -> Dictionary:
	"""Get the next affection tier and required affection"""
	# Tier thresholds (from PetDragon.AFFECTION_TIERS)
	var tiers = [
		{"name": "Friend", "required": 20},
		{"name": "Companion", "required": 40},
		{"name": "Best Friend", "required": 60},
		{"name": "Soulbound", "required": 80}
	]

	for tier in tiers:
		if affection < tier["required"]:
			return tier

	# Max tier reached
	return {}

# === BUTTON CALLBACKS ===

func _on_pet_pressed():
	"""Pet the dragon"""
	if not pet:
		return

	if pet.pet():
		# Update dialogue
		if dialogue_label:
			dialogue_label.text = "\"%s\"" % pet.get_random_dialogue()

		# Play animation (if PetWalkingCharacter exists in scene)
		_notify_walking_character("pet")

		_update_display()

func _on_treat_pressed():
	"""Feed a treat to the dragon (increases affection more)"""
	_on_feed_pressed()  # Same as feed for now

func _on_feed_pressed():
	"""Feed the dragon"""
	if not pet:
		return

	# Check if has food
	if not InventoryManager or not InventoryManager.instance:
		return

	if InventoryManager.instance.has_item(FOOD_ITEM_ID, 1):
		# Consume food
		InventoryManager.instance.remove_item_by_id(FOOD_ITEM_ID, 1)

		# Feed pet
		pet.feed()

		# Update dialogue
		if dialogue_label:
			dialogue_label.text = "\"*munch munch* Thank you!\""

		# Play animation
		_notify_walking_character("feed")

		_update_display()

func _on_heal_pressed():
	"""Heal the dragon"""
	if not pet:
		return

	# Check if has potion
	if not InventoryManager or not InventoryManager.instance:
		return

	if InventoryManager.instance.has_item(HEALTH_POTION_ID, 1):
		# Consume potion
		InventoryManager.instance.remove_item_by_id(HEALTH_POTION_ID, 1)

		# Heal pet and gain affection
		pet.current_health = pet.get_health()
		pet.add_affection(2)  # Gain affection for healing

		# Update dialogue
		if dialogue_label:
			dialogue_label.text = "\"I feel much better now! Thank you!\""

		_update_display()

func _on_rest_pressed():
	"""Toggle rest state for the pet"""
	if not pet or not DragonStateManager or not DragonStateManager.instance:
		return

	# Toggle between resting and idle
	if pet.current_state == Dragon.DragonState.RESTING:
		# Stop resting, go back to idle
		DragonStateManager.instance.set_dragon_state(pet, Dragon.DragonState.IDLE)
		if dialogue_label:
			dialogue_label.text = "\"I'm feeling refreshed!\""
		print("[PetInteractionUI] Pet stopped resting")
	else:
		# Start resting
		DragonStateManager.instance.start_resting(pet)
		if dialogue_label:
			dialogue_label.text = "\"Time for a nap... *yawn*\""
		print("[PetInteractionUI] Pet started resting")

	_update_display()

func _on_gift_pressed():
	"""Give a gift to the pet"""
	if not pet:
		return

	# Check if can afford
	if not TreasureVault or not TreasureVault.instance:
		return

	var gift_cost = pet.get_gift_cost()
	if TreasureVault.instance.spend_gold(gift_cost):
		pet.receive_gift_from_player()

		# Update dialogue
		if dialogue_label:
			dialogue_label.text = "\"A gift for me? Thank you so much!\""

		_update_display()

# Talk button removed - not useful enough
#func _on_talk_pressed():
#	"""Talk to the dragon - shows context-aware dialogue"""
#	if not pet:
#		return
#
#	if not dialogue_label:
#		return
#
#	var dialogue = ""
#
#	# Priority-based contextual dialogue
#	# 1. Pending gifts (highest priority - they found something!)
#	if pet.pending_gifts.size() > 0:
#		var gift_messages = [
#			"I found something special for you!",
#			"Look what I discovered while exploring!",
#			"I saved this just for you!",
#			"I couldn't wait to show you what I found!",
#			"I think you'll like what I brought back!"
#		]
#		dialogue = gift_messages.pick_random()
#
#	# 2. Affection decreasing (pet feels neglected)
#	elif pet.affection_trend == -1:
#		var lonely_messages = [
#			"I feel a bit lonely lately...",
#			"Have you forgotten about me?",
#			"I miss spending time with you...",
#			"Do you still care about me?",
#			"It's been a while since we played together..."
#		]
#		dialogue = lonely_messages.pick_random()
#
#	# 3. Currently exploring (still on adventure)
#	elif pet.current_state == Dragon.DragonState.EXPLORING:
#		var exploring_messages = [
#			"I'm still exploring! I'll be back soon!",
#			"The adventure is going great!",
#			"I'm finding so many interesting things!",
#			"I can't wait to tell you about this place!",
#			"Almost done exploring, then I'll come home!"
#		]
#		dialogue = exploring_messages.pick_random()
#
#	# 4. Hungry (needs food)
#	elif pet.hunger_level > 0.7:
#		var hungry_messages = [
#			"I'm getting hungry...",
#			"Do you have any food? I'm starving!",
#			"My tummy is rumbling...",
#			"I could really use something to eat!",
#			"Feed me, please? I'm so hungry!"
#		]
#		dialogue = hungry_messages.pick_random()
#
#	# 5. Tired (needs rest)
#	elif pet.fatigue_level > 0.7:
#		var tired_messages = [
#			"I'm so tired... I need to rest.",
#			"Can we take a break? I'm exhausted...",
#			"My wings are so heavy...",
#			"I need some time to recover my energy.",
#			"Let me rest a bit before the next adventure..."
#		]
#		dialogue = tired_messages.pick_random()
#
#	# 6. Default: personality-based random dialogue
#	else:
#		dialogue = pet.get_random_dialogue()
#
#	# Display the dialogue
#	dialogue_label.text = "\"%s\"" % dialogue

func _on_journal_pressed():
	"""Open the pet journal"""
	if not pet:
		return

	# Load journal scene
	var journal_scene = load("res://scenes/ui/pet/pet_journal_ui.tscn")
	if not journal_scene:
		push_error("[PetInteractionUI] Could not load pet_journal_ui.tscn!")
		return

	# Instantiate and add to scene tree
	var journal = journal_scene.instantiate()
	get_tree().root.add_child(journal)

	# Setup with current pet
	journal.setup(pet)

	# Hide this modal while journal is open
	hide()

	# When journal closes, show this modal again
	journal.tree_exited.connect(func(): show())

	print("[PetInteractionUI] Journal opened for %s" % pet.dragon_name)

# Stats button removed - just opens journal which has its own button
#func _on_stats_pressed():
#	"""Show detailed stats - opens journal which displays all stats"""
#	# The journal already shows all stats (days together, affection, expeditions, gold, parts, etc.)
#	# So we just open the journal when Stats button is clicked
#	_on_journal_pressed()

func _on_explore_destination_pressed(destination: String):
	"""Send pet to explore a specific destination"""
	print("[PetInteractionUI] Exploration button clicked for: %s" % destination)

	if not pet:
		print("[PetInteractionUI] ERROR: No pet!")
		return

	if not ExplorationManager or not ExplorationManager.instance:
		print("[PetInteractionUI] ERROR: ExplorationManager not available!")
		return

	print("[PetInteractionUI] Pet state: %s, Hunger: %.2f, Fatigue: %.2f" % [pet.current_state, pet.hunger_level, pet.fatigue_level])

	# Map destinations to their durations (1/5/10/15 minutes)
	var destination_durations = {
		"volcanic_caves": 1,
		"ancient_forest": 5,
		"frozen_tundra": 10,
		"thunder_peak": 15
	}

	var duration_minutes = destination_durations.get(destination, 15)  # Default to 15 if unknown

	# Start exploration with correct duration
	if ExplorationManager.instance.start_exploration(pet, duration_minutes, destination):
		print("[PetInteractionUI] ✅ Exploration started successfully to %s for %d minutes!" % [destination, duration_minutes])
		if dialogue_label:
			dialogue_label.text = "\"I'll be back soon!\""

		_update_display()
	else:
		print("[PetInteractionUI] ❌ Failed to start exploration! (Check ExplorationManager logs)")
		if dialogue_label:
			dialogue_label.text = "\"I can't explore right now...\""

func _on_recall_pressed():
	"""Recall the pet early from exploration"""
	if not pet or not ExplorationManager or not ExplorationManager.instance:
		return

	# TODO: Implement recall functionality in ExplorationManager
	# For now, just show a message
	if dialogue_label:
		dialogue_label.text = "\"Recall not yet implemented!\""
	print("[PetInteractionUI] Recall functionality not yet implemented")

func _on_close_pressed():
	"""Close the popup"""
	# Resume the walking character animation before closing
	_resume_walking_character()
	queue_free()

func _pause_walking_character():
	"""Pause the walking character animation when modal opens"""
	walking_character = get_tree().get_first_node_in_group("pet_walking_character")
	if walking_character:
		# Hide the character completely
		if walking_character is CanvasItem:
			walking_character.visible = false
		# Also pause the animation
		if walking_character.has_method("pause_animation"):
			walking_character.call("pause_animation")
		print("[PetInteractionUI] Hidden walking character")

func _resume_walking_character():
	"""Resume the walking character animation when modal closes"""
	if walking_character:
		# Show the character again
		if walking_character is CanvasItem:
			walking_character.visible = true
		# Resume the animation
		if walking_character.has_method("resume_animation"):
			walking_character.call("resume_animation")
		print("[PetInteractionUI] Shown walking character")

func _notify_walking_character(action: String):
	"""Notify the walking character to play an animation"""
	if not walking_character:
		walking_character = get_tree().get_first_node_in_group("pet_walking_character")

	if walking_character and walking_character.has_method("play_" + action + "_animation"):
		walking_character.call("play_" + action + "_animation")
