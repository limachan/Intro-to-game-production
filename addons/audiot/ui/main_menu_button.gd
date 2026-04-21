@tool
extends MenuButton

const Meta := preload("res://addons/audiot/meta.gd")
const SettingsResource := preload("res://addons/audiot/settings_resource.gd")

enum MainMenuOptions {
	SETTINGS = 0,
	EXIT = 1,
	AUTO_PLAY = 3,
	HELP = 4,
	ISSUE = 5,
}

@onready var settings_popup: Popup = %SettingsPopup


func _ready() -> void:
	about_to_popup.connect(_on_about_to_popup)
	get_popup().id_pressed.connect(_on_popup_id_pressed)

	Meta.get_signal_settings_changed(self).connect(_on_settings_changed)

	if Engine.is_editor_hint():
		var quit_index := get_popup().get_item_index(MainMenuOptions.EXIT)
		get_popup().remove_item(quit_index)

		# separator
		get_popup().remove_item(quit_index - 1)

		var settings_index := get_popup().get_item_index(MainMenuOptions.SETTINGS)
		get_popup().remove_item(settings_index)


func _on_about_to_popup() -> void:
	var settings := Meta.get_settings(self)
	get_popup().set_item_checked(
		get_popup().get_item_index(MainMenuOptions.AUTO_PLAY),
		settings.auto_play,
	)


func _on_popup_id_pressed(id: int) -> void:
	match id:
		MainMenuOptions.SETTINGS:
			settings_popup.popup()
		MainMenuOptions.EXIT:
			get_tree().quit()
		MainMenuOptions.AUTO_PLAY:
			var checked := get_popup().is_item_checked(get_popup().get_item_index(id))

			var settings := Meta.get_settings(self)
			settings.auto_play = not checked
			Meta.save_settings(self, settings)

			get_popup().set_item_checked(
				get_popup().get_item_index(MainMenuOptions.AUTO_PLAY),
				settings.auto_play,
			)
		MainMenuOptions.HELP:
			OS.shell_open("https://audiot.app/guides/getting-started/overview/")
		MainMenuOptions.ISSUE:
			OS.shell_open("https://codeberg.org/TranquilMarmot/audiot/issues")


func _on_settings_changed(settings: SettingsResource) -> void:
	get_popup().set_item_checked(
		get_popup().get_item_index(MainMenuOptions.AUTO_PLAY),
		settings.auto_play,
	)
