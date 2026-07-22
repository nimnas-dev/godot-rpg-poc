---
name: game-loop
description: 게임의 순간 행동 반복, 전투·탐험 core loop, 세션과 성장 meta loop, 그리고 부팅·타이틀·플레이·일시정지·게임오버·재시작 같은 application state flow를 설계하고 구현한다. 게임 흐름 신규 설계, 플레이 목적이 불명확한 프로토타입 개선, 상태 전환 버그 제거, restart·pause·scene transition 구성, 보상과 난이도 페이싱 검토에 사용한다.
---

# Game Loop

플레이어가 반복하는 행동과 애플리케이션이 전환하는 상태를 분리해서 설계한다. 반복 횟수보다 선택, 피드백, 학습, 변화가 지속되는지를 우선한다.

## 먼저 구분할 것

- Engine loop: 입력, update, physics, render의 프레임 실행 구조. Godot가 제공한다.
- Gameplay loop: 플레이어가 관찰하고 결정하고 행동하고 결과를 받는 반복.
- Session loop: 한 번의 run, stage, quest 또는 플레이 세션의 시작과 종료.
- Meta loop: 여러 세션에 걸친 성장, 해금, 빌드 변화와 장기 목표.
- Application flow: boot, title, loading, playing, paused, results, game over 등의 상태 전이.

한 문서나 클래스에 이 다섯 의미를 혼합하지 않는다.

## 설계 절차

1. 목표 경험과 플레이어 fantasy를 한 문장으로 정의한다.
2. 플레이어가 가장 자주 내릴 의미 있는 결정을 찾는다.
3. `observe -> decide -> act -> feedback -> consequence`로 core loop를 작성한다.
4. 순간, encounter, session, meta 시간축에 반복 구조를 배치한다.
5. 각 반복에서 새로 배우거나 선택하거나 획득하는 변화를 정의한다.
6. application state와 허용 전이를 별도 state graph로 만든다.
7. 실패, 중단, 재시작, 앱 background 복귀 경로를 먼저 검증한다.
8. 실제 플레이 시간과 telemetry 또는 관찰로 페이싱을 조정한다.

## 재미있는 loop의 조건

- 행동 전에 읽을 정보와 선택지가 있다.
- 결과가 빠르고 원인과 연결되어 보인다.
- 성공이 다음 결정을 바꾸는 자원, 위치, 위험 또는 능력을 만든다.
- 반복할수록 숙련 또는 전략이 발전한다.
- 보상이 핵심 행동을 대체하지 않고 다시 풍부하게 한다.
- 짧은 목표와 긴 목표가 서로 같은 플레이 fantasy를 강화한다.
- 실패가 원인을 학습시키고 재도전 비용이 의도에 맞다.

core/session/meta loop 설계표는 [loop-design.md](references/loop-design.md)를 읽는다.

## Application state 규칙

- 현재 상태의 authoritative owner를 하나만 둔다.
- 전이는 명명된 command 또는 method를 통해서만 요청한다.
- 전이마다 허용 source, target, guard, side effect, save point를 정의한다.
- `restart`를 여러 번 호출해도 중복 적·신호·타이머가 남지 않게 한다.
- pause UI는 paused 상태에서도 입력을 받아야 하지만 world simulation은 멈춰야 한다.
- scene loading 실패, 손상된 save, 앱 interruption의 recovery state를 둔다.
- 상태 진입과 퇴장 작업은 순서가 명확하고 가능한 한 idempotent하게 만든다.

Godot 구현과 전이 검증은 [state-flow.md](references/state-flow.md)를 읽는다.

## MDA 점검

각 loop를 다음 방향으로 검토한다.

```text
designer: Mechanics -> Dynamics -> intended Aesthetics
player:   Aesthetics <- observed Dynamics <- learned Mechanics
```

규칙을 추가할 때 예상되는 실제 행동과 감정까지 적는다. 의도한 fantasy와 다른 최적 행동을 보상하는 loop가 생기면 보상 또는 규칙을 수정한다.

## 산출물

- 한 문장의 target experience
- 시간축별 loop diagram 또는 표
- action, decision, feedback, consequence, variation
- application state graph와 transition table
- pause, game over, restart, resume의 acceptance criteria
- 관찰할 지표와 플레이테스트 질문

연구 근거는 [sources.md](references/sources.md)를 읽는다.

## 금지 사항

- 로그인 보상이나 숫자 상승을 core gameplay의 재미 대신 사용하지 않는다.
- 모든 시스템을 하나의 거대한 `GameManager` 상태 플래그로 관리하지 않는다.
- 화면만 숨기고 이전 world의 processing, collision, input을 방치하지 않는다.
- 실패 후 teardown이 끝나기 전에 새 session을 시작하지 않는다.
- 플레이 시간을 늘리기 위한 강제 대기, 과도한 알림, 손실 회피 압박을 기본 설계 원칙으로 삼지 않는다.
