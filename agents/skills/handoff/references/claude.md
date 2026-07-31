# Handoff — Claude adapter

Claude Code host에서 handoff를 실행할 때의 경로·명령·연동.

---

## 저장 경로

```
~/.agents/handoffs/claude/{project}/{YYYY-MM-DD}-{slug}/HANDOFF.md
```

- `{project}`: `basename $(git rev-parse --show-toplevel 2>/dev/null)` 결과. git repo 밖이면 `harness`.
- `{YYYY-MM-DD}`: 작성 시점 날짜 (로컬 시간).
- `{slug}`: 사용자가 인자로 전달했으면 그대로, 아니면 Rule 0의 "목표"에서 변환 (소문자-하이픈).

2,000 토큰 초과 시 같은 디렉토리 아래 `reports/` 생성:
```
~/.agents/handoffs/claude/{project}/{date}-{slug}/
├── HANDOFF.md
└── reports/
    └── ...
```

---

## 새 세션 부팅 명령

Claude Code는 `@<경로>` 문법으로 파일을 컨텍스트에 자동 주입한다.

저장 완료 후 다음 안내를 출력:
```
✅ HANDOFF 저장: ~/.agents/handoffs/claude/<project>/<date>-<slug>/HANDOFF.md

📋 새 세션 부팅 절차:
   1. /clear
   2. 아래 프롬프트 복사해서 붙여넣기:

      @~/.agents/handoffs/claude/<project>/<date>-<slug>/HANDOFF.md
      위 문서의 Prompt for New Chat 섹션을 그대로 따라 실행해줘.
```

---

## Stop hook 연동

`~/.claude/hooks/stop-verify.sh`가 **응답 5회마다** HANDOFF 리마인더를 stderr로 출력한다 (`HANDOFF_THRESHOLD=5`).

hook이 리마인더를 띄웠을 때 사용자가 "handoff 해"라고 하면 이 스킬이 호출된다. 이 경우:
- `{project}`·`{date}`는 hook이 suggest한 경로와 동일하게 맞춘다
- `{slug}`는 사용자에게 묻거나 현재 세션 목표로부터 자동 생성

hook이 안내하는 경로 형식이 이 adapter의 규약과 같음을 확인:
```bash
# stop-verify.sh L25
~/.agents/handoffs/claude/${PROJ}/${TODAY}-{작업슬러그}/HANDOFF.md
```

---

## /feature-dev · /bug-fix 내부 호출

두 워크플로우가 checkpoint에서 이 스킬을 호출할 때 전달되는 위치:

| 워크플로우 | 호출 시점 | 호출 형태 |
|---|---|---|
| /feature-dev | Step 1.5 완료 후 (구현 시작 전) | `handoff checkpoint feature-dev-step1.5` |
| /feature-dev | Step 3 완료 후 (리뷰 시작 전) | `handoff checkpoint feature-dev-step3` |
| /feature-dev | Step 4 완료 후 (아카이빙 시작 전) | `handoff checkpoint feature-dev-step4` |
| /bug-fix | Phase 2 완료 후 (Council Review 전) | `handoff checkpoint bug-fix-phase2` |
| /bug-fix | Phase 4 완료 후 (개선 루프 전) | `handoff checkpoint bug-fix-phase4` |

checkpoint 모드에서는 workflow가 이미 수집한 컨텍스트(목표·완료 작업·남은 Step 등)를 우선 사용하고, `AskUserQuestion`으로 승인 받는다.

---

## ce:compound 경계

`/ce:compound`의 Auto-Invoke trigger는 이 스킬과 독립적이다.

- handoff는 **세션 전환**을 위한 문서화
- ce:compound는 **해결 완료된 문제의 지식 아카이빙**
- feature-dev/bug-fix 중에는 `/knowledge-archive` 경유로만 ce:compound 호출 (CLAUDE.md §10)

handoff 저장 자체는 ce:compound를 트리거하지 않는다.

---

## Tool 사용 규약

- 파일 쓰기: `Write` 도구. 상위 디렉토리 없으면 `Bash`로 `mkdir -p` 먼저.
- 사용자 확인: `AskUserQuestion` 도구 (checkpoint 모드 필수).
- 새 세션 프롬프트 안내: 텍스트 출력만. `/clear`는 사용자가 직접 실행.

---

## 예외 처리

- **git 정보 접근 실패**: `{project}`를 `harness`로 fallback.
- **동일 경로에 기존 HANDOFF.md 존재**: 사용자에게 `new (다른 slug) | update (누적) | overwrite (주의)` 선택지 제시.
- **사용자가 slug를 거부**: 자동 생성 제안 → 거부 시 작성 중단.
- **워크플로우 호출 중 컨텍스트 부족**: workflow에게 "필요한 정보가 부족함. 어느 섹션을 비울지 확정 필요"를 되돌려준다.
