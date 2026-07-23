extends SceneTree

const FACTORY := preload("res://scripts/expansion_content_factory.gd")

var _checks := 0
var _failures: Array[String] = []


func _initialize() -> void:
	var catalog: ContentCatalog = FACTORY.build()
	_check(catalog.validation_errors().is_empty(), "expansion catalog must validate: %s" % ", ".join(catalog.validation_errors()))
	_check(catalog.regions.size() == 5, "catalog has five regions")
	_check(catalog.arenas.size() == 15, "each region has two encounter arenas and one boss arena")
	_check(catalog.bosses.size() == 5, "catalog has five bosses")
	_check(catalog.objectives.size() == 5, "catalog has five objectives")
	_check(catalog.elite_modifiers.size() == 10, "catalog has ten elite modifiers")
	_check(catalog.relics.size() == 24, "catalog has 24 relics")
	_check(catalog.evolutions.size() == 24, "catalog has two evolutions per class ability")
	_check(catalog.masteries.size() == 3, "catalog has three class masteries")
	_check(catalog.quests.size() == 20, "catalog has 20 quests")
	_check(catalog.cosmetics.size() == 20, "catalog has earned and premium cosmetics")
	_check(catalog.difficulties.size() == 3, "catalog has three difficulty tiers")
	var premium_count := 0
	for cosmetic in catalog.cosmetics:
		if cosmetic.acquisition == "premium":
			premium_count += 1
	_check(premium_count == 15, "15 cosmetics are non-gameplay premium entitlements")
	var final_region := catalog.get_region(&"region.rift_cathedral")
	_check(final_region != null and final_region.boss.phase_count == 3, "final region owns a three-phase boss")
	if _failures.is_empty():
		print("PASS: %d expansion content checks" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("FAIL: %d / %d expansion content checks" % [_failures.size(), _checks])
		quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
