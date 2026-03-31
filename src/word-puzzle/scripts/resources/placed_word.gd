## placed_word.gd
## Records the position, direction, and discovery status of a word placed in the grid.
class_name PlacedWord
extends RefCounted

## Original word (used as search/match key).
var word: String = ""

## Display word (the string actually placed in the grid).
var display: String = ""

## Start coordinate in the grid (col, row).
var start_pos: Vector2i = Vector2i.ZERO

## Placement direction vector (one of 8 directions).
var direction: Vector2i = Vector2i.ZERO

## Whether the player has found this word.
var is_found: bool = false

## Whether a hint has already been applied to this word (prevents duplicate hints).
var is_hinted: bool = false

## Hint type applied (-1 = none). Uses HintType.Type values.
var hint_type: int = -1

## Array of grid cell coordinates occupied by this word.
var cells: Array[Vector2i] = []

## Word category.
var category: String = ""

## Highlight colour index used when the word is found.
var color_index: int = -1


## Creates a PlacedWord and automatically calculates the cells array.
static func create(
	p_word: String,
	p_display: String,
	p_start: Vector2i,
	p_direction: Vector2i,
	p_category: String = ""
) -> PlacedWord:
	var pw := PlacedWord.new()
	pw.word = p_word
	pw.display = p_display
	pw.start_pos = p_start
	pw.direction = p_direction
	pw.category = p_category
	pw.cells = _calculate_cells(p_start, p_direction, p_display.length())
	return pw


static func _calculate_cells(
	start: Vector2i,
	dir: Vector2i,
	length: int
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for i in range(length):
		result.append(start + dir * i)
	return result


func to_debug_string() -> String:
	var found_str := "FOUND" if is_found else "HIDDEN"
	return "%s [%s] at (%d,%d) dir(%d,%d) %s" % [
		display, word, start_pos.x, start_pos.y,
		direction.x, direction.y, found_str
	]
