class_name RunRouteGenerator
extends RefCounted

const DEPTH_COUNT := 5
const DEFAULT_OBJECTIVE_IDS: Array[StringName] = [&"objective.combat", &"objective.capture", &"objective.hunt", &"objective.defend", &"objective.destroy"]
const DEFAULT_ARENA_IDS: Array[StringName] = [&"arena.meadow", &"arena.ruins", &"arena.marsh"]


func generate(seed: int, objective_ids: Array[StringName] = [], arena_ids: Array[StringName] = []) -> RunRoutePlan:
	var plan := RunRoutePlan.new()
	plan.seed = seed
	var objective_pool := _unique_ids(objective_ids if not objective_ids.is_empty() else DEFAULT_OBJECTIVE_IDS)
	if objective_pool.size() < 4:
		plan.generation_error = "Route generation requires four distinct objective IDs"
		return plan
	var arena_pool := _unique_ids(arena_ids if not arena_ids.is_empty() else DEFAULT_ARENA_IDS)
	if arena_pool.is_empty():
		plan.generation_error = "Route generation requires at least one arena ID"
		return plan
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	_shuffle(objective_pool, rng)
	_shuffle(arena_pool, rng)
	var depth_objectives: Array[StringName] = []
	for index in range(4):
		depth_objectives.append(objective_pool[index])
	for depth in range(1, DEPTH_COUNT + 1):
		var count := 1 if depth == 1 or depth == DEPTH_COUNT else 2
		for branch in range(count):
			var node := RunRouteNode.new()
			node.id = StringName("route.%d.%d" % [depth, branch])
			node.depth = depth
			node.arena_id = arena_pool[(depth + branch - 1) % arena_pool.size()]
			if depth == DEPTH_COUNT:
				node.encounter_kind = &"boss"
				node.reward_tags = [&"boss", &"relic"]
			else:
				node.objective_id = depth_objectives[depth - 1]
				node.encounter_kind = _encounter_kind_for(depth, branch, rng)
				node.reward_tags = _reward_tags_for(node.encounter_kind)
			plan.nodes.append(node)
	_connect_depths(plan)
	return plan


func _encounter_kind_for(depth: int, branch: int, rng: RandomNumberGenerator) -> StringName:
	if depth == 1:
		return &"combat"
	if depth == 2:
		return &"elite" if branch == 0 else &"combat"
	if depth == 3:
		return &"recovery" if branch == 0 else &"shrine"
	return &"combat" if rng.randi_range(0, 1) == 0 or branch == 0 else &"elite"


func _reward_tags_for(kind: StringName) -> Array[StringName]:
	if kind == &"elite":
		return [&"elite", &"relic"]
	if kind == &"recovery":
		return [&"recovery", &"health"]
	if kind == &"shrine":
		return [&"shrine", &"reroll"]
	return [&"combat", &"upgrade"]


func _connect_depths(plan: RunRoutePlan) -> void:
	for depth in range(1, DEPTH_COUNT):
		var current_nodes := plan.get_nodes_at_depth(depth)
		var next_nodes := plan.get_nodes_at_depth(depth + 1)
		for node in current_nodes:
			for next_node in next_nodes:
				node.next_node_ids.append(next_node.id)


func _unique_ids(source: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for id in source:
		if not id.is_empty() and not result.has(id):
			result.append(id)
	return result


func _shuffle(values: Array[StringName], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var previous := values[index]
		values[index] = values[other]
		values[other] = previous
