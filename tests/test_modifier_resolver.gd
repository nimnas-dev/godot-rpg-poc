extends SceneTree

const RESOLVER_SCRIPT := preload("res://scripts/modifier_resolver.gd")


func _initialize() -> void:
	var add := ModifierDefinition.new()
	add.id = &"modifier.test.add"
	add.target_stat = "power"
	add.operation = "add"
	add.value = 5.0
	var multiply := ModifierDefinition.new()
	multiply.id = &"modifier.test.multiply"
	multiply.target_stat = "power"
	multiply.operation = "multiply"
	multiply.value = 1.2
	var conditional := ModifierDefinition.new()
	conditional.id = &"modifier.test.conditional"
	conditional.target_stat = "range"
	conditional.operation = "multiply"
	conditional.value = 1.5
	conditional.condition_tag = &"projectile"
	var resolver = RESOLVER_SCRIPT.new()
	resolver.set_sources([add, multiply, conditional])
	if not is_equal_approx(resolver.calculate("power", 10.0), 18.0):
		push_error("modifier pipeline must apply additive before multiplicative")
		quit(1)
	if not is_equal_approx(resolver.calculate("range", 100.0), 100.0):
		push_error("conditional modifier must not apply without its tag")
		quit(1)
	if not is_equal_approx(resolver.calculate("range", 100.0, [&"projectile"]), 150.0):
		push_error("conditional modifier must apply with its tag")
		quit(1)
	print("PASS: 3 modifier resolver checks")
	quit(0)
