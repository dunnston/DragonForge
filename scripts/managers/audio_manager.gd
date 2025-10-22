extends Node

# AudioManager - Centralized audio management singleton
# Handles background music and sound effects throughout the game

# Singleton instance
static var instance: AudioManager

# Audio players
var menu_music_player: AudioStreamPlayer
var gameplay_music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# Audio streams (preloaded)
var menu_music: AudioStream
var gameplay_music: AudioStream

# Sound effects
var scientist_hired_sfx: AudioStream
var dragon_finished_sfx: AudioStream
var dragon_roar_sfx: AudioStream

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
	menu_music_player.volume_db = 0.0
	add_child(menu_music_player)

	# Gameplay music player
	gameplay_music_player = AudioStreamPlayer.new()
	gameplay_music_player.bus = "Master"
	gameplay_music_player.volume_db = 0.0
	add_child(gameplay_music_player)

	# SFX player (for one-shot sounds)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	sfx_player.volume_db = 0.0
	add_child(sfx_player)

func _load_audio_assets():
	"""Load all audio files"""
	# Background music
	menu_music = load("res://assets/audio/Dragon Lab Blues.mp3")
	if menu_music and menu_music is AudioStreamMP3:
		menu_music.loop = true

	gameplay_music = load("res://assets/audio/The Clockwork Ghost.mp3")
	if gameplay_music and gameplay_music is AudioStreamMP3:
		gameplay_music.loop = true

	# Sound effects
	scientist_hired_sfx = load("res://assets/audio/ReadyToWork.mp3")
	dragon_finished_sfx = load("res://assets/audio/DragonsFinished.mp3")
	dragon_roar_sfx = load("res://assets/audio/Undead_dragon_roar-1761092513184.mp3")

	print("[AudioManager] Audio assets loaded")

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
	sfx_player.volume_db = volume_db

# === SOUND EFFECTS ===

func play_scientist_hired():
	"""Play sound when scientist is hired"""
	if scientist_hired_sfx:
		sfx_player.stream = scientist_hired_sfx
		sfx_player.play()
		print("[AudioManager] Playing scientist hired SFX")

func play_dragon_finished():
	"""Play sound when stitcher finishes creating a dragon"""
	if dragon_finished_sfx:
		sfx_player.stream = dragon_finished_sfx
		sfx_player.play()
		print("[AudioManager] Playing dragon finished SFX")

func play_dragon_roar():
	"""Play dragon roar when dragons return from exploration"""
	if dragon_roar_sfx:
		sfx_player.stream = dragon_roar_sfx
		sfx_player.play()
		print("[AudioManager] Playing dragon roar SFX")

func play_custom_sfx(sfx_path: String):
	"""Play a custom sound effect from a file path"""
	var sfx = load(sfx_path)
	if sfx:
		sfx_player.stream = sfx
		sfx_player.play()
		print("[AudioManager] Playing custom SFX: %s" % sfx_path)
