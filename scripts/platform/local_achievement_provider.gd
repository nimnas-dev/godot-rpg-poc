class_name LocalAchievementProvider
extends AchievementProvider

## The queue is intentionally separate from gameplay save state. A platform
## implementation can persist or submit it without altering run/profile rules.
var online := true
var _progress_by_id: Dictionary = {}
var _pending_by_id: Dictionary = {}


func set_online(value: bool) -> PlatformResult:
	online = value
	return flush_pending() if online else PlatformResult.offline("Achievement reports will be queued until reconnect.")


func report_progress(achievement_id: StringName, progress: float) -> PlatformResult:
	if achievement_id.is_empty() or not is_finite(progress):
		var invalid := PlatformResult.error("Achievement id and progress must be valid.")
		_emit_operation(&"report_progress", achievement_id, invalid)
		return invalid
	var normalized := clampf(progress, 0.0, 100.0)
	var previous := float(_progress_by_id.get(achievement_id, 0.0))
	_progress_by_id[achievement_id] = maxf(previous, normalized)
	if not online:
		_pending_by_id[achievement_id] = _progress_by_id[achievement_id]
		var offline := PlatformResult.offline("Achievement progress was queued for reconnect.")
		_emit_operation(&"report_progress", achievement_id, offline)
		return offline
	var result := PlatformResult.ok(_progress_by_id[achievement_id])
	_emit_operation(&"report_progress", achievement_id, result)
	return result


func flush_pending() -> PlatformResult:
	if not online:
		var offline := PlatformResult.offline("Achievement queue remains pending while offline.")
		_emit_operation(&"flush_pending", &"", offline)
		return offline
	var flushed := _pending_by_id.size()
	_pending_by_id.clear()
	var result := PlatformResult.ok(flushed, "Queued achievement reports flushed.")
	_emit_operation(&"flush_pending", &"", result)
	return result


func get_progress(achievement_id: StringName) -> float:
	return float(_progress_by_id.get(achievement_id, 0.0))


func pending_count() -> int:
	return _pending_by_id.size()
