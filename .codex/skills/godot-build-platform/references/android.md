# Android Build와 Google Play

## 1. 요구사항을 현재 문서로 고정한다

Godot 4.7 공식 문서는 OpenJDK 17을 권장하고 Android SDK Platform-Tools 35.0.0+, Build-Tools 35.0.1, Platform 35, 최신 command-line tools를 안내한다. NDK·CMake가 필요한 경로에서는 공식 문서의 exact package를 사용한다.

이 수치는 영구 규칙이 아니다. 작업일에 다음을 함께 대조한다.

1. 목표 Godot 버전의 Android export 문서
2. Google Play의 현재 target API와 App Bundle 정책
3. 사용 중인 plugin·Gradle/Android Gradle Plugin의 지원 범위

문서 간 요구가 다르면 store deadline을 만족하면서 Godot가 지원하는 조합을 선택하고 근거를 기록한다.

### 2026-07-23 조사 snapshot

- Google Play 공식 정책은 2026-08-31부터 새 앱과 업데이트가 Android 16(API 36) 이상을 target하도록 안내한다.
- 기존 앱의 신규 사용자 노출 유지 기준은 Android 15(API 35) 이상으로 안내된다.

이 snapshot을 미래 작업의 고정값으로 사용하지 않는다. 제출 직전에 공식 정책의 날짜·예외·폼팩터별 요구를 다시 확인한다.

## 2. Artifact 선택

| 목적 | 기본 artifact |
| --- | --- |
| 빠른 로컬·실기기 검증 | debug APK |
| 외부 QA | 별도 ID 또는 명시적 update 정책의 signed APK |
| Google Play | signed release AAB |
| custom plugin·SDK·native 변경 | Gradle build |

Google Play용 AAB는 Gradle build가 필요하다. Android plugin, 외부 SDK 또는 native project 수정이 없으면 Gradle 복잡도를 불필요하게 추가하지 않는다.

## 3. Public 설정

- unique package ID를 reverse-DNS 형식으로 고정한다.
- version code는 업로드마다 증가시키고 version name과 source revision을 연결한다.
- min/target SDK, orientation, permissions와 feature 요구를 검토한다.
- arm64-v8a를 기본 store architecture로 확인하고 필요한 경우 x86_64 등 QA target을 분리한다.
- debug와 release preset·application ID·output을 혼동하지 않는다.
- adaptive·themed icon과 launcher safe zone을 실제 launcher에서 확인한다.

## 4. Signing

- debug keystore와 upload/release key를 분리한다.
- keystore, alias password와 private key를 저장소·로그에 넣지 않는다.
- Google Play App Signing 사용 여부, upload key owner, backup과 rotation 절차를 기록한다.
- package ID가 같고 signing key가 다른 앱은 update 설치되지 않는다. clean install과 update 시나리오를 모두 검증한다.
- artifact의 certificate fingerprint를 도구로 검사하되 secret 값은 출력하지 않는다.

## 5. Build와 검사

1. `java -version`, SDK packages, `adb version`을 기록한다.
2. debug APK를 export하고 전체 Godot/Gradle 로그를 검사한다.
3. APK/AAB의 package ID, version, target SDK, ABI와 signature를 검사한다.
4. `adb install` 또는 update 설치를 수행한다.
5. cold launch와 `adb logcat`에서 Godot, AndroidRuntime, permission 오류를 확인한다.
6. release AAB를 만들고 Play Console의 사전 검사를 수행한다.

## 6. 실기기 matrix

- 낮은 메모리의 대표 arm64 기기와 최신 기기
- gesture navigation·Back, cutout·safe area와 orientation
- touch ownership, multi-touch와 외부 controller
- permission 승인·거부·재요청
- phone call/audio focus, background/foreground와 process kill
- airplane mode, 연결 복귀와 download 실패
- 10분 이상 대표 전투의 frame time, memory, thermal과 battery

emulator 성공만으로 GPU driver, touch, thermal 또는 실제 store package를 통과 처리하지 않는다.

## 7. Play 제출

- 현재 target API deadline을 Google 공식 정책에서 조회일과 함께 기록한다.
- release AAB, Play App Signing, data safety/privacy와 required declarations를 확인한다.
- internal testing track에서 install·update·launch를 검증한다.
- native plugin이 있으면 symbol·crash mapping 요구를 확인한다.
- console acceptance 전에는 `release-ready`가 아니라 `release artifact generated`로 보고한다.
