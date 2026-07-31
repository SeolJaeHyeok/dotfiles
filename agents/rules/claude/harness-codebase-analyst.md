# 하네스: 코드베이스 분석 전문가

> 이 파일은 `~/.agents/rules/claude/CLAUDE.md`의 하네스 인덱스에서 참조됨. 코드베이스 분석·인사이트 추출 작업이 트리거되면 로드한다.

**목표:** 시니어 아키텍트·스태프 엔지니어·코드 리뷰어 전문가 팀 관점에서 코드베이스를 분석해, 단순 설명이 아니라 **개발자가 실무에 가져갈 인사이트**(설계 원칙·재사용 패턴·안티패턴·실무 적용방안)를 우선순위와 함께 추출한다.

**핵심 차이점:** 분석·인사이트 추출 전용. 버그 수정은 `bug-fix`, 기능 개발은 `feature-dev`, 코드베이스 기반 **문서 작성**(README/ADR/API)은 `docs-expert`. 헷갈리면 "이 작업의 산출물이 '인사이트 보고서'인가, '수정된 코드'인가, '발행용 문서'인가"로 구분한다.

**에이전트 (5개 분석 렌즈 — 고정 + 1 통합):**
| 에이전트 | 관점 | 동시 호출 |
|---------|------|---------|
| codebase-architect | 시스템 구조·모듈 경계·의존성·통신 패턴 | 1명 |
| codebase-domain-designer | 도메인 모델·유비쿼터스 언어·추상화 | 1명 |
| codebase-quality-reviewer | 가독성·테스트·컨벤션·안티패턴·보안(코드 레벨) | 1명 |
| codebase-performance-analyst | 병목·캐싱·동시성·확장성·인프라 | 1명 |
| codebase-dx-analyst | 온보딩·툴링·문서·디버깅·주목할 구현 기법 | 1명 |
| codebase-synthesizer | 5렌즈 통합 → 종합 보고서 (P0/P1/P2 우선순위) | 1명 (최후) |

**스킬:**
| 스킬 | 용도 | 사용 에이전트 |
|------|------|-------------|
| codebase-analyst | 오케스트레이터 — 스카우트 + 5렌즈 팬아웃 + 종합 조율 | 전체 |

**실행 규칙:**
- 코드베이스 분석 요청 시 `/codebase-analyst` 스킬을 통해 5렌즈 팬아웃으로 처리하라
- 'Team Big Five' 정신: 오케스트레이터 스카우트(`00_scout.md`)가 공유 멘탈 모델, 각 렌즈의 "교차 발견" + synthesizer 통합이 상호 모니터링
- 모든 발견은 `path:line` 근거 + Why 추론 + 트레이드오프 필수 (근거 없는 일반론 금지)
- 단순 질문("이 함수 뭐해")은 에이전트 없이 직접 응답
- 모든 에이전트는 `model: "opus"`, `subagent_type: "general-purpose"` 사용
- **중간 산출물 위치 (고정)**: `~/.agents/_workspace/harness-codebase-analyst/{slug}/` — 슬러그는 Phase 0에서 확정 (예: `some-api-2026-05-29`). CWD에 산출물 생성 금지
- **최종 보고서 기본 출력**: 분석 대상 코드베이스 루트의 `CODEBASE-ANALYSIS-{slug}.md`
- 산출 파일 구성: `00_scout / 01_architecture / 01_domain / 01_quality / 01_performance / 01_dx / 02_synthesis`
- 모든 렌즈 호출 시 오케스트레이터가 `$WS`(작업 디렉토리)와 `$TARGET`(분석 대상) 절대 경로를 프롬프트에 명시 전달
- 부분 재실행 지원: 슬러그만 알면 임의 시점 재진입. "아키텍처만 다시" → architect만, "성능 보강" → performance-analyst만, "우선순위 재조정" → synthesizer만

**디렉토리 구조:**
```
~/.agents/
├── _workspace/
│   └── harness-codebase-analyst/
│       └── {slug}/
│           ├── 00_scout.md
│           ├── 01_architecture.md
│           ├── 01_domain.md
│           ├── 01_quality.md
│           ├── 01_performance.md
│           ├── 01_dx.md
│           └── 02_synthesis.md
├── agents/
│   ├── codebase-architect.md
│   ├── codebase-domain-designer.md
│   ├── codebase-quality-reviewer.md
│   ├── codebase-performance-analyst.md
│   ├── codebase-dx-analyst.md
│   └── codebase-synthesizer.md
└── skills/
    └── codebase-analyst/
        ├── SKILL.md
        └── references/
            ├── mission-prompt.md     ← 분석 미션 헌장 (정전 + 아카이브). 주입 블록을 오케스트레이터가 Phase 1에서 로드해 전 에이전트에 주입
            ├── lens-checklists.md    ← 각 렌즈가 자기 섹션만 로드
            └── report-template.md    ← synthesizer가 로드
```

**기본 미션 프롬프트 관리:**
- 분석 스탠스(태도·목표·관점)의 단일 source of truth는 `references/mission-prompt.md`의 "주입 블록"(¶1~3). 분석 태도를 바꾸려면 **이 파일만** 고친다 → 전 에이전트에 일관 반영.
- 원문 프롬프트 전체(¶1~4)는 같은 파일에 아카이브로 보존. ¶4(실행 구조: 5렌즈·종합 보고서)는 하네스가 소유하므로 **주입하지 않는다** (주입 시 하네스와 중복·drift).
- 실행 구조(렌즈 개수·보고서 섹션·워크플로우)는 미션 파일이 아니라 SKILL.md / 에이전트 정의 / report-template.md에서 관리.

**변경 이력:**
| 날짜 | 변경 내용 | 대상 | 사유 |
|------|----------|------|------|
| 2026-05-29 | 초기 구성 | 전체 | 코드베이스 분석 하네스 신규 구축 (5렌즈 팬아웃 + synthesizer, Team Big Five 경량 적용) |
| 2026-05-29 | 기본 미션 프롬프트 정전 분리 | mission-prompt.md, SKILL.md | 미션 프롬프트를 단일 파일로 관리(주입+아카이브). 주입 블록(¶1~3)만 주입, ¶4는 아카이브로만 보존해 drift 방지 |
