## Multi-Plugin Architecture Refactoring — 2026-04-08

**컨텍스트**: iOS/Android SDK의 플러그인 시스템을 Web SDK와 동일한 다중 플러그인 배열 구조로 개편. `BlackboxOptions.jira` 하드코딩 필드를 `plugins: [BlackboxPlugin]` 배열로 변경.

**핵심 결정**: 
- Web SDK의 BlackboxPlugin 인터페이스를 모바일에 포팅하되, `html` 파라미터와 `renderUI(container: HTMLElement)` 같은 웹 전용 부분은 제외
- `PluginContext.previousResults` 필드를 추가하여 플러그인 간 결과 체이닝 (예: Slack이 Jira 결과의 issueKey를 참조)
- `requiresConfirmation` 플러그인의 UI 처리는 오케스트레이터가 담당 — 플러그인은 `createFormViewController`를 제공하고, 오케스트레이터가 present
- KMP 대신 iOS/Android 각각 독립 구현 유지 (BlackboxPlugin 프로토콜 vs 인터페이스)

**발견**:
- iOS에서 `any BlackboxPlugin` (existential type) 배열은 Swift 5.7+ 필요하지만 이미 iOS 15+ 타겟이므로 문제 없음
- Android에서 `requiresConfirmation` 플러그인의 폼 처리는 static 필드 패턴이 필요 (Blackbox가 object 싱글톤이라 ActivityResult를 직접 받을 수 없음)
- 순차 실행을 재귀 함수로 구현하면 requiresConfirmation 플러그인이 dismiss된 후 다음 플러그인으로 자연스럽게 넘어감

**다음 번엔**:
- 새 플러그인(Slack 등) 추가 시 `BlackboxPlugin` 프로토콜/인터페이스를 구현하고 `plugins` 배열에 추가하면 됨
- `requiresConfirmation: false`인 플러그인은 폼 없이 즉시 자동 실행됨
- 에러 격리는 오케스트레이터의 try-catch가 담당하므로 플러그인 내부에서 throw해도 안전
