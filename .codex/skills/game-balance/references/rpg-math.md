# Practical RPG Math

## Expected damage

기본 기대 피해:

```text
expected_damage_per_attempt = base_damage * accuracy * (1 + crit_chance * (crit_multiplier - 1))
expected_dps = expected_damage_per_attempt * attacks_per_second * uptime
```

`uptime`은 이동, 회피, 사거리, animation lock과 실제 공격 기회를 반영한다. ranged와 melee를 비교할 때 uptime 차이를 무시하지 않는다.

## Defense models

### Subtractive

```text
damage = max(minimum_damage, raw_damage - defense)
```

이해하기 쉽지만 빠른 약공격을 과도하게 벌하고 면역 구간을 만들기 쉽다.

### Ratio mitigation

```text
damage = raw_damage * K / (K + defense)
mitigation = defense / (K + defense)
```

`K`는 방어 효율의 기준점이다. diminishing return이 있지만 표시 방식과 level scaling을 설명해야 한다. 어느 공식도 자동으로 좋은 것은 아니다.

## Time metrics

```text
TTK = effective_enemy_health / effective_player_dps
TTD = effective_player_health / effective_enemy_dps
safety_ratio = TTD / TTK
```

보스의 phase, 무적, 이동, add spawn은 effective health와 uptime으로 모델링하거나 구간별로 나눈다. TTK와 함께 hits-to-kill을 확인해야 타격별 체감과 실수 허용량을 알 수 있다.

## Cooldown skill value

```text
cycle_damage = basic_dps * free_time + sum(skill_damage)
cycle_time = chosen_rotation_period
rotation_dps = cycle_damage / cycle_time
```

다음도 비용으로 포함한다.

- cast and recovery time
- resource cost and regeneration delay
- miss or interruption risk
- positional requirement
- lost basic attacks

Area damage는 최대 target 수가 아니라 실제 encounter의 target distribution으로 평가한다.

## Growth curves

### Linear

```text
value(level) = base + growth * (level - 1)
```

예측하기 쉽고 작은 범위에 적합하다.

### Exponential

```text
value(level) = base * rate^(level - 1)
```

장기적으로 매우 빠르게 벌어진다. 플레이어와 적의 rate가 조금만 달라도 TTK가 크게 변한다.

### Piecewise

구간별 목표를 정해 early, mid, late curve를 다르게 만든다. 능력 해금과 장비 tier 같은 실제 milestone을 표현하기 쉽다. 연결 지점의 power spike를 검사한다.

## Experience pacing

```text
time_to_level = xp_required / expected_xp_per_minute
```

평균만 보지 말고 콘텐츠 선택별 XP, 실패 시 XP, 이동·정비 시간을 포함한다. 레벨업 간격은 수치 상승뿐 아니라 새 능력과 학습 속도에 맞춘다.

## Loot

기대 시도 횟수는 독립 확률 `p`에서 `1/p`지만, 이는 보장 시간이 아니다. 연속 실패 확률:

```text
P(no drop after n attempts) = (1 - p)^n
```

확률 보상은 다음을 함께 설계한다.

- target source visibility
- bad-luck protection or deterministic alternative
- duplicate conversion value
- inventory and comparison cost
- useful-drop probability, not merely any-drop probability

## Economy flow

각 자원을 source, pool, converter, trader, gate, sink로 모델링한다.

```text
net_change_per_session = sources - sinks
sessions_to_goal = required_stock / net_change_per_session
```

stockpile percentile과 신규·숙련 player behavior를 분리한다. sink가 단순 세금인지, 실제 선택과 expression을 만드는지 검토한다.
