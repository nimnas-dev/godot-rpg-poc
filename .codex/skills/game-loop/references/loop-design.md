# Gameplay Loop Design

## Loop canvas

각 loop를 다음 표로 정의한다.

| Field | Question |
|---|---|
| Fantasy | 플레이어는 어떤 존재가 된 느낌을 원하는가? |
| Observation | 결정을 위해 무엇을 읽는가? |
| Decision | 실제 tradeoff가 있는 선택은 무엇인가? |
| Action | 어떤 입력과 게임 동사가 실행되는가? |
| Feedback | 결과를 언제, 어떻게 이해하는가? |
| Consequence | 자원, 위치, 위험, 세계가 어떻게 변하는가? |
| Reward | 다음 선택을 어떻게 확장하는가? |
| Variation | 반복 시 무엇이 달라지는가? |
| Mastery | 어떤 지식이나 수행 능력이 자라는가? |
| Exit | 언제 완료·실패·중단되는가? |

## Time horizons for an action RPG

### Moment-to-moment: seconds

```text
read enemy -> position -> choose attack/skill -> resolve hit -> adapt
```

변화 요소: enemy tell, cooldown, spacing, resource, status, terrain.

### Encounter: minutes

```text
enter threat -> identify composition -> prioritize -> survive escalation -> collect result
```

변화 요소: enemy roles, wave composition, arena shape, objective, attrition.

### Session or run: tens of minutes

```text
choose goal/build -> explore/fight -> acquire options -> face milestone -> cash out or fail -> review
```

변화 요소: route, build synergy, risk/reward branch, optional challenge, boss.

### Meta: hours

```text
set long-term goal -> complete sessions -> unlock possibility -> revise build/strategy -> attempt harder content
```

Meta reward should add decisions or expression, not only increase numbers. Permanent power must not erase the need to learn the core game unless that is the intended audience experience.

## Loop alignment

Check that each layer feeds the next:

- combat reward affects a build choice;
- build choice changes future combat decisions;
- exploration reveals encounter or progression opportunities;
- session results clarify a new goal;
- failure yields actionable information rather than only lost time.

If a reward skips the core action, verify that it does not teach players to avoid the game's strongest experience.

## Teach, test, twist

For a new mechanic or enemy:

1. Teach it in a low-pressure context with clear feedback.
2. Test it with one meaningful complication.
3. Twist it by combining it with known elements or changing context.
4. Rest or reward before introducing another high-load concept.

Do not confuse explanation text with teaching. Let the player perform and observe the rule.

## Failure loop

Design the complete failure experience:

```text
warning -> failure cause -> clear result -> retained/lost state -> restart choice -> return to agency
```

Measure time from failure to meaningful control. Preserve drama for important failures, but remove repeated friction during mastery attempts.

## Loop audit questions

- What decision repeats most often?
- Is there ever one dominant answer regardless of context?
- Does the reward open a choice or merely fill a meter?
- When does the player first experience the core fantasy?
- Where can repetition become execution without thought?
- What causes tension, relief, surprise and anticipation?
- Can a session end at a natural boundary without punishment?
