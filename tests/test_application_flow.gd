extends SceneTree

var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var app := preload("res://scenes/main.tscn").instantiate() as ApplicationFlow
	get_root().add_child(app)
	await process_frame
	await process_frame
	app.request_new_run()
	app.call("_on_class_selected", &"class.swordsman")
	await process_frame
	_check(app.state == ApplicationFlow.AppState.ROUTE_CHOICE, "새 런은 직업·난이도 선택 뒤 경로 선택으로 전이해야 함")
	_check(app.run_world != null and app.run_world.get_route_choices().size() == 1, "첫 경로는 고정 조우 하나를 표시해야 함")
	var route_id := StringName(app.run_world.get_route_choices()[0]["id"])
	app.call("_on_choice_selected", route_id, &"route")
	await process_frame
	_check(app.state == ApplicationFlow.AppState.PLAYING, "경로 선택 뒤 전투 상태로 진입해야 함")
	_check((app.run_world.director.get("_spawn_queue") as Array).size() > 0, "선택한 경로는 실제 적 대기열을 구성해야 함")

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(20, 20)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(90, 20)
	app.get_node("%HUD").call("_on_action_gui_input", press, 0)
	app.get_node("%HUD").call("_on_action_gui_input", release, 0)
	_check(app.run_world.player.cooldowns[0] > 0.0, "버튼 드래그 조준은 방향과 함께 ability를 발동해야 함")

	app.request_pause()
	_check(app.state == ApplicationFlow.AppState.PAUSED, "모바일/Back pause는 전투 월드를 중지해야 함")
	app.request_resume()
	_check(app.state == ApplicationFlow.AppState.PLAYING, "사용자 resume 뒤에만 전투를 재개해야 함")
	app.call("_teardown_run_world")
	await process_frame
	app.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.05).timeout
	if _failures.is_empty():
		print("PASS: %d application-flow checks" % _checks)
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
