## theme_randomizer.gd
## Static utility that picks a random theme from the full pool, excluding the last used theme.
## To add new themes, simply append their IDs to the THEMES array.
class_name ThemeRandomizer

const THEMES: Array[String] = [
	# ── Original 8 themes ───────────────────────────────────
	"animals", "food", "space", "sports",
	"science", "music", "ocean", "mythology",
	# ── Nature ──────────────────────────────────────────────
	"birds", "insects", "dinosaurs", "plants",
	"weather", "gems", "farm", "jungle",
	# ── Food ────────────────────────────────────────────────
	"fruits", "vegetables", "desserts", "drinks",
	"spices", "fastfood", "breakfast",
	# ── Sports ──────────────────────────────────────────────
	"olympicsports", "watersports", "boardgames",
	"videogames", "martialarts",
	# ── Arts & Culture ──────────────────────────────────────
	"musicalinstruments", "dance", "movies",
	"books", "artmovements",
	# ── World ───────────────────────────────────────────────
	"countries", "capitals", "landmarks", "languages",
	# ── People & Daily Life ─────────────────────────────────
	"jobs", "clothing", "emotions", "colors",
	"household", "school",
	# ── Science & Technology ────────────────────────────────
	"chemistry", "humanbody", "technology",
	"medicine", "mathematics",
	# ── Fantasy ─────────────────────────────────────────────
	"superheroes", "pirates",
]
const BASE_PATH: String = "res://data/words/en/"


## Returns a random theme path, excluding the last used theme.
static func pick(last_theme: String) -> String:
	var pool: Array[String] = []
	for t: String in THEMES:
		if t != last_theme:
			pool.append(t)
	if pool.is_empty():
		pool = THEMES.duplicate()
	var theme: String = pool[randi() % pool.size()]
	return BASE_PATH + theme + ".json"


## Extracts the theme name (file basename) from a path.
## Example: "res://data/words/ko/animals.json" → "animals"
static func extract_theme(path: String) -> String:
	return path.get_file().get_basename()
