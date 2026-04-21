@tool
extends Button

const Meta := preload("res://addons/audiot/meta.gd")

## Emitted after a directory is chosen in the file dialog
signal add_library(dir: String)

@onready var _file_dialog: FileDialog = %FileDialog

var initial_file_dialog_size: Vector2


func _ready() -> void:
	pressed.connect(_on_pressed)
	_file_dialog.dir_selected.connect(_on_dir_selected)

	initial_file_dialog_size = _file_dialog.size


func _on_pressed() -> void:
	var ui_scale := Meta.get_ui_scale(self)
	_file_dialog.size = initial_file_dialog_size * ui_scale

	# only apply scale when NOT in the editor; the editor file explorer already has scale applied
	if not Engine.is_editor_hint():
		_file_dialog.content_scale_factor = ui_scale

	_file_dialog.show()


func _on_dir_selected(dir: String) -> void:
	add_library.emit(dir)
