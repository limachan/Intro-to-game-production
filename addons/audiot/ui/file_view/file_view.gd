@tool
extends Control
## Represents a view of a selected audio file

const Tag := preload("res://addons/audiot/ui/tags/tag.gd")
const AudioStreamVisualizer := preload("res://addons/audiot/ui/file_view/audio_stream_visualizer.gd")
const AddTagButton := preload("res://addons/audiot/ui/tags/add_tag_button.gd")
const FavoriteButton := preload("res://addons/audiot/ui/favorite_button.gd")
const Meta := preload("res://addons/audiot/meta.gd")
const SettingsResource := preload("res://addons/audiot/settings_resource.gd")
const CopySelectedFilesButton := preload("res://addons/audiot/ui/file_view/copy_selected_files_button.gd")
const TimeLabel := preload("res://addons/audiot/ui/file_view/time_label.gd")

signal favorite_changed(file_id: int, is_favorite: bool)
signal tag_changed(file_id: int, tag: String, removed: bool)
signal tag_color_changed(tag: String, color: Color)
signal selected_file_changed
signal select_directory(dir_path: String)
signal copy_selected_files_to_dir(dir: String, current_file_id: int)
signal clear_selected_files

@export var tag_scene: PackedScene

@onready var file_view_container: Control = %FileViewContainer
@onready var file_name_label: Label = %FileNameLabel
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var audio_stream_visualizer: AudioStreamVisualizer = %AudioStreamVisualizer
@onready var auto_play_check_button: CheckButton = %AutoPlayCheckButton
@onready var favorite_button: FavoriteButton = %FavoriteButton
@onready var add_tag_button: AddTagButton = %AddTagButton
@onready var tag_list: Control = %TagList
@onready var time_label: TimeLabel = %TimeLabel

@onready var open_directory_button: Control = %OpenDirectoryButton
@onready var select_directory_button: Button = %SelectDirectoryButton
@onready var copy_selected_files_button: CopySelectedFilesButton = %CopySelectedFilesButton
@onready var clear_selected_files_button: Button = %ClearSelectedFilesButton
@onready var close_button: Button = %CloseButton

## Database ID for this file
var file_id: int

## Database ID for the library this file belongs to
var library_id: int

## Directory path for this file, used for opening the file in the system file explorer
var dir_path: String

## List of tags for this file
var tags: Array[String] = []:
	set(value):
		tags = value
		_update_tags()

## Name of the actual file (including extension)
var file_name: String:
	set(value):
		file_name = value
		file_name_label.text = value
		file_name_label.tooltip_text = value
		open_directory_button.set(&"full_file_path", dir_path.path_join(file_name))

## This will be set by [method set_selected_file] to the currently selected file's audio stream.
var audio_stream: AudioStream

## Whether or not this file is marked as a favorite.
## The state here is actually stored in the `favorite_button`.
var is_favorite: bool = false:
	set(value):
		favorite_button.is_favorite = value
	get:
		return favorite_button.is_favorite

## Thread being used to load a file in the background
var file_load_thread: Thread

var has_selected_files := false


func _ready() -> void:
	Meta.get_signal_selected_files_changed(self).connect(_on_selected_files_changed)

	favorite_button.pressed.connect(_on_favorite_button_pressed)

	add_tag_button.file_view = self
	add_tag_button.tag_changed.connect(_on_add_tag_tag_changed)
	select_directory_button.pressed.connect(_on_select_directory_button_pressed)
	close_button.pressed.connect(_close)

	copy_selected_files_button.copy_selected_files_to_dir.connect(_on_copy_selected_files_to_dir)
	clear_selected_files_button.pressed.connect(_on_clear_selected_files_button_pressed)

	time_label.audio_stream_player = audio_stream_player

	Meta.get_signal_settings_changed(self).connect(_on_settings_changed)


func _exit_tree() -> void:
	if file_load_thread:
		file_load_thread.wait_to_finish()


## Force an update of the list of tags for the current file
func _update_tags() -> void:
	# clear out everything EXCEPT the add tag button
	for child in tag_list.get_children():
		if child != add_tag_button:
			child.queue_free()

	var tag_colors := Meta.get_tags(self)

	for tag in tags:
		var tag_node := tag_scene.instantiate() as Tag
		tag_list.add_child(tag_node)
		tag_node.tag = tag

		if tag_colors.has(tag):
			tag_node.set_color(tag_colors[tag], false)

		tag_node.tag_removed.connect(_on_tag_removed)
		tag_node.tag_color_changed.connect(_on_tag_color_changed)

	# we want the add tag button to be at the end of the list
	tag_list.move_child(add_tag_button, -1)


func _on_add_tag_tag_changed(tag: String, removed: bool) -> void:
	if removed:
		_on_tag_removed(tag)
	else:
		_on_tag_added(tag)


func _on_tag_added(tag: String) -> void:
	if tag in tags:
		return

	tags.append(tag)
	tag_changed.emit(file_id, tag, false)

	_update_tags()


func _on_tag_removed(tag: String) -> void:
	if tag not in tags:
		return

	tags.erase(tag)
	tag_changed.emit(file_id, tag, true)

	_update_tags()


func _on_tag_color_changed(tag: String, color: Color) -> void:
	tag_color_changed.emit(tag, color)


func _on_selected_files_changed(selected_files: Array[int]) -> void:
	has_selected_files = not selected_files.is_empty()
	if not has_selected_files:
		if not file_view_container.visible:
			visible = false
	else:
		visible = true


## Set the data for the currently selected file.
func set_selected_file(
		_file_id: int,
		_library_id: int,
		_dir_path: String,
		_tags: Array[String],
		_is_favorite: bool,
		_file_name: String,
) -> void:
	file_id = _file_id
	library_id = _library_id
	dir_path = _dir_path
	tags = _tags
	file_name = _file_name
	is_favorite = _is_favorite

	# TODO this should be done via a signal?
	var settings := Meta.get_settings(self)
	auto_play_check_button.button_pressed = settings.auto_play

	# this will kick off a thread to load the file
	load_file()

	file_view_container.visible = true
	select_directory_button.visible = true
	open_directory_button.visible = true
	close_button.visible = true


func _close() -> void:
	if audio_stream_player.playing:
		audio_stream_player.stop()

	file_view_container.visible = false
	select_directory_button.visible = false
	open_directory_button.visible = false
	close_button.visible = false

	file_id = -1
	library_id = -1
	dir_path = ""
	file_name = ""
	tags = []
	is_favorite = false

	if not has_selected_files:
		visible = false


func load_file() -> void:
	if audio_stream_player.playing:
		audio_stream_player.stop()
		audio_stream_player.stream = null

	if is_instance_valid(audio_stream):
		audio_stream = null

	var full_path := dir_path.path_join(file_name)

	# NOTE: originall was checking `is_alive()` here but that wasn't actually needed
	if file_load_thread:
		file_load_thread.wait_to_finish()

	file_load_thread = Thread.new()
	file_load_thread.start(_load_file_threaded.bind(full_path))


## Loads the given audio file, intended to be run in a thread
func _load_file_threaded(full_path: String) -> void:
	var extension := full_path.get_extension().to_lower()
	match extension:
		"mp3":
			audio_stream = AudioStreamMP3.load_from_file(full_path)
		"ogg":
			audio_stream = AudioStreamOggVorbis.load_from_file(full_path)
		"wav":
			audio_stream = AudioStreamWAV.load_from_file(full_path)
		_:
			push_error("Unsupported file type: %s" % full_path)
			return

	_on_audio_stream_loaded.call_deferred()


## Called after the audio stream is loaded
func _on_audio_stream_loaded() -> void:
	audio_stream_player.stream = audio_stream

	if auto_play_check_button.button_pressed:
		play()

	audio_stream_visualizer.audio_stream = audio_stream
	selected_file_changed.emit()

	visible = true


func play() -> void:
	if not is_instance_valid(audio_stream):
		load_file()

	audio_stream_player.play()


func _on_favorite_button_pressed() -> void:
	favorite_changed.emit(file_id, not favorite_button.is_favorite)


func _on_select_directory_button_pressed() -> void:
	select_directory.emit(dir_path)


func _on_settings_changed(settings: SettingsResource) -> void:
	auto_play_check_button.button_pressed = settings.auto_play


func _on_copy_selected_files_to_dir(dir: String) -> void:
	copy_selected_files_to_dir.emit(dir, file_id)


func _on_clear_selected_files_button_pressed() -> void:
	clear_selected_files.emit()
