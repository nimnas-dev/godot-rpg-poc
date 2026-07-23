class_name CombatProjectile
extends Area2D

signal finished(projectile: CombatProjectile)

var direction := Vector2.RIGHT
var speed := 620.0
var damage := 20.0
var lifetime := 1.5
var projectile_color := Color("#ffd36c")
var radius := 7.0
var pierce := 0
var team := "player"
var ability_tag: StringName
var registry: CombatRegistry
var player_target: PlayerActor
var hit_ids: Array[int] = []
var _finishing := false


func setup(new_direction: Vector2, spec: Dictionary, combat_registry: CombatRegistry, target: PlayerActor) -> void:
	direction = new_direction.normalized()
	rotation = direction.angle()
	speed = float(spec.get("speed", speed))
	damage = float(spec.get("damage", damage))
	lifetime = float(spec.get("lifetime", lifetime))
	projectile_color = spec.get("color", projectile_color)
	radius = float(spec.get("radius", radius))
	pierce = int(spec.get("pierce", pierce))
	team = str(spec.get("team", team))
	ability_tag = StringName(spec.get("ability_tag", ""))
	registry = combat_registry
	player_target = target
	var collision_shape := %CollisionShape2D as CollisionShape2D
	if collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _finishing:
		return
	var start := global_position
	var finish := start + direction * speed * delta
	global_position = finish
	if team == "player":
		_hit_enemies_swept(start, finish)
	else:
		_hit_player_swept(start, finish)
	lifetime -= delta
	if lifetime <= 0.0:
		_finish()


func _hit_enemies_swept(start: Vector2, finish: Vector2) -> void:
	if registry == null:
		return
	for enemy in registry.query_segment(start, finish, radius + 20.0):
		var id := enemy.get_instance_id()
		if hit_ids.has(id):
			continue
		hit_ids.append(id)
		enemy.take_damage(damage, direction, 115.0)
		if is_instance_valid(player_target):
			player_target.report_projectile_hit(enemy.global_position, ability_tag)
		if pierce <= 0:
			_finish()
			return
		pierce -= 1


func _hit_player_swept(start: Vector2, finish: Vector2) -> void:
	if not is_instance_valid(player_target) or player_target.dead:
		return
	var closest := Geometry2D.get_closest_point_to_segment(player_target.global_position, start, finish)
	if closest.distance_to(player_target.global_position) <= radius + 18.0:
		player_target.apply_damage(damage)
		_finish()


func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	finished.emit(self)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2(-7, 0), radius * 0.72, Color(projectile_color, 0.22))
	draw_circle(Vector2.ZERO, radius, projectile_color)
	draw_circle(Vector2(-2, -2), radius * 0.45, Color.WHITE)
	draw_line(Vector2(-radius * 2.8, 0), Vector2(-radius * 0.5, 0), Color(projectile_color, 0.55), radius * 0.9)
