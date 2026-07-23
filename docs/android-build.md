# Android 디버그 APK 빌드

## 빌드 계약

- Godot: `4.7.1.stable.official.a13da4feb` Standard
- Renderer: GL Compatibility
- Artifact: arm64-v8a debug APK
- Package: `com.arcane.frontier`
- Version: code `2`, name `0.3.0`
- Android: min SDK 24, target/compile SDK 36
- Distribution: 직접 설치하는 개발·QA 빌드

Godot 4.3에서 4.7.1로 이관할 때 renderer와 저장 schema v1은 유지했습니다. 4.7에서 달라진 stretch 기본값의 영향을 막기 위해 aspect는 `keep`으로 명시했습니다. 이 문서의 debug APK와 별개로 Play Store 제출에는 release keystore, AAB와 스토어 정책 검증이 필요합니다.

## 준비

1. Godot 4.7.1 Standard와 같은 버전의 공식 Export Templates를 설치합니다.
2. JDK 17을 사용합니다.
3. Android SDK에 Platform-Tools, Platform 36과 Build-Tools 36.0.0 이상을 설치합니다.
4. Godot Editor Settings의 Android SDK Path와 Java SDK Path를 설정합니다.

서명 키나 비밀번호를 저장소에 넣지 않습니다. debug export는 로컬 debug keystore를 사용합니다.

## 검증과 export

저장소 루트에서 실행합니다.

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --quit-after 180
mkdir -p build/android
godot --headless --path . \
  --export-debug Android build/android/arcane-frontier.apk
```

테스트 성공 조건은 종료 코드뿐 아니라 `PASS: 673 checks`와 `SCRIPT ERROR`, `Parse Error`, `Compile Error` 부재를 함께 확인하는 것입니다.

## Artifact 검사

`ANDROID_SDK_ROOT` 아래의 설치된 Build-Tools 버전에 맞게 경로를 조정합니다.

```bash
"$ANDROID_SDK_ROOT/build-tools/36.0.0/aapt" \
  dump badging build/android/arcane-frontier.apk
"$ANDROID_SDK_ROOT/build-tools/36.0.0/apksigner" \
  verify --verbose --print-certs build/android/arcane-frontier.apk
shasum -a 256 build/android/arcane-frontier.apk
```

다음을 확인합니다.

- package `com.arcane.frontier`
- version code `2`, version name `0.3.0`
- `native-code: 'arm64-v8a'`
- min SDK 24, target SDK 36
- APK Signature Scheme v2 또는 그 이후 서명 검증 성공

## 설치와 실행

USB debugging이 허용된 arm64 Android 기기 또는 에뮬레이터를 연결합니다.

```bash
adb devices -l
adb install -r build/android/arcane-frontier.apk
adb shell monkey -p com.arcane.frontier \
  -c android.intent.category.LAUNCHER 1
adb logcat -d -v brief Godot:D AndroidRuntime:E libc:F '*:S'
```

시작 화면, 새 게임, 세 직업 선택과 전투 월드 진입을 확인합니다. 실제 기기에서는 조이스틱을 유지한 채 두 번째 손가락으로 스킬을 누르는 경로, 앱 background/foreground 복귀, Android Back, cutout safe area, 진동과 10분 전투의 발열·frame time을 추가 검증합니다.
