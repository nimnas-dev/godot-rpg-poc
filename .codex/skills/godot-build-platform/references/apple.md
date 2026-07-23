# iOS와 macOS Build

## 1. Apple 공통

- bundle ID, Team ID, version/short version과 배포 채널을 먼저 고정한다.
- certificate private key, App Store Connect API key, password와 provisioning profile을 저장소·로그에 넣지 않는다.
- capability, entitlement, privacy usage description과 sandbox 요구를 실제 기능에서 역추적한다.
- Apple이 현재 허용하는 Xcode·SDK·OS 조합과 제출 deadline을 작업일에 다시 확인한다.

## 2. iOS

Godot iOS export는 macOS, Xcode와 matching export template이 필요하며 Xcode project를 생성한다. project 생성은 build·archive·store 제출 완료가 아니다.

### 구성

- unique bundle ID와 올바른 10자리 Team ID
- development/distribution certificate와 목적에 맞는 provisioning
- minimum iOS, device family, orientation와 required capabilities
- plugin framework의 device architecture, signing과 privacy manifest
- simulator는 Compatibility renderer만 지원하므로 device renderer 증거와 분리

### 검증

1. Godot에서 빈 output directory로 Xcode project를 export한다.
2. Xcode 또는 `xcodebuild`로 development build를 만든다.
3. 실제 기기에 설치하고 device log를 확인한다.
4. Archive를 생성해 bundle ID, version, entitlement와 signature를 검사한다.
5. App Store Connect validation과 TestFlight 설치·launch를 수행한다.
6. touch, safe area, home indicator, interruption, audio route와 background 복귀를 검사한다.

simulator와 Apple Silicon의 iOS app 실행은 실제 iPhone/iPad 설치·서명·GPU 동작을 대신하지 않는다.

## 3. macOS

공식 Godot template은 Intel x86_64와 Apple Silicon arm64를 포함하는 Universal 2 `.app`을 만들 수 있다. 채널에 따라 `.app`, ZIP 또는 macOS host에서 생성하는 DMG를 선택한다.

### 외부 배포

- Developer ID Application으로 code sign한다.
- hardened runtime과 필요한 entitlement를 최소 권한으로 둔다.
- `notarytool` 제출 결과와 log를 확인한다.
- 승인 후 ticket을 staple하고 Gatekeeper 평가를 확인한다.
- 인터넷에서 받은 것과 같은 quarantine 조건의 clean account/Mac에서 실행한다.

ad-hoc signature나 로컬 우회 실행은 notarized release의 증거가 아니다.

### Mac App Store

- App Store distribution identity와 provisioning을 사용한다.
- App Sandbox와 entitlement를 적용하고 file/network 접근을 회귀 검증한다.
- App Store Connect validation과 TestFlight/macOS install을 별도 gate로 둔다.

### Cross-host 주의

- Windows에서 직접 만든 `.app`은 executable permission 문제가 있을 수 있으므로 ZIP 전달이나 macOS 재검사를 사용한다.
- Godot은 macOS 외 host에서 `rcodesign` 경로를 제공할 수 있지만 최종 notarization·Gatekeeper와 채널 검증은 실제 macOS에서 수행한다.
- Intel과 Apple Silicon에서 native library·GDExtension 양쪽 slice와 launch를 확인한다.

## 4. 검사 기록

- Xcode·SDK·Godot/template exact version
- 공개 가능한 Team·bundle ID와 certificate fingerprint
- archive/export 방식, signature·entitlement 검사 결과
- notarization request ID와 성공 상태만 기록하고 credential은 기록하지 않음
- 실제 device/Mac 모델, OS, renderer와 runtime 결과
