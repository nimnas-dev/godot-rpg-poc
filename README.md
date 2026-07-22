# Arcane Frontier

Godot 4.3 기반 Android 우선 2D 탑다운 판타지 RPG vertical slice입니다. 검사·궁수·마법사 중 하나를 선택해 역할이 다른 적 조합의 끝없는 웨이브를 돌파하고, 레벨마다 세 가지 강화 중 하나를 선택합니다.

## 현재 플레이 루프

- 새 게임 또는 웨이브 시작 체크포인트에서 계속하기
- 검사·궁수·마법사 선택
- 슬라임 돌진, 고블린 직선 돌격, 망령 원거리 사격에 대응
- 경험치 획득 후 전투를 멈추고 3개 강화 중 하나 선택
- 웨이브를 끝없이 진행하며 최고 클리어 웨이브 기록
- 사망 후 런 저장을 지우고 새 `RunWorld`로 재시작

웨이브 적 수는 `min(24, 3 + wave × 2)`입니다. 동시 공격자는 3명, 그중 원거리 공격자는 1명으로 제한되며 모든 공격은 전조–판정–회복 단계를 가집니다.

## 조작

| 행동 | PC | 모바일 |
|---|---|---|
| 이동 | WASD | 좌측 가상 조이스틱 |
| 기본 공격 | Space / 마우스 왼쪽 | 우측 공격 버튼 |
| 스킬 | 1 / 2 / 3 | 우측 스킬 버튼 |
| 일시정지 | Esc / Back | 우상단 일시정지 버튼 |

Android Back과 앱 백그라운드 전환은 전투를 일시정지하고 입력을 초기화합니다. 앱으로 돌아와도 사용자가 `계속하기`를 누르기 전에는 전투가 재개되지 않습니다.

## 저장 정책

- 프로필: 최고 클리어 웨이브, SFX 음량, 화면 흔들림, reduced motion, 햅틱, 효과 품질
- 런 체크포인트: 웨이브 시작 시점의 run seed, wave, class stable ID, level, XP, HP, 강화 중첩
- 파일: `user://profile.json`, `user://run_checkpoint.json`, 각 `.bak`

저장은 임시 파일 기록과 재파싱 후 교체됩니다. 현재 파일이 손상되면 백업을 사용합니다. 앱이 웨이브 도중 종료되면 해당 웨이브 시작 지점으로 돌아가며, 그 웨이브에서 얻은 처치와 XP는 보존하지 않습니다.

## 실행과 검증

1. Godot 4.3에서 `project.godot`을 가져옵니다.
2. F5로 메인 씬을 실행합니다.
3. CLI 검증은 다음 명령을 사용합니다.

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_runner.gd
python3 .codex/skills/godot-architect/scripts/audit_godot_architecture.py .
python3 .codex/skills/game-balance/scripts/simulate_progression.py
```

## 모바일 빌드 범위

Android arm64 디버그 빌드가 0.2.0의 완료 플랫폼입니다. Godot Export Templates, Android SDK/JDK와 로컬 디버그 키를 설정한 뒤 다음을 실행합니다.

```bash
godot --headless --path . --export-debug Android build/android/arcane-frontier.apk
```

Android 프리셋은 immersive mode와 진동 권한을 사용합니다. HUD는 `DisplayServer.get_display_safe_area()`를 viewport 좌표로 변환하여 16:9, 19.5:9, 4:3 레이아웃 안쪽에 배치합니다.

iOS 프리셋은 올바른 `.zip` 출력 형식으로만 정리되어 있으며 runnable이 아닙니다. Apple Team ID, 인증서, 실제 iOS 기기 빌드 검증은 이 버전 범위에서 제외됩니다.

## 구조

- `scripts/main.gd`: `ApplicationFlow`, 앱 상태와 저장·재시작 조립
- `scripts/run_world.gd`: 교체 가능한 단일 런의 소유자
- `scripts/encounter_director.gd`: 웨이브, 안전 스폰, 공격권
- `scripts/combat_registry.gd`: 적 등록과 전투 공간 질의
- `scripts/player.gd`: 플레이어 런타임 상태와 ability 실행
- `scripts/enemy.gd`: 역할별 적 FSM과 attack contract
- `data/`: 클래스, ability, 적, 강화 typed Resource
- `scenes/hud.tscn`: safe-area 대응 UI와 모든 사용자 의도 signal
- `docs/architecture.md`: 상태·소유권·저장 계약과 모바일 예산

인벤토리, 장비, 퀘스트, 보스는 현재 vertical slice 범위에 포함되지 않습니다.
