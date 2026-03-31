## false_lead_generator.gd
## Places false leads (prefixes of answer words) in empty grid cells to increase difficulty.
## Only active from Stage 11 onwards.
## RefCounted class — GridGenerator instantiates this within the pipeline.
class_name FalseLeadGenerator
extends RefCounted


## All 8 placement directions.
const ALL_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
	Vector2i(1, 1),
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
]


# ===== Public API =====

## Places false leads in the grid.
## Returns the number of successfully placed leads.
## Returns 0 if stage is below MIN_STAGE.
func inject_false_leads(grid_data: GridData, stage: int) -> int:
	if stage < GameConstants.FALSE_LEAD_MIN_STAGE:
		return 0
	if grid_data.placed_words.is_empty():
		return 0

	var candidates: Array = grid_data.placed_words.duplicate()
	candidates.shuffle()

	var placed_count: int = 0

	for i: int in range(candidates.size()):
		if placed_count >= GameConstants.FALSE_LEAD_MAX_COUNT:
			break

		var target_word: PlacedWord = candidates[i] as PlacedWord
		if target_word.display.length() < GameConstants.FALSE_LEAD_PREFIX_MIN + 1:
			continue

		var max_prefix: int = mini(GameConstants.FALSE_LEAD_PREFIX_MAX, target_word.display.length() - 1)
		var prefix_len: int = randi_range(GameConstants.FALSE_LEAD_PREFIX_MIN, max_prefix)
		var prefix: String = target_word.display.substr(0, prefix_len)

		if _try_place_false_lead(grid_data, prefix, target_word):
			placed_count += 1
			if OS.is_debug_build():
				print("FalseLead: placed '%s' (source: '%s')" % [prefix, target_word.display])

	if OS.is_debug_build() and placed_count > 0:
		print("FalseLead: %d lead(s) placed (Stage %d)" % [placed_count, stage])

	return placed_count


# ===== Internal =====

func _try_place_false_lead(
	grid_data: GridData,
	prefix: String,
	original_word: PlacedWord
) -> bool:
	for _attempt: int in range(GameConstants.FALSE_LEAD_MAX_ATTEMPTS):
		var dir: Vector2i = ALL_DIRECTIONS[randi() % ALL_DIRECTIONS.size()]
		var start: Vector2i = Vector2i(
			randi() % grid_data.width,
			randi() % grid_data.height
		)

		if _can_place_prefix(grid_data, prefix, start, dir, original_word):
			_write_prefix(grid_data, prefix, start, dir)
			return true

	return false


func _can_place_prefix(
	grid_data: GridData,
	prefix: String,
	start: Vector2i,
	dir: Vector2i,
	original_word: PlacedWord
) -> bool:
	if start == original_word.start_pos:
		return false

	for c: int in range(prefix.length()):
		var pos: Vector2i = start + dir * c
		if not grid_data.is_in_bounds(pos):
			return false
		if grid_data.get_cell(pos) != "":
			return false

	return true


func _write_prefix(
	grid_data: GridData,
	prefix: String,
	start: Vector2i,
	dir: Vector2i
) -> void:
	for c: int in range(prefix.length()):
		var pos: Vector2i = start + dir * c
		grid_data.set_cell(pos, prefix[c])
