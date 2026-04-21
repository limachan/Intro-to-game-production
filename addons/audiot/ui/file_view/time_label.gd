@tool
extends Label

## Audio stream being played
var audio_stream_player: AudioStreamPlayer


func _process(delta: float) -> void:
	if not audio_stream_player:
		text = "00:00 / 00:00"
		return

	if audio_stream_player.playing:
		var player_playback_position := audio_stream_player.get_playback_position()

		# From the docs audio stream player docs:
		# > Note: The position is not always accurate, as the `AudioServer` does not mix audio every processed frame.
		# > To get more accurate results, add `AudioServer.get_time_since_last_mix()` to the returned position.
		var time_since_last_mix := AudioServer.get_time_since_last_mix()
		var playback_position := player_playback_position + time_since_last_mix

		var total_duration := audio_stream_player.stream.get_length()

		text = "%s / %ss" % [
			_format_time(playback_position),
			_format_time(total_duration),
		]


func _format_time(seconds: float) -> String:
	var secs := int(seconds)
	var ms := int(fmod(seconds, 1.0) * 100)
	return "%d:%02d" % [secs, ms]
