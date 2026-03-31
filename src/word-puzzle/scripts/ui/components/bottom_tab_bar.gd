## bottom_tab_bar.gd
## Bottom 5-tab navigation bar — manual absolute positioning.
##
## Control height = 380px (220px icon overhang + 160px bar body).
## Bar background image covers only the bottom 160px.
## Top 220px is transparent — icons extend into this area.
## mouse_filter = IGNORE (tscn) → transparent top area does not block touches behind it.
## Only tab hit areas are clickable.
class_name BottomTabBar
extends Control

const FONT_TAB: Font = preload("res://assets/fonts/Nunito-Variable.ttf")

signal tab_selected(index: int)


# ===== Tab data =====

const TAB_COUNT: int = 5
const TAB_LABELS: Array[String] = ["Daily", "Team", "Home", "Collection", "Shop"]
const LOCKED_TABS: Array[int] = []
## Tabs that show a "Coming Soon" popup instead of switching screens.
const WIP_TABS: Array[int] = [0, 1, 3, 4]
const HOME_IDX: int = 2

const TAB_ICONS: Array[String] = [
	"res://assets/icons/tabs/icon_tab_daily.png",
	"res://assets/icons/tabs/icon_tab_team.png",
	"res://assets/icons/tabs/home.png",
	"res://assets/icons/tabs/icon_tab_collection.png",
	"res://assets/icons/tabs/icon_tab_shop.png",
]

const BAR_BG_PATH: String = "res://assets/ui/nav_bar_bg.png"
const PILL_PATH: String = "res://assets/ui/nav_bar_active.png"


# ===== Layout variables (1080×1920 viewport) =====
# Total Control height = 380px. Bottom bar_h(160px) is the bar body.
# Coordinate system: y=0 is Control top, y=220 is bar body top, y=380 is bar bottom (screen edge).
# Declared as var → can be adjusted in real time via debug sliders.

var bar_h: float = 160.0
var bar_y: float = 100.0

## Icon sizes
var ico_sz: float = 140.0            ## Inactive size
var ico_sz_a: float = 240.0          ## Active size

## Icon Y center (active = higher, inactive = lower)
var ico_cy: float = 40.0             ## Active icon center Y (top)
var ico_cy_off: float = 130.0        ## Inactive icon center Y (bottom)

## Golden pill (width = label text width + pill_pad*2, X synced with active label X offset)
var pill_h: float = 61.5
var pill_y: float = 174.5
var pill_pad: float = 20.0           ## Pill horizontal padding relative to label text

## Labels
var lbl_font: float = 38.0
var lbl_y: float = 176.5
var lbl_h: float = 33.5
## Per-tab label X offsets
var lbl_x0: float = 0.0
var lbl_x1: float = 4.5
var lbl_x2: float = 7.0
var lbl_x3: float = -0.5
var lbl_x4: float = -2.0

## Colors (const)
const C_LBL_ON: Color = Color.WHITE
const C_LBL_OFF: Color = Color(0.92, 0.88, 1.0, 0.80)
const C_LBL_LOCK: Color = Color(0.78, 0.73, 0.88, 0.55)
const C_ICO_ON: Color = Color.WHITE
const C_ICO_OFF: Color = Color(1.0, 1.0, 1.0, 0.80)
const C_ICO_LOCK: Color = Color(1.0, 1.0, 1.0, 0.50)

const ANIM: float = 0.22


# ===== Runtime =====

var _act: int = HOME_IDX
var _icons: Array[TextureRect] = []
var _lbls: Array[Label] = []
var _touches: Array[Control] = []
var _pill: TextureRect
var _tw: Tween


func _ready() -> void:
	clip_contents = false
	# Root Control has mouse_filter=IGNORE (set in tscn)
	# → transparent top area does not block the screen behind it.

	_mk_bar_bg()
	_mk_pill()
	_mk_tabs()

	resized.connect(func() -> void: call_deferred("_lay"))
	call_deferred("_lay")


func _mk_bar_bg() -> void:
	var t: TextureRect = TextureRect.new()
	t.name = "BarBg"
	t.mouse_filter = MOUSE_FILTER_IGNORE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.z_index = 0
	if ResourceLoader.exists(BAR_BG_PATH):
		t.texture = load(BAR_BG_PATH)
	add_child(t)


func _mk_pill() -> void:
	_pill = TextureRect.new()
	_pill.name = "Pill"
	_pill.mouse_filter = MOUSE_FILTER_IGNORE
	_pill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pill.stretch_mode = TextureRect.STRETCH_SCALE
	_pill.z_index = 1
	if ResourceLoader.exists(PILL_PATH):
		_pill.texture = load(PILL_PATH)
	add_child(_pill)


func _mk_tabs() -> void:
	for i in range(TAB_COUNT):
		# Icon
		var ico: TextureRect = TextureRect.new()
		ico.name = "Ico%d" % i
		ico.mouse_filter = MOUSE_FILTER_IGNORE
		ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.z_index = 2
		if ResourceLoader.exists(TAB_ICONS[i]):
			ico.texture = load(TAB_ICONS[i])
		add_child(ico)
		_icons.append(ico)

		# Label
		var lb: Label = Label.new()
		lb.name = "Lbl%d" % i
		lb.text = TAB_LABELS[i]
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.mouse_filter = MOUSE_FILTER_IGNORE
		lb.z_index = 3
		lb.add_theme_font_override("font", FONT_TAB)
		lb.add_theme_font_size_override("font_size",
			int(lbl_font))
		add_child(lb)
		_lbls.append(lb)

		# Touch area
		var tc: Control = Control.new()
		tc.name = "Tc%d" % i
		tc.z_index = 10
		tc.mouse_filter = MOUSE_FILTER_STOP
		tc.mouse_default_cursor_shape = (
			CURSOR_POINTING_HAND if i not in LOCKED_TABS else CURSOR_ARROW)
		add_child(tc)
		_touches.append(tc)

		var idx: int = i
		tc.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton:
				var mb: InputEventMouseButton = ev as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					if idx not in LOCKED_TABS:
						_press(idx)
		)


# ────────────────────────────────────────
# Layout
# ────────────────────────────────────────

func _lay() -> void:
	var w: float = size.x
	var h: float = size.y   # Total Control height (380)
	if w < 1.0 or h < 1.0:
		return

	var cw: float = w / TAB_COUNT   # Single tab cell width

	# Bar background: positioned at bar_y with bar_h height.
	var bg: TextureRect = get_node("BarBg") as TextureRect
	bg.position = Vector2(0.0, bar_y)
	bg.size = Vector2(w, bar_h)

	# Golden pill
	_lay_pill(cw)

	# Update label font size
	for i in range(TAB_COUNT):
		var lb: Label = _lbls[i]
		lb.add_theme_font_size_override("font_size",
			int(lbl_font))

	for i in range(TAB_COUNT):
		var cx: float = cw * i + cw * 0.5
		var _is_home: bool = (i == HOME_IDX)
		var active: bool = (i == _act)

		# Icon (active = larger + higher, inactive = smaller + lower)
		var sz: float = ico_sz_a if active else ico_sz
		var cy: float = ico_cy if active else ico_cy_off

		var ico: TextureRect = _icons[i]
		ico.position = Vector2(cx - sz * 0.5, cy - sz * 0.5)
		ico.size = Vector2(sz, sz)

		# Label (per-tab X offset)
		var lb: Label = _lbls[i]
		var lx_off: float = [lbl_x0, lbl_x1, lbl_x2, lbl_x3, lbl_x4][i]
		lb.position = Vector2(cw * i + lx_off, lbl_y)
		lb.size = Vector2(cw, lbl_h)

		# Style
		_sty(i, active)

		# Touch area
		var top_y: float = cy - sz * 0.5
		var tc: Control = _touches[i]
		tc.position = Vector2(cw * i, top_y)
		tc.size = Vector2(cw, h - top_y)


func _get_pill_width(idx: int) -> float:
	## Pill width = label text width + left/right padding.
	var lb: Label = _lbls[idx]
	var text_w: float = lb.get_theme_font("font").get_string_size(
		lb.text, HORIZONTAL_ALIGNMENT_CENTER, -1,
		int(lbl_font)).x
	return text_w + pill_pad * 2.0


func _lay_pill(cw: float) -> void:
	var cx: float = cw * _act + cw * 0.5
	var lx_off: float = [lbl_x0, lbl_x1, lbl_x2, lbl_x3, lbl_x4][_act]
	var pw: float = _get_pill_width(_act)
	_pill.position = Vector2(cx - pw * 0.5 + lx_off, pill_y)
	_pill.size = Vector2(pw, pill_h)


func _sty(i: int, active: bool) -> void:
	var ico: TextureRect = _icons[i]
	var lb: Label = _lbls[i]
	if i in LOCKED_TABS:
		ico.modulate = C_ICO_LOCK
		lb.add_theme_color_override("font_color", C_LBL_LOCK)
	elif active:
		ico.modulate = C_ICO_ON
		lb.add_theme_color_override("font_color", C_LBL_ON)
	else:
		ico.modulate = C_ICO_OFF
		lb.add_theme_color_override("font_color", C_LBL_OFF)


# ────────────────────────────────────────
# Tab switching
# ────────────────────────────────────────

func _press(idx: int) -> void:
	if idx in WIP_TABS:
		_show_wip_popup()
		return
	if idx == _act:
		return
	_anim(idx)
	_act = idx
	tab_selected.emit(idx)


func _anim(nw: int) -> void:
	if _tw:
		_tw.kill()
	_tw = create_tween().set_parallel(true)
	_tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	var w: float = size.x
	var cw: float = w / TAB_COUNT

	# Pill slide (width based on label text)
	var ncx: float = cw * nw + cw * 0.5
	var nw_lx: float = [lbl_x0, lbl_x1, lbl_x2, lbl_x3, lbl_x4][nw]
	var nw_pw: float = _get_pill_width(nw)
	_tw.tween_property(_pill, "position:x", ncx - nw_pw * 0.5 + nw_lx, ANIM)
	_tw.tween_property(_pill, "size:x", nw_pw, ANIM)

	# Previous tab → inactive (shrink + move down)
	var old: int = _act
	var old_cx: float = cw * old + cw * 0.5
	_tw.tween_property(_icons[old], "size",
		Vector2(ico_sz, ico_sz), ANIM * 0.8)
	_tw.tween_property(_icons[old], "position",
		Vector2(old_cx - ico_sz * 0.5, ico_cy_off - ico_sz * 0.5), ANIM * 0.8)
	if old not in LOCKED_TABS:
		_tw.tween_property(_icons[old], "modulate", C_ICO_OFF, ANIM * 0.5)
		var ol: Label = _lbls[old]
		_tw.tween_method(
			func(c: Color) -> void: ol.add_theme_color_override("font_color", c),
			C_LBL_ON, C_LBL_OFF, ANIM * 0.5)

	# New tab → active (grow + move up)
	var new_cx: float = cw * nw + cw * 0.5
	_tw.tween_property(_icons[nw], "size",
		Vector2(ico_sz_a, ico_sz_a), ANIM)
	_tw.tween_property(_icons[nw], "position",
		Vector2(new_cx - ico_sz_a * 0.5, ico_cy - ico_sz_a * 0.5), ANIM)
	_tw.tween_property(_icons[nw], "modulate", C_ICO_ON, ANIM * 0.5)
	var nl: Label = _lbls[nw]
	_tw.tween_method(
		func(c: Color) -> void: nl.add_theme_color_override("font_color", c),
		C_LBL_OFF, C_LBL_ON, ANIM * 0.5)


# ────────────────────────────────────────
# External API
# ────────────────────────────────────────

func set_active_tab(index: int) -> void:
	if index < 0 or index >= TAB_COUNT:
		return
	_act = index
	call_deferred("_lay")


## Called from debug slider — refreshes layout immediately.
func refresh_layout() -> void:
	_lay()


# ────────────────────────────────────────
# Coming Soon popup
# ────────────────────────────────────────

func _show_wip_popup() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	get_tree().root.add_child(layer)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	cs.corner_radius_top_left     = 32
	cs.corner_radius_top_right    = 32
	cs.corner_radius_bottom_left  = 32
	cs.corner_radius_bottom_right = 32
	cs.content_margin_left   = 64
	cs.content_margin_right  = 64
	cs.content_margin_top    = 52
	cs.content_margin_bottom = 52
	card.add_theme_stylebox_override("panel", cs)
	card.custom_minimum_size = Vector2(540, 0)
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 28)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vb)

	# Emoji icon
	var icon_lbl := Label.new()
	icon_lbl.text = "🚧"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 80)
	vb.add_child(icon_lbl)

	# Title
	var title_lbl := Label.new()
	title_lbl.text = "Coming Soon"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", FONT_TAB)
	title_lbl.add_theme_font_size_override("font_size", 36)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(title_lbl)

	# Sub-message
	var sub_lbl := Label.new()
	sub_lbl.text = "Better content is on the way!"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_override("font", FONT_TAB)
	sub_lbl.add_theme_font_size_override("font_size", 26)
	sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.95, 0.85))
	vb.add_child(sub_lbl)

	# OK button
	var ok_btn := Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(220, 76)
	ok_btn.add_theme_font_size_override("font_size", 32)
	var btn_st := StyleBoxFlat.new()
	btn_st.bg_color = Color("#6654D8")
	btn_st.corner_radius_top_left     = 18
	btn_st.corner_radius_top_right    = 18
	btn_st.corner_radius_bottom_left  = 18
	btn_st.corner_radius_bottom_right = 18
	ok_btn.add_theme_stylebox_override("normal", btn_st)
	var btn_st_h: StyleBoxFlat = btn_st.duplicate() as StyleBoxFlat
	btn_st_h.bg_color = Color("#7B6AEC")
	ok_btn.add_theme_stylebox_override("hover", btn_st_h)
	ok_btn.add_theme_stylebox_override("pressed", btn_st)
	ok_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	ok_btn.add_theme_color_override("font_color", Color.WHITE)
	ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(ok_btn)

	# Pop-in animation
	card.scale = Vector2(0.85, 0.85)
	card.pivot_offset = card.custom_minimum_size / 2.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_property(bg,   "color:a", 0.55, 0.15)

	var close_func: Callable = func() -> void:
		var tw2: Tween = create_tween()
		tw2.tween_property(bg, "color:a", 0.0, 0.12)
		await tw2.finished
		layer.queue_free()
	ok_btn.pressed.connect(close_func)
	bg.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			close_func.call()
	)
