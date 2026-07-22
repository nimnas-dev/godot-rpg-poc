# RPG World Design

## World promise

지역마다 한 문장의 약속을 만든다.

```text
이 숲에서는 빛나는 버섯과 오래된 돌길을 따라가며 안전한 길과 희귀 재료 사이를 선택한다.
```

약속은 art theme만이 아니라 navigation, encounter, resources와 발견 방식에 나타나야 한다.

## Movement metrics

blockout 전에 측정한다.

- player speed and dash distance
- camera visible width/height
- basic attack and enemy threat ranges
- desired landmark interval
- desired combat-free recovery time
- entrance-to-goal and optional-loop time
- touch controls에서 편안한 corridor width

거리 단위를 tile과 seconds로 함께 기록한다.

## Region graph

node와 edge로 먼저 설계한다.

```text
Town
  -> Forest Entrance
      -> Old Road -> Ruins Gate -> Ruins
      -> River Loop -> Hidden Grove --shortcut--> Old Road
```

Node에는 fantasy, landmark, beat, reward, encounter, exits를 기록한다. Edge에는 travel time, gate, sightline, risk와 one-way 여부를 기록한다.

## Critical and optional paths

- critical path는 완료에 필요한 최소 경로다.
- optional path는 발견, mastery, story, reward 또는 shortcut을 제공한다.
- optional path 입구에서 약속의 일부를 보여준다.
- 길을 벗어난 비용과 보상의 관계를 의도적으로 정한다.
- critical path가 명확해도 실제 플레이어가 벗어나고 되돌아오는 것을 전제로 한다.

## Landmark hierarchy

### Global landmark

여러 region에서 방향을 잡는 큰 목표. 실루엣과 위치 관계가 안정적이어야 한다.

### Regional landmark

현재 지역의 subgoal 또는 경로 구분. 색보다 형태, 높이, motion, sound도 활용한다.

### Local landmark

갈림길, encounter, 비밀의 기억점. 반복 prop와 구분되어야 한다.

landmark를 너무 많이 두면 모두 배경이 된다. 중요한 landmark 주변의 visual noise를 줄인다.

## Wayfinding toolkit

- sightline and reveal
- path width and surface change
- lighting and contrast
- architecture and terrain affordance
- sound beacon
- enemy facing or movement
- NPC and environmental behavior
- signage when the fiction supports it

한 기법을 절대 법칙으로 사용하지 않는다. 플레이어의 현재 목표와 자원 상태에 따라 같은 단서도 다르게 해석된다.

## Beat and pacing map

beat 종류를 색으로 구분해 시간축에 놓는다.

- Explore: 공간, 경로, resource 탐색
- Combat: 위협과 mastery
- Puzzle/Interaction: 관찰과 world rule
- Choreo/Story: narrative, NPC, world change
- Rest/Reward: 안전, 정비, 성취

`teach -> test -> twist`를 새 terrain, hazard, interaction과 enemy 조합에 적용한다. 높은 intensity가 계속되면 차이가 사라진다.

## Gates, keys and shortcuts

Gate는 단순 문이 아니다.

- ability gate: 새 movement 또는 interaction mastery
- knowledge gate: world clue를 이해해야 통과
- resource gate: 준비와 소비 선택
- state gate: quest/world consequence
- combat gate: encounter mastery

Key를 얻은 뒤 어디에 사용할지 기억할 수 있게 gate의 identity를 강하게 만든다. Shortcut은 이전 공간을 새 관계로 이해하게 해야 한다.

## Exploration rewards

보상 유형을 섞는다.

- power: item, upgrade material, skill
- possibility: route, vendor, crafting recipe
- knowledge: lore, enemy clue, map understanding
- expression: cosmetic, build sidegrade
- efficiency: shortcut, checkpoint
- spectacle: vista, animation, music moment

모든 비밀을 같은 currency chest로 끝내지 않는다.

## Playtest observation

말로 길을 설명하지 않고 관찰한다.

- 첫 시선과 첫 선택
- 멈추거나 회전하는 위치
- landmark를 언급하는 방식
- 갈림길 선택의 근거
- 길을 잃은 시간과 recovery 방법
- optional path의 발견과 포기 이유
- 전투 중 camera와 terrain 문제
- 같은 지역 재방문의 기억
