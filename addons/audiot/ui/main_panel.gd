@tool
extends Panel

const Meta := preload("res://addons/audiot/meta.gd")
const SettingsResource := preload("res://addons/audiot/settings_resource.gd")

@warning_ignore("unused_signal") # this is emitted from inside `Meta`
signal setttings_changed(settings: SettingsResource)


func _enter_tree() -> void:
	Meta.initialize(self)


func _ready() -> void:
	var settings := Meta.get_settings(self)

	if not Engine.is_editor_hint():
		var viewport := get_tree().root
		viewport.content_scale_factor = settings.ui_scale

		var theme_path := settings.theme_path
		var theme := load(theme_path)
		if theme and theme is Theme:
			get_tree().root.theme = theme
