@tool
extends PopupMenu

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton

		# for some reason, by default, only the left mouse button will hide the popup menu
		# https://github.com/godotengine/godot/blob/babc272d44ecfbd86e3b3fc5397ef936b1ce12d8/scene/gui/popup.cpp#L259
		if mouse_button_event.button_index == MouseButton.MOUSE_BUTTON_RIGHT and mouse_button_event.pressed:
			hide()
