## dda_manager.gd
## Lightweight Dynamic Difficulty Adjustment manager.
## Analyses recent N-stage performance and adjusts the word-count offset within ±MAX_OFFSET.
## RefCounted class — GameController holds the instance.
class_name DDAManager
extends RefCounted


# ===== Internal state =====

## Recent stage performance records. Each entry: { "cleared": bool, "time": float, "hints": int }
var history: Array[Dictionary] = []

## Current DDA offset (-MAX_OFFSET to +MAX_OFFSET).
var current_offset: int = 0


# ===== Public API =====

## Records stage performance and evaluates difficulty if enough history exists.
func record_stage(cleared: bool, time: float, hints_used: int) -> void:
	history.append({
		"cleared": cleared,
		"time": time,
		"hints": hints_used,
	})

	while history.size() > GameConstants.DDA_HISTORY_SIZE:
		history.pop_front()

	if history.size() >= GameConstants.DDA_HISTORY_SIZE:
		_evaluate()


## Returns the final word count after applying the DDA offset.
## Returns base_count unchanged for rest stages, Daily Challenge, or when history is insufficient.
func get_adjusted_word_count(base_count: int, is_rest: bool, is_daily: bool) -> int:
	if is_rest or is_daily:
		return base_count
	if history.size() < GameConstants.DDA_HISTORY_SIZE:
		return base_count
	var adjusted: int = base_count + current_offset
	return clampi(adjusted, GameConstants.START_WORD_COUNT, GameConstants.MAX_WORD_COUNT)


## Returns the current DDA offset value.
func get_current_offset() -> int:
	return current_offset


## Resets DDA state.
func reset() -> void:
	history.clear()
	current_offset = 0


## Returns the current DDA state as a Dictionary (for saving).
func get_save_state() -> Dictionary:
	return {
		"offset": current_offset,
		"history": history.duplicate(true),
	}


## Restores DDA state from saved data.
func load_save_state(data: Dictionary) -> void:
	current_offset = data.get("offset", 0)
	history.clear()
	for item: Dictionary in data.get("history", []):
		history.append(item)


# ===== Internal =====

## Analyses history and recalculates the offset.
func _evaluate() -> void:
	var all_cleared: bool = true
	for h: Dictionary in history:
		if not h["cleared"]:
			all_cleared = false
			break

	var no_hints: bool = true
	for h: Dictionary in history:
		if h["hints"] != 0:
			no_hints = false
			break

	var total_time: float = 0.0
	for h: Dictionary in history:
		total_time += float(h["time"])
	var avg_time: float = total_time / float(history.size())

	var fail_count: int = 0
	for h: Dictionary in history:
		if not h["cleared"]:
			fail_count += 1

	var total_hints: float = 0.0
	for h: Dictionary in history:
		total_hints += float(h["hints"])
	var avg_hints: float = total_hints / float(history.size())

	# Evaluate.
	if all_cleared and no_hints and avg_time < GameConstants.DDA_FAST_CLEAR_THRESHOLD:
		current_offset = mini(current_offset + 1, GameConstants.DDA_MAX_OFFSET)
		if OS.is_debug_build():
			print("DDA: Too easy — offset %d" % current_offset)
	elif fail_count >= GameConstants.DDA_FAIL_COUNT_THRESHOLD or avg_hints >= GameConstants.DDA_HIGH_HINT_THRESHOLD:
		current_offset = maxi(current_offset - 1, -GameConstants.DDA_MAX_OFFSET)
		if OS.is_debug_build():
			print("DDA: Too hard — offset %d" % current_offset)
	else:
		if OS.is_debug_build():
			print("DDA: Just right — offset %d (no change)" % current_offset)
