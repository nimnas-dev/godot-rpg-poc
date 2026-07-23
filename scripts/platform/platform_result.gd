class_name PlatformResult
extends RefCounted

## A serializable result for platform operations. Platform integrations must return
## a status instead of throwing when an optional native singleton is unavailable.
enum Status {
	OK,
	NOT_FOUND,
	OFFLINE,
	PENDING,
	CANCELLED,
	CONFLICT,
	UNSUPPORTED,
	ERROR,
}

var status: Status = Status.OK
var message := ""
var payload: Variant = null
var retryable := false


func _init(
		new_status: Status = Status.OK,
		new_message: String = "",
		new_payload: Variant = null,
		is_retryable: bool = false
	) -> void:
	status = new_status
	message = new_message
	payload = new_payload
	retryable = is_retryable


func is_success() -> bool:
	return status == Status.OK


func status_name() -> StringName:
	match status:
		Status.OK:
			return &"ok"
		Status.NOT_FOUND:
			return &"not_found"
		Status.OFFLINE:
			return &"offline"
		Status.PENDING:
			return &"pending"
		Status.CANCELLED:
			return &"cancelled"
		Status.CONFLICT:
			return &"conflict"
		Status.UNSUPPORTED:
			return &"unsupported"
		_:
			return &"error"


static func ok(new_payload: Variant = null, new_message: String = "") -> PlatformResult:
	return PlatformResult.new(Status.OK, new_message, new_payload)


static func not_found(new_message: String = "No data was found.") -> PlatformResult:
	return PlatformResult.new(Status.NOT_FOUND, new_message)


static func offline(new_message: String = "The platform service is offline.") -> PlatformResult:
	return PlatformResult.new(Status.OFFLINE, new_message, null, true)


static func pending(new_message: String = "The platform operation is pending.") -> PlatformResult:
	return PlatformResult.new(Status.PENDING, new_message, null, true)


static func cancelled(new_message: String = "The platform operation was cancelled.") -> PlatformResult:
	return PlatformResult.new(Status.CANCELLED, new_message)


static func conflict(new_payload: Variant, new_message: String = "Cloud save conflict requires a decision.") -> PlatformResult:
	return PlatformResult.new(Status.CONFLICT, new_message, new_payload)


static func unsupported(new_message: String = "This platform feature is unavailable.") -> PlatformResult:
	return PlatformResult.new(Status.UNSUPPORTED, new_message)


static func error(new_message: String, is_retryable: bool = false) -> PlatformResult:
	return PlatformResult.new(Status.ERROR, new_message, null, is_retryable)
