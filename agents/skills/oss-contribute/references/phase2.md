# Phase 2: 코드 수정 및 결과물 생성

## 절차

### 0. 이슈 유형 분기

Phase 1 전략 보고서의 **이슈 유형**을 확인하고 아래에 따라 분기한다:

**이슈 유형 = `bug`:**
브랜치 생성 후 아래 순서로 bug-fix 워크플로우를 실행한다:
1. `~/.agents/skills/bug-fix/references/phase1.md` — 재현 시나리오 구성 및 재현 확인
2. `~/.agents/skills/bug-fix/references/phase2.md` — 원인 분석 (코드 추적 + 가설 검증 + 원인 확정)
3. `~/.agents/skills/bug-fix/references/phase3.md` — 최소 수정
4. `~/.agents/skills/bug-fix/references/phase4.md` — 검증 (재현 시나리오 재실행 + 회귀 확인)

bug-fix 워크플로우 완료 후 아래 Step 3(커밋 전략)부터 이어서 진행한다.

**이슈 유형 = `feature` | `enhancement` | `docs` | `refactor`:**
아래 Step 1(환경 격리)부터 순서대로 진행한다.

---

### 1. 환경 격리
브랜치 생성:
```bash
git checkout -b feat/issue-{이슈번호}
```

### 2. 구현 및 검증

순서대로 진행:

1. **코드 수정**: 이슈 해결을 위한 최소한의 변경 수행
2. **Lint & Type 검사**: 프로젝트 lint/type check 도구 실행, 오류 없어야 함
3. **기존 테스트 실행**: 전체 테스트 스위트 실행 — Side Effect 발생하면 안 됨
4. **관련 유닛 테스트 실행**: 수정된 코드와 직접 관련된 테스트 실행, 반드시 Pass

검증 실패 시 아래 QA 사이클을 실행한다. (최대 3회)

```
[QA Cycle N/3] lint / 테스트 실행 중...
  → 통과: 사이클 종료, Step 3으로 이동
  → 실패: 실패 원인 진단 → 최소 수정 → 재실행
```

**사이클 규칙:**
- 각 사이클 시작 시 `[QA Cycle N/3]` 형식으로 진행 상황을 출력한다
- **같은 실패가 2회 반복**되면 사이클을 중단하고 사용자에게 에스컬레이션한다
- **3사이클 초과** 시 실패 내용과 진단 결과를 사용자에게 보고한다
- **30초 이상 소요되는 빌드/테스트**는 `run_in_background: true`로 백그라운드 실행하고, 완료 알림 수신 후 결과를 확인한다

### 3. 커밋 전략
- 하나의 커밋으로 묶지 말고 **논리 단위로 커밋 분리**
- 프로젝트 컨벤션에 맞는 커밋 메시지 작성 (예: `fix: ...`, `feat: ...`)
- AI 관련 문서는 생성하지 않음 (예: `/superpowers` 같은 파일)

### 4. 산출물 정리
아래 항목을 준비하여 사용자에게 보고:

**커밋 메시지 목록**
- 각 커밋의 메시지와 변경 요약

**PR 제목**
- 기존 PR들의 패턴을 참고하여 작업을 간결하게 요약

**PR 본문**
아래 우선순위에 따라 PR Description 형식을 결정한다:

1. **프로젝트 루트 정책 문서 우선**: `CONTRIBUTING.md`, `CONTRIBUTING.rst`, `.github/CONTRIBUTING.md` 등 기여 정책 문서가 있으면 해당 문서에 명시된 PR 작성 형식을 따른다.

2. **PR 템플릿 차선**: 정책 문서가 없으면 `.github/pull_request_template.md` 또는 `.github/PULL_REQUEST_TEMPLATE/` 하위 템플릿을 확인한다. 템플릿이 있으면 해당 양식을 그대로 사용한다.

3. **기존 Merged PR 참고**: 위 두 가지 모두 없으면 해당 프로젝트의 최근 Merged PR 본문을 3개 이상 참고하여 패턴을 파악하고 동일한 형식으로 작성한다.

4. **기본 형식 (최후 수단)**: 위 세 가지 모두 불가능한 경우에만 아래 기본 형식을 사용한다:
```
## Motivation
(이 PR이 필요한 이유, 해결하는 문제)

## Changes
(구체적으로 어떤 파일이 왜 수정되었는지)

## How to test
(리뷰어가 변경 사항을 검증하는 방법)
```

**작업 요약**
- 어떤 파일이 왜 수정되었는지 짧게 요약

### 5. 스킬 활용
가능한 모든 관련 스킬을 호출하여 기여 가능성을 최대화:
- `lint` 스킬: 코드 품질 검사
- `superpowers:verification-before-completion`: 완료 선언 전 검증
- `superpowers:requesting-code-review`: 구현 후 코드 리뷰 요청

### 6. 사용자 승인 요청
산출물을 보고한 후 사용자의 승인을 받고 Phase 3으로 진행.
