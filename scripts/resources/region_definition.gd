class_name RegionDefinition
extends Resource

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var theme_color := Color.WHITE
@export var arenas: Array[ArenaDefinition] = []
@export var encounters: Array[EncounterDefinition] = []
@export var boss: BossDefinition
@export var next_region_ids: Array[StringName] = []
@export var required_unlock_id: StringName


func is_valid_definition() -> bool:
	if id.is_empty() or display_name.is_empty() or arenas.is_empty() or boss == null or not boss.is_valid_definition():
		return false
	for arena in arenas:
		if arena == null or not arena.is_valid_definition() or arena.region_id != id:
			return false
	return true
