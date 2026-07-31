# 문서 템플릿

## API 엔드포인트 템플릿

```markdown
### `METHOD /path`

설명을 한 문장으로.

**인증:** Bearer Token 필요

**Parameters:**
| 이름 | 위치 | 타입 | 필수 | 설명 |
|------|------|------|------|------|
| id | path | string | O | 리소스 ID |
| limit | query | number | X | 최대 개수 (기본값: 20, 최대: 100) |

**Request Body:**
```json
{
  "name": "string (필수)",
  "email": "string (필수, 이메일 형식)"
}
```

**Response (200):**
```json
{
  "id": "abc123",
  "name": "홍길동",
  "createdAt": "2026-01-01T00:00:00Z"
}
```

**Error Responses:**
| 코드 | 설명 | 원인 |
|------|------|------|
| 400 | Bad Request | 필수 필드 누락 또는 형식 오류 |
| 401 | Unauthorized | 토큰 없음 또는 만료 |
| 404 | Not Found | 해당 ID의 리소스 없음 |

**Example:**
```bash
curl -X METHOD https://api.example.com/path \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "홍길동", "email": "hong@example.com"}'
```
```

## ADR (Architecture Decision Record) 템플릿

```markdown
# ADR-{번호}: {제목}

**상태:** 제안됨 | 승인됨 | 폐기됨 | 대체됨
**날짜:** YYYY-MM-DD
**의사결정자:** [이름/팀]

## 컨텍스트

어떤 문제를 해결하려 하는가? 현재 상황과 제약 조건은?

## 결정

무엇을 결정했는가?

## 고려한 대안

### 대안 1: {이름}
- 장점: ...
- 단점: ...

### 대안 2: {이름}
- 장점: ...
- 단점: ...

## 근거

왜 이 결정을 내렸는가? 어떤 트레이드오프를 수용했는가?

## 결과

이 결정으로 인해 달라지는 것은? 새로 생기는 제약은?
```

## CHANGELOG 템플릿 (Keep a Changelog)

```markdown
# Changelog

이 프로젝트의 모든 주요 변경사항을 기록합니다.
[Keep a Changelog](https://keepachangelog.com) 형식을 따릅니다.

## [Unreleased]

### Added
- 새로 추가된 기능

### Changed
- 기존 기능의 변경사항

### Fixed
- 버그 수정

### Removed
- 제거된 기능

## [1.0.0] - 2026-01-01

### Added
- 최초 릴리스
```

## 온보딩 가이드 템플릿

```markdown
# {프로젝트} 온보딩 가이드

이 문서를 따라하면 개발 환경을 셋업하고 첫 기여를 할 수 있습니다.

## 전제 조건

- [ ] [필요 도구 1] 설치됨 (버전 X 이상)
- [ ] [필요 도구 2] 설치됨
- [ ] [계정/권한] 확보됨

## 1. 프로젝트 클론 및 설치

```bash
git clone [URL]
cd [프로젝트]
[설치 명령]
```

예상 결과: `[성공 메시지]`

## 2. 환경 설정

```bash
cp .env.example .env
# .env 파일을 열고 아래 값을 설정:
# DATABASE_URL=... (팀 위키에서 확인)
# API_KEY=... (팀장에게 요청)
```

## 3. 로컬 실행

```bash
[실행 명령]
```

예상 결과: `[브라우저에서 확인할 내용]`

## 4. 첫 기여

1. 이슈를 선택한다 (`good first issue` 라벨)
2. 브랜치를 만든다: `git checkout -b feature/[이슈번호]-[설명]`
3. 변경하고 테스트한다: `[테스트 명령]`
4. PR을 만든다

## 자주 묻는 질문

### Q: [흔한 에러 메시지]
A: [해결법]
```

## 모듈/컴포넌트 문서 템플릿

```markdown
# {모듈명}

## 개요

{모듈이 해결하는 문제와 역할을 2-3문장으로}

## 아키텍처

{Mermaid 다이어그램 또는 핵심 구조 설명}

## 주요 API

### `functionName(params): ReturnType`

{설명}

**Parameters:**
| 이름 | 타입 | 설명 |
|------|------|------|

**Example:**
```typescript
const result = functionName({ key: "value" })
```

## 설정

| 환경 변수 | 설명 | 기본값 | 필수 |
|----------|------|--------|------|

## 의존성

- {의존하는 다른 모듈/서비스}

## 관련 문서

- [ADR-001: 이 모듈의 설계 결정](./adr/001.md)
```
