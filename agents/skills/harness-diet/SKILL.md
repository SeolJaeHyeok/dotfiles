---
name: harness-diet
description: "harness-legacy-scan 리포트의 *low-risk 항목만* 적용해 AI 코딩 하네스를 더 짧고·명확하고·필요한 순간에만 나타나게 정리하는 Dynamic Workflow 오케스트레이터. CLAUDE.md 중복/일반 지침 축소, 작업별 절차를 .claude/skills 로 이동, 긴 SKILL.md 를 SKILL.md+reference.md+examples.md 로 분리, Skill description 을 좁히기, 과넓은 Skill 에 '사용하지 말아야 할 때' 추가, 삭제 후보는 .claude/archive/harness-diet-YYYY-MM-DD/ 로 *이동*(영구 삭제 X). hooks/MCP/allowed-tools 권한·애플리케이션 코드는 절대 건드리지 않고, 불확실하면 수동 승인 목록에 남긴다. 다음 상황에서 사용: '/harness-diet', '하네스 다이어트', 'low-risk 하네스 개선 적용', 'scan 리포트대로 정리해줘'. 반드시 먼저 /harness-legacy-scan 리포트가 있어야 한다."
---

# harness-diet

`harness-legacy-scan` 리포트를 바탕으로 **low-risk 하네스 개선만** 적용한다. 하네스를 더 짧고, 더 명확하고, 더 필요한 순간에만 나타나는 구조로 정리한다.

## 입력 (없으면 중단)

`<cwd>/.claude/harness-audit/harness-legacy-scan-*.md` 중 가장 최신 리포트를 읽는다. 없으면 **먼저 `/harness-legacy-scan` 을 돌리라고 안내하고 중단**한다. 리포트의 *8. /harness-diet 로 넘겨도 되는 low-risk 변경 목록* 만 처리 대상으로 삼는다. (사용자가 프롬프트로 특정 항목만 지정했으면 그 교집합만.)

## ✅ 허용되는 변경 (이 6종만)

1. CLAUDE.md 에서 **중복되거나 너무 일반적인 지침을 줄인다**.
2. 특정 작업에만 필요한 절차를 CLAUDE.md → `.claude/skills/<name>/` 의 Skill 로 **옮긴다**.
3. 너무 긴 SKILL.md 를 `SKILL.md` + `reference.md` + `examples.md` 구조로 **나눈다** (load-bearing 계약은 SKILL.md 에 남기고, 긴 설명/예시/체크리스트만 분리).
4. Skill `description` 을 **더 좁고 명확하게** 고친다.
5. 자동 호출 범위가 너무 넓은 Skill 에 **"사용하지 말아야 할 때" 섹션을 추가**한다.
6. 삭제 후보는 **영구 삭제하지 말고** `.claude/archive/harness-diet-<YYYY-MM-DD>/` 아래로 **이동**한다 (원래 상대경로 구조 보존).

## 🚫 금지되는 변경

1. 파일을 영구 삭제하지 마 (삭제 후보는 archive 로 이동).
2. hooks 를 수정하지 마.
3. MCP 설정을 수정하지 마.
4. `allowed-tools` / 권한을 넓히지 마.
5. 프로젝트 실제 애플리케이션 코드는 수정하지 마.
6. 테스트/빌드/배포 명령을 임의로 실행하지 마.
7. **불확실한 항목은 수정하지 말고** *수동 승인 필요* 목록에 남겨라. (리포트가 high-risk 또는 신뢰도 low 로 분류했거나, 적용 중 모호하면 손대지 않는다.)

## 개선 원칙

- 하네스는 더 많이 붙이는 게 아니라 필요한 순간에만 나타나야 한다.
- 전역 지침은 **짧고 안정적인 프로젝트 원칙**만 담는다.
- 반복 절차는 Skill 로 옮긴다.
- 긴 설명·예시·체크리스트는 reference.md / examples.md 로 분리한다.
- 작은 작업을 느리게 만드는 규칙은 **조건부 규칙**으로 바꾼다.
- 안전장치는 함부로 삭제하지 않는다.
- 변경 이유를 파일 안에 과도한 주석으로 남기지 말고 **최종 요약에 정리**한다.

## 동작 — Dynamic Workflow

파일을 *수정* 하므로 안전이 우선이다. 병렬 동시 편집으로 충돌을 만들지 말고, **분류 → 순차 적용 → 검증** 으로 구성한다. Claude Code 에선 Workflow 도구로, 그 외 호스트에선 가용 메커니즘으로:

**Phase 1 — Triage**
- 리포트의 low-risk 목록을 읽어 각 항목을 *허용되는 변경 6종* 중 무엇인지 매핑한다. 6종에 안 맞거나 금지 항목을 건드려야 하거나 모호하면 → *수동 승인 필요* 로 분류하고 제외한다.

**Phase 2 — 적용 (순차, 변경 종류별)**
- 각 항목을 한 번에 하나씩 적용한다. 변경 직전 대상 파일을 Read 로 확인(추측 금지).
- SPLIT: 분리 전 SKILL.md 의 load-bearing 지시가 유실되지 않게 reference.md/examples.md 로만 *이동*, SKILL.md 에는 포인터를 남긴다.
- MOVE: 옮긴 절차를 새 Skill 로 만들고, 원본(CLAUDE.md)에서는 제거하되 "이 작업은 `<skill>` 참조" 한 줄로 대체할 수 있다.
- DELETE→archive: `mkdir -p .claude/archive/harness-diet-<date>/<원래 상대경로 디렉토리>` 후 `git mv`(추적 파일) 또는 `mv`(비추적)로 이동.
- 각 적용 후 그 변경이 *허용 6종 + low-risk* 범위 안인지 self-check. 벗어나면 되돌리고 수동 승인 목록으로.

**Phase 3 — 검증 (Adversarial / Diff Review)**
- `git diff`(+ archive 이동 결과)를 받아, 금지 변경(hooks/MCP/권한/앱코드 수정)이 섞이지 않았는지, 안전장치를 실수로 없애지 않았는지, load-bearing 지시가 유실되지 않았는지 반박 검토한다. 문제 발견 시 해당 변경을 되돌린다.

> 커밋/푸시는 자동으로 하지 않는다 — 변경을 working tree 에 남기고 사용자가 `git diff` 로 확인 후 결정한다.

## 최종 보고 (반드시)

1. 변경한 파일 목록
2. 파일별 변경 이유
3. Before / After 요약
4. diff 요약
5. Claude(에이전트)의 행동이 어떻게 달라질 수 있는지
6. 아직 사람이 승인해야 하는 high-risk 항목 (적용 안 함 — 이유 포함)
7. 새 하네스를 검증하기 위한 **smoke-test 프롬프트 5개** (정리로 깨지기 쉬운 동작을 찌르는)

## 사용하지 말아야 할 때

- `harness-legacy-scan` 리포트가 없을 때 → 먼저 scan.
- hooks/MCP/권한/애플리케이션 코드 변경이 필요할 때 → 이 스킬 범위 밖, 사람이 직접.
- 하네스를 *늘리려* 할 때 → 이 스킬은 *줄이기* 전용.

## 추천 사용 순서

1. `/harness-legacy-scan` 리포트 생성.
2. 리포트의 low-risk 섹션 확인, 납득되는 항목만 이 스킬에 넘김.
3. 변경 후 `git diff` 확인.
4. 보고된 smoke-test 프롬프트 5개로 회귀 점검.
5. 문제 없으면 사용자가 커밋.
