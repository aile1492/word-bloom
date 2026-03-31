## grid_input_handler_tv.gd
## Input handling for TV mode only.
## Godot's built-in focus system handles D-pad navigation;
## this class only manages cell selection/cancellation via the A/B buttons.
class_name GridInputHandlerTV
extends Node


signal word_selected(cells: Array)  # Array[Vector2i]
signal selection_cancelled


var _first_cell: Vector2i = Vector2i(-1, -1)
var _is_selecting: bool = false

var _grid_board: GridBoard = null
var _grid_data: GridData = null


func setup(grid_board: GridBoard, grid_data: GridData) -> void:
	_grid_board = grid_board
	_grid_data = grid_data

	# Register the grid_select / grid_cancel actions at runtime.
	if not InputMap.has_action("grid_select"):
		InputMap.add_action("grid_select")
		var event_joypad := InputEventJoypadButton.new()
		event_joypad.button_index = JOY_BUTTON_A
		InputMap.action_add_event("grid_select", event_joypad)

	if not InputMap.has_action("grid_cancel"):
		InputMap.add_action("grid_cancel")
		var event_joypad := InputEventJoypadButton.new()
		event_joypad.button_index = JOY_BUTTON_B
		InputMap.action_add_event("grid_cancel", event_joypad)


func _unhandled_input(event: InputEvent) -> void:
	if LayoutManager.current_input_mode != InputMode.Type.DPAD:
		return

	if event.is_action_pressed("grid_select"):
		_on_select_pressed()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("grid_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()


func _on_select_pressed() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not focused.has_method("get_visual_state"):
		return

	var grid_pos: Vector2i = focused.grid_pos

	if not _is_selecting:
		_first_cell = grid_pos
		_is_selecting = true
		_highlight_first_cell(grid_pos)
	else:
		if grid_pos == _first_cell:
			_cancel_selection()
			return

		if not DirectionSnapper.is_valid_direction(_first_cell, grid_pos):
			_show_invalid_direction_feedback()
			return

		var delta := grid_pos - _first_cell
		var direction := Vector2i(signi(delta.x), signi(delta.y))
		var distance := DirectionSnapper.cell_distance(_first_cell, grid_pos)

		var cells: Array = []
		for i in range(distance + 1):
			var pos := _first_cell + direction * i
			cells.append(pos)

		_is_selecting = false
		_first_cell = Vector2i(-1, -1)
		word_selected.emit(cells)


func _on_cancel_pressed() -> void:
	if _is_selecting:
		_cancel_selection()


func _cancel_selection() -> void:
	_is_selecting = false
	_clear_first_cell_highlight()
	_first_cell = Vector2i(-1, -1)
	selection_cancelled.emit()


func _highlight_first_cell(pos: Vector2i) -> void:
	var cell: LetterCell = _grid_board.get_cell_at(pos)
	if cell:
		cell.set_visual_state(LetterCell.VisualState.DRAGGING)


func _clear_first_cell_highlight() -> void:
	if _first_cell != Vector2i(-1, -1):
		var cell: LetterCell = _grid_board.get_cell_at(_first_cell)
		if cell:
			cell.set_visual_state(LetterCell.VisualState.IDLE)


func _show_invalid_direction_feedback() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		var tween := create_tween()
		tween.tween_property(focused, "position:x", focused.position.x + 5, 0.05)
		tween.tween_property(focused, "position:x", focused.position.x - 5, 0.05)
		tween.tween_property(focused, "position:x", focused.position.x, 0.05)


func reset() -> void:
	_is_selecting = false
	_first_cell = Vector2i(-1, -1)
