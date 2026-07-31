---
name: knowledge-archive
description: "작업 완료 후 지식을 구조화해 아카이빙하는 공유 dispatcher. host별 저장 경로와 fallback만 adapter에서 분기한다."
---

# Knowledge Archive

공유 지식 아카이빙 dispatcher.

## 먼저 읽을 파일

1. 항상 `references/common.md`
2. 현재 host에 맞는 adapter 하나만:
   - Claude: `references/claude.md`
   - Codex: `references/codex.md`
   - Gemini: `references/gemini.md`

## 역할

이 스킬은 지식 손실 방지에만 집중한다.

- 같은 문제를 다음에 처음부터 다시 분석하지 않도록
- 반복되는 실수를 패턴으로 남기도록
- 좋은 결정의 이유를 맥락과 함께 보존하도록

현재 host의 `Host Metadata`를 기준으로 저장 방식을 선택한다.
