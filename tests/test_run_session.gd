extends SceneTree

const RUN_SESSION_SCRIPT := preload("res://scripts/run_session.gd")

var _checks := 0
var _failures: Array[String] = []


func _initialize() -> void:
	var session := RUN_SESSION_SCRIPT.new()
	session.configure_new(&"class.archer", &"difficulty.hunter", &"region.hollowwood", 901)
	_check(session.chapter == 1 and session.depth == 1, "new run starts at chapter/depth 1")
	_check(session.complete_encounter(5) == false and session.depth == 2, "normal encounter advances depth")
	for reward in [6, 7, 8, 25]:
		session.complete_encounter(reward)
	_check(session.depth == 6, "five encounters complete a chapter")
	_check(session.bank_completed_chapter() == 51, "chapter reward banks exactly once")
	_check(session.bank_completed_chapter() == 0, "banking is idempotent")
	_check(session.add_relic(&"relic.test.one"), "relic can be added")
	for index in range(2, 5):
		_check(session.add_relic(StringName("relic.test.%d" % index)), "four relic slots are available")
	_check(not session.add_relic(&"relic.test.five"), "fifth relic requires replacement")
	_check(session.add_relic(&"relic.test.five", 1), "relic replacement uses explicit slot")
	session.continue_to_region(&"region.ossuary")
	_check(session.chapter == 2 and session.depth == 1, "continue starts next chapter")
	_check(session.region_id == &"region.ossuary", "continue records chosen region")
	var saved := session.make_runtime_state()
	var restored := RUN_SESSION_SCRIPT.new()
	_check(restored.restore_runtime(saved), "valid runtime state restores")
	_check(restored.make_runtime_state() == saved, "runtime state round-trips")
	_check(not restored.restore_runtime({"run_seed": 3}), "invalid state is rejected")
	if _failures.is_empty():
		print("PASS: %d run session checks" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("FAIL: %d / %d run session checks" % [_failures.size(), _checks])
		quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
