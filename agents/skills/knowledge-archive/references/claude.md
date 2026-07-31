# Knowledge Archive Claude Adapter

이 adapter는 feature-dev Step 5·bug-fix Phase 5 dispatcher에서 호출된다. 역할은 다음과 같다:

1. 상위 워크플로우가 쌓아둔 산출물(SPEC/Plan/Blueprint/Contract/Review artifact)을 구조화된 컨텍스트 블록으로 정리
2. Stage 0 Quality Gate 통과 여부 판단
3. `/ce:compound` 에 그 블록을 주입해 팀 지식(`docs/solutions/`)을 생성
4. 결과 경로를 개인 하네스 크로스-프로젝트 색인(`~/.agents/knowledge/index.md`)에 한 줄 기록
5. 패턴·경고를 harness에 반영할지 판단해 필요 시 `/harness-improve` 호출

`/ce:compound` 본문은 절대 수정하지 않는다. 플러그인 업데이트로 사라진다.

---

## Stage 0: 인자 파싱

dispatcher 호출 예:

```
/knowledge-archive feature:add-auth \
  spec:docs/specs/add-auth.md \
  plan:docs/plans/add-auth.md \
  exploration:docs/explorations/add-auth.md \
  blueprint:docs/blueprints/add-auth.md \
  contract:docs/contracts/add-auth.md \
  review_artifact:.context/compound-engineering/ce-review/<run-id>/
```

아래 토큰을 파싱한다 (모두 선택, 본문도 같이 받는다):

| 토큰 | 의미 | 없을 때 |
|---|---|---|
| `feature:<slug>` | 기능/버그 슬러그 | conversation에서 추론, 실패 시 사용자에게 질문 |
| `spec:<path>` | SPEC 문서 경로 | — |
| `plan:<path>` | Plan 문서 경로 | — |
| `exploration:<path>` | code-explorer 산출물 | — |
| `blueprint:<path>` | code-architect 산출물 | — |
| `contract:<path>` | contract-reviewer 산출물 | — |
| `review_artifact:<path>` | ce:review run 디렉토리 | — |

토큰이 하나도 없고 사용자가 "기억해줘"·"아카이빙해줘"로 직접 호출한 경우 → **ad-hoc 모드**: conversation history에서 직접 추출한다.

---

## Stage 1: Quality Gate

`common.md`의 3가지 질문을 모두 통과할 때만 이후 단계로 진행한다.

| 질문 | "예"면 |
|---|---|
| 5분 구글링으로 찾을 수 있는가? | **skip** |
| 이 코드베이스·프로젝트에 한정된 내용이 아닌가? | **skip** |
| 실제 디버깅·분석 노력 없이 알 수 있었던 내용인가? | **skip** |

Skip 판정 시 사용자에게 한 줄 보고 후 종료:

```
⏭ 아카이빙 skip — 이유: <질문 번호와 간단한 판정 근거>
```

---

## Stage 2: 구조화 블록 생성

제공된 아티팩트 파일을 읽고 conversation을 결합해 아래 블록을 **그대로** 만든다. 이 블록은 다음 Stage에서 `/ce:compound` 프롬프트 본문으로 주입된다.

```text
## Feature/Bug Summary
- slug: <feature-slug>
- project: <basename(git rev-parse --show-toplevel) 또는 "harness">
- date: <오늘 YYYY-MM-DD>
- track-hint: <bug | knowledge | feature>   # ce:compound가 최종 결정

## Artifacts
- SPEC: <path 또는 "n/a">
- Plan: <path 또는 "n/a">
- Exploration: <path 또는 "n/a">
- Blueprint: <path 또는 "n/a">
- Contract: <path 또는 "n/a">
- Review artifact: <path 또는 "n/a">

## 결정 (Decisions)
- <선택한 접근법과 이유 — Plan/Brainstorm에서 발췌한 1~3개>

## 발견 (Discoveries)
- <예상과 달랐던 것>

## 실수 (Mistakes)
- <잘못 판단한 부분과 원인>

## 패턴 (Reusable Patterns)
- <재사용 가능한 사고방식·원칙 — 코드 스니펫 아님>

## 경고 (Warnings for future self)
- <다음에 이 영역을 건드릴 때 반드시 알아야 할 것>
```

항목이 비면 `- (none)` 로 명시. 억지로 채우지 않는다.

---

## Stage 3: `/ce:compound` 호출

Stage 2 블록을 프롬프트 본문으로 넘겨 `/ce:compound` 를 호출한다.

호출 형태:

```
/ce:compound <slug 한 줄 요약>

<Stage 2 블록 전체>
```

- 블록 상단에 별도 "auto memory" 주석은 붙이지 않는다. `/ce:compound` Phase 0.5가 자체 auto memory scan을 수행하므로 이중 스캔을 유발하지 않기 위함이다.
- `/ce:compound` Phase 1 subagents(Context Analyzer·Solution Extractor·Related Docs Finder)가 이 블록을 권위 있는 컨텍스트로 사용하도록 블록 도입부에 한 줄을 더한다: `Primary context for this compound: the following block was assembled by knowledge-archive dispatcher from verified artifacts.`

---

## Stage 4: 결과 경로 캡처

`/ce:compound` 출력에서 다음을 추출한다:

| 추출 대상 | 파싱 규칙 |
|---|---|
| 성공 여부 | 출력에 `✓ Documentation complete` 또는 `✓ Documentation updated` 존재 |
| 결과 파일 경로 | `File created:` 또는 `File updated:` 라인 다음의 경로 |
| Track | 출력의 YAML frontmatter 또는 섹션 구성에서 유추 (bug/knowledge) |
| Category | 경로의 `docs/solutions/<category>/` 부분 |

추출 실패 또는 성공 신호 없음 → **Stage F (Fallback)** 로.

---

## Stage 5: 크로스-프로젝트 색인 추가

`~/.agents/knowledge/index.md` 에 한 줄을 append한다.

최초 호출 시 파일이 없으면 아래 헤더와 함께 생성:

```markdown
# Cross-Project Knowledge Index

host별 개인 하네스 차원에서 생성된 모든 지식 아카이브의 크로스-프로젝트 색인.
프로젝트 내부 `docs/solutions/`(팀 지식)과 중복되지만, 여기서는 프로젝트를 넘나드는 검색용으로 유지한다.

| Date | Project | Slug | Track | Category | Path |
|---|---|---|---|---|---|
```

각 엔트리 포맷 (절대 경로 필수 — 이동·삭제 추적을 위해):

```markdown
| 2026-04-23 | my-app | add-auth | bug | runtime-errors | /Users/seoljaehyeok/work/my-app/docs/solutions/runtime-errors/add-auth-2026-04-23.md |
```

- **Date**: Stage 2의 `date`
- **Project**: Stage 2의 `project`
- **Slug**: Stage 2의 `slug`
- **Track**: Stage 4에서 캡처한 track
- **Category**: Stage 4에서 캡처한 category
- **Path**: Stage 4 결과 파일의 **절대 경로**

색인 append 실패는 치명적이지 않다 — 에러를 한 줄로 사용자에게 보고하고 다음 Stage로 진행한다.

---

## Stage 6: Harness 반영 여부

Stage 2의 `패턴`·`경고` 항목이 아래 중 하나라도 해당하면 `/harness-improve` 를 즉시 호출한다:

- 규칙(`~/.agents/rules/claude/CLAUDE.md` 또는 하위 파일) 추가·수정이 필요한 패턴
- 새 스킬 또는 기존 스킬 수정이 필요한 반복 작업
- 팀 구성(`~/.claude/teams/*/config.json`)의 멤버·role 프롬프트 수정이 필요한 반복 실패 패턴

해당 없으면 호출하지 않는다. 이미 상위 세션 마무리 루틴에서 `/harness-improve`가 실행되므로, 여기서는 "즉시 반영이 필요한 명확한 신호가 있을 때만" 호출한다.

---

## Stage 7: 완료 선언

```markdown
✅ 지식 아카이빙 완료

- ce:compound 결과: <경로> (track: <bug|knowledge>, category: <카테고리>)
- 크로스-프로젝트 색인: `~/.agents/knowledge/index.md` 1줄 추가
- Harness 반영: <있음 → /harness-improve 호출 / 없음>
```

---

## Stage F: Fallback (`/ce:compound` 실패 시)

`/ce:compound` 호출 실패·타임아웃·결과 파싱 실패 중 하나라도 발생하면:

1. `~/.agents/knowledge/<YYYY-MM-DD>-<slug>.md` 파일을 생성. 포맷은 `common.md` Stage 2 저장 포맷을 그대로 사용 (결정/발견/실수/다음번엔).
2. Stage 5 색인에는 이 파일 경로를 추가하되 `Category` 필드는 `fallback` 으로 기록.
3. 사용자에게 명시적으로 보고:
   ```
   ⚠ ce:compound 실패 — fallback으로 ~/.agents/knowledge/<file> 에 저장
   실패 이유: <reason>
   ```
4. Stage 6 harness 반영 체크는 그대로 실행.
5. fallback 저장조차 실패하면 세션을 "완료"로 선언하지 않고 사용자에게 전체 블록을 콘솔 출력해 수동 저장을 안내.

---

## Auto-Invoke 충돌 방지

`/ce:compound` 의 Auto-Invoke trigger("that worked"·"it's fixed"·"working now"·"problem solved") 가 feature-dev/bug-fix 중간에 발동하면 이 dispatcher 경로가 우회된다. 전역 규칙(`~/.claude/CLAUDE.md` Rule 10)이 이를 차단하며, 이 adapter는 우회 호출을 감지하면 중단하고 사용자에게 dispatcher 경유를 요구한다.
