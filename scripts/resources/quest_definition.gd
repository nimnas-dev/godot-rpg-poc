class_name QuestDefinition
extends Resource

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var prerequisite_ids: Array[StringName] = []
@export var objective_ids: Array[StringName] = []
@export var reward_relic_ids: Array[StringName] = []
@export var unlock_region_ids: Array[StringName] = []
@export var repeatable := false


func is_valid_definition() -> bool:
	return not id.is_empty() and not display_name.is_empty() and not objective_ids.is_empty()
