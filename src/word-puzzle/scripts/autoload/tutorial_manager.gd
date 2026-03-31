## tutorial_manager.gd
## Autoload singleton that manages the 3-stage interactive tutorial.
## Follows the P02_04 design spec.
extends Node


# ===== Constants =====

const TUTORIAL_STAGE_COUNT: int = 3
const GAME_SCENE: String = "res://scenes/screens/game_screen.tscn"


# ===== Signals =====

signal tutorial_started()
signal tutorial_stage_completed(stage: int)
signal tutorial_completed()


# ===== State =====

var _is_in_tutorial: bool = false
var _current_tutorial_stage: int = 0
var _guide_overlay: Node = null  ## GuideOverlay instance.


# ===== Public API =====

## Starts the tutorial from Stage 1.
func start_tutorial() -> void:
	_is_in_tutorial = true
	_current_tutorial_stage = 0
	tutorial_started.emit()
	_start_stage(1)


## Called by GameScreen when a tutorial stage is cleared.
func on_tutorial_stage_cleared(stage: int) -> void:
	if not _is_in_tutorial:
		return
	tutorial_stage_completed.emit(stage)
	hide_guide()

	if stage >= TUTORIAL_STAGE_COUNT:
		_finish_tutorial()
	else:
		_start_stage(stage + 1)


func is_in_tutorial() -> bool:
	return _is_in_tutorial


func get_current_tutorial_stage() -> int:
	return _current_tutorial_stage


## Displays the GuideOverlay. steps: Array of Dictionary.
func show_guide(steps: Array) -> void:
	if _guide_overlay == null:
		_spawn_guide_overlay()
	if _guide_overlay and _guide_overlay.has_method("show_steps"):
		_guide_overlay.show_steps(steps)


func hide_guide() -> void:
	if _guide_overlay and is_instance_valid(_guide_overlay):
		_guide_overlay.hide_all()


# ===== Internal =====

func _start_stage(tutorial_stage: int) -> void:
	_current_tutorial_stage = tutorial_stage

	var lang_index: int = SaveManager.get_setting("language_index", 0) as int
	var grid_data = TutorialPuzzles.get_tutorial_grid(tutorial_stage, lang_index)
	var guide_steps: Array = TutorialPuzzles.get_guide_steps(tutorial_stage)

	var data: Dictionary = {
		"is_tutorial": true,
		"tutorial_stage": tutorial_stage,
		"tutorial_grid": grid_data,
		"guide_steps": guide_steps,
	}

	if ScreenManager.can_pop():
		ScreenManager.replace_top_screen(GAME_SCENE, data)
	else:
		ScreenManager.push_screen(GAME_SCENE, data)


func _finish_tutorial() -> void:
	_is_in_tutorial = false
	SaveManager.set_tutorial_completed(true)
	SaveManager.set_current_stage(4)  ## After completing all 3 tutorial stages, start at Stage 4.
	tutorial_completed.emit()
	## Return to Home.
	GameController.return_to_home()


func _spawn_guide_overlay() -> void:
	var packed: PackedScene = load("res://scenes/ui/guide_overlay.tscn")
	if packed == null:
		push_error("TutorialManager: Failed to load guide_overlay.tscn")
		return
	_guide_overlay = packed.instantiate()
	## Add to the top of the scene tree.
	get_tree().root.add_child(_guide_overlay)
