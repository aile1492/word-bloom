## login_screen.gd
## Login screen. Facebook login or guest play.
## On success, navigates to main_scene.
extends Control


const BG_PATH    := "res://assets/backgrounds/login_bg.png"
const MAIN_SCENE := "res://scenes/main_scene.tscn"


func _ready() -> void:
	_setup_background()
	_setup_ui()


func _setup_background() -> void:
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(BG_PATH):
		bg.texture = ResourceLoader.load(BG_PATH) as Texture2D
	else:
		# Dark green placeholder when background image is absent.
		bg.modulate = Color(0.15, 0.35, 0.2, 1.0)
	add_child(bg)
	move_child(bg, 0)

	# Semi-transparent dark overlay — above background, below UI content.
	var overlay := ColorRect.new()
	overlay.name = "DarkOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.30)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	move_child(overlay, 1)


func _setup_ui() -> void:
	# ── Game title (top center) ──────────────────────────
	var title_container := Control.new()
	title_container.anchor_left   = 0.0
	title_container.anchor_right  = 1.0
	title_container.anchor_top    = 0.08
	title_container.anchor_bottom = 0.28
	add_child(title_container)

	var title_label := Label.new()
	title_label.text = "Word Bloom"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_label.add_theme_font_size_override("font_size", 96)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	title_container.add_child(title_label)

	# ── Button area (bottom center) ────────────────────────────
	var btn_area := Control.new()
	btn_area.anchor_left   = 0.08
	btn_area.anchor_right  = 0.92
	btn_area.anchor_top    = 0.60
	btn_area.anchor_bottom = 0.86
	add_child(btn_area)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 32)
	btn_area.add_child(vbox)

	# Facebook login button (disabled — coming soon)
	var fb_wrapper := VBoxContainer.new()
	fb_wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	fb_wrapper.add_theme_constant_override("separation", 10)
	vbox.add_child(fb_wrapper)

	var fb_btn: Button = _make_button(
		"  Log in with Facebook",
		Color("#1877F2"),
		Color.WHITE,
		true
	)
	fb_btn.disabled  = true
	fb_btn.modulate  = Color(1.0, 1.0, 1.0, 0.40)   ## Dimmed to indicate disabled state.
	fb_wrapper.add_child(fb_btn)

	var coming_lbl := Label.new()
	coming_lbl.text = "🔒  Coming Soon"
	coming_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coming_lbl.add_theme_font_size_override("font_size", 24)
	coming_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.38))
	fb_wrapper.add_child(coming_lbl)

	# Guest play button
	var guest_btn: Button = _make_button(
		"Play as Guest",
		Color(0.08, 0.08, 0.1, 0.82),
		Color.WHITE,
		false
	)
	guest_btn.pressed.connect(_on_guest_pressed)
	vbox.add_child(guest_btn)


func _make_button(label_text: String, bg_color: Color, fg_color: Color, has_border: bool) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size   = Vector2(0, 100)

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left     = 50
	style.corner_radius_top_right    = 50
	style.corner_radius_bottom_left  = 50
	style.corner_radius_bottom_right = 50
	style.content_margin_left   = 32
	style.content_margin_right  = 32
	style.content_margin_top    = 16
	style.content_margin_bottom = 16
	if has_border:
		style.border_width_left   = 0
		style.border_width_right  = 0
		style.border_width_top    = 0
		style.border_width_bottom = 0
	else:
		style.border_width_left   = 2
		style.border_width_right  = 2
		style.border_width_top    = 2
		style.border_width_bottom = 2
		style.border_color = Color(1, 1, 1, 0.5)

	var style_hover := style.duplicate() as StyleBoxFlat
	style_hover.bg_color = bg_color.lightened(0.1)

	var style_pressed := style.duplicate() as StyleBoxFlat
	style_pressed.bg_color = bg_color.darkened(0.15)

	btn.add_theme_stylebox_override("normal",  style)
	btn.add_theme_stylebox_override("hover",   style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", fg_color)
	btn.add_theme_font_size_override("font_size", 36)
	return btn


func _on_facebook_pressed() -> void:
	# TODO: Facebook SDK integration pending.
	# For now, behaves the same as guest login.
	_go_to_main()


func _on_guest_pressed() -> void:
	_go_to_main()


func _go_to_main() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)
