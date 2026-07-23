# 전투·성장 기준선

## 목표 지표

- 일반 적 단독 TTK: 초반 0.8–2.5초, 20웨이브까지 1–4초
- 플레이어가 공격을 모두 허용했을 때 단독 적 TTD: 최소 12초
- 실제 난이도는 HP 배율보다 난이도별 공격권, 지역별 역할 조합, threat budget과 공간으로 만든다.
- 일반 공격을 3회 이상 연속으로 피할 수 없는 상황을 만들지 않는다. 화면 밖 적은 공격권을 받을 수 없다.

## 단위와 공식

- 시간: 초, 거리: logical pixel, 피해/체력: point
- 지역 조우 budget: `4 + 1.5 × (chapter - 1) + 2 × (depth - 1)`, 엘리트는 ×1.4
- 활성 적 상한: 24
- 슬라임 HP: `44 + 7 × wave`, 피해: `7 + 0.65 × wave`
- 고블린 HP: `72 + 9 × wave`, 피해: `11 + 0.8 × wave`
- 망령 HP: `105 + 12 × wave`, 피해: `16 + 1 × wave`
- 레벨업 피해 배율: `base_power × 1.08^(level - 1)`
- 레벨업 HP: 검사 `base + 10 × (level - 1)`, 나머지 `base + 7 × (level - 1)`
- 필요 XP: `floor(75 × 1.28^(level - 1))`
- veteran 피해: 중첩당 ×1.06, 쿨다운: 중첩당 ×0.97(기본의 50% 하한), HP: 중첩당 +8
- 난이도: 개척자 피해 ×0.85/전조 ×1.15, 사냥꾼 기준, 악몽 피해 ×1.15/전조 ×0.85/공격권 4·원거리 2

`progression_config.json`은 검사 기본 베기와 슬라임을 1–20 구간의 기하 성장 근사로 바꾼 비교 시나리오다. 실제 구현은 선형 적 성장과 역할별 attack contract를 사용하므로, 시뮬레이션 결과는 회귀 방향을 보는 기준선이지 다수 전투 플레이테스트를 대체하지 않는다.

```bash
python3 .codex/skills/game-balance/scripts/simulate_progression.py \
  --config docs/progression_config.json --samples 5000 --json
```
