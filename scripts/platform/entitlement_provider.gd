class_name EntitlementProvider
extends RefCounted

## Purchase APIs always return PENDING and deliver their final state through this
## signal. This keeps StoreKit/Billing callbacks out of gameplay and UI code.
signal entitlement_operation_finished(operation: StringName, product_id: StringName, result: PlatformResult)


func request_entitlements() -> PlatformResult:
	return _queue_unsupported(&"query", &"", "Entitlement queries are not configured for this platform.")


func purchase(product_id: StringName) -> PlatformResult:
	return _queue_unsupported(&"purchase", product_id, "Purchases are not configured for this platform.")


func restore_purchases() -> PlatformResult:
	return _queue_unsupported(&"restore", &"", "Purchase restore is not configured for this platform.")


func _queue_unsupported(operation: StringName, product_id: StringName, message: String) -> PlatformResult:
	call_deferred("_emit_operation", operation, product_id, PlatformResult.unsupported(message))
	return PlatformResult.pending()


func _emit_operation(operation: StringName, product_id: StringName, result: PlatformResult) -> void:
	entitlement_operation_finished.emit(operation, product_id, result)
