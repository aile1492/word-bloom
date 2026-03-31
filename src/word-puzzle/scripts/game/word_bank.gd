## word_bank.gd
## Component that displays the list of words to find inside a GridContainer.
## Found words are shown with a strikethrough and greyed out.
class_name WordBank
extends GridContainer

const FONT_WORDBANK: Font = preload("res://assets/fonts/Nunito-Variable.ttf")
var _font_bold: Font = null

func _get_bold_font() -> Font:
	if _font_bold == null:
		var fv := FontVariation.new()
		fv.base_font = FONT_WORDBANK
		fv.variation_embolden = 0.4
		_font_bold = fv
	return _font_bold


## Font size floor and ceiling (can be changed in real time via a slider).
var font_size_min: int = 8
var font_size_max: int = 24

## Original word text keyed by word_key: { word_key: display_text }
var _texts: Dictionary = {}

## Word labels keyed by word_key: { word_key: RichTextLabel }
var _labels: Dictionary = {}


## Builds word labels from a list of PlacedWord objects.
func setup(placed_words: Array) -> void:
	_clear_chips()
	for pw in placed_words:
		_create_chip(pw)


## Calculates column count and font size based on the panel width.
## More words → more columns, smaller font (auto-shrink).
## When panel_height > 0, font size is also capped by the row height.
func update_layout(grid_width: float, panel_height: float = 0.0) -> void:
	if _labels.is_empty() or grid_width <= 0.0:
		return

	var count: int = _labels.size()

	# Column count: ≤9 words → 3 columns, more → 4 columns.
	var cols: int = 3 if count <= 9 else 4
	columns = cols

	# Column width (accounting for h_separation).
	var h_sep: float = float(get_theme_constant("h_separation"))
	var col_width: float = maxf((grid_width - h_sep * (cols - 1)) / cols, 60.0)

	# Calculate font size to fit the longest word in one column (auto-shrink).
	var longest: int = 1
	for text: String in _texts.values():
		longest = maxi(longest, text.length())

	# Korean characters are wider than Latin — use a larger ratio for CJK.
	var sample: String = _texts.values()[0] if not _texts.is_empty() else "가"
	var char_ratio: float = 1.1 if sample.unicode_at(0) >= 0xAC00 else 0.62
	var font_size: int = mini(int(col_width / (longest * char_ratio)), font_size_max)
	font_size = maxi(font_size, font_size_min)  # Enforce absolute floor (8).

	# Optionally cap by row height when panel_height is provided.
	if panel_height > 0.0:
		var v_sep: float = float(get_theme_constant("v_separation"))
		var row_count: int = ceili(float(count) / float(cols))
		if row_count > 0:
			var row_h: float = (panel_height - v_sep * float(row_count - 1)) / float(row_count)
			var font_from_h: int = maxi(font_size_min, int(row_h * 0.55))
			font_size = mini(font_size, font_from_h)

	for key: String in _labels.keys():
		var lbl: RichTextLabel = _labels[key]
		lbl.custom_minimum_size.x = col_width
		lbl.add_theme_font_override("normal_font", FONT_WORDBANK)
		lbl.add_theme_font_override("bold_font", _get_bold_font())
		lbl.add_theme_font_size_override("normal_font_size", font_size)
		lbl.add_theme_font_size_override("bold_font_size", font_size)


## Marks a word as found (strikethrough + grey).
func mark_found(word_key: String) -> void:
	if not word_key in _labels:
		return
	var lbl: RichTextLabel = _labels[word_key]
	var display: String = _texts.get(word_key, word_key)
	lbl.text = "[center][color=#AAAAAA][s]" + display + "[/s][/color][/center]"


## Removes all labels.
func _clear_chips() -> void:
	for child in get_children():
		child.queue_free()
	_texts.clear()
	_labels.clear()


## Creates a word label chip.
func _create_chip(pw: PlacedWord) -> void:
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.scroll_active = false
	lbl.fit_content = true
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.text = "[center][b]" + pw.display + "[/b][/center]"
	lbl.add_theme_color_override("default_color", Color.BLACK)
	lbl.add_theme_font_override("normal_font", FONT_WORDBANK)
	lbl.add_theme_font_override("bold_font", _get_bold_font())
	lbl.size_flags_horizontal = Control.SIZE_FILL
	add_child(lbl)
	_texts[pw.word] = pw.display
	_labels[pw.word] = lbl
