@tool
extends HSlider

@export var audio_stream_player: AudioStreamPlayer
@export var label: Label


func _ready() -> void:
	value_changed.connect(_on_value_changed)


func _on_value_changed(v: float) -> void:
	audio_stream_player.volume_db = v
	label.text = "(%s dB)" % v
