class_name DifficultyDefinition
extends Resource

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export_range(0.25, 3.0, 0.01) var enemy_damage_multiplier := 1.0
@export_range(0.25, 3.0, 0.01) var enemy_health_multiplier := 1.0
@export_range(0.25, 2.0, 0.01) var telegraph_duration_multiplier := 1.0
@export_range(1, 8, 1) var max_attackers := 3
@export_range(0, 4, 1) var max_ranged_attackers := 1
@export var required_unlock_id: StringName


func is_valid_definition() -> bool:
	return not id.is_empty() and not display_name.is_empty() and enemy_damage_multiplier > 0.0 and enemy_health_multiplier > 0.0 and telegraph_duration_multiplier > 0.0 and max_attackers >= 1 and max_ranged_attackers >= 0 and max_ranged_attackers <= max_attackers
