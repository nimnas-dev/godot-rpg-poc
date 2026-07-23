class_name EnemyAttackDefinition
extends Resource

## The delivery determines the authoritative gameplay result. Presentation may
## add rings, particles, or audio, but must not change this contract.
@export_enum("melee", "dash", "projectile", "zone", "support", "control", "summon") var delivery := "melee"
@export_enum("player", "ally", "area") var target_kind := "player"
@export var anticipation := 0.35
@export var active_duration := 0.16
@export var recovery := 0.7
@export var attack_range := 70.0
@export var hit_radius := 42.0
@export var charge_distance := 50.0
@export var charge_width := 34.0
@export var projectile_speed := 0.0
@export var direction_lock_time := 0.0
@export var ranged := false
## Strong attacks remain visible by default. EncounterDirector also enforces
## this at the shared attack-token boundary.
@export var allow_offscreen := false
@export var requires_attack_token := true
@export var special_radius := 0.0
@export var special_power := 0.0
@export var persistent_duration := 0.0


func uses_ranged_token() -> bool:
	return ranged or delivery == "projectile" or delivery == "zone" or delivery == "control" or delivery == "support" or delivery == "summon"


func is_valid_definition() -> bool:
	if anticipation < 0.0 or active_duration <= 0.0 or recovery < 0.0 or attack_range <= 0.0:
		return false
	if ranged or delivery == "projectile" or delivery == "zone" or delivery == "control" or delivery == "summon":
		return projectile_speed > 0.0 and hit_radius > 0.0
	if delivery == "support":
		return special_radius > 0.0 and special_power > 0.0
	return hit_radius > 0.0 and charge_width > 0.0
