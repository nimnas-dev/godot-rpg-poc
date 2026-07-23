# Windows, Linux와 Dedicated Server

## 1. Windows

### Artifact

- x86_64를 기본 target으로 두고 x86_32·arm64가 필요하면 별도 artifact와 실제 기기를 둔다.
- executable과 외부 PCK 또는 embedded PCK 선택을 기록한다.
- embedded PCK의 크기 제한과 signing 순서를 목표 Godot 문서에서 확인한다.
- Steam, itch.io, Microsoft Store/MSIX 등 채널별 package를 독립 gate로 둔다.

### Signing과 검증

- Windows SDK `SignTool` 또는 지원되는 cross-host sign tool과 publisher certificate를 사용한다.
- signature, digest, timestamp와 chain을 검증한다.
- clean Windows user/VM에서 unzip/install, launch, update와 uninstall을 검사한다.
- x86_64·arm64 target, DPI scaling, keyboard/mouse/controller, save path와 antivirus/SmartScreen 반응을 확인한다.
- channel이 다시 서명하는 경우 local signature와 store-delivered signature를 모두 기록한다.

## 2. Linux

### Artifact

- target architecture를 명시한다. Godot official template 제공 여부를 architecture별로 확인한다.
- executable permission, executable과 PCK의 상대 위치를 보존한다.
- case-sensitive filesystem에서 asset path 대소문자를 검사한다.
- 직접 archive, AppImage, Flatpak, Steam runtime 또는 container 중 채널을 명시한다.

### 검증

- 지원 distribution 또는 이에 해당하는 clean container/VM에서 launch한다.
- Wayland와 X11, graphics driver, audio backend, controller와 IME를 범위에 맞게 검사한다.
- dynamic library와 GDExtension architecture·dependency를 검사한다.
- `$XDG_DATA_HOME` 등 실제 save/log 경로와 읽기 전용 설치 directory를 검증한다.
- 개발 distribution 성공을 다른 libc·driver 조합으로 일반화하지 않는다.

## 3. Dedicated server

### Export 계약

- server host OS·architecture, client protocol/content version과 network port를 고정한다.
- dedicated server export preset을 사용하거나 matching template binary와 PCK 배치 계약을 명시한다.
- `dedicated_server` feature tag 또는 명시적 user argument로 server mode 진입을 확인한다.
- export template은 editor보다 작고 운영용 headless server에 적합하다.
- visual strip/remove가 server가 참조하는 Resource·scene을 깨뜨리지 않는지 검사한다.

### 운영 검증

1. display/audio device 없는 clean host에서 headless launch한다.
2. 올바른 interface·port bind, health/readiness와 client connect를 확인한다.
3. 동일·불일치 client protocol/content version을 각각 검사한다.
4. SIGTERM/서비스 stop의 graceful shutdown과 save flush를 확인한다.
5. log path, rotation, crash exit code와 restart policy를 확인한다.
6. 동시 client와 장시간 부하에서 CPU, memory, tick rate와 network를 측정한다.

PCK만 배포할 경우 정확히 matching export template binary, 동일 base name과 launch command를 함께 제공한다. headless로 시작됐다는 사실만으로 authoritative game state, 보안 또는 운영 준비를 통과 처리하지 않는다.
