## Gemini PR 루프 CAS 규약 버그 + @gemini 멘션 중복 POST — 2026-04-20

**컨텍스트**: sentry-auto-fixer 의 Gemini PR 리뷰–수정 루프에서 두 가지 증상 발생. (1) `GEMINI_REVIEW_LOOP_MAX_ROUNDS=3` 설정이지만 실제로는 1회만 실행. CloudWatch 에 `onPullRequestReview: SHA 불일치 — 무시, got=7416789, expected=9b40967` 경고 로그. (2) PR 생성 시 `@gemini-code-assist` 멘션 코멘트가 3회 연달아 POST 됨. 두 증상 모두 커밋 `e87adff`(Apr 8, saveState CAS 도입) 이후 누적된 잠복 버그.

**핵심 결정**:
1. **saveState CAS 규약을 "stored == memory-1" → "stored == memory" 로 단순화** 하고, write 직전 `state.stateVersion += 1` 을 메서드 내부가 담당하도록 책임 이동. 이유: CAS 도입 시 "호출자가 증가" 규약을 세웠지만 호출자 11곳 중 2곳만 따르고 있었고, 규약 암묵성 자체가 재발 가능성 → Optimistic lock 의 버전 증가를 **저장 메서드의 invariant** 로 만들어 향후 호출자 실수 방지.
2. **Bootstrap 진입점을 `pull_request.labeled` 단일로 수렴.** webhook-handler 가 라벨 부여 **전에** `ensureInitialState` 로 상태 코멘트를 선생성하여 labeled 웹훅이 도착했을 때 동일 commentId 를 바라보게 함. `onPullRequest.opened` 트리거와 webhook-handler 직접 호출(`tryBootstrapAfterCreate`)을 모두 제거.
3. **외부 부수효과(@gemini 멘션 POST) 이전에 CAS claim 선행.** `postReviewRequest` 순서를 (state 변경 → 멘션 POST → save) 에서 (state 변경 → **CAS save claim** → 멘션 POST → cid save) 로 재배열. claim 실패 시 즉시 return 하여 동시 트리거 중 하나만 멘션 POST 하게 함. 멘션 POST 실패 시 `phase=failed` 롤백 + 알림으로 좀비(awaiting_review without mention) 방지.

**발견**:
- **CAS 는 보호하려는 리소스 단위로만 유효**. 같은 PR 에 대해 두 Lambda 가 **서로 다른 상태 코멘트를 생성**하면, 각 코멘트에 대한 CAS 는 독립적으로 통과한다 → 코멘트 ID 단위의 optimistic lock 은 "같은 코멘트를 보고 있을 때만" 동시성 보호가 된다. 상태 코멘트 생성 자체가 경쟁 지점.
- **CAS 가 실패해도 in-memory 로직은 계속 진행**. `saveState` 가 `return` 으로 조용히 abort 했기 때문에, 저장은 실패했는데 부수효과(파일 커밋, 코멘트 생성)는 그대로 실행되어 "저장된 state 는 stale, 실제 GitHub 은 앞서 나간" 불일치 상태가 축적됐음.
- **GitHub webhook 타이밍 의존 경로는 racy**. `pull_request.opened` 이벤트의 `pr.labels` 가 라벨 부여 **이전에** 캡처되는지 **이후에** 캡처되는지는 GitHub 내부 타이밍에 따라 달라질 수 있음. 우리는 dead path 라 믿고 있었지만 재시도/동시성 조건에서 활성화 가능.
- **stateVersion 은 "논리적 state transition 카운터"가 아니라 "저장 리비전"으로 해석하는 것이 안전**. 전자 해석은 "의미 있는 변경 시에만 증가" 로 오도되고, 후자는 "매 저장마다 증가" 로 명확.

**실수**:
- 커밋 `e87adff` 에서 CAS 를 도입할 때 호출자 11곳 중 2곳(`postReviewRequest`/`completeSuccess`) 만 `stateVersion += 1` 을 하고 있던 기존 상태를 "의도된 규약" 으로 간주함. 실제로는 해당 2곳이 우연히 증가시키고 있었을 뿐이고, CAS 추가 후 나머지 9곳이 조용히 망가짐.
- CAS 실패 시 `return` 만 하고 호출자에게 전파하지 않음 → 실패가 관측 가능해지는 경로 없음. 로그 경고만 남고 기능은 deadlock.
- 이전 fix 커밋 `5de2c1a` 가 "SHA mismatch → warn & ignore" 로 false failure 제거를 목표로 했으나, 진짜 증상(루프 1회만 실행) 은 그 이전 레이어의 CAS 버그였음. 표면 증상만 가리고 근본 원인은 심화됨.
- 중복 @gemini 멘션 문제에서 처음에는 "labeled 이벤트만 쓰면 됨" 으로 단순화하려 했으나, council 검토에서 **loadState=null 레이스** 가 여전히 남는다는 점 지적. 라벨 부여 전 상태 코멘트 선생성이 핵심.

**다음 번엔**:
1. **Optimistic lock 도입 시 버전 증가 책임은 저장 메서드 내부에 고정.** 호출자 규약은 암묵 버그의 온상.
2. **부수효과가 있는 메서드 순서는 (CAS claim → 외부 API → save result).** claim 없이 외부 API 를 먼저 호출하면 동시 트리거에서 부수효과가 중복 실행된다.
3. **상태 코멘트 같은 "생성이 경쟁 지점인 리소스"** 는 다음 중 하나로 보호:
   - 생성 경로를 단일 진입점으로 서비스 레이어에서 시퀀싱
   - 생성 후 canonical 선정 로직(예: 가장 오래된 것만 유효) + 중복 정리
   - GitHub 외부 lock(DynamoDB 등)
4. **웹훅 기반 워크플로우의 진입점은 단일화 또는 명시적 dedup 필수.** PR 생성 직후 emit 되는 이벤트(opened/labeled/synchronize)가 직접 호출 경로와 섞이면 동시성 행렬이 폭발한다.
5. **`saveState` 가 `Promise<boolean>` 을 반환한다는 사실을 활용한 호출자 dedup 로직을 후속 작업으로 추가.** 현재는 레일만 깔린 상태.
6. **CAS 실패 시 "저장 안 됐는데 notify 만 나간" 경로가 `saveState` 내부 timeout 블록에 존재** (notify 가 CAS 체크 전에 실행). 이번 범위 밖으로 미룸.

**관련 커밋**:
- `9b9ed14` fix: Gemini 루프 saveState CAS 규약 불일치로 루프가 1회만 진행되는 문제 수정
- `432ddc1` fix: Gemini 루프 PR 생성 시 @gemini 멘션이 중복 호출되는 문제 수정

**관련 선행 커밋 (맥락)**:
- `e87adff` (Apr 8) CAS 도입 — 이번 버그 A 의 시작점
- `5de2c1a` (Apr 13) SHA mismatch ignore — 표면 증상 완화였으나 근본 원인 미해결
- `8b2e77d` (Apr 13) Slack 스레드 연속성 보장 — initialSlackTs 도입
- `e14eddc`, `b864965` — 멀티파일 원자적 커밋 인프라 (Gemini 루프 확장과 맞물림)

**주요 파일**:
- `src/services/gemini-pr-loop-service.ts` — CAS 로직, postReviewRequest, tryStartFirstRound, ensureInitialState
- `src/services/webhook-handler.ts:461~471` — Gemini 루프 bootstrap 호출
- `src/services/gemini-pr-loop-state.ts` — 상태 직렬화, processedDeliveryIds, stateVersion 필드
