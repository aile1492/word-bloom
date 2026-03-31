## letter_cell.gd
## Individual cell UI component for the grid.
## Handles letter display, visual state transitions, and pop animations.
class_name LetterCell
extends PanelContainer

const FONT_CELL: Font = preload("res://assets/fonts/Quicksand-Variable.ttf")


## Visual states for a cell.
enum VisualState {
	IDLE,           ## Default state.
	HOVER,          ## Mouse hover or D-pad focus.
	DRAGGING,       ## Selected during a drag.
	FOUND,          ## Confirmed as a correct word cell (color locked).
	HINT,           ## Revealed by a First Letter hint.
	HINT_DIRECTION, ## Revealed by a Direction hint (shows an arrow).
}

## Tile texture paths.
const TILE_NORMAL_PATH:   String = "res://assets/ui/tile_normal.png"
const TILE_SELECTED_PATH: String = "res://assets/ui/tile_selected.png"
const TILE_CORRECT_PATH:  String = "res://assets/ui/tile_correct.png"

## Tile textures (null = fall back to color).
static var _tex_normal:   Texture2D = null
static var _tex_selected: Texture2D = null
static var _tex_correct:  Texture2D = null
static var _textures_loaded: bool = false

## Background colors per state (fallback when textures are absent).
const STATE_COLORS: Dictionary = {
	VisualState.IDLE: Color(0.95, 0.95, 0.95, 1.0),
	VisualState.HOVER: Color(0.85, 0.90, 1.0, 1.0),
	VisualState.DRAGGING: Color(0.6, 0.78, 1.0, 1.0),
	VisualState.HINT: Color(1.0, 0.95, 0.8, 1.0),
	VisualState.HINT_DIRECTION: Color(1.0, 0.95, 0.8, 1.0),
}

## Unique color palette for found words (up to 12 words).
const FOUND_COLORS: Array[Color] = [
	Color(0.56, 0.83, 0.56, 0.8),   # Light green
	Color(0.55, 0.73, 0.96, 0.8),   # Sky blue
	Color(0.96, 0.72, 0.55, 0.8),   # Orange
	Color(0.86, 0.55, 0.96, 0.8),   # Purple
	Color(0.96, 0.55, 0.67, 0.8),   # Pink
	Color(0.55, 0.96, 0.90, 0.8),   # Mint
	Color(0.96, 0.93, 0.55, 0.8),   # Yellow
	Color(0.75, 0.88, 0.55, 0.8),   # Light green 2
	Color(0.55, 0.62, 0.96, 0.8),   # Indigo
	Color(0.96, 0.55, 0.55, 0.8),   # Red
	Color(0.72, 0.55, 0.96, 0.8),   # Violet
	Color(0.55, 0.96, 0.67, 0.8),   # Emerald
]

## Text colors per state.
const TEXT_COLORS: Dictionary = {
	VisualState.IDLE: Color(0.2, 0.2, 0.2, 1.0),
	VisualState.HOVER: Color(0.15, 0.15, 0.35, 1.0),
	VisualState.DRAGGING: Color(0.0, 0.0, 0.3, 1.0),
	VisualState.FOUND: Color(0.1, 0.3, 0.1, 1.0),
	VisualState.HINT: Color(0.5, 0.4, 0.0, 1.0),
	VisualState.HINT_DIRECTION: Color(0.5, 0.4, 0.0, 1.0),
}

## Grid coordinate for this cell.
var grid_pos: Vector2i = Vector2i.ZERO

## Letter displayed in this cell.
var letter: String = ""

## Current visual state.
var _visual_state: VisualState = VisualState.IDLE

## Color index for the found state.
var _found_color_index: int = -1

## Cell size in pixels.
var _cell_size: float = 60.0:
	set(value):
		_cell_size = value
		custom_minimum_size = Vector2(value, value)
		_update_font_size()

## Currently active Tween.
var _active_tween: Tween = null

## Arrow label for direction hints.
var _arrow_label: Label = null

@onready var letter_label: Label = $MarginContainer/Label
@onready var highlight_overlay: ColorRect = $ColorRect

## Tile sprite TextureRect (created dynamically).
var _tile_rect: TextureRect = null


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

	# Load tile textures once (shared as class statics).
	if not _textures_loaded:
		_textures_loaded = true
		_tex_normal   = load(TILE_NORMAL_PATH)   as Texture2D
		_tex_selected = load(TILE_SELECTED_PATH) as Texture2D
		_tex_correct  = load(TILE_CORRECT_PATH)  as Texture2D

	# Insert the tile TextureRect as the first child (behind the letter label).
	# Tile images have no transparent padding — fill the entire cell (PRESET_FULL_RECT).
	_tile_rect = TextureRect.new()
	_tile_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tile_rect.anchor_right  = 1.0
	_tile_rect.anchor_bottom = 1.0
	_tile_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tile_rect.grow_vertical   = Control.GROW_DIRECTION_BOTH
	_tile_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_tile_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tile_rect)
	move_child(_tile_rect, 0)  # Place behind all other children.
	_tile_rect.texture = _tex_normal

	# If textures are available, make the PanelContainer background transparent.
	if _tex_normal:
		var stylebox := StyleBoxEmpty.new()
		add_theme_stylebox_override("panel", stylebox)
	else:
		# No textures — keep the colour-based style.
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = STATE_COLORS[VisualState.IDLE]
		stylebox.corner_radius_top_left = 4
		stylebox.corner_radius_top_right = 4
		stylebox.corner_radius_bottom_left = 4
		stylebox.corner_radius_bottom_right = 4
		add_theme_stylebox_override("panel", stylebox)
	# Set initial font colour explicitly so Tween interpolation works from the start.
	letter_label.add_theme_color_override("font_color", TEXT_COLORS[VisualState.IDLE])

	# Create the direction-hint arrow label dynamically.
	_arrow_label = Label.new()
	_arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arrow_label.add_theme_font_size_override("font_size", 14)
	_arrow_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.0, 1.0))
	_arrow_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_arrow_label.visible = false
	add_child(_arrow_label)


## Initialises the cell.
func setup(pos: Vector2i, ch: String) -> void:
	grid_pos = pos
	letter = ch
	letter_label.text = ch
	highlight_overlay.visible = false


## Changes the displayed character (used when shuffling).
func set_letter(ch: String) -> void:
	letter = ch
	letter_label.text = ch


## Sets the cell size.
func set_cell_size(cell_size: float) -> void:
	_cell_size = cell_size


## Changes the visual state and plays the corresponding animation.
func set_visual_state(new_state: VisualState, color_index: int = -1) -> void:
	# A FOUND cell cannot be changed to any other state.
	if _visual_state == VisualState.FOUND:
		return

	_visual_state = new_state

	# Hide the arrow unless the new state is HINT_DIRECTION.
	if new_state != VisualState.HINT_DIRECTION and _arrow_label:
		_arrow_label.visible = false

	if _active_tween and _active_tween.is_running():
		_active_tween.kill()

	var target_bg_color: Color
	var target_text_color: Color

	if new_state == VisualState.FOUND:
		_found_color_index = color_index
		var ci := clampi(color_index, 0, FOUND_COLORS.size() - 1)
		target_bg_color = FOUND_COLORS[ci]
		target_text_color = TEXT_COLORS[VisualState.FOUND]
	elif new_state == VisualState.DRAGGING and color_index >= 0:
		var ci := clampi(color_index, 0, FOUND_COLORS.size() - 1)
		target_bg_color = FOUND_COLORS[ci]
		target_text_color = TEXT_COLORS[VisualState.DRAGGING]
	else:
		target_bg_color = STATE_COLORS.get(new_state, STATE_COLORS[VisualState.IDLE])
		target_text_color = TEXT_COLORS.get(new_state, TEXT_COLORS[VisualState.IDLE])

	# Switch the tile texture.
	if _tile_rect:
		if new_state == VisualState.FOUND:
			if _tex_correct:
				_tile_rect.texture = _tex_correct
		elif new_state in [VisualState.DRAGGING, VisualState.HOVER]:
			if _tex_selected:
				_tile_rect.texture = _tex_selected
		else:
			if _tex_normal:
				_tile_rect.texture = _tex_normal

	_active_tween = create_tween()
	_active_tween.set_parallel(true)

	if _tex_normal:
		# Texture mode: express state via the colour overlay (ColorRect).
		var overlay_color: Color = target_bg_color
		overlay_color.a = 0.35 if new_state != VisualState.IDLE else 0.0
		if _tile_rect and new_state == VisualState.IDLE:
			highlight_overlay.visible = false
		else:
			highlight_overlay.visible = true
		_active_tween.tween_property(
			highlight_overlay, "color", overlay_color, 0.15
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	else:
		# Fallback: use StyleBoxFlat colours.
		var stylebox := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		add_theme_stylebox_override("panel", stylebox)
		_active_tween.tween_property(
			stylebox, "bg_color", target_bg_color, 0.15
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	_active_tween.tween_property(
		letter_label, "theme_override_colors/font_color",
		target_text_color, 0.15
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	if new_state == VisualState.FOUND:
		_play_found_animation()


## Sets a direction hint on this cell. Displays an arrow on the first-letter cell.
func set_hint_direction(dir: Vector2i) -> void:
	_arrow_label.text = _dir_to_arrow(dir)
	_arrow_label.visible = true
	set_visual_state(VisualState.HINT_DIRECTION)


## Converts a Vector2i direction to an arrow character.
static func _dir_to_arrow(dir: Vector2i) -> String:
	if dir == Vector2i(1, 0):
		return "→"
	elif dir == Vector2i(-1, 0):
		return "←"
	elif dir == Vector2i(0, 1):
		return "↓"
	elif dir == Vector2i(0, -1):
		return "↑"
	elif dir == Vector2i(1, 1):
		return "↘"
	elif dir == Vector2i(-1, -1):
		return "↖"
	elif dir == Vector2i(1, -1):
		return "↗"
	elif dir == Vector2i(-1, 1):
		return "↙"
	return "?"


## Pop animation played when a word is found.
func _play_found_animation() -> void:
	pivot_offset = size / 2.0
	var pop_tween := create_tween()
	pop_tween.tween_property(self, "scale", Vector2(1.38, 1.38), 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	pop_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)


## Resets the cell to its initial state (called when returning to the object pool).
func reset() -> void:
	_visual_state = VisualState.IDLE
	_found_color_index = -1
	letter = ""
	letter_label.text = ""
	scale = Vector2.ONE
	if _active_tween and _active_tween.is_running():
		_active_tween.kill()
	if _arrow_label:
		_arrow_label.visible = false

	# Reset tile texture.
	if _tile_rect and _tex_normal:
		_tile_rect.texture = _tex_normal
		highlight_overlay.visible = false
		highlight_overlay.color = Color(1, 1, 0, 0.5)  # Restore ColorRect default.
	else:
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = STATE_COLORS[VisualState.IDLE]
		stylebox.corner_radius_top_left = 4
		stylebox.corner_radius_top_right = 4
		stylebox.corner_radius_bottom_left = 4
		stylebox.corner_radius_bottom_right = 4
		add_theme_stylebox_override("panel", stylebox)
	letter_label.add_theme_color_override("font_color", TEXT_COLORS[VisualState.IDLE])


## Returns the current visual state.
func get_visual_state() -> VisualState:
	return _visual_state


## D-pad focus entered.
func _on_focus_entered() -> void:
	if LayoutManager.current_input_mode == InputMode.Type.DPAD:
		set_visual_state(VisualState.HOVER)


## D-pad focus exited.
func _on_focus_exited() -> void:
	if LayoutManager.current_input_mode == InputMode.Type.DPAD:
		set_visual_state(VisualState.IDLE)


## Calculates and applies the font size appropriate for the current cell size.
func _update_font_size() -> void:
	if not is_inside_tree():
		return
	var target_font_size: int = roundi(_cell_size * 0.62)
	target_font_size = maxi(target_font_size, 14)
	if letter_label:
		letter_label.add_theme_font_override("font", FONT_CELL)
		letter_label.add_theme_font_size_override("font_size", target_font_size)
