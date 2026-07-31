# Phase 3: Notion 아카이빙

notion-mcp를 사용하여 기여 내역을 Notion에 기록.

## 사전 정보 수집

아카이빙 전 사용자에게 확인:
- **Notion 페이지 URL**: 기록할 대상 페이지 링크
- **PR URL**: 진행 중이거나 완료된 PR 링크

## 절차

### 1. 기존 데이터베이스 확인
대상 Notion 페이지에 해당 프로젝트의 데이터베이스가 이미 존재하는지 확인:
- **있는 경우**: 기존 데이터베이스에 항목 추가 (기존 Property 형식에 맞춰서)
- **없는 경우**: 새 데이터베이스 생성 (아래 스키마 사용)

### 2. 데이터베이스 스키마 (신규 생성 시)

| Property | Type | 설명 |
|----------|------|------|
| Title | title | PR 제목 |
| Status | select | Open / Merged / Closed |
| Link | url | PR URL |
| Date | date | PR 생성일 또는 병합일 |

### 3. 항목 작성

PR을 분석하여 아래 세 항목을 Notion 페이지/항목에 기록:

**Problem (배경 및 문제)**
- 해당 PR이 해결하려는 이슈의 핵심 내용 요약
- 예: 특정 환경에서의 빌드 오류, DX 저해 요소, 성능 병목 등

**Solution (해결 방법)**
- 기술적 접근 방식 및 로직 수정 내용
- 핵심 코드 변경점이나 사용 라이브러리/로직 포함

**Metadata**
- Status: Open / Merged / Closed
- Link: 원본 PR URL
- Date: PR 생성일 또는 병합일

### 4. 기존 항목 업데이트
페이지에 동일 PR이 이미 존재하는 경우:
- Status 변경 여부 확인 후 업데이트

## 제약 사항
- 기술적 내용은 명확하되 간결하게 작성 (가독성 우선)
- 기존 Database Property 형식이 있다면 그 형식에 맞춰 값 채우기
