---
name: content-expert
description: "범용 콘텐츠 제작 하네스 오케스트레이터. 6개 역할 셸(researcher/analyst/fact-checker/assembler/editor/critic)에 주제별 페르소나를 동적으로 부여하여 기술문서·트렌드 보고서·트러블슈팅 보고서·아티클·백서·리서치 노트 등 다른 사람에게 보여주는 모든 장문 텍스트 산출물을 일관된 품질로 생성한다. 다음 상황에서 반드시 이 스킬을 사용할 것: '~에 대한 보고서/글/문서/아티클 써줘', '~ 트렌드 정리', '~ 분석 글', '~ 백서/리서치/칼럼/포스트', '~에 대해 정리해줘', 'AI 트렌드 보고서', '트러블슈팅 보고서', '시장 분석', '기술 비교 글'. 후속 요청('다시 써줘', '톤 바꿔', '보강해줘', '챕터 추가', '팩트체크 다시', '편집만 다시 해줘', '비판적으로 다시 봐줘')에도 트리거된다. 단, 코드베이스 기반 기술 문서(README, ADR, API 레퍼런스, 아키텍처 문서)는 docs-expert를 사용하라."
---

# Content Expert Orchestrator

범용 콘텐츠 제작 하네스의 오케스트레이터. 6개의 역할 셸 에이전트에 **주제별 페르소나**를 동적으로 부여하여 어떤 주제든 일관된 품질의 장문 텍스트를 생성한다.

## 핵심 아이디어

기존 도메인 특화 하네스(aws-expert 등)는 도메인이 바뀔 때마다 새 에이전트가 필요했다. 이 하네스는 다르다:

- **셸 6개는 영구 고정** (researcher / analyst / fact-checker / assembler / editor / critic)
- **페르소나는 매 실행마다 동적 생성** — 주제를 받으면 오케스트레이터가 "이 주제에서 researcher는 ai-historian 역할을 한다"는 브리핑을 만들고, 셸 호출 시 system context로 주입한다
- **같은 셸이 다른 페르소나로 N회 호출 가능** — content-researcher를 ai-historian, model-analyst, regulatory-expert 3명으로 동시에 돌린다

결과: 디렉토리는 늘어나지 않고, 워크플로우·통신 프로토콜은 안정적이며, 모든 주제에 대해 동일한 품질 파이프라인이 적용된다.

## 먼저 읽을 파일

요청 유형에 따라 필요한 레퍼런스만 로드한다:
- 페르소나 생성 패턴: `references/persona-templates.md`
- 출력 형식별 구조 가이드: `references/output-formats.md`

## 에이전트 셸

| 셸 | 정의 파일 | 역할 | 동시 호출 가능 |
|----|----------|------|--------------|
| content-researcher | `~/.agents/agents/content-researcher.md` | 일차 자료 수집·정리 | ✅ (도메인별 N명) |
| content-analyst | `~/.agents/agents/content-analyst.md` | 종합 분석·인사이트 도출 | ✅ (관점별 N명) |
| content-fact-checker | `~/.agents/agents/content-fact-checker.md` | 사실 검증 | 보통 1명 |
| content-assembler | `~/.agents/agents/content-assembler.md` | 통합 초안 작성 | 1명 (단일 목소리) |
| content-editor | `~/.agents/agents/content-editor.md` | 문체·톤 다듬기 | 1명 |
| content-critic | `~/.agents/agents/content-critic.md` | 최종 비판적 리뷰 | 1~2명 (관점별) |

모든 셸은 `general-purpose` 빌트인 타입을 사용하며, Agent 호출 시 반드시 `model: "opus"` 명시.

## 미션 헌장 주입 (공통 패턴)

오케스트레이터는 Phase 0 시작 시 `references/mission-prompt.md`를 읽어 `---INJECT-START---` ~ `---INJECT-END---` 사이의 **콘텐츠 품질 헌장**을 `$MISSION`으로 로드한다. 이후 **모든 셸 호출**(researcher/analyst/fact-checker/assembler/editor/critic) 프롬프트 **맨 앞에 `$MISSION`을 포함**한다 — 페르소나 브리핑·`$WS`와 함께. 헌장은 주제·페르소나와 무관한 공통 품질 스탠스(상수)이고, 페르소나(`personas.md`)와 톤·분량·독자(`00_brief.md`)는 변수다. 품질 태도를 바꾸려면 `mission-prompt.md`의 주입 블록만 고친다. (패턴 근거: `~/.agents/rules/claude/harness-pattern-mission-charter.md`)

## 워크플로우

### Phase 0: 컨텍스트 확인

**작업 디렉토리 정책:** 모든 중간 산출물은 `~/.agents/_workspace/harness-content-expert/{slug}/`에 저장한다. `{slug}`는 세션별 고유 식별자(주제 슬러그 + 날짜)로, Phase 1에서 확정한다. CWD에는 어떤 산출물도 만들지 않는다. 최종 발행 경로 기본값은 `~/projects/mcircle/docs-archive/{slug}.md`.

1. 사용자 요청에서 기존 슬러그 단서를 찾는다:
   - 사용자가 명시 ("`llm-trends-2026` 보고서 다시 편집해줘")
   - 직전 세션의 슬러그를 기억하고 있다면 그것
   - 단서 없음 → 신규 슬러그 생성 대상

2. 슬러그가 식별되면 `~/.agents/_workspace/harness-content-expert/{slug}/` 존재 여부 확인:
   - **존재 + 사용자가 부분 수정 요청** → `$WS=~/.agents/_workspace/harness-content-expert/{slug}/`로 고정하고 Phase 6 부분 재실행 모드
   - **존재 + 사용자가 처음부터 다시** → `~/.agents/_workspace/harness-content-expert/{slug}/`를 `~/.agents/_workspace/harness-content-expert/{slug}_prev_{timestamp}/`로 이동 후 초기 실행
   - **미존재 또는 슬러그 단서 없음** → 신규 슬러그 생성 (Phase 1에서 확정), 초기 실행

3. 신규 실행이라면 `mkdir -p ~/.agents/_workspace/harness-content-expert/{slug}/`로 디렉토리를 만들고, 모든 셸 호출에 작업 디렉토리 절대 경로(`$WS = /Users/{user}/.agents/_workspace/harness-content-expert/{slug}/`)를 프롬프트에 명시 전달한다. 셸 에이전트는 이 절대 경로를 입출력 기준으로 사용한다 (홈 경로 `~`는 사용 금지 — 절대 경로만).

4. 요청 유형 판별:

| 시나리오 | 판별 키워드 | Phase 진입 |
|---------|-----------|----------|
| 신규 콘텐츠 생성 | "~에 대한 글/보고서/아티클" | Phase 1부터 |
| 부분 재실행 | "다시 써줘", "이 부분만", "톤 바꿔" | Phase 6 부분 모드 |
| 단순 질문 | "~ 형식이 뭐야", "~ 어떻게 써" | 에이전트 없이 직접 응답 |

### Phase 1: 브리핑 정리

사용자에게 부족한 정보를 **한 번에 1개씩** 묻는다 (Rule 0). 채워야 하는 슬롯:

| 슬롯 | 질문 예시 | 기본값 (사용자가 명시 안 할 시) |
|------|----------|----------------------------|
| **주제** | "정확한 주제 한 문장으로?" | 필수 — 비우면 진행 금지 |
| **슬러그** | (자동) 주제에서 영문 kebab-case로 자동 생성, 충돌 시 사용자에게 확인 | `{topic-kebab}-{YYYY-MM-DD}` 예: `llm-trends-2026-04-15` |
| **출력 형식** | "기술문서/트렌드보고서/트러블슈팅/아티클/백서 중 어느 쪽?" | 사용자 표현으로 추론 |
| **분량** | "짧게(~1500자) / 중간(~5000자) / 길게(10000자+)?" | 중간 |
| **독자** | "주 독자는 누구? (시니어 개발자 / 비개발자 임원 / 일반 대중)" | "기술에 관심 있는 시니어 개발자" |
| **톤** | "단호한 톤? 친근한 톤? 학술적 톤?" | 단호한 시니어 톤 |
| **출력 경로** | "최종 파일을 어디에 저장?" | `~/projects/mcircle/docs-archive/{slug}.md` |
| **마감/제약** | "특히 강조하거나 피해야 할 점이 있다면?" | 없음 |

**슬러그 생성 규칙:**
- 영문 소문자 + 숫자 + 하이픈만 사용 (한글·공백·특수문자 금지)
- 주제의 핵심 명사 2-4개 + 날짜 (`YYYY-MM-DD`)
- 예: "2026 LLM 추론 최적화 동향" → `llm-inference-optimization-2026-04-15`
- `~/.agents/_workspace/harness-content-expert/{slug}/`가 이미 존재하면 사용자에게 "기존 작업 이어서 / 새로 시작 / 다른 슬러그" 선택을 요청

수집한 내용을 `$WS/00_brief.md`에 저장:

```markdown
---
date: {YYYY-MM-DD}
---
## 주제
...

## 출력 형식
...

## 분량 목표
{단어 수 또는 글자 수}

## 독자
...

## 톤
...

## 강조/회피
...

## 출력 경로
...
```

### Phase 2: 페르소나 생성

오케스트레이터가 직접 수행 (셸 호출 안 함). `references/persona-templates.md`를 참고하여:

1. 주제를 분해해 필요한 **관점 3-7개**를 식별
2. 각 관점을 6개 셸 중 어떤 셸이 담당할지 매핑
3. 각 관점에 페르소나 ID와 브리핑 작성

`$WS/personas.md` 형식:

```markdown
---
topic: {주제}
generated: {YYYY-MM-DD}
---

## 리서처 (content-researcher 호출 시 페르소나)

### ai-historian
- **도메인**: AI 역사 (1950s ~ 현재)
- **관점**: 기술 진화의 시간 축
- **집중 영역**: 주요 마일스톤, 패러다임 전환, 인물
- **회피**: 미래 예측, 최신 모델 비교 (다른 페르소나 영역)
- **출처 우선순위**: 1차 논문 > 위키피디아 > 기술 블로그

### model-analyst
- **도메인**: 현대 LLM 비교 (2020~)
- **관점**: 모델 아키텍처/벤치마크/실용성
- **집중 영역**: GPT/Claude/Gemini/Llama 계열
- **회피**: 역사, 비기술 트렌드
- **출처 우선순위**: 모델 카드 > 논문 > 기술 리뷰

### regulatory-expert
...

## 분석가 (content-analyst 호출 시 페르소나)

### tech-trend-analyst
- **관점**: 기술적 패턴과 인과 관계
- ...

## 팩트체커
### tech-fact-checker
- **검증 깊이**: 모든 수치, 모델 버전, 발표일
- **도메인**: AI/ML

## 어셈블러
### narrative-architect
- **구조 선호**: 시간순 → 현재 → 시사점
- **목소리**: 단호한 시니어 엔지니어

## 에디터
### tech-editor
- **톤 가이드**: AI 슬롭 제거, 단정 톤, 코드/표 적극 사용

## 크리틱
### senior-engineer-critic
- **각도**: "이걸 읽고 시니어가 비웃지 않을까?" 시각으로 점검
```

페르소나 생성 후 사용자에게 보여주고 **승인**을 받는다 ("이 페르소나 구성으로 진행할까요?"). 사용자가 수정/추가 요청하면 반영.

### Phase 3: 리서치 (병렬)

승인된 페르소나의 모든 리서처를 **병렬**로 호출한다.

```
WS = "/Users/{user}/.agents/_workspace/harness-content-expert/{slug}/"  # Phase 0에서 확정된 절대 경로

for each researcher_persona in personas:
    Agent(
        subagent_type="general-purpose",
        model="opus",
        run_in_background=true,
        description=f"Research: {persona_id}",
        prompt=f"""
        {MISSION}    ← Phase 0에서 로드한 콘텐츠 품질 헌장을 맨 앞에 그대로 포함

        너는 content-researcher 셸이다. 정의 파일은 ~/.agents/agents/content-researcher.md 에 있으니 먼저 읽어라.

        너의 페르소나는 {persona_id} 다.
        작업 디렉토리($WS): {WS}

        페르소나 브리핑: {WS}personas.md
        사용자 브리핑: {WS}00_brief.md

        본인 페르소나의 영역만 리서치하고, 결과를 {WS}01_research_{persona_id}.md 에 저장하라.
        """
    )
```

⚠️ 모든 셸 호출은 프롬프트에 `$WS` 절대 경로를 반드시 포함한다. 셸 에이전트는 자체적으로 `_workspace/` 같은 상대 경로를 만들지 않는다.

모든 리서치가 완료될 때까지 대기. 실패한 페르소나가 있으면 1회 재시도 후, 재실패 시 누락 명시하고 진행.

### Phase 4: 분석 (병렬 또는 단일)

리서치 결과를 입력으로 분석가 셸 호출. 분석가가 1명이면 1회, 여러 관점이 필요하면 병렬 호출.

```
Agent(
    subagent_type="general-purpose",
    model="opus",
    run_in_background=true,
    description=f"Analyze: {persona_id}",
    prompt="...content-analyst 호출, 페르소나 = {persona_id}, 모든 01_research_*.md 통합..."
)
```

### Phase 5: 팩트체크 (1차)

리서치+분석 결과에 대한 팩트체크.

```
Agent(content-fact-checker, target = "$WS/01_research_*.md, $WS/02_analysis_*.md")
```

INCORRECT가 5개 이상이면 → 해당 리서처 1회 재호출하여 보강 후 재팩트체크.

### Phase 6: 통합 → 편집 → 비판 → 발행

순차 파이프라인 (각 셸은 이전 산출물 의존):

1. **content-assembler** → `$WS/04_draft.md`
2. **content-fact-checker** (2차, 초안 대상) → `$WS/03_fact_check.md` 갱신
3. **content-editor** → `$WS/05_edited.md`
4. **content-critic** → `$WS/06_critique.md`
5. **Verdict 분기**:
   - `ship` → 사용자 출력 경로로 복사
   - `revise` → P0 권고를 editor에 다시 전달, 1회 재편집 후 재비판
   - `block` → assembler부터 재실행 (사용자 확인 후)

**부분 재실행 모드** (Phase 0에서 진입):
- "톤 바꿔" → editor만 재호출
- "이 사실 다시 체크" → fact-checker만 재호출 (해당 영역)
- "이 챕터 다시" → assembler에 해당 섹션만 재구성 요청 → editor → critic
- "더 깊게 리서치" → 해당 페르소나 researcher 재호출 → analyst → assembler → ...

### Phase 7: 사용자 피드백 수집

발행 후 사용자에게 묻는다:
- "결과에서 개선할 부분이 있나요? (특정 섹션, 톤, 깊이, 누락 등)"
- "페르소나 구성에 추가/제외할 관점이 있었나요?"

피드백이 있으면 Phase 6 부분 재실행 모드로 진입. 없으면 종료.

## 데이터 흐름

```
사용자 입력
   ↓
Phase 0: 슬러그 결정 → $WS = ~/.agents/_workspace/harness-content-expert/{slug}/
   ↓
Phase 1: $WS/00_brief.md
   ↓
Phase 2: $WS/personas.md  ← 사용자 승인
   ↓
Phase 3: $WS/01_research_{p1}.md, $WS/01_research_{p2}.md, ... (병렬)
   ↓
Phase 4: $WS/02_analysis_{a1}.md, ... (병렬)
   ↓
Phase 5: $WS/03_fact_check.md (1차)
   ↓
Phase 6:
   ├── $WS/04_draft.md (assembler)
   ├── $WS/03_fact_check.md (2차, 갱신)
   ├── $WS/05_edited.md (editor)
   ├── $WS/06_critique.md (critic)
   └── 사용자 출력 경로 (기본: ~/projects/mcircle/docs-archive/)
   ↓
Phase 7: 피드백 → 부분 재실행 (같은 $WS 재사용)
```

모든 중간 산출물은 `~/.agents/_workspace/harness-content-expert/{slug}/`에 보존되어 슬러그만 알면 임의 시점에 부분 재실행 가능.

## 에러 핸들링

| 에러 | 처리 |
|------|------|
| 셸 호출 실패 | 1회 재시도 → 재실패 시 해당 산출물 없이 진행, 최종 보고서에 누락 명시 |
| 페르소나 브리핑 누락 | 즉시 중단, Phase 2 재실행 |
| 팩트체크 INCORRECT 폭증 | 해당 리서처 재호출 (1회), 그래도 안 되면 사용자에게 데이터 부족 보고 |
| 어셈블러가 모순 5개+ 보고 | 분석가 재호출 또는 사용자에게 우선순위 결정 요청 |
| critic verdict = block | 사용자 확인 후 assembler부터 재실행 |
| 페르소나 승인 거절 | Phase 2 재실행 (사용자 피드백 반영) |

## 테스트 시나리오

### 정상 흐름: AI 트렌드 보고서
1. 사용자: "2026년 LLM 트렌드 보고서 5000자 정도로 써줘"
2. Phase 0: 슬러그 = `llm-trends-2026-04-15`, `$WS = ~/.agents/_workspace/harness-content-expert/llm-trends-2026-04-15/`, `mkdir -p`
3. Phase 1: 독자/톤/출력 경로 확인 → `$WS/00_brief.md`
4. Phase 2: ai-historian + model-analyst + benchmark-analyst + regulatory-expert + tech-fact-checker + narrative-architect + tech-editor + senior-engineer-critic → `$WS/personas.md`
5. 사용자 승인
6. Phase 3-7 진행
7. 최종 산출물 (CWD): `./llm-trends-2026-04-15.md`
8. 중간 산출물 (보존): `~/.agents/_workspace/harness-content-expert/llm-trends-2026-04-15/`

### 부분 재실행: 톤 변경
1. 사용자: "방금 만든 LLM 트렌드 보고서 톤이 너무 딱딱해. 더 친근하게 다시 편집해줘"
2. Phase 0: 직전 슬러그 `llm-trends-2026-04-15` 사용, `$WS` 존재 확인 → 부분 재실행 모드
3. Phase 1: 톤 슬롯만 갱신 → `$WS/00_brief.md` 업데이트
4. content-editor만 재호출 (입력: `$WS/04_draft.md`, 톤=친근)
5. content-critic 재호출
6. 발행 (같은 출력 경로 덮어쓰기)

### 에러 흐름: 데이터 부족
1. 사용자: "{매우 niche한 주제} 보고서"
2. Phase 3 리서처 모두 GAP 다수 보고
3. 오케스트레이터: "이 주제는 공개 자료가 부족합니다. (a) 진행하되 GAP 명시 (b) 사용자가 1차 자료 제공 (c) 주제 범위 조정 — 어느 쪽?"

## 산출물 체크리스트

- [ ] 슬러그 확정 및 `$WS = ~/.agents/_workspace/harness-content-expert/{slug}/` 디렉토리 생성
- [ ] `$WS/00_brief.md` 작성 완료
- [ ] `$WS/personas.md` 사용자 승인 완료
- [ ] 모든 페르소나의 리서치 산출물 존재 (또는 누락 명시)
- [ ] 분석 보고서 존재
- [ ] 팩트체크 INCORRECT 0건 또는 모두 반영
- [ ] critic verdict = ship
- [ ] 사용자 출력 경로에 최종 파일 저장 (기본: `~/projects/mcircle/docs-archive/{slug}.md`)
- [ ] `$WS/` 보존 (삭제 금지 — 다음 부분 재실행 대비)

## 참고

- 페르소나 패턴 카탈로그: `references/persona-templates.md`
- 출력 형식별 구조 가이드: `references/output-formats.md`
