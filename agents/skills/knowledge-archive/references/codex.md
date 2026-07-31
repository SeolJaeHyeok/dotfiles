# Knowledge Archive Codex Adapter

Codex에서는 설치된 compound-engineering 산출물을 우선 사용한다.

## 저장 방식

1. `ce:compound`를 사용할 수 있으면 실행
2. 사용할 수 없거나 실패하면 `~/.agents/knowledge/` markdown fallback 사용

## Harness 반영

규칙이나 스킬에 반영해야 할 패턴이 있으면 `harness-improve`를 실행한다.
