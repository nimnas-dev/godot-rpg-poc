class_name NoOpAchievementProvider
extends AchievementProvider

var reason := "Achievements are unavailable on this build."


func _init(new_reason: String = "") -> void:
	if not new_reason.is_empty():
		reason = new_reason


func report_progress(achievement_id: StringName, _progress: float) -> PlatformResult:
	var result := PlatformResult.unsupported(reason)
	_emit_operation(&"report_progress", achievement_id, result)
	return result


func flush_pending() -> PlatformResult:
	var result := PlatformResult.unsupported(reason)
	_emit_operation(&"flush_pending", &"", result)
	return result
