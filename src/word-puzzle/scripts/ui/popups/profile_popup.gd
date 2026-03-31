## profile_popup.gd
## Profile popup. Displays avatar, nickname, and stats.
## Open via ScreenManager.open_popup("profile").
class_name ProfilePopup
extends BaseScreen


# ===== Node references =====

@onready var close_button: Button = $Panel/VBox/TopRow/CloseButton
@onready var avatar_button: Button = $Panel/VBox/AvatarRow/AvatarButton
@onready var nickname_label: Label = $Panel/VBox/AvatarRow/NicknameLabel
@onready var edit_nickname_button: Button = $Panel/VBox/AvatarRow/EditNicknameButton
@onready var stage_label: Label = $Panel/VBox/StatsGrid/StageLabel
@onready var clears_label: Label = $Panel/VBox/StatsGrid/ClearsLabel
@onready var words_label: Label = $Panel/VBox/StatsGrid/WordsLabel
@onready var playtime_label: Label = $Panel/VBox/StatsGrid/PlaytimeLabel
@onready var coins_label: Label = $Panel/VBox/StatsGrid/CoinsLabel
@onready var best_classic_label: Label = $Panel/VBox/StatsGrid/BestClassicLabel
@onready var nickname_edit: LineEdit = $Panel/VBox/NicknameEditRow/NicknameEdit
@onready var nickname_edit_row: HBoxContainer = $Panel/VBox/NicknameEditRow
@onready var confirm_nickname_button: Button = $Panel/VBox/NicknameEditRow/ConfirmButton


# ===== BaseScreen overrides =====

func enter(_data: Dictionary = {}) -> void:
	_refresh_ui()
	_connect_signals()
	nickname_edit_row.visible = false


func exit() -> void:
	pass


# ===== Initialization =====

func _connect_signals() -> void:
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if not avatar_button.pressed.is_connected(_on_avatar_pressed):
		avatar_button.pressed.connect(_on_avatar_pressed)
	if not edit_nickname_button.pressed.is_connected(_on_edit_nickname_pressed):
		edit_nickname_button.pressed.connect(_on_edit_nickname_pressed)
	if not confirm_nickname_button.pressed.is_connected(_on_confirm_nickname_pressed):
		confirm_nickname_button.pressed.connect(_on_confirm_nickname_pressed)


func _refresh_ui() -> void:
	nickname_label.text = SaveManager.get_nickname()

	var stats: Dictionary = SaveManager.get_stats()
	stage_label.text = "Stage: %d" % SaveManager.get_current_stage()
	clears_label.text = "Clears: %d" % (stats.get("classic_clears", 0) as int)
	words_label.text = "Words Found: %d" % (stats.get("total_words_found", 0) as int)

	var play_sec: float = stats.get("total_play_time", 0.0) as float
	var play_min: int = int(play_sec / 60)
	playtime_label.text = "Play Time: %d min" % play_min

	coins_label.text = "Coins Earned: %d" % (stats.get("total_coins_earned", 0) as int)

	var best_classic: float = SaveManager.get_best_time("classic")
	if best_classic < 999.0:
		best_classic_label.text = "Classic Best: %.1fs" % best_classic
	else:
		best_classic_label.text = "Classic Best: -"


# ===== Event handlers =====

func _on_close_pressed() -> void:
	ScreenManager.hide_popup()


func _on_avatar_pressed() -> void:
	ScreenManager.open_popup("avatar_select")


func _on_edit_nickname_pressed() -> void:
	nickname_edit_row.visible = true
	nickname_edit.text = SaveManager.get_nickname()
	nickname_edit.grab_focus()


func _on_confirm_nickname_pressed() -> void:
	var new_name: String = nickname_edit.text.strip_edges()
	if new_name.length() > 0 and new_name.length() <= 16:
		SaveManager.set_nickname(new_name)
		nickname_label.text = new_name
	nickname_edit_row.visible = false
