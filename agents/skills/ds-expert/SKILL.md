---
name: ds-expert
description: "디자인 시스템 전문가 하네스 오케스트레이터. 기존 컴포넌트 감사/분석, 디자인 토큰 설계, 컴포넌트 설계/구현(React + Tailwind + SCSS), Storybook 문서화를 수행한다. 다음 상황에서 반드시 이 스킬을 사용할 것: 디자인 시스템 구축/리뉴얼, 컴포넌트 라이브러리 설계, 디자인 토큰 정의, UI 컴포넌트 일관성 개선, Storybook 작성, 컴포넌트 API 설계, 색상/타이포그래피/간격 체계 정리, 접근성(a11y) 감사, cva/variant 패턴 적용, 컴포넌트 리팩토링. 후속 요청('다시 실행', '수정', '다른 컴포넌트 추가', '토큰 변경', '문서 업데이트')에도 트리거된다."
---

# Design System Expert Orchestrator

디자인 시스템 전문가 하네스의 오케스트레이터. 4명의 전문 에이전트를 시나리오에 따라 조율한다.

## 먼저 읽을 파일

요청 유형에 따라 필요한 레퍼런스만 로드한다:
- 토큰 설계: `references/token-patterns.md`
- 컴포넌트 설계: `references/component-patterns.md`
- 감사/분석: 레퍼런스 불필요 (에이전트 정의로 충분)
- 문서화: 레퍼런스 불필요 (에이전트 정의로 충분)

## 에이전트 팀

| 에이전트 | 정의 파일 | 역할 |
|---------|----------|------|
| ds-auditor | `~/.agents/agents/ds-auditor.md` | 기존 컴포넌트 감사/분석 |
| ds-token-architect | `~/.agents/agents/ds-token-architect.md` | 토큰 체계 설계 |
| ds-component-engineer | `~/.agents/agents/ds-component-engineer.md` | 컴포넌트 설계/구현 |
| ds-documenter | `~/.agents/agents/ds-documenter.md` | 문서화/Storybook |

## 워크플로우

### Phase 0: 컨텍스트 확인

**작업 디렉토리 정책:** 모든 중간 산출물은 `~/.agents/_workspace/harness-ds-expert/{slug}/`에 저장한다. `{slug}`는 세션별 고유 식별자(작업 슬러그 + 날짜)로, Phase 1에서 확정한다. CWD에는 어떤 산출물도 만들지 않는다.

1. 사용자 요청에서 기존 슬러그 단서를 찾는다:
   - 사용자가 명시 ("`button-renewal-2026-04-15` 이어서 작업")
   - 직전 세션의 슬러그를 기억하고 있다면 그것
   - 단서 없음 → 신규 슬러그 생성 대상

2. 슬러그가 식별되면 `~/.agents/_workspace/harness-ds-expert/{slug}/` 존재 여부 확인:
   - **존재 + 부분 수정 요청** → `$WS=~/.agents/_workspace/harness-ds-expert/{slug}/`로 고정하고 해당 에이전트만 재호출
   - **존재 + 새로 시작 요청** → 사용자에게 "기존 작업 이어서 / 새로 시작(덮어쓰기) / 다른 슬러그 사용" 선택을 요청
   - **미존재 또는 슬러그 단서 없음** → 신규 슬러그 생성 (Phase 1에서 확정), 초기 실행

3. 신규 실행이라면 `mkdir -p ~/.agents/_workspace/harness-ds-expert/{slug}/`로 디렉토리를 만들고, 모든 에이전트 호출에 작업 디렉토리 절대 경로(`$WS = /Users/{user}/.agents/_workspace/harness-ds-expert/{slug}/`)를 프롬프트에 명시 전달한다. 에이전트는 이 절대 경로를 입출력 기준으로 사용한다 (홈 경로 `~`는 사용 금지 — 절대 경로만).

4. 요청을 분석하여 시나리오를 판별한다:

| 시나리오 | 판별 기준 | 호출 흐름 |
|---------|----------|----------|
| 풀 리뉴얼 | "디자인 시스템 리뉴얼", "전체 정리" | auditor → token-architect → component-engineer → documenter |
| 신규 구축 | "디자인 시스템 만들어줘", "새로 구축" | token-architect → component-engineer → documenter |
| 감사만 | "컴포넌트 분석", "현재 상태 파악" | auditor |
| 토큰만 | "토큰 설계", "색상 체계", "타이포그래피" | token-architect |
| 컴포넌트만 | "Button 만들어줘", "컴포넌트 구현" | component-engineer |
| 문서만 | "Storybook 작성", "문서화" | documenter |
| 단순 질문 | 디자인 시스템 개념, 패턴 비교 | 에이전트 없이 직접 응답 |

### Phase 1: 요구사항 정리

사용자에게 부족한 정보를 **1개씩** 물어본다. 채워야 하는 슬롯:

| 슬롯 | 질문 예시 | 기본값 |
|------|----------|--------|
| **작업 목표** | "한 문장으로 이 작업이 무엇인가?" | 필수 — 비우면 진행 금지 |
| **슬러그** | (자동) 목표에서 영문 kebab-case로 자동 생성, 충돌 시 사용자에게 확인 | `{task-kebab}-{YYYY-MM-DD}` 예: `button-renewal-2026-04-15` |
| **프로젝트 경로** | "대상 프로젝트 경로?" | 필수 (리뉴얼 시) |
| **범위** | "전체 시스템 / 특정 컴포넌트?" | 전체 |
| **브랜드 컬러** | "브랜드 컬러가 있는가?" | 없으면 감사 결과에서 추출 |
| **참고 디자인 시스템** | "참고할 레퍼런스가 있는가?" | 없음 |

**슬러그 생성 규칙:**
- 영문 소문자 + 숫자 + 하이픈만 사용 (한글·공백·특수문자 금지)
- 작업 핵심 명사 2-4개 + 날짜 (`YYYY-MM-DD`)
- DS 작업 예시:
  - "Button 컴포넌트 리뉴얼" → `button-renewal-2026-04-15`
  - "토큰 시스템 재설계" → `token-system-redesign-2026-04-15`
  - "Card 컴포넌트 신규 구축" → `card-component-2026-04-15`
  - "전체 디자인 시스템 리뉴얼" → `full-ds-renewal-2026-04-15`
- `~/.agents/_workspace/harness-ds-expert/{slug}/`가 이미 존재하면 사용자에게 "기존 작업 이어서 / 새로 시작 / 다른 슬러그" 선택을 요청

### Phase 2: 에이전트 호출

에이전트 정의 파일(`~/.agents/agents/{name}.md`)을 읽고, 해당 내용을 Agent 도구의 prompt에 포함하여 호출한다.

**호출 규칙:**
- 모든 Agent 호출에 `model: "opus"` 파라미터를 명시한다
- 에이전트 정의 파일의 "작업 원칙"과 "출력 프로토콜"을 prompt에 반드시 포함한다
- 관련 레퍼런스 파일의 내용도 prompt에 포함한다
- **모든 에이전트 호출 프롬프트에 `$WS` 절대 경로를 반드시 포함한다.** 에이전트는 자체적으로 `_workspace/` 같은 상대 경로를 만들지 않는다.

**풀 리뉴얼 파이프라인:**
```
WS = "/Users/{user}/.agents/_workspace/harness-ds-expert/{slug}/"  # Phase 0에서 확정된 절대 경로

1. ds-auditor → $WS/01_audit_report.md
2. ds-token-architect → $WS/02_token_system.md + $WS/02_tailwind.config.ts + $WS/02_tokens.scss
3. ds-component-engineer → $WS/03_components/
4. ds-documenter → $WS/04_docs/
```

에이전트 호출 예시:
```
Agent(
    subagent_type="general-purpose",
    model="opus",
    description="DS Audit",
    prompt=f"""
    너는 ds-auditor 에이전트다. 정의 파일은 ~/.agents/agents/ds-auditor.md 에 있으니 먼저 읽어라.

    작업 디렉토리($WS): {WS}
    대상 프로젝트 경로: {project_path}

    감사 결과를 {WS}01_audit_report.md 에 저장하라.
    """
)
```

각 단계 완료 후 사용자에게 결과를 보여주고 승인을 받은 뒤 다음 단계로 진행한다. AskUserQuestion을 사용한다.

**단일 호출:**
- 시나리오에 맞는 에이전트 1개만 호출 (프롬프트에 `$WS` 절대 경로 전달 필수)

### Phase 3: 결과 종합

1. 전체 요약을 먼저 보여준다 (변경된 파일 수, 주요 결정)
2. 상세 내용은 `$WS/` 파일 참조
3. 마이그레이션이 필요하면 단계별 전환 계획을 제시한다

## 데이터 흐름

```
사용자 입력
   ↓
Phase 0: 슬러그 결정 → $WS = ~/.agents/_workspace/harness-ds-expert/{slug}/
   ↓
Phase 1: 요구사항 정리 (슬러그·프로젝트 경로·범위·브랜드 컬러 확정)
   ↓
Phase 2: 에이전트 호출 (시나리오별)
   ├── $WS/01_audit_report.md (auditor)
   ├── $WS/02_token_system.md, $WS/02_tailwind.config.ts, $WS/02_tokens.scss (token-architect)
   ├── $WS/03_components/ (component-engineer)
   └── $WS/04_docs/ (documenter)
   ↓
Phase 3: 결과 종합 → 사용자 승인 후 실제 프로젝트에 적용
   ↓
Phase 4: 후속 처리 (같은 $WS 재사용)
```

모든 중간 산출물은 `~/.agents/_workspace/harness-ds-expert/{slug}/`에 보존되어 슬러그만 알면 임의 시점에 부분 재실행 가능.

### Phase 4: 후속 처리

- 특정 컴포넌트 수정 → component-engineer만 재호출
- 토큰 변경 → token-architect 재호출 → 영향받는 컴포넌트 목록 안내
- 문서 업데이트 → documenter 재호출

## 에러 핸들링

- 에이전트 호출 실패 시 1회 재시도 후, 재실패 시 직접 응답
- 감사 결과와 토큰 설계 사이 불일치 시 차이점 명시 후 사용자 선택 요청
- Tailwind/SCSS 혼용 전략에 대해 사용자 확인 필요 시 명시적으로 물어본다

## 테스트 시나리오

### 정상 흐름 (풀 리뉴얼)
```
사용자: "현재 프로젝트의 디자인 시스템을 리뉴얼하고 싶어"
→ auditor: 감사 보고서 생성
→ 사용자 승인
→ token-architect: 토큰 체계 설계
→ 사용자 승인
→ component-engineer: 주요 컴포넌트 구현
→ 사용자 승인
→ documenter: Storybook + 문서 생성
```

### 에러 흐름
```
사용자: "Button 컴포넌트를 리뉴얼해줘"
→ component-engineer 호출
→ 토큰 체계가 없음 감지
→ "토큰 체계를 먼저 설계할까요, 아니면 기존 스타일 기반으로 진행할까요?" 확인
```
