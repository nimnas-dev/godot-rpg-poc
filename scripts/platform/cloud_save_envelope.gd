class_name CloudSaveEnvelope
extends RefCounted

## Binary-safe save boundary. Gameplay owns the payload schema; platform code only
## transports a named, revisioned envelope.
var save_id: StringName
var revision: int
var updated_unix_ms: int
var content_type: StringName
var payload: PackedByteArray


func _init(
		new_save_id: StringName = &"",
		new_revision: int = 0,
		new_payload: PackedByteArray = PackedByteArray(),
		new_updated_unix_ms: int = 0,
		new_content_type: StringName = &"application/octet-stream"
	) -> void:
	save_id = new_save_id
	revision = maxi(0, new_revision)
	updated_unix_ms = maxi(0, new_updated_unix_ms)
	content_type = new_content_type
	payload = new_payload.duplicate()


static func from_text(
		new_save_id: StringName,
		text: String,
		new_revision: int = 0,
		new_updated_unix_ms: int = 0,
		new_content_type: StringName = &"application/json"
	) -> CloudSaveEnvelope:
	return CloudSaveEnvelope.new(new_save_id, new_revision, text.to_utf8_buffer(), new_updated_unix_ms, new_content_type)


func to_text() -> String:
	return payload.get_string_from_utf8()


func duplicate_envelope() -> CloudSaveEnvelope:
	return CloudSaveEnvelope.new(save_id, revision, payload, updated_unix_ms, content_type)


func is_valid() -> bool:
	return not save_id.is_empty() and revision >= 0 and updated_unix_ms >= 0


func has_same_payload(other: CloudSaveEnvelope) -> bool:
	return other != null and payload == other.payload and content_type == other.content_type


func to_dictionary() -> Dictionary:
	return {
		"save_id": String(save_id),
		"revision": revision,
		"updated_unix_ms": updated_unix_ms,
		"content_type": String(content_type),
		"payload_base64": Marshalls.raw_to_base64(payload),
	}


static func from_dictionary(data: Dictionary) -> CloudSaveEnvelope:
	if not data.has_all(["save_id", "revision", "updated_unix_ms", "content_type", "payload_base64"]):
		return null
	if not data["payload_base64"] is String:
		return null
	var envelope := CloudSaveEnvelope.new(
		StringName(str(data["save_id"])),
		int(data["revision"]),
		Marshalls.base64_to_raw(str(data["payload_base64"])),
		int(data["updated_unix_ms"]),
		StringName(str(data["content_type"]))
	)
	return envelope if envelope.is_valid() else null
