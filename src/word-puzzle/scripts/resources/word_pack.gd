## word_pack.gd
## Container for a theme's word list.
## Loaded from a JSON file and used during grid generation.
class_name WordPack
extends RefCounted

## Theme display name.
var theme_name: String = ""

## Language ("en" or "ko").
var language: String = "ko"

## List of word entries.
var entries: Array[WordEntry] = []


## Loads a WordPack from a JSON file.
## JSON format: {"theme": "animals", "language": "ko", "words": [{"word": "고양이", "category": "mammals", "difficulty": 1}]}
static func load_from_json(path: String) -> WordPack:
	var pack := WordPack.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("WordPack: Cannot open file - " + path)
		return pack

	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	file.close()

	if result != OK:
		push_error("WordPack: JSON parse failed - " + path)
		return pack

	var data: Dictionary = json.data
	pack.theme_name = data.get("theme", "Unknown")
	pack.language = data.get("language", "ko")

	for word_data in data.get("words", []):
		var raw: String = word_data.get("word", "")
		if raw.is_empty():
			continue
		var display: String = raw.to_upper() if pack.language == "en" else raw
		var entry := WordEntry.create(
			raw,
			display,
			word_data.get("category", ""),
			word_data.get("difficulty", 1)
		)
		pack.entries.append(entry)

	return pack


## Selects a random subset of words up to count.
## Only includes words within the grid size limit (max_length).
func select_words(count: int, max_length: int = 999) -> Array[WordEntry]:
	var eligible: Array[WordEntry] = []
	for entry in entries:
		if entry.length >= 2 and entry.length <= max_length:
			eligible.append(entry)

	eligible.shuffle()

	var result: Array[WordEntry] = []
	for i in range(mini(count, eligible.size())):
		result.append(eligible[i])

	return result


## Selects words with a difficulty filter based on stage progression.
## Stage  1–20 : difficulty 1        (Easy — short, common words)
## Stage 21–60 : difficulty 1–2      (Easy + Normal)
## Stage 61+   : difficulty 1–3      (Full pool, Hard included)
## Falls back to the full pool if the filtered set has fewer words than count.
func select_words_for_stage(count: int, stage: int, max_length: int = 999) -> Array[WordEntry]:
	var max_diff: int = 1
	if stage >= 61:
		max_diff = 3
	elif stage >= 21:
		max_diff = 2

	var eligible: Array[WordEntry] = []
	for entry in entries:
		if entry.length >= 2 and entry.length <= max_length and entry.difficulty <= max_diff:
			eligible.append(entry)

	# Fall back to the full pool if there are not enough filtered words.
	if eligible.size() < count:
		eligible = []
		for entry in entries:
			if entry.length >= 2 and entry.length <= max_length:
				eligible.append(entry)

	eligible.shuffle()

	var result: Array[WordEntry] = []
	for i in range(mini(count, eligible.size())):
		result.append(eligible[i])

	return result
