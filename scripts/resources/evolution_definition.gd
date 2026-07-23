class_name EvolutionDefinition
extends Resource

@export var id: StringName
@export var class_id: StringName
@export var ability_id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var exclusive_group: StringName
@export var modifiers: Array[ModifierDefinition] = []
@export var required_upgrade_ids: Array[StringName] = []


func is_valid_definition() -> bool:
	if id.is_empty() or class_id.is_empty() or ability_id.is_empty() or display_name.is_empty() or exclusive_group.is_empty() or modifiers.is_empty():
		return false
	for modifier in modifiers:
		if modifier == null or not modifier.is_valid_definition():
			return false
	return true
