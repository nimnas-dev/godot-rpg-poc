extends SceneTree

const PlatformServicesScript = preload("res://scripts/platform/platform_services.gd")
const LocalCloudSaveProviderScript = preload("res://scripts/platform/local_cloud_save_provider.gd")
const LocalAchievementProviderScript = preload("res://scripts/platform/local_achievement_provider.gd")
const LocalEntitlementProviderScript = preload("res://scripts/platform/local_entitlement_provider.gd")
const NoOpCloudSaveProviderScript = preload("res://scripts/platform/no_op_cloud_save_provider.gd")
const NoOpEntitlementProviderScript = preload("res://scripts/platform/no_op_entitlement_provider.gd")
const CloudSaveEnvelopeScript = preload("res://scripts/platform/cloud_save_envelope.gd")
const CloudSaveConflictScript = preload("res://scripts/platform/cloud_save_conflict.gd")
const AndroidPlatformServicesScript = preload("res://scripts/platform/android_services.gd")
const IOSPlatformServicesScript = preload("res://scripts/platform/ios_services.gd")

var _checks := 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_envelope_round_trip()
	_test_local_cloud_conflict_policy()
	_test_achievement_offline_queue()
	await _test_entitlement_async_boundary()
	await _test_no_op_contract()
	await _test_native_wrapper_absence()
	if _failures.is_empty():
		print("PASS: %d platform-service checks" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("FAIL: %d failures / %d checks" % [_failures.size(), _checks])
		quit(1)


func _test_envelope_round_trip() -> void:
	var original := CloudSaveEnvelopeScript.from_text(&"profile.primary", "{\"xp\":42}", 7, 1234)
	var decoded := CloudSaveEnvelopeScript.from_dictionary(original.to_dictionary())
	_check(decoded != null, "cloud envelope dictionary must decode")
	_check(decoded.to_text() == "{\"xp\":42}", "cloud envelope must preserve UTF-8 payload")
	_check(decoded.revision == 7 and decoded.content_type == &"application/json", "cloud envelope must preserve revision and content type")


func _test_local_cloud_conflict_policy() -> void:
	var provider = LocalCloudSaveProviderScript.new()
	var conflicts: Array = []
	provider.conflict_detected.connect(func(conflict) -> void: conflicts.append(conflict))
	var remote := CloudSaveEnvelopeScript.from_text(&"profile.primary", "remote", 2, 2000)
	_check(provider.write_save(remote).is_success(), "first cloud write should store a revisioned envelope")
	var stale_local := CloudSaveEnvelopeScript.from_text(&"profile.primary", "local", 1, 1000)
	var rejected = provider.write_save(stale_local)
	_check(rejected.status_name() == &"conflict", "stale divergent cloud write must return an explicit conflict")
	_check(conflicts.size() == 1 and conflicts[0].is_valid(), "cloud conflict callback must contain both envelopes")
	var keep_remote = provider.resolve_conflict(conflicts[0], CloudSaveConflictScript.Resolution.KEEP_REMOTE)
	_check(keep_remote.is_success() and keep_remote.payload.to_text() == "remote", "KEEP_REMOTE must preserve remote content")
	var second_conflict = provider.write_save(stale_local)
	_check(second_conflict.status_name() == &"conflict" and conflicts.size() == 2, "a later divergent write must request a fresh conflict decision")
	var keep_local = provider.resolve_conflict(conflicts[1], CloudSaveConflictScript.Resolution.KEEP_LOCAL)
	_check(keep_local.is_success() and keep_local.payload.revision == 3, "KEEP_LOCAL must create a monotonic replacement revision")
	var loaded = provider.load_save(&"profile.primary")
	_check(loaded.is_success() and loaded.payload.to_text() == "local", "resolved cloud save must become the authoritative stored envelope")


func _test_achievement_offline_queue() -> void:
	var provider = LocalAchievementProviderScript.new()
	provider.set_online(false)
	var queued = provider.report_progress(&"achievement.first_boss", 45.0)
	_check(queued.status_name() == &"offline", "offline achievement report must return offline status")
	_check(provider.pending_count() == 1 and is_equal_approx(provider.get_progress(&"achievement.first_boss"), 45.0), "offline achievement report must retain queued progress")
	var flushed = provider.set_online(true)
	_check(flushed.is_success() and provider.pending_count() == 0, "reconnect must flush queued achievement progress")


func _test_entitlement_async_boundary() -> void:
	var profile := {"best_cleared_wave": 5, "settings": {"haptics": true}}
	var profile_before := profile.duplicate(true)
	var entitlement_provider = LocalEntitlementProviderScript.new(PackedStringArray(["cosmetic.swordsman.ash"] ))
	var services = PlatformServicesScript.new(LocalCloudSaveProviderScript.new(), LocalAchievementProviderScript.new(), entitlement_provider)
	var events: Array[Dictionary] = []
	services.entitlement_operation_finished.connect(func(operation: StringName, product_id: StringName, result) -> void:
		events.append({"operation": operation, "product_id": product_id, "result": result})
	)
	var pending = services.request_purchased_entitlements()
	_check(pending.status_name() == &"pending", "entitlement query must return pending before async completion")
	await process_frame
	await process_frame
	_check(events.size() == 1 and events[0]["result"].is_success(), "entitlement query must finish through its async event")
	_check(services.owns_entitlement(&"cosmetic.swordsman.ash"), "coordinator must retain purchased entitlements separately")
	_check(profile == profile_before, "platform entitlements must not mutate gameplay profile data")
	var purchase_pending = services.purchase(&"cosmetic.archer.moon")
	_check(purchase_pending.status_name() == &"pending", "store purchase request must return pending, never a fabricated success")
	await process_frame
	await process_frame
	_check(events.size() == 2 and events[1]["result"].status_name() == &"unsupported", "local provider must report unsupported purchase through async event")


func _test_no_op_contract() -> void:
	var cloud = NoOpCloudSaveProviderScript.new()
	_check(cloud.load_save(&"profile.primary").status_name() == &"unsupported", "No-op cloud provider must be explicit about unsupported service")
	var entitlements = NoOpEntitlementProviderScript.new()
	var final_results: Array = []
	entitlements.entitlement_operation_finished.connect(func(_operation: StringName, _product_id: StringName, result) -> void: final_results.append(result))
	_check(entitlements.restore_purchases().status_name() == &"pending", "No-op restore still follows the async purchase event contract")
	await process_frame
	await process_frame
	_check(final_results.size() == 1 and final_results[0].status_name() == &"unsupported", "No-op restore must finish with unsupported rather than silently succeeding")


func _test_native_wrapper_absence() -> void:
	var android = AndroidPlatformServicesScript.new()
	_check(android.load_cloud_save(&"profile.primary").status_name() == &"unsupported", "Android singleton absence must return unsupported without calling a plugin API")
	var android_events: Array = []
	android.entitlement_operation_finished.connect(func(_operation: StringName, _product_id: StringName, result) -> void: android_events.append(result))
	_check(android.restore_purchases().status_name() == &"pending", "Android restore request must retain async contract without Billing")
	await process_frame
	await process_frame
	_check(android_events.size() == 1 and android_events[0].status_name() == &"unsupported", "Android absent Billing singleton must finish explicitly unsupported")
	var ios = IOSPlatformServicesScript.new()
	_check(ios.load_cloud_save(&"profile.primary").status_name() == &"unsupported", "iOS singleton absence must return unsupported without calling a plugin API")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
