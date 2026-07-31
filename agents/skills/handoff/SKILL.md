---
name: handoff
description: "세션 간 의사결정 영속화 스킬. 현재 세션의 목표·진행·실패 가설·다음 단계를 host별 HANDOFF.md로 직렬화해 다음 세션이 파일 하나만 읽고 바로 재개할 수 있게 한다. /feature-dev·/bug-fix 체크포인트 및 Stop hook 리마인더가 공용으로 호출한다."
---

# Handoff

세션 간 컨텍스트·의사결정을 파일로 영속화하는 dispatcher.

> "Git이 코드에 했던 일을, handoff 문서 체계가 의사결정에 대해 한다."
> Context rot / auto-compact 비대칭성 / context amnesia를 동시에 해결한다.

## 진행 상황 출력 규칙

파일을 읽거나 작업을 시작하기 전에 한 줄로 현재 상태를 출력한다.

```
> [handoff] 워크플로우 로딩 중...
> [handoff] host 판단 중...
> [handoff] 현재 세션 상태 수집 중...
> [handoff] 초안 작성 중...
```

## 먼저 읽을 파일

스킬 시작 시 위 첫 줄을 출력한 뒤 아래 파일을 읽는다.

1. 항상 `references/common.md`
2. 현재 host에 맞는 adapter 하나만:
   - Claude: `references/claude.md`
   - Codex: `references/codex.md`
   - Gemini: `references/gemini.md`

다른 host adapter는 읽지 않는다.

## Host 판단 규칙

현재 host의 전역 규칙 파일에 있는 `Host Metadata`의 `host_id`를 기준으로 판단한다.

- Claude: `~/.agents/rules/claude/CLAUDE.md`
- Codex: `~/.agents/rules/codex/AGENTS.md`
- Gemini: `~/.agents/rules/gemini/GEMINI.md`

metadata가 없으면 기본값 `claude`로 처리하고, 판단 불가능하면 사용자에게 묻는다.

## 입력 모드

| 인자 | 동작 |
|---|---|
| `/handoff` | **create 모드** — 새 HANDOFF.md 생성 (현재 세션 자동 분석) |
| `/handoff <slug>` | create 모드 + 작업 슬러그 지정 (예: `/handoff add-auth`) |
| `/handoff update` | **update 모드** — 가장 최근 HANDOFF.md 갱신 (Progress 추가, Failed 누적) |
| `/handoff update <path>` | update 모드 + 경로 지정 |
| `/handoff checkpoint <phase>` | **워크플로우 내부 호출** — /feature-dev·/bug-fix 체크포인트에서 호출되는 경량 모드. AskUserQuestion 포함. |

## 실행 원칙

1. **Preflight 먼저 묻는다.** 정말 handoff가 필요한 상황인지 판단한다 (`references/common.md`의 Preflight Checklist 참조).
2. **파일 경로는 host adapter가 결정한다.** 공통 문서가 경로 규칙을 정의하지 않는다.
3. **초안은 자동 작성하되, 저장 전 반드시 사용자 확인을 받는다.** 단 checkpoint 모드에서는 AskUserQuestion으로 승인.
4. **기존 HANDOFF.md를 발견하면 덮어쓰지 않는다.** update할지 새로 만들지 사용자에게 묻는다.
5. **저장 후 세션 종료 안내까지 한다.** `/clear` → 새 세션 부팅 프롬프트 복사 가능한 형태로 제시.

## 작성 5대 원칙 (요약 — 상세는 common.md)

1. **Open Work는 상태 서술형.** 명령형 금지 ("Implement retry" ❌ → "Retry logic is not yet implemented; depends on backoff util" ✅)
2. **파일 참조는 라인 범위 포함.** `src/auth/TokenService.kt:L45-L72 — race condition 의심`
3. **CLAUDE.md 중복 차단.** "Read CLAUDE.md first. Do NOT restate anything already covered there"를 새 세션 프롬프트에 포함.
4. **2,000 토큰 상한.** 초과분은 `~/.agents/handoffs/{host}/{project}/{date}-{slug}/reports/` 하위 파일로 분리.
5. **"Traps to Avoid"가 가장 가치 있다.** 성공은 코드에 남지만 실패한 접근과 그 이유는 handoff 외엔 소실된다. 이 섹션을 비우지 않는다.

## Gotchas

**하지 말아야 할 것:**

- **자동 compact로 대체 가능하다고 단정하지 않는다.** auto-compact는 모델이 가장 덜 똑똑해진 순간에 발동해 정작 필요한 맥락을 잘라낸다. Document & Clear가 더 안전하다.
- **Handoff를 "사실"로 쓰지 않는다.** 이전 세션의 가설·혼동을 그대로 사실처럼 서술하면 다음 세션이 그대로 이어받는다. 불확실한 부분은 "가정" 또는 "의심" 표지를 남긴다.
- **Prompt for New Chat에 "Read로 검증"을 빠뜨리지 않는다.** 파일 참조만 나열하고 검증 지시가 없으면 새 세션이 문서 주장을 맹목적으로 따른다.
- **Open Work를 명령형으로 쓰지 않는다.** "Do X next"는 새 세션의 판단 공간을 없앤다.
- **Failed/Traps 섹션을 비워두지 않는다.** 실패가 없는 세션은 거의 없다. 누락이 아니라 탐색 부족이다.
- **기존 HANDOFF.md를 조용히 덮어쓰지 않는다.** update 모드 명시 후 기존 내용 유지하며 섹션별 누적.
- **/feature-dev·/bug-fix 내부 호출 시 공통 Step을 임의로 건너뛰지 않는다.** checkpoint 모드라도 5대 원칙은 동일하게 강제한다.
- **CLAUDE.md에 이미 있는 규약을 재서술하지 않는다.** 중복 토큰 낭비 + 두 문서가 어긋나면 혼란의 원인이 된다.
