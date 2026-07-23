class_name AchievementProvider
extends RefCounted

signal achievement_operation_finished(operation: StringName, achievement_id: StringName, result: PlatformResult)


func report_progress(_achievement_id: StringName, _progress: float) -> PlatformResult:
	var result := PlatformResult.unsupported("Achievements are not configured for this platform.")
	_emit_operation(&"report_progress", _achievement_id, result)
	return result


func flush_pending() -> PlatformResult:
	var result := PlatformResult.unsupported("Achievements are not configured for this platform.")
	_emit_operation(&"flush_pending", &"", result)
	return result


func _emit_operation(operation: StringName, achievement_id: StringName, result: PlatformResult) -> void:
	achievement_operation_finished.emit(operation, achievement_id, result)
