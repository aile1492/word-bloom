extends Node

## IAP Manager — handles Google Play Billing for in-app purchases.
## Falls back to stub mode on desktop/editor for testing.

# ============================================================
# Signals
# ============================================================

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, error: String)
signal purchase_restored(product_id: String)


# ============================================================
# Constants
# ============================================================

const PRODUCT_REMOVE_ADS: String = "remove_ads"

## All product IDs offered in the game.
var PRODUCT_IDS: PackedStringArray = PackedStringArray(["remove_ads"])


# ============================================================
# State
# ============================================================

var _billing: Variant = null  # BillingClient instance
var _plugin_available: bool = false
var _connected: bool = false
var _pending_purchase: String = ""


# ============================================================
# Lifecycle
# ============================================================

func _ready() -> void:
	_try_init_billing()


func _try_init_billing() -> void:
	# Check if BillingClient class exists (plugin installed)
	if not Engine.has_singleton("GodotGooglePlayBilling"):
		print("IAPManager: Google Play Billing not available — stub mode.")
		return

	# Dynamically load BillingClient to avoid parse-time dependency
	var bc_script: Variant = null
	var bc_path: String = "res://addons/GodotGooglePlayBilling/BillingClient.gd"
	if ResourceLoader.exists(bc_path):
		bc_script = load(bc_path)
	if bc_script == null:
		print("IAPManager: BillingClient.gd not found — stub mode.")
		return

	_billing = bc_script.new()
	add_child(_billing)

	# Connect signals
	_billing.connected.connect(_on_connected)
	_billing.disconnected.connect(_on_disconnected)
	_billing.connect_error.connect(_on_connect_error)
	_billing.on_purchase_updated.connect(_on_purchase_updated)
	_billing.query_purchases_response.connect(_on_query_purchases_response)
	_billing.acknowledge_purchase_response.connect(_on_acknowledge_response)

	_plugin_available = true
	print("IAPManager: BillingClient created — connecting to store...")
	_billing.start_connection()


# ============================================================
# Connection Callbacks
# ============================================================

func _on_connected() -> void:
	_connected = true
	print("IAPManager: Connected to Google Play Billing.")
	# Restore previous purchases on connect
	_billing.query_purchases(_billing.ProductType.INAPP)


func _on_disconnected() -> void:
	_connected = false
	print("IAPManager: Disconnected from Google Play Billing.")


func _on_connect_error(response_code: int, debug_message: String) -> void:
	_connected = false
	print("IAPManager: Connection error (code=%d): %s" % [response_code, debug_message])


# ============================================================
# Purchase
# ============================================================

## Initiates a purchase for the given product ID.
func purchase(product_id: String) -> void:
	if not _plugin_available:
		# Stub mode: simulate successful purchase after short delay
		print("IAPManager: [Stub] Simulating purchase of '%s'..." % product_id)
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			print("IAPManager: [Stub] Purchase completed: %s" % product_id)
			_handle_successful_purchase(product_id)
		)
		return

	if not _connected:
		print("IAPManager: Not connected — attempting reconnect...")
		purchase_failed.emit(product_id, "Not connected to billing service")
		_billing.start_connection()
		return

	_pending_purchase = product_id
	var result: Dictionary = _billing.purchase(product_id)
	if result.has("response_code") and result["response_code"] != 0:
		var msg: String = result.get("debug_message", "Unknown error")
		print("IAPManager: Purchase launch failed: %s" % msg)
		purchase_failed.emit(product_id, msg)


func _on_purchase_updated(response: Dictionary) -> void:
	var response_code: int = response.get("response_code", -1)

	if response_code == 0:  # BillingResponseCode.OK
		var purchases: Array = response.get("purchases", [])
		for purchase_data: Variant in purchases:
			var p: Dictionary = purchase_data if purchase_data is Dictionary else {}
			var products: Array = p.get("products", [])
			var purchase_state: int = p.get("purchase_state", 0)
			var purchase_token: String = p.get("purchase_token", "")
			var is_acknowledged: bool = p.get("is_acknowledged", false)

			if purchase_state == 1:  # PurchaseState.PURCHASED
				for product_id: Variant in products:
					if not is_acknowledged:
						print("IAPManager: Acknowledging purchase: %s" % str(product_id))
						_billing.acknowledge_purchase(purchase_token)
					else:
						_handle_successful_purchase(str(product_id))

	elif response_code == 1:  # USER_CANCELED
		print("IAPManager: Purchase cancelled by user.")
		purchase_failed.emit(_pending_purchase, "Cancelled")

	else:
		var msg: String = response.get("debug_message", "Error code: %d" % response_code)
		print("IAPManager: Purchase failed: %s" % msg)
		purchase_failed.emit(_pending_purchase, msg)


func _on_acknowledge_response(response: Dictionary) -> void:
	var response_code: int = response.get("response_code", -1)
	if response_code == 0:
		print("IAPManager: Purchase acknowledged successfully.")
		_handle_successful_purchase(_pending_purchase)
	else:
		print("IAPManager: Acknowledge failed (code=%d)." % response_code)
		purchase_failed.emit(_pending_purchase, "Acknowledge failed")


# ============================================================
# Purchase Restoration
# ============================================================

func _on_query_purchases_response(response: Dictionary) -> void:
	var response_code: int = response.get("response_code", -1)
	if response_code != 0:
		print("IAPManager: Query purchases failed (code=%d)." % response_code)
		return

	var purchases: Array = response.get("purchases", [])
	for purchase_data: Variant in purchases:
		var p: Dictionary = purchase_data if purchase_data is Dictionary else {}
		var products: Array = p.get("products", [])
		var purchase_state: int = p.get("purchase_state", 0)

		if purchase_state == 1:  # PURCHASED
			for product_id: Variant in products:
				print("IAPManager: Restored purchase: %s" % str(product_id))
				_handle_successful_purchase(str(product_id))
				purchase_restored.emit(str(product_id))


## Manually trigger purchase restoration (e.g. from settings).
func restore_purchases() -> void:
	if not _plugin_available:
		print("IAPManager: [Stub] No purchases to restore.")
		return
	if _connected:
		_billing.query_purchases(_billing.ProductType.INAPP)
	else:
		print("IAPManager: Not connected — cannot restore.")


# ============================================================
# Internal
# ============================================================

func _handle_successful_purchase(product_id: String) -> void:
	match product_id:
		PRODUCT_REMOVE_ADS:
			AdManager.remove_ads()
			print("IAPManager: Ad removal activated.")
		_:
			print("IAPManager: Unknown product '%s'." % product_id)

	AnalyticsManager.log_purchase(product_id, true)
	purchase_completed.emit(product_id)
