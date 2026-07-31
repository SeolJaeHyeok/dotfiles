---
name: harness-improve
description: "Self-Improving Loop로 Harness를 자동 개선한다. Collect(신호 수집) → Analyze(패턴 탐지) → Propose(개선 제안) → Verify(효과 검증) 4단계를 실행한다. session-wrap 시 자동 호출되거나, 사용자가 명시적으로 호출한다."
---

# Harness Improve

Self-Improving Loop dispatcher.

## 먼저 읽을 파일

1. 항상 `references/common.md`
2. 현재 host에 맞는 adapter 하나만:
   - Claude: `references/claude.md`
   - Codex: `references/codex.md`
   - Gemini: `references/gemini.md`

## 실행 원칙

- 공유 사용자 자산만 수정한다.
- built-in/native tool 디렉터리와 vendor asset은 건드리지 않는다.
- 공통 규칙은 `~/.agents/rules` 아래에서 관리한다.
- 공통 스킬은 `~/.agents/skills` 아래에서 관리한다.
- host 전용 차이는 `references/{host}.md`에만 기록한다.
- 신호 저장소: `~/.agents/signals/` (log.jsonl, changes.jsonl)

현재 host의 `Host Metadata`를 기준으로 adapter를 선택한다.

## Gotchas

- **1회 발생으로 규칙을 만들지 않는다.** 반드시 임계값을 확인한다.
- **dismissed된 패턴을 다시 제안하지 않는다.** changes.jsonl을 반드시 확인한다.
- **모든 적용에 사용자 승인이 필요하다.** AskUserQuestion 없이 자동 적용하지 않는다.
- **log.jsonl에 민감 정보를 기록하지 않는다.** 파일 경로와 패턴 설명만 기록한다.

