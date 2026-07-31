# 구조 (Structure) — 핵심 원칙

> 카테고리 정의: 상호작용 요소(`<a>`, `<button>`, `<input>`)의 **중첩**과 **시맨틱 누락**으로 키보드·스크린리더 사용자의 접근성이 깨지지 않도록, HTML 트리 자체를 시맨틱하게 만든다.

---

## 1. 버튼/링크 안에 또 다른 버튼·링크를 중첩하지 않기

**안티패턴:** `<a><Button>...</Button></a>`처럼 링크가 버튼을 감싸거나, `<button>` 내부에 또 다른 `<button>`을 두고 `event.stopPropagation()`으로 이벤트 충돌을 회피. HTML 명세상 interactive content는 다른 interactive content를 자손으로 가질 수 없다.

**접근성 영향:**
- 키보드 사용자: 외부/내부 핸들러 트리거 순서 예측 불가. 일부 브라우저에서 내부 버튼에 Tab 포커스 자체가 안 감.
- 스크린리더: "버튼, 버튼" 또는 "링크, 버튼"으로 중첩을 그대로 읽어 무엇을 활성화하는지 혼란.
- 모바일 터치: 두 hit area가 겹쳐 의도하지 않은 버튼이 눌림.

**원칙:**
- Button 컴포넌트가 다형성(`as="a"`, `href`)을 지원하도록 설계해 단일 요소로 표현.
- 한 영역에 두 액션이 모두 필요하면, 컨테이너를 `div`로 두고 주 액션 버튼은 `position: absolute; inset: 0;`로 깔고, 보조 액션은 `z-index`를 올려 시각적으로만 겹침. 포커스는 `:focus-within`으로 시각화.

**예시:**
```jsx
// Before
<a href="/go-to"><Button>확인했어요</Button></a>

// After
<Button as="a" href="/go-to">확인했어요</Button>
```

```jsx
// Before — button in button + stopPropagation
<button onClick={openDetail}>
  서비스 검토 관리
  <button aria-label="삭제" onClick={(e) => e.stopPropagation()}>x</button>
</button>

// After — sibling 구조 + absolute layering
<div style={{ position: "relative", isolation: "isolate" }} role="listitem">
  <button onClick={openDetail}
          style={{ position: "absolute", inset: 0, opacity: 0 }}>
    상세보기
  </button>
  서비스 검토 관리
  <div style={{ position: "relative", zIndex: 2 }}>
    <button aria-label="삭제" onClick={onDelete}>x</button>
  </div>
</div>
```

**리뷰 시그널:**
- `<a>`, `<button>` 안에 또 다른 `<button>`, `<a>`, `<Link>`, `<input>` → 즉시 의심
- `event.stopPropagation()` + 중첩 `onClick` 조합 → 거의 100% 중첩 인터랙션 회피
- `<Card as="button">` 류 래퍼 안에 액션 버튼 동거
- `<Button>` children에 `<IconButton>`, `<Link>` 등이 있으면 다형성 prop으로 풀어야 함

---

## 2. 테이블 행(`<tr>`) 클릭으로 라우팅하지 않기

**안티패턴:** `<tr onClick={() => location.assign(...)}>`처럼 비-인터랙티브 요소(`tr`, `div`, `span`)에 클릭 핸들러를 붙여 페이지 이동을 처리. 시맨틱은 데이터 행이지만 동작은 링크인 mismatch.

**접근성 영향:**
- 키보드 사용자: `<tr>`은 기본 tabbable 아님. `tabIndex=0`을 줘도 Enter/Space 핸들링을 직접 구현해야 하고 누락되기 쉽다.
- 스크린리더: 행이 "클릭 가능"임을 알리는 role/label 없어 목적지 모름. 링크 목록 모드(rotor)에 잡히지 않음.
- 마우스 사용자: 우클릭 → "새 탭에서 열기" 같은 브라우저 네이티브 기능 못 씀.

**원칙:**
- 네비게이션은 반드시 `<a href>` (또는 라우터 `<Link>`)로 시맨틱과 동작 일치.
- 행 전체를 클릭 영역으로 키우려면 링크 하나만 두고 `::after { position: absolute; inset: 0 }`로 영역 확장 ("card link" 패턴). `<tr>`엔 `position: relative`만.
- 아이콘만인 링크는 `aria-label`로 목적지 명시.

**예시:**
```jsx
// Before
<tr onClick={() => location.assign(`/detail/${user.id}`)}>
  <td>{user.name}</td>
  <td>{user.age}</td>
</tr>

// After
<tr style={{ position: "relative" }}>
  <td>
    <a href={`/detail/${user.id}`} aria-label={`${user.name} 자세히 보기`}
       className="row-link">{user.name}</a>
  </td>
  <td>{user.age}</td>
</tr>
/* .row-link::after { content: ""; position: absolute; inset: 0; } */
```

**리뷰 시그널:**
- `<tr ... onClick>`, `<div onClick={() => router.push(...)}>`, `<span onClick={navigate}>` 같이 비인터랙티브 태그의 네비게이션 핸들러
- `onClick` 안에서 `location.assign / location.href = / router.push / window.open` 호출되는데 `<a>`/`<button>` 아님
- `tabIndex={0}` + `onKeyDown`으로 Enter/Space 수동 처리 → 거의 항상 `<a>`/`<button>`으로 대체 가능
- 테이블에서 "행 전체 클릭"인데 내부에 진짜 `<a>` 없음
