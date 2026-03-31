extends Node

## Singleton that manages overall game state and stage progression.

signal state_changed(new_state: StringName)

enum GameState {
	IDLE,
	PLAYING,
	PAUSED,
	COMPLETED,
	FAILED,
	## Backward-compat aliases: in case existing code references TITLE / RESULT / DAILY_CHALLENGE.
	TITLE,
	RESULT,
	DAILY_CHALLENGE,
}

enum GameMode {
	CLASSIC,
	TIME_ATTACK,
	DAILY_CHALLENGE,
	BONUS,
	MARATHON,
}

var current_state: GameState = GameState.TITLE
var current_mode: GameMode = GameMode.CLASSIC

## Stage info for the next game start (passed on scene transition).
var pending_stage: int = 61
var pending_word_pack_path: String = "res://data/words/en/animals.json"
var pending_word_count: int = 4

## [DEBUG ONLY] 0 = auto DDA. 1–12 = force this word count.
var debug_word_count_override: int = 0

## [DEBUG ONLY] 0 = normal flow. 1+ = force-jump to this stage.
## Example: 61 → immediately test Stage 61 (10×10 grid, difficulty 3 unlocked).
var debug_start_stage: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Runs even when paused.
	if OS.is_debug_build():
		DifficultyTest.run()


func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(GameState.keys()[new_state])


## Stage start request — call before scene transition.
## word_count: final count after applying DDA and rest-stage logic.
func request_stage(stage: int, word_pack_path: String, word_count: int = 0) -> void:
	pending_stage = stage
	pending_word_pack_path = word_pack_path
	if OS.is_debug_build() and debug_word_count_override > 0:
		pending_word_count = debug_word_count_override
	else:
		pending_word_count = word_count if word_count > 0 else GridCalculator.get_word_count(stage)
	change_state(GameState.PLAYING)
