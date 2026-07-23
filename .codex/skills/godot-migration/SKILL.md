---
name: godot-migration
description: Godot 프로젝트의 엔진 버전 upgrade·downgrade와 호환성 이관을 수행한다. project.godot의 config/features, GDScript·C# API, scene·Resource 직렬화, import·UID, renderer·physics·navigation·audio의 버전별 동작, editor plugin·GDExtension과 native extension의 엔진 호환성을 조사·수정·검증할 때 사용한다.
---

# Godot Migration

Godot 엔진 버전이 바뀌어도 기존 게임 동작, source asset, project data와 player save 호환성을 증거로 보존한다. editor에서 파일이 열리거나 자동 변환됐다는 사실을 완료로 보지 않는다.

## 책임 경계

- 이 스킬은 source/target engine, API·직렬화·import·UID, renderer·physics 등 엔진 동작, editor plugin·GDExtension·C#의 엔진 호환성 이관을 소유한다.
- export preset·template, SDK·Gradle·Xcode, package·architecture, signing·notarization, artifact·설치·스토어 검증은 `$godot-build-platform`이 소유한다.
- 씬 소유권, 의존성, Resource runtime 경계와 성능 구조가 바뀌면 `$godot-architect`를 함께 적용한다.
- 입력·렌더링·오디오의 체감 동작이 바뀌면 `$game-feel`을 함께 적용한다.
- pause, interruption, restart와 application state가 바뀌면 `$game-loop`를 함께 적용한다.
- player save schema와 content ID migration은 `$build-rpg-system`이 소유한다. Godot project file 변환과 player save migration을 별도 테스트한다.
- 전투·적·월드 규칙이나 수치가 달라지면 해당 RPG 도메인 스킬과 `$game-balance`를 추가한다.

엔진 이관을 이유로 기존 스킬의 도메인 규칙을 대신 결정하지 않는다. 대상 플랫폼 산출물까지 요구되면 이 스킬의 Runtime gate 이후 `$godot-build-platform`의 모든 build gate를 별도로 통과한다.

## 작업 절차

### 1. Migration contract를 고정한다

다음을 확인하고 모르는 값은 `미정`으로 기록한다.

- source와 target Godot의 exact version·build·commit
- Standard/.NET/custom editor와 module·build flag
- renderer, physics backend와 사용 중인 engine subsystem
- 보존할 gameplay, player save, network protocol, input과 성능 baseline
- editor plugin, GDExtension, C#·NuGet과 native dependency
- 자동 변환으로 변경될 scene·Resource·import·UID 범위
- rollback commit·source editor 보존과 중단 조건

target 플랫폼·artifact·signing은 migration contract가 아니라 `$godot-build-platform`의 build contract에 기록한다.

### 2. 버전에 맞는 근거를 조사한다

- 항상 [sources.md](references/sources.md)를 읽고 문서 버전과 조회일을 기록한다.
- [engine-upgrade.md](references/engine-upgrade.md)를 읽고 source부터 target까지 모든 중간 minor migration guide를 순서대로 검토한다.
- target exact version의 class reference, release note와 migration guide를 우선한다.
- 공식 GitHub issue·forum은 회귀 후보를 찾는 보조 근거로 사용하고 공식 문서·merged change·최소 재현으로 확인한다.

### 3. 변경 전 상태를 수집한다

- `git status`, ignore 규칙과 rollback 가능한 기준 commit
- `project.godot`, main scene, Autoload와 engine-sensitive 설정
- `.gd`, `.cs`, `.tscn`, `.tres`, `.gdshader`, `.gdextension`, `addons/`와 native library
- source editor의 parse/import 로그, automated test, 대표 scene와 main scene 실행
- save fixture, 대표 입력·물리·navigation·rendering·audio baseline

정적 시작점으로 다음을 실행한다.

```bash
python3 .codex/skills/godot-migration/scripts/migration_preflight.py . \
  --godot-bin /absolute/path/to/target-godot --target-version 4.7.stable
```

이 결과는 inventory일 뿐 target editor의 import·runtime 호환성을 증명하지 않는다.

### 4. rollback 가능한 단계로 이관한다

1. source engine에서 baseline과 save fixture를 남긴다.
2. source와 target editor를 나란히 보존하고 binary 경로를 명시한다.
3. 별도 branch 또는 복구 가능한 복사본에서 target editor로 최초 import한다.
4. 자동 생성·직렬화 diff와 전체 import 로그를 수동 검토한다.
5. parser와 API 오류를 root cause별 작은 변경으로 수정한다.
6. scene·Resource·UID·import, plugin·GDExtension과 C# build를 검증한다.
7. renderer, physics, navigation, input, audio와 save 동작을 동일한 시나리오로 비교한다.
8. 프로젝트의 현재 엔진 버전·명령·알려진 제약 문서를 실제 결과와 맞춘다.
9. 플랫폼 artifact가 범위에 있으면 `$godot-build-platform`으로 handoff한다.

경고를 전역 비활성화하거나 renderer·physics backend를 편의상 바꾸지 않는다. 공식 절차가 요구하지 않는 한 중간 editor에서 프로젝트를 반복 저장하지 않는다.

### 5. 검증 gate를 순서대로 통과한다

| Gate | 필요한 증거 |
| --- | --- |
| Baseline | source engine 테스트·대표 동작·save fixture·rollback 지점 |
| Import | target engine parse/load 성공, 전체 로그 검토, 예상된 source-controlled diff |
| Compatibility | API, scene·Resource, import·UID, plugin·extension·C# 검증 |
| Runtime | 독립 scene, main scene, save·입력·물리·rendering·audio 회귀 테스트 |
| Documentation | exact version, 실행 방법, known risk와 rollback 문서 갱신 |

Godot가 종료 코드 0을 반환해도 로그에 `SCRIPT ERROR`, resource load 또는 import 실패가 있으면 Import gate는 실패다. target editor가 프로젝트를 저장했어도 Runtime gate를 대신하지 않는다.

## 완료 보고

- source/target exact engine, Standard/.NET/custom과 renderer·physics
- 적용한 migration guide·release note와 조회일
- 변경된 API, project setting, scene·Resource·import·UID, plugin·extension
- 실행한 명령과 각 gate의 `통과`, `실패`, `미실행`
- source/target 비교 결과와 player save 호환성
- rollback 방법과 source editor로 다시 열 수 있는 마지막 지점
- `$godot-build-platform` handoff가 필요한 target과 미검증 build 범위
- 차단 요소와 남은 위험

## 금지 사항

- dirty worktree의 사용자 변경을 자동 변환 결과로 덮어쓰지 않는다.
- backup이나 version control 없이 프로젝트를 새 editor로 일괄 저장하지 않는다.
- 새 버전에서 저장한 scene·Resource를 이전 버전이 다시 열 수 있다고 가정하지 않는다.
- forum 답변 하나나 오래된 블로그만으로 호환성을 단정하지 않는다.
- parser/import 오류를 무시하거나 warning 정책을 낮춰 migration을 통과시키지 않는다.
- engine migration 결과만으로 플랫폼 build·설치·release-ready를 보고하지 않는다.
- migration 범위에 불필요한 아키텍처 리팩터링이나 gameplay 변경을 섞지 않는다.
