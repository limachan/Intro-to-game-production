extends Resource

enum Themes {
	CATPUCCIN_FRAPPE = 0,
	GODOT_DEFAULT = 1,
}

const THEME_PATHS: Dictionary[Themes, String] = {
	Themes.CATPUCCIN_FRAPPE: "res://addons/audiot/themes/catpuccin_frappe.tres",
	Themes.GODOT_DEFAULT: "res://addons/audiot/themes/godot_default.tres",
}

## Used to choose which audio device to use for playback.
## In-editor, this should always be "Default" since we don't want to stomp on the user actually hearing the game.
@export var selected_audio_output := "Default":
	set(value):
		selected_audio_output = value

		if not Engine.is_editor_hint():
			AudioServer.set_output_device(selected_audio_output)

## Scale to render the entire UI at.
## Note that in-editor, this is controlled by the editor settings.
@export var ui_scale := 1.0

## If true, selecting a file in the file view will automatically start playing it.
@export var auto_play := true

## Which theme to use for the UI
@export var theme_path := THEME_PATHS[Themes.CATPUCCIN_FRAPPE]
