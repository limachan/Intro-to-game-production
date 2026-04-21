@tool
extends Control
## This draws a single line representing the current playback position.
## This is done in its own control so that it can draw every frame -
## the AudioStreamVisualizer only redraws when the audio stream changes.

const FileView := preload("res://addons/audiot/ui/file_view/file_view.gd")

@export var file_view: FileView

## Color to render the line in
@export var color := Color(1.0, 0.5, 0.0, 0.8):
	set(value):
		color = value

		if is_inside_tree():
			queue_redraw()

## Audio stream player that is being used
var audio_stream_player: AudioStreamPlayer

## Audio stream that is being played
var audio_stream: AudioStream

var playback_position: float


func _ready() -> void:
	file_view.selected_file_changed.connect(_on_selected_file_changed)


func _on_selected_file_changed() -> void:
	playback_position = 0.0
	queue_redraw()


func _draw() -> void:
	if not audio_stream_player or not audio_stream:
		return

	var w := size.x
	var h := size.y

	var total_duration := audio_stream.get_length()
	var playback_visual_position := remap(
		playback_position,
		0.0,
		total_duration,
		0.0,
		w,
	)

	draw_line(
		Vector2(playback_visual_position, 0.0),
		Vector2(playback_visual_position, h),
		color,
		2.0,
	)


func _process(_delta: float) -> void:
	if audio_stream_player.playing:
		var player_playback_position := audio_stream_player.get_playback_position()

		# From the docs audio stream player docs:
		# > Note: The position is not always accurate, as the `AudioServer` does not mix audio every processed frame.
		# > To get more accurate results, add `AudioServer.get_time_since_last_mix()` to the returned position.
		var time_since_last_mix := AudioServer.get_time_since_last_mix()
		playback_position = player_playback_position + time_since_last_mix

		queue_redraw()
