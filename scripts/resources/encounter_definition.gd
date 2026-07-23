class_name EncounterDefinition
extends Resource

@export var id: StringName
@export var region_id: StringName
@export var display_name := ""
@export_enum("combat", "elite", "recovery", "shrine", "boss") var kind := "combat"
@export var objective: ObjectiveDefinition
@export var arena: ArenaDefinition
@export var enemy_ids: Array[StringName] = []
@export var elite_modifier: EliteModifierDefinition
@export var boss: BossDefinition
@export_range(0.0, 1000.0, 0.25) var threat_budget := 0.0
@export_range(1, 24, 1) var max_active_enemies := 12
@export_range(0, 8, 1) var max_ranged_attackers := 1


func is_valid_definition() -> bool:
	if id.is_empty() or region_id.is_empty() or display_name.is_empty() or arena == null:
		return false
	if max_active_enemies < 1 or max_ranged_attackers < 0 or max_ranged_attackers > max_active_enemies:
		return false
	if kind == "boss":
		return boss != null and boss.is_valid_definition()
	if kind == "recovery" or kind == "shrine":
		return objective == null and enemy_ids.is_empty()
	return objective != null and objective.is_valid_definition() and not enemy_ids.is_empty() and threat_budget > 0.0
