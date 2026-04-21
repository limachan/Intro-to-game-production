@tool
extends Button
## Button to start/stop an audio stream.

const FileView := preload("res://addons/audiot/ui/file_view/file_view.gd")

@export var file_view: FileView
@export var audio_stream_player: AudioStreamPlayer
@export var pause_icon: Texture2D
@export var play_icon: Texture2D

## Last known position of audio player.
## Used to un-pause at the same spot we paused at.
var last_position: float = 0.0


func _ready() -> void:
	pressed.connect(_on_pressed)
	audio_stream_player.finished.connect(_on_player_finished)
	file_view.selected_file_changed.connect(_on_selected_file_changed)


func _process(_delta: float) -> void:
	if not audio_stream_player:
		return

	if audio_stream_player.playing:
		icon = pause_icon
		text = "Pause"
	else:
		icon = play_icon
		text = "Play"


func _on_selected_file_changed() -> void:
	last_position = 0.0


func _on_player_finished() -> void:
	last_position = 0.0


func _on_pressed() -> void:
	if not audio_stream_player:
		return

	if audio_stream_player.playing:
		last_position = audio_stream_player.get_playback_position()
		audio_stream_player.stop()
	else:
		audio_stream_player.play(last_position)
