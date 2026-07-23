class_name ModifierDefinition
extends Resource

@export var id: StringName
@export_enum("power", "max_health", "move_speed", "cooldown_rate", "damage_taken", "projectile_count", "range", "mastery_gain") var target_stat := "power"
@export_enum("add", "multiply") var operation := "add"
@export var value := 0.0
@export var condition_tag: StringName
@export var source_tags: Array[StringName] = []


func is_valid_definition() -> bool:
	return not id.is_empty() and not is_zero_approx(value)
