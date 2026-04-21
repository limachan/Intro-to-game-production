extends Node

## Resource that we're actually saving the settings to
const SettingsResource := preload("res://addons/audiot/settings_resource.gd")

const MainPanel := preload("res://addons/audiot/ui/main_panel.gd")


## Called by the `MainPanel` when it enters the tree
static func initialize(main_panel: MainPanel) -> void:
	main_panel.get_tree().set_meta("audiot__main_panel", main_panel)
	main_panel.get_tree().set_meta("audiot__signal__settings_changed", main_panel.setttings_changed)


## Returns a dictionary that contains all tags as they key and their colors as the value.
static func get_tags(node: Node) -> Dictionary[String, Color]:
	if not node.get_tree().has_meta("audiot__tags"):
		return { }

	# fun facts; using `{}` as a default in `get_meta` doesn't type the return dictionary which goes boom
	var tags: Dictionary[String, Color] = node.get_tree().get_meta("audiot__tags")
	return tags


## Returns a list of tags that are currently selected in the search box
static func get_selected_search_tags(node: Node) -> Array[String]:
	if not node.get_tree().has_meta("audiot__selected_search_tags"):
		return []

	# fun facts; using `[]` as a default in `get_meta` doesn't type the return array which goes boom
	var selected_tags: Array[String] = node.get_tree().get_meta("audiot__selected_search_tags")
	return selected_tags


## Load the settings from disk
static func _load_settings() -> SettingsResource:
	var settings := SettingsResource.new()

	var config := ConfigFile.new()
	var err := config.load(get_settings_save_path())

	if err:
		if err == ERR_FILE_NOT_FOUND:
			# this is fine, just means the user hasn't saved any settings yet
			return settings

		printerr("Error loading settings file: ", error_string(err))
		return

	for setting in config.get_section_keys("settings"):
		match setting:
			"selected_audio_output":
				settings.selected_audio_output = config.get_value("settings", setting, settings.selected_audio_output)
			"ui_scale":
				settings.ui_scale = config.get_value("settings", setting, settings.ui_scale)
			"auto_play":
				settings.auto_play = config.get_value("settings", setting, settings.auto_play)
			"theme_path":
				settings.theme_path = config.get_value("settings", setting, settings.theme_path)

	return settings


## Gets the path of the file to save settings to.
## For the editor plugin, this is controlled by the editor settings and is in the `audiot` folder in the editor data directory.
## For the standalone app, this is in the user data directory.
static func get_settings_save_path() -> String:
	if Engine.is_editor_hint():
		# in the editor plugin, this is controlled by the editor settings
		var editor_interface: Object = Engine.get_singleton("EditorInterface")
		var editor_paths: Object = editor_interface.call("get_editor_paths")
		var data_dir: String = editor_paths.call("get_data_dir")
		var full_file_path = data_dir.path_join("audiot").path_join("settings.cfg")
		return full_file_path
	else:
		var data_dir := OS.get_user_data_dir()
		var full_file_path = data_dir.path_join("settings.cfg")
		return full_file_path


## Save the settings out to disk
static func save_settings(node: Node, settings: SettingsResource) -> void:
	var config := ConfigFile.new()

	config.set_value("settings", "selected_audio_output", settings.selected_audio_output)
	config.set_value("settings", "ui_scale", settings.ui_scale)
	config.set_value("settings", "auto_play", settings.auto_play)
	config.set_value("settings", "theme_path", settings.theme_path)

	var err := config.save(get_settings_save_path())

	if err:
		printerr("Error saving settings file: ", error_string(err))

	node.get_tree().set_meta("audiot__settings", settings)

	get_signal_settings_changed(node).emit(settings)


## Get the settings for the app.
## This will also set the `audiot__settings` meta on the tree so it can be accessed from anywhere.
static func get_settings(node: Node) -> SettingsResource:
	if not node.get_tree().has_meta("audiot__settings"):
		var settings := _load_settings()
		node.get_tree().set_meta("audiot__settings", settings)
		return settings

	return node.get_tree().get_meta("audiot__settings")


## Get the scale to use for UI components.
## In the editor plugin, the scale is controlled by the user in the editor settings.
## In the standalone app, this is in the settings menu.
static func get_ui_scale(node: Node) -> float:
	if Engine.is_editor_hint():
		# in the editor plugin, this is controlled by the editor settings
		var editor_interface: Object = Engine.get_singleton("EditorInterface")
		var editor_scale: float = editor_interface.call("get_editor_scale")
		return editor_scale
	else:
		var settings := get_settings(node)
		return settings.ui_scale


## Get a signal that can be listened to for settings changes.
## Signal include the settings resource as an argument.
static func get_signal_settings_changed(node: Node) -> Signal:
	var settings_changed_signal: Signal = node.get_tree().get_meta("audiot__signal__settings_changed")
	return settings_changed_signal


## Emitted when the user selects/deselects files in the file list.
## Signal argument is `selected_files: Array[int]`.
static func get_signal_selected_files_changed(node: Node) -> Signal:
	var settings_changed_signal: Signal = node.get_tree().get_meta("audiot__signal__selected_files_changed")
	return settings_changed_signal
