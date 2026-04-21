@tool
extends Button

const FileView := preload("res://addons/audiot/ui/file_view/file_view.gd")
const TagSearchPopupMenu := preload("res://addons/audiot/ui/tags/tag_search_popup_menu.gd")

signal tag_changed(tag: String, removed: bool)

@onready var tag_popup_menu: TagSearchPopupMenu = %TagPopupMenu

## This is the file view that is rendering this button.
## This gets set in `file_view.gd` `_ready()`
var file_view: FileView


func _ready() -> void:
	pressed.connect(_on_pressed)
	tag_popup_menu.tag_changed.connect(tag_changed.emit)


func _on_pressed() -> void:
	# for some reason, this isn't available in `_ready`?
	if not file_view.selected_file_changed.is_connected(_on_selected_file_changed):
		file_view.selected_file_changed.connect(_on_selected_file_changed)

	tag_popup_menu.show_popup()
	tag_popup_menu.position = get_screen_position() - Vector2(0, tag_popup_menu.size.y)

	for tag in file_view.tags:
		tag_popup_menu.set_checked(tag, true)


func _on_selected_file_changed() -> void:
	tag_popup_menu.visible = false
