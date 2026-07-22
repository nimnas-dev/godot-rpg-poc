class_name EnemyActor
extends CharacterBody2D

signal defeated(enemy: EnemyActor, experience_value: int, enemy_position: Vector2)
signal projectile_requested(origin: Vector2, direction: Vector2, spec: Dictionary)

enum State {
	SPAWN_GRACE,
	APPROACH,
	ANTICIPATION,
	ACTIVE,
	RECOVERY,
	DEAD,
}

var target: PlayerActor
var definition: EnemyDefinition
var director: EncounterDirector
var registry: CombatRegistry
var max_health := 50.0
var health := 50.0
var contact_damage := 8.0
var dead := false

var _state: int = State.SPAWN_GRACE
var _state_clock := 1.0
var _state_elapsed := 0.0
var _attack_direction := Vector2.DOWN
var _attack_origin := Vector2.ZERO
var _attack_hit := false
var _has_attack_token := false
var _hit_flash := 0.0
var _knockback := Vector2.ZERO
var _slow_multiplier := 1.0
var _slow_clock := 0.0

@onready var _screen_notifier: VisibleOnScreenNotifier2D = %ScreenNotifier


func setup(enemy_definition: EnemyDefinition, wave: int, new_target: PlayerActor, encounter: EncounterDirector, combat_registry: CombatRegistry, spawn_grace: float = 1.0) -> void:
	definition = enemy_definition
	target = new_target
	director = encounter
	registry = combat_registry
	max_health = definition.health_for_wave(wave)
	health = max_health
	contact_damage = definition.damage_for_wave(wave)
	_state = State.SPAWN_GRACE
	_state_clock = spawn_grace
	_state_elapsed = 0.0
	registry.register_enemy(self)
	queue_redraw()


func _exit_tree() -> void:
	if registry != null:
		registry.unregister_enemy(self)
	if director != null:
		director.release_attack_token(self)


func _physics_process(delta: float) -> void:
	if dead or definition == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	_hit_flash = maxf(0.0, _hit_flash - delta)
	_knockback = _knockback.move_toward(Vector2.ZERO, 760.0 * delta)
	_slow_clock = maxf(0.0, _slow_clock - delta)
	if _slow_clock <= 0.0:
		_slow_multiplier = 1.0
	_state_clock -= delta
	_state_elapsed += delta
	match _state:
		State.SPAWN_GRACE:
			velocity = _knockback
			if _state_clock <= 0.0:
				_enter_state(State.APPROACH)
		State.APPROACH:
			_process_approach()
		State.ANTICIPATION:
			_process_anticipation()
		State.ACTIVE:
			_process_active()
		State.RECOVERY:
			velocity = _knockback
			if _state_clock <= 0.0:
				_release_token()
				_enter_state(State.APPROACH)
	move_and_slide()


func _process_approach() -> void:
	var offset := target.global_position - global_position
	var distance := offset.length()
	var desired := Vector2.ZERO
	if definition.role == "ranged":
		if distance < definition.preferred_min_distance:
			desired = -offset.normalized() * definition.move_speed
		elif distance > definition.preferred_max_distance:
			desired = offset.normalized() * definition.move_speed
	else:
		desired = offset.normalized() * definition.move_speed
	velocity = desired * _slow_multiplier + _knockback
	if distance <= definition.attack.attack_range and director.request_attack_token(self, definition.attack.ranged):
		_has_attack_token = true
		_attack_direction = offset.normalized()
		_enter_state(State.ANTICIPATION)


func _process_anticipation() -> void:
	velocity = _knockback
	var lock_time := definition.attack.direction_lock_time
	if lock_time <= 0.0 or _state_elapsed < lock_time:
		var new_direction := global_position.direction_to(target.global_position)
		if new_direction.dot(_attack_direction) < 0.999:
			_attack_direction = new_direction
			queue_redraw()
	if _state_clock <= 0.0:
		_enter_state(State.ACTIVE)


func _process_active() -> void:
	if definition.attack.ranged:
		velocity = _knockback
		if not _attack_hit:
			_attack_hit = true
			projectile_requested.emit(global_position + _attack_direction * 24.0, _attack_direction, {
				"team": "enemy",
				"damage": contact_damage,
				"speed": definition.attack.projectile_speed,
				"color": definition.accent_color,
				"radius": definition.attack.hit_radius,
				"pierce": 0,
				"lifetime": 2.2,
			})
	else:
		var speed := definition.attack.charge_distance / maxf(0.01, definition.attack.active_duration)
		velocity = _attack_direction * speed * _slow_multiplier + _knockback
		if not _attack_hit:
			var projected_end := global_position + _attack_direction * speed * get_physics_process_delta_time()
			var closest := Geometry2D.get_closest_point_to_segment(target.global_position, global_position, projected_end)
			if closest.distance_to(target.global_position) <= definition.attack.charge_width:
				_attack_hit = target.apply_damage(contact_damage)
	if _state_clock <= 0.0:
		_enter_state(State.RECOVERY)


func _enter_state(next_state: int) -> void:
	_state = next_state
	_state_elapsed = 0.0
	match _state:
		State.APPROACH:
			_state_clock = 0.0
		State.ANTICIPATION:
			_state_clock = definition.attack.anticipation
			_attack_origin = global_position
			_attack_hit = false
		State.ACTIVE:
			_state_clock = definition.attack.active_duration
			_attack_origin = global_position
			_attack_hit = false
		State.RECOVERY:
			_state_clock = definition.attack.recovery
		State.DEAD:
			_state_clock = 0.0
	queue_redraw()


func take_damage(amount: float, push_direction: Vector2 = Vector2.ZERO, push_force: float = 0.0) -> void:
	if dead:
		return
	health -= amount
	_hit_flash = 0.11
	if not push_direction.is_zero_approx():
		_knockback += push_direction.normalized() * push_force
	if push_force > 0.0 and (_state == State.ANTICIPATION or _state == State.ACTIVE):
		_release_token()
		_enter_state(State.RECOVERY)
		_state_clock = minf(_state_clock, 0.25)
	queue_redraw()
	if health <= 0.0:
		_die()


func apply_slow(amount: float, duration: float) -> void:
	_slow_multiplier = minf(_slow_multiplier, clampf(1.0 - amount, 0.35, 1.0))
	_slow_clock = maxf(_slow_clock, duration)


func cancel_attack() -> void:
	if _state == State.ANTICIPATION or _state == State.ACTIVE:
		_release_token()
		_enter_state(State.RECOVERY)
		_state_clock = minf(_state_clock, 0.2)


func is_on_screen() -> bool:
	return is_instance_valid(_screen_notifier) and _screen_notifier.is_on_screen()


func _release_token() -> void:
	if not _has_attack_token:
		return
	_has_attack_token = false
	if director != null:
		director.release_attack_token(self)


func _die() -> void:
	dead = true
	_release_token()
	_enter_state(State.DEAD)
	collision_layer = 0
	collision_mask = 0
	if registry != null:
		registry.unregister_enemy(self)
	defeated.emit(self, definition.experience_value, global_position)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.4, 0.2), 0.18).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	if definition == null:
		return
	var color := Color.WHITE if _hit_flash > 0.0 else definition.body_color
	draw_circle(Vector2(3, 8), 20.0, Color(0.02, 0.03, 0.04, 0.38))
	match definition.id:
		&"enemy.goblin":
			var ears := PackedVector2Array([Vector2(-19, -10), Vector2(-34, -18), Vector2(-21, 1), Vector2(19, -10), Vector2(34, -18), Vector2(21, 1)])
			draw_colored_polygon(ears, color)
			draw_circle(Vector2.ZERO, 22.0, color)
			draw_circle(Vector2(-8, -4), 3.0, Color("#201d27"))
			draw_circle(Vector2(8, -4), 3.0, Color("#201d27"))
			draw_line(Vector2(-7, 8), Vector2(7, 8), definition.accent_color, 3.0)
		&"enemy.wraith":
			var cloak := PackedVector2Array([Vector2(-23, -10), Vector2(-18, 24), Vector2(-7, 16), Vector2(0, 27), Vector2(8, 16), Vector2(20, 24), Vector2(23, -10)])
			draw_colored_polygon(cloak, color)
			draw_circle(Vector2(0, -10), 21.0, color)
			draw_circle(Vector2(-7, -11), 3.0, definition.accent_color)
			draw_circle(Vector2(7, -11), 3.0, definition.accent_color)
		_:
			draw_circle(Vector2.ZERO, 21.0, color)
			draw_circle(Vector2(0, -7), 17.0, definition.accent_color)
			draw_circle(Vector2(-6, -6), 2.5, Color("#16211e"))
			draw_circle(Vector2(6, -6), 2.5, Color("#16211e"))
	if _state == State.SPAWN_GRACE:
		draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 32, Color(definition.accent_color, 0.65), 3.0)
	elif _state == State.ANTICIPATION:
		var length := definition.attack.charge_distance if not definition.attack.ranged else 110.0
		draw_line(Vector2.ZERO, _attack_direction * length, Color(1.0, 0.35, 0.25, 0.82), 5.0)
		draw_circle(_attack_direction * length, maxf(5.0, definition.attack.hit_radius * 0.45), Color(1.0, 0.25, 0.2, 0.45))
	if health < max_health and not dead:
		draw_rect(Rect2(-23, -34, 46, 5), Color("#261f28"), true)
		draw_rect(Rect2(-23, -34, 46 * maxf(0.0, health / max_health), 5), Color("#ef5b66"), true)
