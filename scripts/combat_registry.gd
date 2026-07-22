class_name CombatRegistry
extends Node

signal enemy_count_changed(value: int)

var _enemies: Array[Node2D] = []


func register_enemy(enemy: Node2D) -> void:
	if enemy == null or _enemies.has(enemy):
		return
	_enemies.append(enemy)
	enemy_count_changed.emit(_enemies.size())


func unregister_enemy(enemy: Node2D) -> void:
	var index := _enemies.find(enemy)
	if index == -1:
		return
	_enemies.remove_at(index)
	enemy_count_changed.emit(_enemies.size())


func clear() -> void:
	_enemies.clear()
	enemy_count_changed.emit(0)


func cancel_all_attacks() -> void:
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.has_method("cancel_attack"):
			enemy.cancel_attack()


func count() -> int:
	return _enemies.size()


func find_nearest(origin: Vector2, max_distance: float) -> Node2D:
	var nearest: Node2D
	var best_distance_squared := max_distance * max_distance
	for enemy in _enemies:
		if not is_instance_valid(enemy) or enemy.get("dead") == true:
			continue
		var distance_squared := origin.distance_squared_to(enemy.global_position)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			nearest = enemy
	return nearest


func query_circle(center: Vector2, radius: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var radius_squared := radius * radius
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.get("dead") != true and center.distance_squared_to(enemy.global_position) <= radius_squared:
			result.append(enemy)
	return result


func query_cone(origin: Vector2, direction: Vector2, radius: float, minimum_dot: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var normalized_direction := direction.normalized()
	for enemy in query_circle(origin, radius):
		var offset := enemy.global_position - origin
		if offset.is_zero_approx() or normalized_direction.dot(offset.normalized()) >= minimum_dot:
			result.append(enemy)
	return result


func query_segment(start: Vector2, finish: Vector2, width: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for enemy in _enemies:
		if not is_instance_valid(enemy) or enemy.get("dead") == true:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start, finish)
		if closest.distance_to(enemy.global_position) <= width:
			result.append(enemy)
	return result


func snapshot_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.get("dead") != true:
			result.append(enemy.global_position)
	return result
