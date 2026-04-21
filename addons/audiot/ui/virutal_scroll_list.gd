@tool
extends Control
## Pool-based virtual scroll list that can renders large lists by
## recycling a fixed pool of [Control] instances.
##
## Only enough instances to fill the visible area are ever created.
## As the user scrolls, off-screen items are repositioned and rebound to new data via
## the [member update_list_item] function.
##
## Note that all items in the list will be set to the same height,
## as measured from the height of the first instance.
##
## Usage:
##   1. Set [member item_scene] to a [PackedScene] of the row template.
##   2. Set [member item_count] to the total number of logical items.
##   3. Set [member update_list_item] to a [Callable] with signature:
##      [code]func(item_node: Control, item_index: int) -> void[/code]
##   4. Call [method refresh] whenever data changes.

## The scene to instantiate for each pooled row.
## NOTE: This must extend [code]Control[/code].
@export var item_scene: PackedScene

## How many extra rows to keep pooled above and below the visible area
@export var overflow_rows := 2

## How many pixels each mouse wheel event scrolls
@export var scroll_tick_amount := 48.0

## Container that holds all pooled item nodes.
## This is clipped by this control and we manually scroll it.
@onready var content: Control = %Content

## The scrollbar on the right side of the control
@onready var _scrollbar: VScrollBar = %VScrollBar

## Total number of items in the list
var item_count: int = 0:
	set(value):
		item_count = value

		if content != null:
			_update_scrollbar()
			_sync_pool_size()
			_layout()

## Called as [code]update_list_item.call(node: Control, index: int)[/code] every
## time a pooled node needs to display a different item.
##
## This should set the values on the node to reflect the backing data.
var update_list_item: Callable = Callable()

## Pool of instantiated item [Control] nodes
var _pool: Array[Control] = []

## For each entry in [code]_pool[/code], which item index it currently represents (-1 = unbound).
var _pool_indices: Array[int] = []

## Height of each item in the list.
## Grabbed from the first instance of the given [code]item_scene[/code].
## Note that each pooled node is resized to this height, so all items must be the same height.
var _item_height: float = 0.0

## How far from the top of the viewport that we've scrolled
var _scroll_offset: float = 0.0

## Guards against re-entrant scrollbar updates
var _updating_scrollbar: bool = false


func _ready() -> void:
	_scrollbar.value_changed.connect(_on_scrollbar_value_changed)
	_position_scrollbar()

	# if item_count was set before _ready, the setter skipped setup, do it now
	if item_count > 0:
		_update_scrollbar()
		_sync_pool_size()
		_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and content != null:
		_position_scrollbar()
		_sync_pool_size()
		_layout()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.pressed:
			if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_set_scroll_offset(_scroll_offset + scroll_tick_amount)
				accept_event()
			elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_set_scroll_offset(_scroll_offset - scroll_tick_amount)
				accept_event()

	if event is InputEventPanGesture:
		var pan_gesture_event := event as InputEventPanGesture
		_set_scroll_offset(_scroll_offset + pan_gesture_event.delta.y * scroll_tick_amount)
		accept_event()

#region Public functions

## Rebuild the pool and force a layout update.
##
## Call after changing data or [member update_list_item].
func refresh() -> void:
	# invalidate all pool indices so _layout() rebinds every visible node
	_pool_indices.fill(-1)

	_update_scrollbar()
	_sync_pool_size()
	_layout()


## Refresh the given index, forcing it to grab its data again and re-render.
## Should be called whenever updating data for a single item.
func refresh_index(index: int) -> void:
	for pool_index in _pool_indices.size():
		if _pool_indices[pool_index] == index:
			_pool_indices[pool_index] = -1

	_layout.call_deferred()


## Scroll so that the given item index is visible
func scroll_to_index(index: int) -> void:
	if _item_height <= 0.0:
		return

	_set_scroll_offset(index * _item_height)


## Total height of ALL items
func get_total_height() -> float:
	return item_count * _item_height

#endregion

#region Scrollbar

## Position and resize the scrollbar to fit the right edge of the control
func _position_scrollbar() -> void:
	if not _scrollbar:
		return

	var scrollbar_width := _scrollbar.get_minimum_size().x

	# `size` here is how big the container node itself is
	_scrollbar.position = Vector2(size.x - scrollbar_width, 0.0)
	_scrollbar.size = Vector2(scrollbar_width, size.y)

	if content:
		content.size = Vector2(_get_content_width(), size.y)


## Update the scollbar's max value and current position
func _update_scrollbar() -> void:
	if not _scrollbar:
		return

	_updating_scrollbar = true

	var total := get_total_height()
	var page := size.y

	# `max_value` is the maximum scroll offset,
	# which is total content height minus one page
	# (since the last page can be partially visible)
	_scrollbar.max_value = maxf(total, page)

	_scrollbar.page = page
	_scrollbar.value = _scroll_offset
	_scrollbar.visible = total > page

	_updating_scrollbar = false


## Called when the scrollbar moves (via signal). Update the scroll offset and re-layout.
func _on_scrollbar_value_changed(value: float) -> void:
	if _updating_scrollbar:
		return

	_set_scroll_offset(value)


## Sets the scroll offset, clamping to the content height, then updates scrollbar and layout.
func _set_scroll_offset(value: float) -> void:
	var max_scroll := maxf(0.0, get_total_height() - size.y)

	_scroll_offset = clampf(value, 0.0, max_scroll)

	_update_scrollbar()
	_layout()

#endregion

#region Pool management

## Ensure the pool has exactly the right number of instances for the current
## viewport height + overflow padding.
func _sync_pool_size() -> void:
	if not item_scene:
		return

	# measure item height from the first instance, or a temporary one
	if _item_height <= 0.0:
		if _pool.size() > 0:
			_item_height = _pool[0].size.y
		else:
			var sample := item_scene.instantiate() as Control
			if not sample:
				push_error("VirtualScrollList: item_scene root must be a Control")
				return

			_item_height = sample.size.y

			sample.queue_free()

		# fallback to a default
		if _item_height <= 0.0:
			_item_height = 40.0

		var editor_scale := 1.0
		if Engine.is_editor_hint():
			# NOTE: Cannot use `EditorInterface` directly here since that will crash the app
			# when it is running outside of the editor; even referencing the class will cause a hard crash
			var editor_interface: Object = Engine.get_singleton("EditorInterface")
			if editor_interface:
				editor_scale = editor_interface.call("get_editor_scale")

		_item_height *= editor_scale

	var visible_rows := ceili(size.y / _item_height)
	var needed := visible_rows + overflow_rows * 2

	needed = clampi(needed, 0, item_count)

	# grow the pool to show the needed number of items to fit the current control size
	while _pool.size() < needed:
		var instance := item_scene.instantiate() as Control

		if not instance:
			push_error("VirtualScrollList: item_scene root must be a Control")
			return

		content.add_child(instance)
		_pool.append(instance)
		_pool_indices.append(-1)

	# shrink the pool if we don't need all of the nodes we currently have in it
	while _pool.size() > needed:
		var last := _pool.size() - 1
		var instance := _pool[last]

		_pool.remove_at(last)
		_pool_indices.remove_at(last)
		content.remove_child(instance)

		instance.queue_free()


## Return the usable width for item rows.
## Total width of control - scrollbar width
func _get_content_width() -> float:
	if _scrollbar and _scrollbar.visible:
		return size.x - _scrollbar.size.x

	return size.x

#endregion

#region Layout

## Reposition every pooled node and rebind any that changed index
func _layout() -> void:
	if _item_height <= 0.0 or _pool.is_empty():
		return

	var content_width := _get_content_width()

	# Find rows are visible, with overflow padding on top/bottom
	var first_visible_row := maxi(
		0,
		floori(_scroll_offset / _item_height) - overflow_rows,
	)

	var last_visible_row := mini(
		item_count - 1,
		ceili((_scroll_offset + size.y) / _item_height) + overflow_rows - 1,
	)

	for pool_idx in _pool.size():
		var logical_row := first_visible_row + pool_idx
		var node := _pool[pool_idx]

		if logical_row > last_visible_row or logical_row >= item_count:
			# this pool slot isn't needed right now, hide it
			node.visible = false
			_pool_indices[pool_idx] = -1
			continue

		node.visible = true
		node.position = Vector2(
			0.0,
			logical_row * _item_height - _scroll_offset,
		)
		node.size = Vector2(content_width, _item_height)

		# only rebind if the index changed
		var prev_index := _pool_indices[pool_idx]
		if prev_index != logical_row:
			_pool_indices[pool_idx] = logical_row

			if update_list_item.is_valid():
				update_list_item.call(node, logical_row)

#endregion
