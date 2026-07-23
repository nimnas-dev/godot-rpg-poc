class_name ContentCatalog
extends Resource

## Export-safe catalog for expansion definitions. It intentionally keeps only
## authored definitions; run state and lookup caches belong to runtime owners.
@export var regions: Array[RegionDefinition] = []
@export var arenas: Array[ArenaDefinition] = []
@export var encounters: Array[EncounterDefinition] = []
@export var objectives: Array[ObjectiveDefinition] = []
@export var elite_modifiers: Array[EliteModifierDefinition] = []
@export var bosses: Array[BossDefinition] = []
@export var modifiers: Array[ModifierDefinition] = []
@export var evolutions: Array[EvolutionDefinition] = []
@export var relics: Array[RelicDefinition] = []
@export var masteries: Array[MasteryDefinition] = []
@export var quests: Array[QuestDefinition] = []
@export var cosmetics: Array[CosmeticDefinition] = []
@export var difficulties: Array[DifficultyDefinition] = []


func get_region(id: StringName) -> RegionDefinition:
	for definition in regions:
		if definition != null and definition.id == id:
			return definition
	return null


func get_arena(id: StringName) -> ArenaDefinition:
	for definition in arenas:
		if definition != null and definition.id == id:
			return definition
	return null


func get_objective(id: StringName) -> ObjectiveDefinition:
	for definition in objectives:
		if definition != null and definition.id == id:
			return definition
	return null


func get_encounter(id: StringName) -> EncounterDefinition:
	for definition in encounters:
		if definition != null and definition.id == id:
			return definition
	return null


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	_validate_regions(errors)
	_validate_arenas(errors)
	_validate_objectives(errors)
	_validate_encounters(errors)
	_validate_elite_modifiers(errors)
	_validate_bosses(errors)
	_validate_modifiers(errors)
	_validate_evolutions(errors)
	_validate_relics(errors)
	_validate_masteries(errors)
	_validate_quests(errors)
	_validate_cosmetics(errors)
	_validate_difficulties(errors)
	return errors


func is_valid_definition() -> bool:
	return validation_errors().is_empty()


func _validate_regions(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in regions:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid RegionDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "RegionDefinition", errors)


func _validate_arenas(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in arenas:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid ArenaDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "ArenaDefinition", errors)
		if get_region(definition.region_id) == null:
			errors.append("ArenaDefinition %s references missing region %s" % [definition.id, definition.region_id])


func _validate_objectives(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in objectives:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid ObjectiveDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "ObjectiveDefinition", errors)


func _validate_encounters(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in encounters:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid EncounterDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "EncounterDefinition", errors)
		if get_region(definition.region_id) == null:
			errors.append("EncounterDefinition %s references missing region %s" % [definition.id, definition.region_id])
		if get_arena(definition.arena.id) == null:
			errors.append("EncounterDefinition %s references an arena absent from the catalog" % definition.id)
		if definition.objective != null and get_objective(definition.objective.id) == null:
			errors.append("EncounterDefinition %s references an objective absent from the catalog" % definition.id)


func _validate_elite_modifiers(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in elite_modifiers:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid EliteModifierDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "EliteModifierDefinition", errors)


func _validate_bosses(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in bosses:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid BossDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "BossDefinition", errors)
		var arena := get_arena(definition.arena_id)
		if arena == null or not arena.supports_boss:
			errors.append("BossDefinition %s requires a boss-capable catalog arena" % definition.id)


func _validate_modifiers(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in modifiers:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid ModifierDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "ModifierDefinition", errors)


func _validate_evolutions(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in evolutions:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid EvolutionDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "EvolutionDefinition", errors)


func _validate_relics(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in relics:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid RelicDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "RelicDefinition", errors)


func _validate_masteries(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in masteries:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid MasteryDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "MasteryDefinition", errors)


func _validate_quests(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in quests:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid QuestDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "QuestDefinition", errors)


func _validate_cosmetics(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in cosmetics:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid CosmeticDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "CosmeticDefinition", errors)


func _validate_difficulties(errors: PackedStringArray) -> void:
	var seen: Array[StringName] = []
	for definition in difficulties:
		if definition == null or not definition.is_valid_definition():
			errors.append("Invalid DifficultyDefinition")
			continue
		_append_duplicate_error(seen, definition.id, "DifficultyDefinition", errors)


func _append_duplicate_error(seen: Array[StringName], id: StringName, type_name: String, errors: PackedStringArray) -> void:
	if seen.has(id):
		errors.append("Duplicate %s ID: %s" % [type_name, id])
		return
	seen.append(id)
