## game_screen.gd
## Top-level controller for the game screen.
## Coordinates GridData creation, input handling, and score/hint management.
extends BaseScreen

# ===== Font preloads =====
const FONT_UI:    Font = preload("res://assets/fonts/Nunito-Variable.ttf")
const _BALOO2_BASE: Font = preload("res://assets/fonts/Baloo2-Variable.ttf")
const FONT_THEME: Font = preload("res://assets/fonts/BubblegumSans-Regular.ttf")
var _title_font_cache: Font = null

func _get_title_font() -> Font:
	if _title_font_cache == null:
		var fv := FontVariation.new()
		fv.base_font = _BALOO2_BASE
		fv.variation_embolden = 0.3
		_title_font_cache = fv
	return _title_font_cache


## Emitted when a word is found.
signal word_found(placed_word: PlacedWord)

## Emitted when the stage is cleared.
signal stage_cleared(stage: int, score: int, grade: String)


# ===== Node references =====

@onready var background_rect: TextureRect = %Background
@onready var stage_label: Label          = %StageLabel
@onready var solve_rate_label: Label     = %SolveRateLabel
@onready var back_button: Button         = %BackButton
@onready var settings_button: Button     = %SettingsButton
@onready var theme_label: Label          = %ThemeLabel
@onready var word_bank: WordBank         = %WordBank
@onready var grid_board: GridBoard       = %GridBoard
@onready var daily_button: Button        = %DailyButton
@onready var task_button: Button         = %TaskButton
@onready var gift_button: Button         = %GiftButton
@onready var power_hint_button: Button   = %PowerHintButton
@onready var hint_button: Button         = %HintButton
@onready var shuffle_button: Button      = %ShuffleButton


# ===== Game state =====

var _grid_data: GridData = null
var _input_handler: GridInputHandler = null
var _input_handler_tv: GridInputHandlerTV = null
var _grid_generator: GridGenerator = GridGenerator.new()
var _hint_manager: HintManager = null

var _current_stage: int = 1
var _total_score: int = 0
var _hint_count: int = 0
var _used_hint: bool = false
var _last_found_time: float = -999.0
var _stage_start_time: float = 0.0

## Previous drag path (used for highlight update).
var _prev_drag_cells: Array = []

## Hint slot cells (semi-transparent black panels behind the icons).
var _hint_cell_first: Button = null
var _hint_cell_full:  Button = null
## Count labels inside the hint slot cells.
var _hint_count_first: Label = null
var _hint_count_full:  Label = null

## Variable layout parameters (can be adjusted in real time via debug sliders).
## Heights: ref_px / 1560 × 1920  |  widths/sizes: ref_px / 720 × 1080
var _lay_gap: float           = 36.9   ## 32/1560×1920 — gap between WordBank and Grid
var _lay_banner_h: float      = 96.0   ## 55/1560×1920
var _lay_wordbank_h: float    = 205.5  ## 166/1560×1920
var _lay_inner_gap: float     = 29.0   ## ThemeBanner↔WordBank gap
var _lay_bar_padding: float   = 16.0
var _lay_grid_y_offset: float = -130.0  ## Fine-tune above auto-centred position (positive = down, negative = up).
## Hint slot cell layout.
var _hint_cell_w:        float = 127.0  ## Cell width (px).
var _hint_cell_h:        float =  53.0  ## Cell height (px).
var _hint_cell_overflow: float =  37.0  ## How far the icon protrudes above the cell (px).
var _hint_cell_x_offset: float =  46.0  ## Cell X fine-tune.
var _hint_cell_y_offset: float = -50.0  ## Cell Y fine-tune.
## Hint count label adjustments.
var _hint_count_x:    float = 46.0   ## Count label X offset.
var _hint_count_y:    float =  0.0   ## Count label Y offset.
var _hint_count_font: float = 35.0   ## Count label font size (supports decimals).
## Hint group (icon + cell + count) global adjustments.
var _hint_group_scale: float =  2.0   ## Group-wide scale (cell size, icon, and font all scale together).
var _hint_group_x:     float = -37.0  ## Group X translation.
var _hint_group_y:     float =   6.0  ## Group Y translation.
var _lay_btn1_pos: float      = 0.30   ## Reveal-hint button position (0–1 across grid width).
var _lay_btn2_pos: float      = 0.70   ## First-letter button position (0–1 across grid width).
var _lay_topbar_h: float      = 254.8  ## 207/1560×1920
var _lay_top_btn_size: float  = 111.0  ## 75/720×1080 — top button (←★🛒) diameter
var _lay_adbanner_h: float    = 119.0
var _lay_level_info_y: float  =  60.0  ## LevelInfo group overall Y (relative to TopBar).
var _lay_top_btn_y: float     =  43.0  ## Button centre Y(99) − radius(56) = 43.
var _lay_stage_y: float       =  64.0  ## "Stage N" centre Y.
var _lay_rate_y: float        = 104.8  ## "X%..." centre Y(191) − RATE_H/2(50) − level_info_y(36).
var _lay_level_info_x: float  = 130.0  ## LevelInfo X offset. 0 = natural HBox centre (screen mid).

## Hint icon scale and independent position offsets (cells/numbers are unaffected).
var _lay_hint_scale: float    = 0.85
var _hint_icon_x:    float    = -12.0  ## Icon-only X translation.
var _hint_icon_y:    float    =  38.0  ## Icon-only Y translation.

## Font size parameters.
var _font_stage: float        = 39.0   ## "Stage N"
var _font_solve_rate: float   = 16.0   ## "X% of players..."
var _font_theme: float        = 53.0   ## Font size as a percentage of the theme-banner height.
var _font_wordbank_max: float = 38.0   ## WordBank maximum word font size.
var _font_btn_action: float   = 15.0   ## Bottom action-button font size.
var _font_ad: float           = 28.0

## TopBar 내부 노드 참조 (Y축 오프셋 적용용; _ready()에서 초기화)
var _topbar_hbox: HBoxContainer = null
var _left_btns:   HBoxContainer = null
var _right_btns:  HBoxContainer = null
var _level_info:  Control       = null  ## VBoxContainer → Control: 자식 정렬 없어 폰트 변경 시 위치 불변

## In-game debug window (created only when OS.is_debug_build() is true).
var _debug_win: Window       = null
var _debug_labels: Dictionary = {}

## Stage-clear popup.
var _stage_complete_popup: StageCompletePopup = null

## Fade layer for screen transitions (layer=9, below popups).
var _fade_layer: CanvasLayer = null
var _fade_rect:  ColorRect   = null

## List of cells currently highlighted by the magnifier hint.
var _magnifier_cells: Array[Vector2i] = []

## Ad-remove button (shown in TopBar when ads not purchased).
var _ad_remove_btn: Button = null

## Current drag colour index (randomly picked from FOUND_COLORS palette).
var _drag_color_index: int = 0

## Combo validity window (seconds).
const COMBO_WINDOW: float = 10.0


func _ready() -> void:
	_setup_styles()

	back_button.pressed.connect(_on_back_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	_setup_ad_remove_button()
	daily_button.pressed.connect(_on_daily_pressed)
	task_button.pressed.connect(_on_task_pressed)
	gift_button.pressed.connect(_on_gift_pressed)
	power_hint_button.pressed.connect(_on_full_reveal_pressed)
	hint_button.pressed.connect(_on_first_letter_pressed)
	shuffle_button.pressed.connect(_on_shuffle_pressed)

	HintTicketManager.tickets_changed.connect(_update_hint_buttons)
	_setup_debug_panel()
	_setup_popup_and_fade()

	# Connect TopBar HBoxContainer sort_children → apply Y-axis offsets in real time.
	_topbar_hbox = %TopBar.get_node("HBoxContainer") as HBoxContainer
	if _topbar_hbox:
		_left_btns  = _topbar_hbox.get_node("LeftBtns")  as HBoxContainer
		_right_btns = _topbar_hbox.get_node_or_null("RightBtns") as HBoxContainer
		_level_info = _topbar_hbox.get_node("LevelInfo") as Control
		## Ensure LevelInfo does not block click events.
		## When a position.x offset is applied, it overlaps button regions and the
		## default MOUSE_FILTER_STOP would swallow clicks.
		if _level_info:
			_level_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_topbar_hbox.sort_children.connect(_reapply_topbar_y_offsets)


# ===== Popup / fade initialisation =====

func _setup_popup_and_fade() -> void:
	# ── Stage-clear popup (CanvasLayer layer=10) ──
	_stage_complete_popup = StageCompletePopup.new()
	add_child(_stage_complete_popup)

	# ── Black fade layer for screen transitions (layer=11, above popup layer 10) ──
	## Pressing the button causes the popup and game screen to be covered together,
	## producing a smooth transition.
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 11
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


## Fade out: covers all layers (including popups) with black over 0.30 s. Supports await.
func _fade_out() -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, 0.30)
	await tw.finished


## Fade in: removes the black overlay over 0.30 s. Supports await.
func _fade_in() -> void:
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 0.0, 0.30)
	await tw.finished
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ===== Style setup =====

func _setup_styles() -> void:
	# Hint button icons: apply dedicated image per type.
	const PATH_FIRST: String = "res://assets/icons/ui/icon_hint_first.png"
	const PATH_FULL:  String = "res://assets/icons/ui/icon_hint_full.png"
	if ResourceLoader.exists(PATH_FIRST):
		hint_button.icon       = load(PATH_FIRST) as Texture2D
		hint_button.expand_icon = true
		hint_button.text        = ""
	if ResourceLoader.exists(PATH_FULL):
		power_hint_button.icon       = load(PATH_FULL) as Texture2D
		power_hint_button.expand_icon = true
		power_hint_button.text        = ""

	# Create slot cells: added to hint_button's parent (BtnContainer) → shares the same coordinate space.
	var cells: Array = _make_hint_cells(hint_button.get_parent())
	_hint_cell_first  = cells[0] as Button
	_hint_cell_full   = cells[1] as Button
	_hint_count_first = cells[2] as Label
	_hint_count_full  = cells[3] as Label
	# Slot-cell buttons handle actual clicks → connect handlers.
	_hint_cell_first.pressed.connect(_on_first_letter_pressed)
	_hint_cell_full.pressed.connect(_on_full_reveal_pressed)
	# Icon buttons are visual only (ignore mouse input → pass through to slot cells).
	hint_button.mouse_filter       = Control.MOUSE_FILTER_IGNORE
	power_hint_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Icons render above cells.
	hint_button.z_index       = 2
	power_hint_button.z_index = 2

	# Back button icon.
	if ResourceLoader.exists("res://assets/icons/ui/icon_back.png"):
		back_button.icon = load("res://assets/icons/ui/icon_back.png") as Texture2D
		back_button.text = ""
		back_button.expand_icon = true

	# Settings button icon.
	if ResourceLoader.exists("res://assets/icons/ui/icon_settings.png"):
		settings_button.icon = load("res://assets/icons/ui/icon_settings.png") as Texture2D
		settings_button.text = ""
		settings_button.expand_icon = true

	# Area background colours.
	%TopBar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_apply_flat_rounded(%ThemeBanner, Color(0.38, 0.25, 0.75, 0.9), 14)
	_apply_flat_rounded(%WordBankPanel, Color.WHITE, 14)
	# Remove BottomActionBar background entirely (overrides PanelContainer default StyleBox too).
	%BottomActionBar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	# Make AdBanner area transparent so the background image shows through.
	%AdBanner.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	# Text colours + fonts.
	stage_label.add_theme_font_override("font", _get_title_font())
	stage_label.add_theme_color_override("font_color", Color.WHITE)
	solve_rate_label.add_theme_font_override("font", FONT_UI)
	solve_rate_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.7))
	solve_rate_label.visible = false  ## TODO: hidden until ready
	theme_label.add_theme_font_override("font", FONT_THEME)
	theme_label.add_theme_color_override("font_color", Color.WHITE)
	%AdLabel.visible = false  # Hidden; real banner ad will overlay this area

	# Circular button styles (hint buttons have a background in the icon itself, so use transparent).
	for btn: Button in [back_button, settings_button,
						daily_button, task_button, gift_button,
						shuffle_button]:
		_apply_circle_btn(btn, Color(0.0, 0.0, 0.0, 0.45))
	for btn: Button in [hint_button, power_hint_button]:
		_apply_circle_btn(btn, Color(0.0, 0.0, 0.0, 0.0))


## Maps word-pack filename to parent theme id.
## e.g. "breakfast" → "food", "planets" → "space"
const WORD_PACK_TO_THEME: Dictionary = {
	# animals
	"animals": "animals", "birds": "animals", "insects": "animals",
	"jungle": "animals", "farm": "animals", "dinosaurs": "animals",
	# food
	"food": "food", "breakfast": "food", "fastfood": "food",
	"fruits": "food", "vegetables": "food", "desserts": "food",
	"drinks": "food", "spices": "food", "household": "food",
	# music
	"music": "music", "musicalinstruments": "music", "dance": "music",
	# mythology
	"mythology": "mythology", "superheroes": "mythology",
	# ocean
	"ocean": "ocean", "watersports": "ocean", "pirates": "ocean",
	# science
	"science": "science", "chemistry": "science", "mathematics": "science",
	"medicine": "science", "technology": "science",
	# space
	"space": "space", "planets": "space", "weather": "space",
	# sports
	"sports": "sports", "olympicsports": "sports", "martialarts": "sports",
}


## Maps theme ID to a human-readable display name (handles compound-word themes).
## Themes not listed here fall back to the general _to_title_case() logic.
const THEME_DISPLAY_NAMES: Dictionary = {
	"videogames":         "Video Games",
	"boardgames":         "Board Games",
	"fastfood":           "Fast Food",
	"martialarts":        "Martial Arts",
	"watersports":        "Water Sports",
	"olympicsports":      "Olympic Sports",
	"artmovements":       "Art Movements",
	"musicalinstruments": "Musical Instruments",
	"humanbody":          "Human Body",
}


## Extracts the background theme id ("food") from a word_pack_path
## ("res://data/words/ko/breakfast.json"). Falls back to "animals" if not mapped.
func _extract_theme(word_pack_path: String) -> String:
	var fname: String = word_pack_path.get_file().get_basename().to_lower()
	return WORD_PACK_TO_THEME.get(fname, "animals")


## Converts each word in a string to title case.
## "olympic sports" → "Olympic Sports"
func _to_title_case(s: String) -> String:
	## Compound-word themes are returned directly from the dictionary.
	var key: String = s.to_lower()
	if THEME_DISPLAY_NAMES.has(key):
		return THEME_DISPLAY_NAMES[key] as String
	## General: capitalise the first letter of each space-separated word.
	var words: Array = s.split(" ")
	var result: PackedStringArray = PackedStringArray()
	for w in words:
		var word: String = w as String
		if word.length() == 0:
			result.append(word)
		else:
			result.append(word.substr(0, 1).to_upper() + word.substr(1))
	return " ".join(result)


## Returns the background image path for the given theme name and stage number.
## Stage  1-20 : bg_{theme}.png
## Stage 21-60 : bg_{theme}_2.png
## Stage 61+   : bg_{theme}_3.png
func _get_background_path(theme_id: String, stage: int) -> String:
	var suffix: String = ""
	if stage >= 61:
		suffix = "_3"
	elif stage >= 21:
		suffix = "_2"
	return "res://assets/backgrounds/bg_" + theme_id + suffix + ".webp"


## Applies the correct background image to the TextureRect for the given theme/stage.
## Accepts the JSON theme field ("animals") rather than a display name ("Animals").
func _apply_background(theme_id: String, stage: int) -> void:
	if not is_instance_valid(background_rect):
		return
	var path: String = _get_background_path(theme_id, stage)
	if ResourceLoader.exists(path):
		background_rect.texture = load(path) as Texture2D
	else:
		push_warning("GameScreen: Cannot load background image - " + path)
		var fallback: String = "res://assets/backgrounds/bg_" + theme_id + ".webp"
		if ResourceLoader.exists(fallback):
			background_rect.texture = load(fallback) as Texture2D
		else:
			push_warning("GameScreen: Fallback background also missing - " + fallback)


func _apply_flat(panel: PanelContainer, color: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	panel.add_theme_stylebox_override("panel", s)


func _apply_flat_rounded(panel: PanelContainer, color: Color, radius: int) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	panel.add_theme_stylebox_override("panel", s)


func _apply_circle_btn(btn: Button, color: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	# 9999: Godot auto-clamps to half the shortest side → always a perfect circle regardless of button size.
	s.corner_radius_top_left     = 9999
	s.corner_radius_top_right    = 9999
	s.corner_radius_bottom_left  = 9999
	s.corner_radius_bottom_right = 9999

	var s_hover := s.duplicate() as StyleBoxFlat
	s_hover.bg_color = color.lightened(0.1)

	var s_press := s.duplicate() as StyleBoxFlat
	s_press.bg_color = color.darkened(0.15)

	var s_dis := StyleBoxFlat.new()
	s_dis.bg_color = Color(0.3, 0.3, 0.3, 0.7)
	s_dis.corner_radius_top_left     = 9999
	s_dis.corner_radius_top_right    = 9999
	s_dis.corner_radius_bottom_left  = 9999
	s_dis.corner_radius_bottom_right = 9999

	btn.add_theme_stylebox_override("normal",   s)
	btn.add_theme_stylebox_override("hover",    s_hover)
	btn.add_theme_stylebox_override("pressed",  s_press)
	btn.add_theme_stylebox_override("disabled", s_dis)
	btn.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color",          Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(1.0, 1.0, 1.0, 0.35))
	btn.add_theme_font_size_override("font_size", 14)


## Creates two hint slot cells (first-letter / reveal) and two count labels.
## Return order: [cell_first, cell_full, count_first, count_full]
func _make_hint_cells(parent: Control) -> Array:
	var cell_first := _make_one_hint_cell(parent)
	var cell_full  := _make_one_hint_cell(parent)
	return [cell_first, cell_full,
			cell_first.get_child(0) as Label,
			cell_full.get_child(0)  as Label]


func _make_one_hint_cell(parent: Control) -> Button:
	var cell := Button.new()
	# Default StyleBox (semi-transparent black, rounded).
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.0, 0.0, 0.0, 125.0 / 255.0)
	cs.corner_radius_top_left     = 14
	cs.corner_radius_top_right    = 14
	cs.corner_radius_bottom_left  = 14
	cs.corner_radius_bottom_right = 14
	cell.add_theme_stylebox_override("normal",   cs)
	# Hover: slightly brighter.
	var cs_hover: StyleBoxFlat = cs.duplicate() as StyleBoxFlat
	cs_hover.bg_color = Color(0.15, 0.15, 0.15, 150.0 / 255.0)
	cell.add_theme_stylebox_override("hover",    cs_hover)
	# Pressed: even brighter.
	var cs_press: StyleBoxFlat = cs.duplicate() as StyleBoxFlat
	cs_press.bg_color = Color(0.25, 0.25, 0.25, 170.0 / 255.0)
	cell.add_theme_stylebox_override("pressed",  cs_press)
	# Remove focus ring.
	cell.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
	cell.flat = false
	cell.z_index = 1   # Below icons (z=2) to preserve visual stacking order.
	parent.add_child(cell)

	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(lbl)
	return cell


## Applies hint button scale and slot-cell position.
## btn_size: actual button size (px) as set by _set_btn_at.
## The icon protrudes above the cell by OVERFLOW_RATIO.
func _apply_hint_icon_scale(btn_size: float = 84.0) -> void:
	# Icon scale = individual slider × group scale.
	var s: float = _lay_hint_scale * _hint_group_scale
	var half: float = btn_size * 0.5
	for btn: Button in [hint_button, power_hint_button]:
		btn.scale = Vector2(s, s)
		btn.pivot_offset = Vector2(half, half)
	# Count label font: _hint_count_font base × combined scale.
	var cnt_font: int = maxi(6, roundi(_hint_count_font * s))
	if _hint_count_first:
		_hint_count_first.add_theme_font_size_override("font_size", cnt_font)
	if _hint_count_full:
		_hint_count_full.add_theme_font_size_override("font_size", cnt_font)


## Immediately applies TopBar / AdBanner sizes and all label font sizes.
## Called every time a slider changes.
func _apply_dynamic_layout() -> void:
	%TopBar.custom_minimum_size = Vector2(0, _lay_topbar_h)
	for btn: Button in [back_button, settings_button]:
		btn.custom_minimum_size = Vector2(_lay_top_btn_size, _lay_top_btn_size)
	# AdBanner uses absolute anchors outside the VBoxContainer, so only offset_top changes the height.
	# Using custom_minimum_size would cause the VBoxContainer to re-layout GridArea.
	%AdBanner.offset_top    = -_lay_adbanner_h
	%AdBanner.offset_bottom = 0.0

	stage_label.add_theme_font_size_override("font_size", int(_font_stage))
	solve_rate_label.add_theme_font_size_override("font_size", int(_font_solve_rate))
	# theme_label font is set in _update_button_layout() as a ratio of the banner height.
	# %AdLabel hidden — no font size needed

	for btn: Button in [daily_button, task_button, gift_button,
						power_hint_button, hint_button, shuffle_button]:
		btn.add_theme_font_size_override("font_size", int(_font_btn_action))

	word_bank.font_size_max = int(_font_wordbank_max)

	# StageLabel / SolveRateLabel positions are set directly via anchor-based offsets.
	# LevelInfo is a plain Control (not a container), so child positions do not shift when fonts change.
	const STAGE_H: float = 60.0   ## Fixed StageLabel height (accommodates max STAGE font of 48 px).
	const RATE_H: float  = 100.0  ## Fixed SolveRateLabel height (accommodates max RATE font of 80 px).

	# X: span the full LevelInfo width with centred text → displayed at screen centre.
	stage_label.anchor_left          = 0.0
	stage_label.anchor_right         = 1.0
	stage_label.offset_left          = 0.0
	stage_label.offset_right         = 0.0
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	solve_rate_label.anchor_left          = 0.0
	solve_rate_label.anchor_right         = 1.0
	solve_rate_label.offset_left          = 0.0
	solve_rate_label.offset_right         = 0.0
	solve_rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Y: use existing approach.
	stage_label.offset_top         = _lay_stage_y
	stage_label.offset_bottom      = _lay_stage_y + STAGE_H
	solve_rate_label.offset_top    = _lay_rate_y
	solve_rate_label.offset_bottom = _lay_rate_y + RATE_H

	# Trigger HBoxContainer re-sort to reapply button/LevelInfo group positions.
	if _topbar_hbox:
		_topbar_hbox.queue_sort()


## Locks the button/LevelInfo group Y positions after the TopBar HBoxContainer sort completes.
## Values are set directly so they always converge to the same result regardless of how many
## times sort_children fires.
func _reapply_topbar_y_offsets() -> void:
	if _left_btns:
		_left_btns.position.y  = _lay_top_btn_y
	if _right_btns:
		_right_btns.position.y = _lay_top_btn_y
	if _level_info:
		_level_info.position.y = _lay_level_info_y
		_level_info.position.x = _lay_level_info_x


## Adds a group of slider rows to vbox for the debug panel.
## defs format: [display name, property, initial value, min, max]
## trigger_layout=false → _update_button_layout() is not called when the slider changes.
func _add_debug_sliders(vbox: VBoxContainer, defs: Array,
		trigger_layout: bool = true) -> void:
	for sd: Array in defs:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		vbox.add_child(row)

		var n_lbl := Label.new()
		n_lbl.text = sd[0]
		n_lbl.custom_minimum_size = Vector2(110, 0)
		n_lbl.add_theme_font_size_override("font_size", 16)
		row.add_child(n_lbl)

		var range_size: float = float(sd[4]) - float(sd[3])
		var use_decimal: bool = range_size <= 2.0
		# A 6th element supplies a custom step (e.g. 0.5 → decimal font slider).
		var custom_step: float = float(sd[5]) if sd.size() >= 6 else 0.0
		var step: float = custom_step if custom_step > 0.0 else (0.01 if use_decimal else 1.0)

		var slider := HSlider.new()
		slider.min_value = sd[3]
		slider.max_value = sd[4]
		slider.value    = sd[2]
		slider.step     = step
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size   = Vector2(0, 32)
		row.add_child(slider)

		var v_lbl := Label.new()
		v_lbl.text = ("%.1f" % float(sd[2])) if (custom_step > 0.0 and custom_step < 1.0) \
				else (("%.2f" % float(sd[2])) if use_decimal else str(roundi(sd[2])))
		v_lbl.custom_minimum_size = Vector2(52, 0)
		v_lbl.add_theme_font_size_override("font_size", 16)
		row.add_child(v_lbl)

		_connect_debug_slider(slider, sd[1], v_lbl, trigger_layout)


## GridArea 안 오버레이 3종 (ThemeBanner, WordBankPanel, BottomActionBar)을
## 그리드 셀 실제 위치에 맞춰 배치한다. 버튼 크기(84×84)는 변경하지 않는다.
func _update_button_layout() -> void:
	var cell_size: float = grid_board.get_cell_size()
	if cell_size <= 0.0:
		return
	if grid_board.size.y <= 0.0:
		return
	var grid_px: Vector2 = GridLayout.calculate_grid_pixel_size(
		cell_size, _grid_data.width, _grid_data.height
	)

	# ── BottomActionBar: 그리드 아래 ──
	const BTN_SIZE: float = 84.0

	# 자동 Y 중앙정렬: 그리드 위쪽 콘텐츠(배너+워드뱅크+GAP)와
	# 아래쪽 콘텐츠(버튼바+GAP) 높이 차의 절반만큼 그리드를 이동한다.
	var top_content_h: float = _lay_banner_h + _lay_inner_gap + _lay_wordbank_h + _lay_gap
	var bot_content_h: float = BTN_SIZE + _lay_bar_padding + _lay_gap
	var auto_y: float = (top_content_h - bot_content_h) / 2.0
	# _lay_grid_y_offset 은 자동 중앙값 위의 미세 조정값
	var total_y: float = auto_y + _lay_grid_y_offset

	# GridBoard 를 Y축으로 이동 (offset_top == offset_bottom 이면 크기 유지)
	grid_board.offset_top    = total_y
	grid_board.offset_bottom = total_y

	# 그리드 셀 수평 범위 (GridBoard = CenterContainer, 셀이 수평 중앙정렬됨)
	var grid_left: float  = (grid_board.size.x - grid_px.x) / 2.0
	var grid_right: float = grid_left + grid_px.x

	# GridArea 높이를 _lay_topbar_h 기준으로 직접 계산한다.
	# grid_board.size.y는 _apply_dynamic_layout() 직후 stale할 수 있다
	# (VBoxContainer sort_children이 deferred 처리되어 아직 구 TopBar 높이 기준).
	var grid_area_h: float = get_viewport_rect().size.y - _lay_topbar_h

	# 그리드 셀 수직 범위 (total_y 기준 GridArea 절대 좌표)
	var grid_cells_top:    float = total_y + (grid_area_h - grid_px.y) / 2.0
	var grid_cells_bottom: float = total_y + (grid_area_h + grid_px.y) / 2.0

	var bar_top:    float = grid_cells_bottom + _lay_gap
	var bar_bottom: float = bar_top + BTN_SIZE + _lay_bar_padding

	_set_overlay_rect(%BottomActionBar, grid_left, grid_right, bar_top, bar_bottom)

	# 활성 버튼 2개를 그리드 너비의 2/5·4/5 지점에 배치
	# BtnContainer 좌표계 = BottomActionBar 내부 (너비 = grid_px.x)
	var bar_h: float   = bar_bottom - bar_top
	# 그룹 Y/X 오프셋: 아이콘+셀+숫자 전체를 이동
	var btn_y: float   = (bar_h - BTN_SIZE) / 2.0 + _hint_group_y
	var btn1_cx: float = grid_px.x * _lay_btn1_pos + _hint_group_x
	var btn2_cx: float = grid_px.x * _lay_btn2_pos + _hint_group_x
	_set_btn_at(power_hint_button, btn1_cx + _hint_icon_x, btn_y + _hint_icon_y, BTN_SIZE)
	_set_btn_at(hint_button,       btn2_cx + _hint_icon_x, btn_y + _hint_icon_y, BTN_SIZE)
	_apply_hint_icon_scale(BTN_SIZE)

	# ── 힌트 슬롯 셀: 아이콘 뒤 반투명 카드 (슬라이더로 조절 가능) ──
	# 그룹 스케일: 셀 크기·overflow 동시 확대/축소
	var gs: float      = _hint_group_scale
	var cell_w: float  = _hint_cell_w * gs
	var cell_h: float  = _hint_cell_h * gs
	var cell_y: float  = btn_y + _hint_cell_overflow * gs + _hint_cell_y_offset
	for cell_data: Array in [
		[_hint_cell_full,  btn1_cx],
		[_hint_cell_first, btn2_cx],
	]:
		var cell: Button = cell_data[0] as Button
		var cx:   float  = cell_data[1]
		if cell == null:
			continue
		cell.anchor_left   = 0.0; cell.anchor_right  = 0.0
		cell.anchor_top    = 0.0; cell.anchor_bottom = 0.0
		cell.offset_left   = cx - cell_w * 0.5 + _hint_cell_x_offset
		cell.offset_right  = cx + cell_w * 0.5 + _hint_cell_x_offset
		cell.offset_top    = cell_y
		cell.offset_bottom = cell_y + cell_h

	# ── 힌트 카운트 라벨 X/Y 오프셋 적용 ──
	for cnt_lbl: Label in [_hint_count_first, _hint_count_full]:
		if cnt_lbl == null:
			continue
		cnt_lbl.anchor_left   = 0.0; cnt_lbl.anchor_right  = 1.0
		cnt_lbl.anchor_top    = 0.0; cnt_lbl.anchor_bottom = 1.0
		cnt_lbl.offset_left   = _hint_count_x
		cnt_lbl.offset_right  = _hint_count_x
		cnt_lbl.offset_top    = _hint_count_y
		cnt_lbl.offset_bottom = _hint_count_y

	# ── ThemeBanner + WordBankPanel: 그리드 위 ──
	var wb_bottom: float = grid_cells_top - _lay_gap
	var wb_top:    float = wb_bottom - _lay_wordbank_h
	var tb_bottom: float = wb_top - _lay_inner_gap
	var tb_top:    float = tb_bottom - _lay_banner_h

	_set_overlay_rect(%ThemeBanner,   grid_left, grid_right, tb_top, tb_bottom)
	_set_overlay_rect(%WordBankPanel, grid_left, grid_right, wb_top, wb_bottom)

	# 테마 배너 폰트: 배너 높이 × (_font_theme / 100) 비율로 자동 계산
	theme_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	theme_label.add_theme_font_size_override("font_size",
		clamp(int(_lay_banner_h * _font_theme / 100.0), 10, 80))

	# 정답 단어 폰트: 패널 높이를 전달해 행 높이 기반으로 제한
	word_bank.update_layout(grid_px.x, _lay_wordbank_h)

	_update_debug_info({
		"grid_top": grid_cells_top,  "grid_bottom": grid_cells_bottom,
		"tb_top":   tb_top,          "tb_bottom":   tb_bottom,
		"wb_top":   wb_top,          "wb_bottom":   wb_bottom,
		"bar_top":  bar_top,         "bar_bottom":  bar_bottom,
		"grid_w":   grid_px.x,       "grid_h":      grid_px.y,
	})


## 별도 OS 창으로 디버그 패널 생성 (debug 빌드 전용).
## 게임 창 옆에 독립 Window를 띄운다.
func _setup_debug_panel() -> void:
	if not OS.is_debug_build() or OS.has_feature("mobile"):
		return

	# ── 별도 OS 창 ──
	var win := Window.new()
	win.title = "Layout Debug"
	win.size = Vector2i(460, 920)
	win.position = Vector2i(600, 40)   # 게임 창(540px) 오른쪽
	win.always_on_top = true
	win.exclusive = false
	win.visible = false
	# 창 닫기 버튼 → hide (destroy 방지)
	win.close_requested.connect(func() -> void: win.hide())
	get_tree().root.add_child(win)

	# 여백 컨테이너
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   14)
	margin.add_theme_constant_override("margin_right",  14)
	margin.add_theme_constant_override("margin_top",    10)
	margin.add_theme_constant_override("margin_bottom", 10)
	win.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	# 제목
	var title := Label.new()
	title.text = "◈ Layout Debug"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	# ── Grid Overlay ──
	var s1 := Label.new()
	s1.text = "▸ Grid Overlay"
	s1.add_theme_font_size_override("font_size", 15)
	s1.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(s1)
	_add_debug_sliders(vbox, [
		["Y보정",      "_lay_grid_y_offset", _lay_grid_y_offset, -300.0, 300.0],
		["GAP",        "_lay_gap",           _lay_gap,              2.0,  60.0],
		["BANNER_H",   "_lay_banner_h",      _lay_banner_h,        20.0, 150.0],
		["WORDBANK_H", "_lay_wordbank_h",    _lay_wordbank_h,      40.0, 240.0],
		["INNER_GAP",  "_lay_inner_gap",     _lay_inner_gap,        0.0,  40.0],
		["BAR_PAD",    "_lay_bar_padding",   _lay_bar_padding,      0.0,  60.0],
		["WB_MAX",     "_font_wordbank_max", _font_wordbank_max,   10.0,  48.0],
		["BTN1_POS",   "_lay_btn1_pos",      _lay_btn1_pos,         0.0,   1.0],
		["BTN2_POS",   "_lay_btn2_pos",      _lay_btn2_pos,         0.0,   1.0],
	])

	vbox.add_child(HSeparator.new())
	var s_hcell := Label.new()
	s_hcell.text = "▸ Hint Cell"
	s_hcell.add_theme_font_size_override("font_size", 15)
	s_hcell.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(s_hcell)
	_add_debug_sliders(vbox, [
		["CELL_W",   "_hint_cell_w",        _hint_cell_w,        20.0, 200.0],
		["CELL_H",   "_hint_cell_h",        _hint_cell_h,        10.0, 150.0],
		["OVERFLOW", "_hint_cell_overflow", _hint_cell_overflow,  0.0, 100.0],
		["CELL_X",   "_hint_cell_x_offset", _hint_cell_x_offset,-100.0, 100.0],
		["CELL_Y",   "_hint_cell_y_offset", _hint_cell_y_offset, -50.0,  50.0],
	])

	vbox.add_child(HSeparator.new())
	var s_hcount := Label.new()
	s_hcount.text = "▸ Hint Count"
	s_hcount.add_theme_font_size_override("font_size", 15)
	s_hcount.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(s_hcount)
	_add_debug_sliders(vbox, [
		["COUNT_X",    "_hint_count_x",    _hint_count_x,    -50.0, 50.0],
		["COUNT_Y",    "_hint_count_y",    _hint_count_y,    -50.0, 50.0],
		["COUNT_FONT", "_hint_count_font", _hint_count_font,   6.0, 48.0, 0.5],
	])

	vbox.add_child(HSeparator.new())
	var s2 := Label.new()
	s2.text = "▸ TopBar / AdBanner  (그리드 고정)"
	s2.add_theme_font_size_override("font_size", 15)
	s2.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(s2)
	# trigger_layout=false: 그리드 오버레이 재계산 없이 크기/위치만 변경
	_add_debug_sliders(vbox, [
		["TOPBAR_H",   "_lay_topbar_h",      _lay_topbar_h,       40.0, 160.0],
		["TOP_BTN_SZ", "_lay_top_btn_size",  _lay_top_btn_size,   40.0, 120.0],
		["AD_H",       "_lay_adbanner_h",    _lay_adbanner_h,     20.0, 120.0],
		["LEVEL_X",    "_lay_level_info_x",  _lay_level_info_x, -200.0, 200.0],
		["LEVEL_Y",    "_lay_level_info_y",  _lay_level_info_y,  -60.0,  60.0],
		["BTN_Y",      "_lay_top_btn_y",     _lay_top_btn_y,     -60.0,  60.0],
		["STAGE_Y",    "_lay_stage_y",       _lay_stage_y,       -60.0, 120.0],
		["RATE_Y",     "_lay_rate_y",        _lay_rate_y,        -60.0, 120.0],
	], false)

	vbox.add_child(HSeparator.new())
	var s3 := Label.new()
	s3.text = "▸ Font Sizes  (그리드 고정)"
	s3.add_theme_font_size_override("font_size", 15)
	s3.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(s3)
	# trigger_layout=false: 폰트 크기만 변경, 그리드 오버레이 재계산 없음
	_add_debug_sliders(vbox, [
		["STAGE",    "_font_stage",        _font_stage,        10.0, 48.0],
		["RATE",     "_font_solve_rate",   _font_solve_rate,    8.0, 80.0],
		["THEME%",   "_font_theme",        _font_theme,        10.0, 100.0],
		["BTN_ACT",  "_font_btn_action",   _font_btn_action,    8.0, 28.0],
		["AD",       "_font_ad",           _font_ad,            8.0, 28.0],
	], false)

	vbox.add_child(HSeparator.new())
	var s4 := Label.new()
	s4.text = "▸ Hint Icon"
	s4.add_theme_font_size_override("font_size", 15)
	s4.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(s4)
	_add_debug_sliders(vbox, [
		["SCALE",  "_lay_hint_scale", _lay_hint_scale, 0.1, 3.0,    0.05],
		["ICON_X", "_hint_icon_x",    _hint_icon_x,  -150.0, 150.0],
		["ICON_Y", "_hint_icon_y",    _hint_icon_y,  -150.0, 150.0],
	])

	vbox.add_child(HSeparator.new())
	var s_hgrp := Label.new()
	s_hgrp.text = "▸ Hint Group  (아이콘+셀+숫자 전체)"
	s_hgrp.add_theme_font_size_override("font_size", 15)
	s_hgrp.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(s_hgrp)
	_add_debug_sliders(vbox, [
		["GRP_SCALE", "_hint_group_scale", _hint_group_scale, 0.1, 3.0, 0.05],
		["GRP_X",     "_hint_group_x",     _hint_group_x,   -200.0, 200.0],
		["GRP_Y",     "_hint_group_y",     _hint_group_y,   -200.0, 200.0],
	])

	vbox.add_child(HSeparator.new())

	# ── 읽기 전용 수치 레이블 ──
	var info_defs: Array[String] = [
		"grid_top", "grid_bottom",
		"tb_top",   "tb_bottom",
		"wb_top",   "wb_bottom",
		"bar_top",  "bar_bottom",
		"grid_w",   "grid_h",
	]
	var info_names: Dictionary = {
		"grid_top":    "Grid Y top",   "grid_bottom": "Grid Y bot",
		"tb_top":      "Banner top",   "tb_bottom":   "Banner bot",
		"wb_top":      "Words  top",   "wb_bottom":   "Words  bot",
		"bar_top":     "Bar    top",   "bar_bottom":  "Bar    bot",
		"grid_w":      "Grid  W px",   "grid_h":      "Grid  H px",
	}
	var info_grid := GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 16)
	info_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(info_grid)

	for key: String in info_defs:
		var n_lbl := Label.new()
		n_lbl.text = info_names.get(key, key)
		n_lbl.add_theme_font_size_override("font_size", 14)
		info_grid.add_child(n_lbl)

		var v_lbl := Label.new()
		v_lbl.text = "---"
		v_lbl.add_theme_font_size_override("font_size", 14)
		info_grid.add_child(v_lbl)
		_debug_labels[key] = v_lbl

	vbox.add_child(HSeparator.new())

	# ── Print Layout 버튼 ──
	var print_btn := Button.new()
	print_btn.text = "[ Print Layout Snapshot ]"
	print_btn.custom_minimum_size = Vector2(0, 44)
	print_btn.add_theme_font_size_override("font_size", 16)
	print_btn.pressed.connect(_print_layout_snapshot)
	vbox.add_child(print_btn)

	vbox.add_child(HSeparator.new())

	# ── 난이도 조절 (DEBUG ONLY) ──
	var s_diff := Label.new()
	s_diff.text = "▸ 난이도 (DEBUG)"
	s_diff.add_theme_font_size_override("font_size", 15)
	s_diff.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(s_diff)

	# DDA 현재 오프셋 + AUTO 단어 수 표시
	var dda_info_lbl := Label.new()
	dda_info_lbl.add_theme_font_size_override("font_size", 13)
	dda_info_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(dda_info_lbl)
	_refresh_dda_info(dda_info_lbl)

	# 단어 수 슬라이더 (0 = AUTO/DDA 사용, 1~12 = 강제 고정)
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 10)
	vbox.add_child(diff_row)

	var diff_name_lbl := Label.new()
	diff_name_lbl.text = "단어 수"
	diff_name_lbl.custom_minimum_size = Vector2(110, 0)
	diff_name_lbl.add_theme_font_size_override("font_size", 16)
	diff_row.add_child(diff_name_lbl)

	var diff_slider := HSlider.new()
	diff_slider.min_value = 0
	diff_slider.max_value = 12
	diff_slider.step     = 1.0
	diff_slider.value    = GameManager.debug_word_count_override
	diff_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diff_slider.custom_minimum_size   = Vector2(0, 32)
	diff_row.add_child(diff_slider)

	var diff_val_lbl := Label.new()
	diff_val_lbl.custom_minimum_size = Vector2(46, 0)
	diff_val_lbl.add_theme_font_size_override("font_size", 16)
	diff_row.add_child(diff_val_lbl)

	# 초기 값 레이블 표시
	if GameManager.debug_word_count_override == 0:
		diff_val_lbl.text = "AUTO"
	else:
		diff_val_lbl.text = str(GameManager.debug_word_count_override)

	diff_slider.value_changed.connect(func(v: float) -> void:
		GameManager.debug_word_count_override = int(v)
		diff_val_lbl.text = "AUTO" if v == 0.0 else str(int(v))
		_refresh_dda_info(dda_info_lbl)
	)

	# "현재 스테이지 재시작" 버튼
	var restart_btn := Button.new()
	restart_btn.text = "[ 현재 스테이지 재시작 ]"
	restart_btn.custom_minimum_size = Vector2(0, 44)
	restart_btn.add_theme_font_size_override("font_size", 15)
	restart_btn.pressed.connect(func() -> void:
		## 1) debug_word_count_override → pending_word_count 반영
		GameManager.request_stage(_current_stage, GameManager.pending_word_pack_path)
		## 2) resume_state 클리어: start_stage()가 저장된 격자를 복원하지 않고 새로 생성하도록
		SaveManager.save_value("resume_state", {})
		_refresh_dda_info(dda_info_lbl)
		start_stage(_current_stage, GameManager.pending_word_pack_path)
	)
	vbox.add_child(restart_btn)

	vbox.add_child(HSeparator.new())

	# ── 계정 초기화 버튼 (DEBUG ONLY) ──
	var reset_btn := Button.new()
	reset_btn.text = "[ 계정 초기화 (재실행) ]"
	reset_btn.custom_minimum_size = Vector2(0, 52)
	reset_btn.add_theme_font_size_override("font_size", 16)
	var reset_style := StyleBoxFlat.new()
	reset_style.bg_color = Color(0.75, 0.1, 0.1)  ## 빨간색 — 위험 버튼 구분
	reset_style.corner_radius_top_left     = 6
	reset_style.corner_radius_top_right    = 6
	reset_style.corner_radius_bottom_left  = 6
	reset_style.corner_radius_bottom_right = 6
	reset_btn.add_theme_stylebox_override("normal",  reset_style)
	reset_btn.add_theme_stylebox_override("pressed", reset_style.duplicate())
	reset_btn.add_theme_color_override("font_color", Color.WHITE)
	reset_btn.pressed.connect(func() -> void:
		SaveManager.reset_data()
		get_tree().reload_current_scene()  ## 씬 재시작 → 온보딩부터 다시 시작
	)
	vbox.add_child(reset_btn)

	# ── ⚙ 토글 버튼 (게임 화면 CanvasLayer에 배치) ──
	var canvas := CanvasLayer.new()
	canvas.layer = 128
	add_child(canvas)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE  ## 전체화면 컨테이너가 GUI 입력을 먹지 않도록
	canvas.add_child(root)

	var toggle_btn := Button.new()
	toggle_btn.text = "⚙"
	toggle_btn.anchor_left   = 1.0
	toggle_btn.anchor_right  = 1.0
	toggle_btn.anchor_top    = 0.0
	toggle_btn.anchor_bottom = 0.0
	toggle_btn.offset_left   = -96.0
	toggle_btn.offset_right  = -4.0
	toggle_btn.offset_top    = 96.0
	toggle_btn.offset_bottom = 144.0
	root.add_child(toggle_btn)

	toggle_btn.pressed.connect(func() -> void:
		win.visible = not win.visible
	)
	_debug_win = win


## 디버그 슬라이더 시그널 연결 헬퍼.
## trigger_layout=false 이면 _update_button_layout() 를 호출하지 않아
## TopBar / AdBanner / Font 슬라이더가 그리드 오버레이를 움직이지 않는다.
func _connect_debug_slider(
		slider: HSlider, prop_name: String, val_lbl: Label,
		trigger_layout: bool = true) -> void:
	slider.value_changed.connect(func(v: float) -> void:
		set(prop_name, v)
		val_lbl.text = ("%.2f" % v) if slider.step < 1.0 else str(int(v))
		_apply_dynamic_layout()
		if trigger_layout and _grid_data != null:
			_update_button_layout()
	)


## DDA 오프셋·AUTO 단어 수 레이블을 갱신한다 (디버그 난이도 섹션용).
func _refresh_dda_info(lbl: Label) -> void:
	var offset: int = GameController._dda.current_offset
	var auto_count: int = GridCalculator.get_word_count(_current_stage)
	lbl.text = "DDA offset: %+d  |  AUTO 단어수: %d (스테이지 %d)" % [
		offset, auto_count, _current_stage
	]


## 디버그 수치 레이블을 최신 레이아웃 값으로 갱신한다.
func _update_debug_info(info: Dictionary) -> void:
	if _debug_labels.is_empty():
		return
	for key: String in info.keys():
		if _debug_labels.has(key):
			(_debug_labels[key] as Label).text = "%.1f" % info[key]


## 현재 레이아웃 파라미터를 Godot 출력창에 스냅샷 형태로 출력한다.
## 출력 결과를 붙여넣기하면 기본값으로 반영할 수 있다.
func _print_layout_snapshot() -> void:
	pass


## GridArea 내 오버레이 노드를 그리드 기준 절대 좌표로 배치한다.
func _set_overlay_rect(node: Control,
		left: float, right: float,
		top: float,  bottom: float) -> void:
	node.anchor_left   = 0.0
	node.anchor_right  = 0.0
	node.anchor_top    = 0.0
	node.anchor_bottom = 0.0
	node.offset_left   = left
	node.offset_right  = right
	node.offset_top    = top
	node.offset_bottom = bottom


## BtnContainer 안의 버튼을 center_x·top_y 기준으로 절대 배치한다.
## center_x = BtnContainer(= BottomActionBar) 너비 기준 위치.
func _set_btn_at(btn: Button, center_x: float, top_y: float, btn_size: float) -> void:
	btn.anchor_left   = 0.0
	btn.anchor_right  = 0.0
	btn.anchor_top    = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left   = center_x - btn_size * 0.5
	btn.offset_right  = center_x + btn_size * 0.5
	btn.offset_top    = top_y
	btn.offset_bottom = top_y + btn_size


## BaseScreen 오버라이드: ScreenManager가 push_screen()할 때 호출된다.
func enter(data: Dictionary = {}) -> void:
	AudioManager.play_bgm("play")
	var is_rest: bool = data.get("is_rest_stage", false)
	if is_rest and OS.is_debug_build():
		print("GameScreen: Bonus Stage! (휴식 스테이지)")

	## 튜토리얼 모드: TutorialManager가 미리 생성한 GridData를 직접 사용한다.
	## 일반 모드: GameManager.pending 값으로 WordPack 로드 후 격자 생성.
	var raw_grid: Variant = data.get("tutorial_grid", null)
	if raw_grid is GridData:
		var tut_stage: int = data.get("tutorial_stage", 1) as int
		call_deferred("start_stage", tut_stage, "", raw_grid as GridData)
	else:
		call_deferred("start_stage", GameManager.pending_stage, GameManager.pending_word_pack_path)


## 스테이지를 시작한다.
## word_pack_path: "res://data/words/ko/animals.json" 형태의 경로.
## prebuilt_grid: 튜토리얼 등에서 격자를 미리 생성해 전달할 때 사용.
##   null이면 word_pack_path로 WordPack을 로드해 격자를 생성한다.
func start_stage(stage: int, word_pack_path: String,
		prebuilt_grid: GridData = null) -> void:
	_current_stage = stage
	SaveManager.set_current_stage(stage)   ## 홈 화면 레벨 표시 동기화
	_hint_count = 0
	_used_hint = false
	_total_score = 0
	_stage_start_time = Time.get_ticks_msec() / 1000.0
	_prev_drag_cells.clear()

	var theme_name: String = ""
	var is_resume: bool = false

	if prebuilt_grid != null:
		# ── 튜토리얼 모드: 미리 생성된 격자 직접 사용 ──
		_grid_data = prebuilt_grid
		theme_name = "Tutorial"
	else:
		# ── 일반 모드: WordPack 로드 후 격자 생성 또는 복원 ──
		var config := GridCalculator.get_stage_config(stage)
		var word_pack := WordPack.load_from_json(word_pack_path)
		if word_pack.entries.is_empty():
			push_error("GameScreen: WordPack이 비어있음 - " + word_pack_path)
			return

		theme_name = word_pack.theme_name

		# 진행 중인 게임 복원 확인
		var resume: Dictionary = SaveManager.load_value("resume_state", {})
		is_resume = (
			not resume.is_empty()
			and resume.get("stage", -1) == stage
			and resume.get("word_pack_path", "") == word_pack_path
			and not (resume.get("grid", {}) as Dictionary).is_empty()
		)

		if is_resume:
			_grid_data = _restore_grid_data(resume.get("grid", {}))
			_total_score = resume.get("score", 0)
			_hint_count = resume.get("hint_count", 0)
			_used_hint = resume.get("used_hint", false)
			var saved_elapsed: float = float(resume.get("elapsed_time", 0.0))
			_stage_start_time = Time.get_ticks_msec() / 1000.0 - saved_elapsed
		else:
			# 단어 선택 (DDA/휴식 스테이지 반영 단어 수 사용)
			var max_len := GridCalculator.get_max_word_length(
				config.width, config.height, word_pack.language
			)
			var selected_words := word_pack.select_words_for_stage(GameManager.pending_word_count, stage, max_len)

			# 격자 생성
			_grid_data = _grid_generator.generate(
				config.width, config.height,
				selected_words, word_pack.language, stage, word_pack
			)

	# HintManager 초기화
	_hint_manager = HintManager.new()
	_hint_manager.setup(_grid_data)
	_hint_manager.hint_activated.connect(_on_hint_activated)
	if is_resume:
		_hint_manager.total_hints_used = _hint_count

	# UI 구성
	stage_label.visible = false
	theme_label.text = "Lv.%d  %s" % [stage, _to_title_case(theme_name)]
	# 배경 이미지 적용: word_pack_path에서 테마 id 추출 ("res://data/words/ko/breakfast.json" → "food")
	if word_pack_path != "":
		var theme_id: String = _extract_theme(word_pack_path)
		_apply_background(theme_id, stage)
	word_bank.setup(_grid_data.placed_words)

	# 실제 가용 영역을 계산하여 build_grid에 전달
	# GridBoard.size(= GridArea 전체)에서 오버레이(배너·워드뱅크·액션바·간격) 빼기
	var grid_area: Vector2 = grid_board.size
	var overlay_h: float = (_lay_banner_h + _lay_inner_gap + _lay_wordbank_h
		+ _lay_gap * 2.0 + 84.0 + _lay_bar_padding)  # 84 = BTN_SIZE
	var available: Vector2 = Vector2(grid_area.x, maxf(grid_area.y - overlay_h, 200.0))
	grid_board.build_grid(_grid_data, available)
	_apply_dynamic_layout()
	_update_button_layout()

	# 복원 시 발견된 단어 UI 반영 + 힌트 시각 상태 재적용
	if is_resume:
		for pw: PlacedWord in _grid_data.placed_words:
			if pw.is_found:
				grid_board.mark_word_found(pw)
				word_bank.mark_found(pw.word)
			elif pw.hint_type != -1:
				pw.is_hinted = true  # 세션 내 중복 힌트 방지 복원
				match pw.hint_type:
					HintType.Type.FIRST_LETTER:
						var cell: LetterCell = grid_board.get_cell_at(pw.cells[0])
						if cell:
							cell.set_visual_state(LetterCell.VisualState.HINT)
					HintType.Type.DIRECTION_SHOW:
						var cell: LetterCell = grid_board.get_cell_at(pw.cells[0])
						if cell:
							cell.set_hint_direction(pw.direction)
					# MAGNIFIER: 임시 효과이므로 복원 불필요

	_update_hint_buttons()

	# 입력 핸들러 초기화
	if _input_handler:
		_input_handler.queue_free()
	if _input_handler_tv:
		_input_handler_tv.queue_free()

	_input_handler = GridInputHandler.new()
	add_child(_input_handler)
	_input_handler.setup(grid_board, _grid_data)
	_input_handler.drag_started.connect(_on_drag_started)
	_input_handler.drag_updated.connect(_on_drag_updated)
	_input_handler.drag_ended.connect(_on_drag_ended)
	_input_handler.drag_cancelled.connect(_on_drag_cancelled)
	_input_handler.cell_tapped.connect(_on_cell_tapped)
	_input_handler.hover_changed.connect(_on_hover_changed)

	_input_handler_tv = GridInputHandlerTV.new()
	add_child(_input_handler_tv)
	_input_handler_tv.setup(grid_board, _grid_data)
	_input_handler_tv.word_selected.connect(_on_drag_ended)

	# ── Banner ad: show from Lv.5 onward ──
	AdManager.show_banner(_current_stage)


# ===== 입력 이벤트 처리 =====

func _on_drag_started(start_cell: Vector2i) -> void:
	_prev_drag_cells.clear()
	_drag_color_index = randi() % LetterCell.FOUND_COLORS.size()
	var cell := grid_board.get_cell_at(start_cell)
	if cell:
		cell.set_visual_state(LetterCell.VisualState.DRAGGING, _drag_color_index)
	_prev_drag_cells = [start_cell]
	AudioManager.play_cell_select()


func _on_drag_updated(cells: Array) -> void:
	grid_board.highlight_drag(cells, _prev_drag_cells, _drag_color_index)
	_prev_drag_cells = cells.duplicate()


func _on_drag_ended(cells: Array) -> void:
	# 단어 매칭 판정
	var matched := _check_word_match(cells)
	if matched:
		matched.is_found = true
		matched.color_index = _drag_color_index
		_animate_word_found(matched)
		word_bank.mark_found(matched.word)
		AudioManager.play_word_found()

		# 힌트 이력에서 제거 후 버튼 상태 갱신
		if _hint_manager:
			_hint_manager.on_word_found(matched)
			_update_hint_buttons()

		var score := _calculate_score(matched.display.length())
		_total_score += score
		word_found.emit(matched)

		if _grid_data.is_all_found():
			_on_stage_complete()
		else:
			_save_progress()
	else:
		grid_board.clear_drag_highlight(cells)
		AudioManager.play_sfx("word_wrong")

	_prev_drag_cells.clear()


## 단어 발견 시 셀을 0.1s 간격으로 순차 FOUND 전환한다.
func _animate_word_found(placed_word: PlacedWord) -> void:
	for i: int in placed_word.cells.size():
		get_tree().create_timer(i * 0.1).timeout.connect(
			func() -> void: grid_board.mark_cell_found(placed_word.cells[i], placed_word.color_index),
			CONNECT_ONE_SHOT
		)


func _on_drag_cancelled() -> void:
	grid_board.clear_drag_highlight(_prev_drag_cells)
	_prev_drag_cells.clear()


func _on_cell_tapped(_pos: Vector2i) -> void:
	pass


func _on_hover_changed(_pos: Vector2i) -> void:
	pass


# ===== 단어 매칭 =====

func _check_word_match(selected_cells: Array) -> PlacedWord:
	for pw: PlacedWord in _grid_data.placed_words:
		if pw.is_found:
			continue
		if _cells_equal(selected_cells, pw.cells):
			return pw
		var reversed_cells: Array[Vector2i] = pw.cells.duplicate()
		reversed_cells.reverse()
		if _cells_equal(selected_cells, reversed_cells):
			return pw
	return null


## 두 셀 배열이 동일한지 원소별로 비교한다.
func _cells_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i: int in range(a.size()):
		if a[i] != b[i]:
			return false
	return true


# ===== 점수 계산 =====

func _calculate_score(word_length: int) -> int:
	var current_time := Time.get_ticks_msec() / 1000.0
	var is_combo := (current_time - _last_found_time) <= COMBO_WINDOW
	_last_found_time = current_time

	var base_score: int = 50 + (word_length * 10)
	if is_combo:
		base_score = int(base_score * 1.5)
	return base_score


# ===== 스테이지 완료 =====

func _on_stage_complete() -> void:
	var clear_time: float = (Time.get_ticks_msec() / 1000.0) - _stage_start_time

	# 노힌트 보너스
	if not _used_hint:
		_total_score += 100

	# 등급 판정
	var grade: String     = _evaluate_grade(_hint_count, clear_time)
	var multiplier: float = _get_grade_multiplier(grade)
	var final_score: int  = int(_total_score * multiplier)

	SaveManager.set_current_stage(_current_stage + 1)   ## 다음 플레이 스테이지로 전진
	SaveManager.save_value("resume_state", {})
	AudioManager.play_sfx("stage_clear")

	# 힌트 티켓 지급 (스테이지 번호 기반)
	HintTicketManager.add_on_clear(_current_stage)

	print("Stage %d Clear! Score: %d, Grade: %s" % [
		_current_stage, final_score, grade
	])

	# Analytics: 스테이지 클리어 이벤트
	AnalyticsManager.log_level_complete(
		_current_stage,
		_grid_data.placed_words.size(),
		clear_time,
		_hint_count
	)

	stage_cleared.emit(_current_stage, final_score, grade)

	# 튜토리얼 모드: TutorialManager가 다음 단계를 제어한다.
	if TutorialManager.is_in_tutorial():
		TutorialManager.on_tutorial_stage_cleared(
			TutorialManager.get_current_tutorial_stage()
		)
		return

	# GameResult 생성 후 DDA·통계 기록 (화면 전환 없음)
	var result := GameResult.new()
	result.stage          = _current_stage
	result.score          = final_score
	result.grade          = grade
	result.coins_earned   = 0
	result.hint_count     = _hint_count
	result.clear_time     = clear_time
	result.word_pack_path = GameManager.pending_word_pack_path
	GameController.record_complete(result)

	# ── 인게임 클리어 팝업 표시 ──
	_stage_complete_popup.show_popup(_current_stage)
	await _stage_complete_popup.next_pressed

	# ── Interstitial ad check (every N stages, after Lv.5) ──
	AdManager.on_stage_cleared()
	if AdManager.try_show_interstitial(_current_stage):
		await AdManager.interstitial_ad_closed

	# 버튼 탭 즉시: fade_rect(layer=11)가 팝업+화면을 한번에 덮어 자연스럽게 전환
	await _fade_out()
	_stage_complete_popup.visible = false   ## 검정 아래에서 즉시 숨김

	# 다음 스테이지 준비
	var next_stage: int   = _current_stage + 1
	var next_pack: String = ThemeRandomizer.pick(SaveManager.get_last_theme())
	SaveManager.set_last_theme(ThemeRandomizer.extract_theme(next_pack))
	var word_count: int   = GameController.get_next_word_count(next_stage)
	GameManager.request_stage(next_stage, next_pack, word_count)

	# 다음 스테이지 로드 (같은 GameScreen 인스턴스 재사용)
	start_stage(next_stage, next_pack)

	# 페이드 인
	await _fade_in()


func _evaluate_grade(hint_count: int, clear_time: float) -> String:
	if hint_count == 0 and clear_time < 90.0:
		return "S"
	elif hint_count == 0:
		return "A"
	elif hint_count == 1:
		return "B"
	return "C"


func _get_grade_multiplier(grade: String) -> float:
	match grade:
		"S": return 2.0
		"A": return 1.5
		"B": return 1.0
		"C": return 0.8
	return 1.0


# ===== 힌트 =====

func _on_first_letter_pressed() -> void:
	var action: Callable = func() -> void:
		if not _hint_manager.can_use_hint(HintType.Type.FIRST_LETTER):
			return  # No unhinted words left — do nothing, keep ticket.
		if HintTicketManager.first_letter_tickets > 0:
			if HintTicketManager.use_first_letter():
				_hint_manager.use_hint(HintType.Type.FIRST_LETTER)
				AnalyticsManager.log_hint_used("first_letter", "ticket")
		else:
			_request_ad_hint(HintType.Type.FIRST_LETTER)
	_try_hint_with_intro("hint_intro_fl", HintType.Type.FIRST_LETTER, action)


func _on_full_reveal_pressed() -> void:
	var action: Callable = func() -> void:
		if not _hint_manager.can_use_hint(HintType.Type.FULL_REVEAL):
			return  # No unfound words left — do nothing, keep ticket.
		if HintTicketManager.reveal_tickets > 0:
			if HintTicketManager.use_reveal():
				_hint_manager.use_hint(HintType.Type.FULL_REVEAL)
				AnalyticsManager.log_hint_used("full_reveal", "ticket")
		else:
			_request_ad_hint(HintType.Type.FULL_REVEAL)
	_try_hint_with_intro("hint_intro_rv", HintType.Type.FULL_REVEAL, action)


## 최초 사용 시 설명 팝업을 보여준 뒤 on_confirmed를 실행한다.
## 이미 본 경우에는 팝업 없이 즉시 실행.
func _try_hint_with_intro(save_key: String, type: int, on_confirmed: Callable) -> void:
	if SaveManager.load_value(save_key, false):
		on_confirmed.call()
		return
	_show_hint_intro_popup(type, func() -> void:
		SaveManager.save_value(save_key, true)
		on_confirmed.call()
	)


## 힌트 최초 사용 안내 팝업.
## type: HintType.Type.FIRST_LETTER 또는 FULL_REVEAL
func _show_hint_intro_popup(type: int, on_confirmed: Callable) -> void:
	var is_fl: bool = (type == HintType.Type.FIRST_LETTER)

	# ── CanvasLayer → 풀스크린 루트 Control ──
	var layer := CanvasLayer.new()
	layer.layer = 12
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)

	# ── 반투명 배경 ──
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.60)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bg)

	# ── CenterContainer: card를 screen 정중앙에 배치 ──
	var center_wrap := CenterContainer.new()
	center_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center_wrap)

	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color       = Color("#1A1032")
	card_style.border_color   = Color(0.55, 0.35, 0.95, 0.9)
	card_style.border_width_left   = 2
	card_style.border_width_right  = 2
	card_style.border_width_top    = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left     = 28
	card_style.corner_radius_top_right    = 28
	card_style.corner_radius_bottom_left  = 28
	card_style.corner_radius_bottom_right = 28
	card_style.content_margin_left   = 72
	card_style.content_margin_right  = 72
	card_style.content_margin_top    = 66
	card_style.content_margin_bottom = 66
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(780, 0)
	center_wrap.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 42)
	card.add_child(vb)

	# ── 힌트 타입 시각화 (글자 셀 그래픽) ──
	var cell_row := HBoxContainer.new()
	cell_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cell_row.add_theme_constant_override("separation", 15)
	vb.add_child(cell_row)

	var cell_colors: Array[Color] = []
	var cell_texts:  Array[String] = []
	if is_fl:
		cell_colors = [Color(0.55, 0.35, 0.95), Color(0.18, 0.12, 0.30), Color(0.18, 0.12, 0.30)]
		cell_texts  = ["A", "?", "?"]
	else:
		cell_colors = [Color(0.55, 0.35, 0.95), Color(0.55, 0.35, 0.95), Color(0.55, 0.35, 0.95)]
		cell_texts  = ["A", "B", "C"]

	for ci: int in range(3):
		var cell := PanelContainer.new()
		var cs := StyleBoxFlat.new()
		cs.bg_color = cell_colors[ci]
		cs.corner_radius_top_left     = 10
		cs.corner_radius_top_right    = 10
		cs.corner_radius_bottom_left  = 10
		cs.corner_radius_bottom_right = 10
		cs.content_margin_left   = 27
		cs.content_margin_right  = 27
		cs.content_margin_top    = 21
		cs.content_margin_bottom = 21
		cell.add_theme_stylebox_override("panel", cs)
		cell.custom_minimum_size = Vector2(108, 108)
		var cl := Label.new()
		cl.text = cell_texts[ci]
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		cl.add_theme_font_size_override("font_size", 48)
		cl.add_theme_color_override("font_color",
			Color.WHITE if cell_colors[ci].v > 0.2 else Color(0.4, 0.3, 0.6))
		cell.add_child(cl)
		cell_row.add_child(cell)

	# ── 설명 문구 ──
	var desc := Label.new()
	desc.text = "Reveals the first letter only." if is_fl else "Reveals the full word."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_override("font", FONT_UI)
	desc.add_theme_font_size_override("font_size", 42)
	desc.add_theme_color_override("font_color", Color(0.88, 0.82, 1.0))
	vb.add_child(desc)

	var sub := Label.new()
	sub.text = "Would you like to use it?"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", FONT_UI)
	sub.add_theme_font_size_override("font_size", 33)
	sub.add_theme_color_override("font_color", Color(0.65, 0.60, 0.80))
	vb.add_child(sub)

	# ── 버튼 행 ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 24)
	vb.add_child(btn_row)

	var _make_btn: Callable = func(label: String, bg_col: Color) -> Button:
		var b := Button.new()
		b.text = label
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 114)
		b.add_theme_font_size_override("font_size", 42)
		var st := StyleBoxFlat.new()
		st.bg_color = bg_col
		st.corner_radius_top_left     = 16
		st.corner_radius_top_right    = 16
		st.corner_radius_bottom_left  = 16
		st.corner_radius_bottom_right = 16
		b.add_theme_stylebox_override("normal",  st)
		var st_h: StyleBoxFlat = st.duplicate() as StyleBoxFlat
		st_h.bg_color = bg_col.lightened(0.1)
		b.add_theme_stylebox_override("hover",   st_h)
		var st_p: StyleBoxFlat = st.duplicate() as StyleBoxFlat
		st_p.bg_color = bg_col.darkened(0.15)
		b.add_theme_stylebox_override("pressed", st_p)
		b.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
		b.add_theme_color_override("font_color", Color.WHITE)
		return b

	var no_btn:  Button = _make_btn.call("No",  Color("#2E2244"))
	var yes_btn: Button = _make_btn.call("Yes", Color(0.38, 0.25, 0.75))
	btn_row.add_child(no_btn)
	btn_row.add_child(yes_btn)

	# ── 팝 인 애니메이션 ──
	card.scale = Vector2(0.80, 0.80)
	card.pivot_offset = card.custom_minimum_size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK)
	tw.tween_property(bg,   "color:a", 0.60, 0.15)

	# ── 콜백 ──
	no_btn.pressed.connect(func() -> void:
		layer.queue_free()
	)
	yes_btn.pressed.connect(func() -> void:
		layer.queue_free()
		on_confirmed.call()
	)


## 티켓 소진 시 광고 다이얼로그를 표시한다.
## 유저가 "광고 보기"를 누르면 티켓 1회 즉시 지급 후 힌트 사용.
## AdManager가 실제 광고 SDK와 연동될 때 _grant_ad_hint() 내부만 교체하면 된다.
func _request_ad_hint(type: int) -> void:
	var hint_name: String = "First Letter" if type == HintType.Type.FIRST_LETTER else "Full Reveal"
	_show_ad_confirm_dialog(hint_name, func() -> void: _grant_ad_hint(type))


## 광고 확인 다이얼로그 (CanvasLayer layer=12 — 페이드·팝업 위).
## on_confirm 콜백: "광고 보기" 버튼 탭 시 호출.
func _show_ad_confirm_dialog(hint_name: String, on_confirm: Callable) -> void:
	# Disable grid input while popup is open
	if _input_handler:
		_input_handler.set_process_input(false)
	if _input_handler_tv:
		_input_handler_tv.set_process_input(false)

	# ── CanvasLayer ──
	var layer := CanvasLayer.new()
	layer.layer = 12
	add_child(layer)

	# ── 반투명 배경 ──
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(bg)

	# ── 중앙 카드 ──
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#1E1E1E")
	card_style.corner_radius_top_left     = 24
	card_style.corner_radius_top_right    = 24
	card_style.corner_radius_bottom_left  = 24
	card_style.corner_radius_bottom_right = 24
	card_style.content_margin_left   = 60
	card_style.content_margin_right  = 60
	card_style.content_margin_top    = 54
	card_style.content_margin_bottom = 54
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(750, 0)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(center)
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 36)
	card.add_child(vb)

	# 아이콘 + 제목
	var title_lbl := Label.new()
	title_lbl.text = "📺  Watch Ad"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", _get_title_font())
	title_lbl.add_theme_font_size_override("font_size", 48)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(title_lbl)

	# 안내 문구
	var desc_lbl := Label.new()
	desc_lbl.text = "Watch a short ad to receive\n1x [%s] hint." % hint_name
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_override("font", FONT_UI)
	desc_lbl.add_theme_font_size_override("font_size", 36)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc_lbl)

	vb.add_child(HSeparator.new())

	# 버튼 행
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 24)
	vb.add_child(btn_row)

	# 취소 버튼
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.custom_minimum_size = Vector2(0, 108)
	cancel_btn.add_theme_font_size_override("font_size", 36)
	var cancel_style := StyleBoxFlat.new()
	cancel_style.bg_color = Color("#333333")
	cancel_style.corner_radius_top_left     = 14
	cancel_style.corner_radius_top_right    = 14
	cancel_style.corner_radius_bottom_left  = 14
	cancel_style.corner_radius_bottom_right = 14
	cancel_btn.add_theme_stylebox_override("normal",  cancel_style)
	cancel_btn.add_theme_stylebox_override("hover",   cancel_style.duplicate())
	cancel_btn.add_theme_stylebox_override("pressed", cancel_style.duplicate())
	cancel_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	cancel_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	btn_row.add_child(cancel_btn)

	# 광고 보기 버튼
	var watch_btn := Button.new()
	watch_btn.text = "Watch Ad  ▶"
	watch_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	watch_btn.custom_minimum_size = Vector2(0, 108)
	watch_btn.add_theme_font_size_override("font_size", 36)
	var watch_style := StyleBoxFlat.new()
	watch_style.bg_color = Color(0.38, 0.25, 0.75, 1.0)
	watch_style.corner_radius_top_left     = 14
	watch_style.corner_radius_top_right    = 14
	watch_style.corner_radius_bottom_left  = 14
	watch_style.corner_radius_bottom_right = 14
	watch_btn.add_theme_stylebox_override("normal",  watch_style)
	var watch_hover := watch_style.duplicate() as StyleBoxFlat
	watch_hover.bg_color = Color(0.38, 0.25, 0.75, 1.0).lightened(0.1)
	watch_btn.add_theme_stylebox_override("hover",   watch_hover)
	var watch_press := watch_style.duplicate() as StyleBoxFlat
	watch_press.bg_color = Color(0.38, 0.25, 0.75, 1.0).darkened(0.15)
	watch_btn.add_theme_stylebox_override("pressed", watch_press)
	watch_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	watch_btn.add_theme_color_override("font_color", Color.WHITE)
	btn_row.add_child(watch_btn)

	# ── 팝 인 애니메이션 ──
	card.scale = Vector2(0.85, 0.85)
	card.pivot_offset = card.custom_minimum_size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_property(bg, "color:a", 0.55, 0.15)

	# ── 버튼 콜백 ──
	var _restore_input := func() -> void:
		if _input_handler:
			_input_handler.set_process_input(true)
		if _input_handler_tv:
			_input_handler_tv.set_process_input(true)

	cancel_btn.pressed.connect(func() -> void:
		layer.queue_free()
		_restore_input.call()
	)
	watch_btn.pressed.connect(func() -> void:
		layer.queue_free()
		_restore_input.call()
		on_confirm.call()
	)


## Shows a rewarded ad, then grants 1 hint ticket on completion.
## If the ad fails or the user cancels, no hint is granted.
func _grant_ad_hint(type: int) -> void:
	var reward_type: String = "first_letter" if type == HintType.Type.FIRST_LETTER else "full_reveal"

	var _on_reward := func(r_type: String, _amount: int) -> void:
		if r_type != reward_type:
			return
		# Stack mode: grant ticket only, don't use immediately.
		# User taps the hint button again to consume the ticket.
		if type == HintType.Type.FIRST_LETTER:
			HintTicketManager.grant(1, 0)
		else:
			HintTicketManager.grant(0, 1)
		_update_hint_buttons()
		# Analytics: 보상형 광고 시청 이벤트
		AnalyticsManager.log_ad_watched("rewarded", reward_type)

	# Disconnect any stale one-shot listeners before connecting new ones.
	if AdManager.rewarded_ad_completed.is_connected(_on_reward):
		AdManager.rewarded_ad_completed.disconnect(_on_reward)

	AdManager.rewarded_ad_completed.connect(_on_reward, CONNECT_ONE_SHOT)
	AdManager.show_rewarded_ad(reward_type)


func _on_hint_activated(type: int, word: PlacedWord, cells: Array[Vector2i]) -> void:
	_hint_count = _hint_manager.total_hints_used
	_used_hint = true
	AudioManager.play_sfx("hint")

	match type:
		HintType.Type.FIRST_LETTER:
			var cell: LetterCell = grid_board.get_cell_at(cells[0])
			if cell:
				cell.set_visual_state(LetterCell.VisualState.HINT)

		HintType.Type.DIRECTION_SHOW:
			var cell: LetterCell = grid_board.get_cell_at(cells[0])
			if cell:
				cell.set_hint_direction(word.direction)

		HintType.Type.MAGNIFIER:
			_clear_magnifier_highlight()
			_magnifier_cells = cells.duplicate()
			for pos: Vector2i in _magnifier_cells:
				var cell: LetterCell = grid_board.get_cell_at(pos)
				if cell and not cell.get_visual_state() == LetterCell.VisualState.FOUND:
					cell.set_visual_state(LetterCell.VisualState.HINT)
			get_tree().create_timer(HintManager.MAGNIFIER_DURATION).timeout.connect(
				_on_magnifier_timer_expired
			)

		HintType.Type.FULL_REVEAL:
			word.color_index = randi() % LetterCell.FOUND_COLORS.size()
			grid_board.mark_word_found(word)
			word_bank.mark_found(word.word)
			if _grid_data.is_all_found():
				_on_stage_complete()
			else:
				_save_progress()

		HintType.Type.TIMER_EXTEND:
			pass  # Time Attack 모드 전용 — 현재 미구현

	_update_hint_buttons()


func _on_magnifier_timer_expired() -> void:
	_clear_magnifier_highlight()


func _clear_magnifier_highlight() -> void:
	for pos: Vector2i in _magnifier_cells:
		var cell: LetterCell = grid_board.get_cell_at(pos)
		if cell and not cell.get_visual_state() == LetterCell.VisualState.FOUND:
			cell.set_visual_state(LetterCell.VisualState.IDLE)
	_magnifier_cells.clear()


# ===== 셔플 =====

func _on_shuffle_pressed() -> void:
	if not _hint_manager.use_shuffle():
		return
	AudioManager.play_sfx("shuffle")
	var word_cells: Dictionary = {}
	for pw: PlacedWord in _grid_data.placed_words:
		for cell: Vector2i in pw.cells:
			word_cells[cell] = true

	var free_positions: Array[Vector2i] = []
	var free_chars: Array[String] = []
	for y: int in range(_grid_data.height):
		for x: int in range(_grid_data.width):
			var pos := Vector2i(x, y)
			if not word_cells.has(pos):
				free_positions.append(pos)
				free_chars.append(_grid_data.grid[y][x])

	for i: int in range(free_chars.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: String = free_chars[i]
		free_chars[i] = free_chars[j]
		free_chars[j] = tmp

	for idx: int in range(free_positions.size()):
		var pos: Vector2i = free_positions[idx]
		_grid_data.grid[pos.y][pos.x] = free_chars[idx]
		var cell: LetterCell = grid_board.get_cell_at(pos)
		if cell:
			cell.set_letter(free_chars[idx])

	_update_hint_buttons()


# ===== 스텁 버튼 핸들러 =====

func _on_settings_pressed() -> void:
	_show_settings_popup()



func _on_daily_pressed() -> void:
	pass  # TODO: 데일리 보너스

func _on_task_pressed() -> void:
	pass  # TODO: 임무 목록

func _on_gift_pressed() -> void:
	pass  # TODO: 보상형 광고 → 무료 힌트


# ===== UI 갱신 =====

## 힌트 버튼 상태를 갱신한다.
## 슬롯 셀 중앙에 남은 횟수 표시.
## 티켓 소진 시 "📺" 표시 → 탭하면 광고 시청.
func _update_hint_buttons() -> void:
	if _hint_manager == null:
		return
	var available: bool = _hint_manager.has_hints_available()

	var fl: int = HintTicketManager.first_letter_tickets
	hint_button.disabled = (fl > 0) and (not available)
	if _hint_count_first:
		_hint_count_first.text = str(fl) if fl > 0 else "📺"

	var rv: int = HintTicketManager.reveal_tickets
	power_hint_button.disabled = (rv > 0) and (not available)
	if _hint_count_full:
		_hint_count_full.text = str(rv) if rv > 0 else "📺"

	# 현재 비활성화 예정 버튼: 코드에서도 강제 비활성 유지
	shuffle_button.disabled = true
	daily_button.disabled   = true
	task_button.disabled    = true
	gift_button.disabled    = true


# ===== 뒤로가기 =====

func _on_back_pressed() -> void:
	AdManager.hide_banner()
	_save_progress()
	GameController.return_to_home()


# ===== 진행 저장 / 복원 =====

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_WM_CLOSE_REQUEST:
			_save_progress()


func _save_progress() -> void:
	if _grid_data == null:
		return
	if _grid_data.is_all_found():
		return
	var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _stage_start_time
	SaveManager.save_value("resume_state", {
		"stage": _current_stage,
		"word_pack_path": GameManager.pending_word_pack_path,
		"score": _total_score,
		"hint_count": _hint_count,
		"used_hint": _used_hint,
		"elapsed_time": elapsed,
		"grid": _serialize_grid_data(_grid_data),
	})


func _serialize_grid_data(gd: GridData) -> Dictionary:
	var words_list: Array = []
	for pw: PlacedWord in gd.placed_words:
		var cells_list: Array = []
		for c: Vector2i in pw.cells:
			cells_list.append([c.x, c.y])
		words_list.append({
			"word": pw.word,
			"display": pw.display,
			"start_pos": [pw.start_pos.x, pw.start_pos.y],
			"direction": [pw.direction.x, pw.direction.y],
			"is_found": pw.is_found,
			"hint_type": pw.hint_type,
			"cells": cells_list,
			"category": pw.category,
			"color_index": pw.color_index,
		})
	var grid_rows: Array = []
	for row: Array in gd.grid:
		var row_arr: Array = []
		for cell: String in row:
			row_arr.append(cell)
		grid_rows.append(row_arr)
	return {
		"width": gd.width,
		"height": gd.height,
		"language": gd.language,
		"grid": grid_rows,
		"placed_words": words_list,
	}


func _restore_grid_data(data: Dictionary) -> GridData:
	var gd := GridData.new()
	gd.width = data.get("width", 0)
	gd.height = data.get("height", 0)
	gd.language = data.get("language", "ko")
	gd.stage = _current_stage
	gd.grid = data.get("grid", [])
	for pw_data: Dictionary in data.get("placed_words", []):
		var pw := PlacedWord.new()
		pw.word = pw_data.get("word", "")
		pw.display = pw_data.get("display", "")
		var sp: Array = pw_data.get("start_pos", [0, 0])
		pw.start_pos = Vector2i(int(sp[0]), int(sp[1]))
		var dir: Array = pw_data.get("direction", [1, 0])
		pw.direction = Vector2i(int(dir[0]), int(dir[1]))
		pw.is_found = pw_data.get("is_found", false)
		pw.hint_type = pw_data.get("hint_type", -1)
		pw.category = pw_data.get("category", "")
		pw.color_index = pw_data.get("color_index", -1)
		var cells_list: Array = pw_data.get("cells", [])
		var cells: Array[Vector2i] = []
		for c: Array in cells_list:
			cells.append(Vector2i(int(c[0]), int(c[1])))
		pw.cells = cells
		gd.placed_words.append(pw)
	return gd


# ===== 설정 팝업 =====

## ⚙ 설정 버튼 탭 시 호출. BGM/SFX 토글+슬라이더, 문의, 약관을 제공한다.
## CanvasLayer layer=15 (광고 다이얼로그(12) 위, 페이드/팝업(10/11) 위).
func _show_settings_popup() -> void:
	# ── 레이어 ──
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)

	# ── 전체화면 루트 (STOP: block all input from reaching lower layers) ──
	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root_ctrl)

	# ── 반투명 배경 ──
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root_ctrl.add_child(bg)

	# ── 중앙 정렬 컨테이너 ──
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(center)

	# ── 카드 ──
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color("#1A1A2E")
	cs.corner_radius_top_left     = 24
	cs.corner_radius_top_right    = 24
	cs.corner_radius_bottom_left  = 24
	cs.corner_radius_bottom_right = 24
	cs.content_margin_left   = 54
	cs.content_margin_right  = 54
	cs.content_margin_top    = 42
	cs.content_margin_bottom = 42
	card.add_theme_stylebox_override("panel", cs)
	card.custom_minimum_size = Vector2(720, 0)
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 27)
	card.add_child(vb)

	# ── 헤더 (제목 + 닫기 버튼) ──
	var header := HBoxContainer.new()
	vb.add_child(header)

	var title_lbl := Label.new()
	title_lbl.text = "⚙  Settings"
	title_lbl.add_theme_font_override("font", _get_title_font())
	title_lbl.add_theme_font_size_override("font_size", 45)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(78, 78)
	close_btn.add_theme_font_size_override("font_size", 30)
	close_btn.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	close_btn.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	close_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	close_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	close_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	header.add_child(close_btn)

	vb.add_child(HSeparator.new())

	# ── 배경음악 섹션 ──
	_settings_add_audio_section(
		vb, "🎵  BGM",
		AudioManager.get_music_enabled(),
		AudioManager.get_music_volume(),
		func(en: bool) -> void: AudioManager.set_music_enabled(en),
		func(v: float)  -> void: AudioManager.set_music_volume(v)
	)

	vb.add_child(HSeparator.new())

	# ── SFX section ──
	_settings_add_audio_section(
		vb, "🔊  SFX",
		AudioManager.get_sfx_enabled(),
		AudioManager.get_sfx_volume(),
		func(en: bool) -> void: AudioManager.set_sfx_enabled(en),
		func(v: float)  -> void: AudioManager.set_sfx_volume(v)
	)

	vb.add_child(HSeparator.new())

	# ── 개인정보처리방침 버튼 ──
	var privacy_btn: Button = _settings_make_link_button("🔒  Privacy Policy")
	privacy_btn.pressed.connect(func() -> void:
		OS.shell_open(AdConfig.PRIVACY_POLICY_URL)
	)
	vb.add_child(privacy_btn)

	# ── 이용약관 버튼 ──
	var terms_btn: Button = _settings_make_link_button("📋  Terms of Service")
	terms_btn.pressed.connect(func() -> void:
		OS.shell_open(AdConfig.TERMS_OF_SERVICE_URL)
	)
	vb.add_child(terms_btn)

	# ── 문의하기 버튼 ──
	var contact_btn: Button = _settings_make_link_button("📧  Contact Developer")
	contact_btn.pressed.connect(func() -> void:
		OS.shell_open("mailto:wordpuzzle.game.dev@gmail.com")
	)
	vb.add_child(contact_btn)

	# ── Pop-in animation ──
	card.scale        = Vector2(0.85, 0.85)
	card.pivot_offset = card.custom_minimum_size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "scale",   Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_property(bg,   "color:a", 0.55,        0.15)

	# 닫기 버튼 & 배경 탭 → 팝업 닫기 (state[0]으로 중복 호출 방지)
	var state: Array = [false]  # [is_closing] — array to allow lambda mutation
	var close_func: Callable = func() -> void:
		if state[0]:
			return
		state[0] = true
		var tw2 := create_tween()
		tw2.tween_property(bg, "color:a", 0.0, 0.12)
		await tw2.finished
		layer.queue_free()
	close_btn.pressed.connect(close_func)
	bg.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and not state[0]:
			close_func.call()
	)


## 오디오 섹션 1개 (레이블+토글 행 + 볼륨 슬라이더) 를 vb에 추가한다.
func _settings_add_audio_section(
		vb: VBoxContainer, section_label: String,
		is_enabled: bool, volume: float,
		on_toggle: Callable, on_volume: Callable) -> void:
	# 레이블 + 토글 행
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)

	var lbl := Label.new()
	lbl.text = section_label
	lbl.add_theme_font_size_override("font_size", 33)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var toggle := CheckButton.new()
	toggle.button_pressed = is_enabled
	toggle.custom_minimum_size = Vector2(108, 0)
	row.add_child(toggle)

	# 볼륨 슬라이더
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step      = 0.02
	slider.value     = volume
	slider.editable  = is_enabled
	slider.modulate  = Color(1.0, 1.0, 1.0, 1.0 if is_enabled else 0.35)
	slider.custom_minimum_size   = Vector2(0, 57)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(slider)

	# 토글 ↔ 슬라이더 연동
	toggle.toggled.connect(func(pressed: bool) -> void:
		slider.editable = pressed
		slider.modulate = Color(1.0, 1.0, 1.0, 1.0 if pressed else 0.35)
		on_toggle.call(pressed)
	)
	slider.value_changed.connect(func(v: float) -> void:
		on_volume.call(v)
	)


## 화살표(→) 포함 링크 스타일 버튼을 반환한다 (문의·약관 항목용).
func _settings_make_link_button(text_val: String) -> Button:
	var btn := Button.new()
	btn.text = text_val + "   →"
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 93)
	btn.add_theme_font_size_override("font_size", 30)
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#252538")
	st.corner_radius_top_left     = 12
	st.corner_radius_top_right    = 12
	st.corner_radius_bottom_left  = 12
	st.corner_radius_bottom_right = 12
	st.content_margin_left   = 30
	st.content_margin_right  = 30
	st.content_margin_top    = 0
	st.content_margin_bottom = 0
	var st_hover: StyleBoxFlat = st.duplicate() as StyleBoxFlat
	st_hover.bg_color = Color("#303048")
	var st_press: StyleBoxFlat = st.duplicate() as StyleBoxFlat
	st_press.bg_color = Color("#1E1E30")
	btn.add_theme_stylebox_override("normal",  st)
	btn.add_theme_stylebox_override("hover",   st_hover)
	btn.add_theme_stylebox_override("pressed", st_press)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	return btn


# ===== Ad-remove button (game screen) =====

func _setup_ad_remove_button() -> void:
	if AdManager.is_ads_removed():
		return
	if not _left_btns:
		return
	_ad_remove_btn = Button.new()
	_ad_remove_btn.name = "AdRemoveBtn"
	_ad_remove_btn.text = ""
	_ad_remove_btn.custom_minimum_size = Vector2(_lay_top_btn_size, _lay_top_btn_size)
	_ad_remove_btn.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	_ad_remove_btn.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	_ad_remove_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_ad_remove_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	_left_btns.add_child(_ad_remove_btn)
	# TextureRect inside button — matches button size exactly
	var tex := TextureRect.new()
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/icons/ui/icon_ad_idle.png"):
		tex.texture = load("res://assets/icons/ui/icon_ad_idle.png") as Texture2D
	_ad_remove_btn.add_child(tex)
	_ad_remove_btn.pressed.connect(func() -> void:
		IAPManager.purchase(IAPManager.PRODUCT_REMOVE_ADS)
	)

	# React to ads being removed from anywhere.
	AdManager.ads_removed_changed.connect(func() -> void:
		if _ad_remove_btn:
			_ad_remove_btn.visible = false
		AdManager.hide_banner()
	)
