@tool
extends Button

const Meta := preload("res://addons/audiot/meta.gd")


func _ready() -> void:
	Meta.get_signal_selected_files_changed(self).connect(_on_selected_files_changed)

	pressed.connect(_on_pressed)


func _on_selected_files_changed(selected_files: Array[int]) -> void:
	self.visible = not selected_files.is_empty()


func _on_pressed() -> void:
	pass
