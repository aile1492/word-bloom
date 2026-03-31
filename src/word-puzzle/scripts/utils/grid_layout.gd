## grid_layout.gd
## Calculates the cell pixel size from screen size and grid dimensions.
## All methods are static — no instance needed.
class_name GridLayout
extends RefCounted


## Minimum cell size in pixels — smaller cells are too hard to tap.
const MIN_CELL_SIZE: float = 40.0

## Maximum cell size in pixels — ~130 px for an 8×8 grid on a 1080-wide base.
const MAX_CELL_SIZE: float = 160.0

## Total horizontal padding inside GridBoard (left + right, in pixels).
const HORIZONTAL_MARGINS: float = 20.0

## Gap between cells in pixels — minimal since tile images have no transparent padding.
const CELL_GAP: float = 1.0

## Overall grid scale factor (1.0 = 100%).
const GRID_SCALE: float = 0.93


## Calculates cell size from the GridBoard's own size (area).
## Pass grid_board.size from grid_board.gd.
static func calculate_cell_size(
	area: Vector2,
	grid_width: int,
	grid_height: int
) -> float:
	var total_gap_x: float = CELL_GAP * (grid_width - 1)
	var total_gap_y: float = CELL_GAP * (grid_height - 1)

	var cell_by_width: float = (area.x - HORIZONTAL_MARGINS - total_gap_x) / grid_width
	var cell_by_height: float = (area.y - total_gap_y) / grid_height

	var cell_size: float = minf(cell_by_width, cell_by_height) * GRID_SCALE
	cell_size = clampf(cell_size, MIN_CELL_SIZE, MAX_CELL_SIZE)

	return cell_size


## Calculates the total pixel size of the grid.
static func calculate_grid_pixel_size(
	cell_size: float,
	grid_width: int,
	grid_height: int
) -> Vector2:
	var total_width: float = cell_size * grid_width + CELL_GAP * (grid_width - 1)
	var total_height: float = cell_size * grid_height + CELL_GAP * (grid_height - 1)
	return Vector2(total_width, total_height)
