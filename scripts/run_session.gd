class_name RunSession
extends RefCounted

signal state_changed
signal chapter_banked(amount: int)

const DEFAULT_REGION_ID := &"region.hollow_grove"
const DEFAULT_DIFFICULTY_ID := &"difficulty.hunter"
const MAX_RELIC_SLOTS := 4

var run_seed := 0
var class_id: StringName = &"class.swordsman"
var difficulty_id: StringName = DEFAULT_DIFFICULTY_ID
var region_id: StringName = DEFAULT_REGION_ID
var chapter := 1
var depth := 1
var route_seed := 0
var route_state: Dictionary = {}
var relic_ids: Array[StringName] = []
var evolution_ids: Array[StringName] = []
var banked_sigils := 0
var unbanked_sigils := 0
var reroll_charges := 1
var banished_upgrade_ids: Array[StringName] = []


func configure_new(
	new_class_id: StringName,
	new_difficulty_id: StringName,
	new_region_id: StringName,
	seed: int
) -> void:
	run_seed = seed
	class_id = new_class_id
	difficulty_id = new_difficulty_id if not new_difficulty_id.is_empty() else DEFAULT_DIFFICULTY_ID
	region_id = new_region_id if not new_region_id.is_empty() else DEFAULT_REGION_ID
	chapter = 1
	depth = 1
	route_seed = _chapter_seed()
	route_state.clear()
	relic_ids.clear()
	evolution_ids.clear()
	banked_sigils = 0
	unbanked_sigils = 0
	reroll_charges = 1
	banished_upgrade_ids.clear()
	state_changed.emit()


func restore_runtime(data: Dictionary) -> bool:
	if not _validate_state(data):
		return false
	run_seed = int(data["run_seed"])
	class_id = StringName(data["class_id"])
	difficulty_id = StringName(data.get("difficulty_id", DEFAULT_DIFFICULTY_ID))
	region_id = StringName(data.get("region_id", DEFAULT_REGION_ID))
	chapter = int(data.get("chapter", 1))
	depth = int(data.get("depth", 1))
	route_seed = int(data.get("route_seed", _chapter_seed()))
	route_state = (data.get("route_state", {}) as Dictionary).duplicate(true)
	relic_ids = _to_string_name_array(data.get("relic_ids", []))
	evolution_ids = _to_string_name_array(data.get("evolution_ids", []))
	banked_sigils = maxi(0, int(data.get("banked_sigils", 0)))
	unbanked_sigils = maxi(0, int(data.get("unbanked_sigils", 0)))
	reroll_charges = clampi(int(data.get("reroll_charges", 1)), 0, 3)
	banished_upgrade_ids = _to_string_name_array(data.get("banished_upgrade_ids", []))
	state_changed.emit()
	return true


func make_runtime_state() -> Dictionary:
	return {
		"run_seed": run_seed,
		"class_id": String(class_id),
		"difficulty_id": String(difficulty_id),
		"region_id": String(region_id),
		"chapter": chapter,
		"depth": depth,
		"route_seed": route_seed,
		"route_state": route_state.duplicate(true),
		"relic_ids": _stringify_ids(relic_ids),
		"evolution_ids": _stringify_ids(evolution_ids),
		"banked_sigils": banked_sigils,
		"unbanked_sigils": unbanked_sigils,
		"reroll_charges": reroll_charges,
		"banished_upgrade_ids": _stringify_ids(banished_upgrade_ids),
	}


func set_route(serialized_route: Dictionary) -> void:
	route_state = serialized_route.duplicate(true)
	state_changed.emit()


func select_route_node(node_state: Dictionary) -> void:
	route_state["selected_node_id"] = str(node_state.get("id", ""))
	route_state["selected_objective_id"] = str(node_state.get("objective_id", ""))
	route_state["selected_encounter_kind"] = str(node_state.get("encounter_kind", ""))
	route_state["selected_arena_id"] = str(node_state.get("arena_id", ""))
	state_changed.emit()


func complete_encounter(reward_sigils: int) -> bool:
	if depth < 1 or depth > 5:
		return false
	unbanked_sigils += maxi(0, reward_sigils)
	depth += 1
	state_changed.emit()
	return depth > 5


func bank_completed_chapter() -> int:
	if depth <= 5:
		return 0
	var amount := unbanked_sigils
	banked_sigils += amount
	unbanked_sigils = 0
	chapter_banked.emit(amount)
	state_changed.emit()
	return amount


func continue_to_region(next_region_id: StringName) -> void:
	if not next_region_id.is_empty():
		region_id = next_region_id
	chapter += 1
	depth = 1
	route_seed = _chapter_seed()
	route_state.clear()
	reroll_charges = mini(3, reroll_charges + 1)
	state_changed.emit()


func add_relic(relic_id: StringName, replace_index: int = -1) -> bool:
	if relic_id.is_empty() or relic_ids.has(relic_id):
		return false
	if relic_ids.size() < MAX_RELIC_SLOTS:
		relic_ids.append(relic_id)
	elif replace_index >= 0 and replace_index < relic_ids.size():
		relic_ids[replace_index] = relic_id
	else:
		return false
	state_changed.emit()
	return true


func add_evolution(evolution_id: StringName) -> bool:
	if evolution_id.is_empty() or evolution_ids.has(evolution_id):
		return false
	evolution_ids.append(evolution_id)
	state_changed.emit()
	return true


func spend_reroll() -> bool:
	if reroll_charges <= 0:
		return false
	reroll_charges -= 1
	state_changed.emit()
	return true


func grant_reroll(amount: int = 1) -> void:
	reroll_charges = clampi(reroll_charges + maxi(0, amount), 0, 3)
	state_changed.emit()


func banish_upgrade(upgrade_id: StringName) -> bool:
	if upgrade_id.is_empty() or banished_upgrade_ids.has(upgrade_id):
		return false
	banished_upgrade_ids.append(upgrade_id)
	state_changed.emit()
	return true


func _chapter_seed() -> int:
	return run_seed ^ (chapter * 104729) ^ int(hash(region_id))


func _validate_state(data: Dictionary) -> bool:
	if not data.has("run_seed") or not data.has("class_id"):
		return false
	if StringName(data.get("class_id", "")).is_empty():
		return false
	var saved_chapter := int(data.get("chapter", 1))
	var saved_depth := int(data.get("depth", 1))
	return saved_chapter >= 1 and saved_chapter <= 100000 and saved_depth >= 1 and saved_depth <= 6


func _to_string_name_array(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if not value is Array:
		return result
	for entry in value:
		var id := StringName(entry)
		if not id.is_empty() and not result.has(id):
			result.append(id)
	return result


func _stringify_ids(ids: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for id in ids:
		result.append(String(id))
	return result
