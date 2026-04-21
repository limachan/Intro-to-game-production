@tool
extends Popup
## Popup that shows all available tags and lets you search through them

const Meta := preload("res://addons/audiot/meta.gd")

## Emitted when a tag is added or removed.
## If `removed` is `true`, the tag was removed. Otherwise, it was added.
signal tag_changed(tag: String, removed: bool)

@onready var tag_line_edit: LineEdit = %TagLineEdit
@onready var tag_tree_list: Tree = %TagTreeList

## Used to track size of the popup for UI scaling
var initial_popup_size: Vector2


func _ready() -> void:
	initial_popup_size = size
	tag_tree_list.item_selected.connect(_on_tag_tree_list_item_selected)
	tag_line_edit.gui_input.connect(_on_tag_line_edit_gui_input)
	tag_line_edit.text_changed.connect(_on_tag_line_edit_text_changed)


func show_popup() -> void:
	tag_line_edit.text = ""
	tag_line_edit.visible = true

	tag_tree_list.clear()

	# create the "hidden root"
	tag_tree_list.create_item()

	var tags := Meta.get_tags(self)
	for tag: String in tags.keys():
		_add_tag_to_tree(tag, tags[tag])

	tag_line_edit.grab_focus()

	popup()

	var ui_scale := Meta.get_ui_scale(self)

	if not Engine.is_editor_hint():
		# in the editor, the content scale is automatically applied
		content_scale_factor = ui_scale

	size = initial_popup_size * ui_scale


func set_checked(tag: String, checked: bool) -> void:
	var root := tag_tree_list.get_root()

	for item in root.get_children():
		if item.get_text(0) == tag:
			item.set_checked(0, checked)
			return


func _add_tag_to_tree(tag: String, color: Color) -> TreeItem:
	var tree_item := tag_tree_list.create_item()

	tree_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	tree_item.set_text(0, tag)
	tree_item.set_editable(0, true)

	tree_item.set_custom_bg_color(0, color)

	var active_tags := Meta.get_selected_search_tags(self)
	tree_item.set_checked(0, tag in active_tags)

	var luminance := color.get_luminance()
	if luminance > 0.5:
		tree_item.set_custom_color(0, Color.BLACK)
	else:
		tree_item.set_custom_color(0, Color.WHITE)

	return tree_item


func _on_tag_line_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ENTER:
			tag_changed.emit(tag_line_edit.text, false)
			visible = false
			tag_line_edit.accept_event()


func _on_tag_line_edit_text_changed(new_text: String) -> void:
	tag_tree_list.clear()

	# create the "hidden root"
	tag_tree_list.create_item()

	var tags := Meta.get_tags(self)
	for tag: String in tags.keys():
		if new_text.is_empty() or tag.containsn(new_text):
			_add_tag_to_tree(tag, tags[tag])


func _on_tag_tree_list_item_selected() -> void:
	var selected_item := tag_tree_list.get_selected()
	if selected_item:
		var selected_tag := selected_item.get_text(0)
		var is_checked := selected_item.is_checked(0)
		tag_changed.emit(selected_tag, is_checked)
