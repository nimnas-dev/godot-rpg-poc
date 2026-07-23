class_name ObjectiveController
extends Node

signal progress_changed(title: String, current: float, target: float, completed: bool)
signal objective_completed(objective_id: StringName)

const CAPTURE_RADIUS := 190.0

var definition: ObjectiveDefinition
var player: PlayerActor
var registry: CombatRegistry
var world_center := Vector2.ZERO
var current := 0.0
var completed := false
var active := false


func configure(
	new_definition: ObjectiveDefinition,
	new_player: PlayerActor,
	new_registry: CombatRegistry,
	new_world_center: Vector2
) -> void:
	definition = new_definition
	player = new_player
	registry = new_registry
	world_center = new_world_center
	current = 0.0
	completed = false
	active = definition != null
	_emit_progress()


func _process(delta: float) -> void:
	if not active or completed or definition == null or not is_instance_valid(player):
		return
	match definition.kind:
		"capture":
			if player.global_position.distance_to(world_center) <= CAPTURE_RADIUS:
				_add_progress(delta)
		"defend":
			var enemies_near_center := registry.query_circle(world_center, CAPTURE_RADIUS).size() if registry != null else 0
			if enemies_near_center == 0:
				_add_progress(delta)
		"survive":
			_add_progress(delta)


func report_enemy_defeated(defeated_definition: EnemyDefinition) -> void:
	if not active or completed or definition == null:
		return
	match definition.kind:
		"hunt":
			if defeated_definition != null and defeated_definition.role in ["artillery", "summoner", "support", "jailer"]:
				_add_progress(1.0)
		"destroy":
			if defeated_definition != null and defeated_definition.role in ["anchor", "summoner"]:
				_add_progress(1.0)
		"combat":
			_add_progress(1.0)


func complete_from_encounter() -> void:
	if not active or completed:
		return
	completed = true
	current = get_target()
	_emit_progress()
	objective_completed.emit(definition.id)


func get_target() -> float:
	if definition == null:
		return 1.0
	if definition.kind in ["capture", "defend", "survive"]:
		return maxf(1.0, definition.target_duration)
	return maxf(1.0, float(definition.target_count))


func _add_progress(amount: float) -> void:
	current = minf(get_target(), current + maxf(0.0, amount))
	if current >= get_target():
		completed = true
	_emit_progress()
	if completed:
		objective_completed.emit(definition.id)


func _emit_progress() -> void:
	var title := definition.display_name if definition != null else "전투"
	progress_changed.emit(title, current, get_target(), completed)
