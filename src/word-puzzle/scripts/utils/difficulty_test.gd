## difficulty_test.gd
## Automated validation for the Phase 3 difficulty system. Runs only in debug builds.
## Called as DifficultyTest.run() from GameManager._ready().
class_name DifficultyTest


static func run() -> void:
	var results: Array[bool] = []

	print("\n========== Phase 3 Difficulty System Validation ==========\n")

	# ── GridCalculator: word count ────────────────────────────

	print("[ GridCalculator - word count ]")

	for s: int in [1, 2, 3, 4, 5]:
		results.append(_check("Stage %d → 4 words" % s, GridCalculator.get_word_count(s), 4))
	for s: int in [6, 7, 8, 9]:
		results.append(_check("Stage %d → 5 words" % s, GridCalculator.get_word_count(s), 5))

	# Stage 10 rest: base=5, 5-2=3 → min(3,4)=4
	results.append(_check("Stage 10 (rest) → 4 words", GridCalculator.get_word_count(10), 4))
	# Stage 20 rest: base = 4+floor(19/5)=7, 7-2=5
	results.append(_check("Stage 20 (rest) → 5 words", GridCalculator.get_word_count(20), 5))

	print("")
	print("[ GridCalculator - is_rest_stage ]")

	for s: int in [10, 20, 30]:
		results.append(_check_bool("is_rest_stage(%d) → true" % s, GridCalculator.is_rest_stage(s), true))
	for s: int in [1, 9, 11, 15]:
		results.append(_check_bool("is_rest_stage(%d) → false" % s, GridCalculator.is_rest_stage(s), false))

	print("")
	print("[ GridCalculator - DDA offset applied ]")

	results.append(_check("Stage 6 + offset 2 → 7 words", GridCalculator.get_word_count(6, 2), 7))
	results.append(_check("Stage 10 (rest) + offset 2 → 4 words (ignored)", GridCalculator.get_word_count(10, 2), 4))

	print("")

	# ── DDAManager ──────────────────────────────────────────

	print("[ DDAManager - offset adjustment ]")

	var dda := DDAManager.new()

	results.append(_check("Initial offset = 0", dda.get_current_offset(), 0))

	# 1 history entry → no evaluation yet.
	dda.record_stage(true, 60.0, 0)
	results.append(_check("Insufficient history → offset unchanged", dda.get_current_offset(), 0))

	# 3 fast clears → offset +1.
	dda.reset()
	dda.record_stage(true, 60.0, 0)
	dda.record_stage(true, 60.0, 0)
	dda.record_stage(true, 60.0, 0)
	results.append(_check("3 fast clears → offset +1", dda.get_current_offset(), 1))

	# Hint used → offset increase blocked.
	dda.reset()
	dda.record_stage(true, 60.0, 1)
	dda.record_stage(true, 60.0, 0)
	dda.record_stage(true, 60.0, 0)
	results.append(_check("1 hint used → offset unchanged", dda.get_current_offset(), 0))

	# 2 failures → offset -1.
	dda.reset()
	dda.record_stage(false, 200.0, 0)
	dda.record_stage(false, 200.0, 0)
	dda.record_stage(true,  200.0, 0)
	results.append(_check("2 failures → offset -1", dda.get_current_offset(), -1))

	# get_adjusted_word_count
	dda.reset()
	dda.record_stage(true, 60.0, 0)
	dda.record_stage(true, 60.0, 0)
	dda.record_stage(true, 60.0, 0)  # offset = +1
	results.append(_check("Rest stage → DDA not applied", dda.get_adjusted_word_count(5, true, false), 5))
	results.append(_check("Daily Challenge → DDA not applied", dda.get_adjusted_word_count(5, false, true), 5))
	results.append(_check("Normal stage → DDA applied (5+1=6)", dda.get_adjusted_word_count(5, false, false), 6))

	print("")

	# ── Summary ──────────────────────────────────────────────

	var passed: int = results.count(true)
	var failed: int = results.count(false)
	print("===================================================")
	print("Result: %d / %d passed" % [passed, results.size()])
	if failed == 0:
		print("✅ All checks passed")
	else:
		print("❌ %d check(s) failed — see log above" % failed)
	print("===================================================\n")


static func _check(label: String, got: int, expected: int) -> bool:
	if got == expected:
		print("  ✅ %s" % label)
		return true
	print("  ❌ %s  (expected: %d, got: %d)" % [label, expected, got])
	return false


static func _check_bool(label: String, got: bool, expected: bool) -> bool:
	if got == expected:
		print("  ✅ %s" % label)
		return true
	print("  ❌ %s  (expected: %s, got: %s)" % [label, str(expected), str(got)])
	return false
