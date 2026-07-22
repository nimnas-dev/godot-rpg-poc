extends Node2D

signal finished

var effect_color := Color.WHITE
var radius := 80.0
var duration := 0.28
var elapsed := 0.0
var effect_type := "ring"
var facing := Vector2.RIGHT


func setup(type: String, color: Color, effect_radius: float, direction: Vector2 = Vector2.RIGHT) -> void:
	effect_type = type
	effect_color = color
	radius = effect_radius
	facing = direction
	rotation = facing.angle()
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= duration:
		finished.emit()
		queue_free()


func _draw() -> void:
	var t := clampf(elapsed / duration, 0.0, 1.0)
	var alpha := 1.0 - t
	match effect_type:
		"slash":
			draw_arc(Vector2.ZERO, radius * (0.55 + t * 0.35), -0.85, 0.85, 24, Color(effect_color, alpha), 12.0 * alpha + 2.0)
		"burst":
			draw_circle(Vector2.ZERO, radius * t, Color(effect_color, alpha * 0.22))
			draw_arc(Vector2.ZERO, radius * t, 0.0, TAU, 48, Color(effect_color, alpha), 5.0)
		_:
			draw_arc(Vector2.ZERO, radius * (0.2 + t * 0.8), 0.0, TAU, 48, Color(effect_color, alpha), 7.0 * alpha + 1.0)
