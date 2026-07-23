class_name GameHUD
extends CanvasLayer

signal class_selected(class_id: StringName)
signal continue_requested
signal new_game_requested
signal action_requested(slot: int)
signal action_aim_requested(slot: int, direction: Vector2)
signal choice_selected(choice_id: StringName, mode: StringName)
signal pause_requested
signal resume_requested
signal restart_requested
signal upgrade_selected(upgrade_id: StringName)
signal settings_changed(settings: Dictionary)
signal quit_requested

@onready var _root: Control = %Root
@onready var _safe_root: Control = %SafeRoot
@onready var _resume_overlay: Control = %ResumeOverlay
@onready var _continue_button: Button = %ContinueButton
@onready var _resume_message: Label = %ResumeMessage
@onready var _selection_overlay: Control = %SelectionOverlay
@onready var _gameplay: Control = %Gameplay
@onready var _pause_overlay: Control = %PauseOverlay
@onready var _level_up_overlay: Control = %LevelUpOverlay
@onready var _choice_overlay: Control = %ChoiceOverlay
@onready var _game_over_overlay: Control = %GameOverOverlay
@onready var _quit_confirm_overlay: Control = %QuitConfirmOverlay
@onready var _joystick: ArcaneVirtualJoystick = %VirtualJoystick
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _health_label: Label = %HealthLabel
@onready var _xp_bar: ProgressBar = %XPBar
@onready var _level_label: Label = %LevelLabel
@onready var _class_label: Label = %ClassLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _enemy_label: Label = %EnemyLabel
@onready var _objective_label: Label = %ObjectiveLabel
@onready var _mastery_bar: ProgressBar = %MasteryBar
@onready var _mastery_label: Label = %MasteryLabel
@onready var _banner_title: Label = %BannerTitle
@onready var _banner_subtitle: Label = %BannerSubtitle
@onready var _banner: Control = %Banner
@onready var _game_over_result: Label = %GameOverResult
@onready var _upgrade_buttons: Array[Button] = [%Upgrade1, %Upgrade2, %Upgrade3]
@onready var _choice_buttons: Array[Button] = [%Choice1, %Choice2, %Choice3]
@onready var _action_buttons: Array[Button] = [%Action0, %Action1, %Action2, %Action3]
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _shake_toggle: CheckButton = %ShakeToggle
@onready var _motion_toggle: CheckButton = %MotionToggle
@onready var _haptics_toggle: CheckButton = %HapticsToggle
@onready var _effects_option: OptionButton = %EffectsOption
@onready var _class_buttons: Array[Button] = [%SwordsmanButton, %ArcherButton, %MageButton]
@onready var _difficulty_option: OptionButton = %DifficultyOption
@onready var _selection_content: Control = $Root/SafeRoot/SelectionOverlay/Content
@onready var _level_content: Control = $Root/SafeRoot/LevelUpOverlay/Content
@onready var _pause_content: Control = $Root/SafeRoot/PauseOverlay/Content
@onready var _pause_menu: Control = $Root/SafeRoot/PauseOverlay/Content/Menu
@onready var _pause_settings: Control = $Root/SafeRoot/PauseOverlay/Content/Settings
@onready var _wave_panel: Control = %WavePanel

var _action_names: Array[String] = ["공격", "스킬 1", "스킬 2", "스킬 3"]
var _upgrade_ids: Array[StringName] = []
var _choice_ids: Array[StringName] = []
var _choice_mode: StringName
var _action_gestures: Dictionary = {}
var _banner_tween: Tween
var _applying_settings := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(_apply_safe_area)
	_continue_button.pressed.connect(continue_requested.emit)
	%NewGameButton.pressed.connect(new_game_requested.emit)
	%SwordsmanButton.pressed.connect(class_selected.emit.bind(&"class.swordsman"))
	%ArcherButton.pressed.connect(class_selected.emit.bind(&"class.archer"))
	%MageButton.pressed.connect(class_selected.emit.bind(&"class.mage"))
	%PauseButton.pressed.connect(pause_requested.emit)
	%ResumeButton.pressed.connect(resume_requested.emit)
	%PauseRestartButton.pressed.connect(restart_requested.emit)
	%GameOverRestartButton.pressed.connect(restart_requested.emit)
	%PauseQuitButton.pressed.connect(_show_quit_confirmation)
	%QuitCancelButton.pressed.connect(_hide_quit_confirmation)
	%QuitConfirmButton.pressed.connect(quit_requested.emit)
	for index in range(_action_buttons.size()):
		_action_buttons[index].gui_input.connect(_on_action_gui_input.bind(index))
	for index in range(_upgrade_buttons.size()):
		_upgrade_buttons[index].pressed.connect(_on_upgrade_pressed.bind(index))
	for index in range(_choice_buttons.size()):
		_choice_buttons[index].pressed.connect(_on_choice_pressed.bind(index))
	_sfx_slider.value_changed.connect(_on_settings_control_changed.unbind(1))
	_shake_toggle.toggled.connect(_on_settings_control_changed.unbind(1))
	_motion_toggle.toggled.connect(_on_settings_control_changed.unbind(1))
	_haptics_toggle.toggled.connect(_on_settings_control_changed.unbind(1))
	_effects_option.item_selected.connect(_on_settings_control_changed.unbind(1))
	_apply_safe_area()
	_show_only(_resume_overlay)


func show_boot(has_checkpoint: bool, recovery_message: String = "") -> void:
	_show_only(_resume_overlay)
	_continue_button.disabled = not has_checkpoint
	if has_checkpoint:
		_resume_message.text = recovery_message if not recovery_message.is_empty() else "저장된 웨이브 시작 지점에서 이어갑니다."
	elif recovery_message.is_empty():
		_resume_message.text = "새 모험을 시작할 준비가 되었습니다."
	else:
		_resume_message.text = recovery_message
	reset_input()


func show_class_selection() -> void:
	_show_only(_selection_overlay)
	reset_input()


func begin_game(class_definition: CharacterClassDefinition) -> void:
	_show_only(_gameplay)
	_class_label.text = "%s · %s" % [class_definition.display_name, class_definition.title]
	_action_names.clear()
	for ability in class_definition.actions:
		_action_names.append(ability.display_name)
	for index in range(_action_buttons.size()):
		_action_buttons[index].text = _action_names[index]
	reset_input()


func get_selected_difficulty_id() -> StringName:
	match _difficulty_option.selected:
		0:
			return &"difficulty.pioneer"
		2:
			return &"difficulty.nightmare"
		_:
			return &"difficulty.hunter"


func show_playing() -> void:
	_show_only(_gameplay)


func show_pause() -> void:
	_gameplay.visible = true
	_pause_overlay.visible = true
	_level_up_overlay.visible = false
	_game_over_overlay.visible = false
	_choice_overlay.visible = false
	reset_input()


func show_level_up(choices: Array[UpgradeDefinition]) -> void:
	_gameplay.visible = true
	_level_up_overlay.visible = true
	_pause_overlay.visible = false
	_choice_overlay.visible = false
	_game_over_overlay.visible = false
	_upgrade_ids.clear()
	for index in range(_upgrade_buttons.size()):
		var button := _upgrade_buttons[index]
		if index < choices.size():
			var choice := choices[index]
			_upgrade_ids.append(choice.id)
			button.text = "%s\n\n%s" % [choice.display_name, choice.description]
			button.disabled = false
		else:
			_upgrade_ids.append(&"")
			button.text = "선택지 없음"
			button.disabled = true
	reset_input()


func show_choice(title: String, subtitle: String, choices: Array[Dictionary], mode: StringName) -> void:
	_gameplay.visible = true
	_choice_overlay.visible = true
	_pause_overlay.visible = false
	_level_up_overlay.visible = false
	_game_over_overlay.visible = false
	%ChoiceTitle.text = title
	%ChoiceSubtitle.text = subtitle
	_choice_mode = mode
	_choice_ids.clear()
	for index in range(_choice_buttons.size()):
		var button := _choice_buttons[index]
		if index < choices.size():
			var choice: Dictionary = choices[index]
			_choice_ids.append(StringName(choice.get("id", "")))
			button.text = "%s\n\n%s" % [str(choice.get("title", "선택")), str(choice.get("description", ""))]
			button.disabled = false
			button.visible = true
		else:
			_choice_ids.append(&"")
			button.disabled = true
			button.visible = false
	reset_input()


func show_game_over(reached_wave: int, level: int, best_cleared_wave: int) -> void:
	_gameplay.visible = true
	_pause_overlay.visible = false
	_level_up_overlay.visible = false
	_choice_overlay.visible = false
	_game_over_overlay.visible = true
	_game_over_result.text = "도달 웨이브 %d · 최종 레벨 %d\n최고 클리어 웨이브 %d" % [reached_wave, level, best_cleared_wave]
	reset_input()


func get_move_vector() -> Vector2:
	return _joystick.value


func reset_input() -> void:
	if is_instance_valid(_joystick):
		_joystick.reset_input()
	_action_gestures.clear()


func update_health(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "%d / %d" % [ceili(current), ceili(maximum)]


func update_experience(level_value: int, current: int, required: int) -> void:
	_level_label.text = "Lv.%d" % level_value
	_xp_bar.max_value = required
	_xp_bar.value = current


func update_wave(value: int) -> void:
	_wave_label.text = "웨이브 %d" % value


func update_enemy_count(value: int) -> void:
	_enemy_label.text = "남은 적 %d" % maxi(0, value)


func update_run_context(context: Dictionary) -> void:
	var depth := int(context.get("depth", 1))
	var depth_text := "보스" if depth == 5 else "%d/5" % depth
	_wave_label.text = "%s · 구역 %s" % [str(context.get("region_name", "변경")), depth_text]
	_enemy_label.tooltip_text = "%s · 확보 %d / 미확보 %d 인장" % [
		str(context.get("difficulty_name", "사냥꾼")),
		int(context.get("banked_sigils", 0)),
		int(context.get("unbanked_sigils", 0)),
	]


func update_mastery(current: float, maximum: float, segments: int) -> void:
	_mastery_bar.max_value = maximum
	_mastery_bar.value = current
	_mastery_label.text = "숙련 %d%% · %d" % [roundi(current / maxf(1.0, maximum) * 100.0), segments]


func update_objective(title: String, current: float, target: float, completed: bool) -> void:
	_objective_label.text = "%s · %s" % [title, "완료" if completed else "%d / %d" % [floori(current), ceili(target)]]


func update_cooldowns(values: Array[float], maximums: Array[float]) -> void:
	for index in range(mini(_action_buttons.size(), values.size())):
		var remaining := values[index]
		var button := _action_buttons[index]
		button.disabled = remaining > 0.03
		button.text = "%s\n%.1f" % [_action_names[index], remaining] if remaining > 0.03 else _action_names[index]
		button.tooltip_text = "재사용 대기시간 %.1f초" % maximums[index]


func show_banner(title: String, subtitle: String) -> void:
	_banner_title.text = title
	_banner_subtitle.text = subtitle
	if is_instance_valid(_banner_tween):
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner.position.y = 126.0
	_banner_tween = create_tween()
	_banner_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if _motion_toggle.button_pressed:
		_banner.position.y = 106.0
		_banner.modulate.a = 1.0
		_banner_tween.tween_interval(0.9)
		_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.12)
		return
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.2)
	_banner_tween.parallel().tween_property(_banner, "position:y", 106.0, 0.28).set_trans(Tween.TRANS_BACK)
	_banner_tween.tween_interval(1.1)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.3)


func apply_profile_settings(settings: Dictionary) -> void:
	_applying_settings = true
	_sfx_slider.value = float(settings.get("sfx_volume", 0.8))
	_shake_toggle.button_pressed = bool(settings.get("shake", true))
	_motion_toggle.button_pressed = bool(settings.get("reduced_motion", false))
	_haptics_toggle.button_pressed = bool(settings.get("haptics", true))
	_effects_option.select(1 if str(settings.get("effects_quality", "high")) == "low" else 0)
	_applying_settings = false


func request_back_action() -> bool:
	if _quit_confirm_overlay.visible:
		_hide_quit_confirmation()
		return true
	if _pause_overlay.visible:
		resume_requested.emit()
		return true
	if _level_up_overlay.visible:
		return true
	if _choice_overlay.visible:
		return true
	if _game_over_overlay.visible:
		_show_quit_confirmation()
		return true
	if _gameplay.visible and not _level_up_overlay.visible and not _game_over_overlay.visible:
		pause_requested.emit()
		return true
	_show_quit_confirmation()
	return true


func _show_only(primary: Control) -> void:
	_resume_overlay.visible = primary == _resume_overlay
	_selection_overlay.visible = primary == _selection_overlay
	_gameplay.visible = primary == _gameplay
	_pause_overlay.visible = false
	_level_up_overlay.visible = false
	_choice_overlay.visible = false
	_game_over_overlay.visible = false
	_quit_confirm_overlay.visible = false


func _on_upgrade_pressed(index: int) -> void:
	if index < _upgrade_ids.size() and not _upgrade_ids[index].is_empty():
		upgrade_selected.emit(_upgrade_ids[index])


func _on_choice_pressed(index: int) -> void:
	if index < _choice_ids.size() and not _choice_ids[index].is_empty():
		choice_selected.emit(_choice_ids[index], _choice_mode)


func _on_action_gui_input(event: InputEvent, slot: int) -> void:
	var pointer_id := -1
	var pressed := false
	var released := false
	var position := Vector2.ZERO
	if event is InputEventScreenTouch:
		pointer_id = event.index
		pressed = event.pressed
		released = not event.pressed
		position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		released = not event.pressed
		position = event.position
	else:
		return
	if pressed:
		_action_gestures[pointer_id] = {"slot": slot, "start": position}
		return
	if not released or not _action_gestures.has(pointer_id):
		return
	var gesture: Dictionary = _action_gestures[pointer_id]
	_action_gestures.erase(pointer_id)
	if int(gesture.get("slot", -1)) != slot:
		return
	var direction: Vector2 = position - Vector2(gesture.get("start", position))
	if direction.length() >= 18.0:
		action_aim_requested.emit(slot, direction.normalized())
	else:
		action_requested.emit(slot)


func _on_settings_control_changed() -> void:
	if _applying_settings:
		return
	settings_changed.emit({
		"sfx_volume": _sfx_slider.value,
		"shake": _shake_toggle.button_pressed,
		"reduced_motion": _motion_toggle.button_pressed,
		"haptics": _haptics_toggle.button_pressed,
		"effects_quality": "low" if _effects_option.selected == 1 else "high",
	})


func _show_quit_confirmation() -> void:
	_quit_confirm_overlay.visible = true


func _hide_quit_confirmation() -> void:
	_quit_confirm_overlay.visible = false


func _apply_safe_area() -> void:
	if not is_instance_valid(_safe_root):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		_safe_root.set_offsets_preset(Control.PRESET_FULL_RECT)
		return
	var safe_pixels := DisplayServer.get_display_safe_area()
	var mobile := OS.has_feature("android") or OS.has_feature("ios")
	var metrics := compute_safe_layout(viewport_size, window_size, safe_pixels, mobile)
	_safe_root.offset_left = metrics["left"]
	_safe_root.offset_top = metrics["top"]
	_safe_root.offset_right = metrics["right"]
	_safe_root.offset_bottom = metrics["bottom"]
	var compact: bool = metrics["compact"]
	for button in _class_buttons:
		button.custom_minimum_size.x = 250.0 if compact else 280.0
	for button in _upgrade_buttons:
		button.custom_minimum_size.x = 255.0 if compact else 330.0
	_selection_content.offset_left = 22.0 if compact else 36.0
	_selection_content.offset_right = -22.0 if compact else -36.0
	_level_content.offset_left = -440.0 if compact else -540.0
	_level_content.offset_right = 440.0 if compact else 540.0
	_pause_content.offset_left = -390.0 if compact else -410.0
	_pause_content.offset_right = 390.0 if compact else 410.0
	_pause_menu.custom_minimum_size.x = 330.0 if compact else 360.0
	_pause_settings.custom_minimum_size.x = 370.0 if compact else 410.0
	_wave_panel.offset_left = 360.0 if compact else 500.0
	_wave_panel.offset_right = -360.0 if compact else -500.0


static func compute_safe_layout(viewport_size: Vector2, window_size: Vector2, safe_pixels: Rect2i, mobile: bool) -> Dictionary:
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0, "compact": viewport_size.x < 1100.0}
	if not mobile or safe_pixels.size.x <= 0 or safe_pixels.size.y <= 0:
		safe_pixels = Rect2i(Vector2i.ZERO, Vector2i(window_size))
	var scale := viewport_size / window_size
	var left := safe_pixels.position.x * scale.x
	var top := safe_pixels.position.y * scale.y
	var right := -(window_size.x - safe_pixels.end.x) * scale.x
	var bottom := -(window_size.y - safe_pixels.end.y) * scale.y
	var safe_width := viewport_size.x - left + right
	return {"left": left, "top": top, "right": right, "bottom": bottom, "compact": safe_width < 1100.0}
