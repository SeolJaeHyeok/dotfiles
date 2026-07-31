# Harness Improve Common Flow

## 언제 실행하나

- session-wrap 마무리 단계 (자동)
- 사용자가 명시적으로 harness 개선을 요청했을 때
- 반복 지시, 수정 요구, 불필요한 마찰이 감지됐을 때
- **새 모델 출시 / 모델 업그레이드 직후** — 기존 구조가 여전히 필요한지 검토

## Self-Improving Loop

4단계를 순서대로 실행한다: **Collect → Analyze → Propose → Verify**

---

## Phase 1: Collect (신호 수집)

이번 대화를 분석해 아래 5가지 신호를 추출하고 `~/.agents/signals/log.jsonl`에 append한다.

### 신호 유형

| type | 탐지 기준 | 예시 |
|---|---|---|
| `correction` | "하지 마", "그러지 마", "이렇게 바꿔줘" | "null check 대신 optional chaining 써줘" |
| `approval` | "맞아", "좋아", 비자명한 결정 승인 | "이 접근법이 좋다" |
| `friction` | 같은 지시 반복, 규칙 미준수 재지시 | zustand 패턴을 매 세션 재설명 |
| `slop` | hook이 자동 기록 (수동 추출 불필요) | — |
| `scope-warning` | hook이 자동 기록 (수동 추출 불필요) | — |

### 추출 규칙

- `slop`과 `scope-warning`은 hook이 이미 기록하므로 **대화에서 추출하지 않는다**.
- `correction`, `approval`, `friction`만 대화에서 추출한다.
- 피드백이 없으면 그 사실을 보고하고 Phase 2로 넘어간다 (Analyze는 과거 누적 신호도 분석하므로 항상 실행).

### 기록 형식

```json
{"ts":"2026-04-06T14:30:00","session":"abc","type":"correction","source":"user","detail":"null check 대신 optional chaining 사용","file":"src/auth.ts","skill":"bug-fix","phase":"phase-3"}
```

선택 필드 (`file`, `skill`, `phase`)는 파악 가능한 경우에만 기록한다.

---

## Phase 2: Analyze (패턴 탐지)

`~/.agents/signals/log.jsonl`을 읽고 패턴을 탐지한다.

### 절차

1. 최근 **14일** 이내 신호만 필터링
2. `(type, detail 키워드)` 쌍으로 그루핑 — detail이 정확히 같지 않아도 의미적으로 동일하면 묶는다
3. 임계값 초과 여부 판정

### 임계값

| type | 후보 승격 기준 | 근거 |
|---|---|---|
| `correction` | **2회** | 사용자가 같은 걸 2번 말하면 규칙화 |
| `approval` | **2회** | 검증된 접근법은 빨리 규칙화 |
| `friction` | **3회** | 환경 차이 가능성 고려 |
| `scope-warning` | **3회** | 워크플로우 범위 문제 확인 |
| `slop` | **5회** | 프로젝트별 차이 고려, 충분한 샘플 필요 |

### 제외 조건

- `~/.agents/signals/changes.jsonl`에서 `status: "dismissed"`인 패턴과 동일하면 제외
- 이미 `status: "applied"` 또는 `"validated"`인 패턴과 동일하면 제외

### 출력

```markdown
## 패턴 분석 결과

| 패턴 | 유형 | 발생 횟수 | 최근 발생 | 제안 유형 |
|------|------|----------|----------|----------|
| "optional chaining 우선" | correction | 3회 | 2026-04-05 | 규칙 추가 |
| "zustand store 반복 설명" | friction | 3회 | 2026-04-04 | knowledge 연결 |

임계값 미달: scope-warning 1회 (3회 필요)
```

임계값을 초과한 패턴이 없으면 "개선 후보 없음"을 보고하고 Phase 4(Verify)로 건너뛴다.

---

## Phase 3: Propose (개선 제안)

### 제안 유형 라우팅

| 패턴 성격 | 대상 |
|-----------|------|
| host 전반 행동 방식 | `~/.agents/rules/{host}/...` |
| 모든 host에 공통인 워크플로우 의미 | 해당 스킬의 `SKILL.md` 또는 `references/common.md` |
| 특정 host에서만 필요한 실행 방식 | 해당 스킬의 `references/{host}.md` |
| 기존 knowledge 활용 부족 | 스킬에 knowledge 참조 연결 |
| 반복되는 코드 품질 문제 | hook 수정 또는 `ai-slop-gc` 규칙 추가 |

### 라우팅 원칙

- 공유 규칙을 한 host 파일에만 넣고 자동 전파된다고 가정하지 않는다.
- host 전용 경로나 명령은 다른 host adapter에 복사하지 않는다.
- built-in/native asset은 수정 대상에서 제외한다.
- 이동 대상이 불명확하면 추측하지 말고 사용자에게 묻는다.

### 승인 절차

각 후보에 대해 개별적으로 `AskUserQuestion`을 사용해 승인을 받는다.

- header: "개선 제안"
- question: "[패턴 설명] — [제안 내용]. 적용할까요?"
- options: "승인" / "거부" / "수정 후 적용"

### 적용 후 기록

승인된 변경은 `~/.agents/signals/changes.jsonl`에 기록한다:

```json
{"ts":"2026-04-06T15:00:00","id":"chg-001","pattern":"optional chaining 우선","action":"rules/claude/CLAUDE.md에 규칙 추가","signal_type":"correction","signal_count":3,"status":"applied"}
```

거부된 제안은 `status: "dismissed"`로 기록한다 (다시 제안하지 않음).

### 적용 결과 출력

```markdown
## Harness 개선 적용 완료
- 수정된 파일: [목록]
- 반영된 패턴: [요약]
- 거부된 패턴: [요약]
```

---

## Phase 4: Verify (효과 검증)

적용된 변경이 실제로 효과가 있는지 추적한다.

### 절차

1. `changes.jsonl`에서 `status: "applied"`인 변경을 읽는다
2. 각 변경의 `pattern`과 동일한 신호가 **적용 이후** `log.jsonl`에 있는지 확인
3. 판정:

| 조건 | 판정 | 액션 |
|---|---|---|
| 적용 후 14일간 재발 0회 | `validated` | changes.jsonl 업데이트 |
| 적용 후 7일 미만 | `monitoring` | 보고만 |
| 적용 후에도 재발 | `ineffective` | 사용자에게 제거/수정 제안 |

### 출력

```markdown
## Harness 변경 효과 추적

| 변경 | 적용일 | 이후 재발 | 상태 |
|------|--------|----------|------|
| "주석 규칙 추가" | 04-01 | 0회/14일 | validated |
| "scope 임계값 조정" | 04-03 | 2회/3일 | monitoring |
| "래퍼 함수 금지" | 03-25 | 3회/12일 | ineffective → 수정 제안 |
```

`ineffective` 판정 시 사용자에게 해당 규칙을 제거할지, 수정할지 물어본다.

---

## Phase 5: 모델 진화 감사 (선택적)

**트리거**: 새 모델 출시 또는 사용자가 "모델이 업그레이드됐다"고 언급한 경우에만 실행한다.

### 감사 원칙

> "모든 harness 요소는 모델이 수행하지 못하는 역할을 인코딩한다. 모델이 진화하면 그 가정을 재검토해야 한다."

harness의 각 구조적 요소에 대해 아래 질문을 던진다:

| 질문 | 판정 |
|------|------|
| 이 Phase/Rule이 없으면 모델이 스스로 잘못된 행동을 하는가? | 아니면 → 제거 후보 |
| 이 구조가 이전 모델의 약점을 보완하기 위해 추가됐는가? | 그렇다면 → 재검증 필요 |
| 제거했을 때 품질 저하가 관찰 가능한가? | 아니면 → 제거 권장 |

### 감사 대상

- `~/.agents/skills/*/references/common.md`의 각 Phase
- `~/.agents/rules/{host}/` 전역 규칙
- team config의 각 에이전트 및 spawn 구조

### 감사 보고 형식

```markdown
## 모델 진화 감사 결과

| 요소 | 추가된 이유 (추정) | 현재도 필요한가 | 권장 조치 |
|------|-----------------|--------------|---------|
| [Phase/Rule명] | [당시 모델 약점] | 예/아니오/불확실 | 유지/제거/축소 |
```

제거 또는 축소를 권장할 경우 사용자 승인을 받은 뒤 적용한다.

---

## 신호 정리

session-wrap 실행 시 90일 초과 신호를 `log.jsonl`에서 제거한다. `validated`된 변경의 원본 신호도 정리 대상에 포함한다.
