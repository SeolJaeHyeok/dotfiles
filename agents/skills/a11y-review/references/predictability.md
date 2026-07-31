# 예측 가능한 동작 (Predictability) — 핵심 원칙

> 카테고리 정의: 사용자가 시각적으로 인지한 요소의 역할과 실제 동작이 일치해야 한다. `<button>`처럼 보이면 키보드로 포커스되고 Enter/Space로 활성화돼야 하며, 입력 폼이라면 Enter로 제출되고 SR이 "폼"으로 안내해야 한다. 시맨틱 HTML이 제공하는 기본 동작을 우회하지 않는 것이 핵심.

---

## 1. 버튼은 `<button>` 요소로 만들기 (Fake Button 금지)

**안티패턴:** `<div class="button-style" onclick="handleClick()">문의하기</div>` 처럼 일반 요소에 `cursor: pointer`와 클릭 리스너만 얹어 버튼처럼 보이게. `<a>`로 가짜 버튼/링크를 만드는 경우도 동일.

**접근성 영향:**
- 키보드 사용자는 Tab으로 포커스 자체가 불가, 버튼에 도달조차 못함
- SR은 "버튼"으로 인식 못 해 역할 안내 안 됨, Enter·Space 활성화 안 됨
- 클릭 외 모든 입력 경로 차단

**원칙:**
- 시맨틱 `<button>` 사용 — 키보드 포커스, Enter/Space 활성화, "버튼" 역할 안내, 비활성/포커스 링까지 무료
- 디자인 제약상 `<div>`를 써야 하면 `role="button"` + `tabIndex={0}` + `onKeyDown`(Enter/Space) 모두 직접 추가, 또는 react-aria의 `useButton`

**예시:**
```jsx
// Before
<div className="btn" onClick={handleClick}>문의하기</div>

// After
<button onClick={handleClick}>문의하기</button>

// 부득이 div를 써야 할 때
<div role="button" tabIndex={0} onClick={handleClick}
  onKeyDown={(e) => { if (e.key === "Enter" || e.key === " ") handleClick(); }}>
  문의하기
</div>
```

**리뷰 시그널:**
- `<div onClick=` / `<span onClick=` / `<a onClick=` 패턴
- `cursor: pointer`만 있고 `<button>`이 아닌 요소
- `role="button"`이 있는데 `tabIndex`나 `onKeyDown` 없음
- `<a href="#">` + `onClick + preventDefault`로 만든 가짜 링크

---

## 2. 입력 요소는 `<form>`으로 감싸기

**안티패턴:** `<input>` / `<textarea>`를 `<form>` 없이 단독 배치하고 제출 버튼을 `<div onClick>` 또는 `<button onClick>`(type 미지정)로 처리. 폼 안에 둔 일반 클릭 버튼에 `type="button"`을 명시하지 않아 의도치 않은 submit 발생도 포함.

**접근성 영향:**
- `<form>`이 없으면 입력란에서 Enter 제출 불가
- SR은 폼 진입 시 "로그인, 폼, 아이디, 편집..." 같은 landmark 안내 못 함
- 단축키로 폼 영역만 건너뛰며 탐색 불가
- 자동완성·입력 기록·모바일 입력 최적화도 `<form>` 컨텍스트가 없으면 제대로 동작 안 함

**원칙:**
- 입력 요소는 항상 `<form>`으로 감싸고 `onSubmit`에서 `event.preventDefault()`
- 제출 버튼은 `<button type="submit">`, 클릭 전용은 반드시 `type="button"` 명시
- 시각적으로 폼 바깥의 버튼은 `<button form="form-id" type="submit">`으로 연결
- `<form>`에 `aria-label`로 폼의 목적 부여

**예시:**
```html
<!-- Before: form 없음, Enter 제출 불가 -->
<input id="id" type="text" />
<input id="pw" type="password" />
<div onClick="login()">로그인</div>

<!-- After -->
<form aria-label="로그인" onsubmit="event.preventDefault(); login();">
  <label for="id">아이디</label>
  <input id="id" name="id" type="text" />
  <label for="pw">비밀번호</label>
  <input id="pw" name="pw" type="password" />
  <button type="submit">로그인</button>
</form>

<!-- 폼 안의 부가 버튼은 type="button" 필수 -->
<button type="button" aria-label="아이디 입력값 삭제">❌</button>
```

**리뷰 시그널:**
- `<input>`이 `<form>` 바깥에 있음
- `<form>` 안에 `type` 미지정 `<button>` (클릭 시 의도치 않은 submit)
- `<button>` 대신 `<div onClick="submit()">`로 제출 구현
- `<label htmlFor>` 누락, `aria-label` 없는 `<form>`
- "Enter 키로 제출 안 됨", "삭제 버튼 클릭 시 폼이 제출됨", "SR이 폼 landmark 인식 못 함" 같은 지적 가능
