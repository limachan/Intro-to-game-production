@tool
extends Control
## Shows a waveform visualization of an audio stream

const PlaybackPosition := preload("res://addons/audiot/ui/file_view/playback_position.gd")
const PlayPauseButton := preload("res://addons/audiot/ui/file_view/play_pause_button.gd")

## Audio stream to read in and show
@export var audio_stream: AudioStream:
	set(value):
		audio_stream = value

		if playback_position_indicator:
			playback_position_indicator.audio_stream = audio_stream

		_regenerate()

## Color of the waveform at low amplitude
@export var color_quiet := Color(0.2, 0.5, 1.0, 1.0):
	set(value):
		color_quiet = value

		if is_inside_tree():
			queue_redraw()

## Color of the waveform at high amplitude
@export var color_loud := Color(0.0, 1.0, 0.8, 1.0):
	set(value):
		color_loud = value

		if is_inside_tree():
			queue_redraw()

## Color to use for the background
@export var background_color := Color(0.15, 0.15, 0.15, 1.0):
	set(value):
		background_color = value

		if is_inside_tree():
			queue_redraw()

@export var play_pause_button: PlayPauseButton

@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

## This is in its own control so that it can redraw every frame.
## The actual audio visualization is only drawn once when the stream changes.
@onready var playback_position_indicator: PlaybackPosition = %PlaybackPositionIndicator

# Decoded samples, one float per frame
var _samples: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_regenerate()

	playback_position_indicator.audio_stream_player = audio_stream_player


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not audio_stream_player.stream:
			return

		var mouse_button_event := event as InputEventMouseButton

		# seek the audio stream to the clicked position
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
			var t := mouse_button_event.position.x / size.x
			var seek_pos := t * audio_stream_player.stream.get_length()
			audio_stream_player.seek(seek_pos)

			play_pause_button.last_position = seek_pos
			playback_position_indicator.playback_position = seek_pos
			playback_position_indicator.queue_redraw()


## Called by Godot to draw the control. Draws a waveform visualization of the audio stream.
func _draw() -> void:
	var w := size.x
	var h := size.y

	if w <= 0 or h <= 0:
		return

	# draw the background rect
	draw_rect(
		Rect2(0.0, 0.0, w, h),
		background_color,
	)

	if _samples.is_empty():
		# flat center line as a placeholder
		draw_line(
			Vector2(0.0, h * 0.5),
			Vector2(w, h * 0.5),
			color_quiet,
			1.0,
		)
		return

	var middle := h * 0.5
	var num_samples := _samples.size()

	# Each pixel column covers a slice of samples.
	# Find the min/max amplitude within that slice so the envelope is accurate regardless of zoom level.
	for x in int(w):
		var t0 := float(x) / w
		var t1 := float(x + 1) / w
		var i0 := clampi(int(t0 * num_samples), 0, num_samples - 1)
		var i1 := clampi(int(t1 * num_samples), 0, num_samples)

		var low := 1.0
		var high := -1.0

		for i in range(i0, i1):
			var sample := _samples[i]
			if sample < low:
				low = sample
			if sample > high:
				high = sample

		# Map amplitude (-1..1) to pixel y, clamped to control bounds
		var y_top := clampf(middle - high * middle, 0.0, h)
		var y_bot := clampf(middle - low * middle, 0.0, h)

		# Ensure at least 1 pixel is drawn even for near-silence
		if y_bot - y_top < 1.0:
			y_top = clampf(middle - 0.5, 0.0, h)
			y_bot = clampf(middle + 0.5, 0.0, h)

		# actually draw the line for this column
		var amplitude := maxf(absf(low), absf(high))
		var color := color_quiet.lerp(color_loud, amplitude)
		draw_line(Vector2(x, y_top), Vector2(x, y_bot), color, 1.0)


## Regenerates the samples from the audio stream
func _regenerate() -> void:
	_samples = PackedFloat32Array()
	queue_redraw()

	if audio_stream == null or not is_inside_tree():
		return

	_samples = _extract_samples(audio_stream)
	queue_redraw()


## Extracts samples from the given audio stream.
## Returns an array of floats in the range [-1, 1].
func _extract_samples(stream: AudioStream) -> PackedFloat32Array:
	var playback := stream.instantiate_playback()
	if playback == null:
		return PackedFloat32Array()

	playback.start(0.0)

	var samples := PackedFloat32Array()
	var chunk_size := 4096

	while true:
		var frames := playback.mix_audio(1.0, chunk_size)

		if frames.is_empty():
			break

		for frame in frames:
			# average left and right to get mono
			samples.append((frame.x + frame.y) * 0.5)

		# end of stream
		if frames.size() < chunk_size:
			break

	return samples
