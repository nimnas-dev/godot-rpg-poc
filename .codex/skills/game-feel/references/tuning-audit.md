# Game Feel Tuning and Audit

## Event inventory

먼저 플레이 세션의 중요한 사건을 작성한다.

- 이동 시작, 정지, 방향 전환, dash
- 공격 시작, 적중, 빗나감, parry, critical
- 피해, 회복, 상태 이상, 사망
- 아이템 획득, 레벨업, 퀘스트 완료
- UI 선택, 성공, 실패, 잠금

각 사건에 대해 다음 표를 채운다.

| Event | Intended information | Target feeling | Current channels | Missing/conflicting signal | Priority |
|---|---|---|---|---|---|

## Responsiveness audit

- 입력이 들어온 프레임과 첫 화면 변화를 고속 촬영 또는 프레임 캡처로 비교한다.
- animation lock, input buffer, cancel window와 cooldown을 분리해서 기록한다.
- 판정이 animation pose, effect, sound와 같은 순간에 발생하는지 확인한다.
- 터치 입력에서 GUI가 이벤트를 소비하거나 멀티터치 index가 충돌하지 않는지 확인한다.
- 낮은 프레임률에서도 입력 버퍼 시간이 지나치게 짧아지지 않는지 확인한다.

## Clarity audit

- 효과를 제거해도 공격 범위, 위험 방향, 성공·실패를 이해할 수 있는가?
- 같은 색과 모양이 상반된 의미에 사용되지 않는가?
- 적의 전조와 플레이어 효과가 겹쳐도 위험을 볼 수 있는가?
- 반복 피해가 최초 타격보다 더 강하게 보이지 않는가?
- 화면 밖 사건이 카메라 또는 UI를 불필요하게 흔들지 않는가?

## Saturation test

최대 적 수, 최대 공격 속도, 다중 상태 효과, 좁은 공간을 동시에 재현한다.

측정할 항목:

- 화면을 가리는 particle count와 alpha overdraw
- 동시에 재생되는 impact voices
- damage number 수와 겹침
- camera trauma 누적 상한
- effect instance 생성·해제 spikes
- 읽을 수 있는 enemy telegraph 비율

## A/B process

1. 한 번에 한 레이어만 변경한다.
2. 동일한 encounter와 입력 순서를 사용한다.
3. 영상만 보여주는 평가와 직접 조작 평가를 구분한다.
4. `더 화려함` 대신 `적중을 더 빨리 이해함`, `무게가 느껴짐`, `피로가 줄어듦`을 질문한다.
5. 선호도와 실제 수행 결과를 함께 기록한다.

## Accessibility and comfort

최소한 다음 옵션을 고려한다.

- screen shake intensity 또는 off
- hit flash와 전체 화면 flash 감소
- reduced motion profile
- haptic intensity 또는 off
- damage number density
- 색 외의 shape/sound redundancy
- 반복 고주파 사운드 완화

접근성 설정은 단순히 모든 피드백을 제거하지 말고, 제거된 채널의 정보를 다른 채널로 보존한다.
