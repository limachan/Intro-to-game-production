@tool
extends Button

const Meta := preload("res://addons/audiot/meta.gd")

signal tag_pressed(tag: String)

## Base style box to use for setting the styles of this button based on the tag color
@export var base_style: StyleBoxFlat

## Actual tag being rendered in this tag
var tag: String


func _ready() -> void:
	pressed.connect(_on_pressed)

	var tags := Meta.get_tags(self)
	var color: Color = tags.get(tag, Color("#191919"))
	var luminance := color.get_luminance()

	var normal_style: StyleBoxFlat = base_style.duplicate()
	normal_style.bg_color = color

	var hover_style: StyleBoxFlat = normal_style.duplicate()
	hover_style.bg_color = color.lightened(0.1)

	var pressed_style: StyleBoxFlat = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.1)

	if luminance > 0.5:
		normal_style.border_color = color.darkened(0.5)
		hover_style.border_color = color.darkened(0.5)
		pressed_style.border_color = color.darkened(0.5)

		add_theme_color_override("font_color", Color.BLACK)
		add_theme_color_override("font_hover_color", Color.BLACK)
		add_theme_color_override("font_pressed_color", Color.BLACK)
	else:
		normal_style.border_color = color.lightened(0.5)
		hover_style.border_color = color.lightened(0.5)
		pressed_style.border_color = color.lightened(0.5)

		add_theme_color_override("font_color", Color.WHITE)
		add_theme_color_override("font_hover_color", Color.WHITE)
		add_theme_color_override("font_pressed_color", Color.WHITE)

	add_theme_stylebox_override("normal", normal_style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", pressed_style)


func _on_pressed() -> void:
	tag_pressed.emit(tag)
