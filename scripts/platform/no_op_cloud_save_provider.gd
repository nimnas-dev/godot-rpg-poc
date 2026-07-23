class_name NoOpCloudSaveProvider
extends CloudSaveProvider

var reason := "Cloud save is unavailable on this build."


func _init(new_reason: String = "") -> void:
	if not new_reason.is_empty():
		reason = new_reason


func load_save(_save_id: StringName) -> PlatformResult:
	var result := PlatformResult.unsupported(reason)
	_emit_operation(&"load", result)
	return result


func write_save(_envelope: CloudSaveEnvelope) -> PlatformResult:
	var result := PlatformResult.unsupported(reason)
	_emit_operation(&"write", result)
	return result


func resolve_conflict(_conflict: CloudSaveConflict, _resolution: CloudSaveConflict.Resolution) -> PlatformResult:
	var result := PlatformResult.unsupported(reason)
	_emit_operation(&"resolve_conflict", result)
	return result
