@tool
extends Button

const Meta := preload("res://addons/audiot/meta.gd")

signal copy_selected_files_to_dir(dir: String)

@onready var _file_dialog: FileDialog = %CopySelectedFilesDialog

var initial_file_dialog_size: Vector2


func _ready() -> void:
	Meta.get_signal_selected_files_changed(self).connect(_on_selected_files_changed)

	pressed.connect(_on_copy_selected_files_button_pressed)

	_file_dialog.dir_selected.connect(_on_dir_selected)
	initial_file_dialog_size = _file_dialog.size


func _on_selected_files_changed(selected_files: Array[int]) -> void:
	if selected_files.is_empty():
		text = "Copy file to project"
	else:
		text = "Copy %d selected %s to project" % [
			selected_files.size(),
			"file" if selected_files.size() == 1 else "files",
		]


func _on_copy_selected_files_button_pressed() -> void:
	var ui_scale := Meta.get_ui_scale(self)
	_file_dialog.size = initial_file_dialog_size * ui_scale

	if Engine.is_editor_hint():
		# in-editor, we assume they only want to move files to the current project
		_file_dialog.access = FileDialog.ACCESS_RESOURCES
	else:
		# NOT in-editor, we want to scale the file dialog with the settings
		# in-editor file dialog is pre-scaled
		_file_dialog.content_scale_factor = ui_scale

	_file_dialog.show()


func _on_dir_selected(dir: String) -> void:
	copy_selected_files_to_dir.emit(dir)
