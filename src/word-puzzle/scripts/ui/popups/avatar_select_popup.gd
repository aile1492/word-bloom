## avatar_select_popup.gd
## Avatar selection popup. Displays a grid of avatar buttons (indices 0–20).
## Opened via ScreenManager.open_popup("avatar_select").
class_name AvatarSelectPopup
extends BaseScreen

const AVATAR_COUNT: int = 21  ## Avatars 0–20.

@onready var close_button: Button = $Panel/VBox/TopRow/CloseButton
@onready var avatar_grid: GridContainer = $Panel/VBox/ScrollContainer/AvatarGrid

var _avatar_buttons: Array[Button] = []


func enter(_data: Dictionary = {}) -> void:
	_build_grid()
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)


func exit() -> void:
	pass


func _build_grid() -> void:
	## Remove existing buttons.
	for child in avatar_grid.get_children():
		child.queue_free()
	_avatar_buttons.clear()

	var current_index: int = SaveManager.get_avatar_index()

	for i: int in range(AVATAR_COUNT):
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.text = "Av\n%d" % i  ## Fallback number label when no asset is present.
		if i == current_index:
			btn.modulate = Color(1.0, 0.8, 0.0, 1.0)  ## Highlight the selected avatar.
		var idx: int = i  ## Capture for closure.
		btn.pressed.connect(func() -> void: _on_avatar_selected(idx))
		avatar_grid.add_child(btn)
		_avatar_buttons.append(btn)


func _on_avatar_selected(index: int) -> void:
	SaveManager.set_avatar_index(index)
	## Refresh the selection highlight.
	for i: int in range(_avatar_buttons.size()):
		_avatar_buttons[i].modulate = Color(1.0, 0.8, 0.0, 1.0) if i == index else Color.WHITE
	## Return to ProfilePopup.
	ScreenManager.open_popup("profile")


func _on_close_pressed() -> void:
	ScreenManager.hide_popup()
