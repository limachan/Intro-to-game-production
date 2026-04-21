@tool
extends CheckButton
## When this is toggled ("pressed") it audio will play when the user selects a file in the file list

const Meta := preload("res://addons/audiot/meta.gd")

@export var audio_stream_player: AudioStreamPlayer


func _ready() -> void:
	pressed.connect(_on_pressed)

	var settings := Meta.get_settings(self)
	button_pressed = settings.auto_play


func _on_pressed() -> void:
	var checked := button_pressed

	var settings := Meta.get_settings(self)
	settings.auto_play = checked
	Meta.save_settings(self, settings)
