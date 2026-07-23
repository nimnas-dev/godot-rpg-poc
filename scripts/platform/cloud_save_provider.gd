class_name CloudSaveProvider
extends RefCounted

signal cloud_operation_finished(operation: StringName, result: PlatformResult)
signal conflict_detected(conflict: CloudSaveConflict)


func load_save(_save_id: StringName) -> PlatformResult:
	var result := PlatformResult.unsupported("Cloud save is not configured for this platform.")
	_emit_operation(&"load", result)
	return result


func write_save(_envelope: CloudSaveEnvelope) -> PlatformResult:
	var result := PlatformResult.unsupported("Cloud save is not configured for this platform.")
	_emit_operation(&"write", result)
	return result


func resolve_conflict(_conflict: CloudSaveConflict, _resolution: CloudSaveConflict.Resolution) -> PlatformResult:
	var result := PlatformResult.unsupported("Cloud conflict resolution is not configured for this platform.")
	_emit_operation(&"resolve_conflict", result)
	return result


func _emit_operation(operation: StringName, result: PlatformResult) -> void:
	cloud_operation_finished.emit(operation, result)
