@tool
extends PanelContainer

const Meta := preload("res://addons/audiot/meta.gd")

signal tag_removed(tag: String)
signal tag_color_changed(tag: String, color: Color)

@onready var tag_label: Label = %TagLabel
@onready var remove_tag_button: Button = %RemoveTagButton
@onready var color_picker_popup: Popup = %ColorPickerPopup
@onready var color_picker: ColorPicker = %ColorPicker
@onready var separator: Separator = %VSeparator

var initial_color_picker_popup_size: Vector2

var tag: String:
	set(value):
		tag = value
		tag_label.text = value

		var tags := Meta.get_tags(self)
		var color: Color = tags.get(tag, Color("#191919"))
		set_color(color, false)
	get:
		return tag_label.text


func _ready() -> void:
	remove_tag_button.pressed.connect(_on_remove_tag_button_pressed)
	color_picker.color_changed.connect(set_color)

	initial_color_picker_popup_size = color_picker_popup.size


func _on_remove_tag_button_pressed() -> void:
	tag_removed.emit(tag_label.text)
	self.queue_free()


func _show_color_picker() -> void:
	var ui_scale := Meta.get_ui_scale(self)

	if not Engine.is_editor_hint():
		# in the editor, the content scale is automatically applied
		color_picker_popup.content_scale_factor = ui_scale

	color_picker_popup.size = initial_color_picker_popup_size * ui_scale
	color_picker_popup.position = get_screen_position() - Vector2(0, color_picker_popup.size.y)
	color_picker_popup.popup()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MouseButton.MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_show_color_picker()


## Set the color for this tag.
## [param should_emit] Whether or not to emit the `tag_color_changed` signal
func set_color(color: Color, should_emit: bool = true) -> void:
	var current_stylebox := get_theme_stylebox("panel") as StyleBoxFlat
	current_stylebox.bg_color = color

	var separator_stylebox := separator.get_theme_stylebox("separator") as StyleBoxLine

	var luminance := color.get_luminance()
	if luminance > 0.5:
		current_stylebox.border_color = color.darkened(0.5)
		separator_stylebox.color = color.darkened(0.5)
		tag_label.add_theme_color_override("font_color", Color.BLACK)
		remove_tag_button.add_theme_color_override("icon_normal_color", color.darkened(0.5))
		remove_tag_button.add_theme_color_override("icon_hover_color", color.darkened(0.7))
	else:
		current_stylebox.border_color = color.lightened(0.5)
		separator_stylebox.color = color.lightened(0.5)
		tag_label.add_theme_color_override("font_color", Color.WHITE)
		remove_tag_button.add_theme_color_override("icon_normal_color", color.lightened(0.5))
		remove_tag_button.add_theme_color_override("icon_hover_color", color.lightened(0.7))

	add_theme_stylebox_override("panel", current_stylebox)

	color_picker.color = color

	if should_emit:
		tag_color_changed.emit(tag, color)
