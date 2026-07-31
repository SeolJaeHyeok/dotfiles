---
name: obsidian-ingest
description: "`Inbox/` 에 쌓인 raw 노트(세션 archive·웹 클립 등)를 Obsidian Vault 의 LLM Wiki ingest 흐름에 태우는 스킬. Hammerspoon 자동 ingest(핫키→웹 클립)가 하던 일을 Claude Code 세션 안에서 수동·일괄로 수행한다. 동작: Inbox 파일을 읽어 성격별 목적지로 승격 + frontmatter Phase 2 표준 보정 + 관련 MOC 에 `[[wikilink]] — 1줄` 추가(ingest 패스), 반복 참조될 개념이면 canonical wiki 노트 생성/갱신(canonical 패스). **읽기·분류·계획은 먼저 하고, 일괄 계획 표를 1회 승인받은 뒤에만 쓰기를 실행한다.** Inbox 전체 또는 선택한 파일만 처리 가능. (1) '인박스 정리' / 'Inbox ingest' / 'Inbox 비워줘' / '인박스 분류해줘' / 'Inbox 의 노트들 승격' 요청 시, (2) `/obsidian-archive` 로 세션을 Inbox 에 떨군 뒤 그걸 위키에 편입하고 싶을 때, (3) 수동/웹클리퍼로 들어온 Inbox 잔여 노트를 위키 흐름에 올리고 싶을 때 호출. 단순 세션 archive(입구)는 `/obsidian-archive` 를 쓴다."
---

# obsidian-ingest

`~/Documents/Obsidian Vault/Inbox/` 에 raw 로 쌓인 노트를 **LLM Wiki ingest 흐름**에 태워 위키 계층으로 편입한다. `/obsidian-archive` 가 *입구*(세션 → Inbox)라면, 이 스킬은 *처리*(Inbox → 위키)다.

## Purpose

Karpathy LLM Wiki 패턴에서 RAG 함정을 피하는 핵심은 **종합(synthesis)을 query-time 이 아니라 ingest-time 에 한다**는 것. Inbox 에 raw 만 쌓이면 매 질문마다 재발견하는 RAG 로 회귀한다. 이 스킬은 raw 를 받아:

1. **ingest 패스** — 성격별 목적지로 승격 + frontmatter 보정 + 관련 MOC 에 `[[wikilink]] — 1줄 요약` 추가
2. **canonical 패스** — *반복 참조될 개념*이면 canonical wiki 노트를 생성/갱신하고 raw 를 역링크. *단일 아티클 요약으로 충분*하면 만들지 않고 그 판단을 기록.

→ 다음에 같은 주제를 물으면 raw 를 다시 종합하지 않고 *이미 종합된 페이지 하나*를 읽고 답할 수 있게 된다.

## 정전(canonical) 규칙은 Hammerspoon lua 와 공유

ingest/canonical 규칙은 `~/.hammerspoon/modules/obsidian_archive.lua` 의 `buildIngestPrompt` / `buildCanonicalPrompt` 에 이미 존재한다. **이 스킬은 그 규칙을 미러링**해 자동(핫키)·수동(스킬) ingest 동작이 갈라지지 않게 한다. 단 한 군데만 일반화한다:

> **목적지 라우팅.** lua 는 외부 링크 웹 클립만 다뤄 `Reference/` 로 승격이 하드코딩돼 있다. 이 스킬은 Inbox 에 섞인 모든 성격(`개발`·`회의`·`학습`·`대화`·`외부 링크`)을 다루므로 노트 성격으로 목적지를 분기한다.

## When to Use

호출:
- "인박스 정리" / "Inbox ingest" / "Inbox 비워줘" / "인박스 분류해줘" / "Inbox 노트들 위키로 승격"
- `/obsidian-archive` 로 세션을 Inbox 에 떨군 뒤 그걸 위키에 편입할 때
- 수동/Web Clipper/다른 경로로 들어와 Inbox 에 남은 잔여 노트를 위키 흐름에 올릴 때

호출하지 않음:
- *세션 대화를 Inbox 에 떨구는 것 자체* — 그건 입구인 `/obsidian-archive`
- Inbox 밖(이미 `개발 기록/`·`Reference/` 에 있는) 노트 재정리 — 그건 일반 편집/lint
- 사용자가 "그냥 두자" / "분류 안 해도 돼" 라고 한 경우

## 목적지 라우팅 (성격 → 위치 + type + MOC)

각 Inbox 노트의 frontmatter `source` 와 본문 성격으로 분기한다. `source` 가 없으면 본문으로 추론.

| 노트 성격 (`source`) | 목적지 폴더 | frontmatter `type` | 연결 MOC |
|---|---|---|---|
| 외부 링크 | `Reference/{AI · FE · Claude와 Codex · 생산성 도구 · 기타}` | `reference` | `MOC - Reference *` |
| 개발 (트러블슈팅·패턴·결정) | `개발 기록/{React · DevOps · 브라우저 · TypeScript · 백엔드 · AI · Git · 모바일 · 프로젝트}` | `wiki` | `MOC - 개발 기록` |
| 회의 | `업무/회의록/` | `meeting` | (없음) |
| 학습 · 대화 (Claude 세션) | 내용 기반 — 개발 패턴이면 `개발 기록/`, AI·도구 지식이면 `Reference/AI` 또는 `Reference/Claude와 Codex` | `wiki` 또는 `reference` | 해당 MOC |

라우팅 판단 규칙:
- **하위 폴더가 애매하면** 가장 가까운 기존 하위 폴더를 고르고, 정말 없으면 새 하위 폴더를 *계획 표에 제안*한 뒤 승인받는다.
- **목적지 MOC 가 없으면** MOC 를 새로 만들지 말고 *이동만* 수행한다(lua 규칙과 동일).
- **회의록 라우팅은 드물다** — Inbox 의 대부분은 외부 링크/개발/학습이다. `회의` 는 명확히 회의 노트일 때만.

## 절대 금지 (vault CLAUDE.md 계약)

- `.obsidian/`, `회사/`, `업무/configuration/` — 읽기·쓰기·검색 전부 금지
- `업무/개발/AI Prompts/` — 수정 금지
- **승인 전 어떤 파일도 이동·편집·생성하지 않는다.** 읽기·검색·분류는 자유, 쓰기는 1회 일괄 승인 게이트 이후에만.
- 대상 파일 외 파일 삭제·이동·이름 변경·대규모 재작성 금지
- 깨진 `[[wikilink]]` 생성 금지 — 존재하는 노트만

---

## Phase 0: 범위 결정 (전체 vs 선택)

먼저 `Inbox/*.md` 를 나열한다(`회사/` 등 금지 경로는 애초에 Inbox 밖이라 무관). 그 다음 범위를 받는다:

- 인자 없이 호출 → Inbox 목록을 보여주고 **전체 / 선택** 을 블로킹 질문으로 받음
- "전체" / "all" → Inbox 의 모든 `.md`
- 특정 파일명/번호 지정 → 그 파일들만

> Inbox 가 비어 있으면 "Inbox 가 비어 있습니다 — ingest 할 노트가 없습니다" 로 종료.

## Phase 1: 읽기 · 분류 · canonical 사전 평가 (읽기 전용)

승인 전, 대상 각 파일에 대해 **쓰기 없이** 다음을 수행:

1. 파일을 읽어 `source`/내용 파악 → 목적지 라우팅 표로 목적지 폴더·`type`·연결 MOC 결정
2. **유사 노트 검색**(Grep/Glob) — 목적지 폴더와 MOC 에 이미 관련 노트가 있는지
3. **canonical 사전 판단** — 이 자료가 *반복 참조될 개념*인가, 아니면 *단일 아티클 요약으로 충분*한가
   - 같은 개념의 노트가 이미 있으면 → "기존 canonical 노트 X 에 보강"
   - 반복 개념인데 노트 없으면 → "신규 canonical 노트 1개 생성"
   - 단발성이면 → "canonical 생성 안 함(단일 아티클)"

이 단계 산출물은 다음 Phase 의 *계획 표* 한 줄씩이다.

## Phase 2: 일괄 계획 표 → 1회 승인 (블로킹 게이트)

대상 전체에 대한 계획을 **표 하나**로 제시한다:

```
[ingest 계획 — N개 파일]
| # | 파일 | → 목적지 | frontmatter | MOC 갱신 | canonical |
|---|------|---------|-------------|----------|-----------|
| 1 | Boris Cherny… (2026-06-16) | Reference/AI/ | type:reference, status:active | MOC-Reference AI +1줄 | 단일 아티클(생성 안 함) |
| 2 | next-env.d.ts… (2026-06-22) | 개발 기록/React/ | type:wiki, status:active | MOC-개발 기록 +1줄 | 기존 'Next.js 타입 생성' 보강 |
| 3 | … | … | … | … | 신규 'AI 에이전트 워크플로' 생성 |
```

그 다음 **블로킹 질문**(`AskUserQuestion`, 옵션: `전체 승인` / `일부만 — 번호 지정` / `수정` / `취소`)으로 승인을 받는다. 

> Cursor/Codex 등 다른 플랫폼이면 평문 표 + 번호 옵션 + 응답 대기. **어떤 플랫폼이든 응답 없이 쓰기를 시작하지 않는다.**

## Phase 3: 실행 (승인된 파일마다 순차)

승인된 각 파일에 대해, lua 규칙을 미러링해 수행:

**ingest 패스**
1. 대상 파일을 목적지 폴더로 **이동**(`Bash mv` 또는 Write+삭제가 아닌 mv 권장 — 한 파일만)
2. frontmatter 를 Phase 2 표준으로 보정: `created`(보존)·`source`(보존)·`topic`(목적지에 맞게)·`type`(라우팅 표)·`status: active`. 기존 `url`·`archived` 등 메타는 보존.
3. raw 본문은 **보존** — 과도하게 재작성하지 않는다.
4. 연결 MOC 가 있으면 그 **MOC 하나에만** `[[노트 제목]] — 1줄 요약` 형식으로 *append*(기존 항목 건드리지 않음). MOC 가 없으면 이동만.

**canonical 패스** (Phase 1 판단대로)
5. *반복 개념* → 기존 canonical wiki 노트를 보강하거나 신규 1개 생성. 생성/갱신 시 **raw/reference 노트 역링크 필수**(`[[방금 이동한 노트]]`).
6. canonical 노트가 생기면 관련 MOC 에 canonical 링크도 추가/보강.
7. *단일 아티클* → canonical 만들지 않고 그 판단을 최종 보고에 적는다.

> 최종 상태에서 대상 파일이 `Inbox/` 에 남아 있으면 그 파일은 ingest 실패로 간주하고 보고에 명시.

## Phase 4: 보고

표 하나로 결과 요약:
- 이동한 파일: `Inbox/X → 목적지/X`
- 보정한 frontmatter
- 갱신한 MOC (파일명 + 추가한 줄)
- canonical 결정 (생성/보강/생략 + 노트 경로)
- 실패/보류 항목 (있으면 사유)

---

## Core Principles

1. **읽기 먼저, 쓰기는 1회 승인 후** — Phase 1 분류·검색·canonical 판단은 자유, 모든 쓰기는 Phase 2 일괄 승인 게이트 이후.
2. **lua 규칙 미러링** — 자동(핫키)·수동(스킬) ingest 가 같은 결과를 내게. 목적지 라우팅만 일반화.
3. **raw 보존** — 원본성 우선, 과도한 재작성 금지(vault CLAUDE.md §5).
4. **MOC 는 append-only 한 줄** — 기존 항목 수정·재배열 금지. 없는 MOC 만들지 않음.
5. **canonical 은 절제** — 반복 개념일 때만 종합 노트. 단발성은 만들지 말고 판단만 기록(= rule "패턴이 굳을 때까지 추출 안 함").
6. **깨진 wikilink 금지** — `[[...]]` 는 존재하는 노트만(이동 후 실제 경로 기준).
7. **금지 경로 불가침** — `.obsidian/`·`회사/`·`업무/configuration/`·`업무/개발/AI Prompts/`.

## Examples

### Good — 선택 ingest, canonical 보강
**입력**: "Inbox 에서 next-env.d.ts 노트만 ingest 해줘"
- Phase 1: `source: 개발` → `개발 기록/React/`, `type: wiki`, MOC-개발 기록 연결. 유사 검색 → 기존 'Next.js 타입 생성' 개념 노트 있음 → canonical=보강.
- Phase 2: 계획 표 1줄 제시 → 승인.
- Phase 3: 이동 + frontmatter 보정 + MOC +1줄 + 기존 개념 노트에 역링크 보강.
- Phase 4: 결과 표 보고.

왜 좋은가: 단일 파일도 동일 게이트를 거치고, canonical 을 신규 생성이 아니라 *기존 노트 보강*으로 처리해 중복을 막음.

### Good — 전체 ingest, 혼합 성격
**입력**: "인박스 전체 정리해줘"
- Phase 1: 4개 파일 각각 분류 — 외부 링크 3개 → Reference/AI, 개발 1개 → 개발 기록/React.
- Phase 2: 4줄 계획 표 → `전체 승인`.
- Phase 3: 순차 처리, 각 목적지·MOC 별 반영.
- Phase 4: "4개 중 4개 이동 완료, MOC 2종 갱신, canonical 1개 생성/2개 생략" 보고.

왜 좋은가: 전체 모드에서 파일별로 묻지 않고 표 1회 승인으로 일괄 처리(효율) + 성격별 라우팅 분기(정확).

### Bad — 승인 없이 이동
**잘못**: Inbox 읽고 바로 `mv` 실행.
**올바름**: Phase 1(읽기 전용) → Phase 2 계획 표 + 블로킹 승인 → 그 다음에만 쓰기.

### Bad — 없는 MOC 생성 / 단발성 canonical 남발
**잘못**: 목적지 MOC 가 없는데 새 MOC 를 만들거나, 단일 아티클인데 canonical 개념 노트를 생성.
**올바름**: MOC 없으면 이동만. canonical 은 반복 개념일 때만 — 단발성은 판단만 기록.

## Final Checklist

실행 직후:
- [ ] Phase 2 일괄 승인을 받은 뒤에만 쓰기를 했는가
- [ ] 각 파일이 성격(`source`)에 맞는 목적지로 갔는가
- [ ] frontmatter 가 Phase 2 표준(`type`·`status: active`)으로 보정되고 기존 메타는 보존됐는가
- [ ] MOC 갱신이 *append-only 한 줄*인가, 없는 MOC 를 만들지 않았는가
- [ ] canonical 생성/갱신 시 raw 역링크가 들어갔는가, 단발성은 생략 판단을 기록했는가
- [ ] 대상 파일이 Inbox 에 남지 않았는가(남았으면 실패 보고)
- [ ] `[[wikilink]]` 가 모두 존재하는 노트를 가리키는가
- [ ] 금지 경로를 건드리지 않았는가

## Related Skills

- `/obsidian-archive` — 입구. 세션 대화/학습을 Inbox 로 떨군다. 이 스킬은 그 출구(Inbox → 위키).
- `/find-wiki` — 위키 질의. ingest 로 정제된 위키를 1차 소스로 검색.
- Hammerspoon `obsidian_archive.lua` — 핫키 기반 자동 ingest. 이 스킬과 *동일 규칙*을 공유(수동판).

## Why This Exists

Hammerspoon 자동 ingest 는 *브라우저 핫키* 로 들어온 웹 클립만 큐에 태운다. 하지만 `/obsidian-archive` 로 떨군 세션 노트나 수동/Web Clipper 로 들어온 노트는 Inbox 에 raw 로 남아 위키에 편입되지 않는다 — 그대로 두면 RAG 함정(매 질문마다 raw 재종합)으로 회귀한다. 이 스킬은 *세션 안에서 사람이 직접* 그 잔여 raw 를 위키 흐름에 태워, 자동·수동 두 경로 모두 같은 ingest 규칙으로 수렴하게 한다.
