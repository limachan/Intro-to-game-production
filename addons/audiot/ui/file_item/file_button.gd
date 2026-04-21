@tool
extends Button

const FileItemPopupMenu := preload("res://addons/audiot/ui/file_item/file_item_popup_menu.gd")

@onready var file_item_popup_menu: FileItemPopupMenu = %FileItemPopupMenu


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == MouseButton.MOUSE_BUTTON_RIGHT and mouse_button_event.pressed:
			# Straight from the docs for `get_screen_position()`:
			# ---
			# Returns the position of this Control in global screen coordinates (i.e. taking window position into account). Mostly useful for editor plugins. Equivalent to get_screen_transform().origin (see CanvasItem.get_screen_transform). Example: Show a popup at the mouse position:
			# popup_menu.position = get_screen_position() + get_screen_transform().basis_xform(get_local_mouse_position())
			# # The above code is equivalent to:
			# popup_menu.position = get_screen_transform() * get_local_mouse_position()
			# popup_menu.reset_size()
			# ---
			file_item_popup_menu.popup()
			file_item_popup_menu.position = get_screen_transform() * mouse_button_event.position
			file_item_popup_menu.reset_size()
