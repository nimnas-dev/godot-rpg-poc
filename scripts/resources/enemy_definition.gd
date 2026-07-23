class_name EnemyDefinition
extends Resource

@export var id: StringName
@export var display_name := ""
@export var region_id: StringName
@export_enum("skirmisher", "charger", "ranged", "anchor", "support", "artillery", "swarmer", "flanker", "jailer", "summoner") var role := "skirmisher"
@export_enum("pursue", "hold_range", "orbit", "flank", "anchor") var movement_mode := "pursue"
@export_multiline var counterplay := ""
@export var body_color := Color.WHITE
@export var accent_color := Color.WHITE
@export var base_health := 40.0
@export var health_per_wave := 7.0
@export var move_speed := 75.0
@export var base_damage := 7.0
@export var damage_per_wave := 0.65
@export var experience_value := 13
@export var preferred_min_distance := 0.0
@export var preferred_max_distance := 0.0
@export_range(0.1, 12.0, 0.1) var threat_cost := 1.0
@export var has_frontal_guard := false
@export_range(-1.0, 1.0, 0.01) var frontal_guard_dot := -0.45
@export_range(0.0, 1.0, 0.01) var frontal_damage_multiplier := 1.0
@export var is_boss := false
@export_range(1, 4, 1) var boss_phase_count := 1
@export_range(0.0, 1.0, 0.01) var boss_damage_per_phase := 0.12
@export_range(0.0, 1.0, 0.01) var boss_speed_per_phase := 0.08
@export var attack: EnemyAttackDefinition


func health_for_wave(wave: int) -> float:
	return base_health + health_per_wave * wave


func damage_for_wave(wave: int) -> float:
	return base_damage + damage_per_wave * wave


func is_valid_definition() -> bool:
	return not id.is_empty() and not region_id.is_empty() and not counterplay.is_empty() and base_health > 0.0 and health_per_wave >= 0.0 and move_speed > 0.0 and base_damage >= 0.0 and damage_per_wave >= 0.0 and experience_value > 0 and threat_cost > 0.0 and attack != null and attack.is_valid_definition()
