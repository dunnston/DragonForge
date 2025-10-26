extends Control
class_name SettingsUI

## Settings UI - Controls for audio volumes and game settings

# Node references
@onready var close_button: Button = %CloseButton if has_node("%CloseButton") else null
@onready var master_volume_slider: HSlider = %MasterVolumeSlider if has_node("%MasterVolumeSlider") else null
@onready var music_volume_slider: HSlider = %MusicVolumeSlider if has_node("%MusicVolumeSlider") else null
@onready var sfx_volume_slider: HSlider = %SFXVolumeSlider if has_node("%SFXVolumeSlider") else null
@onready var ui_volume_slider: HSlider = %UIVolumeSlider if has_node("%UIVolumeSlider") else null

@onready var master_volume_label: Label = %MasterVolumeLabel if has_node("%MasterVolumeLabel") else null
@onready var music_volume_label: Label = %MusicVolumeLabel if has_node("%MusicVolumeLabel") else null
@onready var sfx_volume_label: Label = %SFXVolumeLabel if has_node("%SFXVolumeLabel") else null
@onready var ui_volume_label: Label = %UIVolumeLabel if has_node("%UIVolumeLabel") else null

# Signals
signal closed()

func _ready():
	# Start hidden
	visible = false

	# Setup close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Setup sliders
	if master_volume_slider:
		master_volume_slider.min_value = 0.0
		master_volume_slider.max_value = 1.0
		master_volume_slider.step = 0.05
		master_volume_slider.value_changed.connect(_on_master_volume_changed)

	if music_volume_slider:
		music_volume_slider.min_value = 0.0
		music_volume_slider.max_value = 1.0
		music_volume_slider.step = 0.05
		music_volume_slider.value_changed.connect(_on_music_volume_changed)

	if sfx_volume_slider:
		sfx_volume_slider.min_value = 0.0
		sfx_volume_slider.max_value = 1.0
		sfx_volume_slider.step = 0.05
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)

	if ui_volume_slider:
		ui_volume_slider.min_value = 0.0
		ui_volume_slider.max_value = 1.0
		ui_volume_slider.step = 0.05
		ui_volume_slider.value_changed.connect(_on_ui_volume_changed)

	print("[SettingsUI] Initialized")

func open():
	"""Open the settings UI"""
	# Load current volumes from AudioManager
	if AudioManager and AudioManager.instance:
		if master_volume_slider:
			master_volume_slider.value = AudioManager.instance.master_volume
			_update_master_volume_label(AudioManager.instance.master_volume)

		if music_volume_slider:
			music_volume_slider.value = AudioManager.instance.music_volume
			_update_music_volume_label(AudioManager.instance.music_volume)

		if sfx_volume_slider:
			sfx_volume_slider.value = AudioManager.instance.sfx_volume
			_update_sfx_volume_label(AudioManager.instance.sfx_volume)

		if ui_volume_slider:
			ui_volume_slider.value = AudioManager.instance.ui_volume
			_update_ui_volume_label(AudioManager.instance.ui_volume)

	visible = true
	print("[SettingsUI] Opened")

func _on_close_pressed():
	"""Close the settings UI"""
	visible = false
	closed.emit()
	print("[SettingsUI] Closed")

func _on_master_volume_changed(value: float):
	"""Called when master volume slider changes"""
	if AudioManager and AudioManager.instance:
		AudioManager.instance.set_master_volume(value)
	_update_master_volume_label(value)

func _on_music_volume_changed(value: float):
	"""Called when music volume slider changes"""
	if AudioManager and AudioManager.instance:
		AudioManager.instance.set_music_volume_level(value)
	_update_music_volume_label(value)

func _on_sfx_volume_changed(value: float):
	"""Called when SFX volume slider changes"""
	if AudioManager and AudioManager.instance:
		AudioManager.instance.set_sfx_volume_level(value)
	_update_sfx_volume_label(value)

func _on_ui_volume_changed(value: float):
	"""Called when UI volume slider changes"""
	if AudioManager and AudioManager.instance:
		AudioManager.instance.set_ui_volume_level(value)
	_update_ui_volume_label(value)

func _update_master_volume_label(value: float):
	"""Update master volume label"""
	if master_volume_label:
		master_volume_label.text = "Master Volume: %d%%" % int(value * 100)

func _update_music_volume_label(value: float):
	"""Update music volume label"""
	if music_volume_label:
		music_volume_label.text = "Music Volume: %d%%" % int(value * 100)

func _update_sfx_volume_label(value: float):
	"""Update SFX volume label"""
	if sfx_volume_label:
		sfx_volume_label.text = "SFX Volume: %d%%" % int(value * 100)

func _update_ui_volume_label(value: float):
	"""Update UI volume label"""
	if ui_volume_label:
		ui_volume_label.text = "UI Volume: %d%%" % int(value * 100)
