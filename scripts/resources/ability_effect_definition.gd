class_name AbilityEffectDefinition
extends Resource

@export_enum("melee_cone", "area", "dash", "guard", "projectile", "spread", "line_projectile", "target_area", "teleport") var kind := "projectile"
@export var damage := 0.0
@export var range := 0.0
@export var radius := 0.0
@export var speed := 0.0
@export var pierce := 0
@export var projectile_count := 1
@export var duration := 0.0
@export var status_type: String = ""
@export var status_strength := 0.0
@export var status_duration := 0.0
