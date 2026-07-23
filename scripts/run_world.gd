class_name RunWorld
extends Node2D

signal health_changed(current: float, maximum: float)
signal cooldowns_changed(values: Array[float], maximums: Array[float])
signal experience_changed(level_value: int, current: int, required: int)
signal enemy_count_changed(value: int)
signal wave_started(wave: int, total: int)
signal wave_cleared(wave: int)
signal run_progress_changed(context: Dictionary)
signal mastery_changed(current: float, maximum: float, segments: int)
signal objective_changed(title: String, current: float, target: float, completed: bool)
signal objective_completed(objective_id: StringName)
signal upgrade_choice_queued
signal player_died
signal checkpoint_ready(checkpoint: Dictionary)
signal audio_cue_requested(cue: StringName)

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const EFFECT_SCRIPT := preload("res://scripts/combat_effect.gd")
const ROUTE_GENERATOR_SCRIPT := preload("res://scripts/run_route_generator.gd")
const OBJECTIVE_CONTROLLER_SCRIPT := preload("res://scripts/objective_controller.gd")
const WORLD_SIZE := Vector2(2400.0, 1600.0)
const MAX_PROJECTILES := 48
const MAX_EFFECTS := 48
const REGION_BACKDROP_PATHS := {
	&"region.hollow_grove": "res://assets/generated/regions/hollow_grove.png",
	&"region.ossuary_monastery": "res://assets/generated/regions/ossuary_monastery.png",
	&"region.bloodwater_bog": "res://assets/generated/regions/bloodwater_bog.png",
	&"region.frozen_sanatorium": "res://assets/generated/regions/frozen_sanatorium.png",
	&"region.rift_cathedral": "res://assets/generated/regions/rift_cathedral.png",
}

var player: PlayerActor
var registry: CombatRegistry
var director: EncounterDirector
var content: ContentRegistry
var session: RunSession
var objective_controller
var run_seed := 0
var current_wave := 0
var _projectile_count := 0
var _effect_count := 0
var _shutdown := false
var _effect_limit := MAX_EFFECTS
var _reduced_motion := false
var _feedback: FeedbackProfile

@onready var _actors: Node2D = %Actors
@onready var _projectiles: Node2D = %Projectiles
@onready var _effects: Node2D = %Effects
@onready var _backdrop: Sprite2D = %Backdrop


func _ready() -> void:
	queue_redraw()


func configure_new(
	class_definition: CharacterClassDefinition,
	new_content: ContentRegistry,
	seed: int,
	difficulty_id: StringName = RunSession.DEFAULT_DIFFICULTY_ID,
	region_id: StringName = RunSession.DEFAULT_REGION_ID
) -> void:
	_setup_runtime(new_content, seed)
	session = RunSession.new()
	session.configure_new(class_definition.id, difficulty_id, region_id, seed)
	_ensure_route()
	_apply_region_backdrop()
	player.configure(class_definition, registry)
	_apply_run_modifiers()
	queue_redraw()


func restore_checkpoint(checkpoint: Dictionary, new_content: ContentRegistry) -> void:
	_setup_runtime(new_content, int(checkpoint["run_seed"]))
	session = RunSession.new()
	if not session.restore_runtime(checkpoint):
		session.configure_new(
			StringName(checkpoint["class_id"]),
			StringName(checkpoint.get("difficulty_id", RunSession.DEFAULT_DIFFICULTY_ID)),
			StringName(checkpoint.get("region_id", RunSession.DEFAULT_REGION_ID)),
			int(checkpoint["run_seed"])
		)
	_ensure_route()
	_apply_region_backdrop()
	var class_definition := content.get_class_definition(StringName(checkpoint["class_id"]))
	player.configure(class_definition, registry)
	player.restore_runtime(checkpoint)
	current_wave = int(checkpoint["wave"])
	_apply_run_modifiers()
	queue_redraw()


func _setup_runtime(new_content: ContentRegistry, seed: int) -> void:
	content = new_content
	run_seed = seed
	registry = CombatRegistry.new()
	registry.name = "CombatRegistry"
	add_child(registry)
	director = EncounterDirector.new()
	director.name = "EncounterDirector"
	add_child(director)
	objective_controller = OBJECTIVE_CONTROLLER_SCRIPT.new()
	objective_controller.name = "ObjectiveController"
	add_child(objective_controller)
	objective_controller.progress_changed.connect(objective_changed.emit)
	objective_controller.objective_completed.connect(objective_completed.emit)
	player = PLAYER_SCENE.instantiate() as PlayerActor
	player.position = WORLD_SIZE * 0.5
	_actors.add_child(player)
	director.configure(player, registry, content, run_seed, WORLD_SIZE)
	director.spawn_requested.connect(_on_spawn_requested)
	director.wave_started.connect(_on_wave_started)
	director.wave_cleared.connect(_on_wave_cleared)
	director.remaining_changed.connect(enemy_count_changed.emit)
	player.projectile_requested.connect(_on_projectile_requested)
	player.effect_requested.connect(_on_effect_requested)
	player.health_changed.connect(health_changed.emit)
	player.cooldowns_changed.connect(cooldowns_changed.emit)
	player.experience_changed.connect(experience_changed.emit)
	player.mastery_changed.connect(mastery_changed.emit)
	player.upgrade_choice_queued.connect(upgrade_choice_queued.emit)
	player.audio_cue_requested.connect(audio_cue_requested.emit)
	player.died.connect(player_died.emit)


func start_wave(wave: int) -> void:
	if _shutdown:
		return
	current_wave = wave
	_clear_transient_nodes()
	player.reset_transient_state()
	_configure_encounter_context()
	checkpoint_ready.emit(make_checkpoint())
	director.start_wave(wave)


func start_current_encounter() -> void:
	if session == null:
		return
	var encounter_kind := StringName(session.route_state.get("selected_encounter_kind", "combat"))
	if encounter_kind == &"recovery" or encounter_kind == &"shrine":
		_resolve_noncombat_encounter(encounter_kind)
		return
	start_wave((session.chapter - 1) * 5 + session.depth)


func stop_wave() -> void:
	if director != null:
		director.stop_wave()


func suspend_combat() -> void:
	if registry != null:
		registry.cancel_all_attacks()


func set_mobile_move(value: Vector2) -> void:
	if is_instance_valid(player):
		player.mobile_move = value


func configure_effects(settings: Dictionary) -> void:
	var high_limit := _feedback.high_quality_effect_limit if _feedback != null else MAX_EFFECTS
	var low_limit := _feedback.low_quality_effect_limit if _feedback != null else 24
	_effect_limit = low_limit if str(settings.get("effects_quality", "high")) == "low" else high_limit
	_reduced_motion = bool(settings.get("reduced_motion", false))


func configure_feedback(feedback: FeedbackProfile, settings: Dictionary) -> void:
	_feedback = feedback
	configure_effects(settings)


func try_use_ability(slot: int, aim_override: Vector2 = Vector2.ZERO) -> bool:
	return is_instance_valid(player) and player.try_use_ability(slot, aim_override)


func apply_upgrade(definition: UpgradeDefinition) -> void:
	if is_instance_valid(player):
		player.apply_upgrade(definition)


func select_relic(relic_id: StringName, replace_index: int = -1) -> bool:
	if session == null or content.get_relic_definition(relic_id) == null:
		return false
	if not session.add_relic(relic_id, replace_index):
		return false
	_apply_run_modifiers()
	checkpoint_ready.emit(make_checkpoint())
	return true


func select_evolution(evolution_id: StringName) -> bool:
	var definition := content.get_evolution_definition(evolution_id)
	if session == null or definition == null or definition.class_id != session.class_id:
		return false
	for owned_id in session.evolution_ids:
		var owned := content.get_evolution_definition(owned_id)
		if owned != null and owned.exclusive_group == definition.exclusive_group:
			return false
	if not session.add_evolution(evolution_id):
		return false
	_apply_run_modifiers()
	checkpoint_ready.emit(make_checkpoint())
	return true


func get_route_choices() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if session == null:
		return result
	_ensure_route()
	var raw_nodes: Variant = session.route_state.get("nodes", [])
	if not raw_nodes is Array:
		return result
	for raw_node in raw_nodes:
		if not raw_node is Dictionary or int(raw_node.get("depth", 0)) != session.depth:
			continue
		var objective := content.get_objective_definition(StringName(raw_node.get("objective_id", "")))
		var kind := StringName(raw_node.get("encounter_kind", "combat"))
		result.append({
			"id": String(raw_node.get("id", "")),
			"title": _encounter_kind_title(kind),
			"description": objective.description if objective != null else ("지역 지배자와 결전을 벌입니다." if kind == &"boss" else "전투를 돌파합니다."),
			"objective_id": String(raw_node.get("objective_id", "")),
			"encounter_kind": String(kind),
			"arena_id": String(raw_node.get("arena_id", "")),
		})
	return result


func select_route_node(node_id: StringName) -> bool:
	if session == null:
		return false
	for choice in get_route_choices():
		if StringName(choice["id"]) == node_id:
			session.select_route_node(choice)
			checkpoint_ready.emit(make_checkpoint())
			return true
	return false


func get_relic_choices() -> Array[RelicDefinition]:
	return content.get_relic_choices(
		run_seed + (session.chapter if session != null else 1) * 3571,
		session.relic_ids if session != null else []
	)


func bank_chapter() -> int:
	if session == null:
		return 0
	var banked := session.bank_completed_chapter()
	checkpoint_ready.emit(make_checkpoint())
	return banked


func continue_to_region(region_id: StringName) -> bool:
	if session == null or not content.get_next_region_ids(session.region_id).has(region_id):
		return false
	session.continue_to_region(region_id)
	current_wave = (session.chapter - 1) * 5 + 1
	_apply_region_backdrop()
	queue_redraw()
	checkpoint_ready.emit(make_checkpoint())
	run_progress_changed.emit(get_run_context())
	return true


func get_run_context() -> Dictionary:
	if session == null:
		return {}
	var region := content.get_region_definition(session.region_id)
	var difficulty := content.get_difficulty_definition(session.difficulty_id)
	return {
		"region_id": String(session.region_id),
		"region_name": region.display_name if region != null else String(session.region_id),
		"difficulty_id": String(session.difficulty_id),
		"difficulty_name": difficulty.display_name if difficulty != null else String(session.difficulty_id),
		"chapter": session.chapter,
		"depth": session.depth,
		"is_boss": session.depth == 5,
		"banked_sigils": session.banked_sigils,
		"unbanked_sigils": session.unbanked_sigils,
		"relic_ids": session.relic_ids.duplicate(),
		"evolution_ids": session.evolution_ids.duplicate(),
	}


func make_checkpoint() -> Dictionary:
	var state := player.make_runtime_state()
	if session != null:
		state.merge(session.make_runtime_state(), true)
	state["schema_version"] = RunSaveService.SCHEMA_VERSION
	state["content_version"] = RunSaveService.CONTENT_VERSION
	state["run_seed"] = run_seed
	state["wave"] = current_wave
	return state


func _configure_encounter_context() -> void:
	if session == null:
		return
	var difficulty := content.get_difficulty_definition(session.difficulty_id)
	var encounter_kind := StringName(session.route_state.get("selected_encounter_kind", "combat"))
	director.configure_run_context(session.region_id, difficulty, session.chapter, session.depth, encounter_kind)
	var objective := content.get_objective_definition(StringName(session.route_state.get("selected_objective_id", "")))
	objective_controller.configure(objective, player, registry, WORLD_SIZE * 0.5)
	run_progress_changed.emit(get_run_context())


func _resolve_noncombat_encounter(kind: StringName) -> void:
	current_wave = (session.chapter - 1) * 5 + session.depth
	if kind == &"recovery":
		player.restore_health_fraction(0.35)
	elif kind == &"shrine":
		session.grant_reroll()
	checkpoint_ready.emit(make_checkpoint())
	call_deferred("_complete_noncombat_encounter")


func _complete_noncombat_encounter() -> void:
	if _shutdown or session == null:
		return
	var cleared_wave := current_wave
	session.complete_encounter(3)
	run_progress_changed.emit(get_run_context())
	checkpoint_ready.emit(make_checkpoint())
	wave_cleared.emit(cleared_wave)


func _ensure_route() -> void:
	if session == null or not session.route_state.is_empty():
		return
	var plan: RunRoutePlan = ROUTE_GENERATOR_SCRIPT.new().generate(
		session.route_seed,
		content.get_route_objective_ids(),
		content.get_arena_ids_for_region(session.region_id)
	)
	var serialized_nodes: Array[Dictionary] = []
	for node in plan.nodes:
		serialized_nodes.append({
			"id": String(node.id),
			"depth": node.depth,
			"encounter_kind": String(node.encounter_kind),
			"objective_id": String(node.objective_id),
			"arena_id": String(node.arena_id),
			"reward_tags": _stringify_ids(node.reward_tags),
			"next_node_ids": _stringify_ids(node.next_node_ids),
		})
	session.set_route({
		"seed": plan.seed,
		"nodes": serialized_nodes,
		"selected_node_id": "",
		"selected_objective_id": "",
		"selected_encounter_kind": "",
		"selected_arena_id": "",
	})


func _encounter_kind_title(kind: StringName) -> String:
	match kind:
		&"elite":
			return "엘리트 사냥"
		&"recovery":
			return "회복의 샘"
		&"shrine":
			return "균열 제단"
		&"boss":
			return "지역 지배자"
		_:
			return "전투"


func _stringify_ids(ids: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for id in ids:
		result.append(String(id))
	return result


func _apply_run_modifiers() -> void:
	if not is_instance_valid(player) or session == null:
		return
	var sources: Array[ModifierDefinition] = []
	for relic_id in session.relic_ids:
		var relic := content.get_relic_definition(relic_id)
		if relic != null:
			sources.append_array(relic.modifiers)
	for evolution_id in session.evolution_ids:
		var evolution := content.get_evolution_definition(evolution_id)
		if evolution != null:
			sources.append_array(evolution.modifiers)
	player.set_run_modifier_sources(sources)


func _apply_region_backdrop() -> void:
	if not is_instance_valid(_backdrop) or session == null:
		return
	var path := str(REGION_BACKDROP_PATHS.get(session.region_id, ""))
	_backdrop.texture = load(path) as Texture2D if not path.is_empty() else null


func shutdown() -> void:
	if _shutdown:
		return
	_shutdown = true
	if director != null:
		director.stop_wave()
	if is_instance_valid(player):
		player.shutdown()
	process_mode = Node.PROCESS_MODE_DISABLED


func _clear_transient_nodes() -> void:
	for projectile in _projectiles.get_children():
		projectile.process_mode = Node.PROCESS_MODE_DISABLED
		projectile.queue_free()
	for effect in _effects.get_children():
		effect.process_mode = Node.PROCESS_MODE_DISABLED
		effect.queue_free()
	for actor in _actors.get_children():
		if actor is EnemyActor:
			actor.process_mode = Node.PROCESS_MODE_DISABLED
			actor.queue_free()
	_projectile_count = 0
	_effect_count = 0
	if registry != null:
		registry.clear()


func _on_spawn_requested(definition: EnemyDefinition, spawn_position: Vector2) -> void:
	if _shutdown:
		return
	var enemy := ENEMY_SCENE.instantiate() as EnemyActor
	enemy.position = spawn_position
	_actors.add_child(enemy)
	enemy.setup(
		definition,
		current_wave,
		player,
		director,
		registry,
		1.0,
		director.get_enemy_health_multiplier(),
		director.get_enemy_damage_multiplier(),
		director.get_telegraph_duration_multiplier()
	)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.projectile_requested.connect(_on_projectile_requested)


func _on_enemy_defeated(enemy: EnemyActor, experience_value: int, _enemy_position: Vector2) -> void:
	director.report_enemy_defeated(enemy)
	if objective_controller != null:
		objective_controller.report_enemy_defeated(enemy.definition)
	player.gain_experience(experience_value)


func _on_projectile_requested(origin: Vector2, direction: Vector2, spec: Dictionary) -> void:
	if _shutdown or _projectile_count >= MAX_PROJECTILES:
		return
	var projectile := PROJECTILE_SCENE.instantiate() as CombatProjectile
	_projectiles.add_child(projectile)
	projectile.global_position = origin
	projectile.setup(direction, spec, registry, player)
	projectile.finished.connect(_on_projectile_finished)
	_projectile_count += 1


func _on_projectile_finished(_projectile: CombatProjectile) -> void:
	_projectile_count = maxi(0, _projectile_count - 1)


func _on_effect_requested(effect_position: Vector2, effect_type: String, color: Color, radius: float, direction: Vector2) -> void:
	if _shutdown or _effect_count >= _effect_limit:
		return
	var effect := Node2D.new()
	effect.set_script(EFFECT_SCRIPT)
	_effects.add_child(effect)
	effect.global_position = effect_position
	effect.call("setup", effect_type, color, radius, direction)
	if _reduced_motion:
		effect.set("duration", _feedback.reduced_motion_effect_duration if _feedback != null else 0.12)
	effect.connect("finished", _on_effect_finished)
	_effect_count += 1


func _on_effect_finished() -> void:
	_effect_count = maxi(0, _effect_count - 1)


func _on_wave_started(wave: int, total: int) -> void:
	wave_started.emit(wave, total)


func _on_wave_cleared(wave: int) -> void:
	if objective_controller != null:
		objective_controller.complete_from_encounter()
	if session != null:
		var reward := 6 + session.chapter * 2 + session.depth * 2
		session.complete_encounter(reward)
		run_progress_changed.emit(get_run_context())
		checkpoint_ready.emit(make_checkpoint())
	wave_cleared.emit(wave)


func _draw() -> void:
	var region_color := Color("#335348")
	if content != null and session != null:
		var region := content.get_region_definition(session.region_id)
		if region != null:
			region_color = region.theme_color
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(region_color.darkened(0.52), 0.18))
	draw_circle(WORLD_SIZE * 0.5, 330.0, Color(region_color.darkened(0.24), 0.12))
	var path := PackedVector2Array([Vector2(0, 890), Vector2(620, 760), Vector2(1200, 820), Vector2(1820, 690), Vector2(2400, 760)])
	draw_polyline(path, Color("#5a503b"), 120.0, true)
	draw_polyline(path, Color("#7a694a"), 76.0, true)
	for x in range(0, int(WORLD_SIZE.x), 64):
		draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), Color(0.12, 0.23, 0.2, 0.3), 1.0)
	for y in range(0, int(WORLD_SIZE.y), 64):
		draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), Color(0.12, 0.23, 0.2, 0.3), 1.0)
	var decoration_rng := RandomNumberGenerator.new()
	decoration_rng.seed = 1107
	for index in range(86):
		var point := Vector2(decoration_rng.randf_range(35.0, WORLD_SIZE.x - 35.0), decoration_rng.randf_range(35.0, WORLD_SIZE.y - 35.0))
		if point.distance_to(WORLD_SIZE * 0.5) < 380.0:
			continue
		var radius := decoration_rng.randf_range(8.0, 17.0)
		draw_circle(point + Vector2(3, 5), radius, Color(0.03, 0.08, 0.07, 0.4))
		draw_circle(point, radius, Color("#315641"))
		draw_circle(point - Vector2(radius * 0.28, radius * 0.25), radius * 0.55, Color("#477254"))
	var center := WORLD_SIZE * 0.5
	draw_circle(center, 84.0, Color("#142523"), false, 5.0)
	draw_circle(center, 64.0, Color(0.24, 0.77, 0.72, 0.15))
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		draw_circle(center + Vector2.from_angle(angle) * 73.0, 7.0, Color("#69d7c6"))
