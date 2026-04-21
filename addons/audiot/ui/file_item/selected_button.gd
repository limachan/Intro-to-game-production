@tool
extends Button

@export var selected_icon: Texture2D
@export var unselected_icon: Texture2D

var is_selected: bool = false:
	set(value):
		is_selected = value
		icon = selected_icon if is_selected else unselected_icon
