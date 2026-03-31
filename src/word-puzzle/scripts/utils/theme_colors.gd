## theme_colors.gd
## Project-wide color palette constants.
class_name ThemeColors


# ===== Light palette =====

const BG_LIGHT: Color = Color("#F5F5F5")
const SURFACE: Color = Color("#FFFFFF")
const TEXT_PRIMARY: Color = Color("#333333")
const TEXT_SECONDARY: Color = Color("#757575")
const ACCENT_ORANGE: Color = Color("#FF8C00")
const ACCENT_ORANGE_DARK: Color = Color("#FF6D00")
const SELECTING: Color = Color("#FFD54F")

## 6-colour cycle for found words (mirrors LetterCell.FOUND_COLORS).
const FOUND_COLORS: Array[Color] = [
	Color("#4CAF50"), Color("#2196F3"), Color("#FF5722"),
	Color("#9C27B0"), Color("#00BCD4"), Color("#E91E63"),
]

## Hint cell colours.
const HINT_CELL: Color = Color("#FFE082")
const HINT_BORDER: Color = Color("#FF8F00")

## Word bank chip — before and after found.
const CHIP_IDLE: Color = Color("#E8E8E8")
const CHIP_FOUND: Color = Color("#BDBDBD")
const CHIP_TEXT_IDLE: Color = Color("#333333")
const CHIP_TEXT_FOUND: Color = Color("#9E9E9E")


# ===== Dark palette =====

const DARK_BG: Color = Color("#1A1A2E")
const DARK_SURFACE: Color = Color("#2D2D44")
const DARK_TEXT: Color = Color("#E0E0E0")
const DARK_TEXT_SECONDARY: Color = Color("#9E9E9E")
