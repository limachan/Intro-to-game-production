@tool
extends CheckButton
## When this is toggled ("pressed") it will restart the audio stream when it finishes

@export var audio_stream_player: AudioStreamPlayer


func _ready() -> void:
	audio_stream_player.finished.connect(_on_player_finished)


func _on_player_finished() -> void:
	if button_pressed:
		audio_stream_player.play(0)
