## screen_manager.gd
## Navigation Autoload that manages the Tab/Push/Popup three-layer system.
## initialize() must be called from MainScene._ready().
extends Node


# ===== Layer references =====

var _tab_layer: CanvasLayer = null
var _push_layer: CanvasLayer = null
var _popup_layer: CanvasLayer = null
var _bottom_tab_bar: Control = null  # Hidden/restored during push navigation.


# ===== Tab state =====

var _tab_screens: Array[BaseScreen] = []
var _active_tab: int = 2  # Default: Home (2)


# ===== Push stack =====

var _push_stack: Array[BaseScreen] = []


# ===== Initialization =====

## Called from MainScene._ready().
func initialize(
	tab_layer: CanvasLayer,
	push_layer: CanvasLayer,
	popup_layer: CanvasLayer,
	bottom_tab_bar: Control = null
) -> void:
	_tab_layer = tab_layer
	_push_layer = push_layer
	_popup_layer = popup_layer
	_bottom_tab_bar = bottom_tab_bar

	# Register BaseScreen children of TabLayer in order.
	_tab_screens.clear()
	for child in _tab_layer.get_children():
		if child is BaseScreen:
			_tab_screens.append(child as BaseScreen)

	# Hide all tabs, show the default.
	for i in range(_tab_screens.size()):
		_tab_screens[i].visible = (i == _active_tab)
	if _active_tab < _tab_screens.size():
		_tab_screens[_active_tab].enter({})


# ===== Tab navigation =====

## Switches the active tab within TabLayer.
func switch_tab(index: int) -> void:
	if _tab_layer == null:
		push_error("ScreenManager: initialize() has not been called.")
		return
	if index < 0 or index >= _tab_screens.size():
		push_error("ScreenManager: Invalid tab index %d" % index)
		return
	if index == _active_tab:
		return

	_tab_screens[_active_tab].exit()
	_tab_screens[_active_tab].visible = false

	_active_tab = index
	_tab_screens[_active_tab].visible = true
	_tab_screens[_active_tab].enter({})


func get_active_tab() -> int:
	return _active_tab


# ===== Push navigation =====

## Adds a new screen to PushLayer.
## scene_path: e.g. "res://scenes/screens/game_screen.tscn"
## data: dictionary passed to enter()
func push_screen(scene_path: String, data: Dictionary = {}) -> void:
	if _push_layer == null:
		push_error("ScreenManager: initialize() has not been called.")
		return

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("ScreenManager: Failed to load scene - " + scene_path)
		return

	var screen: BaseScreen = packed.instantiate() as BaseScreen
	if screen == null:
		push_error("ScreenManager: Scene is not a BaseScreen - " + scene_path)
		return

	# First push: hide TabLayer and BottomTabBar to prevent overlap.
	if _push_stack.is_empty():
		_tab_layer.visible = false
		if _bottom_tab_bar:
			_bottom_tab_bar.visible = false

	_push_layer.add_child(screen)
	# Force full-screen size.
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_push_stack.append(screen)
	screen.enter(data)


## Removes the top screen from PushLayer.
func pop_screen() -> void:
	if _push_stack.is_empty():
		return

	var screen: BaseScreen = _push_stack.pop_back()
	screen.exit()
	screen.queue_free()

	# Restore TabLayer and BottomTabBar when stack is empty.
	if _push_stack.is_empty():
		_tab_layer.visible = true
		if _bottom_tab_bar:
			_bottom_tab_bar.visible = true
		# Re-enter the active tab so it can refresh UI and resume BGM.
		if _active_tab >= 0 and _active_tab < _tab_screens.size():
			_tab_screens[_active_tab].enter({})


## Replaces the top screen in PushLayer with a new screen.
## Does not touch TabLayer visibility — avoids overlap on game→result→game transitions.
func replace_top_screen(scene_path: String, data: Dictionary = {}) -> void:
	if _push_layer == null:
		push_error("ScreenManager: initialize() has not been called.")
		return

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("ScreenManager: Failed to load scene - " + scene_path)
		return

	var screen: BaseScreen = packed.instantiate() as BaseScreen
	if screen == null:
		push_error("ScreenManager: Scene is not a BaseScreen - " + scene_path)
		return

	# Remove current top screen (without restoring TabLayer).
	if not _push_stack.is_empty():
		var old_screen: BaseScreen = _push_stack.pop_back()
		old_screen.exit()
		old_screen.queue_free()

	# Add new screen (TabLayer already hidden — leave it alone).
	_push_layer.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_push_stack.append(screen)
	screen.enter(data)


## Returns true if the push stack is not empty.
func can_pop() -> bool:
	return not _push_stack.is_empty()


## Removes all screens from PushLayer and restores TabLayer/BottomTabBar.
func clear_push_stack() -> void:
	while not _push_stack.is_empty():
		var screen: BaseScreen = _push_stack.pop_back()
		screen.exit()
		screen.queue_free()

	# Restore TabLayer/BottomTabBar after clearing.
	if _tab_layer:
		_tab_layer.visible = true
	if _bottom_tab_bar:
		_bottom_tab_bar.visible = true
	# Re-enter the active tab so it can refresh UI and resume BGM.
	if _active_tab >= 0 and _active_tab < _tab_screens.size():
		_tab_screens[_active_tab].enter({})


# ===== Popup navigation =====

var _active_popup: BaseScreen = null


## Shows a popup on PopupLayer.
func show_popup(scene_path: String, data: Dictionary = {}) -> void:
	if _popup_layer == null:
		push_error("ScreenManager: initialize() has not been called.")
		return

	hide_popup()

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("ScreenManager: Failed to load popup scene - " + scene_path)
		return

	var popup: BaseScreen = packed.instantiate() as BaseScreen
	if popup == null:
		push_error("ScreenManager: Popup scene is not a BaseScreen - " + scene_path)
		return

	_popup_layer.add_child(popup)
	_active_popup = popup
	popup.enter(data)


## Closes the current popup.
func hide_popup() -> void:
	if _active_popup == null:
		return
	_active_popup.exit()
	_active_popup.queue_free()
	_active_popup = null


## Convenience method that opens a popup by name instead of path.
## Supported names: "settings" | "profile" | "avatar_select" | "feature_unlock"
func open_popup(popup_name: String, data: Dictionary = {}) -> void:
	const POPUP_PATHS: Dictionary = {
		"settings":       "res://scenes/popups/settings_popup.tscn",
		"profile":        "res://scenes/popups/profile_popup.tscn",
		"avatar_select":  "res://scenes/popups/avatar_select_popup.tscn",
		"feature_unlock": "res://scenes/popups/feature_unlock_popup.tscn",
	}
	var path: String = POPUP_PATHS.get(popup_name, "") as String
	if path.is_empty():
		push_error("ScreenManager: Unknown popup name '%s'" % popup_name)
		return
	show_popup(path, data)


## Returns true if a popup is currently open.
func is_popup_open() -> bool:
	return _active_popup != null
