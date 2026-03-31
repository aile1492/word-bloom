## tutorial_puzzles.gd
## Static class that returns fixed puzzle data and guide steps for tutorial stages 1–3.
## Follows the P02_04 design spec.
class_name TutorialPuzzles


# ===== Fixed puzzles =====

## Returns the GridData for the given tutorial stage (1–3) and language index (0=EN, 1=KO).
## Stage 3 uses random generation — returns null, and game_screen handles it via the normal path.
static func get_tutorial_grid(stage: int, lang_index: int) -> GridData:
	match stage:
		1: return _make_stage1(lang_index)
		2: return _make_stage2(lang_index)
		_: return null  ## Stage 3: random generation.


## Stage 1: 5×5 grid, 2 horizontal words.
## Uses the same grid size as a regular stage so the UI layout remains consistent.
static func _make_stage1(lang: int) -> GridData:
	var gd: GridData = GridData.new()
	gd.width  = 5
	gd.height = 5
	gd.language = "ko" if lang == 1 else "en"

	if lang == 1:
		## Korean: 고양이 (→ row0 col0–2), 강아지 (→ row1 col0–2)
		gd.grid = [
			["고", "양", "이", "나", "다"],
			["강", "아", "지", "라", "마"],
			["바", "사", "타", "자", "차"],
			["카", "파", "하", "라", "자"],
			["바", "라", "나", "다", "마"],
		]
		var w1: PlacedWord = PlacedWord.create("고양이", "고양이", Vector2i(0, 0), Vector2i(1, 0))
		var w2: PlacedWord = PlacedWord.create("강아지", "강아지", Vector2i(0, 1), Vector2i(1, 0))
		gd.placed_words = [w1, w2]
	else:
		## English: CAT (→ row0 col0–2), DOG (→ row1 col0–2)
		gd.grid = [
			["C", "A", "T", "P", "Q"],
			["D", "O", "G", "R", "S"],
			["W", "V", "U", "X", "Y"],
			["H", "I", "J", "K", "L"],
			["M", "N", "B", "E", "F"],
		]
		var w1: PlacedWord = PlacedWord.create("CAT", "CAT", Vector2i(0, 0), Vector2i(1, 0))
		var w2: PlacedWord = PlacedWord.create("DOG", "DOG", Vector2i(0, 1), Vector2i(1, 0))
		gd.placed_words = [w1, w2]

	return gd


## Stage 2: 5×5 grid, 3 horizontal words (practicing multiple positions).
static func _make_stage2(lang: int) -> GridData:
	var gd: GridData = GridData.new()
	gd.width  = 5
	gd.height = 5
	gd.language = "ko" if lang == 1 else "en"

	if lang == 1:
		## Korean: 하늘 (→ row0 col0–1), 바다 (→ row1 col1–2), 나무 (→ row2 col2–3)
		gd.grid = [
			["하", "늘", "나", "다", "라"],
			["마", "바", "다", "사", "아"],
			["자", "차", "나", "무", "카"],
			["타", "파", "하", "라", "마"],
			["나", "다", "라", "바", "사"],
		]
		var w1: PlacedWord = PlacedWord.create("하늘", "하늘", Vector2i(0, 0), Vector2i(1, 0))
		var w2: PlacedWord = PlacedWord.create("바다", "바다", Vector2i(1, 1), Vector2i(1, 0))
		var w3: PlacedWord = PlacedWord.create("나무", "나무", Vector2i(2, 2), Vector2i(1, 0))
		gd.placed_words = [w1, w2, w3]
	else:
		## English: SUN (→ row0 col0–2), SEA (↓ col4 row0–2)
		gd.grid = [
			["S", "U", "N", "T", "S"],
			["B", "C", "D", "E", "E"],
			["F", "G", "H", "I", "A"],
			["J", "K", "L", "M", "N"],
			["O", "P", "Q", "R", "V"],
		]
		var w1: PlacedWord = PlacedWord.create("SUN", "SUN", Vector2i(0, 0), Vector2i(1, 0))
		var w2: PlacedWord = PlacedWord.create("SEA", "SEA", Vector2i(4, 0), Vector2i(0, 1))
		gd.placed_words = [w1, w2]

	return gd


# ===== Guide steps =====

## Returns the guide step array for the given tutorial stage (1–3).
static func get_guide_steps(stage: int) -> Array:
	match stage:
		1: return _steps_stage1()
		2: return _steps_stage2()
		_: return []  ## Stage 3: no guide.


static func _steps_stage1() -> Array:
	return [
		{
			"message": "Find the hidden words in the grid!\nDrag to connect letters.",
			"spotlight_rect": Rect2(0, 0, 0, 0),  ## No spotlight.
			"hand_from": Vector2.ZERO,
			"hand_to": Vector2.ZERO,
			"auto_advance": 3.0,
			"show_button": false,
		},
		{
			"message": "Check the word list on the right.",
			"spotlight_rect": Rect2(0.6, 0.3, 0.4, 0.3),  ## WordBank area (ratio).
			"hand_from": Vector2.ZERO,
			"hand_to": Vector2.ZERO,
			"auto_advance": 2.5,
			"show_button": false,
		},
		{
			"message": "Drag from the first letter to the last\nto select the word!",
			"spotlight_rect": Rect2(0.1, 0.2, 0.5, 0.5),  ## Grid area (ratio).
			"hand_from": Vector2(150, 400),
			"hand_to": Vector2(350, 400),
			"auto_advance": 0.0,
			"show_button": true,
		},
	]


static func _steps_stage2() -> Array:
	return [
		{
			"message": "Great job! This time words are\nhidden in multiple places.",
			"spotlight_rect": Rect2(0, 0, 0, 0),
			"hand_from": Vector2.ZERO,
			"hand_to": Vector2.ZERO,
			"auto_advance": 0.0,
			"show_button": true,
		},
	]
