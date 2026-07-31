---
name: harness-legacy-scan
description: "AI 코딩 하네스(CLAUDE.md · AGENTS.md · .claude/skills · .claude/workflows · settings.json · .cursor/rules · hooks · MCP 설정)를 *읽기 전용*으로 감사하는 Dynamic Workflow 오케스트레이터. 7개 전문 관점 에이전트(Inventory · Global Context Tax · Skill Quality · Product Overlap · Safety/Permission · Refactor Planner · Adversarial Reviewer)를 병렬로 돌려 낡은 규칙·중복 지시·과도한 전역 컨텍스트·너무 넓은 Skill·불필요한 Hook/MCP·제품 기본 기능과 중복되는 설정을 찾아 KEEP/SHRINK/MOVE/SPLIT/CONVERT/DELETE 로 분류한 *분석 리포트만* 작성한다. 파일/hooks/MCP/권한을 절대 수정·삭제하지 않는다. 다음 상황에서 사용: '/harness-legacy-scan', '하네스 감사/점검', '하네스 다이어트 전 분석', '낡은 규칙 찾아줘', 'CLAUDE.md 비대해졌나', 'Skill 정리 후보', 'harness audit'. 산출 후 후속은 /harness-diet 로 넘긴다."
---

# harness-legacy-scan

내 AI 코딩 하네스를 **읽기 전용으로 감사**하는 Dynamic Workflow. 낡은 규칙을 찾아 줄일 후보를 분류한 *분석 리포트만* 만든다. 규칙을 추가하지 않는다.

## 감사 원칙 (이 렌즈로 모든 판단을 한다)

1. 좋은 하네스는 **반복되는 실제 실수**를 막아야 한다.
2. 좋은 하네스는 **과거의 습관을 보존하기 위해** 존재하면 안 된다.
3. 하네스는 더 많이 붙이는 것이 아니라 **필요한 순간에만** 나타나야 한다.
4. 이번 감사의 목표는 규칙을 *추가*하는 것이 아니라, 낡은 규칙을 찾고 **줄일 수 있는 후보를 분류**하는 것이다.

## 🚫 하드 제약 (위반 금지)

이 워크플로우와 그 안의 모든 에이전트는 **읽기 전용**이다.

- 파일을 수정하지 마.
- 파일을 삭제하지 마.
- hooks 를 수정하지 마.
- MCP 설정을 수정하지 마.
- `allowed-tools` / 권한을 바꾸지 마.
- 명령(테스트/빌드/배포)을 실행하지 마 — 오직 *읽기*(Read/Glob/Grep/ls/cat)만.
- 이번 단계의 유일한 산출물은 **분석 리포트 파일 하나**다. (리포트 작성은 하네스 *수정*이 아니므로 허용 — 단 감사 대상 파일은 절대 건드리지 않는다.)

서브에이전트를 띄울 때 **각 에이전트 프롬프트 첫 줄에 위 제약을 명시**한다.

## 감사 범위

호출된 위치(cwd)와 사용자 홈 양쪽에서 아래를 수집한다:

- `CLAUDE.md` (cwd + `~/.claude/CLAUDE.md` + `~/.agents/rules/**`)
- `AGENTS.md` (cwd + `~/.agents/rules/codex/AGENTS.md` 등)
- `.claude/skills/**` 와 `~/.agents/skills/**` (SKILL.md + references/examples)
- `.claude/workflows/**`
- `.claude/settings.json` (+ `settings.local.json`, `~/.claude/settings.json`)
- `.cursor/rules/**`
- MCP 설정 파일이 있으면 (`.mcp.json`, `~/.codex/config.toml` 의 mcp 섹션, settings.json 의 mcp 등)
- hooks 설정이 있으면 (`settings.json` 의 hooks, plugin `hooks/hooks.json` 등)

> 글로벌(홈)과 프로젝트(cwd) 하네스가 섞여 있으면 **각 발견의 경로에 어느 스코프인지 명시**한다.

## 동작 — Dynamic Workflow (멀티 에이전트)

Claude Code 에선 **Workflow 도구**로, 그 외 호스트에선 가용한 멀티 에이전트/서브에이전트 메커니즘으로 아래 단계를 구성·실행한다. 모든 에이전트는 위 하드 제약(읽기 전용)을 받는다.

**Phase 1 — Inventory** (1 에이전트)
- *Inventory Agent*: 위 범위의 하네스 파일·설정을 모두 찾아 목록화한다. 각 항목: 경로 · 스코프(global/project) · 종류(global-instruction / skill / workflow / setting / hook / mcp / cursor-rule) · 대략 크기(줄 수/토큰 추정) · 한 줄 목적. 이후 단계의 *공유 입력*이 된다.

**Phase 2 — 병렬 분석** (4 에이전트 동시, 각각 Phase 1 인벤토리를 입력으로)
- *Global Context Tax Agent*: CLAUDE.md · AGENTS.md · Cursor Rules 처럼 **모든 세션에 항상 붙는 지침**이 불필요한 컨텍스트 비용을 만드는지. 항상 로드될 필요 없는 절차/예시/체크리스트, 한 번도 안 쓰이는 규칙, 너무 일반적이라 행동을 못 바꾸는 문장을 찾는다.
- *Skill Quality Agent*: 각 Skill 이 **지금도 필요한지**, `description` 이 너무 넓어 과잉 자동호출되는지, SKILL.md 가 너무 길어 reference/examples 로 분리할 후보인지, 중복 Skill 이 있는지.
- *Product Overlap Agent*: 예전엔 필요했지만 이제 **Claude Code / Codex / Cursor 제품 기본 기능과 중복**될 가능성이 있는 규칙(예: 기본 제공되는 plan mode · todo · diff · permission prompt 를 프로즈로 재구현한 것).
- *Safety and Permission Agent*: hooks · `allowed-tools` · MCP 설정이 **너무 넓은 권한**을 주는지. (분석만 — 수정 금지.)

**Phase 3 — Refactor Planner** (1 에이전트, Phase 2 발견 종합)
- 각 발견 항목을 **KEEP / SHRINK / MOVE / SPLIT / CONVERT / DELETE** 중 하나로 분류하고, MOVE/SPLIT 이면 추천 위치를 적는다.

**Phase 4 — Adversarial Reviewer** (1 에이전트)
- Planner 의 SHRINK/MOVE/CONVERT/DELETE 후보 각각에 대해 **"줄이거나 삭제하면 오히려 위험해질 수 있는가"** 를 반박 검토한다. 안전장치(실제 실수를 막는 규칙)를 무심코 없애려는 항목을 KEEP 또는 *수동 승인 필요* 로 되돌린다. 신뢰도를 조정한다.

**Phase 5 — Synthesize**
- 모든 발견을 합치고 중복 제거 후 아래 *발견 항목 형식* 으로 정리, *필수 최종 섹션* 9개를 포함한 리포트를 작성한다.

## 발견 항목 형식 (항목마다)

- **경로** (스코프 명시: global / project)
- **현재 목적**
- **발견한 문제**
- **근거** (왜 낡았/중복/과넓다고 보는지 — 구체적으로)
- **추천 조치**: KEEP / SHRINK / MOVE / SPLIT / CONVERT / DELETE
- **옮긴다면 추천 위치** (MOVE/SPLIT 일 때)
- **변경 시 위험도**: low / medium / high
- **신뢰도**: low / medium / high
- **/harness-diet 자동 처리 가능 여부**: yes / no (no 면 사유)

## 필수 최종 섹션 (리포트 끝에 반드시)

1. 전체 요약
2. 유지해야 할 항목 (KEEP)
3. 줄여야 할 항목 (SHRINK)
4. 전역 지침 → Skill 로 옮길 항목 (MOVE)
5. Skill → reference.md / examples.md 로 분리할 항목 (SPLIT)
6. 삭제 후보 (DELETE)
7. **사람이 직접 승인해야 하는 위험한 변경** (high-risk / Adversarial 가 되돌린 것)
8. **/harness-diet 로 넘겨도 되는 low-risk 변경 목록** (자동 처리 가능 + low risk + medium↑ 신뢰도만)
9. **/harness-diet 실행용 추천 프롬프트** (8번 목록을 넘기는 구체 프롬프트)

## 산출 위치

리포트를 `<cwd>/.claude/harness-audit/harness-legacy-scan-<YYYY-MM-DD>.md` 에 쓴다 (날짜는 런타임 `date +%F`). `.claude/harness-audit/` 가 없으면 만든다. 이 디렉토리 생성·리포트 쓰기 외에 **어떤 파일도 만들거나 고치지 않는다**. 작성 후 경로와 8번 섹션을 사용자에게 보고한다.

## 사용하지 말아야 할 때

- 하네스를 *수정/정리* 하려는 단계 → `/harness-diet` (이 스킬은 분석 전용).
- 단일 파일의 사소한 점검 → 그냥 직접 Read.
- 코드베이스(애플리케이션 코드) 분석 → `codebase-analyst`.

## 추천 사용 순서

1. `/harness-legacy-scan` 으로 리포트 생성.
2. 리포트의 *8. /harness-diet 로 넘겨도 되는 low-risk 변경 목록* 을 사람이 확인.
3. 납득되는 항목만 `/harness-diet` 에 넘긴다.
4. 변경 후 `git diff` 확인.
5. 리포트의 smoke-test 프롬프트로 회귀 점검.
