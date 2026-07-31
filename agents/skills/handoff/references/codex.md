# Handoff — Codex adapter

Codex CLI host에서 handoff를 실행할 때의 경로·명령·연동.

---

## 저장 경로

```
~/.agents/handoffs/codex/{project}/{YYYY-MM-DD}-{slug}/HANDOFF.md
```

- `{project}`: `basename $(git rev-parse --show-toplevel 2>/dev/null)`. git repo 밖이면 `harness`.
- `{YYYY-MM-DD}`: 작성 시점 날짜 (로컬 시간).
- `{slug}`: 인자로 전달되면 그대로, 아니면 세션 목표에서 변환.

2,000 토큰 초과 시:
```
~/.agents/handoffs/codex/{project}/{date}-{slug}/
├── HANDOFF.md
└── reports/
```

---

## 새 세션 부팅 명령

Codex는 `@<경로>` 문법이 없으므로 새 세션에서 파일을 먼저 `Read`로 로드해야 한다.

저장 완료 후 안내:
```
✅ HANDOFF 저장: ~/.agents/handoffs/codex/<project>/<date>-<slug>/HANDOFF.md

📋 새 세션 부팅 절차:
   1. 세션 종료 (Ctrl+D 또는 exit)
   2. 새 세션에서 아래 프롬프트:

      ~/.agents/handoffs/codex/<project>/<date>-<slug>/HANDOFF.md 를 먼저 읽어줘.
      그 다음 문서의 Prompt for New Chat 섹션을 그대로 따라 실행해.
```

---

## /feature-dev · /bug-fix 내부 호출

Claude와 동일한 checkpoint 지점에서 호출된다. 호출 규약은 claude adapter와 같다:

| 워크플로우 | 호출 시점 | 호출 형태 |
|---|---|---|
| /feature-dev | Step 1.5 / Step 3 / Step 4 완료 후 | `handoff checkpoint feature-dev-step<N>` |
| /bug-fix | Phase 2 / Phase 4 완료 후 | `handoff checkpoint bug-fix-phase<N>` |

---

## Tool 사용 규약

- 파일 쓰기: codex-runtime의 `shell.apply_patch` 또는 편집 도구.
- 상위 디렉토리 생성: `mkdir -p` 선행.
- 사용자 확인: Codex는 `AskUserQuestion`이 없을 수 있음. 없으면 **선택지를 번호로 제시하고 답변을 기다린다**.
  - `1) 저장하고 다음 단계 진행`
  - `2) 저장하고 세션 나누기`
  - `3) 수정 후 재확인`

---

## 예외 처리

- **git 정보 접근 실패**: `{project}`를 `harness`로 fallback.
- **동일 경로에 기존 HANDOFF.md 존재**: `new | update | overwrite` 선택지 제시.
- **AskUserQuestion 미지원**: 번호 선택지로 대체.
- **checkpoint 호출이지만 workflow context 누락**: workflow에 부족 정보 되돌려준다.
