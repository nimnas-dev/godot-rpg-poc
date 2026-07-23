# Sources and Research Rules

## 근거 우선순위

1. 목표 버전으로 고정된 Godot 공식 문서
2. Google, Apple, Microsoft, browser vendor 등 플랫폼 소유자의 공식 문서
3. 배포 채널의 공식 정책·validator 문서
4. Godot 공식 GitHub issue·merged change와 공식 forum
5. 외부 사례와 일반 forum

하위 근거는 재현 후보를 찾는 데만 사용하고 상위 근거와 실제 artifact·기기 검증으로 확인한다. SDK, store 정책, Xcode와 signing 요구는 작업 시점에 다시 조회한다.

## Godot export 공통

- [Exporting projects 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html)
- [Command line tutorial 4.7](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [Feature tags 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/feature_tags.html)
- [One-click deploy 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/one-click_deploy.html)

목표가 4.7이 아니면 URL과 요구를 해당 exact 버전으로 바꾼다. Godot 문서에 따르면 `export_presets.cfg`는 일반 export 설정이고 `.godot/export_credentials.cfg`는 confidential 설정이므로 후자를 commit·출력하지 않는다.

## Android

- [Godot Android export 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)
- [Godot Gradle builds 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html)
- [Android app signing](https://developer.android.com/studio/publish/app-signing)
- [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)

Google Play 정책의 deadline과 target API는 바뀌므로 값 자체보다 공식 페이지의 조회일을 기록한다.

## Apple

- [Godot iOS export 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html)
- [Godot macOS export 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html)
- [Apple code signing overview](https://developer.apple.com/support/code-signing/)
- [Apple provisioning profiles](https://developer.apple.com/help/account/provisioning-profiles/provisioning-profile-updates/)
- [Uploading builds to App Store Connect](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [Resolving notarization issues](https://developer.apple.com/documentation/security/resolving-common-notarization-issues)

## Web

- [Godot Web export 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html)
- [MDN secure contexts](https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts)
- [MDN cross-origin isolation](https://developer.mozilla.org/en-US/docs/Web/API/Window/crossOriginIsolated)
- [MDN WebAssembly MIME guidance](https://developer.mozilla.org/en-US/docs/WebAssembly/Guides/Loading_and_running)

## Desktop와 server

- [Godot Windows export 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_windows.html)
- [Godot Linux export 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_linux.html)
- [Godot dedicated server export 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_dedicated_servers.html)
- [Microsoft code signing options](https://learn.microsoft.com/en-us/windows/apps/develop/smart-app-control/code-signing-for-smart-app-control)
- [SignTool](https://learn.microsoft.com/en-us/windows/win32/seccrypto/signtool)

## 공식 커뮤니티와 issue

- [godotengine/godot issues](https://github.com/godotengine/godot/issues)
- [godotengine/godot-docs](https://github.com/godotengine/godot-docs)
- [Godot Forum](https://forum.godotengine.org/)

issue·forum을 사용할 때 engine exact version, host, renderer, target, toolchain과 재현 조건이 현재 작업과 같은지 확인한다. 해결되지 않은 글은 위험으로 기록하고 완료 근거로 사용하지 않는다.

## Research log

| Source | Version/date | 적용 범위 | 프로젝트 영향 | 검증 |
| --- | --- | --- | --- | --- |
| 공식 URL | 문서·정책 버전과 조회일 | preset/toolchain/policy | 사용/N/A | artifact/device/store |
