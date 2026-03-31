## profile_setup_screen.gd
## Profile setup screen shown on first launch (nickname entry).
## Follows the P02_04 design spec.
class_name ProfileSetupScreen
extends BaseScreen


# ===== Node references =====

@onready var nickname_edit: LineEdit = $VBox/NicknameEdit
@onready var confirm_button: Button = $VBox/ButtonRow/ConfirmButton


# ===== BaseScreen overrides =====

func enter(_data: Dictionary = {}) -> void:
	nickname_edit.text = SaveManager.get_nickname()
	if not confirm_button.pressed.is_connected(_on_confirm_pressed):
		confirm_button.pressed.connect(_on_confirm_pressed)


func exit() -> void:
	pass


# ===== Event handling =====

func _on_confirm_pressed() -> void:
	var name_text: String = nickname_edit.text.strip_edges()
	if name_text.length() > 0 and name_text.length() <= 16:
		SaveManager.set_nickname(name_text)
	_start_tutorial()


func _start_tutorial() -> void:
	## Mark onboarding (language + nickname) as complete immediately.
	## Even if the player doesn't finish the tutorial, it won't repeat on the next launch.
	SaveManager.set_tutorial_completed(true)
	TutorialManager.start_tutorial()
