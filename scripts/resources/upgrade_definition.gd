class_name UpgradeDefinition
extends Resource

@export var id: StringName
@export var class_id: StringName
@export var display_name := ""
@export_multiline var description := ""
## A value of 0 means unlimited stacks.
@export_range(0, 99, 1) var max_stacks := 3
@export_enum("wide_slash", "charge", "fortress", "twin_string", "drill_tip", "storm_front", "permafrost", "constellation", "blink_nova", "veteran_damage", "veteran_health", "veteran_cooldown") var effect_key := "veteran_damage"
