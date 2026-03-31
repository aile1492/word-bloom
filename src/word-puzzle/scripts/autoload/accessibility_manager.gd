## accessibility_manager.gd
## Accessibility settings singleton.
## Manages dark mode, font size, and reduced motion settings.
extends Node


signal dark_mode_changed(is_dark: bool)
signal font_scale_changed(scale: float)


const FONT_SCALES: Array[float] = [0.85, 1.0, 1.2]


var _is_dark: bool = false
var _font_scale_index: int = 1  # 0=Small  1=Medium  2=Large
var _reduce_motion: bool = false


func _ready() -> void:
	var saved: Dictionary = SaveManager.load_value("accessibility", {})
	_font_scale_index = clampi(saved.get("font_scale", 1), 0, FONT_SCALES.size() - 1)
	_reduce_motion = saved.get("reduce_motion", false)
	var follow_sys: bool = saved.get("dark_mode_follow_system", true)
	if follow_sys:
		_is_dark = DisplayServer.is_dark_mode()
	else:
		_is_dark = saved.get("dark_mode", false)


# ===== Dark mode =====

func set_dark_mode(enabled: bool) -> void:
	if _is_dark == enabled:
		return
	_is_dark = enabled
	_save()
	dark_mode_changed.emit(_is_dark)


func is_dark_mode() -> bool:
	return _is_dark


# ===== Font size =====

func set_font_scale(index: int) -> void:
	var clamped: int = clampi(index, 0, FONT_SCALES.size() - 1)
	if _font_scale_index == clamped:
		return
	_font_scale_index = clamped
	_save()
	font_scale_changed.emit(get_font_scale())


func get_font_scale() -> float:
	return FONT_SCALES[_font_scale_index]


func get_font_scale_index() -> int:
	return _font_scale_index


# ===== Reduced motion =====

func set_reduce_motion(enabled: bool) -> void:
	_reduce_motion = enabled
	_save()


func should_animate() -> bool:
	return not _reduce_motion


## Returns animation duration. Returns 0 when reduce_motion is enabled.
func get_animation_duration(base: float) -> float:
	return 0.0 if _reduce_motion else base


# ===== Save =====

func _save() -> void:
	var current: Dictionary = SaveManager.load_value("accessibility", {})
	current["dark_mode"] = _is_dark
	current["font_scale"] = _font_scale_index
	current["reduce_motion"] = _reduce_motion
	SaveManager.save_value("accessibility", current)
