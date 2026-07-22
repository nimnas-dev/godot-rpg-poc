class_name ContentRegistry
extends RefCounted

const CLASS_RESOURCES: Array[CharacterClassDefinition] = [
	preload("res://data/classes/swordsman.tres"),
	preload("res://data/classes/archer.tres"),
	preload("res://data/classes/mage.tres"),
]
const ENEMY_RESOURCES: Array[EnemyDefinition] = [
	preload("res://data/enemies/slime.tres"),
	preload("res://data/enemies/goblin.tres"),
	preload("res://data/enemies/wraith.tres"),
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


func _init() -> void:
	for definition in CLASS_RESOURCES:
		if definition.is_valid_definition():
			_classes[definition.id] = definition
	for definition in ENEMY_RESOURCES:
		_enemies[definition.id] = definition
	for definition in UPGRADE_RESOURCES:
		_upgrades[definition.id] = definition


func get_class_definition(id: StringName) -> CharacterClassDefinition:
	return _classes.get(id) as CharacterClassDefinition


func get_enemy_definition(id: StringName) -> EnemyDefinition:
	return _enemies.get(id) as EnemyDefinition


func get_upgrade_definition(id: StringName) -> UpgradeDefinition:
	return _upgrades.get(id) as UpgradeDefinition


func has_class(id: StringName) -> bool:
	return _classes.has(id)


func has_upgrade(id: StringName) -> bool:
	return _upgrades.has(id)


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
