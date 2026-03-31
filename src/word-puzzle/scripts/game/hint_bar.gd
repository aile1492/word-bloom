## hint_bar.gd
## Bottom-bar component that handles hint buttons and progress display.
extends HBoxContainer


signal hint_requested
signal shuffle_requested

@onready var progress_label: Label = $ProgressLabel
@onready var hint_button: Button = $HintButton
@onready var shuffle_button: Button = $ShuffleButton


func _ready() -> void:
	hint_button.pressed.connect(_on_hint_pressed)
	shuffle_button.pressed.connect(_on_shuffle_pressed)


## Updates the progress display.
func update_progress(found: int, total: int) -> void:
	progress_label.text = "%d / %d" % [found, total]


func _on_hint_pressed() -> void:
	hint_requested.emit()


func _on_shuffle_pressed() -> void:
	shuffle_requested.emit()
