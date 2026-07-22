class_name PlayerActor
extends CharacterBody2D

signal projectile_requested(origin: Vector2, direction: Vector2, spec: Dictionary)
signal effect_requested(effect_position: Vector2, effect_type: String, color: Color, radius: float, direction: Vector2)
signal health_changed(current: float, maximum: float)
signal cooldowns_changed(values: Array[float], maximums: Array[float])
signal experience_changed(level_value: int, current: int, required: int)
signal upgrade_choice_queued
signal audio_cue_requested(cue: StringName)
signal died

const WORLD_RECT := Rect2(24.0, 24.0, 2352.0, 1552.0)

var definition: CharacterClassDefinition
var registry: CombatRegistry
var class_id: StringName = &"class.swordsman"
var body_color := Color("#ef665d")
var accent_color := Color("#ffd17a")
var move_speed := 245.0
var max_health := 150.0
var health := 150.0
var power := 1.0
var level := 1
var experience := 0
var experience_to_next := 75
var mobile_move := Vector2.ZERO
var facing := Vector2.DOWN
var cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]
var cooldown_max: Array[float] = [0.42, 4.5, 5.5, 10.0]
var upgrade_stacks: Dictionary = {}
var pending_upgrade_choices := 0
var invulnerability := 0.0
var guard_multiplier := 1.0
var guard_clock := 0.0
var hurt_flash := 0.0
var dead := false
var walk_time := 0.0
var active := false
var _cooldown_ui_clock := 0.0


func _ready() -> void:
	queue_redraw()


func configure(new_definition: CharacterClassDefinition, combat_registry: CombatRegistry) -> void:
	definition = new_definition
	registry = combat_registry
	class_id = definition.id
	level = 1
	experience = 0
	experience_to_next = _experience_required(level)
	upgrade_stacks.clear()
	pending_upgrade_choices = 0
	_recalculate_derived_stats()
	health = max_health
	reset_transient_state()
	dead = false
	active = true
	visible = true
	collision_layer = 1
	collision_mask = 2
	_emit_all_state()
	queue_redraw()


func restore_runtime(checkpoint: Dictionary) -> void:
	level = int(checkpoint.get("level", 1))
	experience = int(checkpoint.get("experience", 0))
	experience_to_next = _experience_required(level)
	upgrade_stacks = (checkpoint.get("upgrade_stacks", {}) as Dictionary).duplicate(true)
	pending_upgrade_choices = 0
	_recalculate_derived_stats()
	health = clampf(float(checkpoint.get("health", max_health)), 1.0, max_health)
	reset_transient_state()
	dead = false
	active = true
	visible = true
	collision_layer = 1
	collision_mask = 2
	_emit_all_state()
	queue_redraw()


func make_runtime_state() -> Dictionary:
	return {
		"class_id": String(class_id),
		"level": level,
		"experience": experience,
		"health": health,
		"upgrade_stacks": upgrade_stacks.duplicate(true),
	}


func get_class_definition() -> CharacterClassDefinition:
	return definition


func get_cooldown_state() -> Array:
	return [cooldowns.duplicate(), cooldown_max.duplicate()]


func _process(delta: float) -> void:
	if not active or dead:
		return
	var cooldown_changed := false
	for index in range(cooldowns.size()):
		if cooldowns[index] > 0.0:
			cooldowns[index] = maxf(0.0, cooldowns[index] - delta)
			cooldown_changed = true
	_cooldown_ui_clock -= delta
	if cooldown_changed and _cooldown_ui_clock <= 0.0:
		_cooldown_ui_clock = 0.1
		cooldowns_changed.emit(cooldowns.duplicate(), cooldown_max.duplicate())
	var had_hurt_flash := hurt_flash > 0.0
	var had_guard := guard_clock > 0.0
	invulnerability = maxf(0.0, invulnerability - delta)
	hurt_flash = maxf(0.0, hurt_flash - delta)
	guard_clock = maxf(0.0, guard_clock - delta)
	if had_guard and guard_clock <= 0.0:
		guard_multiplier = 1.0
	if (had_hurt_flash and hurt_flash <= 0.0) or (had_guard and guard_clock <= 0.0):
		queue_redraw()


func _physics_process(delta: float) -> void:
	if dead or not active:
		velocity = Vector2.ZERO
		return
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_vector := mobile_move if mobile_move.length() > keyboard.length() else keyboard
	if input_vector.length() > 0.08:
		input_vector = input_vector.normalized()
		facing = input_vector
		walk_time += delta * 10.0
		queue_redraw()
	velocity = input_vector * move_speed
	move_and_slide()
	position.x = clampf(position.x, WORLD_RECT.position.x, WORLD_RECT.end.x)
	position.y = clampf(position.y, WORLD_RECT.position.y, WORLD_RECT.end.y)


func try_use_ability(slot: int) -> bool:
	if dead or not active or definition == null or slot < 0 or slot >= cooldowns.size() or cooldowns[slot] > 0.0:
		return false
	var ability := definition.actions[slot]
	cooldowns[slot] = cooldown_max[slot]
	cooldowns_changed.emit(cooldowns.duplicate(), cooldown_max.duplicate())
	var aim := _get_aim_direction()
	_execute_ability(ability, aim)
	audio_cue_requested.emit(&"attack")
	return true


func _execute_ability(ability: AbilityDefinition, aim: Vector2) -> void:
	var effect := ability.effect
	if effect == null:
		return
	match effect.kind:
		"melee_cone":
			var stacks := _stack(&"upgrade.swordsman.wide_slash")
			var radius := effect.range * (1.0 + 0.1 * stacks)
			var minimum_dot := effect.radius - (0.18 if stacks > 0 else 0.0)
			_damage_cone(aim, radius, effect.damage * power, minimum_dot, effect.speed)
			_request_effect(global_position, "slash", ability.color, radius, aim)
		"area":
			var radius := effect.range
			if ability.id == &"ability.mage.frost":
				radius *= 1.0 + 0.08 * _stack(&"upgrade.mage.permafrost")
			_damage_area(global_position, radius, effect.damage * power, effect.speed)
			if ability.id == &"ability.mage.frost":
				var frost_stacks := _stack(&"upgrade.mage.permafrost")
				if frost_stacks > 0:
					for enemy in registry.query_circle(global_position, radius):
						enemy.apply_slow(effect.status_strength + (frost_stacks - 1) * 0.1, effect.status_duration)
			_request_effect(global_position, "burst", ability.color, radius, aim)
		"dash":
			var stacks := _stack(&"upgrade.swordsman.charge")
			var old_position := global_position
			global_position += aim * effect.range * (1.0 + 0.12 * stacks)
			_clamp_to_world()
			_damage_line(old_position, global_position, effect.radius, effect.damage * power * (1.0 + 0.08 * stacks))
			invulnerability = effect.duration + 0.04 * stacks
			_request_effect(global_position, "slash", ability.color, 105.0, aim)
		"guard":
			var stacks := _stack(&"upgrade.swordsman.fortress")
			guard_multiplier = maxf(0.1, effect.speed - 0.03 * stacks)
			guard_clock = effect.range + 0.3 * stacks
			health = minf(max_health, health + effect.radius + level * 2.0 + 5.0 * stacks)
			health_changed.emit(health, max_health)
			_request_effect(global_position, "burst", ability.color, 92.0, aim)
			queue_redraw()
		"projectile":
			_fire_basic_projectile(ability, aim)
		"spread":
			_fire_spread(ability, aim)
		"line_projectile":
			var stacks := _stack(&"upgrade.archer.drill_tip")
			_fire_projectile(aim, effect.damage * power, effect.speed * (1.0 + 0.05 * stacks), ability.color, effect.radius, effect.pierce + stacks, effect.range)
			_request_effect(global_position, "slash", ability.color, 90.0, aim)
		"target_area":
			_fire_target_area(ability, aim)
		"teleport":
			var old_position := global_position
			global_position += aim * effect.range
			_clamp_to_world()
			invulnerability = effect.duration
			_request_effect(old_position, "burst", body_color, effect.radius, aim)
			_request_effect(global_position, "burst", ability.color, effect.radius, aim)
			var stacks := _stack(&"upgrade.mage.blink_nova")
			if stacks > 0:
				_damage_area(global_position, 72.0 + 8.0 * stacks, 26.0 * power * stacks, 120.0)


func _fire_basic_projectile(ability: AbilityDefinition, aim: Vector2) -> void:
	var effect := ability.effect
	var twin_stacks := _stack(&"upgrade.archer.twin_string") if ability.id == &"ability.archer.shot" else 0
	if twin_stacks > 0:
		var twin_damage := effect.damage * power * 0.65 * (1.0 + 0.1 * (twin_stacks - 1))
		_fire_projectile(aim.rotated(-0.055), twin_damage, effect.speed, ability.color, effect.radius, effect.pierce, effect.range)
		_fire_projectile(aim.rotated(0.055), twin_damage, effect.speed, ability.color, effect.radius, effect.pierce, effect.range)
	else:
		_fire_projectile(aim, effect.damage * power, effect.speed, ability.color, effect.radius, effect.pierce, effect.range)


func _fire_spread(ability: AbilityDefinition, aim: Vector2) -> void:
	var effect := ability.effect
	var angles: Array[float] = []
	if effect.projectile_count == 5:
		angles = [-0.30, -0.15, 0.0, 0.15, 0.30]
	else:
		angles = [-0.22, 0.0, 0.22]
	for angle in angles:
		_fire_projectile(aim.rotated(angle), effect.damage * power, effect.speed, ability.color, effect.radius, effect.pierce, effect.range)
	if ability.id == &"ability.mage.stars":
		var stacks := _stack(&"upgrade.mage.constellation")
		for index in range(stacks):
			var angle := 0.36 + index * 0.12
			_fire_projectile(aim.rotated(-angle), effect.damage * power * 0.6, effect.speed, ability.color, effect.radius, effect.pierce, effect.range)
			_fire_projectile(aim.rotated(angle), effect.damage * power * 0.6, effect.speed, ability.color, effect.radius, effect.pierce, effect.range)
	_request_effect(global_position, "ring", ability.color, 88.0, aim)


func _fire_target_area(ability: AbilityDefinition, aim: Vector2) -> void:
	var effect := ability.effect
	var center := global_position + aim * 230.0
	var nearest := registry.find_nearest(global_position, effect.range)
	if is_instance_valid(nearest):
		center = nearest.global_position
	var stacks := _stack(&"upgrade.archer.storm_front")
	var radius := effect.radius * (1.0 + 0.08 * stacks)
	_damage_area(center, radius, effect.damage * power, effect.speed)
	_request_effect(center, "burst", ability.color, radius, aim)
	if stacks > 0:
		_delayed_area(center, radius, effect.damage * power * 0.55, effect.speed, ability.color)


func _delayed_area(center: Vector2, radius: float, damage: float, push: float, color: Color) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.28
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()
	if not active or dead or registry == null:
		return
	_damage_area(center, radius, damage, push)
	_request_effect(center, "ring", color, radius, Vector2.RIGHT)


func _fire_projectile(direction: Vector2, projectile_damage: float, projectile_speed: float, color: Color, radius: float, pierce: int, lifetime: float) -> void:
	projectile_requested.emit(global_position + direction * 28.0, direction, {
		"team": "player",
		"damage": projectile_damage,
		"speed": projectile_speed,
		"color": color,
		"radius": radius,
		"pierce": pierce,
		"lifetime": lifetime,
	})


func _damage_cone(direction: Vector2, radius: float, damage: float, minimum_dot: float, push: float) -> void:
	for enemy in registry.query_cone(global_position, direction, radius, minimum_dot):
		enemy.take_damage(damage, global_position.direction_to(enemy.global_position), push)


func _damage_area(center: Vector2, radius: float, damage: float, push: float) -> void:
	for enemy in registry.query_circle(center, radius):
		enemy.take_damage(damage, center.direction_to(enemy.global_position), push)


func _damage_line(start: Vector2, finish: Vector2, width: float, damage: float) -> void:
	for enemy in registry.query_segment(start, finish, width):
		enemy.take_damage(damage, start.direction_to(finish), 210.0)


func _get_aim_direction() -> Vector2:
	var nearest := registry.find_nearest(global_position, 560.0)
	if is_instance_valid(nearest):
		return global_position.direction_to(nearest.global_position)
	return facing.normalized() if not facing.is_zero_approx() else Vector2.RIGHT


func _request_effect(effect_position: Vector2, effect_type: String, color: Color, radius: float, direction: Vector2) -> void:
	effect_requested.emit(effect_position, effect_type, color, radius, direction)


func apply_damage(amount: float) -> bool:
	if dead or invulnerability > 0.0 or not active:
		return false
	health = maxf(0.0, health - amount * guard_multiplier)
	invulnerability = 0.32
	hurt_flash = 0.14
	health_changed.emit(health, max_health)
	audio_cue_requested.emit(&"hit")
	queue_redraw()
	if health <= 0.0:
		dead = true
		active = false
		velocity = Vector2.ZERO
		collision_layer = 0
		collision_mask = 0
		died.emit()
	return true


func gain_experience(amount: int) -> void:
	if dead:
		return
	experience += amount
	while experience >= experience_to_next:
		experience -= experience_to_next
		level += 1
		experience_to_next = _experience_required(level)
		pending_upgrade_choices += 1
		_recalculate_derived_stats(true)
		_request_effect(global_position, "burst", Color("#ffe97d"), 118.0, Vector2.RIGHT)
		upgrade_choice_queued.emit()
		audio_cue_requested.emit(&"level")
	experience_changed.emit(level, experience, experience_to_next)


func apply_upgrade(upgrade: UpgradeDefinition) -> void:
	if upgrade == null:
		return
	var current := _stack(upgrade.id)
	if upgrade.max_stacks > 0 and current >= upgrade.max_stacks:
		return
	upgrade_stacks[upgrade.id] = current + 1
	pending_upgrade_choices = maxi(0, pending_upgrade_choices - 1)
	_recalculate_derived_stats()
	if upgrade.effect_key == "veteran_health":
		health = minf(max_health, health + 8.0)
	_emit_all_state()


func reset_transient_state() -> void:
	mobile_move = Vector2.ZERO
	velocity = Vector2.ZERO
	cooldowns = [0.0, 0.0, 0.0, 0.0]
	invulnerability = 0.0
	guard_multiplier = 1.0
	guard_clock = 0.0
	hurt_flash = 0.0
	_cooldown_ui_clock = 0.0
	queue_redraw()


func shutdown() -> void:
	active = false
	mobile_move = Vector2.ZERO
	velocity = Vector2.ZERO


func _recalculate_derived_stats(heal_for_level: bool = false) -> void:
	if definition == null:
		return
	var old_max := max_health
	body_color = definition.body_color
	accent_color = definition.accent_color
	move_speed = definition.move_speed
	max_health = definition.max_health + definition.health_per_level * (level - 1) + 8.0 * _stack(&"upgrade.veteran.health")
	power = definition.power * pow(1.08, level - 1) * pow(1.06, _stack(&"upgrade.veteran.damage"))
	var cooldown_factor := maxf(0.5, pow(0.97, _stack(&"upgrade.veteran.cooldown")))
	cooldown_max.clear()
	for ability in definition.actions:
		var value := ability.cooldown * cooldown_factor
		if ability.id == &"ability.mage.blink":
			value *= pow(0.94, _stack(&"upgrade.mage.blink_nova"))
		value = maxf(ability.cooldown * 0.5, value)
		cooldown_max.append(value)
	if heal_for_level:
		health = minf(max_health, health + (max_health - old_max) + max_health * 0.22)
	else:
		health = minf(health, max_health)


func _stack(id: StringName) -> int:
	return int(upgrade_stacks.get(id, 0))


func _experience_required(for_level: int) -> int:
	return int(75.0 * pow(1.28, for_level - 1))


func _emit_all_state() -> void:
	health_changed.emit(health, max_health)
	cooldowns_changed.emit(cooldowns.duplicate(), cooldown_max.duplicate())
	experience_changed.emit(level, experience, experience_to_next)


func _clamp_to_world() -> void:
	position.x = clampf(position.x, WORLD_RECT.position.x, WORLD_RECT.end.x)
	position.y = clampf(position.y, WORLD_RECT.position.y, WORLD_RECT.end.y)


func _draw() -> void:
	var bob := sin(walk_time) * 2.0 if velocity.length() > 5.0 else 0.0
	var shown_color := Color.WHITE if hurt_flash > 0.0 else body_color
	_draw_ellipse_shadow(Vector2(3, 15), Vector2(24, 11), Color(0.01, 0.02, 0.03, 0.38))
	if guard_clock > 0.0:
		draw_arc(Vector2.ZERO, 32.0, 0.0, TAU, 36, Color(0.4, 0.82, 1.0, 0.7), 4.0)
	match class_id:
		&"class.archer":
			draw_circle(Vector2(0, -7 + bob), 14.0, Color("#f3cda5"))
			draw_colored_polygon(PackedVector2Array([Vector2(-17, -11 + bob), Vector2(0, -26 + bob), Vector2(17, -11 + bob), Vector2(13, 18), Vector2(-13, 18)]), shown_color)
			draw_arc(Vector2(17, -1), 17.0, -1.4, 1.4, 16, accent_color, 3.0)
			draw_line(Vector2(20, -18), Vector2(20, 16), Color("#e7dbc2"), 2.0)
		&"class.mage":
			draw_colored_polygon(PackedVector2Array([Vector2(-24, 20), Vector2(-12, -9 + bob), Vector2(12, -9 + bob), Vector2(24, 20)]), shown_color)
			draw_circle(Vector2(0, -9 + bob), 13.0, Color("#f3cda5"))
			draw_colored_polygon(PackedVector2Array([Vector2(-21, -14 + bob), Vector2(0, -37 + bob), Vector2(21, -14 + bob)]), shown_color)
			draw_circle(Vector2(19, 1), 6.0, accent_color)
			draw_line(Vector2(19, 7), Vector2(19, 24), Color("#9b744d"), 4.0)
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(-18, -13 + bob), Vector2(18, -13 + bob), Vector2(15, 20), Vector2(-15, 20)]), shown_color)
			draw_circle(Vector2(0, -10 + bob), 13.0, Color("#f3cda5"))
			draw_arc(Vector2(0, -12 + bob), 15.0, PI, TAU, 18, Color("#c9d5df"), 6.0)
			draw_line(Vector2(17, -7), Vector2(27, -24), accent_color, 5.0)
			draw_line(Vector2(26, -25), Vector2(30, -31), Color.WHITE, 3.0)
	draw_circle(facing.normalized() * 26.0, 3.5, accent_color)


func _draw_ellipse_shadow(center: Vector2, size: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)
