## language_select_screen.gd
## Language selection screen shown on first launch.
## Follows the P02_04 design spec.
class_name LanguageSelectScreen
extends BaseScreen

const PROFILE_SETUP_SCENE: String = "res://scenes/screens/profile_setup_screen.tscn"


# ===== Node references =====

@onready var en_button: Button = $VBox/ButtonContainer/EnButton
@onready var ko_button: Button = $VBox/ButtonContainer/KoButton


# ===== BaseScreen overrides =====

func enter(_data: Dictionary = {}) -> void:
	if not en_button.pressed.is_connected(_on_en_selected):
		en_button.pressed.connect(_on_en_selected)
	if not ko_button.pressed.is_connected(_on_ko_selected):
		ko_button.pressed.connect(_on_ko_selected)


func exit() -> void:
	pass


# ===== Event handling =====

func _on_en_selected() -> void:
	_set_language(0)


func _on_ko_selected() -> void:
	_set_language(1)


func _set_language(index: int) -> void:
	SaveManager.update_setting("language_index", index)
	var locale: String = "ko" if index == 1 else "en"
	TranslationServer.set_locale(locale)
	## Proceed to profile setup.
	ScreenManager.replace_top_screen(PROFILE_SETUP_SCENE)
