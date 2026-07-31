---
name: oss-contribute
description: "Open source contribution workflow in 3 phases. Use when the user invokes /oss-contribute or wants to contribute to an open source project. Guides through: (1) issue analysis and contribution strategy with agent-council evaluation, (2) code implementation with branch isolation and test verification, (3) archiving contribution to Notion via notion-mcp. Handles both user-provided issues and self-proposed improvement suggestions."
---

# OSS Contribute

오픈소스 기여 3단계 워크플로우.

## 시작 절차

스킬 호출 시 아래 순서로 정보를 수집해:

1. **프로젝트 확인**: "어떤 프로젝트에 기여하고 싶어? GitHub URL을 알려줘."
2. **이슈 확인**: "특정 이슈가 있어? 이슈 번호나 URL을 알려줘. 없으면 내가 직접 프로젝트를 분석해서 기여 가능한 이슈를 제안할게."

정보 수집 후 아래 3단계를 순서대로 진행해. **각 단계 완료 후 반드시 사용자 승인을 받고 다음 단계로 넘어가.**

## 3단계 워크플로우

### Phase 1: 이슈 분석 및 기여 전략 수립
→ [references/phase1.md](references/phase1.md) 참조

- CONTRIBUTING.md 분석 → 이슈 탐색 → 중복 PR 확인 → agent-council 평가 → 기여 전략 보고서 작성
- 이슈가 제공된 경우: 해당 이슈 직접 분석
- 이슈가 없는 경우: good first issue / help wanted / bug / enhancement 등 라벨 이슈 중 최적 후보 자체 선정 후 역제안

### Phase 2: 코드 수정 및 결과물 생성
→ [references/phase2.md](references/phase2.md) 참조

- 브랜치 생성 → 구현 → lint/type/test 검증 → 논리 단위 커밋 → PR 초안 작성

### Phase 3: Notion 아카이빙
→ [references/phase3.md](references/phase3.md) 참조

- notion-mcp로 기여 내역(Problem / Solution / Metadata)을 Notion 데이터베이스에 기록
