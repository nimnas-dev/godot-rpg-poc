class_name ApplicationFlow
extends Node

enum AppState {
	BOOT,
	RESUME_CHOICE,
	CLASS_SELECTION,
	PLAYING,
	WAVE_TRANSITION,
	LEVEL_UP,
	ROUTE_CHOICE,
	BOSS_REWARD,
	REGION_CHOICE,
	PAUSED,
	GAME_OVER,
}

const RUN_WORLD_SCENE := preload("res://scenes/run_world.tscn")
const QUEST_SERVICE_SCRIPT := preload("res://scripts/quest_progress_service.gd")
const LOCAL_PLATFORM_SCRIPT := preload("res://scripts/platform/platform_services.gd")
const ANDROID_PLATFORM_SCRIPT := preload("res://scripts/platform/android_services.gd")
const IOS_PLATFORM_SCRIPT := preload("res://scripts/platform/ios_services.gd")

var state := AppState.BOOT
var content: ContentRegistry
var save_service: RunSaveService
var quest_service
var platform_services
var profile: Dictionary
var run_world: RunWorld
var _state_before_pause := AppState.PLAYING
var _transitioning := false
var _last_health := -1.0
var _wave_transition_clock := 0.0
var _next_wave := 1
var _upgrade_return_state := AppState.PLAYING
var _pending_post_encounter := false

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
	quest_service = QUEST_SERVICE_SCRIPT.new()
	quest_service.configure(content, profile.get("quest_states", {}))
	platform_services = _create_platform_services()
	platform_services.request_purchased_entitlements()
	_hud.apply_profile_settings(profile["settings"])
	_apply_settings(profile["settings"])
	var checkpoint := save_service.load_checkpoint()
	state = AppState.RESUME_CHOICE
	_hud.show_boot(not checkpoint.is_empty(), save_service.last_error)


func _process(delta: float) -> void:
	if state == AppState.PLAYING and is_instance_valid(run_world):
		run_world.set_mobile_move(_hud.get_move_vector())
	elif state == AppState.WAVE_TRANSITION and not _pending_post_encounter and is_instance_valid(run_world):
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


func _exit_tree() -> void:
	if platform_services != null:
		platform_services.shutdown()


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
	if run_world.session.depth > 5:
		_show_boss_reward()
	elif String(run_world.session.route_state.get("selected_node_id", "")).is_empty():
		_show_route_choices()
	else:
		_enter_playing()
		run_world.start_current_encounter()
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
	run_world.configure_new(class_definition, content, seed, _hud.get_selected_difficulty_id())
	_hud.begin_game(class_definition)
	_show_route_choices()
	_transitioning = false


func _create_run_world() -> void:
	_teardown_run_world()
	run_world = RUN_WORLD_SCENE.instantiate() as RunWorld
	_world_host.add_child(run_world)
	run_world.configure_feedback(content.get_feedback_profile(), profile.get("settings", {}))
	run_world.health_changed.connect(_on_health_changed)
	run_world.cooldowns_changed.connect(_hud.update_cooldowns)
	run_world.experience_changed.connect(_hud.update_experience)
	run_world.mastery_changed.connect(_hud.update_mastery)
	run_world.objective_changed.connect(_hud.update_objective)
	run_world.objective_completed.connect(_on_objective_completed)
	run_world.enemy_count_changed.connect(_hud.update_enemy_count)
	run_world.run_progress_changed.connect(_hud.update_run_context)
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
	_hud.update_run_context(run_world.get_run_context())
	var context := run_world.get_run_context()
	_hud.show_banner(
		"지역 지배자" if bool(context.get("is_boss", false)) else "조우 %d" % int(context.get("depth", 1)),
		str(context.get("region_name", "변경"))
	)


func _on_wave_cleared(wave: int) -> void:
	if state != AppState.PLAYING or _transitioning:
		return
	_transitioning = true
	profile["best_cleared_wave"] = maxi(int(profile.get("best_cleared_wave", 0)), wave)
	save_service.save_profile(profile)
	state = AppState.WAVE_TRANSITION
	run_world.process_mode = Node.PROCESS_MODE_DISABLED
	_hud.show_banner("조우 완료", "전리품과 다음 길을 확인하세요")
	_pending_post_encounter = true
	_transitioning = false
	call_deferred("_advance_post_encounter")


func _advance_post_encounter() -> void:
	if not _pending_post_encounter or not is_instance_valid(run_world):
		return
	if run_world.player.pending_upgrade_choices > 0:
		_upgrade_return_state = AppState.WAVE_TRANSITION
		state = AppState.LEVEL_UP
		_hud.show_level_up(_build_upgrade_choices())
		return
	_pending_post_encounter = false
	if run_world.session.depth > 5:
		_show_boss_reward()
	else:
		_show_route_choices()


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
		call_deferred("_advance_post_encounter")
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
	_hud.action_aim_requested.connect(_on_action_aim_requested)
	_hud.choice_selected.connect(_on_choice_selected)
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


func _on_action_aim_requested(slot: int, direction: Vector2) -> void:
	_audio_router.play_cue(&"ui")
	if state == AppState.PLAYING and is_instance_valid(run_world):
		run_world.try_use_ability(slot, direction)


func _show_route_choices() -> void:
	if not is_instance_valid(run_world):
		return
	state = AppState.ROUTE_CHOICE
	run_world.process_mode = Node.PROCESS_MODE_DISABLED
	_hud.update_run_context(run_world.get_run_context())
	_hud.show_choice(
		"변경의 길을 선택하세요",
		"전투 규칙과 보상이 달라집니다",
		run_world.get_route_choices(),
		&"route"
	)


func _show_boss_reward() -> void:
	if not is_instance_valid(run_world):
		return
	state = AppState.BOSS_REWARD
	run_world.process_mode = Node.PROCESS_MODE_DISABLED
	var choices: Array[Dictionary] = []
	var relics := run_world.get_relic_choices()
	for index in range(mini(2, relics.size())):
		var relic: RelicDefinition = relics[index]
		choices.append({
			"id": String(relic.id),
			"title": "%s · %s" % [relic.display_name, String(relic.rarity)],
			"description": relic.description,
		})
	var evolutions := content.get_evolutions_for_class(run_world.session.class_id)
	if not evolutions.is_empty():
		var evolution := evolutions[(run_world.session.chapter - 1) % evolutions.size()]
		choices.append({
			"id": String(evolution.id),
			"title": evolution.display_name,
			"description": evolution.description,
		})
	_hud.show_choice("지배자의 전리품", "유물 슬롯은 네 칸이며 이후 선택은 가장 오래된 유물을 교체합니다", choices, &"boss_reward")


func _show_region_choices() -> void:
	state = AppState.REGION_CHOICE
	run_world.process_mode = Node.PROCESS_MODE_DISABLED
	var choices: Array[Dictionary] = []
	for region_id in content.get_next_region_ids(run_world.session.region_id):
		var region := content.get_region_definition(region_id)
		if region != null:
			choices.append({
				"id": String(region.id),
				"title": region.display_name,
				"description": region.description,
			})
	_hud.show_choice("다음 원정지", "확보한 인장은 마을 자원으로 보존되었습니다", choices, &"region")


func _on_choice_selected(choice_id: StringName, mode: StringName) -> void:
	if not is_instance_valid(run_world):
		return
	match mode:
		&"route":
			if state != AppState.ROUTE_CHOICE or not run_world.select_route_node(choice_id):
				return
			_enter_playing()
			run_world.start_current_encounter()
		&"boss_reward":
			if state != AppState.BOSS_REWARD:
				return
			var accepted := false
			if String(choice_id).begins_with("relic."):
				accepted = run_world.select_relic(choice_id, 0)
			elif String(choice_id).begins_with("evolution."):
				accepted = run_world.select_evolution(choice_id)
			if not accepted:
				return
			var banked := run_world.bank_chapter()
			profile["banked_sigils"] = int(profile.get("banked_sigils", 0)) + banked
			var unlock_ids: Array = profile.get("unlock_ids", [])
			for region_id in content.get_next_region_ids(run_world.session.region_id):
				if not unlock_ids.has(String(region_id)):
					unlock_ids.append(String(region_id))
			profile["unlock_ids"] = unlock_ids
			save_service.save_profile(profile)
			platform_services.report_achievement_progress(
				StringName("achievement.chapter.%d" % run_world.session.chapter),
				100.0
			)
			_show_region_choices()
		&"region":
			if state != AppState.REGION_CHOICE or not run_world.continue_to_region(choice_id):
				return
			_show_route_choices()


func _on_objective_completed(objective_id: StringName) -> void:
	var rewards: Dictionary = quest_service.report_objective_completed(objective_id)
	var completed: Array = rewards.get("completed_quest_ids", [])
	if completed.is_empty():
		return
	profile["quest_states"] = quest_service.make_state()
	var unlock_ids: Array = profile.get("unlock_ids", [])
	for region_id in rewards.get("unlock_region_ids", []):
		if not unlock_ids.has(region_id):
			unlock_ids.append(region_id)
	profile["unlock_ids"] = unlock_ids
	var cosmetic_ids: Array = profile.get("earned_cosmetic_ids", [])
	for cosmetic_id in rewards.get("earned_cosmetic_ids", []):
		if not cosmetic_ids.has(cosmetic_id):
			cosmetic_ids.append(cosmetic_id)
	profile["earned_cosmetic_ids"] = cosmetic_ids
	save_service.save_profile(profile)
	for quest_id in completed:
		platform_services.report_achievement_progress(
			StringName("achievement.%s" % String(quest_id).trim_prefix("quest.")),
			100.0
		)
	_hud.show_banner("퀘스트 완료", "%d개의 새 보상이 마을에 추가되었습니다" % completed.size())


func _create_platform_services():
	if OS.has_feature("android"):
		return ANDROID_PLATFORM_SCRIPT.new()
	if OS.has_feature("ios"):
		return IOS_PLATFORM_SCRIPT.new()
	return LOCAL_PLATFORM_SCRIPT.create_local()
