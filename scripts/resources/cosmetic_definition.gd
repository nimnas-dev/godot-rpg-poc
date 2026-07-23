class_name CosmeticDefinition
extends Resource

@export var id: StringName
@export var display_name := ""
@export var class_id: StringName
@export_enum("earned", "premium") var acquisition := "earned"
@export var unlock_quest_id: StringName
@export var platform_product_id: StringName
@export var palette: Array[Color] = []


func is_valid_definition() -> bool:
	if id.is_empty() or display_name.is_empty() or class_id.is_empty() or palette.is_empty():
		return false
	if acquisition == "earned":
		return not unlock_quest_id.is_empty() and platform_product_id.is_empty()
	return not platform_product_id.is_empty() and unlock_quest_id.is_empty()
