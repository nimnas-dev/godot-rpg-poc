extends SceneTree

const MASTERY_SCRIPT := preload("res://scripts/mastery_controller.gd")

var _checks := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_swordsman()
	_test_archer()
	_test_mage()
	if _failures.is_empty():
		print("PASS: %d mastery checks" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("FAIL: %d / %d mastery checks" % [_failures.size(), _checks])
		quit(1)


func _test_swordsman() -> void:
	var mastery = MASTERY_SCRIPT.new()
	mastery.configure(&"class.swordsman")
	for index in range(4):
		mastery.report_perfect_guard()
	_check(mastery.ready and is_equal_approx(mastery.current, 100.0), "four perfect guards ready Resolve")
	_check(not mastery.consume_for_ability(&"ability.swordsman.slash", 0), "basic attack cannot consume mastery")
	_check(mastery.consume_for_ability(&"ability.swordsman.charge", 2), "skill consumes Resolve")


func _test_archer() -> void:
	var mastery = MASTERY_SCRIPT.new()
	mastery.configure(&"class.archer")
	for index in range(10):
		mastery.report_ranged_hit(320.0, true)
	_check(mastery.ready, "ten long moving hits ready Focus")
	mastery.consume_for_ability(&"ability.archer.pierce", 2)
	mastery.report_ranged_hit(320.0, true)
	mastery.report_player_damaged()
	_check(is_zero_approx(mastery.current), "damage removes unready Focus")


func _test_mage() -> void:
	var mastery = MASTERY_SCRIPT.new()
	mastery.configure(&"class.mage")
	mastery.report_spell_hit(&"arcane")
	mastery.report_spell_hit(&"frost")
	mastery.report_spell_hit(&"astral")
	_check(mastery.ready, "three distinct spell tags ready Resonance")
	var saved: Dictionary = mastery.make_runtime_state()
	var restored = MASTERY_SCRIPT.new()
	restored.configure(&"class.mage")
	_check(restored.restore_runtime(saved) and restored.ready, "Resonance save restores")
	restored.consume_for_ability(&"ability.mage.blink", 3)
	restored.report_spell_hit(&"arcane")
	restored.report_spell_hit(&"arcane")
	_check(restored.get("_resonance_tags").size() == 1, "repeated spell restarts Resonance chain")
	restored.advance(6.1)
	_check(is_zero_approx(restored.current), "Resonance expires after its window")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
