# Enemy Design

## Start with a question

적이 요구하는 player response를 한 문장으로 쓴다.

- 돌진병: 계속 같은 위치에 머물 것인가?
- 방패병: 정면 공격만 반복할 것인가?
- 치유사: 현재 target을 유지할 것인가?
- 포격수: 안전 지대와 공격 기회 중 어디로 이동할 것인가?
- 소환사: 약한 add와 본체 중 무엇을 우선할 것인가?

질문에 플레이어가 실제로 사용할 수 있는 답이 둘 이상 있어야 한다.

## Orthogonal roster matrix

다음 축에서 roster를 배치한다.

- closes distance <-> maintains distance
- projectile <-> contact/area
- pressure <-> support/control
- fragile priority <-> durable anchor
- predictable rhythm <-> conditional reaction
- stationary territory <-> mobile pursuit

모든 축이 필요하지 않다. 비슷한 위치의 적이 많으면 encounter 조합이 달라도 같은 판단을 요구할 가능성이 높다.

## Attack contract

각 공격을 표로 정의한다.

| Field | Meaning |
|---|---|
| trigger | 어떤 상태와 거리에서 고려하는가 |
| anticipation | 사전 pose, VFX, sound와 시간 |
| commitment | 이동/회전이 제한되기 시작하는 시점 |
| tracking | target 보정 방식과 lock 시점 |
| active | 실제 판정 시간과 shape |
| consequence | damage, status, displacement |
| recovery | 안전한 반격 기회 |
| interrupt | 무엇으로 중단 가능한가 |
| counterplay | dodge, block, spacing, priority 등 |

실제 collision shape와 표시된 위험 영역을 일치시킨다. 난이도별 anticipation 조정은 사람이 인지할 수 있는 범위를 유지한다.

## State model

단순한 상태로 시작한다.

```text
SPAWN
  -> IDLE/PATROL
  -> ALERT/CHASE
  -> POSITION
  -> ATTACK_ANTICIPATION
  -> ATTACK_ACTIVE
  -> RECOVER
  -> POSITION
any valid state -> STAGGER or DEAD
```

상태가 아니라 attack selection만 달라질 경우 상태를 늘리지 말고 data-driven attack chooser를 사용한다. 상태 전이에는 reason을 기록할 수 있게 해 디버깅한다.

## Decision model

가장 단순한 충분한 모델을 선택한다.

- deterministic state machine: 읽기 쉽고 명확한 패턴
- weighted selector: 제한된 변주
- utility scoring: 거리, 위험, cooldown에 따른 상황적 선택
- behavior tree: 복합 순서와 병렬 조건이 실제로 필요할 때
- GOAP: 재계획 가능한 목표와 action 조합이 핵심 재미일 때

어떤 모델도 플레이어에게 보이지 않는 복잡성 자체로 재미를 만들지 않는다.

## Fairness rules

- 카메라 밖 적은 강한 공격을 제한하거나 distinct audio warning을 제공한다.
- spawn 직후 즉시 공격하지 않는다.
- crowd control 연속 적용에 diminishing return 또는 immunity window를 고려한다.
- 공격 토큰이나 director로 동시 공격 강도를 제한한다.
- ranged accuracy는 player movement와 난이도에 맞춰 의도적으로 설계한다.
- 적이 길을 잃거나 target에 도달할 수 없을 때 timeout/reposition fallback을 둔다.

## Difficulty dimensions

난이도별로 바꿀 수 있는 것:

- 더 복합적인 enemy composition
- attack selection 다양성
- positioning과 flanking 빈도
- reaction window의 제한적 감소
- resource pressure
- recovery opportunity 빈도

HP와 damage scaling은 encounter 길이와 실수 허용량을 조절하는 보조 수단으로 사용한다.

## Presentation identity

- silhouette로 역할을 읽게 한다.
- locomotion speed와 animation cadence를 실제 위협에 맞춘다.
- 공격마다 anticipation sound와 impact sound를 구분한다.
- element는 색 외에도 모양, motion, sound로 전달한다.
- elite modifier는 UI icon만이 아니라 행동에서 드러나게 한다.
