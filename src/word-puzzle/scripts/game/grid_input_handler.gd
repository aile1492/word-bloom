## grid_input_handler.gd
## Main class for grid input handling.
## Receives touch/mouse input and emits signals with the resulting cell selection.
## TV mode is handled separately by grid_input_handler_tv.gd.
class_name GridInputHandler
extends Node


# ===== State =====

enum State {
	IDLE,       ## Waiting for input.
	DRAGGING,   ## Drag in progress.
	TAP_FIRST,  ## Tap mode — first cell selected, waiting for second.
}


# ===== Signals =====

signal drag_started(start_cell: Vector2i)
signal drag_updated(cells: Array)
signal drag_ended(cells: Array)
signal drag_cancelled
signal cell_tapped(pos: Vector2i)
signal tap_cancelled
signal tap_invalid(first: Vector2i, second: Vector2i)
signal hover_changed(pos: Vector2i)


# ===== State variables =====

var _state: State = State.IDLE
var _drag_start_cell: Vector2i = Vector2i.ZERO
var _drag_start_screen: Vector2 = Vector2.ZERO
var _current_selected_cells: Array = []  # Array[Vector2i]
var _tap_first_cell: Vector2i = Vector2i(-1, -1)
var _hover_cell: Vector2i = Vector2i(-1, -1)


# ===== References =====

var _grid_board: GridBoard = null
var _grid_data: GridData = null
var _cell_size: float = 60.0
var _cell_gap: float = 2.0


# ===== Initialisation =====

func setup(grid_board: GridBoard, grid_data: GridData) -> void:
	_grid_board = grid_board
	_grid_data = grid_data
	_cell_size = grid_board.get_cell_size()
	_cell_gap = GridLayout.CELL_GAP
	_state = State.IDLE


# ===== Event handling =====

func _input(event: InputEvent) -> void:
	if LayoutManager.current_input_mode == InputMode.Type.DPAD:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_start_drag(event.position)
		else:
			_end_drag()

	elif event is InputEventScreenDrag:
		_update_drag(event.position)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(event.position)
			else:
				_end_drag()

	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_update_drag(event.position)
		else:
			_update_hover(event.position)


# ===== Drag handling =====

func _start_drag(screen_pos: Vector2) -> void:
	var grid_pos := _screen_to_grid(screen_pos)

	if not _grid_data.is_in_bounds(grid_pos):
		return

	_state = State.DRAGGING
	_drag_start_cell = grid_pos
	_drag_start_screen = screen_pos
	_current_selected_cells.clear()
	_current_selected_cells.append(grid_pos)

	drag_started.emit(grid_pos)


func _update_drag(screen_pos: Vector2) -> void:
	if _state != State.DRAGGING:
		return

	var snapped_dir := DirectionSnapper.snap_direction(
		_drag_start_screen,
		screen_pos
	)

	if snapped_dir == Vector2i.ZERO:
		return

	var current_grid_pos := _screen_to_grid(screen_pos)
	var cell_dist := DirectionSnapper.cell_distance(_drag_start_cell, current_grid_pos)

	var new_cells := DirectionSnapper.get_snapped_path(
		_drag_start_cell,
		snapped_dir,
		cell_dist + 1,
		_grid_data.width,
		_grid_data.height
	)

	if new_cells == _current_selected_cells:
		return

	_current_selected_cells = new_cells
	drag_updated.emit(_current_selected_cells)


func _end_drag() -> void:
	if _state != State.DRAGGING:
		return

	_state = State.IDLE
	var final_cells := _current_selected_cells.duplicate()
	_current_selected_cells.clear()

	if final_cells.size() >= 2:
		drag_ended.emit(final_cells)
	else:
		if final_cells.size() == 1:
			_handle_tap(final_cells[0])
		drag_cancelled.emit()


# ===== Tap handling =====

func _handle_tap(grid_pos: Vector2i) -> void:
	if not _grid_data.is_in_bounds(grid_pos):
		return

	match _state:
		State.IDLE:
			_state = State.TAP_FIRST
			_tap_first_cell = grid_pos
			cell_tapped.emit(grid_pos)

		State.TAP_FIRST:
			if grid_pos == _tap_first_cell:
				_state = State.IDLE
				_tap_first_cell = Vector2i(-1, -1)
				tap_cancelled.emit()
			else:
				_complete_tap_selection(grid_pos)


func _complete_tap_selection(second_cell: Vector2i) -> void:
	if not DirectionSnapper.is_valid_direction(_tap_first_cell, second_cell):
		tap_invalid.emit(_tap_first_cell, second_cell)
		return

	var delta := second_cell - _tap_first_cell
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var distance := DirectionSnapper.cell_distance(_tap_first_cell, second_cell)

	var cells: Array = []
	for i in range(distance + 1):
		var pos := _tap_first_cell + direction * i
		if _grid_data.is_in_bounds(pos):
			cells.append(pos)

	_state = State.IDLE
	_tap_first_cell = Vector2i(-1, -1)

	if cells.size() >= 2:
		drag_ended.emit(cells)


# ===== Hover handling (PC mouse only) =====

func _update_hover(screen_pos: Vector2) -> void:
	var grid_pos := _screen_to_grid(screen_pos)
	if not _grid_data.is_in_bounds(grid_pos):
		grid_pos = Vector2i(-1, -1)

	if grid_pos != _hover_cell:
		_hover_cell = grid_pos
		hover_changed.emit(_hover_cell)


# ===== Coordinate conversion =====

func _screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var grid_container := _grid_board.get_node("GridContainer") as GridContainer
	var grid_global_pos: Vector2 = grid_container.global_position
	var local_x: float = screen_pos.x - grid_global_pos.x
	var local_y: float = screen_pos.y - grid_global_pos.y
	var step: float = _cell_size + _cell_gap
	return Vector2i(int(local_x / step), int(local_y / step))


func _grid_to_screen(grid_pos: Vector2i) -> Vector2:
	var grid_container := _grid_board.get_node("GridContainer") as GridContainer
	var grid_global_pos: Vector2 = grid_container.global_position
	var step: float = _cell_size + _cell_gap
	return Vector2(
		grid_global_pos.x + grid_pos.x * step + _cell_size / 2.0,
		grid_global_pos.y + grid_pos.y * step + _cell_size / 2.0
	)


# ===== Public API =====

func get_state() -> State:
	return _state


func get_selected_cells() -> Array:
	return _current_selected_cells.duplicate()


func reset() -> void:
	_state = State.IDLE
	_current_selected_cells.clear()
	_tap_first_cell = Vector2i(-1, -1)
	_hover_cell = Vector2i(-1, -1)
