class_name LocalEntitlementProvider
extends EntitlementProvider

## A storeless provider can expose already-known cosmetic entitlements for local
## development, but it never fabricates a completed purchase.
var _owned_product_ids: Dictionary = {}


func _init(initial_owned_product_ids: PackedStringArray = PackedStringArray()) -> void:
	for product_id in initial_owned_product_ids:
		if not product_id.is_empty():
			_owned_product_ids[StringName(product_id)] = true


func request_entitlements() -> PlatformResult:
	_queue_result(&"query", &"", PlatformResult.ok(get_owned_product_ids()))
	return PlatformResult.pending()


func purchase(product_id: StringName) -> PlatformResult:
	if product_id.is_empty():
		_queue_result(&"purchase", product_id, PlatformResult.error("A product id is required."))
	else:
		_queue_result(&"purchase", product_id, PlatformResult.unsupported("Local entitlement provider cannot complete store purchases."))
	return PlatformResult.pending()


func restore_purchases() -> PlatformResult:
	_queue_result(&"restore", &"", PlatformResult.ok(get_owned_product_ids(), "Known local entitlements restored."))
	return PlatformResult.pending()


func get_owned_product_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for product_id in _owned_product_ids.keys():
		result.append(String(product_id))
	result.sort()
	return result


func set_local_entitlements(product_ids: PackedStringArray) -> void:
	_owned_product_ids.clear()
	for product_id in product_ids:
		if not product_id.is_empty():
			_owned_product_ids[StringName(product_id)] = true


func _queue_result(operation: StringName, product_id: StringName, result: PlatformResult) -> void:
	call_deferred("_emit_operation", operation, product_id, result)
