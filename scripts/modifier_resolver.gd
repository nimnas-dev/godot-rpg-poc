class_name ModifierResolver
extends RefCounted

var _sources: Array[ModifierDefinition] = []


func set_sources(sources: Array[ModifierDefinition]) -> void:
	_sources.clear()
	for source in sources:
		if source != null and source.is_valid_definition():
			_sources.append(source)


func calculate(target_stat: String, base_value: float, context_tags: Array[StringName] = []) -> float:
	var additive := 0.0
	var multiplier := 1.0
	for source in _sources:
		if source.target_stat != target_stat or not _matches_condition(source, context_tags):
			continue
		if source.operation == "add":
			additive += source.value
		else:
			multiplier *= source.value
	return (base_value + additive) * multiplier


func calculate_int(target_stat: String, base_value: int, context_tags: Array[StringName] = []) -> int:
	return maxi(0, roundi(calculate(target_stat, float(base_value), context_tags)))


func snapshot_source_ids() -> Array[String]:
	var result: Array[String] = []
	for source in _sources:
		result.append(String(source.id))
	return result


func _matches_condition(source: ModifierDefinition, context_tags: Array[StringName]) -> bool:
	if not source.condition_tag.is_empty() and not context_tags.has(source.condition_tag):
		return false
	for required_tag in source.source_tags:
		if not context_tags.has(required_tag):
			return false
	return true
