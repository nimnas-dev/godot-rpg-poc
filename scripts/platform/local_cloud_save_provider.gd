class_name LocalCloudSaveProvider
extends CloudSaveProvider

## In-memory deterministic provider for desktop development and headless tests.
## Production persistence remains owned by RunSaveService; this provider models
## the revision/conflict contract a native cloud adapter must preserve.
var online := true
var _saves: Dictionary = {}


func set_online(value: bool) -> void:
	online = value


func load_save(save_id: StringName) -> PlatformResult:
	if not online:
		var offline := PlatformResult.offline()
		_emit_operation(&"load", offline)
		return offline
	var stored: CloudSaveEnvelope = _saves.get(save_id, null)
	if stored == null:
		var missing := PlatformResult.not_found()
		_emit_operation(&"load", missing)
		return missing
	var result := PlatformResult.ok(stored.duplicate_envelope())
	_emit_operation(&"load", result)
	return result


func write_save(envelope: CloudSaveEnvelope) -> PlatformResult:
	if envelope == null or not envelope.is_valid():
		var invalid := PlatformResult.error("Cloud save envelope is invalid.")
		_emit_operation(&"write", invalid)
		return invalid
	if not online:
		var offline := PlatformResult.offline()
		_emit_operation(&"write", offline)
		return offline
	var existing: CloudSaveEnvelope = _saves.get(envelope.save_id, null)
	if existing == null:
		var created := _store(envelope)
		_emit_operation(&"write", created)
		return created
	if envelope.revision > existing.revision:
		var replaced := _store(envelope)
		_emit_operation(&"write", replaced)
		return replaced
	if envelope.revision == existing.revision and envelope.has_same_payload(existing):
		var idempotent := PlatformResult.ok(existing.duplicate_envelope(), "Cloud save already matches this revision.")
		_emit_operation(&"write", idempotent)
		return idempotent
	var conflict := CloudSaveConflict.new(envelope.save_id, envelope, existing)
	var conflict_result := PlatformResult.conflict(conflict)
	conflict_detected.emit(conflict)
	_emit_operation(&"write", conflict_result)
	return conflict_result


func resolve_conflict(conflict: CloudSaveConflict, resolution: CloudSaveConflict.Resolution) -> PlatformResult:
	if conflict == null or not conflict.is_valid():
		var invalid := PlatformResult.error("Cloud conflict payload is invalid.")
		_emit_operation(&"resolve_conflict", invalid)
		return invalid
	if not online:
		var offline := PlatformResult.offline()
		_emit_operation(&"resolve_conflict", offline)
		return offline
	var current: CloudSaveEnvelope = _saves.get(conflict.save_id, null)
	if current == null or not current.has_same_payload(conflict.remote_envelope) or current.revision != conflict.remote_envelope.revision:
		var stale := PlatformResult.error("Cloud conflict is stale; load the latest save before resolving.", true)
		_emit_operation(&"resolve_conflict", stale)
		return stale
	var chosen: CloudSaveEnvelope
	match resolution:
		CloudSaveConflict.Resolution.KEEP_LOCAL:
			chosen = conflict.local_envelope.duplicate_envelope()
			chosen.revision = maxi(conflict.local_envelope.revision, conflict.remote_envelope.revision) + 1
			chosen.updated_unix_ms = int(Time.get_unix_time_from_system() * 1000.0)
		CloudSaveConflict.Resolution.KEEP_REMOTE:
			chosen = conflict.remote_envelope.duplicate_envelope()
		_:
			var unsupported := PlatformResult.unsupported("The requested cloud conflict resolution is unsupported.")
			_emit_operation(&"resolve_conflict", unsupported)
			return unsupported
	var result := _store(chosen)
	_emit_operation(&"resolve_conflict", result)
	return result


func _store(envelope: CloudSaveEnvelope) -> PlatformResult:
	var normalized := envelope.duplicate_envelope()
	if normalized.updated_unix_ms <= 0:
		normalized.updated_unix_ms = int(Time.get_unix_time_from_system() * 1000.0)
	_saves[normalized.save_id] = normalized
	return PlatformResult.ok(normalized.duplicate_envelope())
