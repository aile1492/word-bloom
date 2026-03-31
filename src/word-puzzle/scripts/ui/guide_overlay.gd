## guide_overlay.gd
## Tutorial guide overlay. Displays a spotlight, hand animation, and tooltip.
## Controlled via TutorialManager.show_guide(steps) / hide_guide().
## Follows P02_04 design spec.
class_name GuideOverlay
extends CanvasLayer


# ===== Constants =====

const HAND_ANIM_DURATION: float = 1.5
const HAND_PRESS_SCALE: float = 0.8
const TOOLTIP_APPEAR_DURATION: float = 0.3
const HAND_WAIT_BEFORE: float = 0.3
const HAND_WAIT_AFTER: float = 0.5


# ===== Node references =====

@onready var dim_rect: ColorRect = $DimRect
@onready var hand_icon: Control = $HandIcon
@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var message_label: Label = $TooltipPanel/MarginContainer/VBox/MessageLabel
@onready var dismiss_button: Button = $TooltipPanel/MarginContainer/VBox/DismissButton


# ===== State =====

var _steps: Array = []
var _current_step: int = 0
var _hand_tween: Tween = null
var _auto_tween: Tween = null
var _shader_material: ShaderMaterial = null


# ===== Initialization =====

func _ready() -> void:
	layer = 100  ## Top-most layer.
	visible = false
	dismiss_button.pressed.connect(_on_dismiss_pressed)

	## Spotlight shader setup.
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = load("res://shaders/spotlight.gdshader")
	dim_rect.material = _shader_material


# ===== Public API =====

func show_steps(steps: Array) -> void:
	_steps = steps
	_current_step = 0
	visible = true
	_show_step(_current_step)


func advance() -> void:
	_current_step += 1
	if _current_step >= _steps.size():
		hide_all()
	else:
		_show_step(_current_step)


func hide_all() -> void:
	visible = false
	_cancel_tweens()
	_steps = []
	_current_step = 0


# ===== Internal logic =====

func _show_step(index: int) -> void:
	if index >= _steps.size():
		hide_all()
		return

	var step: Dictionary = _steps[index] as Dictionary
	_cancel_tweens()

	## Spotlight setup.
	var spotlight: Rect2 = step.get("spotlight_rect", Rect2()) as Rect2
	if spotlight.size == Vector2.ZERO:
		## No spotlight: full dim, hole size 0.
		_shader_material.set_shader_parameter("hole_size", Vector2(0.0, 0.0))
	else:
		_shader_material.set_shader_parameter("hole_position",
			Vector2(spotlight.position.x + spotlight.size.x * 0.5,
					spotlight.position.y + spotlight.size.y * 0.5))
		_shader_material.set_shader_parameter("hole_size",
			Vector2(spotlight.size.x, spotlight.size.y))

	## Tooltip.
	var msg: String = step.get("message", "") as String
	message_label.text = msg
	tooltip_panel.visible = not msg.is_empty()

	var show_btn: bool = step.get("show_button", true) as bool
	dismiss_button.visible = show_btn

	## Tooltip fade-in.
	tooltip_panel.modulate.a = 0.0
	var tt: Tween = create_tween()
	tt.tween_property(tooltip_panel, "modulate:a", 1.0, TOOLTIP_APPEAR_DURATION)

	## Hand animation.
	var hand_from: Vector2 = step.get("hand_from", Vector2.ZERO) as Vector2
	var hand_to: Vector2 = step.get("hand_to", Vector2.ZERO) as Vector2
	if hand_from != Vector2.ZERO or hand_to != Vector2.ZERO:
		hand_icon.visible = true
		_start_hand_loop(hand_from, hand_to)
	else:
		hand_icon.visible = false

	## Auto-advance.
	var auto_adv: float = step.get("auto_advance", 0.0) as float
	if auto_adv > 0.0:
		_auto_tween = create_tween()
		_auto_tween.tween_interval(auto_adv)
		_auto_tween.tween_callback(advance)


func _start_hand_loop(from_pos: Vector2, to_pos: Vector2) -> void:
	hand_icon.position = from_pos
	hand_icon.scale = Vector2.ONE

	_hand_tween = create_tween().set_loops()
	_hand_tween.tween_interval(HAND_WAIT_BEFORE)
	_hand_tween.tween_property(hand_icon, "scale", Vector2(HAND_PRESS_SCALE, HAND_PRESS_SCALE), 0.1)
	_hand_tween.tween_property(hand_icon, "position", to_pos, HAND_ANIM_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hand_tween.tween_property(hand_icon, "scale", Vector2.ONE, 0.1)
	_hand_tween.tween_interval(HAND_WAIT_AFTER)
	_hand_tween.tween_property(hand_icon, "position", from_pos, 0.0)


func _cancel_tweens() -> void:
	if _hand_tween and _hand_tween.is_valid():
		_hand_tween.kill()
	_hand_tween = null
	if _auto_tween and _auto_tween.is_valid():
		_auto_tween.kill()
	_auto_tween = null


func _on_dismiss_pressed() -> void:
	advance()
