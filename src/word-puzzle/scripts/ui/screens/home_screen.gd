## home_screen.gd
## 홈(타이틀) 화면. 플레이 버튼으로 게임을 시작한다.
class_name HomeScreen
extends BaseScreen

const FONT_UI:    Font = preload("res://assets/fonts/Nunito-Variable.ttf")
const _BALOO2_BASE: Font = preload("res://assets/fonts/Baloo2-Variable.ttf")
var _title_font_cache: Font = null

func _get_title_font() -> Font:
	if _title_font_cache == null:
		var fv := FontVariation.new()
		fv.base_font = _BALOO2_BASE
		fv.variation_embolden = 0.3
		_title_font_cache = fv
	return _title_font_cache


# ===== 노드 참조 =====

@onready var play_button:      Button          = $CenterContainer/VBoxContainer/PlayButton
@onready var level_label:      Label           = $CenterContainer/VBoxContainer/LevelBadge/LevelLabel
@onready var level_badge_bg:   TextureRect     = $CenterContainer/VBoxContainer/LevelBadge/BadgeBg
@onready var level_badge:      Control         = $CenterContainer/VBoxContainer/LevelBadge
@onready var title_label:      Label           = $CenterContainer/VBoxContainer/TitleLabel
@onready var vbox:             VBoxContainer   = $CenterContainer/VBoxContainer
@onready var center_container: CenterContainer = $CenterContainer
@onready var settings_button:  Button          = %SettingsButton


# ===== 레이아웃 파라미터 (디버그 슬라이더로 실시간 변경) =====

## ── 각 요소 독립 좌표 (화면 중앙 기준, 양수=오른쪽/아래) ──
var _font_title:    float = 102.0   ## 타이틀 폰트 크기

## 로고 이미지
var _logo_scale: float = 3.0    ## 로고 스케일 (1.0 = 기본 360px 기준)
var _logo_x:     float = 0.0    ## 로고 X (화면 중앙 기준)
var _logo_y:     float = -477.5 ## 로고 Y (화면 중앙 기준)
var _logo_rect:  TextureRect = null
var _logo_base_w: float = 360.0
var _logo_base_h: float = 0.0

## 레벨 배지
var _badge_x:       float = 8.5     ## 배지 X (화면 중앙 기준)
var _badge_y:       float = -116.0  ## 배지 Y (화면 중앙 기준)
var _badge_w:       float = 525.5   ## 배지 너비
var _badge_h:       float = 528.5   ## 배지 높이
var _badge_lbl_y:   float = -8.0    ## 배지 내 라벨 상단 Y
var _font_level:    float = 54.0    ## 레벨 레이블 폰트 크기

## 플레이 버튼
var _play_x:        float = 0.0     ## 버튼 X (화면 중앙 기준)
var _play_y:        float = 177.5   ## 버튼 Y (화면 중앙 기준)
var _btn_h:         float = 162.5   ## 플레이 버튼 높이
var _btn_w:         float = 749.0   ## 플레이 버튼 너비
var _btn_lbl_y:     float = 0.0     ## 버튼 텍스트 Y 오프셋 (양수=아래)
var _font_play:     float = 66.0    ## 플레이 버튼 폰트 크기

## ── Ad-remove button layout ──
var _ad_btn_x:    float = 223.5   ## Ad button X (absolute, left edge)
var _ad_btn_y:    float = 20.5    ## Ad button Y (absolute, top edge)
var _ad_btn_size: float = 160.5   ## Ad button size (same as settings)

## ── 설정 버튼 위치 상수 (game_screen.gd 기본값과 동기화) ──
## 게임 화면 글로벌 좌표 계산:
##   X = BackButton(_lay_top_btn_size=111) + LeftBtns_separation(4) = 115
##   Y = _lay_top_btn_y = 43
##   SIZE = _lay_top_btn_size = 111
const _SETTINGS_BTN_X:    float = 115.0
const _SETTINGS_BTN_Y:    float = 43.0
const _SETTINGS_BTN_SIZE: float = 111.0
## Ad-remove button: placed right of settings button, same size.
const _AD_BTN_GAP: float = 4.0

## 플레이 버튼 StyleBox 참조 (apply_layout에서 마진 업데이트용)
var _sbt_normal:  StyleBoxTexture = null
var _sbt_pressed: StyleBoxTexture = null
var _ad_remove_btn: Button = null


# ===== 초기화 =====

func _ready() -> void:
	_apply_background()
	_setup_level_badge()
	_setup_title_badge()
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	_setup_play_button_style()
	_setup_settings_button_style()
	_setup_ad_remove_button()
	# VBoxContainer에서 분리 → 각 요소를 루트에 절대 배치
	_detach_to_absolute(title_label)
	_detach_to_absolute(level_badge)
	_detach_to_absolute(play_button)
	if _logo_rect:
		_detach_to_absolute(_logo_rect)
	call_deferred("_apply_layout")
	if OS.is_debug_build() and not OS.has_feature("mobile"):
		call_deferred("_setup_debug_panel")


## 레벨 배지 — 이미지 배경 + "Lv. N" 텍스트
func _setup_level_badge() -> void:
	if is_instance_valid(level_badge_bg):
		var tex_path: String = "res://assets/ui/level_badge.png"
		if ResourceLoader.exists(tex_path):
			level_badge_bg.texture = load(tex_path) as Texture2D
	if not is_instance_valid(level_label):
		return
	var tf: Font = preload("res://assets/fonts/BubblegumSans-Regular.ttf")
	level_label.add_theme_font_override("font", tf)
	level_label.add_theme_color_override("font_color", Color("#FFF8E7"))
	## 텍스트 그림자 — 가독성 향상
	level_label.add_theme_constant_override("shadow_offset_x", 2)
	level_label.add_theme_constant_override("shadow_offset_y", 2)
	level_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))


## 타이틀 영역: 로고 이미지가 있으면 사용, 없으면 텍스트 레이블 폴백.
func _setup_title_badge() -> void:
	if not is_instance_valid(title_label):
		return
	const LOGO_PATH: String = "res://assets/illustrations/logo.png"
	if ResourceLoader.exists(LOGO_PATH):
		# 로고 이미지로 교체 — 텍스트 레이블 숨기고 TextureRect 삽입
		title_label.visible = false
		var logo_tex: Texture2D = load(LOGO_PATH) as Texture2D
		var lr := TextureRect.new()
		lr.texture = logo_tex
		# 로고 원본 비율로 높이 자동 계산
		var aspect: float = float(logo_tex.get_height()) / float(logo_tex.get_width())
		_logo_base_h = _logo_base_w * aspect
		lr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lr.custom_minimum_size = Vector2(_logo_base_w, _logo_base_h)
		# title_label 바로 뒤에 삽입 (VBox 순서 유지)
		var parent_node: Control = title_label.get_parent()
		var idx: int = title_label.get_index()
		parent_node.add_child(lr)
		parent_node.move_child(lr, idx + 1)
		_logo_rect = lr
	else:
		# 폴백: 기존 텍스트 + 반투명 배경
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.0, 0.0, 0.0, 0.35)
		st.corner_radius_top_left     = 24
		st.corner_radius_top_right    = 24
		st.corner_radius_bottom_left  = 24
		st.corner_radius_bottom_right = 24
		st.content_margin_left   = 40
		st.content_margin_right  = 40
		st.content_margin_top    = 16
		st.content_margin_bottom = 16
		title_label.add_theme_stylebox_override("normal", st)
		title_label.add_theme_color_override("font_color", Color.WHITE)
		title_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _apply_background() -> void:
	var bg_options: Array[String] = [
		"res://assets/backgrounds/bg_home.webp",
		"res://assets/backgrounds/bg_animals.webp",
		"res://assets/backgrounds/bg_ocean.webp",
		"res://assets/backgrounds/bg_space.webp",
	]
	var bg_node: TextureRect = %Background
	if not is_instance_valid(bg_node):
		return
	for path: String in bg_options:
		if ResourceLoader.exists(path):
			bg_node.texture = load(path) as Texture2D
			return
	# 사용 가능한 배경 이미지가 없어도 오류 없이 계속 진행


# ===== BaseScreen 오버라이드 =====

func enter(_data: Dictionary = {}) -> void:
	_refresh_ui()
	AudioManager.play_bgm("main")
	AnalyticsManager.log_app_open()
	## 연속 출석 보상 체크 — 오늘 첫 방문이면 팝업 표시
	var reward: Dictionary = HintTicketManager.check_and_claim_daily()
	if not reward.is_empty():
		call_deferred("_show_daily_reward_popup", reward)


# ===== UI 갱신 =====

func _refresh_ui() -> void:
	var stage: int = SaveManager.get_current_stage()
	if level_label:
		level_label.text = "Lv. %d" % stage


## 레이아웃 파라미터를 모든 노드에 즉시 반영한다.
## VBoxContainer 자식을 루트(self)로 옮기고 절대 배치 모드로 전환한다.
func _detach_to_absolute(node: Control) -> void:
	var old_parent: Node = node.get_parent()
	if old_parent and old_parent != self:
		old_parent.remove_child(node)
		add_child(node)
	# 앵커: 화면 중앙 기준
	node.anchor_left   = 0.5
	node.anchor_right  = 0.5
	node.anchor_top    = 0.5
	node.anchor_bottom = 0.5
	node.grow_horizontal = Control.GROW_DIRECTION_BOTH
	node.grow_vertical   = Control.GROW_DIRECTION_BOTH
	node.mouse_filter = Control.MOUSE_FILTER_PASS


## 화면 중앙 기준으로 노드를 (cx, cy) 위치에 (w × h) 크기로 배치한다.
func _place_at_center(node: Control, cx: float, cy: float, w: float, h: float) -> void:
	node.offset_left   = cx - w * 0.5
	node.offset_right  = cx + w * 0.5
	node.offset_top    = cy - h * 0.5
	node.offset_bottom = cy + h * 0.5


func _apply_layout() -> void:
	var _vp: Vector2 = get_viewport_rect().size
	# ── 로고 ──
	if _logo_rect:
		var lw: float = _logo_base_w * _logo_scale
		var lh: float = _logo_base_h * _logo_scale
		_place_at_center(_logo_rect, _logo_x, _logo_y, lw, lh)
	if title_label.visible:
		title_label.add_theme_font_size_override("font_size", int(_font_title))

	# ── 레벨 배지 ──
	if is_instance_valid(level_badge):
		_place_at_center(level_badge, _badge_x, _badge_y, _badge_w, _badge_h)
	if is_instance_valid(level_label):
		level_label.add_theme_font_size_override("font_size", int(_font_level))
		level_label.offset_top    = _badge_lbl_y
		level_label.offset_bottom = 0.0

	# ── 플레이 버튼 ──
	_place_at_center(play_button, _play_x, _play_y, _btn_w, _btn_h)
	play_button.add_theme_font_size_override("font_size", int(_font_play))

	## 버튼 텍스트 Y 오프셋 — StyleBoxTexture content_margin_top 조정
	if _sbt_normal:
		_sbt_normal.content_margin_top    = _btn_lbl_y
		_sbt_normal.content_margin_bottom = -_btn_lbl_y
	if _sbt_pressed:
		_sbt_pressed.content_margin_top    = _btn_lbl_y
		_sbt_pressed.content_margin_bottom = -_btn_lbl_y

	## 설정 버튼을 게임 화면 설정 버튼의 월드 포지션에 정확히 배치
	## game_screen.gd: BackButton(111) + separation(4) = X:115, Y:43, SIZE:111
	settings_button.custom_minimum_size = Vector2(_SETTINGS_BTN_SIZE, _SETTINGS_BTN_SIZE)
	settings_button.offset_left   = _SETTINGS_BTN_X
	settings_button.offset_right  = _SETTINGS_BTN_X + _SETTINGS_BTN_SIZE
	settings_button.offset_top    = _SETTINGS_BTN_Y
	settings_button.offset_bottom = _SETTINGS_BTN_Y + _SETTINGS_BTN_SIZE

	## Ad-remove button
	if _ad_remove_btn and _ad_remove_btn.visible:
		_ad_remove_btn.custom_minimum_size = Vector2(_ad_btn_size, _ad_btn_size)
		_ad_remove_btn.offset_left   = _ad_btn_x
		_ad_remove_btn.offset_right  = _ad_btn_x + _ad_btn_size
		_ad_remove_btn.offset_top    = _ad_btn_y
		_ad_remove_btn.offset_bottom = _ad_btn_y + _ad_btn_size


# ===== 연속 출석 보상 팝업 =====

## 연속 출석 보상을 스트릭 캘린더와 함께 카드 팝업으로 표시한다.
## CanvasLayer layer=20 (홈 화면의 모든 요소 위).
## data 키: fl, rv, streak_day, cumulative, milestone_fl, milestone_rv
func _show_daily_reward_popup(data: Dictionary) -> void:
	var fl:          int  = data.get("fl", 0)
	var rv:          int  = data.get("rv", 0)
	var sday:        int  = data.get("streak_day", 1)
	var cumulative:  int  = data.get("cumulative", 1)
	var m_fl:        int  = data.get("milestone_fl", 0)
	var m_rv:        int  = data.get("milestone_rv", 0)
	var has_ms:      bool = m_fl > 0 or m_rv > 0

	# ── 레이어 ──
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	# ── 전체화면 루트 Control ──
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
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#1A1A2E")
	card_style.corner_radius_top_left     = 28
	card_style.corner_radius_top_right    = 28
	card_style.corner_radius_bottom_left  = 28
	card_style.corner_radius_bottom_right = 28
	card_style.content_margin_left   = 40
	card_style.content_margin_right  = 40
	card_style.content_margin_top    = 40
	card_style.content_margin_bottom = 40
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(560, 0)
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	card.add_child(vb)

	# ── 제목 ──
	var title_text: String
	if sday == 7:
		title_text = "★  7-Day Streak Achieved!"
	elif sday == 1:
		title_text = "🎁  Daily Reward"
	else:
		title_text = "🔥  %d-Day Streak!" % sday
	var title_lbl := Label.new()
	title_lbl.text = title_text
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", _get_title_font())
	title_lbl.add_theme_font_size_override("font_size", 34)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(title_lbl)

	# ── 7일 스트릭 캘린더 스트립 ──
	var strip := HBoxContainer.new()
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 6)
	vb.add_child(strip)
	_build_streak_strip(strip, sday)

	vb.add_child(HSeparator.new())

	# ── 오늘 보상 배지 ──
	var reward_hbox := HBoxContainer.new()
	reward_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_hbox.add_theme_constant_override("separation", 40)
	vb.add_child(reward_hbox)
	_add_reward_item(reward_hbox, "First\nLetter",  "×%d" % fl,  Color(0.38, 0.25, 0.75, 1.0))
	if rv > 0:
		_add_reward_item(reward_hbox, "Full\nReveal", "×%d" % rv, Color("#9C27B0"))

	# ── 누적 일수 ──
	var cum_lbl := Label.new()
	cum_lbl.text = "🗓️  Total: %d days attended" % cumulative
	cum_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cum_lbl.add_theme_font_size_override("font_size", 20)
	cum_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.75))
	vb.add_child(cum_lbl)

	# ── 누적 마일스톤 보너스 (해당 일에만 표시) ──
	if has_ms:
		var ms_panel := PanelContainer.new()
		var ms_style := StyleBoxFlat.new()
		ms_style.bg_color = Color("#2A1A3E")
		ms_style.corner_radius_top_left     = 12
		ms_style.corner_radius_top_right    = 12
		ms_style.corner_radius_bottom_left  = 12
		ms_style.corner_radius_bottom_right = 12
		ms_style.content_margin_left   = 16
		ms_style.content_margin_right  = 16
		ms_style.content_margin_top    = 12
		ms_style.content_margin_bottom = 12
		ms_panel.add_theme_stylebox_override("panel", ms_style)
		vb.add_child(ms_panel)
		var ms_lbl := Label.new()
		ms_lbl.text = "✨  %d-Day Bonus!  First Letter +%d  /  Full Reveal +%d" % [cumulative, m_fl, m_rv]
		ms_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ms_lbl.add_theme_font_size_override("font_size", 19)
		ms_lbl.add_theme_color_override("font_color", Color("#FFD700"))
		ms_panel.add_child(ms_lbl)

	# ── 내일 보상 예고 ──
	var next_day: int   = (sday % 7) + 1
	var next_row: Array = HintTicketManager.STREAK_REWARDS[next_day - 1]
	var tmr_lbl := Label.new()
	if sday < 7:
		tmr_lbl.text = "Tomorrow (Day %d): First Letter ×%d  /  Full Reveal ×%d" % [next_day, next_row[0], next_row[1]]
	else:
		tmr_lbl.text = "Resets to Day 1 tomorrow  (First Letter ×2)"
	tmr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tmr_lbl.add_theme_font_size_override("font_size", 18)
	tmr_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
	vb.add_child(tmr_lbl)

	vb.add_child(HSeparator.new())

	# ── 확인 버튼 ──
	var ok_btn := Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(0, 76)
	ok_btn.add_theme_font_size_override("font_size", 28)
	var ok_style := StyleBoxFlat.new()
	ok_style.bg_color = Color(0.38, 0.25, 0.75, 1.0)
	ok_style.corner_radius_top_left     = 18
	ok_style.corner_radius_top_right    = 18
	ok_style.corner_radius_bottom_left  = 18
	ok_style.corner_radius_bottom_right = 18
	ok_btn.add_theme_stylebox_override("normal",  ok_style)
	var ok_hover := ok_style.duplicate() as StyleBoxFlat
	ok_hover.bg_color = Color(0.38, 0.25, 0.75, 1.0).lightened(0.1)
	ok_btn.add_theme_stylebox_override("hover",   ok_hover)
	var ok_press := ok_style.duplicate() as StyleBoxFlat
	ok_press.bg_color = Color(0.38, 0.25, 0.75, 1.0).darkened(0.15)
	ok_btn.add_theme_stylebox_override("pressed", ok_press)
	ok_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	ok_btn.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(ok_btn)

	# ── 팝 인 애니메이션 ──
	card.scale        = Vector2(0.82, 0.82)
	card.pivot_offset = card.custom_minimum_size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "scale",   Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	tw.tween_property(bg,   "color:a", 0.50,        0.18)

	# 확인 버튼 → 팝업 닫기
	ok_btn.pressed.connect(func() -> void:
		var tw2 := create_tween()
		tw2.tween_property(bg, "color:a", 0.0, 0.15)
		await tw2.finished
		layer.queue_free()
	)


## 7일 스트릭 달력 스트립을 생성해 parent에 추가한다.
## streak_day_val: 오늘이 몇 일차인지 (1~7)
func _build_streak_strip(parent: HBoxContainer, streak_day_val: int) -> void:
	for i: int in range(7):
		var day_num:  int  = i + 1
		var is_done:  bool = day_num < streak_day_val
		var is_today: bool = day_num == streak_day_val
		var is_last:  bool = day_num == 7

		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 4)
		parent.add_child(col)

		# 원형 배지
		var circle := PanelContainer.new()
		var cs := StyleBoxFlat.new()
		cs.corner_radius_top_left     = 9999
		cs.corner_radius_top_right    = 9999
		cs.corner_radius_bottom_left  = 9999
		cs.corner_radius_bottom_right = 9999
		cs.content_margin_left   = 0
		cs.content_margin_right  = 0
		cs.content_margin_top    = 0
		cs.content_margin_bottom = 0
		var circle_size: int
		if is_today:
			cs.bg_color = Color("#FF6B35")
			cs.border_width_left   = 3
			cs.border_width_right  = 3
			cs.border_width_top    = 3
			cs.border_width_bottom = 3
			cs.border_color = Color.WHITE
			circle_size = 58
		elif is_done:
			cs.bg_color = Color(0.38, 0.25, 0.75, 1.0)
			circle_size = 52
		else:
			cs.bg_color = Color("#252538")
			cs.border_width_left   = 2
			cs.border_width_right  = 2
			cs.border_width_top    = 2
			cs.border_width_bottom = 2
			cs.border_color = Color("#444466")
			circle_size = 52
		circle.add_theme_stylebox_override("panel", cs)
		circle.custom_minimum_size = Vector2(circle_size, circle_size)
		col.add_child(circle)

		# 배지 안 아이콘/숫자
		var inner := Label.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		if is_done:
			inner.text = "✓"
			inner.add_theme_font_size_override("font_size", 22)
			inner.add_theme_color_override("font_color", Color.WHITE)
		elif is_last:
			inner.text = "★"
			inner.add_theme_font_size_override("font_size", 22 if is_today else 20)
			inner.add_theme_color_override("font_color",
				Color.WHITE if is_today else Color("#8888AA"))
		else:
			inner.text = "%d" % day_num
			inner.add_theme_font_size_override("font_size", 22 if is_today else 18)
			inner.add_theme_color_override("font_color",
				Color.WHITE if is_today else Color("#666688"))
		circle.add_child(inner)

		# 아래 일수 레이블
		var day_lbl := Label.new()
		day_lbl.text = "Day %d" % day_num
		day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_lbl.add_theme_font_size_override("font_size", 14)
		day_lbl.add_theme_color_override("font_color",
			Color.WHITE if is_today else Color("#555577"))
		col.add_child(day_lbl)


## 보상 아이템 카드 1개를 생성해 parent에 추가한다.
func _add_reward_item(parent: HBoxContainer,
		label: String, amount: String, color: Color) -> void:
	var item := VBoxContainer.new()
	item.add_theme_constant_override("separation", 8)
	item.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(item)

	# 색상 원형 배지
	var badge := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = color
	bs.corner_radius_top_left     = 9999
	bs.corner_radius_top_right    = 9999
	bs.corner_radius_bottom_left  = 9999
	bs.corner_radius_bottom_right = 9999
	bs.content_margin_left   = 20
	bs.content_margin_right  = 20
	bs.content_margin_top    = 14
	bs.content_margin_bottom = 14
	badge.add_theme_stylebox_override("panel", bs)
	badge.custom_minimum_size = Vector2(100, 100)
	item.add_child(badge)

	var amount_lbl := Label.new()
	amount_lbl.text = amount
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	amount_lbl.add_theme_font_size_override("font_size", 32)
	amount_lbl.add_theme_color_override("font_color", Color.WHITE)
	amount_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(amount_lbl)

	var name_lbl := Label.new()
	name_lbl.text = label
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	item.add_child(name_lbl)


# ===== 플레이 =====

func _on_play_pressed() -> void:
	GameController.start_game(SaveManager.get_current_stage())


# ===== 디버그 패널 (DEBUG 빌드 전용) =====

func _setup_debug_panel() -> void:
	var win := Window.new()
	win.title         = "Home Debug"
	win.size          = Vector2i(420, 560)
	win.position      = Vector2i(600, 40)
	win.always_on_top = true
	win.exclusive     = false
	win.visible       = false
	win.close_requested.connect(func() -> void: win.hide())
	get_tree().root.add_child(win)

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

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	scroll.add_child(vb)

	var ttl := Label.new()
	ttl.text = "◈ Home Debug"
	ttl.add_theme_font_size_override("font_size", 20)
	vb.add_child(ttl)
	vb.add_child(HSeparator.new())

	_add_dbg_section(vb, "▸ 로고", Color(0.7, 0.85, 1.0))
	_add_dbg_slider(vb, "SCALE", "_logo_scale", _logo_scale, 0.1, 3.0, 0.05)
	_add_dbg_slider(vb, "X",     "_logo_x",     _logo_x,    -400.0, 400.0)
	_add_dbg_slider(vb, "Y",     "_logo_y",     _logo_y,    -600.0, 600.0)
	vb.add_child(HSeparator.new())

	_add_dbg_section(vb, "▸ 레벨 배지", Color(1.0, 0.9, 0.6))
	_add_dbg_slider(vb, "X",           "_badge_x",     _badge_x,    -400.0, 400.0)
	_add_dbg_slider(vb, "Y",           "_badge_y",     _badge_y,    -600.0, 600.0)
	_add_dbg_slider(vb, "배지 너비",   "_badge_w",     _badge_w,     80.0,  600.0)
	_add_dbg_slider(vb, "배지 높이",   "_badge_h",     _badge_h,     80.0,  600.0)
	_add_dbg_slider(vb, "라벨 Y",      "_badge_lbl_y", _badge_lbl_y, -400.0, 400.0)
	_add_dbg_slider(vb, "폰트",        "_font_level",  _font_level,  10.0,  80.0)
	vb.add_child(HSeparator.new())

	_add_dbg_section(vb, "▸ Ad Remove Btn", Color(1.0, 0.7, 0.7))
	_add_dbg_slider(vb, "X",    "_ad_btn_x",    _ad_btn_x,    0.0, 600.0)
	_add_dbg_slider(vb, "Y",    "_ad_btn_y",    _ad_btn_y,    0.0, 400.0)
	_add_dbg_slider(vb, "SIZE", "_ad_btn_size", _ad_btn_size, 40.0, 200.0)
	vb.add_child(HSeparator.new())

	_add_dbg_section(vb, "▸ 플레이 버튼", Color(0.8, 1.0, 0.7))
	_add_dbg_slider(vb, "X",           "_play_x",    _play_x,    -400.0, 400.0)
	_add_dbg_slider(vb, "Y",           "_play_y",    _play_y,    -600.0, 600.0)
	_add_dbg_slider(vb, "버튼 너비",   "_btn_w",     _btn_w,     100.0, 900.0)
	_add_dbg_slider(vb, "버튼 높이",   "_btn_h",     _btn_h,     40.0,  300.0)
	_add_dbg_slider(vb, "텍스트 Y",    "_btn_lbl_y", _btn_lbl_y, -80.0, 80.0)
	_add_dbg_slider(vb, "폰트",        "_font_play", _font_play, 10.0,  80.0)
	vb.add_child(HSeparator.new())

	# ── 스테이지 점프 ──────────────────────────────────────────
	vb.add_child(HSeparator.new())
	_add_dbg_section(vb, "▸ 스테이지 점프", Color(1.0, 0.85, 0.5))

	var stage_row := HBoxContainer.new()
	stage_row.add_theme_constant_override("separation", 8)
	vb.add_child(stage_row)

	var stage_lbl := Label.new()
	stage_lbl.text = "Stage:"
	stage_lbl.add_theme_font_size_override("font_size", 16)
	stage_lbl.custom_minimum_size = Vector2(60, 0)
	stage_row.add_child(stage_lbl)

	var stage_edit := LineEdit.new()
	stage_edit.placeholder_text = "예: 61"
	stage_edit.text = str(GameManager.debug_start_stage) if GameManager.debug_start_stage > 0 else ""
	stage_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_edit.add_theme_font_size_override("font_size", 16)
	stage_row.add_child(stage_edit)

	var jump_btn := Button.new()
	jump_btn.text = "▶ GO"
	jump_btn.custom_minimum_size = Vector2(80, 44)
	jump_btn.add_theme_font_size_override("font_size", 16)
	jump_btn.pressed.connect(func() -> void:
		var n: int = int(stage_edit.text)
		if n >= 1:
			GameManager.debug_start_stage = n
			SaveManager.clear_resume_state()
			GameController.start_game(n)
		else:
			stage_edit.placeholder_text = "1 이상 입력!"
	)
	stage_row.add_child(jump_btn)

	var reset_btn := Button.new()
	reset_btn.text = "RESET"
	reset_btn.custom_minimum_size = Vector2(70, 44)
	reset_btn.add_theme_font_size_override("font_size", 14)
	reset_btn.pressed.connect(func() -> void:
		GameManager.debug_start_stage = 0
		stage_edit.text = ""
		stage_edit.placeholder_text = "예: 61"
	)
	stage_row.add_child(reset_btn)

	var hint_lbl := Label.new()
	hint_lbl.text = "5×5=St.1  10×10=St.41  diff3=St.61"
	hint_lbl.add_theme_font_size_override("font_size", 12)
	hint_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vb.add_child(hint_lbl)
	vb.add_child(HSeparator.new())
	# ──────────────────────────────────────────────────────────

	# ── 바텀 탭바 슬라이더 ──────────────────────────────────
	vb.add_child(HSeparator.new())
	_add_dbg_section(vb, "▸ 바텀 탭바", Color(1.0, 0.75, 0.5))

	var btb: BottomTabBar = _get_bottom_tab_bar()
	if btb:
		_add_bar_slider(vb, btb, "바 높이",     "bar_h",     btb.bar_h,     80.0,  240.0)
		_add_bar_slider(vb, btb, "바 Y",        "bar_y",     btb.bar_y,     0.0,   350.0)
		_add_bar_slider(vb, btb, "비활성 크기", "ico_sz",     btb.ico_sz,     60.0,  300.0)
		_add_bar_slider(vb, btb, "활성 크기",   "ico_sz_a",   btb.ico_sz_a,   60.0,  400.0)
		_add_bar_slider(vb, btb, "활성 CY",     "ico_cy",     btb.ico_cy,     0.0,   380.0)
		_add_bar_slider(vb, btb, "비활성 CY",   "ico_cy_off", btb.ico_cy_off, 0.0,   380.0)
		_add_bar_slider(vb, btb, "필 H",        "pill_h",    btb.pill_h,    20.0,  80.0)
		_add_bar_slider(vb, btb, "필 Y",        "pill_y",    btb.pill_y,    0.0,   380.0)
		_add_bar_slider(vb, btb, "필 패딩",     "pill_pad",  btb.pill_pad,  0.0,   60.0)
		_add_bar_slider(vb, btb, "라벨 폰트",     "lbl_font", btb.lbl_font, 10.0, 48.0)
		_add_bar_slider(vb, btb, "라벨 Y",       "lbl_y",    btb.lbl_y,    0.0,  380.0)
		_add_bar_slider(vb, btb, "라벨 H",       "lbl_h",    btb.lbl_h,    16.0, 60.0)
		_add_bar_slider(vb, btb, "X 데일리",     "lbl_x0",   btb.lbl_x0,  -100.0, 100.0)
		_add_bar_slider(vb, btb, "X 팀",         "lbl_x1",   btb.lbl_x1,  -100.0, 100.0)
		_add_bar_slider(vb, btb, "X 홈",         "lbl_x2",   btb.lbl_x2,  -100.0, 100.0)
		_add_bar_slider(vb, btb, "X 컬렉션",     "lbl_x3",   btb.lbl_x3,  -100.0, 100.0)
		_add_bar_slider(vb, btb, "X 상점",       "lbl_x4",   btb.lbl_x4,  -100.0, 100.0)
	else:
		var warn := Label.new()
		warn.text = "(BottomTabBar를 찾을 수 없음)"
		warn.add_theme_font_size_override("font_size", 14)
		vb.add_child(warn)
	vb.add_child(HSeparator.new())
	# ──────────────────────────────────────────────────────────

	var print_btn := Button.new()
	print_btn.text = "[ Print Snapshot ]"
	print_btn.custom_minimum_size = Vector2(0, 44)
	print_btn.add_theme_font_size_override("font_size", 16)
	print_btn.pressed.connect(_print_snapshot)
	vb.add_child(print_btn)

	# ── ⚙ 토글 버튼 (우상단) ──
	var canvas := CanvasLayer.new()
	canvas.layer = 64
	add_child(canvas)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	var toggle := Button.new()
	toggle.text = "⚙"
	toggle.custom_minimum_size = Vector2(64, 64)
	toggle.add_theme_font_size_override("font_size", 28)
	toggle.anchor_left   = 1.0
	toggle.anchor_right  = 1.0
	toggle.anchor_top    = 0.0
	toggle.anchor_bottom = 0.0
	toggle.offset_left   = -72.0
	toggle.offset_right  = -8.0
	toggle.offset_top    = 8.0
	toggle.offset_bottom = 72.0
	toggle.pressed.connect(func() -> void:
		win.visible = not win.visible
		if win.visible:
			win.grab_focus()
	)
	root.add_child(toggle)


func _add_dbg_section(vb: VBoxContainer, text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", color)
	vb.add_child(lbl)


func _add_dbg_slider(vb: VBoxContainer, label_text: String,
		prop: String, init_val: float,
		min_v: float, max_v: float, custom_step: float = 0.0) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)

	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.custom_minimum_size = Vector2(100, 0)
	name_lbl.add_theme_font_size_override("font_size", 15)
	row.add_child(name_lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step      = custom_step if custom_step > 0.0 else 0.5
	slider.value     = init_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size   = Vector2(0, 32)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.text = "%.1f" % init_val
	val_lbl.custom_minimum_size = Vector2(52, 0)
	val_lbl.add_theme_font_size_override("font_size", 15)
	row.add_child(val_lbl)

	slider.value_changed.connect(func(v: float) -> void:
		set(prop, v)
		val_lbl.text = "%.1f" % v
		_apply_layout()
	)


func _get_bottom_tab_bar() -> BottomTabBar:
	## ScreenManager를 통해 BottomTabBar 참조 획득
	var main: Node = get_tree().root.get_node_or_null("MainScene")
	if main:
		var bar: Node = main.get_node_or_null("BarLayer/BottomTabBar")
		if bar is BottomTabBar:
			return bar as BottomTabBar
	return null


func _add_bar_slider(vb_parent: VBoxContainer, btb: BottomTabBar,
		label_text: String, prop: String, init_val: float,
		min_v: float, max_v: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb_parent.add_child(row)

	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.custom_minimum_size = Vector2(100, 0)
	name_lbl.add_theme_font_size_override("font_size", 15)
	row.add_child(name_lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 0.5
	slider.value = init_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 32)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.text = "%.1f" % init_val
	val_lbl.custom_minimum_size = Vector2(52, 0)
	val_lbl.add_theme_font_size_override("font_size", 15)
	row.add_child(val_lbl)

	slider.value_changed.connect(func(v: float) -> void:
		btb.set(prop, v)
		val_lbl.text = "%.1f" % v
		btb.refresh_layout()
	)


func _print_snapshot() -> void:
	pass


# ===== 플레이 버튼 =====

func _setup_play_button_style() -> void:
	## 텍스처 버튼 스타일 (pill 이미지 — 좌우 캡 9-slice 보호)
	## 소스 이미지 1280x227 (normal/pressed 동일 크기) — 캡 너비 ≈ 높이/2 = 113px
	const NORMAL_PATH:  String = "res://assets/ui/btn_play_normal.png"
	const PRESSED_PATH: String = "res://assets/ui/btn_play_pressed.png"
	const CAP: float = 113.0  ## 9-slice 좌우 마진 (pill 라운드 영역)

	var _make_sbt: Callable = func(path: String) -> StyleBoxTexture:
		var sbt := StyleBoxTexture.new()
		if ResourceLoader.exists(path):
			sbt.texture = load(path) as Texture2D
		sbt.texture_margin_left   = CAP
		sbt.texture_margin_right  = CAP
		sbt.texture_margin_top    = 0.0
		sbt.texture_margin_bottom = 0.0
		return sbt

	_sbt_normal  = _make_sbt.call(NORMAL_PATH)  as StyleBoxTexture
	_sbt_pressed = _make_sbt.call(PRESSED_PATH) as StyleBoxTexture
	play_button.add_theme_stylebox_override("normal",  _sbt_normal)
	play_button.add_theme_stylebox_override("hover",   _sbt_normal)
	play_button.add_theme_stylebox_override("pressed", _sbt_pressed)
	play_button.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	play_button.add_theme_font_override("font", preload("res://assets/fonts/BubblegumSans-Regular.ttf"))
	play_button.add_theme_color_override("font_color", Color("#FFF8E7"))
	## 눌렸을 때 텍스트 위치 고정 — Godot 기본 press offset 무효화
	play_button.add_theme_constant_override("pressed_offset_x", 0)
	play_button.add_theme_constant_override("pressed_offset_y", 0)


# ===== 설정 버튼 =====

func _setup_settings_button_style() -> void:
	## 원형 스타일 (게임 화면의 설정 버튼과 동일한 디자인)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.0, 0.0, 0.0, 0.45)
	st.corner_radius_top_left     = 9999
	st.corner_radius_top_right    = 9999
	st.corner_radius_bottom_left  = 9999
	st.corner_radius_bottom_right = 9999
	var st_hover: StyleBoxFlat = st.duplicate() as StyleBoxFlat
	st_hover.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	var st_press: StyleBoxFlat = st.duplicate() as StyleBoxFlat
	st_press.bg_color = Color(0.0, 0.0, 0.0, 0.65)
	settings_button.add_theme_stylebox_override("normal",  st)
	settings_button.add_theme_stylebox_override("hover",   st_hover)
	settings_button.add_theme_stylebox_override("pressed", st_press)
	settings_button.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	settings_button.add_theme_color_override("font_color", Color.WHITE)
	# 설정 아이콘 적용 (파일이 존재할 때만)
	if ResourceLoader.exists("res://assets/icons/ui/icon_settings.png"):
		settings_button.icon = load("res://assets/icons/ui/icon_settings.png") as Texture2D
		settings_button.text = ""
		settings_button.expand_icon = true


# ===== Ad-remove button =====

const _AD_IDLE_PATH:    String = "res://assets/icons/ui/icon_ad_idle.png"
const _AD_PRESS_PATH:   String = "res://assets/icons/ui/icon_ad_press.png"
const _AD_DISABLE_PATH: String = "res://assets/icons/ui/icon_ad_disable.png"

func _setup_ad_remove_button() -> void:
	if AdManager.is_ads_removed():
		return
	_ad_remove_btn = Button.new()
	_ad_remove_btn.name = "AdRemoveBtn"
	_ad_remove_btn.text = ""
	_ad_remove_btn.custom_minimum_size = Vector2(_SETTINGS_BTN_SIZE, _SETTINGS_BTN_SIZE)
	_ad_remove_btn.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	_ad_remove_btn.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	_ad_remove_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_ad_remove_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	_ad_remove_btn.anchor_left   = 0.0
	_ad_remove_btn.anchor_right  = 0.0
	_ad_remove_btn.anchor_top    = 0.0
	_ad_remove_btn.anchor_bottom = 0.0
	add_child(_ad_remove_btn)
	# TextureRect inside button — matches button size exactly
	var tex := TextureRect.new()
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(_AD_IDLE_PATH):
		tex.texture = load(_AD_IDLE_PATH) as Texture2D
	_ad_remove_btn.add_child(tex)
	_ad_remove_btn.pressed.connect(_on_ad_remove_pressed)

	# React to ads being removed from anywhere (e.g. game screen IAP).
	AdManager.ads_removed_changed.connect(func() -> void:
		if _ad_remove_btn:
			_ad_remove_btn.visible = false
	)


func _on_ad_remove_pressed() -> void:
	_show_ad_remove_popup()


func _show_ad_remove_popup() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root_ctrl)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root_ctrl.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(center)

	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color("#1E1E32")
	cs.corner_radius_top_left     = 28
	cs.corner_radius_top_right    = 28
	cs.corner_radius_bottom_left  = 28
	cs.corner_radius_bottom_right = 28
	cs.content_margin_left   = 72
	cs.content_margin_right  = 72
	cs.content_margin_top    = 60
	cs.content_margin_bottom = 60
	card.add_theme_stylebox_override("panel", cs)
	card.custom_minimum_size = Vector2(840, 0)
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 36)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vb)

	# Icon
	var icon_lbl := Label.new()
	icon_lbl.text = "🚫"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 96)
	vb.add_child(icon_lbl)

	# Title
	var title_lbl := Label.new()
	title_lbl.text = "Remove Ads"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", preload("res://assets/fonts/BubblegumSans-Regular.ttf"))
	title_lbl.add_theme_font_size_override("font_size", 54)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(title_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = "Enjoy an ad-free experience!\nRemove all ads permanently."
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_override("font", FONT_UI)
	desc_lbl.add_theme_font_size_override("font_size", 36)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.95, 0.85))
	vb.add_child(desc_lbl)

	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 24)
	vb.add_child(btn_row)

	# Cancel
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.custom_minimum_size = Vector2(0, 108)
	cancel_btn.add_theme_font_override("font", FONT_UI)
	cancel_btn.add_theme_font_size_override("font_size", 36)
	var cancel_st := StyleBoxFlat.new()
	cancel_st.bg_color = Color("#333333")
	cancel_st.corner_radius_top_left     = 16
	cancel_st.corner_radius_top_right    = 16
	cancel_st.corner_radius_bottom_left  = 16
	cancel_st.corner_radius_bottom_right = 16
	cancel_btn.add_theme_stylebox_override("normal", cancel_st)
	cancel_btn.add_theme_stylebox_override("hover", cancel_st.duplicate())
	cancel_btn.add_theme_stylebox_override("pressed", cancel_st.duplicate())
	cancel_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	cancel_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	btn_row.add_child(cancel_btn)

	# Purchase
	var buy_btn := Button.new()
	buy_btn.text = "Purchase"
	buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn.custom_minimum_size = Vector2(0, 108)
	buy_btn.add_theme_font_override("font", FONT_UI)
	buy_btn.add_theme_font_size_override("font_size", 36)
	var buy_st := StyleBoxFlat.new()
	buy_st.bg_color = Color(0.38, 0.25, 0.75, 1.0)
	buy_st.corner_radius_top_left     = 16
	buy_st.corner_radius_top_right    = 16
	buy_st.corner_radius_bottom_left  = 16
	buy_st.corner_radius_bottom_right = 16
	buy_btn.add_theme_stylebox_override("normal", buy_st)
	var buy_hover := buy_st.duplicate() as StyleBoxFlat
	buy_hover.bg_color = buy_st.bg_color.lightened(0.1)
	buy_btn.add_theme_stylebox_override("hover", buy_hover)
	buy_btn.add_theme_stylebox_override("pressed", buy_st.duplicate())
	buy_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	buy_btn.add_theme_color_override("font_color", Color.WHITE)
	btn_row.add_child(buy_btn)

	# Pop-in animation
	card.scale = Vector2(0.85, 0.85)
	card.pivot_offset = card.custom_minimum_size / 2.0
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_property(bg, "color:a", 0.55, 0.15)

	var _close := func() -> void:
		var tw2: Tween = create_tween()
		tw2.tween_property(bg, "color:a", 0.0, 0.12)
		await tw2.finished
		layer.queue_free()

	cancel_btn.pressed.connect(_close)
	bg.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_close.call()
	)

	buy_btn.pressed.connect(func() -> void:
		_close.call()
		IAPManager.purchase(IAPManager.PRODUCT_REMOVE_ADS)
	)


func _on_settings_pressed() -> void:
	_show_settings_popup()


# ===== 설정 팝업 =====

## ⚙ 설정 팝업 (CanvasLayer layer=15).
## 배경음악·효과음 토글+슬라이더, 문의, 약관 제공.
func _show_settings_popup() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root_ctrl)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root_ctrl.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ctrl.add_child(center)

	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color("#1A1A2E")
	cs.corner_radius_top_left     = 34
	cs.corner_radius_top_right    = 34
	cs.corner_radius_bottom_left  = 34
	cs.corner_radius_bottom_right = 34
	cs.content_margin_left   = 50
	cs.content_margin_right  = 50
	cs.content_margin_top    = 39
	cs.content_margin_bottom = 39
	card.add_theme_stylebox_override("panel", cs)
	card.custom_minimum_size = Vector2(672, 0)
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 25)
	card.add_child(vb)

	# 헤더
	var header := HBoxContainer.new()
	vb.add_child(header)

	var title_lbl := Label.new()
	title_lbl.text = "⚙  Settings"
	title_lbl.add_theme_font_override("font", _get_title_font())
	title_lbl.add_theme_font_size_override("font_size", 42)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(73, 73)
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	close_btn.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	close_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	close_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	close_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	header.add_child(close_btn)

	vb.add_child(HSeparator.new())

	_settings_add_audio_section(
		vb, "🎵  BGM",
		AudioManager.get_music_enabled(),
		AudioManager.get_music_volume(),
		func(en: bool) -> void: AudioManager.set_music_enabled(en),
		func(v: float)  -> void: AudioManager.set_music_volume(v)
	)

	vb.add_child(HSeparator.new())

	_settings_add_audio_section(
		vb, "🔊  SFX",
		AudioManager.get_sfx_enabled(),
		AudioManager.get_sfx_volume(),
		func(en: bool) -> void: AudioManager.set_sfx_enabled(en),
		func(v: float)  -> void: AudioManager.set_sfx_volume(v)
	)

	vb.add_child(HSeparator.new())

	var privacy_btn: Button = _settings_make_link_button("🔒  Privacy Policy")
	privacy_btn.pressed.connect(func() -> void:
		OS.shell_open(AdConfig.PRIVACY_POLICY_URL)
	)
	vb.add_child(privacy_btn)

	var terms_btn: Button = _settings_make_link_button("📋  Terms of Service")
	terms_btn.pressed.connect(func() -> void:
		OS.shell_open(AdConfig.TERMS_OF_SERVICE_URL)
	)
	vb.add_child(terms_btn)

	var contact_btn: Button = _settings_make_link_button("📧  Contact Developer")
	contact_btn.pressed.connect(func() -> void:
		OS.shell_open("mailto:wordpuzzle.game.dev@gmail.com")
	)
	vb.add_child(contact_btn)

	# 팝 인 애니메이션
	card.scale        = Vector2(0.85, 0.85)
	card.pivot_offset = card.custom_minimum_size / 2.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "scale",   Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_property(bg,   "color:a", 0.55,        0.15)

	var close_func: Callable = func() -> void:
		var tw2 := create_tween()
		tw2.tween_property(bg, "color:a", 0.0, 0.12)
		await tw2.finished
		layer.queue_free()
	close_btn.pressed.connect(close_func)
	bg.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			close_func.call()
	)


func _settings_add_audio_section(
		vb: VBoxContainer, section_label: String,
		is_enabled: bool, volume: float,
		on_toggle: Callable, on_volume: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 17)
	vb.add_child(row)

	var lbl := Label.new()
	lbl.text = section_label
	lbl.add_theme_font_size_override("font_size", 31)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var toggle := CheckButton.new()
	toggle.button_pressed = is_enabled
	toggle.custom_minimum_size = Vector2(101, 0)
	row.add_child(toggle)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step      = 0.02
	slider.value     = volume
	slider.editable  = is_enabled
	slider.modulate  = Color(1.0, 1.0, 1.0, 1.0 if is_enabled else 0.35)
	slider.custom_minimum_size   = Vector2(0, 53)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(slider)

	toggle.toggled.connect(func(pressed: bool) -> void:
		slider.editable = pressed
		slider.modulate = Color(1.0, 1.0, 1.0, 1.0 if pressed else 0.35)
		on_toggle.call(pressed)
	)
	slider.value_changed.connect(func(v: float) -> void:
		on_volume.call(v)
	)


func _settings_make_link_button(text_val: String) -> Button:
	var btn := Button.new()
	btn.text = text_val + "   →"
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 87)
	btn.add_theme_font_size_override("font_size", 28)
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#252538")
	st.corner_radius_top_left     = 17
	st.corner_radius_top_right    = 17
	st.corner_radius_bottom_left  = 17
	st.corner_radius_bottom_right = 17
	st.content_margin_left   = 28
	st.content_margin_right  = 28
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
	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	return btn
