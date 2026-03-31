## settings_popup.gd
## Settings popup. Adjusts sound, music, dark mode, language, and font size.
## Open via ScreenManager.open_popup("settings").
class_name SettingsPopup
extends BaseScreen


# ===== Node references =====

@onready var close_button: Button = $Panel/VBox/TopRow/CloseButton
@onready var sound_toggle: CheckButton = $Panel/VBox/SoundRow/SoundToggle
@onready var music_toggle: CheckButton = $Panel/VBox/MusicRow/MusicToggle
@onready var dark_toggle: CheckButton = $Panel/VBox/DarkRow/DarkToggle
@onready var lang_option: OptionButton = $Panel/VBox/LangRow/LangOption
@onready var font_option: OptionButton = $Panel/VBox/FontRow/FontOption


# ===== BaseScreen overrides =====

func enter(_data: Dictionary = {}) -> void:
	_load_settings()
	_connect_signals()


func exit() -> void:
	pass


# ===== Initialization =====

func _ready() -> void:
	## Language option items
	lang_option.add_item("English", 0)
	lang_option.add_item("Korean", 1)
	## Font size options
	font_option.add_item("Small", 0)
	font_option.add_item("Medium", 1)
	font_option.add_item("Large", 2)


func _connect_signals() -> void:
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if not sound_toggle.toggled.is_connected(_on_sound_toggled):
		sound_toggle.toggled.connect(_on_sound_toggled)
	if not music_toggle.toggled.is_connected(_on_music_toggled):
		music_toggle.toggled.connect(_on_music_toggled)
	if not dark_toggle.toggled.is_connected(_on_dark_toggled):
		dark_toggle.toggled.connect(_on_dark_toggled)
	if not lang_option.item_selected.is_connected(_on_lang_selected):
		lang_option.item_selected.connect(_on_lang_selected)
	if not font_option.item_selected.is_connected(_on_font_selected):
		font_option.item_selected.connect(_on_font_selected)


func _load_settings() -> void:
	sound_toggle.button_pressed = SaveManager.get_setting("sound_enabled", true) as bool
	music_toggle.button_pressed = SaveManager.get_setting("music_enabled", true) as bool
	dark_toggle.button_pressed = SaveManager.get_setting("is_dark_theme", false) as bool
	lang_option.selected = SaveManager.get_setting("language_index", 0) as int
	font_option.selected = SaveManager.get_setting("font_size_index", 1) as int


# ===== Event handlers =====

func _on_close_pressed() -> void:
	ScreenManager.hide_popup()


func _on_sound_toggled(pressed: bool) -> void:
	SaveManager.update_setting("sound_enabled", pressed)
	if AudioManager:
		AudioManager.set_sfx_enabled(pressed)


func _on_music_toggled(pressed: bool) -> void:
	SaveManager.update_setting("music_enabled", pressed)
	if AudioManager:
		AudioManager.set_music_enabled(pressed)


func _on_dark_toggled(pressed: bool) -> void:
	SaveManager.update_setting("is_dark_theme", pressed)
	SaveManager.update_accessibility("dark_mode", pressed)


func _on_lang_selected(index: int) -> void:
	SaveManager.update_setting("language_index", index)
	var locale: String = "ko" if index == 1 else "en"
	TranslationServer.set_locale(locale)


func _on_font_selected(index: int) -> void:
	SaveManager.update_setting("font_size_index", index)
