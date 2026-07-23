class_name MasteryController
extends RefCounted

signal mastery_changed(current: float, maximum: float, segments: int)
signal mastery_ready
signal mastery_consumed(ability_id: StringName)

const SWORDSMAN_ID := &"class.swordsman"
const ARCHER_ID := &"class.archer"
const MAGE_ID := &"class.mage"
const METER_MAX := 100.0
const RESONANCE_WINDOW := 6.0

var class_id: StringName
var current := 0.0
var ready := false
var _resonance_tags: Array[StringName] = []
var _resonance_clock := 0.0


func configure(new_class_id: StringName) -> void:
	class_id = new_class_id
	current = 0.0
	ready = false
	_resonance_tags.clear()
	_resonance_clock = 0.0
	_emit_state()


func advance(delta: float) -> void:
	if class_id != MAGE_ID or _resonance_tags.is_empty():
		return
	_resonance_clock = maxf(0.0, _resonance_clock - delta)
	if _resonance_clock <= 0.0:
		_resonance_tags.clear()
		current = 0.0
		ready = false
		_emit_state()


func report_perfect_guard() -> void:
	if class_id == SWORDSMAN_ID:
		_add_meter(25.0)


func report_multi_hit(target_count: int) -> void:
	if class_id == SWORDSMAN_ID and target_count >= 2:
		_add_meter(8.0)


func report_ranged_hit(distance: float, moving: bool) -> void:
	if class_id != ARCHER_ID:
		return
	var gain := 6.0 if distance >= 280.0 else 0.0
	if moving:
		gain += 4.0
	if gain > 0.0:
		_add_meter(gain)


func report_player_damaged() -> void:
	if class_id == ARCHER_ID and current > 0.0 and not ready:
		current = maxf(0.0, current - 25.0)
		_emit_state()


func report_spell_hit(tag: StringName) -> void:
	if class_id != MAGE_ID or tag.is_empty():
		return
	if _resonance_tags.has(tag):
		_resonance_tags.clear()
		_resonance_tags.append(tag)
	else:
		_resonance_tags.append(tag)
	_resonance_clock = RESONANCE_WINDOW
	current = minf(METER_MAX, float(_resonance_tags.size()) / 3.0 * METER_MAX)
	if _resonance_tags.size() >= 3:
		ready = true
		mastery_ready.emit()
	_emit_state()


func consume_for_ability(ability_id: StringName, slot: int) -> bool:
	if not ready or slot <= 0:
		return false
	ready = false
	current = 0.0
	_resonance_tags.clear()
	_resonance_clock = 0.0
	mastery_consumed.emit(ability_id)
	_emit_state()
	return true


func make_runtime_state() -> Dictionary:
	return {
		"class_id": String(class_id),
		"current": current,
		"ready": ready,
		"resonance_tags": _stringify_ids(_resonance_tags),
		"resonance_clock": _resonance_clock,
	}


func restore_runtime(data: Dictionary) -> bool:
	var saved_class := StringName(data.get("class_id", ""))
	if saved_class != class_id:
		return false
	current = clampf(float(data.get("current", 0.0)), 0.0, METER_MAX)
	ready = bool(data.get("ready", false))
	_resonance_tags.clear()
	var raw_tags: Variant = data.get("resonance_tags", [])
	if raw_tags is Array:
		for value in raw_tags:
			var tag := StringName(value)
			if not tag.is_empty() and not _resonance_tags.has(tag):
				_resonance_tags.append(tag)
	_resonance_tags.resize(mini(3, _resonance_tags.size()))
	_resonance_clock = clampf(float(data.get("resonance_clock", 0.0)), 0.0, RESONANCE_WINDOW)
	_emit_state()
	return true


func _add_meter(amount: float) -> void:
	if ready:
		return
	current = minf(METER_MAX, current + amount)
	if current >= METER_MAX:
		ready = true
		mastery_ready.emit()
	_emit_state()


func _emit_state() -> void:
	var segments := _resonance_tags.size() if class_id == MAGE_ID else int(floor(current / 25.0))
	mastery_changed.emit(current, METER_MAX, segments)


func _stringify_ids(ids: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for id in ids:
		result.append(String(id))
	return result
