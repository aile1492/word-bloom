## toast_manager.gd
## Autoload singleton that displays slide-in Toast notifications from the top of the screen.
## Follows the P02_04 design spec.
extends Node


# ===== Constants =====

const TOAST_DURATION: float = 3.0
const SLIDE_DURATION: float = 0.3
const TOAST_HEIGHT: float = 64.0
const TOAST_OFFSET_TOP: float = 48.0


# ===== State =====

var _queue: Array[String] = []
var _is_showing: bool = false
var _toast_node: Control = null
var _tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# ===== Public API =====

## Enqueues a Toast message. Messages are displayed in order automatically.
func show_toast(message: String) -> void:
	_queue.append(message)
	if not _is_showing:
		_show_next()


# ===== Internal =====

func _show_next() -> void:
	if _queue.is_empty():
		_is_showing = false
		return

	_is_showing = true
	var message: String = _queue.pop_front()
	_create_toast(message)


func _create_toast(message: String) -> void:
	## Remove any existing toast.
	if _toast_node and is_instance_valid(_toast_node):
		_toast_node.queue_free()

	## Build the Toast node.
	var toast: PanelContainer = PanelContainer.new()
	toast.custom_minimum_size = Vector2(400, TOAST_HEIGHT)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	toast.add_theme_stylebox_override("panel", style)

	var label: Label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(label)
	toast.add_child(margin)

	## Add to a CanvasLayer so it always renders on top.
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 200
	get_tree().root.add_child(canvas)
	canvas.add_child(toast)

	## Position: centered at the top of the screen, initially hidden above the viewport.
	toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	toast.position = Vector2((viewport_width - 400) * 0.5, -TOAST_HEIGHT)

	_toast_node = toast

	## Slide in.
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = toast.create_tween()
	_tween.tween_property(toast, "position:y", TOAST_OFFSET_TOP, SLIDE_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	## Hold.
	_tween.tween_interval(TOAST_DURATION)
	## Slide out.
	_tween.tween_property(toast, "position:y", -TOAST_HEIGHT, SLIDE_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	## Clean up.
	_tween.tween_callback(func() -> void:
		canvas.queue_free()
		_toast_node = null
		_show_next()
	)
