class_name ContentRegistry
extends RefCounted

const EXPANSION_FACTORY := preload("res://scripts/expansion_content_factory.gd")

const CLASS_RESOURCES: Array[CharacterClassDefinition] = [
	preload("res://data/classes/swordsman.tres"),
	preload("res://data/classes/archer.tres"),
	preload("res://data/classes/mage.tres"),
]
const ENEMY_RESOURCES: Array[EnemyDefinition] = [
	preload("res://data/enemies/slime.tres"),
	preload("res://data/enemies/goblin.tres"),
	preload("res://data/enemies/wraith.tres"),
	preload("res://data/enemies/shield_guardian.tres"),
	preload("res://data/enemies/cantor_healer.tres"),
	preload("res://data/enemies/bell_artillery.tres"),
	preload("res://data/enemies/leech_swarm.tres"),
	preload("res://data/enemies/burrow_stalker.tres"),
	preload("res://data/enemies/plague_hexer.tres"),
	preload("res://data/enemies/frost_hound.tres"),
	preload("res://data/enemies/mirror_sniper.tres"),
	preload("res://data/enemies/ice_jailer.tres"),
	preload("res://data/enemies/void_knight.tres"),
	preload("res://data/enemies/blink_assassin.tres"),
	preload("res://data/enemies/rift_summoner.tres"),
	preload("res://data/enemies/rift_warden.tres"),
	preload("res://data/enemies/ashen_abbot.tres"),
	preload("res://data/enemies/bloodroot_matron.tres"),
	preload("res://data/enemies/glass_huntsman.tres"),
	preload("res://data/enemies/pale_archon.tres"),
]
const UPGRADE_RESOURCES: Array[UpgradeDefinition] = [
	preload("res://data/upgrades/swordsman_wide_slash.tres"),
	preload("res://data/upgrades/swordsman_charge.tres"),
	preload("res://data/upgrades/swordsman_fortress.tres"),
	preload("res://data/upgrades/archer_twin_string.tres"),
	preload("res://data/upgrades/archer_drill_tip.tres"),
	preload("res://data/upgrades/archer_storm_front.tres"),
	preload("res://data/upgrades/mage_permafrost.tres"),
	preload("res://data/upgrades/mage_constellation.tres"),
	preload("res://data/upgrades/mage_blink_nova.tres"),
	preload("res://data/upgrades/veteran_damage.tres"),
	preload("res://data/upgrades/veteran_health.tres"),
	preload("res://data/upgrades/veteran_cooldown.tres"),
]
const FEEDBACK_PROFILE: FeedbackProfile = preload("res://data/feedback/default.tres")

var _classes: Dictionary = {}
var _enemies: Dictionary = {}
var _upgrades: Dictionary = {}
var expansion_catalog: ContentCatalog
var _regions: Dictionary = {}
var _difficulties: Dictionary = {}
var _relics: Dictionary = {}
var _evolutions: Dictionary = {}
var _quests: Dictionary = {}
var _cosmetics: Dictionary = {}


func _init() -> void:
	for definition in CLASS_RESOURCES:
		if definition.is_valid_definition():
			_classes[definition.id] = definition
	for definition in ENEMY_RESOURCES:
		_enemies[definition.id] = definition
	for definition in UPGRADE_RESOURCES:
		_upgrades[definition.id] = definition
	expansion_catalog = EXPANSION_FACTORY.build()
	for definition in expansion_catalog.regions:
		_regions[definition.id] = definition
	for definition in expansion_catalog.difficulties:
		_difficulties[definition.id] = definition
	for definition in expansion_catalog.relics:
		_relics[definition.id] = definition
	for definition in expansion_catalog.evolutions:
		_evolutions[definition.id] = definition
	for definition in expansion_catalog.quests:
		_quests[definition.id] = definition
	for definition in expansion_catalog.cosmetics:
		_cosmetics[definition.id] = definition


func get_class_definition(id: StringName) -> CharacterClassDefinition:
	return _classes.get(id) as CharacterClassDefinition


func get_enemy_definition(id: StringName) -> EnemyDefinition:
	return _enemies.get(id) as EnemyDefinition


func get_upgrade_definition(id: StringName) -> UpgradeDefinition:
	return _upgrades.get(id) as UpgradeDefinition


func get_region_definition(id: StringName) -> RegionDefinition:
	return _regions.get(id) as RegionDefinition


func get_difficulty_definition(id: StringName) -> DifficultyDefinition:
	return _difficulties.get(id) as DifficultyDefinition


func get_relic_definition(id: StringName) -> RelicDefinition:
	return _relics.get(id) as RelicDefinition


func get_evolution_definition(id: StringName) -> EvolutionDefinition:
	return _evolutions.get(id) as EvolutionDefinition


func get_quest_definition(id: StringName) -> QuestDefinition:
	return _quests.get(id) as QuestDefinition


func get_cosmetic_definition(id: StringName) -> CosmeticDefinition:
	return _cosmetics.get(id) as CosmeticDefinition


func get_all_quests() -> Array[QuestDefinition]:
	return expansion_catalog.quests.duplicate() if expansion_catalog != null else []


func get_all_cosmetics() -> Array[CosmeticDefinition]:
	return expansion_catalog.cosmetics.duplicate() if expansion_catalog != null else []


func get_objective_definition(id: StringName) -> ObjectiveDefinition:
	return expansion_catalog.get_objective(id) if expansion_catalog != null else null


func has_class(id: StringName) -> bool:
	return _classes.has(id)


func has_upgrade(id: StringName) -> bool:
	return _upgrades.has(id)


func has_region(id: StringName) -> bool:
	return _regions.has(id)


func has_relic(id: StringName) -> bool:
	return _relics.has(id)


func has_evolution(id: StringName) -> bool:
	return _evolutions.has(id)


func get_upgrades_for_class(class_id: StringName, stacks: Dictionary) -> Array[UpgradeDefinition]:
	var available: Array[UpgradeDefinition] = []
	for definition in UPGRADE_RESOURCES:
		if definition.class_id == class_id and (definition.max_stacks == 0 or int(stacks.get(definition.id, 0)) < definition.max_stacks):
			available.append(definition)
	return available


func get_veteran_upgrades() -> Array[UpgradeDefinition]:
	var result: Array[UpgradeDefinition] = []
	for definition in UPGRADE_RESOURCES:
		if definition.class_id == &"class.any":
			result.append(definition)
	return result


func get_enemies_for_region(region_id: StringName, include_boss: bool = false) -> Array[EnemyDefinition]:
	var result: Array[EnemyDefinition] = []
	for definition in ENEMY_RESOURCES:
		if definition.region_id == region_id and (include_boss or not definition.is_boss):
			result.append(definition)
	return result


func get_boss_for_region(region_id: StringName) -> EnemyDefinition:
	for definition in ENEMY_RESOURCES:
		if definition.region_id == region_id and definition.is_boss:
			return definition
	return null


func get_route_objective_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition in expansion_catalog.objectives:
		result.append(definition.id)
	return result


func get_arena_ids_for_region(region_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var region := get_region_definition(region_id)
	if region == null:
		return result
	for arena in region.arenas:
		if not arena.supports_boss:
			result.append(arena.id)
	return result


func get_next_region_ids(region_id: StringName) -> Array[StringName]:
	var region := get_region_definition(region_id)
	return region.next_region_ids.duplicate() if region != null else []


func get_relic_choices(seed: int, excluded_ids: Array[StringName] = []) -> Array[RelicDefinition]:
	var pool: Array[RelicDefinition] = []
	for definition in expansion_catalog.relics:
		if not excluded_ids.has(definition.id):
			pool.append(definition)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for index in range(pool.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var previous := pool[index]
		pool[index] = pool[other]
		pool[other] = previous
	var result: Array[RelicDefinition] = []
	for index in range(mini(3, pool.size())):
		result.append(pool[index])
	return result


func get_evolutions_for_class(class_id: StringName) -> Array[EvolutionDefinition]:
	var result: Array[EvolutionDefinition] = []
	for definition in expansion_catalog.evolutions:
		if definition.class_id == class_id:
			result.append(definition)
	return result


func get_feedback_profile() -> FeedbackProfile:
	return FEEDBACK_PROFILE


func validate_ids(class_id: StringName, upgrade_stacks: Dictionary) -> bool:
	if not has_class(class_id):
		return false
	for id in upgrade_stacks:
		var definition := get_upgrade_definition(StringName(id))
		var count := int(upgrade_stacks[id])
		if definition == null or count < 0 or count > 100:
			return false
		if definition.class_id != class_id and definition.class_id != &"class.any":
			return false
		if definition.max_stacks > 0 and count > definition.max_stacks:
			return false
	return true


func validate_run_content_ids(region_id: StringName, difficulty_id: StringName, relic_ids: Array, evolution_ids: Array) -> bool:
	if not has_region(region_id) or get_difficulty_definition(difficulty_id) == null:
		return false
	for id in relic_ids:
		if not has_relic(StringName(id)):
			return false
	for id in evolution_ids:
		var definition := get_evolution_definition(StringName(id))
		if definition == null or definition.class_id.is_empty():
			return false
	return true
