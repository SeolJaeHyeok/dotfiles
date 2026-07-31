# 하네스: 디자인 시스템 전문가

> 이 파일은 `~/.agents/rules/claude/CLAUDE.md`의 하네스 인덱스에서 참조됨. 디자인 시스템 작업이 트리거되면 로드한다.

**목표:** 기존 컴포넌트 디자인 시스템 리뉴얼 또는 신규 디자인 시스템 구축. React + Tailwind + SCSS 환경.

**에이전트:**
| 에이전트 | 역할 |
|---------|------|
| ds-auditor | 기존 컴포넌트 감사/분석, 일관성·접근성·중복 진단 |
| ds-token-architect | 3계층 토큰 체계 설계 (Global → Semantic → Component) |
| ds-component-engineer | cva + Compound Component 패턴으로 컴포넌트 구현 |
| ds-documenter | Storybook 스토리 + 사용 가이드 + 접근성 문서 생성 |

**스킬:**
| 스킬 | 용도 | 사용 에이전트 |
|------|------|-------------|
| ds-expert | 오케스트레이터 — 시나리오별 에이전트 조율 | 전체 |

**실행 규칙:**
- 디자인 시스템 관련 작업 요청 시 `/ds-expert` 스킬을 통해 에이전트를 호출하라
- 풀 리뉴얼: auditor → token-architect → component-engineer → documenter (파이프라인)
- 단순 디자인 질문은 에이전트 없이 직접 응답해도 무방
- 모든 에이전트는 `model: "opus"` 사용
- **중간 산출물 위치 (고정)**: `~/.agents/_workspace/harness-ds-expert/{slug}/` — 슬러그는 Phase 1에서 확정되는 세션별 식별자 (예: `button-renewal-2026-04-15`). CWD 산출물 생성 금지
- 산출 파일 구성: `01_audit_report.md / 02_token_system.md / 02_tailwind.config.ts / 02_tokens.scss / 03_components/ / 04_docs/`
- 모든 에이전트 호출 시 오케스트레이터가 절대 경로 `$WS = /Users/{user}/.agents/_workspace/harness-ds-expert/{slug}/`를 프롬프트에 명시 전달

**디렉토리 구조:**
```
~/.agents/
├── _workspace/                              ← 모든 DS 세션의 중간 산출물 베이스
│   └── harness-ds-expert/
│       └── {slug}/                          ← 세션별 격리 (예: button-renewal-2026-04-15)
│           ├── 01_audit_report.md
│           ├── 02_token_system.md
│           ├── 02_tailwind.config.ts
│           ├── 02_tokens.scss
│           ├── 03_components/
│           │   ├── design-decisions.md
│           │   └── {ComponentName}/
│           └── 04_docs/
│               ├── overview.md
│               ├── tokens.md
│               ├── components/
│               └── guidelines/
├── agents/
│   ├── ds-auditor.md
│   ├── ds-token-architect.md
│   ├── ds-component-engineer.md
│   └── ds-documenter.md
└── skills/
    └── ds-expert/
        ├── SKILL.md
        └── references/
            ├── token-patterns.md
            └── component-patterns.md
```

**변경 이력:**
| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
| 2026-04-07 | 초기 구성 | 전체 | 디자인 시스템 전문가 하네스 신규 구축 |
| 2026-04-15 | 작업 디렉토리 통합 | SKILL.md, 4 agents, harness rule | 4개 하네스 통합 패턴(`~/.agents/_workspace/harness-{name}/{slug}/`)에 맞춰 절대 경로·슬러그 격리로 전환 |
