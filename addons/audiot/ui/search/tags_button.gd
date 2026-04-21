@tool
extends Button

const Meta := preload("res://addons/audiot/meta.gd")
const TagSearchPopupMenu := preload("res://addons/audiot/ui/tags/tag_search_popup_menu.gd")
const SeachBox := preload("res://addons/audiot/ui/search/search_box.gd")

@onready var tag_popup_menu: TagSearchPopupMenu = %TagSearchPopupMenu

var search_box: SeachBox


func _ready() -> void:
	search_box = owner as SeachBox

	assert(search_box, "TagsButton must be a child of SearchBox")

	pressed.connect(_on_pressed)
	tag_popup_menu.tag_changed.connect(search_box.tag_search_changed.emit)


func _on_pressed() -> void:
	var selected_search_tags := Meta.get_selected_search_tags(self)

	for tag in selected_search_tags:
		tag_popup_menu.set_checked(tag, true)

	tag_popup_menu.show_popup()
	tag_popup_menu.position = get_screen_position() + Vector2(0, size.y)
