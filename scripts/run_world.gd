class_name RunWorld
extends Node2D

signal health_changed(current: float, maximum: float)
signal cooldowns_changed(values: Array[float], maximums: Array[float])
signal experience_changed(level_value: int, current: int, required: int)
signal enemy_count_changed(value: int)
signal wave_started(wave: int, total: int)
signal wave_cleared(wave: int)
signal upgrade_choice_queued
signal player_died
signal checkpoint_ready(checkpoint: Dictionary)
signal audio_cue_requested(cue: StringName)

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const EFFECT_SCRIPT := preload("res://scripts/combat_effect.gd")
const WORLD_SIZE := Vector2(2400.0, 1600.0)
const MAX_PROJECTILES := 48
const MAX_EFFECTS := 48

var player: PlayerActor
var registry: CombatRegistry
var director: EncounterDirector
var content: ContentRegistry
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


func _ready() -> void:
	queue_redraw()


func configure_new(class_definition: CharacterClassDefinition, new_content: ContentRegistry, seed: int) -> void:
	_setup_runtime(new_content, seed)
	player.configure(class_definition, registry)


func restore_checkpoint(checkpoint: Dictionary, new_content: ContentRegistry) -> void:
	_setup_runtime(new_content, int(checkpoint["run_seed"]))
	var class_definition := content.get_class_definition(StringName(checkpoint["class_id"]))
	player.configure(class_definition, registry)
	player.restore_runtime(checkpoint)
	current_wave = int(checkpoint["wave"])


func _setup_runtime(new_content: ContentRegistry, seed: int) -> void:
	content = new_content
	run_seed = seed
	registry = CombatRegistry.new()
	registry.name = "CombatRegistry"
	add_child(registry)
	director = EncounterDirector.new()
	director.name = "EncounterDirector"
	add_child(director)
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
	player.upgrade_choice_queued.connect(upgrade_choice_queued.emit)
	player.audio_cue_requested.connect(audio_cue_requested.emit)
	player.died.connect(player_died.emit)


func start_wave(wave: int) -> void:
	if _shutdown:
		return
	current_wave = wave
	_clear_transient_nodes()
	player.reset_transient_state()
	checkpoint_ready.emit(make_checkpoint())
	director.start_wave(wave)


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


func try_use_ability(slot: int) -> bool:
	return is_instance_valid(player) and player.try_use_ability(slot)


func apply_upgrade(definition: UpgradeDefinition) -> void:
	if is_instance_valid(player):
		player.apply_upgrade(definition)


func make_checkpoint() -> Dictionary:
	var state := player.make_runtime_state()
	state["schema_version"] = RunSaveService.SCHEMA_VERSION
	state["content_version"] = RunSaveService.CONTENT_VERSION
	state["run_seed"] = run_seed
	state["wave"] = current_wave
	return state


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
	enemy.setup(definition, current_wave, player, director, registry, 1.0)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.projectile_requested.connect(_on_projectile_requested)


func _on_enemy_defeated(enemy: EnemyActor, experience_value: int, _enemy_position: Vector2) -> void:
	director.report_enemy_defeated(enemy)
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
	wave_cleared.emit(wave)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#182e2b"))
	draw_circle(WORLD_SIZE * 0.5, 330.0, Color("#263e35"))
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
