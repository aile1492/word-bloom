## game_result.gd
## Data container for a stage clear/failure result.
## Passed along the chain: GameScreen → GameController → ResultScreen.
class_name GameResult
extends RefCounted

var stage: int = 0
var score: int = 0
var grade: String = "C"
var coins_earned: int = 0
var hint_count: int = 0
var clear_time: float = 0.0
var word_pack_path: String = ""

## P02_01 additional fields.
var mode: int = 0              ## GameManager.GameMode integer (0=CLASSIC, 1=TIME_ATTACK …)
var theme: String = ""         ## Theme ID (e.g. "animals")
var is_cleared: bool = true    ## true = cleared, false = failed
var is_new_record: bool = false ## Whether a new best-time record was set
var words_found: int = 0       ## Number of words found
var total_words: int = 0       ## Total number of words in the stage
