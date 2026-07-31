## Replay-DevTools Timeline Sync — 2026-04-06

**컨텍스트**: rrweb 리플레이 재생 시점과 DevTools Network/Console 탭을 동기화. 리플레이 진행에 따라 이벤트가 점진적으로 표시되고, 페이지 전환 시 자동 전환.

**핵심 결정**: 클라이언트 500ms 폴링 + 서버 점진적 전송(syncToTimestamp). iframe 전체 리로드(B)는 UX 불가, 클라이언트 CDP 직접 관리(C)는 아키텍처 변경 과다. 기존 REST→WebSocket 패턴 재사용.

**발견**: rrweb-player는 시간 변경 이벤트를 제공하지 않는다. `getReplayer().getCurrentTime()` 폴링이 유일한 방법. `getMetaData().startTime`으로 절대 시간 변환.

**실수**: 
1. seek back의 setTimeout 클로저가 stale 값 캡처 → ref 기반으로 최신 값 참조
2. seek back 전에 기존 debounce 타이머 미취소 → iframe reload 중 경합
3. close 핸들러가 무조건 Map 삭제 → iframe reload 시 신규 연결 엔트리 날림

**다음 번엔**:
- activeDevToolsSockets Map은 recordingId당 1개만 저장. iframe reload 시 구/신 연결 경합 가능. close에서 반드시 `socket === activeSocket` 체크.
- 점진적 이벤트 전송 패턴: `ts > lastSent && ts <= current`. timestamp 없는 이벤트는 requestId fan-out으로 처리.
- syncModeActive 플래그로 enable 핸들러의 즉시 전송을 제어. 첫 sync 요청이 올 때까지 이벤트 보류.
