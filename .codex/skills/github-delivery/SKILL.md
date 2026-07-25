---
name: github-delivery
description: Git 저장소의 기능·버그 수정·리팩터링·설정·문서·스킬 변경을 격리된 브랜치에서 작업 단위별로 선택적 스테이징하고 커밋한 뒤 GitHub pull request를 생성해 검증된 상태로 병합한다. 구현 작업을 기본 브랜치에 반영해야 하거나 사용자가 브랜치, 커밋, push, PR 생성, 자동 병합, 병합 후 동기화를 요청할 때 사용한다.
---

# GitHub Delivery

검증된 변경만 추적 가능한 단위로 기본 브랜치에 전달한다. 구현 방법은 도메인 스킬에 맡기고, 이 스킬은 브랜치부터 병합 후 동기화까지의 delivery lifecycle을 소유한다.

## 책임 경계

- 구현·설계·테스트 기준은 해당 프로젝트와 도메인 스킬을 먼저 적용한다.
- 이 스킬은 Git 상태 격리, 선택적 스테이징, 커밋 구성, push, PR, merge gate와 사후 동기화를 담당한다.
- `github:yeet`, `github:gh-fix-ci`, `github:gh-address-comments`를 사용할 수 있으면 필요한 단계의 실행을 맡기되 이 스킬의 범위·검증·병합 조건을 유지한다.
- release 배포, 패키지 게시, 스토어 제출과 운영 환경 변경은 별도 명시적 요청과 해당 배포 스킬 없이는 수행하지 않는다.

## Delivery contract

작업 시작 전에 다음을 확인하거나 저장소에서 추론한다.

- remote 저장소, 기본 브랜치, 시작 commit과 사용할 GitHub 계정
- 작업 범위, 소유할 파일, 완료 조건과 필요한 검증
- 브랜치 이름, 커밋 분할 기준, PR base와 merge 방식
- 필수 CI·review·branch protection과 병합 후 브랜치 정리 정책

추론한 값이 사용자 의도나 외부 상태를 크게 바꾸지 않으면 진행하고 최종 보고에 남긴다.

## 1. 변경 전 상태를 보호한다

다음을 확인한다.

```bash
git status --short --branch
git branch --show-current
git remote -v
git log -1 --oneline
git config --get user.name
git config --get user.email
gh auth status
gh repo view --json nameWithOwner,defaultBranchRef
```

- 기본 브랜치에서 새 변경을 시작할 때는 원격을 fetch하고 fast-forward 상태를 확인한 뒤 작업 브랜치를 먼저 만든다.
- 저장소 convention이 없으면 `agent/<short-kebab-task>` 형식을 사용한다.
- 이미 현재 작업 전용 브랜치라면 중복 브랜치를 만들지 않는다.
- 기존 untracked·modified·staged 변경은 사용자 소유로 취급한다. 임의로 stash, reset, checkout, 삭제하거나 이번 작업에 포함하지 않는다.
- 작업 시작 전 index에 staged 변경이 있으면 그 경로를 기록하고 delivery commit을 만들지 않는다. 사용자 변경을 unstage하지 말고 사용자가 index 경계를 정리할 때까지 중단한다.
- 기존 변경과 작업 범위를 안전하게 구분할 수 없으면 쓰기를 멈추고 사용자에게 경계를 확인한다.
- 기본 브랜치에 직접 기능 commit을 만들지 않는다.
- `gh` 활성 계정과 commit author가 프로젝트 정책 또는 사용자가 지정한 identity인지 첫 commit 전에 확인한다. token, key와 credential 값은 출력하지 않는다.

### GitHub 계정과 macOS Keychain을 정확히 검증한다

이 저장소의 GitHub 작업 계정은 `nimnas-dev`다. macOS Keychain을 사용하는 환경에서는 제한된 sandbox 안의 `gh auth status`가 Keychain을 읽지 못해 유효한 계정을 `The token is invalid`로 잘못 보고할 수 있다. sandbox 안의 결과만으로 token 만료, 재로그인 필요 또는 권한 부재를 판정하지 않는다.

다음 상황에서는 원래 작업을 중단하거나 다른 인증 방식으로 우회하기 전에 Keychain과 네트워크에 접근 가능한 승인된 실행 환경에서 인증을 다시 확인한다.

- `gh auth status`가 저장된 계정을 invalid로 표시함
- `gh repo view`가 연결 오류 또는 인증 오류를 반환함
- `git push`가 예상과 다른 GitHub 계정의 403을 반환함
- 현재 활성 계정과 프로젝트 정책 계정이 다름

검증과 복구 순서는 다음과 같다.

```bash
gh auth status
gh auth switch -h github.com -u nimnas-dev
gh api user --jq .login
gh repo view --json nameWithOwner,defaultBranchRef
```

1. Keychain 접근이 가능한 환경의 `gh auth status`에서 `nimnas-dev`가 유효한지 확인한다.
2. 유효하지만 inactive이면 별도 확인을 요구하지 않고 `gh auth switch -h github.com -u nimnas-dev`로 전환한다.
3. `gh api user --jq .login` 결과가 정확히 `nimnas-dev`인지 확인한다.
4. `gh repo view`로 대상이 `nimnas-dev/godot-rpg-poc`이고 기본 브랜치가 `main`인지 다시 확인한다.
5. 실패했던 `git push`, PR 또는 merge 명령을 한 번 다시 실행한다.

Keychain 접근이 가능한 재검증에서도 `nimnas-dev`가 없거나 invalid이고 `gh api user`도 실패할 때만 사용자에게 `gh auth login`을 요청한다. `gh auth switch`는 저장된 유효 계정 선택이며 재로그인이 아니다. 이 진단 전에 SSH, 다른 GitHub 계정 또는 read-only connector로 우회하지 않는다. `gh auth token`, credential helper 원문, Keychain 값과 token 실값은 읽거나 출력하지 않는다.

## 2. 범위 안에서 구현하고 검증한다

- 도메인 스킬의 절차와 완료 조건으로 가장 작은 end-to-end 변경을 구현한다.
- 작업 중 새로 발견한 별도 개선은 현재 변경에 섞지 않고 후속 작업으로 기록한다.
- 관련 정적 검사, 테스트, 빌드와 통합 검증을 실행한다.
- 완료 조건이 충족되지 않았거나 필수 검증이 실패하면 delivery 완료로 진행하지 않는다.

## 3. 기능 단위로 스테이징하고 커밋한다

각 독립 변경 단위마다 다음 순서를 반복한다.

1. `git status --short`와 `git diff -- <paths>`로 소유 파일과 실제 diff를 검토한다.
2. `git add -- <explicit-paths>`로 해당 단위의 파일만 스테이징한다.
3. `git diff --cached --check`, `git diff --cached --stat`, `git diff --cached`를 검토한다.
4. staged path 집합이 현재 기능 단위의 명시적 경로와 정확히 일치하고 credential, generated artifact, 임시 파일과 무관한 사용자 변경이 없는지 확인한다.
5. 한 가지 의도를 설명하는 명령형 commit message로 커밋한다.
6. `git show --stat --oneline --decorate HEAD`와 author identity를 확인한다.

staged path가 하나라도 예상과 다르면 commit하지 않는다. 기존 변경이 있거나 범위가 혼합되었을 때 `git add .`, `git add -A`와 포괄 glob을 사용하지 않는다. 여러 기능 단위를 하나의 거대 commit으로 합치거나 하나의 기능을 이유 없이 미세 commit으로 쪼개지 않는다.

## 4. Push하고 ready PR을 만든다

- 현재 브랜치를 명시적으로 `git push --set-upstream origin <branch>` 한다. force push는 사용자가 승인한 history rewrite 외에는 사용하지 않는다.
- `gh pr list --head <branch> --state open`으로 같은 head의 열린 PR을 먼저 찾는다. 존재하면 새 PR을 만들지 말고 해당 PR을 갱신·검증한다.
- 완료된 작업은 draft가 아닌 ready PR로 만든다.
- PR 본문에 목적, 주요 변경, 정확한 검증 명령과 결과, 미검증 항목·위험, rollback 또는 호환성 정보를 기록한다.
- PR 생성 후 base/head, 전체 diff, commit 목록, mergeability와 check·review 상태를 다시 확인한다.
- PR diff에 범위 밖 파일이나 commit이 있으면 병합 전에 바로잡는다.

## 5. Merge gate를 통과한 뒤 자동 병합한다

다음을 모두 만족해야 한다.

- 요청한 완료 조건을 달성했고 PR diff가 승인된 작업 범위와 일치한다.
- 필수 테스트와 검증이 통과했으며 실패를 성공으로 오인하지 않았다.
- PR이 충돌 없이 mergeable하다.
- 필수 CI, review, branch protection과 unresolved conversation 조건을 충족한다.
- secret, credential, 불필요한 generated artifact와 무관한 사용자 변경이 없다.
- 사용자가 review 대기, draft 유지 또는 병합 금지를 지시하지 않았다.

필수 check가 진행 중이면 상태를 추적하고 통과 후 병합한다. 저장소가 auto-merge를 지원하면 gate 충족을 조건으로 예약할 수 있다. 실패한 check는 범위 안에서 원인을 고치고 다시 검증하며, check를 비활성화하거나 admin 권한으로 보호 규칙을 우회하지 않는다.

CI나 필수 review가 구성되지 않은 저장소에서는 완료 조건에 맞는 로컬 검증 증거와 GitHub의 mergeable 상태를 merge gate로 사용한다. 저장소가 지정한 merge 방식을 따르고, 별도 정책이 없으면 merge commit을 사용한다.

## 6. 병합과 동기화를 증명한다

- PR 상태가 `MERGED`인지, `mergedAt`과 merge commit SHA가 존재하는지 확인한다.
- 원격 기본 브랜치가 병합 결과를 포함하는지 확인한다.
- `git status --porcelain`이 비어 있고 unpushed commit이 없을 때만 로컬 기본 브랜치로 전환해 fetch 후 fast-forward 동기화한다.
- 병합이 증명되고 worktree가 깨끗한 작업 브랜치만 프로젝트 정책에 따라 원격과 로컬에서 정리한다. unmerged branch는 삭제하지 않는다.
- dirty worktree가 전환을 막으면 stash나 reset하지 말고 현재 브랜치와 원격 branch를 모두 보존한 채 정확히 보고한다.

## 중단 조건

다음 상태에서는 PR을 병합하지 않는다.

- 작업 미완료, 검증 실패 또는 재현하지 못한 중대한 위험
- merge conflict, 필수 check 실패, 필수 review 대기 또는 unresolved conversation
- Keychain 접근 가능한 환경의 재검증과 계정 전환 후에도 남는 GitHub 계정·commit identity 불일치, 인증·권한 부족 또는 remote 불일치
- 포함 범위를 판별할 수 없는 기존 사용자 변경
- branch protection 우회나 새로운 외부 권한이 필요한 상태

가능하면 안전한 범위의 원인을 해결하고 gate를 다시 평가한다. 해결할 수 없으면 branch와 commit을 보존하고 현재 PR 상태, 차단 조건과 필요한 후속 조치를 보고한다.

## 완료 보고

- 사용한 branch, commit SHA·제목과 commit author
- PR 번호·링크·base/head와 최종 상태
- 실행한 검증과 check·review 결과
- merge commit SHA와 원격·로컬 기본 브랜치 동기화 상태
- 실제 GitHub 활성 계정과 Keychain 접근 가능한 환경에서의 인증 검증 결과
- 삭제하거나 보존한 branch, 미검증 항목과 남은 위험
