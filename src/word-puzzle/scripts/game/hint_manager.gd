## hint_manager.gd
## Manages all hint/booster logic.
## GameScreen holds a per-stage instance (not an Autoload).
class_name HintManager
extends RefCounted


## Emitted when a hint is activated.
## cells: FIRST_LETTER/DIRECTION_SHOW → [start_pos], MAGNIFIER → 3×3 area, FULL_REVEAL → all cells.
signal hint_activated(type: int, word: PlacedWord, cells: Array[Vector2i])


# ===== Cost constants =====

const COST_FIRST_LETTER: int = 100
const COST_DIRECTION_SHOW: int = 120
const COST_MAGNIFIER: int = 150
const COST_FULL_REVEAL: int = 200
const COST_TIMER_EXTEND: int = 80

## Magnifier area radius (3×3 = radius 1).
const MAGNIFIER_RADIUS: int = 1

## Magnifier glow duration in seconds — GameScreen uses this value to manage its timer.
const MAGNIFIER_DURATION: float = 5.0


# ===== State =====

var _grid_data: GridData = null

## Total hints used this stage.
var total_hints_used: int = 0

## Shuffles remaining this stage (1 free per stage).
var shuffle_remaining: int = 1


# ===== Initialisation =====

## Call at the start of each new stage.
func setup(p_grid_data: GridData) -> void:
	_grid_data = p_grid_data
	total_hints_used = 0
	shuffle_remaining = 1


# ===== Public API =====

## Returns true if there are valid candidates for the given hint type.
func can_use_hint(type: int) -> bool:
	for pw: PlacedWord in _grid_data.placed_words:
		if pw.is_found:
			continue
		if type == HintType.Type.FULL_REVEAL:
			return true
		else:
			if not pw.is_hinted:
				return true
	return false


## Uses a hint. Returns true on success.
## Ticket consumption must be handled by the caller (GameScreen via HintTicketManager) beforehand.
## FULL_REVEAL sets is_found = true internally before emitting hint_activated.
## MAGNIFIER timer is managed by the caller (GameScreen) using MAGNIFIER_DURATION.
func use_hint(type: int) -> bool:
	var candidates: Array[PlacedWord] = []
	for pw: PlacedWord in _grid_data.placed_words:
		if pw.is_found:
			continue
		if type == HintType.Type.FULL_REVEAL:
			# Full Reveal can target any unfound word, even if already hinted.
			candidates.append(pw)
		else:
			# Other hints only target unhinted words.
			if not pw.is_hinted:
				candidates.append(pw)

	if candidates.is_empty():
		return false

	total_hints_used += 1

	var target: PlacedWord = candidates[randi() % candidates.size()]
	# FULL_REVEAL sets is_found = true, so no separate flag is needed.
	if type != HintType.Type.FULL_REVEAL:
		target.is_hinted = true
		target.hint_type = type

	match type:
		HintType.Type.FIRST_LETTER:
			var first_cells: Array[Vector2i] = [target.cells[0]]
			hint_activated.emit(type, target, first_cells)
		HintType.Type.DIRECTION_SHOW:
			var first_cells: Array[Vector2i] = [target.cells[0]]
			hint_activated.emit(type, target, first_cells)
		HintType.Type.MAGNIFIER:
			var area: Array[Vector2i] = _get_magnifier_cells(target)
			hint_activated.emit(type, target, area)
		HintType.Type.FULL_REVEAL:
			target.is_found = true
			var all_cells: Array[Vector2i] = target.cells.duplicate()
			hint_activated.emit(type, target, all_cells)
		HintType.Type.TIMER_EXTEND:
			var empty: Array[Vector2i] = []
			hint_activated.emit(type, target, empty)

	return true


## Uses the shuffle booster. Free — only decrements the remaining count.
func use_shuffle() -> bool:
	if shuffle_remaining <= 0:
		return false
	shuffle_remaining -= 1
	return true


## Returns true if there are words that can still receive a hint (not found and not already hinted).
func has_hints_available() -> bool:
	for pw: PlacedWord in _grid_data.placed_words:
		if not pw.is_found and not pw.is_hinted:
			return true
	return false


## Called when a word is found.
func on_word_found(_pw: PlacedWord) -> void:
	pass


## Returns the coin cost for the given hint type.
static func get_cost(type: int) -> int:
	match type:
		HintType.Type.FIRST_LETTER:   return COST_FIRST_LETTER
		HintType.Type.DIRECTION_SHOW: return COST_DIRECTION_SHOW
		HintType.Type.MAGNIFIER:      return COST_MAGNIFIER
		HintType.Type.FULL_REVEAL:    return COST_FULL_REVEAL
		HintType.Type.TIMER_EXTEND:   return COST_TIMER_EXTEND
		_:
			push_warning("HintManager: Unknown hint type %d" % type)
			return 0


# ===== Internal =====

## Returns the 3×3 area around the word's center cell.
## Near boundaries, the center is clamped inward to always return 9 cells.
func _get_magnifier_cells(pw: PlacedWord) -> Array[Vector2i]:
	@warning_ignore("integer_division")
	var center_index: int = pw.cells.size() / 2
	var raw_center: Vector2i = pw.cells[center_index]
	# Clamp center so it is at least MAGNIFIER_RADIUS away from all edges.
	var cx: int = clampi(raw_center.x, MAGNIFIER_RADIUS, _grid_data.width - 1 - MAGNIFIER_RADIUS)
	var cy: int = clampi(raw_center.y, MAGNIFIER_RADIUS, _grid_data.height - 1 - MAGNIFIER_RADIUS)
	var center := Vector2i(cx, cy)
	var area: Array[Vector2i] = []
	for dy: int in range(-MAGNIFIER_RADIUS, MAGNIFIER_RADIUS + 1):
		for dx: int in range(-MAGNIFIER_RADIUS, MAGNIFIER_RADIUS + 1):
			area.append(center + Vector2i(dx, dy))
	return area
