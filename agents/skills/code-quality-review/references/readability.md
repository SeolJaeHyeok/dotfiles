# 가독성 (Readability) — 8가지 패턴

> 출처: Frontend Fundamentals — Code Quality / Readability (Toss)
> 용도: 코드 리뷰 시 "가독성 결함"을 식별하기 위한 패턴 레퍼런스. 각 항목의 "리뷰 시그널"을 우선 스캔할 것.

---

## 1. 같이 실행되지 않는 코드 분리하기

**안티패턴:** 상호배타적인 두 경로(예: `viewer` vs `admin`)를 하나의 컴포넌트/함수 안에서 `if`·삼항·early return으로 처리. `useEffect` 안에서 `if (isViewer) return` 같은 가드로 부수효과를 건너뛰는 패턴이 대표적.

**원칙:** 분기를 컴포넌트/함수 단위로 쪼개고, 진입점에서는 단일 분기로 어느 컴포넌트를 쓸지만 고른다.

**리뷰 시그널:**
- `useEffect` 첫 줄이 `if (X) return;`
- 동일 컴포넌트 안에서 props/JSX가 역할별로 갈라지는 삼항 다수
- 함수 길이의 절반 이상이 하나의 boolean으로 갈라지는 분기

```tsx
// Before
function SubmitButton() {
  const isViewer = useRole() === "viewer";
  useEffect(() => {
    if (isViewer) return;
    showButtonAnimation();
  }, [isViewer]);
  return isViewer ? <TextButton disabled /> : <Button type="submit" />;
}

// After
function SubmitButton() {
  return useRole() === "viewer" ? <ViewerSubmitButton /> : <AdminSubmitButton />;
}
```

---

## 2. 구현 상세 추상화하기

**안티패턴:** 페이지/컴포넌트의 본질과 무관한 횡단 관심사(인증 체크, 리다이렉트, 권한 가드, 로깅)가 컴포넌트 본문에 그대로 노출.

**원칙:** 한 번에 알아야 할 맥락의 양을 줄인다. 횡단 관심사는 래퍼 컴포넌트(`<AuthGuard>`)·HOC·커스텀 훅으로 들어내고, 본문은 본질만 남긴다.

**리뷰 시그널:**
- 페이지 컴포넌트 최상단에 `useCheckLogin`, `if (!user) redirect(...)` 같은 가드 로직
- 동일 패턴이 여러 페이지에 복붙되어 있음
- 컴포넌트 이름과 무관한 책임이 본문에 섞여 있음

```tsx
// Before
function LoginStartPage() {
  useCheckLogin({
    onChecked: (status) => { if (status === "LOGGED_IN") location.href = "/home"; }
  });
  return <>{/* 로그인 UI */}</>;
}

// After
<AuthGuard><LoginStartPage /></AuthGuard>
```

---

## 3. 로직 종류에 따라 함수 쪼개기

**안티패턴:** 한 훅/함수가 "이 페이지에 필요한 모든 쿼리 파라미터", "이 폼의 모든 필드 상태"처럼 무제한 책임을 떠안음.

**원칙:** 책임 단위로 잘게 쪼갠다. 쿼리 파라미터 N개면 훅도 N개. 호출부에서 필요한 것만 골라 쓴다.

**리뷰 시그널:**
- 한 훅이 5개 이상의 값/세터를 반환 (`{ values, controls }` 형태의 거대 객체)
- 훅 이름이 `usePageState`, `useFormState`처럼 범위가 페이지/폼 단위
- 훅 수정 PR이 한 파일에 자주 집중됨 (변경 hotspot)

```ts
// Before
function usePageState() { return { values, controls }; } // cardId, dateFrom, ... 모두

// After
function useCardIdQueryParam() { /* ... */ }
function useDateRangeQueryParam() { /* ... */ }
```

---

## 4. 복잡한 조건에 이름 붙이기

**안티패턴:** `&&`/`||`/`some`/`filter`가 여러 줄 중첩된 조건식이 `if`·`return`에 그대로 박힘.

**원칙:** 조건의 의미를 변수/함수 이름으로 노출. 단, 단순한 1줄 조건엔 적용하지 않는다 (과한 추상화는 시점 이동 유발).

**리뷰 시그널:**
- 한 줄짜리 boolean 식이 80자 이상
- `.some(... => ... && ....some(...))`처럼 중첩 고차함수
- 같은 조건식이 2회 이상 반복

```ts
// Before
product.categories.some(c =>
  c.id === targetCategory.id &&
  product.prices.some(p => p >= minPrice && p <= maxPrice)
);

// After
const isSameCategory = product.categories.some(c => c.id === targetCategory.id);
const isPriceInRange = product.prices.some(p => minPrice <= p && p <= maxPrice);
return isSameCategory && isPriceInRange;
```

---

## 5. 매직 넘버에 이름 붙이기

**안티패턴:** 코드에 의미 없는 숫자 리터럴(`300`, `404`, `86400`, `0.8`)이 그대로 박힘.

**원칙:** 의미를 가지는 숫자는 단위/의도를 담은 상수로 추출. 단순 인덱싱(`arr[0]`)이나 자명한 수학 상수(`* 2`)에는 적용하지 않는다.

**리뷰 시그널:**
- `delay(300)`, `setTimeout(..., 500)` — 단위·이유 없음
- HTTP 상태 비교 `=== 404`, `=== 401`
- 비율·임계값 `> 0.8`, `< 100`
- 같은 숫자 리터럴이 2곳 이상 반복

```ts
// Before
await postLike(url); await delay(300); await refetchPostLike();

// After
const ANIMATION_DELAY_MS = 300;
await postLike(url); await delay(ANIMATION_DELAY_MS); await refetchPostLike();
```

---

## 6. 시점 이동 줄이기

**안티패턴:** 한 줄을 이해하려고 다른 함수→다른 상수→다른 파일을 차례로 열어봐야 함. 작은 도메인인데 과도한 추상화로 3홉 이상 점프.

**원칙:** "위에서 아래로" 한 화면에서 읽히도록. **추상화 비용 > 이해 비용**이면 인라인이 낫다.

**리뷰 시그널:**
- 분기 결과를 알려면 2개 이상 다른 파일을 열어야 함
- 헬퍼 함수가 단 1곳에서만 호출되고, 본문이 짧음
- 정책/권한 객체가 컴포넌트와 멀리 떨어진 파일에 흩뿌려져 있음

```ts
// Before (3홉)
const canInvite = getPolicyByRole(role).canInvite;

// After (인라인 switch)
switch (role) {
  case "admin":  return <InviteButton />;
  case "viewer": return <DisabledButton />;
}
```

---

## 7. 삼항 연산자 단순하게

**안티패턴:** 삼항 중첩(`a ? b : c ? d : e ? f : g`).

**원칙:** 중첩 삼항 대신 IIFE + `if` 사슬, 또는 lookup 객체. 단일 조건의 삼항은 그대로 둬도 무방.

**리뷰 시그널:**
- `?` 가 한 식에 2개 이상
- 줄바꿈된 삼항 식
- boolean 조합 분기가 3개 이상

```ts
// Before
const status = A && B ? "BOTH" : A ? "A" : B ? "B" : "NONE";

// After
const status = (() => {
  if (A && B) return "BOTH";
  if (A)      return "A";
  if (B)      return "B";
  return "NONE";
})();
```

---

## 8. 왼쪽에서 오른쪽으로 읽히게

**안티패턴:** 범위 조건을 `a >= b && a <= c`처럼 변수 `a`를 양쪽에서 다른 방향으로 비교.

**원칙:** 범위 비교는 수학 부등식 형태 `low <= x && x <= high`. 부정형(`!isReady`)보다 긍정형(`isReady`)을 선호.

**리뷰 시그널:**
- `x >= A && x <= B` 패턴
- `!hasError && !isLoading` 같이 부정 사슬
- 비교 연산자 방향이 한 줄 안에서 섞임

```ts
// Before
if (a >= b && a <= c) { /* ... */ }

// After
if (b <= a && a <= c) { /* ... */ }
```

---

## 리뷰어 체크리스트 (한 줄 요약)

| # | 시그널 |
|---|---|
| 1 | `useEffect` 안의 `if (X) return` 가드 / 역할별 삼항 JSX |
| 2 | 페이지 본문의 횡단 관심사 (인증·리다이렉트) |
| 3 | 거대 훅 (5+ 항목 반환) |
| 4 | 80자+ 한 줄 조건식 / 중첩 `.some` |
| 5 | 단위·의도 없는 숫자 리터럴 |
| 6 | 한 줄 이해에 3개 파일 점프 / 단일 호출 헬퍼 |
| 7 | 한 식에 `?` 2개 이상 |
| 8 | `x >= A && x <= B` (대신 `A <= x && x <= B`) |
