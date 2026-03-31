extends Node

## Singleton responsible for local save/load.
## Follows P02_03 design spec: full SaveData schema, backup/restore, migration, typed API.

const SAVE_PATH: String = "user://save_data.json"
const BACKUP_PATH: String = "user://save_data.backup.json"
const SAVE_VERSION: int = 2

signal data_loaded()
signal data_saved()
signal data_reset()
signal coin_balance_changed(new_balance: int)

var _data: Dictionary = {}


func _ready() -> void:
	_load_data()
	_ensure_defaults()
	data_loaded.emit()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_WM_CLOSE_REQUEST:
			_save_data()


# ============================================================
# Save / Load internals
# ============================================================

func _save_data() -> void:
	## Backup first: copy current main file to .backup.json.
	if FileAccess.file_exists(SAVE_PATH):
		var src := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if src:
			var content: String = src.get_as_text()
			src.close()
			var bak := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if bak:
				bak.store_string(content)
				bak.close()
	## Write main file.
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_data, "\t"))
		file.close()
	data_saved.emit()


func _load_data() -> void:
	## Try main file → backup → empty dict.
	if _try_load_file(SAVE_PATH):
		return
	if _try_load_file(BACKUP_PATH):
		push_warning("SaveManager: Restored from backup file.")
		_save_data()  # Recreate main file.
		return
	_data = {}


func _try_load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var json := JSON.new()
	var err: int = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return false
	if not json.data is Dictionary:
		return false
	_data = json.data
	return true


# ============================================================
# Migration & defaults
# ============================================================

func _ensure_defaults() -> void:
	## Step-by-step version migration.
	var ver: int = _data.get("version", 0) as int
	if ver < 1:
		_migrate_v0_to_v1()
	if ver < 2:
		_migrate_v1_to_v2()

	## Top-level scalar fields.
	if not _data.has("version"):              _data["version"] = SAVE_VERSION
	if not _data.has("coin_balance"):         _data["coin_balance"] = 300
	if not _data.has("selected_avatar_index"): _data["selected_avatar_index"] = 0
	if not _data.has("nickname"):             _data["nickname"] = _generate_guest_name()
	if not _data.has("current_stage"):        _data["current_stage"] = 1
	if not _data.has("unlocked_themes"):      _data["unlocked_themes"] = ["animals", "food"]
	if not _data.has("best_times"):           _data["best_times"] = {"classic": 999.0, "time_attack": 999.0}
	if not _data.has("daily_streak"):         _data["daily_streak"] = 0
	if not _data.has("last_play_date"):       _data["last_play_date"] = ""
	if not _data.has("last_daily_date"):      _data["last_daily_date"] = ""
	if not _data.has("tutorial_completed"):   _data["tutorial_completed"] = true
	## Force-complete tutorial even if an old save has false (onboarding removed).
	_data["tutorial_completed"] = true
	if not _data.has("achievements"):         _data["achievements"] = {}
	if not _data.has("last_theme"):           _data["last_theme"] = ""
	if not _data.has("dda_offset"):           _data["dda_offset"] = 0
	if not _data.has("dda_history"):          _data["dda_history"] = []
	if not _data.has("resume_state"):         _data["resume_state"] = {}

	## stats sub-dictionary.
	if not _data.has("stats"):
		_data["stats"] = {}
	var s: Dictionary = _data["stats"] as Dictionary
	if not s.has("total_games"):         s["total_games"] = 0
	if not s.has("total_words_found"):   s["total_words_found"] = 0
	if not s.has("total_play_time"):     s["total_play_time"] = 0.0
	if not s.has("total_coins_earned"):  s["total_coins_earned"] = 0
	if not s.has("classic_clears"):      s["classic_clears"] = 0
	if not s.has("time_attack_clears"):  s["time_attack_clears"] = 0
	if not s.has("daily_clears"):        s["daily_clears"] = 0
	if not s.has("used_themes"):         s["used_themes"] = []

	## settings sub-dictionary.
	if not _data.has("settings"):
		_data["settings"] = {}
	var st: Dictionary = _data["settings"] as Dictionary
	if not st.has("sound_enabled"):   st["sound_enabled"] = true
	if not st.has("music_enabled"):   st["music_enabled"] = true
	if not st.has("is_dark_theme"):   st["is_dark_theme"] = false
	if not st.has("language_index"):  st["language_index"] = 0
	if not st.has("font_size_index"): st["font_size_index"] = 1

	## daily_login sub-dictionary.
	if not _data.has("daily_login"):
		_data["daily_login"] = {}
	var dl: Dictionary = _data["daily_login"] as Dictionary
	if not dl.has("last_login_date"):  dl["last_login_date"] = ""
	if not dl.has("consecutive_days"): dl["consecutive_days"] = 0
	if not dl.has("claimed_today"):    dl["claimed_today"] = false

	## accessibility sub-dictionary.
	if not _data.has("accessibility"):
		_data["accessibility"] = {}
	var ac: Dictionary = _data["accessibility"] as Dictionary
	if not ac.has("font_scale"):              ac["font_scale"] = 1
	if not ac.has("dark_mode"):               ac["dark_mode"] = false
	if not ac.has("dark_mode_follow_system"): ac["dark_mode_follow_system"] = true
	if not ac.has("reduce_motion"):           ac["reduce_motion"] = false

	_data["version"] = SAVE_VERSION


func _migrate_v0_to_v1() -> void:
	## last_stage → current_stage
	if _data.has("last_stage") and not _data.has("current_stage"):
		_data["current_stage"] = _data["last_stage"]
		_data.erase("last_stage")
	## coins → coin_balance
	if _data.has("coins") and not _data.has("coin_balance"):
		_data["coin_balance"] = _data["coins"]
		_data.erase("coins")


func _migrate_v1_to_v2() -> void:
	## v2: no structural changes (placeholder for future migrations).
	pass


func _generate_guest_name() -> String:
	return "Guest_%05d" % randi_range(0, 99999)


# ============================================================
# Generic API — backward-compat (used by game_controller etc.)
# ============================================================

## Store a key-value pair immediately.
func save_value(key: String, value: Variant) -> void:
	_data[key] = value
	_save_data()


## Load a value by key. Returns default if not found.
func load_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)


# ============================================================
# Stage progression
# ============================================================

func get_current_stage() -> int:
	return _data.get("current_stage", 1) as int


func set_current_stage(stage: int) -> void:
	_data["current_stage"] = stage
	_save_data()


# ============================================================
# Coins
# ============================================================

func get_coin_balance() -> int:
	return _data.get("coin_balance", 0) as int


func add_coins(amount: int) -> void:
	var current: int = get_coin_balance()
	_data["coin_balance"] = current + amount
	var s: Dictionary = _data["stats"] as Dictionary
	s["total_coins_earned"] = (s.get("total_coins_earned", 0) as int) + amount
	coin_balance_changed.emit(_data["coin_balance"] as int)
	_save_data()


## Spend coins. Returns false if balance is insufficient.
func spend_coins(amount: int) -> bool:
	var current: int = get_coin_balance()
	if current < amount:
		return false
	_data["coin_balance"] = current - amount
	coin_balance_changed.emit(_data["coin_balance"] as int)
	_save_data()
	return true


# ============================================================
# Themes
# ============================================================

func get_unlocked_themes() -> Array[String]:
	var raw: Array = _data.get("unlocked_themes", ["animals", "food"]) as Array
	var result: Array[String] = []
	for item: Variant in raw:
		result.append(item as String)
	return result


func unlock_theme(theme_id: String) -> void:
	var themes: Array = _data.get("unlocked_themes", ["animals", "food"]) as Array
	if theme_id not in themes:
		themes.append(theme_id)
		_data["unlocked_themes"] = themes
		_save_data()


func add_used_theme(theme_id: String) -> void:
	var s: Dictionary = _data["stats"] as Dictionary
	var used: Array = s.get("used_themes", []) as Array
	if theme_id not in used:
		used.append(theme_id)
		s["used_themes"] = used
		_save_data()


func get_last_theme() -> String:
	return _data.get("last_theme", "") as String


func set_last_theme(theme: String) -> void:
	_data["last_theme"] = theme
	# Write directly to avoid duplicate signals.
	_save_data()


# ============================================================
# Best times
# ============================================================

func get_best_time(mode_key: String) -> float:
	var bt: Dictionary = _data.get("best_times", {}) as Dictionary
	return bt.get(mode_key, 999.0) as float


func set_best_time(mode_key: String, time: float) -> void:
	var bt: Dictionary = _data["best_times"] as Dictionary
	bt[mode_key] = time
	_save_data()


## Updates best time from a result. Returns true if a new record was set.
func check_and_update_best_time(mode_key: String, clear_time: float) -> bool:
	var current_best: float = get_best_time(mode_key)
	if clear_time < current_best:
		set_best_time(mode_key, clear_time)
		return true
	return false


# ============================================================
# Stats
# ============================================================

func get_stats() -> Dictionary:
	return _data.get("stats", {}) as Dictionary


## Updates stats from a GameResult.
## Requires GameResult.is_cleared, .words_found, .mode, .clear_time (added in STEP2).
func update_stats(result: GameResult) -> void:
	var s: Dictionary = _data["stats"] as Dictionary
	s["total_games"] = (s.get("total_games", 0) as int) + 1
	s["total_words_found"] = (s.get("total_words_found", 0) as int) + result.words_found
	s["total_play_time"] = (s.get("total_play_time", 0.0) as float) + result.clear_time
	if result.is_cleared:
		## mode integer: 0=CLASSIC, 1=TIME_ATTACK, 2=DAILY_CHALLENGE (GameManager.GameMode).
		match result.mode:
			0: s["classic_clears"] = (s.get("classic_clears", 0) as int) + 1
			1: s["time_attack_clears"] = (s.get("time_attack_clears", 0) as int) + 1
			2: s["daily_clears"] = (s.get("daily_clears", 0) as int) + 1
	_save_data()


# ============================================================
# Settings
# ============================================================

func get_settings() -> Dictionary:
	return _data.get("settings", {}) as Dictionary


func get_setting(key: String, default: Variant = null) -> Variant:
	var st: Dictionary = _data.get("settings", {}) as Dictionary
	return st.get(key, default)


func update_setting(key: String, value: Variant) -> void:
	var st: Dictionary = _data["settings"] as Dictionary
	st[key] = value
	_save_data()


# ============================================================
# Nickname / Avatar
# ============================================================

func get_nickname() -> String:
	return _data.get("nickname", "") as String


func set_nickname(new_name: String) -> void:
	_data["nickname"] = new_name
	_save_data()


func get_avatar_index() -> int:
	return _data.get("selected_avatar_index", 0) as int


func set_avatar_index(index: int) -> void:
	_data["selected_avatar_index"] = index
	_save_data()


# ============================================================
# Tutorial
# ============================================================

func is_tutorial_completed() -> bool:
	return _data.get("tutorial_completed", false) as bool


func set_tutorial_completed(completed: bool) -> void:
	_data["tutorial_completed"] = completed
	_save_data()


# ============================================================
# DDA (backward-compat + new API)
# ============================================================

func get_dda_history() -> Array:
	return _data.get("dda_history", []) as Array


func add_dda_entry(entry: Dictionary) -> void:
	var history: Array = _data.get("dda_history", []) as Array
	history.append(entry)
	while history.size() > 20:
		history.pop_front()
	_data["dda_history"] = history
	_save_data()


# ============================================================
# Daily attendance
# ============================================================

func get_daily_streak() -> int:
	return _data.get("daily_streak", 0) as int


func update_daily_streak(new_streak: int) -> void:
	_data["daily_streak"] = new_streak
	_save_data()


func get_daily_login() -> Dictionary:
	return _data.get("daily_login", {}) as Dictionary


func update_daily_login(login_data: Dictionary) -> void:
	_data["daily_login"] = login_data
	_save_data()


# ============================================================
# Resume state
# ============================================================

func get_resume_state() -> Dictionary:
	return _data.get("resume_state", {}) as Dictionary


func set_resume_state(state: Dictionary) -> void:
	_data["resume_state"] = state
	_save_data()


func clear_resume_state() -> void:
	_data["resume_state"] = {}
	_save_data()


# ============================================================
# Achievements
# ============================================================

func get_achievements() -> Dictionary:
	return _data.get("achievements", {}) as Dictionary


func set_achievement(key: String, value: Variant) -> void:
	var ach: Dictionary = _data["achievements"] as Dictionary
	ach[key] = value
	_save_data()


# ============================================================
# Accessibility
# ============================================================

func get_accessibility() -> Dictionary:
	return _data.get("accessibility", {}) as Dictionary


func update_accessibility(key: String, value: Variant) -> void:
	var ac: Dictionary = _data["accessibility"] as Dictionary
	ac[key] = value
	_save_data()


# ============================================================
# Full reset
# ============================================================

func reset_data() -> void:
	_data = {}
	_ensure_defaults()
	_save_data()
	data_reset.emit()
