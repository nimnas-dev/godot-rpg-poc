# Godot 4 World Production Pipeline

## 1. Blockout

- 단색 placeholder TileSet을 만든다.
- ground, blocker, height/foreground, interaction marker를 최소 layer로 분리한다.
- player collision과 camera를 실제 값으로 사용한다.
- entrance, exits, landmark proxies, encounter bounds를 배치한다.
- 이동 시간과 sightline을 먼저 검증한다.

Blockout 단계에서 final art 문제를 해결하지 않는다. 구조가 바뀔 수 있어야 한다.

## 2. TileSet authoring

- 여러 map이 공유하면 TileSet을 external `.tres` Resource로 저장한다.
- source atlas margin, separation, region size를 원본 art와 일치시킨다.
- terrain sets는 연결 규칙이 실제 지형 logic을 표현할 때 사용한다.
- collision, occlusion, navigation custom data를 목적별 layer로 명명한다.
- reusable animated prop, chest, door, NPC spawn은 scene tile 또는 별도 scene instance를 검토한다.

## 3. TileMapLayer responsibilities

가능한 구성:

```text
WorldRegion
  Ground
  GroundDetails
  Collision
  NavigationSource
  PropsBack
  Actors
  PropsFront
  InteractionMarkers
```

프로젝트에 필요 없는 layer는 만들지 않는다. y-sorted layer와 일반 batch layer를 구분한다. frequent runtime update가 있는 layer를 static art와 분리한다.

## 4. Collision

- player, enemy, projectile, interaction의 physics layer/mask 표를 유지한다.
- 작은 장식마다 collision을 만들지 않는다.
- tile seam에서 CharacterBody2D가 걸리는지 여러 속도와 dash로 테스트한다.
- 절벽과 물의 시각 경계가 collision 경계와 일치하는지 확인한다.
- debug collision view로 art 없이 검증한다.

## 5. Navigation

- TileMap navigation은 prototype에 유용하지만 큰 실제 map에서 경로 품질과 성능 한계가 있다.
- 안정된 geometry는 NavigationRegion2D mesh로 bake하는 방식을 검토한다.
- agent size가 다른 actor는 navigation layer/map 또는 적절한 bake 설정을 분리한다.
- 동적 obstacle과 RVO avoidance는 필요한 actor에만 사용한다.
- region 연결과 portal/door 상태 변화를 명시적으로 갱신한다.
- impossible target과 path timeout fallback을 구현한다.

## 6. Region scene contract

각 region scene은 다음 interface를 갖도록 한다.

- stable region ID
- named entrances/exits
- spawn and checkpoint markers
- local encounter/interaction owners
- load-time world state application
- unload-time transient cleanup
- optional navigation ready signal

Player나 persistent service를 region의 임의 NodePath로 참조하지 않는다. WorldHost가 의존성을 주입한다.

## 7. Streaming and activation

작은 게임은 단순 scene replacement를 우선한다. 필요할 때만 인접 region preload 또는 streaming을 도입한다.

- active region과 preloaded neighbors를 구분한다.
- off-screen region processing과 audio를 끈다.
- memory reclaimed 여부를 Resource cache까지 측정한다.
- loading 중 player input과 duplicate transition을 잠근다.
- entrance 위치를 stable ID로 저장한다.

## 8. World state

저장 가능한 변화:

- opened chest and door IDs
- defeated unique encounter IDs
- collected unique resource IDs
- quest-driven tile/scene variants
- activated checkpoint and shortcut IDs

임시 grass particle, current enemy path, dropped damage number는 저장하지 않는다. Tile coordinate만으로 identity를 만들면 map edit 시 save가 깨질 수 있으므로 persistent object에 stable ID를 부여한다.

## 9. Optimization pass

- TileMap quadrant and y-sort behavior
- visible CanvasItems and overdraw
- active physics bodies and shapes
- navigation map update spikes
- runtime tile updates
- texture memory and atlas import
- active particles, lights and audio players

대표 모바일 기기의 실제 export build에서 region 진입, 대규모 encounter, 빠른 이동과 반복 transition을 측정한다.
