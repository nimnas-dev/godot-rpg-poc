---
name: godot-architect
description: Godot 4 프로젝트의 씬 트리, 노드 책임, 신호, 의존성 주입, Autoload, Resource 데이터, 파일 구조와 런타임 성능 경계를 설계하고 리뷰한다. Godot 프로젝트 신규 구조 설계, 기능 추가 전 아키텍처 결정, 결합도 높은 씬·스크립트 리팩터링, 순환 의존성 제거, 모바일 성능 구조 점검, 프로젝트 규칙 수립 작업에 사용한다. 엔진 버전 이관은 godot-migration, 플랫폼 export·서명·패키징은 godot-build-platform과 함께 사용한다.
---

# Godot Architect

Godot의 씬 기반 합성을 유지하면서 기능을 독립적으로 테스트·교체할 수 있는 구조를 만든다. 추상화의 양보다 명확한 소유권, 단방향 의존성, 측정된 성능을 우선한다.

## 작업 절차

1. `project.godot`, 디렉터리, main scene, Autoload, 핵심 씬과 스크립트를 확인한다.
2. 게임 기능을 `application`, `world`, `actor`, `feature`, `presentation`, `data`, `platform` 영역으로 분류한다.
3. 각 노드와 씬의 소유자, 생명주기, 외부 의존성, 입력과 출력을 기록한다.
4. 참조 방향과 신호 흐름을 그려 순환 의존성, 전역 상태, 깊은 NodePath를 찾는다.
5. 가장 작은 안전한 구조 변경을 제안하고 기존 동작을 보존하면서 단계적으로 적용한다.
6. 변경 후 메인 씬, 독립 씬, 모바일 해상도에서 검증하고 프로파일링한다.

## Godot Migration·Platform Build와의 경계

- 엔진 버전과 API·직렬화·import 호환성은 `$godot-migration`이 소유한다.
- export preset·template, SDK, signing과 artifact 판정은 `$godot-build-platform`이 소유한다.
- 이 스킬은 마이그레이션으로 발생한 scene owner, dependency, Resource 경계, lifecycle과 성능 구조 변화를 소유한다.
- 엔진 업데이트가 parser rename만 요구하고 구조가 보존되면 불필요한 리팩터링을 추가하지 않는다.
- renderer·physics backend 변경은 migration contract와 측정 결과 없이 아키텍처 개선으로 끼워 넣지 않는다.
- 함께 사용할 때 각 스킬의 migration, build와 scene/runtime gate를 모두 별도로 통과해야 한다.

## 필수 규칙

- 씬 하나에 하나의 명확한 책임을 부여한다. 독립 실행할 수 있는 기능 단위를 별도 씬으로 만든다.
- 부모는 자식을 소유하고 초기화한다. 자식이 상위 트리나 형제의 구체적 경로를 탐색하지 않게 한다.
- 외부 의존성은 exported property, 초기화 메서드 또는 소유자의 조립 코드로 주입한다.
- 하위 기능은 signal로 사건을 알리고, 상위 조정자가 시스템 간 반응을 연결하게 한다.
- 같은 씬 내부의 필수 노드는 scene unique name과 typed `@onready` 참조를 사용한다.
- 게임 정의 데이터는 custom Resource로 분리한다. 런타임 상태를 공유 Resource 원본에 쓰지 말고 복제하거나 별도 상태 객체에 둔다.
- Autoload는 저장소, 세션 전환, 오디오 라우팅처럼 실제로 전역 생명주기를 갖는 서비스에만 사용한다.
- 매 프레임 트리 검색, 동적 파일 로드, 불필요한 노드 생성·해제를 피한다. 참조는 초기화 때 캐시한다.
- 최적화는 프로파일러로 병목을 확인한 뒤 수행한다. 데스크톱 결과로 모바일 성능을 추정하지 않는다.
- `$godot-migration`이 정한 source/target 버전과 공식 migration guide를 기준으로 API 차이를 확인한다. 일반 구조 작업은 `project.godot`의 현재 feature 버전 문서를 사용한다.

## 구조 결정

- 장면에 위치·생명주기·콜백이 필요하면 Node 또는 scene을 사용한다.
- 데이터와 편집기 노출이 중요하면 Resource를 사용한다.
- 순수 계산이면 RefCounted 또는 static helper를 사용한다.
- 여러 형제 시스템을 조정하면 공통 부모 coordinator를 사용한다.
- 전역 접근보다 전역 생명주기가 필요한 경우에만 Autoload를 사용한다.
- 수백 개의 동일 객체가 필요하면 노드 편의성보다 서버 API, 배칭, 풀링을 검토한다.

## 변경 산출물

아키텍처 변경 시 다음을 남긴다.

- 현재 문제와 재현 가능한 결합 지점
- 변경 전후 소유권 및 의존성 방향
- 선택한 구조와 기각한 대안의 간단한 이유
- 단계별 마이그레이션과 호환성 영향
- 테스트 항목과 측정할 성능 지표

## 참조 라우팅

- 씬·노드·Resource·Autoload 규칙은 [architecture-rules.md](references/architecture-rules.md)를 읽는다.
- 모바일 성능 또는 대규모 객체 구조는 [performance-mobile.md](references/performance-mobile.md)를 읽는다.
- 근거 문서와 버전 확인 링크는 [sources.md](references/sources.md)를 읽는다.
- 구조 점검이 필요하면 `python3 scripts/audit_godot_architecture.py <project-root>`를 실행하고 결과를 수동 검토한다.

## 금지 사항

- 편의를 이유로 모든 시스템을 하나의 `GameManager`에 모으지 않는다.
- `get_tree().root`, `/root/...`, 다단계 `get_parent()`를 일반적인 의존성 해결 수단으로 쓰지 않는다.
- 신호만 늘려 흐름을 추적할 수 없게 만들지 않는다. 한 기능 내부 호출은 직접 typed API를 사용한다.
- 측정 없이 풀링, 멀티스레딩, 서버 API로 복잡도를 높이지 않는다.
- 사용자가 구조 개선만 요청한 경우 게임 규칙이나 콘텐츠를 임의로 재설계하지 않는다.
