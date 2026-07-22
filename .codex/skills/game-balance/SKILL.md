---
name: game-balance
description: 게임의 전투, 직업, 스킬, 적, 성장 곡선, 보상, 드롭률과 자원 경제를 수학 모델·시뮬레이션·플레이테스트로 조정한다. 직업 간 강약 비교, TTK·난이도·경험치 곡선 설계, 장비·스킬 비용 책정, 드롭 테이블 검증, 지배 전략이나 진행 막힘 진단, 밸런스 패치 영향 분석 작업에 사용한다.
---

# Game Balance

밸런스를 모든 선택의 동일한 승률로 정의하지 않는다. 목표 경험에 맞는 유효한 선택, 이해 가능한 위험·보상, 의도된 진행 속도를 만들고 실제 데이터로 검증한다.

## 작업 절차

1. 밸런스 대상, 플레이 모드, 대상 플레이어와 목표 감정을 정의한다.
2. 변경 가능한 변수와 관찰할 결과 지표를 분리한다.
3. 현재 수치를 단일 표 또는 데이터 파일로 추출하고 단위와 공식을 명시한다.
4. 기준 캐릭터, 기준 적, 기준 encounter를 정해 anchor 값을 만든다.
5. 기대값 모델로 큰 오류와 성장 곡선을 확인한다.
6. 확률·조합·플레이 스타일 차이는 시뮬레이션과 민감도 분석으로 확인한다.
7. 극단값, 신규·숙련 플레이어, 낮은·높은 장비 상태를 시나리오별로 비교한다.
8. 실제 플레이에서 선택 행동, 실패 원인, 피로도, 이해도를 관찰한다.
9. 한 번에 제한된 변수만 조정하고 변경 이유와 회귀 범위를 기록한다.

## 먼저 정할 목표

- 전투: time-to-kill, time-to-danger, hits-to-kill, resource uptime, decision frequency
- 직업: 강점이 나타나는 상황, 약점, mastery ceiling, 팀 또는 solo 역할
- 성장: milestone 도달 시간, power gain, 새 선택지의 빈도
- 경제: source, sink, stockpile, conversion, scarcity, recovery route
- 드롭: 유효 보상 빈도, 중복 가치, bad-luck 상한, target farming 가능성
- 난이도: 실수 허용량, 읽기 시간, 전략 요구, 회복 가능성

공식과 RPG 지표는 [rpg-math.md](references/rpg-math.md)를 읽는다.

## 모델링 원칙

- 모든 수치에 단위와 시간축을 붙인다. `damage/hit`, `attacks/sec`, `gold/run`을 혼합하지 않는다.
- 평균뿐 아니라 분포, 최악 구간, percentile과 streak를 확인한다.
- 플레이어 수행 능력과 캐릭터 수치 성장을 별도 축으로 본다.
- 직업 간 동일 피해보다 상황별 tradeoff와 counterplay를 설계한다.
- 성장률이 여러 시스템에서 곱해지는 경우 복합 증가를 계산한다.
- 확률 보상에는 획득 조건의 player agency와 실패 후 회복 경로를 둔다.
- 난이도를 체력과 피해만 늘려 만들지 않는다. 구성, 타이밍, 공간, 목표를 바꾼다.

## 시뮬레이션 사용

초기 전투 성장 곡선은 다음으로 점검한다.

```bash
python3 scripts/simulate_progression.py
python3 scripts/simulate_progression.py --config path/to/balance.json --samples 5000
python3 scripts/simulate_progression.py --config path/to/balance.json --json
```

이 스크립트는 기대 DPS, TTK, TTD와 확률적 전투 분포를 비교하는 출발점이다. 실제 이동, cooldown, 범위, 군중 제어와 플레이어 판단을 대체하지 않는다.

## 밸런스 보고서

다음을 포함한다.

- 문제와 플레이어에게 나타나는 증상
- 목표 지표와 허용 범위
- 현재 데이터와 공식
- 비교한 시나리오 및 가정
- 기대값·분포·민감도 결과
- 제안 변경과 예상 부작용
- 플레이테스트 계획 및 rollback 조건

반복 튜닝 절차는 [balance-method.md](references/balance-method.md)를 읽고, 근거 자료는 [sources.md](references/sources.md)를 읽는다.

## 금지 사항

- 하나의 평균 DPS 값만으로 직업을 평가하지 않는다.
- 표본이 작은 승률을 원인 분석 없이 즉시 패치하지 않는다.
- 모든 적이 플레이어와 함께 자동 비례 성장하게 만들지 않는다.
- 확률 보상을 장기 기대값만으로 정당화하지 않는다.
- 지배 전략을 약화하기 전에 다른 선택이 사용되지 않는 이유를 조사한다.
- 스프레드시트 결과를 재미의 증거로 취급하지 않는다.
