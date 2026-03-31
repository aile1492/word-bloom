## grid_generator.gd
## Main grid generation class.
## Receives stage info and a word list, returns a completed GridData.
class_name GridGenerator
extends RefCounted


## 8-direction vectors.
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),    # Right →
	Vector2i(-1, 0),   # Left ←
	Vector2i(0, 1),    # Down ↓
	Vector2i(0, -1),   # Up ↑
	Vector2i(1, 1),    # Down-Right ↘
	Vector2i(-1, -1),  # Up-Left ↖
	Vector2i(1, -1),   # Up-Right ↗
	Vector2i(-1, 1),   # Down-Left ↙
]

## Maximum placement attempts per word.
const MAX_PLACEMENT_ATTEMPTS: int = 100

## Fallback Korean syllable pool.
const BACKUP_KOREAN_SYLLABLES: Array[String] = [
	"가", "나", "다", "라", "마", "바", "사", "아", "자", "차",
	"카", "타", "파", "하", "고", "노", "도", "로", "모", "보",
	"소", "오", "조", "초", "코", "토", "포", "호", "구", "누",
	"두", "루", "무", "부", "수", "우", "주", "추", "쿠", "투",
	"기", "니", "디", "리", "미", "비", "시", "이", "지", "히",
]


## Generates a grid, places all words, fills empty cells, and returns the completed GridData.
## rng_seed: -1 (default) produces a different grid each run.
##           0 or higher seeds the RNG for reproducible grids (used for Daily Challenge).
func generate(
	width: int,
	height: int,
	word_list: Array[WordEntry],
	language: String,
	stage: int,
	word_pack: WordPack,
	rng_seed: int = -1
) -> GridData:
	if rng_seed >= 0:
		seed(rng_seed)
	var data := GridData.new()
	data.width = width
	data.height = height
	data.stage = stage
	data.language = language
	data.grid = _create_empty_grid(width, height)

	# Sort words longest-first to improve placement success rate.
	var sorted_words := _sort_by_length_desc(word_list)

	# Attempt to place each word.
	for entry in sorted_words:
		var placed := _try_place_word(data, entry)
		if not placed:
			push_warning("GridGenerator: Failed to place word - '%s'" % entry.word)

	# Inject false leads before filling empty cells.
	var false_lead_gen := FalseLeadGenerator.new()
	false_lead_gen.inject_false_leads(data, stage)

	# Fill empty cells with random characters.
	_fill_empty_cells(data, language, word_pack)

	# Remove ambiguous paths (same word readable from the same start cell in a different direction).
	_fix_ambiguities(data, language)

	# Validate.
	var validation := _validate_grid(data, word_list.size())
	for warning in validation.warnings:
		push_warning("GridGenerator: " + warning)

	# Debug output.
	if OS.is_debug_build():
		print("=== Grid Generated (Stage %d) ===" % stage)
		print("Size: %dx%d, Words: %d/%d" % [
			width, height,
			data.placed_words.size(), word_list.size()
		])
		print(data.to_debug_string())
		for pw in data.placed_words:
			print("  " + pw.to_debug_string())

	return data


# ===== Empty grid initialisation =====

func _create_empty_grid(width: int, height: int) -> Array:
	var grid: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append("")
		grid.append(row)
	return grid


# ===== Sorting =====

func _sort_by_length_desc(word_list: Array[WordEntry]) -> Array[WordEntry]:
	var sorted_list := word_list.duplicate()
	sorted_list.sort_custom(func(a: WordEntry, b: WordEntry) -> bool:
		return a.length > b.length
	)
	return sorted_list


# ===== Word placement =====

func _try_place_word(data: GridData, entry: WordEntry) -> bool:
	for _attempt in range(MAX_PLACEMENT_ATTEMPTS):
		var dir: Vector2i = DIRECTIONS[randi() % DIRECTIONS.size()]
		var start := Vector2i(randi() % data.width, randi() % data.height)

		if _can_place(data.grid, entry.display, start, dir, data.width, data.height):
			_place_word(data, entry, start, dir)
			return true

	return false


func _can_place(
	grid: Array,
	display: String,
	start: Vector2i,
	dir: Vector2i,
	width: int,
	height: int
) -> bool:
	for i in range(display.length()):
		var pos := start + dir * i

		if pos.x < 0 or pos.x >= width or pos.y < 0 or pos.y >= height:
			return false

		var existing: String = grid[pos.y][pos.x]
		if existing != "" and existing != display[i]:
			return false

	return true


func _place_word(
	data: GridData,
	entry: WordEntry,
	start: Vector2i,
	dir: Vector2i
) -> void:
	for i in range(entry.display.length()):
		var pos := start + dir * i
		data.grid[pos.y][pos.x] = entry.display[i]

	var placed := PlacedWord.create(
		entry.word,
		entry.display,
		start,
		dir,
		entry.category
	)
	placed.color_index = data.placed_words.size()
	data.placed_words.append(placed)


# ===== Fill empty cells =====

func _fill_empty_cells(
	data: GridData,
	language: String,
	word_pack: WordPack
) -> void:
	match language:
		"en":
			_fill_empty_english(data)
		"ko":
			_fill_empty_korean(data, word_pack)
		_:
			push_warning("GridGenerator: Unsupported language - " + language)
			_fill_empty_english(data)


func _fill_empty_english(data: GridData) -> void:
	var char_frequency: Dictionary = {}
	for pw in data.placed_words:
		for ch in pw.display:
			var upper_ch := ch.to_upper()
			char_frequency[upper_ch] = char_frequency.get(upper_ch, 0) + 1

	var fill_pool: Array[String] = []
	for ch in char_frequency:
		for i in range(char_frequency[ch]):
			fill_pool.append(ch)

	if fill_pool.is_empty():
		var default_chars := "ABCDEFGHIJKLMNOPRSTUVWXY"
		for ch in default_chars:
			fill_pool.append(ch)

	for y in range(data.height):
		for x in range(data.width):
			if data.grid[y][x] == "":
				data.grid[y][x] = fill_pool[randi() % fill_pool.size()]


func _fill_empty_korean(data: GridData, word_pack: WordPack) -> void:
	var syllable_pool: Array[String] = []
	if word_pack:
		for entry in word_pack.entries:
			for syllable in entry.display:
				syllable_pool.append(syllable)

	if syllable_pool.size() < 20:
		syllable_pool.append_array(BACKUP_KOREAN_SYLLABLES)

	for y in range(data.height):
		for x in range(data.width):
			if data.grid[y][x] == "":
				data.grid[y][x] = syllable_pool[randi() % syllable_pool.size()]


# ===== Validation =====

func _validate_grid(data: GridData, requested_count: int) -> Dictionary:
	var warnings: Array[String] = []
	var result := {
		"valid": true,
		"warnings": warnings
	}

	if data.placed_words.size() < requested_count:
		var missing := requested_count - data.placed_words.size()
		result.warnings.append(
			"%d word(s) failed to place (requested: %d, placed: %d)" % [
				missing, requested_count, data.placed_words.size()
			]
		)

	for y in range(data.height):
		for x in range(data.width):
			if data.grid[y][x] == "":
				result.valid = false
				result.warnings.append("Empty cell found: (%d, %d)" % [x, y])

	return result


# ===== Ambiguity removal =====

## For each placed word, checks all other directions from its start cell.
## If the same word is readable in a different direction, replaces the first
## non-word cell along that path with a safe character.
func _fix_ambiguities(data: GridData, language: String) -> void:
	# Build a set of all word-cell positions for fast lookup.
	var word_cells: Dictionary = {}
	for pw: PlacedWord in data.placed_words:
		for cell: Vector2i in pw.cells:
			word_cells[cell] = true

	for pw: PlacedWord in data.placed_words:
		var start: Vector2i = pw.cells[0]
		var word_len: int = pw.display.length()

		for dir: Vector2i in DIRECTIONS:
			# Skip the word's own direction.
			if dir == pw.direction:
				continue

			# Skip if the word does not fit in bounds along this direction.
			var end_pos: Vector2i = start + dir * (word_len - 1)
			if end_pos.x < 0 or end_pos.x >= data.width:
				continue
			if end_pos.y < 0 or end_pos.y >= data.height:
				continue

			# Check whether all characters match along this alternative path.
			var is_ambiguous: bool = true
			for i: int in range(word_len):
				var pos: Vector2i = start + dir * i
				if pos.x < 0 or pos.x >= data.width or pos.y < 0 or pos.y >= data.height:
					is_ambiguous = false
					break
				var cell_char: String = data.grid[pos.y][pos.x]
				if cell_char != pw.display[i]:
					is_ambiguous = false
					break

			if not is_ambiguous:
				continue

			# Ambiguous path found — find the first non-word cell and replace it.
			for i: int in range(word_len):
				var pos: Vector2i = start + dir * i
				if not word_cells.has(pos):
					var bad_ch: String = data.grid[pos.y][pos.x]
					data.grid[pos.y][pos.x] = _pick_safe_char(bad_ch, language)
					if OS.is_debug_build():
						print("GridGenerator: Fixed ambiguity '%s' dir=%s pos=%s '%s'→'%s'" % [
							pw.display, dir, pos, bad_ch, data.grid[pos.y][pos.x]
						])
					break


## Returns a safe replacement character different from bad_ch.
func _pick_safe_char(bad_ch: String, language: String) -> String:
	if language == "ko":
		for ch: String in BACKUP_KOREAN_SYLLABLES:
			if ch != bad_ch:
				return ch
		return "가"
	else:
		var alphabet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		for i: int in range(alphabet.length()):
			var ch: String = alphabet[i]
			if ch != bad_ch:
				return ch
		return "A"
