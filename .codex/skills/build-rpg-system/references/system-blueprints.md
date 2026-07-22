# RPG System Blueprints

## Fight, reward, choose, grow

RPG 시스템의 최소 완성 경로:

```text
player command
  -> ability validates cost/cooldown/state
  -> effects resolve against targets
  -> combat outcome emits domain event
  -> reward service grants transaction
  -> inventory/progression state changes
  -> player makes a build choice
  -> next combat decisions change
```

마지막 단계가 이전과 같은 행동의 숫자만 커지게 한다면 성장 선택을 다시 검토한다.

## Stat pipeline

한 곳에서 고정된 순서로 계산한다.

```text
base definition
-> permanent progression additions
-> equipment additions
-> additive temporary modifiers
-> multiplicative modifiers
-> derived stats
-> final clamps and rules
```

- modifier는 source ID, target stat, operation, value, duration/condition을 가진다.
- 장비 변경 시 현재 결과에 더하고 빼지 말고 source 목록에서 다시 계산한다.
- UI는 같은 calculation result를 읽어 preview와 실제 값이 다르지 않게 한다.
- percentage가 어느 단계에 적용되는지 명시한다.

## Ability pipeline

1. command received
2. actor and target state validation
3. cost and cooldown reservation
4. cast/animation starts
5. effect payload resolves at authored timing
6. result events publish
7. recovery and next command window opens

Ability definition과 effect implementation을 분리한다. 공통 effect는 damage, heal, status, spawn projectile, move, area query처럼 조합한다. 특수 보스나 직업 규칙은 extension point로 둔다.

취소 시 cost, cooldown, partial effect가 어떻게 처리되는지 transaction 규칙을 정한다.

## Inventory and equipment

분리할 개념:

- item definition: 모든 동일 아이템이 공유하는 데이터
- item instance: rolled affix, durability, unique seed 등 개별 상태
- stack: 동일 조건의 수량
- inventory: container와 capacity 규칙
- equipment: typed slot과 현재 instance references

Equip transaction:

```text
validate ownership and slot
-> preview consequences
-> remove previous equipment source
-> add new equipment source
-> recalculate derived stats
-> emit one committed change event
-> persist at safe boundary
```

실패 시 중간 상태를 남기지 않는다.

## Progression

Progression milestone은 다음 중 하나 이상을 제공한다.

- 새 동사 또는 스킬
- 기존 동사의 변형
- 새로운 synergy 가능성
- 새로운 world access
- 플레이 스타일 expression
- 어려운 encounter를 감당할 power

XP bar만 길어지는 dead level을 최소화한다. 플레이어 skill growth와 character power growth를 함께 고려한다.

## Reward and loot

Reward grant는 source event의 unique transaction ID를 받아 중복 처리를 막는다.

Loot table 단계 예시:

1. drop opportunity 판단
2. category/rarity 선택
3. level and eligibility filter
4. base item 선택
5. affix roll
6. smart weighting or target rule
7. pity/fallback update
8. inventory grant or world drop

플레이어가 원하는 보상을 추적할 수 있는 정보를 제공한다. 필수 build 요소에는 deterministic route를 고려한다.

## Quest and world state

Quest는 presentation text가 아니라 조건과 결과의 state machine이다.

- stable quest ID
- state: locked, available, active, completed, failed
- objectives with explicit event filters
- prerequisites
- rewards
- world state consequences
- repeatability and reset policy

전역 event를 무차별 수신해 모든 quest를 매번 순회하지 않게 index 또는 active set을 사용한다.

## Save boundary

저장할 것:

- schema version and build/content version
- profile and settings
- stable content IDs
- player runtime state
- inventory instances and equipment references
- progression, quest and world flags
- deterministic random state only where required

저장하지 않을 것:

- scene Node references
- transient effects, tweens and cached derived values
- 전체 definition Resource 복제
- 다시 계산할 수 있는 presentation state

임시 파일에 쓰고 검증한 뒤 교체하는 atomic strategy를 사용한다. migration은 원본을 보존한 복사본에서 수행한다.
