# 하네스: 콘텐츠 제작 전문가 (범용)

> 이 파일은 `~/.agents/rules/claude/CLAUDE.md`의 하네스 인덱스에서 참조됨. 임의 주제의 장문 콘텐츠 작업이 트리거되면 로드한다. (코드베이스 기반 문서는 `harness-docs-expert.md`)

**목표:** 기술문서·트렌드 보고서·트러블슈팅 보고서·아티클·백서 등 **다른 사람에게 보여주는 모든 장문 텍스트**를 주제와 무관하게 일관된 품질로 생성한다. 6개 역할 셸에 주제별 페르소나를 동적으로 부여하는 패턴.

**핵심 차이점:** docs-expert는 **코드베이스 기반** 기술 문서(README/ADR/API), content-expert는 **임의 주제**의 장문 콘텐츠 생성. 헷갈리면 입력이 "코드"인지 "주제"인지로 구분한다.

**에이전트 (역할 셸 6개 — 영구 고정, 페르소나는 런타임 주입):**
| 에이전트 | 역할 | 동시 호출 |
|---------|------|---------|
| content-researcher | 일차 자료 수집·정리 (페르소나별 도메인 리서치) | ✅ N명 |
| content-analyst | 종합 분석·인사이트 도출 | ✅ N명 |
| content-fact-checker | 사실 검증 (등급별: VERIFIED/PARTIAL/INCORRECT/UNVERIFIABLE) | 보통 1명 |
| content-assembler | 통합 초안 작성 (단일 목소리) | 1명 |
| content-editor | 문체·톤·가독성 다듬기 (사실 불변) | 1명 |
| content-critic | 최종 비판적 리뷰 (P0/P1/P2 권고, ship/revise/block) | 1~2명 |

**스킬:**

| 스킬 | 용도 | 사용 에이전트 |
|------|------|-------------|
| content-expert | 오케스트레이터 — 페르소나 동적 생성 + 파이프라인 조율 | 전체 |

**실행 규칙:**
- 장문 콘텐츠 작성 요청 시 `/content-expert` 스킬을 통해 셸 + 페르소나로 처리하라
- Phase 2(페르소나 생성)는 항상 **사용자 승인**을 받고 진행한다
- 코드베이스 기반 문서는 `/docs-expert`를 사용 (혼동 금지)
- 단순 글쓰기 팁/형식 질문은 에이전트 없이 직접 응답해도 무방
- 모든 에이전트는 `model: "opus"`, `subagent_type: "general-purpose"` 사용
- **중간 산출물 위치 (고정)**: `~/.agents/_workspace/harness-content-expert/{slug}/` — 슬러그는 Phase 1에서 확정되는 세션별 식별자 (예: `llm-trends-2026-04-15`). CWD에 산출물 생성 금지
- 산출 파일 구성: `00_brief / personas / 01_research_* / 02_analysis_* / 03_fact_check / 04_draft / 05_edited / 06_critique`
- 모든 셸 호출 시 오케스트레이터가 절대 경로 `$WS = /Users/{user}/.agents/_workspace/harness-content-expert/{slug}/`를 프롬프트에 명시 전달
- 부분 재실행 지원: 슬러그만 알면 임의 시점 재진입 가능. "톤만 바꿔" → editor만, "이 챕터 다시" → assembler부터, "더 깊게 리서치" → 해당 페르소나 researcher부터

**디렉토리 구조:**
```
~/.agents/
├── _workspace/                          ← 모든 콘텐츠 세션의 중간 산출물 베이스
│   └── harness-content-expert/          ← 콘텐츠 하네스 전용 격리 레이어
│       └── {slug}/                      ← 세션별 격리
│           ├── 00_brief.md
│           ├── personas.md
│           ├── 01_research_{persona}.md
│           ├── 02_analysis_{persona}.md
│           ├── 03_fact_check.md
│           ├── 04_draft.md
│           ├── 05_edited.md
│           └── 06_critique.md
├── agents/
│   ├── content-researcher.md
│   ├── content-analyst.md
│   ├── content-fact-checker.md
│   ├── content-assembler.md
│   ├── content-editor.md
│   └── content-critic.md
└── skills/
    └── content-expert/
        ├── SKILL.md
        └── references/
            ├── mission-prompt.md      ← 콘텐츠 품질 헌장 (정전+아카이브). Phase 0에서 $MISSION으로 로드해 전 셸에 주입
            ├── persona-templates.md   ← Phase 2 페르소나 생성 시 참고
            └── output-formats.md      ← assembler가 형식 결정 시 참고
```

**미션 헌장 관리 (공통 패턴):** 주제·페르소나와 무관한 공통 품질 스탠스(근거·반론·사실성·투명성·AI슬롭제거)는 `references/mission-prompt.md`의 주입 블록이 정전. 품질 태도를 바꾸려면 이 파일만 수정. 페르소나는 `personas.md`(런타임), 톤·분량·독자는 `00_brief.md`에서 관리. 패턴 근거: `~/.agents/rules/claude/harness-pattern-mission-charter.md`.

**변경 이력:**
| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
| 2026-04-15 | 초기 구성 | 전체 | 범용 콘텐츠 제작 하네스 신규 구축 (셸 + 동적 페르소나 패턴) |
| 2026-04-15 | 작업 디렉토리 고정 | SKILL.md, 6 agents, CLAUDE.md | `_workspace/`(CWD 기준)에서 `~/.agents/_workspace/harness-content-expert/{slug}/`(절대 경로, 슬러그 격리)로 변경. 세션 간 충돌 방지 + 어디서 실행해도 동일 위치 |
| 2026-04-15 | 작업 디렉토리 한 단계 추가 | SKILL.md, 6 agents, harness rule | 4개 하네스 통합 패턴(`~/.agents/_workspace/harness-{name}/{slug}/`)에 맞춰 `harness-content-expert/` 한 단계 삽입 |
| 2026-05-29 | 미션 헌장 분리 패턴 적용 | mission-prompt.md, SKILL.md | 공통 "미션 헌장 분리" 컨벤션 적용. 6개 셸 공통 품질 스탠스를 단일 정전으로 추출, Phase 0에서 $MISSION으로 주입 |
