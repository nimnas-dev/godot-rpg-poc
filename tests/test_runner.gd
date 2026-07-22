extends SceneTree

class AttackDummy:
	extends Node

	func is_on_screen() -> bool:
		return true


class DamageDummy:
	extends Node2D

	var dead := false
	var received_damage := 0.0

	func take_damage(amount: float, _direction: Vector2 = Vector2.ZERO, _force: float = 0.0) -> void:
		received_damage += amount


var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var content := ContentRegistry.new()
	_test_content(content)
	_test_spawn_contract()
	_test_attack_budget(content)
	await _test_player_runtime(content)
	await _test_run_world_lifecycle(content)
	await _test_swept_projectile()
	_test_save_recovery(content)
	_test_safe_area_layouts()
	await _test_hud_scene()
	if _failures.is_empty():
		print("PASS: %d checks" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("FAIL: %d failures / %d checks" % [_failures.size(), _checks])
		quit(1)


func _test_content(content: ContentRegistry) -> void:
	_check(content.get_class_definition(&"class.swordsman") != null, "검사 정의를 불러와야 함")
	_check(content.get_class_definition(&"class.archer").actions.size() == 4, "궁수는 ability 4개를 가져야 함")
	_check(content.get_class_definition(&"class.mage").actions[3].id == &"ability.mage.blink", "ability stable ID가 보존되어야 함")
	_check(content.get_class_definition(&"class.mage").actions[1].effect.status_type == "slow", "ability는 별도 typed effect/status 계약을 가져야 함")
	_check(content.get_enemy_definition(&"enemy.wraith").attack.ranged, "망령 공격은 원거리여야 함")
	_check(content.get_upgrade_definition(&"upgrade.veteran.damage").max_stacks == 0, "공용 베테랑 강화는 무제한이어야 함")
	_check(is_equal_approx(content.get_feedback_profile().max_camera_shake, 6.0), "feedback profile은 모바일 흔들림 상한을 정의해야 함")


func _test_spawn_contract() -> void:
	var corners := [Vector2(70, 70), Vector2(2330, 70), Vector2(70, 1530), Vector2(2330, 1530), Vector2(1200, 800)]
	var bounds := Rect2(Vector2(70, 70), Vector2(2260, 1460))
	for corner_index in range(corners.size()):
		for seed_offset in range(64):
			var rng := RandomNumberGenerator.new()
			rng.seed = corner_index * 1000 + seed_offset
			var enemies: Array[Vector2] = []
			var position := EncounterDirector.choose_spawn_position(corners[corner_index], enemies, rng, Vector2(2400, 1600))
			var distance := position.distance_to(corners[corner_index])
			_check(bounds.has_point(position), "스폰은 inset 경계 안이어야 함")
			_check(distance >= 440.0 - 0.01 and distance <= 650.0 + 0.01, "스폰은 플레이어 거리 계약을 지켜야 함")


func _test_attack_budget(content: ContentRegistry) -> void:
	var director := EncounterDirector.new()
	var player := Node2D.new()
	var registry := CombatRegistry.new()
	get_root().add_child(director)
	get_root().add_child(player)
	director.configure(player, registry, content, 77, Vector2(2400, 1600))
	director.start_wave(20)
	_check((director.get("_spawn_queue") as Array).size() == 24, "웨이브 활성 적 수는 24로 제한되어야 함")
	var ranged_a := AttackDummy.new()
	var ranged_b := AttackDummy.new()
	var melee_a := AttackDummy.new()
	var melee_b := AttackDummy.new()
	var melee_c := AttackDummy.new()
	for enemy in [ranged_a, ranged_b, melee_a, melee_b, melee_c]:
		get_root().add_child(enemy)
	_check(director.request_attack_token(ranged_a, true), "첫 원거리 공격권은 허용되어야 함")
	director.set("_attack_elapsed", 1.0)
	_check(not director.request_attack_token(ranged_b, true), "원거리 공격권은 하나여야 함")
	_check(director.request_attack_token(melee_a, false), "두 번째 전체 공격권은 허용되어야 함")
	director.set("_attack_elapsed", 1.0)
	_check(director.request_attack_token(melee_b, false), "세 번째 전체 공격권은 허용되어야 함")
	director.set("_attack_elapsed", 1.0)
	_check(not director.request_attack_token(melee_c, false), "네 번째 동시 공격은 거부되어야 함")
	director.queue_free()
	player.queue_free()
	for enemy in [ranged_a, ranged_b, melee_a, melee_b, melee_c]:
		enemy.queue_free()


func _test_player_runtime(content: ContentRegistry) -> void:
	var player := preload("res://scenes/player.tscn").instantiate() as PlayerActor
	var registry := CombatRegistry.new()
	get_root().add_child(registry)
	get_root().add_child(player)
	await process_frame
	player.configure(content.get_class_definition(&"class.swordsman"), registry)
	player.guard_multiplier = 0.28
	player.guard_clock = 2.0
	player.invulnerability = 1.0
	player.hurt_flash = 1.0
	player.reset_transient_state()
	_check(is_equal_approx(player.guard_multiplier, 1.0), "재시작은 guard multiplier를 초기화해야 함")
	_check(is_zero_approx(player.guard_clock) and is_zero_approx(player.invulnerability) and is_zero_approx(player.hurt_flash), "재시작은 모든 transient timer를 초기화해야 함")
	var upgrade := content.get_upgrade_definition(&"upgrade.swordsman.charge")
	player.apply_upgrade(upgrade)
	var checkpoint := player.make_runtime_state()
	var restored := preload("res://scenes/player.tscn").instantiate() as PlayerActor
	get_root().add_child(restored)
	await process_frame
	restored.configure(content.get_class_definition(&"class.swordsman"), registry)
	restored.restore_runtime(checkpoint)
	_check(int(restored.upgrade_stacks.get(upgrade.id, 0)) == 1, "강화 중첩은 체크포인트에서 복원되어야 함")
	_check(is_equal_approx(restored.power, player.power), "파생 능력치는 정의와 런타임 상태에서 재계산되어야 함")
	player.queue_free()
	restored.queue_free()
	registry.queue_free()


func _test_swept_projectile() -> void:
	var registry := CombatRegistry.new()
	var enemy := DamageDummy.new()
	enemy.position = Vector2(500, 0)
	registry.register_enemy(enemy)
	get_root().add_child(registry)
	get_root().add_child(enemy)
	var projectile := preload("res://scenes/projectile.tscn").instantiate() as CombatProjectile
	get_root().add_child(projectile)
	projectile.set_physics_process(false)
	await process_frame
	projectile.global_position = Vector2.ZERO
	projectile.setup(Vector2.RIGHT, {"team": "player", "speed": 1000.0, "damage": 25.0, "radius": 5.0, "lifetime": 2.0}, registry, null)
	projectile._physics_process(1.0)
	_check(is_equal_approx(enemy.received_damage, 25.0), "저 FPS 선분을 가로지른 투사체도 적중해야 함")
	projectile.queue_free()
	enemy.queue_free()
	registry.queue_free()


func _test_run_world_lifecycle(content: ContentRegistry) -> void:
	var first := preload("res://scenes/run_world.tscn").instantiate() as RunWorld
	get_root().add_child(first)
	await process_frame
	first.configure_new(content.get_class_definition(&"class.mage"), content, 12345)
	first.start_wave(1)
	var checkpoint := first.make_checkpoint()
	_check(checkpoint["class_id"] == "class.mage" and int(checkpoint["wave"]) == 1, "RunWorld는 완전한 웨이브 시작 체크포인트를 만들어야 함")
	first.player.guard_multiplier = 0.2
	first.shutdown()
	_check(not first.player.active and first.process_mode == Node.PROCESS_MODE_DISABLED, "shutdown은 전투 입력과 월드 처리를 중지해야 함")
	first.queue_free()
	await process_frame
	var second := preload("res://scenes/run_world.tscn").instantiate() as RunWorld
	get_root().add_child(second)
	await process_frame
	second.configure_new(content.get_class_definition(&"class.mage"), content, 54321)
	_check(is_equal_approx(second.player.guard_multiplier, 1.0), "새 RunWorld는 이전 런의 guard 상태를 공유하지 않아야 함")
	second.shutdown()
	second.queue_free()


func _test_save_recovery(content: ContentRegistry) -> void:
	var profile_path := "user://arcane_frontier_test_profile.json"
	var checkpoint_path := "user://arcane_frontier_test_checkpoint.json"
	var service := RunSaveService.new(content, profile_path, checkpoint_path)
	service.clear_checkpoint()
	var checkpoint := {
		"schema_version": 1,
		"content_version": 1,
		"run_seed": 99,
		"wave": 4,
		"class_id": "class.archer",
		"level": 3,
		"experience": 12,
		"health": 70.0,
		"upgrade_stacks": {"upgrade.archer.drill_tip": 1},
	}
	_check(service.save_checkpoint(checkpoint), "유효 체크포인트를 저장할 수 있어야 함")
	checkpoint["health"] = 55.0
	_check(service.save_checkpoint(checkpoint), "두 번째 저장은 이전 파일을 백업해야 함")
	var corrupt := FileAccess.open(checkpoint_path, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	var recovered := service.load_checkpoint()
	_check(not recovered.is_empty() and is_equal_approx(float(recovered["health"]), 70.0), "현재 파일 손상 시 백업을 복원해야 함")
	service.clear_checkpoint()
	var unknown := checkpoint.duplicate(true)
	unknown["class_id"] = "class.missing"
	var invalid_file := FileAccess.open(checkpoint_path, FileAccess.WRITE)
	invalid_file.store_string(JSON.stringify(unknown))
	invalid_file.close()
	_check(service.load_checkpoint().is_empty(), "알 수 없는 콘텐츠 ID는 Continue를 비활성화해야 함")
	service.clear_checkpoint()
	var legacy := checkpoint.duplicate(true)
	legacy["schema_version"] = 0
	legacy.erase("content_version")
	legacy["class_id"] = "archer"
	var legacy_file := FileAccess.open(checkpoint_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy))
	legacy_file.close()
	var migrated := service.load_checkpoint()
	_check(not migrated.is_empty() and migrated["class_id"] == "class.archer", "schema v0 class ID는 v1 stable ID로 이관되어야 함")
	service.clear_checkpoint()
	for suffix in ["", ".bak", ".tmp"]:
		var path := profile_path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _test_hud_scene() -> void:
	var hud := preload("res://scenes/hud.tscn").instantiate() as GameHUD
	get_root().add_child(hud)
	await process_frame
	_check(hud.get_node_or_null("%SafeRoot") != null, "HUD는 safe-area root를 가져야 함")
	_check(hud.get_node_or_null("%VirtualJoystick") is VirtualJoystick, "HUD는 typed virtual joystick을 가져야 함")
	var joystick := hud.get_node("%VirtualJoystick") as VirtualJoystick
	var first_touch := InputEventScreenTouch.new()
	first_touch.index = 1
	first_touch.pressed = true
	first_touch.position = joystick.size * 0.5 + Vector2(50, 0)
	joystick._gui_input(first_touch)
	var second_touch := InputEventScreenTouch.new()
	second_touch.index = 2
	second_touch.pressed = true
	second_touch.position = joystick.size * 0.5 + Vector2(-50, 0)
	joystick._gui_input(second_touch)
	_check(joystick.touch_index == 1 and joystick.value.x > 0.0, "조이스틱은 첫 터치만 소유해야 함")
	hud.show_boot(false)
	hud.reset_input()
	_check(joystick.touch_index == -1 and joystick.value.is_zero_approx(), "pause/background 입력 초기화가 터치 소유권을 해제해야 함")
	hud.queue_free()


func _test_safe_area_layouts() -> void:
	var standard := GameHUD.compute_safe_layout(Vector2(1280, 720), Vector2(1280, 720), Rect2i(0, 0, 1280, 720), true)
	_check(not bool(standard["compact"]), "16:9 논리 해상도는 표준 HUD 레이아웃이어야 함")
	var wide := GameHUD.compute_safe_layout(Vector2(1280, 720), Vector2(2340, 1080), Rect2i(132, 0, 2076, 1080), true)
	_check(float(wide["left"]) > 0.0 and float(wide["right"]) < 0.0, "19.5:9 cutout 여백은 양쪽 HUD 안쪽 여백으로 변환되어야 함")
	var tablet := GameHUD.compute_safe_layout(Vector2(960, 720), Vector2(960, 720), Rect2i(0, 0, 960, 720), true)
	_check(bool(tablet["compact"]), "4:3 화면은 compact 컨테이너 크기를 사용해야 함")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
