## grid_calculator.gd
## Utility that derives grid dimensions and word counts from a stage number.
## All methods are static — no instance needed.
class_name GridCalculator


## Returns the group index for the given stage.
## Stages are grouped in sets of 4.
static func get_group_index(stage: int) -> int:
	return int(floor(float(stage - 1) / 4.0))


## Returns the grid width for the given stage.
## Width increases by 1 on every odd group transition, capped at 10.
static func get_grid_width(stage: int) -> int:
	var group_index := get_group_index(stage)
	return mini(5 + int(floor(float(group_index + 1) / 2.0)), 10)


## Returns the grid height for the given stage.
## Height increases by 1 on every even group transition, capped at 10.
static func get_grid_height(stage: int) -> int:
	var group_index := get_group_index(stage)
	return mini(5 + int(floor(float(group_index) / 2.0)), 10)


## Returns true if the given stage is a rest stage (multiple of 10).
static func is_rest_stage(stage: int) -> bool:
	return stage > 0 and stage % GameConstants.REST_STAGE_INTERVAL == 0


## Returns the word count for the given stage.
## Increases by 1 every 5 stages, capped at 12.
## dda_offset: pass DDAManager.get_current_offset() (not applied to rest stages).
static func get_word_count(stage: int, dda_offset: int = 0) -> int:
	var base: int = mini(
		GameConstants.START_WORD_COUNT + int(floor(float(stage - 1) / float(GameConstants.WORD_INCREASE_INTERVAL))),
		GameConstants.MAX_WORD_COUNT
	)
	if is_rest_stage(stage):
		return maxi(base - GameConstants.REST_WORD_REDUCTION, GameConstants.START_WORD_COUNT)
	return clampi(base + dda_offset, GameConstants.START_WORD_COUNT, GameConstants.MAX_WORD_COUNT)


## Returns the maximum word length allowed for the given grid dimensions and language.
static func get_max_word_length(width: int, height: int, language: String) -> int:
	var grid_max := mini(width, height)
	if language == "ko":
		if width >= 7 and height >= 6:
			return mini(5, grid_max)
		else:
			return grid_max
	return grid_max


## Returns a Dictionary with all stage configuration values.
static func get_stage_config(stage: int) -> Dictionary:
	return {
		"stage": stage,
		"width": get_grid_width(stage),
		"height": get_grid_height(stage),
		"word_count": get_word_count(stage, 0),
		"group_index": get_group_index(stage)
	}
