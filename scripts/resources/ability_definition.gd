class_name AbilityDefinition
extends Resource

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var tags: Array[StringName] = []
@export_range(0.05, 60.0, 0.01) var cooldown := 1.0
@export var color := Color.WHITE
@export var effect: AbilityEffectDefinition
