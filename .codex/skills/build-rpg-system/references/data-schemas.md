# RPG Data Schemas for Godot

실제 필드는 게임 요구에 맞춰 줄이거나 확장한다. 모든 schema를 처음부터 만들지 않는다.

## Identity rules

- ID는 lowercase namespaced `StringName`을 권장한다: `class.swordsman`, `skill.swordsman.cleave`.
- 표시 이름, 번역 key와 ID를 분리한다.
- 출시 후 ID를 변경하면 migration alias를 유지한다.
- 다른 definition은 raw path보다 typed Resource reference 또는 stable ID로 연결한다.

## CharacterClassDefinition

| Field | Type | Purpose |
|---|---|---|
| id | StringName | stable identity |
| display_name_key | StringName | localization |
| base_stats | StatBlock Resource | starting values |
| starting_abilities | Array[AbilityDefinition] | initial verbs |
| progression | ProgressionDefinition | milestones |
| equipment_rules | EquipmentRuleSet | allowed slots/types |
| presentation | CharacterPresentation | icons, scene, colors |

## AbilityDefinition

| Field | Type | Purpose |
|---|---|---|
| id | StringName | stable identity |
| tags | Array[StringName] | filtering and synergy |
| cooldown | float | seconds |
| costs | Array[ResourceCost] | mana/stamina/etc. |
| targeting | TargetingDefinition | range, shape, allegiance |
| cast_timing | CastTiming | anticipation/active/recovery |
| effects | Array[EffectDefinition] | ordered resolution payloads |
| presentation | AbilityPresentation | icon, animation, VFX, SFX refs |

Do not let presentation timing silently define authoritative hit timing. Store or expose the relationship explicitly.

## EffectDefinition

Common fields:

- effect type or typed subclass
- magnitude/scaling formula reference
- damage/heal element
- tags and required/blocked target tags
- duration and stacking rule
- application timing
- proc chance with deterministic/random policy

Prefer typed effect subclasses when fields differ materially. Avoid one universal effect with dozens of unused fields.

## ItemDefinition and ItemInstance

Definition:

- id, category, tags, rarity policy
- equip slot and requirements
- fixed modifiers and possible affix pools
- maximum stack and sell/conversion value
- presentation references

Instance state:

- unique instance ID when non-stackable
- definition ID
- rolled affix IDs and values
- upgrade/durability state if used
- bound/locked flags

## EnemyDefinition

- id and role tags
- base stat profile and level scaling policy
- behavior/attack loadout definitions
- sensing and navigation parameters
- reward table ID
- presentation scene and feedback profiles

AI state belongs to the runtime enemy, not this shared definition.

## LootTableDefinition

- id
- eligible entry list
- weight and conditions per entry
- roll count/rules
- level and context filters
- pity/fallback policy
- duplicate conversion policy

Weights are relative, not percentages, unless the schema names them as explicit probabilities.

## Save schema

Use plain serializable values at the boundary:

```json
{
  "schema_version": 1,
  "profile_id": "local-1",
  "player": {
    "class_id": "class.swordsman",
    "level": 8,
    "experience": 420
  },
  "inventory": [],
  "equipment": {},
  "quests": {},
  "world": {}
}
```

Validate types, required keys, numeric ranges and referenced IDs before constructing runtime objects.

## Content validation

Check automatically where possible:

- duplicate or empty IDs;
- missing referenced definition;
- negative cooldown, costs or weights;
- invalid slot and category combination;
- unreachable progression milestone;
- loot table with no eligible result;
- cyclic prerequisites;
- save ID without definition or migration alias.
