@tool
extends Button

## Full path to the file to open
var full_file_path: String


func _ready() -> void:
	pressed.connect(_on_open_directory_button_pressed)


func _on_open_directory_button_pressed() -> void:
	if full_file_path.is_empty():
		push_warning("OpenDirectoryButton has no file path set! Got %s" % full_file_path)
		return

	# this will open the file manager AND select the file
	OS.shell_show_in_file_manager(full_file_path)
