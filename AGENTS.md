# Arcane Frontier 프로젝트 에이전트 지침

## 프로젝트 기준

- 이 저장소는 `project.godot` 기준 현재 Godot 4.3 기반의 Android·iOS용 2D 탑다운 판타지 RPG다.
- 렌더러는 Mobile/GL Compatibility이며, 키보드 프로토타입뿐 아니라 터치 입력, 다양한 화면 비율, safe area, 앱 중단·복귀, 발열·배터리·메모리 비용을 함께 고려한다.
- 핵심 콘텐츠는 검사·궁수·마법사 등의 직업, 직업별 스킬, 전투, 적, 성장, 보상과 탐험이다.
- 작은 vertical slice를 실제로 플레이 가능하게 완성한 뒤 시스템과 콘텐츠를 확장한다.

## 서브에이전트 모델과 병렬 작업

루트 에이전트가 전체 목표, 스킬 선택, 사용자 소통, 변경 통합과 최종 검증을 소유한다. 서브에이전트는 독립적이고 경계가 명확한 하위 작업에만 사용하며, 단순 작업에 의무적으로 생성하지 않는다.

### 모델 프로필

현재 Codex 환경에서 `gpt-5.6-luna`가 노출되지 않는 동안 모든 서브에이전트는 `gpt-5.6-terra`만 사용한다. `gpt-5.6-sol`은 기획·추론·분석·설계 용도이므로 서브에이전트 구현·조사·검증 모델로 지정하지 않는다. Luna가 다시 노출되더라도 이 지침을 명시적으로 갱신하기 전에는 자동으로 사용하지 않는다.

| 프로필 | model override | reasoning effort | 사용 범위 |
| --- | --- | --- | --- |
| Terra 기본 | `gpt-5.6-terra` | `medium` | 범위가 명확한 구현, inventory, 테스트 실행, 문서 정리 |
| Terra 심층 | `gpt-5.6-terra` | `high` | 중간 난도 구현, 원인 분석, 코드 리뷰, 플랫폼별 조사 |
| Terra 고난도 | `gpt-5.6-terra` | `xhigh` | migration 위험 조사, 복합 결함 재현, 독립적 architecture 대안 검토와 adversarial review |

model override를 지정할 때 `fork_turns="all"`을 사용하지 않는다. 최근 문맥이 필요하면 양의 turn 수를, 완전히 self-contained한 작업이면 `fork_turns="none"`을 사용하고 task message에 목표·제약·파일을 모두 적는다.

권장 생성값:

```text
기본 작업: model="gpt-5.6-terra", reasoning_effort="medium", fork_turns="3"
심층 작업: model="gpt-5.6-terra", reasoning_effort="high", fork_turns="3"
고난도 검토: model="gpt-5.6-terra", reasoning_effort="xhigh", fork_turns="3"
```

### 난이도에 따른 라우팅

다음 기준으로 가장 가벼운 충분한 구성을 선택한다.

| 작업 상태 | 실행 방식 |
| --- | --- |
| 한 파일의 명확한 수정, 짧은 설명, 순차 의존성이 강한 작업 | 루트가 직접 수행 |
| 서로 겹치지 않는 2개 이상의 inventory·문서 조사·테스트·플랫폼 검증 | Terra를 병렬 배치 |
| 범위가 명확한 여러 구현 단위이며 파일 소유권을 분리할 수 있음 | Terra에 파일별로 배치하고 루트가 통합 |
| 엔진 migration, 저장 호환성, 여러 시스템의 architecture 결정, 재현이 어려운 결함 | 루트가 기획·설계를 소유하고 여러 Terra 심층 에이전트에 독립 조사·대안·위험 분석을 병렬 요청 |
| 구현과 독립적 adversarial review가 모두 필요한 고위험 변경 | 서로 다른 Terra에 구현과 read-only 리뷰를 분리하고 루트가 상충 결과를 판단 |
| 설계 결과가 나와야 구현 범위가 정해지는 작업 | 루트가 Terra 조사 결과를 종합해 설계를 확정한 뒤 구현을 순차 진행 |

예상 시간이 짧거나 서브에이전트 조정 비용이 더 큰 작업은 직접 수행한다. 병렬화는 독립 작업의 총 지연을 줄일 때만 사용한다.

### 병렬 작업 안전 규칙

1. 루트는 적용할 모든 `SKILL.md`와 필수 reference를 직접 끝까지 읽고 공통 계약을 먼저 정한다. 이 책임을 서브에이전트에 위임하지 않는다.
2. 각 task message에 한 개의 구체적 산출물, 읽기·쓰기 허용 범위, 적용 스킬, 금지 사항, 검증 명령과 완료 조건을 적는다.
3. 같은 `.gd`, `.tscn`, `.tres`, `project.godot`, `export_presets.cfg`, 문서 또는 생성 artifact를 여러 에이전트가 동시에 수정하지 않게 파일 owner를 하나만 둔다.
4. scene과 연결 script, Resource definition과 resolver처럼 함께 변해야 하는 파일은 하나의 작업 단위로 묶는다. 줄 단위로 억지 분할하지 않는다.
5. 설계·migration 조사·코드 리뷰처럼 read-only인 작업은 구현과 병렬화할 수 있지만, 구현 계약을 바꿀 발견은 즉시 루트에 전달한다.
6. 서브에이전트는 루트의 명시적 요청 없이 다시 하위 에이전트를 생성하지 않는다.
7. 도구가 보고한 가용 동시성에서 루트 슬롯 하나를 남긴다. 현재 root 포함 4-slot 환경에서는 동시에 최대 3개 child만 실행한다.
8. destructive action, secret·signing credential 접근, 외부 제출·배포와 사용자 결정이 필요한 변경은 서브에이전트에 독립 위임하지 않는다.
9. 루트는 결과를 그대로 신뢰하지 않고 diff, 로그, 테스트와 스킬 완료 조건을 직접 검토한다.
10. 한 에이전트의 실패로 독립 작업까지 취소하지 않는다. 실패 범위를 격리하고 안전한 다른 작업을 계속 진행한다.

### 서브에이전트 완료 계약

각 서브에이전트는 다음을 반환한다.

- 수행한 범위와 변경한 파일
- 핵심 판단과 사용한 근거
- 실행한 명령·테스트와 결과
- 실패·미검증 항목과 남은 위험
- 루트가 통합 전에 확인해야 할 충돌 또는 후속 작업

루트는 병렬 결과를 합친 뒤 중복 변경, 상충하는 가정, scene/resource reference와 target platform 차이를 확인하고 end-to-end 검증을 다시 실행한다. 최종 보고에는 사용한 Terra 작업별 역할, reasoning effort, 통합 판단과 미검증 위험을 함께 기록한다.

## 프로젝트 스킬은 필수 규칙이다

`.codex/skills/`의 스킬은 참고용 목록이 아니라 설계·구현·리뷰의 필수 작업 규칙이다. 작업이 스킬 설명의 적용 범위에 들어가면 사용자가 스킬을 직접 지명하지 않아도 반드시 해당 스킬을 적용한다.

모든 게임 코드, 씬, Resource, 프로젝트 설정 변경에는 `$godot-architect`를 기본으로 적용한다. 그 위에 작업 영역에 해당하는 스킬을 모두 추가한다. 여러 스킬이 관련된 작업을 하나의 스킬만으로 처리하지 않는다.

Godot 엔진 버전, API·직렬화·import·UID, renderer·physics backend의 버전 호환성이 관련되면 `$godot-migration`을 반드시 추가한다. `$godot-migration`은 source/target 엔진 이관을, `$godot-architect`와 도메인 스킬은 런타임 구조와 게임 동작 보존을 각각 소유한다.

export preset·template, 플랫폼 SDK·툴체인, package·architecture, 서명·notarization, artifact·설치·스토어 출시가 관련되면 `$godot-build-platform`을 반드시 추가한다. 엔진을 바꾸고 대상 플랫폼 빌드까지 검증하는 작업은 두 스킬을 함께 사용하되 migration gate와 build gate를 별도로 보고한다.

스킬을 적용할 때는 다음을 지킨다.

1. 구현 전에 해당 `SKILL.md`를 끝까지 읽는다.
2. `SKILL.md`가 현재 작업에 연결한 `references/` 문서를 읽고 규칙·체크리스트·산출물을 반영한다.
3. 작업 시작 업데이트에서 사용할 스킬과 적용 이유를 짧게 밝힌다.
4. 스킬의 작업 절차, 필수 규칙, 금지 사항과 완료 조건을 구현 및 리뷰 기준으로 사용한다.
5. 스킬 간 요구가 겹치면 더 엄격한 검증 조건을 따른다. 충돌한다면 임의로 무시하지 말고 충돌 지점과 선택 근거를 알린다.
6. 최종 보고에 사용한 스킬, 주요 설계 결정, 실행한 검증과 남은 위험을 기록한다.

## 작업별 필수 스킬 라우팅

### `$godot-migration`

다음 작업에서는 항상 사용한다.

- Godot 엔진 upgrade·downgrade, Standard/.NET/custom editor 변경
- `project.godot`의 `config/features`, renderer, physics backend나 엔진 호환 설정 변경
- GDScript·C# API, scene·Resource 직렬화, import·UID와 changed default 이관
- .NET editor, GDExtension, editor plugin과 native extension의 엔진 버전 호환성 이관
- 엔진 변경 전후 renderer·physics·navigation·audio·input·save 동작 회귀 검증

작업 시작 시 정적 inventory를 실행하고 결과를 수동 검토한다.

```bash
python3 .codex/skills/godot-migration/scripts/migration_preflight.py . \
  --godot-bin /absolute/path/to/target-godot --target-version 4.7.stable
```

정적 inventory나 target editor의 파일 저장만으로 migration 완료 판정을 내리지 않는다. source/target engine, rollback 지점과 import·runtime gate를 먼저 정한다.

### `$godot-build-platform`

다음 작업에서는 항상 사용한다.

- `export_presets.cfg`, export template, custom template 또는 build CI 추가·변경
- Android/iOS/Web/Windows/macOS/Linux/dedicated server target 추가·변경
- JDK, Android SDK, Gradle, Xcode와 플랫폼별 SDK·toolchain 구성
- package·bundle ID, version, architecture, permission, entitlement와 privacy 설정
- APK, AAB, Xcode project/archive, Web bundle, desktop package와 server artifact 생성
- code signing, notarization, provisioning, device 설치·브라우저 hosting, store 제출과 release readiness 검증

작업 시작 시 secret을 읽지 않는 정적 inventory를 실행하고 결과를 수동 검토한다.

```bash
python3 .codex/skills/godot-build-platform/scripts/platform_build_preflight.py . \
  --godot-bin /absolute/path/to/godot --platform Android
```

사전 진단, preset 존재나 export exit code만으로 빌드·설치·출시 가능 판정을 내리지 않는다. Configure, Export, Inspect, Install/Host, Runtime과 Release gate를 구분한다.

### `$godot-architect`

다음 작업에서는 항상 사용한다.

- `.gd`, `.tscn`, `.tres`, `.res`, `project.godot`의 게임 구조와 런타임 설정 변경
- 씬 트리, 노드 책임, 신호, 의존성, Resource, Autoload 또는 파일 구조 변경
- 모바일 성능, 메모리, 로딩, 풀링, 다수 개체 처리
- 기능 추가 전 구조 결정과 기존 구조 리팩터링

엔진 API·직렬화 포맷 호환성은 `$godot-migration`이, platform export·artifact 호환성은 `$godot-build-platform`이 소유한다. 이 작업들로 씬·Resource·노드 책임이나 성능 구조가 바뀌면 `$godot-architect`를 함께 적용한다.

구조 변경 뒤에는 가능하면 다음 감사를 실행하고 결과를 수동 검토한다.

```bash
python3 .codex/skills/godot-architect/scripts/audit_godot_architecture.py .
```

### `$game-feel`

입력 반응, 이동, 공격, 피격, 애니메이션, hit-stop, 카메라, 파티클, 사운드, 햅틱, 피해 숫자 또는 UI 피드백을 변경할 때 사용한다. 판정과 연출을 분리하고, 반복 전투의 효과 포화와 reduced motion·진동·화면 흔들림 옵션을 검증한다.

### `$game-loop`

core loop, encounter/session/meta loop, boot·title·loading·playing·paused·game over·results·restart·resume 흐름을 변경할 때 사용한다. 상태 owner와 전이 표를 먼저 정하고, pause·중단·복귀·재시작의 중복 신호, 타이머, 적과 입력을 회귀 검증한다.

### `$game-balance`

피해, 체력, 방어, 사거리, 속도, cooldown, 자원 비용, 경험치, 성장률, 가격, 드롭률, 적 수치 또는 난이도를 변경할 때 사용한다. 감으로 숫자를 정하지 말고 목표 지표, 기준값, 단위, 공식과 비교 시나리오를 남긴다. 확률이나 성장 곡선이 포함되면 다음 도구를 시작점으로 사용한다.

```bash
python3 .codex/skills/game-balance/scripts/simulate_progression.py
```

### `$build-rpg-system`

직업, 스킬, 능력치, status/effect, 장비, 인벤토리, 전리품, 경험치, 레벨, 퀘스트, progression 또는 저장·불러오기를 설계·구현할 때 사용한다. definition data, runtime state와 presentation을 분리하고 stable ID, typed Resource, 저장 schema version과 migration을 사용한다.

### `$build-rpg-enemy`

적, 몬스터, AI, 감지, 이동, 공격 패턴, 전조, 역할 조합, wave, elite, boss 또는 encounter를 만들거나 수정할 때 사용한다. 새 적의 player question, counterplay, 상태 흐름, attack contract와 다수 전투 공정성을 먼저 정의한다.

### `$build-rpg-world`

필드, 던전, 방, TileMapLayer, TileSet, collision, navigation, landmark, 갈림길, 비밀, gate, shortcut, encounter·보상 배치 또는 지역 로딩을 만들거나 수정할 때 사용한다. art pass 전에 blockout으로 실제 이동 시간, 길찾기, 전투 공간과 탐험 보상을 검증한다.

## 자주 쓰는 필수 스킬 조합

| 작업 | 반드시 함께 적용할 스킬 |
| --- | --- |
| 새 직업 또는 직업 스킬 | `$godot-architect`, `$build-rpg-system`, `$game-balance`, `$game-feel` |
| 전투 공식 또는 status/effect 변경 | `$godot-architect`, `$build-rpg-system`, `$game-balance`; 표현이 바뀌면 `$game-feel` |
| 새 일반 적 또는 공격 패턴 | `$godot-architect`, `$build-rpg-enemy`, `$game-balance`, `$game-feel` |
| 보스와 보스방 | `$godot-architect`, `$build-rpg-enemy`, `$build-rpg-world`, `$game-balance`, `$game-feel`, `$game-loop` |
| 신규 필드·던전 | `$godot-architect`, `$build-rpg-world`, `$build-rpg-enemy`; 보상·진행이 있으면 `$build-rpg-system`, `$game-balance` |
| 게임오버·재시작·pause·scene 전환 | `$godot-architect`, `$game-loop`; 저장 상태가 바뀌면 `$build-rpg-system` |
| 저장·불러오기와 앱 복귀 | `$godot-architect`, `$build-rpg-system`, `$game-loop` |
| Godot 엔진 버전 변경 | `$godot-migration`, `$godot-architect`; 저장·입력·게임 흐름 등 실제 영향 도메인 스킬 추가, target artifact까지 검증하면 `$godot-build-platform` 추가 |
| 신규 플랫폼 export 또는 출시 | `$godot-build-platform`; 런타임 적응이 있으면 `$godot-architect`, `$game-feel`, `$game-loop` 및 영향 도메인 스킬 추가 |
| 모바일 입력·피드백·성능 | `$godot-architect`, `$game-feel` 및 변경 대상 도메인 스킬; SDK·export·실기기 release 검증은 `$godot-build-platform` 추가 |

표에 없는 작업도 실제 영향 범위를 기준으로 스킬을 추가한다. 예를 들어 적 보상이 바뀌면 enemy 작업이라도 `$build-rpg-system`과 `$game-balance`를 함께 적용한다.

## 구현 전 필수 절차

1. `project.godot`, 관련 씬·스크립트·Resource와 기존 변경 상태를 확인한다.
2. 적용할 스킬을 결정하고 해당 지침과 필요한 참조 문서를 읽는다.
3. 엔진 작업이면 source/target exact version, baseline, rollback과 import·runtime gate를 migration contract로 정한다.
4. 플랫폼 작업이면 target·artifact·architecture·signing·배포 채널과 검증 환경을 build contract로 정한다.
5. 플레이어에게 나타나는 목표 경험과 완료 조건을 한두 문장으로 정의한다.
6. authoritative owner, 데이터 경계, 입력·출력, 생명주기와 저장 여부를 정한다.
7. 밸런스 수치, 상태 전이, 공격 패턴 또는 월드 동선이 있으면 구현 전에 표·그래프·간단한 계약으로 명시한다.
8. 기존 동작을 보존하는 가장 작은 end-to-end 변경을 구현한다.
9. 독립 기능 테스트와 실제 main scene 통합 테스트를 모두 수행한다.
10. 대상 플랫폼이 있으면 실제 artifact 검사, 설치·launch와 release 요구를 별도 검증한다.

요청이 단순 버그 수정이어도 원인을 고치며, 스킬의 금지 사항을 우회하는 임시 전역 상태나 하드코딩을 추가하지 않는다.

## 공통 아키텍처 규칙

- 부모 또는 명시적인 coordinator가 하위 기능을 조립하고 시스템 간 반응을 연결한다.
- 자식이 `/root`, 다단계 `get_parent()`, 광범위한 트리 검색으로 의존성을 찾지 않게 한다.
- 필수 의존성은 typed API, exported property 또는 초기화 메서드로 주입한다.
- 사건 통지는 signal을 사용하되 한 기능 내부의 명확한 호출까지 무조건 signal로 바꾸지 않는다.
- 정의 데이터는 typed custom Resource, 개체별 현재 상태는 runtime state에 둔다. 공유 Resource 원본에 현재 HP, cooldown, 수량을 기록하지 않는다.
- 저장 키와 콘텐츠 참조에는 표시 이름이 아닌 stable ID를 사용한다.
- UI와 연출은 도메인 규칙의 owner가 되지 않는다.
- 모든 것을 담당하는 거대한 `GameManager`, `player.gd`, `main.gd`를 만들지 않는다.
- 매 프레임 전체 그룹·트리 검색, 경로 재계산, 동적 로드와 반복 생성·해제를 피한다.
- 성능 최적화는 프로파일링 결과와 목표 모바일 기기 조건을 근거로 한다.

## RPG 품질 기준

- 직업은 수치 차이만이 아니라 행동, 자원, 거리, timing, 강점과 약점으로 구분한다.
- 스킬은 명시적인 cost, cooldown, targeting, effect, interruption, feedback과 upgrade 경계를 가진다.
- 적 피해는 읽을 수 있는 전조와 회피·방어·중단 같은 counterplay를 제공한다.
- 난이도는 HP·피해 배율만 올리지 않고 역할 조합, 공간, timing과 목표를 변화시킨다.
- 보상은 전투·탐험·성장 loop로 다시 연결되며 필수 진행을 무작위 드롭 하나에 맡기지 않는다.
- 월드는 빈 이동 시간을 늘리기보다 landmark, 의미 있는 갈림길, optional loop, shortcut과 발견 보상을 제공한다.
- 타격 연출은 입력 반응과 판정 명확성을 보강해야 하며 플레이 정보를 가리지 않는다.

## 검증 및 완료 조건

변경 규모에 비례해 다음을 검증한다.

- Godot 프로젝트가 parse/load되며 새 오류와 경고가 없는가
- migration이면 source/target exact version과 관련 breaking change를 검토하고 import·runtime gate를 통과했는가
- platform build이면 editor와 export template이 정확히 일치하는가
- 변경한 scene을 독립 실행할 수 있고 main scene에서도 동작하는가
- 키보드와 터치 입력 모두에서 핵심 경로가 가능한가
- pause, game over, restart, 앱 background/foreground 복귀 후 상태가 중복되거나 소실되지 않는가
- Android·iOS 화면 비율과 safe area에서 HUD와 조작 UI가 잘리지 않는가
- 대상 플랫폼 artifact가 실제 생성되고 올바른 architecture·서명으로 설치·launch되는가
- 저사양 모바일 조건에서 frame time, draw call, 메모리, 파티클·오디오 동시 수와 활성 AI 수가 허용 범위인가
- 새 직업·스킬·아이템·적을 기존 resolver의 큰 분기 수정 없이 데이터 중심으로 추가할 수 있는가
- 수치 변경은 목표 지표와 시뮬레이션 또는 플레이테스트 근거가 있는가
- 적 공격, 게임 상태, 저장, 보상 지급과 장비 변경의 경계 사례를 회귀 검증했는가

테스트할 수 없는 항목은 통과한 것으로 간주하지 않는다. 실행하지 못한 검증, 이유와 남은 위험을 최종 보고에 명확히 적는다.

## 문서와 근거

- 일반 구현은 `project.godot`이 선언한 현재 버전(현재 Godot 4.3)에 맞는 공식 문서를 우선한다. 엔진 업데이트는 source부터 target까지 각 버전의 공식 migration guide를 `$godot-migration` 기준으로, export·출시는 target 버전의 공식 export 문서와 플랫폼 소유자의 현재 정책을 `$godot-build-platform` 기준으로 적용한다.
- 각 스킬의 `references/sources.md`를 연구 출발점으로 사용한다.
- 최신성이나 버전 차이가 중요한 사실은 구현 전에 공식 문서에서 다시 확인한다.
- 외부 자료의 조언은 프로젝트 제약과 실제 플레이테스트로 검증하며 그대로 권위화하지 않는다.
- 새로운 반복 규칙, 데이터 schema, 상태 흐름 또는 성능 한계를 도입했다면 관련 프로젝트 문서나 코드 근처에 유지 가능한 형태로 남긴다.
