## analytics_manager.gd
## Firebase Analytics 연동 — 네이티브 SDK(Android)와 Measurement Protocol(fallback) 지원.
## Autoload 싱글톤으로 등록하여 전역에서 사용.
extends Node


# ============================================================
# Constants
# ============================================================

## Firebase project info (from google-services.json)
const FIREBASE_APP_ID: String = "1:236476367291:android:429cb3d3af32610e65849e"
const FIREBASE_PROJECT_ID: String = "word-bloom-393a3"

## Measurement Protocol (GA4) — fallback for non-Android platforms
## Get api_secret from: GA4 Admin → Data Streams → Measurement Protocol API secrets
## NOTE: MP_API_SECRET is only needed for non-Android (web/desktop) analytics.
## Android uses Firebase native SDK which does not require this secret.
## To enable web analytics: GA4 Admin → Data Streams → Measurement Protocol API secrets
const MP_API_SECRET: String = ""
const MP_ENDPOINT: String = "https://www.google-analytics.com/mp/collect"
const MP_DEBUG_ENDPOINT: String = "https://www.google-analytics.com/debug/mp/collect"


# ============================================================
# State
# ============================================================

var _http: HTTPRequest = null
var _device_id: String = ""
var _session_id: String = ""
var _session_start_time: int = 0
var _use_debug: bool = false
var _enabled: bool = true
var _event_queue: Array[Dictionary] = []


# ============================================================
# Lifecycle
# ============================================================

func _ready() -> void:
	_device_id = _get_or_create_device_id()
	_session_id = str(Time.get_unix_time_from_system())
	_session_start_time = Time.get_ticks_msec()

	_http = HTTPRequest.new()
	_http.timeout = 10.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

	# Log session start
	log_event("session_start")
	print("AnalyticsManager: Initialized (device_id=%s)" % _device_id)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_flush_queue()
			var session_sec: int = (Time.get_ticks_msec() - _session_start_time) / 1000
			log_event("session_end", {"session_duration_sec": str(session_sec)})
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_session_id = str(Time.get_unix_time_from_system())
			_session_start_time = Time.get_ticks_msec()


# ============================================================
# Public API
# ============================================================

## Log a custom event with optional parameters.
func log_event(event_name: String, params: Dictionary = {}) -> void:
	if not _enabled:
		return

	# Sanitize params — all values must be strings
	var clean: Dictionary = {}
	clean["engagement_time_msec"] = "1000"
	clean["session_id"] = _session_id
	for key: String in params:
		clean[key] = str(params[key])

	var event: Dictionary = {
		"name": event_name,
		"params": clean,
	}

	_event_queue.append(event)
	print("AnalyticsManager: Queued event '%s'" % event_name)

	# Batch send every 5 events or flush important ones immediately
	if _event_queue.size() >= 5 or event_name in ["session_start", "session_end", "purchase"]:
		_flush_queue()


## Log level/stage completion.
func log_level_complete(level: int, word_count: int, time_sec: float, hints_used: int) -> void:
	log_event("level_complete", {
		"level_number": str(level),
		"word_count": str(word_count),
		"time_seconds": str(int(time_sec)),
		"hints_used": str(hints_used),
	})


## Log hint usage.
func log_hint_used(hint_type: String, source: String) -> void:
	log_event("hint_used", {
		"hint_type": hint_type,
		"source": source,  # "ticket", "ad", "daily"
	})


## Log ad watched.
func log_ad_watched(ad_type: String, reward_type: String = "") -> void:
	log_event("ad_watched", {
		"ad_type": ad_type,  # "banner", "interstitial", "rewarded"
		"reward_type": reward_type,
	})


## Log in-app purchase.
func log_purchase(product_id: String, success: bool) -> void:
	log_event("purchase" if success else "purchase_failed", {
		"product_id": product_id,
	})


## Log app open / daily login.
func log_app_open() -> void:
	log_event("app_open", {
		"day": Time.get_date_string_from_system(),
	})


## Log tutorial progress.
func log_tutorial_step(step: String) -> void:
	log_event("tutorial_step", {
		"step": step,
	})


## Enable or disable analytics.
func set_enabled(value: bool) -> void:
	_enabled = value


# ============================================================
# Internal — Measurement Protocol
# ============================================================

func _flush_queue() -> void:
	if _event_queue.is_empty():
		return
	if MP_API_SECRET.is_empty():
		# No API secret configured — just clear the queue
		_event_queue.clear()
		return

	var payload: Dictionary = {
		"app_instance_id": _device_id,
		"events": _event_queue.duplicate(),
	}

	_event_queue.clear()

	var url: String = MP_DEBUG_ENDPOINT if _use_debug else MP_ENDPOINT
	var query: String = "?api_secret=%s&firebase_app_id=%s" % [MP_API_SECRET, FIREBASE_APP_ID]
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var body: String = JSON.stringify(payload)

	var err: int = _http.request(url + query, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("AnalyticsManager: HTTP request failed (error=%d)" % err)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 204:
		pass  # Success (production endpoint returns 204 No Content)
	elif response_code == 200 and _use_debug:
		var response: String = body.get_string_from_utf8()
		print("AnalyticsManager: Debug response: %s" % response)
	elif response_code != 0:
		print("AnalyticsManager: Request failed (code=%d)" % response_code)


func _get_or_create_device_id() -> String:
	var stored: String = SaveManager.load_value("analytics_device_id", "")
	if stored.is_empty():
		# Generate a valid app_instance_id (alphanumeric, no dashes)
		var time_hex: String = "%x" % int(Time.get_unix_time_from_system())
		var rand_hex: String = "%x" % (randi() & 0x7FFFFFFF)
		stored = time_hex + rand_hex
		SaveManager.save_value("analytics_device_id", stored)
	return stored
