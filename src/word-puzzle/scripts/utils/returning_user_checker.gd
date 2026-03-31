## returning_user_checker.gd
## Utility for detecting returning users based on their last login date.
## Follows the P02_04 design spec.
class_name ReturningUserChecker

const ABSENCE_THRESHOLD_DAYS: int = 3


## Checks whether the current user is a returning user.
## Returns true and requests a welcome-back popup if absent for 3+ days.
static func check_and_welcome() -> bool:
	if not SaveManager.is_tutorial_completed():
		return false  ## New users go to tutorial first.

	var last_date_str: String = SaveManager.load_value("last_play_date", "") as String
	var today_str: String = _get_today_string()

	## Update the last play date.
	SaveManager.save_value("last_play_date", today_str)

	if last_date_str.is_empty():
		return false  ## First launch.

	var days_absent: int = _days_between(last_date_str, today_str)
	if days_absent >= ABSENCE_THRESHOLD_DAYS:
		## Reuse the feature_unlock popup with the "returning_user" type.
		if ScreenManager.has_method("open_popup"):
			ScreenManager.open_popup("feature_unlock", {
				"feature": "returning_user",
				"days_absent": days_absent,
				"stage": SaveManager.get_current_stage(),
			})
		return true

	return false


static func _get_today_string() -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]


static func _days_between(from_str: String, to_str: String) -> int:
	var from_unix: float = Time.get_unix_time_from_datetime_string(from_str + "T00:00:00")
	var to_unix: float = Time.get_unix_time_from_datetime_string(to_str + "T00:00:00")
	var diff_sec: float = to_unix - from_unix
	return int(diff_sec / 86400.0)
