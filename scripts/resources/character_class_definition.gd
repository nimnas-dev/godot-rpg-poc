class_name CharacterClassDefinition
extends Resource

@export var id: StringName
@export var display_name := ""
@export var title := ""
@export var body_color := Color.WHITE
@export var accent_color := Color.WHITE
@export var move_speed := 200.0
@export var max_health := 100.0
@export var power := 1.0
@export var health_per_level := 7.0
@export var actions: Array[AbilityDefinition] = []


func is_valid_definition() -> bool:
	if id.is_empty() or actions.size() != 4:
		return false
	for action in actions:
		if action == null or action.id.is_empty() or action.effect == null:
			return false
	return max_health > 0.0 and move_speed > 0.0 and power > 0.0
