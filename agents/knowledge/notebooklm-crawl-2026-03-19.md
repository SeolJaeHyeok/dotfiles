# notebooklm-crawl EC2 배포 + 자동화 디버깅 — 2026-03-19

---

## 1. Amazon Linux 2023 x11vnc 소스 빌드

**컨텍스트**: noVNC 구현을 위해 x11vnc가 필요하나, AL2023 기본 저장소에 없고 EPEL도 `redhat-release >= 9` 요구로 설치 불가.

**핵심 결정**: libvncserver → x11vnc 순서로 소스 빌드.

**발견**:
- EPEL el9 RPM은 `redhat-release >= 9`를 요구하는데 AL2023은 이를 제공하지 않음
- cmake는 x86_64에서 `/usr/local/lib64`에 설치 → `/usr/local/lib`만 ldconfig에 등록하면 `libvncserver.so.1 not found` 발생
- x11vnc.service의 `ExecStart` 경로를 `/usr/local/bin/x11vnc`로 명시해야 함 (소스 빌드 기본 설치 위치)

**다음 번엔**:
- AL2023에서 외부 패키지 필요 시 EPEL 대신 소스 빌드 고려
- ldconfig 설정 시 `/usr/local/lib`와 `/usr/local/lib64` 모두 등록할 것
- systemd 서비스가 소스 빌드 바이너리를 사용할 경우 `/usr/local/bin` 경로 확인 필수

---

## 2. x11vnc.passwd 소유자 미일치

**컨텍스트**: bootstrap이 root로 실행되어 `/etc/x11vnc.passwd`가 `root:root 600`으로 생성됨. x11vnc 서비스는 `User=notebooklm`으로 실행되어 파일을 읽지 못함.

**핵심 결정**: bootstrap에서 파일 생성 직후 `chown "${SERVICE_USER}:${SERVICE_USER}" /etc/x11vnc.passwd` 추가.

**경고**: systemd 서비스가 특정 유저로 실행될 때, root로 생성한 파일의 소유자를 반드시 해당 유저로 변경해야 함. 에러 메시지가 "Couldn't read password file"로 나오지 않고 "password check failed"로 나와 원인 추적이 어려움.

---

## 3. NotebookLM SPA race condition — 채팅 기록 비동기 로드

**컨텍스트**: `page.goto()` + `waitUntil: "domcontentloaded"` 완료 직후 `waitForConversationToClear()`를 호출하면 `.individual-message` count가 0으로 보여 "비어있음"으로 잘못 판단함. 실제로는 채팅 기록이 비동기 API로 아직 로드 중인 상태.

**핵심 결정**: `page.goto()` 이후 `page.waitForLoadState("networkidle", {timeout: 5000}).catch(() => {})` 추가. 타임아웃 시 무시하고 진행(백그라운드 폴링 예외 허용).

**발견**: NotebookLM은 SPA로, `domcontentloaded` 완료 ≠ 채팅 데이터 로드 완료. 채팅 기록은 별도 XHR로 fetch됨.

**실수**: 초기에 `waitForConversationToClear()`의 false positive 원인을 잘못 추정(clearHistory 로직 오류로 의심)했으나 실제는 goto 직후 타이밍 문제였음.

**다음 번엔**: SPA에서 `page.goto()` 후 데이터가 비동기 로드되는 구조라면, `domcontentloaded`만으로는 충분하지 않음. `networkidle` 또는 특정 데이터 로드 완료 신호를 기다려야 함.

---

## 4. pressSequentially + \n = Enter 자동 제출

**컨텍스트**: n8n에서 전달된 질문에 줄바꿈(`\n`)이 포함된 경우 (예: "안녕하세요!\n질문내용"), `pressSequentially`가 `\n`을 Enter 키 이벤트로 전송하여 질문이 두 번 제출됨.

**핵심 결정**: `fillQuestion`에서 `pressSequentially` 호출 전 `question.replace(/[\r\n]+/g, " ").trim()`으로 줄바꿈을 공백으로 치환.

**경고**: Playwright의 `fill()`은 Angular 폼 이벤트를 트리거하지 않아 사용 불가. `pressSequentially`는 문자 하나하나를 타이핑하므로 특수 문자(`\n`, `\r`) 처리에 주의.

---

## 5. clearHistory 확인 버튼 셀렉터 오탐

**컨텍스트**: 채팅 기록 삭제 확인 다이얼로그의 "삭제" 버튼을 클릭해야 하는데, `page.locator('button, [role="button"]').filter({ hasText: /삭제|확인/ }).first()`가 follow-up-chip(role=button, "삭제" 텍스트 포함)을 먼저 잡아 30초 타임아웃 발생.

**핵심 결정**: 셀렉터를 `mat-dialog-actions button, .mat-mdc-dialog-actions button`으로 범위 한정.

**발견**: 에러 로그에 `locator resolved to <div class="follow-up-chip ...">` 라는 힌트가 있어 오탐 원인 파악 가능. 에러 메시지를 꼼꼼히 읽는 것이 핵심.

**다음 번엔**: 다이얼로그 내 버튼을 대상으로 할 때는 항상 `mat-dialog-actions` 또는 `cdk-overlay-pane` 안으로 범위를 한정할 것.

---

## 6. dist/ git tracking + EC2 빌드 충돌

**컨텍스트**: 로컬에서 빌드 후 `dist/`를 커밋·push했는데, EC2 bootstrap도 `pnpm build`로 `dist/`를 생성함. git pull 시 "Your local changes would be overwritten by merge" 충돌.

**핵심 결정**: `dist/`를 `.gitignore`에 추가하고 `git rm -r --cached dist/`로 tracking 제거. EC2에서 빌드하는 방식 유지.

**패턴**: 빌드 산출물은 git tracking 대상이 아님. 배포 서버에서 빌드하는 구조라면 더욱 그렇다. Agent Council도 동일하게 A 방향(gitignore) 권장.

**다음 번엔**: CI/CD + 서버 빌드 구조에서 `dist/`, `build/` 등 빌드 산출물 디렉토리는 최초 설계 시 `.gitignore`에 포함할 것.
