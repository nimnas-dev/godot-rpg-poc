# Arcane Frontier 프로젝트 에이전트 지침

## 프로젝트 기준

- 이 저장소는 Godot 4.3 기반의 Android·iOS용 2D 탑다운 판타지 RPG다.
- 렌더러는 Mobile/GL Compatibility이며, 키보드 프로토타입뿐 아니라 터치 입력, 다양한 화면 비율, safe area, 앱 중단·복귀, 발열·배터리·메모리 비용을 함께 고려한다.
- 핵심 콘텐츠는 검사·궁수·마법사 등의 직업, 직업별 스킬, 전투, 적, 성장, 보상과 탐험이다.
- 작은 vertical slice를 실제로 플레이 가능하게 완성한 뒤 시스템과 콘텐츠를 확장한다.

## 프로젝트 스킬은 필수 규칙이다

`.codex/skills/`의 스킬은 참고용 목록이 아니라 설계·구현·리뷰의 필수 작업 규칙이다. 작업이 스킬 설명의 적용 범위에 들어가면 사용자가 스킬을 직접 지명하지 않아도 반드시 해당 스킬을 적용한다.

모든 게임 코드, 씬, Resource, 프로젝트 설정 변경에는 `$godot-architect`를 기본으로 적용한다. 그 위에 작업 영역에 해당하는 스킬을 모두 추가한다. 여러 스킬이 관련된 작업을 하나의 스킬만으로 처리하지 않는다.

스킬을 적용할 때는 다음을 지킨다.

1. 구현 전에 해당 `SKILL.md`를 끝까지 읽는다.
2. `SKILL.md`가 현재 작업에 연결한 `references/` 문서를 읽고 규칙·체크리스트·산출물을 반영한다.
3. 작업 시작 업데이트에서 사용할 스킬과 적용 이유를 짧게 밝힌다.
4. 스킬의 작업 절차, 필수 규칙, 금지 사항과 완료 조건을 구현 및 리뷰 기준으로 사용한다.
5. 스킬 간 요구가 겹치면 더 엄격한 검증 조건을 따른다. 충돌한다면 임의로 무시하지 말고 충돌 지점과 선택 근거를 알린다.
6. 최종 보고에 사용한 스킬, 주요 설계 결정, 실행한 검증과 남은 위험을 기록한다.

## 작업별 필수 스킬 라우팅

### `$godot-architect`

다음 작업에서는 항상 사용한다.

- `.gd`, `.tscn`, `.tres`, `.res`, `project.godot`, `export_presets.cfg` 변경
- 씬 트리, 노드 책임, 신호, 의존성, Resource, Autoload 또는 파일 구조 변경
- 모바일 성능, 메모리, 로딩, 풀링, 다수 개체 처리
- 기능 추가 전 구조 결정과 기존 구조 리팩터링

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
| 모바일 입력·피드백·성능 | `$godot-architect`, `$game-feel` 및 변경 대상 도메인 스킬 |

표에 없는 작업도 실제 영향 범위를 기준으로 스킬을 추가한다. 예를 들어 적 보상이 바뀌면 enemy 작업이라도 `$build-rpg-system`과 `$game-balance`를 함께 적용한다.

## 구현 전 필수 절차

1. `project.godot`, 관련 씬·스크립트·Resource와 기존 변경 상태를 확인한다.
2. 적용할 스킬을 결정하고 해당 지침과 필요한 참조 문서를 읽는다.
3. 플레이어에게 나타나는 목표 경험과 완료 조건을 한두 문장으로 정의한다.
4. authoritative owner, 데이터 경계, 입력·출력, 생명주기와 저장 여부를 정한다.
5. 밸런스 수치, 상태 전이, 공격 패턴 또는 월드 동선이 있으면 구현 전에 표·그래프·간단한 계약으로 명시한다.
6. 기존 동작을 보존하는 가장 작은 end-to-end 변경을 구현한다.
7. 독립 기능 테스트와 실제 main scene 통합 테스트를 모두 수행한다.

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
- 변경한 scene을 독립 실행할 수 있고 main scene에서도 동작하는가
- 키보드와 터치 입력 모두에서 핵심 경로가 가능한가
- pause, game over, restart, 앱 background/foreground 복귀 후 상태가 중복되거나 소실되지 않는가
- Android·iOS 화면 비율과 safe area에서 HUD와 조작 UI가 잘리지 않는가
- 저사양 모바일 조건에서 frame time, draw call, 메모리, 파티클·오디오 동시 수와 활성 AI 수가 허용 범위인가
- 새 직업·스킬·아이템·적을 기존 resolver의 큰 분기 수정 없이 데이터 중심으로 추가할 수 있는가
- 수치 변경은 목표 지표와 시뮬레이션 또는 플레이테스트 근거가 있는가
- 적 공격, 게임 상태, 저장, 보상 지급과 장비 변경의 경계 사례를 회귀 검증했는가

테스트할 수 없는 항목은 통과한 것으로 간주하지 않는다. 실행하지 못한 검증, 이유와 남은 위험을 최종 보고에 명확히 적는다.

## 문서와 근거

- 엔진 API와 플랫폼 동작은 프로젝트의 Godot 4.3 버전에 맞는 공식 문서를 우선한다.
- 각 스킬의 `references/sources.md`를 연구 출발점으로 사용한다.
- 최신성이나 버전 차이가 중요한 사실은 구현 전에 공식 문서에서 다시 확인한다.
- 외부 자료의 조언은 프로젝트 제약과 실제 플레이테스트로 검증하며 그대로 권위화하지 않는다.
- 새로운 반복 규칙, 데이터 schema, 상태 흐름 또는 성능 한계를 도입했다면 관련 프로젝트 문서나 코드 근처에 유지 가능한 형태로 남긴다.
