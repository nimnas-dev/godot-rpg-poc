class_name PlatformServices
extends RefCounted

## Application-level platform coordinator. It does not own gameplay profile,
## checkpoint, quest, or run data; it only forwards platform service events.
signal cloud_operation_finished(operation: StringName, result: PlatformResult)
signal cloud_conflict_detected(conflict: CloudSaveConflict)
signal achievement_operation_finished(operation: StringName, achievement_id: StringName, result: PlatformResult)
signal entitlement_operation_finished(operation: StringName, product_id: StringName, result: PlatformResult)
signal purchased_entitlements_changed(product_ids: PackedStringArray)

var cloud_save: CloudSaveProvider
var achievements: AchievementProvider
var entitlements: EntitlementProvider
var _purchased_entitlement_ids: Dictionary = {}


func _init(
		new_cloud_save: CloudSaveProvider = null,
		new_achievements: AchievementProvider = null,
		new_entitlements: EntitlementProvider = null
	) -> void:
	cloud_save = new_cloud_save if new_cloud_save != null else LocalCloudSaveProvider.new()
	achievements = new_achievements if new_achievements != null else LocalAchievementProvider.new()
	entitlements = new_entitlements if new_entitlements != null else LocalEntitlementProvider.new()
	cloud_save.cloud_operation_finished.connect(_on_cloud_operation_finished)
	cloud_save.conflict_detected.connect(_on_cloud_conflict_detected)
	achievements.achievement_operation_finished.connect(_on_achievement_operation_finished)
	entitlements.entitlement_operation_finished.connect(_on_entitlement_operation_finished)


static func create_local(initial_owned_product_ids: PackedStringArray = PackedStringArray()) -> PlatformServices:
	return PlatformServices.new(
		LocalCloudSaveProvider.new(),
		LocalAchievementProvider.new(),
		LocalEntitlementProvider.new(initial_owned_product_ids)
	)


static func create_no_op() -> PlatformServices:
	return PlatformServices.new(NoOpCloudSaveProvider.new(), NoOpAchievementProvider.new(), NoOpEntitlementProvider.new())


func load_cloud_save(save_id: StringName) -> PlatformResult:
	return cloud_save.load_save(save_id)


func write_cloud_save(envelope: CloudSaveEnvelope) -> PlatformResult:
	return cloud_save.write_save(envelope)


func resolve_cloud_conflict(conflict: CloudSaveConflict, resolution: CloudSaveConflict.Resolution) -> PlatformResult:
	return cloud_save.resolve_conflict(conflict, resolution)


func report_achievement_progress(achievement_id: StringName, progress: float) -> PlatformResult:
	return achievements.report_progress(achievement_id, progress)


func flush_achievement_queue() -> PlatformResult:
	return achievements.flush_pending()


## The returned PENDING result is not a purchase result. Observe
## entitlement_operation_finished for OK, CANCELLED, UNSUPPORTED, or ERROR.
func request_purchased_entitlements() -> PlatformResult:
	return entitlements.request_entitlements()


func purchase(product_id: StringName) -> PlatformResult:
	return entitlements.purchase(product_id)


func restore_purchases() -> PlatformResult:
	return entitlements.restore_purchases()


func get_purchased_entitlements() -> PackedStringArray:
	var product_ids := PackedStringArray()
	for product_id in _purchased_entitlement_ids.keys():
		product_ids.append(String(product_id))
	product_ids.sort()
	return product_ids


func owns_entitlement(product_id: StringName) -> bool:
	return _purchased_entitlement_ids.has(product_id)


func shutdown() -> void:
	if cloud_save != null:
		if cloud_save.cloud_operation_finished.is_connected(_on_cloud_operation_finished):
			cloud_save.cloud_operation_finished.disconnect(_on_cloud_operation_finished)
		if cloud_save.conflict_detected.is_connected(_on_cloud_conflict_detected):
			cloud_save.conflict_detected.disconnect(_on_cloud_conflict_detected)
	if achievements != null and achievements.achievement_operation_finished.is_connected(_on_achievement_operation_finished):
		achievements.achievement_operation_finished.disconnect(_on_achievement_operation_finished)
	if entitlements != null and entitlements.entitlement_operation_finished.is_connected(_on_entitlement_operation_finished):
		entitlements.entitlement_operation_finished.disconnect(_on_entitlement_operation_finished)
	cloud_save = null
	achievements = null
	entitlements = null
	_purchased_entitlement_ids.clear()


func _on_cloud_operation_finished(operation: StringName, result: PlatformResult) -> void:
	cloud_operation_finished.emit(operation, result)


func _on_cloud_conflict_detected(conflict: CloudSaveConflict) -> void:
	cloud_conflict_detected.emit(conflict)


func _on_achievement_operation_finished(operation: StringName, achievement_id: StringName, result: PlatformResult) -> void:
	achievement_operation_finished.emit(operation, achievement_id, result)


func _on_entitlement_operation_finished(operation: StringName, product_id: StringName, result: PlatformResult) -> void:
	if result.is_success() and operation in [&"query", &"restore", &"purchase"]:
		var owned_ids := _extract_product_ids(result.payload)
		if not owned_ids.is_empty() or operation != &"purchase":
			_replace_purchased_entitlements(owned_ids)
	entitlement_operation_finished.emit(operation, product_id, result)


func _extract_product_ids(value: Variant) -> PackedStringArray:
	var product_ids := PackedStringArray()
	if value is PackedStringArray:
		for product_id in value:
			if not product_id.is_empty():
				product_ids.append(product_id)
	elif value is Array:
		for product_id in value:
			var normalized := str(product_id)
			if not normalized.is_empty():
				product_ids.append(normalized)
	return product_ids


func _replace_purchased_entitlements(product_ids: PackedStringArray) -> void:
	var previous := get_purchased_entitlements()
	_purchased_entitlement_ids.clear()
	for product_id in product_ids:
		_purchased_entitlement_ids[StringName(product_id)] = true
	var current := get_purchased_entitlements()
	if current != previous:
		purchased_entitlements_changed.emit(current)
