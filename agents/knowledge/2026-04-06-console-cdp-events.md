## Console CDP Events — 2026-04-06

**컨텍스트**: Blackbox 녹화 재생 시 DevTools Console 탭에 console.log/warn/error를 페이지별로 필터링하여 표시하는 기능 구현.

**핵심 결정**: 독립 ConsoleInterceptor를 만들어 기존 CDP 파이프라인(sendCdpEvent → cdpEvents 테이블 → DevTools 리플레이)을 재사용. rrweb 콘솔 플러그인 확장은 3초 배치 딜레이와 타임스탬프 정밀도 문제로 기각.

**발견**: cdpEvents 테이블과 파이프라인이 도메인에 무관하게 설계되어 있어 새 테이블 없이 Runtime 도메인 이벤트를 그대로 저장/재생할 수 있었다.

**실수**: replayEventsForPage에서 Network+Runtime을 모두 전송하도록 구현하여, Network.enable과 Runtime.enable 양쪽에서 호출 시 Network 이벤트가 2번 재생되는 중복 버그 발생. → methodPrefix 파라미터로 도메인별 분리로 해결.

**다음 번엔**:
- DevTools Console 탭은 `Runtime.executionContextCreated` 이벤트가 선행되어야 consoleAPICalled를 렌더링한다. 새 도메인 추가 시 초기화 이벤트 필수 여부를 먼저 확인할 것.
- CDP 파이프라인에 새 도메인 추가 패턴: (1) SDK 인터셉터 → sendCdpEvent() 재사용, (2) 서버 {Domain}.enable 핸들러 추가, (3) replayEventsForPage에 methodPrefix 전달.
- console 프록시 시 재귀 방지(isIntercepting 플래그)와 안전한 직렬화(순환 참조 대응)는 필수.
