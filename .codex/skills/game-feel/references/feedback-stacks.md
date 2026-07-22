# Feedback Stacks

수치는 출발점일 뿐이다. 카메라 배율, 아트 스타일, 프레임률, 모바일 화면 크기와 실제 플레이테스트에 맞춰 조정한다.

## Timing anatomy

| Phase | Purpose | Questions |
|---|---|---|
| Anticipation | 행동과 위험을 예고 | 플레이어가 반응할 시간이 있는가? |
| Action | 입력이 실행됨을 확인 | 첫 시각·음향 반응이 즉시 시작하는가? |
| Contact | 판정 위치와 성공을 알림 | 무엇을 맞혔고 얼마나 강했는가? |
| Impact | 사건 중요도와 무게를 증폭 | 시간·카메라·음향이 같은 순간에 정렬되는가? |
| Recovery | 다음 선택 가능 시점을 전달 | 입력 버퍼와 취소 가능 상태가 읽히는가? |

## Melee hit stack

### Light hit

- 짧고 선명한 contact flash
- 진행 방향을 따르는 소량의 impact particles
- 작은 피격 pose 또는 knockback
- 짧은 transient 중심의 SFX
- 카메라 흔들림 없이 공격자 애니메이션의 미세한 ease

### Heavy hit

- 강한 anticipation pose와 명확한 active frame
- 접촉점 directional burst
- 공격자와 피격자의 짧은 정지 또는 매우 느린 구간
- 저역 body가 포함된 layered SFX
- 감쇠가 빠른 camera impulse
- 더 큰 knockback, 환경 흔적 또는 적절한 피해 숫자 강조

Hit-stop의 대략적인 실험 범위는 light 20~40 ms, medium 40~80 ms, heavy 80~120 ms로 시작할 수 있다. 프레임 고정값이 아니라 실제 시간과 게임 리듬을 기준으로 테스트하고, 빠른 반복 공격에는 더 짧게 적용한다.

## Projectile stack

- 발사: muzzle shape, recoil pose, firing transient
- 비행: 읽을 수 있는 silhouette와 team/color language
- 접촉: 이동 방향에 맞춘 burst와 hit flash
- 관통: 첫 타격 이후에도 경로가 읽히는 trail 변화
- 빗나감: 벽·지면 반응으로 판정 위치를 설명

투사체가 빠를수록 발사 순간과 도착 지점의 정보가 중요하다. trail을 길게 만드는 것만으로 해결하지 않는다.

## Magic stack

- charge 단계에서 위험 범위와 속성을 예고한다.
- cast와 impact의 음색을 구분한다.
- 원소별 색뿐 아니라 모양, 운동, 음향 성격도 구분한다.
- 지속 피해는 첫 타격보다 약한 반복 신호를 사용한다.
- 범위 공격은 실제 판정 반경과 시각 반경을 일치시킨다.

## Movement stack

- 입력 시작에 가속 pose 또는 즉시 silhouette 변화를 준다.
- 방향 전환은 마찰과 회전 시간으로 캐릭터 성격을 표현한다.
- 발걸음, 먼지, 착지 반응은 표면과 속도에 비례시킨다.
- dash는 출발, 이동, 도착을 구분하며 무적 구간을 읽을 수 있게 한다.
- 조작이 무거워야 하더라도 입력이 무시된다는 인상을 주지 않는다.

## Camera impulse model

각 사건은 카메라 위치를 직접 덮어쓰지 말고 impulse를 제출한다.

```text
impulse = direction * amplitude
trauma = clamp(trauma + event_strength, 0, 1)
offset = noise(time) * max_offset * trauma^2
trauma decays over time
```

- 공격 방향 또는 접촉 법선을 활용한다.
- 연속 타격은 무한 누적하지 않는다.
- UI와 조준점은 필요에 따라 흔들림에서 분리한다.
- `reduced motion`에서는 카메라 대신 국소 flash, 음향, 햅틱을 강화할 수 있다.

## Audio stack

Impact SFX를 역할로 나눈다.

- transient: 타격 시점과 재질의 날카로움
- body: 질량과 힘
- tail: 공간과 잔향

반복 샘플은 작은 pitch/volume 변화와 sample pool을 사용한다. 중요한 사건이 사소한 반복음에 묻히지 않도록 동시 재생 수와 bus priority를 관리한다. Master 출력 clipping을 방지한다.

## Priority tiers

| Tier | Examples | Treatment |
|---|---|---|
| Critical | player death, boss phase, level up | 여러 감각 레이어, 독점적 공간 허용 |
| Strong | critical hit, heavy skill, elite defeat | 짧은 temporal/camera accent |
| Routine | basic hit, pickup, footsteps | 빠르고 국소적인 명확성 |
| Ambient | leaves, distant particles | gameplay signals와 경쟁하지 않음 |

동시에 발생하면 상위 tier를 보존하고 하위 tier의 파티클, 숫자, 음향을 줄인다.
