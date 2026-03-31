extends Node

## Singleton that manages platform detection and input mode switching.

## Whether the current platform is a TV.
var is_tv: bool = false

## Current input mode.
var current_input_mode: InputMode.Type = InputMode.Type.TOUCH

## Emitted when the input mode changes.
signal input_mode_changed(new_mode: InputMode.Type)


func _ready() -> void:
	_detect_platform()


## Auto-detect platform.
func _detect_platform() -> void:
	# TV detection: Android device without a touchscreen.
	is_tv = (
		OS.has_feature("android")
		and not DisplayServer.is_touchscreen_available()
	)

	if is_tv:
		current_input_mode = InputMode.Type.DPAD
	elif OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		current_input_mode = InputMode.Type.TOUCH
	else:
		current_input_mode = InputMode.Type.MOUSE

	print("LayoutManager: Platform detected - is_tv=%s, mode=%s" % [
		is_tv,
		InputMode.Type.keys()[current_input_mode]
	])


## Detects runtime input mode switches.
func _input(event: InputEvent) -> void:
	var new_mode := current_input_mode

	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		new_mode = InputMode.Type.TOUCH
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		if not event is InputEventScreenTouch:
			new_mode = InputMode.Type.MOUSE
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		new_mode = InputMode.Type.DPAD

	if new_mode != current_input_mode:
		current_input_mode = new_mode
		input_mode_changed.emit(new_mode)


func is_mobile() -> bool:
	return current_input_mode == InputMode.Type.TOUCH


func is_pc() -> bool:
	return current_input_mode == InputMode.Type.MOUSE
