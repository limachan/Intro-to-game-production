@tool
extends Control

const Meta := preload("res://addons/audiot/meta.gd")
const TagsButton := preload("res://addons/audiot/ui/search/tags_button.gd")
const Tag := preload("res://addons/audiot/ui/tags/tag.gd")

@export var favorite_icon: Texture2D
@export var unfavorite_icon: Texture2D
@export var library_tree: Tree
@export var tag_scene: PackedScene

## Emitted when the value in the search input changes
signal search_changed(new_test: String)

## Emitted when only showing favorites is toggled on/off
signal only_favorites_changed(only_favorites: bool)

## Emitted when the clear selected folder button is pressed
signal clear_selected_folder

## Emitted when the user selects/removes a tag to search by
signal tag_search_changed(tag: String, removed: bool)

## Emitted when changing the color of a tag from the searchbox
signal tag_color_changed(tag: String, color: Color)

@onready var search_line_edit: LineEdit = %SearchLineEdit
@onready var favorite_button: Button = %FavoriteButton
@onready var clear_selected_folder_button: Button = %FolderClearButton

@onready var tags_button: TagsButton = %TagsButton
@onready var tag_scroll_container: ScrollContainer = %TagScrollContainer
@onready var tag_scroll_hbox: HBoxContainer = %TagScrollHBoxContainer
@onready var search_debounce_timer: Timer = %DebounceTimer

var only_favorites: bool = false


func _ready() -> void:
	search_debounce_timer.timeout.connect(_on_search_debounce_timeout)

	search_line_edit.text_changed.connect(_on_search_text_changed)
	favorite_button.pressed.connect(_on_favorite_button_pressed)
	clear_selected_folder_button.pressed.connect(_on_clear_selected_folder_button_pressed)

	if library_tree:
		library_tree.item_selected.connect(_on_library_tree_item_selected)

	tags_button.tag_popup_menu.tag_changed.connect(_on_tag_changed)

	resized.connect(_update_tag_scroll_width)
	tag_scroll_hbox.sort_children.connect(_update_tag_scroll_width)

	_update_tag_scroll_width()


func _on_search_text_changed(_new_text: String) -> void:
	search_debounce_timer.start()


func _on_search_debounce_timeout() -> void:
	search_changed.emit(search_line_edit.text)


func _on_favorite_button_pressed() -> void:
	only_favorites = !only_favorites
	only_favorites_changed.emit(only_favorites)

	favorite_button.icon = favorite_icon if only_favorites else unfavorite_icon


func _on_library_tree_item_selected() -> void:
	clear_selected_folder_button.visible = true


func _on_clear_selected_folder_button_pressed() -> void:
	library_tree.deselect_all()
	clear_selected_folder_button.visible = false
	clear_selected_folder.emit()


## Tag selected/removed from the popover
func _on_tag_changed(tag: String, removed: bool, emit_event: bool = true) -> void:
	# not an existing tag; do nothing
	var tags := Meta.get_tags(self)
	if not tags.has(tag):
		return

	var seen := false
	for tag_node: Tag in tag_scroll_hbox.get_children():
		if tag_node.tag == tag:
			if removed:
				tag_node.queue_free()

				_update_tag_scroll_width.call_deferred()
				break

			seen = true

	if not removed and not seen:
		var new_tag := tag_scene.instantiate() as Tag
		tag_scroll_hbox.add_child(new_tag)
		new_tag.tag = tag

		new_tag.tag_color_changed.connect(tag_color_changed.emit)
		new_tag.tag_removed.connect(_on_tag_removed)

		_update_tag_scroll_width.call_deferred()

	if emit_event:
		tag_search_changed.emit(tag, removed)


func _on_tag_removed(tag: String) -> void:
	_on_tag_changed(tag, true)


## Recalculate the tag scroll container width so it fits its content up to half
## the total width of the search box.
##
## NOTE: Once this is merged, max width will be a native feature:
## https://github.com/godotengine/godot/pull/116640
func _update_tag_scroll_width() -> void:
	var child_count := tag_scroll_hbox.get_child_count()

	if child_count == 0:
		tag_scroll_container.custom_minimum_size.x = 0
		tag_scroll_container.visible = false
		return

	var content_width := 0.0
	for child: Control in tag_scroll_hbox.get_children():
		content_width += child.get_combined_minimum_size().x

	var separation := tag_scroll_hbox.get_theme_constant("separation")
	content_width += separation * (child_count - 1)

	var max_width := size.x / 2.0

	tag_scroll_container.visible = true
	tag_scroll_container.custom_minimum_size.x = minf(content_width, max_width)


## Called by the main extension when a tag should be added to the tag search filter
func external_add_tag_to_search(tag: String) -> void:
	_on_tag_changed(tag, false, false)


## Called by the main extension when a tag's color changes so that we can update
## the color in the search box
func external_tag_color_changed(tag: String, color: Color) -> void:
	for tag_node: Tag in tag_scroll_hbox.get_children():
		if tag_node.tag == tag:
			tag_node.set_color(color, false)
