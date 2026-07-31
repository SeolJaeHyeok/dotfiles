## sentry-auto-fixer: AI codeContext vs apply 범위 불일치 버그 — 2026-03-27

**컨텍스트**: Sentry 에러를 감지해 자동으로 GitHub Draft PR을 생성하는 시스템. AI가 생성한 find/replace replacements를 Sentry context 줄 범위(block)에만 적용.

**핵심 결정**: `createFixRequest`의 `codeContext`를 `extractScopedContext(전체 함수 스코프)`에서 `location.context.join('\n')`(Sentry context ~11줄)으로 변경.
- 대안 A(block 확장 → 전체 함수): PR diff가 수백 줄이 될 수 있어 채택 안 함
- 대안 B(프롬프트 강화만): 범위 불일치 근본 원인을 해결 못해 채택 안 함

**발견**:
- `extractScopedContext`(AST 기반 전체 함수)는 AI에게 수백 줄 컨텍스트를 줌. AI는 "같은 스코프의 모든 risky access를 고쳐라" 규칙에 따라 함수 전체에서 optional chaining을 적용하는 replacements를 생성.
- 실제 fix apply 범위(block)는 Sentry context ~11줄. AI가 생성한 엉뚱한 replacements가 마침 block 안 코드에 매칭되어 apply됨.
- `cycOno` 에러인데 `pcpData`, `preViewSearch`, `pcpEducationConsultationData`를 수정하는 현상이 이 메커니즘으로 발생.
- 같은 이슈에 대해 두 번의 Sentry 이벤트(created/recurring)가 발생하면 Run 1 실패(패턴 불일치) → Run 2 성공(잘못된 코드)으로 Slack 스레드에 모순된 메시지가 남음.

**실수**:
- `extractScopedContext`를 도입할 때 "AI에게 더 많은 컨텍스트를 주면 completeness가 높아진다"는 가정이 맞았지만, apply 범위와의 불일치를 간과함.
- AI가 본 범위 ≠ 실제 수정이 적용되는 범위라는 점이 핵심 버그. 시스템 설계 시 이 두 범위를 항상 의식적으로 일치시켜야 함.

**Gemini Loop silent failure**:
- `onPullRequestReview`와 `onIssueComment`에서 phase mismatch, SHA mismatch 발생 시 알림 없이 return하여 루프가 조용히 중단됨.
- 수정: 3곳의 guard에 Slack failed 알림 + console.warn 추가.
- 패턴: 상태 머신에서 guard/early-return은 반드시 로깅이나 알림을 동반해야 함. 없으면 어디서 실패했는지 알 수 없다.

**다음 번엔**:
- AI에게 전달하는 `codeContext`와 실제 코드에 apply되는 범위(block)는 항상 동일해야 함. 다를 경우 AI가 볼 수 없는 코드에 대한 replacements를 생성하거나, 관련 없는 코드에 매칭되어 적용될 수 있음.
- `extractScopedContext`는 AI가 전체 함수 맥락을 이해하는 데 유용하지만, fix용 codeContext로 쓸 때는 apply 범위와 일치해야 함.
- Gemini loop처럼 비동기 상태 머신에서는 모든 guard가 관찰 가능(loggable/notifiable)해야 함. silent return은 디버깅을 불가능하게 만든다.
- 관련 파일: `src/services/ai-service.ts:createFixRequest`, `src/services/webhook-handler.ts:buildUpdatedBlockContent`, `src/services/gemini-pr-loop-service.ts:onPullRequestReview`
