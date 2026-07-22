# Encounter Design

## Compose combat chess

각 enemy role이 다른 player decision을 요구하게 조합한다.

예시:

- anchor + artillery: 근접 압박을 피하면서 원거리 우선순위를 판단
- swarmer + support: 다수 처리와 치유사 interruption 선택
- charger + zone controller: 이동 경로와 안전 지대 변화
- shield + flanker: 방향과 위치 전환 요구

같은 질문을 던지는 적을 많이 배치하는 것은 난이도는 올려도 깊이를 늘리지 못한다.

## Threat budget

각 적에게 고정된 절대 점수보다 상황별 위협 비용을 준다.

```text
effective threat = base role cost
                 * arena synergy
                 * composition synergy
                 * objective pressure
                 * player build counter factor
```

좁은 arena의 area denial 적, escort objective의 fast diver처럼 맥락에 따라 비용이 달라진다.

예산에는 다음 상한을 별도로 둔다.

- simultaneous attackers
- hard crowd control
- off-screen ranged threats
- persistent area coverage
- expensive AI/navigation/VFX actors

## Encounter pacing

```text
read space -> first contact -> escalation -> complication -> resolution -> recovery/reward
```

- 첫 순간에 모든 역할을 동시에 숨기지 않는다.
- 새 enemy는 안전한 문맥에서 단독 또는 단순 조합으로 소개한다.
- wave는 단지 수를 늘리지 말고 priority와 movement 요구를 바꾼다.
- combat 뒤에는 loot, route choice, story beat 또는 휴식으로 intensity를 낮춘다.

## Arena relationship

검토할 요소:

- 입구에서 보이는 위협과 safe observation area
- 근접과 원거리 모두 사용할 공간
- obstacle이 projectile, dash, navigation에 미치는 영향
- 막다른 곳, escape route, kiting loop
- objective와 spawn 위치
- 카메라가 telegraph를 볼 수 있는 범위

Arena와 enemy를 독립적으로 밸런싱하지 않는다.

## Boss phases

각 phase를 별도 문제로 정의한다.

| Phase | Learned rule | New pressure | Player adaptation | Failure lesson |
|---|---|---|---|---|

좋은 phase transition:

- 명확한 health/event threshold
- 잠깐의 읽기와 재배치 시간
- 새로운 pattern을 시각·음향으로 소개
- 이전에 학습한 pattern과 조합
- transition 중 피해 가능 여부가 명확함

Boss adds는 화면을 채우기 위한 것이 아니라 resource, positioning, priority 역할을 가져야 한다.

## Test matrix

- 각 직업과 대표 build
- 처음 보는 플레이어와 패턴을 아는 플레이어
- 최소/목표/최대 장비
- camera edge와 좁은 arena
- low frame rate와 touch input
- 한 enemy의 navigation failure
- 겹친 telegraph와 audio saturation
- phase transition 직전의 stun, burst, death
