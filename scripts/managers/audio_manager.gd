extends Node

# AudioManager - Centralized audio management singleton
# Handles background music and sound effects throughout the game

# Singleton instance
static var instance: AudioManager

# Audio players
var menu_music_player: AudioStreamPlayer
var gameplay_music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []  # Pool of SFX players
var ui_player: AudioStreamPlayer

const MAX_SFX_PLAYERS = 8  # Allow multiple sounds to play simultaneously

# Audio streams (preloaded)
var menu_music: AudioStream
var gameplay_music: AudioStream

# Sound effects - Existing
var scientist_hired_sfx: AudioStream
var dragon_finished_sfx: AudioStream
var dragon_roar_sfx: AudioStream

# Sound effects - New Dragon Sounds
var dragon_created_sfx: AudioStream
var dragon_level_up_sfx: AudioStream
var dragon_death_sfx: AudioStream
var dragon_growl_sfx: AudioStream
var dragon_fed_sfx: AudioStream
var dragon_healed_sfx: AudioStream
var dragon_exploring_sfx: AudioStream

# Sound effects - Combat
var wave_start_sfx: AudioStream
var battle_won_sfx: AudioStream
var attack_hit_sfx: AudioStream

# Sound effects - UI
var button_click_sfx: AudioStream
var button_hover_sfx: AudioStream
var notification_sfx: AudioStream
var error_sfx: AudioStream
var success_sfx: AudioStream
var gold_sfx: AudioStream

# Sound effects - Building
var repair_sfx: AudioStream

# Volume settings
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var ui_volume: float = 1.0

# State tracking
var current_music_scene: String = ""  # "menu" or "gameplay"

func _ready():
	instance = self
	_setup_audio_players()
	_load_audio_assets()
	print("[AudioManager] Audio Manager initialized")

func _setup_audio_players():
	"""Create audio stream players"""
	# Menu music player
	menu_music_player = AudioStreamPlayer.new()
	menu_music_player.bus = "Master"
	menu_music_player.volume_db = -12.0  # Quieter to not overpower SFX
	add_child(menu_music_player)

	# Gameplay music player
	gameplay_music_player = AudioStreamPlayer.new()
	gameplay_music_player.bus = "Master"
	gameplay_music_player.volume_db = -12.0  # Quieter to not overpower SFX
	add_child(gameplay_music_player)

	# Create pool of SFX players (allows multiple sounds to play at once)
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = 0.0
		add_child(player)
		sfx_players.append(player)

	# UI player (for button clicks and UI feedback)
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "Master"
	ui_player.volume_db = 0.0
	add_child(ui_player)

func _load_audio_assets():
	"""Load all audio files"""
	# Background music
	menu_music = load("res://assets/audio/Dragon Lab Blues.mp3")
	if menu_music and menu_music is AudioStreamMP3:
		menu_music.loop = true

	gameplay_music = load("res://assets/audio/The Clockwork Ghost.mp3")
	if gameplay_music and gameplay_music is AudioStreamMP3:
		gameplay_music.loop = true

	# Sound effects - Existing
	scientist_hired_sfx = load("res://assets/audio/ReadyToWork.mp3")
	dragon_finished_sfx = load("res://assets/audio/DragonsFinished.mp3")
	dragon_roar_sfx = load("res://assets/audio/Undead_dragon_roar-1761092513184.mp3")

	# Sound effects - Dragon Sounds
	dragon_created_sfx = load("res://assets/audio/baby-dragon.mp3")
	dragon_level_up_sfx = load("res://assets/audio/level-up-02.mp3")
	dragon_death_sfx = load("res://assets/audio/dragon-death-102428.mp3")
	dragon_growl_sfx = load("res://assets/audio/dragon-growl-7-364612.mp3")
	dragon_fed_sfx = load("res://assets/audio/eating-sound-effect.mp3")
	dragon_healed_sfx = load("res://assets/audio/heal.mp3")
	dragon_exploring_sfx = load("res://assets/audio/dragon-flapping-wings-364476.mp3")

	# Sound effects - Combat
	wave_start_sfx = load("res://assets/audio/wave-start-mega-horn.mp3")
	battle_won_sfx = load("res://assets/audio/success-fanfare-trumpets.mp3")
	attack_hit_sfx = load("res://assets/audio/armor-impact-from-sword.mp3")

	# Sound effects - UI
	button_click_sfx = load("res://assets/audio/button_click.mp3")
	button_hover_sfx = load("res://assets/audio/click.mp3")
	notification_sfx = load("res://assets/audio/new-notification.mp3")
	error_sfx = load("res://assets/audio/error.mp3")
	success_sfx = load("res://assets/audio/winner-game-sound.mp3")
	gold_sfx = load("res://assets/audio/cha_ching_#3-1761092694592.mp3")

	# Sound effects - Building
	repair_sfx = load("res://assets/audio/repair.mp3")

	print("[AudioManager] Audio assets loaded (music + %d SFX)" % 20)

# === MUSIC CONTROL ===

func play_menu_music():
	"""Start playing menu background music"""
	if current_music_scene == "menu":
		return  # Already playing

	# Stop gameplay music if playing
	if gameplay_music_player.playing:
		gameplay_music_player.stop()

	# Play menu music
	if menu_music:
		menu_music_player.stream = menu_music
		menu_music_player.play()
		current_music_scene = "menu"
		print("[AudioManager] Playing menu music")

func play_gameplay_music():
	"""Start playing gameplay background music"""
	if current_music_scene == "gameplay":
		return  # Already playing

	# Stop menu music if playing
	if menu_music_player.playing:
		menu_music_player.stop()

	# Play gameplay music
	if gameplay_music:
		gameplay_music_player.stream = gameplay_music
		gameplay_music_player.play()
		current_music_scene = "gameplay"
		print("[AudioManager] Playing gameplay music")

func stop_all_music():
	"""Stop all background music"""
	if menu_music_player.playing:
		menu_music_player.stop()
	if gameplay_music_player.playing:
		gameplay_music_player.stop()
	current_music_scene = ""
	print("[AudioManager] All music stopped")

func set_music_volume(volume_db: float):
	"""Set background music volume"""
	menu_music_player.volume_db = volume_db
	gameplay_music_player.volume_db = volume_db

func set_sfx_volume(volume_db: float):
	"""Set sound effects volume"""
	for player in sfx_players:
		player.volume_db = volume_db
	ui_player.volume_db = volume_db

# === SOUND EFFECTS ===

func play_scientist_hired():
	"""Play sound when scientist is hired"""
	_play_sound(scientist_hired_sfx, 1.0)
	print("[AudioManager] Playing scientist hired SFX")

func play_dragon_finished():
	"""Play sound when stitcher finishes creating a dragon"""
	_play_sound(dragon_finished_sfx, 1.0)
	print("[AudioManager] Playing dragon finished SFX")

func play_dragon_roar():
	"""Play dragon roar when dragons return from exploration"""
	_play_sound(dragon_roar_sfx, 1.0)
	print("[AudioManager] Playing dragon roar SFX")

func play_custom_sfx(sfx_path: String):
	"""Play a custom sound effect from a file path"""
	var sfx = load(sfx_path)
	if sfx:
		_play_sound(sfx)
		print("[AudioManager] Playing custom SFX: %s" % sfx_path)

# === HELPER FUNCTIONS ===

func _play_sound(stream: AudioStream, volume_multiplier: float = 1.0):
	"""Find available SFX player and play sound"""
	if not stream:
		push_error("[AudioManager] Attempted to play null stream")
		return

	# Find available player
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(master_volume * sfx_volume * volume_multiplier)
			player.play()
			return

	# All players busy, use first one (interrupt oldest sound)
	var player = sfx_players[0]
	player.stop()
	player.stream = stream
	player.volume_db = linear_to_db(master_volume * sfx_volume * volume_multiplier)
	player.play()

func _play_ui_sound(stream: AudioStream, volume_multiplier: float = 1.0):
	"""Play UI sound (interrupts previous UI sound for instant feedback)"""
	if not stream:
		return

	ui_player.stream = stream
	ui_player.volume_db = linear_to_db(master_volume * ui_volume * volume_multiplier)
	ui_player.play()

# === NEW DRAGON SOUNDS ===

func play_dragon_created():
	"""Play when a new dragon is born/created"""
	_play_sound(dragon_created_sfx, 1.0)
	print("[AudioManager] 🐣 Dragon created")

func play_dragon_level_up():
	"""Play when dragon gains a level"""
	_play_sound(dragon_level_up_sfx, 1.2)
	print("[AudioManager] ⬆️ Dragon level up")

func play_dragon_death():
	"""Play when a dragon dies"""
	_play_sound(dragon_death_sfx, 1.3)
	print("[AudioManager] 💀 Dragon death")

func play_dragon_growl():
	"""Play when dragon modal opens or dragon is assigned to task"""
	_play_sound(dragon_growl_sfx, 0.8)
	print("[AudioManager] 🐉 Dragon growl")

func play_dragon_fed():
	"""Play when dragon eats food"""
	_play_sound(dragon_fed_sfx, 0.9)
	print("[AudioManager] 🍖 Dragon fed")

func play_dragon_healed():
	"""Play when dragon is healed"""
	_play_sound(dragon_healed_sfx, 1.0)
	print("[AudioManager] ❤️ Dragon healed")

func play_dragon_exploring():
	"""Play when dragon starts exploration"""
	_play_sound(dragon_exploring_sfx, 0.9)
	print("[AudioManager] 🗺️ Dragon exploring")

# === COMBAT SOUNDS ===

func play_wave_start():
	"""Play when a defense wave begins"""
	_play_sound(wave_start_sfx, 1.1)
	print("[AudioManager] ⚔️ Wave start")

func play_battle_won():
	"""Play when defense wave is defeated"""
	_play_sound(battle_won_sfx, 1.2)
	print("[AudioManager] 🎉 Battle won")

func play_attack_hit():
	"""Play when an attack hits during combat"""
	_play_sound(attack_hit_sfx, 0.7)
	# Don't log - too frequent during combat

# === UI SOUNDS ===

func play_button_click():
	"""Play when any button is clicked"""
	_play_ui_sound(button_click_sfx, 0.6)
	# Don't log - too frequent

func play_button_hover():
	"""Play when mouse hovers over any button"""
	_play_ui_sound(button_hover_sfx, 0.4)
	# Don't log - too frequent

func play_notification():
	"""Play when player receives a notification (scouts, etc.)"""
	_play_ui_sound(notification_sfx, 0.9)
	print("[AudioManager] 🔔 Notification")

func play_error():
	"""Play when user tries invalid action"""
	_play_ui_sound(error_sfx, 0.8)
	print("[AudioManager] ❌ Error")

func play_success():
	"""Play for major achievements (chimera, freezer unlock, etc.)"""
	_play_sound(success_sfx, 1.3)
	print("[AudioManager] ✨ Success")

func play_gold():
	"""Play when gold is earned or spent"""
	_play_ui_sound(gold_sfx, 0.7)
	# Don't log - too frequent

# === BUILDING SOUNDS ===

func play_repair():
	"""Play when tower is repaired or rebuilt"""
	_play_sound(repair_sfx, 0.8)
	print("[AudioManager] 🔧 Repair")

# === VOLUME CONTROL (Enhanced) ===

func set_master_volume(volume: float):
	"""Set master volume (0.0 to 1.0)"""
	master_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()

func set_sfx_volume_level(volume: float):
	"""Set sound effects volume (0.0 to 1.0)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()

func set_music_volume_level(volume: float):
	"""Set music volume (0.0 to 1.0)"""
	music_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()

func set_ui_volume_level(volume: float):
	"""Set UI sounds volume (0.0 to 1.0)"""
	ui_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()

func _update_all_volumes():
	"""Apply volume settings to all players"""
	menu_music_player.volume_db = linear_to_db(master_volume * music_volume)
	gameplay_music_player.volume_db = linear_to_db(master_volume * music_volume)
	# SFX players are updated when they play a sound

func stop_all_sounds():
	"""Stop all currently playing sounds"""
	for player in sfx_players:
		player.stop()
	ui_player.stop()
