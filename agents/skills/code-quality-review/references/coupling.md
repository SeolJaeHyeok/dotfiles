# 결합도 (Coupling) — 핵심 원칙

> 코드를 수정했을 때의 영향 범위. 한 곳을 고쳤을 때 다른 곳이 깨지지 않고, 변경 범위를 예측할 수 있어야 한다. 핵심 질문: **"한 부분의 변경이 다른 부분에 미치는 영향이 작은가?"**

---

## 1. 책임을 하나씩 관리하기

**안티패턴:** 쿼리 파라미터·상태·API 호출 같은 "로직의 종류"로 묶어 하나의 Hook/컴포넌트/함수에 모든 것을 몰아넣음. 예: 페이지 전체의 cardId, statementId, dateFrom, dateTo, statusList를 한 `usePageState()` Hook에서 동시 관리.

**원칙:** "기술 종류"가 아니라 "도메인 책임" 단위로 쪼갠다. 쿼리 파라미터 하나당 하나의 Hook(`useCardIdQueryParam`)으로 분리하면, 그 파라미터를 쓰는 컴포넌트만 영향을 받는다.

**리뷰 시그널:**
- 단일 Hook/Store가 5개 이상 서로 다른 상태·파라미터 관리
- 서로 무관한 화면·컴포넌트가 같은 Hook을 import
- 한 필드만 고치는데 그 Hook을 쓰는 모든 페이지의 회귀 테스트가 필요해짐
- 이름이 `usePageState`, `useXxxAll`, `useGlobalForm`처럼 범위가 모호

```ts
// Before
function usePageState() { /* cardId, dateFrom, ..., 5+ */ return { values, controls }; }

// After
function useCardIdQueryParam() { /* ... */ }
function useDateRangeQueryParam() { /* ... */ }
```

---

## 2. 중복 코드 허용하기

**안티패턴:** "비슷해 보인다"는 이유로 여러 페이지에서 쓰는 Hook(예: 점검 바텀시트 — 로깅 → 오픈 → 화면 종료)을 공통 Hook 하나로 무리하게 통합. 페이지별로 살짝 다른 요구사항이 들어올 때마다 조건부 인자가 추가되어, 한 페이지를 위한 수정이 다른 모든 페이지를 흔든다.

**원칙:** 동작과 모양이 지금도 같고 "앞으로도 같을 예정"일 때만 공통화한다. 미래에 갈라질 여지가 있다면 중복을 허용하는 편이 결합도를 낮춘다. **DRY보다 "변경 축이 같은가"를 먼저 묻는다.**

**리뷰 시그널:**
- 공통 Hook/유틸의 인자에 `isXxxPage`, `variant`, `mode` 같은 호출처 분기 플래그가 누적
- 한 페이지 요구사항 반영을 위해 공통 Hook 내부에 `if` 분기가 늘어남
- 한 줄 수정이 N개 페이지의 QA를 강제
- 호출처마다 "이 옵션은 우리 페이지에선 안 씀" 주석

```ts
// Before — 분기 플래그가 누적되는 공통 Hook
useMaintenanceBottomSheet({ isOrderPage: true, mode: "v2" });

// After — 페이지마다 자기 로직 직접 보유
```

---

## 3. Props Drilling 지우기

**안티패턴:** `ItemEditModal` → `ItemEditBody` → `ItemEditList`처럼 중간 컴포넌트가 `items`, `recommendedItems`, `onConfirm`을 그대로 통과시키기만 함. prop 이름 하나만 바뀌어도 경로상의 모든 컴포넌트를 수정 → 수직 결합도 ↑.

**원칙:** Composition(`children`)으로 중간 추상화를 걷어내 부모가 직접 리프를 조립. 그래도 깊다면 그때 Context를 도입. **Props는 "통과 통로"가 아니라 "그 컴포넌트의 역할과 의도"를 표현해야 한다.**

**리뷰 시그널:**
- 동일 prop 이름이 3단계 이상 컴포넌트 계층을 따라 반복
- 중간 컴포넌트가 prop을 받기만 하고 자기 로직에선 안 쓴 채 자식에 forward
- prop 추가/이름 변경 PR diff가 4~5개 파일에 동일 패턴으로 퍼짐
- 중간 컴포넌트의 props 타입이 자식 props 타입의 상위집합

```tsx
// Before
<ItemEditModal items={items} onConfirm={onConfirm}>
  {/* 내부에서 ItemEditBody → ItemEditList로 forward */}
</ItemEditModal>

// After — Composition
<ItemEditModal>
  <ItemEditList items={items} onConfirm={onConfirm} />
</ItemEditModal>
```

---

## 리뷰어 체크리스트

| # | 시그널 |
|---|---|
| 1 | Hook/Store가 5+ 책임 / 무관한 화면이 같은 Hook 의존 / 모호한 범위 이름 |
| 2 | 공통 Hook 인자에 `isXxxPage`/`mode` 누적 / 내부 `if` 분기 증가 |
| 3 | 동일 prop이 3+ 단계 forward / 중간 컴포넌트가 prop을 안 쓰고 통과 |
