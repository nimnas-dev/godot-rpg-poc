# Godot Engine Upgrade Workflow

## 목차

1. 업그레이드 결정
2. 위험 inventory
3. 공식 guide 적용
4. 최초 import와 diff
5. 호환성 수정
6. Downgrade
7. 검증과 handoff

## 1. 업그레이드 결정

| 항목 | 기록할 내용 |
| --- | --- |
| Source | exact editor version·commit, Standard/.NET/custom |
| Target | exact stable/patch 또는 pre-release와 선택 이유 |
| Drivers | 보안, bug fix, 기능, plugin·extension 요구 |
| Compatibility | gameplay, save, network, input, rendering·physics |
| Rollback | 기준 commit, source editor 보존, 중단 조건 |

patch와 minor upgrade도 회귀 가능성을 전제로 한다. Godot 3→4처럼 major version이 바뀌면 자동 변환 뒤 수동 포팅이 필요한 별도 프로젝트로 취급한다.

## 2. 위험 inventory

- `project.godot`의 `config/features`, renderer, physics, input과 display 설정
- GDScript parser warning, renamed API, native class와 `class_name` 충돌
- scene·Resource의 node/property/enum, external reference와 subresource
- import plugin, importer option, source asset와 generated metadata
- Godot 4.4+ script·shader UID sidecar와 resource UID reference
- C# target framework, NuGet, source generator와 .NET editor
- `.gdextension`, godot-cpp/API compatibility, native library와 custom module
- editor plugin·tool script의 supported Godot range
- shader language, renderer 기능과 texture import
- TileMap, navigation, physics, animation, audio, input의 changed default
- `user://` save schema, stable content ID와 multiplayer protocol

문서의 변경이 프로젝트 검색에 걸리지 않으면 근거와 함께 N/A로 남긴다. 검색에 걸리면 명시적 조치와 검증을 연결한다.

## 3. 공식 guide 적용

source minor부터 target minor까지 guide를 모두 읽는다. 예를 들어 4.3→4.7이면 4.3→4.4, 4.4→4.5, 4.5→4.6, 4.6→4.7을 검토한다.

| Change | 프로젝트 사용 여부 | 조치 | 검증 |
| --- | --- | --- | --- |
| API rename/removal | 검색 결과 | 코드 수정 또는 N/A | parse/test |
| Changed default | scene·setting | 이전 값 명시 또는 새 동작 승인 | before/after |
| Serialization | scene·Resource | target editor 변환 | diff/load |
| Import·UID | source·sidecar | reimport·reference 정리 | import log/diff |
| Plugin·extension | dependency | 지원 version·rebuild | load/test |

모든 중간 breaking change를 적용한다는 뜻이지 실제 프로젝트를 각 중간 editor에서 저장한다는 뜻은 아니다. 공식 converter가 중간 단계를 요구할 때만 별도 복사본에서 수행한다.

## 4. 최초 import와 diff

최초 import 전에 rollback 지점을 만든다. target editor binary를 명시한다.

```bash
/absolute/path/to/godot --version
/absolute/path/to/godot --headless --path . --editor --quit
```

확인할 것:

- stdout/stderr의 parser, importer, plugin, resource load 오류
- `project.godot`, `.tscn`, `.tres`, UID sidecar와 import metadata 변화
- node type, property default, enum과 resource reference 변화
- `.godot/` generated cache와 source-controlled 파일 구분

Godot 4.4+가 생성하는 script·shader `.uid`는 source와 함께 version control에 포함한다. 일괄 UID·project upgrade는 의미 있는 gameplay 변경과 분리해 리뷰한다.

삭제된 property, reset 값, 잘못된 UID fallback과 예상 밖 reimport가 없는지 수동으로 확인한다.

## 5. 호환성 수정

우선순위:

1. parser와 resource load
2. native class·method·property 충돌
3. serialization·import·UID
4. plugin, GDExtension과 C# build
5. changed default와 runtime behavior
6. renderer·shader·physics·navigation·audio·input
7. player save와 network protocol

- cascade의 root error부터 고친다.
- Variant inference 오류는 필요한 domain type을 명시한다.
- 새 native class와 custom `class_name`이 충돌하면 동작을 보존하는 project-specific 이름으로 이관한다.
- warning을 error로 취급하던 정책을 낮춰 통과시키지 않는다.
- 자동 rename 뒤 signal, NodePath, serialized enum과 default를 검토한다.
- renderer·physics backend 변경은 별도 승인과 새 baseline이 필요한 결정이다.
- player save migration은 Godot project resource conversion과 분리한다.

## 6. Downgrade

새 버전에서 저장한 scene·Resource를 이전 엔진이 열 수 있다고 가정하지 않는다. 가장 안전한 downgrade는 version control에서 source engine의 마지막 검증 파일을 복원하고 필요한 gameplay 변경만 이전 API와 format으로 다시 포팅하는 것이다.

복원이 불가능하면 별도 복사본에서 다음을 수행한다.

1. 이전 exact version의 class reference와 file format 지원 범위를 조사한다.
2. 새 node·property·Resource·UID를 이전 버전 표현으로 수동 대체한다.
3. source asset에서 다시 import하고 새 버전 cache를 재사용하지 않는다.
4. 이전 버전을 지원하는 plugin·GDExtension·C# dependency를 복원한다.
5. upgrade와 같은 전체 parse, import, runtime gate를 통과한다.

공식 downgrade 도구가 없는 경로에서는 성공 가능성을 보장하지 않는다.

## 7. 검증과 handoff

1. target headless import 로그에 새 오류가 없다.
2. automated test가 target editor에서 통과한다.
3. 변경 scene을 독립 실행한다.
4. main scene의 대표 end-to-end 흐름을 실행한다.
5. source와 target에서 동일 save·scene·입력 시나리오를 비교한다.
6. 문서와 rollback 절차를 갱신한다.
7. 플랫폼 산출물이 필요하면 `$godot-build-platform`의 Configure부터 Release gate로 handoff한다.

핵심 plugin·extension이 target을 지원하지 않거나 회귀를 보존 가능한 방식으로 해결하지 못하면 source version으로 rollback하고 차단 조건을 기록한다.
