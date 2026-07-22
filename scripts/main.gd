class_name ApplicationFlow
extends Node

enum AppState {
	BOOT,
	RESUME_CHOICE,
	CLASS_SELECTION,
	PLAYING,
	WAVE_TRANSITION,
	LEVEL_UP,
	PAUSED,
	GAME_OVER,
}

const RUN_WORLD_SCENE := preload("res://scenes/run_world.tscn")

var state := AppState.BOOT
var content: ContentRegistry
var save_service: RunSaveService
var profile: Dictionary
var run_world: RunWorld
var _state_before_pause := AppState.PLAYING
var _transitioning := false
var _last_health := -1.0
var _wave_transition_clock := 0.0
var _next_wave := 1
var _upgrade_return_state := AppState.PLAYING

@onready var _world_host: Node2D = %WorldHost
@onready var _hud: GameHUD = %HUD
@onready var _audio_router: AudioRouter = %AudioRouter


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().quit_on_go_back = false
	content = ContentRegistry.new()
	save_service = RunSaveService.new(content)
	_connect_hud()
	_audio_router.configure_buses(content.get_feedback_profile())
	profile = save_service.load_profile()
	_hud.apply_profile_settings(profile["settings"])
	_apply_settings(profile["settings"])
	var checkpoint := save_service.load_checkpoint()
	state = AppState.RESUME_CHOICE
	_hud.show_boot(not checkpoint.is_empty(), save_service.last_error)


func _process(delta: float) -> void:
	if state == AppState.PLAYING and is_instance_valid(run_world):
		run_world.set_mobile_move(_hud.get_move_vector())
	elif state == AppState.WAVE_TRANSITION and is_instance_valid(run_world):
		_wave_transition_clock -= delta
		if _wave_transition_clock <= 0.0:
			_enter_playing()
			run_world.start_wave(_next_wave)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_hud.request_back_action()
		get_viewport().set_input_as_handled()
		return
	if state != AppState.PLAYING or not is_instance_valid(run_world):
		return
	if event.is_action_pressed("basic_attack"):
		run_world.try_use_ability(0)
	elif event.is_action_pressed("skill_1"):
		run_world.try_use_ability(1)
	elif event.is_action_pressed("skill_2"):
		run_world.try_use_ability(2)
	elif event.is_action_pressed("skill_3"):
		run_world.try_use_ability(3)


func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_hud.request_back_action()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if state == AppState.PLAYING or state == AppState.WAVE_TRANSITION:
			request_pause()
		_hud.reset_input()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_hud.reset_input()


func request_new_run() -> void:
	if _transitioning:
		return
	_transitioning = true
	save_service.clear_checkpoint()
	_teardown_run_world()
	state = AppState.CLASS_SELECTION
	_hud.show_class_selection()
	_transitioning = false


func request_continue() -> void:
	if _transitioning:
		return
	_transitioning = true
	var checkpoint := save_service.load_checkpoint()
	if checkpoint.is_empty():
		state = AppState.RESUME_CHOICE
		_hud.show_boot(false, save_service.last_error)
		_transitioning = false
		return
	_create_run_world()
	run_world.restore_checkpoint(checkpoint, content)
	_hud.begin_game(run_world.player.get_class_definition())
	_enter_playing()
	run_world.start_wave(int(checkpoint["wave"]))
	_transitioning = false


func request_pause() -> void:
	if (state != AppState.PLAYING and state != AppState.WAVE_TRANSITION) or not is_instance_valid(run_world):
		return
	_state_before_pause = state
	run_world.suspend_combat()
	run_world.process_mode = Node.PROCESS_MODE_DISABLED
	state = AppState.PAUSED
	_hud.show_pause()


func request_resume() -> void:
	if state != AppState.PAUSED or not is_instance_valid(run_world):
		return
	state = _state_before_pause
	run_world.process_mode = Node.PROCESS_MODE_DISABLED if state == AppState.WAVE_TRANSITION else Node.PROCESS_MODE_INHERIT
	_hud.show_playing()


func request_restart() -> void:
	request_new_run()


func _on_class_selected(class_id: StringName) -> void:
	if state != AppState.CLASS_SELECTION or _transitioning:
		return
	var class_definition := content.get_class_definition(class_id)
	if class_definition == null:
		return
	_transitioning = true
	_create_run_world()
	var seed := int(Time.get_unix_time_from_system()) ^ Time.get_ticks_msec()
	run_world.configure_new(class_definition, content, seed)
	_hud.begin_game(class_definition)
	_enter_playing()
	run_world.start_wave(1)
	_transitioning = false


func _create_run_world() -> void:
	_teardown_run_world()
	run_world = RUN_WORLD_SCENE.instantiate() as RunWorld
	_world_host.add_child(run_world)
	run_world.configure_feedback(content.get_feedback_profile(), profile.get("settings", {}))
	run_world.health_changed.connect(_on_health_changed)
	run_world.cooldowns_changed.connect(_hud.update_cooldowns)
	run_world.experience_changed.connect(_hud.update_experience)
	run_world.enemy_count_changed.connect(_hud.update_enemy_count)
	run_world.wave_started.connect(_on_wave_started)
	run_world.wave_cleared.connect(_on_wave_cleared)
	run_world.upgrade_choice_queued.connect(_on_upgrade_choice_queued)
	run_world.player_died.connect(_on_player_died)
	run_world.checkpoint_ready.connect(_on_checkpoint_ready)
	run_world.audio_cue_requested.connect(_audio_router.play_cue)
	_last_health = -1.0


func _teardown_run_world() -> void:
	if not is_instance_valid(run_world):
		return
	run_world.shutdown()
	if run_world.get_parent() != null:
		run_world.get_parent().remove_child(run_world)
	run_world.queue_free()
	run_world = null


func _enter_playing() -> void:
	state = AppState.PLAYING
	run_world.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.show_playing()


func _on_wave_started(wave: int, _total: int) -> void:
	_audio_router.play_cue(&"wave")
	_hud.update_wave(wave)
	_hud.show_banner("웨이브 %d" % wave, "어둠의 무리가 다가옵니다")


func _on_wave_cleared(wave: int) -> void:
	if state != AppState.PLAYING or _transitioning:
		return
	_transitioning = true
	profile["best_cleared_wave"] = maxi(int(profile.get("best_cleared_wave", 0)), wave)
	save_service.save_profile(profile)
	state = AppState.WAVE_TRANSITION
	run_world.process_mode = Node.PROCESS_MODE_DISABLED
	_hud.show_banner("웨이브 완료", "다음 전투를 준비하세요")
	_wave_transition_clock = 2.2
	_next_wave = wave + 1
	_transitioning = false


func _on_upgrade_choice_queued() -> void:
	call_deferred("_resolve_upgrade_queue")


func _resolve_upgrade_queue() -> void:
	if not is_instance_valid(run_world) or run_world.player.dead or state == AppState.GAME_OVER:
		return
	if run_world.player.pending_upgrade_choices <= 0 or (state != AppState.PLAYING and state != AppState.WAVE_TRANSITION):
		return
	_upgrade_return_state = state
	state = AppState.LEVEL_UP
	run_world.suspend_combat()
	run_world.process_mode = Node.PROCESS_MODE_DISABLED
	_hud.show_level_up(_build_upgrade_choices())


func _build_upgrade_choices() -> Array[UpgradeDefinition]:
	var player := run_world.player
	var pool := content.get_upgrades_for_class(player.class_id, player.upgrade_stacks)
	if pool.size() < 3:
		for veteran in content.get_veteran_upgrades():
			pool.append(veteran)
	var rng := RandomNumberGenerator.new()
	rng.seed = run_world.run_seed + player.level * 7919 + player.pending_upgrade_choices * 313
	for index in range(pool.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary := pool[index]
		pool[index] = pool[swap_index]
		pool[swap_index] = temporary
	var choices: Array[UpgradeDefinition] = []
	for definition in pool:
		if choices.size() >= 3:
			break
		choices.append(definition)
	return choices


func _on_upgrade_selected(upgrade_id: StringName) -> void:
	if state != AppState.LEVEL_UP or not is_instance_valid(run_world):
		return
	var definition := content.get_upgrade_definition(upgrade_id)
	if definition == null:
		return
	run_world.apply_upgrade(definition)
	if run_world.player.pending_upgrade_choices > 0:
		_hud.show_level_up(_build_upgrade_choices())
	elif _upgrade_return_state == AppState.WAVE_TRANSITION:
		state = AppState.WAVE_TRANSITION
		run_world.process_mode = Node.PROCESS_MODE_DISABLED
		_hud.show_playing()
	else:
		_enter_playing()


func _on_player_died() -> void:
	call_deferred("_commit_game_over")


func _commit_game_over() -> void:
	if not is_instance_valid(run_world) or state == AppState.GAME_OVER:
		return
	state = AppState.GAME_OVER
	_audio_router.play_cue(&"death")
	run_world.shutdown()
	save_service.clear_checkpoint()
	_hud.show_game_over(run_world.current_wave, run_world.player.level, int(profile.get("best_cleared_wave", 0)))


func _on_checkpoint_ready(checkpoint: Dictionary) -> void:
	if not save_service.save_checkpoint(checkpoint):
		call_deferred("_show_save_error", save_service.last_error)


func _show_save_error(message: String) -> void:
	_hud.show_banner("저장 실패", message)


func _on_health_changed(current: float, maximum: float) -> void:
	_hud.update_health(current, maximum)
	if _last_health >= 0.0 and current < _last_health:
		var settings: Dictionary = profile.get("settings", {})
		if bool(settings.get("haptics", true)):
			Input.vibrate_handheld(25)
		if bool(settings.get("shake", true)) and not bool(settings.get("reduced_motion", false)):
			_shake_camera()
	_last_health = current


func _shake_camera() -> void:
	if not is_instance_valid(run_world) or not is_instance_valid(run_world.player):
		return
	var camera := run_world.player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	var shake := content.get_feedback_profile().max_camera_shake
	camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	var tween := create_tween()
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.12)


func _on_settings_changed(settings: Dictionary) -> void:
	profile["settings"] = settings.duplicate(true)
	_apply_settings(settings)
	save_service.save_profile(profile)


func _apply_settings(settings: Dictionary) -> void:
	Engine.max_fps = 30 if str(settings.get("effects_quality", "high")) == "low" else 60
	_audio_router.apply_settings(settings)
	if is_instance_valid(run_world):
		run_world.configure_effects(settings)


func _connect_hud() -> void:
	_hud.class_selected.connect(_on_class_selected)
	_hud.continue_requested.connect(request_continue)
	_hud.new_game_requested.connect(request_new_run)
	_hud.action_requested.connect(_on_action_requested)
	_hud.pause_requested.connect(request_pause)
	_hud.resume_requested.connect(request_resume)
	_hud.restart_requested.connect(request_restart)
	_hud.upgrade_selected.connect(_on_upgrade_selected)
	_hud.settings_changed.connect(_on_settings_changed)
	_hud.quit_requested.connect(get_tree().quit)


func _on_action_requested(slot: int) -> void:
	_audio_router.play_cue(&"ui")
	if state == AppState.PLAYING and is_instance_valid(run_world):
		run_world.try_use_ability(slot)
