class_name RelicDefinition
extends Resource

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var rarity: StringName = &"common"
@export var modifiers: Array[ModifierDefinition] = []
@export var trigger_tags: Array[StringName] = []


func is_valid_definition() -> bool:
	if id.is_empty() or display_name.is_empty() or rarity.is_empty():
		return false
	for modifier in modifiers:
		if modifier == null or not modifier.is_valid_definition():
			return false
	return true
