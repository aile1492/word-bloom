## game_controller.gd
## Autoload that manages game flow.
## Handles the FSM: start game → result screen → return to home.
## Role is separate from GameManager (which handles stage data delivery).
extends Node


# ===== Constants =====

const GAME_SCENE: String = "res://scenes/screens/game_screen.tscn"
const RESULT_SCENE: String = "res://scenes/screens/result_screen.tscn"
const HOME_TAB: int = 2

## Stages at which features unlock.
const TIME_ATTACK_UNLOCK_STAGE: int = 10
const DAILY_UNLOCK_STAGE: int = 24

## Fade transition duration (seconds).
const FADE_DURATION: float = 0.35


# ===== Signals (P02_01) =====

signal game_started(stage: int, mode: int)
signal game_paused()
signal game_resumed()
signal game_completed(result: GameResult)
signal game_failed(result: GameResult)
signal game_state_changed(old_state: int, new_state: int)


# ===== DDA =====

var _dda: DDAManager = DDAManager.new()

# ===== Fade overlay =====

var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null
var _is_transitioning: bool = false


func _ready() -> void:
	_dda.load_save_state({
		"offset": SaveManager.load_value("dda_offset", 0),
		"history": SaveManager.load_value("dda_history", []),
	})
	_setup_fade_overlay()


func _setup_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func _fade_out(duration: float = FADE_DURATION) -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw: Tween = create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, duration)
	await tw.finished


func _fade_in(duration: float = FADE_DURATION) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(_fade_rect, "color:a", 0.0, duration)
	await tw.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ===== Start game =====

## Starts a stage. Called from HomeScreen's Play button.
func start_game(stage: int) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	var old_state: int = GameManager.current_state
	## [DEBUG] Force-jump to debug_start_stage if set.
	if OS.is_debug_build() and GameManager.debug_start_stage > 0:
		stage = GameManager.debug_start_stage
	## Check resume state.
	var resume: Dictionary = SaveManager.get_resume_state()
	var word_pack_path: String = ""
	if not resume.is_empty() and resume.get("stage", -1) == stage:
		word_pack_path = resume.get("word_pack_path", "")

	if word_pack_path.is_empty():
		var last_theme: String = SaveManager.get_last_theme()
		word_pack_path = ThemeRandomizer.pick(last_theme)
		SaveManager.set_last_theme(ThemeRandomizer.extract_theme(word_pack_path))

	var is_rest: bool = GridCalculator.is_rest_stage(stage)
	var base_count: int = GridCalculator.get_word_count(stage)
	var word_count: int = _dda.get_adjusted_word_count(base_count, is_rest, false)
	GameManager.request_stage(stage, word_pack_path, word_count)

	game_state_changed.emit(old_state, GameManager.GameState.PLAYING)
	game_started.emit(stage, GameManager.current_mode)

	await _fade_out()

	## Push if stack is empty, replace otherwise (prevent duplicates).
	if ScreenManager.can_pop():
		ScreenManager.replace_top_screen(GAME_SCENE, {"is_rest_stage": is_rest})
	else:
		ScreenManager.push_screen(GAME_SCENE, {"is_rest_stage": is_rest})

	await _fade_in()
	_is_transitioning = false


# ===== Game complete (clear) =====

## Records clear stats and DDA only. Does not transition screens.
## Used by the in-game StageCompletePopup flow.
func record_complete(result: GameResult) -> void:
	var old_state: int = GameManager.current_state
	result.is_cleared = true

	_dda.record_stage(true, result.clear_time, result.hint_count)
	_save_dda_state()

	SaveManager.update_stats(result)

	var mode_key: String = _get_mode_key(result.mode)
	result.is_new_record = SaveManager.check_and_update_best_time(mode_key, result.clear_time)

	if result.theme != "":
		SaveManager.add_used_theme(result.theme)

	var newly_unlocked: Array[String] = ThemeUnlockChecker.check_new_unlocks()
	for theme_id: String in newly_unlocked:
		if Engine.has_singleton("ToastManager"):
			ToastManager.show_toast("🎉 New theme unlocked: %s" % theme_id)

	SaveManager.clear_resume_state()
	_check_feature_unlocks(result.stage)

	GameManager.change_state(GameManager.GameState.COMPLETED)
	game_state_changed.emit(old_state, GameManager.GameState.COMPLETED)
	game_completed.emit(result)


## Returns the DDA-adjusted word count for the next stage.
## Used by StageCompletePopup when loading the next stage.
func get_next_word_count(stage: int) -> int:
	var is_rest: bool   = GridCalculator.is_rest_stage(stage)
	var base: int       = GridCalculator.get_word_count(stage)
	return _dda.get_adjusted_word_count(base, is_rest, false)


## Transitions to ResultScreen after a stage clear. Called from GameScreen.
func complete_game(result: GameResult) -> void:
	var old_state: int = GameManager.current_state
	result.is_cleared = true

	## Record DDA.
	_dda.record_stage(true, result.clear_time, result.hint_count)
	_save_dda_state()

	## Update stats.
	SaveManager.update_stats(result)

	## Update best time.
	var mode_key: String = _get_mode_key(result.mode)
	result.is_new_record = SaveManager.check_and_update_best_time(mode_key, result.clear_time)

	## Record theme usage.
	if result.theme != "":
		SaveManager.add_used_theme(result.theme)

	## Check theme unlocks — notify new unlocks via ToastManager (STEP6).
	var newly_unlocked: Array[String] = ThemeUnlockChecker.check_new_unlocks()
	for theme_id: String in newly_unlocked:
		if Engine.has_singleton("ToastManager"):
			ToastManager.show_toast("🎉 New theme unlocked: %s" % theme_id)

	## Clear resume state.
	SaveManager.clear_resume_state()

	## Feature unlock popup (when stage condition is met).
	_check_feature_unlocks(result.stage)

	## State transition.
	GameManager.change_state(GameManager.GameState.COMPLETED)
	game_state_changed.emit(old_state, GameManager.GameState.COMPLETED)
	game_completed.emit(result)

	ScreenManager.replace_top_screen(RESULT_SCENE, {"result": result})


# ===== Game fail =====

## Transitions to ResultScreen after a stage failure (timeout etc.).
func fail_game(result: GameResult) -> void:
	var old_state: int = GameManager.current_state
	result.is_cleared = false
	result.grade = "F"

	## Record DDA.
	_dda.record_stage(false, result.clear_time, result.hint_count)
	_save_dda_state()

	## Update stats.
	SaveManager.update_stats(result)

	## Clear resume state.
	SaveManager.clear_resume_state()

	## State transition.
	GameManager.change_state(GameManager.GameState.FAILED)
	game_state_changed.emit(old_state, GameManager.GameState.FAILED)
	game_failed.emit(result)

	ScreenManager.replace_top_screen(RESULT_SCENE, {"result": result})


# ===== Pause =====

func pause_game() -> void:
	GameManager.change_state(GameManager.GameState.PAUSED)
	game_paused.emit()


func resume_game() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	game_resumed.emit()


# ===== Return to home =====

## Clears the push layer and returns to the Home tab.
## Called from the back button and ResultScreen's "Home" button.
func return_to_home() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	await _fade_out()

	GameManager.change_state(GameManager.GameState.IDLE)
	ScreenManager.clear_push_stack()
	ScreenManager.switch_tab(HOME_TAB)

	await _fade_in()
	_is_transitioning = false


# ===== Internal helpers =====

func _save_dda_state() -> void:
	var state: Dictionary = _dda.get_save_state()
	SaveManager.save_value("dda_offset", state["offset"])
	SaveManager.save_value("dda_history", state["history"])


func _get_mode_key(mode: int) -> String:
	match mode:
		GameManager.GameMode.CLASSIC:        return "classic"
		GameManager.GameMode.TIME_ATTACK:    return "time_attack"
		_:                                   return "classic"


func _check_feature_unlocks(stage: int) -> void:
	## Time Attack unlock: first clear of Stage 10.
	if stage == TIME_ATTACK_UNLOCK_STAGE:
		if ScreenManager.has_method("open_popup"):
			ScreenManager.open_popup("feature_unlock", {"feature": "time_attack"})
	## Daily Challenge unlock: first clear of Stage 24.
	if stage == DAILY_UNLOCK_STAGE:
		if ScreenManager.has_method("open_popup"):
			ScreenManager.open_popup("feature_unlock", {"feature": "daily"})
