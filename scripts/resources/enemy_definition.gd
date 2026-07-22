class_name EnemyDefinition
extends Resource

@export var id: StringName
@export var display_name := ""
@export_enum("skirmisher", "charger", "ranged") var role := "skirmisher"
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
@export var attack: EnemyAttackDefinition


func health_for_wave(wave: int) -> float:
	return base_health + health_per_wave * wave


func damage_for_wave(wave: int) -> float:
	return base_damage + damage_per_wave * wave
