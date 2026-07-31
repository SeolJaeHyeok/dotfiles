---
name: code-quality-review
description: "Frontend Fundamentals 4대 코드 품질 기준(가독성·예측가능성·응집도·결합도)으로 코드를 리뷰하는 오케스트레이터. 4개 전문 리뷰어 에이전트를 병렬 실행해 결과를 머지·중복 제거하고 심각도순으로 정리한다. git diff(브랜치/커밋 비교)와 파일/디렉토리 직접 지정 두 입력 모드를 모두 지원한다. 다음 상황에서 사용: '/code-quality-review', 'FF 기준으로 리뷰', '가독성·결합도 검토', PR 또는 변경사항 코드 품질 점검, 특정 파일/디렉토리 코드 품질 점검."
---

# Code Quality Review Orchestrator

Frontend Fundamentals(Toss) 4대 코드 품질 기준으로 코드를 리뷰한다. 4개 전문 리뷰어를 병렬 실행하고 결과를 통합한다.

## 카테고리와 에이전트

| 카테고리 | 에이전트 | 레퍼런스 |
|---------|----------|---------|
| 가독성 (Readability) | `readability-reviewer` | `references/readability.md` |
| 예측 가능성 (Predictability) | `predictability-reviewer` | `references/predictability.md` |
| 응집도 (Cohesion) | `cohesion-reviewer` | `references/cohesion.md` |
| 결합도 (Coupling) | `coupling-reviewer` | `references/coupling.md` |

## 워크플로우

### Phase 0: 입력 모드 결정

사용자 인풋에서 다음을 추출한다:

| 모드 | 트리거 | `target` |
|------|--------|---------|
| `diff` | "PR 리뷰", "main 대비", "이번 변경", "브랜치", base ref 명시 | base ref (기본값 `main`) |
| `files` | 절대/상대 경로, 디렉토리, "이 파일", 파일명 명시 | 경로 목록 |

둘 다 모호하면 사용자에게 1개 질문: `"어떤 단위로 리뷰할까요? (1) main 대비 변경분 (2) 특정 파일/디렉토리 — 경로를 알려주세요"`.

`repo_root`는 현재 작업 디렉토리(`pwd`)로 설정. git 저장소가 아닌데 `diff` 모드가 요청되면 사용자에게 `files` 모드를 제안.

### Phase 1: 사전 점검

- `mode=diff`: `git diff --stat <base>...HEAD` 로 변경 파일 목록을 먼저 확인. 0개면 "변경사항 없음"으로 종료.
- `mode=files`: 경로 존재 확인. 코드 파일(.ts, .tsx, .js, .jsx 등)만 추린다. 0개면 사용자에게 다시 물음.

리뷰 대상 파일이 50개를 넘으면 사용자에게 확인: "50개 초과인데 진행할까요?"

### Phase 2: 4개 리뷰어 병렬 실행

**한 메시지에 4개 Agent tool 호출을 동시에 보낸다** (병렬). 각 호출에 다음 프롬프트를 전달:

```
당신은 {category}-reviewer 에이전트입니다.

먼저 ~/.agents/agents/{category}-reviewer.md 를 읽어 자신의 역할과 출력 포맷을 확인하세요.
그다음 ~/.agents/skills/code-quality-review/references/{category}.md 를 읽어 패턴 레퍼런스를 로드하세요.

입력:
- mode: "{diff|files}"
- target: "{base ref or path list}"
- repo_root: "{absolute path}"

리뷰 대상 파일 목록 (사전 추출):
{file list}

규칙:
- 자신의 카테고리 결함만 보고. 다른 카테고리는 무시.
- reference의 "리뷰 시그널"과 매칭되는 명확한 안티패턴만 보고.
- 출력은 반드시 단일 JSON 배열(빈 배열 가능). 마크다운 코드블록(```json) 으로 감싸기.
- 각 항목은 자신의 에이전트 파일이 정의한 스키마를 따른다.
```

`subagent_type`은 `general-purpose` 사용 (Claude Code 기본 — 별도 등록된 sub-agent를 쓰면 거기에 맞춰 변경).

### Phase 3: 결과 머지 & 중복 제거

각 리뷰어로부터 받은 JSON 배열을 합친다. 중복 제거 규칙:
- 동일 `file:line` 에서 두 카테고리가 같은 코드를 짚으면 **양쪽 모두 보존** (서로 다른 관점). 단, `signal` 텍스트가 거의 동일하면 더 본질적인(더 critical) 한 쪽만 남기고 다른 쪽은 "관련 카테고리: X" 노트로 흡수.
- 가독성 §5와 응집도 §2 (매직 넘버)는 의도적 겹침 — 둘 다 다른 관점이면 보존.

### Phase 4: 보고서 작성

마크다운으로 출력. 구조:

```markdown
# Code Quality Review

**모드:** diff (main 대비) | files
**대상:** N개 파일
**총 발견:** Critical X / Major Y / Minor Z

## Critical
### [file:line] [category — subitem]
**문제:** {snippet}
**시그널:** {signal}
**제안:** {suggestion}

## Major
...

## Minor
...

## 카테고리별 요약
| 카테고리 | Critical | Major | Minor |
|---------|---------|-------|-------|
| 가독성 | ... |

## 다음 단계
- (사용자 선택) 자동 수정 진행 / 특정 항목만 수정 / 보고만
```

발견이 0건이면 짧게: "4개 카테고리 모두 결함 미발견."

### Phase 5: 후속

사용자에게 묻는다:
1. 특정 항목 자동 수정해줄까요? (항목 번호로 지정)
2. 특정 카테고리 결과만 자세히 볼까요?
3. 보고서를 파일로 저장할까요? (`~/.agents/_workspace/code-quality-review/{slug}/report.md`)

## 단일 카테고리만 실행 (옵션)

사용자가 "가독성만 봐줘" 같이 카테고리를 한정하면 해당 리뷰어 1개만 호출하고 Phase 3 머지 단계 생략.

## 입력 예시

- `/code-quality-review` → diff vs main 기본
- `/code-quality-review main` → diff vs main 명시
- `/code-quality-review src/features/order/` → 디렉토리
- `/code-quality-review src/hooks/usePageState.ts` → 단일 파일
- `/code-quality-review --only readability src/` → 가독성만

## 하지 않는 일

- 코드를 자동 수정하지 않음 (Phase 5에서 사용자가 명시 요청 시에만)
- 4대 기준 외(성능·보안·테스트 커버리지)는 보고하지 않음 — 다른 스킬의 영역
- 50+ 파일 일괄 리뷰는 사용자 확인 후에만
