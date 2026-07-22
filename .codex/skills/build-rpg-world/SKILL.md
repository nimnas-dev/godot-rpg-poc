---
name: build-rpg-world
description: 플레이어가 길을 이해하면서도 호기심과 발견을 느끼는 2D RPG 필드, 지역, 던전, 랜드마크, 탐험 경로, 비밀, encounter 배치와 환경 서사를 설계하고 Godot 4 TileMapLayer·TileSet·NavigationRegion2D로 구현한다. 신규 맵 제작, 비어 있거나 길을 잃기 쉬운 월드 개선, 탐험 보상과 페이싱 구성, 지역 스트리밍·충돌·내비게이션 최적화에 사용한다.
---

# Build RPG World

맵을 콘텐츠가 놓이는 배경이 아니라 플레이어의 이동, 위험 판단, 호기심과 기억을 만드는 게임 시스템으로 설계한다.

## 작업 절차

1. 지역의 fantasy, 핵심 동사, 목표 플레이 시간과 이동 속도를 정의한다.
2. entrance, destination, landmark, gate, shortcut, optional pocket을 graph로 배치한다.
3. critical path와 optional loop의 거리·시간·시야를 blockout에서 검증한다.
4. 탐험, 전투, 퍼즐, 이야기, 휴식 beat를 리듬 있게 배치한다.
5. 각 갈림길에 정보, 위험, 예상 보상을 제공한다.
6. 회색 타일과 임시 collision으로 길찾기와 encounter를 플레이테스트한다.
7. TileMapLayer, TileSet, navigation, interaction과 region state를 데이터화한다.
8. art pass 후 landmark, silhouette, readability가 유지되는지 다시 검증한다.
9. 실제 이동 시간, 막힘, 되돌아감, 발견률과 성능을 측정한다.

## 탐험 원칙

- 중요한 목적지는 전역 landmark와 지역 landmark로 기억할 수 있게 한다.
- 완벽한 미니맵 지시보다 환경에서 세운 가설을 이동으로 검증하게 한다.
- 갈림길은 서로 다른 시각 정보, 위험 또는 보상 약속을 보여준다.
- optional route는 시간 낭비가 아니라 lore, mastery, shortcut, build option 중 하나를 제공한다.
- 비밀은 일부 플레이어가 놓쳐도 괜찮지만 발견 가능한 clue를 가진다.
- backtracking에는 shortcut, world change, 새 ability gate 또는 다른 encounter를 더한다.
- 긴 combat 뒤에는 탐색·안전·보상 beat를 두어 intensity를 회복한다.
- 맵 크기보다 의미 있는 결정과 기억 가능한 밀도를 우선한다.

월드 그래프, 길찾기와 페이싱은 [world-design.md](references/world-design.md)를 읽는다.

## Godot 구현 원칙

- 시각, collision, foreground, interaction, navigation 책임을 필요한 만큼 TileMapLayer로 나눈다.
- 여러 지역이 공유하는 TileSet은 외부 Resource로 저장한다.
- terrain painting과 reusable scene tiles를 적절히 구분한다.
- y-sort, z-index, collision layer와 navigation layer 규칙을 문서화한다.
- 대형 월드에서 TileMap 내장 navigation 한계를 확인하고 NavigationRegion2D로 baking한다.
- region 경계는 로딩, 저장, 음악, encounter, quest state가 함께 전환될 수 있게 stable ID를 가진다.
- 런타임 변경 타일과 영구 world state를 분리하고 저장 시 ID 기반으로 재구성한다.
- off-screen region의 processing, particles, navigation agents와 audio를 비활성화한다.

구체적인 Godot 제작 파이프라인은 [godot-world-pipeline.md](references/godot-world-pipeline.md)를 읽는다.

## 산출물

- world fantasy와 movement metrics
- region graph와 critical/optional path
- landmark 및 sightline plan
- beat map과 intensity curve
- gate/key/shortcut와 reward promise
- encounter·quest·resource placement 근거
- TileMapLayer, collision, navigation, y-sort 규칙
- 탐험 플레이테스트와 성능 결과

근거 자료는 [sources.md](references/sources.md)를 읽는다.

## 금지 사항

- 플레이 시간을 늘리기 위해 빈 공간과 긴 복도를 추가하지 않는다.
- 모든 관심 지점을 동일한 아이콘과 동일한 보상 구조로 만든 뒤 탐험이라 부르지 않는다.
- art를 완성한 뒤 처음으로 이동과 전투를 테스트하지 않는다.
- collision과 navigation을 시각 타일에 암묵적으로 결합해 수정하기 어렵게 만들지 않는다.
- 미니맵 marker만으로 나쁜 landmark와 wayfinding을 보완하지 않는다.
- optional path 끝에 아무 정보나 변화 없이 dead end를 반복하지 않는다.
