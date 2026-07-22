# Arcane Frontier 실행 구조

## 소유권

- `ApplicationFlow`는 앱 상태, 저장, HUD와 교체 가능한 `RunWorld`를 조립한다.
- `RunWorld`는 한 번의 런에 속하는 플레이어, 웨이브 디렉터, 전투 레지스트리, 투사체와 효과를 소유한다.
- `EncounterDirector`는 웨이브 구성, 안전 스폰, 최대 3개의 공격권(원거리 1개)을 관리한다.
- `CombatRegistry`는 살아 있는 적 목록과 원·부채꼴·선분 질의를 제공한다. 전투 코드는 씬 트리나 그룹을 매 프레임 검색하지 않는다.
- `CharacterClassDefinition`, `AbilityDefinition`, 별도 `AbilityEffectDefinition`, `EnemyDefinition`/`EnemyAttackDefinition`, `UpgradeDefinition`, `FeedbackProfile` typed Resource는 불변 정의만 담는다. HP·경험치·쿨다운·status·강화 중첩은 런타임 객체와 체크포인트가 소유한다.

## 앱 상태 전이

`BOOT → RESUME_CHOICE → CLASS_SELECTION → PLAYING`

`PLAYING`에서는 `WAVE_TRANSITION`, `LEVEL_UP`, `PAUSED`, `GAME_OVER`로 전이할 수 있다. 전투 월드는 `PLAYING`에서만 처리된다. 레벨업과 사망 신호가 같은 프레임에 발생하면 지연 커밋된 사망 전이가 최종 상태를 소유한다.

앱이 백그라운드로 가거나 Android Back이 눌리면 전투가 취소되고 일시정지한다. 복귀 시 자동으로 전투를 재개하지 않는다. 재시작은 기존 `RunWorld`를 종료·제거한 뒤 새 인스턴스를 만든다.

## 저장 계약

- `user://profile.json`: 최고 클리어 웨이브와 접근성·효과 설정
- `user://run_checkpoint.json`: schema/content version, run seed, 시작할 wave, class ID, level, XP, HP, upgrade stacks

체크포인트는 웨이브 시작 직전에 transient 상태와 쿨다운을 정규화한 뒤 원자적으로 기록한다. 임시 파일을 다시 파싱한 뒤 기존 파일을 `.bak`으로 회전한다. 현재 파일이 손상되면 백업을 시도한다. 진행 중 강제 종료 시 현재 웨이브의 처치와 XP는 의도적으로 되돌아간다.

현재 schema는 v1이다. 저장 기능이 없던 prototype 형식(v0)의 `swordsman`/`archer`/`mage` ID는 namespaced class ID로 이관하며, 알 수 없는 schema/content version이나 정의 ID는 로드하지 않는다.

## 모바일 예산

- 활성 적 24
- 동시 공격 3, 원거리 공격 1
- 투사체 48
- 전투 효과 48
- 동시 impact SFX voice 8
- 기본 60 FPS, 낮은 효과 품질 30 FPS

풀링은 현재 도입하지 않는다. 프로파일링에서 생성·해제 비용이 병목으로 확인될 때만 대상별로 추가한다.
