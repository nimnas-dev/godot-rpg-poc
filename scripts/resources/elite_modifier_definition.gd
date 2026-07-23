class_name EliteModifierDefinition
extends Resource

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var threat_multiplier := 1.35
@export var modifier_ids: Array[StringName] = []
@export var telegraph_color := Color(1.0, 0.72, 0.2)


func is_valid_definition() -> bool:
	return not id.is_empty() and not display_name.is_empty() and threat_multiplier >= 1.0
