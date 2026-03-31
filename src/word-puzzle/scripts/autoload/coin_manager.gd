extends Node

## Singleton that manages the coin economy.
## 1 hint use = 100 coins.

signal coins_changed(new_amount: int)

const HINT_COST: int = 100

## Hints are unlimited in debug builds (editor/test). Automatically false in release exports.
var DEBUG_UNLIMITED_HINTS: bool = OS.is_debug_build()

var _coins: int = 0


func _ready() -> void:
	_coins = SaveManager.load_value("coins", 0)


func get_coins() -> int:
	return _coins


func add_coins(amount: int) -> void:
	_coins += amount
	SaveManager.save_value("coins", _coins)
	coins_changed.emit(_coins)


func spend_coins(amount: int) -> bool:
	if _coins >= amount:
		_coins -= amount
		SaveManager.save_value("coins", _coins)
		coins_changed.emit(_coins)
		return true
	return false


func can_afford(amount: int) -> bool:
	if DEBUG_UNLIMITED_HINTS:
		return true
	return _coins >= amount


func use_hint(cost: int = HINT_COST) -> bool:
	if DEBUG_UNLIMITED_HINTS:
		return true
	return spend_coins(cost)
