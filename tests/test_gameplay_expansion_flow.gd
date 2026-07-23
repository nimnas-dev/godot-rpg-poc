extends SceneTree

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var content := ContentRegistry.new()
	var world := preload("res://scenes/run_world.tscn").instantiate() as RunWorld
	get_root().add_child(world)
	await process_frame
	world.configure_new(
		content.get_class_definition(&"class.swordsman"),
		content,
		24680,
		&"difficulty.nightmare",
		&"region.hollow_grove"
	)
	_check((world.get_node("%Backdrop") as Sprite2D).texture != null, "현재 지역의 생성형 배경이 런 월드에 로드되어야 함")
	var first_choices := world.get_route_choices()
	_check(first_choices.size() == 1, "첫 깊이는 고정 전투 하나여야 함")
	_check(world.select_route_node(StringName(first_choices[0]["id"])), "경로 선택은 저장 가능한 런 상태를 갱신해야 함")
	world.start_current_encounter()
	_check(world.director.region_id == &"region.hollow_grove", "전투 디렉터는 선택 지역의 적 풀을 사용해야 함")
	_check(world.director.get("_max_attackers") == 4, "악몽 난이도는 네 개의 공격권을 사용해야 함")
	var checkpoint := world.make_checkpoint()
	_check(checkpoint["schema_version"] == 2 and checkpoint["route_state"] is Dictionary, "체크포인트 v2는 경로 상태를 포함해야 함")
	world.stop_wave()

	world.session.depth = 3
	var branch_choices := world.get_route_choices()
	var noncombat_id := &""
	for choice in branch_choices:
		if StringName(choice["encounter_kind"]) in [&"recovery", &"shrine"]:
			noncombat_id = StringName(choice["id"])
			break
	_check(not noncombat_id.is_empty(), "중간 경로에는 회복 또는 제단 기회가 있어야 함")
	_check(world.select_route_node(noncombat_id), "비전투 경로도 선택 가능해야 함")
	world.start_current_encounter()
	await process_frame
	await process_frame
	_check(world.session.depth == 4, "비전투 경로는 효용을 적용한 뒤 다음 깊이로 진행해야 함")

	world.session.depth = 5
	var boss_choices := world.get_route_choices()
	_check(boss_choices.size() == 1 and StringName(boss_choices[0]["encounter_kind"]) == &"boss", "깊이 5는 단일 보스 노드여야 함")
	world.select_route_node(StringName(boss_choices[0]["id"]))
	world.start_current_encounter()
	_check((world.director.get("_spawn_queue") as Array).size() == 1, "보스 조우는 지역 보스 하나를 대기열에 넣어야 함")
	_check((world.director.get("_spawn_queue") as Array)[0] == &"enemy.rift_warden", "속빈 묘목숲 보스 ID가 일치해야 함")

	var relics := world.get_relic_choices()
	_check(relics.size() == 3 and world.select_relic(relics[0].id), "보스 보상은 결정론적 유물 세 개 중 하나를 적용해야 함")
	_check(world.player.modifier_resolver.snapshot_source_ids().size() >= 1, "선택한 유물 modifier가 플레이어 파생 능력치에 연결되어야 함")
	var quest_service := preload("res://scripts/quest_progress_service.gd").new()
	quest_service.configure(content, {})
	var quest_rewards: Dictionary = quest_service.report_objective_completed(&"objective.capture")
	_check(not (quest_rewards["completed_quest_ids"] as Array).is_empty(), "목표 완료는 선행 조건을 만족한 퀘스트를 진행해야 함")
	_check(not (quest_rewards["earned_cosmetic_ids"] as Array).is_empty(), "초기 퀘스트 완료는 획득형 외형을 해금해야 함")

	world.shutdown()
	world.queue_free()
	await process_frame
	if _failures.is_empty():
		print("PASS: %d checks" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("FAIL: %d failures / %d checks" % [_failures.size(), _checks])
		quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
