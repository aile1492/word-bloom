## direction_snapper.gd
## Snaps a drag vector to the nearest of 8 directions.
## All methods are static — no instance needed.
class_name DirectionSnapper
extends RefCounted


## 8-direction vectors (in angle order, starting at 0° with 45° increments).
const DIRECTION_VECTORS: Array[Vector2i] = [
	Vector2i(1, 0),    # 0: Right →       (0°)
	Vector2i(1, 1),    # 1: Down-Right ↘  (45°)
	Vector2i(0, 1),    # 2: Down ↓        (90°)
	Vector2i(-1, 1),   # 3: Down-Left ↙   (135°)
	Vector2i(-1, 0),   # 4: Left ←        (180°)
	Vector2i(-1, -1),  # 5: Up-Left ↖     (225°)
	Vector2i(0, -1),   # 6: Up ↑          (270°)
	Vector2i(1, -1),   # 7: Up-Right ↗    (315°)
]


## Snaps the vector from from_pos to to_pos to the nearest of the 8 directions.
## Returns Vector2i.ZERO if the distance is negligibly small.
static func snap_direction(from_pos: Vector2, to_pos: Vector2) -> Vector2i:
	var delta := to_pos - from_pos

	if delta.length() < 0.001:
		return Vector2i.ZERO

	var angle_deg := rad_to_deg(atan2(delta.y, delta.x))

	if angle_deg < 0.0:
		angle_deg += 360.0

	var bin_index := int((angle_deg + 22.5) / 45.0) % 8

	return DIRECTION_VECTORS[bin_index]


## Calculates the grid path from start_cell in the given direction.
static func get_snapped_path(
	start_cell: Vector2i,
	direction: Vector2i,
	drag_length: int,
	grid_width: int,
	grid_height: int
) -> Array:  # Array[Vector2i]
	var path: Array = []

	if direction == Vector2i.ZERO:
		path.append(start_cell)
		return path

	for i in range(drag_length):
		var pos := start_cell + direction * i

		if pos.x < 0 or pos.x >= grid_width:
			break
		if pos.y < 0 or pos.y >= grid_height:
			break

		path.append(pos)

	return path


## Returns the Chebyshev distance (in cells) between two grid cells.
static func cell_distance(from_cell: Vector2i, to_cell: Vector2i) -> int:
	var dx := absi(to_cell.x - from_cell.x)
	var dy := absi(to_cell.y - from_cell.y)
	return maxi(dx, dy)


## Returns true if the direction between two cells is a valid 8-direction
## (horizontal, vertical, or 45° diagonal).
static func is_valid_direction(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	var dx := to_cell.x - from_cell.x
	var dy := to_cell.y - from_cell.y

	if dx == 0 and dy == 0:
		return false

	if dx == 0 or dy == 0:
		return true

	return absi(dx) == absi(dy)
