class_name AndroidGooglePlayCloudSaveProvider
extends CloudSaveProvider

## Plugin APIs are intentionally not guessed. These wrappers only discover
## optional singletons and fail explicitly until a verified Android plugin
## contract is linked for the exact Godot/export-template version.
const PLAY_GAMES_SINGLETONS: Array[StringName] = [&"GooglePlayGames", &"GodotGooglePlayGames"]

var singleton_name: StringName


func _init() -> void:
	singleton_name = _find_singleton(PLAY_GAMES_SINGLETONS)


func load_save(_save_id: StringName) -> PlatformResult:
	return _unsupported(&"load")


func write_save(_envelope: CloudSaveEnvelope) -> PlatformResult:
	return _unsupported(&"write")


func resolve_conflict(_conflict: CloudSaveConflict, _resolution: CloudSaveConflict.Resolution) -> PlatformResult:
	return _unsupported(&"resolve_conflict")


func _unsupported(operation: StringName) -> PlatformResult:
	var result := PlatformResult.unsupported(_native_message("Google Play Games Saved Games"))
	_emit_operation(operation, result)
	return result


func _native_message(feature: String) -> String:
	if singleton_name.is_empty():
		return "%s singleton is unavailable; local saves remain authoritative." % feature
	return "%s singleton '%s' was detected, but no verified native API adapter is linked." % [feature, singleton_name]


static func _find_singleton(candidates: Array[StringName]) -> StringName:
	for candidate in candidates:
		if Engine.has_singleton(candidate):
			return candidate
	return &""


class AndroidGooglePlayAchievementProvider:
	extends AchievementProvider

	const PLAY_GAMES_SINGLETONS: Array[StringName] = [&"GooglePlayGames", &"GodotGooglePlayGames"]
	var singleton_name: StringName

	func _init() -> void:
		singleton_name = _find_singleton(PLAY_GAMES_SINGLETONS)

	static func _find_singleton(candidates: Array[StringName]) -> StringName:
		for candidate in candidates:
			if Engine.has_singleton(candidate):
				return candidate
		return &""

	func report_progress(achievement_id: StringName, _progress: float) -> PlatformResult:
		var result := PlatformResult.unsupported(_native_message())
		_emit_operation(&"report_progress", achievement_id, result)
		return result

	func flush_pending() -> PlatformResult:
		var result := PlatformResult.unsupported(_native_message())
		_emit_operation(&"flush_pending", &"", result)
		return result

	func _native_message() -> String:
		if singleton_name.is_empty():
			return "Google Play Games singleton is unavailable; achievement reports cannot leave the offline queue."
		return "Google Play Games singleton '%s' was detected, but no verified achievement API adapter is linked." % singleton_name


class AndroidBillingEntitlementProvider:
	extends EntitlementProvider

	const BILLING_SINGLETONS: Array[StringName] = [&"GooglePlayBilling", &"GodotGooglePlayBilling"]
	var singleton_name: StringName

	func _init() -> void:
		singleton_name = _find_singleton(BILLING_SINGLETONS)

	static func _find_singleton(candidates: Array[StringName]) -> StringName:
		for candidate in candidates:
			if Engine.has_singleton(candidate):
				return candidate
		return &""

	func request_entitlements() -> PlatformResult:
		return _queue_unsupported(&"query", &"", _native_message())

	func purchase(product_id: StringName) -> PlatformResult:
		return _queue_unsupported(&"purchase", product_id, _native_message())

	func restore_purchases() -> PlatformResult:
		return _queue_unsupported(&"restore", &"", _native_message())

	func _native_message() -> String:
		if singleton_name.is_empty():
			return "Google Play Billing singleton is unavailable; purchases cannot be started on this build."
		return "Google Play Billing singleton '%s' was detected, but no verified billing API adapter is linked." % singleton_name
