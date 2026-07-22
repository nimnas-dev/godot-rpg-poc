# Balance Method

## 1. Define the balance question

좋은 질문:

- 레벨 10 궁수가 같은 장비 등급의 검사보다 안전한 거리에서 높은 피해까지 가지는가?
- 웨이브 8에서 평균 플레이어의 생존 시간이 전조를 학습할 만큼 긴가?
- 희귀 장비를 얻지 못한 플레이어가 몇 회 안에 다른 방식으로 성장할 수 있는가?

나쁜 질문:

- 게임 밸런스가 맞는가?
- 마법사는 강한가?

대상, 상황, 비교 기준과 관찰 지표를 포함하도록 질문을 좁힌다.

## 2. Build an authoritative sheet

한 행이 무엇인지 정하고 다음을 포함한다.

- stable ID와 표시 이름
- 단위가 있는 원시 값
- 파생 값의 공식
- 적용 조건과 태그
- 데이터 버전
- 마지막 변경 이유

코드, Resource, 문서에 같은 값을 복사하지 않는다. 게임이 사용하는 데이터에서 분석 표를 생성하거나 명시적인 import/export 경로를 둔다.

## 3. Establish anchors

기준점을 먼저 정한다.

- baseline basic attack
- baseline enemy at each progression band
- expected equipment level
- target encounter duration
- target mistakes survivable
- target rewards per minute or per session

새 능력은 기준점 대비 damage, range, safety, area, control, mobility, cost, cooldown의 교환으로 설명한다.

## 4. Analyze relationships

### Transitive progression

상위 등급이나 레벨이 명확히 강해지는 관계다. 비용 곡선과 성장 속도를 제어한다. 이전 콘텐츠가 너무 빨리 무의미해지지 않는지 확인한다.

### Intransitive choice

A가 B에 강하고 B가 C에 강하며 C가 A에 강한 식의 상황적 관계다. 직업, 무기, 원소 또는 enemy counter에 사용한다. 모든 상황에 좋은 선택을 줄이고 적 roster와 encounter가 관계를 실제로 드러내게 한다.

### Orthogonal differentiation

damage만 바꾸지 말고 range, timing, movement, area, control, setup, risk 축을 다르게 만든다. 수치가 비슷해도 플레이 결정이 달라야 한다.

## 5. Run scenario and sensitivity tests

최소 시나리오:

- 신규 플레이어, 평균 플레이어, 숙련 플레이어
- 낮은 장비, 목표 장비, 높은 장비
- 단일 적, 혼합 encounter, boss
- 안정적인 평균과 나쁜 확률 streak
- 최적 build와 직관적인 build

주요 변수는 ±5%, ±10%, ±20% 바꿔 결과 민감도를 본다. 작은 변화로 결과가 붕괴하면 해당 시스템은 튜닝이 불안정하다.

## 6. Playtest behavior, not opinions alone

관찰:

- 무엇을 선택했고 어떤 정보로 결정했는가?
- 같은 행동만 반복한 이유는 무엇인가?
- 실패 원인을 어떻게 설명하는가?
- 보상을 보고 다음 목표가 생기는가?
- 쉬워도 지루했는가, 어려워도 공정했는가?

플레이어의 수정 제안은 문제 신호로 받아들이되 그대로 구현할 필요는 없다. 실제 행동과 원인을 함께 분석한다.

## 7. Patch safely

- 한 패치의 목표를 제한한다.
- 바뀐 공식과 콘텐츠 범위를 기록한다.
- 저장 데이터와 이미 생성된 아이템에 미치는 영향을 확인한다.
- 극단 build와 이전 boss를 회귀 테스트한다.
- 성공 기준과 되돌릴 조건을 배포 전에 정한다.
