class_name QuestProgressService
extends RefCounted

var _content: ContentRegistry
var _states: Dictionary = {}


func configure(content: ContentRegistry, saved_states: Dictionary) -> void:
	_content = content
	_states = saved_states.duplicate(true)


func report_objective_completed(objective_id: StringName) -> Dictionary:
	var result := {
		"completed_quest_ids": [],
		"unlock_region_ids": [],
		"earned_cosmetic_ids": [],
	}
	if _content == null or objective_id.is_empty():
		return result
	var made_progress := true
	while made_progress:
		made_progress = false
		for quest in _content.get_all_quests():
			if not quest.objective_ids.has(objective_id) or not _prerequisites_met(quest):
				continue
			var state: Dictionary = (_states.get(quest.id, {}) as Dictionary).duplicate(true)
			if bool(state.get("completed", false)) and not quest.repeatable:
				continue
			var completed_objectives: Array = state.get("completed_objective_ids", [])
			var objective_text := String(objective_id)
			if not completed_objectives.has(objective_text):
				completed_objectives.append(objective_text)
			state["completed_objective_ids"] = completed_objectives
			var complete := true
			for required_id in quest.objective_ids:
				if not completed_objectives.has(String(required_id)):
					complete = false
					break
			state["completed"] = complete
			_states[quest.id] = state
			if not complete:
				continue
			var completed_ids: Array = result["completed_quest_ids"]
			completed_ids.append(String(quest.id))
			for region_id in quest.unlock_region_ids:
				var unlocks: Array = result["unlock_region_ids"]
				if not unlocks.has(String(region_id)):
					unlocks.append(String(region_id))
			for cosmetic in _content.get_all_cosmetics():
				if cosmetic.acquisition == "earned" and cosmetic.unlock_quest_id == quest.id:
					var cosmetics: Array = result["earned_cosmetic_ids"]
					if not cosmetics.has(String(cosmetic.id)):
						cosmetics.append(String(cosmetic.id))
			made_progress = true
	return result


func make_state() -> Dictionary:
	return _states.duplicate(true)


func _prerequisites_met(quest: QuestDefinition) -> bool:
	for prerequisite_id in quest.prerequisite_ids:
		var prerequisite: Dictionary = _states.get(prerequisite_id, {})
		if not bool(prerequisite.get("completed", false)):
			return false
	return true
