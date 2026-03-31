## ad_config.gd
## Pure-data class holding all ad-related constants and unit IDs.
## NOT an autoload — imported by AdManager via class_name.
class_name AdConfig


# ============================================================
# Policy thresholds
# ============================================================

## Levels 1..AD_FREE_LEVELS have zero ads (banner, interstitial).
const AD_FREE_LEVELS: int = 4

## Banner ads appear from this level onward.
const BANNER_START_LEVEL: int = 5

## Interstitial shows every N stage clears (after AD_FREE_LEVELS).
const INTERSTITIAL_INTERVAL: int = 3

## Minimum seconds between two interstitials.
const INTERSTITIAL_COOLDOWN: float = 90.0

## Seconds to wait before retrying a failed ad load.
const AD_RELOAD_DELAY: float = 30.0


# ============================================================
# Ad Unit IDs — Test (Google official sample IDs)
# ============================================================

const TEST_BANNER_ANDROID: String      = "ca-app-pub-3940256099942544/6300978111"
const TEST_BANNER_IOS: String          = "ca-app-pub-3940256099942544/2435281174"
const TEST_INTERSTITIAL_ANDROID: String = "ca-app-pub-3940256099942544/1033173712"
const TEST_INTERSTITIAL_IOS: String    = "ca-app-pub-3940256099942544/4411468910"
const TEST_REWARDED_ANDROID: String    = "ca-app-pub-3940256099942544/5224354917"
const TEST_REWARDED_IOS: String        = "ca-app-pub-3940256099942544/1712485313"


# ============================================================
# Ad Unit IDs — Production (replace before release)
# ============================================================

const PROD_BANNER_ANDROID: String      = "ca-app-pub-4172930503672560/5128863971"
const PROD_BANNER_IOS: String          = ""
const PROD_INTERSTITIAL_ANDROID: String = "ca-app-pub-4172930503672560/1273646341"
const PROD_INTERSTITIAL_IOS: String    = ""
const PROD_REWARDED_ANDROID: String    = "ca-app-pub-4172930503672560/9503490153"
const PROD_REWARDED_IOS: String        = ""


# ============================================================
# Toggle
# ============================================================

## Set to false before release to use production IDs.
const USE_TEST_ADS: bool = false


# ============================================================
# Ad Content Rating / Compliance
# ============================================================

## Max ad content rating: G (General), PG, T (Teen), MA (Mature)
const MAX_AD_CONTENT_RATING: String = "G"

## Tag for child-directed treatment (COPPA).
## false = this app is NOT specifically directed at children under 13.
## The app is rated "Everyone" but serves a general audience, not exclusively children.
## Ad content is restricted to G-rating via MAX_AD_CONTENT_RATING above.
const TAG_FOR_CHILD_DIRECTED: bool = false

## Tag for under age of consent (GDPR). false = user is not under age of consent.
const TAG_FOR_UNDER_AGE_OF_CONSENT: bool = false

## Privacy Policy URL
const PRIVACY_POLICY_URL: String = "https://aile1492.github.io/word-bloom-policy/#privacy"

## Terms of Service URL
const TERMS_OF_SERVICE_URL: String = "https://aile1492.github.io/word-bloom-policy/#terms"


# ============================================================
# Helper
# ============================================================

## Returns the correct unit ID for the given ad type and current platform.
## ad_type: &"banner", &"interstitial", &"rewarded"
static func get_unit_id(ad_type: StringName) -> String:
	var is_ios: bool = OS.get_name() == "iOS"

	if USE_TEST_ADS:
		match ad_type:
			&"banner":
				return TEST_BANNER_IOS if is_ios else TEST_BANNER_ANDROID
			&"interstitial":
				return TEST_INTERSTITIAL_IOS if is_ios else TEST_INTERSTITIAL_ANDROID
			&"rewarded":
				return TEST_REWARDED_IOS if is_ios else TEST_REWARDED_ANDROID
	else:
		match ad_type:
			&"banner":
				return PROD_BANNER_IOS if is_ios else PROD_BANNER_ANDROID
			&"interstitial":
				return PROD_INTERSTITIAL_IOS if is_ios else PROD_INTERSTITIAL_ANDROID
			&"rewarded":
				return PROD_REWARDED_IOS if is_ios else PROD_REWARDED_ANDROID

	push_error("AdConfig: Unknown ad_type '%s'" % ad_type)
	return ""
