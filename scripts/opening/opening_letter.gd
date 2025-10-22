extends Control
## Opening Letter Scene
## Displays the professor's letter with typewriter effect and dramatic audio

# --- Letter Content ---
const LETTER_TEXT = """To my dearest apprentice,

If you're reading this, I'm gone.

The knights have discovered our work. They've been hunting dragons to extinction, burning nests, destroying eggs. But I found another way - we can CREATE them. Assemble them from parts, like Dr. Frankenstein's great work.

The laboratory is yours now. I've left you what I could:
- 30 gold pieces
- 6 dragon parts from my collection (at least one head, body, and tail)

The knights know about the laboratory now. They will come. You must be ready.

Dragons are living creatures, even if assembled. They need food, rest, and training to grow strong. When you can afford it, hire scientists from town - they'll help automate the work.

Key lessons I taught you:
1. Always create your first defender immediately
2. Send dragons exploring to gather resources, but only when rested
3. Keep them fed and rested before you leave the laboratory
4. Training and treats make them powerful - hire a Trainer when possible
5. Never leave the lab undefended

The dragons need you. The world needs you.

Don't let my life's work die with me.

- Professor Von Drakescale

P.S. - Trust the process. Trust the dragons."""

# --- Configuration ---
@export var characters_per_second: float = 30.0  # Speed of typewriter effect
@export var skip_enabled: bool = true  # Allow skipping with any key
@export var fade_duration: float = 1.5  # Duration of fade transitions

# --- Node References ---
@onready var background: ColorRect = $Background
@onready var parchment: Panel = $Parchment
@onready var letter_text: RichTextLabel = $Parchment/MarginContainer/LetterText
@onready var continue_prompt: Label = $ContinuePrompt
@onready var fade_overlay: ColorRect = $FadeOverlay

# --- Audio References ---
@onready var typing_sound: AudioStreamPlayer = $TypingSound
@onready var thunder_sound: AudioStreamPlayer = $ThunderSound
@onready var dramatic_music: AudioStreamPlayer = $DramaticMusic

# --- State ---
var current_char_index: int = 0
var is_typing: bool = false
var typing_complete: bool = false
var can_continue: bool = false
var typing_timer: float = 0.0

# --- Signals ---
signal letter_complete


func _ready() -> void:
	# Hide continue prompt initially
	continue_prompt.visible = false

	# Setup letter text
	letter_text.bbcode_enabled = true
	letter_text.text = ""

	# Setup fade overlay
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 1.0

	# Start dramatic music
	if dramatic_music:
		dramatic_music.play()

	# Fade in from black
	await fade_in()

	# Start typewriter effect
	start_typewriter()


func _process(delta: float) -> void:
	if is_typing:
		typing_timer += delta
		var chars_to_add = int(typing_timer * characters_per_second)

		if chars_to_add > 0:
			typing_timer = 0.0
			advance_text(chars_to_add)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if is_typing and skip_enabled:
			# Skip typewriter, show full text
			skip_to_end()
		elif typing_complete and can_continue:
			# Continue to tutorial
			proceed_to_tutorial()


func start_typewriter() -> void:
	"""Start the typewriter effect"""
	is_typing = true
	current_char_index = 0
	typing_timer = 0.0

	# Start typing sound loop
	if typing_sound:
		typing_sound.play()


func advance_text(char_count: int) -> void:
	"""Add characters to the displayed text"""
	for i in range(char_count):
		if current_char_index >= LETTER_TEXT.length():
			finish_typing()
			return

		current_char_index += 1
		letter_text.text = LETTER_TEXT.substr(0, current_char_index)

		# Check for thunder trigger phrase
		if current_char_index >= 250 and current_char_index <= 280:
			# "They will come" range - trigger thunder
			if "They will come" in letter_text.text and not thunder_sound.playing:
				play_thunder()


func finish_typing() -> void:
	"""Complete the typewriter effect"""
	is_typing = false
	typing_complete = true
	letter_text.text = LETTER_TEXT

	# Stop typing sound
	if typing_sound:
		typing_sound.stop()

	# Show continue prompt
	show_continue_prompt()


func skip_to_end() -> void:
	"""Skip typewriter and show full text immediately"""
	current_char_index = LETTER_TEXT.length()
	finish_typing()


func show_continue_prompt() -> void:
	"""Display the continue prompt with fade-in effect"""
	continue_prompt.visible = true
	continue_prompt.modulate.a = 0.0
	can_continue = true

	# Fade in the prompt
	var tween = create_tween()
	tween.tween_property(continue_prompt, "modulate:a", 1.0, 0.5)
	tween.set_ease(Tween.EASE_IN_OUT)


func play_thunder() -> void:
	"""Play thunder sound effect"""
	if thunder_sound and not thunder_sound.playing:
		thunder_sound.play()


func proceed_to_tutorial() -> void:
	"""Fade out and transition to tutorial"""
	can_continue = false

	# Fade out music
	if dramatic_music:
		var music_tween = create_tween()
		music_tween.tween_property(dramatic_music, "volume_db", -80.0, fade_duration)

	# Fade to black
	await fade_out()

	# Emit signal that letter is complete
	letter_complete.emit()

	# Load tutorial scene
	get_tree().change_scene_to_file("res://scenes/opening/tutorial_manager.tscn")


func fade_in() -> void:
	"""Fade in from black"""
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, fade_duration)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func fade_out() -> void:
	"""Fade out to black"""
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, fade_duration)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished
