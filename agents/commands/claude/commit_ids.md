# Claude Code 전역 지침 - Commit(IDS&Trust용)

이 문서는 프로젝트의 일관된 커밋 로그를 유지하기 위한 메시지 작성 표준을 정의합니다.

## 0. 기본 원칙 (Basic Principles)

1.  **스테이징된 변경사항만 커밋 (Staged Changes Only)**:
    *   커밋 명령을 실행할 때는 **반드시 이미 스테이징(staged)된 변경사항만** 포함해야 합니다.
    *   AI나 개발자는 `git commit -a` 또는 `git add .`을 무분별하게 사용하여 의도치 않은 변경사항(테스트 코드, 임시 파일 등)이 함께 커밋되지 않도록 엄격히 주의해야 합니다.
    *   커밋 전 `git status`를 확인하여 포함될 파일을 명확히 인지하십시오.


## 1. 메시지 구조 (Structure)

커밋 메시지는 **제목(Header)**, **본문(Body)**, **바닥글(Footer)**로 구성됩니다.

```
[Jira-ID] type: subject

body
```

### A. 제목 (Header)

제목은 50자를 넘기지 않는 것을 권장하며, 다음 형식을 따릅니다.

1.  **Jira 이슈 연동 시**: `[티켓번호] type: 제목`
    *   예시: `[MCCWC-1234] feat: 사용자 로그인 기능 구현`
2.  **일반 커밋**: `type: 제목`
    *   예시: `docs: 커밋 메시지 규칙 문서 추가`

### B. 본문 (Body)

*   필수 사항입니다. 제목으로 충분하지 않을 때 상세 내용을 작성합니다.
*   **무엇을**, **왜** 변경했는지에 초점을 맞춥니다.
*   항목별로 불렛 포인트(`-`)를 사용하여 가독성을 높입니다.

## 2. 타입 (Types)

다음의 타입(Prefix)을 사용하여 커밋의 성격을 명확히 합니다.

| Type | Description |
| :--- | :--- |
| **feat** | 새로운 기능 추가 (A new feature) |
| **fix** | 버그 수정 (A bug fix) |
| **docs** | 문서 변경 (Documentation only changes) |
| **style** | 코드 포맷팅, 세미콜론 누락 등 코드 변경이 없는 경우 (White-space, formatting, etc) |
| **refactor** | 리팩토링 (A code change that neither fixes a bug nor adds a feature) |
| **test** | 테스트 코드 추가 또는 수정 (Adding missing tests or correcting existing tests) |
| **chore** | 빌드 태스크, 패키지 매니저 설정 등 (Changes to the build process or auxiliary tools and libraries) |

## 3. 작성 가이드 (Guidelines)

1.  **언어**: 제목과 본문은 **한국어** 작성을 원칙으로 합니다. (프로젝트 컨벤션에 따라 영문 허용 가능)
2.  **명령문**: 제목은 명령문으로 시작하지 않아도 되나, 명확한 서술형으로 작성합니다.
3.  **Jira 티켓**: 작업과 직접 관련된 Jira 이슈가 있다면 반드시 포함합니다.
    *   **Jira ID 추출**: 현재 체크아웃된 브랜치명에서 `feature/`, `fix/` 등의 상위 그룹 접두어를 제외한 `MCCWC-####` 형식의 ID를 사용합니다. (예: `feature/MCCWC-1234-login` -> `MCCWC-1234`)
    *   단순 문서 수정이나 이슈와 무관한 리팩토링의 경우 생략할 수 있습니다.

## 4. 예시 (Examples)

**새로운 기능 추가 (With Jira)**
```
[MCCWC-8342] feat: 건강생활실천지원금제 앱 신청 관리 페이지 추가

- 신청 관리 목록 조회 API 연동
- 탭 레이아웃 적용 및 라우팅 설정
```

**문서 수정 (No Jira)**
```
docs: 페이지 생성 규칙 문서 업데이트

- 컴포넌트 명명 규칙(Page postfix) 추가
- 공통 컴포넌트 우선순위 가이드 보강
```
