class_name NoOpEntitlementProvider
extends EntitlementProvider

var reason := "Store purchases are unavailable on this build."


func _init(new_reason: String = "") -> void:
	if not new_reason.is_empty():
		reason = new_reason


func request_entitlements() -> PlatformResult:
	return _queue_unsupported(&"query", &"", reason)


func purchase(product_id: StringName) -> PlatformResult:
	return _queue_unsupported(&"purchase", product_id, reason)


func restore_purchases() -> PlatformResult:
	return _queue_unsupported(&"restore", &"", reason)
