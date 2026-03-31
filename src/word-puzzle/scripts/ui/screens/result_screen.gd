## result_screen.gd
## Stage clear / fail result screen.
## Receives a GameResult via enter(data) and displays score, grade, and coins.
## - Clear: grade pop animation, Next / Retry / Home buttons
## - Fail: Next button hidden, only Retry / Home shown
class_name ResultScreen
extends BaseScreen


# ===== Node references =====

@onready var new_record_label: Label = $VBoxContainer/NewRecordLabel
@onready var grade_label: Label = $VBoxContainer/GradeLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var coins_label: Label = $VBoxContainer/CoinsLabel
@onready var words_label: Label = $VBoxContainer/WordsLabel
@onready var home_button: Button = $VBoxContainer/ButtonRow/HomeButton
@onready var retry_button: Button = $VBoxContainer/ButtonRow/RetryButton
@onready var next_button: Button = $VBoxContainer/ButtonRow/NextButton


# ===== State =====

var _result: GameResult = null


# ===== Initialization =====

func _ready() -> void:
	home_button.pressed.connect(_on_home_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	next_button.pressed.connect(_on_next_pressed)
	_setup_button_styles()


func _setup_button_styles() -> void:
	## Apply soft purple style to all result screen buttons.
	for btn: Button in [home_button, retry_button, next_button]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.38, 0.25, 0.75, 1.0)
		st.corner_radius_top_left     = 14
		st.corner_radius_top_right    = 14
		st.corner_radius_bottom_left  = 14
		st.corner_radius_bottom_right = 14
		st.content_margin_left   = 20
		st.content_margin_right  = 20
		st.content_margin_top    = 10
		st.content_margin_bottom = 10
		var st_hover: StyleBoxFlat = st.duplicate() as StyleBoxFlat
		st_hover.bg_color = Color(0.38, 0.25, 0.75, 1.0).lightened(0.12)
		var st_press: StyleBoxFlat = st.duplicate() as StyleBoxFlat
		st_press.bg_color = Color(0.38, 0.25, 0.75, 1.0).darkened(0.15)
		btn.add_theme_stylebox_override("normal",  st)
		btn.add_theme_stylebox_override("hover",   st_hover)
		btn.add_theme_stylebox_override("pressed", st_press)
		btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
		btn.add_theme_color_override("font_color", Color.WHITE)


# ===== BaseScreen overrides =====

func enter(data: Dictionary = {}) -> void:
	if data.has("result") and data["result"] is GameResult:
		_result = data["result"] as GameResult
		_refresh_ui()
	else:
		push_error("ResultScreen: No GameResult data provided.")


# ===== UI refresh =====

func _refresh_ui() -> void:
	if _result == null:
		return

	var cleared: bool = _result.is_cleared

	## Show grade; override with F on failure.
	var display_grade: String = _result.grade if cleared else "F"
	grade_label.text = "Grade: %s" % display_grade
	score_label.text = "Score: %d" % _result.score

	## Coins: only shown on clear.
	if cleared:
		coins_label.text = "Coins Earned: +%d" % _result.coins_earned
		coins_label.visible = true
	else:
		coins_label.visible = false

	## Word progress.
	if _result.total_words > 0:
		words_label.text = "Words: %d / %d" % [_result.words_found, _result.total_words]
		words_label.visible = true
	else:
		words_label.visible = false

	## New record banner.
	new_record_label.visible = cleared and _result.is_new_record

	## Hide Next button on failure.
	next_button.visible = cleared

	## Grade pop animation.
	_animate_grade()


func _animate_grade() -> void:
	grade_label.scale = Vector2.ZERO
	var tw: Tween = grade_label.create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(grade_label, "scale", Vector2.ONE, 0.4)


# ===== Button handlers =====

func _on_home_pressed() -> void:
	GameController.return_to_home()


func _on_retry_pressed() -> void:
	if _result == null:
		GameController.return_to_home()
		return
	GameController.start_game(_result.stage)


func _on_next_pressed() -> void:
	if _result == null:
		GameController.return_to_home()
		return
	GameController.start_game(_result.stage + 1)
