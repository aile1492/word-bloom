## hint_type.gd
## Enum container defining all hint types.
class_name HintType
extends RefCounted

enum Type {
	FIRST_LETTER,   ## Reveals the first letter (100 coins).
	DIRECTION_SHOW, ## Shows a direction arrow (120 coins).
	MAGNIFIER,      ## Highlights the 3×3 area around the word center (150 coins).
	FULL_REVEAL,    ## Reveals the entire word — marks it as found immediately (200 coins).
	TIMER_EXTEND,   ## Extends the timer by +30 seconds (80 coins, Time Attack only).
}
