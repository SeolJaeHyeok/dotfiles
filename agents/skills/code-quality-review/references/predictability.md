# 예측 가능성 (Predictability) — 핵심 원칙

> 카테고리 정의: 코드의 **이름·시그니처·맥락만 보고 동작을 정확히 예측 가능한가**. 같은 이름은 같은 동작을, 같은 종류의 함수는 같은 모양의 반환을, 시그니처가 약속한 일만 수행해야 한다. 예측이 어긋나는 순간 호출부에서 버그가 발생한다.

---

## 1. 이름 겹치지 않게 관리하기

**안티패턴:** 라이브러리/표준 함수와 시그니처·이름이 같지만 추가 동작(예: 인증 토큰 자동 첨부)을 몰래 수행하는 래퍼. 호출자는 표준 `http.get`이라 믿고 쓰지만 실제로는 토큰을 붙인 요청이 나간다.

**원칙:** 표준 라이브러리/외부 API와 구분되도록 명칭을 바꿔 추가 동작을 시그니처에 드러낸다. **이름이 곧 계약이다.**

**리뷰 시그널:**
- 표준 라이브러리/네이티브 API와 동일한 이름인데 부가 동작(인증·캐시·로깅)이 있음
- import 별칭(`import { get } from "./http"`)으로 표준 이름을 덮어쓴 코드
- 함수 본문이 시그니처보다 더 많은 일을 함

```ts
// Before — 이름은 표준 http.get처럼 보이지만 토큰을 붙인다
http.get(url);

// After — 부가 동작이 이름에 드러남
httpService.getWithAuth(url);
```

---

## 2. 같은 종류의 함수는 반환 타입 통일하기

**안티패턴:** 같은 카테고리(서버 호출 훅, 유효성 검사 등)인데 반환 타입이 제각각. 어떤 훅은 Query 객체 전체를, 어떤 훅은 데이터만 반환. 검증 함수도 어디는 boolean, 어디는 string, 어디는 객체. 더 위험한 점: truthy 객체를 boolean처럼 `if`로 쓰면 항상 참이 되어 검증이 무력화되는 버그.

**원칙:** 같은 종류의 동작은 일관된 규칙(반환 형태)을 따른다. 호출부 분기 패턴까지 통일된다.

**리뷰 시그널:**
- 같은 카테고리(API 훅, validator 등)의 형제 함수와 반환 타입이 다름
- `if (validate(x))` 처럼 객체 반환을 boolean처럼 사용
- 일부 훅은 `useQuery` 결과 그대로, 일부는 `.data`만 꺼내 반환

```ts
// Before — 형제끼리 반환 모양 불일치
function useUser() { return useQuery(...); }              // Query 객체
function useServerTime() { return useQuery(...).data; }   // 데이터만

// After — 통일
function useUser() { return useQuery(...); }
function useServerTime() { return useQuery(...); }
```

---

## 3. 숨은 로직 드러내기

**안티패턴:** 함수 이름·파라미터·반환 타입으론 예측할 수 없는 부수효과(로깅, 분석 이벤트, 캐시 무효화, 라우팅)가 구현 안에 숨어있다. 호출자는 "잔액을 가져올" 의도였는데 분석 이벤트까지 발생.

**원칙:** "함수의 이름과 파라미터, 반환 타입으로 예측할 수 있는 로직만 구현 부분에 남기세요." 시그니처가 약속한 일만 한다. 부수효과는 호출부로.

**리뷰 시그널:**
- `fetchX`/`getX`/`useX` 안에 `logging.log(...)`, `analytics.track(...)`, `router.push(...)` 같은 부수효과
- "이 함수를 부르면 X도 일어난다"가 주석으로만 표시됨
- 테스트가 부수효과 모킹 없이 호출 못 함

```ts
// Before — 이름은 fetch인데 로깅도 한다
async function fetchBalance() {
  const balance = await api.get(...);
  logging.log("balance_fetched");
  return balance;
}

// After — 호출부에서 명시
const balance = await fetchBalance();
logging.log("balance_fetched");
```

---

## 리뷰어 체크리스트

| # | 시그널 |
|---|---|
| 1 | 표준 함수와 동명인데 부가 동작이 있음 |
| 2 | 같은 카테고리 형제와 반환 타입이 다름 / 객체를 boolean처럼 사용 |
| 3 | 함수 본문에 이름이 약속하지 않은 부수효과(log/track/route/cache) |
