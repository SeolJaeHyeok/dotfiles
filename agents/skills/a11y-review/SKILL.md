---
name: a11y-review
description: "Frontend Fundamentals 4대 접근성 기준(구조·의미·예측 가능한 동작·시각 정보 보완)으로 코드를 리뷰하는 오케스트레이터. 4개 전문 a11y 리뷰어 에이전트를 병렬 실행해 결과를 머지·중복 제거하고 심각도순으로 정리한다. git diff(브랜치/커밋 비교)와 파일/디렉토리 직접 지정 두 입력 모드를 모두 지원한다. 코드에 modal/tab/accordion/radio/checkbox/switch 같은 UI 컴포넌트가 등장하면 컴포넌트별 ARIA 스펙 reference도 자동 로드한다. 다음 상황에서 사용: '/a11y-review', 'FF 접근성 기준으로 리뷰', 'a11y 검토', 'ARIA 점검', PR/변경분 접근성 점검, 특정 파일/디렉토리 접근성 점검."
---

# A11y Review Orchestrator

Frontend Fundamentals(Toss) 4대 접근성 기준으로 코드를 리뷰한다. 4개 전문 리뷰어를 병렬 실행하고 결과를 통합한다.

## 카테고리와 에이전트

| 카테고리 | 에이전트 | 레퍼런스 |
|---------|----------|---------|
| 구조 (Structure) | `a11y-structure-reviewer` | `references/structure.md` |
| 의미 (Semantic) | `a11y-semantic-reviewer` | `references/semantic.md` |
| 예측 가능한 동작 (Predictability) | `a11y-predictability-reviewer` | `references/predictability.md` |
| 시각 정보 보완 (Visual) | `a11y-visual-reviewer` | `references/visual.md` |

**공통 reference (모든 리뷰어가 항상 로드):**
- `references/foundation.md` — role/label/state ARIA 어휘집

**조건부 reference (UI 컴포넌트 감지 시 로드):**
- `references/ui-elements.md` — modal/tab/accordion/radio/checkbox/switch 스펙

## 워크플로우

### Phase 0: 입력 모드 결정

| 모드 | 트리거 | `target` |
|------|--------|---------|
| `diff` | "PR 리뷰", "main 대비", base ref 명시 | base ref (기본값 `main`) |
| `files` | 절대/상대 경로, 디렉토리, 파일명 | 경로 목록 |

둘 다 모호하면: `"어떤 단위로 리뷰할까요? (1) main 대비 변경분 (2) 특정 파일/디렉토리"`. `repo_root`는 `pwd`.

### Phase 1: 사전 점검 + 컴포넌트 감지

- `mode=diff`: `git diff --stat <base>...HEAD` → 변경 파일 목록
- `mode=files`: 경로 존재 확인 + 코드 파일(.tsx, .jsx, .ts, .js, .html, .vue, .svelte)만 추림

**UI 컴포넌트 사전 감지 (모든 리뷰어에 힌트로 전달):**
대상 파일을 grep해서 다음 패턴이 있으면 `detected_components` 배열에 추가:

| 패턴 | 컴포넌트 |
|------|---------|
| `<dialog`, `Dialog`, `Modal`, `aria-modal` | `modal` |
| `role="tab"`, `tablist`, `Tabs`, `TabList` | `tab` |
| `<details>`, `<summary>`, `Accordion`, `aria-expanded` | `accordion` |
| `type="radio"`, `role="radio"`, `RadioGroup` | `radio` |
| `type="checkbox"`, `role="checkbox"`, `Checkbox` | `checkbox` |
| `role="switch"`, `Switch`, `Toggle` | `switch` |

리뷰 대상이 50+ 파일이면 사용자 확인.

### Phase 2: 4개 리뷰어 병렬 실행

**한 메시지에 4개 Agent tool 호출을 동시에 보낸다.** 각 호출 프롬프트:

```
당신은 {category}-reviewer 에이전트입니다.

먼저 ~/.agents/agents/{category}-reviewer.md 를 읽어 자신의 역할과 출력 포맷을 확인하세요.
그다음 다음 reference를 순서대로 로드하세요:
1. ~/.agents/skills/a11y-review/references/foundation.md (필수)
2. ~/.agents/skills/a11y-review/references/{category-key}.md (자기 카테고리)
3. detected_components가 비어있지 않으면 ~/.agents/skills/a11y-review/references/ui-elements.md 의 해당 섹션만

입력:
- mode: "{diff|files}"
- target: "{base ref or path list}"
- repo_root: "{absolute path}"
- detected_components: {array}

리뷰 대상 파일 목록 (사전 추출):
{file list}

규칙:
- 자신의 카테고리 결함만 보고. 다른 카테고리는 무시.
- reference의 "리뷰 시그널"과 매칭되는 명확한 안티패턴만 보고.
- 출력은 반드시 단일 JSON 배열(빈 배열 가능). 마크다운 코드블록(```json)으로 감싸기.
- 각 항목은 자신의 에이전트 파일 스키마(category/subitem/severity/file/line/snippet/signal/impact/suggestion)를 따른다.
```

`subagent_type`은 `general-purpose` 사용.

### Phase 3: 결과 머지 & 중복 제거

각 리뷰어로부터 받은 JSON 배열 통합.

**중복 제거:**
- 동일 `file:line`에서 두 카테고리가 다른 관점으로 짚으면 양쪽 보존
- 동일 `file:line` + `signal`이 거의 동일하면 더 critical한 것만 남기고 다른 쪽은 "관련: X" 노트로 흡수
- 의미(§1 이름 부재)와 시각(§1 alt 부재)이 같은 아이콘 버튼을 동시에 짚는 경우는 의미 쪽으로 통합 (alt도 accessible name의 한 종류)

### Phase 4: 보고서 작성

```markdown
# A11y Review

**모드:** diff (main 대비) | files
**대상:** N개 파일
**감지된 컴포넌트:** modal, tab (있을 때만)
**총 발견:** Critical X / Major Y / Minor Z

## Critical
### [file:line] [category — subitem]
**문제:** {snippet}
**시그널:** {signal}
**영향:** {impact}
**제안:** {suggestion}

## Major
...

## Minor
...

## 카테고리별 요약
| 카테고리 | Critical | Major | Minor |
|---------|---------|-------|-------|
| 구조 | ... |

## 다음 단계
- 자동 수정 / 카테고리 상세 / 보고서 저장
```

발견 0건이면: "4개 카테고리 모두 결함 미발견."

### Phase 5: 후속

1. 특정 항목 자동 수정?
2. 특정 카테고리 상세 보기?
3. 보고서 파일 저장? (`~/.agents/_workspace/a11y-review/{slug}/report.md`)

## 단일 카테고리 옵션

`--only structure` / `--only semantic` / `--only predictability` / `--only visual` 으로 한 카테고리만 실행 가능. Phase 3 머지 단계 생략.

## 입력 예시

- `/a11y-review` → diff vs main
- `/a11y-review main src/features/auth/` → 디렉토리
- `/a11y-review --only visual src/icons/` → 시각만

## 코드 품질과의 차이

- **`/code-quality-review`**: 코드 변경·유지보수 관점 (가독성·결합도·응집도·코드 예측 가능성)
- **`/a11y-review`**: 사용자 도달 관점 (키보드·SR·시각 정보 보완)
- 두 스킬은 보완적이며 같은 코드에 모두 적용 가능. PR 단위로 둘 다 실행해도 됨.

## 하지 않는 일

- 코드를 자동 수정하지 않음 (Phase 5에서 사용자 명시 요청 시에만)
- WCAG contrast ratio·동적 ARIA(aria-live 시점) 같은 런타임 검사는 정적 분석 범위 밖 — 정적으로 잡히는 것만
- 4대 기준 외 검사 (성능·SEO·보안)는 다른 스킬 영역
- 50+ 파일 일괄 리뷰는 사용자 확인 후
