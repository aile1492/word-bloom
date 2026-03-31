## word_entry.gd
## An individual word entry loaded from a WordPack.
## Used during grid generation for word selection.
class_name WordEntry
extends RefCounted

## Original word (unique key).
## English: "hello", Korean: "사과"
var word: String = ""

## Word length (number of characters/syllables).
var length: int = 0

## Display word.
## English: "HELLO" (uppercased), Korean: "사과" (unchanged).
var display: String = ""

## Word category (sub-grouping within a theme).
var category: String = ""

## Difficulty rating (1=Easy, 5=Hard).
var difficulty: int = 1


## Creates a WordEntry.
static func create(
	p_word: String,
	p_display: String,
	p_category: String = "",
	p_difficulty: int = 1
) -> WordEntry:
	var entry := WordEntry.new()
	entry.word = p_word
	entry.display = p_display
	entry.length = p_display.length()
	entry.category = p_category
	entry.difficulty = p_difficulty
	return entry
