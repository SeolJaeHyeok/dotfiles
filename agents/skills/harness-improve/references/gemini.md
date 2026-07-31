# Harness Improve Gemini Adapter

Gemini 관련 피드백은 아래 경로로 라우팅한다.

- 전역 규칙: `~/.agents/rules/gemini/GEMINI.md`
- 세션 handoff: `handoff` 스킬 (`~/.agents/skills/handoff/`, gemini adapter 경유)
- 공유 스킬 공통 본문: `~/.agents/skills/<skill>/SKILL.md`
- Gemini 전용 차이: `~/.agents/skills/<skill>/references/gemini.md`

Gemini 전용 판단 기준:

- Claude/Codex 전용 명령을 그대로 복사하지 않는다.
- `ce:*` 사용은 실제 설치가 검증된 이후에만 adapter에 추가한다.
- 검증되지 않은 기능은 수동 절차로 fallback한다.
