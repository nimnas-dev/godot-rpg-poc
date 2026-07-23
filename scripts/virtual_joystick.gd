class_name ArcaneVirtualJoystick
extends Control

var value := Vector2.ZERO
var touch_index := -1
var dragging_mouse := false
var knob_position := Vector2.ZERO
var max_radius := 68.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(190, 190)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_VISIBILITY_CHANGED:
		reset_input()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			_update_from_position(event.position)
			accept_event()
		elif not event.pressed and event.index == touch_index:
			reset_input()
			accept_event()
	elif event is InputEventScreenDrag and event.index == touch_index:
		_update_from_position(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging_mouse = event.pressed
		if dragging_mouse:
			_update_from_position(event.position)
		else:
			reset_input()
		accept_event()
	elif event is InputEventMouseMotion and dragging_mouse:
		_update_from_position(event.position)
		accept_event()


func reset_input() -> void:
	touch_index = -1
	dragging_mouse = false
	value = Vector2.ZERO
	knob_position = Vector2.ZERO
	queue_redraw()


func _update_from_position(local_position: Vector2) -> void:
	var center := size * 0.5
	var offset := local_position - center
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius
	knob_position = offset
	value = offset / max_radius
	if value.length() < 0.12:
		value = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, 82.0, Color(0.03, 0.06, 0.08, 0.42))
	draw_circle(center, 68.0, Color(0.32, 0.44, 0.48, 0.18))
	draw_arc(center, 68.0, 0.0, TAU, 48, Color(0.67, 0.82, 0.83, 0.34), 3.0)
	draw_circle(center + knob_position, 31.0, Color(0.44, 0.86, 0.8, 0.82))
	draw_circle(center + knob_position - Vector2(6, 7), 12.0, Color(0.8, 1.0, 0.94, 0.55))
