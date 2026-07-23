class_name RunSaveService
extends RefCounted

const SCHEMA_VERSION := 2
const CONTENT_VERSION := 2
const PROFILE_PATH := "user://profile.json"
const CHECKPOINT_PATH := "user://run_checkpoint.json"

var last_error := ""
var _content: ContentRegistry
var _profile_path := PROFILE_PATH
var _checkpoint_path := CHECKPOINT_PATH


func _init(content: ContentRegistry, profile_path: String = PROFILE_PATH, checkpoint_path: String = CHECKPOINT_PATH) -> void:
	_content = content
	_profile_path = profile_path
	_checkpoint_path = checkpoint_path


func default_profile() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"best_cleared_wave": 0,
		"banked_sigils": 0,
		"unlock_ids": ["region.hollow_grove"],
		"quest_states": {},
		"region_records": {},
		"earned_cosmetic_ids": [],
		"equipped_cosmetics": {},
		"achievement_progress": {},
		"settings": {
			"sfx_volume": 0.8,
			"shake": true,
			"reduced_motion": false,
			"haptics": true,
			"effects_quality": "high",
		},
	}


func load_profile() -> Dictionary:
	last_error = ""
	var loaded: Dictionary = {}
	for candidate in [_profile_path, _profile_path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var parsed: Variant = _parse_json_file(candidate)
		if parsed is Dictionary:
			parsed = _migrate_profile(parsed)
			if int(parsed.get("schema_version", -1)) == SCHEMA_VERSION:
				loaded = parsed
				break
	if loaded.is_empty() or int(loaded.get("schema_version", -1)) != SCHEMA_VERSION:
		return default_profile()
	var result := default_profile()
	result["best_cleared_wave"] = maxi(0, int(loaded.get("best_cleared_wave", 0)))
	result["banked_sigils"] = maxi(0, int(loaded.get("banked_sigils", 0)))
	result["unlock_ids"] = _sanitize_string_array(loaded.get("unlock_ids", []), ["region.hollow_grove"])
	result["quest_states"] = _sanitize_dictionary(loaded.get("quest_states", {}))
	result["region_records"] = _sanitize_dictionary(loaded.get("region_records", {}))
	result["earned_cosmetic_ids"] = _sanitize_string_array(loaded.get("earned_cosmetic_ids", []))
	result["equipped_cosmetics"] = _sanitize_dictionary(loaded.get("equipped_cosmetics", {}))
	result["achievement_progress"] = _sanitize_dictionary(loaded.get("achievement_progress", {}))
	result["settings"] = _sanitize_settings(loaded.get("settings", {}))
	return result


func save_profile(profile: Dictionary) -> bool:
	var normalized := default_profile()
	normalized["best_cleared_wave"] = maxi(0, int(profile.get("best_cleared_wave", 0)))
	normalized["banked_sigils"] = maxi(0, int(profile.get("banked_sigils", 0)))
	normalized["unlock_ids"] = _sanitize_string_array(profile.get("unlock_ids", []), ["region.hollow_grove"])
	normalized["quest_states"] = _sanitize_dictionary(profile.get("quest_states", {}))
	normalized["region_records"] = _sanitize_dictionary(profile.get("region_records", {}))
	normalized["earned_cosmetic_ids"] = _sanitize_string_array(profile.get("earned_cosmetic_ids", []))
	normalized["equipped_cosmetics"] = _sanitize_dictionary(profile.get("equipped_cosmetics", {}))
	normalized["achievement_progress"] = _sanitize_dictionary(profile.get("achievement_progress", {}))
	normalized["settings"] = _sanitize_settings(profile.get("settings", {}))
	return _atomic_write_json(_profile_path, normalized)


func has_valid_checkpoint() -> bool:
	return not load_checkpoint().is_empty()


func load_checkpoint() -> Dictionary:
	last_error = ""
	var found_file := false
	var candidates := [_checkpoint_path, _checkpoint_path + ".bak"]
	for index in range(candidates.size()):
		var candidate: String = candidates[index]
		if not FileAccess.file_exists(candidate):
			continue
		found_file = true
		var parsed: Variant = _parse_json_file(candidate)
		if parsed is Dictionary:
			parsed = _migrate_checkpoint(parsed)
		if parsed is Dictionary and _validate_checkpoint(parsed):
			if index == 1:
				last_error = "현재 저장 파일을 읽지 못해 백업 체크포인트를 사용합니다."
			return parsed
	last_error = "저장 데이터가 손상되었거나 버전·콘텐츠 ID를 확인할 수 없습니다." if found_file else ""
	return {}


func save_checkpoint(checkpoint: Dictionary) -> bool:
	var normalized := _normalize_checkpoint(checkpoint)
	normalized["schema_version"] = SCHEMA_VERSION
	normalized["content_version"] = CONTENT_VERSION
	if not _validate_checkpoint(normalized):
		last_error = "체크포인트 필수 값이 올바르지 않습니다."
		return false
	return _atomic_write_json(_checkpoint_path, normalized)


func clear_checkpoint() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = _checkpoint_path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _validate_checkpoint(data: Dictionary) -> bool:
	if int(data.get("schema_version", -1)) != SCHEMA_VERSION or int(data.get("content_version", -1)) != CONTENT_VERSION:
		return false
	var required := [
		"run_seed", "wave", "class_id", "level", "experience", "health", "upgrade_stacks",
		"difficulty_id", "region_id", "chapter", "depth", "route_seed", "route_state",
		"relic_ids", "evolution_ids", "banked_sigils", "unbanked_sigils",
		"reroll_charges", "banished_upgrade_ids", "mastery",
	]
	for key in required:
		if not data.has(key):
			return false
	if int(data["wave"]) < 1 or int(data["wave"]) > 100000:
		return false
	if int(data["level"]) < 1 or int(data["level"]) > 100 or int(data["experience"]) < 0 or int(data["experience"]) > 1000000000 or float(data["health"]) <= 0.0:
		return false
	if not data["upgrade_stacks"] is Dictionary:
		return false
	if not data["route_state"] is Dictionary or not data["mastery"] is Dictionary:
		return false
	if not data["relic_ids"] is Array or not data["evolution_ids"] is Array or not data["banished_upgrade_ids"] is Array:
		return false
	if int(data["chapter"]) < 1 or int(data["depth"]) < 1 or int(data["depth"]) > 6:
		return false
	if int(data["banked_sigils"]) < 0 or int(data["unbanked_sigils"]) < 0 or int(data["reroll_charges"]) < 0 or int(data["reroll_charges"]) > 3:
		return false
	return _content.validate_ids(StringName(data["class_id"]), data["upgrade_stacks"]) and _content.validate_run_content_ids(
		StringName(data["region_id"]),
		StringName(data["difficulty_id"]),
		data["relic_ids"],
		data["evolution_ids"],
	)


func _migrate_profile(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return data
	if not data.has("schema_version") and data.has("best_wave"):
		return {
			"schema_version": 1,
			"best_cleared_wave": maxi(0, int(data.get("best_wave", 0))),
			"settings": data.get("settings", {}),
		}
	if int(data.get("schema_version", -1)) == 1:
		var migrated := default_profile()
		migrated["best_cleared_wave"] = maxi(0, int(data.get("best_cleared_wave", 0)))
		migrated["settings"] = data.get("settings", {})
		return migrated
	return data


func _sanitize_settings(value: Variant) -> Dictionary:
	var result: Dictionary = default_profile()["settings"]
	if not value is Dictionary:
		return result
	if value.get("sfx_volume") is float or value.get("sfx_volume") is int:
		result["sfx_volume"] = clampf(float(value["sfx_volume"]), 0.0, 1.0)
	for key in ["shake", "reduced_motion", "haptics"]:
		if value.get(key) is bool:
			result[key] = value[key]
	if str(value.get("effects_quality", "high")) in ["high", "low"]:
		result["effects_quality"] = str(value["effects_quality"])
	return result


func _migrate_checkpoint(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	if int(migrated.get("schema_version", -1)) == 0:
		var legacy_class := str(migrated.get("class_id", ""))
		if legacy_class in ["swordsman", "archer", "mage"]:
			migrated["class_id"] = "class.%s" % legacy_class
		migrated["schema_version"] = 1
		migrated["content_version"] = 1
		if not migrated.has("upgrade_stacks"):
			migrated["upgrade_stacks"] = {}
	if int(migrated.get("schema_version", -1)) == 1:
		migrated = _normalize_checkpoint(migrated)
		migrated["schema_version"] = SCHEMA_VERSION
		migrated["content_version"] = CONTENT_VERSION
	return migrated


func _normalize_checkpoint(data: Dictionary) -> Dictionary:
	var normalized := data.duplicate(true)
	var wave := maxi(1, int(normalized.get("wave", 1)))
	var run_seed := int(normalized.get("run_seed", 0))
	var chapter := maxi(1, int(normalized.get("chapter", (wave - 1) / 5 + 1)))
	var class_id := str(normalized.get("class_id", "class.swordsman"))
	normalized["difficulty_id"] = str(normalized.get("difficulty_id", "difficulty.hunter"))
	normalized["region_id"] = str(normalized.get("region_id", "region.hollow_grove"))
	normalized["chapter"] = chapter
	normalized["depth"] = clampi(int(normalized.get("depth", (wave - 1) % 5 + 1)), 1, 6)
	normalized["route_seed"] = int(normalized.get("route_seed", run_seed ^ chapter * 104729))
	normalized["route_state"] = (normalized.get("route_state", {}) as Dictionary).duplicate(true) if normalized.get("route_state", {}) is Dictionary else {}
	normalized["relic_ids"] = _sanitize_string_array(normalized.get("relic_ids", []))
	normalized["evolution_ids"] = _sanitize_string_array(normalized.get("evolution_ids", []))
	normalized["banked_sigils"] = maxi(0, int(normalized.get("banked_sigils", 0)))
	normalized["unbanked_sigils"] = maxi(0, int(normalized.get("unbanked_sigils", 0)))
	normalized["reroll_charges"] = clampi(int(normalized.get("reroll_charges", 1)), 0, 3)
	normalized["banished_upgrade_ids"] = _sanitize_string_array(normalized.get("banished_upgrade_ids", []))
	var mastery_state: Dictionary = {}
	var raw_mastery: Variant = normalized.get("mastery", {})
	if raw_mastery is Dictionary:
		mastery_state = (raw_mastery as Dictionary).duplicate(true)
	if mastery_state.is_empty():
		mastery_state = {
			"class_id": class_id,
			"current": 0.0,
			"ready": false,
			"resonance_tags": [],
			"resonance_clock": 0.0,
		}
	normalized["mastery"] = mastery_state
	return normalized


func _sanitize_string_array(value: Variant, defaults: Array = []) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for entry in value:
			var text := str(entry)
			if not text.is_empty() and not result.has(text):
				result.append(text)
	for entry in defaults:
		var text := str(entry)
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result


func _sanitize_dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _atomic_write_json(path: String, data: Dictionary) -> bool:
	last_error = ""
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "임시 저장 파일을 열 수 없습니다."
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()
	var reparsed: Variant = _parse_json_file(temporary)
	if not reparsed is Dictionary:
		last_error = "저장 데이터 검증에 실패했습니다."
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return false
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temp := ProjectSettings.globalize_path(temporary)
	var absolute_backup := ProjectSettings.globalize_path(path + ".bak")
	if FileAccess.file_exists(path):
		var existing: Variant = _parse_json_file(path)
		var existing_valid := existing is Dictionary
		if existing_valid and path == _checkpoint_path:
			existing_valid = _validate_checkpoint(_migrate_checkpoint(existing))
		elif existing_valid and path == _profile_path:
			existing_valid = int(existing.get("schema_version", -1)) == SCHEMA_VERSION
		if existing_valid:
			if FileAccess.file_exists(path + ".bak"):
				DirAccess.remove_absolute(absolute_backup)
			var backup_error := DirAccess.rename_absolute(absolute_path, absolute_backup)
			if backup_error != OK:
				last_error = "기존 저장 파일을 백업할 수 없습니다."
				return false
		else:
			DirAccess.remove_absolute(absolute_path)
	var rename_error := DirAccess.rename_absolute(absolute_temp, absolute_path)
	if rename_error != OK:
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.rename_absolute(absolute_backup, absolute_path)
		last_error = "검증된 저장 파일을 적용할 수 없습니다."
		return false
	return true


func _parse_json_file(path: String) -> Variant:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return json.data
