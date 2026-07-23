extends SceneTree

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	_test_deterministic_route_generation()
	_test_route_contracts()
	_test_invalid_route_input()
	_test_content_catalog_validation()
	if _failures.is_empty():
		print("PASS: %d checks" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("FAIL: %d failures / %d checks" % [_failures.size(), _checks])
		quit(1)


func _test_deterministic_route_generation() -> void:
	var generator := RunRouteGenerator.new()
	var first := generator.generate(481516)
	var second := generator.generate(481516)
	_check(first.is_valid(), "default route must meet the chapter contract")
	_check(first.signature() == second.signature(), "the same seed must produce the same route")
	_check(first.nodes.size() == 8, "a five-depth chapter must contain one, two, two, two, one nodes")


func _test_route_contracts() -> void:
	var objectives: Array[StringName] = [&"objective.combat", &"objective.capture", &"objective.hunt", &"objective.defend"]
	var arenas: Array[StringName] = [&"arena.a", &"arena.b"]
	var plan := RunRouteGenerator.new().generate(9123, objectives, arenas)
	_check(plan.is_valid(), "custom content IDs must still make a valid route")
	_check(plan.get_nodes_at_depth(1).size() == 1 and plan.get_nodes_at_depth(1)[0].encounter_kind == &"combat", "depth one must be one fixed combat")
	_check(plan.get_nodes_at_depth(2).size() == 2 and plan.get_nodes_at_depth(3).size() == 2 and plan.get_nodes_at_depth(4).size() == 2, "depths two through four must offer two choices")
	_check(plan.get_nodes_at_depth(5).size() == 1 and plan.get_nodes_at_depth(5)[0].is_boss(), "depth five must end in a boss")
	var objective_ids: Array[StringName] = []
	var elite_count := 0
	var recovery_count := 0
	for node in plan.nodes:
		if not node.objective_id.is_empty() and not objective_ids.has(node.objective_id):
			objective_ids.append(node.objective_id)
		if node.is_elite():
			elite_count += 1
		if node.is_recovery_opportunity():
			recovery_count += 1
	_check(objective_ids.size() == 4, "objectives cannot repeat across chapter depths")
	_check(elite_count >= 1, "the route must expose an elite opportunity")
	_check(recovery_count >= 1, "the route must expose a recovery or shrine opportunity")
	for depth in range(1, 5):
		for node in plan.get_nodes_at_depth(depth):
			_check(not node.next_node_ids.is_empty(), "every non-boss route node must lead forward")


func _test_invalid_route_input() -> void:
	var objectives: Array[StringName] = [&"objective.combat", &"objective.capture", &"objective.hunt"]
	var plan := RunRouteGenerator.new().generate(3, objectives)
	_check(not plan.is_valid(), "route generation must reject fewer than four unique objectives")
	_check(not plan.generation_error.is_empty(), "invalid route input must explain the generation failure")


func _test_content_catalog_validation() -> void:
	var objective := ObjectiveDefinition.new()
	objective.id = &"objective.combat"
	objective.display_name = "Skirmish"
	var arena := ArenaDefinition.new()
	arena.id = &"arena.meadow"
	arena.region_id = &"region.meadow"
	arena.display_name = "Hollow Meadow"
	arena.supports_boss = true
	var boss := BossDefinition.new()
	boss.id = &"boss.rift_warden"
	boss.enemy_id = &"enemy.rift_warden"
	boss.display_name = "Rift Warden"
	boss.arena_id = arena.id
	var region := RegionDefinition.new()
	region.id = arena.region_id
	region.display_name = "Hollow Meadow"
	region.arenas = [arena]
	region.boss = boss
	var encounter := EncounterDefinition.new()
	encounter.id = &"encounter.meadow.combat"
	encounter.region_id = region.id
	encounter.display_name = "First Contact"
	encounter.objective = objective
	encounter.arena = arena
	encounter.enemy_ids = [&"enemy.slime"]
	encounter.threat_budget = 10.0
	var modifier := ModifierDefinition.new()
	modifier.id = &"modifier.power.small"
	modifier.value = 0.1
	var evolution := EvolutionDefinition.new()
	evolution.id = &"evolution.swordsman.shatter"
	evolution.class_id = &"class.swordsman"
	evolution.ability_id = &"ability.swordsman.charge"
	evolution.display_name = "Shatter"
	evolution.exclusive_group = &"evolution.swordsman.charge"
	evolution.modifiers = [modifier]
	var relic := RelicDefinition.new()
	relic.id = &"relic.black_thorn"
	relic.display_name = "Black Thorn"
	var mastery := MasteryDefinition.new()
	mastery.id = &"mastery.swordsman.resolve"
	mastery.class_id = &"class.swordsman"
	mastery.display_name = "Resolve"
	mastery.trigger_modifier = modifier
	var quest := QuestDefinition.new()
	quest.id = &"quest.first_blood"
	quest.display_name = "First Blood"
	quest.objective_ids = [objective.id]
	var cosmetic := CosmeticDefinition.new()
	cosmetic.id = &"cosmetic.swordsman.ashen"
	cosmetic.display_name = "Ashen Knight"
	cosmetic.class_id = &"class.swordsman"
	cosmetic.unlock_quest_id = quest.id
	cosmetic.palette = [Color.WHITE, Color.BLACK]
	var difficulty := DifficultyDefinition.new()
	difficulty.id = &"difficulty.hunter"
	difficulty.display_name = "Hunter"
	var catalog := ContentCatalog.new()
	catalog.regions = [region]
	catalog.arenas = [arena]
	catalog.encounters = [encounter]
	catalog.objectives = [objective]
	catalog.bosses = [boss]
	catalog.modifiers = [modifier]
	catalog.evolutions = [evolution]
	catalog.relics = [relic]
	catalog.masteries = [mastery]
	catalog.quests = [quest]
	catalog.cosmetics = [cosmetic]
	catalog.difficulties = [difficulty]
	_check(catalog.is_valid_definition(), "a complete typed catalog must validate")
	_check(catalog.get_region(region.id) == region and catalog.get_objective(objective.id) == objective, "catalog lookups must use stable IDs")
	catalog.objectives.append(objective)
	_check(not catalog.is_valid_definition(), "duplicate catalog IDs must be rejected")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
