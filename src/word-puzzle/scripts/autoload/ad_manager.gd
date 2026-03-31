extends Node

## AdMob integration manager. Singleton handling banner, interstitial, and rewarded ads.
## Includes GDPR/UMP consent flow and iOS ATT prompt.
## All plugin class references are loaded dynamically at runtime.

# ============================================================
# Signals
# ============================================================

signal rewarded_ad_completed(reward_type: String, reward_amount: int)
signal interstitial_ad_closed()
signal banner_visibility_changed(is_visible: bool)
signal ads_removed_changed()
signal rewarded_ad_failed()


# ============================================================
# Dynamically loaded plugin scripts
# ============================================================

var _S_MobileAds: Variant = null
var _S_AdView: Variant = null
var _S_AdSize: Variant = null
var _S_AdPosition: Variant = null
var _S_AdRequest: Variant = null
var _S_AdListener: Variant = null
var _S_InterstitialAdLoader: Variant = null
var _S_InterstitialAdLoadCallback: Variant = null
var _S_RewardedAdLoader: Variant = null
var _S_RewardedAdLoadCallback: Variant = null
var _S_FullScreenContentCallback: Variant = null
var _S_OnUserEarnedRewardListener: Variant = null

# UMP (User Messaging Platform) scripts
var _S_UserMessagingPlatform: Variant = null
var _S_ConsentRequestParameters: Variant = null
var _S_ConsentDebugSettings: Variant = null
var _S_DebugGeography: Variant = null

# Configuration
var _S_RequestConfiguration: Variant = null


# ============================================================
# State
# ============================================================

var _ads_removed: bool = false
var _plugin_available: bool = false
var _initialized: bool = false
var _consent_completed: bool = false

## Banner
var _ad_view: Variant = null
var _banner_visible: bool = false

## Interstitial
var _interstitial_ad: Variant = null
var _interstitial_loaded: bool = false
var _stages_since_last_interstitial: int = 0
var _last_interstitial_time: float = -999.0

## Rewarded
var _rewarded_ad: Variant = null
var _rewarded_loaded: bool = false
var _rewarded_loading: bool = false
var _pending_reward_type: String = ""


# ============================================================
# Lifecycle
# ============================================================

func _ready() -> void:
	_ads_removed = SaveManager.load_value("ads_removed", false)
	_try_load_plugin_classes()

	if _plugin_available:
		print("AdManager: AdMob plugin detected — starting consent flow.")
		_request_consent_then_initialize()
	else:
		print("AdManager: AdMob plugin not available — running in stub mode.")


# ============================================================
# Plugin Loading
# ============================================================

func _try_load_plugin_classes() -> void:
	var base: String = "res://addons/admob/src/"
	var paths: Dictionary = {
		"MobileAds":                  base + "api/MobileAds.gd",
		"AdView":                     base + "api/AdView.gd",
		"AdSize":                     base + "api/core/AdSize.gd",
		"AdPosition":                 base + "api/core/AdPosition.gd",
		"AdRequest":                  base + "api/core/AdRequest.gd",
		"AdListener":                 base + "api/listeners/AdListener.gd",
		"InterstitialAdLoader":       base + "api/InterstitialAdLoader.gd",
		"InterstitialAdLoadCallback": base + "api/listeners/InterstitialAdLoadCallback.gd",
		"RewardedAdLoader":           base + "api/RewardedAdLoader.gd",
		"RewardedAdLoadCallback":     base + "api/listeners/RewardedAdLoadCallback.gd",
		"FullScreenContentCallback":  base + "api/listeners/FullScreenContentCallback.gd",
		"OnUserEarnedRewardListener": base + "api/listeners/OnUserEarnedRewardListener.gd",
	}

	# UMP paths
	var ump_paths: Dictionary = {
		"UserMessagingPlatform":  base + "ump/api/UserMessagingPlatform.gd",
		"ConsentRequestParameters": base + "ump/core/ConsentRequestParameters.gd",
		"ConsentDebugSettings":  base + "ump/core/ConsentDebugSettings.gd",
		"DebugGeography":        base + "ump/core/DebugGeography.gd",
		"RequestConfiguration":  base + "api/core/RequestConfiguration.gd",
	}

	for key: String in paths:
		if not ResourceLoader.exists(paths[key]):
			_plugin_available = false
			return

	var scripts: Dictionary = {}
	for key: String in paths:
		var res: Variant = load(paths[key])
		if res == null:
			_plugin_available = false
			return
		scripts[key] = res

	_S_MobileAds                  = scripts["MobileAds"]
	_S_AdView                     = scripts["AdView"]
	_S_AdSize                     = scripts["AdSize"]
	_S_AdPosition                 = scripts["AdPosition"]
	_S_AdRequest                  = scripts["AdRequest"]
	_S_AdListener                 = scripts["AdListener"]
	_S_InterstitialAdLoader       = scripts["InterstitialAdLoader"]
	_S_InterstitialAdLoadCallback = scripts["InterstitialAdLoadCallback"]
	_S_RewardedAdLoader           = scripts["RewardedAdLoader"]
	_S_RewardedAdLoadCallback     = scripts["RewardedAdLoadCallback"]
	_S_FullScreenContentCallback  = scripts["FullScreenContentCallback"]
	_S_OnUserEarnedRewardListener = scripts["OnUserEarnedRewardListener"]

	# Load UMP scripts (optional — if missing, skip consent but still init)
	for key: String in ump_paths:
		if ResourceLoader.exists(ump_paths[key]):
			var res: Variant = load(ump_paths[key])
			if key == "UserMessagingPlatform":
				_S_UserMessagingPlatform = res
			elif key == "ConsentRequestParameters":
				_S_ConsentRequestParameters = res
			elif key == "ConsentDebugSettings":
				_S_ConsentDebugSettings = res
			elif key == "DebugGeography":
				_S_DebugGeography = res
			elif key == "RequestConfiguration":
				_S_RequestConfiguration = res

	if not Engine.has_singleton("PoingGodotAdMob"):
		print("AdManager: Plugin scripts found but native backend absent (desktop) — stub mode.")
		_plugin_available = false
		return

	_plugin_available = true
	print("AdManager: All plugin classes loaded — native backend available.")


# ============================================================
# GDPR Consent (UMP) + iOS ATT + SDK Init
# ============================================================

func _request_consent_then_initialize() -> void:
	if not _plugin_available:
		_initialize_sdk()
		return

	# iOS: Request App Tracking Transparency BEFORE consent
	if OS.get_name() == "iOS":
		_request_att()

	# UMP Consent flow
	if _S_UserMessagingPlatform != null and _S_ConsentRequestParameters != null:
		print("AdManager: Requesting UMP consent info update...")
		var params: Variant = _S_ConsentRequestParameters.new()
		params.tag_for_under_age_of_consent = false

		# Debug: uncomment to test consent flow in non-EU regions
		# if _S_ConsentDebugSettings and _S_DebugGeography:
		#     var debug_settings = _S_ConsentDebugSettings.new()
		#     debug_settings.debug_geography = _S_DebugGeography.Values.EEA
		#     params.consent_debug_settings = debug_settings

		_S_UserMessagingPlatform.consent_information.update(
			params,
			_on_consent_info_updated,
			_on_consent_info_update_failed
		)
	else:
		print("AdManager: UMP not available — skipping consent, initializing SDK directly.")
		_initialize_sdk()


func _request_att() -> void:
	# iOS App Tracking Transparency — handled by the native plugin if available.
	# The Poing Studios plugin shows the ATT dialog automatically when configured.
	print("AdManager: iOS detected — ATT will be handled by native plugin.")


func _on_consent_info_updated() -> void:
	print("AdManager: Consent info updated.")
	var status: int = _S_UserMessagingPlatform.consent_information.get_consent_status()
	# Status: 0=UNKNOWN, 1=NOT_REQUIRED, 2=REQUIRED, 3=OBTAINED

	if status == 2:  # REQUIRED
		if _S_UserMessagingPlatform.consent_information.get_is_consent_form_available():
			print("AdManager: Consent required — loading form...")
			_S_UserMessagingPlatform.load_consent_form(
				_on_consent_form_loaded,
				_on_consent_form_load_failed
			)
			return
	# NOT_REQUIRED, OBTAINED, or form not available — proceed
	_consent_completed = true
	_initialize_sdk()


func _on_consent_info_update_failed(_error: Variant) -> void:
	print("AdManager: Consent info update failed — initializing SDK anyway.")
	_consent_completed = true
	_initialize_sdk()


func _on_consent_form_loaded(consent_form: Variant) -> void:
	print("AdManager: Consent form loaded — showing...")
	consent_form.show(func(_form_error: Variant) -> void:
		print("AdManager: Consent form dismissed.")
		_consent_completed = true
		_initialize_sdk()
	)


func _on_consent_form_load_failed(_error: Variant) -> void:
	print("AdManager: Consent form load failed — initializing SDK anyway.")
	_consent_completed = true
	_initialize_sdk()


# ============================================================
# SDK Initialization
# ============================================================

func _initialize_sdk() -> void:
	if not _plugin_available or _initialized:
		return

	# Apply ad content rating and child-directed settings
	if _S_RequestConfiguration != null:
		var config: Variant = _S_RequestConfiguration.new()
		config.max_ad_content_rating = AdConfig.MAX_AD_CONTENT_RATING
		if not AdConfig.TAG_FOR_CHILD_DIRECTED:
			config.tag_for_child_directed_treatment = 0  # FALSE
		if not AdConfig.TAG_FOR_UNDER_AGE_OF_CONSENT:
			config.tag_for_under_age_of_consent = 0  # FALSE
		_S_MobileAds.set_request_configuration(config)
		print("AdManager: RequestConfiguration applied (rating=%s)." % AdConfig.MAX_AD_CONTENT_RATING)

	_S_MobileAds.initialize()
	_initialized = true
	print("AdManager: MobileAds.initialize() called.")

	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		_preload_interstitial()
		_preload_rewarded()
	)


# ============================================================
# Banner Ads
# ============================================================

func show_banner(level: int = 999) -> void:
	if _ads_removed or level < AdConfig.BANNER_START_LEVEL:
		return

	if not _plugin_available:
		_banner_visible = true
		banner_visibility_changed.emit(true)
		return

	if not _initialized:
		return
	if _ad_view != null and _banner_visible:
		return

	if _ad_view != null:
		_ad_view.destroy()
		_ad_view = null

	var unit_id: String = AdConfig.get_unit_id(&"banner")
	var ad_size: Variant = _S_AdSize.BANNER
	var ad_pos: int = _S_AdPosition.Values.BOTTOM
	_ad_view = _S_AdView.new(unit_id, ad_size, ad_pos)

	var listener: Variant = _S_AdListener.new()
	listener.on_ad_loaded = func() -> void:
		_banner_visible = true
		banner_visibility_changed.emit(true)
	listener.on_ad_failed_to_load = func(_error: Variant) -> void:
		_banner_visible = false
		banner_visibility_changed.emit(false)
	_ad_view.ad_listener = listener
	_ad_view.load_ad(_S_AdRequest.new())


func hide_banner() -> void:
	if not _plugin_available:
		if _banner_visible:
			_banner_visible = false
			banner_visibility_changed.emit(false)
		return
	if _ad_view != null:
		_ad_view.destroy()
		_ad_view = null
	_banner_visible = false
	banner_visibility_changed.emit(false)


func is_banner_visible() -> bool:
	return _banner_visible


# ============================================================
# Interstitial Ads
# ============================================================

func on_stage_cleared() -> void:
	_stages_since_last_interstitial += 1


func try_show_interstitial(level: int = 999) -> bool:
	if _ads_removed or level <= AdConfig.AD_FREE_LEVELS:
		return false
	if _stages_since_last_interstitial < AdConfig.INTERSTITIAL_INTERVAL:
		return false

	var now: float = Time.get_ticks_msec() / 1000.0
	if (now - _last_interstitial_time) < AdConfig.INTERSTITIAL_COOLDOWN:
		return false

	if not _plugin_available:
		_stages_since_last_interstitial = 0
		_last_interstitial_time = now
		call_deferred("emit_signal", "interstitial_ad_closed")
		return true

	if not _initialized or _interstitial_ad == null:
		return false

	var callback: Variant = _S_FullScreenContentCallback.new()
	callback.on_ad_dismissed_full_screen_content = func() -> void:
		_interstitial_ad = null
		_interstitial_loaded = false
		_stages_since_last_interstitial = 0
		_last_interstitial_time = Time.get_ticks_msec() / 1000.0
		interstitial_ad_closed.emit()
		_preload_interstitial()
	callback.on_ad_failed_to_show_full_screen_content = func(_error: Variant) -> void:
		_interstitial_ad = null
		_interstitial_loaded = false
		interstitial_ad_closed.emit()
		_preload_interstitial()

	_interstitial_ad.full_screen_content_callback = callback
	_interstitial_ad.show()
	return true


func _preload_interstitial() -> void:
	if not _plugin_available or not _initialized:
		return
	if _interstitial_loaded or _interstitial_ad != null:
		return

	var unit_id: String = AdConfig.get_unit_id(&"interstitial")
	var load_cb: Variant = _S_InterstitialAdLoadCallback.new()
	load_cb.on_ad_loaded = func(ad: Variant) -> void:
		_interstitial_ad = ad
		_interstitial_loaded = true
	load_cb.on_ad_failed_to_load = func(_error: Variant) -> void:
		_interstitial_loaded = false
		get_tree().create_timer(AdConfig.AD_RELOAD_DELAY).timeout.connect(
			_preload_interstitial, CONNECT_ONE_SHOT
		)
	_S_InterstitialAdLoader.new().load(unit_id, _S_AdRequest.new(), load_cb)


# ============================================================
# Rewarded Ads
# ============================================================

func show_rewarded_ad(reward_type: String = "") -> void:
	_pending_reward_type = reward_type

	if not _plugin_available:
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			rewarded_ad_completed.emit(reward_type, 1)
		)
		return

	if not _initialized:
		rewarded_ad_failed.emit()
		return

	if _rewarded_ad == null:
		rewarded_ad_failed.emit()
		_preload_rewarded()
		return

	var callback: Variant = _S_FullScreenContentCallback.new()
	callback.on_ad_dismissed_full_screen_content = func() -> void:
		_rewarded_ad = null
		_rewarded_loaded = false
		_preload_rewarded()
	callback.on_ad_failed_to_show_full_screen_content = func(_error: Variant) -> void:
		_rewarded_ad = null
		_rewarded_loaded = false
		rewarded_ad_failed.emit()
		_preload_rewarded()

	_rewarded_ad.full_screen_content_callback = callback

	var reward_listener: Variant = _S_OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(reward_item: Variant) -> void:
		var amount: int = reward_item.amount if reward_item else 1
		rewarded_ad_completed.emit(_pending_reward_type, amount)

	_rewarded_ad.show(reward_listener)


func is_rewarded_ready() -> bool:
	if not _plugin_available:
		return true
	return _rewarded_ad != null


func _preload_rewarded() -> void:
	if not _plugin_available or not _initialized:
		return
	if _rewarded_loaded or _rewarded_ad != null or _rewarded_loading:
		return

	_rewarded_loading = true
	var unit_id: String = AdConfig.get_unit_id(&"rewarded")
	var load_cb: Variant = _S_RewardedAdLoadCallback.new()
	load_cb.on_ad_loaded = func(ad: Variant) -> void:
		_rewarded_ad = ad
		_rewarded_loaded = true
		_rewarded_loading = false
	load_cb.on_ad_failed_to_load = func(_error: Variant) -> void:
		_rewarded_loaded = false
		_rewarded_loading = false
		get_tree().create_timer(AdConfig.AD_RELOAD_DELAY).timeout.connect(
			_preload_rewarded, CONNECT_ONE_SHOT
		)
	_S_RewardedAdLoader.new().load(unit_id, _S_AdRequest.new(), load_cb)


# ============================================================
# Ad Removal (IAP)
# ============================================================

func remove_ads() -> void:
	_ads_removed = true
	SaveManager.save_value("ads_removed", true)
	hide_banner()
	if _interstitial_ad != null and _plugin_available:
		_interstitial_ad.destroy()
		_interstitial_ad = null
		_interstitial_loaded = false
	ads_removed_changed.emit()


func is_ads_removed() -> bool:
	return _ads_removed
