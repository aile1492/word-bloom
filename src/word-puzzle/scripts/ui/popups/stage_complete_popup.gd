## stage_complete_popup.gd
## In-game overlay popup shown when a stage is cleared.
## Displayed on top of the game screen via CanvasLayer (layer=10).
class_name StageCompletePopup
extends CanvasLayer

const FONT_UI:    Font = preload("res://assets/fonts/Nunito-Variable.ttf")
const FONT_TITLE: Font = preload("res://assets/fonts/LuckiestGuy-Regular.ttf")


## Emitted when the player taps the "Next Stage" button.
signal next_pressed


# ===== UI 노드 참조 =====

var _overlay:     ColorRect      = null
var _card:        PanelContainer = null
var _stage_lbl:   Label          = null
var _next_btn:    Button         = null
var _anim_tween:  Tween          = null   ## Active tween — prevents duplicate animations.


# ===== 초기화 =====

func _ready() -> void:
	layer   = 10
	visible = false
	_build_ui()


func _build_ui() -> void:
	# ── Semi-transparent full-screen overlay ──
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.47)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# ── Center card ──
	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.grow_vertical   = Control.GROW_DIRECTION_BOTH
	_card.custom_minimum_size = Vector2(380, 0)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#1C1C1E")
	card_style.corner_radius_top_left     = 28
	card_style.corner_radius_top_right    = 28
	card_style.corner_radius_bottom_left  = 28
	card_style.corner_radius_bottom_right = 28
	card_style.content_margin_left   = 44.0
	card_style.content_margin_right  = 44.0
	card_style.content_margin_top    = 48.0
	card_style.content_margin_bottom = 48.0
	_card.add_theme_stylebox_override("panel", card_style)
	_overlay.add_child(_card)

	# ── VBox (card interior) ──
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	_card.add_child(vbox)

	# Title
	var title_lbl := Label.new()
	title_lbl.text = "STAGE CLEAR!"
	title_lbl.add_theme_font_override("font", FONT_TITLE)
	title_lbl.add_theme_font_size_override("font_size", 36)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	# Stage number
	_stage_lbl = Label.new()
	_stage_lbl.add_theme_font_override("font", FONT_UI)
	_stage_lbl.add_theme_font_size_override("font_size", 18)
	_stage_lbl.add_theme_color_override("font_color", Color("#AAAAAA"))
	_stage_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_stage_lbl)

	# Next stage button
	_next_btn = Button.new()
	_next_btn.text = "Next Stage  →"
	_next_btn.custom_minimum_size = Vector2(300, 68)
	_next_btn.add_theme_font_override("font", FONT_UI)
	_next_btn.add_theme_font_size_override("font_size", 22)
	_next_btn.add_theme_color_override("font_color", Color.WHITE)

	var btn_n := StyleBoxFlat.new()
	btn_n.bg_color = Color("#E91E8C")
	btn_n.corner_radius_top_left     = 9999
	btn_n.corner_radius_top_right    = 9999
	btn_n.corner_radius_bottom_left  = 9999
	btn_n.corner_radius_bottom_right = 9999

	var btn_h := btn_n.duplicate() as StyleBoxFlat
	btn_h.bg_color = Color("#FF2FA0")
	var btn_p := btn_n.duplicate() as StyleBoxFlat
	btn_p.bg_color = Color("#C2185B")

	_next_btn.add_theme_stylebox_override("normal",  btn_n)
	_next_btn.add_theme_stylebox_override("hover",   btn_h)
	_next_btn.add_theme_stylebox_override("pressed", btn_p)
	_next_btn.pressed.connect(func() -> void: next_pressed.emit())
	vbox.add_child(_next_btn)


# ===== 공개 API =====

## Shows the popup with overlay fade-in and card pop-in animation.
func show_popup(stage: int) -> void:
	_stage_lbl.text  = "Stage %d" % stage

	visible          = true
	_card.modulate.a = 0.0
	_card.scale      = Vector2(0.82, 0.82)
	_overlay.color.a = 0.0

	# Kill any in-progress animation before starting a new one.
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()

	_anim_tween = create_tween().set_parallel(true)
	_anim_tween.tween_property(_overlay, "color:a",    0.47,        0.22)
	_anim_tween.tween_property(_card,    "modulate:a", 1.0,         0.20)
	_anim_tween.tween_property(_card,    "scale",      Vector2.ONE, 0.24)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
