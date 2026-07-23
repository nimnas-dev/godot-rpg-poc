class_name RunRoutePlan
extends RefCounted

const DEPTH_COUNT := 5

var seed := 0
var nodes: Array[RunRouteNode] = []
var generation_error := ""


func get_nodes_at_depth(requested_depth: int) -> Array[RunRouteNode]:
	var result: Array[RunRouteNode] = []
	for node in nodes:
		if node.depth == requested_depth:
			result.append(node)
	return result


func get_node(id: StringName) -> RunRouteNode:
	for node in nodes:
		if node.id == id:
			return node
	return null


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not generation_error.is_empty():
		errors.append(generation_error)
		return errors
	if nodes.size() != 8:
		errors.append("A chapter route must contain eight nodes")
		return errors
	var expected_counts := [1, 2, 2, 2, 1]
	for depth in range(1, DEPTH_COUNT + 1):
		var nodes_at_depth := get_nodes_at_depth(depth)
		if nodes_at_depth.size() != expected_counts[depth - 1]:
			errors.append("Route depth %d has an invalid node count" % depth)
		for node in nodes_at_depth:
			if node.id.is_empty() or node.encounter_kind.is_empty():
				errors.append("Route contains an incomplete node at depth %d" % depth)
			for next_id in node.next_node_ids:
				var next_node := get_node(next_id)
				if next_node == null or next_node.depth != depth + 1:
					errors.append("Route node %s has an invalid edge" % node.id)
	var first := get_nodes_at_depth(1)
	var last := get_nodes_at_depth(DEPTH_COUNT)
	if not first.is_empty() and first[0].encounter_kind != &"combat":
		errors.append("Depth one must be fixed combat")
	if not last.is_empty() and last[0].encounter_kind != &"boss":
		errors.append("Depth five must be a boss")
	if not _has_reachable_kind(&"elite"):
		errors.append("Route must contain a reachable elite")
	if not _has_reachable_recovery():
		errors.append("Route must contain a reachable recovery or shrine")
	if not first.is_empty() and _has_repeated_objective_on_path(first[0], []):
		errors.append("Route repeats an objective along a path")
	return errors


func is_valid() -> bool:
	return validation_errors().is_empty()


func signature() -> PackedStringArray:
	var result := PackedStringArray()
	for node in nodes:
		result.append("%s|%d|%s|%s|%s|%s" % [node.id, node.depth, node.encounter_kind, node.objective_id, node.arena_id, ",".join(node.next_node_ids)])
	return result


func _has_reachable_kind(kind: StringName) -> bool:
	for node in nodes:
		if node.encounter_kind == kind:
			return true
	return false


func _has_reachable_recovery() -> bool:
	for node in nodes:
		if node.is_recovery_opportunity():
			return true
	return false


func _has_repeated_objective_on_path(node: RunRouteNode, seen: Array[StringName]) -> bool:
	var next_seen := seen.duplicate()
	if not node.objective_id.is_empty():
		if next_seen.has(node.objective_id):
			return true
		next_seen.append(node.objective_id)
	for next_id in node.next_node_ids:
		var next_node := get_node(next_id)
		if next_node != null and _has_repeated_objective_on_path(next_node, next_seen):
			return true
	return false
