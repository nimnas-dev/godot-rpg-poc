# Godot Platform Build 공통 절차

## 1. 완료 상태를 분리한다

| 상태 | 최소 증거 |
| --- | --- |
| Configured | exact editor/template, preset, toolchain과 필수 public 설정 |
| Exported | 전체 로그가 깨끗하고 예상 artifact가 생성됨 |
| Inspected | 형식, architecture, package ID, version과 signature를 도구로 확인 |
| Installable | clean target에 설치·호스팅 후 launch 성공 |
| Runtime-verified | 입력, 화면, 오디오, save, lifecycle, network와 성능 통과 |
| Release-ready | release credential과 배포 채널 validation 통과 |

상위 상태는 모든 하위 상태의 증거를 포함해야 한다. `가능해 보임`과 `실제로 수행함`을 구분한다.

## 2. Build contract

작업 전에 표로 고정한다.

| 항목 | 예 |
| --- | --- |
| Engine | `4.7.stable`, Standard 또는 .NET, official/custom |
| Host | macOS arm64, Windows x86_64, Linux CI |
| Target | Android arm64, iOS device, Web, Windows x86_64 |
| Renderer | Mobile 또는 Compatibility |
| Artifact | APK, AAB, Xcode archive, Web bundle, executable+PCK |
| Identity | package/bundle ID, version name/code |
| Channel | direct QA, Play, App Store, Steam, dedicated host |
| Signing owner | 개인명이 아닌 역할과 secret system |
| Test environment | 기기·OS·browser·clean install/update |

정책이나 툴체인 요구가 바뀌기 쉬운 값은 `확인한 공식 URL`, `문서 버전`, `조회일`을 함께 기록한다.

## 3. Editor와 template

- export template은 editor의 exact version·status에 맞춘다. custom engine이면 같은 source revision과 build flags로 template을 만든다.
- Standard와 .NET editor/template을 혼동하지 않는다.
- `export_presets.cfg`에는 대부분의 export 설정이 들어가며 일반적으로 version control에 둘 수 있다.
- `.godot/export_credentials.cfg`에는 password·encryption key 같은 confidential 옵션이 들어간다. commit·공유·내용 출력을 금지한다.
- plugin, GDExtension과 native library가 모든 target architecture용 binary를 제공하는지 확인한다.

## 4. CLI export

대표 형태:

```bash
/absolute/path/to/godot --headless --path /absolute/project \
  --export-debug "Android Debug" /absolute/output/game.apk

/absolute/path/to/godot --headless --path /absolute/project \
  --export-release "Windows Release" /absolute/output/game.exe
```

- CLI export에도 이름이 정확히 일치하는 preset이 필요하다.
- output 확장자는 platform exporter가 기대하는 형식과 맞춘다.
- command의 working directory가 아니라 `--path`와 명시적 output을 기준으로 재현한다.
- PCK/ZIP pack export는 data pack이다. matching executable·template 없이 독립 실행 가능하다고 보고하지 않는다.
- stdout/stderr 전체를 보존하고 `SCRIPT ERROR`, parser/import, missing file, signing 경고를 검사한다.

## 5. Artifact 검사

공통으로 다음을 기계적으로 확인한다.

- 파일 존재, 크기, checksum과 build timestamp
- archive 내부의 예상 executable·PCK·manifest·native library
- target architecture와 debug/release 구분
- package/bundle ID와 version
- signature chain, timestamp/notarization 또는 unsigned 상태
- 이전 버전 설치 위 update가 의도한 signing key와 save를 유지하는지

artifact가 존재한다는 사실만으로 launch 또는 store acceptance를 추론하지 않는다.

## 6. CI

- matrix 축은 `engine exact version × host × target × architecture × debug/release`로 명시한다.
- editor와 template checksum, SDK package 목록, dependency lock을 기록한다.
- import cache는 engine·renderer·platform key가 같을 때만 재사용한다.
- release signing은 trusted branch/tag와 승인된 runner에서만 수행한다.
- secret은 CI secret·keychain에서 주입하고 값 대신 존재와 검증 결과만 로그에 남긴다.
- unsigned QA artifact와 signed release artifact를 서로 다른 경로·retention으로 보관한다.
- artifact checksum, build log, source revision과 provenance를 연결한다.

## 7. 실제 실행 회귀

- clean install, update install, cold launch, warm launch와 uninstall을 구분한다.
- save 생성·복원·이전 버전 호환, 권한 거부, offline과 네트워크 복귀를 검사한다.
- 화면 비율, DPI, safe area, 입력 장치, audio route와 language를 target matrix로 만든다.
- background/suspend/resume, focus loss, process kill과 low-memory recovery를 검사한다.
- 대표 저사양 조건에서 frame time, memory와 장시간 안정성을 측정한다.

## 8. Release 증거

- 배포 채널의 validator 결과 또는 제출 pre-check를 보존한다.
- signing identity는 공개 가능한 fingerprint·Team/Publisher 정보만 기록한다.
- 인증서·profile·SDK·target API의 만료 또는 정책 deadline을 기록한다.
- 미실행 gate는 실패와 구분하되 통과로 간주하지 않는다.
