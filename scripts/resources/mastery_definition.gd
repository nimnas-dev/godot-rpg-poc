class_name MasteryDefinition
extends Resource

@export var id: StringName
@export var class_id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export_range(1.0, 1000.0, 1.0) var threshold := 100.0
@export_range(0.0, 100.0, 0.1) var decay_per_second := 0.0
@export var trigger_tags: Array[StringName] = []
@export var trigger_modifier: ModifierDefinition


func is_valid_definition() -> bool:
	return not id.is_empty() and not class_id.is_empty() and not display_name.is_empty() and threshold > 0.0 and decay_per_second >= 0.0 and trigger_modifier != null and trigger_modifier.is_valid_definition()
