---
name: build-rpg-system
description: Godot 4에서 재미있고 확장 가능한 RPG의 캐릭터 능력치, 직업, 스킬, 전투 효과, 경험치, 레벨, 장비, 인벤토리, 전리품, 퀘스트와 저장 시스템을 데이터 중심으로 설계·구현한다. 새로운 RPG 기능 구축, 기존 하드코딩 데이터의 Resource 전환, 전투-보상-성장 연결, 빌드 선택과 아이템 시너지 설계, 저장 가능한 progression 구현에 사용한다.
---

# Build RPG System

전투, 보상, 성장이 서로를 강화하는 RPG 시스템을 만든다. 시스템 수보다 플레이어가 이해하고 계획하고 표현할 수 있는 선택을 우선한다.

## 작업 절차

1. 게임 fantasy와 RPG 핵심 동사를 정의한다. 예: `탐험한다`, `싸운다`, `획득한다`, `빌드를 바꾼다`.
2. `fight -> reward -> choose -> become capable of new play`의 vertical slice를 먼저 설계한다.
3. 필요한 시스템과 각 authoritative owner를 분리한다.
4. definition data, runtime state, presentation을 구분한다.
5. stable ID와 typed custom Resource schema를 만든다.
6. 한 직업, 소수 스킬, 아이템, 적으로 end-to-end slice를 구현한다.
7. 저장·불러오기와 데이터 버전 변경을 slice 단계에서 검증한다.
8. 새 콘텐츠를 코드 수정 없이 추가할 수 있는지 확인한 뒤 범위를 확장한다.
9. `game-balance`, `game-feel`, `build-rpg-enemy`, `build-rpg-world`와 교차 검증한다.

## 재미를 만드는 시스템 원칙

- 보상은 숫자만 키우지 말고 새로운 행동, synergy 또는 tradeoff를 연다.
- 플레이어가 다음 목표와 획득 경로를 이해할 수 있게 한다.
- random reward와 deterministic progress를 함께 제공한다.
- 직업 정체성은 강점뿐 아니라 플레이를 바꾸는 제약과 약점으로 만든다.
- 스킬은 damage, range, timing, movement, control, cost 중 여러 축에서 구분한다.
- 장비 선택에는 공격력 하나로 환산되지 않는 상황적 가치가 있어야 한다.
- 실패 후 다른 빌드, 강화, 연습, 경로 선택 같은 회복 수단을 제공한다.
- 여러 progression layer가 같은 역할을 중복하지 않게 한다.

## 시스템 경계

기본 경계와 책임은 [system-blueprints.md](references/system-blueprints.md)를 읽는다.

- Definition registry: class, skill, item, enemy, quest 정의를 ID로 제공
- Actor state: 현재 HP, resource, cooldown, status, equipment-derived stats
- Effect resolution: damage, healing, status, movement effect를 일관되게 처리
- Inventory/equipment: 소유, stack, slot, equip transaction
- Progression: XP, level, unlock과 milestone
- Reward: loot table, quest reward, deterministic fallback
- Quest/world state: 조건, 진행, 완료와 world consequences
- Save system: schema version, migration, atomic persistence
- Presentation: 위 상태를 관찰하지만 규칙의 owner가 되지 않음

## Godot 데이터 규칙

- Inspector에서 편집할 definition은 custom Resource로 만든다.
- Resource에는 stable ID, 표시 데이터, 규칙 파라미터와 다른 definition 참조를 둔다.
- 현재 HP, 수량, cooldown 같은 세션 상태를 공유 Resource에 저장하지 않는다.
- Dictionary는 동적 payload나 serialization boundary에 제한하고 핵심 도메인에는 typed object를 사용한다.
- UI 문자열과 아이콘을 domain calculation에서 분리하되 definition에서 함께 참조할 수 있게 한다.
- save에는 전체 Resource를 직렬화하지 말고 ID와 runtime state를 저장한다.
- schema version과 migration을 첫 저장 버전부터 둔다.

추천 schema는 [data-schemas.md](references/data-schemas.md)를 읽는다.

## 구현 순서

1. IDs and definitions
2. stat calculation and modifier order
3. ability command and effect resolution
4. reward grant transaction
5. inventory and equipment transaction
6. progression milestones
7. save snapshot and load reconstruction
8. UI observation and feedback
9. content validation and balancing export

각 단계에 headless 또는 작은 test scene을 만든다. 전체 Main scene만으로 검증하지 않는다.

## 완료 조건

- 새 직업·스킬·아이템을 기존 resolver 수정 없이 데이터와 작은 전용 effect로 추가할 수 있다.
- 장비 교체와 status 만료 후 derived stats가 정확히 복원된다.
- reward transaction이 중복 지급되지 않는다.
- 저장 후 재시작해 inventory, equipment, progression, quest state가 동일하다.
- 없는 content ID와 오래된 save version이 안전하게 처리된다.
- 플레이어에게 다음 성장 목표와 선택 결과가 명확하다.

연구 근거는 [sources.md](references/sources.md)를 읽는다.

## 금지 사항

- `player.gd` 하나에 전투, 인벤토리, UI, 저장, 퀘스트를 모두 넣지 않는다.
- 직업별 거대한 `match` 문을 장기 확장 구조로 사용하지 않는다.
- 표시 이름을 save key 또는 도메인 ID로 쓰지 않는다.
- 장비를 해제할 때 기존 수치를 역산해 빼는 방식에 의존하지 않는다. authoritative sources에서 다시 계산한다.
- 무작위 드롭만으로 필수 progression을 막지 않는다.
- 저장 실패 중 기존 정상 save를 먼저 덮어쓰지 않는다.
