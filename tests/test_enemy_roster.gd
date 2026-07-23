extends SceneTree

const ROSTER: Array[EnemyDefinition] = [
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
]

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	var ids: Dictionary = {}
	var per_region: Dictionary = {}
	var roles: Dictionary = {}
	for definition in ROSTER:
		_check(definition != null, "roster resource must load")
		if definition == null:
			continue
		_check(definition.is_valid_definition(), "%s must satisfy the enemy data contract" % definition.id)
		_check(not ids.has(definition.id), "%s must be a unique stable ID" % definition.id)
		ids[definition.id] = true
		per_region[definition.region_id] = int(per_region.get(definition.region_id, 0)) + 1
		roles[definition.role] = true
		_check(not definition.attack.allow_offscreen, "%s may not execute its strong attack off-screen" % definition.id)
		_check(definition.attack.anticipation >= 0.25, "%s needs a readable anticipation window" % definition.id)
		_check(definition.attack.recovery >= 0.5, "%s needs a counterattack recovery window" % definition.id)
	_check(ids.size() == 15, "the roster must expose fifteen stable enemy definitions")
	for region_id in [&"region.hollow_grove", &"region.ossuary_monastery", &"region.bloodwater_bog", &"region.frozen_sanatorium", &"region.rift_cathedral"]:
		_check(int(per_region.get(region_id, 0)) == 3, "%s must have exactly three normal enemies" % region_id)
	for role in ["anchor", "support", "artillery", "swarmer", "flanker", "jailer", "summoner"]:
		_check(roles.has(role), "roster must include the %s combat role" % role)
	_check(ROSTER[2].attack.uses_ranged_token(), "existing wraith must keep ranged attack-token compatibility")
	_check(ROSTER[4].attack.delivery == "support" and ROSTER[4].attack.target_kind == "ally", "healer must use the support ally contract")
	_check(ROSTER[5].attack.delivery == "zone", "artillery must declare its zone delivery")
	_check(ROSTER[14].attack.delivery == "summon", "summoner must declare its future world-owned summon delivery")
	if _failures.is_empty():
		print("PASS: %d enemy roster checks" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("FAIL: %d failures / %d enemy roster checks" % [_failures.size(), _checks])
		quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
