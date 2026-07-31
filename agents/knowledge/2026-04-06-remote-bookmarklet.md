## Remote Bookmarklet Bundle — 2026-04-06

**컨텍스트**: 원격 지원 시 사용자 PC에 크롬 익스텐션 없이 Blackbox를 주입하는 방법. 북마클릿으로 단일 JS 파일을 로드.

**핵심 결정**: 북마클릿 + 단일 IIFE 번들 방식 선택. 크롬 익스텐션은 설치/삭제 번거로움과 흔적 잔류 문제가 있어 기각. URL 파라미터 방식은 자사 코드 수정이 필요하여 범용성 부족.

**발견**: Vite의 resolve.alias를 사용하면 별도 패키지(@blackbox/plugin-jira)의 소스를 직접 번들에 포함시킬 수 있다. 별도 빌드 단계 없이 하나의 IIFE로 출력.

**다음 번엔**:
- HTTPS 사이트에서 HTTP 서버로의 Mixed Content 제한 주의. 프로덕션에서는 서버도 HTTPS 필수.
- CSP가 엄격한 사이트에서는 외부 스크립트 로드가 차단될 수 있음. DevTools Console snippet 방식을 대안으로 준비.
- CONFIG 객체에 API 토큰이 하드코딩되어 있으므로 번들 파일의 접근 제어 필요.
