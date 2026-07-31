## Android MediaProjection 백그라운드 크래시 — 2026-04-08

**컨텍스트**: 화면 녹화 중 앱이 백그라운드로 전환되면 크래시 발생. MediaProjection + VirtualDisplay + MediaCodec + Foreground Service 조합.

**핵심 결정**:
- `stop()`에 `@Synchronized` 추가 — `projectionCallback.onStop()`과 `Blackbox.stop()`이 동시에 호출되면 double-free 발생
- 인코더 스레드를 먼저 종료(`quitSafely` + `join`) → 그 후 인코더 해제 — 순서를 바꾸면 스레드가 해제된 Surface에 접근
- `ActivityLifecycleCallbacks`로 앱 백그라운드 감지 → 녹화 안전 중지

**발견**:
- `@Volatile var isRecording`은 가시성만 보장, 원자성은 아님. `stop()` 동시 진입 방지에는 `@Synchronized` 필요
- `MediaCodec.dequeueOutputBuffer`가 이미 해제된 인코더에서 `IllegalStateException` 발생 — try-catch 필수
- Android의 `activeActivityCount` 패턴 (started +1, stopped -1)으로 앱 전체의 foreground/background 상태를 판단할 수 있음

**실수**:
- 초기 구현에서 Foreground Service만 추가하면 충분할 것으로 판단. 실제로는 리소스 해제 순서 + 동시성 + lifecycle 감지까지 필요했음

**다음 번엔**:
- MediaProjection 관련 코드를 수정할 때 반드시 `stop()` 동시 호출 시나리오를 테스트
- 인코더 스레드 종료 → 인코더 해제 순서를 절대 바꾸지 않음
- 백그라운드 전환 테스트를 필수 QA 항목에 포함
