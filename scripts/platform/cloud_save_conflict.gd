class_name CloudSaveConflict
extends RefCounted

## A conflict never resolves itself. The application flow must submit one of the
## named resolutions after it presents the two snapshots to the player.
enum Resolution {
	KEEP_LOCAL,
	KEEP_REMOTE,
}

var save_id: StringName
var local_envelope: CloudSaveEnvelope
var remote_envelope: CloudSaveEnvelope
var reason: StringName


func _init(
		new_save_id: StringName = &"",
		new_local_envelope: CloudSaveEnvelope = null,
		new_remote_envelope: CloudSaveEnvelope = null,
		new_reason: StringName = &"revision_diverged"
	) -> void:
	save_id = new_save_id
	local_envelope = new_local_envelope.duplicate_envelope() if new_local_envelope != null else null
	remote_envelope = new_remote_envelope.duplicate_envelope() if new_remote_envelope != null else null
	reason = new_reason


func is_valid() -> bool:
	return not save_id.is_empty() and local_envelope != null and remote_envelope != null
