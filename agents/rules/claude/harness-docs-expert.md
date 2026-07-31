# 하네스: 기술 문서 전문가

> 이 파일은 `~/.agents/rules/claude/CLAUDE.md`의 하네스 인덱스에서 참조됨. **코드베이스 기반** 기술 문서 작업이 트리거되면 로드한다. (임의 주제 장문 콘텐츠는 `harness-content-expert.md`)

**목표:** 코드베이스 분석 기반으로 기술 문서를 체계적으로 생성한다. API/SDK 문서, 아키텍처/설계 문서, 가이드/튜토리얼, 프로젝트 문서를 내부 팀(개발자+비개발자) 대상으로 작성한다.

**에이전트:**
| 에이전트 | 역할 |
|---------|------|
| docs-analyst | 코드베이스 분석, 문서 갭 식별, 구조 설계 |
| docs-writer | 문서 유형별 초안 작성 (API, 아키텍처, 가이드, 프로젝트) |
| docs-reviewer | 기술적 정확성·독자 적합성·완전성 검증 |
| docs-diagrammer | Mermaid 다이어그램 생성 (아키텍처, ERD, 시퀀스, 플로우) |

**스킬:**
| 스킬 | 용도 | 사용 에이전트 |
|------|------|-------------|
| docs-expert | 오케스트레이터 — 시나리오별 에이전트 조율 | 전체 |

**실행 규칙:**
- 기술 문서 작성 요청 시 `/docs-expert` 스킬을 통해 에이전트를 호출하라
- 전체 문서화: analyst → writer + diagrammer(병렬) → reviewer (파이프라인)
- 단순 문서 작성법 질문은 에이전트 없이 직접 응답해도 무방
- 모든 에이전트는 `model: "opus"` 사용
- **중간 산출물 위치 (고정)**: `~/.agents/_workspace/harness-docs-expert/{slug}/` — 슬러그는 Phase 1에서 확정되는 세션별 식별자 (예: `auth-api-docs-2026-04-15`). CWD에 산출물 생성 금지
- 산출 파일 구성: `00_brief.md / 01_analysis.md / 02_docs/*.md / 02_docs/diagrams/*.md / 03_review.md`
- 모든 에이전트 호출 시 오케스트레이터가 절대 경로 `$WS = /Users/{user}/.agents/_workspace/harness-docs-expert/{slug}/`를 프롬프트에 명시 전달
- 부분 재실행 지원: 슬러그만 알면 임의 시점 재진입 가능. "특정 문서 수정" → writer만, "다이어그램 추가" → diagrammer만, "리뷰 반영" → writer 재호출

**디렉토리 구조:**
```
~/.agents/
├── _workspace/                                  ← 모든 docs 세션의 중간 산출물 베이스
│   └── harness-docs-expert/
│       └── {slug}/                              ← 세션별 격리 (예: auth-api-docs-2026-04-15)
│           ├── 00_brief.md
│           ├── 01_analysis.md
│           ├── 02_docs/
│           │   ├── [문서명].md
│           │   └── diagrams/
│           │       ├── architecture.md
│           │       └── ...
│           └── 03_review.md
├── agents/
│   ├── docs-analyst.md
│   ├── docs-writer.md
│   ├── docs-reviewer.md
│   └── docs-diagrammer.md
└── skills/
    └── docs-expert/
        ├── SKILL.md
        └── references/
            ├── writing-standards.md
            └── templates.md
```

**변경 이력:**
| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
| 2026-04-08 | 초기 구성 | 전체 | 기술 문서 전문가 하네스 신규 구축 |
| 2026-04-15 | 작업 디렉토리 통합 | SKILL.md, 4 agents, harness rule | 4개 하네스 통합 패턴(`~/.agents/_workspace/harness-{name}/{slug}/`)에 맞춰 절대 경로·슬러그 격리로 전환 |
