# Harness Improve Claude Adapter

Claude 관련 피드백은 아래 경로로 라우팅한다.

- 전역 규칙: `~/.agents/rules/claude/CLAUDE.md`
- 세션 handoff: `/handoff` 스킬 (`~/.agents/skills/handoff/`, claude adapter 경유)
- 공유 스킬 공통 본문: `~/.agents/skills/<skill>/SKILL.md`
- Claude 전용 차이: `~/.agents/skills/<skill>/references/claude.md`

Claude 전용 기능 예시:

- `/claude-mem:mem-search`
- Agent Teams
- `~/.claude/teams/...`
- `~/.claude/tasks/...`

이런 항목은 공통 스킬 본문이 아니라 Claude adapter로만 이동한다.

