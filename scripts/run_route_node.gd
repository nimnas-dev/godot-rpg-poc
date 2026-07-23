class_name RunRouteNode
extends RefCounted

var id: StringName
var depth := 0
var encounter_kind: StringName
var objective_id: StringName
var arena_id: StringName
var reward_tags: Array[StringName] = []
var next_node_ids: Array[StringName] = []


func is_elite() -> bool:
	return encounter_kind == &"elite"


func is_recovery_opportunity() -> bool:
	return encounter_kind == &"recovery" or encounter_kind == &"shrine"


func is_boss() -> bool:
	return encounter_kind == &"boss"
