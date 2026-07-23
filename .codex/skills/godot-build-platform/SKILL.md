---
name: godot-build-platform
description: Godot 프로젝트를 Android, iOS, Web, Windows, macOS, Linux와 dedicated server용으로 export·build하고 실제 배포 가능성을 검증한다. export_presets.cfg, 정확히 일치하는 export template, JDK·Android SDK·Gradle·Xcode·플랫폼 툴체인, architecture, APK·AAB·Xcode archive·Web bundle·desktop/server artifact, signing·notarization·provisioning, 기기 설치·브라우저 호스팅, 스토어·CI release readiness를 다룰 때 사용한다.
---

# Godot Build Platform

Godot 프로젝트를 재현 가능한 플랫폼 산출물로 만들고 실제 대상 환경에서 실행·배포할 수 있음을 단계별 증거로 확인한다. `export 성공`, `설치 가능`, `출시 가능`을 서로 다른 상태로 취급한다.

## 책임 경계

- 이 스킬은 export preset·template, SDK·툴체인, package·bundle 설정, architecture, 서명·notarization·provisioning, artifact, 설치·호스팅, 스토어 검증과 build CI를 소유한다.
- 엔진 버전, API·직렬화·import·UID·GDExtension API 호환성 이관은 `$godot-migration`이 소유한다. 엔진을 바꾼 뒤 대상 플랫폼까지 증명할 때 두 스킬을 함께 적용한다.
- scene owner, runtime dependency와 성능 구조 변경은 `$godot-architect`가 소유한다.
- touch, safe area, 화면 비율, 햅틱, 오디오와 체감 성능은 `$game-feel`이 소유한다.
- background/foreground, pause, 재시작과 recovery state는 `$game-loop`가 소유한다.
- player save schema와 content ID migration은 `$build-rpg-system`이 소유한다.

플랫폼 빌드를 이유로 도메인 동작을 임의로 바꾸지 않는다. 반대로 editor 실행 결과만으로 대상 플랫폼의 런타임·출시 gate를 완료 처리하지 않는다.

## 참조 라우팅

- 항상 [sources.md](references/sources.md)와 [common-build.md](references/common-build.md)를 읽는다.
- Android APK·AAB·Gradle·Play 작업이면 [android.md](references/android.md)를 읽는다.
- iOS·macOS·Xcode·Apple 서명 작업이면 [apple.md](references/apple.md)를 읽는다.
- Web export·hosting·PWA 작업이면 [web.md](references/web.md)를 읽는다.
- Windows·Linux·dedicated server 작업이면 [desktop-server.md](references/desktop-server.md)를 읽는다.

목표 Godot 버전으로 고정된 공식 문서와 플랫폼 소유자의 현재 정책을 작업 시점에 다시 확인하고 조회일을 기록한다.

## 작업 절차

### 1. Build contract를 고정한다

다음을 확인하고 모르는 값은 `미정`으로 기록한다.

- 정확한 Godot editor·template 버전과 Standard/.NET/custom 여부
- target OS·최소 버전·browser, CPU architecture와 renderer
- debug, QA, release, store, server 중 필요한 artifact와 파일 형식
- package·bundle ID, version name/code와 배포 채널
- 권한·entitlement·privacy·network 요구
- signing owner, 인증서·keystore·provisioning의 보관 위치와 만료 책임
- 대표 기기·clean OS·브라우저와 설치·업데이트·삭제·save 보존 시나리오
- CI host, 캐시, secret 주입과 artifact 보존 정책

### 2. 변경 전 상태를 수집한다

- `git status`, `project.godot`, `export_presets.cfg`, `.gitignore`와 기존 빌드 문서를 읽는다.
- editor 버전, matching template, host OS와 설치된 툴체인을 기록한다.
- 기존 artifact와 실기기 baseline을 보존한다.
- `.godot/export_credentials.cfg`, password, token, private key, keystore와 provisioning 내용을 읽거나 출력하지 않는다. 존재·주입 여부만 확인한다.

정적 시작점으로 다음을 실행하고 결과를 수동 검토한다.

```bash
python3 .codex/skills/godot-build-platform/scripts/platform_build_preflight.py . \
  --godot-bin /absolute/path/to/godot --platform Android
```

이 도구는 secret을 읽지 않는 static inventory다. export, 서명, 설치 또는 release 가능성을 증명하지 않는다.

### 3. 최소 preset부터 만든다

- 정확히 같은 editor와 export template을 사용한다.
- debug와 release/store preset 및 output directory를 분리한다.
- package ID, architecture, renderer와 feature tag를 명시적으로 검토한다.
- custom template·Gradle·plugin은 요구가 있을 때만 추가한다.
- `export_presets.cfg`는 검토 가능한 설정으로 관리하고 credential은 별도 secret 저장소에서 주입한다.

### 4. 검증 gate를 순서대로 통과한다

| Gate | 필요한 증거 |
| --- | --- |
| Configure | target preset, matching template, 필요한 SDK·toolchain과 secret 주입 확인 |
| Export | 명령 종료 코드 0, 오류 없는 전체 로그, 예상 경로의 artifact |
| Inspect | artifact 형식·내용·architecture·ID·version·서명 검사 |
| Install/Host | clean target 기기·OS·HTTP(S) host에 설치·배포하고 실제 launch |
| Runtime | 입력·화면·오디오·save·lifecycle·network·성능의 target 회귀 테스트 |
| Release | release 서명·notarization·provisioning과 채널·스토어 validation |

하위 gate가 실패하거나 미실행이면 상위 gate를 통과로 기록하지 않는다. exit code 0이어도 로그에 `SCRIPT ERROR`, import 실패, signing 오류가 있으면 Export gate는 실패다.

### 5. 실제 대상에서 검증한다

- Android/iOS는 simulator·emulator와 대표 실기기 결과를 구분한다.
- Web은 `file://`가 아니라 production과 같은 header·MIME·cache를 가진 HTTP(S) host에서 검사한다.
- desktop은 clean user/VM과 지원 architecture에서 검사한다.
- server는 headless launch, port, graceful shutdown, log·save path와 client protocol을 검사한다.
- 모바일은 10분 이상 대표 전투에서 frame time, 메모리, 발열과 background 복귀를 확인한다.

## CI와 비밀정보 규칙

- CLI export는 `--headless --path`와 정확한 preset 이름을 사용하고 로그와 artifact hash를 보존한다.
- 비밀정보는 CI secret 또는 OS keychain에서 환경변수·임시 파일로 주입하고 작업 후 폐기한다.
- secret 값, private key, password, keystore, provisioning profile을 저장소·로그·artifact 이름·최종 보고에 노출하지 않는다.
- pull request의 신뢰할 수 없는 코드가 release secret에 접근하지 못하게 한다.
- cache key에 Godot exact version, template, platform toolchain과 dependency lock을 포함한다.
- platform matrix의 한 항목 성공을 다른 target 성공으로 일반화하지 않는다.

## 완료 보고

- Godot/editor/template exact version, host와 target matrix
- preset, artifact 종류·경로·architecture·ID·version
- 사용한 SDK·toolchain과 공식 정책 조회일
- 실행한 명령과 각 gate의 `통과`, `실패`, `미실행`
- 서명은 identity의 공개 가능한 식별자와 검증 결과만 기록
- 실제 기기·OS·브라우저, launch log와 runtime 관찰
- CI 재현 방법, 미검증 항목, 차단 요소와 남은 위험

## 금지 사항

- preset 존재나 data PCK/ZIP만으로 실행 가능한 빌드라고 보고하지 않는다.
- debug keystore, ad-hoc signature, simulator 실행을 store release 증거로 사용하지 않는다.
- 서로 다른 버전의 editor와 export template을 섞지 않는다.
- 플랫폼 정책의 버전·조회일 없이 오래된 SDK 수치를 고정 규칙으로 복사하지 않는다.
- 개발 머신 실행으로 다른 OS·architecture·브라우저·실기기 호환성을 추정하지 않는다.
- 플랫폼 빌드를 통과시키려고 renderer, 권한, 보안 header 또는 signing 검사를 임의로 낮추지 않는다.
