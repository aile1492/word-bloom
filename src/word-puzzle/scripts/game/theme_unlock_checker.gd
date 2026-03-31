## theme_unlock_checker.gd
## Checks unlock conditions for all 8 themes and records newly unlocked themes in SaveManager.
## Follows the P02_02 design spec.
class_name ThemeUnlockChecker


## Unlock condition definitions.
## type: "default" | "classic_clears" | "time_attack_clears" | "daily_streak" | "all_themes_used"
const UNLOCK_CONDITIONS: Dictionary = {
	"animals":   {"type": "default"},
	"food":      {"type": "default"},
	"space":     {"type": "classic_clears",      "required": 5},
	"sports":    {"type": "classic_clears",      "required": 10},
	"science":   {"type": "classic_clears",      "required": 20},
	"music":     {"type": "time_attack_clears",  "required": 5},
	"ocean":     {"type": "daily_streak",        "required": 7},
	"mythology": {"type": "all_themes_used"},
}

## All theme IDs in unlock order (for reference).
const ALL_THEMES: Array[String] = [
	"animals", "food", "space", "sports", "science", "music", "ocean", "mythology"
]


## Checks for newly unlocked themes based on the current SaveManager state.
## Newly unlocked themes are saved immediately via SaveManager.unlock_theme().
static func check_new_unlocks() -> Array[String]:
	var stats: Dictionary = SaveManager.get_stats()
	var already_unlocked: Array[String] = SaveManager.get_unlocked_themes()
	var newly_unlocked: Array[String] = []

	for theme_id: String in UNLOCK_CONDITIONS.keys():
		if theme_id in already_unlocked:
			continue  # Already unlocked.
		var cond: Dictionary = UNLOCK_CONDITIONS[theme_id] as Dictionary
		if _is_condition_met(cond, stats, already_unlocked):
			SaveManager.unlock_theme(theme_id)
			newly_unlocked.append(theme_id)

	return newly_unlocked


## Checks whether an individual unlock condition is satisfied.
static func _is_condition_met(
		cond: Dictionary,
		stats: Dictionary,
		_unlocked: Array[String]) -> bool:

	var cond_type: String = cond.get("type", "") as String

	match cond_type:
		"default":
			return true  # Unlocked by default.

		"classic_clears":
			var required: int = cond.get("required", 999) as int
			var clears: int = stats.get("classic_clears", 0) as int
			return clears >= required

		"time_attack_clears":
			var required: int = cond.get("required", 999) as int
			var clears: int = stats.get("time_attack_clears", 0) as int
			return clears >= required

		"daily_streak":
			var required: int = cond.get("required", 999) as int
			var streak: int = SaveManager.get_daily_streak()
			return streak >= required

		"all_themes_used":
			## Mythology unlocks only after every other theme has been used at least once.
			var used: Array = (stats.get("used_themes", []) as Array)
			for other_theme: String in ALL_THEMES:
				if other_theme == "mythology":
					continue
				if other_theme not in used:
					return false
			return true

	return false
