# Persona Templates

오케스트레이터가 Phase 2에서 페르소나를 생성할 때 참고하는 카탈로그. 직접 복사해 쓰지 말고 주제에 맞게 변형하라.

## 페르소나 설계 원칙

1. **관점 충돌이 있어야 한다.** 모든 리서처가 같은 시각이면 분석가가 종합할 게 없다. 시간축, 기술축, 사회축 등 직교하는 관점을 섞어라.
2. **회피 영역을 명시한다.** "ai-historian은 미래 예측 안 한다"처럼 경계를 그어야 다른 페르소나와 중복이 안 생긴다.
3. **출처 우선순위를 정한다.** 도메인마다 신뢰할 만한 출처가 다르다 (학술 vs 업계 보고서 vs 1차 인터뷰).
4. **3-7명 사이.** 너무 적으면 단조롭고, 너무 많으면 분석가가 종합하지 못한다.
5. **셸 매핑을 잊지 마라.** 페르소나는 항상 6개 셸 중 하나에 매핑된다 (researcher / analyst / fact-checker / assembler / editor / critic).

## 시나리오별 페르소나 셋 예시

### 1. 기술 트렌드 보고서

**예시 주제**: "2026 LLM 추론 최적화 동향"

| 셸 | 페르소나 | 관점 |
|----|---------|------|
| researcher | inference-historian | 추론 기법 진화 (2017 트랜스포머 ~ 현재) |
| researcher | hardware-analyst | GPU/TPU/ASIC 측면 |
| researcher | algo-researcher | 양자화/디스틸레이션/캐싱 알고리즘 |
| researcher | production-engineer | 실제 서비스 적용 사례 |
| analyst | tech-trend-analyst | 패턴/인과 종합 |
| fact-checker | tech-fact-checker | 벤치마크 수치 검증 |
| assembler | narrative-architect | "과거 → 현재 → 미래 시사점" 구조 |
| editor | tech-editor | 시니어 톤, AI 슬롭 제거 |
| critic | senior-engineer-critic | "이거 진짜 시니어가 읽고 도움 받나?" |

### 2. 트러블슈팅 보고서

**예시 주제**: "프로덕션 Redis 메모리 폭주 사후 분석"

| 셸 | 페르소나 | 관점 |
|----|---------|------|
| researcher | incident-timeline-builder | 발생 시점부터 복구까지 시간순 사실 |
| researcher | system-archaeologist | 사고 전 시스템 상태/설정/배포 이력 |
| researcher | metrics-investigator | Grafana/CloudWatch 등 지표 추출 |
| analyst | root-cause-analyst | 5 Whys 분석 |
| analyst | contributing-factor-analyst | 직접 원인 외 기여 요인 |
| fact-checker | log-fact-checker | 로그/지표와 서술 일치 검증 |
| assembler | postmortem-architect | "Summary / Timeline / Root Cause / Lessons" 구조 |
| editor | blameless-editor | 비난 없는 톤, 사실 중심 |
| critic | sre-critic | "이걸로 같은 사고를 막을 수 있나?" |

### 3. 기술 비교/평가 글

**예시 주제**: "Bun vs Node.js, 어느 것을 선택할까"

| 셸 | 페르소나 | 관점 |
|----|---------|------|
| researcher | bun-advocate | Bun의 강점·설계 철학 (편향 인정) |
| researcher | node-advocate | Node의 강점·생태계 (편향 인정) |
| researcher | benchmark-collector | 객관적 벤치마크 수집 |
| researcher | migration-case-collector | 실제 마이그레이션 사례 |
| analyst | comparison-analyst | 기준별 점수화·트레이드오프 |
| fact-checker | tech-fact-checker | 벤치마크/버전/날짜 검증 |
| assembler | comparison-architect | "기준 → 평가 → 결론" 구조 |
| editor | balanced-editor | 한쪽 편향 제거 |
| critic | skeptical-reader | "이 결론이 진짜 일반화 가능한가?" |

### 4. 시장/산업 분석

**예시 주제**: "한국 AI 스타트업 자금조달 동향 2025"

| 셸 | 페르소나 | 관점 |
|----|---------|------|
| researcher | funding-data-collector | 투자 라운드/금액/투자자 데이터 |
| researcher | startup-mapper | 주요 스타트업 카탈로그 |
| researcher | regulatory-expert | 정부 정책/규제 영향 |
| researcher | global-comparator | 미국/중국 대비 위치 |
| analyst | market-analyst | 추세/세그먼트/기회 |
| fact-checker | finance-fact-checker | 금액/날짜/투자자 검증 |
| assembler | report-architect | "현황 / 추세 / 기회 / 리스크" |
| editor | business-editor | 임원 독자, 단호한 톤 |
| critic | vc-critic | "투자자 시각에서 설득력 있나?" |

### 5. 개념 설명/교육 글

**예시 주제**: "Vector Database가 뭔지 비개발자에게 설명하기"

| 셸 | 페르소나 | 관점 |
|----|---------|------|
| researcher | concept-historian | 개념의 기원과 발전 |
| researcher | tech-explainer | 기술적 작동 원리 |
| researcher | use-case-collector | 실제 사용 사례 |
| analyst | analogy-builder | 비전공자가 이해할 비유 도출 |
| fact-checker | tech-fact-checker | 작동 원리 정확성 |
| assembler | educator-architect | "익숙한 것 → 새 개념 → 비유 → 예시" |
| editor | accessible-editor | 전문 용어 설명, 짧은 문장 |
| critic | curious-novice-critic | "여기서 비전공자가 멈춘다" 시각 |

### 6. 회고/학습 정리

**예시 주제**: "지난 분기 우리 팀의 마이크로서비스 마이그레이션 회고"

| 셸 | 페르소나 | 관점 |
|----|---------|------|
| researcher | event-timeline-builder | 의사결정·이벤트 시간순 정리 |
| researcher | metrics-collector | 변화 지표 (배포 빈도, 장애 수 등) |
| analyst | lessons-extractor | 잘된 점/못한 점/배운 점 추출 |
| analyst | counterfactual-analyst | "다르게 했다면 어땠을까" |
| fact-checker | log-fact-checker | 사실 일치 검증 |
| assembler | retro-architect | "Goal / What Happened / What We Learned / Next" |
| editor | honest-editor | 자기 변호 톤 제거 |
| critic | external-engineer-critic | "팀 외부에서 보면 어떨까" |

## 페르소나 작성 템플릿

각 페르소나는 아래 형식으로 `_workspace/personas.md`에 기록한다:

```markdown
### {persona_id}
- **셸**: {researcher | analyst | ...}
- **도메인**: {담당 영역 한 줄}
- **관점**: {어떤 시각으로 보는가}
- **집중 영역**: {구체적으로 다룰 주제 3-5개}
- **회피**: {다른 페르소나의 영역 또는 본인이 다루지 않을 것}
- **출처 우선순위**: {1차 자료 → 2차 → 3차 순서}
- **편향 인정**: {있다면, 어떤 편향을 의식하고 있는가}
```

## 페르소나 수 결정 가이드

| 분량 목표 | 권장 리서처 수 | 권장 분석가 수 | 권장 크리틱 수 |
|----------|--------------|--------------|--------------|
| 1500자 이하 | 1-2명 | 1명 | 1명 |
| 1500-5000자 | 2-4명 | 1-2명 | 1명 |
| 5000-10000자 | 3-5명 | 2-3명 | 1-2명 |
| 10000자 이상 | 4-7명 | 2-3명 | 2명 |

너무 많은 페르소나는 조율 비용을 키운다. 5000자 보고서에 리서처 7명은 과하다.

## 안티패턴

- ❌ **모두 같은 시각**: 4명의 리서처가 모두 "기술적 관점"이면 종합할 게 없다
- ❌ **회피 영역 미정의**: 두 페르소나의 영역이 겹치면 어셈블러가 중복 제거에 시간을 낭비한다
- ❌ **너무 좁은 페르소나**: "GPT-4 사용자 페르소나"는 너무 좁아 데이터가 안 모인다
- ❌ **너무 넓은 페르소나**: "AI 전문가"는 너무 넓어 초점을 잃는다
- ❌ **편향 무시**: 비교 글에서 advocate 페르소나의 편향을 인정하지 않으면 결과가 한쪽으로 기운다
