@tool
extends Control
## Represents a file in the virutalized scroll list

const FileView := preload("res://addons/audiot/ui/file_view/file_view.gd")
const FileButton := preload("res://addons/audiot/ui/file_item/file_button.gd")
const FileItemPopupMenu := preload("res://addons/audiot/ui/file_item/file_item_popup_menu.gd")
const FileItemTag := preload("res://addons/audiot/ui/file_item/file_item_tag.gd")
const FavoriteButton := preload("res://addons/audiot/ui/favorite_button.gd")
const SelectedButton := preload("res://addons/audiot/ui/file_item/selected_button.gd")

signal favorite_changed(file_id: int, is_favorite: bool)
signal selected_changed(file_id: int, is_selected: bool)
signal select_directory(dir_path: String)
signal tag_search(tag: String)

@export var file_item_tag_scene: PackedScene

## Maximum width the tag scroll container can occupy before scrolling kicks in
@export var max_tag_container_width := 500.0

@onready var file_button: FileButton = %FileButton
@onready var selected_button: SelectedButton = %SelectedButton
@onready var favorite_button: FavoriteButton = %FavoriteButton
@onready var tag_container: Control = %TagContainer
@onready var tag_scroll_container: ScrollContainer = %TagScrollContainer
@onready var file_item_popup_menu: FileItemPopupMenu = %FileItemPopupMenu

## Database ID for this file
var file_id: int:
	set(value):
		file_id = value

		if file_view:
			file_button.button_pressed = file_view.file_id == file_id

## Database ID for the library this file belongs to
var library_id: int

## Directory path for this file, used for opening the file in the system file explorer
var dir_path: String

## List of tags for this file
var tags: Array[String] = []:
	set(value):
		tags = value
		for child in tag_container.get_children():
			# NOTE: intentionally using `free` here instead of `queue_free`, the row will be refreshed after this is called
			child.free()

		if tags.is_empty():
			tag_scroll_container.hide()
			tag_scroll_container.custom_minimum_size.x = 0
		else:
			tag_scroll_container.show()

			for tag in tags:
				var tag_node := file_item_tag_scene.instantiate() as FileItemTag
				tag_node.tag = tag
				tag_container.add_child(tag_node)
				tag_node.text = tag
				tag_node.tag_pressed.connect(_on_tag_pressed)
			_update_tag_scroll_size.call_deferred()

var file_name: String:
	set(value):
		file_name = value
		file_button.text = value

		var full_file_path := dir_path.path_join(file_name)
		file_button.tooltip_text = full_file_path

		file_item_popup_menu.dir_path = dir_path
		file_item_popup_menu.file_name = file_name

## Reference to the [code]FileView[/code] that is shown when this file is clicked on
var file_view: FileView:
	set(value):
		file_view = value

		if not file_view.selected_file_changed.is_connected(_on_selected_file_changed):
			file_view.selected_file_changed.connect(_on_selected_file_changed)

## Whether or not this file is marked as a favorite.
## The state here is actually stored in the `favorite_button`.
var is_favorite: bool = false:
	set(value):
		favorite_button.is_favorite = value
		file_item_popup_menu.is_favorite = value
	get:
		return favorite_button.is_favorite

## Whether or not this file has been selected
var is_selected: bool:
	set(value):
		selected_button.is_selected = value
	get:
		return selected_button.is_selected


## Calculates the needed width of the tag container content and sets the
## scroll container's minimum size to that, capped at max_tag_container_width.
func _update_tag_scroll_size() -> void:
	var content_width := tag_container.get_combined_minimum_size().x
	tag_scroll_container.custom_minimum_size.x = minf(content_width, max_tag_container_width)


func _ready() -> void:
	selected_button.pressed.connect(_on_selected_button_pressed)
	favorite_button.pressed.connect(_on_favorite_button_pressed)
	file_button.pressed.connect(_set_as_active_file)
	file_item_popup_menu.favorite_changed.connect(_on_favorite_changed_popup)
	file_item_popup_menu.select_directory.connect(_on_select_directory)


func _to_string() -> String:
	return "FileItem: %s | %s | %s | %s | %s | %s" % [file_name, file_id, library_id, dir_path, tags, favorite_button.pressed]


func _on_selected_file_changed() -> void:
	file_button.button_pressed = file_view.file_id == file_id


func _set_as_active_file() -> void:
	if not file_view:
		push_error("File item %s has no file view set!" % file_name)
		return

	file_view.set_selected_file(
		file_id,
		library_id,
		dir_path,
		tags,
		favorite_button.is_favorite,
		file_name,
	)


func _on_favorite_changed_popup(popup_is_favorite: bool) -> void:
	favorite_button.set_pressed_no_signal(popup_is_favorite)
	file_item_popup_menu.is_favorite = popup_is_favorite
	favorite_changed.emit(file_id, popup_is_favorite)


func _on_select_directory(_dir_path: String) -> void:
	select_directory.emit(_dir_path)


func _on_selected_button_pressed() -> void:
	selected_button.is_selected = not selected_button.is_selected
	selected_changed.emit(file_id, selected_button.is_selected)


func _on_favorite_button_pressed() -> void:
	favorite_changed.emit(file_id, not favorite_button.is_favorite)


func _on_tag_pressed(tag: String) -> void:
	tag_search.emit(tag)
