class_name ExpansionContentFactory
extends RefCounted

const REGION_SPECS := [
	[&"region.hollow_grove", "속빈 묘목숲", Color("#335348"), [&"region.ossuary_monastery", &"region.bloodwater_bog"], &"enemy.rift_warden", "균열 감시자", 2],
	[&"region.ossuary_monastery", "납골 수도원", Color("#5a535f"), [&"region.frozen_sanatorium", &"region.rift_cathedral"], &"enemy.ashen_abbot", "잿빛 수도원장", 2],
	[&"region.bloodwater_bog", "혈수 늪지", Color("#5e2934"), [&"region.frozen_sanatorium", &"region.rift_cathedral"], &"enemy.bloodroot_matron", "혈근의 모후", 2],
	[&"region.frozen_sanatorium", "얼어붙은 요양원", Color("#527080"), [&"region.rift_cathedral", &"region.hollow_grove"], &"enemy.glass_huntsman", "유리 사냥꾼", 2],
	[&"region.rift_cathedral", "균열 대성당", Color("#6d527c"), [&"region.hollow_grove", &"region.ossuary_monastery"], &"enemy.pale_archon", "창백한 집정관", 3],
]

const OBJECTIVE_SPECS := [
	[&"objective.capture", "봉인 룬 점령", "capture", 30.0, 1],
	[&"objective.hunt", "표적 사냥", "hunt", 90.0, 1],
	[&"objective.defend", "수호석 방어", "defend", 60.0, 1],
	[&"objective.destroy", "균열 닻 파괴", "destroy", 90.0, 3],
	[&"objective.survive", "일식 생존", "survive", 75.0, 0],
]

const EVOLUTION_ABILITIES := [
	[&"class.swordsman", [&"ability.swordsman.slash", &"ability.swordsman.spin", &"ability.swordsman.charge", &"ability.swordsman.fortress"]],
	[&"class.archer", [&"ability.archer.shot", &"ability.archer.spread", &"ability.archer.pierce", &"ability.archer.rain"]],
	[&"class.mage", [&"ability.mage.bolt", &"ability.mage.frost", &"ability.mage.stars", &"ability.mage.blink"]],
]


static func build() -> ContentCatalog:
	var catalog := ContentCatalog.new()
	catalog.objectives = _build_objectives()
	_build_regions(catalog)
	catalog.difficulties = _build_difficulties()
	catalog.modifiers = _build_modifiers()
	catalog.relics = _build_relics(catalog.modifiers)
	catalog.evolutions = _build_evolutions(catalog.modifiers)
	catalog.masteries = _build_masteries(catalog.modifiers)
	catalog.elite_modifiers = _build_elite_modifiers()
	catalog.quests = _build_quests()
	catalog.cosmetics = _build_cosmetics()
	return catalog


static func _build_objectives() -> Array[ObjectiveDefinition]:
	var result: Array[ObjectiveDefinition] = []
	for spec in OBJECTIVE_SPECS:
		var definition := ObjectiveDefinition.new()
		definition.id = spec[0]
		definition.display_name = spec[1]
		definition.description = "지역의 공간 규칙을 읽으며 %s 목표를 완수합니다." % spec[1]
		definition.kind = spec[2]
		definition.target_duration = spec[3]
		definition.target_count = spec[4]
		definition.reward_tags = [&"sigil", &"upgrade"]
		result.append(definition)
	return result


static func _build_regions(catalog: ContentCatalog) -> void:
	for region_index in range(REGION_SPECS.size()):
		var spec: Array = REGION_SPECS[region_index]
		var region := RegionDefinition.new()
		region.id = spec[0]
		region.display_name = spec[1]
		region.description = "암울한 변경에서 전투 규칙과 지형 위험을 배우는 %s입니다." % spec[1]
		region.theme_color = spec[2]
		region.next_region_ids.assign(spec[3])
		region.required_unlock_id = &"" if region_index == 0 else StringName("unlock.%s" % String(region.id).trim_prefix("region."))
		for arena_index in range(3):
			var arena := ArenaDefinition.new()
			arena.id = StringName("arena.%s.%d" % [String(region.id).trim_prefix("region."), arena_index + 1])
			arena.region_id = region.id
			arena.display_name = "%s %s" % [region.display_name, ["외곽", "심부", "보스 성역"][arena_index]]
			arena.landmark_tags = [&"gothic", &"combat_loop"]
			arena.supports_boss = arena_index == 2
			for objective in catalog.objectives:
				arena.supports_objective_ids.append(objective.id)
			region.arenas.append(arena)
			catalog.arenas.append(arena)
		var boss := BossDefinition.new()
		boss.id = StringName("boss.%s" % String(region.id).trim_prefix("region."))
		boss.enemy_id = spec[4]
		boss.display_name = spec[5]
		boss.arena_id = region.arenas[2].id
		boss.phase_count = spec[6]
		boss.learned_rule_tags = [&"priority", &"positioning", &"telegraph"]
		region.boss = boss
		catalog.bosses.append(boss)
		catalog.regions.append(region)


static func _build_difficulties() -> Array[DifficultyDefinition]:
	var result: Array[DifficultyDefinition] = []
	var specs := [
		[&"difficulty.pioneer", "개척자", 0.85, 1.0, 1.15, 3, 1, &""],
		[&"difficulty.hunter", "사냥꾼", 1.0, 1.0, 1.0, 3, 1, &""],
		[&"difficulty.nightmare", "악몽", 1.15, 1.05, 0.85, 4, 2, &"unlock.nightmare"],
	]
	for spec in specs:
		var definition := DifficultyDefinition.new()
		definition.id = spec[0]
		definition.display_name = spec[1]
		definition.description = "적의 조합과 공격권을 바꾸는 %s 난이도입니다." % spec[1]
		definition.enemy_damage_multiplier = spec[2]
		definition.enemy_health_multiplier = spec[3]
		definition.telegraph_duration_multiplier = spec[4]
		definition.max_attackers = spec[5]
		definition.max_ranged_attackers = spec[6]
		definition.required_unlock_id = spec[7]
		result.append(definition)
	return result


static func _build_modifiers() -> Array[ModifierDefinition]:
	var result: Array[ModifierDefinition] = []
	var specs := [
		["power", "multiply", 1.12],
		["max_health", "multiply", 1.18],
		["move_speed", "multiply", 1.1],
		["cooldown_rate", "multiply", 0.88],
		["range", "multiply", 1.16],
		["projectile_count", "add", 1.0],
		["mastery_gain", "multiply", 1.25],
		["damage_taken", "multiply", 0.86],
		["power", "multiply", 1.22],
		["max_health", "add", 24.0],
		["range", "multiply", 1.28],
		["cooldown_rate", "multiply", 0.78],
	]
	for index in range(specs.size()):
		var definition := ModifierDefinition.new()
		definition.id = StringName("modifier.frontier.%02d" % (index + 1))
		definition.target_stat = specs[index][0]
		definition.operation = specs[index][1]
		definition.value = specs[index][2]
		result.append(definition)
	return result


static func _build_relics(modifiers: Array[ModifierDefinition]) -> Array[RelicDefinition]:
	var names := [
		"검은 가시", "순례자의 등불", "깨진 성배", "장송 종편", "피안의 나침반", "핏빛 뿌리",
		"서리 거울", "공허의 못", "방랑자의 뼈", "잿빛 인장", "사냥개의 이빨", "별 없는 렌즈",
		"수호자의 파편", "메아리 심장", "침묵의 화살촉", "균열 실", "성가대 가면", "늪의 왕관",
		"유리 척추", "창백한 손", "봉인된 눈", "검은 해시계", "변경의 맹세", "종말의 씨앗",
	]
	var result: Array[RelicDefinition] = []
	for index in range(names.size()):
		var relic := RelicDefinition.new()
		relic.id = StringName("relic.frontier.%02d" % (index + 1))
		relic.display_name = names[index]
		relic.description = "전투 방식 하나를 강화하고 다른 선택과 조합되는 런 유물입니다."
		relic.rarity = &"cursed" if index >= 19 else (&"rare" if index >= 10 else &"common")
		relic.modifiers = [modifiers[index % modifiers.size()]]
		relic.trigger_tags = [&"combat"]
		result.append(relic)
	return result


static func _build_evolutions(modifiers: Array[ModifierDefinition]) -> Array[EvolutionDefinition]:
	var result: Array[EvolutionDefinition] = []
	for class_spec in EVOLUTION_ABILITIES:
		var class_id: StringName = class_spec[0]
		var ability_ids: Array = class_spec[1]
		for ability_index in range(ability_ids.size()):
			var ability_id: StringName = ability_ids[ability_index]
			var group := StringName("evolution.%s.%s" % [String(class_id).trim_prefix("class."), String(ability_id).get_slice(".", 2)])
			for branch in range(2):
				var evolution := EvolutionDefinition.new()
				evolution.id = StringName("%s.%s" % [group, "force" if branch == 0 else "control"])
				evolution.class_id = class_id
				evolution.ability_id = ability_id
				evolution.display_name = "%s · %s" % [String(ability_id).get_slice(".", 2).capitalize(), "강습" if branch == 0 else "변형"]
				evolution.description = "피해 축과 범위·제어 축 중 하나를 선택하는 배타적 진화입니다."
				evolution.exclusive_group = group
				evolution.modifiers = [modifiers[(ability_index * 2 + branch) % modifiers.size()]]
				result.append(evolution)
	return result


static func _build_masteries(modifiers: Array[ModifierDefinition]) -> Array[MasteryDefinition]:
	var result: Array[MasteryDefinition] = []
	var specs := [
		[&"mastery.swordsman.resolve", &"class.swordsman", "결의", [&"perfect_guard", &"multi_hit"], modifiers[8]],
		[&"mastery.archer.focus", &"class.archer", "집중", [&"range_hit", &"moving_hit"], modifiers[10]],
		[&"mastery.mage.resonance", &"class.mage", "공명", [&"distinct_spell"], modifiers[11]],
	]
	for spec in specs:
		var mastery := MasteryDefinition.new()
		mastery.id = spec[0]
		mastery.class_id = spec[1]
		mastery.display_name = spec[2]
		mastery.description = "직업 고유 행동을 반복해 다음 스킬을 자동 강화합니다."
		mastery.threshold = 100.0
		mastery.trigger_tags.assign(spec[3])
		mastery.trigger_modifier = spec[4]
		result.append(mastery)
	return result


static func _build_elite_modifiers() -> Array[EliteModifierDefinition]:
	var names := ["격노", "철갑", "흡혈", "신속", "폭발", "장막", "분열", "서리", "공허", "성가"]
	var result: Array[EliteModifierDefinition] = []
	for index in range(names.size()):
		var modifier := EliteModifierDefinition.new()
		modifier.id = StringName("elite.frontier.%02d" % (index + 1))
		modifier.display_name = names[index]
		modifier.description = "역할을 강화하되 전조 색과 행동 변화로 읽을 수 있는 엘리트 속성입니다."
		modifier.threat_multiplier = 1.2 + 0.05 * float(index % 4)
		result.append(modifier)
	return result


static func _build_quests() -> Array[QuestDefinition]:
	var result: Array[QuestDefinition] = []
	for index in range(20):
		var quest := QuestDefinition.new()
		quest.id = StringName("quest.frontier.%02d" % (index + 1))
		quest.display_name = ["지역 원정", "변경 조사", "직업 숙련", "마을 복구"][index % 4] + " %d" % (index + 1)
		quest.description = "전투·목표·보스 사건을 추적해 새 가능성을 여는 퀘스트입니다."
		quest.objective_ids = [OBJECTIVE_SPECS[index % OBJECTIVE_SPECS.size()][0]]
		if index > 0:
			quest.prerequisite_ids = [StringName("quest.frontier.%02d" % index)]
		if index < REGION_SPECS.size():
			quest.unlock_region_ids = [REGION_SPECS[index][0]]
		result.append(quest)
	return result


static func _build_cosmetics() -> Array[CosmeticDefinition]:
	var result: Array[CosmeticDefinition] = []
	var classes: Array[StringName] = [&"class.swordsman", &"class.archer", &"class.mage"]
	for index in range(20):
		var cosmetic := CosmeticDefinition.new()
		cosmetic.id = StringName("cosmetic.frontier.%02d" % (index + 1))
		cosmetic.display_name = "고딕 원정복 %02d" % (index + 1)
		cosmetic.class_id = classes[index % classes.size()]
		cosmetic.palette = [Color.from_hsv(float(index) / 20.0, 0.45, 0.72), Color("#e6d6bd")]
		if index < 5:
			cosmetic.acquisition = "earned"
			cosmetic.unlock_quest_id = StringName("quest.frontier.%02d" % (index + 1))
		else:
			cosmetic.acquisition = "premium"
			cosmetic.platform_product_id = StringName("arcane.frontier.cosmetic.%02d" % (index - 4))
		result.append(cosmetic)
	return result
