## feature_unlock_popup.gd
## Feature unlock notification popup. Used for Time Attack, Daily Challenge, returning users, etc.
## Open via ScreenManager.open_popup("feature_unlock", {"feature": "time_attack"}).
## Follows P02_04 design spec.
class_name FeatureUnlockPopup
extends BaseScreen


# ===== Node references =====

@onready var icon_label: Label = $Panel/VBox/IconLabel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var desc_label: Label = $Panel/VBox/DescLabel
@onready var try_button: Button = $Panel/VBox/ButtonRow/TryButton
@onready var later_button: Button = $Panel/VBox/ButtonRow/LaterButton


# ===== State =====

var _feature: String = ""


# ===== BaseScreen overrides =====

func enter(data: Dictionary = {}) -> void:
	_feature = data.get("feature", "") as String
	_setup_content(data)
	if not try_button.pressed.is_connected(_on_try_pressed):
		try_button.pressed.connect(_on_try_pressed)
	if not later_button.pressed.is_connected(_on_later_pressed):
		later_button.pressed.connect(_on_later_pressed)


func exit() -> void:
	pass


func _setup_content(data: Dictionary) -> void:
	match _feature:
		"time_attack":
			icon_label.text = "⏱️"
			title_label.text = "Time Attack Unlocked!"
			desc_label.text = "Find all words before the clock runs out!\nFaster clears earn higher scores!"
			try_button.text = "Try Now"
			try_button.visible = true

		"daily":
			icon_label.text = "📅"
			title_label.text = "Daily Challenge Unlocked!"
			desc_label.text = "A new puzzle every day.\nComplete it for special rewards!"
			try_button.text = "Try Now"
			try_button.visible = true

		"returning_user":
			var days: int = data.get("days_absent", 0) as int
			var stage: int = data.get("stage", 1) as int
			icon_label.text = "👋"
			title_label.text = "Welcome Back!"
			desc_label.text = "You've been away for %d day(s).\nPick up where you left off — Stage %d!" % [days, stage]
			try_button.text = "Continue"
			try_button.visible = true

		_:
			icon_label.text = "🎉"
			title_label.text = "New Feature Unlocked!"
			desc_label.text = ""
			try_button.visible = true


# ===== Event handlers =====

func _on_try_pressed() -> void:
	ScreenManager.hide_popup()
	## Navigate based on feature
	match _feature:
		"time_attack":
			## TODO: connect when Time Attack mode is implemented
			pass
		"daily":
			ScreenManager.switch_tab(0)  ## Daily tab (index 0)


func _on_later_pressed() -> void:
	ScreenManager.hide_popup()
