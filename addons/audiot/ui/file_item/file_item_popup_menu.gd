@tool
extends PopupMenu

signal favorite_changed(is_favorite: bool)
signal select_directory(dir_path: String)

@export var favorite_icon: Texture2D
@export var unfavorite_icon: Texture2D

## Options in the popup menu.
## The number here is the "ID" of the item in the editor.
enum FileItemPopupMenuOption {
	## Toggle file as favorite/unfavorite
	TOGGLE_FAVORITE = 0,

	## Show the file in the file manager
	OPEN_IN_FILE_MANAGER = 1,

	## Select the folder that this file is in in the library tree
	SELECT_CONTAINING_FOLDER = 2,
}

## Directory path for this file, used for opening the file in the system file explorer
var dir_path: String

## File name, including extension
var file_name: String

var is_favorite: bool = false:
	set(value):
		if is_favorite == value:
			return

		is_favorite = value

		if is_favorite:
			set_item_icon(FileItemPopupMenuOption.TOGGLE_FAVORITE, favorite_icon)
			set_item_text(FileItemPopupMenuOption.TOGGLE_FAVORITE, "Unfavorite")
		else:
			set_item_icon(FileItemPopupMenuOption.TOGGLE_FAVORITE, unfavorite_icon)
			set_item_text(FileItemPopupMenuOption.TOGGLE_FAVORITE, "Favorite")


func _ready() -> void:
	id_pressed.connect(_on_id_pressed)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton

		# for some reason, by default, only the left mouse button will hide the popup menu
		# https://github.com/godotengine/godot/blob/babc272d44ecfbd86e3b3fc5397ef936b1ce12d8/scene/gui/popup.cpp#L259
		if mouse_button_event.button_index == MouseButton.MOUSE_BUTTON_RIGHT and mouse_button_event.pressed:
			hide()


func _on_id_pressed(id: int) -> void:
	match id:
		FileItemPopupMenuOption.TOGGLE_FAVORITE:
			is_favorite = not is_favorite
			favorite_changed.emit(is_favorite)
		FileItemPopupMenuOption.OPEN_IN_FILE_MANAGER:
			_show_in_file_manager()
		FileItemPopupMenuOption.SELECT_CONTAINING_FOLDER:
			_select_containing_folder()


func _select_containing_folder() -> void:
	# note that the signal flow is a little funny here
	# this bubbles up to the `file_item`, which then re-emits it, which is then picked up by the Rust addon
	# which then tells the library tree to select the folder
	select_directory.emit(dir_path)


func _show_in_file_manager() -> void:
	var full_file_path := dir_path.path_join(file_name)

	# this will open the file manager AND select the file
	# ... which doesn't work in Linux
	OS.shell_show_in_file_manager(full_file_path)
