## hint_ticket_manager.gd
## Hint ticket system singleton.
##
## ┌────────────────────────────────────────────────────────────────┐
## │                   Hint supply sources                          │
## ├───────────────────┬────────────────────────────────────────────┤
## │ Stage clear       │ Every 3 → First Letter ×1 / Every 5 → Reveal ×1  │
## │ 7-day streak      │ Day 1–7 (resets to Day 1 on missed day)    │
## │ Cumulative milestones │ 7/14/30/60/100 days (never resets)      │
## │ Watch ad          │ Grants 1 immediately on depletion (AdManager pending) │
## │ First install     │ First Letter ×3 + Reveal ×1                │
## └───────────────────┴────────────────────────────────────────────┘
##
## Supply simulation (5 stages/day):
##   Stage clears  : First Letter ≈1.67/day, Reveal ≈1.0/day
##   Streak avg    : First Letter ≈3.43/day, Reveal ≈1.57/day
##   Ad cap        : ≈1.0/day each
##   ─────────────────────────────────────────────
##   Total         : First Letter ≈6.1/day, Reveal ≈3.6/day
##   Active spend  : First Letter 4–5/day, Reveal 1–2/day  → slight surplus
extends Node


## Emitted when ticket counts change (for button UI refresh).
signal tickets_changed

## Emitted when a daily attendance reward is granted (for home screen popup).
## data keys: fl, rv, streak_day, cumulative, milestone_fl, milestone_rv
signal daily_reward_claimed(data: Dictionary)


# ============================================================
# State variables
# ============================================================

var first_letter_tickets: int = 0   ## Remaining First Letter hint uses.
var reveal_tickets:        int = 0   ## Remaining Reveal hint uses.

var streak_day:       int    = 0    ## Current login streak day (1–7, 0 = not started).
var streak_last_date: String = ""   ## Date of last claim "YYYY-MM-DD".
var cumulative_days:  int    = 0    ## Total cumulative login days (never resets).


# ============================================================
# Design constants
# ============================================================

## Grant one First Letter ticket every N stage clears.
const FIRST_LETTER_EARN_EVERY: int = 3
## Grant one Reveal ticket every N stage clears.
const REVEAL_EARN_EVERY: int       = 5

## First-install grant (industry standard: let players try hints immediately).
const INITIAL_FIRST_LETTER: int = 3
const INITIAL_REVEAL: int       = 1

## 7-day streak reward table [first_letter, reveal].
## Day 7 is the headline reward (~3× Day 1). Industry ref: Homescapes Day7 = 5× Day1.
const STREAK_REWARDS: Array = [
	[2, 0],  ## Day 1: light start
	[2, 1],  ## Day 2
	[3, 1],  ## Day 3
	[3, 1],  ## Day 4
	[4, 2],  ## Day 5: mid-week jump
	[4, 2],  ## Day 6
	[6, 4],  ## Day 7 ★ headline (First Letter ×6 + Reveal ×4)
]

## Cumulative login milestone rewards { days: [first_letter, reveal] }.
## Independent of streak — never resets (Puzzle & Dragons style).
const CUMULATIVE_MILESTONES: Dictionary = {
	7:   [5, 2],
	14:  [5, 3],
	30:  [8, 5],
	60:  [10, 7],
	100: [15, 10],
}


# ============================================================
# Initialization
# ============================================================

func _ready() -> void:
	var saved_fl: Variant = SaveManager.load_value("hint_fl_tickets", null)
	var saved_rv: Variant = SaveManager.load_value("hint_rv_tickets", null)
	## null = first run → grant initial tickets.
	first_letter_tickets = (saved_fl as int) if saved_fl != null else INITIAL_FIRST_LETTER
	reveal_tickets       = (saved_rv as int) if saved_rv != null else INITIAL_REVEAL
	streak_day       = SaveManager.load_value("hint_streak_day",  0)  as int
	streak_last_date = SaveManager.load_value("hint_streak_date", "") as String
	cumulative_days  = SaveManager.load_value("hint_cumulative",  0)  as int
	_save()


# ============================================================
# Stage clear rewards
# ============================================================

## Call on stage clear. Grants tickets based on the stage number.
func add_on_clear(stage: int) -> void:
	var changed: bool = false
	if stage % FIRST_LETTER_EARN_EVERY == 0:
		first_letter_tickets += 1
		changed = true
	if stage % REVEAL_EARN_EVERY == 0:
		reveal_tickets += 1
		changed = true
	if changed:
		_save()
		tickets_changed.emit()


# ============================================================
# Consume API
# ============================================================

## Consume one First Letter ticket. Returns false if none remain.
func use_first_letter() -> bool:
	if first_letter_tickets <= 0:
		return false
	first_letter_tickets -= 1
	_save()
	tickets_changed.emit()
	return true


## Consume one Reveal ticket. Returns false if none remain.
func use_reveal() -> bool:
	if reveal_tickets <= 0:
		return false
	reveal_tickets -= 1
	_save()
	tickets_changed.emit()
	return true


# ============================================================
# Grant API (ad rewards · debug)
# ============================================================

## Called on ad view completion or for direct debug grants.
func grant(first_letter: int, reveal: int) -> void:
	first_letter_tickets += first_letter
	reveal_tickets       += reveal
	_save()
	tickets_changed.emit()


# ============================================================
# Daily attendance rewards (7-day streak + cumulative milestones)
# ============================================================

## Call on home screen entry.
## If this is the player's first visit today, grants streak and cumulative rewards
## and returns a result Dictionary. Returns {} if already claimed today.
##
## Return keys:
##   fl           : int — First Letter tickets granted (streak reward)
##   rv           : int — Reveal tickets granted (streak reward)
##   streak_day   : int — Today's streak day (1–7)
##   cumulative   : int — Total cumulative login days
##   milestone_fl : int — Cumulative milestone bonus First Letter (0 if none)
##   milestone_rv : int — Cumulative milestone bonus Reveal (0 if none)
func check_and_claim_daily() -> Dictionary:
	var today: String = Time.get_date_string_from_system()
	if today == streak_last_date:
		return {}   ## Already claimed today.

	## Decide whether streak is continuous by comparing to yesterday.
	var yesterday: String = _get_yesterday()
	if streak_last_date != yesterday:
		streak_day = 0   ## Streak broken → reset (then +1 → Day 1).

	## Advance streak (wraps 7→1).
	streak_day       = (streak_day % 7) + 1
	cumulative_days += 1
	streak_last_date = today

	## Today's streak reward.
	var row: Array = STREAK_REWARDS[streak_day - 1]
	var fl:  int   = row[0]
	var rv:  int   = row[1]
	first_letter_tickets += fl
	reveal_tickets       += rv

	## Cumulative milestone bonus (granted only once on the milestone day).
	var m_fl: int = 0
	var m_rv: int = 0
	if CUMULATIVE_MILESTONES.has(cumulative_days):
		var ms: Array = CUMULATIVE_MILESTONES[cumulative_days]
		m_fl = ms[0]
		m_rv = ms[1]
		first_letter_tickets += m_fl
		reveal_tickets       += m_rv

	_save()
	tickets_changed.emit()

	var result: Dictionary = {
		"fl":           fl,
		"rv":           rv,
		"streak_day":   streak_day,
		"cumulative":   cumulative_days,
		"milestone_fl": m_fl,
		"milestone_rv": m_rv,
	}
	daily_reward_claimed.emit(result)
	return result


## Returns the current streak status for external display (always-visible home screen info).
func get_streak_info() -> Dictionary:
	return {
		"streak_day":    streak_day,
		"cumulative":    cumulative_days,
		"claimed_today": streak_last_date == Time.get_date_string_from_system(),
	}


# ============================================================
# Internal
# ============================================================

func _save() -> void:
	SaveManager.save_value("hint_fl_tickets",  first_letter_tickets)
	SaveManager.save_value("hint_rv_tickets",  reveal_tickets)
	SaveManager.save_value("hint_streak_day",  streak_day)
	SaveManager.save_value("hint_streak_date", streak_last_date)
	SaveManager.save_value("hint_cumulative",  cumulative_days)


func _get_yesterday() -> String:
	var unix: int        = roundi(Time.get_unix_time_from_system()) - 86400
	var d:    Dictionary = Time.get_date_dict_from_unix_time(unix)
	return "%d-%02d-%02d" % [d["year"], d["month"], d["day"]]
