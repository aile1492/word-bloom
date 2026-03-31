## daily_screen.gd
## Daily Challenge screen - Coming Soon placeholder.
class_name DailyScreen
extends BaseScreen


func _ready() -> void:
	_build_coming_soon_ui()


func enter(_data: Dictionary = {}) -> void:
	pass


func _build_coming_soon_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	var icon_lbl := Label.new()
	icon_lbl.text = "📅"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 72)
	vbox.add_child(icon_lbl)

	var title_lbl := Label.new()
	title_lbl.text = "Daily Challenge"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 36)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title_lbl)

	var badge := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color("#E91E8C", 0.25)
	bs.corner_radius_top_left     = 9999
	bs.corner_radius_top_right    = 9999
	bs.corner_radius_bottom_left  = 9999
	bs.corner_radius_bottom_right = 9999
	bs.content_margin_left   = 28
	bs.content_margin_right  = 28
	bs.content_margin_top    = 10
	bs.content_margin_bottom = 10
	badge.add_theme_stylebox_override("panel", bs)
	vbox.add_child(badge)

	var badge_lbl := Label.new()
	badge_lbl.text = "Coming Soon"
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.add_theme_font_size_override("font_size", 22)
	badge_lbl.add_theme_color_override("font_color", Color("#E91E8C"))
	badge.add_child(badge_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = "A fresh word puzzle every day"
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 20)
	desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(desc_lbl)
