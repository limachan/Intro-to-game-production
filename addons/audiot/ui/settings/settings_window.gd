@tool
extends Popup

const SettingsResource := preload("res://addons/audiot/settings_resource.gd")
const Meta := preload("res://addons/audiot/meta.gd")

@onready var audio_output_option_button: OptionButton = %AudioOutputOptionButton
@onready var show_database_button: Button = %ShowDatabaseButton
@onready var bug_report_button: Button = %BugReportButton

@onready var ui_scale_container: Control = %UIScaleContainer
@onready var ui_scale_slider: Slider = %UIScaleSlider
@onready var ui_scale_label: Label = %UIScaleSliderLabel
@onready var ui_scale_reset_button: Button = %UIScaleResetButton
@onready var theme_options: OptionButton = %ThemeOptionButton

@onready var close_button: Button = %CloseButton

## Settings; loaded when this component is ready
var settings: SettingsResource

## List of all available audio devices
var audio_devices: PackedStringArray = []

## Default size of the popup when it first opens, before any scaling is applied
var initial_size: Vector2i


func _ready() -> void:
	self.visibility_changed.connect(_on_visibility_changed)

	audio_output_option_button.item_selected.connect(_on_audio_output_changed)

	close_button.pressed.connect(_on_close_button_pressed)
	show_database_button.pressed.connect(_on_show_database_button_pressed)
	bug_report_button.pressed.connect(_on_bug_report_button_pressed)
	close_requested.connect(_on_close_requested)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	ui_scale_slider.drag_ended.connect(_on_ui_scale_drag_ended)
	ui_scale_reset_button.pressed.connect(_on_ui_scale_reset_button_pressed)
	theme_options.item_selected.connect(_on_theme_item_selected)

	initial_size = self.size


func _on_visibility_changed() -> void:
	if self.visible:
		settings = Meta.get_settings(self)

		_set_up_audio_output()

		var ui_scale := Meta.get_ui_scale(self)
		self.size = initial_size * ui_scale

		if not Engine.is_editor_hint():
			ui_scale_slider.value = settings.ui_scale
			ui_scale_label.text = "%s" % settings.ui_scale

			self.content_scale_factor = settings.ui_scale

			var theme_path := settings.theme_path
			var theme_index := SettingsResource.THEME_PATHS.values().find(theme_path)
			theme_options.select(theme_index)


func _set_up_audio_output() -> void:
	audio_output_option_button.clear()

	# See https://github.com/godotengine/godot-demo-projects/tree/master/audio/device_changer
	var current_device := AudioServer.get_output_device()
	audio_devices = AudioServer.get_output_device_list()

	for i in range(audio_devices.size()):
		var item := audio_devices[i]
		audio_output_option_button.add_item(item)

		if item == current_device:
			audio_output_option_button.select(i)


func _on_audio_output_changed(index: int) -> void:
	if index >= 0 and index < audio_devices.size():
		var selected_device := audio_devices[index]
		AudioServer.set_output_device(selected_device)
		settings.selected_audio_output = selected_device


func _on_ui_scale_changed(value: float) -> void:
	settings.ui_scale = value
	ui_scale_label.text = "%s" % value

	var viewport := get_tree().root
	viewport.content_scale_factor = value

	ui_scale_reset_button.visible = not value == 1.0


func _on_ui_scale_drag_ended(value_changed: bool) -> void:
	if value_changed:
		# don't change this as the user is dragging or things go haywire
		self.content_scale_factor = settings.ui_scale
		self.size = initial_size * settings.ui_scale


func _on_ui_scale_reset_button_pressed() -> void:
	ui_scale_slider.value = 1.0
	self.content_scale_factor = 1.0
	self.size = initial_size * settings.ui_scale


func _on_close_button_pressed() -> void:
	_on_close_requested()
	hide()


func _on_close_requested() -> void:
	Meta.save_settings(self, settings)


func _on_theme_item_selected(index: int) -> void:
	var new_theme_path: String = SettingsResource.THEME_PATHS[index]
	var theme: Theme = load(new_theme_path)

	get_tree().root.theme = theme

	settings.theme_path = new_theme_path


func _on_show_database_button_pressed() -> void:
	if Engine.is_editor_hint():
		# in the editor plugin, this is controlled by the editor settings
		var editor_interface: Object = Engine.get_singleton("EditorInterface")
		var editor_paths: Object = editor_interface.call("get_editor_paths")
		var data_dir: String = editor_paths.call("get_data_dir")
		var full_file_path = data_dir.path_join("audiot").path_join("library.db")
		OS.shell_show_in_file_manager(full_file_path)
	else:
		var data_dir := OS.get_user_data_dir()
		var full_file_path = data_dir.path_join("library.db")
		OS.shell_show_in_file_manager(full_file_path)


func _on_bug_report_button_pressed() -> void:
	OS.shell_open("https://codeberg.org/TranquilMarmot/audiot/issues")
