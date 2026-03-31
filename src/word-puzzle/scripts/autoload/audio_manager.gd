extends Node

## BGM/SFX audio system singleton.
## Path-based loading — gracefully skips missing OGG files.
## AudioBus: Master > Music(-6dB) / SFX(0dB) / UI(-3dB)
## Configure buses via Project > Audio > Buses in the editor.


# ===== Path constants =====

const SFX_BASE: String = "res://assets/audio/sfx/"
const BGM_BASE: String = "res://assets/audio/bgm/"

const SFX_PATHS: Dictionary = {
	"cell_select": SFX_BASE + "sfx_tick.ogg",
	"word_found":  SFX_BASE + "sfx_success.ogg",
	"word_wrong":  SFX_BASE + "sfx_soft_fail.ogg",
	"stage_clear": SFX_BASE + "sfx_fanfare.ogg",
	"hint":        SFX_BASE + "sfx_hint.ogg",
	"coin":        SFX_BASE + "sfx_coin.ogg",
	"button":      SFX_BASE + "sfx_click.ogg",
	"shuffle":     SFX_BASE + "sfx_shuffle.ogg",
}

const BGM_PATHS: Dictionary = {
	"main":   BGM_BASE + "bgm_main.ogg",
	"play":   BGM_BASE + "bgm_play.ogg",
	"result": BGM_BASE + "bgm_result.ogg",
	"daily":  BGM_BASE + "bgm_daily.ogg",
}

const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"
const UI_BUS: String = "UI"

const SFX_POOL_SIZE: int = 8
const MAX_COMBO: int = 3
const COMBO_WINDOW: float = 10.0


# ===== Audio nodes =====

## A/B players for BGM crossfade.
var _bgm_a: AudioStreamPlayer
var _bgm_b: AudioStreamPlayer
## true = B is currently active, false = A is currently active.
var _bgm_active: bool = false

## SFX pool (max 8 simultaneous sounds).
var _sfx_players: Array[AudioStreamPlayer] = []


# ===== Combo pitch tracker =====

var _combo_count: int = 0
var _combo_timer: float = 0.0
var _combo_timing_active: bool = false


# ===== Volume / enabled state =====

var _music_volume_linear: float = 1.0
var _sfx_volume_linear:   float = 1.0
var _music_enabled:       bool  = true   ## false = muted (volume value preserved)
var _sfx_enabled:         bool  = true   ## false = suppresses SFX playback


# ===== Internal state =====

var _current_bgm: String = ""
var _bgm_tween: Tween = null
var _duck_tween: Tween = null
var _duck_base_db: float = 0.0


# ===== Initialization =====

func _ready() -> void:
	# BGM A/B players
	_bgm_a = AudioStreamPlayer.new()
	_bgm_a.bus = MUSIC_BUS
	add_child(_bgm_a)

	_bgm_b = AudioStreamPlayer.new()
	_bgm_b.bus = MUSIC_BUS
	_bgm_b.volume_db = -80.0
	add_child(_bgm_b)

	# SFX pool
	for i: int in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_sfx_players.append(p)

	# Restore saved volume settings
	var settings: Dictionary = SaveManager.load_value("audio_settings", {})
	_music_volume_linear = settings.get("music_volume",  1.0)
	_sfx_volume_linear   = settings.get("sfx_volume",    1.0)
	_music_enabled       = settings.get("music_enabled", true)
	_sfx_enabled         = settings.get("sfx_enabled",   true)
	_apply_music_volume()


func _process(delta: float) -> void:
	# Combo timer — reset if no word found within COMBO_WINDOW seconds.
	if _combo_timing_active:
		_combo_timer += delta
		if _combo_timer >= COMBO_WINDOW:
			_combo_count = 0
			_combo_timing_active = false
			_combo_timer = 0.0


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_fade_active_bgm(-80.0, 0.3)
			_stop_all_sfx()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_resume_bgm_after_focus()


# ===== Public: SFX =====

## Plays a sound effect. Default pitch is 1.0.
func play_sfx(sfx_name: String, pitch: float = 1.0) -> void:
	if not _sfx_enabled:
		return
	var stream: AudioStream = _load_sfx(sfx_name)
	if stream == null:
		return
	var player: AudioStreamPlayer = _get_free_sfx_player()
	player.bus = SFX_BUS
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(_sfx_volume_linear)
	player.play()


## Plays an SFX on the UI bus (button clicks etc.).
func play_ui_sfx(sfx_name: String) -> void:
	var stream: AudioStream = _load_sfx(sfx_name)
	if stream == null:
		return
	var player: AudioStreamPlayer = _get_free_sfx_player()
	player.bus = UI_BUS
	player.stream = stream
	player.pitch_scale = 1.0
	player.volume_db = linear_to_db(_sfx_volume_linear)
	player.play()
	player.finished.connect(func(): player.bus = SFX_BUS, CONNECT_ONE_SHOT)


## Cell select sound — automatically applies current combo pitch.
func play_cell_select() -> void:
	play_sfx("cell_select", _get_cell_pitch())


## Word found sound — updates combo and applies combo pitch.
func play_word_found() -> void:
	var pitch: float = _get_word_pitch()
	_record_combo()
	play_sfx("word_found", pitch)


# ===== Public: BGM =====

## Switches BGM with a crossfade.
func play_bgm(bgm_name: String, crossfade_sec: float = 1.0) -> void:
	if bgm_name == _current_bgm:
		return
	_current_bgm = bgm_name

	if not BGM_PATHS.has(bgm_name):
		return
	var path: String = BGM_PATHS[bgm_name]
	if not ResourceLoader.exists(path):
		if OS.is_debug_build():
			print("AudioManager: BGM file missing — ", path)
		return
	var stream: AudioStream = ResourceLoader.load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true

	var out_player: AudioStreamPlayer = _bgm_a if not _bgm_active else _bgm_b
	var in_player: AudioStreamPlayer = _bgm_b if not _bgm_active else _bgm_a
	_bgm_active = not _bgm_active

	in_player.stream = stream
	in_player.volume_db = -80.0
	in_player.play()

	if _bgm_tween and _bgm_tween.is_running():
		_bgm_tween.kill()
	_bgm_tween = create_tween().set_parallel(true)
	_bgm_tween.tween_property(in_player, "volume_db", _music_vol_db(), crossfade_sec)
	_bgm_tween.tween_property(out_player, "volume_db", -80.0, crossfade_sec)
	_bgm_tween.finished.connect(func(): out_player.stop(), CONNECT_ONE_SHOT)


## Fades out and stops the current BGM.
func stop_bgm(fade_sec: float = 1.0) -> void:
	_current_bgm = ""
	_fade_active_bgm(-80.0, fade_sec)


## Temporarily lowers BGM volume (for popups, fanfares, etc.).
func duck_bgm(duck_db: float, duration: float = 0.3) -> void:
	var bus_idx: int = AudioServer.get_bus_index(MUSIC_BUS)
	if bus_idx < 0:
		return
	_duck_base_db = AudioServer.get_bus_volume_db(bus_idx)
	_set_bus_volume_tween(bus_idx, _duck_base_db, _duck_base_db + duck_db, duration)


## Restores BGM volume to the level it was before duck_bgm().
func unduck_bgm(duration: float = 0.3) -> void:
	var bus_idx: int = AudioServer.get_bus_index(MUSIC_BUS)
	if bus_idx < 0:
		return
	_set_bus_volume_tween(bus_idx, AudioServer.get_bus_volume_db(bus_idx), _duck_base_db, duration)


# ===== Public: Volume =====

func set_music_volume(linear: float) -> void:
	_music_volume_linear = clampf(linear, 0.0, 1.0)
	_apply_music_volume()
	_save_audio_settings()


func set_sfx_volume(linear: float) -> void:
	_sfx_volume_linear = clampf(linear, 0.0, 1.0)
	_save_audio_settings()


func get_music_volume() -> float:
	return _music_volume_linear


func get_sfx_volume() -> float:
	return _sfx_volume_linear


func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	_apply_music_volume()
	_save_audio_settings()


func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled
	_save_audio_settings()


func get_music_enabled() -> bool:
	return _music_enabled


func get_sfx_enabled() -> bool:
	return _sfx_enabled


# ===== Internal helpers =====

func _load_sfx(sfx_name: String) -> AudioStream:
	if not SFX_PATHS.has(sfx_name):
		return null
	var path: String = SFX_PATHS[sfx_name]
	if not ResourceLoader.exists(path):
		if OS.is_debug_build():
			print("AudioManager: SFX file missing — ", path)
		return null
	return ResourceLoader.load(path) as AudioStream


func _get_free_sfx_player() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _sfx_players:
		if not p.playing:
			return p
	# All players busy — reuse the oldest one.
	_sfx_players[0].stop()
	return _sfx_players[0]


func _record_combo() -> void:
	_combo_count = mini(_combo_count + 1, MAX_COMBO)
	_combo_timing_active = true
	_combo_timer = 0.0


func _get_word_pitch() -> float:
	return 1.0 + _combo_count * 0.1


func _get_cell_pitch() -> float:
	return 1.0 + _combo_count * 0.05


func _music_vol_db() -> float:
	if not _music_enabled or _music_volume_linear <= 0.0:
		return -80.0
	return linear_to_db(_music_volume_linear)


func _apply_music_volume() -> void:
	var active_player: AudioStreamPlayer = _bgm_b if _bgm_active else _bgm_a
	if active_player.playing:
		active_player.volume_db = _music_vol_db()


func _resume_bgm_after_focus() -> void:
	if _current_bgm.is_empty() or not _music_enabled:
		return
	var active_player: AudioStreamPlayer = _bgm_b if _bgm_active else _bgm_a
	if not active_player.playing:
		# Player was stopped during focus-out — restart it.
		active_player.volume_db = -80.0
		active_player.play()
	var tw := create_tween()
	tw.tween_property(active_player, "volume_db", _music_vol_db(), 0.5)


func _fade_active_bgm(target_db: float, duration: float) -> void:
	var active_player: AudioStreamPlayer = _bgm_b if _bgm_active else _bgm_a
	if not active_player.playing:
		return
	var tw := create_tween()
	tw.tween_property(active_player, "volume_db", target_db, duration)
	if target_db <= -79.0:
		tw.finished.connect(func(): active_player.stop(), CONNECT_ONE_SHOT)


func _stop_all_sfx() -> void:
	for p: AudioStreamPlayer in _sfx_players:
		p.stop()


func _set_bus_volume_tween(bus_idx: int, from_db: float, to_db: float, duration: float) -> void:
	if _duck_tween and _duck_tween.is_running():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_method(
		func(v: float): AudioServer.set_bus_volume_db(bus_idx, v),
		from_db, to_db, duration
	)


func _save_audio_settings() -> void:
	SaveManager.save_value("audio_settings", {
		"music_volume":  _music_volume_linear,
		"sfx_volume":    _sfx_volume_linear,
		"music_enabled": _music_enabled,
		"sfx_enabled":   _sfx_enabled,
	})
