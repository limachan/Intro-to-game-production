@tool
extends Tree

## Options in the popup-menu.
## The number here is the "ID" of the item in the editor.
enum LibraryPopupMenuOption {
	## Opens the delete library dialog
	DELETE = 0,

	## Rename the library
	RENAME = 1,
}

## Emitted when a path is selected in the tree.
## Will emit an empty string if the "root" of the libary is selected.
signal path_selected(full_path: String)

## Emitted when the user confirms the delete library dialog
signal library_delete_confirmed(library_id: int)

@onready var library_popup_menu: PopupMenu = %LibraryPopupMenu
@onready var delete_library_confirmation_dialog: ConfirmationDialog = %DeleteLibraryConfirmationDialog

## ID of the library that was right-clicked to open the dropdown
var popup_menu_library_id: int = -1

## Name of the library that was right-clicked
var popup_menu_library_name: String = ""


func _ready() -> void:
	item_selected.connect(_on_item_selected)

	library_popup_menu.id_pressed.connect(_on_library_popup_menu_id_pressed)

	delete_library_confirmation_dialog.confirmed.connect(_on_delete_library_confirmation_dialog_confirmed)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == MouseButton.MOUSE_BUTTON_RIGHT and mouse_button_event.pressed:
			var item: TreeItem = get_item_at_position(get_local_mouse_position())

			# currently, only allow right-clicking libraries and not folders
			if not item or not item.has_meta(&"library_id"):
				library_popup_menu.hide()
				popup_menu_library_id = -1
				popup_menu_library_name = ""

				return

			item.select(0)

			var library_id: int = item.get_meta(&"library_id")
			var library_name: String = item.get_meta(&"library_name")

			popup_menu_library_id = library_id
			popup_menu_library_name = library_name

			# Straight from the docs for `get_screen_position()`:
			# ---
			# Returns the position of this Control in global screen coordinates (i.e. taking window position into account). Mostly useful for editor plugins. Equivalent to get_screen_transform().origin (see CanvasItem.get_screen_transform). Example: Show a popup at the mouse position:
			# popup_menu.position = get_screen_position() + get_screen_transform().basis_xform(get_local_mouse_position())
			# # The above code is equivalent to:
			# popup_menu.position = get_screen_transform() * get_local_mouse_position()
			# popup_menu.reset_size()
			# ---
			library_popup_menu.popup()
			library_popup_menu.position = get_screen_transform() * mouse_button_event.position
			library_popup_menu.reset_size()


func _on_library_popup_menu_id_pressed(id: int) -> void:
	match id:
		LibraryPopupMenuOption.DELETE:
			_show_delete_library_confirmation_dialog()
		LibraryPopupMenuOption.RENAME:
			# the `true` here forces the item to be editable, which lets the user change it
			# but once the editing stops, it is no longer editable
			#
			# note that the `item_edited` signal is listened to in Rust
			edit_selected(true)


func _show_delete_library_confirmation_dialog() -> void:
	# TODO translate
	delete_library_confirmation_dialog.dialog_text = "Are you sure you want to remove the library \"%s\"?\n\nThis will not delete any files, but you will lose any metadata such as tags that you have applied." % popup_menu_library_name

	delete_library_confirmation_dialog.popup()


func _on_delete_library_confirmation_dialog_confirmed() -> void:
	library_delete_confirmed.emit(popup_menu_library_id)


func _on_item_selected() -> void:
	var item: TreeItem = get_selected()

	if item == get_root():
		path_selected.emit("")
	else:
		var full_path: String = item.get_meta(&"full_path")

		path_selected.emit(full_path)


func _notification(what: int) -> void:
	# "fun" bug where if you open the popup menu and the editor loses focus, the popup stays open above all over windows and is still clickable
	# note that this also "swallows" ths click so you have to double-click but whatever
	#
	# extra fun, this is ONLY in the editor, the standalone app is fine
	if (
		Engine.is_editor_hint() and
		(
			what == NOTIFICATION_APPLICATION_FOCUS_OUT or
			what == NOTIFICATION_WM_WINDOW_FOCUS_OUT
		) and
		library_popup_menu.visible
	):
		library_popup_menu.hide()


## Given the path to a directory, selects it in the file tree and emits the `path_selected` signal with that path.
func select_directory(full_path: String) -> void:
	_find_and_select(get_root(), full_path)


## From the given item, recursively try to find the item with the given `full_path`.
## When the item is found, the tree is "un-collapsed" to show it and then it gets selcted
func _find_and_select(item: TreeItem, full_path: String) -> bool:
	if item.has_meta(&"full_path") and item.get_meta(&"full_path") == full_path:
		# this recursively un-collapses the tree so that this item is visible
		# (wow, very nice that it's built in!!!)
		item.uncollapse_tree()

		# the `true` here centers the scolling on the item, otherwise it shows up at the top
		scroll_to_item(item, true)

		set_selected(item, 0)
		path_selected.emit(full_path)

		return true

	for child in item.get_children():
		if _find_and_select(child, full_path):
			return true

	return false
