# Harness Improve Codex Adapter

Codex 관련 피드백은 아래 경로로 라우팅한다.

- 전역 규칙: `~/.agents/rules/codex/AGENTS.md`
- 세션 handoff: `handoff` 스킬 (`~/.agents/skills/handoff/`, codex adapter 경유)
- 공유 스킬 공통 본문: `~/.agents/skills/<skill>/SKILL.md`
- Codex 전용 차이: `~/.agents/skills/<skill>/references/codex.md`

Codex 전용 판단 기준:

- `ce:*` 워크플로우는 현재 설치 여부가 확인된 경우에만 사용한다.
- 다른 host 전용 팀 기능, 경로, slash 명령은 Codex adapter에 두지 않는다.
- built-in Codex skills와 vendor imports는 수정 대상에서 제외한다.

