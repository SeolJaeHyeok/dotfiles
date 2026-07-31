## Blackbox Android SDK 배포 준비 이슈 — 2026-04-09

**컨텍스트**: 모노레포에서 분리한 Android SDK의 배포 준비 과정에서 4가지 코드 품질 이슈를 발견하고 수정.

**핵심 결정**:
- ProGuard consumer rules: `@Serializable` 클래스만 정밀 타겟팅. 광범위한 keep 규칙은 소비자 앱 바이너리 크기를 불필요하게 키움.
- 포트 하드코딩 제거: 개발 환경 가정(`:3100→:3000`)을 완전 제거. 서버가 반환하는 URL을 그대로 사용하는 것이 SDK로서 올바른 설계.
- ActivityLifecycleCallbacks: 콜백을 멤버 변수로 저장하고 `stop()`에서 해제 + `activeActivityCount` 초기화. Council에서 카운트 초기화 누락을 지적받아 반영.
- connectionType: 캡처 시점 스냅샷 방식 채택 (실시간 감시 대비 배터리 효율적). `ACCESS_NETWORK_STATE` 권한이 Manifest Merger로 소비자 앱에 자동 병합되므로 문서화 필요.

**발견**:
- API 34 에뮬레이터에서 `startForegroundService()` → `getMediaProjection()` 타이밍이 API 33 이하보다 엄격. 동일 코드가 API 버전에 따라 크래시 여부가 갈림.
- Predictive back gesture (API 34)에서 Activity 전환 시 `onActivityStopped`가 `onActivityStarted`보다 먼저 호출되어 백그라운드 오탐 발생.
- 모노레포에서 별도 레포로 분리할 때 코드 자체는 동일해도, 테스트 환경(에뮬레이터 API 레벨)이 달라지면 새로운 문제가 드러남.

**실수**:
- 초기에 영상 길이가 짧은 문제를 SDK 코드 버그로 접근했으나, 실제 원인은 백그라운드 감지 오탐이었음. logcat 로그를 먼저 확인했어야 함.

**다음 번엔**:
- Android SDK 배포 전 반드시 확인: (1) consumer-proguard-rules.pro 존재 여부, (2) 하드코딩된 개발 환경 가정 제거, (3) lifecycle 콜백 등록/해제 쌍 확인.
- API 34+ 에뮬레이터에서 반드시 테스트. Foreground Service 타이밍과 predictive back gesture 동작이 이전 버전과 다름.
- 영상 녹화 문제 디버깅 시 첫 번째로 `adb logcat`에서 ScreenRecorder/Blackbox 태그 필터링.
