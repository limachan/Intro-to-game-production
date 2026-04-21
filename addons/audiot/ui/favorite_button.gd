@tool
extends Button

@export var favorite_icon: Texture2D
@export var unfavorite_icon: Texture2D

var is_favorite: bool = false:
	set(value):
		is_favorite = value
		icon = favorite_icon if is_favorite else unfavorite_icon
