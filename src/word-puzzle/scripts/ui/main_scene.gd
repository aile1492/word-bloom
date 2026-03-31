## main_scene.gd
## Root scene script.
## Initializes ScreenManager and connects BottomTabBar signals.
## Handles first-run onboarding and returning user detection.
extends Node


# ===== Node references =====

@onready var tab_layer: CanvasLayer = $TabLayer
@onready var push_layer: CanvasLayer = $PushLayer
@onready var popup_layer: CanvasLayer = $PopupLayer
@onready var bottom_tab_bar: BottomTabBar = $BarLayer/BottomTabBar


# ===== Initialization =====

func _ready() -> void:
	# Force portrait orientation on mobile
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	ScreenManager.initialize(tab_layer, push_layer, popup_layer, bottom_tab_bar)
	bottom_tab_bar.tab_selected.connect(_on_tab_selected)
	bottom_tab_bar.set_active_tab(ScreenManager.get_active_tab())

	## Run first-launch checks after layout initialization completes.
	call_deferred("_post_init")


func _post_init() -> void:
	## Detect returning users (absent for 3+ days).
	ReturningUserChecker.check_and_welcome()


func _on_tab_selected(index: int) -> void:
	ScreenManager.switch_tab(index)
	bottom_tab_bar.set_active_tab(index)
