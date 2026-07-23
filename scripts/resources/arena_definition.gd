class_name ArenaDefinition
extends Resource

@export var id: StringName
@export var region_id: StringName
@export var display_name := ""
@export var world_size := Vector2(2400.0, 1600.0)
@export var landmark_tags: Array[StringName] = []
@export var supports_boss := false
@export var supports_objective_ids: Array[StringName] = []


func is_valid_definition() -> bool:
	return not id.is_empty() and not region_id.is_empty() and not display_name.is_empty() and world_size.x > 0.0 and world_size.y > 0.0
