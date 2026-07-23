class_name BossDefinition
extends Resource

@export var id: StringName
@export var enemy_id: StringName
@export var display_name := ""
@export var arena_id: StringName
@export_range(1, 4, 1) var phase_count := 2
@export var learned_rule_tags: Array[StringName] = []
@export var reward_relic_ids: Array[StringName] = []


func is_valid_definition() -> bool:
	return not id.is_empty() and not enemy_id.is_empty() and not arena_id.is_empty() and not display_name.is_empty() and phase_count >= 1
