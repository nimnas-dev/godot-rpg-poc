---
name: build-rpg-enemy
description: 플레이어에게 읽을 수 있는 문제와 재미있는 대응 선택을 제공하는 RPG 적, 몬스터, AI 상태, 공격 패턴, 전조, 역할 조합, encounter, 엘리트와 보스를 설계하고 Godot 4로 구현한다. 새로운 적 제작, 단조로운 추적 AI 개선, 공격 공정성·전조 조정, enemy roster 구성, wave·boss encounter 설계, NavigationAgent2D 성능 점검에 사용한다.
---

# Build RPG Enemy

가장 영리한 AI가 아니라 플레이어에게 명확하고 서로 다른 문제를 만드는 적을 만든다. 적의 행동은 플레이어의 이동, 공격, 방어, target priority와 resource 선택을 바꿔야 한다.

## 작업 절차

1. 플레이어의 핵심 동사, 회피 수단, 사거리와 읽기 속도를 확인한다.
2. 새 적이 플레이어에게 던질 한 가지 핵심 질문을 정의한다.
3. 기존 roster에서 겹치지 않는 역할 축과 silhouette를 선택한다.
4. `perceive -> decide -> telegraph -> act -> recover` 상태 흐름을 작성한다.
5. 공격별 range, timing, tracking, damage, interrupt, counterplay를 표로 만든다.
6. 회색 상자와 최소 효과로 1대1 prototype을 검증한다.
7. 2~4개 역할을 섞은 encounter에서 target priority와 공간 이동을 검증한다.
8. 난이도, 카메라 밖, 다수 공격, navigation 실패와 모바일 성능을 점검한다.
9. reward, world placement, audio/visual identity를 연결한다.

## 적 설계 원칙

- 적 하나는 하나의 읽을 수 있는 핵심 역할을 먼저 가진다.
- 외형, 이동, 소리, 전조가 같은 역할을 일관되게 전달한다.
- 피할 수 있는 피해에는 인지하고 반응할 시간이 있어야 한다.
- 공격은 anticipation, commitment, active, recovery를 가진다.
- tracking과 방향 보정은 전조 후 언제 잠기는지 명확해야 한다.
- AI는 완벽한 정보나 정확도를 사용하지 않고 의도된 player fantasy를 지원한다.
- 다수 전투는 attack permission, spacing, cooldown coordination으로 공정성을 관리한다.
- 난이도 상승은 가능한 한 새 조합과 요구 판단을 만들고 단순 수치 상승에 머물지 않는다.
- 적 사망과 reward는 encounter loop를 닫고 다음 선택으로 연결한다.

적 역할, 공격과 AI 구조는 [enemy-design.md](references/enemy-design.md)를 읽는다.

## Godot 구현 규칙

- 공유 수치는 `EnemyDefinition` Resource, 개체별 상태는 enemy scene instance에 둔다.
- AI decision, locomotion, attack execution, health/effects, presentation을 분리한다.
- 상태 전이는 하나의 owner가 결정하고 진입·퇴장 시 timer와 animation을 정리한다.
- NavigationAgent2D는 경로를 제공하며 실제 movement는 parent actor가 수행한다.
- 모든 적이 매 physics frame에 새 target과 path를 계산하지 않게 한다.
- `AnimationPlayer` 또는 animation event와 authoritative hit timing의 관계를 명시한다.
- 공격 판정은 collision layer/mask와 대상 allegiance를 분명히 한다.
- pooled enemy를 사용한다면 signal, status, path, target, collision과 reward flags를 완전히 reset한다.

## Encounter와 보스

적은 단독보다 조합에서 깊이를 만든다. 역할 조합, 위협 예산, pacing, boss phase는 [encounter-design.md](references/encounter-design.md)를 읽는다.

보스는 다음을 충족한다.

- 일반 전투에서 학습한 규칙을 시험하거나 명확히 확장한다.
- phase 변화가 단순 HP 증가가 아니라 새로운 decision 또는 공간 변화를 만든다.
- 큰 공격은 충분한 전조, 일관된 회피 규칙, 명확한 recovery를 갖는다.
- 실패 원인을 플레이어가 설명할 수 있다.
- 반복 시 intro와 재도전 friction을 줄인다.

## 완료 산출물

- enemy question과 combat role
- roster differentiation matrix
- state graph와 attack table
- counterplay, failure condition, difficulty modifiers
- encounter 조합과 threat budget
- navigation 및 최대 동시 개체 성능 조건
- 1대1, 혼합 encounter, boss regression tests

근거 자료는 [sources.md](references/sources.md)를 읽는다.

## 금지 사항

- 기존 적의 HP, 속도, 색만 바꿔 새 적으로 취급하지 않는다.
- 보이지 않는 적이 강한 공격을 사전 신호 없이 실행하지 않는다.
- 여러 적이 같은 순간에 회피 불가능한 공격을 겹치게 두지 않는다.
- 복잡한 behavior tree나 GOAP를 적의 재미보다 먼저 선택하지 않는다.
- player input을 읽어 즉시 counter하는 방식으로 가짜 난이도를 만들지 않는다.
- boss를 큰 체력과 연속 광역 공격만 가진 적으로 만들지 않는다.
