# Handoff — 공통 워크플로우

모든 host에서 공유되는 작성 절차·템플릿·원칙. host별 경로·CLI 차이는 adapter에서 처리한다.

---

## Preflight Checklist (작성 전 확인)

아래 중 **하나라도 해당되지 않으면 handoff 작성을 보류하고 더 가벼운 수단을 제시한다.**

| 질문 | 예 → handoff 필요 | 아니오 → 대안 |
|---|---|---|
| 세션을 지금 끝내거나 `/clear`할 예정인가? | ○ | 계속 진행 |
| 방금 시도가 실패해서 접근을 바꾸는 건가? | ○ | `/rewind` (Esc Esc 두 번) — 실패 지점 직전으로 되돌리고 학습을 새 프롬프트에 녹여 컨텍스트 오염을 원천 차단 |
| 컨텍스트가 포화(>70%)거나 무관한 task로 전환하는가? | ○ | `/compact focus on <key decisions>` — 단 focus 인자 필수. 인자 없는 auto-compact는 비신뢰 |
| 며칠 이상 재개하지 않을 가능성이 있는가? | ○ | 계속 진행 |
| 여러 세션·에이전트가 병렬로 같은 영역을 건드리는가? | ○ | Registry 패턴 고려 (reports/ 분리) |

→ Preflight에서 "대안"이 적절하다고 판단되면 사용자에게 제안하고 대기한다. 사용자가 그래도 handoff를 원하면 진행.

---

## 실행 단계

### Step 1. 경로 결정
adapter의 경로 규약에 따라 `~/.agents/handoffs/{host}/{project}/{YYYY-MM-DD}-{slug}/HANDOFF.md` 확정.
- `{project}`: git repo면 `basename $(git rev-parse --show-toplevel)`, 아니면 `harness`
- `{slug}`: 인자로 받았으면 사용, 아니면 세션 목표를 소문자-하이픈으로 자동 변환 (예: `add-auth`, `fix-login-bug`)
- 이미 같은 경로 존재 → update/new 선택을 사용자에게 묻는다

### Step 2. 세션 상태 수집
아래 정보를 수집한다. 추측하지 말고 확인된 것만 쓴다.
- 세션 목표 (Rule 0의 "목표" — 한 문장)
- 완료된 작업 (실제 머지·커밋·테스트 통과만)
- 시도했고 실패한 접근 (+ **이유**)
- 미해결 질문·가정
- 건드린 주요 파일 (라인 범위)
- 사용자와 합의된 제약·결정

### Step 3. 초안 작성
아래 템플릿을 따라 작성. 채울 게 없는 섹션은 `(없음)`으로 명시 (삭제하지 않음). 총 2,000 토큰 이내.

### Step 4. 자체 검토 (5대 원칙 체크)
작성 후 저장 전에 self-check:
- [ ] Open Work가 모두 상태 서술형인가? (명령형 동사 금지)
- [ ] Relevant Files에 라인 범위가 있는가?
- [ ] Traps to Avoid가 비어있지 않은가?
- [ ] Prompt for New Chat에 "Read로 검증" 지시가 있는가?
- [ ] CLAUDE.md와 중복되는 규약을 다시 적지 않았는가?
- [ ] 2,000 토큰 이하인가? (초과 시 `reports/` 분리)

### Step 5. 사용자 확인
초안 전체를 보여주고 저장 여부 확인. checkpoint 모드면 `AskUserQuestion`으로 "저장 후 세션 종료" / "수정 필요" / "저장만 하고 계속" 선택지 제시.

### Step 6. 저장
확인된 경로에 쓰기. 상위 디렉토리 없으면 `mkdir -p`.

### Step 7. 종료 안내
저장 후 다음 메시지를 출력:
```
✅ HANDOFF 저장: <경로>
📋 새 세션 부팅:
   1. /clear
   2. 다음 프롬프트를 붙여넣기:
      @<경로> 위 문서를 읽고 Prompt for New Chat 섹션을 그대로 따라줘.
```

update 모드면 "이어서 작업" 안내도 병기.

---

## HANDOFF.md 템플릿

```markdown
# HANDOFF: <한 문장 목표>

**Date:** YYYY-MM-DD
**Host:** claude | codex | gemini
**Project:** <project name>
**Status:** in-progress | paused | blocked

## Goal
<달성하려는 목표를 한 문장. 한 세션 단위의 구체적 outcome.>

## Summary
<현재까지의 한 문단 요약. 중간 전환점·의사결정의 큰 흐름. 3~5줄.>

## Key Decisions
- <결정 1>: <왜 이걸 선택했고, 어떤 대안을 배제했는가>
- <결정 2>: ...

## Worked
- <성공한 접근 1 — 어떤 시도가 어떤 근거로 통과했는지>
- <성공한 접근 2>

## Traps to Avoid
<가장 가치 있는 섹션. 실패한 접근과 왜 실패했는지.>
- <실패 1>: <무엇을 시도했고, 어떤 신호로 틀렸음을 확인했는가>
- <실패 2>: ...

## Relevant Files
- `path/to/file.ext:L<start>-L<end>` — <왜 중요한지, 무엇을 봐야 하는지>
- `path/to/other.ext:L<n>` — ...

## Open Work
<상태 서술형만. 명령형 금지.>
- <X is not yet implemented; depends on Y>
- <Z is partially done but has race condition suspected at file:Lxx>
- <Decision pending on A vs B>

## Prompt for New Chat
> Read CLAUDE.md first. Do NOT restate anything already covered there.
>
> 이 handoff 문서(@<경로>)의 Goal / Summary / Key Decisions / Traps to Avoid / Open Work를 먼저 훑고,
> Relevant Files에 나열된 파일을 **실제로 Read 도구로 읽어** 문서의 주장을 코드와 대조해 검증한 뒤
> Open Work 중 가장 위험도가 낮은 항목부터 선택해 진행할지, 아니면 다른 우선순위가 있는지를 사용자에게 제시해.
```

---

## 작성 5대 원칙 (상세)

### 1. Open Work는 상태 서술형
명령형 ❌ `Implement retry logic`
상태 서술형 ✅ `Retry logic is not yet implemented; TokenService depends on backoff util which is absent.`

이유: 명령형은 새 세션을 맹목적으로 실행하게 만든다. 상태 서술형은 세션이 현재 조건을 파악하고 스스로 다음 행동을 결정하게 한다.

### 2. 파일 참조는 라인 범위 포함
❌ `TokenService 확인 필요`
✅ `src/auth/TokenService.kt:L45-L72 — refresh loop에서 race condition 의심됨. stateFlow.update 이후 observer 재등록 타이밍 확인할 것.`

### 3. CLAUDE.md 중복 차단
Prompt for New Chat 맨 위에 `Read CLAUDE.md first. Do NOT restate anything already covered there.`를 반드시 포함.

handoff에는 "이 task 고유의 상태"만 쓴다. host 규칙·커밋 컨벤션·skill 사용법 같은 일반 규약은 CLAUDE.md에 있다.

### 4. 2,000 토큰 상한
초과하면 아래와 같이 분리:
```
~/.agents/handoffs/{host}/{project}/{date}-{slug}/
├── HANDOFF.md              # 2000 토큰 이하 핵심
└── reports/
    ├── analysis-XXX.md     # 조사 결과 상세
    ├── arch-XXX.md         # 아키텍처 결정 상세
    └── bug-XXX.md          # 버그 재현 로그 등
```
HANDOFF.md의 Relevant Files 또는 Key Decisions에서 `reports/analysis-XXX.md 참조`로 링크만 남긴다.

### 5. "Traps to Avoid"가 핵심
성공한 코드는 리포지토리에 남지만 **실패한 접근은 handoff가 아니면 소실된다.** 다음 세션(또는 다른 에이전트)이 같은 함정을 재현한다. 이 섹션을 비우지 않는다.

실패를 쓰는 방식:
- 무엇을 시도했나 (구체적 접근명)
- 어떤 신호로 실패를 확인했나 (에러 메시지·테스트 결과·관찰)
- 왜 실패했다고 판단하나 (가설 + 불확실성 표지)

---

## 안티패턴

- **Auto-compact 맹신.** 자동 compact는 모델이 가장 덜 똑똑해진 순간에 발동해 정작 필요한 맥락을 잘라낸다.
- **2,000줄 파일 통째 dump.** 파일 내용을 붙여넣지 않는다. 경로+라인 범위만 쓴다.
- **Long-running session 집착.** 새 task에는 이전의 10%만 필요하다. 나머지 90%는 noise.
- **Subagent 과다 생성으로 대체 시도.** 조율 오버헤드가 handoff보다 크다.
- **Handoff 없는 무중단 세션.** Stop hook이 5회 리마인더를 띄우는 이유.
- **checkpoint에서 생략.** /feature-dev·/bug-fix가 체크포인트에서 호출할 때도 동일 원칙 적용.

---

## Checkpoint 모드 (워크플로우 내부 호출)

`/feature-dev`·`/bug-fix`가 단계 사이에서 호출하는 경량 모드.

차이점:
- 진입 시 phase 정보 함께 받음 (예: `checkpoint phase2` — bug-fix Phase 2 완료 지점)
- Step 2(상태 수집)는 워크플로우가 전달한 컨텍스트를 우선 사용
- Step 5(사용자 확인)는 반드시 `AskUserQuestion`로 수행. 선택지:
  - "저장하고 다음 단계 진행"
  - "저장하고 세션 나누기 (여기서 종료)"
  - "수정 후 재확인"
- update 모드 기본값. 같은 작업 슬러그의 기존 HANDOFF.md에 Progress·Traps 누적.
