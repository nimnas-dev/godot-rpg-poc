class_name ObjectiveDefinition
extends Resource

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export_enum("combat", "capture", "hunt", "defend", "destroy", "survive") var kind := "combat"
@export_range(1.0, 180.0, 0.5) var target_duration := 60.0
@export_range(0, 99, 1) var target_count := 0
@export var reward_tags: Array[StringName] = []


func is_valid_definition() -> bool:
	return not id.is_empty() and not display_name.is_empty() and target_duration > 0.0 and target_count >= 0
