## Bugcha Gemini Default 전환 — 2026-05-13

**컨텍스트**: Bugcha에서 Lambda 환경변수만 Gemini로 바꾼 상태였고, 코드베이스 전반이 실제로 Gemini를 기본 경로로 동작하는지 점검하고 정리했다.

**핵심 결정**: provider 전환 스위치는 유지하되, 기본 provider를 `gemini`로 바꾸고 `AgentLoop`를 특정 SDK에 직접 묶지 않는 provider-중립 인터페이스로 재구성했다. 환경변수만 바꾸면 되는 척 보이는 상태를 피하려면, tool calling과 archive embeddings 같이 런타임 핵심 경로도 같은 추상화 레벨로 맞춰야 한다.

**발견**: `get_ai_service()`는 문서와 달리 실제 기본값이 `openai`였고, Slack agent loop는 OpenAI chat completions에 직접 결합돼 있었다. 또 아카이브 임베딩은 OpenAI 고정이어서 요약 저장/검색만 별도로 OpenAI 의존이 남아 있었다.

**실수**: 처음에는 provider 팩토리가 이미 있으니 Lambda 환경변수만 바꾸면 충분할 가능성을 크게 봤다. 실제로는 tool calling 경로와 임베딩 경로가 별도 결합점을 가지고 있어서, 팩토리 존재만으로 provider 중립이 보장되지는 않았다.

**다음 번엔**: AI provider 전환 작업에서는 1) 기본 provider 값, 2) tool calling/agent loop, 3) embeddings/vector search, 4) 운영 문서와 테스트 fixture 기본값을 한 묶음으로 점검한다. 특히 SDK 객체 shape로 provider를 추론하는 분기는 장기적으로 취약하므로, 가능하면 서비스 인터페이스 기준으로 호출 경로를 숨긴다.
