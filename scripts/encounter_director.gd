class_name EncounterDirector
extends Node

signal spawn_requested(definition: EnemyDefinition, spawn_position: Vector2)
signal wave_started(wave: int, total: int)
signal wave_cleared(wave: int)
signal remaining_changed(value: int)

const MAX_ACTIVE_ENEMIES := 24
const MAX_ATTACKERS := 3
const MAX_RANGED_ATTACKERS := 1
const MIN_ATTACK_INTERVAL := 0.25
const MIN_PLAYER_DISTANCE := 440.0
const MAX_PLAYER_DISTANCE := 650.0
const MIN_ENEMY_SEPARATION := 48.0
const SPAWN_SAMPLES := 16
const SPAWN_INSET := 70.0

var current_wave := 0
var run_seed := 0
var world_size := Vector2(2400.0, 1600.0)
var player: Node2D
var registry: CombatRegistry
var content: ContentRegistry
var region_id: StringName
var difficulty: DifficultyDefinition
var encounter_kind: StringName = &"combat"
var chapter := 1
var depth := 1

var _spawn_queue: Array[StringName] = []
var _spawn_clock := 0.0
var _active_count := 0
var _running := false
var _rng := RandomNumberGenerator.new()
var _attack_tokens: Dictionary = {}
var _ranged_token_count := 0
var _attack_elapsed := MIN_ATTACK_INTERVAL
var _max_attackers := MAX_ATTACKERS
var _max_ranged_attackers := MAX_RANGED_ATTACKERS


func configure(new_player: Node2D, new_registry: CombatRegistry, new_content: ContentRegistry, seed: int, size: Vector2) -> void:
	player = new_player
	registry = new_registry
	content = new_content
	run_seed = seed
	world_size = size


func configure_run_context(
	new_region_id: StringName,
	new_difficulty: DifficultyDefinition,
	new_chapter: int,
	new_depth: int,
	new_encounter_kind: StringName = &"combat"
) -> void:
	region_id = new_region_id
	difficulty = new_difficulty
	chapter = maxi(1, new_chapter)
	depth = clampi(new_depth, 1, 5)
	encounter_kind = new_encounter_kind if not new_encounter_kind.is_empty() else &"combat"
	_max_attackers = difficulty.max_attackers if difficulty != null else MAX_ATTACKERS
	_max_ranged_attackers = difficulty.max_ranged_attackers if difficulty != null else MAX_RANGED_ATTACKERS


func start_wave(wave: int) -> void:
	stop_wave()
	current_wave = wave
	_rng.seed = run_seed + wave * 104729
	if not region_id.is_empty():
		_build_run_queue()
	else:
		var count := mini(MAX_ACTIVE_ENEMIES, 3 + wave * 2)
		for index in range(count):
			_spawn_queue.append(_roll_enemy_id(wave, _rng.randf()))
	_running = true
	_spawn_clock = 0.1
	wave_started.emit(wave, _spawn_queue.size())
	remaining_changed.emit(_spawn_queue.size())


func stop_wave() -> void:
	_running = false
	_spawn_queue.clear()
	_active_count = 0
	_release_all_attack_tokens()
	remaining_changed.emit(0)


func _process(delta: float) -> void:
	if not _running:
		return
	_attack_elapsed += delta
	if _spawn_queue.is_empty() or _active_count >= MAX_ACTIVE_ENEMIES:
		return
	_spawn_clock -= delta
	if _spawn_clock > 0.0:
		return
	var enemy_id: StringName = _spawn_queue.pop_front()
	var definition := content.get_enemy_definition(enemy_id)
	if definition != null:
		var spawn_position := choose_spawn_position(player.global_position, registry.snapshot_positions(), _rng, world_size)
		spawn_requested.emit(definition, spawn_position)
		_active_count += 1
	_spawn_clock = maxf(0.18, 0.62 - current_wave * 0.025)
	remaining_changed.emit(_spawn_queue.size() + _active_count)


func report_enemy_defeated(enemy: Node) -> void:
	release_attack_token(enemy)
	_active_count = maxi(0, _active_count - 1)
	remaining_changed.emit(_spawn_queue.size() + _active_count)
	if _running and _active_count == 0 and _spawn_queue.is_empty():
		_running = false
		wave_cleared.emit(current_wave)


func request_attack_token(enemy: Node, ranged: bool) -> bool:
	if not _running or not is_instance_valid(enemy) or _attack_tokens.has(enemy.get_instance_id()):
		return false
	if _attack_tokens.size() >= _max_attackers or _attack_elapsed < MIN_ATTACK_INTERVAL:
		return false
	if ranged and _ranged_token_count >= _max_ranged_attackers:
		return false
	if enemy.has_method("is_on_screen") and not enemy.is_on_screen():
		return false
	_attack_tokens[enemy.get_instance_id()] = ranged
	if ranged:
		_ranged_token_count += 1
	_attack_elapsed = 0.0
	return true


func release_attack_token(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	var id := enemy.get_instance_id()
	if not _attack_tokens.has(id):
		return
	if bool(_attack_tokens[id]):
		_ranged_token_count = maxi(0, _ranged_token_count - 1)
	_attack_tokens.erase(id)


func _release_all_attack_tokens() -> void:
	_attack_tokens.clear()
	_ranged_token_count = 0


func get_enemy_health_multiplier() -> float:
	var result: float = difficulty.enemy_health_multiplier if difficulty != null else 1.0
	return result * (1.3 if encounter_kind == &"elite" else 1.0)


func get_enemy_damage_multiplier() -> float:
	var result: float = difficulty.enemy_damage_multiplier if difficulty != null else 1.0
	return result * (1.15 if encounter_kind == &"elite" else 1.0)


func get_telegraph_duration_multiplier() -> float:
	return difficulty.telegraph_duration_multiplier if difficulty != null else 1.0


func _build_run_queue() -> void:
	if depth == 5:
		var boss := content.get_boss_for_region(region_id)
		if boss != null:
			_spawn_queue.append(boss.id)
			return
	var pool := content.get_enemies_for_region(region_id)
	if pool.is_empty():
		return
	var budget := 4.0 + float(chapter - 1) * 1.5 + float(depth - 1) * 2.0
	if encounter_kind == &"elite":
		budget *= 1.4
	var spent := 0.0
	while _spawn_queue.size() < MAX_ACTIVE_ENEMIES and spent < budget:
		var affordable: Array[EnemyDefinition] = []
		for candidate in pool:
			if candidate.threat_cost <= budget - spent + 0.25 or _spawn_queue.is_empty():
				affordable.append(candidate)
		if affordable.is_empty():
			break
		var chosen := affordable[_rng.randi_range(0, affordable.size() - 1)]
		_spawn_queue.append(chosen.id)
		spent += chosen.threat_cost


func _roll_enemy_id(wave: int, roll: float) -> StringName:
	if wave <= 1:
		return &"enemy.slime"
	if wave <= 3:
		return &"enemy.slime" if roll < 0.7 else &"enemy.goblin"
	if wave % 5 == 0:
		if roll < 0.35:
			return &"enemy.slime"
		return &"enemy.goblin" if roll < 0.75 else &"enemy.wraith"
	if roll < 0.5:
		return &"enemy.slime"
	return &"enemy.goblin" if roll < 0.85 else &"enemy.wraith"


static func choose_spawn_position(player_position: Vector2, enemy_positions: Array[Vector2], rng: RandomNumberGenerator, size: Vector2) -> Vector2:
	var bounds := Rect2(Vector2(SPAWN_INSET, SPAWN_INSET), size - Vector2.ONE * SPAWN_INSET * 2.0)
	for sample in range(SPAWN_SAMPLES):
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(MIN_PLAYER_DISTANCE, MAX_PLAYER_DISTANCE)
		var candidate := player_position + Vector2.from_angle(angle) * distance
		if _is_valid_spawn(candidate, player_position, enemy_positions, bounds):
			return candidate
	var fallback_candidates: Array[Vector2] = []
	for angle_index in range(64):
		var direction := Vector2.from_angle(TAU * float(angle_index) / 64.0)
		for distance in [MAX_PLAYER_DISTANCE, MIN_PLAYER_DISTANCE]:
			var candidate: Vector2 = player_position + direction * distance
			if _is_valid_spawn(candidate, player_position, enemy_positions, bounds):
				fallback_candidates.append(candidate)
	if not fallback_candidates.is_empty():
		var best := fallback_candidates[0]
		var best_clearance := -1.0
		for candidate in fallback_candidates:
			var clearance := _minimum_clearance(candidate, enemy_positions)
			if clearance > best_clearance:
				best = candidate
				best_clearance = clearance
		return best
	# A dense final sweep preserves the player-distance and world-bound contracts.
	for angle_index in range(360):
		var direction := Vector2.from_angle(TAU * float(angle_index) / 360.0)
		var candidate := player_position + direction * MIN_PLAYER_DISTANCE
		if _is_valid_spawn(candidate, player_position, enemy_positions, bounds):
			return candidate
	# With the configured world and 24-enemy cap this branch is unreachable. It
	# still preserves the non-negotiable player-distance contract.
	var center_direction := player_position.direction_to(size * 0.5)
	if center_direction.is_zero_approx():
		center_direction = Vector2.RIGHT
	return player_position + center_direction * MIN_PLAYER_DISTANCE


static func _is_valid_spawn(candidate: Vector2, player_position: Vector2, enemy_positions: Array[Vector2], bounds: Rect2) -> bool:
	if not bounds.has_point(candidate):
		return false
	var player_distance := candidate.distance_to(player_position)
	if player_distance < MIN_PLAYER_DISTANCE or player_distance > MAX_PLAYER_DISTANCE:
		return false
	return _minimum_clearance(candidate, enemy_positions) >= MIN_ENEMY_SEPARATION


static func _minimum_clearance(candidate: Vector2, enemy_positions: Array[Vector2]) -> float:
	var result := INF
	for position in enemy_positions:
		result = minf(result, candidate.distance_to(position))
	return result
