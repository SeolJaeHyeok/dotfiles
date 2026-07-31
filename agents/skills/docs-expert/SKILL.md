---
name: docs-expert
description: "기술 문서 작성 전문가 하네스 오케스트레이터. 코드베이스 분석 기반 문서 갭 식별, API/SDK 레퍼런스 생성, 아키텍처/설계 문서(ADR) 작성, 온보딩/가이드/튜토리얼 작성, README/CHANGELOG/CONTRIBUTING 등 프로젝트 문서 생성, Mermaid 다이어그램 생성을 수행한다. 내부 팀 개발자와 비개발자 모두를 독자로 고려한다. 다음 상황에서 반드시 이 스킬을 사용할 것: 기술 문서 작성, API 문서화, 아키텍처 문서, 설계 문서, ADR 작성, README 작성, 온보딩 문서, 가이드 작성, 튜토리얼, CHANGELOG 업데이트, 다이어그램 생성, 문서 리뷰, 문서 갭 분석, 기존 문서 업데이트. 후속 요청('다시 작성', '수정', '문서 추가', '톤 변경', '다이어그램 추가', '리뷰 반영')에도 트리거된다."
---

# Docs Expert Orchestrator

기술 문서 작성 전문가 하네스의 오케스트레이터. 4명의 전문 에이전트를 시나리오에 따라 조율한다.

## 먼저 읽을 파일

요청 유형에 따라 필요한 레퍼런스만 로드한다:
- 문서 작성 전반: `references/writing-standards.md`
- 문서 템플릿 필요 시: `references/templates.md`

## 에이전트 팀

| 에이전트 | 정의 파일 | 역할 |
|---------|----------|------|
| docs-analyst | `~/.agents/agents/docs-analyst.md` | 코드베이스 분석, 문서 갭 식별, 구조 설계 |
| docs-writer | `~/.agents/agents/docs-writer.md` | 문서 초안 작성 (유형별 특화) |
| docs-reviewer | `~/.agents/agents/docs-reviewer.md` | 정확성·적합성·완전성 검증 |
| docs-diagrammer | `~/.agents/agents/docs-diagrammer.md` | Mermaid 다이어그램 생성 |

## 워크플로우

### Phase 0: 컨텍스트 확인

**작업 디렉토리 정책:** 모든 중간 산출물은 `~/.agents/_workspace/harness-docs-expert/{slug}/`에 저장한다. `{slug}`는 세션별 고유 식별자(작업 슬러그 + 날짜)로, Phase 1에서 확정한다. CWD에는 어떤 산출물도 만들지 않는다 (사용자 출력 경로 제외).

1. 사용자 요청에서 기존 슬러그 단서를 찾는다:
   - 사용자가 명시 ("`auth-api-docs-2026-04-15` 문서 다시 리뷰해줘")
   - 직전 세션의 슬러그를 기억하고 있다면 그것
   - 단서 없음 → 신규 슬러그 생성 대상

2. 슬러그가 식별되면 `~/.agents/_workspace/harness-docs-expert/{slug}/` 존재 여부 확인:
   - **존재 + 사용자가 부분 수정 요청** → `$WS=~/.agents/_workspace/harness-docs-expert/{slug}/`로 고정하고 Phase 4 부분 재실행 모드
   - **존재 + 사용자가 처음부터 다시** → 사용자에게 "기존 작업 이어서 / 새로 시작(다른 슬러그 제안) / 현재 슬러그 유지하고 덮어쓰기" 중 선택 요청
   - **미존재 또는 슬러그 단서 없음** → 신규 슬러그 생성 (Phase 1에서 확정), 초기 실행

3. 신규 실행이라면 `mkdir -p ~/.agents/_workspace/harness-docs-expert/{slug}/`로 디렉토리를 만들고, 모든 에이전트 호출에 작업 디렉토리 절대 경로(`$WS = /Users/{user}/.agents/_workspace/harness-docs-expert/{slug}/`)를 프롬프트에 명시 전달한다. 에이전트는 이 절대 경로를 입출력 기준으로 사용한다 (홈 경로 `~`는 사용 금지 — 절대 경로만).

4. 요청을 분석하여 시나리오를 판별한다:

| 시나리오 | 판별 기준 | 호출 흐름 |
|---------|----------|----------|
| 전체 문서화 | "문서화해줘", "문서 정리", "프로젝트 문서" | analyst → writer → (diagrammer) → reviewer |
| API 문서 | "API 문서", "엔드포인트 문서화" | analyst → writer → reviewer |
| 아키텍처 문서 | "아키텍처 문서", "설계 문서", "ADR" | analyst → writer + diagrammer(병렬) → reviewer |
| 가이드/튜토리얼 | "가이드 작성", "온보딩 문서", "튜토리얼" | analyst → writer → reviewer |
| 다이어그램만 | "다이어그램", "ERD", "시퀀스 다이어그램" | diagrammer |
| 문서 리뷰만 | "문서 검토", "리뷰해줘" | reviewer |
| 기존 문서 업데이트 | "문서 업데이트", "최신화" | analyst → writer → reviewer |
| 단순 질문 | 문서 작성법, 포맷 질문 | 에이전트 없이 직접 응답 |

### Phase 1: 요구사항 정리

사용자에게 부족한 정보를 **1개씩** 물어본다 (Rule 0). 채워야 하는 슬롯:

| 슬롯 | 질문 예시 | 기본값 |
|------|----------|--------|
| **프로젝트 경로** | "문서화할 프로젝트 경로는?" | 필수 — 비우면 진행 금지 |
| **문서화 범위** | "전체 / 특정 모듈 / 특정 문서 유형?" | 필수 |
| **문서 유형** | "API 레퍼런스 / 아키텍처 / 가이드 / 프로젝트 문서 중 어느 쪽?" | 사용자 표현으로 추론 |
| **독자** | "주 독자는 개발자 / 비개발자 / 혼합?" | 혼합 |
| **슬러그** | (자동) 작업에서 영문 kebab-case로 자동 생성, 충돌 시 사용자에게 확인 | `{task-kebab}-{YYYY-MM-DD}` 예: `auth-api-docs-2026-04-15` |
| **출력 위치** | "최종 문서를 어디에 저장? (프로젝트 내 `docs/` / 외부 경로)" | `{project}/docs/` |

**슬러그 생성 규칙:**
- 영문 소문자 + 숫자 + 하이픈만 사용 (한글·공백·특수문자 금지)
- 작업의 핵심 명사 2-4개 + 날짜 (`YYYY-MM-DD`)
- 예시:
  - "인증 모듈 API 레퍼런스 작성" → `auth-api-docs-2026-04-15`
  - "결제 시스템 아키텍처 ADR" → `payment-architecture-adr-2026-04-15`
  - "신규 개발자 온보딩 가이드" → `onboarding-guide-2026-04-15`
- `~/.agents/_workspace/harness-docs-expert/{slug}/`가 이미 존재하면 사용자에게 "기존 작업 이어서 / 새로 시작 / 다른 슬러그" 선택을 요청

슬러그가 확정되면 `mkdir -p $WS`로 작업 디렉토리를 만들고, 수집한 요구사항을 `$WS/00_brief.md`에 저장한다.

### Phase 2: 에이전트 호출

에이전트 정의 파일(`~/.agents/agents/{name}.md`)을 읽고, 해당 내용을 Agent 도구의 prompt에 포함하여 호출한다.

**호출 규칙:**
- 모든 Agent 호출에 `model: "opus"` 파라미터를 명시한다
- 관련 레퍼런스 파일의 내용도 prompt에 포함한다
- diagrammer는 writer와 병렬 실행 가능 (`run_in_background: true`)
- **모든 호출 프롬프트에 작업 디렉토리 절대 경로 `$WS`를 명시 전달한다** (Phase 0에서 확정). 에이전트는 자체적으로 `_workspace/` 같은 상대 경로를 만들지 않는다.

**전체 문서화 파이프라인:**
```
WS = "/Users/{user}/.agents/_workspace/harness-docs-expert/{slug}/"  # Phase 0/1에서 확정

1. docs-analyst → $WS/01_analysis.md
2. docs-writer → $WS/02_docs/*.md
   + docs-diagrammer (병렬) → $WS/02_docs/diagrams/
3. docs-reviewer → $WS/03_review.md
4. reviewer 피드백 기반 writer 재호출 (Critical 이슈 있을 때만)
```

**에이전트 호출 예시:**
```
Agent(
    subagent_type="general-purpose",
    model="opus",
    description="docs-analyst: 코드베이스 분석",
    prompt=f"""
    너는 docs-analyst 에이전트다. 정의 파일은 ~/.agents/agents/docs-analyst.md 에 있으니 먼저 읽어라.

    작업 디렉토리($WS): {WS}
    사용자 브리핑: {WS}00_brief.md

    프로젝트 경로: {project_path}
    문서화 범위: {scope}

    분석 결과를 {WS}01_analysis.md 에 저장하라.
    """
)
```

각 단계 완료 후 사용자에게 결과를 보여주고 AskUserQuestion으로 승인을 받은 뒤 다음 단계로 진행한다.

### Phase 3: 결과 종합

1. 생성된 문서 목록과 각 문서의 요약을 보여준다
2. reviewer 점수와 주요 피드백을 함께 제시한다
3. 문서 파일을 프로젝트의 최종 위치에 복사할지 물어본다

### Phase 4: 후속 처리

- 특정 문서 수정 → writer만 재호출
- 다이어그램 추가 → diagrammer만 재호출
- 톤 변경 → writer 재호출 (톤 가이드 포함)
- 리뷰 피드백 반영 → writer 재호출 (review.md 포함)

부분 재실행은 모두 같은 `$WS`를 재사용한다. 슬러그만 알면 임의 시점에 재진입 가능.

## 데이터 흐름

```
사용자 입력
   ↓
Phase 0: 슬러그 결정 → $WS = ~/.agents/_workspace/harness-docs-expert/{slug}/
   ↓
Phase 1: $WS/00_brief.md
   ↓
Phase 2:
   ├── $WS/01_analysis.md (analyst)
   ├── $WS/02_docs/*.md (writer)
   ├── $WS/02_docs/diagrams/*.md (diagrammer, 병렬)
   └── $WS/03_review.md (reviewer)
   ↓
Phase 3: 최종 문서 복사 → 사용자 출력 경로 (프로젝트 docs/ 또는 명시 경로)
   ↓
Phase 4: 피드백 → 부분 재실행 (같은 $WS 재사용)
```

모든 중간 산출물은 `~/.agents/_workspace/harness-docs-expert/{slug}/`에 보존되어 슬러그만 알면 임의 시점에 부분 재실행 가능.

## 에러 핸들링

- 에이전트 호출 실패 시 1회 재시도 후 직접 응답
- 코드베이스 접근 불가 시 사용자 설명 기반으로만 작성 (analyst 건너뜀)
- reviewer가 Critical 3건 이상 발견 시 자동으로 writer 재호출 (최대 1회)

## 테스트 시나리오

### 정상 흐름
```
사용자: "이 프로젝트의 API 문서를 작성해줘"
→ analyst: 코드 분석 → API 엔드포인트 목록화
→ writer: API 레퍼런스 문서 생성
→ reviewer: 코드 대조 검증
→ 사용자에게 결과 제시
```

### 에러 흐름
```
사용자: "이 모듈의 아키텍처 문서를 만들어줘"
→ analyst: 코드 분석
→ writer + diagrammer 병렬 실행
→ diagrammer 실패 → writer 결과만으로 진행, 다이어그램 누락 명시
→ reviewer: 다이어그램 누락을 Minor 이슈로 기록
```
