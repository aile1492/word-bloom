## grid_data.gd
## Stores all grid data for a single stage.
class_name GridData
extends RefCounted

## Number of columns.
var width: int = 0

## Number of rows.
var height: int = 0

## 2D grid array. Access as grid[row][col].
var grid: Array = []  # Array[Array[String]]

## List of words placed in the grid.
var placed_words: Array[PlacedWord] = []

## Current stage number.
var stage: int = 0

## Language ("en" or "ko").
var language: String = "en"


## Returns the character at the given position.
func get_cell(pos: Vector2i) -> String:
	if pos.x < 0 or pos.x >= width or pos.y < 0 or pos.y >= height:
		return ""
	return grid[pos.y][pos.x]


## Sets the character at the given position.
func set_cell(pos: Vector2i, value: String) -> void:
	if pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height:
		grid[pos.y][pos.x] = value


## Returns true if the position is within the grid bounds.
func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height


## Returns true if all words have been found.
func is_all_found() -> bool:
	for pw in placed_words:
		if not pw.is_found:
			return false
	return true


## Returns the number of found words.
func get_found_count() -> int:
	var count := 0
	for pw in placed_words:
		if pw.is_found:
			count += 1
	return count


## Returns the total number of words.
func get_total_count() -> int:
	return placed_words.size()


## Returns a debug string representation of the grid.
func to_debug_string() -> String:
	var result := ""
	for row in grid:
		for cell in row:
			if cell == "":
				result += ". "
			else:
				result += cell + " "
		result += "\n"
	return result
