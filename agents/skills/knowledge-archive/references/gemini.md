# Knowledge Archive Gemini Adapter

Gemini에서는 검증된 compound-engineering 설치가 없으면 markdown fallback을 기본값으로 사용한다.

## 저장 방식

1. 기본 저장소: `~/.agents/knowledge/`
2. 향후 `ce:compound` 또는 동등한 도구가 실제로 설치된 것이 확인되면 그때 adapter를 업데이트한다.

## Harness 반영

규칙이나 스킬에 반영해야 할 패턴이 있으면 `harness-improve`를 실행한다.
