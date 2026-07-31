---
name: codebase-analyst
description: "코드베이스 심층 분석 하네스 오케스트레이터. 시니어 아키텍트·스태프 엔지니어·코드 리뷰어 전문가 팀 관점에서 코드베이스를 분석해 개발자가 학습·참고할 인사이트를 추출한다. 5개 전문 렌즈(아키텍처/도메인설계/코드품질/성능·확장성/개발자경험)가 병렬 분석 후 종합 보고서(핵심 인사이트·설계 원칙·재사용 패턴·안티패턴·실무 적용방안 + 우선순위)를 작성한다. 다음 상황에서 반드시 이 스킬을 사용할 것: '이 코드베이스/레포/프로젝트 분석해줘', '아키텍처 분석', '코드베이스 리뷰', '이 프로젝트에서 배울 점', '설계 패턴 분석', '코드 품질·구조 진단', '이 레포 어떻게 짜여있어', 'analyze this codebase', '오픈소스 분석'. 후속 요청('다시 분석', '재분석', '아키텍처만 다시', '성능 관점 보강', '보고서 업데이트', '우선순위 재조정', '특정 모듈만', '이전 분석 개선')에도 트리거된다. 단, 버그 수정은 bug-fix, 기능 개발은 feature-dev, 코드베이스 기반 문서 작성은 docs-expert를 사용하라 — 이 스킬은 '분석·인사이트 추출' 전용."
---

# Codebase Analyst Orchestrator

코드베이스 심층 분석 하네스의 오케스트레이터. 5개 전문 렌즈 에이전트를 병렬로 돌려 코드베이스를 다각도로 분석하고, synthesizer가 종합 보고서로 통합한다.

## 핵심 아이디어

단순히 "코드가 무엇을 하는지" 설명하는 게 아니라, **개발자가 실무에 가져갈 인사이트**를 추출하는 것이 목표다.

- **5개 렌즈는 고정** (architecture / domain / quality / performance / dx) — 도메인 페르소나를 동적 생성하지 않는다. 코드베이스를 보는 관점은 안정적이기 때문.
- **공유 멘탈 모델 먼저** — 오케스트레이터가 코드베이스를 스카우트해 `00_scout.md`(스택·구조·진입점 맵)를 만들고, 5렌즈가 같은 출발점에서 분석한다. 이것이 'Team Big Five'의 shared mental model.
- **상호 모니터링은 경량** — 각 렌즈가 "교차 발견(→ 다른 렌즈)"을 기록하고, synthesizer가 이를 엮어 충돌을 조정한다. 별도 통신 단계 없이 Big Five의 mutual monitoring을 구현.
- **모든 발견은 근거 기반** — `path:line` 인용 + Why 추론 + 트레이드오프. 근거 없는 일반론 금지.

## 먼저 읽을 파일

- **미션 헌장(정전): `references/mission-prompt.md`** — 오케스트레이터가 Phase 1에서 "주입 블록"을 로드해 모든 에이전트에 주입. 분석 스탠스의 단일 source of truth이자 아카이브. 분석 태도를 바꾸려면 이 파일만 고친다.
- 렌즈별 분석 체크리스트: `references/lens-checklists.md` (각 렌즈 에이전트가 자기 섹션만 읽음 — 오케스트레이터는 읽을 필요 없음)
- 종합 보고서 템플릿: `references/report-template.md` (synthesizer가 읽음)

## 에이전트 렌즈

| 렌즈 | 정의 파일 | 관점 | 동시 호출 |
|------|----------|------|----------|
| codebase-architect | `~/.agents/agents/codebase-architect.md` | 시스템 구조·모듈 경계·의존성·통신 | 1명 |
| codebase-domain-designer | `~/.agents/agents/codebase-domain-designer.md` | 도메인 모델·유비쿼터스 언어·추상화 | 1명 |
| codebase-quality-reviewer | `~/.agents/agents/codebase-quality-reviewer.md` | 가독성·테스트·컨벤션·안티패턴·보안(코드) | 1명 |
| codebase-performance-analyst | `~/.agents/agents/codebase-performance-analyst.md` | 병목·캐싱·동시성·확장성·인프라 | 1명 |
| codebase-dx-analyst | `~/.agents/agents/codebase-dx-analyst.md` | 온보딩·툴링·문서·디버깅·구현 기법 | 1명 |
| codebase-synthesizer | `~/.agents/agents/codebase-synthesizer.md` | 5렌즈 통합 → 종합 보고서 | 1명 (최후) |

모든 에이전트는 `general-purpose` 빌트인 타입, Agent 호출 시 반드시 `model: "opus"` 명시.

## 워크플로우

### Phase 0: 컨텍스트 확인

**작업 디렉토리 정책:** 모든 중간 산출물은 `~/.agents/_workspace/harness-codebase-analyst/{slug}/`에 저장한다. `{slug}`는 분석 대상 식별자(레포명 + 날짜)로 Phase 1에서 확정한다. **CWD에는 산출물을 만들지 않는다.** 최종 보고서 기본 출력 경로는 **분석 대상 코드베이스 루트**의 `CODEBASE-ANALYSIS-{slug}.md`.

1. **분석 대상 경로(`$TARGET`) 확정.** 사용자가 경로/레포를 지정했으면 그것. 안 했으면 CWD가 분석 대상인지 확인하고, 모호하면 **묻는다** (추측 금지). 원격 레포면 먼저 클론 위치를 확인.

2. **슬러그 단서 확인:**
   - 사용자 명시 ("`myrepo` 분석 다시 해줘")
   - 직전 세션 슬러그 기억
   - 단서 없음 → 신규 슬러그 생성 대상

3. 슬러그가 식별되면 `~/.agents/_workspace/harness-codebase-analyst/{slug}/` 존재 확인:
   - **존재 + 부분 수정 요청** ("아키텍처만 다시", "성능 보강") → `$WS` 고정, Phase 3 부분 재실행 모드
   - **존재 + 처음부터 다시** → 기존 디렉토리를 `{slug}_prev_{timestamp}/`로 이동 후 초기 실행
   - **미존재 / 단서 없음** → 신규 슬러그 (Phase 1 확정), 초기 실행

4. 신규 실행이면 `mkdir -p ~/.agents/_workspace/harness-codebase-analyst/{slug}/`. 모든 에이전트 호출에 `$WS`와 `$TARGET` 절대 경로를 프롬프트에 명시 전달한다 (홈 경로 `~` 금지 — 절대 경로만).

5. 요청 유형 판별:

| 시나리오 | 판별 키워드 | Phase 진입 |
|---------|-----------|----------|
| 신규 분석 | "이 코드베이스 분석", "레포 리뷰" | Phase 1부터 |
| 부분 재실행 | "아키텍처만 다시", "성능 관점 보강", "우선순위 재조정" | Phase 3 부분 모드 (해당 렌즈만 재호출 → synthesizer 재통합) |
| 단순 질문 | "이 함수 뭐해", "이 파일 설명" | 에이전트 없이 직접 응답 |

6. **미션 변형 선택 (`$VARIANT`):** `references/mission-prompt.md`의 "미션 변형 선택" 표를 기준으로 사용자 요청의 어조·키워드로 변형을 고른다. 단서 없으면 **deep(기본)**. "빠르게/간단히/핵심만/진단/훑어" 계열이면 **quick**. 부분 재실행 시 이전 실행의 변형을 유지한다 (사용자가 바꾸지 않는 한). 선택된 변형은 Phase 1에서 로드한다.

### Phase 1: 코드베이스 스카우트 (오케스트레이터 직접)

오케스트레이터가 직접 수행한다 (에이전트 호출 안 함). 5개 렌즈가 공유할 멘탈 모델을 만든다. 깊이 분석이 아니라 **지도 그리기**다 — 빠르게.

**먼저 미션 헌장을 로드한다.** `references/mission-prompt.md`를 읽어 Phase 0에서 선택한 `$VARIANT`에 해당하는 `---INJECT-START:{VARIANT}---` ~ `---INJECT-END:{VARIANT}---` 사이의 텍스트를 `$MISSION`으로 확보한다 (예: `$VARIANT=deep` → `---INJECT-START:deep---` 블록). 이 분석 헌장은 Phase 2의 모든 렌즈 호출과 Phase 3의 synthesizer 호출 프롬프트 **맨 앞에 그대로 포함**한다 — 5개 렌즈가 동일한 분석 스탠스를 공유하게 하는 장치다. 헌장은 "왜·무엇을·얼마나 깊이"의 스탠스만 담고, "누가·언제·어떻게"의 구조는 이 워크플로우가 담당한다. 변형의 **실행 힌트**(quick = 렌즈별 상위 3~5개·1페이지 보고서)는 Phase 2 렌즈 프롬프트와 Phase 3 보고서 분량에 반영한다.

수집 항목:
- **기술 스택**: 언어, 프레임워크, 주요 라이브러리, 빌드 도구 (package.json / go.mod / Cargo.toml / pyproject.toml / pom.xml 등에서)
- **규모**: 대략적 파일 수, 최상위 디렉토리 구조, LOC 감
- **진입점**: main/app/index/server 위치, 라우팅, CLI 엔트리
- **구조 맵**: 최상위 모듈/패키지와 그 역할(추정)
- **핵심 설정 위치**: 린터/포매터, 테스트 디렉토리, CI 설정, 인프라 파일(Dockerfile/IaC), 데이터 계층, 문서/README

`$WS/00_scout.md`에 저장:

```markdown
---
target: {$TARGET 절대 경로}
slug: {slug}
scouted: {YYYY-MM-DD}
---
## 기술 스택
## 규모 (파일 수 / 최상위 구조 / LOC 감)
## 진입점
## 모듈/패키지 맵 (이름 → 역할 추정)
## 핵심 위치 (린터 / 테스트 / CI / 인프라 / 데이터 계층 / 문서)
## 렌즈별 주목 지점 (각 렌즈가 우선 볼 디렉토리 힌트)
```

> 스카우트는 빠르게. 전수 읽기 금지. `ls`, `glob`, 설정 파일 읽기, 진입점 1~2개 훑기 수준. 깊은 분석은 렌즈 에이전트의 일이다.

### Phase 2: 5렌즈 병렬 분석 (팬아웃)

5개 렌즈를 **모두 병렬로** 호출한다 (`run_in_background=true`).

```
WS = "/Users/{user}/.agents/_workspace/harness-codebase-analyst/{slug}/"   # Phase 0 확정
TARGET = "{분석 대상 코드베이스 절대 경로}"                                  # Phase 0 확정

for lens in [architect, domain-designer, quality-reviewer, performance-analyst, dx-analyst]:
    Agent(
        subagent_type="general-purpose",
        model="opus",
        run_in_background=true,
        description=f"Analyze: {lens}",
        prompt=f"""
        {MISSION}    ← Phase 1에서 로드한 분석 헌장을 맨 앞에 그대로 포함

        너는 codebase-{lens} 렌즈다. 정의 파일 ~/.agents/agents/codebase-{lens}.md 를 먼저 읽어라.

        작업 디렉토리($WS): {WS}
        분석 대상($TARGET): {TARGET}

        - 코드베이스 맵: {WS}00_scout.md (먼저 읽어라)
        - 분석 체크리스트: ~/.agents/skills/codebase-analyst/references/lens-checklists.md 의 네 렌즈 섹션
        - 실제 코드는 {TARGET} 에서 직접 읽어라.

        네 렌즈 관점으로만 분석하고, 결과를 {WS}01_{lens_output}.md 에 저장하라.
        모든 발견은 path:line 근거 + Why 추론 + 트레이드오프를 포함한다.
        """
    )
```

⚠️ 모든 호출에 `$WS`와 `$TARGET` 절대 경로를 반드시 포함한다. 렌즈 출력 파일명: `01_architecture.md`, `01_domain.md`, `01_quality.md`, `01_performance.md`, `01_dx.md`.

5개 모두 완료까지 대기. 실패한 렌즈는 1회 재시도 → 재실패 시 누락 명시하고 진행 (synthesizer에 누락 통보).

### Phase 3: 종합 (synthesizer)

5개 렌즈 완료 후 synthesizer 1회 호출.

```
Agent(
    subagent_type="general-purpose",
    model="opus",
    run_in_background=true,
    description="Synthesize codebase analysis",
    prompt=f"""
    {MISSION}    ← Phase 1에서 로드한 분석 헌장을 맨 앞에 그대로 포함

    너는 codebase-synthesizer 다. 정의 파일 ~/.agents/agents/codebase-synthesizer.md 를 먼저 읽어라.

    작업 디렉토리($WS): {WS}
    입력: {WS}00_scout.md + {WS}01_*.md (5개 렌즈)
    템플릿: ~/.agents/skills/codebase-analyst/references/report-template.md

    [누락된 렌즈가 있으면 여기 명시]

    종합 보고서를 {WS}02_synthesis.md 에 저장하고,
    최종본을 {TARGET}/CODEBASE-ANALYSIS-{slug}.md 에도 저장하라.
    """
)
```

synthesizer 완료 후 오케스트레이터가 최종 경로를 사용자에게 보고하고, 핵심 인사이트(P0)를 3~5줄로 요약 제시한다.

**부분 재실행 모드** (Phase 0에서 진입):
- "아키텍처만 다시" → architect만 재호출 → synthesizer 재통합
- "성능 관점 보강" → performance-analyst 재호출 → synthesizer 재통합
- "우선순위 재조정" / "실무 적용 보강" → synthesizer만 재호출 (렌즈 재실행 없이)
- "특정 모듈만" → 관련 렌즈에 해당 모듈로 범위 좁혀 재호출 → synthesizer

### Phase 4: 사용자 피드백 수집

발행 후 묻는다:
- "분석에서 더 깊이 봤으면 하는 렌즈나 영역이 있나요?"
- "보고서 우선순위·실무 적용 섹션이 실제로 쓸모 있나요?"

피드백이 있으면 Phase 3 부분 재실행 모드로 진입. 없으면 종료.

## 데이터 흐름

```
사용자 입력 ($TARGET 지정)
   ↓
Phase 0: 슬러그 결정 → $WS = ~/.agents/_workspace/harness-codebase-analyst/{slug}/
   ↓
Phase 1: $WS/00_scout.md  (오케스트레이터 직접 — 공유 멘탈 모델)
   ↓
Phase 2: $WS/01_{architecture,domain,quality,performance,dx}.md  (5렌즈 병렬)
   ↓
Phase 3: $WS/02_synthesis.md  →  $TARGET/CODEBASE-ANALYSIS-{slug}.md  (synthesizer)
   ↓
Phase 4: 피드백 → 부분 재실행 (같은 $WS 재사용)
```

중간 산출물은 `$WS`에 보존되어 슬러그만 알면 임의 시점 부분 재실행 가능.

## 에러 핸들링

| 에러 | 처리 |
|------|------|
| 렌즈 호출 실패 | 1회 재시도 → 재실패 시 해당 렌즈 없이 진행, synthesizer에 누락 통보, 보고서에 "미수행" 명시 |
| `$TARGET` 경로 불명/접근 불가 | 즉시 중단, 사용자에게 경로 확인 요청 (추측 금지) |
| 스카우트 단계 스택 식별 실패 | 사용자에게 주력 언어/프레임워크 확인 |
| 코드베이스 과대 (전수 불가) | 스카우트에서 핵심 영역 식별 → 각 렌즈에 샘플링 범위 전달, 보고서에 범위 명시 |
| 렌즈 간 충돌 5건+ | synthesizer가 양쪽 출처 병기하고 맥락별 판단 추가 (삭제 금지) |
| 모든 렌즈 "데이터 부족" | 종합 강행 금지, 코드베이스 범위·접근성 문제 사용자 보고 |

## 테스트 시나리오

### 정상 흐름: 오픈소스 레포 분석
1. 사용자: "`~/projects/some-api` 코드베이스 분석해줘"
2. Phase 0: `$TARGET=/Users/{user}/projects/some-api`, 슬러그 `some-api-2026-05-29`, `$WS` mkdir
3. Phase 1: 스카우트 → `00_scout.md` (Node/Express, 120파일, REST API)
4. Phase 2: 5렌즈 병렬 → `01_*.md` 5개
5. Phase 3: synthesizer → `02_synthesis.md` + `~/projects/some-api/CODEBASE-ANALYSIS-some-api-2026-05-29.md`
6. 오케스트레이터: P0 인사이트 3개 요약 보고
7. Phase 4: 피드백 수집

### 부분 재실행: 성능 관점 보강
1. 사용자: "방금 분석한 some-api, 성능 관점만 더 깊게 다시 봐줘"
2. Phase 0: 직전 슬러그 사용, `$WS` 존재 확인 → 부분 재실행 모드
3. performance-analyst만 재호출 (이전 `01_performance.md` 읽고 심화)
4. synthesizer 재호출 (갱신된 성능 렌즈 재통합)
5. 보고서 덮어쓰기

### 에러 흐름: 경로 불명
1. 사용자: "코드베이스 분석해줘" (경로 미지정, CWD도 코드베이스 아님)
2. Phase 0: `$TARGET` 확정 불가 → "어느 디렉토리/레포를 분석할까요? 절대 경로로 알려주세요." 질문 후 대기

## 산출물 체크리스트

- [ ] `$TARGET` 확정 및 `$WS = ~/.agents/_workspace/harness-codebase-analyst/{slug}/` 생성
- [ ] 미션 변형(`$VARIANT`: deep/quick) 선택 → `references/mission-prompt.md`의 해당 INJECT 블록을 `$MISSION`으로 로드 → 모든 렌즈·synthesizer 호출에 포함 (quick이면 실행 힌트도 반영)
- [ ] `$WS/00_scout.md` 작성 완료 (스택·구조·진입점 맵)
- [ ] 5개 렌즈 산출물 존재 (또는 누락 명시)
- [ ] 모든 발견에 `path:line` 근거 포함
- [ ] `$WS/02_synthesis.md` 작성 (8개 섹션 전부, 우선순위 정렬)
- [ ] 최종 보고서 `$TARGET/CODEBASE-ANALYSIS-{slug}.md` 저장
- [ ] P0 인사이트 사용자에게 요약 보고
- [ ] `$WS/` 보존 (부분 재실행 대비)

## 참고

- 미션 헌장 (정전 + 아카이브): `references/mission-prompt.md`
- 렌즈별 체크리스트: `references/lens-checklists.md`
- 종합 보고서 템플릿: `references/report-template.md`
