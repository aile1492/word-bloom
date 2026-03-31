## game_constants.gd
## Central repository for all game-wide difficulty and balance constants.
## Usage: access directly as GameConstants.START_WORD_COUNT, etc.
class_name GameConstants
extends RefCounted


# ===== Grid / Words =====

const START_WORD_COUNT: int = 4
const MAX_WORD_COUNT: int = 12
const MIN_GRID_SIZE: int = 5
const MAX_GRID_SIZE: int = 10
const GROUP_SIZE: int = 4
const WORD_INCREASE_INTERVAL: int = 5


# ===== Rest stages =====

const REST_STAGE_INTERVAL: int = 10
const REST_WORD_REDUCTION: int = 2


# ===== DDA =====

const DDA_HISTORY_SIZE: int = 3
const DDA_MAX_OFFSET: int = 2
const DDA_FAST_CLEAR_THRESHOLD: float = 90.0
const DDA_HIGH_HINT_THRESHOLD: float = 2.0
const DDA_FAIL_COUNT_THRESHOLD: int = 2


# ===== False Leads =====

const FALSE_LEAD_MIN_STAGE: int = 11
const FALSE_LEAD_MAX_COUNT: int = 2
const FALSE_LEAD_PREFIX_MIN: int = 2
const FALSE_LEAD_PREFIX_MAX: int = 3
const FALSE_LEAD_MAX_ATTEMPTS: int = 50
