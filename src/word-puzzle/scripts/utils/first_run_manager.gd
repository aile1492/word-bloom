## first_run_manager.gd
## Onboarding flow (language selection, nickname, tutorial) — currently disabled.
## The app goes directly to Home (level 1) on first launch.
class_name FirstRunManager


## Always returns false — onboarding screens are not shown.
static func check_and_start() -> bool:
	return false
