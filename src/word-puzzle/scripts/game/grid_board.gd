## grid_board.gd
## Dynamically builds and lays out LetterCell instances inside a GridContainer.
## Also handles cell highlighting and focus-neighbor setup for TV mode.
class_name GridBoard
extends CenterContainer


## Preloaded LetterCell scene.
const LetterCellScene: PackedScene = preload("res://scenes/game/letter_cell.tscn")

## Active cell array (1D, row-major order).
var _cells: Array = []  # Array[LetterCell]

## Cell size in pixels.
var _cell_size: float = 60.0

## Reference to the current grid data.
var _grid_data: GridData = null

## Object pool for reusing cells.
var _cell_pool: Array = []  # Array[LetterCell]

@onready var grid_container: GridContainer = $GridContainer


## Builds the grid UI from the provided GridData.
## area_override: when non-zero, this size is used instead of self.size to calculate cell size.
##   Pass the actual available area after subtracting overlay space (banner, word bank, action bar).
func build_grid(data: GridData, area_override: Vector2 = Vector2.ZERO) -> void:
	_clear_grid()
	_grid_data = data

	# Use area_override if provided; otherwise fall back to self.size (guaranteed after anchor layout).
	var area: Vector2 = area_override if area_override != Vector2.ZERO else size
	_cell_size = GridLayout.calculate_cell_size(
		area, data.width, data.height
	)

	grid_container.columns = data.width
	grid_container.add_theme_constant_override("h_separation", int(GridLayout.CELL_GAP))
	grid_container.add_theme_constant_override("v_separation", int(GridLayout.CELL_GAP))

	for y in range(data.height):
		for x in range(data.width):
			var cell: LetterCell = _get_or_create_cell()
			grid_container.add_child(cell)
			cell.set_cell_size(_cell_size)
			cell.setup(Vector2i(x, y), data.grid[y][x])
			_cells.append(cell)

	# Set up focus neighbors for TV mode.
	if LayoutManager.is_tv:
		_setup_focus_neighbors()


## Returns the cell at the given grid coordinate.
func get_cell_at(pos: Vector2i) -> LetterCell:
	var index := pos.y * grid_container.columns + pos.x
	if index >= 0 and index < _cells.size():
		return _cells[index]
	return null


## Sets the visual state of a list of cells at once.
func set_cells_state(cells: Array, state: LetterCell.VisualState) -> void:
	for pos in cells:
		var cell := get_cell_at(pos)
		if cell:
			cell.set_visual_state(state)


## Updates the drag highlight for the current drag path.
func highlight_drag(cells: Array, previous_cells: Array, color_index: int = -1) -> void:
	# Reset cells that were in the previous path but not in the new one.
	for pos in previous_cells:
		if not cells.has(pos):
			var cell := get_cell_at(pos)
			if cell and cell.get_visual_state() == LetterCell.VisualState.DRAGGING:
				cell.set_visual_state(LetterCell.VisualState.IDLE)

	# Highlight cells in the new drag path.
	for pos in cells:
		var cell := get_cell_at(pos)
		if cell:
			cell.set_visual_state(LetterCell.VisualState.DRAGGING, color_index)


## Marks all cells of a found word as FOUND.
func mark_word_found(placed_word: PlacedWord) -> void:
	for pos in placed_word.cells:
		var cell := get_cell_at(pos)
		if cell:
			cell.set_visual_state(LetterCell.VisualState.FOUND, placed_word.color_index)


## Marks a single cell as FOUND (used for sequential reveal animations).
func mark_cell_found(pos: Vector2i, color_index: int) -> void:
	var cell := get_cell_at(pos)
	if cell:
		cell.set_visual_state(LetterCell.VisualState.FOUND, color_index)


## Clears the drag highlight from a list of cells.
func clear_drag_highlight(cells: Array) -> void:
	for pos in cells:
		var cell := get_cell_at(pos)
		if cell and cell.get_visual_state() == LetterCell.VisualState.DRAGGING:
			cell.set_visual_state(LetterCell.VisualState.IDLE)


## Returns the cell size in pixels (used for input coordinate conversion).
func get_cell_size() -> float:
	return _cell_size


## Removes all cells from the grid UI.
func _clear_grid() -> void:
	for cell in _cells:
		_return_cell_to_pool(cell)
	_cells.clear()


## Retrieves a cell from the pool, or creates a new one if the pool is empty.
func _get_or_create_cell() -> LetterCell:
	if _cell_pool.size() > 0:
		return _cell_pool.pop_back()
	return LetterCellScene.instantiate()


## Returns a used cell to the pool.
func _return_cell_to_pool(cell: LetterCell) -> void:
	if cell.get_parent():
		cell.get_parent().remove_child(cell)
	cell.reset()
	_cell_pool.append(cell)


## Sets up focus neighbors for TV mode.
func _setup_focus_neighbors() -> void:
	if _grid_data == null:
		return

	var width: int = _grid_data.width
	var height: int = _grid_data.height

	for y in range(height):
		for x in range(width):
			var index: int = y * width + x
			var cell: Control = _cells[index]

			cell.focus_neighbor_left = _cells[y * width + (maxi(x - 1, 0))].get_path()
			cell.focus_neighbor_right = _cells[y * width + (mini(x + 1, width - 1))].get_path()
			cell.focus_neighbor_top = _cells[(maxi(y - 1, 0)) * width + x].get_path()
			cell.focus_neighbor_bottom = _cells[(mini(y + 1, height - 1)) * width + x].get_path()

	# Set initial focus to the center cell.
	@warning_ignore("integer_division")
	var center_index: int = (height / 2) * width + (width / 2)
	_cells[center_index].grab_focus()
